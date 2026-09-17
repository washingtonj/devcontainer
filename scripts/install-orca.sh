#!/usr/bin/env bash
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  file \
  jq \
  xvfb \
  zlib1g-dev \
  unzip \
  wget \
  libgtk-3-0t64 \
  libnss3 \
  libatk1.0-0t64 \
  libatk-bridge2.0-0t64 \
  libgbm1 \
  libasound2t64 \
  libxtst6 \
  libcups2t64 \
  libdrm2 \
  libxkbcommon0 \
  libpango-1.0-0 \
  libcairo2 \
  libatspi2.0-0t64 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxrandr2 \
  libxrender1 \
  libx11-xcb1 \
  libxcb-dri3-0 \
  libxss1 \
  python3 \
  python3-pip \
  python3-venv \
  build-essential
rm -rf /var/lib/apt/lists/*

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
chown -R root:root /opt/orca
test -x /opt/orca/squashfs-root/AppRun
