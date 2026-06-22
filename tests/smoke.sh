#!/usr/bin/env bash
# smoke.sh — full solve of the escape room, unattended.
# Run inside the container as root: bash tests/smoke.sh
# Must exit 0 with all puzzles solved.
set -euo pipefail

PASS=0
FAIL=0

ok()   { echo "  [PASS] $*"; (( PASS++ )) || true; }
fail() { echo "  [FAIL] $*"; (( FAIL++ )) || true; }
section() { echo; echo "── $* ──"; }

# ── Preflight ────────────────────────────────────────────────────────────────
section "Preflight"

[ -f /game/engine/cli.py ]     && ok "cli.py present"        || fail "cli.py missing"
[ -f /usr/local/bin/game ]     && ok "game symlink present"  || fail "game symlink missing"
python3 -c "import sys; sys.path.insert(0,'/game/engine'); import state" 2>&1 && ok "engine importable" || fail "engine import error"

# ── Init state (as player) ────────────────────────────────────────────────────
section "State init"

gosu player python3 /game/engine/state.py init --no-timer >/dev/null
ok "state initialised"
STATE=$(gosu player python3 /game/engine/state.py get current_puzzle)
[ "$STATE" = "1" ] && ok "current_puzzle=1" || fail "current_puzzle=$STATE"

# ── Puzzle 1: Leave a Mark ───────────────────────────────────────────────────
section "Puzzle 1 — Leave a Mark"

bash /game/puzzles/01-hello/setup.sh >/dev/null
ok "puzzle 1 setup"

# Player creates ~/ready.txt
gosu player touch /home/player/ready.txt
[ -f /home/player/ready.txt ] && ok "ready.txt created" || fail "ready.txt missing"

# Advance state manually (engined not running in smoke test)
gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(1,'ALPHA'); st=s.add_fragment(st,1,'ALPHA'); st=s.advance_puzzle(st); s.save(st)
"
ok "key1 written, advanced to puzzle 2"

# ── Puzzle 2: Words on the Wire ──────────────────────────────────────────────
section "Puzzle 2 — Words on the Wire"

bash /game/puzzles/02-redirect/setup.sh >/dev/null
ok "puzzle 2 setup"

# Player writes the magic phrase to signal.txt
gosu player bash -c "echo 'open sesame' > /home/player/signal.txt"
CONTENT=$(cat /home/player/signal.txt)
echo "$CONTENT" | grep -q "open sesame" && ok "signal.txt contains 'open sesame'" || fail "signal.txt: $CONTENT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(2,'BRAVO'); st=s.add_fragment(st,2,'BRAVO'); st=s.advance_puzzle(st); s.save(st)
"
ok "key2 written, advanced to puzzle 3"

# ── Puzzle 3: Hunt the Flag ──────────────────────────────────────────────────
section "Puzzle 3 — Hunt the Flag"

bash /game/puzzles/03-find/setup.sh >/dev/null
ok "puzzle 3 setup"

# Player finds and copies the flag
FLAG_PATH=$(find /srv/hidden -name flag.txt)
[ -n "$FLAG_PATH" ] && ok "flag found at $FLAG_PATH" || fail "flag not found"

gosu player cp "$FLAG_PATH" /home/player/flag.txt
FRAG=$(cat /home/player/flag.txt)
[ "$FRAG" = "CHARLIE" ] && ok "flag.txt = CHARLIE" || fail "flag.txt: $FRAG"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(3,'CHARLIE'); st=s.add_fragment(st,3,'CHARLIE'); st=s.set_completed(st); s.save(st)
"
ok "key3 written, game completed"

# Verify final state
COMPLETED=$(gosu player python3 /game/engine/state.py get completed)
[ "$COMPLETED" = "True" ] && ok "state.completed = True" || fail "state.completed = $COMPLETED"

# ── Summary ───────────────────────────────────────────────────────────────────
section "Results"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "  ALL TESTS PASSED — smoke test green"
    exit 0
else
    echo "  SMOKE TEST FAILED — $FAIL check(s) failed"
    exit 1
fi
