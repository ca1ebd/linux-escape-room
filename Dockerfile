FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        tmux \
        build-essential \
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
    && find /game/engine -name "*.py" -exec chmod +x {} \; \
    && find /game/puzzles -name "setup.sh" -exec chmod +x {} \;

# Install the game CLI on PATH
RUN ln -s /game/engine/cli.py /usr/local/bin/game \
    && chmod +x /game/engine/cli.py

# Allow player to run puzzle setup scripts as root (no password)
RUN echo 'player ALL=(root) NOPASSWD: /game/puzzles/*/setup.sh' > /etc/sudoers.d/game-setup \
    && chmod 440 /etc/sudoers.d/game-setup

# tmux config + prompt (hardcode hostname since Docker can't change it at runtime)
RUN mkdir -p /home/player && cp /game/tmux/.tmux.conf /home/player/.tmux.conf \
    && chown player:player /home/player/.tmux.conf \
    && echo "PS1='\\[\\033[1;35m\\]\\w\\[\\033[0m\\]\\$ '" >> /home/player/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
