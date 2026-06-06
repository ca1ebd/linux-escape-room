#!/bin/bash
# Puzzle 7 setup — runs as root.
# Asserts key6 exists, starts finalserver, drops briefing.
set -e

KEY6="/home/player/.game/keys/key6"
if [ ! -f "$KEY6" ]; then
    echo "setup: key6 not found — solve puzzle 6 first" >&2
    exit 1
fi

# Kill any existing instance
pkill -f finalserver.py 2>/dev/null || true
sleep 0.3

# Start server as player user (it only needs to listen on loopback)
nohup gosu player python3 /game/puzzles/07-networking/finalserver.py \
    >/tmp/finalserver.log 2>&1 &

sleep 0.5

# Drop briefing
NOTE="/home/player/puzzle7.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 7 — Networking & Sockets (FINAL)
========================================

A server is listening on localhost. Find it, connect to it, and
send the complete passphrase: all 7 fragments concatenated as one word.

Useful commands:
  ss -ltnp                          — list listening TCP ports
  nc 127.0.0.1 <port>               — connect with netcat
  exec 3<>/dev/tcp/127.0.0.1/<port> — connect via bash

Assemble your passphrase from ~/.game/keys/key1 through key6
plus whatever the server gives you last.

When the server accepts your passphrase, run: game check
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
