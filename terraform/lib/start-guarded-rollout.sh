#!/bin/bash
#
# start-guarded-rollout.sh <project-key> <flag-key> <new-variation-value> <pipeline-key> <pipeline-name>
#
# Start a guarded (monitored) release of a flag variation via the beta
# release-pipeline APIs. Generalized from terraform/release-08's script;
# called by solve paths only (a learner who skips the guarded-release lab).
#
# VERIFY before first live run (see DECISIONS.md "Rollout solves use the
# beta release APIs"):
#  - that a pipeline release with releaseStrategy=monitoredRelease registers
#    under the flags-list filter `guardedRollout:` the check scripts use;
#  - how metrics attach to a pipeline-based monitored release (the pipeline
#    audience schema carries no metric keys — the UI's Serve-menu flow
#    attaches them at creation).
#
# If any step fails, this script logs loudly and exits 0, leaving the flag
# serving its current default — the same state a learner ends in AFTER the
# guarded rollout rolls back. Exit 0 is deliberate: baseline replays call
# solves in sequence, and beta-API flakiness must not abort a whole baseline
# over a state difference that blocks no downstream challenge.
#
set -uo pipefail

PROJECT_KEY="$1"; FLAG_KEY="$2"; NEW_VALUE="$3"; PIPELINE_KEY="$4"; PIPELINE_NAME="$5"
API=https://app.launchdarkly.com/api/v2
AUTH=(-H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" -H "Content-Type: application/json" -H "LD-API-Version: beta")
TMP=/tmp/guarded-$FLAG_KEY

warn_and_bail() {
  echo "WARNING: $1" >&2
  echo "WARNING: leaving $FLAG_KEY serving its current default (post-rollback state)." >&2
  exit 0
}

CREATE_STATUS=$(curl -sS -o "$TMP-pipeline.json" -w '%{http_code}' -X POST \
  "$API/projects/$PROJECT_KEY/release-pipelines" \
  "${AUTH[@]}" \
  --data-raw "$(jq -n --arg k "$PIPELINE_KEY" --arg n "$PIPELINE_NAME" '{
    key: $k, name: $n,
    description: "Single-phase guarded release pipeline (created by a solve script).",
    phases: [{
      name: "Guarded ramp",
      audiences: [{
        environmentKey: "test", name: "test",
        configuration: {
          releaseStrategy: "monitoredRelease",
          requireApproval: false,
          releaseGuardianConfiguration: {
            monitoringWindowMilliseconds: 600000,
            rolloutWeight: 50,
            rollbackOnRegression: true,
            randomizationUnit: "user"
          }
        }
      }]
    }]}')")
if [ "$CREATE_STATUS" != "201" ] && [ "$CREATE_STATUS" != "200" ] && [ "$CREATE_STATUS" != "409" ]; then
  warn_and_bail "release-pipeline create returned HTTP $CREATE_STATUS: $(cat "$TMP-pipeline.json")"
fi

NEW_ID=$(curl -sS -X GET "$API/flags/$PROJECT_KEY/$FLAG_KEY" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  | jq -r --arg v "$NEW_VALUE" '.variations[] | select((.value | tostring) == $v) | ._id')
if [ -z "$NEW_ID" ] || [ "$NEW_ID" == "null" ]; then
  warn_and_bail "could not resolve the '$NEW_VALUE' variation id on $FLAG_KEY"
fi

RELEASE_STATUS=$(curl -sS -o "$TMP-release.json" -w '%{http_code}' -X PUT \
  "$API/projects/$PROJECT_KEY/flags/$FLAG_KEY/release" \
  "${AUTH[@]}" \
  --data-raw "$(jq -n --arg p "$PIPELINE_KEY" --arg id "$NEW_ID" '{releasePipelineKey: $p, releaseVariationId: $id}')")
if [ "$RELEASE_STATUS" == "409" ] || { [ "$RELEASE_STATUS" == "400" ] && grep -qiE "already|active|exists" "$TMP-release.json"; }; then
  echo "A release already exists on $FLAG_KEY — leaving it in place (re-run)."
  exit 0
fi
if [ "$RELEASE_STATUS" != "200" ] && [ "$RELEASE_STATUS" != "201" ]; then
  warn_and_bail "flag release PUT returned HTTP $RELEASE_STATUS: $(cat "$TMP-release.json")"
fi

echo "Guarded release of '$NEW_VALUE' on $FLAG_KEY started via pipeline '$PIPELINE_KEY'."
exit 0
