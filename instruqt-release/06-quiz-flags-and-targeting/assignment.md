---
slug: quiz-flags-and-targeting
id: nus2tcdrv5nl
type: quiz
title: 'Quiz: Flags and Targeting'
teaser: Check your understanding of flags, contexts, targeting, and segments.
notes:
- type: text
  contents: Quick checkpoint before we start rolling Otto out. One question on the
    machinery you just built — flags, contexts, targeting rules, and segments.
answers:
- Copy the "tier is one of beta" condition from release-otto's old rule into a new
  rule on release-wishlist.
- Add a targeting rule on release-wishlist that serves true when the context is in
  the Beta Testers segment.
- Just toggle release-wishlist on — targeting rules apply project-wide, so the beta
  rule from release-otto already covers it.
- Change release-wishlist's default rule to serve true for beta users.
solution:
- 1
difficulty: basic
timelimit: 600
enhanced_loading: null
---
Four challenges in, Otto exists and only the right people can see him. The pieces so far:

- A **flag** (`release-otto`) controls the feature without deploys.
- The **SDKs** connect the app to LaunchDarkly, evaluating the flag server-side and client-side.
- A **context** describes who's using the app — including the `tier` attribute you added.
- A **targeting rule** serves `true` to the right contexts, and since the last lab it points at the **Beta Testers segment** instead of a copy-pasted condition.

# One question

Your teammate ships a new feature behind a new flag, `release-wishlist`, and wants the same beta group to see it first. What's the right move?
