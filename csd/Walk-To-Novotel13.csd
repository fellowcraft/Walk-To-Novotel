<CsoundSynthesizer>
<CsOptions>
-+rtaudio=pulse -o dac -d ; policy: REAPER owns the Scarlett on ALSA,
; everything else plays the current Pulse default sink (analog out)
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

; Walk-To-Novotel13 — changes vs 12: ring-mod carrier 0.1..120 Hz
; (was 5..80). Otherwise same.
; scheduled grain to a per-take log Walk-To-Novotel13-takeNN-events.sco (NN = 01, 02, ...;
; next number picked automatically each run) (start dur ampDb skip
; carrPeriod revSend phase flip panPerL panPhsL panPerR panPhsR
; pieceLen wetMix, full %.17g precision). Grain phase moved to the
; conductor so NOTHING is random inside instr 2: the log plus the recall
; template fully reproduces a take. Assembly:
; Launch takes ONLY via run-take.sh (plain csound run fails: no $TAKE).
; Recall assembly for take NN (e.g. NN=take01):
; awk '/;__EVENTS__/{while((getline l<"/mnt/b/CSOUND/Walk-To-Novotel/takes/Walk-To-Novotel13-take01-events.sco")>0)print l;next}1' /mnt/b/CSOUND/Walk-To-Novotel/csd/Walk-To-Novotel13-recall-template.csd > /mnt/b/CSOUND/Walk-To-Novotel/takes/Walk-To-Novotel13-recall-take01.csd
; Conductor (instr 1) schedules grains (instr 2), each with its own reverb.
; Change iTotal in the score to change piece length; LFO periods follow p3.
; Take number seeds the PRNG: same take always identical, new take new piece.
; MODES (run-take.sh picks correctly; direct csound needs the macros below):
; generate: --omacro:TAKE=N  (logs takeNN, playback include stays empty)
; playback: --omacro:PLAYBACK=1 with Walk-To-Novotel13-playback-events.sco holding
;   the take (run-take.sh copies it there automatically)

#ifdef PLAYBACK
instr 1 ; stub: playback mode, grains come from the score include
  turnoff
endin
#else
instr 1 ; conductor
  iTotal = p3
  ; --- take log: launch via run-take.sh, which passes --omacro:TAKE=N ---
#ifdef TAKE
  iTake = $TAKE
  STakeLog sprintf "/mnt/b/CSOUND/Walk-To-Novotel/takes/Walk-To-Novotel13-take%02d-events.sco", iTake
  giLog fiopen STakeLog, 0
  printf_i "Walk-To-Novotel13 take %02d logging to %s\n", 1, iTake, STakeLog
#end ; TAKE
  ; --- take seed: run-take.sh passes --omacro:TAKE=N (different take,
  ; different performance; same N replays the same take via its log) ---
#ifdef TAKE
  seed $TAKE
#else
  seed 12345
#end ; TAKE
  iFileLen = 437.69 ; Media/Walk-To-Novotel.wav, stereo 48k
  iTwoPi = 6.2831853

  kT timeinsts ; seconds since this note started

  ; --- modulators: one sine each, periods locked to piece length ---
  kDens   oscil3 1, 4 / iTotal, 1            ; 4 cycles per piece
  kSin2T  oscil3 1, 2 / iTotal, 1, 0           ; 2 cycles
  kSin3T  oscil3 1, 3 / iTotal, 1, 0.5        ; 3 cycles
  kSin5T  oscil3 1, 5 / iTotal, 1, 0.75       ; 5 cycles
  kSinH   oscil3 1, 2 / iTotal, 1, 0.125      ; reverb: 2 cycles (period T/2)

  ; --- event density: ~0.02..0.26 grains/sec, 4 sine breaths per hour ---
  ; troughs (~1-2 overlapping grains) alternate with peaks (~4-16 voices)
  kRate = 0.14 + 0.12 * kDens
  kTrig metro kRate

  ; --- per-grain bounds, all time-varying ---
  kDurLo = 60 + 10 * kSin3T                  ; 50..70 s
  kDurHi = 105 + 15 * kSin5T                 ; 90..120 s
  kDur random kDurLo, kDurHi
  kDurQ = (int(kDur * sr + 0.5) + 0.5) / sr ; half-sample offset:
                                      ; keeps D*sr AND D*750 clear of integers,
                                      ; so generate and recall agree on note ends

  kAmpHi = -5.1 + 4 * kSin3T                 ; -9.1..-1.1 dB
  kAmpW  = 28 + 8 * (0.5 + 0.5 * kSin5T)     ; width 28..36 dB
  kAmpDb random kAmpHi - kAmpW, kAmpHi

  kWobPeriod random 20, 600                 ; carrier drift period 20 s..10 min, independent each grain

  kRevCtr = 0.55 + 0.3 * kSinH                ; 0.25..0.85, period T/2
  kRevRnd random -1, 1
  kRevSend = limit(kRevCtr + 0.25 * kRevRnd, 0, 0.95) * 0.5 ; halved send

  ; forwards only: grain must fit from skip to end of file
  kSkipMax = iFileLen - kDurQ - 0.1
  kSkipMin = 0
  if kSkipMax < kSkipMin then
    kSkipMax = kSkipMin
  endif
  kSkip random kSkipMin, kSkipMax
  kFlipRnd random 0, 1
  kFlip = kFlipRnd < 0.5 ? 0 : 1 ; 1 = swap L/R for this grain
  kPhs random 0, 1 ; wobble start phase, logged so takes recall exactly
  kPanNumL random 1, 8 ; oscillations per grain per side, logged
  kPanPhsL random 0, 1
  kPanNumR random 1, 8
  kPanPhsR random 0, 1
  kPanPerL = kDurQ / kPanNumL ; period follows grain length (1..8 cycles)
  kPanPerR = kDurQ / kPanNumR
  kWetMix random 0.2, 0.8 ; ring-mod wet proportion per grain, logged

  ; snap start to the next k-cycle grid point and schedule exactly there,
  ; so live placement == logged time == recall placement, bit for bit
  kK = int(kT * 750)
  kTq = kK / 750
  if kTq < kT then
    kTq = (kK + 1) / 750
  endif

  if kTrig == 1 then
#ifdef TAKE
    fprintks giLog, "i2 %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g %.17g\n", kTq, kDurQ, kAmpDb, kSkip, kWobPeriod, kRevSend, kPhs, kFlip, kPanPerL, kPanPhsL, kPanPerR, kPanPhsR, iTotal, kWetMix
#end ; TAKE
  endif

  schedkwhen kTrig, 0, 0, 2, kTq - kT, kDurQ, kAmpDb, kSkip, kWobPeriod, kRevSend, kPhs, kFlip, kPanPerL, kPanPhsL, kPanPerR, kPanPhsR, iTotal, kWetMix
endin
#end ; PLAYBACK conductor selection

instr 3 ; log closer, scheduled once at score end (generate mode only)
#ifdef TAKE
  kCl timeinsts
  if kCl < 0.002 then
    ficlose giLog
  endif
#end ; TAKE
endin

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
#include "/mnt/b/CSOUND/Walk-To-Novotel/takes/Walk-To-Novotel13-playback-events.sco"
i1 0 3600
i3 3606.5 0.5
</CsScore>
</CsoundSynthesizer>
