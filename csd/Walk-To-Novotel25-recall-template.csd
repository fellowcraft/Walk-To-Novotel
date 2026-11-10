<CsoundSynthesizer>
<CsOptions>
-+rtaudio=pulse -o dac -d ; policy: REAPER owns the Scarlett on ALSA,
; everything else plays the current Pulse default sink (analog out)
</CsOptions>
<CsInstruments>

; Walk-To-Novotel25-recall template. Static resynthesis: NO conductor, NO random
; calls, NO file I/O. Grain events come from a logged take assembled at
; the marker line in the score section (see Walk-To-Novotel25.csd header).
; AmbiX first-order bus (W,Y,Z,X; SN3D) with per-side elevation is
; written by instr 98 to takes/Walk-To-Novotel25-recall-ambi.wav
; (fixed name, overwritten per recall).

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

gaW init 0 ; ambisonic bus: W omni (+ diffuse reverb), Y left(+)/right, Z up, X front
gaY init 0
gaZ init 0
gaX init 0

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
  iElPerL = p16 ; elevation LFOs, fully logged (own sine per side)
  iElPhsL = p17
  iElPerR = p18
  iElPhsR = p19
  iStart = p2
  xtratim 4 ; lets this grain's own reverb ring out; envelope already 0

  kSw oscil3 1, 1 / iWobPeriod, 1, iPhs ; slow drift sine
  kCarr = 0.1 * (20000 ^ ((kSw + 1) * 0.5)) ; 0.1..2 kHz drifting carrier
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
  ; constant-power autopan, one sine each side; elevation own sine each side
  kPanL = 0.5 + 0.5 * oscil3(1, 1 / iPanPerL, 1, iPanPhsL)
  kPanL limit kPanL, 0, 1
  kPanR = 0.5 + 0.5 * oscil3(1, 1 / iPanPerR, 1, iPanPhsR)
  kPanR limit kPanR, 0, 1
  kElL = 1.5707963 * oscil3(1, 1 / iElPerL, 1, iElPhsL) ; +-90 deg
  kElR = 1.5707963 * oscil3(1, 1 / iElPerR, 1, iElPhsR)
  aOutL = aM1 * cos(kPanL * 1.5707963) + aM2 * cos(kPanR * 1.5707963)
  aOutR = aM1 * sin(kPanL * 1.5707963) + aM2 * sin(kPanR * 1.5707963)
  ; global wet-mix swell, phase-aligned to absolute time
  iPhW = frac(0.125 + 2 * iStart / iTotal)
  kMix oscil3 0.5, 2 / iTotal, 1, iPhW
  kWet = 0.25 + 0.65 * (0.5 + 0.5 * kMix)
  ; own reverb (linear: sums to the old global sound, no shared state)
  aWL, aWR reverbsc aOutL * iRevSend, aOutR * iRevSend, 0.9, 12000
  outch 1, aOutL + aWL * kWet, 2, aOutR + aWR * kWet
  ; --- AmbiX encode (recall only): full 3D, elevation +-90 deg per side
  azL = (0.5 - kPanL) * 3.1415927 ; pan 0 = hard left = +90 deg (Y+ = left)
  azR = (0.5 - kPanR) * 3.1415927
  kCEL = cos(kElL)
  kCER = cos(kElR)
  gaW = gaW + aM1 + aM2 + (aWL + aWR) * 0.5 * kWet
  gaY = gaY + aM1 * sin(azL) * kCEL + aM2 * sin(azR) * kCER
  gaZ = gaZ + aM1 * sin(kElL) + aM2 * sin(kElR)
  gaX = gaX + aM1 * cos(azL) * kCEL + aM2 * cos(azR) * kCER
endin

instr 98 ; ambisonic writer (recall only): 4ch AmbiX float file
  fout "/mnt/b/CSOUND/Walk-To-Novotel/takes/Walk-To-Novotel25-recall-ambi.wav", 16, gaW, gaY, gaZ, gaX
  gaW = 0
  gaY = 0
  gaZ = 0
  gaX = 0
endin


</CsInstruments>
<CsScore>
f1 0 16384 10 1
;__AMBISPAN__
;__EVENTS__
</CsScore>
</CsoundSynthesizer>
