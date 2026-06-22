# Spec: `escape-linux` — A Linux Fundamentals Escape Room (Containerized)

## 1. Premise

A single Docker container drops the player into a terminal. To "escape," they must
solve **3 progressive puzzles**, each teaching one Linux fundamental. Each puzzle is
locked behind the previous one: solving puzzle *N* produces a **key fragment** and a
**clue** that bootstraps puzzle *N+1*.

The player's **timer is always visible** via a persistent tmux status bar. A
**countdown timer runs by default** but can be disabled during onboarding.

Target audience: not beginners. Think a software engineer ~2 years in who uses Linux
daily but hasn't gone deep — challenging but achievable.

-----

## 2. The 3 puzzles

|#|Name|Concept|
|-|----|-------|
|1|Leave a Mark|File creation — `touch`, redirection|
|2|Words on the Wire|stdout redirection — `echo 'phrase' > file`|
|3|Hunt the Flag|Recursive file search — `find`, `cp`|

-----

## 3. Puzzle chain (the "escape room" logic)

Each puzzle emits a **key fragment** (a short string) written to `~/.game/keys/keyN`, and
a **clue** that bootstraps the next puzzle. The chain is hard-linked: a puzzle's `setup.sh`
refuses to run unless the prior key exists.

> **Containment model:** the container runs as an unprivileged `player` user. Puzzle
> setup scripts run as root via sudo. The player cannot skip puzzles because each
> setup asserts the prior key file exists.

### Puzzle 1 — Leave a Mark

- The player must create a file called `~/ready.txt`. Any content (or empty) is fine.
- Watch condition: `~/ready.txt` exists.
- **Reward:** fragment "ALPHA" + clue: *"A program only speaks when wired the right way."*

### Puzzle 2 — Words on the Wire

- The player must write the exact phrase "open sesame" to `~/signal.txt` using stdout
  redirection: `echo 'open sesame' > ~/signal.txt`
- A briefing file (`~/puzzle2.txt`) explains the task and syntax.
- Watch condition: `~/signal.txt` exists and contains "open sesame".
- **Gate:** `setup.sh` asserts key1 exists.
- **Reward:** fragment "BRAVO" + clue: *"Something is hiding where names don't matter."*

### Puzzle 3 — Hunt the Flag

- A flag file containing "CHARLIE" is hidden in a nested directory tree under
  `/srv/hidden/`. Decoy files exist at other paths.
- The player must find it (`find /srv/hidden -name flag.txt`) and copy it home:
  `cp /path/to/flag.txt ~/flag.txt`
- A briefing file (`~/puzzle3.txt`) explains the task.
- Watch condition: `~/flag.txt` exists and contains "CHARLIE".
- **Gate:** `setup.sh` asserts key2 exists.
- **Reward:** fragment "CHARLIE" — game complete.

-----

## 4. Status bar

**Mechanism:** the container runs inside **tmux**. The status bar displays the player's
name, time remaining, and hints used.

Status line format:

```
 Alice  41:12  hints:0 
```

Content shown:
- Player name (from onboarding)
- Time remaining as `MM:SS`, or `PAUSED MM:SS`, or `+MM:SS` (overtime), or `off`
- Hint count

Content **not** shown:
- Puzzle names or numbers
- Progress bar or percentage
- Emoji or unicode symbols (terminal compatibility)

**Performance:** `engined` writes the formatted status line to `~/.game/status_cache`
every second. The tmux `status-left` simply cats this file (`cat ~/.game/status_cache`),
avoiding Python startup overhead on every refresh. This ensures true 1-second updates.

The tmux window list is hidden (`window-status-format` and `window-status-current-format`
set to empty) so only the status line appears.

-----

## 5. Timer

- **Default: ON.** Onboarding asks: *"Enable countdown timer? [Y/n]"*. Can also be set
  non-interactively via `GAME_TIMER=off` env var.
