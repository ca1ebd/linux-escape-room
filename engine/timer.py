#!/usr/bin/env python3
"""Pure timer math — no I/O. All functions take a state dict and return values."""

import time


def _now() -> float:
    return time.time()


def elapsed(state: dict) -> float:
    t = state["timer"]
    if not t["enabled"]:
        return 0.0
    base = _now() - t["start_epoch"] - t["paused_sec"]
    if t["paused_at"] is not None:
        # Currently paused — don't count time since paused_at
        base -= _now() - t["paused_at"]
    return max(0.0, base)


def remaining(state: dict) -> float:
    t = state["timer"]
    if not t["enabled"]:
        return float("inf")
    return t["duration_sec"] - elapsed(state)


def is_overtime(state: dict) -> bool:
    return state["timer"]["enabled"] and remaining(state) < 0


def is_paused(state: dict) -> bool:
    return state["timer"]["paused_at"] is not None


def format_timer(state: dict) -> str:
    t = state["timer"]
    if not t["enabled"]:
        return "⏱ off"
    if is_paused(state):
        secs = abs(remaining(state))
        m, s = divmod(int(secs), 60)
        return f"⏱ PAUSED {m:02d}:{s:02d}"
    r = remaining(state)
    if r >= 0:
        m, s = divmod(int(r), 60)
        return f"⏱ {m:02d}:{s:02d}"
    else:
        m, s = divmod(int(-r), 60)
        return f"⏱ +{m:02d}:{s:02d}"


def pause(state: dict) -> dict:
    t = state["timer"]
    if t["paused_at"] is not None:
        return state  # already paused
    t["paused_at"] = _now()
    return state


def resume(state: dict) -> dict:
    t = state["timer"]
    if t["paused_at"] is None:
        return state  # not paused
    t["paused_sec"] += _now() - t["paused_at"]
    t["paused_at"] = None
    return state
