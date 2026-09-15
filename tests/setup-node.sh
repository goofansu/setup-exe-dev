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
printf '%s\n' "$*" >>"$HOME/npx-calls"
SCRIPT
chmod +x "$target/bin/node" "$target/bin/npm" "$target/bin/npx"
EOF

cat >"$FAKE_BIN/pi" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HOME/pi-calls"
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'setup.sh unexpectedly attempted to install NVM' >&2
exit 99
EOF

chmod +x "$FAKE_BIN/uvx" "$FAKE_BIN/pi" "$FAKE_BIN/curl"

HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/setup.sh"

for executable in node npm npx; do
	link="$TEST_HOME/.local/bin/$executable"
	[[ -L "$link" ]]
	[[ "$(readlink "$link")" == "$TEST_HOME/node/bin/$executable" ]]
done

[[ ! -e "$TEST_HOME/.nvm" ]]
cat >"$TEST_ROOT/expected-pi-calls" <<'EOF'
install npm:@goofansu/pi-stuff
install npm:@goofansu/pi-subagent
install npm:@goofansu/pi-web
install npm:pi-autoresearch
EOF

cat >"$TEST_ROOT/expected-npx-calls" <<'EOF'
skills add goofansu/skills/skills/engineering -a pi -g -y
skills add mattpocock/skills/skills/engineering -a pi -g -y
skills add mattpocock/skills/skills/productivity -a pi -g -y
skills add humanlayer/skills -s show-me -a pi -g -y
skills add herdrdev/herdr -s herdr -a pi -g -y
EOF

diff -u "$TEST_ROOT/expected-pi-calls" "$TEST_HOME/pi-calls"
diff -u "$TEST_ROOT/expected-npx-calls" "$TEST_HOME/npx-calls"

printf '%s\n' 'setup node installation test passed'