- Duration: **60:00** — fixed, not configurable by the player.
- **On reaching zero (soft-fail, default):** the run is flagged `escaped_late=true`, the
  status timer shows overtime `+MM:SS`, but the player **may keep going** and still escape.
  A `GAME_HARD_TIMER=true` option converts this to a lockout.
- Timer pauses are allowed via `game pause` / `game resume`.

State for the timer (start epoch, duration, paused-accumulated, enabled flag) lives in the
shared state file so the status bar and engine agree.

-----

## 6. Engine: commands & contracts

A single `game` CLI (on PATH) is the player's control surface. Subcommands:

- `game hint` — print the next hint for the current puzzle (increments `hints`).
- `game pause` / `game resume` — timer control.

There is no `game check`, `game status`, `game reset`, or `game intro`. Puzzles complete
automatically. The status bar provides all state visibility.

**Progression contract (how puzzles link):**

1. Each puzzle dir ships `setup.sh` (places artifacts, asserts prior key exists) and a
   `watch` condition declared in the puzzle registry (`file` path + optional `contains` string).
1. `engined` — a background daemon started at onboarding — polls the current puzzle's watch
   condition every second. On match it writes `~/.game/keys/keyN`, runs the next puzzle's
   `setup.sh`, advances state, and notifies the player via their terminal.
1. On final puzzle completion, `engined` shows a tmux display-message "YOU ESCAPED!" and exits.
1. A puzzle's `setup.sh` **must** assert the prior key exists; this enforces "you can't be
   here without the previous answer," even across container restarts.

**State file** (`~/.game/state.json`), single source of truth read by engine + status bar:

```json
{
  "player_name": "Alice",
  "current_puzzle": 2,
  "total_puzzles": 3,
  "fragments": {"1": "ALPHA"},
  "timer": {"enabled": true, "start_epoch": 0, "duration_sec": 3600,
            "paused_sec": 0, "paused_at": null},
  "hints": 0,
  "escaped_late": false,
  "completed": false
}
```

-----

## 7. Container & environment

### Base image

- `debian:trixie-slim` — pinned to a named release (not the floating `stable` tag) to
  stabilize layer cache across builds.

### Installed packages (minimal)

`tmux`, `python3`, `procps`, `findutils`, `sudo`, `gosu`

No build tools, networking utilities, or other packages unless a puzzle requires them.

### Player environment

