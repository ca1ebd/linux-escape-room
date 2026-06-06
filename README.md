# escape-linux

A Linux fundamentals escape room in a Docker container. Solve 7 progressive puzzles,
each teaching one concept you use daily but haven't gone deep on.

## Requirements

- Docker

## Build & run

```bash
docker build -t escape-linux .
docker run -it --rm escape-linux
```

## Options

| Env var | Default | Effect |
|---------|---------|--------|
| `GAME_TIMER` | `on` | Set to `off` to disable the countdown |
| `GAME_DURATION` | `2700` | Timer duration in seconds |
| `GAME_HARD_TIMER` | unset | Set to `true` to lock out on timeout |

```bash
# No timer
docker run -it --rm -e GAME_TIMER=off escape-linux

# 60-minute timer
docker run -it --rm -e GAME_DURATION=3600 escape-linux
```

## Controls

- `game status` — print current progress
- `game hint` — get a hint (uses one hint token)
- `game check` — submit your answer for the current puzzle
- `game pause` / `game resume` — pause/resume the timer
- `game reset` — reset the current puzzle if you've corrupted an artifact
- `game intro` — replay the welcome screen

## House rules

- You're working as the `player` user. `sudo` is not your friend here — the puzzles are designed to be solved without it.
- Every puzzle requires the previous one's output. No skipping.
- The source for any compiled binary is readable at `/usr/local/src/`.
