# PHASES-iterate.md

Build sequence for **Track 3 / Iterate** (`instruqt-iterate/`), the third sibling track. Mirrors the phase structure of `PHASES-release.md`.

Track 3 starts from the post-Release baseline (Otto shipped, SDKs wired, the recommendations carousel present). The track-level `setup-workstation` runs Release's solves (and optionally Observability's, if the experiment reuses instrumentation) to materialize that baseline, then teaches experimentation on the recommendations feature.

---

## Track 3 / Iterate — scope

By the end of Iterate, the learner has:

- Created a metric and wired its events into the app (copy-paste).
- Designed an A/B experiment comparing two recommendation strategies with a hypothesis and a primary metric.
- Run the experiment against live lab traffic and read the results (significance, winner).
- Promoted the winning variation to 100%.
- Converted the decision to a multi-armed bandit that routes traffic to the best performer automatically.

Challenge list (8 challenges, ~2h):

| # | Slug | Type |
|---|---|---|
| 01 | welcome-recap | challenge |
| 02 | your-first-metric | challenge (create a metric + wire `track` events) |
| 03 | design-an-experiment | challenge (A/B setup: control vs treatment, hypothesis, primary metric) |
| 04 | run-and-read | challenge (start, drive traffic, read results) |
| 05 | quiz-experiments | quiz |
| 06 | promote-the-winner | challenge |
| 07 | multi-armed-bandit | challenge |
| 08 | wrap-up | challenge |

Slugs are draft and lock in Phase 1.

---

## Source-of-truth notes

- `CLAUDE.md` — operational spec; conventions apply across all three tracks.
- `DECISIONS.md` — see "Second storefront feature," "Three safety nets, three timescales," and the Terraform/traffic-generator carry-overs.
- `NARRATIVE.md` — the recommendations carousel spec, `recs-engagement` metric, the `bestsellers` / `personalized` strategies.
- `PHASES-release.md` / `PHASES-observability.md` — Release is the baseline; the bandit and metric may reuse Observability's instrumentation.

---

## Phase 0: Verification spike

**Goal:** Pin down the experimentation surface before authoring.

**What needs verification:**

1. **Metrics (challenge 02)**
   - How a metric is created (UI + Terraform `launchdarkly_metric` vs. REST) and how the app emits events for it (`track` call shape from the server SDK; whether the metric is a conversion/count/custom-numeric kind).
   - The `recs-engagement` event: what the app tracks (a click on a recommended item, or a synthetic engagement event from the traffic generator).

2. **Experiments (challenge 03–04)**
   - Confirm the current experiment-creation flow on a **feature flag**: name/key, hypothesis, flag picker, rule picker (fallthrough), treatments (control + treatment with allocation summing to 100%, one marked baseline), randomization unit, primary metric.
   - Terraform coverage for experiments vs. REST/MCP (`create-experiment`, `start-experiment-iteration` existed for AI Configs; confirm the flag equivalent and payload).
   - Where results appear, what "reached significance" looks like in the UI, and the promote-winner flow (challenge 06).
   - Convergence time with synthetic traffic — target ~60–90s.

3. **Multi-armed bandit (challenge 07)**
   - Confirm MAB is a first-class experiment type/toggle and how it's configured (is it a setting on an experiment, a separate construct?). Confirm the REST/Terraform surface. If MAB isn't authorable confidently from docs, flag it — it may become a "watch it happen" exploratory beat rather than a "configure it yourself" beat.

4. **Baseline reuse**
   - Decide whether Iterate's setup applies only Release's solves, or also Observability's instrumentation (if the engagement metric reuses the observability wiring). Lean minimal — apply only what the experiment needs.

**Deliverable:** "Phase 0 verification notes" appended to this file.

**Done-when:** operator reviews findings; experiment + MAB approach locked; baseline-reuse decision recorded.

---

## Phase 1: Baseline + experiment scaffolding

**Goal:** Materialize the baseline and prepare the experiment's flag/metric groundwork.

