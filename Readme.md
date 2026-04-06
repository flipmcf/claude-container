# Claude Code Sandbox

A containerized environment where Claude Code operates as an isolated developer with its own workspace, git identity, and toolchain.

## Prerequisites

- Docker
- An Anthropic API key
- (Optional) A GitHub fine-grained personal access token

## Setup

### 1. Authenticate Claude (pick one)

**Option A: Claude Pro/Max subscription** (recommended if you already have one)

Your existing subscription works out of the box. Just make sure you've logged in on your host machine:

```bash
claude
```

Complete the browser login flow. The container will automatically mount your OAuth credentials from `~/.claude/.credentials.json`.

> **Note:** This uses your existing Pro/Max subscription. No additional API billing needed.

**Option B: Anthropic API key** (pay-per-use)

1. Go to https://console.anthropic.com/settings/keys
2. Click "Create Key"
3. Copy the key (starts with `sk-ant-`)
4. Add prepaid credits at https://console.anthropic.com/settings/billing

> **Note:** API access is billed separately from a Claude Pro/Max subscription. You pay per token used.

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

Edit `.env`:
- If using **Option A** (Pro/Max): no Claude auth needed in `.env`, just add your GitHub token if desired
- If using **Option B** (API key): uncomment and fill in `ANTHROPIC_API_KEY`

See `.env.example` for details on each setting.

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

Make sure auth is configured. Either:
- **Pro/Max users:** Run `claude` on your host and complete the browser login. The container mounts `~/.claude/.credentials.json` automatically.
- **API key users:** Set `ANTHROPIC_API_KEY` in `.env`.

### "Credit balance too low"

You're using an API key (`ANTHROPIC_API_KEY`) but haven't added prepaid credits. Either add credits at https://console.anthropic.com/settings/billing, or switch to Option A (Pro/Max subscription) by removing the API key from `.env` and using OAuth instead.

### "Permission denied" errors

Ensure `HOST_UID` is being passed (it is by default in `claude-here`).

### GitHub CLI not working

Check that `GITHUB_TOKEN` is set in `.env`. Verify the token has the right permissions on the repos you need.

---

**Created by:** Michael McFadden (@flipmcf) / OpenForge Solutions
