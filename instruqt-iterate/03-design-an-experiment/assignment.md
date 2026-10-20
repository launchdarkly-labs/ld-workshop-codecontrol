---
slug: design-an-experiment
type: challenge
title: Design an Experiment
teaser: "Set up an A/B experiment: Bestsellers vs Personalized, a hypothesis, and a primary metric."
notes:
- type: text
  contents: "You have two strategies and a metric. Now you'll write down what you expect to happen and build the experiment that will test it."
tabs:
- title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# Say what you expect before you look

An **experiment** splits traffic between flag variations at random, measures the same metric for each group, and tells you whether the difference is real or noise. The design step is where you commit, before any data comes in, to what you're testing and what would count as a win. Writing the hypothesis down first is what keeps "we'll know it when we see it" from turning into "we saw what we wanted."

Our hypothesis: *Personalized recommendations will increase the share of shoppers who click a recommended item, compared to Bestsellers.*

# Create the experiment

In the [LaunchDarkly](#tab-0) tab, open **Experiments** in the left sidebar.

1. Click **Create** and choose **Experiment**.
   <!-- VERIFY: the Create button's menu (Experiment / Multi-armed bandit / Holdout) and dialog field names -->
2. Name it:

   ```
   Recommendations strategy: Bestsellers vs Personalized
   ```

3. Enter the hypothesis:

   ```
   Personalized recommendations will increase the share of shoppers who click a recommended item compared to Bestsellers.
   ```

4. Click **Create experiment**. The experiment's **Design** tab opens. Work through its sections:

**Variations and audience targeting**

5. Leave the assignment method on **LaunchDarkly flag or config** and choose the flag **recommendations-strategy**.
6. For the **Targeting rule**, choose the **default rule**. It's the only rule the flag has, so every shopper is eligible.
7. **Randomize by**: **user**. This must match the metric's analysis unit, and it does.

**Audience allocation**

8. For the **Variation served to contexts outside this experiment**, choose **Bestsellers**. Nobody is outside it (you'll include everyone), but the safe default is the right answer anyway.
9. Include **100%** of contexts in the experiment.
10. Leave **Disable reshuffling** checked. Once a shopper is assigned a variation, they keep it.
    <!-- VERIFY: default state of the reshuffling checkbox and its label -->

**Variations split**

11. Click **Edit** and **Split equally**: 50% Bestsellers, 50% Personalized. Save the split.
12. Mark **Bestsellers** as the **Control**. The control is the baseline every other variation is compared against.

**Metrics**

13. Metric source **LaunchDarkly**. Select **Recs engagement**. With one metric it's the primary automatically.

**Statistical approach**

14. Choose **Bayesian** with the standard **90%** threshold. Bayesian analysis gives you a plain-language *probability that each variation is best*, and it's the approach LaunchDarkly recommends for samples under a thousand, which describes a workshop lab exactly.
    <!-- VERIFY: label and default of the statistical-approach selector; threshold presets -->

15. Scroll to the top and click **Save**.

![The experiment design](../assets/itr-03-experiment-design.png)

Don't start it yet. Look at what you've built: the flag decides *who sees what*, the metric decides *what counts*, and the experiment ties them together with a hypothesis and a fair split. Every piece was something you already had. The experiment is just the agreement about how to read them.

# Two things worth knowing

- **The experiment doesn't change the flag until it runs.** The default rule still serves Bestsellers to everyone. When you start the experiment in the next lab, LaunchDarkly takes over the default rule's allocation for the duration.
- **One experiment per rule.** You could run a second experiment on a different targeting rule of the same flag, but never two on the same rule at once. Guarded and progressive rollouts on the rule block it too; neither is running here.

Click **Check**, then **Next** to start the experiment and watch the data come in.
