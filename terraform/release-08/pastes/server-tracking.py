    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly event tracking paste block
    # ─────────────────────────────────────────────────────────────────────
    if ld_client is not None:
        ld_client.track(
            "otto-response-latency",
            build_context(req.session_id, req.user_tier),
            metric_value=elapsed_ms,
        )
    # ─── End LaunchDarkly event tracking paste block ──────────────────────
