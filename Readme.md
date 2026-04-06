# Claude Code Sandbox

A containerized environment where Claude Code operates as an isolated developer with its own workspace, git identity, and toolchain.

## Prerequisites

- Docker
- An Anthropic API key
- (Optional) A GitHub fine-grained personal access token

## Setup

### 1. Get your Anthropic API Key

1. Go to https://console.anthropic.com/settings/keys
2. Click "Create Key"
3. Give it a name (e.g. "claude-sandbox")
4. Copy the key (starts with `sk-ant-`)

> **Note:** This requires an Anthropic account with API access. This is separate from a Claude Pro/Max subscription. You'll need to add billing at https://console.anthropic.com/settings/billing.

### 2. (Optional) Get a GitHub Personal Access Token

This lets Claude create PRs, push branches, and manage issues.

1. Go to https://github.com/settings/personal-access-tokens/new
2. Select "Fine-grained token"
3. Name it (e.g. "claude-sandbox")
4. Set repository access to only the repos you want Claude to work on
5. Grant these permissions:
   - **Contents**: Read and write (push commits/branches)
   - **Pull requests**: Read and write (create/update PRs)
   - **Issues**: Read and write (create/close issues)
6. Copy the token

### 3. Configure your keys

```bash
cd ~/Projects/claude-sandbox   # or wherever you cloned this repo
cp .env.example .env
```

Edit `.env` and fill in your keys:

```
ANTHROPIC_API_KEY=sk-ant-your_key_here
GITHUB_TOKEN=ghp_your_token_here
```

> **Important:** `.env` is gitignored and will never be committed.

### 4. Build the container

```bash
docker build -t claude-code-sandbox:latest .
```

### 5. Source the launcher

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
source ~/Projects/claude-sandbox/claude-here
```

Then reload your shell:

```bash
source ~/.bashrc  # or ~/.zshrc
```

## Usage

Navigate to any git repo and launch:

```bash
cd ~/Projects/my-project
claude-here
```

### What happens on launch

1. Your repo is copied into the container (host files are never modified)
2. Claude switches to a `claude` branch inside the container
3. Claude Code launches with full permissions

### Creating Pull Requests

Claude can create PRs directly if you configured a GitHub token:

```
You: "Create a PR for these changes"
Claude: [pushes branch, creates PR via gh CLI]
```

### Docker-in-Docker

Claude can build and test containers if the Docker socket is mounted (included by default):

```bash
# Inside the container, Claude can run:
docker build -t my-app:test .
docker compose up -d
```

## Git Identity

Claude's commits show as:
- **Name:** Claude (AI Assistant)
- **Email:** claude@openforgesolutions.com

## Security

- Your API keys live only in `.env` (gitignored, never committed)
- The host repo is copied, not modified — Claude works on an isolated copy
- GitHub token can be scoped to specific repos with minimal permissions
- Container is ephemeral — destroyed on exit

## Troubleshooting

### Claude hangs on launch

Make sure your `ANTHROPIC_API_KEY` is set in `.env`. Without it, Claude tries OAuth which requires a browser the container can't open.

### "Permission denied" errors

Ensure `HOST_UID` is being passed (it is by default in `claude-here`).

### GitHub CLI not working

Check that `GITHUB_TOKEN` is set in `.env`. Verify the token has the right permissions on the repos you need.

---

**Created by:** Michael McFadden (@flipmcf) / OpenForge Solutions
