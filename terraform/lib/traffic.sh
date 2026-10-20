#!/bin/bash
#
# traffic.sh <profile>
#
# Write the synthetic-traffic profile to /opt/ld/traffic.env (read by the
# togglewear-traffic systemd unit via EnvironmentFile) and (re)start the
# service so the new knobs take effect. Idempotent. Profiles:
#
#   release  Release-track defaults: a shopper every ~2s, one in three
#            browses the carousel, products picked uniformly.
#   recs     Observability: a shopper every ~1s, every shopper browses the
#            carousel, and ~35% of them view the Rollout Tote — the product
#            with no category that the personalized strategy trips over.
#            Enough error volume for the monitoring charts, the guarded
#            rollout, and the adaptive trigger to move inside a lab.
#   exp      Iterate: two shoppers a second, every shopper browses, products
#            uniform (the bug is fixed in this track), and engagement clicks
#            weighted so Personalized wins clearly (45% vs 25%). ~120
#            exposures per minute, so an experiment reads in a few minutes.
#
set -euo pipefail

PROFILE="${1:-release}"
ENV_FILE=/opt/ld/traffic.env

case "$PROFILE" in
  release)
    cat > "$ENV_FILE" <<EOT
TRAFFIC_PERIOD_SECONDS=2.0
TRAFFIC_RECS_EVERY=3
TRAFFIC_TOTE_BIAS=0.125
EOT
    ;;
  recs)
    cat > "$ENV_FILE" <<EOT
TRAFFIC_PERIOD_SECONDS=1.0
TRAFFIC_RECS_EVERY=1
TRAFFIC_TOTE_BIAS=0.35
EOT
    ;;
  exp)
    cat > "$ENV_FILE" <<EOT
TRAFFIC_PERIOD_SECONDS=0.5
TRAFFIC_RECS_EVERY=1
TRAFFIC_TOTE_BIAS=0.125
TRAFFIC_ENGAGE_BESTSELLERS=0.25
TRAFFIC_ENGAGE_PERSONALIZED=0.45
EOT
    ;;
  *)
    echo "ERROR: unknown traffic profile '$PROFILE' (release|recs|exp)" >&2
    exit 1
    ;;
esac

# stop/start rather than restart: guarantees the EnvironmentFile is re-read.
service togglewear-traffic stop || true
service togglewear-traffic start
systemctl is-active --quiet togglewear-traffic \
  || echo "WARNING: togglewear-traffic is not running after profile '$PROFILE'" >&2
echo "traffic profile '$PROFILE' active"
