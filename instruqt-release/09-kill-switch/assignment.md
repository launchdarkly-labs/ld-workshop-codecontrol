---
slug: kill-switch
id: lvaimrbwbgmq
type: challenge
title: The Kill Switch
teaser: Turn a misbehaving feature off in seconds.
notes:
- type: text
  contents: Sometimes you don't want a ramp or a guard. Something is wrong
    right now and you want it off. That's the kill switch, and it's the
    simplest move in the whole workshop.
tabs:
- id: zw50aim215gu
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: jbiix1jpxrd9
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: s9lzkfybnahi
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# When you just need it off

It's 4:55pm on a Friday. Support says Otto is confidently giving customers the wrong shipping answers. You don't know why yet. You don't need to know why yet — you need him *gone*, and then you can investigate on Monday's schedule instead of Friday's adrenaline.

That's the **kill switch**: a flag's targeting toggle used as an off button. No ramp, no metric, no statistics. Off. Because Otto lives behind `release-otto`, you already built it — you just haven't pulled it in anger.

# Pull it

1. First, look at the [ToggleWear](#tab-1) tab. Otto's there in the corner, blissfully unaware.
2. In the [LaunchDarkly](#tab-0) tab, open **release-otto**.
3. Flip the flag's targeting toggle to **Off** and click **Review and save**.
4. Now watch the [ToggleWear](#tab-1) tab — don't refresh, just watch. Within a few seconds Otto vanishes. Every open browser session, everywhere, at once. The `change` listener you wired in the SDK lab is doing exactly what it was built for.

![The flag toggled off](../assets/rel-09-flag-off.png)

The off state isn't an accident, either: when targeting is off, the flag serves its **off variation** — `false`, which you've had configured since the day you created the flag. A kill switch is only as good as its off variation, so it's worth deciding that value on day one, like you did.

Two habits make this a real practice rather than a party trick:

- **Keep permanent flags around critical features.** `release-otto` earned permanent status today. Kill-switch flags aren't tech debt; they're circuit breakers.
- **It doesn't have to be a human.** The same "turn it off" action is one API call (the `turnFlagOff` instruction), which monitoring tools can fire via flag triggers. In the Observability track, you'll see LaunchDarkly do this kind of thing for you automatically.

# Stand down

Click **Check** to confirm the kill.

Then — since the Friday crisis was a drill — flip **release-otto** back **On** and save. Otto returns to his corner, and ToggleWear's story continues with him live.

Click **Next** for the wrap-up.
