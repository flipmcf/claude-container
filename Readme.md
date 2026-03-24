PUT THIS IN YOUR bash profile or something.

```
alias claude-here='docker run -it --rm --name claude-dev \
  -v "$(pwd):/workspace" \
  -v "$HOME/.claude.json:/home/claude/.claude.json:ro" \
  -v "$HOME/.claude:/home/claude/.claude:ro" \
  claude-code-sandbox:latest'

source your file, like `source ~/.bashrc` to read it once, or restart your terminal

Then, CD to the git repo you want to work with in Claude:
cd /home/flipmcf/Projects/my-project
and run 'claude-here'
