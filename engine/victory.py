#!/usr/bin/env python3
"""Victory banner displayed when the player escapes."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import state as _state
import timer as _timer

BANNER = r"""
  ███████╗███████╗ ██████╗ █████╗ ██████╗ ███████╗██████╗ ██╗
  ██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗██║
  █████╗  ███████╗██║     ███████║██████╔╝█████╗  ██║  ██║██║
  ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔══╝  ██║  ██║╚═╝
  ███████╗███████║╚██████╗██║  ██║██║     ███████╗██████╔╝██╗
  ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═════╝ ╚═╝
"""


def main() -> None:
    try:
        s = _state.load()
    except FileNotFoundError:
        s = None

    print(BANNER)
    print("  You have escaped the Linux escape room!")
    print()

    if s:
        hints = s.get("hints", 0)
        total = s["total_puzzles"]
        late = s.get("escaped_late", False)

        if s["timer"]["enabled"]:
            elapsed = _timer.elapsed(s)
            m, sec = divmod(int(elapsed), 60)
            time_str = f"{m}m {sec:02d}s"
            if late:
                print(f"  Time: {time_str}  (overtime — but you made it!)")
            else:
                print(f"  Time: {time_str}")
        else:
            print("  Timer: off")

        print(f"  Hints used: {hints}")
        print(f"  Puzzles solved: {total}/{total}")
        frags = s.get("fragments", {})
        if frags:
            passphrase = "".join(frags[str(i)] for i in range(1, total + 1) if str(i) in frags)
            print(f"  Passphrase: {passphrase}")

    print()
    print("  " + "─" * 56)
    print()


if __name__ == "__main__":
    main()
