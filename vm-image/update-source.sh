#!/bin/bash
#
# update-source.sh — refresh /opt/ld/codecontrol on an EXISTING image VM
# without rebuilding the venv or reinstalling tools. Use it when only repo
# content changed (paste files, Terraform modules, lib helpers, app code,
# traffic generator). Then Save the VM as a new image version.
#
# Why not `git pull`: the installer deliberately strips .git from
# /opt/ld/codecontrol so no history or remote config ships to learners.
#
# Source selection (same as app-install.sh): set SOURCE_DIR to a checkout
# you scp'd onto the VM, or REPO_URL/REPO_REF to clone.
#
#   REPO_REF=main bash /opt/ld/codecontrol/vm-image/update-source.sh
#   SOURCE_DIR=/root/ld-workshop-codecontrol bash update-source.sh
#
# If requirements.txt changed too, re-run the venv step afterwards:
#   /opt/ld/venv/bin/pip install --no-cache-dir -r /opt/ld/codecontrol/app/requirements.txt
#
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo -i)." >&2; exit 1; }

REPO_URL="${REPO_URL:-https://github.com/launchdarkly-labs/ld-workshop-codecontrol.git}"
REPO_REF="${REPO_REF:-main}"
SOURCE_DIR="${SOURCE_DIR:-}"
DEST=/opt/ld/codecontrol
STAGE=$(mktemp -d /opt/ld/codecontrol.new.XXXX)

echo "==> Fetching source"
if [ -n "${SOURCE_DIR}" ]; then
    for d in app terraform traffic-generator instruqt-release instruqt-observability instruqt-iterate vm-image; do
        [ -d "${SOURCE_DIR}/$d" ] && cp -r "${SOURCE_DIR}/$d" "${STAGE}/$d"
    done
else
    git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" "${STAGE}"
    rm -rf "${STAGE}/.git"
fi
find "${STAGE}" \( -name '*.remote' -o -name '*.tfstate' -o -name '*.tfstate.*' -o -name 'terraform.tfvars' -o -name '.terraform' -o -name '__pycache__' -o -name '.DS_Store' \) -prune -exec rm -rf {} + 2>/dev/null || true

echo "==> Preserving app/.env, swapping in the new tree"
[ -f "${DEST}/app/.env" ] && cp "${DEST}/app/.env" "${STAGE}/app/.env" || cp "${STAGE}/app/.env.example" "${STAGE}/app/.env"
rm -rf "${DEST}.old"; mv "${DEST}" "${DEST}.old"; mv "${STAGE}" "${DEST}"; rm -rf "${DEST}.old"
chmod +x "${DEST}"/instruqt-*/*/*-workstation "${DEST}"/instruqt-*/track_scripts/* "${DEST}"/terraform/lib/*.sh "${DEST}"/vm-image/*.sh 2>/dev/null || true

echo "==> Re-initializing Terraform modules (plugin cache makes this fast)"
export TF_PLUGIN_CACHE_DIR=/opt/ld/terraform-plugin-cache
for m in "${DEST}"/terraform/*/; do
    [ -f "${m}/versions.tf" ] || continue
    (cd "$m" && terraform init -input=false -backend=false >/dev/null) && echo "    init $(basename "$m")"
done

echo "==> Reinstalling units and restarting the storefront"
install -m 644 "${DEST}/vm-image/systemd/togglewear.service"         /etc/systemd/system/togglewear.service
install -m 644 "${DEST}/vm-image/systemd/togglewear-traffic.service" /etc/systemd/system/togglewear-traffic.service
systemctl daemon-reload
systemctl restart togglewear || true

echo "==> Done. Run ${DEST}/vm-image/verify-image.sh, then Save the VM as the image."
