---
slug: welcome-recap
id: gmjglxulhnsr
type: challenge
title: Welcome Back to ToggleWear
teaser: The carousel works. But is the new version actually better? Time to find out.
notes:
- type: text
  contents: Whether you just finished the Observability track or are starting here,
    this challenge re-establishes where ToggleWear stands and what question this track
    answers.
tabs:
- id: h4x9dbic2uh7
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 2rdi4jquwoni
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: affog0amr3eb
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: m8cihyhubzdh
  title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 300
enhanced_loading: null
---

# Welcome back to ToggleWear

If you've done the earlier tracks: Otto is live, the **Recommended for You** carousel shipped, and you've seen what happens when a release goes wrong. If you're starting here: welcome. You're a developer at **ToggleWear**, a small shop for LaunchDarkly-branded apparel, and your job is to ship changes without breaking things. This track assumes you know what a flag and a targeting rule are; everything about experimentation, it teaches from zero.

Here's the state of the shop, materialized in your own LaunchDarkly project while this lab loaded:

- **Otto** the chat widget is live for everyone behind `release-otto`.
- The **Recommended for You** carousel sits under the product grid, gated by `show-recommendations` and filled by `recommendations-strategy`, which has two variations: **Bestsellers** (the same four popular items for everyone) and **Personalized** (items matching the product the shopper just viewed). The default rule serves **Bestsellers**.
- The bug Personalized once had in production is fixed. Both strategies work.
- Synthetic shoppers browse the shop around the clock, and they click recommendations when something catches their eye.

# The question

Everyone on the team *believes* Personalized is better. It demos better. It's cleverer. And nobody has a shred of evidence. Shipping it on a hunch would be guessing; this track is about not guessing.

**Experimentation** is how you let the shop decide: show each strategy to a random half of shoppers, measure the same thing for both, and let the statistics say which one wins. Then ship the winner. Then, for decisions that never stop needing to be made, let a **multi-armed bandit** keep routing traffic to whatever is winning right now.

| # | Beat |
|---|---|
| 02 | Create an engagement metric and wire the event that feeds it. |
| 03 | Design an A/B experiment: Bestsellers vs Personalized, with a hypothesis and a primary metric. |
| 04 | Run it against live traffic and read the results. |
| 05 | Quick quiz. |
| 06 | Promote the winner to everyone. |
| 07 | Hand the decision to a multi-armed bandit. |
| 08 | Wrap up the whole CodeControl journey. |

All code is copy-paste: one `track()` call. The rest happens in LaunchDarkly.

# Look around

1. [ToggleWear](#tab-1): scroll to **Recommended for You**, click a product card, and notice the carousel doesn't change. That's Bestsellers ignoring what you viewed. Now click an item *in the carousel*: it gets a green outline. That click is the behavior we're about to measure.
2. [LaunchDarkly](#tab-0): open **recommendations-strategy** and look at its two variations. Then find **Experiments** in the left sidebar. Empty, for now.
   <!-- VERIFY: sidebar placement of Experiments and Multi-armed bandits; Metrics under a "Data" section per current docs -->
3. [Code Editor](#tab-2): the editor opens on the shop's source, nothing else. In `server.py`, find the `/recommendations/click` endpoint. It receives every carousel click and, right now, does nothing with it. That's where the metric event will go.

Click **Check**, then **Next**.
