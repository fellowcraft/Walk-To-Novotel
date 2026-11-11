#!/bin/sh
# from-min.sh — play or render a logged take starting MINUTES in.
# Usage: ./from-min.sh EVENTS_SCO MINUTES [-o out.wav -W -3 -d]
#   No -o: live to analog out (Pulse default). With -o: file render.
#   Grains overlapping the start point are kept (attack restarts there).
D="/mnt/b/CSOUND/Walk-To-Novotel"
SCO="$1"; MIN="$2"; shift 2
case "$SCO" in /*) ;; *) SCO="$PWD/$SCO";; esac
if [ ! -f "$SCO" ]; then
  CAND="$D/takes/$(basename "$SCO")"
  if [ -f "$CAND" ]; then SCO="$CAND"; else
    echo "from-min: take not found: $1 (also tried $CAND)" >&2; exit 1
  fi
fi
OFF=$(python3 -c "print($MIN*60)")
python3 - "$SCO" "$OFF" <<'EOF' > /tmp/opencode/aud-events.sco
import sys
off = float(sys.argv[2])
for l in open(sys.argv[1]):
    p = l.split()
    if not p or p[0] != 'i2':
        continue
    s, d = float(p[1]), float(p[2])
    if s + d > off - 20:
        p[1] = '%.9g' % max(s - off, 0)
        print(' '.join(p))
EOF
N=$(wc -l < /tmp/opencode/aud-events.sco)
echo "from-min: $N grains from minute $MIN (offset ${OFF}s)"
cp "$D/csd/Walk-To-Novotel27-recall-template.csd" /tmp/opencode/aud-tpl.csd
awk -v LOG=/tmp/opencode/aud-events.sco 'BEGIN{while((getline l<LOG)>0){if(l~/^i2 /){n=split(l,p);e=p[2]+p[3];if(e>max)max=e}};close(LOG)} /;__AMBISPAN__/{printf "i98 0 %.17g\n",max+4;next} /;__EVENTS__/{while((getline l<LOG)>0)print l;next}1' \
  /tmp/opencode/aud-tpl.csd > /tmp/opencode/audition.csd
exec csound "$@" /tmp/opencode/audition.csd
