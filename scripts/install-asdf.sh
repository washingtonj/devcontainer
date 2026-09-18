#!/usr/bin/env bash
set -eu

asdf_version="${ASDF_VERSION:-0.20.0}"
target_arch="${TARGETARCH:-amd64}"
data_dir="${ASDF_DATA_DIR:-/home/agent/.asdf}"

case "$target_arch" in
  amd64) asdf_arch=amd64 ;;
  arm64) asdf_arch=arm64 ;;
  *) echo "Unsupported asdf architecture: $target_arch" >&2; exit 1 ;;
esac

curl -fsSL -o /tmp/asdf.tar.gz \
  "https://github.com/asdf-vm/asdf/releases/download/v${asdf_version}/asdf-v${asdf_version}-linux-${asdf_arch}.tar.gz"
tar -xzf /tmp/asdf.tar.gz -C /usr/local/bin asdf
rm /tmp/asdf.tar.gz

cat > /etc/devserver/env.d/asdf.env <<'EOF'
export ASDF_DATA_DIR=/home/agent/.asdf
export PATH=/home/agent/.asdf/shims:/home/agent/.asdf/bin:$PATH
EOF

asdf version