**Deliverables:**
- `instruqt-iterate/track.yml` / `config.yml` (single secret; shared image).
- `track_scripts/setup-workstation` that bootstraps, mints `LD_API_TOKEN`, and applies the decided baseline solves. Time it; escalate to pre-baking if past ~60s.
- The `recommendations-strategy` flag and `recs-engagement` metric present in the baseline (the `personalized` bug fixed for this track — the experiment compares strategies, not error rates).
- Empty challenge folders `01`–`08` with valid front-matter.

**Done-when:** a learner landing cold in Iterate arrives with the carousel present and the strategies ready to experiment on; setup timing within budget.

---

## Phase 2: Challenges 02–04 (metric, design, run)

**Goal:** Author the three core experimentation labs.

**Deliverables (per challenge):** `assignment.md`, `setup-workstation`, `check-workstation`, `solve-workstation`, `terraform/iterate-0N/`.

- **02 your-first-metric** — create the `recs-engagement` metric and copy-paste the `track` event emission into `server.py` (marker-based). Check: metric exists and events are being received.
- **03 design-an-experiment** — create an A/B experiment on `recommendations-strategy`: `bestsellers` (control/baseline) vs `personalized` (treatment), a hypothesis, allocation, randomization unit, and `recs-engagement` as the primary metric. Check: experiment exists with the expected treatments and metric.
- **04 run-and-read** — start the iteration; setup drives the experiment-traffic variant of the generator (weighted so one strategy wins clearly and it converges in ~60–90s); the learner reads significance and identifies the winner. Exploratory read, similar to the reference's results-panel lab. Check: iteration started (and/or results present).

**Done-when:** operator click-through per challenge; convergence timing tuned; markers resolved; solves correct; checks helpful.

---

## Phase 3: Challenges 06–07 (promote, bandit)

**Goal:** Author the promote-winner and multi-armed-bandit labs. (05 is the quiz, Phase 4.)

**Deliverables:**
- **06 promote-the-winner** — the learner promotes the winning strategy to 100% via the results/promote flow. Check: the flag serves the winner at 100%.
- **07 multi-armed-bandit** — per Phase 0's finding, either the learner configures a MAB that dynamically routes traffic to the best performer, or (if MAB isn't authorable as a hands-on step) an exploratory "watch the bandit shift allocation" beat. Setup drives traffic with a shifting winner so the reallocation is visible. Check: MAB configured (or the exploratory check pattern).

**Done-when:** operator verifies the promote flow and the bandit behavior; MAB UI steps verified or the beat downgraded to exploratory per Phase 0.

---

## Phase 4: Welcome-recap, quiz, wrap-up (01, 05, 08)

**Goal:** Author the non-lab challenges.

**Deliverables:**
- **01 welcome-recap** — re-establish context: Otto's shipped and guarded, the carousel is live and observable, and now the question is whether the current version is actually the best one. State what setup materialized.
- **05 quiz-experiments** — `type: quiz`, 1–3 questions on experiment design and reading results (challenges 02–04).
- **08 wrap-up** — recap the full CodeControl journey across all three tracks (release → observe → iterate), reinforce the "three safety nets, three timescales" framing (guarded release at release time, auto-remediation post-release, experimentation as the optimization loop), and close the workshop.

**Done-when:** recap matches materialized state; quiz answerable from content; wrap-up ties the whole workshop together.

---

## Phase 5: Polish

Same as `PHASES-release.md` Phase 7, scoped to Iterate: narrative consistency, `fail-message` quality, setup/solve idempotency, experiment convergence timing confirmed in both delivery modes, `instruqt-iterate/assets/` images, `track.yml` finalization, `DECISIONS.md` updates, and baseline-startup timing.

**Done-when:** operator runs both delivery modes end-to-end; all polish items checked; track ready to publish.

---

## Open questions surfaced during scoping

1. **MAB authorability.** Is multi-armed bandit a hands-on "configure it" step or a "watch it happen" exploratory beat? Phase 0 decides; if the docs don't support confident authoring, downgrade to exploratory.
2. **Baseline reuse.** Apply only Release's solves, or also Observability's instrumentation? Lean minimal. Phase 0/1 decides.
3. **Engagement event source.** Real click tracking from the carousel vs. synthetic events from the traffic generator. Lean synthetic for reliable convergence, matching the reference's approach; the real click path can be a bonus if simple.
4. **Convergence time.** Tune the traffic generator so experiments reach a readable result in ~60–90s in presenter mode.
5. **Experiment on Otto too?** The scope centers the experiment on recommendations. An Otto-greeting experiment is a possible alternative or bonus; keep the primary path on recommendations for continuity with Observability.

