# Spec: `escape-linux` — A Linux Fundamentals Escape Room (Containerized)

## 1. Premise

A single Docker container drops the player into a terminal. To "escape," they must
solve **7 progressive puzzles**, each teaching one Linux fundamental. Each puzzle is
locked behind the previous one: solving puzzle *N* produces a **key fragment** and a
**clue** that are required to start and/or solve puzzle *N+1*. The final puzzle requires
the passphrase assembled from all 7 fragments.

The player's **state is always visible** (current puzzle, progress, time remaining) via a
persistent terminal status bar. A **countdown timer runs by default** but can be disabled
during onboarding.

Target audience: not beginners. Think a software engineer ~2 years in who uses Linux
daily but hasn't gone deep — challenging but achievable.

-----

## 2. The 7 concepts (and why each made the cut)

|#|Concept                                             |Why it's worth going deeper                                                                                                       |
|-|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
|1|**Permissions, ownership & special bits**           |Most people know `chmod 755` but not setuid/setgid/sticky, `find -perm`, or *why* a root-owned binary can read a file they can't. |
|2|**Processes, signals & `/proc`**                    |`ps`/`kill -9` is muscle memory; signals as IPC, signal handlers, and reading `/proc/<pid>` are not.                              |
|3|**File descriptors, redirection & pipes**           |`>` and `|` are used constantly but fd duplication (`2>&1`, `3<`, `tee`, here-docs) is fuzzy for most.                            |
|4|**Environment, PATH & command resolution**          |`export` is known; PATH resolution order, builtins vs binaries, and PATH shadowing/hijack (a real security topic) are not.        |
|5|**Text-processing pipelines (grep/sed/awk + regex)**|Everyone greps; composing `grep | awk | sort | uniq` and writing a real regex is the actual skill.                                |
|6|**Links, inodes & the filesystem**                  |Hard vs symbolic links, inode identity, `find -inum`, and recovering a deleted-but-open file via `/proc/<pid>/fd` are eye-openers.|
|7|**Networking & sockets**                            |Listening ports, `ss`, connecting with `nc` or bash `/dev/tcp`, and the client/server model on `localhost`.                       |

-----

## 3. Puzzle chain (the "escape room" logic)

Each puzzle emits a **key fragment** (a short string) written to `~/.game/keys/keyN`, and
a **clue** that bootstraps the next puzzle. The chain is hard-linked: a puzzle's `setup`
and `check` refuse to run/pass unless the prior key exists.

> **Containment model:** the container runs as an unprivileged `player` user. All secrets
> are owned by `root` and placed at build/entry time. The player can never trivially `cat`
> their way to the end — they must use the technique each puzzle teaches.

### Puzzle 1 — Permissions & setuid  *(teaches C; this is the "Linux is C" puzzle)*