- User: `player` (unprivileged, created with `useradd -m -s /bin/bash`)
- Working directory: `/home/player` (tmux session starts here via `-c`)
- PS1: current path only, purple (256-color `38;5;141`): `\[\033[38;5;141m\]\w\[\033[0m\]\$ `
- No hostname or username in prompt (Docker can't reliably set hostname at runtime)

### tmux session

- Session name: `game`
- Starts in `/home/player`
- Status bar on bottom (status-left only, no window list, no status-right)
- Session locked down: detach, split, new-window, kill-pane all unbound
- Mouse disabled
- History: 50000 lines

### Onboarding

`intro.sh` runs before tmux starts (from `entrypoint.sh`). It:

1. Displays the ASCII welcome banner
2. Prompts for player name (stored in state, shown in tmux status bar only)
3. Prompts for timer on/off
4. Initializes `state.json`
5. Records player tty for engined notifications
6. Starts `engined` in background
7. Writes the puzzle 1 briefing into `.bashrc` as a one-shot block (guarded by a flag file)
   so it displays when the tmux shell first opens — not before tmux starts

### Victory

On final puzzle completion, `engined` shows `tmux display-message "YOU ESCAPED!"` (4-second
display in the status area) and exits. No separate victory banner or script.

-----

## 8. CI/CD

GitHub Actions workflow (`.github/workflows/docker-build.yml`):

- Triggers on push to any branch
- Uses `docker/setup-buildx-action` for BuildKit support
- Builds multi-arch: `linux/amd64,linux/arm64`
- Pushes to GitHub Container Registry (`ghcr.io`)
- Registry-based build cache (`cache-from`/`cache-to` with `type=registry`) to avoid
  re-downloading unchanged layers on pull
- Tags: branch name, sha prefix, `latest` on main

-----

## 9. Implementation plan — bite-size chunks (≤ 3 files each)

Build in this order. Each chunk is independently testable.

### Chunk A — Base container (3 files)

- `Dockerfile` — base `debian:trixie-slim`; install minimal packages; create `player`
  user; copy `engine/` and `puzzles/`; set PS1; set entrypoint.
- `entrypoint.sh` — at boot: run puzzle 1 setup as root, run `intro.sh` if first boot,
  drop to `player`, launch tmux with `-c /home/player`.
- `README.md` — how to build/run, env var options, controls.

### Chunk B — Engine core (4 files)

- `engine/state.py` — load/save `state.json`, advance puzzle, write fragments (atomic writes).
- `engine/puzzles.py` — registry: ordered list of puzzle metadata (id, name, dir, fragment,
  watch condition, hints).
- `engine/cli.py` — the `game` command (`hint`, `pause/resume`).
- `engine/engined.py` — background watcher daemon; polls watch conditions, writes status
  cache, auto-advances on match.

### Chunk C — Status bar + timer (2 files)

- `tmux/.tmux.conf` — `status-interval 1`, `status-left` cats `~/.game/status_cache`,
  hide window list, lock down pane-killing/detach keys.
- `engine/timer.py` — timer math (remaining/overtime/paused), formatting without emoji.

### Chunk D — Onboarding (1 file)

- `intro.sh` — welcome banner, ask player name + timer on/off (duration fixed at 60 min),
  write initial state, record player tty, start `engined`, write puzzle 1 briefing into
  `.bashrc` with one-shot guard.

### Chunks E–G — One chunk per puzzle (≤ 3 files each)

Each lives in `puzzles/NN-name/` with the same shape:

- `setup.sh` — assert prior key, place artifacts (as root where needed).
- A **watch condition** declared in `engine/puzzles.py` (`file` path + optional `contains`
  string) — no `check.sh`/`check.py`; `engined` polls and auto-advances.
- **E / P1:** `puzzles/01-hello/setup.sh` (no artifacts needed, just cleanup).
- **F / P2:** `puzzles/02-redirect/setup.sh` (drops briefing file `~/puzzle2.txt`).
- **G / P3:** `puzzles/03-find/setup.sh` (builds `/srv/hidden/` directory tree with flag).

### Chunk H — Validation (1 file)

- `tests/smoke.sh` — scripts a full solve end-to-end as root using `gosu player` to
  simulate player actions. Must exit 0 from a clean container.

-----

## 10. Design rules / acceptance criteria

- **Python for all engine code.** Puzzles themselves are pure shell interactions.
- **Every puzzle requires the previous one's output** (key file present).
- **Timer is always on screen** (tmux status bar). No progress, puzzle position, or
  completion percentage is shown.
- **Timer on by default, disable-able at onboarding** (`GAME_TIMER=off` for non-interactive).
  Duration is fixed at 60 minutes and not player-configurable.
- **No emoji or unicode symbols** in the status bar or engine output — use plain ASCII for
  terminal compatibility.
- **Status bar updates every second** via a cache file (not by spawning Python on each tick).
- **Multi-arch image** (amd64 + arm64) built in CI with registry cache.
- **Minimal image footprint** — only install packages required by current puzzles.
- Each implementation chunk touches **at most 3 files**.
- A `tests/smoke.sh` run must escape from a clean container with no manual intervention.

-----

## 11. Stretch (post-MVP)

- More puzzles (permissions/setuid, processes/signals, file descriptors, PATH resolution,
  text processing, inodes, networking) to bring the count up to 7.
- Difficulty modes (`easy` adds more hints / longer timer).
- Persisted leaderboard of best escape times via a bind-mounted volume.
