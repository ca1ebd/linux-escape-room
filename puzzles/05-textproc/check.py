#!/usr/bin/env python3
"""Puzzle 5 validator — finds the anomalous log line and extracts the fragment."""

import re
import sys
from pathlib import Path

sys.path.insert(0, "/game/engine")

EXPECTED = "ECHO"
LOG_FILE = Path("/srv/logs/access.log")
KEY4 = Path.home() / ".game" / "keys" / "key4"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not KEY4.exists():
        fail("key4 missing — complete puzzle 4 first.")
    if not LOG_FILE.exists():
        fail(f"{LOG_FILE} not found. Try: game reset 5")

    # Find lines with a non-standard HTTP status (not 200, 301, 302, 304, 404, 500)
    standard = {200, 201, 204, 301, 302, 304, 400, 401, 403, 404, 500, 502, 503}
    anomalies = []
    for line in LOG_FILE.read_text().splitlines():
        # Apache combined log format: status is field 9 (0-indexed field 8)
        parts = line.split()
        if len(parts) >= 9:
            try:
                status = int(parts[8])
                if status not in standard:
                    anomalies.append((status, parts))
            except ValueError:
                pass

    if not anomalies:
        fail("No anomalous log line found. Has the log been modified?")

    # Extract the last field of the anomalous line — that's the fragment
    _, parts = anomalies[0]
    fragment = parts[-1]

    if fragment != EXPECTED:
        fail(f"Fragment extracted from log: {fragment!r} — unexpected value.")

    print(fragment)


if __name__ == "__main__":
    main()
