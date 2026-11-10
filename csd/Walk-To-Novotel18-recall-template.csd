<CsoundSynthesizer>
<CsOptions>
-+rtaudio=pulse -o dac -d ; policy: REAPER owns the Scarlett on ALSA,
; everything else plays the current Pulse default sink (analog out)
</CsOptions>
<CsInstruments>

; Walk-To-Novotel18-recall template. Static resynthesis: NO conductor, NO random
; calls, NO file I/O. Grain events come from a logged take assembled at
; the marker line in the score section (see Walk-To-Novotel18.csd header).

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

instr 2 ; grain: fixed-rate slice, parallel ring-mod, autopan, own reverb
  iDur = p3
  iAmp = ampdb(p4)
  iSkip = p5
  iWobPeriod = p6
  iRevSend = p7
  iPhs = p8 ; logged drift phase, no randomness left in this instrument
  iFlip = p9 ; 1 = swap which side gets which pan LFO
  iPanPerL = p10 ; independent pan LFOs, fully logged
  iPanPhsL = p11
  iPanPerR = p12
  iPanPhsR = p13
  iTotal = p14 ; piece length, for the global wet-mix swell
  iWetMix = p15 ; ring-mod wet proportion, logged per grain (0.2..0.8)
  iStart = p2
  xtratim 4 ; lets this grain's own reverb ring out; envelope already 0

  kSw oscil3 1, 1 / iWobPeriod, 1, iPhs ; slow drift sine
  kCarr = 0.1 * (1200 ^ ((kSw + 1) * 0.5)) ; 0.1..120 Hz drifting carrier
  aC oscil3 1, kCarr, 1 ; shared audio-rate carrier, phase-continuous
  a1, a2 diskin2 "/mnt/b/CSOUND/Walk-To-Novotel/Media/Walk-To-Novotel.wav", 1, iSkip, 0
  aR1 = a1 * aC
  aR2 = a2 * aC
  iAtt = 0.3 * iDur
  iRel = 0.3 * iDur
  kEnv linseg 0, iAtt, iAmp, iDur - iAtt - iRel, iAmp, iRel, 0
  ; parallel blend: per-grain wet/dry, 20..80% ring-mod
  iDryMix = 1 - iWetMix
  aM1 = (a1 * iDryMix + aR1 * iWetMix) * kEnv
  aM2 = (a2 * iDryMix + aR2 * iWetMix) * kEnv
  if iFlip == 1 then
    aT = aM1
    aM1 = aM2
    aM2 = aT
  endif
  ; constant-power autopan, one sine each side
  kPanL = 0.5 + 0.5 * oscil3(1, 1 / iPanPerL, 1, iPanPhsL)
  kPanL limit kPanL, 0, 1
  kPanR = 0.5 + 0.5 * oscil3(1, 1 / iPanPerR, 1, iPanPhsR)
  kPanR limit kPanR, 0, 1
  aOutL = aM1 * cos(kPanL * 1.5707963) + aM2 * cos(kPanR * 1.5707963)
  aOutR = aM1 * sin(kPanL * 1.5707963) + aM2 * sin(kPanR * 1.5707963)
  ; global wet-mix swell, phase-aligned to absolute time
  iPhW = 0.125 + 2 * iStart / iTotal
  iPhW = iPhW - int(iPhW)
  kMix oscil3 0.5, 2 / iTotal, 1, iPhW
  kWet = 0.25 + 0.65 * (0.5 + 0.5 * kMix)
  ; own reverb (linear: sums to the old global sound, no shared state)
  aWL, aWR reverbsc aOutL * iRevSend, aOutR * iRevSend, 0.9, 12000
  outch 1, aOutL + aWL * kWet, 2, aOutR + aWR * kWet
endin


</CsInstruments>
<CsScore>
f1 0 16384 10 1
;__EVENTS__
</CsScore>
</CsoundSynthesizer>
