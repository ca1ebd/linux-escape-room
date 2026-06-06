#!/usr/bin/env python3
"""Puzzle 7 validator — verifies the player connected to finalserver with the correct passphrase."""

import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")

FRAGMENT7 = "GOLF"
SUCCESS_FLAG = Path("/tmp/final_success")
KEY6 = Path.home() / ".game" / "keys" / "key6"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY6.exists():
        fail("key6 missing — complete puzzle 6 first.")

    if not SUCCESS_FLAG.exists():
        fail(
            "No successful connection recorded yet.\n"
            "Find the server (ss -ltnp), connect to it (nc 127.0.0.1 7777),\n"
            "and send the full passphrase (all fragments concatenated)."
        )

    print(FRAGMENT7)


if __name__ == "__main__":
    main()
