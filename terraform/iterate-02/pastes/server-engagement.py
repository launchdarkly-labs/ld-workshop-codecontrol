    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly engagement tracking paste block
    # ─────────────────────────────────────────────────────────────────────
    if ld_client is not None:
        ld_client.track("recs-engagement", build_context(req.user_key, req.user_tier))
    # ─── End LaunchDarkly engagement tracking paste block ─────────────────
