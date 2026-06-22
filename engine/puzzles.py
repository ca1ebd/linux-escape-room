#!/usr/bin/env python3
"""Ordered registry of puzzle metadata.

Each puzzle defines a 'watch' condition that engined polls every second.
When the condition is met, engined auto-advances — no 'game check' needed.

watch keys:
  file     — path (supports {home} substitution) that must exist
  contains — optional string the file must contain (stripped comparison)
"""

from pathlib import Path

PUZZLE_COUNT = 3

PUZZLES = [
    {
        "id": 1,
        "name": "Leave a Mark",
        "dir": "puzzles/01-hello",
        "fragment": "ALPHA",
        "clue": "A program only speaks when wired the right way.",
        "watch": {
            "file": "{home}/ready.txt",
            "contains": None,
        },
        "hints": [
            "The touch command creates an empty file: touch ~/ready.txt",
            "Or redirect anything into it: echo hi > ~/ready.txt",
        ],
    },
    {
        "id": 2,
        "name": "Words on the Wire",
        "dir": "puzzles/02-redirect",
        "fragment": "BRAVO",
        "clue": "Something is hiding where names don't matter.",
        "watch": {
            "file": "{home}/signal.txt",
            "contains": "open sesame",
        },
        "hints": [
            "Redirect stdout into a file with >: echo 'something' > ~/signal.txt",
            "The exact phrase matters. Try: echo 'open sesame' > ~/signal.txt",
        ],
    },
    {
        "id": 3,
        "name": "Hunt the Flag",
        "dir": "puzzles/03-find",
        "fragment": "CHARLIE",
        "clue": "",  # final puzzle
        "watch": {
            "file": "{home}/flag.txt",
            "contains": "CHARLIE",
        },
        "hints": [
            "find /srv/hidden -name flag.txt locates files by name recursively.",
            "Once you find it, copy it home: cp /path/to/flag.txt ~/flag.txt",
        ],
    },
]


def get_puzzle(n: int) -> dict:
    if not 1 <= n <= PUZZLE_COUNT:
        raise ValueError(f"Puzzle {n} out of range")
    return PUZZLES[n - 1]


def get_setup(n: int) -> Path:
    p = get_puzzle(n)
    return Path("/game") / p["dir"] / "setup.sh"


def watch_condition_met(puzzle: dict, home: Path) -> bool:
    """Return True if this puzzle's watch condition is satisfied."""
    watch = puzzle.get("watch", {})
    file_tmpl = watch.get("file")
    if not file_tmpl:
        return False

    target = Path(str(file_tmpl).replace("{home}", str(home)))
    if not target.exists():
        return False

    required_content = watch.get("contains")
    if required_content is None:
        return True

    return required_content in target.read_text()
