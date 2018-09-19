#!/usr/local/bin/liquidsoap

set("log.file",true)
set("log.stdout",true)
set("log.level",4)

#set("init.daemon.pidfile.path","/var/run/liquidsoap/radio.pid")
#set("init.daemon.pidfile",true)
#set("init.daemon",true)

set("server.telnet",true)

%include "/home/kus/radio/scripts/library.liq"
%include "/home/kus/radio/scripts/tunein.liq"

# The File Sources
electronic = playlist("/home/kus/radio/library/electronic",reload_mode="watch")
electronictheme = playlist("/home/kus/radio/library/electronicthemes",reload_mode="watch")

triphop =       playlist("/home/kus/radio/library/triphop",reload_mode="watch")
rock =       playlist("/home/kus/radio/library/rock",reload_mode="watch")
folk =       playlist("/home/kus/radio/library/folk",reload_mode="watch")
hiphop =     playlist("/home/kus/radio/library/hiphop",reload_mode="watch")
ambient =    playlist("/home/kus/radio/library/ambient",reload_mode="watch")
# children =   playlist("/home/kus/radio/library/children",reload_mode="watch")
# fairytales = audio_to_stereo(playlist("/home/kus/radio/library/fairytales",reload_mode="watch"))
# classical =  playlist("/home/kus/radio/library/classical",reload_mode="watch")
# jazz =       playlist("/home/kus/radio/library/jazz",reload_mode="watch")
# world =      playlist("/home/kus/radio/library/world",reload_mode="watch")
dub =	    playlist("/home/kus/radio/library/dub",reload_mode="watch")
edm =        playlist("/home/kus/radio/library/edm",reload_mode="watch")
pop =        playlist("/home/kus/radio/library/pop",reload_mode="watch")

# christmas =        playlist("/home/kus/radio/library/christmas",reload_mode="watch")

blocsonictheme =  playlist("/home/kus/radio/library/blocsonicthemes/",reload_mode="watch")
blocsonic =       playlist("/home/kus/radio/library/blocsonic",reload_mode="watch")

# broquetheme = playlist("/home/kus/radio/library/broquethemes",reload_mode="watch")
# broque =      playlist("/home/kus/radio/library/broque")

# lastfmcc = input.lastfm(user="starfrosch",password="hackme","lastfm://globatags/rock")
# lastfmcc = lastfm.uri(user="starfrosch", password="hackme",discovery=false,"globaltags/creative-commons")

# The jingle source
jingles =    playlist("/home/kus/radio/library/jingles",reload_mode="watch")

# define default broadcast
default = single("/home/kus/radio/library/jingles/SSSStarfrosch.mp3")

# Electronic incl. Ambient and some Dub
electronic = rotate(weights=[10,1,1,1,1], [electronic,ambient,dub,edm,triphop])

# Standard Mix
fullmix = rotate(weights=[2,2,2,2,2], [electronic,hiphop,rock,pop,folk])

# Play user requests if there are any,
# otherwise one of our playlists,
# and the default file if anything goes wrong.
s = fallback([ request.queue(id="request"),
                    switch([	({ 07h-19h }, fullmix),
				({ 19h-20h }, ambient),
				({ 20h-21h }, fullmix),
                                ({ 21h-01h }, sequence([electronictheme,electronic])),
				({ 01h-01h30 }, sequence([blocsonictheme,blocsonic])),
				({ 01h30-02h }, sequence([blocsonictheme,blocsonic])),
                                ({ 02h-07h }, electronic),
				]),
                                default])

# Add the normal jingles
s = rotate(weights=[1,9],[ jingles, s ])

# scrobble to last.fm, libre.fm, tune.in, flows
s = on_metadata(lastfm.submit(user="youruser",password="hackme"), s)
s = on_metadata(librefm.submit(user="youruser",password="hackme"), s)
s = on_metadata(tunein.submit(partnerid="yourid",partnerkey="hackme",stationid="yourid"), s)

#s = on_metadata(apply_metadata,s)
# s = map_metadata(add_replaygain,s)
# s = amplify(1.,override="replay_gain",s)
# s = normalize(s)
s = crossfade(start_next=10.,fade_out=10.,fade_in=10.,s)

%include "/home/kus/radio/scripts/sound-processing.liq"

# rms-leveler https://launchpad.net/%7Emc-1/+archive/ubuntu/audio-tools
# s = ladspa.rms_leveler_3s(s)

# multiband compressor
# s = sky(s)
# Now overall compression, faster attack, harder ratio, mostly RMS based.
# s = compress(s, attack = 1.0, gain = 1.0, knee = 1.0, ratio = 4.0, release = 2.0, threshold = -2.0, rms_window = 0.9)
# Normalize, with a higher threshold to stop suck-up.
# s = normalize(s, target = -1.0, threshold = -65.0)
# Limiter, this one's a scaling one which limits nicely and without artefacting mostly
# s = ladspa.tap_limiter(s, limit_level = -1.5)
# And a final limiter - this should never really get hit, but stops anything nasty hitting the DAC. Highly peak-focused.
# s = limit(s, threshold = -0.1, attack = 2.0, release = 25.0, rms_window = 0.02)

# register flow
# s = register_flow(
#  radio="starfrosch",
#  website="http://starfrosch.com/radio/",
#  description="Creative Commons #hot100 Radio",
#  genre="Eclectic",
#  user="yourusername",
#  password="hackme",
#  streams=[("mp3/160k","http://radio.starfrosch.com:8000/stream"),("vorbis/128k","http://radio.starfrosch.com:8000/ogg")],
#  s)

#preserve meta
# pattern = "$(title)"

# stereo-tool write to output
# output.file(%wav(stereo=true, channels=2, samplesize=16, header=true, duration=1.), "/tmp/audioin.pcm", s)

# put all stream in the s object using the dd command
# s = mksafe(input.external("dd if=/tmp/audioout.pcm 2>/dev/null"))

# re-apply metadata that got lost by stereo-tool
# pattern = '"$(title)"'
# s = rewrite_metadata([("title",pattern)], s)

# live stream / mountpoint /live
live1 = input.harbor("live",port=8001,password="hackme")

s = fallback(track_sensitive=false,
             transitions=[to_live, to_file],
             [live1, s])

#s = fallback(track_sensitive=false,
#            [live1, s])

 
# We output the stream to an icecast
# server, in ogg/vorbis format.
outputs(s)

# avoid buffer overruns
output.dummy(fallible=true, live1)
output.dummy(fallible=true, s)
