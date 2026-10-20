# ---- Workshop app: ToggleWear + per-challenge Terraform + traffic generator --
# Unlike the skill's stock Flask demo, the CodeControl app is not embedded as
# heredocs (it vendors ~1 MB of browser bundles); it is placed from this repo.
# Edit REPO_URL / REPO_REF to the commit to bake, or set SOURCE_DIR to a local
# checkout scp'd onto the VM (SOURCE_DIR wins when set).
REPO_URL="${REPO_URL:-https://github.com/launchdarkly-labs/ld-workshop-codecontrol.git}"
REPO_REF="${REPO_REF:-main}"
SOURCE_DIR="${SOURCE_DIR:-}"
DEST=/opt/ld/codecontrol
VENV=/opt/ld/venv

echo "==> Placing the workshop source at ${DEST}"
rm -rf "${DEST}"
if [ -n "${SOURCE_DIR}" ]; then
    mkdir -p "${DEST}"
    for d in app terraform traffic-generator instruqt-release instruqt-observability instruqt-iterate vm-image; do
        [ -d "${SOURCE_DIR}/$d" ] && cp -r "${SOURCE_DIR}/$d" "${DEST}/$d"
    done
else
    git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" "${DEST}"
    rm -rf "${DEST}/.git"
fi
# Nothing generated or stateful rides along: no .remote (Instruqt CLI publish
# artifacts), no Terraform state/tfvars, no caches.
find "${DEST}" \( -name '*.remote' -o -name '*.tfstate' -o -name '*.tfstate.*' -o -name 'terraform.tfvars' -o -name '.terraform' -o -name '__pycache__' -o -name '.DS_Store' \) -prune -exec rm -rf {} + 2>/dev/null || true
rm -f "${DEST}/app/.env"
chmod +x "${DEST}"/instruqt-*/*/*-workstation "${DEST}"/instruqt-*/track_scripts/* "${DEST}"/terraform/lib/*.sh "${DEST}"/vm-image/*.sh 2>/dev/null || true

echo "==> Building the Python venv at ${VENV}"
# One venv for the app and the traffic generators. Includes
# launchdarkly-observability (~180 MB of OpenTelemetry) — baked, never
# installed at lab start. noble enforces PEP 668, hence the venv.
python3 -m venv "${VENV}"
"${VENV}/bin/pip" install --no-cache-dir --quiet --upgrade pip
"${VENV}/bin/pip" install --no-cache-dir --quiet -r "${DEST}/app/requirements.txt"
"${VENV}/bin/python" -c "import ldclient, ldobserve, fastapi, uvicorn; print('python deps OK: ldclient', ldclient.__version__)"

echo "==> Seeding app/.env (real values are sed'd in at lab start)"
cp "${DEST}/app/.env.example" "${DEST}/app/.env"
: > /opt/ld/traffic.env   # optional traffic profile; empty = generator defaults

echo "==> Pre-initializing every per-challenge Terraform module"
# Shared plugin cache: the ~> 2.30 launchdarkly provider and the null provider
# download once and symlink into each module. Later tracks run seven applies
# at lab start, so this is what keeps setup inside its time budget.
export TF_PLUGIN_CACHE_DIR=/opt/ld/terraform-plugin-cache
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
echo "plugin_cache_dir = \"${TF_PLUGIN_CACHE_DIR}\"" > /root/.terraformrc
for m in "${DEST}"/terraform/*/; do
    [ -f "${m}/versions.tf" ] || continue
    echo "    terraform init $(basename "$m")"
    (cd "$m" && terraform init -input=false -backend=false >/dev/null)
done

echo "==> Installing the ToggleWear services"
install -m 644 "${DEST}/vm-image/systemd/togglewear.service"         /etc/systemd/system/togglewear.service
install -m 644 "${DEST}/vm-image/systemd/togglewear-traffic.service" /etc/systemd/system/togglewear-traffic.service
systemctl daemon-reload
systemctl enable togglewear
systemctl disable togglewear-traffic 2>/dev/null || true   # labs start it when needed
systemctl restart togglewear || true

apt-get -y autoremove
apt-get -y clean
echo "==> Done. Run ${DEST}/vm-image/verify-image.sh, then save this VM as the image (launchdarkly/workshop-codecontrol)."
