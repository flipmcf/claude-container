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
    echo "Git repo detected."
    cd /workspace

    git config --global --add safe.directory /workspace

    git stash --quiet 2>/dev/null || true

    if git show-ref --verify --quiet refs/heads/claude; then
        echo "Switching to existing 'claude' branch..."
        git checkout claude
    else
        echo "Creating and switching to new 'claude' branch..."
        git checkout -b claude
    fi
else
    echo "Warning: /workspace is not a git repo. Skipping branch setup."
fi

echo "Updating Claude Code..."
npm install -g @anthropic-ai/claude-code --silent || echo "Warning: update failed, continuing with installed version..."

echo "Launching Claude..."
claude --dangerously-skip-permissions
EXIT_CODE=$?

if [ $EXIT_CODE -eq 1 ]; then
    # Check if it looks like an auth failure
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│              Claude exited unexpectedly.                 │"
    echo "│                                                          │"
    echo "│  This may be due to an expired OAuth token.             │"
    echo "│                                                          │"
    echo "│  To fix:                                                 │"
    echo "│    1. Exit this container                                │"
    echo "│    2. Run 'claude' on your HOST machine                  │"
    echo "│    3. Complete the login flow in your browser            │"
    echo "│    4. Re-run 'claude-here' to restart the container      │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
fi

exec bash
