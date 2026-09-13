#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Install Node.js 24 if it is not already available.
if command -v node >/dev/null 2>&1 && [[ "$(node --version)" == v24.* ]]; then
	printf 'Node.js 24 is already installed: %s\n' "$(node --version)"
else
	export NVM_DIR="$HOME/.nvm"

	if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
	fi

	# Load nvm without restarting the shell.
	# shellcheck source=/dev/null
	source "$NVM_DIR/nvm.sh"

	if nvm version 24 >/dev/null 2>&1; then
		nvm use 24
	else
		nvm install 24
	fi
fi

# Report the active versions.
node --version
npm --version

# Install Herdr configuration.
mkdir -p "$HOME/.config/herdr"
install -m 0644 "$SCRIPT_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Install Pi configuration.
mkdir -p "$HOME/.pi/agent"
install -m 0644 "$SCRIPT_DIR/config/pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"

# Install Pi extensions.
pi install npm:@goofansu/pi-stuff
pi install npm:@goofansu/pi-subagent
pi install npm:@goofansu/pi-web
pi install npm:pi-autoresearch

# Install Pi skills.
npx skills add goofansu/skills/skills/engineering -a pi -g -y
npx skills add mattpocock/skills/skills/engineering -a pi -g -y
npx skills add mattpocock/skills/skills/productivity -a pi -g -y
npx skills add humanlayer/skills -s show-me -a pi -g -y
npx skills add herdrdev/herdr -s herdr -a pi -g -y

printf '%s\n' 'Setup complete.'
