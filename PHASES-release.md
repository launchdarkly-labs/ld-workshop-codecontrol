# PHASES-release.md

Build sequence for **Track 1 / Release** (`instruqt-release/`), the foundation track of the workshop. Mirrors the phase structure of the AgentControl workshop's `PHASES-*.md`: phases group related challenges, Claude Code works one phase at a time, and operator review gates each phase boundary.

Release is the first track authored and the only one that builds shared infrastructure (the app, the student-bootstrap Terraform, the VM image inputs, the traffic generator). Observability and Iterate reuse all of it.

**Audience reminder:** learners are new to LaunchDarkly. This track teaches fundamentals from zero. See the "Audience" entry in `DECISIONS.md`.

---

## Track 1 / Release — scope

By the end of Release, the learner has:

- Created a feature flag in the LaunchDarkly UI and seen it evaluate.
- Wired the LaunchDarkly server and client SDKs into the ToggleWear app (copy-paste) so a flag controls whether Otto appears.
- Built a context and written a targeting rule to show Otto to beta users.
- Created a segment and targeted it.
- Rolled Otto out progressively from a small percentage to everyone.
- Configured a guarded release that automatically rolls back a bad variation of Otto.
- Used the kill switch to turn a feature off instantly.

Challenge list (10 challenges, ~2h):

| # | Slug | Type |
|---|---|---|
| 01 | welcome | challenge |
| 02 | your-first-flag | challenge (create a flag in the UI) |
| 03 | wire-up-the-sdk | challenge (server + client SDK wiring; Otto appears) |
| 04 | contexts-and-targeting | challenge |
| 05 | segments | challenge |
| 06 | quiz-flags-and-targeting | quiz |
| 07 | progressive-rollout | challenge |
| 08 | guarded-release | challenge (guarded release + automatic rollback) |
| 09 | kill-switch | challenge |
| 10 | wrap-up | challenge |

Slugs are draft and lock in Phase 1.

---

## Source-of-truth notes

- `CLAUDE.md` — operational spec; conventions apply across all three tracks.
- `DECISIONS.md` — see "Audience," "Otto is a mock chatbot," "Two guarded-release beats," and "Challenges start at 01."
- `NARRATIVE.md` — ToggleWear voice, product list, Otto's spec, flag keys.

---

## Phase 0: Verification spike

**Goal:** Pin down the API/UI/SDK shape of each surface before authoring touches it. Do not guess from training data; web-search current LaunchDarkly docs.

**What needs verification:**

1. **LaunchDarkly SDKs**
   - Current `launchdarkly-server-sdk` (Python) version and minimum Python. Confirm the init call, context builder API, `variation` call shape, and `track` call shape.
   - Current `launchdarkly-js-client-sdk` (browser) version. Confirm client-side init, context, and `variation` for show/hide.
   - Confirm 3.12 (Ubuntu noble system python) satisfies the server SDK.

2. **Terraform provider**
   - Current `launchdarkly/launchdarkly` provider version and which resources it exposes: `launchdarkly_feature_flag`, `launchdarkly_environment`, `launchdarkly_segment`, `launchdarkly_feature_flag_environment` (targeting), `launchdarkly_metric`. Record which exist and which need REST fallback.

3. **Guarded release (a.k.a. guarded rollout) surface**
   - Confirm the current UI entry point and the REST/MCP surface for starting a guarded release on a **feature flag** (not an AI Config). The AgentControl workshop found `start-guarded-rollout` for AI Configs; confirm the flag equivalent, its parameters (test/control variation, metric, regression threshold, stages, `onRegression: rollback`), and whether the Terraform provider exposes it.
   - Confirm what **simple metric** is available for Release `08` without deep instrumentation (a built-in error/latency signal, or a lightweight custom metric the app can emit). This is the "simple" guard; the "real" instrumented guard lives in Observability. Decide the simple metric here.

