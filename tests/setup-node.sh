#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
mkdir -p "$TEST_HOME" "$FAKE_BIN"

cat >"$FAKE_BIN/uvx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == nodeenv && "$2" == -n && "$3" == lts ]]
target="$4"
mkdir -p "$target/bin"
cat >"$target/bin/node" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' 'v24.21.0'
SCRIPT
cat >"$target/bin/npm" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' '11.19.0'
SCRIPT
cat >"$target/bin/npx" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$target/bin/node" "$target/bin/npm" "$target/bin/npx"
EOF

cat >"$FAKE_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ -x "$HOME/.local/bin/wt" ]]
[[ "$(command -v wt)" == "$HOME/.local/bin/wt" ]]
printf '%s\n' "$*" >>"$HOME/pi-calls"
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/curl-calls"
case "${!#}" in
	https://get.pnpm.io/install.sh) destination="$HOME/.local/share/pnpm/bin/pnpm" ;;
	https://bun.com/install) destination="$HOME/.bun/bin/bun" ;;
	https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh)
		cat <<'SCRIPT'
[ "$WORKTRUNK_INSTALL_DIR" = "$HOME/.local/bin" ] || exit 1
[ "$INSTALLER_NO_MODIFY_PATH" = 1 ] || exit 1
mkdir -p "$WORKTRUNK_INSTALL_DIR"
printf '%s\n' '#!/usr/bin/env bash' "printf '%s\\n' 'wt test version'" >"$WORKTRUNK_INSTALL_DIR/wt"
chmod +x "$WORKTRUNK_INSTALL_DIR/wt"
SCRIPT
		exit 0
		;;
	*) exit 99 ;;
esac
cat <<SCRIPT
mkdir -p "$(dirname "$destination")"
printf '%s\\n' '#!/usr/bin/env bash' "printf '%s\\n' 'test version'" >"$destination"
chmod +x "$destination"
SCRIPT
EOF

chmod +x "$FAKE_BIN/uvx" "$FAKE_BIN/pi" "$FAKE_BIN/curl"

HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/setup.sh"

for executable in node npm npx; do
	link="$TEST_HOME/.local/bin/$executable"
	[[ -L "$link" ]]
	[[ "$(readlink "$link")" == "$TEST_HOME/node/bin/$executable" ]]
done

[[ ! -e "$TEST_HOME/.nvm" ]]

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

printf '%s\n' 'setup Node.js, pnpm, Bun, Worktrunk, and Pi extension installation test passed'
