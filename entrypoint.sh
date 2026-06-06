#!/bin/bash
set -e

# Run puzzle 1 setup as root (places artifacts)
bash /game/puzzles/01-hello/setup.sh

# Init game state if this is a fresh container
STATE_FILE="/home/player/.game/state.json"
if [ ! -f "$STATE_FILE" ]; then
    gosu player bash /game/intro.sh
fi

# Drop to player and start tmux session
exec gosu player tmux new-session -s game \
    -x "$(tput cols 2>/dev/null || echo 220)" \
    -y "$(tput lines 2>/dev/null || echo 50)"
