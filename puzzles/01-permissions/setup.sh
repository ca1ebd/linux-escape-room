#!/bin/bash
# Puzzle 1 setup — runs as root.
# Places /srv/vault/secret1 and drops a briefing for the player.
# No prior key required (this is puzzle 1).
set -e

FRAGMENT="ALPHA"

mkdir -p /srv/vault
echo "$FRAGMENT" > /srv/vault/secret1
chown root:root /srv/vault/secret1
chmod 600 /srv/vault/secret1

# The vault directory itself should be traversable but not listable
chmod 711 /srv/vault

# Ensure the setuid binary is still correct (re-run after image rebuild)
chown root:root /usr/local/bin/unlock1
chmod 4755 /usr/local/bin/unlock1
