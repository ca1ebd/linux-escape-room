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

echo "  7 puzzles. One escape. Good luck."
echo ""
echo "  Target: a developer who uses Linux daily but hasn't gone deep."
echo "  Commands: game check | game hint | game status | game reset"
echo ""
echo "──────────────────────────────────────────────────────────────"
echo ""

# ── Timer configuration ────────────────────────────────────────────────────────

TIMER_ENABLED=true
DURATION_SEC=2700

# Non-interactive overrides
if [ "${GAME_TIMER:-}" = "off" ]; then
    TIMER_ENABLED=false
fi
if [ -n "${GAME_DURATION:-}" ]; then
    DURATION_SEC="$GAME_DURATION"
fi

# Interactive prompt (only when stdin is a terminal and no env override)
if $TIMER_ENABLED && [ -z "${GAME_TIMER:-}" ] && [ -t 0 ]; then
    read -r -p "  Enable countdown timer? [Y/n] " answer
    case "$answer" in
        [nN]*) TIMER_ENABLED=false ;;
    esac
fi

if $TIMER_ENABLED && [ -z "${GAME_DURATION:-}" ] && [ -t 0 ]; then
    echo "  Default: 45 minutes. Enter duration in minutes, or press Enter to keep default."
    read -r -p "  Duration [45]: " mins
    if [ -n "$mins" ] && [ "$mins" -eq "$mins" ] 2>/dev/null; then
        DURATION_SEC=$(( mins * 60 ))
    fi
fi

echo ""
if $TIMER_ENABLED; then
    echo "  Timer: ON — $(( DURATION_SEC / 60 )) minutes"
else
    echo "  Timer: OFF"
fi
echo ""

# ── State initialisation ───────────────────────────────────────────────────────

if ! $NO_RESET; then
    TIMER_FLAG=""
    $TIMER_ENABLED || TIMER_FLAG="--no-timer"
    python3 /game/engine/state.py init $TIMER_FLAG --duration "$DURATION_SEC" > /dev/null
fi

# ── Inject PS1 shortcut into .bashrc (idempotent) ─────────────────────────────

BASHRC="$HOME/.bashrc"
if ! grep -q 'game status --short' "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'EOF'

# escape-linux: compact game status in prompt
_game_ps1() { python3 /game/engine/cli.py status --short 2>/dev/null; }
export PS1='\[$(_game_ps1)\] \u@escape:\w\$ '
EOF
fi

# ── Puzzle 1 briefing ──────────────────────────────────────────────────────────

echo "──────────────────────────────────────────────────────────────"
echo ""
echo "  PUZZLE 1 of 7 — Permissions & Setuid"
echo ""
echo "  Linux file permissions go deeper than rwx. Some binaries carry"
echo "  a special bit that lets them run with elevated privileges — even"
echo "  when you invoke them as an unprivileged user."
echo ""
echo "  Somewhere on this system is a root-owned binary with that special"
echo "  bit set. Find it, understand it, and make it reveal the first"
echo "  key fragment."
echo ""
echo "  When you have the fragment, run:  game check"
echo ""
echo "──────────────────────────────────────────────────────────────"
echo ""
