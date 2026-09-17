#!/usr/bin/env bash
set -euo pipefail

HOME_DIR=/home/agent
SNAPSHOT_DIR=/opt/devserver/agent-home

if [[ ! -d "$HOME_DIR/.asdf/installs/nodejs" ]]; then
  if [[ -e "$HOME_DIR/.asdf" ]]; then
    echo "ERROR: $HOME_DIR/.asdf exists but ASDF data is incomplete." >&2
    exit 1
  fi

  cp -a "$SNAPSHOT_DIR/.asdf" "$HOME_DIR/.asdf"
  chown -R agent:agent "$HOME_DIR/.asdf"
fi

if [[ -f "$SNAPSHOT_DIR/.tool-versions" && ! -f "$HOME_DIR/.tool-versions" ]]; then
  cp -a "$SNAPSHOT_DIR/.tool-versions" "$HOME_DIR/.tool-versions"
  chown agent:agent "$HOME_DIR/.tool-versions"
fi

mkdir -p "$HOME_DIR/ssh" "$HOME_DIR/workspace"
chown agent:agent "$HOME_DIR/ssh" "$HOME_DIR/workspace"

shopt -s nullglob
env_files=(/etc/devserver/env.d/*.env)
shopt -u nullglob

for env_file in "${env_files[@]}"; do
  source "$env_file"
done
