#!/bin/bash
#
# Base image for LaunchDarkly Instruqt tracks (launchdarkly-instruqt-track
# skill contract). Run on a fresh Ubuntu 24.04 host image (Instruqt: Settings
# -> Host images -> Create image -> terminal, as root), then save it.
#
# REQUIRED sections are marked. Everything after the "Workshop app" marker is
# appended by build-image.sh from ./app-install.sh.
#
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get -y update

# ---- Install tools (terraform + python3 are REQUIRED: terraform runs a python3
#      external data source, modules/workshop-project/sign.py) ----------------
mkdir -p /etc/apt/keyrings
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get -y update
apt-get -y install unzip jq git curl wget gnupg ca-certificates lsb-release terraform vim python3 python3-venv python3-pip
terraform version
python3 --version

# ---- REQUIRED: clone the Terraform that provisions the learner's project -----
# track_scripts/setup-workstation runs `terraform apply` here with the sandbox
# id; cleanup runs `terraform destroy` here. It creates the project, the test
# environment, the team member, and the magic-login record the "launchdarkly"
# virtual browser reads.
mkdir -p /opt/ld
cd /opt/ld
rm -rf /opt/ld/ld-workshop-participant
git clone https://github.com/launchdarkly-labs/ld-workshop-participant.git
cd /opt/ld/ld-workshop-participant
terraform init

# ---- REQUIRED: code-server (the "Code Editor" tab, port 8080, rooted at /opt/ld)
mkdir -p /root/.local/share/code-server/User

cat > /root/.local/share/code-server/User/settings.json <<-SETTINGS
{
    "workbench.colorTheme": "Default Dark+",
    "workbench.startupEditor": "none",
    "security.workspace.trust.enabled": false,
    "chat.disableAIFeatures": true,
    "chat.commandCenter.enabled": false,
    "workbench.secondarySideBar.defaultVisibility": "hidden"
}
SETTINGS

curl -fsSL https://code-server.dev/install.sh | sh

cat <<-UNIT > /etc/systemd/system/code-server.service
[Unit]
Description=Code Server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/code-server --host 0.0.0.0 --port 8080 --auth none /opt/ld

[Install]
WantedBy=multi-user.target
UNIT

systemctl enable code-server
systemctl start code-server
