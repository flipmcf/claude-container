#!/bin/bash
set -e


# If we're still root, fix uid and re-exec as claude
if [ "$(id -u)" = "0" ]; then
    if [ -n "$HOST_UID" ]; then
        echo "Setting claude uid to $HOST_UID..."
        usermod -u $HOST_UID claude
    fi
    exec gosu claude "$0" "$@"
fi

# From here down we are running as claude

if [ -d /workspace/.git ]; then
    echo "Git repo detected. Copying to /work..."
    git config --global --add safe.directory /workspace
    git config --global --add safe.directory /work

    cp -a /workspace/. /work
    cd /work

    if git show-ref --verify --quiet refs/heads/claude; then
        echo "Switching to existing 'claude' branch..."
        git checkout claude
    else
        echo "Creating and switching to new 'claude' branch..."
        git checkout -b claude
    fi
else
    echo "Warning: /workspace is not a git repo. Skipping branch setup."
    cp -a /workspace/. /work 2>/dev/null || true
    cd /work
fi

echo "Updating Claude Code..."
npm install -g @anthropic-ai/claude-code --silent || echo "Warning: update failed, continuing with installed version..."

echo "Launching Claude..."
exec claude --dangerously-skip-permissions
