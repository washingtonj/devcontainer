#!/usr/bin/env bash
set -euo pipefail

SSH_DIR=/home/agent/ssh
mkdir -p /run/sshd "$SSH_DIR"

if [[ ! -f "$SSH_DIR/ssh_host_ed25519_key" ]]; then
  ssh-keygen -q -t ed25519 -N '' -f "$SSH_DIR/ssh_host_ed25519_key"
fi
if [[ ! -f "$SSH_DIR/ssh_host_ecdsa_key" ]]; then
  ssh-keygen -q -t ecdsa -N '' -f "$SSH_DIR/ssh_host_ecdsa_key"
fi
if [[ ! -f "$SSH_DIR/ssh_host_rsa_key" ]]; then
  ssh-keygen -q -t rsa -b 3072 -N '' -f "$SSH_DIR/ssh_host_rsa_key"
fi

if [[ ! -f "$SSH_DIR/sshd_config" ]]; then
  cat > "$SSH_DIR/sshd_config" <<EOF
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
HostKey $SSH_DIR/ssh_host_ed25519_key
HostKey $SSH_DIR/ssh_host_ecdsa_key
HostKey $SSH_DIR/ssh_host_rsa_key
AuthorizedKeysFile $SSH_DIR/authorized_keys
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers agent
X11Forwarding no
PrintMotd no
UsePAM yes
EOF
fi

touch "$SSH_DIR/authorized_keys"
chown agent:agent "$SSH_DIR" "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
sshd -t -f "$SSH_DIR/sshd_config"
exec /usr/sbin/sshd -f "$SSH_DIR/sshd_config"