---

## Phase 0 verification notes

Recorded 2026-10-19 against the live OpenAPI spec and the current Experimentation / Multi-armed bandit / Metrics docs (`launchdarkly.com/docs/home/experimentation/*`, `home/multi-armed-bandits/*`, `home/metrics/custom`). Phases 1–5 were authored in the same pass at the operator's request; see the status block at the end.

### 1. Metrics (challenge 02)

- **Shape:** `recs-engagement` is a **custom conversion binary** metric — in the UI, event kind **Custom**, event key `recs-engagement`, metric definition **Occurrence (Percent)** ("percentage of users who sent the event at least once"), analysis unit `user`, **higher is better**. API/Terraform: `kind=custom`, `isNumeric=false`, `successCriteria=HigherThanBaseline`, `randomizationUnits=["user"]` (the API has since renamed this `analysisUnits`; the 2.x provider still uses `randomization_units`).
- **Metric key vs event key.** The UI derives the metric *key* from the *name* ("Event keys and metric keys are different"). So checks and solves resolve the metric **by event key** via `GET /metrics/{proj}?filter=eventKeys anyOf ["recs-engagement"]` rather than assuming a key. The solve's Terraform metric uses key `recs-engagement` explicitly; a UI-created duplicate on the same event key is harmless.
- **Emission:** server-side `ld_client.track("recs-engagement", context)` on a new `POST /recommendations/click` endpoint (added to the base app with a paste-block stub). The browser reports carousel clicks to it as plain app behavior. The context must be the same `user` key/kind that evaluated `recommendations-strategy` — the attribution rule — which `build_context(req.user_key, …)` guarantees.
- **Event source decision:** both. Real clicks from the learner's browser flow through the endpoint, and the traffic generator posts clicks for synthetic shoppers with per-strategy probabilities (45% Personalized vs 25% Bestsellers, `TRAFFIC_ENGAGE_*`). The weighting is the one synthetic ingredient and is documented in `generate_traffic.py`; the event itself is emitted by the server exactly as a real shopper's would be.

### 2. Experiments (challenges 03–04, 06)

- **UI flow (docs):** Experiments list → **Create → Experiment** → Name, Hypothesis → **Create experiment** → Design tab: Assignment method (LaunchDarkly flag), **Flag**, **Targeting rule** (the default rule is offered when the flag has no other rules), **Randomize by**; Audience allocation (variation served outside, % included, **Disable reshuffling** checkbox); **Variations split** (Edit → Split equally; mark **Control**); Metrics (source LaunchDarkly, pick metric, primary); **Statistical approach** Bayesian (90/95/99 threshold) or frequentist (default); **Save**. Start: experiment page → **Start** → "Start experiment" dialog (offers **Toggle on flag** if off) → **Start experiment**.
- **Results (Bayesian):** sample size, conversion rate, **probability to be best**, **probability to beat control**, relative difference (green above threshold, red below 1−threshold), expected loss, probability-density chart. **Ship it** button appears when a non-control variation clears the threshold; otherwise **Stop → Ship menu → pick variation → Reason for stopping → Stop experiment**. Shipping stops the iteration *and* updates the flag's rule to serve the winner.
- **REST (stable, confirmed in spec):** `POST /projects/{p}/environments/{e}/experiments` with `{key, name, type, methodology, iteration:{hypothesis, randomizationUnit, metrics:[{key}], primarySingleMetricKey, treatments:[{name, baseline, allocationPercent:"50", parameters:[{flagKey, variationId}]}], flags:{<flagKey>:{ruleId:"fallthrough", flagConfigVersion, notInExperimentVariationId}}}}`; `PATCH …/experiments/{key}` (semantic patch) with `startIteration` / `stopIteration {winningTreatmentId, winningReason}` / `saveAndStartNewIteration`; `GET …/experiments?filter=flagKey:…,metricKey:…,status:running|stopped|not_started&expand=currentIteration,draftIteration,treatments`. Treatment ids come from the GET. `flagConfigVersion` = the environment config's `version` (VERIFY on first live solve). The separate "Create iteration" endpoint is deprecated in favor of the patch instructions.
- **Terraform:** no experiment resource at 2.x → all experiment solves are REST via `terraform/lib/exp.sh` (`metric-key | create | start | ship`), wrapped in `null_resource` per module.
- **Statistical approach for the labs: Bayesian at 90%** — recommended by LD for samples under 1,000, and its "probability to be best" reads naturally for a new-to-experimentation audience. Prose never says "significance" in the frequentist sense.
- **Constraints to respect:** one running experiment per rule; no experiments on a rule with an active guarded/progressive rollout (none in this track); adaptive triggers don't run on flags with active experiments (none here — fresh project per session).
- **Convergence:** `exp` traffic profile = 2 shoppers/s, every one browses → ~120 exposures/min, ~60 per arm. With 45% vs 25% engagement, the gap is ~20 points; ~3 minutes yields ~180/arm, comfortably past a 90% probability-to-beat-control. The 04 prose budgets "a couple of minutes"; `sabotage.py --target recs` accelerates (its clicks are weighted identically).

