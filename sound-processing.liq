#
# Pieci / 5 koncerti sound processing
# http://pieci.lv
#
# Author: Aigars Sukurs <aigars@130db.lv>
# Copyright: (C) 2013 130DB
# Licence: MIT
#

#s = ladspa.gate(s, threshold = -60.0, attack = 0.15, hold = 1.0, decay = 200.0, range = -25.0)

# Wideband AGC
#s = normalize(target = 0., window = 0.03, gain_min = -16., gain_max = 0., s)
#s = normalize(s, target = -3.0, threshold = -65.0)

# Initial compression low ration
s = ladspa.sc4(rms_peak=-0.3, attack_time = 0.5, release_time = 3., threshold_level = -5.0, ratio=1., makeup_gain = 3., s)

# Emulate a five-band crossover network
#sub = filter.iir.eq.low(frequency = 190.,)

#lhi = filter.iir.eq.high(frequency = 190.,)
#llo = filter.iir.eq.low(frequency = 700.,)

#mhi = filter.iir.eq.high(frequency = 700.,)
#mlo = filter.iir.eq.low(frequency = 2500.,)

#hhi = filter.iir.eq.high(frequency = 2500.)
#hlo = filter.iir.eq.low(frequency = 6500.)

#shi = filter.iir.eq.high(frequency = 6500.)
#slo = filter.iir.eq.low(frequency = 15000.)

#c = ladspa.sc4(rms_peak = 0.5)
#l = ladspa.tap_limiter(limit_level = -0.5)

# Emulate a five-band AGC compresor and limit 
#s = add(normalize=false,
#  [
#  l(c(attack_time = 2.25, release_time = 40., threshold_level = -10., ratio=3., makeup_gain = 3., sub(s))),
#  l(c(attack_time = 2.25, release_time = 40., threshold_level = -13., ratio=3., makeup_gain = 3., llo(lhi(s)))),
#  l(c(attack_time = 2.25, release_time = 40., threshold_level = -9., ratio=3., makeup_gain = 0.5, mlo(mhi(s)))),
#  l(c(attack_time = 2.25, release_time = 40., threshold_level = -6., ratio=3., makeup_gain = 0.5, hlo(hhi(s)))),
#  l(c(attack_time = 2.25, release_time = 40., threshold_level = -4., ratio=3., makeup_gain = 2., slo(shi(s))))
#  ])

# Limit, if there is something to limit
s = limit(s, threshold = -0.1, attack = 2.0, release = 25.0, rms_window = 0.02)
