# OPERATOR-CHECKLIST-release.md

Per-challenge verification items for **Track 1 / Release** (`instruqt-release/`). These are tasks that can only be completed by an operator with browser access to a live LaunchDarkly project — Claude Code drafts UI steps from docs but cannot drive the UI itself (see "UI instructions in assignment.md are drafts pending operator verification" in `CLAUDE.md`).

This checklist is the verification plan to run **after** Claude Code authors the track. Tick items as they're verified.

---

## Cross-cutting items

- [ ] **Live-fire end-to-end smoke test** against a fresh sandbox: bootstrap → click through every challenge → solve every challenge → confirm every check passes. Time each challenge against the ~2h presenter / ~1h self-paced budgets.
- [ ] **Confirm challenges are numbered from `01`** and that Instruqt renders `01-welcome` (not skipped as a `00` would be).
- [ ] **Track-level `setup-workstation` timing** — bootstrap the project, mint the scoped token, write `.env`, restart the service. Should be well under 60s.
- [ ] **Confirm the skill contract** — `config.yml` declares the four secrets (`AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `LAUNCHDARKLY_ACCESS_TOKEN`) and the skill's Lambda URL; the `launchdarkly` tab actually signs the learner into their project (this depends on the participant Terraform's magic-login record). **Confirm which Lambda URL is live** — the skill's (`l5vv6unuu4…`, used here) vs. the older one in the reference tracks (`i3vcudz5…`).
- [ ] **Run `instruqt track validate` then `instruqt track push`** from each track directory; the first push assigns the `id:` fields — commit them afterward.
- [ ] **VM image bake** from `vm-image/` inputs produces a working image; confirm the app starts on boot and serves on port 3000.
- [ ] **Confirm the mock Otto** returns on-brand canned replies and never attempts a model call.
- [ ] **Confirm client-side SDK availability defaults on** for flags created in the sandbox project (docs: accounts created after 2025-10-21 default it on). If not, challenge 02/03 prose must teach the "SDKs using Client-side ID" setting — note which label the create-flag dialog actually shows.

## Per-challenge verification

For each challenge: confirm UI labels in `assignment.md` against the live LD UI; capture screenshots into `instruqt-release/assets/`; add `![alt](../assets/<file>)` references at the right beats; complete the lab as a real learner; click Check (expect pass); run solve from a fresh state and click Check again (expect pass); deliberately fail one assertion and confirm the `fail-message` is helpful.

### 01 Welcome
- [ ] Copy reads cleanly; the ToggleWear "ship safely" premise and app/LD tour land. No task beyond continue.

### 02 Your first flag
- [ ] Verify UI for **Create flag**: the flags list, **Create flag** button, key/name/type fields, boolean variation defaults, the environment toggle. Confirm the created flag key matches what the check expects (`release-otto`).
- [ ] Screenshot: the create-flag dialog and the new flag in the list.

### 03 Wire up the SDK
- [ ] Verify the server SDK paste lands in `server.py` at the marker and reloads the service correctly; confirm the client SDK paste lands in `app.js`.
- [ ] Confirm turning `release-otto` on makes Otto appear on the [ToggleWear](#tab-1) tab, and off makes him disappear.
- [ ] Verify where the SDK key / client-side ID are surfaced in the UI (the assignment should point the learner to them, or the setup should have injected them).

### 04 Contexts and targeting
- [ ] Verify UI for adding a targeting rule: the Targeting tab, the rule builder (context kind, attribute, operator, value), serving a variation, save/review flow.
- [ ] Confirm flipping the header dropdown to **Beta user** makes Otto appear only for that context (SDK picks up the rule).
- [ ] Screenshot: the rule builder.

### 05 Segments
- [ ] Verify UI for **Create segment**, adding members/rules, and referencing the segment from the flag's targeting rule.
- [ ] Confirm the "Beta Testers" segment name matches the check.
- [ ] Screenshot: segment creation and the segment-referencing rule.

### 06 Quiz — flags and targeting
- [ ] Confirm exactly one correct answer per question; Instruqt renders the answers list without markdown artifacts.

### 07 Progressive rollout
- [ ] Verify the **progressive rollout** entry point (Targeting tab → edit rule → **Serve** menu → **Progressive rollout**) and the configuration flow: Target by (context kind) and the stage schedule editor.
- [ ] **Capture the default progressive-rollout schedule** (stage percentages and durations) — not published in docs; the assignment prose needs the real numbers.
- [ ] Confirm the traffic generator (started in setup) produces visible variation across contexts and the ramp advances on schedule.
- [ ] **Confirm the check's read surface**: while a progressive rollout is mid-ramp, `GET /api/v2/flags/<proj>/release-otto` should show `.environments.test.fallthrough.rollout`. The check passes on that OR on the completed state (`fallthrough.variation == 0`); tighten it if the live JSON shows a more specific marker.
- [ ] Confirm the solve's completed-state JSON patch (fallthrough → `true`) leaves the flag in the same state as a finished UI ramp, and that 08's guarded rollout can start afterward.
- [ ] Screenshot: the progressive rollout configuration and an in-progress ramp (`rel-07-progressive-config.png`, `rel-07-ramp-progress.png`).

### 08 Guarded release
- [ ] Verify the **guarded rollout** entry point (Targeting tab → edit rule → **Serve** menu → **Guarded rollout**) and the configuration flow: health check, metric picker (expect `otto-response-latency`), the per-metric **Automatic rollback** checkbox, Target by, and rollout duration.
- [ ] **Capture the default guarded-rollout duration/stages** and whether any regression-threshold field appears in the creation dialog (docs show none — detection is sequential testing on absolute difference, no user threshold).
- [ ] **Note the minimum contexts-per-step** if surfaced anywhere in the UI (never published in docs); confirm lab traffic volume clears it so steps don't auto-extend past presenter patience.
- [ ] Confirm the regression fires from organic traffic (Chatty Otto's slower replies) within a presenter-friendly window, and that the sabotage script forces it on demand.
- [ ] Confirm the rollback reverts to Concise Otto and the app reflects it.
- [ ] ~~Verify the beta-API-driven solve produces a real monitored guarded rollout~~ **Live play 2026-10-19: the release-pipelines beta POST returned 404; the solve fell back to Concise.** Decide: accept Skip→Check failing on 08, relax the check, or find a working API (check the account's release-pipelines entitlement / try release policies).
- [ ] Screenshots: the guarded-rollout configuration, an in-progress rollout, the regression-detected event, the post-rollback state.

### 09 Kill switch
- [ ] Verify the flag toggle that turns targeting off instantly; confirm the feature disappears immediately on the [ToggleWear](#tab-1) tab **without a refresh** (the change listener).
- [ ] Confirm the check validates the flag's targeting is off.
- [ ] Confirm the closing "turn Otto back on" step lands — the track should end with Otto live (later tracks' baselines re-enable the flag after replaying this solve; see the note in `terraform/release-09/main.tf`).

### 10 Wrap-up
- [ ] Recap reads cleanly and reflects what the learner did; the transition to Observability lands.
- [ ] Confirm any final quiz questions have exactly one correct answer.

---

## How to mark progress

Tick items as `[x]` when verified. Capture per-item gotchas inline as plain prose under the bullet (e.g. a button label differs from the docs draft; alternative wording chosen). When all per-challenge items are ticked and the cross-cutting smoke test passes, Release is ship-ready.
