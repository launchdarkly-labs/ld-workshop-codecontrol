---
slug: segments
id: yym7qpy0oekj
type: challenge
title: Segments
teaser: Make your beta audience reusable.
notes:
- type: text
  contents: One targeting rule for one flag works, but your beta testers will be trying
    more than Otto. Segments make that audience something you define once and reuse
    everywhere.
tabs:
- id: xtxvmpw0dry5
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: u0ijkkgdtxjw
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: u75hpwlp0igd
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: xulh7mfhfn3k
  title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# One audience, many flags

Your beta rule works, but think ahead: next month ToggleWear ships three more features, all "beta users first." Copying the same `tier is beta` condition into every flag means that when the definition of "beta user" changes, you edit every flag and hope you found them all.

A **segment** is a reusable audience: you define who's in it once, and any number of flags can target it. Change the segment, and every flag targeting it updates instantly.

You'll create a "Beta Testers" segment, then re-point Otto's rule at it. Nothing changes for your users; everything changes for the next feature you ship. No code this time.

# Create the segment

Go to the [LaunchDarkly](#tab-0) tab.

1. In the left sidebar, click **Segments**.
2. Click **Create segment**.
3. For the name, enter:

   ```
   Beta Testers
   ```

4. The key should read `beta-testers` — fix it if not.
5. If asked for a segment type, choose the standard rule-based segment.
   <!-- VERIFY: whether the create-segment dialog asks for a type (rule-based vs synced/big segment) in this account -->
6. Create the segment, then add a rule to it: context kind **user**, attribute

   ```
   tier
   ```

   operator **is one of**, value

   ```
   beta
   ```

7. Save the segment.
   <!-- VERIFY: rule-editing flow on the segment page — inline builder vs edit mode, and the save button label -->

![The Beta Testers segment](../assets/rel-05-segment.png)

# Point the flag at the segment

Now the swap. Open the **release-otto** flag's targeting view.

1. Edit the targeting rule you built last lab.
2. Replace its condition: instead of matching on the `tier` attribute, make the rule match contexts that are **in** the segment **Beta Testers**.
   <!-- VERIFY: how the rule builder expresses segment match — a "Segment" option in the attribute/operator picker vs a separate rule type -->
3. The rule still serves **true**, and the default rule still serves **false**. Leave both alone.
4. Click **Review and save**.

![The segment-based rule](../assets/rel-05-segment-rule.png)

# Confirm nothing broke

Switch to the [ToggleWear](#tab-1) tab.

1. As a **Beta user**, Otto is there.
2. As a **Free user**, he's gone.

Identical behavior, better plumbing: "who is a beta tester" now lives in exactly one place.

Click **Check**, then **Next** — a quick quiz to lock in what you've learned, and then we start rolling Otto out to everyone.
