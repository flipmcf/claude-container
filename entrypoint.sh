#!/bin/bash
set -e


# If we're still root, fix uid and re-exec as claude
if [ "$(id -u)" = "0" ]; then
    if [ -n "$HOST_UID" ]; then
        echo "Setting claude uid to $HOST_UID..."
        usermod -u $HOST_UID claude
    fi
    # Copy only auth-related files (not sessions/projects which can confuse Claude)
    if [ -d /tmp/.claude-host ]; then
        mkdir -p /home/claude/.claude
        for f in .credentials.json settings.json; do
            if [ -f "/tmp/.claude-host/$f" ]; then
                cp "/tmp/.claude-host/$f" "/home/claude/.claude/$f"
            fi
        done
        chown -R claude:claude /home/claude/.claude
    fi
    if [ -f /tmp/.claude.json ]; then
        cp /tmp/.claude.json /home/claude/.claude.json
        chown claude:claude /home/claude/.claude.json
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

    # Configure git to use GITHUB_TOKEN for push/pull/fetch
    if [ -n "$GITHUB_TOKEN" ]; then
        git config --global credential.helper '!f() { echo "password=$GITHUB_TOKEN"; }; f'
    fi

    # Clean working tree so branch switch works (host files are untouched)
    git checkout -- . 2>/dev/null || true
    git clean -fd 2>/dev/null || true

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

# Check auth status
if [ -f /home/claude/.claude/.credentials.json ]; then
    echo "OAuth credentials loaded."
elif [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "API key configured."
else
    echo "WARNING: No auth configured. Claude will prompt for login."
    echo "  Option A: Run 'claude' on your host to set up OAuth"
    echo "  Option B: Set ANTHROPIC_API_KEY in .env"
fi

echo "Launching Claude..."
exec claude --dangerously-skip-permissions
