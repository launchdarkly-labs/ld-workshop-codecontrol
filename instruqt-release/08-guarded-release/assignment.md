---
slug: guarded-release
id: udtkwl3na891
type: challenge
title: Guarded Release
teaser: Ship Chatty Otto behind a guard that rolls back if things go wrong.
notes:
- type: text
  contents: There's a new, more talkative version of Otto ready to ship.
    Instead of hoping it's fine, you'll release it behind a guard that
    watches a real metric and rolls back automatically if the new Otto makes
    things worse.
tabs:
- id: oc6jh1lmekdr
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: fn1jip1z4snj
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: iizsuqq9u8s3
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# Meet Chatty Otto

Someone at ToggleWear decided Otto should have more *personality*. The new version — call him Chatty Otto — answers the same questions with three times the words and the occasional forklift anecdote. Maybe customers will love it. Maybe it'll drive them away. Opinions in the standup were split.

This is exactly the situation the last lab warned you about: a change that *might* be worse, ramping to production with nothing watching. This time, something will be watching.

Three things were prepared for you while this challenge loaded — go look at each:

1. **A new flag, `otto-style`** — in the [LaunchDarkly](#tab-0) tab, find it in the flags list. It's a multivariate flag with two variations, **Concise Otto** and **Chatty Otto**, currently serving Concise to everyone.
2. **A metric, `otto-response-latency`** — under **Metrics** in the sidebar. A **metric** is a measurement your app reports to LaunchDarkly (a click, an error, a duration) so releases can be judged on data. This one tracks how many milliseconds Otto takes to answer, fed by a `track()` call in the server, and it counts *lower as better*.
3. **The wiring** — in the [Code Editor](#tab-2), peek at `server.py`. The style paste block now evaluates `otto-style`, and the tracking block reports each response's latency:

   ```python
   ld_client.track("otto-response-latency", context, metric_value=elapsed_ms)
   ```

   One more detail worth noticing: Otto "types" his replies, so longer replies genuinely take longer. Chatty Otto isn't rigged to fail. He's just slower, the way a rambling coworker is slower.

# How a guarded release works

A **guarded release** ramps a new variation to a growing share of traffic while LaunchDarkly's Release Guardian compares your metric between the new variation and the old one. It re-evaluates roughly every ten seconds using sequential statistical testing. If the new variation is significantly worse — a **regression** — LaunchDarkly can roll everyone back to the old variation automatically and notify you.

The synthetic shoppers from the last lab are still chatting away, so both variations will collect real latency samples.

# Ship Chatty Otto, guarded

In the [LaunchDarkly](#tab-0) tab, open **otto-style**'s targeting view.

1. Edit the **default rule**, which serves **Concise Otto**, and change the served variation to **Chatty Otto**.
2. In the **Serve** menu, choose **Guarded rollout**.
   <!-- VERIFY: guarded rollout is offered when changing the served variation on the default rule, per the "when you make a change to a variation" path in the docs -->
3. Wait for the **health check** to pass — it confirms flag evaluations and metric events are flowing.
   <!-- VERIFY: the health check panel's appearance and how long it typically takes with lab traffic -->
4. Under metrics to monitor, add **Otto response latency**.
5. Check the **Automatic rollback** box for the metric. This is the whole point — without it, a regression only *notifies* you.
6. Leave **Target by** on **user**, and set the **rollout duration** to the shortest schedule offered so the whole drama fits in this lab.
   <!-- VERIFY: default and minimum rollout durations; capture the stage schedule shown for the prose -->
7. Click **Review and save**.

![Configuring the guarded rollout](../assets/rel-08-guarded-config.png)

# Watch the guard work

The flag's page now shows the rollout monitoring: the share of traffic on Chatty Otto, samples collected, and the latency difference between variations building up.
<!-- VERIFY: what the monitoring view shows mid-rollout — chart, regression threshold line, sample counts -->

![Monitoring the rollout](../assets/rel-08-monitoring.png)

While you wait, chat with Otto in the [ToggleWear](#tab-1) tab — if your session landed in the rollout, you'll notice he's gotten wordy, and a beat slower.

Detection needs samples, and lab traffic is modest. If you're presenting (or impatient), open the terminal in the [Code Editor](#tab-2) tab and turn up the crowd:

```bash
python3 /opt/ld/codecontrol/traffic-generator/sabotage.py
```

That floods the shop with shoppers. It fakes nothing — every request measures Chatty Otto's real slowness; more traffic just means the statistics converge in minutes instead of an afternoon.

Then watch the flag page. When Release Guardian concludes the latency regression is real, it **rolls the release back on its own**: everyone returns to Concise Otto, and the rollout is marked as regressed and rolled back.

![Regression detected and rolled back](../assets/rel-08-rolled-back.png)

Confirm it in the shop: Otto's answers are short again. Nobody paged you. Nothing was decided by vibes at 2am. The guard measured, concluded, and reverted. That's the release safety net this track has been building toward.

Click **Check** (a rolled-back rollout counts — that's success, not failure), then **Next**. One more tool belongs on your belt: the blunt one.
