#!/usr/bin/env python3
"""engined — reactive puzzle watcher daemon.

Polls the current puzzle's watch condition every second.
On completion: writes the key fragment, runs next puzzle's setup,
advances state, and notifies the player via their terminal.

Started automatically by entrypoint.sh. The player's tty is passed
as $GAME_TTY so notifications appear in their terminal.
"""

import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import puzzles as _puzzles
import state as _state
import timer as _timer

POLL_INTERVAL = 1.0
HOME = Path.home()
STATUS_CACHE = HOME / ".game" / "status_cache"

# Where to send notifications — written to by intro.sh
TTY_FILE = HOME / ".game" / "player_tty"


def _tty() -> str:
    tty = os.environ.get("GAME_TTY", "")
    if not tty and TTY_FILE.exists():
        tty = TTY_FILE.read_text().strip()
    return tty


def _notify(msg: str) -> None:
    """Write a message to the player's terminal."""
    text = f"\n\033[1m{msg}\033[0m\n"
    tty = _tty()
    if tty:
        try:
            with open(tty, "w") as f:
                f.write(text)
            return
        except OSError:
            pass
    sys.stdout.write(text)
    sys.stdout.flush()


def _tmux_popup(msg: str) -> None:
    try:
        subprocess.run(
            ["tmux", "display-message", "-d", "4000", msg],
            capture_output=True,
        )
    except FileNotFoundError:
        pass


def _run_setup(n: int) -> None:
    setup = _puzzles.get_setup(n)
    if setup.exists():
        subprocess.run(["sudo", str(setup)], capture_output=True)


def _on_complete(n: int, puzzle: dict) -> None:
    fragment = puzzle["fragment"]

    _state.write_key(n, fragment)
    s = _state.load()
    s = _state.add_fragment(s, n, fragment)

    if n == _puzzles.PUZZLE_COUNT:
        s = _state.set_completed(s)
        _state.save(s)
        _tmux_popup("YOU ESCAPED!")
        sys.exit(0)

    s = _state.advance_puzzle(s)
    _state.save(s)

    _run_setup(n + 1)

    clue = puzzle.get("clue", "")

    banner = (
        f"┌─────────────────────────────────────────┐\n"
        f"│  ✓ Unlocked!  Fragment: {fragment:<17}│\n"
        f"│                                         │\n"
        f"│  {clue:<41}│\n"
        f"└─────────────────────────────────────────┘"
    )
    _notify(banner)
    _tmux_popup("Fragment unlocked!")


def _update_status_cache(s: dict) -> None:
    """Write the status line to a cache file for instant tmux reads."""
    try:
        timer_str = _timer.format_timer(s)
        name = _state.get_player_name(s)
        hints = s["hints"]
        line = f" {name}  {timer_str}  hints:{hints} "
        STATUS_CACHE.write_text(line)
    except Exception:
        pass


def main() -> None:
    while True:
        try:
            s = _state.load()
        except (FileNotFoundError, Exception):
            time.sleep(POLL_INTERVAL)
            continue

        if s.get("completed"):
            STATUS_CACHE.write_text(" ESCAPED! ")
            sys.exit(0)

        _update_status_cache(s)

        n = _state.get_current_puzzle(s)

        # Already have the key — wait for state to catch up
        if _state.key_exists(n):
            time.sleep(POLL_INTERVAL)
            continue

        try:
            puzzle = _puzzles.get_puzzle(n)
            if _puzzles.watch_condition_met(puzzle, HOME):
                _on_complete(n, puzzle)
        except Exception:
            pass

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
