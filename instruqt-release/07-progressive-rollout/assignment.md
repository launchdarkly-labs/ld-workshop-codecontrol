---
slug: progressive-rollout
type: challenge
title: Progressive Rollout
teaser: Ramp Otto from a sliver of traffic to everyone, automatically.
notes:
- type: text
  contents: The beta testers like Otto. Time to release him to the world,
    but gradually. A progressive rollout ramps the flag up in stages while
    you watch real traffic move over.
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
timelimit: 900
enhanced_loading: null
---

# From beta to everybody

The Beta Testers have had Otto for a while and nobody's complained. Time to release him to everyone. But "everyone at once" is still a bad idea: if something's subtly wrong, you want it to hurt 10% of your traffic, not 100%.

A **progressive rollout** ramps a flag up automatically: LaunchDarkly serves the new variation to a growing percentage of contexts, stage by stage, on a schedule you set. Each visitor's experience is sticky — once someone's in, they stay in as the percentage grows.

One more thing changed: your shop now has traffic. We've turned on a stream of synthetic shoppers so the rollout has real contexts flowing through it — watch the [ToggleWear](#tab-1) server work in the background as they chat with Otto.

# Start the rollout

Go to the [LaunchDarkly](#tab-0) tab and open **release-otto**'s targeting view. The beta rule stays exactly as it is — beta testers keep Otto no matter what. The ramp happens on the **default rule**, which currently serves `false` to everyone else.

1. Edit the default rule and open its **Serve** menu.
2. Choose **Progressive rollout**.
   <!-- VERIFY: "Progressive rollout" appears in the fallthrough/default rule's Serve menu, not only on custom rules -->
3. Leave **Target by** on the **user** context kind.
4. LaunchDarkly shows a default schedule of stages. For the lab, shorten it so you can watch the whole ramp — set the stages to roughly:

   | Serve `true` to | For |
   |---|---|
   | 10% | 1 minute |
   | 25% | 1 minute |
   | 50% | 1 minute |
   | then 100% | — |

   <!-- VERIFY: the stage editor's exact shape (add/remove stages, percentage and duration fields) and the default schedule values — capture the defaults for the prose -->
5. Click **Review and save**.

![Configuring the progressive rollout](../assets/rel-07-progressive-config.png)

# Watch it ramp

Stay on the flag's targeting view. The default rule now shows the rollout progressing — which stage it's in and the percentage currently receiving `true`.
<!-- VERIFY: where rollout progress is displayed on the targeting view and what it looks like mid-ramp -->

![The ramp in progress](../assets/rel-07-ramp-progress.png)

While it runs, two things worth doing:

1. Switch the [ToggleWear](#tab-1) tab to **Free user** and refresh now and then. Your browser session is one context among the crowd: you might get Otto at 10%, or not until 100%. That's bucketing — each context lands on one side of the percentage consistently, no flapping.
2. Notice what you're *not* doing: no deploys, no manual weight changes. The schedule advances by itself.

After the last stage, the default rule serves `true` — Otto is fully released. The beta rule is still there, now redundant but harmless (next month's beta feature will want it anyway).

# The catch

One honest observation before you click **Check**: the whole ramp, nothing was *watching*. If a broken version of Otto had shipped at 10%, the rollout would have marched on to 100% anyway unless a human noticed. Percentages limit the blast radius; they don't detect the blast.

That's the next lab: a rollout with a metric watching it, and an automatic rollback when the metric goes bad.

Click **Check** once the rollout is underway (or done), then **Next**.
