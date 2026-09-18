#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/devserver/configure-runtime.sh
/usr/local/lib/devserver/configure-ssh.sh
exec /usr/local/lib/devserver/start-orca.sh
