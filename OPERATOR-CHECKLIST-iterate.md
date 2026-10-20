# OPERATOR-CHECKLIST-iterate.md

Per-challenge verification items for **Track 3 / Iterate** (`instruqt-iterate/`). Run **after** Claude Code authors the track. The main risk here is experiment convergence timing and whether the multi-armed bandit is authorable as a hands-on step.

---

## Cross-cutting items

- [ ] **Live-fire end-to-end smoke test** against a fresh sandbox: bootstrap → materialize the baseline → click through every challenge → solve every challenge → confirm every check passes. Time each challenge.
- [x] **Track-level `setup-workstation` timing** — measured 41 s and 195 s in two live plays (2026-10-20); the slow run stalled between the 05 and 07 replays with no error. Watch the `[setup +Ns]` lines; pre-baking only if slow runs become common.
- [ ] **Re-bake the image** before the next play: `terraform/lib/exp.sh` gained four API fixes (maintainerId, 400-duplicate handling, canReshuffleTraffic and the 1-hour minimum update frequency for bandits) that live in the image, not the track. With the patched helper applied by hand on a VM, the whole Iterate solve chain (02 → 07) ran clean on 2026-10-20.
- [ ] **Confirm the baseline** a cold learner lands in: four flags, Otto on, the carousel on **Bestsellers**, the personalized bug **fixed** (click the Rollout Tote on Personalized: carousel stays), traffic on the `exp` profile, and NO `recs-engagement` metric yet (the learner creates it in 02).
- [ ] **Confirm Experimentation is enabled** on the workshop account (assumed from the AgentControl workshop; not verified in Phase 0).
- [ ] **VM image re-bake** picks up the `instruqt-iterate/` directory and the app changes (`/recommendations/click`, rec-click reporting in `app.js`).
- [ ] **Experiment convergence** — with the `exp` profile (~120 exposures/min, 45% vs 25% engagement), confirm Personalized's probability to beat control crosses 90% within ~3 minutes, and that `sabotage.py --target recs` accelerates it. Tune `TRAFFIC_ENGAGE_*` / `TRAFFIC_PERIOD_SECONDS` in `terraform/lib/traffic.sh` if too slow or suspiciously fast.
- [ ] **VM image re-bake** picks up the experiment-traffic generator variant.

## Per-challenge verification

For each challenge: confirm UI labels against the live UI; capture screenshots into `instruqt-iterate/assets/`; add image references; complete the lab; click Check (expect pass); solve from fresh and re-check; fail one assertion to confirm the `fail-message` helps.

### 01 Welcome-recap
- [ ] Recap accurately reflects the materialized baseline. Reads cleanly for a learner who did NOT just finish the prior tracks.

### 02 Your first metric
- [ ] Verify the **Create metric** dialog labels: event source **LaunchDarkly hosted**, event kind **Custom**, the **Event key** picker listing recently received events, **Occurrence (Percent)**, analysis unit, higher/lower is better. **Capture the metric key generated from the name "Recs engagement"** and whether it's editable (checks resolve by event key, so any key works, but the prose claims `recs-engagement`).
- [ ] Confirm the `track()` paste lands in the `/recommendations/click` handler and events appear on the metric (Events / activity view) after clicking carousel items; confirm the Metrics list is under **Data** in the sidebar as the prose says.
- [ ] Screenshots: metric creation, events arriving.

### 03 Design an experiment
- [ ] Verify the experiment-creation flow against the assignment's 15 steps: **Create → Experiment**, name/hypothesis dialog, Design tab sections (Assignment method, Flag, Targeting rule = default rule, Randomize by, variation served outside, % included, **Disable reshuffling** default state, Variations split → Split equally, Control picker, Metric source/metric, **Statistical approach** Bayesian 90%), **Save**.
- [ ] Confirm the check's `expand=draftIteration,currentIteration` populates treatments for an unstarted experiment on the live API (VERIFY in `03/check-workstation`).
- [ ] Confirm the solve's `flagConfigVersion` (environment `version`) is accepted by `POST /experiments` (VERIFY in `terraform/lib/exp.sh`).
- [ ] Confirm the treatments and primary metric match the check.
- [ ] Screenshots: experiment creation, treatments config.

### 04 Run and read
- [ ] Verify **Start → Start experiment** (flag already on, so no toggle step) and that the flag's Targeting tab shows the experiment allocation on the default rule.
- [ ] Confirm the **Results** tab's columns match the five the prose walks through (sample size, conversion rate, probability to be best, probability to beat control + relative difference, expected loss) and note how long until values appear.
- [ ] Screenshots: start-iteration, results panel at significance.

### 05 Quiz — experiments
- [ ] Confirm exactly one correct answer per question; renders without artifacts.

### 06 Promote the winner
- [ ] Verify the **Ship it** button appears once Personalized clears 90%, and the fallback **Stop → Ship menu → Personalized → reason → Stop experiment**; confirm the default rule serves Personalized afterward and the Results tab is frozen with the winner.
- [ ] Confirm the solve's `stopIteration` + `set-fallthrough` leaves the same state (the API may or may not update the flag on stop; the helper sets it explicitly).
- [ ] Screenshots: promote-winner flow, post-promotion targeting.

### 07 Multi-armed bandit
- [ ] Hands-on MAB (Phase 0 finding): verify **Multi-armed bandits → Create → Multi-armed bandit**, the Name/Goal dialog, and the Design tab (Randomize by, Metric with environment hover, Flag, audience rule, variation served outside, %, **Update frequency**, split), then **Start → Start multi-armed bandit**.
- [x] **Update frequency**: the API enforces 1–24 hours (live play 2026-10-20), so the first reallocation is at least an hour out; the assignment now says so and the solve uses 1 hour. Confirm the UI offers the same minimum and whether a presenter wants to pre-start a bandit in a second project to show a reallocated chart.
- [ ] Confirm the exposures chart bends toward Personalized after the first update and how the allocation renders on the flag's Targeting tab.
- [ ] Confirm starting the bandit fails (or is blocked) while the A/B iteration is still running, so the 07 prose's assumption (06 stopped it) holds; the solve chain stops it explicitly.
- [ ] Screenshots: MAB configuration or the reallocation over time.

### 08 Wrap-up
- [ ] Recap ties together all three tracks (release → observe → iterate) and the journey table reads correctly; the AgentControl workshop pointer is wanted.
- [ ] Final quiz questions have exactly one correct answer; the workshop close lands.

---

## How to mark progress

Tick items as `[x]` when verified. Capture per-item gotchas inline, especially anything about MAB authorability or convergence timing that should feed back into `DECISIONS.md` or `PHASES-iterate.md`. When all per-challenge items are ticked and the smoke test passes, Iterate is ship-ready — and with it, the workshop.
