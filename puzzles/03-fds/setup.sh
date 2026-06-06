#!/bin/bash
# Puzzle 3 setup — runs as root.
# Asserts key2 exists, installs whisper, places token file for player.
set -e

KEY2="/home/player/.game/keys/key2"
if [ ! -f "$KEY2" ]; then
    echo "setup: key2 not found — solve puzzle 2 first" >&2
    exit 1
fi

# Install whisper on PATH
install -m 755 /game/puzzles/03-fds/whisper.py /usr/local/bin/whisper

# Place the token file in the player's home — readable by player.
# The token IS key2's content; the player must wire it to fd 3.
TOKEN_FILE="/home/player/token.txt"
cp "$KEY2" "$TOKEN_FILE"
chown player:player "$TOKEN_FILE"
chmod 644 "$TOKEN_FILE"

# Drop a briefing note
NOTE="/home/player/puzzle3.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 3 — File Descriptors & Redirection
==========================================

The program `whisper` is finicky about its wiring:
  - It reads a token from file descriptor 3 (not stdin)
  - It writes the real answer to stderr (not stdout)
  - stdout is just noise

You have a token file at ~/token.txt.

Wire them together correctly and capture the answer.
When you have the fragment, run: game check
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
