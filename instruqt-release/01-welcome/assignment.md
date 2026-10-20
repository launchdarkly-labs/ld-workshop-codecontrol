---
slug: welcome
id: fecknra7q6wt
type: challenge
title: Welcome to ToggleWear
teaser: Meet the shop, meet Otto, and see what shipping safely looks like.
notes:
- type: text
  contents: ToggleWear is live and you're its newest developer. Before we ship
    anything, take a look around the shop and the LaunchDarkly project you'll
    be working in.
tabs:
- id: i5jh20wfpyha
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: hmuu9d3ucivq
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: wuekzko1nztq
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 300
enhanced_loading: null
---

# Welcome

You're the newest developer at **ToggleWear**, a small online shop selling LaunchDarkly-branded apparel. The shop is live, real customers are browsing it right now, and your first assignment is already on the board: ship **Otto**, a chat widget that helps shoppers with sizing and shipping questions.

Here's the catch, and the whole point of this track: you're going to ship him **without ever holding your breath**. No big-bang deploy, no "looks fine on my machine," no hoping. You'll release Otto gradually, to the right people, with automatic safety nets, using **LaunchDarkly**.

No LaunchDarkly experience required. This track teaches everything from zero.

# What you'll do

| # | Beat |
|---|---|
| 02 | Create your first feature flag. |
| 03 | Wire the LaunchDarkly SDKs into the app — Otto appears when you flip a toggle. |
| 04 | Target Otto to beta users with contexts and rules. |
| 05 | Make the beta audience reusable with a segment. |
| 06 | Quick quiz to consolidate. |
| 07 | Ramp Otto to everyone with a progressive rollout. |
| 08 | Ship a risky new Otto behind a guarded release, and watch it roll itself back. |
| 09 | Pull the kill switch. |
| 10 | Wrap up. |

This is Track 1 of the CodeControl series. **Observability** (releases you can see into) and **Iterate** (experiments that pick winners for you) build on what you do here.

# Look around

You have three tabs, and all of them matter:

1. [ToggleWear](#tab-1) — the live storefront. Browse it. Note what's *missing*: no chat widget anywhere. Otto doesn't exist yet.
2. [LaunchDarkly](#tab-0) — your own LaunchDarkly project, created just for this session. It's nearly empty. The flags list is where everything starts.
3. [Code Editor](#tab-2) — the shop's source code. You'll paste a few marked blocks into it along the way; all code is copy-paste, never from scratch.

When you've had a look, click **Check**, then **Next**. Otto is waiting to exist.
