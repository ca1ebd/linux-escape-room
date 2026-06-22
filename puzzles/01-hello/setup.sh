#!/bin/bash
# Puzzle 1 setup — no prior key required.
# Nothing to place; the puzzle is pure player action (touch ~/ready.txt).
set -e

# Clean up any previous solve artifact so reset works cleanly
rm -f /home/player/ready.txt

echo "Puzzle 1 ready."
