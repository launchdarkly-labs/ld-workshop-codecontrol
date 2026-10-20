#!/bin/bash
#
# set-fallthrough.sh <project-key> <flag-key> <variation-value>
#
# Turn the flag on (if needed) and point its default rule at the variation
# whose VALUE matches, via the stable semantic-patch API. Used by the
# Observability track's setup and solve scripts to move
# recommendations-strategy between "bestsellers" and "personalized" — the
# flag resource itself is owned by terraform/observability-baseline, so
# per-challenge modules update it over REST (see DECISIONS.md, "Terraform
# per-challenge modules, hybrid provider + REST").
#
# Operator context only (needs LAUNCHDARKLY_ACCESS_TOKEN). Exits non-zero on
# failure; callers that must tolerate an active rollout on the default rule
# (which rejects the patch) should `|| echo WARNING`.
#
set -euo pipefail

PROJ="$1"; FLAG="$2"; VALUE="$3"
API=https://app.launchdarkly.com/api/v2

VAR_ID=$(curl -fsS "$API/flags/$PROJ/$FLAG" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  | jq -r --arg v "$VALUE" '.variations[] | select((.value | tostring) == $v) | ._id')
if [ -z "$VAR_ID" ] || [ "$VAR_ID" == "null" ]; then
  echo "ERROR: flag $FLAG has no variation with value '$VALUE'" >&2
  exit 1
fi

curl -fsS -X PATCH "$API/flags/$PROJ/$FLAG" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
  --data-raw "$(jq -n --arg id "$VAR_ID" '{
    environmentKey: "test",
    instructions: [
      {kind: "turnFlagOn"},
      {kind: "updateFallthroughVariationOrRollout", variationId: $id}
    ]}')" > /dev/null
echo "$FLAG default rule now serves '$VALUE'"
