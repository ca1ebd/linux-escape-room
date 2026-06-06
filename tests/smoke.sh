#!/usr/bin/env bash
# smoke.sh — full solve of the escape room, unattended.
# Run inside the container as root: bash tests/smoke.sh
# Must exit 0 with the escape code printed.
set -euo pipefail

PASS=0
FAIL=0
LOG=$(mktemp)

ok()   { echo "  [PASS] $*"; (( PASS++ )) || true; }
fail() { echo "  [FAIL] $*"; (( FAIL++ )) || true; }
section() { echo; echo "── $* ──"; }

# ── Preflight ────────────────────────────────────────────────────────────────
section "Preflight"

[ -f /game/engine/cli.py ]          && ok "cli.py present"       || fail "cli.py missing"
[ -f /usr/local/bin/game ]          && ok "game symlink present"  || fail "game symlink missing"
[ -f /usr/local/bin/unlock1 ]       && ok "unlock1 present"       || fail "unlock1 missing"
[ -x /usr/local/bin/unlock1 ]       && ok "unlock1 executable"    || fail "unlock1 not executable"
python3 -c "import sys; sys.path.insert(0,'/game/engine'); import state" 2>&1 && ok "engine importable" || fail "engine import error"

# ── Init state (as player) ────────────────────────────────────────────────────
section "State init"

gosu player python3 /game/engine/state.py init --no-timer --duration 2700 >/dev/null
ok "state initialised"
STATE=$(gosu player python3 /game/engine/state.py get current_puzzle)
[ "$STATE" = "1" ] && ok "current_puzzle=1" || fail "current_puzzle=$STATE"

# ── Puzzle 1: Permissions & Setuid ───────────────────────────────────────────
section "Puzzle 1 — Permissions & Setuid"

bash /game/puzzles/01-permissions/setup.sh >/dev/null
ok "puzzle 1 setup"

# Player finds and runs the setuid binary
FRAG1=$(gosu player /usr/local/bin/unlock1 open)
[ "$FRAG1" = "ALPHA" ] && ok "unlock1 returns ALPHA" || fail "unlock1 returned: $FRAG1"

RESULT=$(gosu player python3 /game/puzzles/01-permissions/check.py)
[ "$RESULT" = "ALPHA" ] && ok "puzzle 1 check passes" || fail "puzzle 1 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(1,'ALPHA'); st=s.add_fragment(st,1,'ALPHA'); st=s.advance_puzzle(st); s.save(st)
"
ok "key1 written, advanced to puzzle 2"

# ── Puzzle 2: Processes & Signals ────────────────────────────────────────────
section "Puzzle 2 — Processes & Signals"

bash /game/puzzles/02-signals/setup.sh >/dev/null
ok "puzzle 2 setup (heartbeatd started)"
sleep 1

PID=$(cat /tmp/heartbeatd.pid 2>/dev/null || echo "")
[ -n "$PID" ] && ok "heartbeatd running (pid $PID)" || fail "heartbeatd PID not found"

# Send correct signal
gosu player kill -USR1 "$PID"
sleep 0.5
DROP=$(cat /tmp/heartbeat.drop 2>/dev/null || echo "")
[ "$DROP" = "BRAVO" ] && ok "heartbeat drop = BRAVO" || fail "heartbeat drop: $DROP"

RESULT=$(gosu player python3 /game/puzzles/02-signals/check.py)
[ "$RESULT" = "BRAVO" ] && ok "puzzle 2 check passes" || fail "puzzle 2 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(2,'BRAVO'); st=s.add_fragment(st,2,'BRAVO'); st=s.advance_puzzle(st); s.save(st)
"
ok "key2 written, advanced to puzzle 3"

# ── Puzzle 3: File Descriptors ────────────────────────────────────────────────
section "Puzzle 3 — File Descriptors & Redirection"

bash /game/puzzles/03-fds/setup.sh >/dev/null
ok "puzzle 3 setup"

# Player runs: whisper 3< token.txt 2> answer.txt >/dev/null
FRAG3=$(gosu player bash -c '/usr/local/bin/whisper 3< /home/player/token.txt 2>&1 >/dev/null')
[ "$FRAG3" = "CHARLIE" ] && ok "whisper stderr = CHARLIE" || fail "whisper: $FRAG3"

RESULT=$(gosu player python3 /game/puzzles/03-fds/check.py)
[ "$RESULT" = "CHARLIE" ] && ok "puzzle 3 check passes" || fail "puzzle 3 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(3,'CHARLIE'); st=s.add_fragment(st,3,'CHARLIE'); st=s.advance_puzzle(st); s.save(st)
"
ok "key3 written, advanced to puzzle 4"

