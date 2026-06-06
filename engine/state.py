#!/usr/bin/env python3
"""Single source of truth for game state. All reads/writes go through here."""

import json
import os
import sys
import time
from pathlib import Path

STATE_PATH = Path.home() / ".game" / "state.json"
KEYS_DIR = Path.home() / ".game" / "keys"


def load() -> dict:
    return json.loads(STATE_PATH.read_text())


def save(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2))
    os.rename(tmp, STATE_PATH)


def init(player_name: str = "player", timer_enabled: bool = True,
         duration_sec: int = 3600) -> dict:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    state = {
        "player_name": player_name,
        "current_puzzle": 1,
        "total_puzzles": 3,
        "fragments": {},
        "timer": {
            "enabled": timer_enabled,
            "start_epoch": time.time(),
            "duration_sec": duration_sec,
            "paused_sec": 0,
            "paused_at": None,
        },
        "hints": 0,
        "escaped_late": False,
        "completed": False,
    }
    save(state)
    return state


def get_current_puzzle(state: dict) -> int:
    return state["current_puzzle"]


def advance_puzzle(state: dict) -> dict:
    state["current_puzzle"] += 1
    return state


def add_fragment(state: dict, n: int, value: str) -> dict:
    state["fragments"][str(n)] = value
    return state


def add_hint(state: dict) -> dict:
    state["hints"] += 1
    return state


def set_completed(state: dict) -> dict:
    state["completed"] = True
    return state


def key_path(n: int) -> Path:
    return KEYS_DIR / f"key{n}"


def write_key(n: int, fragment: str) -> None:
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    p = key_path(n)
    p.write_text(fragment)
    p.chmod(0o644)


def key_exists(n: int) -> bool:
    return key_path(n).exists()


def get_player_name(state: dict) -> str:
    return state.get("player_name", "player")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "init":
        enabled = "--no-timer" not in sys.argv
        dur = 3600
        if "--duration" in sys.argv:
            idx = sys.argv.index("--duration")
            dur = int(sys.argv[idx + 1])
        name = "player"
        if "--name" in sys.argv:
            idx = sys.argv.index("--name")
            name = sys.argv[idx + 1]
        s = init(name, enabled, dur)
        print(json.dumps(s, indent=2))
    elif cmd == "get":
        field = sys.argv[2]
        s = load()
        val = s
        for part in field.split("."):
            val = val[part]
        print(val)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)
