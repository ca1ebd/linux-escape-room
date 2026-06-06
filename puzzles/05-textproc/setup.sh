#!/bin/bash
# Puzzle 5 setup — runs as root.
# Asserts key4 exists, generates the access log, drops a briefing.
set -e

KEY4="/home/player/.game/keys/key4"
if [ ! -f "$KEY4" ]; then
    echo "setup: key4 not found — solve puzzle 4 first" >&2
    exit 1
fi

# Generate the log (idempotent — deterministic output)
python3 /game/puzzles/05-textproc/gen_log.py /srv/logs/access.log

# Player can read the log but not write it
chmod 644 /srv/logs/access.log

# Drop a briefing note
NOTE="/home/player/puzzle5.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 5 — Text Processing & Regex
====================================

A web server has been logging 7,000 requests to /srv/logs/access.log.
Most are routine. One line is anomalous — it contains an HTTP status
code you'd never see in normal traffic, and a hidden extra field at
the end that is the fragment you need.

Useful commands:
  grep -E '<pattern>' /srv/logs/access.log
  awk '{print $NF}'            — print the last field of each line
  sort | uniq -c               — count unique values
  wc -l                        — count lines

When you have the fragment, run: game check
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
