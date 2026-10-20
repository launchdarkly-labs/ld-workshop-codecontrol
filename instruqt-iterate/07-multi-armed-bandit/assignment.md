---
slug: multi-armed-bandit
id: ih7hyz4r7t9h
type: challenge
title: Multi-Armed Bandit
teaser: "Hand the decision to a bandit that routes traffic to whichever strategy is winning."
notes:
- type: text
  contents: "An experiment gives you one answer at one moment. A multi-armed bandit keeps answering, shifting traffic toward the leader as the data changes."
tabs:
- id: pk49zpxyndmh
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 67vhr9xu8m82
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: eq9xrfldxz5y
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
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
11. **Update frequency**: choose the shortest option offered. This is how often the bandit re-reads the results and shifts the split.
    <!-- VERIFY: the available update-frequency options; the solve script assumes one minute is allowed -->
12. Leave the starting **Variations split** equal.
13. Scroll up and click **Save**, then click **Start** and **Start multi-armed bandit**.

![Designing the bandit](../assets/itr-07-mab-design.png)

# Watch it shift

Open the bandit's **Results** tab.

1. **Cumulative exposures** shows how many shoppers each variation has received over time. It starts as two lines climbing together.
2. **Cumulative results** names the current **leading variation** and shows each variation's **probability to be best** and conversion rate.
3. Wait for the first update. When it lands, the exposures chart bends: Personalized's line steepens and Bestsellers' flattens, because the bandit just handed the leader most of the traffic. On the flag's **Targeting** tab, the default rule's allocation has changed to match.
   <!-- VERIFY: how the bandit's allocation is rendered on the Targeting tab and in the Results exposures chart; time to first reallocation with the exp profile -->

![Traffic shifting toward the leader](../assets/itr-07-mab-results.png)

Each update, the split moves again. If Bestsellers ever started winning, say the catalog changed and Personalized's picks got worse, the bandit would notice its probability to be best rising and route shoppers back without anyone filing a ticket.

# Experiment or bandit?

| | A/B experiment | Multi-armed bandit |
|---|---|---|
| Traffic split | Fixed for the iteration | Reallocated toward the leader on a schedule |
| Ends when | You stop it and ship a winner | Never has to; stop it when a variation reaches ~99% |
| Best for | Learning *whether* and *by how much*, with a clean read | Optimizing continuously when the cost of showing the loser is real |
| What you give up | Shoppers keep seeing the loser until you act | A less precise estimate of the losing variations |

The experiment taught you Personalized is better and by roughly how much. The bandit stops you from ever having to re-learn it.

Click **Check** once the bandit is running, then **Next** for the wrap-up.
