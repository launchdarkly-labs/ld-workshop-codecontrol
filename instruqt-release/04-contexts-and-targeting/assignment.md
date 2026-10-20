---
slug: contexts-and-targeting
type: challenge
title: Contexts and Targeting
teaser: Show Otto to beta users first.
notes:
- type: text
  contents: Shipping to everyone at once is what we're trying to avoid.
    You'll tell LaunchDarkly who each visitor is, then write a targeting rule
    so only beta users meet Otto first.
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

# Who gets Otto?

Right now `release-otto` is on for everyone. Real releases don't start that way — they start with a small group who opted into rough edges. At ToggleWear, that's the beta users.

Two pieces make that work. A **context** describes who's using the app right now: a key plus any attributes you care about, like a plan tier. A **targeting rule** tells LaunchDarkly which contexts get which variation: "if `tier` is `beta`, serve `true`."

The contexts you built last lab only have a key, so LaunchDarkly can't tell a beta user from anyone else yet. First we'll enrich the contexts, then write the rule.

# Tell LaunchDarkly about the tier

Open the [Code Editor](#tab-2) tab.

1. In `server.py`, find the `LaunchDarkly context paste block` you pasted last lab and replace it with this version, which adds the tier attribute:

   ```python
       # ─────────────────────────────────────────────────────────────────────
       # LaunchDarkly context paste block
       # ─────────────────────────────────────────────────────────────────────
       return (
           Context.builder(user_key)
           .kind("user")
           .set("tier", user_tier)
           .build()
       )
       # ─── End LaunchDarkly context paste block ─────────────────────────────
   ```

2. In `static/app.js`, replace the `LaunchDarkly client SDK paste block` with this version. Two changes: the browser context now carries `tier`, and switching the dropdown calls `identify()` — telling LaunchDarkly "this is someone else now, re-evaluate my flags":

   ```js
   // ─────────────────────────────────────────────────────────────────────────
   // LaunchDarkly client SDK paste block
   // ─────────────────────────────────────────────────────────────────────────
   let ottoEnabled = false;
   let ldClient = null;

   function ldContext() {
     return {
       kind: 'user',
       key: getSessionId(),
       tier: userTier,
     };
   }

   async function initLaunchDarkly() {
     const cfg = await (await fetch('/config')).json();
     ldClient = LDClient.createClient(cfg.clientKey, ldContext());
     const refresh = () => {
       ottoEnabled = ldClient.boolVariation('release-otto', false);
       applyOttoVisibility();
     };
     ldClient.on('ready', refresh);
     ldClient.on('change', refresh);
     await ldClient.start();
   }

   function onTierChanged() {
     if (ldClient) {
       ldClient.identify(ldContext()).then(() => {
         ottoEnabled = ldClient.boolVariation('release-otto', false);
         applyOttoVisibility();
       });
     }
   }
   // ─── End LaunchDarkly client SDK paste block ──────────────────────────────
   ```

3. Save both files.

# Write the targeting rule

Go to the [LaunchDarkly](#tab-0) tab and open the **release-otto** flag's targeting view.

1. Add a new targeting rule.
   <!-- VERIFY: current control for adding a rule on the Targeting tab — "+ Add rule" button and whether it offers rule-type choices (e.g. "Build a custom rule") -->
2. Build the condition: context kind **user**, attribute

   ```
   tier
   ```

   operator **is one of**, value

   ```
   beta
   ```

   <!-- VERIFY: attribute entry accepts a free-typed attribute name; operator label is "is one of" -->
3. Set the rule to serve **true**.
4. Now the important part: change the **default rule** (what's served when no rule matches) to serve **false**. Without this, non-beta users still get Otto and your rule means nothing.
   <!-- VERIFY: current label/placement of the default rule / fallthrough on the Targeting tab -->
5. Click **Review and save**.

![The rule builder](../assets/rel-04-rule-builder.png)

# Watch the rule work

Switch to the [ToggleWear](#tab-1) tab and refresh it.

1. The header dropdown says **Free user**. Otto is gone. The rule is doing its job: free users don't match, the default rule serves `false`.
2. Switch the dropdown to **Beta user**. The `identify()` call you pasted fires, LaunchDarkly re-evaluates, and Otto pops back in — for beta users only.
3. Flip between tiers a few times. Same page, same flag, different people, different experience. That's targeting.

Click **Check**. Next: your beta audience is defined inside one flag's rule, and that doesn't scale. Segments fix that.
