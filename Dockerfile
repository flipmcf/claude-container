FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git wget unzip zip \
    build-essential python3 python3-pip \
    ripgrep fd-find jq sudo gosu \
    && rm -rf /var/lib/apt/lists/*


# We really don't need that ubuntu user.  Probably should change the base image layer.
#  It gets in the way (uid 1000)... too much to explain.  just kill it.
RUN userdel ubuntu
    
# Create claude user with sudo access
RUN useradd -m -s /bin/bash claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude Code via the native installer (per-user, into ~/.local/bin)                   
USER claude                                                                                    
RUN curl -fsSL https://claude.ai/install.sh | bash                                             
USER root                                                                                      
ENV PATH="/home/claude/.local/bin:${PATH}" 

RUN mkdir /work && chown claude:claude /work

# Install github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Guardrail: deny PR merges / pushes to main. Humans merge. (See CLAUDE.md)
COPY managed-settings.json /etc/claude-code/managed-settings.json

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
