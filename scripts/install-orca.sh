#!/usr/bin/env bash
set -eu

url="${ORCA_APPIMAGE_URL:-}"
case "${TARGETARCH:-amd64}" in
  arm64) default_url="https://github.com/stablyai/orca/releases/latest/download/orca-linux-arm64.AppImage" ;;
  amd64) default_url="https://github.com/stablyai/orca/releases/latest/download/orca-linux.AppImage" ;;
  *) echo "Unsupported Orca architecture: ${TARGETARCH:-}" >&2; exit 1 ;;
esac

url="${url:-$default_url}"
echo "Downloading: $url"
curl -fsSL -o /opt/orca/orca-linux.AppImage "$url"
chmod +x /opt/orca/orca-linux.AppImage
cd /opt/orca
./orca-linux.AppImage --appimage-extract
chmod -R a+rX /opt/orca/squashfs-root
test -x /opt/orca/squashfs-root/AppRun
