#!/usr/bin/env python3
"""whisper — fd puzzle program.

Reads a token from fd 3. If the token matches key2's content, writes
the fragment to stderr. Prints misleading noise to stdout regardless.
"""

import os
import sys
from pathlib import Path

FRAGMENT = "CHARLIE"
KEY2_PATH = Path("/home/player/.game/keys/key2")


def main() -> None:
    # Always print noise to stdout
    print("Nothing to see here. Move along.")

    # Read the token from fd 3
    try:
        with os.fdopen(3, "r") as fd3:
            token = fd3.read().strip()
    except OSError:
        print("whisper: no data on fd 3. Try: whisper 3< token.txt", file=sys.stderr)
        sys.exit(1)

    # Validate against key2
    if not KEY2_PATH.exists():
        print("whisper: key2 not found — solve puzzle 2 first.", file=sys.stderr)
        sys.exit(1)

    expected_token = KEY2_PATH.read_text().strip()
    if token != expected_token:
        print("whisper: wrong token.", file=sys.stderr)
        sys.exit(1)

    # The real answer goes only to stderr
    print(FRAGMENT, file=sys.stderr)


if __name__ == "__main__":
    main()
