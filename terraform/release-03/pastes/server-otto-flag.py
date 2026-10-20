    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly Otto flag paste block
    # ─────────────────────────────────────────────────────────────────────
    context = build_context(req.session_id, req.user_tier)
    otto_enabled = ld_client.variation("release-otto", context, False)
    # ─── End LaunchDarkly Otto flag paste block ───────────────────────────
