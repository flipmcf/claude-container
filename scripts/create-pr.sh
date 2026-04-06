#!/bin/bash
# Helper script for creating Pull Requests from the claude branch
# This can be called by Claude Code when asked to "create a PR"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Not in a git repository"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    error "GitHub CLI not authenticated"
    echo "  Run 'gh auth login' on your host machine, then restart the container"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "claude" ]; then
    warn "Not on 'claude' branch (currently on '$CURRENT_BRANCH')"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if there are commits to push
if ! git log origin/main..$CURRENT_BRANCH --oneline 2>/dev/null | grep -q .; then
    error "No commits to create PR from"
    echo "  The '$CURRENT_BRANCH' branch has no new commits compared to origin/main"
    exit 1
fi

# Show commits that will be in the PR
echo ""
info "Commits that will be included in the PR:"
git log origin/main..$CURRENT_BRANCH --oneline --decorate
echo ""

# Generate PR title from commits
PR_TITLE=$(git log origin/main..$CURRENT_BRANCH --format=%s | head -1)

# Generate PR body from commits
PR_BODY=$(cat <<EOF
## Changes

$(git log origin/main..$CURRENT_BRANCH --format="- %s" | sed 's/^/  /')

## Files Changed

\`\`\`
$(git diff origin/main..$CURRENT_BRANCH --stat)
\`\`\`

---
*This PR was created by Claude (AI Assistant)*
EOF
)

# Interactive mode or use defaults
if [ "$1" = "--auto" ]; then
    # Auto mode: use generated title and body
    info "Auto mode: Using generated PR title and body"
else
    # Interactive mode
    echo "Proposed PR title:"
    echo "  $PR_TITLE"
    echo ""
    read -p "Use this title? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "Enter PR title: " PR_TITLE
    fi
fi

# Push the branch
info "Pushing $CURRENT_BRANCH to origin..."
if ! git push origin $CURRENT_BRANCH 2>&1; then
    error "Failed to push branch"
    exit 1
fi
success "Branch pushed"

# Create the PR
info "Creating pull request..."

if gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head $CURRENT_BRANCH; then
    
    echo ""
    success "Pull request created successfully!"
    
    # Get PR URL
    PR_URL=$(gh pr view $CURRENT_BRANCH --json url -q .url)
    info "View at: $PR_URL"
    
else
    error "Failed to create pull request"
    exit 1
fi
