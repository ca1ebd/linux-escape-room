#!/bin/bash
# Puzzle 2 setup — asserts key1 exists, drops a briefing.
set -e

KEY1="/home/player/.game/keys/key1"
if [ ! -f "$KEY1" ]; then
    echo "setup: key1 not found — puzzle 1 must be solved first" >&2
    exit 1
fi

rm -f /home/player/signal.txt

NOTE="/home/player/puzzle2.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 2 — Words on the Wire
==============================

stdout redirection lets you send a program's output to a file.
The syntax is:  command > filename

Write exactly this phrase to ~/signal.txt:
  open sesame

The game will notice automatically.
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
