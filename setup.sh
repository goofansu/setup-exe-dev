#!/usr/bin/env bash
set -euo pipefail

# Install the latest Node.js LTS release.
export PATH="$HOME/.local/bin:$PATH"
NODE_ENV="$HOME/node"

rm -rf "$NODE_ENV"
uvx nodeenv -n lts "$NODE_ENV"

mkdir -p "$HOME/.local/bin"
for executable in node npm npx; do
	ln -sfn "$NODE_ENV/bin/$executable" "$HOME/.local/bin/$executable"
done
hash -r

# Report the active versions.
node --version
npm --version

# Install pnpm and Bun as standalone executables.
curl --retry 5 --retry-all-errors -fsSL https://get.pnpm.io/install.sh | sh -
curl --retry 5 --retry-all-errors -fsSL https://bun.com/install | bash

export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export PATH="$PNPM_HOME/bin:$BUN_INSTALL/bin:$PATH"
hash -r

pnpm --version
bun --version

# Install Pi extensions.
pi install npm:@goofansu/pi-stuff
pi install npm:@goofansu/pi-subagent
pi install npm:@goofansu/pi-web
pi install npm:pi-autoresearch

# Install Pi skills.
npx --yes skills add goofansu/skills/skills/engineering -a pi -g -y
npx --yes skills add mattpocock/skills/skills/engineering -a pi -g -y
npx --yes skills add mattpocock/skills/skills/productivity -a pi -g -y
npx --yes skills add humanlayer/skills -s show-me -s visual-pr -a pi -g -y
npx --yes skills add herdrdev/herdr -s herdr -a pi -g -y

printf '%s\n' 'Setup complete.'
