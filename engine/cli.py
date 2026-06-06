#!/usr/bin/env python3
"""game CLI — the player's control surface."""

import subprocess
import sys
from pathlib import Path

# Engine lives at /game/engine/; add it to path when invoked as a script
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


# ── subcommands ────────────────────────────────────────────────────────────────

def cmd_status(args: list[str]) -> None:
    short = "--short" in args
    try:
        s = _state.load()
    except FileNotFoundError:
        print("[no game] run: game intro")
        return

    n = _state.get_current_puzzle(s)
    total = s["total_puzzles"]
    puzzle = _puzzles.get_puzzle(n)
    frags = len(s["fragments"])
    pct = int(frags / total * 100)
    bar_filled = frags
    bar_empty = total - frags
    bar = "█" * bar_filled + "░" * bar_empty
    timer_str = _timer.format_timer(s)
    hints = s["hints"]

    if short:
        print(f"[{n}/{total} {timer_str}]", end="")
        return

    print(
        f"[ESCAPE-LINUX]  Puzzle {n}/{total}: {puzzle['name']}"
        f"  {bar} {pct}%  {timer_str}  hints:{hints}"
    )


def cmd_check(args: list[str]) -> None:
    s = _require_state()
    n = _state.get_current_puzzle(s)

    if n > 1 and not _state.key_exists(n - 1):
        _die(f"Complete puzzle {n-1} first (key{n-1} missing).")

    try:
        validator = _puzzles.get_validator(n)
    except FileNotFoundError as e:
        _die(str(e))

    # Run the validator as the current user
    cmd = ["python3", str(validator)] if str(validator).endswith(".py") else [str(validator)]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        print(f"\nPuzzle {n} check failed. Keep trying!")
        sys.exit(1)

    fragment = result.stdout.strip()
    if not fragment:
        _die("Validator exited 0 but printed no fragment. Bug in check script.")

    _state.write_key(n, fragment)
    s = _state.add_fragment(s, n, fragment)

    if n == _puzzles.PUZZLE_COUNT:
        s = _state.set_completed(s)
        _state.save(s)
        _run_victory()
        return

    s = _state.advance_puzzle(s)
    _state.save(s)

    # Run next puzzle's setup as root
    setup = _puzzles.get_setup(n + 1)
    if setup.exists():
        subprocess.run(["sudo", str(setup)], check=True)

    next_puzzle = _puzzles.get_puzzle(n + 1)
    print(f"\n*** Puzzle {n} complete! Fragment: {fragment} ***\n")
    print(f"Clue for puzzle {n+1}: {_puzzles.get_puzzle(n)['clue']}\n")
    print(f"Next up — Puzzle {n+1}: {next_puzzle['name']}")


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


def _run_victory() -> None:
    victory = Path("/game/engine/victory.py")
    if victory.exists():
        subprocess.run(["python3", str(victory)])
    else:
        print("\n" + "=" * 60)
        print("  ESCAPED! Congratulations!")
        print("=" * 60)


# ── dispatch ───────────────────────────────────────────────────────────────────

COMMANDS = {
    "status": cmd_status,
    "check": cmd_check,
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
  check           validate the current puzzle
  hint            get a hint for the current puzzle
  reset [N]       re-run setup for puzzle N (default: current)
  pause / resume  timer control
  intro           replay the welcome screen
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
