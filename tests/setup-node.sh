#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
mkdir -p "$TEST_HOME" "$FAKE_BIN"

cat >"$FAKE_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/sudo-calls"
EOF

# Keep each heredoc small: bash 5.3 on macOS can hang on large heredocs.
FAKE_NPM="$TEST_ROOT/fake-npm"
cat >"$FAKE_NPM" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == --version ]] && { printf '%s\n' '11.19.0'; exit 0; }
printf '%s\n' "$*" >>"$HOME/npm-calls"
[[ "$1 $2" == "install --global" ]] || exit 0
# Global installs land beside the real npm, not the ~/.local/bin link.
bin="$(dirname "$(readlink -f "$0")")/${3%@*}"
printf '%s\n' '#!/usr/bin/env bash' 'echo test version' >"$bin"
chmod +x "$bin"
EOF

cat >"$FAKE_BIN/uvx" <<EOF
#!/usr/bin/env bash
set -euo pipefail
[[ "\$1" == nodeenv && "\$2" == -n && "\$3" == lts ]]
target="\$4"
mkdir -p "\$target/bin"
cp "$FAKE_NPM" "\$target/bin/npm"
cat >"\$target/bin/node" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' 'v24.21.0'
SCRIPT
cat >"\$target/bin/npx" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "\$target/bin/node" "\$target/bin/npm" "\$target/bin/npx"
EOF

cat >"$FAKE_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ -x "$HOME/.local/bin/wt" ]]
[[ "$(command -v wt)" == "$HOME/.local/bin/wt" ]]
printf '%s\n' "$*" >>"$HOME/pi-calls"
EOF

cat >"$FAKE_BIN/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/claude-calls"
EOF

# Match the upstream installer's cargo-home layout: the prefix gets /bin.
export FAKE_WORKTRUNK_INSTALLER="$TEST_ROOT/fake-worktrunk-installer"
cat >"$FAKE_WORKTRUNK_INSTALLER" <<'EOF'
[ "$INSTALLER_NO_MODIFY_PATH" = 1 ] || exit 1
mkdir -p "$WORKTRUNK_INSTALL_DIR/bin"
printf '%s\n' '#!/usr/bin/env bash' 'echo wt test version' >"$WORKTRUNK_INSTALL_DIR/bin/wt"
chmod +x "$WORKTRUNK_INSTALL_DIR/bin/wt"
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/curl-calls"
case "${!#}" in
	https://get.pnpm.io/install.sh) destination="$HOME/.local/share/pnpm/bin/pnpm" ;;
	https://bun.com/install) destination="$HOME/.bun/bin/bun" ;;
	*/worktrunk-installer.sh) exec cat "$FAKE_WORKTRUNK_INSTALLER" ;;
	*) exit 99 ;;
esac
cat <<SCRIPT
mkdir -p "$(dirname "$destination")"
printf '%s\\n' '#!/usr/bin/env bash' "printf '%s\\n' 'test version'" >"$destination"
chmod +x "$destination"
SCRIPT
EOF

chmod +x "$FAKE_BIN/sudo" "$FAKE_BIN/uvx" "$FAKE_BIN/pi" "$FAKE_BIN/claude" "$FAKE_BIN/curl"

HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/setup.sh"

printf '%s\n' 'apt install -y fonts-noto-core' >"$TEST_ROOT/expected-sudo-calls"
diff -u "$TEST_ROOT/expected-sudo-calls" "$TEST_HOME/sudo-calls"

for executable in node npm npx; do
	link="$TEST_HOME/.local/bin/$executable"
	[[ -L "$link" ]]
	[[ "$(readlink "$link")" == "$TEST_HOME/node/bin/$executable" ]]
done

[[ ! -e "$TEST_HOME/.nvm" ]]

printf '%s\n' 'install --global agent-browser@0.43.0' >"$TEST_ROOT/expected-npm-calls"
diff -u "$TEST_ROOT/expected-npm-calls" "$TEST_HOME/npm-calls"

agent_browser_link="$TEST_HOME/.local/bin/agent-browser"
[[ -L "$agent_browser_link" ]]
[[ "$(readlink "$agent_browser_link")" == "$TEST_HOME/node/bin/agent-browser" ]]

cat >"$TEST_ROOT/expected-curl-calls" <<'EOF'
--retry 5 --retry-all-errors -fsSL https://get.pnpm.io/install.sh
--retry 5 --retry-all-errors -fsSL https://bun.com/install
--retry 5 --retry-all-errors -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh
EOF

diff -u "$TEST_ROOT/expected-curl-calls" "$TEST_HOME/curl-calls"

cat >"$TEST_ROOT/expected-pi-calls" <<'EOF'
install npm:@goofansu/pi-web
install npm:@goofansu/pi-stuff
EOF

diff -u "$TEST_ROOT/expected-pi-calls" "$TEST_HOME/pi-calls"

cat >"$TEST_ROOT/expected-claude-calls" <<'EOF'
plugin install mattpocock-skills
plugin install worktrunk --marketplace max-sixty/worktrunk
EOF
diff -u "$TEST_ROOT/expected-claude-calls" "$TEST_HOME/claude-calls"

colorterm_in_shell() {
	HOME="$TEST_HOME" TERM="$1" COLORTERM= bash -c '. "$HOME/.bashrc"; printf %s "${COLORTERM-}"'
}
[[ "$(colorterm_in_shell xterm-rex)" == truecolor ]]
[[ -z "$(colorterm_in_shell xterm-256color)" ]]

HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/setup.sh" >/dev/null
[[ "$(grep -c COLORTERM "$TEST_HOME/.bashrc")" == 1 ]]

printf '%s\n' 'setup fonts, Node.js, agent-browser, pnpm, Bun, Worktrunk, Pi extension, and Claude plugin installation test passed'
