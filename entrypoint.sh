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

# Load repo-specific env (GITHUB_TOKEN, etc.) from .claude.env if mounted
if [ -f /tmp/.claude.env ]; then
    echo "Loading repo-specific environment from .claude.env..."
    set -a
    . /tmp/.claude.env
    set +a
fi

if [ -d /workspace/.git ]; then
    echo "Git repo detected. Copying to /work..."
    git config --global --add safe.directory /workspace
    git config --global --add safe.directory /work

    cp -a /workspace/. /work
    cd /work

    # Git access is HTTPS + fine-grained PAT only; SSH keys are never used.
    if [ -n "$GITHUB_TOKEN" ]; then
        case "$GITHUB_TOKEN" in
            github_pat_*) ;;
            *)
                echo "ERROR: GITHUB_TOKEN is not a fine-grained personal access token (expected 'github_pat_' prefix)." >&2
                echo "Create one scoped to this repo; see .claude.env.example." >&2
                exit 1
                ;;
        esac
        git config --global credential.helper '!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f'
    else
        echo "Warning: no GITHUB_TOKEN set. Git remote access will be read-only at best."
    fi

    # Rewrite any SSH remote to HTTPS (scp-style and ssh:// forms). HTTPS remotes are left alone.
    # This only touches the /work copy's config; the host repo is unchanged.
    for remote in $(git remote); do
        for kind in url pushurl; do
            old=$(git config --get "remote.$remote.$kind" 2>/dev/null) || continue
            new=$(printf '%s' "$old" | sed -E \
                -e 's#^ssh://([^@/]+@)?([^/:]+)(:[0-9]+)?/#https://\2/#' \
                -e 's#^[^@/:]+@([^:/]+):/?#https://\1/#')
            if [ "$new" != "$old" ]; then
                echo "Rewriting SSH remote '$remote' ($kind) to HTTPS: $new"
                git config "remote.$remote.$kind" "$new"
            fi
        done
    done
    # Safety net for submodules and any remote added later
    git config --global url."https://github.com/".insteadOf "git@github.com:"
    git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"

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
claude update || echo "Warning: update failed, continuing with installed version..."


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