4. **Kill switch**
   - Confirm the exact UI for turning a flag's targeting off (the flag toggle) and whether that's what "kill switch" refers to in current docs, vs. a distinct feature.

5. **Infra**
   - The LaunchDarkly IdP simulator lambda URL (from the reference track's `config.yml`).
   - VM `machine_type` (the app + traffic generator are light without an LLM; `n1-standard-1` may be enough — confirm).
   - Whether to pre-create one environment (`test`) or two (`test` + `production`). Lean `test` only, matching the reference.

**Deliverable:** a "Phase 0 verification notes" section appended to the bottom of this file recording every finding, plus open questions surfaced for the operator.

**Done-when:** operator reviews the findings; open questions answered; version pins and REST-vs-provider gaps recorded.

---

## Phase 1: Foundation

**Goal:** Establish the repo skeleton, Instruqt scaffolding, and shared infrastructure stubs.

**Deliverables:**
- Repository directory structure per `CLAUDE.md`.
- `instruqt-release/track.yml` and `config.yml` populated (slug, ID, title, teaser, description, time limit, the single `LAUNCHDARKLY_ACCESS_TOKEN` secret, VM declaration pointing at the shared image, the IdP simulator lambda).
- `instruqt-release/track_scripts/setup-workstation` and `cleanup-workstation` adapted from the reference: bootstrap the project, pull keys, mint the scoped `LD_API_TOKEN`, write `.env`, restart the service.
- Empty `01-welcome/` through `10-wrap-up/` folders with front-matter-only `assignment.md` files (**numbered from 01, never 00**).
- `terraform/student-bootstrap/` module creating the LD project and `test` environment.
- `vm-image/README.md` documenting what the image must contain and how to build it.

**Verification steps:** `track.yml` / `config.yml` parse as valid YAML; placeholder front-matter is valid; version findings from Phase 0 are pinned.

**Done-when:** operator confirms structure; setup-workstation bootstrap mechanics reviewed against the reference.

---

## Phase 2: App scaffold (mock, no LD wiring)

**Goal:** Produce the ToggleWear app in its BEFORE state — the storefront renders, Otto and the recommendations carousel exist as mock features, but nothing is wired to LaunchDarkly.

**Deliverables:**
- `app/server.py` — FastAPI serving `static/index.html`, a `/chat` endpoint returning **canned** Otto responses (small keyword-matched set per `NARRATIVE.md`), and a `/recommendations` endpoint returning a product list. LD integration points are clearly-marked stub blocks (marker-based paste pattern from `DECISIONS.md`).
- `app/static/index.html` — header with logo and user-tier dropdown (Free / Premium / Beta), product grid of the catalog items, Otto chat widget, and the "Recommended for You" carousel region.
- `app/static/style.css` — clean retail aesthetic per `NARRATIVE.md`.
- `app/static/app.js` — vanilla JS: chat submit/receive against `/chat`, the recommendations carousel, and the user-tier dropdown updating in-memory context state. LD client-SDK integration is a marked stub.
- `app/requirements.txt` (pinned), `app/.env.example` (documented vars — only LD-related; no AWS).
- One catalog product seeded with the malformed field the Observability track's bug relies on (documented in a code comment so it isn't "fixed" accidentally).

**Verification steps:** app starts via `uvicorn`; page renders; `/chat` returns a canned reply; the carousel renders; the dropdown updates the context value sent on requests.

**Done-when:** operator views the running app and signs off on look, product list, Otto's canned replies, and the carousel.

---

## Phase 3: Challenges 02–05 (flag, SDK, targeting, segments)

**Goal:** Author the four foundational labs.

**Deliverables (per challenge):** `assignment.md` (full body, `NARRATIVE.md` voice, concept orientation for new-to-LD learners), `setup-workstation`, `check-workstation` (with `fail-message` guidance), `solve-workstation`, and the `terraform/release-0N/` module.

