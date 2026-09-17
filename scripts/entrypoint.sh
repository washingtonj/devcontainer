#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=/usr/local/lib/devserver

source "$SCRIPT_DIR/prepare-agent-runtime.sh"
"$SCRIPT_DIR/configure-ssh.sh"
exec "$SCRIPT_DIR/start-orca.sh"
