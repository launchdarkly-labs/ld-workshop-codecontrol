---
slug: welcome-recap
id: bzwwgk06cm3u
type: challenge
title: Welcome Back to ToggleWear
teaser: Otto is live. Now the shop wants recommendations, and you want to see what
  breaks.
notes:
- type: text
  contents: Whether you just finished the Release track or are starting here, this
    challenge re-establishes where ToggleWear stands and what you're about to ship.
tabs:
- id: xxiincx10lt3
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: hxegbqyu6sgi
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: jiaruzyw5brn
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: 3b6fwhqr2thx
  title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 300
enhanced_loading: null
---

# Welcome back to ToggleWear

If you just finished the Release track: Otto is live, you shipped him safely, and you already know what a guarded release feels like. If you're starting here: welcome. You're a developer at **ToggleWear**, a small online shop for LaunchDarkly-branded apparel, and your job is to ship changes to the live site without breaking it. This track assumes you know what a feature flag is and have seen a LaunchDarkly targeting rule; everything about observability, it teaches from zero.

Here's where the shop stands. While this lab was loading, your own LaunchDarkly project was created and brought up to the end of the Release story:

- **Otto**, the chat widget, is behind `release-otto` and fully rolled out. Say hi to him in the [ToggleWear](#tab-1) tab.
- `otto-style` and its latency metric from Otto's guarded release are there too. You won't touch them in this track.
- A new feature shipped: the **Recommended for You** carousel under the product grid, gated by `show-recommendations` and filled by the `recommendations-strategy` flag, which currently serves **Bestsellers**, the same four popular items for everyone.
- Synthetic shoppers browse the site in the background, so the shop always has traffic.

# The premise

The team built a second strategy for the carousel, **Personalized**: recommend items in the same category as the product the shopper just viewed. It demos beautifully. It also has a bug nobody has noticed, and this track is the story of shipping it anyway and learning to *see* what happens.

The Release track answered "how do I release without holding my breath?" This track answers the next question: **"how do I know the moment something breaks, and how do I make the fix automatic?"**

| # | Beat |
|---|---|
| 02 | Instrument the app with LaunchDarkly's observability plugins, then ship Personalized and watch the first error arrive. |
| 03 | See the error attributed to the exact flag variation that caused it, and replay the shopper's session. |
| 04 | Read release health with metrics LaunchDarkly generated from your instrumentation, then revert. |
| 05 | Quick quiz. |
| 06 | Re-release Personalized behind a guarded release that watches the *real* error rate. |
| 07 | Arm an adaptive trigger so a regression after release heals itself. |
| 08 | Wrap up, and a look at the Iterate track. |

Everything you paste is copy-paste. The point is seeing how observability wires into an app and into releases, not typing.

# Look around

1. [ToggleWear](#tab-1): scroll down to **Recommended for You**. Click a product card; the carousel doesn't change yet, because Bestsellers ignores what you viewed. Remember the **Rollout Tote**. It matters later.
2. [LaunchDarkly](#tab-0): open the **Flags** list. Four flags: two from the Release track, two for the carousel. Open **recommendations-strategy** and note its two variations and the default rule serving **Bestsellers**. Then find **Telemetry** in the left sidebar; its **Errors**, **Sessions**, and **Alerts** pages are empty right now. They won't stay that way.
   <!-- VERIFY: sidebar section name ("Telemetry") and which pages appear under it before any observability data exists -->
3. [Code Editor](#tab-2): open `server.py` and find `_recommend_personalized`. Spot the line that reads `viewed["category"]` with no guard. Don't fix it. That's the bug, and it's the whole plot.

Click **Check**, then **Next**.