- **02 your-first-flag** — create the boolean `release-otto` flag in the UI. No code yet. Check: the flag exists via REST.
- **03 wire-up-the-sdk** — copy-paste the server SDK init + `release-otto` evaluation into the marked stub in `server.py`, and the client SDK init into `app.js`. Turn the flag on; Otto appears. This is the first-flag "aha." Check: flag on + SDK wired (verify the paste landed and the flag serves `true`).
- **04 contexts-and-targeting** — build a context including the user tier; add a targeting rule serving `true` to `beta` users. Flip the dropdown to Beta; Otto appears only then. Check: targeting rule exists and serves correctly.
- **05 segments** — create a "Beta Testers" segment, move the targeting to reference it. Check: segment exists and the rule targets it.

**Verification steps:** each Terraform module applies cleanly and produces the challenge end-state; UI steps drafted from docs with `<!-- VERIFY -->` markers where uncertain.

**Done-when:** operator click-through pass per challenge; markers resolved; solves produce correct end-state; checks pass valid work and fail common mistakes helpfully.

---

## Phase 4: Challenge 07 (progressive rollout)

**Goal:** Author the progressive-rollout lab. (06 is the quiz, authored in Phase 6.)

**Deliverables:** full `07-progressive-rollout/` challenge + `terraform/release-07/`. The learner starts a **progressive rollout** (the first-class release feature: Serve menu → **Progressive rollout**, automated timed percentage stages) on `release-otto` and observes the ramp. Setup starts the traffic generator so the rollout has contexts flowing. Solve materializes the **completed-ramp end-state** (fallthrough serving `true`) via stable JSON patch — not the beta APIs — because solves must be instant and a mid-ramp flag would block 08's guarded rollout (see the refinement note under "Rollout solves use the beta release APIs" in `DECISIONS.md`). Check (authored) passes on an active fallthrough rollout OR the completed state; the active-ramp JSON shape carries a VERIFY for the operator.

**Done-when:** operator verifies the rollout UI steps and sees the ramp behave; markers resolved.

---

## Phase 5: Challenges 08–09 (guarded release, kill switch)

