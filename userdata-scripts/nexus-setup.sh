#!/bin/bash
# Stop execution if any background command triggers a non-zero exit status
set -e

# 1. Import Corretto Keys & Setup Repo
rpm --import https://yum.corretto.aws/corretto.key
curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo

# 2. Install Java 21 & Automation Dependencies
yum install -y java-21-amazon-corretto-devel wget

# 3. Provision Execution Context Layouts
mkdir -p /opt/nexus/
mkdir -p /tmp/nexus/
cd /tmp/nexus/

# 4. Pull Nexus Binary Distro
NEXUSURL="https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.78.0-14.tar.gz"
wget "$NEXUSURL" -O nexus.tar.gz

# 5. Extract cleanly and scrub raw archives
tar -xzvf nexus.tar.gz
rm -f nexus.tar.gz

# 6. Migrate Binaries & Blobs to App Framework Path
cp -r /tmp/nexus/* /opt/nexus/

# Define explicit folder mappings expected from the source binary payload
NEXUSDIR="nexus-3.78.0-14"

# 7. Provision Service Accounts & Enforce Permissions
useradd nexus
chown -R nexus:nexus /opt/nexus

# 8. Render Systemd Orchestration Engine Hook cleanly
cat <<EOT > /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# 9. Establish Target System RC Defaults & Spin Up
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus
