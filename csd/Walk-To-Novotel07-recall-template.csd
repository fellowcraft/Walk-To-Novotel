<CsoundSynthesizer>
<CsOptions>
-+rtaudio=pulse -o dac -d ; policy: REAPER owns the Scarlett on ALSA,
; everything else plays the current Pulse default sink (analog out)
</CsOptions>
<CsInstruments>

; Walk-To-Novotel07-recall template. Static resynthesis: NO conductor, NO random
; calls, NO file I/O. Grain events come from a logged take assembled at
; the marker line in the score section (see Walk-To-Novotel07.csd header).
; i99 length must stay conductor_len + 6 (instr 99 recovers LFO periods).

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

gaRevL init 0
gaRevR init 0

instr 2 ; grain: fixed-rate stereo slice, parallel ring-mod, independent autopan per side
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
  xtratim 0.01 ; note-off lands in digital silence (envelope already 0),
                ; so score vs schedkwhen end-rounding cannot differ audibly

  kSw oscil3 1, 1 / iWobPeriod, 1, iPhs ; slow drift sine
  kCarr = 40 * (2 ^ kSw) ; 20..80 Hz drifting carrier
  aC oscil3 1, kCarr, 1 ; shared audio-rate carrier, phase-continuous
  a1, a2 diskin2 "/mnt/b/CSOUND/Walk-To-Novotel/Media/Walk-To-Novotel.wav", 1, iSkip, 0
  aR1 = a1 * aC
  aR2 = a2 * aC
  iAtt = 0.3 * iDur
  iRel = 0.3 * iDur
  kEnv linseg 0, iAtt, iAmp, iDur - iAtt - iRel, iAmp, iRel, 0
  ; parallel blend: mostly dry, a little ring-mod shimmer on top
  aM1 = (a1 * 0.8 + aR1 * 0.2) * kEnv
  aM2 = (a2 * 0.8 + aR2 * 0.2) * kEnv
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
  outch 1, aOutL, 2, aOutR
  gaRevL = gaRevL + aOutL * iRevSend
  gaRevR = gaRevR + aOutR * iRevSend
endin

instr 99 ; global reverb, wet mix rides the same T/2 sine as send center
  iTotal = p3 - 6 ; score gives 6 s tail; recover conductor length
  kT timeinsts
  kMix oscil3 0.5, 2 / iTotal, 1, 0.125
  kWet = 0.2 + 0.6 * (0.5 + 0.5 * kMix)
  aWL, aWR reverbsc gaRevL, gaRevR, 0.8, 12000
  outch 1, aWL * kWet, 2, aWR * kWet
  gaRevL = 0
  gaRevR = 0
endin

</CsInstruments>
<CsScore>
f1 0 16384 10 1
i99 0 3606
;__EVENTS__
</CsScore>
</CsoundSynthesizer>
