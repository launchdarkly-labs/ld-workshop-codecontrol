#!/bin/bash
#
# Instruqt VM image build — `launchdarkly/workshop-codecontrol`.
#
# One image serves all three CodeControl tracks (Release, Observability,
# Iterate). Workflow (same as the AgentControl workshop):
#
#   1. In the Instruqt console, start a fresh Ubuntu 24.04 (noble) base VM.
#   2. Edit REPO_URL / REPO_REF below to the commit you want baked — or, if
#      the repo has no remote yet, scp a checkout to the VM and set
#      SOURCE_DIR to it (SOURCE_DIR wins over the clone when set).
#   3. Become root (sudo -i) and paste this entire script into the terminal.
#   4. When it prints "Done", run /opt/ld/codecontrol/vm-image/verify-image.sh,
#      then save the running VM as a new image from the console under the
#      name in every track's config.yml (bump a suffix when re-baking so
#      labs in flight keep their image).
#
# Idempotent enough to re-run on the same VM: it re-copies the source, rebuilds
# the venv in place, re-inits Terraform, and rewrites the unit files.
#
# What it does NOT do: bake any secret. LAUNCHDARKLY_ACCESS_TOKEN arrives via
# Instruqt at lab start; SDK/client/project keys and the scoped lab token are
# written into app/.env by the track-level setup-workstation.
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Edit these before pasting:
# ---------------------------------------------------------------------------
REPO_URL="${REPO_URL:-https://github.com/launchdarkly-labs/ld-workshop-codecontrol.git}"
REPO_REF="${REPO_REF:-main}"
SOURCE_DIR="${SOURCE_DIR:-}"            # optional: local checkout to copy instead of cloning
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.16.6}"   # latest stable on 2026-10-19; >= 1.5 required
# ---------------------------------------------------------------------------

DEST=/opt/ld/codecontrol
VENV=/opt/ld/venv

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo -i)." >&2; exit 1; }

say "Updating apt and installing system tools"
apt-get -y update
# python3-venv is required because noble enforces PEP 668 (no system pip
# installs). No build-essential: every wheel we need is prebuilt for 3.12.
apt-get -y install \
    unzip jq git curl wget gnupg ca-certificates lsb-release vim \
    python3 python3-venv python3-dev
python3 --version

say "Installing Terraform ${TERRAFORM_VERSION} (direct binary; HashiCorp's apt repo lags on noble)"
TF_ARCH="$(dpkg --print-architecture)"
TF_ZIP="terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip"
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TF_ZIP}" -o "/tmp/${TF_ZIP}"
unzip -o -q "/tmp/${TF_ZIP}" -d /usr/local/bin
chmod +x /usr/local/bin/terraform
rm -f "/tmp/${TF_ZIP}"
terraform version

say "Placing the workshop source at ${DEST}"
mkdir -p /opt/ld
rm -rf "${DEST}"
if [ -n "${SOURCE_DIR}" ]; then
    echo "copying from ${SOURCE_DIR}"
    mkdir -p "${DEST}"
    # Only what the VM needs; never .git, state, or CLI publish artifacts.
    for d in app terraform traffic-generator instruqt-release instruqt-observability instruqt-iterate vm-image; do
        [ -d "${SOURCE_DIR}/$d" ] && cp -r "${SOURCE_DIR}/$d" "${DEST}/$d"
    done
else
    echo "cloning ${REPO_URL}@${REPO_REF}"
    git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" "${DEST}"
    rm -rf "${DEST}/.git"
fi
# Belt and braces: nothing generated or stateful rides along.
find "${DEST}" \( -name '*.remote' -o -name '*.tfstate' -o -name '*.tfstate.*' -o -name 'terraform.tfvars' -o -name '.terraform' -o -name '__pycache__' -o -name '.DS_Store' \) -prune -exec rm -rf {} + 2>/dev/null || true
rm -f "${DEST}/app/.env"
chmod +x "${DEST}"/instruqt-*/*/*-workstation "${DEST}"/instruqt-*/track_scripts/* "${DEST}"/terraform/lib/*.sh "${DEST}"/vm-image/*.sh 2>/dev/null || true

say "Building the Python venv at ${VENV} ($(python3 --version))"
# One venv for the app and the traffic generators. Includes
# launchdarkly-observability (~180 MB of OpenTelemetry) — must be baked, never
# installed at lab start.
python3 -m venv "${VENV}"
"${VENV}/bin/pip" install --quiet --upgrade pip
"${VENV}/bin/pip" install --quiet -r "${DEST}/app/requirements.txt"
"${VENV}/bin/python" -c "import ldclient, ldobserve, fastapi, uvicorn; print('python deps OK: ldclient', ldclient.__version__)"

say "Seeding app/.env from .env.example (real values are sed'd in at lab start)"
cp "${DEST}/app/.env.example" "${DEST}/app/.env"

say "Pre-initializing every Terraform module (provider downloads happen now, not at lab start)"
# Shared plugin cache so the ~> 2.30 launchdarkly provider and the null
# provider are downloaded once and symlinked into each module.
export TF_PLUGIN_CACHE_DIR=/opt/ld/terraform-plugin-cache
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
echo "plugin_cache_dir = \"${TF_PLUGIN_CACHE_DIR}\"" > /root/.terraformrc
for m in "${DEST}"/terraform/*/; do
    [ -f "${m}/versions.tf" ] || continue
    echo "  terraform init $(basename "$m")"
    (cd "$m" && terraform init -input=false -backend=false >/dev/null)
done

say "Installing systemd units from ${DEST}/vm-image/systemd/"
install -m 644 "${DEST}/vm-image/systemd/togglewear.service"         /etc/systemd/system/togglewear.service
install -m 644 "${DEST}/vm-image/systemd/togglewear-traffic.service" /etc/systemd/system/togglewear-traffic.service
install -m 644 "${DEST}/vm-image/systemd/code-server.service"        /etc/systemd/system/code-server.service
# The traffic profile file is optional (EnvironmentFile=-); start empty so
# the Release track runs on the generator's defaults until a challenge
# setup writes a profile via terraform/lib/traffic.sh.
: > /opt/ld/traffic.env

say "Installing code-server (:8080, --auth none, workspace = the app)"
curl -fsSL https://code-server.dev/install.sh | sh   # .deb method on Ubuntu → /usr/bin/code-server
mkdir -p /root/.local/share/code-server/User
cat > /root/.local/share/code-server/User/settings.json <<'JSON'
{
    "workbench.colorTheme": "Default Dark+",
    "workbench.startupEditor": "none",
    "security.workspace.trust.enabled": false,
    "files.autoSave": "off",
    "editor.renderWhitespace": "none"
}
JSON

say "Enabling services (togglewear + code-server at boot; traffic stays disabled until a lab starts it)"
systemctl daemon-reload
systemctl enable togglewear code-server
systemctl disable togglewear-traffic 2>/dev/null || true
systemctl restart togglewear code-server

say "Cleaning up apt caches"
apt-get -y autoremove
apt-get -y clean

say "Done. Run ${DEST}/vm-image/verify-image.sh, then save this VM as the image from the Instruqt console."
