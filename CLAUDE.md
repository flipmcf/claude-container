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
- `GITHUB_TOKEN` from `.env` configures git credential helper for push/pull/fetch
- Git identity: "Claude (AI Assistant)" / claude@openforgesolutions.com

## Key Files

- `claude-here` — bash function (not alias) sourced by user; loads `.env`, runs `docker run`
- `entrypoint.sh` — UID matching via gosu, auth copy, repo copy, branch setup, launches claude
- `.env` — gitignored, holds `GITHUB_TOKEN` (and optionally `ANTHROPIC_API_KEY`)
- `.env.example` — documents both auth options

## Known Issues

- Claude Code npm update fails inside container (non-blocking, uses baked-in version)
- First-run trust prompt appears every launch (ephemeral container, no persisted state)
- `claude-here` function name uses underscore (`claude_here`) with alias wrapper because bash doesn't allow hyphens in function names

## Build & Run

```bash
docker build -t claude-code-sandbox:latest .
source claude-here
claude-here
```
