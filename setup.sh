#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Install nvm and Node.js 24.
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash

# Load nvm without restarting the shell.
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
\. "$NVM_DIR/nvm.sh"

nvm install 24

# Verify the installed versions.
node -v # Expected: v24.21.0
npm -v  # Expected: 11.19.0

# Install global Codex skills.
npx skills add mattpocock/skills/skills/engineering -s tdd -s code-review -a pi -g -y
npx skills add herdrdev/herdr -s herdr -a pi -g -y

# Install the pi-subagent extension.
pi install https://github.com/goofansu/pi-subagent

# Install the Herdr configuration.
mkdir -p "$HOME/.config/herdr"
install -m 0644 "$SCRIPT_DIR/config/herdr.toml" "$HOME/.config/herdr/config.toml"

# Install pi agent definitions.
mkdir -p "$HOME/.pi/agent/agents"
install -m 0644 "$SCRIPT_DIR"/agents/*.md "$HOME/.pi/agent/agents/"

printf '%s\n' 'Setup complete.'
