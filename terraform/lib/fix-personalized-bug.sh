#!/bin/bash
#
# fix-personalized-bug.sh
#
# The Iterate track compares the two recommendation strategies on
# engagement, so the personalized strategy's production bug (it reads
# viewed["category"] on a product that has no category) must be FIXED in
# this track's baseline — otherwise the experiment would be measuring an
# error rate, which is the Observability track's story. Idempotent: a
# one-line replacement in app/server.py outside any paste block, applied by
# the Iterate track-level setup.
#
set -euo pipefail
SERVER=/opt/ld/codecontrol/app/server.py
if grep -q 'viewed_category = viewed.get("category")' "$SERVER"; then
  echo "personalized bug already fixed"
  exit 0
fi
sed -i 's/viewed_category = viewed\["category"\]/viewed_category = viewed.get("category")/' "$SERVER"
grep -q 'viewed_category = viewed.get("category")' "$SERVER" || { echo "ERROR: could not patch the personalized strategy" >&2; exit 1; }
echo "personalized bug fixed (viewed.get(\"category\"))"
