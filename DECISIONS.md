# DECISIONS.md

This file records every meaningful decision made during planning, with the reasoning behind it. When Claude Code (or any contributor) is tempted to reopen a decision, they should read the rationale here first.

Format: one decision per section, dated, with options considered and reason for the chosen path. Add new decisions to the bottom as they arise.

The dates below reflect the planning session that produced this workshop. Decisions carried over unchanged from the AgentControl workshop (`ld-workshop-ai-configs-intro`) are noted as such.

---

## Product scope: CodeControl, not AgentControl (2026-07-07)

**Decision:** This workshop teaches **CodeControl** — LaunchDarkly's feature-management / progressive-delivery / release-observability / experimentation surface. It does not touch AgentControl (AI Configs, judges, agent-mode Configs, agent graphs). Three tracks map to the three CodeControl pillars the operator named: **Release**, **Observability** (release observability specifically), and **Iterate** (experimentation).

**Rationale:** CodeControl and AgentControl are the two halves of the LaunchDarkly platform. The AgentControl workshop already exists (`ld-workshop-ai-configs-intro`). This one covers the other half. Confirmed against the current launchdarkly.com CodeControl feature lineup: feature flags (targeting, progressive rollouts, automated rollbacks, feature monitoring), observability (error monitoring, auto-remediation), and experimentation (A/B/n, multi-armed bandits, holdouts).

---

## Audience: developers new to LaunchDarkly (2026-07-07)

**Decision:** The workshop assumes **no prior LaunchDarkly knowledge.** The Release track teaches fundamentals from zero — projects, flags, contexts, targeting, segments, SDK wiring — before progressing to guarded releases. Later tracks build on that foundation.

**Rationale:** This is the single most important divergence from the AgentControl workshop, which explicitly assumed LD mastery and refused to re-teach basics. The operator confirmed this workshop is aimed at devs new to LD, delivered live (also fine self-paced). Teaching fundamentals in Track 1 makes the whole series a coherent on-ramp rather than an intermediate course.

**Consequence:** Release is the longest track (10 challenges) because it carries the foundational load. Observability and Iterate can assume the fundamentals were taught in Release and re-establish only the specific state they need, via a recap challenge.

---

## Delivery format and cadence (2026-07-07)

**Decision:** Each track is a 2-hour presenter-led format with slide-based lecture interleaved between labs; the same content runs ~1 hour self-paced. Each track has one quiz interstitial and a wrap-up. Challenge counts: Release = 10, Observability = 8, Iterate = 8.

**Rationale:** Matches the reference pattern and the requested delivery profile. The quiz is a natural break point for presenters and a consolidation moment for self-paced learners. Counts were set by the operator.

---

## Three sibling tracks, standalone but continuous (2026-07-07)

**Decision:** Release → Observability → Iterate form a light continuous arc (same shop, same developer, features carried forward), but **each track is independently deliverable.** Observability and Iterate each open with a recap challenge (`01-welcome-recap`) that re-establishes context, and their track-level `setup-workstation` runs prior-track solves to materialize the baseline state.

**Rationale:** The operator wanted continuity for narrative payoff without forcing learners through all three in sequence. The recap-challenge-plus-prior-solves pattern is exactly what the AgentControl workshop used for its Evaluate and Coordinate tracks, and it works.

**Trade-off accepted:** A learner starting Observability or Iterate cold pays a small startup delay while prior solves materialize. Acceptable for the simplicity of one shared image. If the delay exceeds ~60s, fall back to pre-baking the baseline into the VM image (flagged in each `PHASES-<track>.md`).

---

## Challenges start at `01`, never `00` (2026-07-07)

**Decision:** Every track's first challenge is numbered `01` (`01-welcome` / `01-welcome-recap`). No `00-` challenge folder exists anywhere in this repo.

**Rationale:** Instruqt ignores a challenge numbered `00`. The AgentControl workshop used `00-welcome`, which is a latent bug there (its welcome challenge is effectively skipped). We start correct here. This convention is also documented in `CLAUDE.md` under Instruqt conventions so it isn't accidentally "corrected" back to `00`.

---

## Reuse the ToggleWear app, stripped to a mock (2026-07-07)

**Decision:** Copy the ToggleWear app from the AgentControl workshop's `app/` into this repo and strip out all AI-Config wiring. The app is the same storefront shell — header with a user-tier dropdown, product grid of LaunchDarkly-branded apparel, and Otto the chat widget — but ships with **nothing wired to LaunchDarkly.** Learners wire the flags, contexts, metrics, and instrumentation themselves via copy-paste over the course of the tracks.

**Rationale:** The operator likes the ToggleWear look and wanted to keep it. Copying it into this repo (rather than depending on the other repo) keeps this workshop self-contained. Starting from an unwired app is what lets the Release track teach SDK wiring from zero — the first real "aha" is the learner's own flag toggling a visible feature.

---

## Otto is a mock chatbot — no LLM provider (2026-07-07)

**Decision:** Otto returns **canned/scripted responses** from a small hardcoded set in `server.py`. There is no real language model behind him. This removes Bedrock, boto3, AWS credentials, the AWS/GCP credential pathways, and the entire `gcp-federation/` directory that the AgentControl workshop carried.

