<CsoundSynthesizer>
<CsOptions>
-+rtaudio=pulse -o dac -d ; policy: REAPER owns the Scarlett on ALSA,
; everything else plays the current Pulse default sink (analog out)
</CsOptions>
<CsInstruments>

; Walk-To-Novotel02-recall template. Static resynthesis: NO conductor, NO random
; calls, NO file I/O. Grain events come from a logged take assembled at
; the marker line in the score section (see Walk-To-Novotel02.csd header).
; i99 length must stay conductor_len + 6 (instr 99 recovers LFO periods).

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

gaRevL init 0
gaRevR init 0

instr 2 ; grain: fixed-rate stereo slice through sweeping narrow bandpass
  iDur = p3
  iAmp = ampdb(p4)
  iSkip = p5
  iWobPeriod = p6
  iRevSend = p7
  iPhs = p8 ; logged sweep phase
  iFlip = p9 ; 1 = L/R swapped for this grain
  xtratim 0.01 ; note-off lands in digital silence (envelope already 0),
                ; so score vs schedkwhen end-rounding cannot differ audibly

  kSw oscil3 1, 1 / iWobPeriod, 1, iPhs ; same sine as before, full swing
  kCf = 500 * (8 ^ ((kSw + 1) * 0.5))    ; 500 Hz..4 kHz, exponential sweep
  kBw = kCf / 4                          ; wide, gentle Q
  a1, a2 diskin2 "/mnt/b/CSOUND/Walk-To-Novotel/Media/Walk-To-Novotel.wav", 1, iSkip, 0
  aF1 butbp a1, kCf, kBw
  aF2 butbp a2, kCf, kBw
  iAtt = 0.3 * iDur
  iRel = 0.3 * iDur
  kEnv linseg 0, iAtt, iAmp, iDur - iAtt - iRel, iAmp, iRel, 0
  aL = aF1 * kEnv
  aR = aF2 * kEnv
  if iFlip == 1 then
    aT = aL
    aL = aR
    aR = aT
  endif
  outch 1, aL, 2, aR
  gaRevL = gaRevL + aL * iRevSend
  gaRevR = gaRevR + aR * iRevSend
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
