# escape-linux — agent instructions

Linux fundamentals escape room in a Docker container. Full design: @SPEC.md
Build one chunk at a time. A "chunk" touches **at most 3 files**.

## Commands

- Build image: `docker build -t escape-linux .`
- Run: `docker run -it --rm escape-linux`
- Full solve test: `bash tests/smoke.sh` (must escape a clean container unattended)

## Hard invariants (do NOT change without updating SPEC.md)

- **`~/.game/state.json` is the single source of truth.** Engine and status bar both
  read it. Schema is fixed in SPEC.md §6. Write atomically (temp file + rename).
- **Progression contract:** solving puzzle N writes `~/.game/keys/keyN`, runs puzzle
  N+1's `setup.sh`, advances `current_puzzle`, prints the next clue. A puzzle's
  `setup.sh` MUST assert the prior key exists before placing artifacts.
- **Puzzle layout:** `puzzles/NN-name/` containing `setup.sh`, a validator
  (`check.sh` or `check.py`), and one artifact source. Nothing else.
- **No puzzle is solvable by a naive `cat`/read.** Secrets are root-owned; the
  player runs as the unprivileged `player` user. Enforce with perms + the gate check.
- **Language:** Python for all programming, EXCEPT where the lesson itself is C
  (Puzzle 1's setuid binary). Do not rewrite the C puzzle in Python.

## Workflow

- Verify before declaring done: run the current puzzle's validator (or `tests/smoke.sh`)
  and paste the output. Do not assert success without evidence.
- Match the existing puzzle's file shape when adding a new one — read an existing
  `puzzles/NN-name/` first and follow the pattern.
- Keep `state.json` reads/writes only in `engine/state.py`. Other code calls it.

## Repo etiquette

- Default branch `main`. Conventional commit messages. One chunk per commit.
