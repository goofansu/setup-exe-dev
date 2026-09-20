#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
NODE_BIN="$TEST_HOME/node/bin"
mkdir -p "$TEST_HOME" "$FAKE_BIN" "$NODE_BIN"

cat >"$NODE_BIN/node" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'v24.21.0'
EOF

cat >"$NODE_BIN/npm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '11.19.0'
EOF

cat >"$NODE_BIN/npx" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HOME/npx-calls"
EOF

cat >"$FAKE_BIN/pi" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HOME/pi-calls"
EOF

cat >"$FAKE_BIN/uvx" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'setup.sh unexpectedly attempted to reinstall Node.js' >&2
exit 99
EOF

chmod +x "$NODE_BIN/node" "$NODE_BIN/npm" "$NODE_BIN/npx"
chmod +x "$FAKE_BIN/pi" "$FAKE_BIN/uvx"

HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/setup.sh"

cmp "$REPO_ROOT/config/pi/keybindings.json" "$TEST_HOME/.pi/agent/keybindings.json"

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

printf '%s\n' 'setup Pi configuration test passed'
