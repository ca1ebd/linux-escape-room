#!/usr/bin/env python3
"""Puzzle 3 validator — runs whisper with correct fd wiring and checks stderr output."""

import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, "/game/engine")

EXPECTED = "CHARLIE"
WHISPER = "/usr/local/bin/whisper"
TOKEN = Path.home() / "token.txt"
KEY2 = Path.home() / ".game" / "keys" / "key2"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY2.exists():
        fail("key2 missing — complete puzzle 2 first.")
    if not Path(WHISPER).exists():
        fail(f"{WHISPER} not found. Try: game reset 3")
    if not TOKEN.exists():
        fail(f"{TOKEN} not found. Try: game reset 3")

    with tempfile.NamedTemporaryFile(mode="r", suffix=".txt", delete=False) as tmp:
        tmpname = tmp.name

    try:
        # Invoke via shell to get the '3<' fd redirection the puzzle teaches
        result = subprocess.run(
            f"{WHISPER} 3< {TOKEN} 2> {tmpname} >/dev/null",
            shell=True,
        )
        fragment = Path(tmpname).read_text().strip()
    finally:
        Path(tmpname).unlink(missing_ok=True)

    if fragment != EXPECTED:
        fail(
            f"Wrong output from whisper stderr: {fragment!r}\n"
            "Make sure token.txt exists and you're wiring fd 3 and stderr correctly."
        )

    print(fragment)


if __name__ == "__main__":
    main()
