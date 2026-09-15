#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Install the latest Node.js LTS release if it is not already available.
export PATH="$HOME/.local/bin:$PATH"
NODE_ENV="$HOME/node"

if [[ -x "$NODE_ENV/bin/node" && -x "$NODE_ENV/bin/npm" && -x "$NODE_ENV/bin/npx" ]]; then
	printf 'Node.js is already installed: %s\n' "$("$NODE_ENV/bin/node" --version)"
else
	rm -rf "$NODE_ENV"
	uvx nodeenv -n lts "$NODE_ENV"
fi

mkdir -p "$HOME/.local/bin"
for executable in node npm npx; do
	ln -sfn "$NODE_ENV/bin/$executable" "$HOME/.local/bin/$executable"
done
hash -r

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
