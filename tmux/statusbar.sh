#!/bin/bash
# Render the status line from state.json.
# Called every second by tmux status-left.
python3 /game/engine/cli.py status 2>/dev/null || echo "[ESCAPE-LINUX] (no state)"