**Rationale:**
- CodeControl is about shipping and controlling *code*, not AI. A live LLM adds cost, credential complexity, and a federation apparatus for zero pedagogical gain here — the lessons are about flags, releases, observability, and experiments, none of which need a real model.
- A mock chatbot is fully sufficient: Otto's *presence* is toggled by a flag (Release), his *behavior variations* drive a guarded release (Release), and metric/error events are emitted by the app regardless of whether the response text came from a model or a canned string.
- Dropping the LLM collapses the credential model to a single Instruqt secret (`LAUNCHDARKLY_ACCESS_TOKEN`) plus the per-session scoped `LD_API_TOKEN`. Much simpler VM image, no AWS account setup, no per-learner inference bill.

**Options considered:**
- *Keep Otto as a live Bedrock assistant (reuse the AgentControl infra).* Rejected: drags in AWS + GCP federation for a workshop that isn't about AI. The demo doesn't need real model output to teach flags/observability/experiments.

**Consequence:** The AgentControl workshop's cost-protection decisions (per-session turn cap to limit Bedrock spend, model-level cost tiering, traffic generator skipping Bedrock) are **moot** here — a canned chatbot has no inference cost. A light turn cap may still be kept for realism but is not a cost control.

---

## Second storefront feature: a "Recommended for You" carousel (2026-07-07)

**Decision:** Beyond Otto, the app has a second flaggable feature: a **"Recommended for You" recommendations carousel** below the product grid. Otto anchors the Release track (ship a chat widget safely). The recommendations carousel anchors the Observability track (a new version throws errors in production) and the Iterate track (A/B which recommendations strategy drives more engagement).

**Rationale:** The operator chose a second storefront feature rather than reusing Otto for every track. Two features give each track a distinct centerpiece while keeping one shared app. Recommendations is a good fit: it's visually obvious on a presenter's screen, it's believable as a source of production errors (a rec service that fails on a product with a missing field), and it's a natural experiment subject (which layout/strategy converts better).

**Feature specs live in `NARRATIVE.md`.** Flag keys, variation names, and the specific "bad" behavior that triggers rollback/remediation are defined there so all three tracks stay consistent.

---

## Observability scope: release-scoped only (2026-07-07)

**Decision:** The Observability track covers **only** release-relevant observability: error monitoring attributed to a specific flag/release, release health metrics, guarded releases driven by real instrumented metrics, and auto-remediation / self-healing. Explicitly **out of scope:** session replay, distributed tracing UI, and log aggregation/search.

**Rationale:** The operator scoped this deliberately — the track should teach observability *in service of releasing safely*, not the full APM surface LaunchDarkly's observability product offers. Keeping it narrow keeps the track to ~2 hours and keeps the through-line ("observe your releases so you can roll back and self-heal") clean.

---

## Two guarded-release beats, split by depth (2026-07-07)

**Decision:** Guarded releases appear in **both** the Release track and the Observability track, deliberately, at two different depths:
- **Release track (`08-guarded-release`)** — a guarded release using a **simple metric** (e.g. an error-rate or latency signal available without deep instrumentation). The lesson is "a guarded release watches a metric while it ramps and rolls back automatically on a regression." First exposure; keep the metric wiring light.
- **Observability track (`06-guarded-release-real-metrics`)** — a guarded release driven by the **real instrumented error metric** the learner wired earlier in the track. The lesson is "now that you can observe your release properly, the guard is watching a signal you actually built." Deeper, and it earns the repeat by using genuine instrumentation.

**Rationale:** Guarded releases are marketed under CodeControl's Feature Flags pillar (automated rollbacks) *and* depend on observability. Rather than pick one track, we teach the concept in Release (where the "automatic rollback" wow moment belongs) and revisit it in Observability with real signal. The two are not redundant because the metric source differs — this is called out in both `assignment.md` intros so learners understand why they're seeing it twice.

---

## Three safety nets, three timescales (2026-07-07, adapted from the AgentControl workshop)

**Decision:** The workshop teaches three distinct safety mechanisms, framed by the timescale at which they react. This is the same organizing idea the AgentControl workshop used, mapped onto CodeControl:

| Timescale | Mechanism | Track / challenge |
|---|---|---|
| Release time (while ramping) | Guarded release — LD watches a metric during rollout and rolls back on regression | Release `08`; Observability `06` |
| Post-release (detect and fix in production) | Error monitoring + auto-remediation / self-healing | Observability `07` |
| Over time (optimize) | Experimentation — measure which variation is actually better and promote it | Iterate |

**Rationale:** These three are easy to conflate. Naming the timescale makes the distinction concrete: a guarded release reacts *during* a rollout; auto-remediation reacts *after* something is already live and misbehaving; experimentation isn't a safety net at all but an optimization loop. The wrap-ups reinforce the distinction. The kill switch (Release `09`) is the manual, instant version of the same "make it stop" instinct that guarded releases and auto-remediation automate.

---

## App architecture: single Python process serving frontend + API (carried over)

**Decision:** One FastAPI process serves both the static HTML/JS frontend and the app's API endpoints (`/chat` for Otto, `/recommendations` for the carousel) on port 3000. Flag evaluation and metric/event emission happen server-side in Python; the JS client also evaluates client-side flags for show/hide UI. Vanilla JS, no build step.

