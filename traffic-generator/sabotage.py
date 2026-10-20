#!/usr/bin/env python3
"""Presenter escape hatch for the guarded-release and auto-remediation labs.

Floods the app with synthetic shoppers at a much higher rate than the normal
traffic generator. It does NOT fake any metric values — more traffic just
means LaunchDarkly collects enough samples to detect the (real) regression
within a presenter-friendly window instead of a coffee break.

Two targets:

  --target chat  (default) floods /chat. Chatty Otto is organically slower,
                 so this is what trips the otto-response-latency guard in
                 the Release track.
  --target recs  floods /recommendations, with half the shoppers viewing the
                 Rollout Tote — the product with no category that the
                 personalized strategy throws on. This is what trips the
                 error-rate guard and the adaptive trigger in the
                 Observability track.

Run it from the workstation while a guarded rollout is monitoring (or an
adaptive trigger is armed):

    python3 /opt/ld/codecontrol/traffic-generator/sabotage.py
    python3 /opt/ld/codecontrol/traffic-generator/sabotage.py --target recs

Stops on its own after --minutes (default 5), or Ctrl-C anytime.
"""
import argparse
import json
import logging
import os
import random
import time
import urllib.error
import urllib.request

APP_URL = os.getenv("TRAFFIC_APP_URL", "http://localhost:3000")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s sabotage %(message)s")
log = logging.getLogger("sabotage")

MESSAGES = [
    "hi",
    "What size should I get?",
    "How long does shipping take?",
    "Can I return this?",
    "Which hoodie is warmest?",
    "Any deals right now?",
]


def one_chat() -> None:
    visitor = f"burst-{random.randrange(10**9):09d}"
    req = urllib.request.Request(
        f"{APP_URL}/chat",
        data=json.dumps({
            "message": random.choice(MESSAGES),
            "user_tier": random.choice(["free", "premium"]),
            "session_id": visitor,
        }).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as res:
        res.read()


PRODUCT_IDS = [
    "rocket-tee", "feature-flag-hoodie", "dark-mode-cap", "ship-it-mug",
    "toggle-socks", "release-notes-notebook", "rollout-tote",
    "feature-branch-crewneck",
]


def one_recs() -> None:
    visitor = f"burst-{random.randrange(10**9):09d}"
    viewed = "rollout-tote" if random.random() < 0.5 else random.choice(PRODUCT_IDS)
    url = (f"{APP_URL}/recommendations?user_key={visitor}"
           f"&user_tier={random.choice(['free', 'premium'])}&viewed={viewed}")
    try:
        with urllib.request.urlopen(url, timeout=10) as res:
            res.read()
    except urllib.error.HTTPError:
        # 500 = the personalized bug firing. That's the point; keep going.
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", choices=["chat", "recs"], default="chat",
                        help="which endpoint to flood (default chat)")
    parser.add_argument("--minutes", type=float, default=5.0,
                        help="how long to run the burst (default 5)")
    parser.add_argument("--period", type=float, default=0.3,
                        help="seconds between requests (default 0.3)")
    args = parser.parse_args()

    hit = one_chat if args.target == "chat" else one_recs
    deadline = time.monotonic() + args.minutes * 60
    sent = 0
    log.info("bursting %s (%s) for %.1f min (one request every ~%.1fs)",
             APP_URL, args.target, args.minutes, args.period)
    while time.monotonic() < deadline:
        try:
            hit()
            sent += 1
            if sent % 25 == 0:
                log.info("%d requests sent", sent)
        except (urllib.error.URLError, OSError) as err:
            log.warning("request failed (%s), continuing", err)
        time.sleep(args.period * random.uniform(0.7, 1.3))
    log.info("done — %d requests sent", sent)


if __name__ == "__main__":
    main()
