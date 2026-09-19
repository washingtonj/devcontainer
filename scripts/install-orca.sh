#!/usr/bin/env bash
set -eu

orca_version="${ORCA_VERSION:-1.4.205}"

case "${TARGETARCH:-amd64}" in
  arm64) deb_arch="arm64" ;;
  amd64) deb_arch="amd64" ;;
  *) echo "Unsupported Orca architecture: ${TARGETARCH:-}" >&2; exit 1 ;;
esac

url="${ORCA_APPIMAGE_URL:-}"
if [[ -z "$url" ]]; then
  url="https://github.com/stablyai/orca/releases/download/v${orca_version}/orca-ide_${orca_version}_${deb_arch}.deb"
fi

echo "Downloading: $url"
curl -fsSL -o /tmp/orca-ide.deb "$url"
dpkg-deb -x /tmp/orca-ide.deb /opt/orca/
rm /tmp/orca-ide.deb

orca_root="/opt/orca/opt/Orca"
chmod -R a+rX "$orca_root"

find "$orca_root/locales" -name '*.pak' \
  ! -name 'en-US.pak' ! -name 'en-GB.pak' -delete 2>/dev/null || true
rm -f "$orca_root/LICENSES.chromium.html"

test -x "$orca_root/orca-ide"
