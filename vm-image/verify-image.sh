#!/bin/bash
#
# Post-bake verification — run on the VM after build-image.sh, before saving
# the image. Exits non-zero if anything the tracks rely on is missing.
#
set -uo pipefail
DEST=/opt/ld/codecontrol
VENV=/opt/ld/venv
fail=0
ok()   { printf '  \033[1;32mOK\033[0m   %s\n' "$*"; }
bad()  { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=1; }
check(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "Tools"
check "terraform >= 1.5"            'terraform version -json | jq -e ".terraform_version | split(\".\") | (.[0]|tonumber) > 1 or ((.[0]|tonumber) == 1 and (.[1]|tonumber) >= 5)"'
check "jq, curl, git, unzip present" 'command -v jq && command -v curl && command -v git && command -v unzip'
check "python3 >= 3.10"             'python3 -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)"'

echo "Participant Terraform (skill contract)"
check "/opt/ld/ld-workshop-participant cloned"   "test -f /opt/ld/ld-workshop-participant/main.tf"
check "participant terraform initialized"        "test -d /opt/ld/ld-workshop-participant/.terraform"

echo "Source tree"
for d in app terraform/observability-baseline terraform/lib traffic-generator instruqt-release instruqt-observability instruqt-iterate; do
  check "$DEST/$d" "test -d $DEST/$d"
done
check "app/.env seeded with KEY= lines"      "grep -q '^LD_SDK_KEY=' $DEST/app/.env && grep -q '^LD_CLIENT_KEY=' $DEST/app/.env"
check "no .remote / tfstate / .git baked"    "! find $DEST \( -name '*.remote' -o -name '*.tfstate' -o -name '.git' \) | grep -q ."
check "release solve scripts executable"     "test -x $DEST/instruqt-release/02-your-first-flag/solve-workstation"
check "lib helpers executable"               "test -x $DEST/terraform/lib/traffic.sh && test -x $DEST/terraform/lib/set-fallthrough.sh && test -x $DEST/terraform/lib/exp.sh"
check "vendored browser bundles"             "test -s $DEST/app/static/vendor/ldclient-v4.9.1.min.js && test -s $DEST/app/static/vendor/ld-observability-v1.2.1.umd.js && test -s $DEST/app/static/vendor/ld-session-replay-v1.2.1.umd.js"

echo "Python venv"
check "import ldclient, ldobserve, fastapi, uvicorn" "$VENV/bin/python -c 'import ldclient, ldobserve, fastapi, uvicorn'"
check "uvicorn reloader deps (watchfiles)"            "$VENV/bin/python -c 'import watchfiles'"

echo "Terraform modules pre-initialized"
for m in "$DEST"/terraform/*/; do
  [ -f "$m/versions.tf" ] || continue
  check "$(basename "$m") has .terraform/" "test -d $m/.terraform"
done

echo "Services"
check "togglewear enabled + active"       "systemctl is-enabled togglewear && systemctl is-active togglewear"
check "code-server enabled + active"      "systemctl is-enabled code-server && systemctl is-active code-server"
check "togglewear-traffic installed, NOT enabled" "systemctl cat togglewear-traffic && ! systemctl is-enabled togglewear-traffic"
check "storefront answers on :3000"       "curl -fsS localhost:3000/healthz | jq -e '.ok == true'"
check "storefront is UNWIRED (fresh image)" "curl -fsS localhost:3000/healthz | jq -e '.ld_wired == false'"
check "code-server answers on :8080"      "curl -fsS -o /dev/null localhost:8080"
check "code-server rooted at the app dir"   "systemctl cat code-server | grep -q ' /opt/ld/codecontrol/app$'"
check "/opt/ld/traffic.env exists"        "test -f /opt/ld/traffic.env"

echo
if [ "$fail" -eq 0 ]; then echo "All checks passed — save the image."; else echo "Some checks FAILED — fix before saving the image."; fi
exit $fail
