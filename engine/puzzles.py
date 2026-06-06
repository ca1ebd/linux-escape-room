#!/usr/bin/env python3
"""Ordered registry of puzzle metadata."""

from pathlib import Path

PUZZLE_COUNT = 7

PUZZLES = [
    {
        "id": 1,
        "name": "Permissions & Setuid",
        "dir": "puzzles/01-permissions",
        "clue": "A heartbeat process is listening for a signal.",
        "hints": [
            "Special permission bits exist beyond the usual rwx. Try: find / -perm -4000 -type f 2>/dev/null",
            "You found a setuid binary. ls -l shows 's' in the owner-execute position. Who owns it?",
            "The source is at /usr/local/src/unlock1.c — read it to learn what argument the binary expects.",
        ],
    },
    {
        "id": 2,
        "name": "Processes & Signals",
        "dir": "puzzles/02-signals",
        "clue": "A program only speaks on the right wires (file descriptors).",
        "hints": [
            "A daemon named heartbeatd is running. Find it: ps -ef | grep heartbeatd, or pgrep -a heartbeatd.",
            "Signals are how processes communicate. kill -USR1 <pid> sends SIGUSR1.",
            "After sending the right signal, check /tmp/heartbeat.drop for the fragment.",
        ],
    },
    {
        "id": 3,
        "name": "File Descriptors & Redirection",
        "dir": "puzzles/03-fds",
        "clue": "The way out depends on what PATH finds first.",
        "hints": [
            "The whisper program reads from file descriptor 3. Use 3< to open a file on that fd.",
            "The answer goes to stderr, not stdout. Redirect: 2> answer.txt to capture it.",
            "Full command shape: whisper 3< token.txt 2> answer.txt >/dev/null",
        ],
    },
    {
        "id": 4,
        "name": "Environment & PATH",
        "dir": "puzzles/04-path",
        "clue": "7,000 log lines, one anomaly. The anomaly contains a hidden field.",
        "hints": [
            "echo $PATH shows the search order. Directories earlier in the list win.",
            "Create your own verify script in a directory, then prepend that directory to PATH.",
            "export PATH=/tmp/mydir:$PATH makes your verify run instead of the system one.",
        ],
    },
    {
        "id": 5,
        "name": "Text Processing & Regex",
        "dir": "puzzles/05-textproc",
        "clue": "The next clue has no name, only a number.",
        "hints": [
            "The log is at /srv/logs/access.log. Use grep -E to filter with extended regex.",
            "grep -E '<pattern>' access.log | awk '{print $NF}' extracts a field.",
            "Look for lines where the HTTP status code is unusual (not 200/301/404).",
        ],
    },
    {
        "id": 6,
        "name": "Links & Inodes",
        "dir": "puzzles/06-inodes",
        "clue": "A service is listening on port 7777. Go knock.",
        "hints": [
            "Every file has an inode number. ls -i shows it; stat shows more detail.",
            "find /srv/maze -inum <number> finds the file by inode, ignoring its name.",
            "If the file is deleted but a process still has it open, /proc/<pid>/fd/<n> is a live handle.",
        ],
    },
    {
        "id": 7,
        "name": "Networking & Sockets",
        "dir": "puzzles/07-networking",
        "clue": "",  # Final puzzle — no next clue
        "hints": [
            "ss -ltnp shows listening TCP ports. Look for the port from fragment 6.",
            "Connect with: nc 127.0.0.1 <port>  or  exec 3<>/dev/tcp/127.0.0.1/<port>",
            "The server will tell you your final fragment. Concatenate all 7 fragments and send them back.",
        ],
    },
]


def get_puzzle(n: int) -> dict:
    if not 1 <= n <= PUZZLE_COUNT:
        raise ValueError(f"Puzzle {n} out of range")
    return PUZZLES[n - 1]


def get_validator(n: int) -> Path:
    p = get_puzzle(n)
    base = Path("/game") / p["dir"]
    for name in ("check.py", "check.sh"):
        candidate = base / name
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"No validator found for puzzle {n} in {base}")


def get_setup(n: int) -> Path:
    p = get_puzzle(n)
    return Path("/game") / p["dir"] / "setup.sh"
