 #!/usr/bin/env pwsh
  # Launch Claude Code sandbox in the current directory.
  # Install: place on PATH (e.g. copy claude-here.ps1 to a folder in $env:Path)

  $ErrorActionPreference = 'Stop'

  $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

  # Load .env if it exists (KEY=VALUE per line, with optional `export ` and quotes)
  $envFile = Join-Path $ScriptDir '.env'
  if (Test-Path $envFile) {
      Get-Content $envFile | ForEach-Object {
          if ($_ -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
              $value = $matches[2] -replace '^["'']|["'']$',''
              Set-Item -Path "env:$($matches[1])" -Value $value
          }
      }
  }

  $dockerArgs = @(
      'run','-it','--rm','--name','claude-dev',
      '-v', "${PWD}:/workspace",
      '-v', '/var/run/docker.sock:/var/run/docker.sock'
  )

  # Host Claude config (skip if missing — Docker would otherwise create empty dirs)
  $claudeDir = Join-Path $HOME '.claude'
  if (Test-Path $claudeDir -PathType Container) {
      $dockerArgs += @('-v', "${claudeDir}:/tmp/.claude-host:ro")
  }
  $claudeJson = Join-Path $HOME '.claude.json'
  if (Test-Path $claudeJson -PathType Leaf) {
      $dockerArgs += @('-v', "${claudeJson}:/tmp/.claude.json:ro")
  }

  # GitHub auth: prefer token; else mount host gh config
  if ($env:GITHUB_TOKEN) {
      $dockerArgs += @('-e', "GITHUB_TOKEN=$env:GITHUB_TOKEN")
  } else {
      $ghConfig = Join-Path $env:APPDATA 'GitHub CLI'
      if (Test-Path $ghConfig -PathType Container) {
          $dockerArgs += @('-v', "${ghConfig}:/home/claude/.config/gh:ro")
      }
  }

  if ($env:ANTHROPIC_API_KEY) {
      $dockerArgs += @('-e', "ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY")
  }

  $dockerArgs += 'claude-code-sandbox:latest'

  & docker @dockerArgs