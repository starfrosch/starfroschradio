# This function is called when
# a new metadata block is passed in
# the stream.
#def apply_metadata(m) =
#  title = m["title"]
#  artist = m["artist"]
#  type = m["type"]
#  genre = m["genre"]
#log(level=3, "starfrosch.type: " ^ type)
#log(level=3, "starfrosch.title: " ^ title)
#log(level=3, "starfrosch.genre: " ^ genre)
#end

# A function that contains all the output
# we want to create with the final stream
def outputs(s) =
  # First, we partially apply output.icecast
  # with common parameters. The resulting function
  # is stored in a new definition of output.icecast,
  # but this could be my_icecast or anything.
output.icecast = output.icecast(host="radio.starfrosch.com",port=8000,id="icecast",fallible=true, 
                                  name="starfrosch", url="https://starfrosch.com/radio", description="Looking for freshness", genre="Electronic, Rock, Hip-Hop, World, Pop, Ambient", password="hackme")

  # An output in mp3 to the "my_radio.ogg"
  # mountpoint:
output.icecast(%mp3(bitrate=192), mount="stream", s)

  # An output in ogg/vorbis to the "ogg"
  # mountpoint:
#  output.icecast(%vorbis, mount="ogg",s)

  # An output in AAC+ at 96 kbits to the "aac"
  # mountpoint
#  output.icecast(%aacplus(bitrate=96), mount="aac",s)
end

# Define a transition that fades out the
# old source, adds a single, and then 
# plays the new source
def to_live(old,new) = 
  # Fade out old source
  old = fade.final(old)
  new = fade.in(new)
  # Superpose the jingle
#  s = add([jingle,old])
  # Compose this in sequence with
  # the new source
  sequence([old,new])
end

# A transition when switching back to files:
def to_file(old,new) =
  # We skip the file
  # currently in new
  # in order to being with
  # a fresh file
#  source.skip(new) 
  old = fade.final(old)
  new = fade.in(new)
  sequence([old,new])
end

# This function takes a metadata,
# check if it is of type "file"
# and add the replay_gain metadata in
# this case
def add_replaygain(m) = 
  # Get the type
  type = m["type"]
  # The replaygain script is located there
  script = "#{configure.libdir}/extract-replaygain"
  # The file name is contained in this value
  filename = m["filename"]

  # If type not = "jingles", proceed:
  if type != "jingles" then
    info = list.hd(get_process_lines("#{script} #{filename}")) 
    [("replay_gain",info)]
  # Otherwise add nothing
  else
    []
  end
end

# Our custom crossfade that 
# only crossfade between tracks
def my_crossfade(s) = 
  # Our transition function
  def f(_,_, old_m, new_m, old, new) =  
  # If none of old and new have "type" metadata
    # with value "Jingle", we crossfade the source:  
    log(level=3, "starfrosch.type2: " ^ old_m["type"])
    if old_m["type"] != "Jingle" and new_m["type"] != "Jingle" then
      add([fade.initial(new), fade.final(old)])
    else
      sequence([old,new])
    end
end
 # Now, we apply smart_cross with this function:
 smart_cross(f,s)
end
