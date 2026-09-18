#!/usr/bin/env bash
set -eu

orca_version="${ORCA_VERSION:-1.4.205}"

url="${ORCA_APPIMAGE_URL:-}"
case "${TARGETARCH:-amd64}" in
  arm64) asset="orca-linux-arm64.AppImage" ;;
  amd64) asset="orca-linux.AppImage" ;;
  *) echo "Unsupported Orca architecture: ${TARGETARCH:-}" >&2; exit 1 ;;
esac

if [[ -z "$url" ]]; then
  url="https://github.com/stablyai/orca/releases/download/v${orca_version}/${asset}"
fi

echo "Downloading: $url"
curl -fsSL -o /opt/orca/orca-linux.AppImage "$url"
chmod +x /opt/orca/orca-linux.AppImage
cd /opt/orca
./orca-linux.AppImage --appimage-extract
chmod -R a+rX /opt/orca/squashfs-root
rm /opt/orca/orca-linux.AppImage

find /opt/orca/squashfs-root/locales -name '*.pak' \
  ! -name 'en-US.pak' ! -name 'en-GB.pak' -delete 2>/dev/null || true
rm -f /opt/orca/squashfs-root/LICENSES.chromium.html

test -x /opt/orca/squashfs-root/AppRun
