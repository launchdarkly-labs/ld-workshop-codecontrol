    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly context paste block
    # ─────────────────────────────────────────────────────────────────────
    return (
        Context.builder(user_key)
        .kind("user")
        .set("tier", user_tier)
        .build()
    )
    # ─── End LaunchDarkly context paste block ─────────────────────────────
