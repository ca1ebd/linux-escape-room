#!/bin/bash
# Build the hard-link maze for puzzle 6.
# Creates /srv/maze with many identically-named decoy files.
# One specific inode number holds the real fragment — its inode number IS fragment 5.
# The fragment written to key5 by gen_log/check is "ECHO", which is the log fragment,
# but the clue for puzzle 6 says "the next clue has no name, only a number (an inode)".
# We use a deterministic inode by creating the real file first, noting its inode,
# then filling the maze. The inode number becomes the content of key5 (see puzzle5/check.py
# comments — actually key5 content is "ECHO"). Wait, re-reading SPEC:
#
# "fragment 5 [...] a field within it (extracted via awk/cut) is fragment 5"
# "clue: 'the next clue has no name, only a number' (an inode)"
#
# So the inode number is delivered as the CLUE, not as fragment 5. Fragment 5 is "ECHO".
# The inode is the clue text printed when puzzle 5 completes.
# The puzzle 5 clue in puzzles.py is already "The next clue has no name, only a number."
# We need to: after the maze is built, write the chosen inode to a clue file so the
# engine can display it. We'll store it at /srv/maze/.inode_clue and the cli/setup prints it.
#
# Actually the simplest approach: encode the inode in the clue printed by game check.
# The puzzle registry already has the static clue text. We need to embed the real inode.
# The cleanest: store inode in a known file; puzzle 6 setup.sh reads it and mentions it
# in the briefing note.

set -e

MAZE="/srv/maze"
FRAGMENT="FOXTROT"
REAL_FILE="$MAZE/.real"
DECOYS=500

rm -rf "$MAZE"
mkdir -p "$MAZE"

# Create the real file first to get a predictable inode assignment
echo "$FRAGMENT" > "$REAL_FILE"
chmod 644 "$REAL_FILE"  # player can read once they find it by inode
REAL_INODE=$(stat -c %i "$REAL_FILE")

# Record the inode for the briefing and the engine clue
echo "$REAL_INODE" > /srv/maze_inode.txt
chmod 644 /srv/maze_inode.txt

# Fill maze with decoy hard links (different inodes) bearing random-looking names
for i in $(seq 1 $DECOYS); do
    tmp=$(mktemp "$MAZE"/XXXXXXXXXXXXXX)
    echo "decoy$i" > "$tmp"
done

# Create a hard link to the real file with a random-looking name so player
# can't just ls and guess — they must use find -inum
LINK_NAME=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | cut -c1-12)
ln "$REAL_FILE" "$MAZE/$LINK_NAME"
rm "$REAL_FILE"  # remove the original; link survives

# Lock down the maze directory — player can stat/find but not ls -la to see the
# hidden .real (it's deleted anyway), and file content needs root to read directly
chown -R root:root "$MAZE"
chmod 755 "$MAZE"
# Individual files are root:root 600 for the real one, others are 644 decoys
# The real hard link still has mode 600 from when .real was created

echo "Maze built: $DECOYS decoys + 1 real (inode $REAL_INODE) → $MAZE"
echo "$REAL_INODE"
