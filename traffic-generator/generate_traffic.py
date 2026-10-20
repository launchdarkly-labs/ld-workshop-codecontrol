#!/usr/bin/env python3
"""Synthetic shopper traffic for the ToggleWear labs.

Drives the real app endpoints so every downstream signal is organic: each
/chat request makes the server evaluate release-otto (and, once wired,
emit the otto-response-latency metric); /recommendations requests exercise
the carousel (and, in the Observability track, the personalized strategy's
lurking bug — note the occasional rollout-tote view below).

Each request is a fresh synthetic visitor, so rollouts and guarded releases
see a steady stream of distinct contexts.

Run via the togglewear-traffic systemd service (started by challenge setup
scripts, not at boot). Stdlib only — no dependencies.
"""
import json
import logging
import os
import random
import time
import urllib.error
import urllib.request

APP_URL = os.getenv("TRAFFIC_APP_URL", "http://localhost:3000")
# Seconds between synthetic shoppers (jittered ±50%).
PERIOD = float(os.getenv("TRAFFIC_PERIOD_SECONDS", "2.0"))
# Every Nth shopper also browses the carousel (1 = every shopper).
RECS_EVERY = max(1, int(os.getenv("TRAFFIC_RECS_EVERY", "3")))
# Probability that a browsing shopper viewed the Rollout Tote — the product
# with no category that the personalized recommendations strategy trips
# over. 0.125 ≈ uniform over the 8-product catalog; the Observability track
# raises it so the error signal is visible inside a lab's time budget.
# Profiles are written to /opt/ld/traffic.env by terraform/lib/traffic.sh.
TOTE_BIAS = float(os.getenv("TRAFFIC_TOTE_BIAS", "0.125"))
# Probability that a browsing shopper clicks a recommended item, per
# strategy. These weights are the one deliberately synthetic thing in the
# generator: they encode "personalized recommendations are more engaging"
# so the Iterate track's experiment has a clear, honest-looking winner that
# converges in a presenter-friendly window. The click itself goes through
# the real /recommendations/click endpoint, so the metric event is emitted
# by the server exactly as a real shopper's would be.
ENGAGE = {
    "bestsellers": float(os.getenv("TRAFFIC_ENGAGE_BESTSELLERS", "0.25")),
    "personalized": float(os.getenv("TRAFFIC_ENGAGE_PERSONALIZED", "0.45")),
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s traffic %(message)s")
log = logging.getLogger("traffic")

# Mostly free shoppers, some premium, a few beta testers.
TIERS = ["free"] * 6 + ["premium"] * 3 + ["beta"]

MESSAGES = [
    "hi",
    "What size hoodie should I get?",
    "How long does shipping take?",
    "Can I return the socks if they don't fit?",
    "Is the mug dishwasher safe?",
    "Do you have any discounts?",
    "What's the warmest thing you sell?",
    "Tell me about the notebook",
]

PRODUCT_IDS = [
    "rocket-tee", "feature-flag-hoodie", "dark-mode-cap", "ship-it-mug",
    "toggle-socks", "release-notes-notebook", "rollout-tote",
    "feature-branch-crewneck",
]


def post_json(path: str, payload: dict) -> dict:
    req = urllib.request.Request(
        f"{APP_URL}{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as res:
        return json.load(res)


def get_json(path: str) -> dict:
    with urllib.request.urlopen(f"{APP_URL}{path}", timeout=10) as res:
        return json.load(res)


def one_shopper(i: int) -> None:
    visitor = f"shopper-{random.randrange(10**9):09d}"
    tier = random.choice(TIERS)

    post_json("/chat", {
        "message": random.choice(MESSAGES),
        "user_tier": tier,
        "session_id": visitor,
    })

    # Some shoppers also browse, feeding the recommendations feature.
    recs = "-"
    if i % RECS_EVERY == 0:
        viewed = "rollout-tote" if random.random() < TOTE_BIAS else random.choice(PRODUCT_IDS)
        try:
            data = get_json(f"/recommendations?user_key={visitor}&user_tier={tier}&viewed={viewed}")
            strategy = data.get("strategy")
            recs = f"{strategy}/{viewed}"
            items = data.get("items") or []
            if items and random.random() < ENGAGE.get(strategy, 0.0):
                post_json("/recommendations/click", {
                    "user_key": visitor, "user_tier": tier,
                    "product_id": random.choice(items)["id"],
                })
                recs += "/clicked"
        except urllib.error.HTTPError as err:
            # A 500 here is the personalized strategy's bug doing its thing —
            # exactly the organic error signal the Observability track wants.
            recs = f"HTTP {err.code}/{viewed}"

    log.info("shopper=%s tier=%s recs=%s", visitor, tier, recs)


def main() -> None:
    log.info("starting against %s (period ~%.1fs)", APP_URL, PERIOD)
    i = 0
    while True:
        i += 1
        try:
            one_shopper(i)
        except (urllib.error.URLError, OSError, json.JSONDecodeError) as err:  # HTTPError from /chat included
            # The app may be mid-reload after a paste; keep going.
            log.warning("request failed (%s), retrying next cycle", err)
        time.sleep(PERIOD * random.uniform(0.5, 1.5))


if __name__ == "__main__":
    main()
