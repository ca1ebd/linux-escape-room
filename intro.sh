#!/bin/bash
# Onboarding / welcome screen.
# Usage: intro.sh            — full init (first boot)
#        intro.sh --no-reset — re-display welcome without reinitialising state

set -e

NO_RESET=false
for arg in "$@"; do
    [ "$arg" = "--no-reset" ] && NO_RESET=true
done

clear
cat <<'BANNER'

  ███████╗███████╗ ██████╗ █████╗ ██████╗ ███████╗
  ██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝
  █████╗  ███████╗██║     ███████║██████╔╝█████╗
  ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔══╝
  ███████╗███████║╚██████╗██║  ██║██║     ███████╗
  ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚══════╝

         ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
         ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
         ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
         ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
         ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
         ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝

BANNER

echo "  Good luck."
echo ""
echo "  Commands: game hint | game status | game reset | game pause"
echo ""
echo "──────────────────────────────────────────────────────────────"
echo ""

# ── Player name ────────────────────────────────────────────────────────────────

PLAYER_NAME="player"
if ! $NO_RESET && [ -t 0 ]; then
    read -r -p "  Your name: " input_name
    if [ -n "$input_name" ]; then
        PLAYER_NAME="$input_name"
    fi
elif $NO_RESET; then
    PLAYER_NAME=$(python3 /game/engine/state.py get player_name 2>/dev/null || echo "player")
fi

echo ""

# ── Timer configuration ────────────────────────────────────────────────────────

TIMER_ENABLED=true
DURATION_SEC=3600  # 60 minutes, not configurable

if [ "${GAME_TIMER:-}" = "off" ]; then
    TIMER_ENABLED=false
fi

if $TIMER_ENABLED && [ -z "${GAME_TIMER:-}" ] && [ -t 0 ]; then
    read -r -p "  Enable countdown timer? [Y/n] " answer
    case "$answer" in
        [nN]*) TIMER_ENABLED=false ;;
    esac
fi

echo ""
if $TIMER_ENABLED; then
    echo "  Timer: ON — 60 minutes"
else
    echo "  Timer: OFF"
fi
echo ""

# ── State initialisation ───────────────────────────────────────────────────────

if ! $NO_RESET; then
    TIMER_FLAG=""
    $TIMER_ENABLED || TIMER_FLAG="--no-timer"
    python3 /game/engine/state.py init \
        --name "$PLAYER_NAME" \
        $TIMER_FLAG \
        --duration "$DURATION_SEC" > /dev/null

    # Record the player's tty so engined can write notifications there
    mkdir -p "$HOME/.game"
    tty > "$HOME/.game/player_tty" 2>/dev/null || true
fi

# ── PS1 — plain prompt with player name ───────────────────────────────────────

BASHRC="$HOME/.bashrc"
if ! grep -q 'escape-linux prompt' "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<EOF

# escape-linux prompt
export PS1='${PLAYER_NAME}@escape:\w\$ '
EOF
fi

# ── Start engined if not already running ───────────────────────────────────────

if ! pgrep -f engined.py > /dev/null 2>&1; then
    GAME_TTY=$(cat "$HOME/.game/player_tty" 2>/dev/null || tty) \
        nohup python3 /game/engine/engined.py \
        > "$HOME/.game/engined.log" 2>&1 &
fi

# ── Puzzle 1 briefing ──────────────────────────────────────────────────────────

echo "──────────────────────────────────────────────────────────────"
echo ""
echo "  Every action on a Linux system leaves a trace."
echo "  Your first task: create a file called ready.txt"
echo "  in your home directory."
echo ""
echo "  The game will notice automatically."
echo ""
echo "──────────────────────────────────────────────────────────────"
echo ""