### 3. Multi-armed bandit (challenge 07) — hands-on, not exploratory

- **First-class.** Bandits are an experiment `type` (`experiment | mab | holdout`); Bayesian only (Thompson sampling: each variation receives traffic equal to its probability to be best, re-allocated on a schedule). UI: **Multi-armed bandits** list → **Create → Multi-armed bandit** → Name, **Goal** → Design: Randomize by, **Metric**, **Flag**, experiment audience (rule), variation served outside, % included, **Update frequency**, variations split → **Save** → **Start → Start multi-armed bandit**. Results: cumulative exposures, leading variation, probability to be best. Can run indefinitely; LD suggests stopping at ≥99%.
- **REST:** same `POST …/experiments` with `type:"mab"` and `iteration.reallocationFrequencyMillis`; `methodology` defaults to bayesian. Solve uses 60,000 ms — the UI's option set isn't documented (VERIFY the minimum and align). Check: list filtered by flag, `type == "mab"`, `currentIteration.status == "running"`.
- **Not supported:** percentile-analysis metrics (ours is a conversion metric — fine).

### 4. Baseline reuse — lean minimal

Iterate's setup replays Release (same deviations as Observability: 08 infra only, 09 skipped), applies the shared `terraform/observability-baseline/` carousel module, then **fixes the personalized bug** (`terraform/lib/fix-personalized-bug.sh`: `viewed.get("category")`) and switches traffic to the `exp` profile. The observability plugins are **not** applied — the experiment measures engagement, not errors, and the plugin's startup cost buys nothing here.

### 5. Answers to the scoping questions

1. **MAB authorability** → hands-on "configure it" lab; fully documented UI and stable API.
2. **Baseline reuse** → Release + carousel module + bug fix only; no observability instrumentation.
3. **Engagement event source** → real click path in the app **and** weighted synthetic clicks from the generator, both through the same endpoint.
4. **Convergence** → ~3 minutes at the `exp` profile; sabotage burst available.
5. **Experiment on Otto?** → no; the whole track stays on the carousel for continuity.

### 6. UI-only values to capture (operator checklist)

Metric key generated from the name "Recs engagement"; the Create-menu entries; statistical-approach selector labels and defaults; reshuffling checkbox default; results latency and the Ship it conditions; bandit update-frequency options and time to first reallocation.

**Phases 1–5 status (2026-10-19):** authored in one pass; awaiting the live click-through. Modules `iterate-02` (metric via provider + paste), `iterate-03/04/06/07` (REST via `lib/exp.sh`); solves chain (07 → 06 → 04 → 03 → 02) so any skip point lands correctly. Local verification: YAML/front-matter, `terraform validate` on all modules, `bash -n` on all scripts, app compiles with the engagement endpoint and paste. Open assumption: the workshop account has Experimentation enabled (it ran the AgentControl workshop's experiments). Densest VERIFY areas: metric-dialog labels and generated key (02), experiment Design-tab labels (03), results timing and Ship it (04/06), bandit update-frequency options (07), `flagConfigVersion` field in the solve (03).
