#!/bin/sh
set -eu

rm -rf /tmp/setup-exe-dev
git clone --depth 1 https://github.com/goofansu/setup-exe-dev.git /tmp/setup-exe-dev
exec /tmp/setup-exe-dev/setup.sh
