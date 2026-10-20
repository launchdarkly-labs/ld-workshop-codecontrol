---
slug: promote-the-winner
id: smyll2mfoysx
type: challenge
title: Promote the Winner
teaser: Ship the winning strategy to everyone.
notes:
- type: text
  contents: 'The experiment has an answer. In this challenge you''ll act on it: stop
    the iteration, name the winner, and serve it to every shopper.'
tabs:
- id: t0jkp9ydqkvo
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 22oryyqk9yc5
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: mqggkn3e0lll
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: 9el6a4gjsqcv
  title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 900
enhanced_loading: null
---

# Act on the answer

Back in the [LaunchDarkly](#tab-0) tab, open your experiment's **Results** tab. If Personalized's probability to beat control has crossed 90%, its row is highlighted green and LaunchDarkly offers a **Ship it** button. If it's not there yet, let the shoppers vote for another minute (or open the terminal in the [Code Editor](#tab-2) tab and run `python3 /opt/ld/codecontrol/traffic-generator/sabotage.py --target recs` to hurry them along; the clicks it generates are weighted exactly like normal traffic).
<!-- VERIFY: "Ship it" button appearance and conditions; the Stop → Ship menu flow as the alternative -->

**Shipping a winner** does two things at once: it stops the iteration, recording Personalized as the winner with your reason, and it changes the flag's default rule to serve Personalized to everyone. Experiment and flag stay in sync because they were never separate things.

1. Click **Ship it** (or click **Stop** and choose **Personalized** from the **Ship** menu).
2. Enter a **Reason for stopping**:

   ```
   Personalized beat Bestsellers on recommendation engagement with >90% probability.
   ```

3. Click **Stop experiment**.

![Shipping the winner](../assets/itr-06-ship-it.png)

# Confirm it

1. Open the **recommendations-strategy** flag's **Targeting** tab. The default rule serves **Personalized**. The experiment's allocation is gone; this is an ordinary flag again, with a decision behind it.
2. In the [ToggleWear](#tab-1) tab, refresh and click a few product cards. The carousel follows you now, for everyone.
3. Back on the experiment, the **Results** tab is frozen at the moment you stopped, with the winner recorded. Six months from now, when someone asks why the carousel works this way, the answer is a link, not a memory.

# Why this beats the alternative

Compare to how this decision usually gets made: someone senior likes Personalized, it ships, and the team never finds out whether it helped. Here the shop made the call, you can prove it, and if you ever want to revisit it (a new strategy, a different season) you run another iteration. The flag never goes away; it's the switch the next experiment will use.

Click **Check**, then **Next**. One more lab, and it's the one where you stop making this decision at all.
