---
slug: multi-armed-bandit
id: xvxx9xdosxgx
type: challenge
title: Multi-Armed Bandit
teaser: Hand the decision to a bandit that routes traffic to whichever strategy is
  winning.
notes:
- type: text
  contents: An experiment gives you one answer at one moment. A multi-armed bandit
    keeps answering, shifting traffic toward the leader as the data changes.
tabs:
- id: ihfir8mo7kpt
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: lyyfdekvltp7
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: folwtrxp2tte
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: ucdmmu9uoplw
  title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# When the answer keeps changing

You ran an experiment, got an answer, and shipped it. For most decisions that's the right shape. But some decisions never settle: which strategy wins might change with the season, the catalog, or who's shopping today. Re-running an experiment every month is a lot of ceremony for a question the data could answer continuously.

A **multi-armed bandit** is an experiment that acts on its own results. It starts by splitting traffic evenly, measures the same metric, and then, on a schedule you choose, **reallocates traffic toward the variation most likely to be best**. The leader gets most of the shoppers; the others keep a small share so the bandit notices if they catch up. Statisticians call this balancing *exploitation* against *exploration*; LaunchDarkly implements it with Thompson sampling. You don't have to pick a winner, and you don't have to stop it.

# Build the bandit

In the [LaunchDarkly](#tab-0) tab, open **Multi-armed bandits** in the left sidebar.
<!-- VERIFY: sidebar entry name and location for Multi-armed bandits -->

1. Click **Create** and choose **Multi-armed bandit**.
2. Name it:

   ```
   Recommendations strategy bandit
   ```

3. Enter the goal:

   ```
   Keep routing shoppers to whichever recommendation strategy is currently winning on engagement.
   ```

4. Click **Create multi-armed bandit**. The **Design** tab opens.
5. **Randomize by**: **user**.
6. **Metric**: **Recs engagement**. Hover it to confirm the test environment is receiving events.
7. **Flag or config**: **recommendations-strategy**.
8. **Experiment audience**: the **default rule**.
9. **Variation served to users outside this experiment**: **Personalized** (the current winner; nobody is outside, since you'll include everyone).
10. Include **100%** of contexts.
11. **Update frequency**: choose **1 hour**, the shortest allowed. This is how often the bandit re-reads the results and shifts the split.
    <!-- VERIFY: the update-frequency options in the UI; the API accepts 1–24 hours (live play, 2026-10-20) -->
12. Leave the starting **Variations split** equal.
13. Scroll up and click **Save**, then click **Start** and **Start multi-armed bandit**.

![Designing the bandit](../assets/itr-07-mab-design.png)

# Read it, and know what happens next

Open the bandit's **Results** tab.

1. **Cumulative exposures** shows how many shoppers each variation has received over time. Right now it's two lines climbing together: the bandit starts with an even split.
2. **Cumulative results** names the current **leading variation** and shows each variation's **probability to be best** and conversion rate. Within a couple of minutes of shopper traffic, Personalized takes the lead, just as it did in the experiment.
3. On the flag's **Targeting** tab, the default rule now shows it's allocated by the bandit.
   <!-- VERIFY: how the bandit's allocation is rendered on the Targeting tab and in the Results exposures chart -->

![The bandit's first results](../assets/itr-07-mab-results.png)

Here's the part you won't see inside this lab: the shortest update frequency is **one hour**. At the top of each hour the bandit re-reads the results and hands the leading variation a share of traffic equal to its probability to be best. Personalized's exposures line steepens, Bestsellers' flattens, and nobody touched the flag. If Bestsellers ever started winning, say the catalog changed and Personalized's picks got worse, the next update would route shoppers back without anyone filing a ticket. A bandit is a decision that keeps making itself, on a schedule you chose.

# Experiment or bandit?

| | A/B experiment | Multi-armed bandit |
|---|---|---|
| Traffic split | Fixed for the iteration | Reallocated toward the leader on a schedule (hourly at the fastest) |
| Ends when | You stop it and ship a winner | Never has to; stop it when a variation reaches ~99% |
| Best for | Learning *whether* and *by how much*, with a clean read | Optimizing continuously when the cost of showing the loser is real |
| What you give up | Shoppers keep seeing the loser until you act | A less precise estimate of the losing variations |

The experiment taught you Personalized is better and by roughly how much. The bandit stops you from ever having to re-learn it.

Click **Check** once the bandit is running, then **Next** for the wrap-up.
