---
slug: your-first-flag
type: challenge
title: Your First Feature Flag
teaser: Create the flag that will control Otto's release.
notes:
- type: text
  contents: ToggleWear wants a chat widget named Otto, but nobody wants to
    ship him to everyone at once. Step one is creating the feature flag that
    will control his release.
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
timelimit: 600
enhanced_loading: null
---

# Otto needs a flag

ToggleWear is adding Otto, a chat widget that helps shoppers with sizing and shipping questions. The code is nearly ready. What we're **not** going to do is deploy it and hope for the best.

A **feature flag** is a switch that controls whether a feature is on or off — without deploying code. Wrap Otto in a flag, and turning him on (or off, for everyone or just for some people) becomes a click in LaunchDarkly instead of a redeploy.

In this challenge you'll create that flag. No code yet; that's the next lab.

# Create the flag

Head to the [LaunchDarkly](#tab-0) tab. You're in your own sandbox project, created just for this session.

1. In the left sidebar, click **Flags**.
2. Click **Create flag**.
3. For the name, enter:

   ```
   Release Otto
   ```

4. LaunchDarkly generates the key `release-otto` from the name. **The key must be exactly `release-otto`** — the app's code will evaluate the flag by this key. If it shows anything else, fix it now; the key can't change after creation.
   <!-- VERIFY: key auto-generation produces "release-otto" from "Release Otto" in the current create-flag dialog -->
5. For the description, enter:

   ```
   Gates Otto, the ToggleWear chat widget.
   ```

6. Under flag type or configuration, keep the **Boolean** flag with two variations, `true` and `false`.
   <!-- VERIFY: current create-flag dialog layout — template picker vs. flag type section, and the default variation setup -->
7. Make sure the **SDKs using Client-side ID** checkbox is checked. Otto's show/hide logic runs in the browser, and client-side SDKs can only see flags with this enabled. New projects usually have it on by default — confirm rather than assume.
   <!-- VERIFY: exact label and location of the client-side availability checkbox in the create dialog; whether it is checked by default in this account -->
8. Click **Create flag**.

![The create-flag dialog](../assets/rel-02-create-flag.png)

You'll land on the flag's page. Notice the big toggle: the flag exists, and it's **Off**. Otto stays hidden, exactly what we want until the code is wired up.

![The new flag, off](../assets/rel-02-flag-off.png)

# Check your work

Click **Check** to verify the flag. Then click **Next** — it's time to connect this flag to the app.
