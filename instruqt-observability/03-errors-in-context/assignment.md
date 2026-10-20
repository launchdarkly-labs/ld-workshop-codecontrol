---
slug: errors-in-context
id: u2liaub9bqw9
type: challenge
title: Errors in Context
teaser: See the error attributed to the variation that caused it, then replay the session where it happened.
notes:
- type: text
  contents: An error count is a number. An error tied to a flag variation, with a replay of the shopper who hit it, is a diagnosis.
tabs:
- id: isj86dgi0j9e
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: xb4t62g3utcq
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: 0jwir8i295hd
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 900
enhanced_loading: null
---

# From "an error" to "that error, for those shoppers"

Last lab you found a `KeyError` in the Errors list. Useful, but a traditional error tracker would have told you that much. The question that actually matters on release day is different: *is this error about the thing I just shipped?*

LaunchDarkly can answer that because the server plugin stamped every request trace with the flag evaluations that happened in it. When `/recommendations` evaluated `recommendations-strategy` and then threw, the exception and the evaluation landed in the same trace, so LaunchDarkly knows that error happened to a shopper who was served **Personalized**. No cross-referencing, no filtering by timestamp. The attribution is already there.

This lab is about looking, not building. There's nothing to paste.

# The flag's own monitoring view

In the [LaunchDarkly](#tab-0) tab, open the **recommendations-strategy** flag and click its **Monitoring** tab.
<!-- VERIFY: tab name "Monitoring" on the flag page and the chart selector (Errors / Logs / Traces / Sessions) -->

1. Select the **Errors** chart. The chart shows error volume over time, **grouped by flag variation**. Hover a bar: every occurrence of `KeyError: 'category'` sits under **Personalized**. Bestsellers has none.
2. Below the chart, click the error itself. Expand **Instance metadata** and look for the `feature_flag` attributes: the flag key, the context key of the shopper who hit it, and `result.value: personalized`.
3. Now select the **Logs** chart. The server's own log lines (`recommendations user=... strategy=personalized viewed=rollout-tote`) are here too, grouped the same way. You didn't add logging; the plugin captured the app's existing `log.info` calls.

![Errors grouped by variation](../assets/obs-03-errors-by-variation.png)

Pause on what this view is telling you. If the question were "did the Personalized release cause errors?", you could answer it in one glance, and you could answer the opposite question just as fast: if errors had appeared under *both* variations, the release would be innocent and you'd look elsewhere.

# Watch it happen

Charts show you that it broke. Session replay shows you *what the shopper saw* when it broke.

1. Still on the **Monitoring** tab, select the **Sessions** chart. Sessions are grouped by variation like everything else; yours is one of the recent ones under **Personalized**.
   <!-- VERIFY: recording-to-visible latency for sessions; whether the learner's session appears under the flag's Sessions chart with server-side + client-side evaluation in place -->
2. Click your session to open the replay and press **Play**. Watch yourself click the Rollout Tote and watch the carousel vanish. Scrub back and forth; use the speed control if you're impatient.
3. Open the **Flags** subsection beside the replay. It lists every flag this session evaluated and the variation served, including `recommendations-strategy: personalized`. Open **Traces** and you'll find the failed `/recommendations` request, linked to the server-side trace that carries the exception.
   <!-- VERIFY: subsection names (General / Logs / Traces / Flags / Performance) and that the frontend fetch links to the backend trace via tracingOrigins -->

![Replaying the moment the carousel vanished](../assets/obs-03-session-replay.png)

For a support ticket that says "recommendations sometimes don't show up," this is the difference between an afternoon of guessing and a thirty-second answer.

# Two honest observations

Before you move on, two things worth noticing about what you did *not* have to do:

- You never searched by time window, or correlated a deploy timestamp with a log line. The flag variation *is* the join key.
- Nobody filed a bug. The signal has been there since you shipped, waiting to be looked at. Which raises the real question for the rest of this track: *why is a human looking at all?*

Click **Check**, then **Next**. Next lab, you'll find the metric that answers "how bad is it?" with a number, and you'll undo this release the right way.
