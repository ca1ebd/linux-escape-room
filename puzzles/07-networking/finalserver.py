#!/usr/bin/env python3
"""finalserver — TCP server for puzzle 7.

Listens on 127.0.0.1:7777. Challenges the client to send the
full passphrase (all 7 fragments concatenated). On success, writes
a flag file and returns the ESCAPE CODE. Stays running so check.py
can independently verify.
"""

import socketserver
import sys
from pathlib import Path

PORT = 7777
HOST = "127.0.0.1"

FRAGMENTS = ["ALPHA", "BRAVO", "CHARLIE", "DELTA", "ECHO", "FOXTROT", "GOLF"]
PASSPHRASE = "".join(FRAGMENTS)
FRAGMENT7 = "GOLF"
ESCAPE_CODE = "ESCAPED"
SUCCESS_FLAG = Path("/tmp/final_success")

KEY6 = Path("/home/player/.game/keys/key6")

BANNER = (
    "=== FINAL CHALLENGE ===\n"
    "You've reached the last gate.\n"
    "Concatenate all 7 fragments and send them as a single line.\n"
    "> "
)


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(BANNER.encode())
        self.wfile.flush()
        try:
            line = self.rfile.readline().decode().strip()
        except Exception:
            return

        if line == PASSPHRASE:
            SUCCESS_FLAG.write_text("1")
            response = (
                f"\nFragment 7: {FRAGMENT7}\n"
                f"ESCAPE CODE: {ESCAPE_CODE}\n"
                "Congratulations — you have escaped.\n"
                "Now run: game check\n"
            )
            self.wfile.write(response.encode())
            self.wfile.flush()
        else:
            self.wfile.write(b"\nWrong passphrase. Try again.\n")
            self.wfile.flush()


def main() -> None:
    if not KEY6.exists():
        sys.stderr.write("finalserver: key6 not found — solve puzzle 6 first\n")
        sys.exit(1)

    # Clear any previous success flag
    SUCCESS_FLAG.unlink(missing_ok=True)

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer((HOST, PORT), Handler) as server:
        sys.stdout.write(f"Listening on {HOST}:{PORT}\n")
        sys.stdout.flush()
        server.serve_forever()


if __name__ == "__main__":
    main()
