#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

apt-get update
apt-get install --yes ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update
apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker "${SUDO_USER:-ubuntu}"

install -d -o "${SUDO_USER:-ubuntu}" -g "${SUDO_USER:-ubuntu}" /opt/wearo-backend

echo "Docker is installed. Sign out and back in before running Docker without sudo."
