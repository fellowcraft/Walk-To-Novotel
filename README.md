# Walk-To-Novotel

Generative hour-long Csound piece. A conductor instrument schedules
pitched stereo grains (`diskin2`) from `Media/Walk-To-Novotel.wav`, each with
its own pitch wobble, random direction, and sine-modulated bounds, into a
global `reverbsc` bus.

Current version: `csd/Walk-To-Novotel23.csd` (engine ported from
Rain-Over-Slaughterhouse19: ring modulator in parallel, wet/dry
random per grain (20..80% wet),
independent sine autopan per side (1..8 cycles per grain),
per-grain reverb, halved send, Pulse/analog-out default; only
REAPER touches the Scarlett).

## Layout

- `csd/` — numbered versions + recall templates (read-only history)
- `takes/` — take event logs (`.sco`, the actual performances), counters
- `scripts/` — `run-take.sh`, `from-min.sh`, `latest.sh`, `next-take.sh`
- `rpp/` — REAPER projects
- `Media/` — source audio (**not in git**, local only)

## Use

New take, live: `./scripts/run-take.sh`
New take to file: `./scripts/run-take.sh -o takes/Walk-To-Novotel01-takeNN.wav -W -3 -d`
Replay a take: `./scripts/run-take.sh takes/Walk-To-Novotel01-takeNN-events.sco [-o ...]`
Audition from minute M: `./scripts/from-min.sh takes/<take>.sco M [-o ...]`
Follow newest file: `./scripts/latest.sh`

## Recall

Takes are bit-identical: the event log plus the version's `.csd`
re-renders the take exactly (verified md5).

## REAPER

`rpp/Walk-To-Novotel-Ambisonic.RPP` plays take01 two ways: track 1 is
the stereo render as monitored; track 2 (muted) decodes the 4ch AmbiX
file to stereo through the bundled JSFX (`rpp/jsfx/`, also installed
under `~/.config/REAPER/Effects/`). For true headphone 3D, install IEM
BinauralDecoder, put it after the JSFX on track 2, bypass the JSFX,
unmute track 2 and mute track 1.

## Ambisonics

Recall also renders first-order AmbiX (W,Y,Z,X; SN3D; elevation 0;
frontal stage from the pan LFOs) to
`takes/Walk-To-Novotel24-recall-ambi.wav` (fixed name, overwritten per
recall). Live/generate stays stereo — ambisonics is a recall product.
Use the awk line in the `.csd` header to assemble; audition renders
(`from-min.sh`) skip the ambi file.

Requires Csound 6.18, sox (`soxi`, `stats`).
