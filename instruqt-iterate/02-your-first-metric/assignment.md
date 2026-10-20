---
slug: your-first-metric
id: x8tfsv57zver
type: challenge
title: Your First Metric
teaser: "Create an engagement metric and wire the event that feeds it."
notes:
- type: text
  contents: "An experiment needs something to measure. In this challenge you'll define what \"better\" means for the carousel and give the app a way to report it."
tabs:
- id: 3rrlbwz1vioc
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: omxlyml5hnj8
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: tar0qsb3qrlj
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# What does "better" mean?

Before you can compare two strategies, you have to say what you're comparing them on. For the carousel, the honest answer is engagement: *did the shopper click something we recommended?* If Personalized is better, more shoppers who see it should click.

In LaunchDarkly that's a **metric**: a definition of an event your app sends plus the rule for turning those events into a number per flag variation. You met metrics in earlier tracks as guardrails; here the same machinery drives the decision. The app sends a `recs-engagement` event every time a shopper clicks a recommended item, and the metric counts the percentage of shoppers who did that at least once.

# Send the event

Open the [Code Editor](#tab-2) tab and open `server.py`.

1. Find the `/recommendations/click` endpoint and its stub (`LaunchDarkly engagement tracking paste block`). Replace the block, markers and all, with:

   ```python
       # ─────────────────────────────────────────────────────────────────────
       # LaunchDarkly engagement tracking paste block
       # ─────────────────────────────────────────────────────────────────────
       if ld_client is not None:
           ld_client.track("recs-engagement", build_context(req.user_key, req.user_tier))
       # ─── End LaunchDarkly engagement tracking paste block ─────────────────
   ```

2. Save the file. The server reloads on save.

One line, and it's doing something subtle: it reports the event for the **same context** that evaluated `recommendations-strategy` when the carousel was built. That's how LaunchDarkly will later know which variation each click belongs to. Same key, same context kind. If you tracked against a different context, the clicks would be orphans.

Now feed it. In the [ToggleWear](#tab-1) tab, click two or three items in the **Recommended for You** carousel. Each click posts to the endpoint you just wired. The synthetic shoppers are clicking too.

# Create the metric

Go to the [LaunchDarkly](#tab-0) tab and open **Metrics** in the left sidebar.
<!-- VERIFY: Metrics lives under a "Data" section in the current sidebar -->

1. Click **Create metric**.
2. Leave the event source on **LaunchDarkly hosted** and choose the event kind **Custom**.
3. Click into **Event key**. Recently received events appear; pick `recs-engagement` (or type it). If it's listed, your paste is working.

   ```
   recs-engagement
   ```

4. In the metric definition, choose **Occurrence (Percent)**: the percentage of users who sent the event at least once. Leave the analysis unit on **user** and the success criterion on **higher is better**. More clicks is good.
   <!-- VERIFY: exact labels in the metric-definition builder (Occurrence (Percent), analysis unit picker, higher/lower is better) -->
5. Name it:

   ```
   Recs engagement
   ```

   LaunchDarkly derives the metric key from the name (`recs-engagement`). The event key and the metric key happen to match here, but they're different things: the event key is what your code sends; the metric key is what the API calls the definition.
   <!-- VERIFY: the generated key for this name, and whether the key is editable in the dialog -->
6. Click **Create**.

![Creating the engagement metric](../assets/itr-02-create-metric.png)

Open the new metric. Its **Events** or activity view shows the `recs-engagement` events arriving, each tagged with a shopper. Nothing is being compared yet; there's no experiment. But the raw material is flowing.

# Why "percent of users" and not "number of clicks"

A quick word on the choice you made in step 4. Counting *clicks* would let one enthusiastic shopper clicking twenty times swing the result. Counting *shoppers who clicked at least once* measures what we care about, whether the recommendations are worth clicking, one vote per shopper. When you design the experiment, this is the metric that decides it, so the definition matters more than it looks.

Click **Check**, then **Next**. You have a flag with two variations and a metric that measures them. That's everything an experiment needs.
