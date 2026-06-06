#!/usr/bin/env python3
"""Puzzle 1 validator — runs as the player user.

Invokes the setuid binary /usr/local/bin/unlock1 open and checks its output
matches the known fragment. Prints the fragment to stdout on success.
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")
import state as _state

EXPECTED = "ALPHA"
BINARY = "/usr/local/bin/unlock1"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not Path(BINARY).exists():
        fail(f"Binary not found: {BINARY}. Try: game reset 1")

    result = subprocess.run([BINARY, "open"], capture_output=True, text=True)
    if result.returncode != 0:
        fail(f"unlock1 failed: {result.stderr.strip()}")

    fragment = result.stdout.strip()
    if fragment != EXPECTED:
        fail("Unexpected output from unlock1. Something is wrong.")

    print(fragment)


if __name__ == "__main__":
    main()
