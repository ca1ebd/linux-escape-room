#!/usr/bin/env python3
"""Puzzle 2 validator — checks /tmp/heartbeat.drop for the correct fragment."""

import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")
import state as _state

EXPECTED = "BRAVO"
DROP_FILE = Path("/tmp/heartbeat.drop")
KEY1 = Path.home() / ".game" / "keys" / "key1"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY1.exists():
        fail("key1 missing — complete puzzle 1 first.")

    if not DROP_FILE.exists():
        fail(
            "No fragment found yet.\n"
            "Hint: find the heartbeatd process and send it the right signal.\n"
            "  ps -ef | grep heartbeatd\n"
            "  kill -USR1 <pid>"
        )

    fragment = DROP_FILE.read_text().strip()
    if fragment != EXPECTED:
        fail(f"Wrong fragment in drop file: {fragment!r}")

    print(fragment)


if __name__ == "__main__":
    main()
