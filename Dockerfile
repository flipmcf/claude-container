## Once this is built:
## PUT THIS IN YOUR bash profile or something.
## alias claude-here='docker run -it --rm --name claude-dev \
##  -v "$(pwd):/workspace" \
##  -v "$HOME/.claude.json:/home/claude/.claude.json:ro" \
##  -v "$HOME/.claude:/home/claude/.claude:ro" \
##  claude-code-sandbox:latest'

## Then, CD to the project / git repo you want to work with in Claude:
## cd /home/flipmcf/Projects/my-project
## and run 'claude-here'

## Auth is handled by mounting ~/.claude.json at runtime (see alias above)
## No ANTHROPIC_API_KEY needed.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git wget unzip zip \
    build-essential python3 python3-pip \
    ripgrep fd-find jq sudo gosu \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create claude user with sudo access
RUN useradd -m -s /bin/bash claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude Code globally, accessible by claude user
RUN npm install -g @anthropic-ai/claude-code

## If git gets grumpy that /workspace is owned by the host user, not root...
##  if you see 'fatal: detected dubious ownership in repository at '/workspace'
##  uncomment this line
##RUN git config --global --add safe.directory /workspace


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
