#!/bin/bash
# Puzzle 6 setup — runs as root.
# Asserts key5 exists, builds the inode maze, drops briefing with inode clue.
set -e

KEY5="/home/player/.game/keys/key5"
if [ ! -f "$KEY5" ]; then
    echo "setup: key5 not found — solve puzzle 5 first" >&2
    exit 1
fi

# Build the maze and capture the real inode
REAL_INODE=$(bash /game/puzzles/06-inodes/build_maze.sh | tail -1)

# Drop briefing for the player
NOTE="/home/player/puzzle6.txt"
cat > "$NOTE" <<EOF
PUZZLE 6 — Links, Inodes & the Filesystem
==========================================

A directory at /srv/maze holds hundreds of files. Most are decoys.
The real file is identified only by its inode number: $REAL_INODE

You cannot read it directly (it's root-owned, mode 600).
But you can find it — and then read it — via a special path.

Useful commands:
  ls -i /srv/maze          — show inode numbers
  find /srv/maze -inum $REAL_INODE
  stat <file>              — detailed inode info

Bonus: can you think of another way to read a root-owned file
if a process already has it open?

When you have the fragment, run: game check
EOF
chown player:player "$NOTE"
chmod 644 "$NOTE"
