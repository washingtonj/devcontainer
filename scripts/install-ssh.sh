#!/usr/bin/env bash
set -eu

apt-get update
apt-get install -y --no-install-recommends openssh-client openssh-server
rm -rf /var/lib/apt/lists/*
