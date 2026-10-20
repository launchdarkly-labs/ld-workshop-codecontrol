    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly Otto style paste block
    # ─────────────────────────────────────────────────────────────────────
    otto_style = "concise"
    if ld_client is not None:
        otto_style = ld_client.variation(
            "otto-style", build_context(req.session_id, req.user_tier), "concise"
        )
    # ─── End LaunchDarkly Otto style paste block ──────────────────────────