**Rationale:** Carried over unchanged from the AgentControl workshop's decision. Single process = simpler VM image, fewer ports, fewer ways to break. Server-side flag eval and event tracking is where most of the copy-paste teaching happens; the client SDK handles the visible show/hide. Matches the reference track's single-process-on-3000 shape so learner muscle memory carries over.

---

## Terraform per-challenge modules, hybrid provider + REST (carried over)

**Decision:** Each substantive challenge has its own `terraform/<track>-NN/` module with its own state. Modules use `launchdarkly_*` provider resources for NEW resources a challenge introduces, and `null_resource` + `local-exec curl` for updates to resources owned by earlier challenges' modules and for anything the provider doesn't yet expose.

**Rationale:** Carried over from the AgentControl workshop. Each challenge's solve must produce that challenge's end-state regardless of whether prior challenges were done in code or skipped. Terraform's per-module state doesn't share resources across modules, so cross-module updates go through REST. Verify current provider resource coverage in each track's Phase 0.

---

## server.py BEFORE-state + marker-based paste pattern (carried over)

**Decision:** `server.py` ships from the VM image in a BEFORE state: framework, static-file serving, and the mock Otto/recommendations response helpers pre-wired, but the LaunchDarkly integration points are clearly-marked stub blocks. Each wiring challenge has the learner replace a marked stub with a copy-paste block. Solve scripts apply the same paste programmatically via a Python script that finds the markers and substitutes the block.

**Rationale:** Carried over from the AgentControl workshop, where this two-step staged injection worked well. Marker-based find/replace on stable comment markers is more robust than line-number patching and survives the learner pasting manually vs. running solve. Use generic markers that don't reference a specific challenge number, so later challenges can extend the same file cleanly (e.g. `# ─── LD flag evaluation injects below this marker ───`).

---

## UI instructions are drafts pending operator verification (carried over)

**Decision:** Claude Code drafts click-by-click LaunchDarkly UI instructions from the public docs and mirrors the reference voice; the operator verifies each flow in a live UI, corrects labels/paths, captures screenshots, and removes `<!-- VERIFY: ... -->` markers. Phase done-when conditions require this verification pass.

**Rationale:** Carried over. Claude Code can't drive a browser to verify flows. Confident drafts from docs plus an operator click-through pass is the lowest-total-effort path to accurate instructions.

---

## JS client SDK: `@launchdarkly/js-client-sdk` v4 (2026-07-07)

**Decision:** The browser SDK is the current scoped package **`@launchdarkly/js-client-sdk`** (v4.x, loaded via the jsDelivr CDN script tag; global `LDClient`), not the legacy `launchdarkly-js-client-sdk` v3.

**Rationale:** Phase 0 verification found the legacy package deprecated — its own README says to use the scoped package — and the current LaunchDarkly docs' CDN include and code samples are all v4. Learners who go on to read the docs should see the same package the workshop taught. Note the v4 `'change'` event callback shape differs from v3; verify against the v4 typedoc when wiring `app.js` in Phase 2/3.

**Refinement (2026-07-07, Phase 7):** the published v4 package ships only CJS/ESM — no browser-global CDN build — so a plain `<script src>` of the jsDelivr URL does not work. Operator chose to **vendor a self-built IIFE bundle** (`app/static/vendor/ldclient-v4.9.1.min.js`, built with esbuild, exposing the `LDClient` global; rebuild instructions in `app/static/vendor/README.md`) over falling back to the deprecated v3 UMD or relying on jsDelivr's `+esm` transform. The v4 browser API was verified from the package typings: `LDClient.createClient(clientSideId, context, options)` → attach `'ready'`/`'change'` listeners → `await client.start()`; `boolVariation(key, default)`; `identify(context)` returns a Promise. All pastes and check greps use these shapes.

---

## Challenge 07 teaches the progressive rollout feature, not a manual ramp (2026-07-07)

**Decision:** Release `07-progressive-rollout` teaches LaunchDarkly's first-class **progressive rollout** release feature (Serve menu → **Progressive rollout**: automated timed percentage stages), not a manual percentage rollout the learner ramps by hand.

**Rationale:** Operator call, made with the trade-off on the table. The manual ramp was fully solvable via Terraform/REST, but the automated feature is the actual CodeControl release capability and is available on all plans. The solve gap (no stable public API starts a progressive rollout) is covered by the beta-API decision below.

**Consequence:** `terraform/release-07/` will be REST-driven (beta release APIs) rather than provider resources. Manual percentage rollout mechanics (`rolloutWeights`) may still get a one-line mention in prose as the manual cousin.

---

## Rollout solves use the beta release APIs (2026-07-07)

**Decision:** Where solve scripts must materialize a running progressive (Release `07`) or guarded (Release `08`, Observability `06`) rollout — which stable REST and the Terraform provider cannot start — they use LaunchDarkly's **beta release APIs** (`LD-API-Version: beta`; release policies' `progressiveReleaseConfig` / `guardedReleaseConfig`, or release pipelines' `releaseGuardianConfiguration`).

**Rationale:** Operator call. The alternatives were weaker: a fake pre-rollout end-state breaks the "solve leaves the workstation as a successful learner would" contract, and a UI-required challenge breaks Skip. Beta-stability risk is acceptable for a workshop whose solves are operator-maintained.

