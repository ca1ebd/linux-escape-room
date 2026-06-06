FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        tmux \
        gcc \
        python3 \
        netcat-traditional \
        procps \
        findutils \
        iproute2 \
        sudo \
        gosu \
    && rm -rf /var/lib/apt/lists/*

# Create the player user
RUN useradd -m -s /bin/bash player

# Copy project files
COPY engine/ /game/engine/
COPY puzzles/ /game/puzzles/
COPY tmux/ /game/tmux/
COPY tests/ /game/tests/
COPY intro.sh /game/intro.sh

RUN chmod +x /game/intro.sh \
    && find /game/puzzles -name "setup.sh" -exec chmod +x {} \; \
    && find /game/puzzles -name "check.py" -exec chmod +x {} \; \
    && find /game/puzzles -name "check.sh" -exec chmod +x {} \; \
    && find /game/puzzles -name "*.py" -exec chmod +x {} \; \
    && chmod +x /game/tests/smoke.sh

# Compile the setuid binary for puzzle 1
RUN gcc -o /usr/local/bin/unlock1 /game/puzzles/01-permissions/unlock1.c \
    && chown root:root /usr/local/bin/unlock1 \
    && chmod 4755 /usr/local/bin/unlock1

# Place source where the player can read it
RUN mkdir -p /usr/local/src \
    && cp /game/puzzles/01-permissions/unlock1.c /usr/local/src/unlock1.c \
    && chmod 644 /usr/local/src/unlock1.c

# Pre-generate the puzzle 5 access log at build time (deterministic)
RUN mkdir -p /srv/logs \
    && python3 /game/puzzles/05-textproc/gen_log.py /srv/logs/access.log \
    && chmod 644 /srv/logs/access.log

# Install the game CLI
RUN ln -s /game/engine/cli.py /usr/local/bin/game \
    && chmod +x /game/engine/cli.py

# Install puzzle-specific binaries on PATH
RUN ln -s /game/puzzles/03-fds/whisper.py /usr/local/bin/whisper \
    && ln -s /game/puzzles/04-path/gateway /usr/local/bin/gateway \
    && chmod +x /game/puzzles/04-path/gateway

# Allow player to run setup scripts as root (no password)
RUN echo 'player ALL=(root) NOPASSWD: /game/puzzles/*/setup.sh' > /etc/sudoers.d/game-setup \
    && chmod 440 /etc/sudoers.d/game-setup

# tmux config goes to player's home
RUN mkdir -p /home/player && cp /game/tmux/.tmux.conf /home/player/.tmux.conf \
    && chown player:player /home/player/.tmux.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
