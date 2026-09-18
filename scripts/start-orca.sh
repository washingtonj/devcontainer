#!/usr/bin/env bash
set -euo pipefail

PORT="${ORCA_PORT:-6768}"
PAIRING_ADDRESS="${ORCA_PAIRING_ADDRESS:-}"
ARGS=(serve --port "$PORT" --pairing-address "$PAIRING_ADDRESS")
EXTRA_ARGS=()

if [[ -z "$PAIRING_ADDRESS" ]]; then
  echo "ERROR: ORCA_PAIRING_ADDRESS is not set." >&2
  echo "Set it to an address your Orca client can reach." >&2
  exit 1
fi

unset DISPLAY || true

if [[ "${ORCA_JSON:-0}" == "1" ]]; then
  ARGS+=(--json)
fi
if [[ "${ORCA_MOBILE_PAIRING:-0}" == "1" ]]; then
  ARGS+=(--mobile-pairing)
fi
if [[ "${ORCA_NO_SANDBOX:-0}" == "1" ]]; then
  export ELECTRON_DISABLE_SANDBOX=1
  EXTRA_ARGS+=(--no-sandbox)
fi

echo "Starting Orca serve on port ${PORT}"
echo "  pairing-address: ${PAIRING_ADDRESS}"
echo "  user: agent (1000)"

cd /home/agent
exec runuser --preserve-environment -u agent -- env \
  ASDF_DATA_DIR=/home/agent/.asdf \
  NPM_CONFIG_PREFIX=/home/agent/.npm-global \
  PATH=/home/agent/.npm-global/bin:/home/agent/.local/bin:/home/agent/.asdf/shims:/home/agent/.asdf/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/home/agent \
  XDG_CONFIG_HOME=/home/agent/.config \
  XDG_DATA_HOME=/home/agent/.local/share \
  XDG_CACHE_HOME=/home/agent/.cache \
  LIBGL_ALWAYS_SOFTWARE=1 \
  /opt/orca/squashfs-root/AppRun "${EXTRA_ARGS[@]}" "${ARGS[@]}"
