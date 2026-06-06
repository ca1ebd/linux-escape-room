#!/bin/bash
# Puzzle 4 setup — runs as root.
# Asserts key3 exists, installs gateway and the decoy verify binary.
set -e

KEY3="/home/player/.game/keys/key3"
if [ ! -f "$KEY3" ]; then
    echo "setup: key3 not found — solve puzzle 3 first" >&2
    exit 1
fi

# Install gateway
install -m 755 /game/puzzles/04-path/gateway /usr/local/bin/gateway

# Install the decoy verify (always fails, so player must shadow it)
cat > /usr/local/bin/verify <<'VERIFY_SCRIPT'
#!/bin/bash
echo "WRONG"
exit 0
VERIFY_SCRIPT
chmod 755 /usr/local/bin/verify

# Drop a briefing note in the player's home
NOTE="/home/player/puzzle4.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 4 — Environment & PATH Resolution
=========================================

The program `gateway` runs a command called `verify` and checks its output.
The system-installed `verify` always gives the wrong answer.

Your task: make `gateway` run YOUR `verify` instead.

Relevant commands:
  echo $PATH          — see the search order
  which verify        — see which binary wins right now
  type verify         — same, with more detail
  export PATH=...     — change the search order

When `gateway` accepts your verify, run: game check
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
