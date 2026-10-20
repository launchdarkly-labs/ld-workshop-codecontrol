#!/bin/bash
#
# Start a guarded (monitored) release of Chatty Otto on otto-style via the
# beta release-pipeline APIs. Called by terraform (solve path only).
#
# VERIFY before first live run (see DECISIONS.md "Rollout solves use the
# beta release APIs"):
#  - that a pipeline release with releaseStrategy=monitoredRelease registers
#    under the flags-list filter `guardedRollout:` the check script uses;
#  - how metrics attach to a pipeline-based monitored release (the pipeline
#    audience schema carries no metric keys — the UI's Serve-menu flow
#    attaches them at creation; the pipeline flavor may need them attached
#    at release start or fall back to flag-attached metrics).
#
# If any step fails, this script logs loudly and exits 0, leaving otto-style
# serving Concise — the same state a learner ends in AFTER the guarded
# rollout rolls back. Exit 0 is deliberate: later tracks replay this solve
# while materializing their baselines, and a hard failure on beta-API
# flakiness would abort the whole baseline for a state difference that
# doesn't block any downstream challenge. The trade-off (a Skip can report
# success without a live rollout) is accepted and covered by the operator
# checklist's verification of this script.
#
set -uo pipefail

PROJECT_KEY="$1"
API=https://app.launchdarkly.com/api/v2
AUTH=(-H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" -H "Content-Type: application/json" -H "LD-API-Version: beta")
PIPELINE_KEY="otto-guarded-pipeline"

warn_and_bail() {
  echo "WARNING: $1" >&2
  echo "WARNING: leaving otto-style serving Concise (post-rollback state)." >&2
  exit 0
}

# 1. Create the single-phase pipeline with a Release Guardian audience.
#    409 (already exists) is fine — solve may run more than once.
CREATE_STATUS=$(curl -sS -o /tmp/rel08-pipeline.json -w '%{http_code}' -X POST \
  "$API/projects/$PROJECT_KEY/release-pipelines" \
  "${AUTH[@]}" \
  --data-raw '{
    "key": "'"$PIPELINE_KEY"'",
    "name": "Otto guarded pipeline",
    "description": "Single-phase guarded release pipeline (created by the 08 solve).",
    "phases": [
      {
        "name": "Guarded ramp",
        "audiences": [
          {
            "environmentKey": "test",
            "name": "test",
            "configuration": {
              "releaseStrategy": "monitoredRelease",
              "requireApproval": false,
              "releaseGuardianConfiguration": {
                "monitoringWindowMilliseconds": 600000,
                "rolloutWeight": 50,
                "rollbackOnRegression": true,
                "randomizationUnit": "user"
              }
            }
          }
        ]
      }
    ]
  }')
if [ "$CREATE_STATUS" != "201" ] && [ "$CREATE_STATUS" != "200" ] && [ "$CREATE_STATUS" != "409" ]; then
  warn_and_bail "release-pipeline create returned HTTP $CREATE_STATUS: $(cat /tmp/rel08-pipeline.json)"
fi

# 2. Find the Chatty Otto variation id.
CHATTY_ID=$(curl -sS -X GET "$API/flags/$PROJECT_KEY/otto-style" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  | jq -r '.variations[] | select(.value == "chatty") | ._id')
if [ -z "$CHATTY_ID" ] || [ "$CHATTY_ID" == "null" ]; then
  warn_and_bail "could not resolve the chatty variation id on otto-style"
fi

# 3. Attach the flag to the pipeline and release the chatty variation.
RELEASE_STATUS=$(curl -sS -o /tmp/rel08-release.json -w '%{http_code}' -X PUT \
  "$API/projects/$PROJECT_KEY/flags/otto-style/release" \
  "${AUTH[@]}" \
  --data-raw '{
    "releasePipelineKey": "'"$PIPELINE_KEY"'",
    "releaseVariationId": "'"$CHATTY_ID"'"
  }')
if [ "$RELEASE_STATUS" == "409" ] || { [ "$RELEASE_STATUS" == "400" ] && grep -qiE "already|active|exists" /tmp/rel08-release.json; }; then
  echo "A release already exists on otto-style — leaving it in place (re-run)."
  exit 0
fi
if [ "$RELEASE_STATUS" != "200" ] && [ "$RELEASE_STATUS" != "201" ]; then
  warn_and_bail "flag release PUT returned HTTP $RELEASE_STATUS: $(cat /tmp/rel08-release.json)"
fi

echo "Guarded release of Chatty Otto started via pipeline '$PIPELINE_KEY'."
exit 0
