#!/usr/bin/env python3
"""Puzzle 4 validator — verifies the player has shadowed `verify` on PATH."""

import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")

EXPECTED = "CHARLIE"   # fragment 3
FRAGMENT = "DELTA"     # fragment 4
KEY3 = Path.home() / ".game" / "keys" / "key3"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY3.exists():
        fail("key3 missing — complete puzzle 3 first.")

    # Run `verify` with the player's current PATH
    result = subprocess.run(
        ["verify"],
        capture_output=True,
        text=True,
        env=os.environ,
    )

    output = result.stdout.strip()
    if output != EXPECTED:
        fail(
            f"`verify` returned {output!r}. Expected the fragment-3 value.\n"
            "Create your own verify script that prints the puzzle-3 fragment,\n"
            "then prepend its directory to PATH before running: game check"
        )

    print(FRAGMENT)


if __name__ == "__main__":
    main()
