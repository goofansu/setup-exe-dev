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

# Install the pi skills and extensions.
rm -rf /tmp/pi-stuff
git clone --depth 1 https://github.com/goofansu/pi-stuff.git /tmp/pi-stuff
make -C /tmp/pi-stuff install-exe-dev

# Install the Herdr configuration.
mkdir -p "$HOME/.config/herdr"
install -m 0644 "$SCRIPT_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

printf '%s\n' 'Setup complete.'
