First, add this alias to your bash profile or something.

```
alias claude-here='docker run -it --rm --name claude-dev \
  -v "$(pwd):/workspace" \
  -v "$HOME/.claude.json:/home/claude/.claude.json:ro" \
  -v "$HOME/.claude:/home/claude/.claude:ro" \
  claude-code-sandbox:latest'

source your file, like `source ~/.bashrc` to read it once, or restart your terminal
```

Next, build the container:

```
cd ~/Projects/claude-sandbox
docker build -t claude-code-sandbox .
```

Then go to your project and run it:

```
cd /home/flipmcf/Projects/my-project
run 'claude-here'
```
