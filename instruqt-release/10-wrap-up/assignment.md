---
slug: wrap-up
type: quiz
title: Wrap-Up
teaser: What you shipped, what you learned, and what's next.
notes:
- type: text
  contents: Otto is live, guarded, and one toggle away from off. One last
    question, then a look at where the series goes next.
answers:
- "A progressive rollout ramps in smaller percentage steps, while a guarded rollout ramps all at once."
- "They're the same mechanism — \"guarded\" is just the name for a progressive rollout on a paid plan."
- "A progressive rollout ramps traffic on a schedule but nothing watches it; a guarded rollout also monitors a metric and can automatically roll back when the new variation regresses."
- "A guarded rollout requires the kill switch to be configured first, and a progressive rollout doesn't."
solution:
- 2
difficulty: basic
timelimit: 600
enhanced_loading: null
---
# Otto's release arc

At the start of this track, ToggleWear had no chat widget and you'd maybe never touched LaunchDarkly. Since then:

- **02** — you created `release-otto`. A flag: the power to change behavior without deploying.
- **03** — you wired both SDKs and flipped the toggle. Otto appeared on a live page in seconds, and off by default became your safety posture.
- **04** — you enriched contexts with a `tier` attribute and wrote a targeting rule. Same site, different people, different experience.
- **05** — you moved the audience into the **Beta Testers** segment. Define who once, reuse it everywhere.
- **07** — a **progressive rollout** ramped Otto from a sliver of traffic to everyone, on a schedule, while synthetic shoppers streamed through.
- **08** — the big one. Chatty Otto shipped behind a **guarded release**: Release Guardian watched the `otto-response-latency` metric, caught the real regression, and rolled everyone back to Concise Otto. Nobody paged you.
- **09** — you pulled the **kill switch**. Off, everywhere, in seconds, because the off variation was worth deciding on day one.

# The idea to keep

Every mechanism in this track answers the same question — *"how much damage can this release do?"* — at a different moment:

1. **Targeting and segments** decide *who* gets it (before anyone does).
2. **Progressive rollouts** limit *how many* get it (while it ramps).
3. **Guarded releases** watch *what it's doing* and revert automatically (while it ramps).
4. **The kill switch** is the manual override (any time at all).

Ship anything — a chat widget, a checkout flow, a schema migration — behind that stack, and "release day" stops being an adrenaline event.

# One last question

You used both a progressive rollout (07) and a guarded rollout (08). What's the actual difference?

# Where to go from here

- **Observability (Track 2)** — ToggleWear ships its next feature, a "Recommended for You" carousel, and it starts throwing errors in production on certain products. You'll instrument the app so errors show up attributed to the release that caused them, watch release health per variation, run a guarded release on a *real* instrumented error metric, and set up auto-remediation so the system heals itself.
- **Iterate (Track 3)** — stop guessing which version is better; measure it. Experiments, metrics, and a multi-armed bandit that routes traffic to the winner automatically.
- **Docs** — [launchdarkly.com/docs](https://launchdarkly.com/docs), particularly the Releases section for everything you touched today.

# Otto says

> You turned me on, turned me off, rolled me out, and rolled me back, and I never once went down in flames. Ship everything like that.
