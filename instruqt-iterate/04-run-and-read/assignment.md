---
slug: run-and-read
id: 2bu37vg92rrm
type: challenge
title: Run and Read
teaser: "Start the experiment, drive traffic through it, and read the results."
notes:
- type: text
  contents: "The design is done. Now you'll start the iteration, let the synthetic shoppers vote with their clicks, and learn to read what the results table is telling you."
tabs:
- id: 5hgab1idfzg2
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 3f76ttd8jatw
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: wrtplhncr2bi
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# Start the iteration

Experiments run in **iterations**: a block of time with one fixed configuration. Change anything that matters (hypothesis, metric, split) and LaunchDarkly closes the iteration and starts a new one, so results are never a blend of two designs.

In the [LaunchDarkly](#tab-0) tab, open your experiment from the **Experiments** list.

1. Click **Start**. A "Start experiment" dialog appears.
2. The flag is already on, so click **Start experiment**.
   <!-- VERIFY: dialog contents; the "Toggle on flag" step is skipped because the flag is on -->

That's it. Open the **recommendations-strategy** flag's **Targeting** tab for a second: the default rule now shows it's allocated by the experiment, 50/50.

![Starting the iteration](../assets/itr-04-start.png)

# Let the shop vote

The synthetic shoppers browse the carousel about twice a second, so the experiment gathers roughly a hundred shoppers a minute, split evenly between the two strategies. When something catches their eye, they click, and the click becomes a `recs-engagement` event for whichever variation they were served.

You're a shopper too. In the [ToggleWear](#tab-1) tab, refresh, and see which strategy you landed in: if clicking a product card changes the carousel, you're on Personalized. Click a recommendation or two. One vote.

# Read the results

Open the experiment's **Results** tab. Give it a couple of minutes to fill in; this is the one place in the workshop where patience is part of the lesson.
<!-- VERIFY: results latency with the exp traffic profile; what the table shows before the minimum sample is reached -->

![Reading the results](../assets/itr-04-results.png)

Work down the table for **Recs engagement**:

1. **Sample size** per variation. Watch it climb. Both sides should be roughly equal; a lopsided split would mean a sample ratio mismatch and LaunchDarkly would warn you.
2. **Conversion rate**: the percentage of shoppers in each variation who clicked at least once. This is the raw comparison. Personalized should pull ahead.
3. **Probability to be best**: the chance, given everything seen so far, that this variation is the true winner. Early on it hovers near 50/50. As samples accumulate it separates.
4. **Probability to beat control** and **relative difference**: for Personalized, how likely it is to beat Bestsellers, and by how much, with a range. When the probability clears your 90% threshold, the relative difference turns **green**.
5. **Expected loss**: what you'd expect to give up by shipping this variation if it turned out not to be the best. Low is reassuring.

Hover the chart to watch the two distributions separate over time. Narrow curves mean the estimate is tight; a wide curve is the statistics telling you it hasn't seen enough yet.

# What you're not doing

Notice what isn't happening. You aren't eyeballing two dashboards and arguing. You aren't shipping to everyone and checking back next quarter. You declared a hypothesis, split traffic fairly, and now a number is telling you how confident you're entitled to be. When Personalized's probability to beat control passes 90%, the answer is in, and the next lab acts on it.

Click **Check** once the experiment is running (results can keep accumulating while you move on), then **Next**.