**Goal:** Author the guarded-release lab (the track's wow moment) and the kill switch.

**Deliverables:**
- **08 guarded-release** — full challenge + `terraform/release-08/`. Setup pre-builds the "Chatty Otto" variation (long-winded canned replies per `NARRATIVE.md`) and wires the **simple** metric chosen in Phase 0. The learner configures the guarded release in the UI (test = Chatty Otto, control = Concise Otto), watches it ramp, and watches the regression auto-rollback. A `traffic-generator/sabotage.py`-style presenter escape hatch forces the regression on demand. Check: verify a guarded rollout exists on the flag via the stable flags-list filter `?filter=guardedRollout:<status>` (confirmed in Phase 0). Solve: beta release APIs (see `DECISIONS.md`).
- **09 kill-switch** — full challenge + (light or no) Terraform. The learner turns a feature off instantly with the flag toggle when something's wrong. Short lab. Check: flag targeting is off.

**Specific notes:**
- Chatty Otto must be *organically* worse on the simple metric — bad enough to trip the threshold, not comical.
- Keep the simple metric genuinely simple. Deep instrumentation is Observability's job; this beat teaches the guarded-release *mechanism*, not metric wiring.

**Done-when:** operator runs the guarded release end-to-end (organic + sabotage), confirms rollback fires when expected and not otherwise, verifies UI steps, and confirms the "guarded releases roll back bad releases for you" takeaway lands.

---

## Phase 6: Welcome, quiz, wrap-up (01, 06, 10)

**Goal:** Author the non-lab challenges.

**Deliverables:**
- **01 welcome** — orient the learner, introduce ToggleWear and the "ship safely" premise, tour the app and the LD UI. No task beyond "click Next."
- **06 quiz-flags-and-targeting** — `type: quiz`, 1–3 questions on flags, contexts, targeting, and segments (challenges 02–05).
- **10 wrap-up** — recap the Release arc, 1–3 quiz questions covering the track, and a transition teeing up the Observability track.

**Done-when:** quiz questions are answerable from track content; welcome sets the scene without spoiling labs; wrap-up closes the arc and points to Observability.

---

## Phase 7: Polish

**Goal:** Final consistency, voice, and operator-experience pass.

**Deliverables:** narrative-consistency pass against `NARRATIVE.md`; `fail-message` quality pass on every check; idempotency pass on every setup and solve; populate/refine `instruqt-release/assets/` image references; finalize `track.yml` description/teaser; update `DECISIONS.md` with anything decided during implementation; confirm track-level setup timing fits budget.

**Verification steps:** full run-through in both 2h presenter mode and 1h self-paced mode; time each challenge.

**Done-when:** operator runs both modes end-to-end without intervention; all polish items checked; track ready to publish.

---

## Open questions surfaced during scoping

1. **Guarded release on flags vs. AI Configs.** The AgentControl workshop's guarded-rollout knowledge is AI-Config-specific. Phase 0 must confirm the feature-flag equivalent's API/UI and Terraform coverage.
2. **Simple metric for Release `08`.** What signal guards the first guarded release without deep instrumentation? Phase 0 decides (built-in error/latency vs. a lightweight custom metric the mock app emits).
3. **Guarded-release variation structure.** Multivariate `otto-style` (`concise`/`chatty`) vs. a second boolean. Lean multivariate so the dialog's variation pickers have named options. Phase 1 confirms against the UI.
4. **One environment or two.** Lean `test` only, matching the reference. Revisit only if a targeting demo needs `production`.
5. **VM machine type.** Without an LLM the app is light; `n1-standard-1` may suffice. Phase 0 confirms.

---

## Phase 0 verification notes

Recorded 2026-07-07. All web findings verified against live LaunchDarkly docs, PyPI/npm registries, the Terraform registry/changelog, and the live OpenAPI spec (`GET https://app.launchdarkly.com/api/v2/openapi.json`) on that date. Local findings verified against the checked-out reference repos at `/Users/kevin/projects/workshops/launchdarkly-workshops` and `/Users/kevin/projects/workshops/ld-workshop-ai-configs-intro`.

### 1. SDKs

**Python server SDK — `launchdarkly-server-sdk` 9.16.0 (pin this).**
- Requires Python >= 3.10; classifiers list 3.10–3.14. **Ubuntu noble's system 3.12 is fine.**
- Import name is `ldclient`. Current idioms, confirmed from docs + API reference:
  ```python
  import ldclient
  from ldclient.config import Config
  from ldclient import Context

  ldclient.set_config(Config("SDK_KEY"))
  client = ldclient.get()

  context = Context.builder("user-key").kind("user").name("Sandy").set("tier", "beta").build()
  value = client.variation("release-otto", context, False)
  client.track("event-key", context)                       # basic
  client.track("event-key", context, data, metric_value)   # full: (event_name, context, data=None, metric_value=None)
  ```
- Sources: pypi.org/pypi/launchdarkly-server-sdk/json, launchdarkly.com/docs/sdk/server-side/python, launchdarkly-python-sdk.readthedocs.io.

**JS client SDK — packaging decision needed (open question 1).**
- The package named in our planning docs, `launchdarkly-js-client-sdk` (latest 3.9.3), is **deprecated**. Its README says: "Use @launchdarkly/js-client-sdk instead of this package."
- Current package: **`@launchdarkly/js-client-sdk` 4.9.1**. Current docs use a jsDelivr CDN include:
  ```html
  <script crossorigin="anonymous" src="https://cdn.jsdelivr.net/npm/@launchdarkly/js-client-sdk@<version>"></script>
  ```
  The script-tag global is `LDClient` for both v3 and v4.
- Init idiom (same shape both versions): `LDClient.initialize(clientSideId, context, options)`, then `await client.waitForInitialization(5)` or `client.on('ready', ...)`.
- Change events diverge: v3 `client.on('change:FLAG-KEY', (current, previous) => ...)` (confirmed from typedoc); v4 docs show `client.on('change', (context, changedKeys) => ...)` plus typed variants (`boolVariation`) — the v4 callback shape was not cross-checked against the v4 typedoc; verify when wiring `app.js`.
- **Client-side availability:** flags must be available to client-side SDKs for this SDK to see them. Docs show two wordings: a "SDKs using Client-side ID" checkbox at flag creation and an "Available on client-side SDKs" toggle under Advanced controls in the flag sidebar. **Accounts created after 2025-10-21 have it on by default** — likely true of our sandbox projects, operator to confirm; challenge 03 must still teach the setting (or Terraform must set it) so learner-created flags work client-side.

### 2. Terraform provider

**Pin `launchdarkly/launchdarkly` at `~> 2.30`** (latest stable 2.30.0, released 2026-06-11). **Do not float past 3.0.0**: a breaking v3 (typed-client field renames) is in beta as of 2026-07-07 (3.0.0-beta.7 published that day) and could GA during this workshop's life. No breaking changes in the 2.x line over the last 12 months.

Resource coverage at 2.30.0:

| Resource | Exists | Notes |
|---|---|---|
| `launchdarkly_project` | yes | |
| `launchdarkly_environment` | yes | |
| `launchdarkly_feature_flag` | yes | |
| `launchdarkly_feature_flag_environment` | yes | `on`, `rules` (clauses + per-rule `variation` or `rollout_weights`), `targets`, `context_targets`, `prerequisites`, required `fallthrough`. Rollout weights are in **thousandths of a percent** (100000 = 100%). |
| `launchdarkly_segment` | yes | |
| `launchdarkly_metric` | yes | `kind` ∈ `click` / `custom` / `pageview`; numeric = `custom` + `is_numeric` + `unit`; `success_criteria`, `analysis_type`, `randomization_units` |
| `launchdarkly_access_token` | yes | could replace the curl-based token minting, but we keep the reference curl pattern |
| experiments | **no** | REST fallback: `POST /api/v2/projects/{proj}/environments/{env}/experiments` (Iterate modules) |
| guarded rollouts | **no** | see §3 — no public REST either |
| progressive rollouts (timed workflow) | **no** | manual percentage rollouts ARE supported via `rollout_weights`; the automated timed workflow is not |
| release pipelines / bandits | **no** | (`release_policy` exists only in the v3 beta — unusable at our pin) |

### 3. Guarded releases (challenge 08 — the load-bearing findings)

**Terminology.** The feature on a flag is a **"guarded rollout"** ("Guarded Releases" is the umbrella term; "Release Guardian" is the detection engine). Docs: launchdarkly.com/docs/home/releases/guarded-rollouts and …/creating-guarded-rollouts.

**Plan tier.** Guarded rollouts require a **Guardian plan**; every account includes a **limited trial**. Operator must confirm what the workshop account is entitled to (open question 2).

**UI flow (draft for assignment.md).** Flag's **Targeting** tab → **View targeting rules** → **Edit** on a rule → **Serve** menu → **Guarded rollout**. Available when toggling the flag on to serve a new variation, or when changing which variation an on-flag serves. Not available if another guarded/progressive rollout or experiment is running on the flag. The learner then configures four things: the **health check**, **metrics to monitor** (must exist beforehand; warehouse-native metrics excluded), a per-metric **Automatic rollback** checkbox (default is notify-only — the lab must tell the learner to check it), and **Target by** + **rollout duration**. There is also a **Guarded rollouts** item in the left sidebar listing flags that use one.

**Detection model.** Since January 2026, regression detection is **frequentist sequential testing on the absolute difference** between new and original variations — **not Bayesian** (do not write "Bayesian" in any prose). Evaluations run roughly every minute; monitoring spans the full rollout duration; larger degradations are caught faster. No user-configurable regression threshold appears in the documented creation flow (operator to verify in the live UI). Undocumented numbers the operator must capture from the UI: default rollout duration/stages and the minimum contexts-per-step.

**Automatic behaviors.** Even without auto-rollback checked, LD rolls back on a sample-ratio mismatch or if the new variation gets too little traffic by rollout end. Steps auto-extend when the per-step minimum isn't met. Mid-rollout the user can Dismiss a regression alert, Roll back, or Stop monitoring.

**The simple metric: confirmed viable.** A plain custom (conversion or numeric) metric fed by server-side `client.track()` events **can guard a rollout — no observability SDK required**. Built-in error/latency metrics exist only as *autogenerated* metrics requiring the browser observability plugin or OpenTelemetry, so they are NOT the "simple" path — that instrumentation is deliberately Observability-track material. **Proposal (open question 5):** a custom numeric metric `otto-response-latency` (lower is better, `success_criteria = LowerThanBaseline`) — Chatty Otto's long-winded replies organically take longer, and the mock server can make that real by delaying proportionally to reply length. Alternative: a conversion metric like `otto-helpful` (thumbs-up click), which is more visible in the UI but needs a UI affordance on the widget.

**REST/API surface — the big gap.** There is **no public API to start a guarded rollout on a flag's targeting rule.** The flags semantic-patch endpoint (`PATCH /api/v2/flags/{proj}/{key}` with `domain-model=launchdarkly.semanticpatch`) has no guarded/measured-rollout instruction kind in the live OpenAPI spec; the UI evidently drives an internal `measured-rollouts` API that appears in the spec only as a response `_links` example. The only documented write paths are **beta** (release pipelines' `releaseGuardianConfiguration`; release policies' `guardedReleaseConfig`). Consequences:
- `solve-workstation` for 08 **cannot start a real guarded rollout via stable REST or Terraform** (open question 4).
- `check-workstation` CAN verify one exists: the flags list endpoint supports `?filter=guardedRollout:<any|monitoring|regressed|rolledBack|completed|archived>` — confirmed in the live spec. So the check is API-driven and solid.

### 4. Progressive rollout (challenge 07)

Two distinct things exist; the lab must pick one (open question 3):
- **Manual percentage rollout** — learner sets rollout weights on a rule/fallthrough and ramps 10% → 50% → 100% by hand. Fully supported by Terraform (`rollout_weights`) and REST semantic patch (`updateFallthroughVariationOrRollout` / `updateRuleVariationOrRollout` with `rolloutWeights` in thousandths). Solve and check are trivial. This matches the current PHASES wording.
- **Progressive rollout (the product feature)** — same Serve-menu entry as guarded ("Progressive rollout"), automated timed stages, available on **all plans**. Default schedule values are not published (operator captures from UI). **No public API or Terraform support** — same solve gap as guarded rollouts; restarting one re-randomizes contexts (unlike manual percentage rollouts, which retain bucketing across stop/restart).

Recommendation: teach the **manual percentage ramp** in 07 (it teaches the mechanics and is fully solvable/checkable), and let 08's guarded rollout introduce the automated-stages concept. Operator decides.

### 5. Kill switch (challenge 09)

"Kill switch" in current docs is a **flag template / usage pattern**, not a separate product feature (launchdarkly.com/docs/home/flags/killswitch): a permanent boolean flag where killing = toggling targeting **Off**. A "Kill switch" template appears under **Custom** in the Create-flag dialog. API: the semantic-patch instruction **`turnFlagOff`** — confirmed in the live spec — which gives 09 a clean solve (`turnFlagOff` via curl) and check (`environments.test.on == false`). Related but distinct: **flag triggers** (APM tools flipping flags via webhook) — worth a one-line mention in 09's prose as the automated cousin, and possibly relevant to Observability's auto-remediation.

### 6. Infra (from the reference repos)

- **IdP simulator lambda URL** (from both reference tracks' `config.yml`, identical):
  `https://i3vcudz5ncoet6xkoaqxnos7mu0sdcpz.lambda-url.us-east-2.on.aws/?sandboxId=${_SANDBOX_ID}`
- **VM machine type:** the basics track runs `n1-standard-1`; AgentControl needed `n1-standard-2` (LLM-era app). Without an LLM, **`n1-standard-1`** should suffice — confirm during image bake.
- **Environments:** the basics track creates **`test` only**, embedded in the `launchdarkly_project` resource. We match. (AgentControl's `student-bootstrap` main.tf is the template: one `launchdarkly_project` with an inline `environments { key = "test" ... }` block.)
- **Bootstrap mechanics:** both reference tracks bake the student-bootstrap Terraform into the VM image at `/opt/ld/terraform-ld-student` and run it from track-level `setup-workstation` (`terraform.tfvars` gets `sandbox_id = "${_SANDBOX_ID}"`; project key comes from `terraform output`). SDK key (`.apiKey`) and client-side ID (`._id`) are pulled from `GET /api/v2/projects/{proj}/environments/test`. Keys are written to `~/.profile`, `~/.bashrc`, and the app `.env` via `sed`.
- **Scoped token minting:** AgentControl's snippet carries over verbatim — `POST /api/v2/tokens` with `inlineRole: [{effect: "allow", actions: ["*"], resources: ["proj/<key>", "proj/<key>:*"]}]`.
- **Service restart gotcha (from AgentControl):** use `service <name> stop` then `start`, not `restart` — restart SIGHUPs and the app doesn't reload env vars.
- **Secrets:** the reference tracks declare AWS keys + `LAUNCHDARKLY_ACCESS_TOKEN`; we declare **only `LAUNCHDARKLY_ACCESS_TOKEN`**.
- **Check-script idiom confirmed** from the basics track's `03-controlling-risk/check-workstation`: `curl -s` against `app.launchdarkly.com/api/v2` with `-H 'Authorization: '$LAUNCHDARKLY_ACCESS_TOKEN`, parse with `jq`, `fail-message "..."` + `exit 1` on failure.
- **Marker paste pattern confirmed** from AgentControl: BEGIN/END comment markers in `server.py`, a `patch-server.py` per challenge module doing `str.find()` substitution from a `server-paste.py` file, idempotency via a already-wired sentinel string check.

### Answers to the scoping questions

1. **Guarded release on flags** — confirmed: UI-only start (stable), no Terraform, no public REST write; check via `filter=guardedRollout:` on the flags list. See §3.
2. **Simple metric for 08** — a `track()`-fed custom metric works with zero observability instrumentation; proposal is `otto-response-latency` (numeric, LowerThanBaseline). See §3 and open question 5.
3. **Variation structure** — nothing found contradicts the multivariate `otto-style` (`concise`/`chatty`) lean; a guarded rollout attaches when a rule changes which variation it serves, which fits multivariate cleanly. Confirm against the UI in Phase 1.
4. **One environment or two** — `test` only, confirmed against the reference.
5. **VM machine type** — `n1-standard-1`, pending confirmation at image-bake time.

### Open questions for the operator — ANSWERED 2026-07-07 (recorded in `DECISIONS.md`)

1. **JS client SDK package:** → **`@launchdarkly/js-client-sdk` v4.**
2. **Plan entitlement:** → **the workshop LD account includes Guardian**; guarded rollouts fully available, no trial limits in play.
3. **Challenge 07 shape:** → **the automated progressive-rollout feature** (not a manual ramp).
4. **Challenge 08 solve-on-skip:** → **use the beta release APIs** in solve scripts (applies to 07's solve too, since progressive rollouts share the no-stable-API gap).
5. **Simple metric for 08:** → **`otto-response-latency`** (custom numeric, LowerThanBaseline).
6. **UI-only numbers to capture:** → agreed; items added to `OPERATOR-CHECKLIST-release.md`.
