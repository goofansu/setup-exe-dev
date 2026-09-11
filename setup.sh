#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Install Node.js 24 only when it is not already available.
if command -v node >/dev/null 2>&1 && [[ "$(node --version)" == v24.* ]]; then
  printf 'Node.js 24 is already installed: %s\n' "$(node --version)"
else
  export NVM_DIR="$HOME/.nvm"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
  fi

  # Load nvm without restarting the shell.
  # shellcheck source=/dev/null
  \. "$NVM_DIR/nvm.sh"

  if nvm version 24 >/dev/null 2>&1; then
    nvm use 24
  else
    nvm install 24
  fi
fi

# Report the versions in use.
node --version
npm --version

# Install global pi skills.
npx skills add mattpocock/skills/skills/engineering -s tdd -s code-review -a pi -g -y
npx skills add mattpocock/skills/skills/productivity -s handoff -a pi -g -y
npx skills add herdrdev/herdr -s herdr -a pi -g -y

# Install the pi-subagent extension.
pi install https://github.com/goofansu/pi-subagent

# Install the Herdr configuration.
mkdir -p "$HOME/.config/herdr"
install -m 0644 "$SCRIPT_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Install the pi configuration.
mkdir -p "$HOME/.pi/agent/agents"
install -m 0644 "$SCRIPT_DIR"/config/pi/agents/*.md "$HOME/.pi/agent/agents/"
install -m 0644 "$SCRIPT_DIR/config/pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"

printf '%s\n' 'Setup complete.'
