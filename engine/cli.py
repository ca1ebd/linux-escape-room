#!/usr/bin/env python3
"""game CLI — the player's control surface.

Puzzles complete automatically when their watch condition is met.
No 'game check' needed — just do the thing.
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import state as _state
import puzzles as _puzzles
import timer as _timer


def _die(msg: str, code: int = 1) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(code)


def _require_state() -> dict:
    try:
        return _state.load()
    except FileNotFoundError:
        _die("No game state found. Run: game intro")


def cmd_status(args: list[str]) -> None:
    try:
        s = _state.load()
    except FileNotFoundError:
        print("[no game] run: game intro")
        return

    timer_str = _timer.format_timer(s)
    name = _state.get_player_name(s)
    hints = s["hints"]

    print(f" {name}  {timer_str}  hints:{hints}")


def cmd_hint(args: list[str]) -> None:
    s = _require_state()
    n = _state.get_current_puzzle(s)
    puzzle = _puzzles.get_puzzle(n)
    hints_used = s["hints"]
    available = puzzle["hints"]

    if hints_used >= len(available):
        print("No more hints for this puzzle.")
        return

    hint = available[hints_used]
    s = _state.add_hint(s)
    _state.save(s)
    print(f"Hint {hints_used + 1}: {hint}")


def cmd_reset(args: list[str]) -> None:
    s = _require_state()
    n = int(args[0]) if args else _state.get_current_puzzle(s)
    setup = _puzzles.get_setup(n)
    if not setup.exists():
        _die(f"No setup.sh for puzzle {n}")
    subprocess.run(["sudo", str(setup)], check=True)
    print(f"Puzzle {n} reset.")


def cmd_pause(args: list[str]) -> None:
    s = _require_state()
    s = _timer.pause(s)
    _state.save(s)
    print("Timer paused.")


def cmd_resume(args: list[str]) -> None:
    s = _require_state()
    s = _timer.resume(s)
    _state.save(s)
    print("Timer resumed.")


def cmd_intro(args: list[str]) -> None:
    subprocess.run(["bash", "/game/intro.sh", "--no-reset"])


COMMANDS = {
    "status": cmd_status,
    "hint": cmd_hint,
    "reset": cmd_reset,
    "pause": cmd_pause,
    "resume": cmd_resume,
    "intro": cmd_intro,
}

USAGE = """\
usage: game <command> [args]

commands:
  status          show current puzzle and timer
  hint            get a hint for the current puzzle
  reset [N]       re-run setup for puzzle N (default: current)
  pause / resume  timer control
  intro           replay the welcome screen

Puzzles complete automatically — just do the thing.
"""


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(USAGE)
        return

    cmd = args[0]
    if cmd not in COMMANDS:
        _die(f"Unknown command '{cmd}'. Run 'game --help' for usage.")

    COMMANDS[cmd](args[1:])


if __name__ == "__main__":
    main()
