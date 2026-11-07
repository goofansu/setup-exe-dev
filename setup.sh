#!/usr/bin/env bash
set -euo pipefail

# Provide fallback fonts for Tailwind CSS projects in agent-browser screenshots.
sudo apt install -y fonts-noto-core

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

# Install agent-browser and expose it outside the Node environment.
npm install --global agent-browser@0.41.2
ln -sfn "$HOME/node/bin/agent-browser" "$HOME/.local/bin/agent-browser"
hash -r
agent-browser --version

# Install pnpm and Bun as standalone executables.
curl --retry 5 --retry-all-errors -fsSL https://get.pnpm.io/install.sh | sh -
curl --retry 5 --retry-all-errors -fsSL https://bun.com/install | bash

export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export PATH="$PNPM_HOME/bin:$BUN_INSTALL/bin:$PATH"
hash -r

pnpm --version
bun --version

# Worktrunk appends /bin to its install prefix; keep binaries in ~/.local/bin.
curl --retry 5 --retry-all-errors -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh |
	WORKTRUNK_INSTALL_DIR="$HOME/.local" INSTALLER_NO_MODIFY_PATH=1 sh
hash -r
wt --version

# Install Pi extensions.
pi install npm:@goofansu/pi-web
pi install npm:@goofansu/pi-stuff

# Install Pi skills.
npx --yes skills add mattpocock/skills/skills/engineering -a pi -g -y
npx --yes skills add mattpocock/skills/skills/productivity -a pi -g -y
npx --yes skills add humanlayer/skills -s show-me -a pi -g -y
npx --yes skills add mitsuhiko/agent-stuff -s librarian -a pi -g -y
npx --yes skills add herdrdev/herdr -s herdr -a pi -g -y

# SSH drops COLORTERM, so tools fall back to 16 colors under TERM=xterm-rex.
COLORTERM_LINE='[ "$TERM" = xterm-rex ] && export COLORTERM=truecolor'
touch "$HOME/.bashrc"
grep -qxF "$COLORTERM_LINE" "$HOME/.bashrc" || printf '%s\n' "$COLORTERM_LINE" >>"$HOME/.bashrc"

printf '%s\n' 'Setup complete.'
