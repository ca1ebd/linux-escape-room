#!/usr/bin/env python3
"""heartbeatd — signal-handling daemon for puzzle 2.

Listens for SIGUSR1 (correct) and SIGUSR2 (decoy/reset).
On SIGUSR1: writes fragment to /tmp/heartbeat.drop.
On SIGUSR2: removes the drop file (reset / decoy path).
Writes its PID to /tmp/heartbeatd.pid on start.
"""

import os
import signal
import sys
import time
from pathlib import Path

FRAGMENT = "BRAVO"
DROP_FILE = Path("/tmp/heartbeat.drop")
PID_FILE = Path("/tmp/heartbeatd.pid")
KEY1_PATH = Path("/home/player/.game/keys/key1")


def _assert_key1():
    if not KEY1_PATH.exists():
        sys.stderr.write("heartbeatd: key1 not found — puzzle 1 must be solved first\n")
        sys.exit(1)


def _on_sigusr1(signum, frame):
    DROP_FILE.write_text(FRAGMENT + "\n")
    DROP_FILE.chmod(0o644)


def _on_sigusr2(signum, frame):
    if DROP_FILE.exists():
        DROP_FILE.unlink()


def main():
    _assert_key1()

    PID_FILE.write_text(str(os.getpid()) + "\n")
    PID_FILE.chmod(0o644)

    signal.signal(signal.SIGUSR1, _on_sigusr1)
    signal.signal(signal.SIGUSR2, _on_sigusr2)

    # Run until killed
    while True:
        time.sleep(60)


if __name__ == "__main__":
    main()
