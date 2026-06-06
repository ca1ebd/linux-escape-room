#!/bin/bash
# Puzzle 3 setup — asserts key2 exists, builds a hidden flag in /srv/hidden.
set -e

KEY2="/home/player/.game/keys/key2"
if [ ! -f "$KEY2" ]; then
    echo "setup: key2 not found — puzzle 2 must be solved first" >&2
    exit 1
fi

rm -f /home/player/flag.txt

# Build a small directory tree to hide flag.txt in
rm -rf /srv/hidden
mkdir -p /srv/hidden/a/b/c \
         /srv/hidden/d/e \
         /srv/hidden/f

# Drop decoy files
echo "nope" > /srv/hidden/a/notflag.txt
echo "nope" > /srv/hidden/d/e/notflag.txt
echo "nope" > /srv/hidden/f/notflag.txt

# The real flag
echo "CHARLIE" > /srv/hidden/a/b/c/flag.txt
chmod 644 /srv/hidden/a/b/c/flag.txt

NOTE="/home/player/puzzle3.txt"
cat > "$NOTE" <<'EOF'
PUZZLE 3 — Hunt the Flag
==========================

A flag file is hidden somewhere under /srv/hidden/.
There are decoy files too — you need to find the one named flag.txt.

The find command searches recursively:
  find /srv/hidden -name flag.txt

Once you have the path, copy it to your home directory:
  cp <path> ~/flag.txt

The game will notice automatically.
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
