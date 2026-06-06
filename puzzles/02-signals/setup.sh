#!/bin/bash
# Puzzle 2 setup — runs as root.
# Asserts key1 exists, then starts heartbeatd as the player user.
set -e

KEY1="/home/player/.game/keys/key1"
if [ ! -f "$KEY1" ]; then
    echo "setup: key1 not found — solve puzzle 1 first" >&2
    exit 1
fi

# Kill any existing instance
pkill -f heartbeatd.py 2>/dev/null || true

# Start the daemon as the player user (it reads key1 from player's home)
nohup gosu player python3 /game/puzzles/02-signals/heartbeatd.py \
    >/tmp/heartbeatd.log 2>&1 &

# Give it a moment to write its PID file
sleep 0.5

echo "heartbeatd started (pid $(cat /tmp/heartbeatd.pid 2>/dev/null || echo '?'))"
