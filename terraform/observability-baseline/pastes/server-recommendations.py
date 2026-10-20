    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly recommendations paste block
    # ─────────────────────────────────────────────────────────────────────
    strategy = "bestsellers"
    if ld_client is not None:
        context = build_context(user_key, user_tier)
        if not ld_client.variation("show-recommendations", context, False):
            return {"strategy": None, "items": []}
        strategy = ld_client.variation("recommendations-strategy", context, "bestsellers")
    # ─── End LaunchDarkly recommendations paste block ─────────────────────