# ── Puzzle 4: Environment & PATH ─────────────────────────────────────────────
section "Puzzle 4 — Environment & PATH"

bash /game/puzzles/04-path/setup.sh >/dev/null
ok "puzzle 4 setup"

# Player creates a shadow verify and prepends to PATH
gosu player bash -c '
  mkdir -p /tmp/myverify
  echo "#!/bin/bash" > /tmp/myverify/verify
  echo "echo CHARLIE" >> /tmp/myverify/verify
  chmod +x /tmp/myverify/verify
'
ok "shadow verify created"

RESULT=$(gosu player bash -c 'export PATH=/tmp/myverify:$PATH; python3 /game/puzzles/04-path/check.py')
[ "$RESULT" = "DELTA" ] && ok "puzzle 4 check passes" || fail "puzzle 4 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(4,'DELTA'); st=s.add_fragment(st,4,'DELTA'); st=s.advance_puzzle(st); s.save(st)
"
ok "key4 written, advanced to puzzle 5"

# ── Puzzle 5: Text Processing ─────────────────────────────────────────────────
section "Puzzle 5 — Text Processing & Regex"

bash /game/puzzles/05-textproc/setup.sh >/dev/null
ok "puzzle 5 setup (log generated)"

# Player finds the anomalous line
FOUND=$(grep -E ' 418 ' /srv/logs/access.log | awk '{print $NF}')
[ "$FOUND" = "ECHO" ] && ok "anomaly found via grep: ECHO" || fail "grep result: $FOUND"

RESULT=$(gosu player python3 /game/puzzles/05-textproc/check.py)
[ "$RESULT" = "ECHO" ] && ok "puzzle 5 check passes" || fail "puzzle 5 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(5,'ECHO'); st=s.add_fragment(st,5,'ECHO'); st=s.advance_puzzle(st); s.save(st)
"
ok "key5 written, advanced to puzzle 6"

# ── Puzzle 6: Links & Inodes ──────────────────────────────────────────────────
section "Puzzle 6 — Links & Inodes"

bash /game/puzzles/06-inodes/setup.sh >/dev/null
ok "puzzle 6 setup (maze built)"

INODE=$(cat /srv/maze_inode.txt)
[ -n "$INODE" ] && ok "inode clue = $INODE" || fail "no inode file"

MAZE_FILE=$(find /srv/maze -inum "$INODE")
[ -n "$MAZE_FILE" ] && ok "found maze file: $MAZE_FILE" || fail "find -inum failed"

FRAG6=$(gosu player cat "$MAZE_FILE")
[ "$FRAG6" = "FOXTROT" ] && ok "maze file = FOXTROT" || fail "maze file: $FRAG6"

RESULT=$(gosu player python3 /game/puzzles/06-inodes/check.py)
[ "$RESULT" = "FOXTROT" ] && ok "puzzle 6 check passes" || fail "puzzle 6 check: $RESULT"

gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(6,'FOXTROT'); st=s.add_fragment(st,6,'FOXTROT'); st=s.advance_puzzle(st); s.save(st)
"
ok "key6 written, advanced to puzzle 7"

# ── Puzzle 7: Networking ──────────────────────────────────────────────────────
section "Puzzle 7 — Networking & Sockets (Final)"

bash /game/puzzles/07-networking/setup.sh >/dev/null
ok "puzzle 7 setup (server started)"
sleep 1

# Verify server is listening
ss -ltn | grep -q ":7777" && ok "server listening on :7777" || fail "server not listening"

PASSPHRASE="ALPHABRAVOCHARLIEDELTAECHOFOXTROTGOLF"

# Connect and send passphrase
RESPONSE=$(echo "$PASSPHRASE" | gosu player nc 127.0.0.1 7777)
echo "$RESPONSE" | grep -q "ESCAPED" && ok "server returned ESCAPED" || fail "server response: $RESPONSE"

RESULT=$(gosu player python3 /game/puzzles/07-networking/check.py)
[ "$RESULT" = "GOLF" ] && ok "puzzle 7 check passes" || fail "puzzle 7 check: $RESULT"

# Final state update
gosu player python3 -c "
import sys; sys.path.insert(0,'/game/engine'); import state as s
st=s.load(); s.write_key(7,'GOLF'); st=s.add_fragment(st,7,'GOLF'); st=s.set_completed(st); s.save(st)
"
ok "Game completed!"

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