**Consequence:** Exact endpoint mechanics (whether release policies attach to a single flag the way the UI's Serve-menu flow does) must be verified live when authoring Phase 4/5 solves — the Phase 0 pass confirmed the schemas exist but did not exercise them. Checks stay on stable API surface (flags list `?filter=guardedRollout:<status>`).

**Refinement (2026-07-07, Phase 4):** this decision applies only where the challenge's *end-state* is a running rollout. Release `07`'s end-state is a **completed** ramp (a learner who finishes the lab watched it reach 100%), so its solve uses a stable JSON patch to set the fallthrough to `true` — instant, and it leaves the flag free for 08's guarded rollout, which can't start while another rollout is active. The beta APIs remain the plan for 08/Observability-06, where the end-state genuinely is a monitored guarded rollout.

---

## Simple metric for Release 08: `otto-response-latency` (2026-07-07)

**Decision:** The guarded release in Release `08` is guarded by **`otto-response-latency`** — a custom **numeric** metric (`kind = custom`, `is_numeric`, unit milliseconds, `success_criteria = LowerThanBaseline`) emitted server-side via `client.track(..., metric_value=elapsed_ms)` on each `/chat` response.

**Rationale:** Operator call. Phase 0 confirmed a plain `track()`-fed custom metric can guard a rollout with no observability SDK, preserving the Release/Observability depth split. Latency is the most *organic* regression available to a mock: Chatty Otto's long-winded replies genuinely take longer to produce (the mock delays proportionally to reply length), so the regression is real behavior, not a rigged event. The rejected alternative (`otto-helpful` conversion clicks) required adding a thumbs-up UI affordance and made the regression depend on synthetic click-weighting alone.

**Consequence:** The app's `/chat` handler times the response and tracks the metric (wired as part of the 08 setup or pre-wired in Phase 2 — decide in Phase 5); `traffic-generator/` drives chat traffic so the metric has volume; the sabotage script can exaggerate the delay. The workshop LD account includes Guardian, so guarded rollouts are fully available (confirmed by operator, 2026-07-07).

---

## Implementation decisions made while building the Release track (2026-07-07)

Smaller decisions made during Phases 2–6, recorded together:

- **uvicorn runs with `--reload`.** Learners paste into `server.py` and the service picks it up on save; no manual restart step in any lab. Track-level setup still does a full stop/start because `.env` changes aren't picked up by the reloader.
- **The browser gets the client-side ID from a `/config` endpoint** on the app rather than a build-time injection (no build step exists). The client-side ID is public by design, so exposing it is safe.
- **The traffic generator drives the real app endpoints** (`/chat`, `/recommendations`) instead of evaluating flags with its own SDK client. Every downstream signal is therefore organic: server-side evaluations now, the latency metric in Release 08, the personalized-strategy errors in Observability. `sabotage.py` is the same idea at a burst rate — it accelerates statistics, it never fakes values.
- **Chatty Otto's regression is typing latency.** Otto sleeps proportionally to reply length (`OTTO_TYPING_SECONDS_PER_CHAR`), so chatty replies are ~4x slower organically (~165ms vs ~620ms per reply at defaults).
- **Quizzes are single-question `type: quiz` challenges** using Instruqt's `answers:`/`solution:` front-matter (0-based, no tabs) — confirmed against the public release workshop and the AgentControl workshop. The wrap-up (10) is also a quiz, mirroring AgentControl's wrap-ups. "1–3 quiz questions" in the phase plan effectively means one strong question per quiz challenge.
- **The kill-switch lab ends by turning Otto back on.** The check validates the kill (targeting off); the closing step re-enables so the finished-track state has Otto live. Later tracks' baseline setups must re-enable `release-otto` after replaying the 09 solve (noted in `terraform/release-09/main.tf`).
- **Challenge 08's supporting infra is applied by setup via `terraform apply -target=...`** on the shared release-08 module — the flag/metric are pre-built for the learner without running the guarded-rollout resource, keeping one source of truth for solve and setup while honoring "setup doesn't do the learner's work."

---

## VM image inputs in repo, image build done by humans (carried over)

**Decision:** Claude Code produces the *inputs* for VM image building (app source, Packer/Docker config, install scripts, systemd unit files) in `vm-image/`. A human bakes the image and registers it with Instruqt.

**Rationale:** Carried over. Image builds need registry access Claude Code doesn't have. Separating "what goes in the image" from "build and register it" makes the handoff explicit.

---

## Observability Phase 0 outcomes (2026-10-19)

Operator answers to the open questions in `PHASES-observability.md` §9, recorded here so Phase 1 can proceed. (Question 2, browser instrumentation / session replay, is resolved separately below once scope is confirmed.)

- **Entitlement confirmed.** The workshop LaunchDarkly account has observability enabled and the adaptive-triggers entitlement (Guardian was already confirmed for Release). No plan-gated fallbacks are needed for Observability.
- **Auto-remediation is adaptive triggers (challenge 07).** The managed feature — a trigger on the flag's default rule, sourced from an error metric or error query, with a threshold and a "switch variation to Bestsellers" action — is what the lab teaches. The app-side polling loop is retired as the fallback plan unless the feature proves unusable in the live click-through. Rationale: it is the actual CodeControl capability, it is UI-authorable from current docs, and it has stable REST for list/update/enable/disable, which gives the check script an API-driven surface.
- **The "real metric" for 04/06 is the autogenerated OpenTelemetry error-rate metric** (LaunchDarkly's **User HTTP error rate**, event key `otel.http.error`), produced automatically from the observability plugin's traces. Zero extra wiring is the point: the guard watches the signal the instrumentation gave you. Fallback if the autogenerated metric does not materialize in sandbox projects in time: a learner-created custom conversion metric fed by one `track()` paste. `NARRATIVE.md`'s `recs-error-rate` stays as prose shorthand for "the recommendations error-rate metric"; the UI name is the autogenerated one.
- **07 solve-on-skip materializes only the healed end-state.** Adaptive-trigger creation needs an observability alert ID that has no public API, so `solve-workstation` sets the default rule back to `bestsellers` via stable semantic patch, logs loudly that the trigger itself is UI-only, and exits 0 (same accepted trade-off as `terraform/release-08/start-guarded-rollout.sh`). The check still requires a real trigger via `GET …/adaptive-triggers`, so Skip → Check fails honestly rather than passing on a fake. Operator call.
- **Vega gets a one-line mention in 07.** The trigger heals the symptom (flips the flag); Vega can investigate the alert and draft the code fix. One sentence, no lab step, no dependency.

- **Session replay joins the Observability track; the browser plugins are wired (2026-10-19, amends "Observability scope").** Operator call, made with the written scope exclusion on the table: session replay is the human-visible half of error attribution — the learner sees the shopper's screen at the moment the carousel vanished, scoped to the `personalized` variation — and it requires the browser observability + session-replay plugins, so those are wired in challenge 02 alongside the Python plugin. The scope boundary moves, it does not disappear: session replay is taught only as **flag-scoped evidence of a broken release** (the flag's Monitoring → Sessions chart and one replay), folded into `03-errors-in-context`. Trace waterfalls, log search, rage-click analytics, and general UX analytics stay out. `CLAUDE.md`, `NARRATIVE.md`, `PHASES-observability.md`, and the operator checklist were updated to match. Consequence: the browser plugins are vendored as UMD builds next to the client SDK (no CDN dependency at lab time), the 02 paste in `app.js` passes `plugins: [...]` into `LDClient.createClient`, and the privacy setting is relaxed from the `strict` default so the replay is legible (the storefront has no PII).

---

## Implementation decisions made while building the Observability track (2026-10-19)

- **The VM image carries the `instruqt-*/` directories.** The Observability (and later Iterate) track-level setup materializes its baseline by calling the Release track's `solve-workstation` scripts, but Instruqt only ships a track's own challenge scripts to the VM. Baking the track directories into the image at `/opt/ld/codecontrol/instruqt-release/` etc. keeps a single source of truth for each solve instead of duplicating replay logic in later tracks' setup scripts. `.remote` files and other CLI publish artifacts are never baked.
- **Baseline replay skips Release 09 and applies Release 08's infra only.** 09's sole effect is turning Otto off (the track then turns him back on), so replaying it is a no-op pair. 08's full solve starts a live guarded rollout of Chatty Otto via the beta APIs; a cold Observability learner should not inherit a running rollout on an unrelated flag, so the baseline applies 08's flag + metric + pastes with the same `-target` list 08's own setup uses.
- **The recommendations carousel baseline is its own Terraform module, `terraform/observability-baseline/`,** applied by the track-level setup rather than by challenge 02. Both flags (`show-recommendations` on → true; `recommendations-strategy` on → `bestsellers`) and the server-side evaluation paste belong to "the shop already shipped the carousel", not to any lab's learner work. Iterate's baseline reuses the module. The carousel is gated server-side: `/recommendations` returns an empty item list when `show-recommendations` is off, and `app.js` hides the section on an empty list.
- **Both flags are client-side available.** `recommendations-strategy` is evaluated server-side for the strategy, but the browser must also evaluate it for the session-replay plugin to attribute a session to a variation; making it available to client-side SDKs now avoids a flag edit mid-track.
- **Challenge 04 ends with the revert; 06 and 07 each re-release.** The track's arc is ship-naively (02) → see it (03) → measure it and revert (04) → re-release guarded (06) → re-release at 100% behind an adaptive trigger (07). Each re-release starts from Bestsellers, so setups for 06 and 07 reset the default rule with `terraform/lib/set-fallthrough.sh` (tolerating an active rollout). This keeps every lab self-contained for a learner who skipped the previous one.
- **07 arms the trigger before releasing.** The learner adds the adaptive trigger while the rule still serves Bestsellers, then flips the rule to Personalized. Safety net first, release second is the habit worth teaching, and it also means the trigger's firing is unambiguous (the rule was changed by the trigger, not by the learner).
- **Traffic profiles live in `/opt/ld/traffic.env`.** The traffic generator gained two knobs (`TRAFFIC_RECS_EVERY`, `TRAFFIC_TOTE_BIAS`); `terraform/lib/traffic.sh <release|recs>` writes the profile and stop/starts the systemd unit, which reads it via `EnvironmentFile`. The Observability track's 02 setup switches to `recs`; the Release track never touches it. `sabotage.py --target recs` is the matching presenter burst for the carousel.
- **`/healthz` reports the observability plugin state** (`"observability": true|false`) by inspecting `sys.modules` for `ldobserve.observe`, so the 02 check can tell "paste landed but plugin failed to init" from "paste missing" without the unwired app ever importing the plugin.
- **03's solve delegates to 02's solve.** 03 is exploratory (no learner artifact), so "the state a successful learner ends in" is exactly 02's end-state, re-applied idempotently.
- **Release 08 prose corrected: Release Guardian evaluates roughly every 10 seconds**, not every minute (current regression-detection doc, 2026-10-19). One-word fix made in `instruqt-release/08-guarded-release/assignment.md` during the Observability polish pass.

---

## Implementation decisions made while building the Iterate track (2026-10-19)

- **Bayesian at 90% for the lab experiment.** LaunchDarkly recommends Bayesian under ~1,000 contexts, and "probability to be best" is the most teachable readout for a new audience. The frequentist path is mentioned nowhere in prose to avoid a statistics lecture; slides can cover it.
- **Engagement is a custom conversion binary metric, resolved by event key.** "Percent of shoppers who clicked at least once" is the honest measure (one vote per shopper). Because UI-created metric keys derive from names, every check and solve looks the metric up by its event key (`recs-engagement`) instead of assuming a key.
- **The engagement click is real app behavior plus weighted synthetic clicks.** A new `POST /recommendations/click` endpoint (with a paste-block stub, the learner's one paste in the track) receives clicks from the browser and from the traffic generator, which clicks with per-strategy probabilities (45% Personalized vs 25% Bestsellers). The weighting is the only synthetic element and is documented in the generator; the server emits the event identically for both.
- **Iterate's baseline fixes the personalized bug and skips the observability plugins.** The experiment compares strategies on engagement; errors would confound it. `terraform/lib/fix-personalized-bug.sh` makes a one-line change outside any paste block; the Observability plugins aren't applied (lean-minimal baseline, no startup cost for nothing).
- **The multi-armed bandit is a hands-on lab.** Bandits are a first-class experiment type with a documented Design flow and stable REST (`type: "mab"`), so 07 is "configure it", not "watch it".
- **Iterate solves chain backwards (07 → 06 → 04 → 03 → 02).** Each solve runs the previous challenge's solve first, because experiments depend on the metric, a running iteration depends on the experiment, shipping depends on a running iteration, and a bandit can't start while the A/B experiment still runs on the same rule. Every step is idempotent (409/“already running” tolerated).
- **The `exp` traffic profile** (2 shoppers/s, every shopper browses, uniform products, weighted clicks) is the third profile in `terraform/lib/traffic.sh`; it replaces `recs` for this track since the bug is fixed and error volume is irrelevant.

---

## VM image build inputs (2026-10-19)

- **Paste-into-console script, not Packer.** `vm-image/build-image.sh` follows the AgentControl workshop's proven flow: fresh Ubuntu base in the Instruqt console, paste the script as root, run the verifier, save the image. It accepts `SOURCE_DIR` as an alternative to cloning because this repo has no remote yet.
- **Unit files are real files under `vm-image/systemd/`,** installed by the script, rather than heredocs inside it — so the contract in `vm-image/README.md`, the units, and the installer can't drift from each other and the units can be reviewed on their own.
- **Deviations from AgentControl's script, all per this repo's README contract:** one venv at `/opt/ld/venv` (not `app/.venv`) shared by the app and the generators; *every* Terraform module is pre-inited through a shared `TF_PLUGIN_CACHE_DIR` (the later tracks run seven applies at setup); the traffic unit is installed but disabled and reads `/opt/ld/traffic.env`; no Node.js (the browser bundles are vendored, nothing is built on the VM); `--reload` on uvicorn; code-server installed via the official script (`.deb`, `/usr/bin/code-server`) with the app directory as workspace.
- **Terraform is pinned to the latest stable at authoring time** (looked up from HashiCorp's releases API on 2026-10-19, not from memory) and installed as a direct binary; `>= 1.5` is the only hard requirement.

---

## Adopted the `launchdarkly-instruqt-track` skill contract (2026-10-19)

**Decision:** The repo now follows the infrastructure contract fixed by the `launchdarkly-instruqt-track` skill, which supersedes four earlier choices:

| Before | Now | Why it matters |
|---|---|---|
| `terraform/student-bootstrap/` created the project + `test` environment | The shared `launchdarkly-labs/ld-workshop-participant` Terraform, baked at `/opt/ld/ld-workshop-participant`, applied/destroyed by track setup/cleanup | The participant module also creates the **team member and the magic-login record** the `launchdarkly` virtual browser needs. Without it the browser tab could never have signed the learner in — a real defect, not a style difference. The public basics track bootstraps the same way (its setup reads the same `students` output). `student-bootstrap` is deleted. |
| Virtual-browser URL copied from the reference tracks (`i3vcudz5…`) | The skill's URL (`l5vv6unuu4…`), verified Oct 2026 | The two reference tracks still carry the older Lambda. **Operator to confirm** which Lambda is live for new tracks; the skill's is used here as the authoritative, more recent one. |
| Single secret (`LAUNCHDARKLY_ACCESS_TOKEN`) | Four secrets: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `LAUNCHDARKLY_ACCESS_TOKEN` | The participant Terraform stores login-handler state and DynamoDB records in AWS. The "no AWS" decision was about Bedrock/LLM credentials and still holds for the app: nothing in `app/` or `traffic-generator/` reads an AWS variable. |
| Scripts relied on `LD_PROJECT_KEY` inherited from the shell | Track setup writes `/opt/ld/ld.env`; every challenge script `source`s it; `agent variable set` publishes the key for assignments | Lifecycle scripts run via the Instruqt agent and don't inherit `~/.profile`. |

Also adopted from the skill's conventions: no `id:` fields anywhere (first `instruqt track push` assigns them), `idle_timeout: 1200` and `sidebar_enabled: true` in `track.yml`, a fourth **Shell** terminal tab on every challenge, a `cleanup-workstation` (`exit 0`) per substantive challenge, and the image split into `image.base.sh` (skill contract: tools via the HashiCorp apt repo, participant clone + `terraform init`, code-server rooted at `/opt/ld`) plus `app-install.sh` (this workshop's app), assembled into `image.sh` by `build-image.sh`. The one deliberate deviation from the skill's image template: the app is placed from git (or a copied checkout) rather than embedded as heredocs, because it vendors ~1 MB of browser bundles that can't sensibly be pasted into a console.

**Kept from this repo's own design, on top of the contract:** the scoped `LD_API_TOKEN` minted per lab (the skill has no equivalent), the three-tab ToggleWear/Code Editor layout (now four with Shell), the per-challenge Terraform solve modules, the baseline-replay pattern for later tracks, and the `/opt/ld/codecontrol` + `/opt/ld/venv` layout (code-server's workspace root moved from the app directory to `/opt/ld` per the contract, so learners open `codecontrol/app/server.py` in the explorer).

---

## First live play: the scoped `LD_API_TOKEN` is retired (2026-10-19)

**What happened:** the first play of the Release track on Instruqt got through the participant Terraform (project, team member, magic-login record all created; the login URL confirmed the skill's Lambda) and then died on `curl: (22) … 403` in track setup. The only REST call after the apply that a Terraform-capable token could plausibly be forbidden from making is `POST /api/v2/tokens`: the team secret is the workshops account's **service token** ("API Token for the LaunchDarkly Terraform provider"), and service tokens cannot create other access tokens.

**Decision:** remove the minting step from all three track setups and the matching deletion from cleanups, drop `LD_API_TOKEN` from `app/.env.example`, and update `CLAUDE.md`. Nothing consumed the token any more: it existed for the Observability track's app-side auto-remediation loop, which Phase 0 replaced with adaptive triggers (a managed feature; no runtime REST call). The environment-keys GET now captures its HTTP status and prints the body on failure, so the next failure of this kind names itself in the Instruqt log instead of appearing as a bare curl exit code.

**Also set:** `skipping_enabled: true` in every `track.yml` so the operator can exercise `solve-workstation` scripts with the Skip button during verification (the console showed "Allow skipping" off).

---

## First full play of the Release track (2026-10-19)

Played end to end on Instruqt with the baked image (every challenge: Check first to exercise the failure message, then Skip to exercise the solve). Results:

- **Track setup: ~64 s**, almost all of it the participant Terraform reading its remote state (~40 s). Magic login into the sandbox project works; the storefront and code-server come up wired.
- **Every challenge solve ran clean** (02 flag, 03 pastes + flag on, 04 context + rule, 05 segment + rule incl. the tolerated "nothing to import", 07 completed ramp, 09 kill switch) and every failure message fired with the intended text. Quizzes render as four plain radio options.
- **Finding: `fail-message` is plain text.** Markdown bold and backticks showed literally. All 70 fail-message lines across the three tracks were rewritten without Markdown; recorded as a convention in `CLAUDE.md`.
- **Finding: the beta release-pipeline API returned HTTP 404** (empty body) from the 08 solve, so `start-guarded-rollout.sh` took its designed fallback (Concise Otto, loud warning, exit 0). Consequence: Skip on Release 08 (and Observability 06, same helper) leaves a state the check rejects. **Decision pending with the operator**: keep the honest Skip→Check failure, relax the two checks to also accept a solve-marker, or find a working API (release policies beta, or confirm the account's release-pipelines entitlement).
- **Cosmetics fixed:** the welcome said "three tabs" (now four, with the Shell tab described); code-server opened its AI chat panel by default (disabled via settings in `image.base.sh`; needs a re-bake to take effect).
- **Image as baked** also carries a `ld-workshop-codecontrol/` clone beside `codecontrol/` under `/opt/ld`; harmless, but the operator may want to drop it on the next bake for a cleaner Code Editor explorer.

---

## First full play of the Observability track (2026-10-19)

Played end to end on Instruqt right after the Release play (Check-first-then-Skip on every lab; 03's Check run against the state 02's solve left behind).

- **Track setup: 46 s total** — participant bootstrap 13 s, Release solve replay 20 s (02→08 infra), carousel baseline 4 s, service restart 5 s. Comfortably inside the ~60 s budget; the pre-baking fallback is not needed.
- **The baseline landed as designed:** the storefront came up wired, the carousel was on Bestsellers, and after 02's solve the live `/healthz` reported `"observability": true` with no OpenTelemetry export errors in the service log. 03's Check passed on the first try against 02's solve state. Traffic ran on the `recs` profile and the Personalized bug fired 38 times in under two minutes.
- **Autogenerated metrics did not exist yet when 04's Check ran.** Personalized had been live for only ~1 min 45 s (solve to solve). The check's failure message handles this honestly ("wait a minute or two"), and a real learner spends 10–20 minutes on 02–03 first, but the operator should **measure how long LaunchDarkly takes to autogenerate `otel.http.error`** in a sandbox before deciding whether 04 needs a longer runway or the custom-metric fallback.
- **The guarded-rollout solve fell back again** (release-pipelines beta POST → HTTP 404), same as Release 08; the shared helper's warning path worked. Same pending decision.
- **07's solve behaved as decided** (healed end-state, loud warning) and its Check failure message read correctly.
- All Observability fail-messages rendered as plain text after the de-markdown pass.

---

## First full plays of the Iterate track (2026-10-20)

Two plays (the second after patching `terraform/lib/exp.sh` on the VM, since `lib/` is baked into the image rather than shipped with the track).

- **Setup: 41 s** on the first play; **195 s** on the second, with a ~2.5-minute stall between the 05 and 07 Release solve replays that the log doesn't explain (no errors; Terraform and the LD API simply took longer). Treat the budget as "usually ~45 s, occasionally minutes": the `[setup +Ns]` lines make the slow step visible when it happens.
- **Three API facts the experiments helper now encodes:** `POST /experiments` requires `maintainerId` (a service token has no member identity — the helper now uses the sandbox's student member, falling back to the first account member); a duplicate experiment key is HTTP **400 `duplicate_experiment_key`**, not 409, which matters because the Iterate solves chain 07 → 06 → 04 → 03 and must be re-runnable; and a multi-armed bandit requires **`canReshuffleTraffic: true`** (400 "Reshuffle traffic must be true for a MAB").
- **With the first two fixes, the chain works:** 03's solve created the experiment, 04's Check correctly reported "exists but hasn't been started", 04's solve started the iteration, 06's solve stopped it with Personalized as the winner and pointed the default rule at Personalized. Every Iterate fail-message read correctly.
- **The bandit solve failed on two API rules in successive plays:** `canReshuffleTraffic` must be true for a MAB, and the update frequency must be **1–24 hours** (the solve had asked for one minute). Both are fixed in the helper, and a fourth play with the patched helper on the VM confirmed the full chain: experiment created, started, shipped with Personalized as winner, then the bandit created and started. The hour-long minimum also reshaped lab 07: the learner configures and starts the bandit and reads its initial results, and the prose explains that the first reallocation happens at the next hourly update rather than promising to watch the split move inside the lab.
- **The 06 check** said "still running" when no experiment existed at all; it now names the missing experiment first.
- `terraform/lib/` changes need an **image re-bake** to reach learners; the operator checklist notes this.

---

## Release pipelines removed; guarded-rollout solves materialize the post-rollback state (2026-10-20)

**Decision (operator):** remove every use of LaunchDarkly's beta **release pipelines** API from the repo and do not replace it. Release pipelines are deprecated and a successor product is about to ship; the beta endpoint also returned HTTP 404 in every live sandbox. This supersedes "Rollout solves use the beta release APIs".

**What this means for the two guarded-release labs (Release 08, Observability 06):** a guarded rollout can only be started from the LaunchDarkly UI, so their `solve-workstation` scripts now materialize the state a successful learner ends in *after* the guard rolls the bad variation back — `otto-style` on Concise, `recommendations-strategy` on Bestsellers — and nothing else. Their checks still require a real guarded rollout (`?filter=guardedRollout:any`), so a learner who clicks Skip and then Check fails honestly. This is the same pattern already accepted for Observability 07's adaptive trigger, and it has no practical cost: Instruqt's Skip advances the learner regardless of the check, and later challenges' setups reset the flag states they need.

Deleted: `terraform/lib/start-guarded-rollout.sh`, `terraform/release-08/start-guarded-rollout.sh`, the `null_resource.start_guarded_rollout` in `release-08` (and its `null` provider), and `observability-06`'s pipeline call (now a `set-fallthrough` to Bestsellers).

---

## Story-led track titles (2026-10-20)

**Decision (operator):** the published titles are story-led rather than pillar-named. Slugs are unchanged (immutable after first push) and the pillar names Release / Observability / Iterate remain the internal names in this repo and in prose that refers to "the Release track".

| Track | Slug | Title |
|---|---|---|
| 1 | `ld-codecontrol-release` | Shipping Otto: From First Flag to Guarded Release |
| 2 | `ld-codecontrol-observability` | The Carousel That Broke Production |
| 3 | `ld-codecontrol-iterate` | Bestsellers vs. Personalized: Let the Shop Decide |

**Rationale:** the titles name what happens to ToggleWear, which is more inviting in a catalog than the product pillar, and each is a promise the labs keep. Trade-off accepted: Track 2's title alone doesn't say "LaunchDarkly" or "observability"; the teaser and the series tag carry that.
