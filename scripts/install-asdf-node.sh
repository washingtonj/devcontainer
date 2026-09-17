#!/usr/bin/env bash
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  git \
  dirmngr \
  gpg \
  gawk \
  xz-utils
rm -rf /var/lib/apt/lists/*

asdf_version="${ASDF_VERSION:-0.20.0}"
target_arch="${TARGETARCH:-amd64}"
asdf_data_dir="${ASDF_DATA_DIR:-/home/agent/.asdf}"
runtime_asdf_data_dir=/home/agent/.asdf
asdf_path="$asdf_data_dir/shims:$asdf_data_dir/bin:$PATH"
export ASDF_DATA_DIR="$asdf_data_dir" PATH="$asdf_path"

case "$target_arch" in
  amd64) asdf_arch=amd64 ;;
  arm64) asdf_arch=arm64 ;;
  *) echo "Unsupported asdf architecture: $target_arch" >&2; exit 1 ;;
esac

curl -fsSL -o /tmp/asdf.tar.gz \
  "https://github.com/asdf-vm/asdf/releases/download/v${asdf_version}/asdf-v${asdf_version}-linux-${asdf_arch}.tar.gz"
tar -xzf /tmp/asdf.tar.gz -C /usr/local/bin asdf
rm /tmp/asdf.tar.gz

mkdir -p "$asdf_data_dir" /etc/devserver/env.d
chown -R agent:agent "$asdf_data_dir"
runuser --preserve-environment -u agent -- env \
  HOME=/home/agent \
  ASDF_DATA_DIR="$asdf_data_dir" \
  bash -c '
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf install nodejs latest
    version="$(asdf list nodejs | sed -n "s/^[* ]*//p" | tail -n 1)"
    asdf set -u nodejs "$version"
    asdf reshim nodejs
  ' 

cat > /etc/devserver/env.d/asdf-node.env <<EOF
export ASDF_DATA_DIR=$runtime_asdf_data_dir
export PATH=$runtime_asdf_data_dir/shims:$runtime_asdf_data_dir/bin:$PATH
EOF

asdf version
