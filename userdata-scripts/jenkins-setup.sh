#!/bin/bash
# Install and start Jenkins (LTS) on Ubuntu / Debian.
# Run as root (e.g. EC2 user data). Safe to re-run.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEYRING="/usr/share/keyrings/jenkins-keyring.asc"
KEY_URL="https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key"
REPO_FILE="/etc/apt/sources.list.d/jenkins.list"

# ---------- 0. Sanity check ----------
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# ---------- 1. Base packages ----------
apt-get update -y
apt-get install -y wget curl ca-certificates fontconfig

# ---------- 2. Java 21 ----------
if ! apt-get install -y openjdk-21-jdk; then
  echo "openjdk-21-jdk is not available on this OS. Use Ubuntu 22.04/24.04 or Debian 13." >&2
  exit 1
fi
java -version

# ---------- 3. Jenkins repository ----------
mkdir -p /usr/share/keyrings
wget -qO "$KEYRING" "$KEY_URL"
echo "deb [signed-by=$KEYRING] https://pkg.jenkins.io/debian-stable binary/" > "$REPO_FILE"

# ---------- 4. Install Jenkins ----------
apt-get update -y
apt-get install -y jenkins

# ---------- 5. Enable & start ----------
systemctl daemon-reload
systemctl enable --now jenkins

echo "Jenkins is starting on port 8080 (can take about a minute)."
echo "Initial admin password: /var/lib/jenkins/secrets/initialAdminPassword"