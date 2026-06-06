#!/bin/bash
set -e

# Run puzzle 1 setup (places secrets as root)
bash /game/puzzles/01-permissions/setup.sh

# Init game state if it doesn't exist yet (first boot)
STATE_FILE="/home/player/.game/state.json"
if [ ! -f "$STATE_FILE" ]; then
    # Run intro as the player user (it writes state to player's home)
    gosu player bash /game/intro.sh
fi

# Drop to player and start tmux session
exec gosu player tmux new-session -s game \
    -x "$(tput cols 2>/dev/null || echo 220)" \
    -y "$(tput lines 2>/dev/null || echo 50)"
