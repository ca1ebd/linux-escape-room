#!/usr/bin/env python3
"""Puzzle 6 validator — finds the maze file by its stored inode and reads the fragment."""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")

EXPECTED = "FOXTROT"
MAZE = Path("/srv/maze")
INODE_FILE = Path("/srv/maze_inode.txt")
KEY5 = Path.home() / ".game" / "keys" / "key5"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY5.exists():
        fail("key5 missing — complete puzzle 5 first.")
    if not INODE_FILE.exists():
        fail("Maze inode file missing. Try: game reset 6")
    if not MAZE.exists():
        fail("Maze directory missing. Try: game reset 6")

    target_inode = int(INODE_FILE.read_text().strip())

    # Find the file by inode — same technique the player uses
    result = subprocess.run(
        ["find", str(MAZE), "-inum", str(target_inode)],
        capture_output=True,
        text=True,
    )
    matches = [p for p in result.stdout.strip().splitlines() if p]

    if not matches:
        fail(f"No file with inode {target_inode} found in {MAZE}. Try: game reset 6")

    fragment = Path(matches[0]).read_text().strip()

    if fragment != EXPECTED:
        fail(f"File found but unexpected content: {fragment!r}. Maze may be corrupted.")

    print(fragment)


if __name__ == "__main__":
    main()
