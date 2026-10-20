#!/bin/bash
#
# exp.sh — Experimentation REST helper for the Iterate track's solve
# scripts (the Terraform provider at our 2.x pin has no experiment
# resource; see PHASES-iterate.md Phase 0 notes). Operator context only.
#
#   exp.sh metric-key <project> <event-key>
#       Print the key of the metric whose event key matches (the UI derives
#       metric keys from names, so solves resolve by event key).
#   exp.sh create <project> <exp-key> <name> <hypothesis> <metric-key> [experiment|mab]
#       Create an A/B experiment (or multi-armed bandit) on
#       recommendations-strategy's default rule: Bestsellers (control) vs
#       Personalized, 50/50, randomized by user, Bayesian. 409 = exists, ok.
#   exp.sh start <project> <exp-key>
#       Start the draft iteration (startIteration semantic patch).
#   exp.sh ship <project> <exp-key> <winning-variation-value>
#       Stop the running iteration naming the winner, then point the flag's
#       default rule at that variation.
#
set -euo pipefail

API=https://app.launchdarkly.com/api/v2
AUTHH=(-H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}")
JSONH=(-H "Content-Type: application/json")
PATCHH=(-H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch")
FLAG=recommendations-strategy
ENV=test

cmd="$1"; shift

metric_key() {
  local proj="$1" event="$2"
  curl -fsS "$API/metrics/$proj?limit=50&filter=eventKeys%20anyOf%20%5B%22${event}%22%5D" "${AUTHH[@]}" \
    | jq -r '.items[0].key // empty'
}

flag_json() { curl -fsS "$API/flags/$1/$FLAG" "${AUTHH[@]}"; }

maintainer_id() {
  # POST /experiments requires maintainerId, and a service token has no member
  # identity of its own (first live play: HTTP 400 "maintainerId is required").
  # Prefer the sandbox's own student member (instruqt+<project>@...), created
  # by the participant Terraform; fall back to the first member in the account.
  local proj="$1" id
  id=$(curl -fsS "$API/members?limit=5&filter=query:instruqt%2B${proj}" "${AUTHH[@]}" 2>/dev/null \
    | jq -r --arg p "instruqt+${proj}@" '[.items[] | select(.email | startswith($p))][0]._id // empty')
  if [ -z "$id" ]; then
    id=$(curl -fsS "$API/members?limit=1" "${AUTHH[@]}" 2>/dev/null | jq -r '.items[0]._id // empty')
  fi
  echo "$id"
}

case "$cmd" in
  metric-key)
    metric_key "$1" "$2"
    ;;

  create)
    PROJ="$1"; KEY="$2"; NAME="$3"; HYPO="$4"; METRIC="$5"; TYPE="${6:-experiment}"
    FJ=$(flag_json "$PROJ")
    BEST_ID=$(echo "$FJ" | jq -r '.variations[] | select(.value=="bestsellers") | ._id')
    PERS_ID=$(echo "$FJ" | jq -r '.variations[] | select(.value=="personalized") | ._id')
    # VERIFY: flagConfigVersion = the environment config's "version" (per the
    # FeatureFlagConfig schema); fall back to the flag's top-level _version.
    VER=$(echo "$FJ" | jq -r ".environments.$ENV.version // ._version")
    MAINT=$(maintainer_id "$PROJ")
    [ -n "$MAINT" ] || { echo "ERROR: could not resolve a maintainerId (members API returned nothing)" >&2; exit 1; }
    BODY=$(jq -n --arg key "$KEY" --arg name "$NAME" --arg hypo "$HYPO" --arg metric "$METRIC" --arg maint "$MAINT" \
      --arg best "$BEST_ID" --arg pers "$PERS_ID" --argjson ver "$VER" --arg type "$TYPE" --arg flag "$FLAG" '
      {
        key: $key, name: $name, type: $type, methodology: "bayesian", maintainerId: $maint,
        description: "Created by the Iterate track solve script.",
        iteration: {
          hypothesis: $hypo,
          randomizationUnit: "user",
          canReshuffleTraffic: false,
          metrics: [{key: $metric, isGroup: false}],
          primarySingleMetricKey: $metric,
          treatments: [
            {name: "Bestsellers", baseline: true,  allocationPercent: "50", parameters: [{flagKey: $flag, variationId: $best}]},
            {name: "Personalized", baseline: false, allocationPercent: "50", parameters: [{flagKey: $flag, variationId: $pers}]}
          ],
          flags: { ($flag): {ruleId: "fallthrough", flagConfigVersion: $ver, notInExperimentVariationId: $best} }
        }
      }
      | if $type == "mab" then .iteration.reallocationFrequencyMillis = 60000 else . end')
    STATUS=$(curl -sS -o /tmp/exp-create.json -w '%{http_code}' -X POST \
      "$API/projects/$PROJ/environments/$ENV/experiments" "${AUTHH[@]}" "${JSONH[@]}" --data-raw "$BODY")
    case "$STATUS" in
      200|201) echo "created $TYPE '$KEY'" ;;
      409) echo "$TYPE '$KEY' already exists (ok)" ;;
      *) echo "ERROR: create $TYPE returned HTTP $STATUS: $(cat /tmp/exp-create.json)" >&2; exit 1 ;;
    esac
    ;;

  start)
    PROJ="$1"; KEY="$2"
    STATUS=$(curl -sS -o /tmp/exp-start.json -w '%{http_code}' -X PATCH \
      "$API/projects/$PROJ/environments/$ENV/experiments/$KEY" "${AUTHH[@]}" "${PATCHH[@]}" \
      --data-raw '{"instructions":[{"kind":"startIteration","changeJustification":"Started by the Iterate track solve script."}]}')
    case "$STATUS" in
      200) echo "started '$KEY'" ;;
      400|409)
        if grep -qiE "already|running" /tmp/exp-start.json; then echo "'$KEY' already running (ok)"; else
          echo "ERROR: start returned HTTP $STATUS: $(cat /tmp/exp-start.json)" >&2; exit 1; fi ;;
      *) echo "ERROR: start returned HTTP $STATUS: $(cat /tmp/exp-start.json)" >&2; exit 1 ;;
    esac
    ;;

  ship)
    PROJ="$1"; KEY="$2"; WIN="$3"
    WIN_VAR=$(flag_json "$PROJ" | jq -r --arg v "$WIN" '.variations[] | select(.value==$v) | ._id')
    EXP=$(curl -fsS "$API/projects/$PROJ/environments/$ENV/experiments/$KEY?expand=treatments" "${AUTHH[@]}")
    ITER_STATUS=$(echo "$EXP" | jq -r '.currentIteration.status // "none"')
    if [ "$ITER_STATUS" == "running" ]; then
      TREAT_ID=$(echo "$EXP" | jq -r --arg v "$WIN_VAR" '.currentIteration.treatments[] | select(.parameters[0].variationId==$v) | ._id')
      STATUS=$(curl -sS -o /tmp/exp-stop.json -w '%{http_code}' -X PATCH \
        "$API/projects/$PROJ/environments/$ENV/experiments/$KEY" "${AUTHH[@]}" "${PATCHH[@]}" \
        --data-raw "$(jq -n --arg t "$TREAT_ID" '{instructions:[{kind:"stopIteration", winningTreatmentId:$t, winningReason:"Personalized beat Bestsellers on recommendation engagement."}]}')")
      [ "$STATUS" == "200" ] || { echo "ERROR: stopIteration returned HTTP $STATUS: $(cat /tmp/exp-stop.json)" >&2; exit 1; }
      echo "stopped '$KEY' with winner '$WIN'"
    else
      echo "'$KEY' iteration status is '$ITER_STATUS'; nothing to stop"
    fi
    bash "$(dirname "$0")/set-fallthrough.sh" "$PROJ" "$FLAG" "$WIN"
    ;;

  *)
    echo "usage: exp.sh metric-key|create|start|ship ..." >&2; exit 2 ;;
esac