- A root-owned file `/srv/vault/secret1` is mode `0600` (player can't read it).
- A **setuid C binary** `/usr/local/bin/unlock1` (owned by root, mode `4755`) reads that
  file and prints fragment #1 — but only when invoked with a required argument.
- The player must discover it: `find / -perm -4000 -type f 2>/dev/null`, inspect with
  `ls -l`/`stat`, then run it correctly.
- **Reward:** fragment 1 + clue: *"a heartbeat process is listening for a signal."*
- **Why C:** setuid is a kernel/libc mechanism; reading `unlock1.c` shows `setuid()`,
  `getuid()`/`geteuid()`, and why the privilege boundary works.

### Puzzle 2 — Processes & signals

- A daemon (`heartbeatd`, a Python script) runs in the background with a `SIGUSR1` handler.
- On `SIGUSR1` it writes fragment #2 to a player-readable drop file; on `SIGUSR2` it
  decoys/resets.
- Player must locate it (`ps -ef`, `pgrep`, `/proc/<pid>/cmdline`) and send the right
  signal: `kill -USR1 <pid>`.
- **Gate:** `heartbeatd` only starts if `key1` exists.
- **Reward:** fragment 2 + clue: *"a program only speaks on the right wires (fds)."*

### Puzzle 3 — File descriptors & redirection

- A program `whisper` (Python) reads a token on **fd 3**, writes the real answer to
  **stderr** only, and prints noise to stdout.
- Player must wire it up, e.g. `whisper 3< token.txt 2> answer.txt >/dev/null` (exact form
  documented in-puzzle), feeding the token derived from fragment 2.
- **Reward:** fragment 3 + clue: *"the way out depends on what `PATH` finds first."*

### Puzzle 4 — Environment & PATH resolution

- A wrapper `gateway` runs whatever `verify` resolves to on PATH and checks its output.
- The system `verify` is a decoy that always fails. The player must **shadow** it by
  creating their own `verify` script earlier in PATH (or prepend a dir to PATH), making it
  emit the value from fragment 3.
- Teaches: `which`/`type`, `echo $PATH`, builtins vs binaries, PATH ordering, `export`.
- **Reward:** fragment 4 + clue: *"7,000 log lines, one anomaly."*

### Puzzle 5 — Text processing & regex

- A large generated log `/srv/logs/access.log` (~7k lines). Exactly one line matches a
  pattern hinted by fragment 4; a field within it (extracted via `awk`/`cut`) is fragment 5.
- Intended pipeline shape: `grep -E '<pattern>' access.log | awk '{print $N}' | sort | uniq -c`.
- **Reward:** fragment 5 + clue: *"the next clue has no name, only a number"* (an inode).

### Puzzle 6 — Links & inodes

- A directory of thousands of hard-linked decoy files; the real one is identified **only by
  inode number** (given by fragment 5): `find /srv/maze -inum <N>`.
- Bonus variant (configurable): the file is **deleted but still held open** by a process;
  recover it via `/proc/<pid>/fd/<n>`.
- Teaches: `ls -i`, `stat`, `find -inum`, hard vs symbolic links, `df`/`du`.
- **Reward:** fragment 6 + clue: *"a service is listening on a port — go knock."* (port #).

### Puzzle 7 — Networking & sockets  *(final)*

- A server (Python `socketserver`) listens on `127.0.0.1:<port>` (port from fragment 6).
- Player connects (`nc 127.0.0.1 <port>` or bash `exec 3<>/dev/tcp/127.0.0.1/<port>`),
  is challenged, and must send the **full passphrase = fragments 1–7 concatenated**.
- On success the server returns the **ESCAPE CODE**; the engine marks the game complete and
  stops the timer.
- Teaches: `ss -ltnp`, ports, client/server, `nc`, `/dev/tcp`.

-----

## 4. Always-visible state (status bar)

**Mechanism:** the container auto-starts inside **tmux**; the player works in the main pane
and a persistent **status line** is always rendered.

Status line format:

```
⏱ 41:12
```

- **Timer only** — `⏱ MM:SS` remaining, or `⏱ off` if disabled, or `⏱ +MM:SS` overtime.
- No puzzle name, progress bar, or hint count is shown. The player should not know how
  close they are to finishing.

The status bar refreshes every second (tmux `status-interval 1`) by calling a render script
that reads the state file. `game status` prints the timer for non-tmux use. The PS1 shows
`name@escape:~$` — plain directory only, no game state.

-----

## 5. Timer

- **Default: ON.** Onboarding asks: *"Enable countdown timer? [Y/n]"*. Can also be set
  non-interactively via `GAME_TIMER=off` env var.
- Duration: **60:00** — fixed, not configurable by the player.
- **On reaching zero (soft-fail, default):** the run is flagged `escaped_late=true`, the
  status timer shows overtime `⏱ +MM:SS`, but the player **may keep going** and still escape.
  A `GAME_HARD_TIMER=true` option converts this to a lockout (final puzzle refuses to
  complete after zero).
- Timer pauses are allowed via `game pause` / `game resume`.

State for the timer (start epoch, duration, paused-accumulated, enabled flag) lives in the
shared state file so the status bar and engine agree.

-----

## 6. Engine: commands & contracts

A single `game` CLI (on PATH) is the player's control surface. Core subcommands:

- `game status` — print the timer (also used by tmux).
- `game hint` — print the next hint for the current puzzle (increments `hints`).
- `game reset [N]` — re-run setup for the current puzzle (or puzzle N), for when the player
  corrupts an artifact.
- `game pause` / `game resume` — timer control.
- `game intro` — (re)run onboarding.

There is no `game check`. Puzzles complete automatically.

**Progression contract (how puzzles link):**

1. Each puzzle dir ships `setup.sh` (places artifacts, asserts prior key exists) and a
   `watch` condition declared in the puzzle registry (`file` path + optional `contains` string).
1. `engined` — a background daemon started at onboarding — polls the current puzzle's watch
   condition every second. On match it writes `~/.game/keys/keyN`, runs the next puzzle's
   `setup.sh`, advances state, and notifies the player via their terminal.
1. A puzzle's `setup.sh` **must** assert the prior key exists; this enforces "you can't be
   here without the previous answer," even across container restarts.

**State file** (`~/.game/state.json`), single source of truth read by engine + status bar:

```json
{
  "player_name": "Alice",
  "current_puzzle": 3,
  "total_puzzles": 7,
  "fragments": {"1": "...", "2": "...", "3": "..."},
  "timer": {"enabled": true, "start_epoch": 0, "duration_sec": 3600,
            "paused_sec": 0, "paused_at": null},
  "hints": 1,
  "escaped_late": false,
  "completed": false
}
```

-----

## 7. Implementation plan — bite-size chunks (≤ 3 files each)

Build in this order. Each chunk is independently testable.

### Chunk A — Base container (3 files)

- `Dockerfile` — base `debian:stable-slim`; install `tmux`, `gcc`, `python3`, `netcat`,
  `procps`, `findutils`; create `player` user; copy `engine/` and `puzzles/`; set entrypoint.
- `entrypoint.sh` — at boot: run all `setup` needed for puzzle 1, init state, drop to
  `player`, launch tmux with the game session.
- `README.md` — how to build/run (`docker run -it escape-linux`), house rules.

### Chunk B — Engine core (3 files)

- `engine/state.py` — load/save `state.json`, advance puzzle, write fragments (atomic writes).
- `engine/puzzles.py` — registry: ordered list of puzzle metadata (id, name, dir, fragment, watch condition, hints).
- `engine/cli.py` — the `game` command (`status`, `hint`, `reset`, `pause/resume`, `intro`).
- `engine/engined.py` — background watcher daemon; polls watch conditions, auto-advances on match.

### Chunk C — Status bar + timer (3 files)

- `tmux/.tmux.conf` — `status-interval 1`, `status-left` calls `statusbar.sh`, lock down
  pane-killing/detach keys so the session stays put.
- `tmux/statusbar.sh` — render the status line from `state.json`.
- `engine/timer.py` — timer math (remaining/overtime/paused), enable/disable, used by both
  the engine and status bar.

### Chunk D — Onboarding (1–2 files)

- `intro.sh` — welcome screen, ask player name + timer on/off (duration fixed at 60 min),
  write initial state, record player tty, start `engined`, show puzzle 1 briefing.

### Chunks E–K — One chunk per puzzle (≤ 3 files each)

Each lives in `puzzles/NN-name/` with the same shape:

- `setup.sh` — assert prior key, place artifacts/secrets (as root where needed).
- A **watch condition** declared in `engine/puzzles.py` (`file` path + optional `contains`
  string) — no `check.sh`/`check.py`; `engined` polls and auto-advances.
- one **artifact source** file specific to the puzzle:
  - **E / P1:** `unlock1.c` (setuid C binary, compiled at build).
  - **F / P2:** `heartbeatd.py` (signal-handling daemon).
  - **G / P3:** `whisper.py` (fd-3 reader / stderr-only writer).
  - **H / P4:** `gateway` + decoy `verify` (PATH shadowing target).
  - **I / P5:** `gen_log.py` (deterministic ~7k-line log generator, build-time).
  - **J / P6:** `build_maze.sh` (hard-link forest + chosen inode; optional open-fd variant).
  - **K / P7:** `finalserver.py` (`socketserver` validating the assembled passphrase).

### Chunk L — Polish & validation (2–3 files)

- `tests/smoke.sh` — scripts a full solve end-to-end to prove the chain links correctly.
- `engine/victory.py` — ESCAPE banner, final time, late/hint summary, `completed=true`.
- (Optional) `engine/messages.py` — centralized clue/briefing text.

-----

## 8. Design rules / acceptance criteria

- **Python for any programming**, except where the *lesson is C/C++* (Puzzle 1's setuid
  binary) — that's intentional, since Linux itself is C.
- **Every puzzle requires the previous one's output** (key file present and/or fragment used).
- **Timer is always on screen** (tmux status bar; `game status` fallback). No progress or
  puzzle position is shown — the player should not know how close they are to finishing.
- **Timer on by default, disable-able at onboarding** (`GAME_TIMER=off` for non-interactive).
  Duration is fixed at 60 minutes and not player-configurable.
- No puzzle is solvable by a naive `cat`/`find`-and-read; each forces the intended technique
  (enforced by root ownership + permissions + the gate checks).
- Each implementation chunk touches **at most 3 files**.
- A `tests/smoke.sh` run must escape from a clean container with no manual intervention.

-----

## 9. Stretch (post-MVP)

- Difficulty modes (`easy` adds more hints / longer timer).
- A second branch of puzzles (cron/systemd, archives/compression, mounts/devices) for replay.
- Persisted leaderboard of best escape times via a bind-mounted volume.
