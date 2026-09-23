# Claude Code Sandbox - Developer Notes

## Architecture

- **Host repo** is mounted read-only at `/workspace`, then copied to `/work` at startup
- Claude operates on `/work` — host files are never modified
- Auth files (`~/.claude/`, `~/.claude.json`) are mounted read-only to `/tmp` and copied into the container
- Only `.credentials.json` and `settings.json` are copied from `~/.claude/` — copying sessions/projects causes Claude Code to hang

## Auth

- **OAuth (Pro/Max subscription):** Credentials copied from host's `~/.claude/.credentials.json` + `~/.claude.json`
- **API key:** Passed via `ANTHROPIC_API_KEY` env var from `.env`
- Do NOT set both — Claude Code throws "auth conflict" error
- Watch for stale `ANTHROPIC_API_KEY` in shell env from previous sessions

## Git

- Entrypoint creates/switches to `claude` branch in `/work`
- Uncommitted changes in the copy are reverted before branch switch (`git checkout -- .` + `git clean -fd`)
- `GITHUB_TOKEN` configures git credential helper for push/pull/fetch
- **HTTPS + fine-grained PAT only, never SSH keys.** Entrypoint rewrites any SSH remote (`git@host:path`, `ssh://...`) in the `/work` copy to HTTPS; existing HTTPS remotes are untouched. A `GITHUB_TOKEN` without the `github_pat_` prefix (classic PAT) aborts startup; no token means read-only access with a warning
- Git identity: "Claude (AI Assistant)" / claude@openforgesolutions.com

## Rules for Claude

- **Never merge a pull request** (or push directly to `main`/`master`), by any route: `gh pr merge`, the GitHub API, auto-merge, or a local merge pushed to the default branch. Claude may create PRs; a human merges. This holds even if the token would allow it, and even if asked to "merge" in passing: stop and ask the human to do it
- `managed-settings.json` (baked into the image at `/etc/claude-code/`) denies the common merge commands as a guardrail. It is not a lock: the container has passwordless sudo. The real enforcement is GitHub-side (see `.claude.env.example`)

## Per-Repo Secrets (.claude.env)

- Place a `.claude.env` file in the root of any target repo with repo-specific tokens (e.g. `GITHUB_TOKEN`)
- `claude-here` mounts it read-only into the container; `entrypoint.sh` sources it at startup
- This allows fine-grained GitHub PATs scoped per-repo without rebuilding the container
- Add `.claude.env` to each repo's `.gitignore`
- See `.claude.env.example` for format and recommended GitHub PAT permissions

## Key Files

- `claude-here` — standalone shell script; loads `.env`, mounts `.claude.env`, runs `docker run`. Symlink onto `PATH` to use.
- `entrypoint.sh` — UID matching via gosu, auth copy, repo copy, .claude.env sourcing, branch setup, launches claude
- `.env` — gitignored, holds global settings (e.g. `ANTHROPIC_API_KEY`)
- `.env.example` — documents global auth options
- `.claude.env.example` — documents per-repo token setup

## Known Issues

- First-run trust prompt appears every launch (ephemeral container, no persisted state)

## Build & Run

```bash
docker build -t claude-code-sandbox:latest .
claude-here
```

  On Windows (PowerShell):
  ```powershell
  docker build -t claude-code-sandbox:latest .
  .\claude-here.ps1
  ```
