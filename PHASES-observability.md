# PHASES-observability.md

Build sequence for **Track 2 / Observability** (`instruqt-observability/`), the second sibling track. Mirrors the phase structure of `PHASES-release.md`.

Track 2 starts where Release ends — Otto is shipped and rolled out, the SDKs are wired. The track-level `setup-workstation` runs Release's solve scripts to materialize that baseline before any Observability-specific work runs, then the track adds the "Recommended for You" carousel as the feature under observation.

**Scope reminder:** release-scoped observability only. Error monitoring attributed to a release, session replay as flag-scoped evidence of the broken experience (added 2026-10-19), release health metrics, guarded releases on real metrics, and auto-remediation. **Out of scope:** distributed tracing UI, log aggregation/search, general UX analytics. See the "Observability scope" entry and its 2026-10-19 amendment in `DECISIONS.md`.

---

## Track 2 / Observability — scope

By the end of Observability, the learner has:

- Wired LaunchDarkly's observability plugins into the app (server and browser) so runtime errors become visible errors in LaunchDarkly and shopper sessions are recorded.
- Viewed errors attributed to the specific flag/release that introduced them, and replayed the session where a shopper watched the carousel break.
- Attached a release-health metric (error rate and/or latency) and read per-variation health.
- Guarded a rollout of a risky recommendations strategy on the **real instrumented error metric** and watched it auto-rollback.
- Configured auto-remediation / self-healing so a detected regression is fixed automatically.

Challenge list (8 challenges, ~2h):

| # | Slug | Type |
|---|---|---|
| 01 | welcome-recap | challenge |
| 02 | instrument-for-errors | challenge (wire the observability SDK) |
| 03 | errors-in-context | challenge (errors attributed to a release) |
| 04 | release-monitoring | challenge (release-health metric + per-variation health) |
| 05 | quiz-release-health | quiz |
| 06 | guarded-release-real-metrics | challenge (guard on the real error metric) |
| 07 | auto-remediation | challenge (self-healing) |
| 08 | wrap-up | challenge |

Slugs are draft and lock in Phase 1.

---

## Source-of-truth notes

- `CLAUDE.md` — operational spec; conventions apply across all three tracks.
- `DECISIONS.md` — see "Observability scope," "Two guarded-release beats," "Second storefront feature," and "Three safety nets, three timescales."
- `NARRATIVE.md` — the recommendations carousel spec, the personalized-strategy bug, flag/metric keys.
- `PHASES-release.md` — Release is the baseline this track materializes.

---

## Phase 0: Verification spike

**Goal:** Pin down the newer, less-documented surfaces before authoring. **Auto-remediation is the riskiest surface in the whole workshop** — treat its verification as blocking for challenge 07.

**What needs verification:**

1. **Observability SDK (challenge 02)** — the highest-priority unknown.
   - Exact package name and init for both the **Python server** and the **JS client**. (LaunchDarkly's observability offering post-dates this file; the package names must come from current docs, not memory.)
   - How an error/exception is reported to LaunchDarkly — automatic capture vs. an explicit `recordError`-style call.
   - Whether errors carry flag/release context automatically or need it attached.
   - Whether observability data requires anything beyond the existing keys (a separate ingest key?). If so, thread it through the track-level setup like the other keys.

2. **Errors attributed to a release (challenge 03)**
   - Confirm the UI where errors appear filtered/attributed by flag or release, and what "release" means in that view (a flag change? a rollout?).

3. **Release-health metrics (challenge 04)**
   - How an error-rate / latency metric is defined and attached to a flag's release, and where per-variation health is shown. Terraform `launchdarkly_metric` coverage vs. REST.

4. **Guarded release on the real metric (challenge 06)**
   - Same guarded-release surface Release Phase 0 confirmed, now pointed at the instrumented `recs-error-rate` metric. Confirm a custom app-emitted error metric can drive a guarded release's regression detection.

5. **Auto-remediation / self-healing (challenge 07) — BLOCKING**
   - **What is the actual feature?** The launchdarkly.com lineup markets "auto-remediation" and "self-healing" as "instantly fix issues with suggested changes and PRs." Confirm which of these it actually is today:
     - a fully-managed LaunchDarkly feature that flips a flag on a signal automatically, or
     - a "suggested change / open a PR" workflow the operator reviews, or
     - an app-side loop the developer wires using documented SDK + REST primitives (analogous to the AgentControl workshop's "adaptive switching," which was an in-app rolling-window loop hitting the targeting REST API).
   - Confirm the REST/MCP surface for whichever it is. If it's an app-side loop, confirm the flag-targeting REST endpoint (the flag equivalent of `update-ai-config-targeting-rules` / `update-ai-config-rollout`).
   - **If the managed feature isn't available or isn't documented enough to author confidently, fall back to the app-side loop** (flip `recommendations-strategy` back to `bestsellers` when `recs-error-rate` crosses a threshold), and record the fallback in this file. Do not invent a managed feature that doesn't exist.

**Deliverable:** "Phase 0 verification notes" appended to this file; the auto-remediation shape decided and recorded.

**Done-when:** operator reviews findings; the auto-remediation approach for challenge 07 is locked.

---

## Phase 1: Baseline + carousel wiring

**Goal:** Materialize the post-Release baseline and add the recommendations carousel as the feature under observation.

**Deliverables:**
- `instruqt-observability/track.yml` / `config.yml` (same single secret; shared image).
- `track_scripts/setup-workstation` that bootstraps the project, mints `LD_API_TOKEN`, **then applies Release's solve modules in order** to reach the post-Release baseline. Time it; if past ~60s, escalate about pre-baking the baseline into the image.
- The `show-recommendations` and `recommendations-strategy` flags added to the baseline (via a bootstrap addition or challenge-02 setup, decide during authoring). **Decided 2026-10-19: a dedicated `terraform/observability-baseline/` module applied by the track-level setup**, with the matching server-side paste — see "Implementation decisions made while building the Observability track" in `DECISIONS.md`.
- Confirmation that the carousel and the seeded malformed-product bug behave as `NARRATIVE.md` describes.
- Empty challenge folders `01`–`08` with valid front-matter.
- (Added 2026-10-19 with the session-replay scope change) the two browser plugin UMD bundles vendored into `app/static/vendor/` and loaded from `index.html`; `launchdarkly-observability` pinned in `app/requirements.txt`; `vm-image/README.md` updated for the heavier venv, the `instruqt-*/` directories, and observability egress.

**Phase 1 status (2026-10-19):** delivered; awaiting operator review. Setup timing cannot be measured without a VM — the script logs `[setup +Ns]` per step so the first live run reports it. Local verification done: Terraform module validates; all YAML/front-matter parses; the baseline paste compiles on top of the full Release paste stack and is idempotent; the unwired app serves the storefront, `/recommendations`, and all three vendor bundles.

**Done-when:** a learner landing cold in Observability arrives with Otto shipped and the carousel present; setup timing is within budget.

**Phases 2–6 status (2026-10-19):** all authored in one pass at the operator's request; awaiting the live click-through. Per-phase notes:
- *Phase 2 (02–04):* 02 = two pastes (server plugin; browser plugins + client-side `recommendations-strategy` evaluation) and a plain release of Personalized; 03 = exploratory (Monitoring tab, session replay), solve delegates to 02; 04 = autogenerated metrics + revert to Bestsellers. Modules: `observability-02`, `observability-04` (REST via `lib/set-fallthrough.sh`).
- *Phase 3 (06):* guarded rollout on **User HTTP error rate**; module `observability-06` uses `lib/start-guarded-rollout.sh` (beta pipeline, same VERIFY as Release 08).
- *Phase 4 (07):* adaptive trigger, arm-then-release; module `observability-07` materializes the healed end-state only (see DECISIONS).
- *Phase 5 (01, 05, 08):* recap matches the baseline module; quizzes are single-question with `solution: [1]`.
- *Phase 6:* assets table, checklist rewritten for the actual surfaces, DECISIONS updated, Release 08 "every minute" corrected. Local verification: YAML/front-matter, `terraform validate` on all modules, `bash -n` on all scripts, full paste stack compiles (Python + JS) and is idempotent, and a scratch server with the 02 server paste and a dummy SDK key starts with the plugin initialized.

**Densest VERIFY areas for the click-through:** browser plugin option names and UMD export shape (02); autogenerated metric names/keys and appearance latency (04); adaptive-trigger threshold unit, alert-window options, and time-to-fire (07).

---

## Phase 2: Challenges 02–04 (instrument, attribute, monitor)

**Goal:** Author the three observability labs, using the SDK/API shapes confirmed in Phase 0.

**Deliverables (per challenge):** `assignment.md`, `setup-workstation`, `check-workstation`, `solve-workstation`, `terraform/observability-0N/`.

- **02 instrument-for-errors** — copy-paste the Python observability plugin into the SDK-setup block in `server.py`, and the browser observability + session-replay plugins into the client-SDK block in `app.js` (the UMD bundles are vendored and loaded from `index.html`). Trigger the personalized-strategy bug; see the error land in LaunchDarkly. Check: pastes landed (grep) and the running server reports the plugin initialized (`/healthz`); the autogenerated error metric's presence is a bonus assertion once its key is known.
- **03 errors-in-context** — on the flag's **Monitoring** tab, view errors attributed to the `personalized` variation, then open the **Sessions** chart and replay the session where the carousel vanished (the **Flags** subsection of the replay shows the `personalized` evaluation). Exploratory lab with reflective steps, similar to the reference's monitoring challenge. Session replay stays scoped to this one beat.
- **04 release-monitoring** — define/attach the `recs-error-rate` metric and view per-variation health. Check: the metric exists and is attached.

**Done-when:** operator click-through per challenge; markers resolved; solves correct; checks helpful.

---

## Phase 3: Challenge 06 (guarded release on real metrics)

**Goal:** Author the deeper guarded-release lab. (05 is the quiz, Phase 5.)

**Deliverables:** full `06-guarded-release-real-metrics/` + `terraform/observability-06/`. Setup ensures the `recs-error-rate` metric is live and drives background traffic (the bug-triggering variant of the generator). The learner configures a guarded release of `personalized` (test) vs `bestsellers` (control) on `recs-error-rate`, watches the real error signal trip the regression threshold, and watches the auto-rollback. The `assignment.md` intro explicitly notes this is the *same mechanism* as Release `08` but guarding a *real instrumented signal* — reinforcing the "two beats, split by depth" decision. Sabotage escape hatch available.

**Done-when:** operator sees the rollback fire from the real metric (organic + sabotage); UI verified; the "now the guard watches a signal you built" point lands.

---

## Phase 4: Challenge 07 (auto-remediation / self-healing)

**Goal:** Author the self-healing lab using the approach locked in Phase 0. **The riskiest challenge — depends entirely on Phase 0's finding.**

**Deliverables:** full `07-auto-remediation/` + `terraform/observability-07/`.
- If the **managed feature** exists and is documented: the learner configures it (a rule that flips `recommendations-strategy` to `bestsellers`, or accepts a suggested change/PR, when `recs-error-rate` crosses a threshold), then watches it heal automatically.
- If falling back to the **app-side loop**: copy-paste a rolling-window loop into `server.py` (marker-based) that polls/computes the error rate and issues a flag-targeting REST PATCH to flip back to `bestsellers` when the threshold trips. This mirrors the AgentControl workshop's adaptive-switching challenge and reuses the scoped `LD_API_TOKEN`.
- Either way: the app-visible result is the carousel reverting to the safe strategy without human intervention, and the LD Targeting view reflecting the flip.

**Specific notes:**
- Keep `<!-- VERIFY -->` markers dense here; this is the surface most likely to have shifted since authoring.
- Time the heal loop so the flip fires within a presenter-friendly window (~60–90s), tuning the traffic generator and threshold.

**Done-when:** operator confirms the heal fires reliably from the bad signal and the Targeting view updates; the "the system fixed itself" takeaway lands; all markers resolved.

---

## Phase 5: Welcome-recap, quiz, wrap-up (01, 05, 08)

**Goal:** Author the non-lab challenges.

**Deliverables:**
- **01 welcome-recap** — re-establish context for a learner who didn't just finish Release: the shop is live, Otto is shipped and guarded, and now we're adding a recommendations feature that will misbehave. State what the setup materialized.
- **05 quiz-release-health** — `type: quiz`, 1–3 questions on error attribution and release health (challenges 02–04).
- **08 wrap-up** — recap the Observability arc; a question or two contrasting the *release-time* guard (rolls back while ramping) with *post-release* auto-remediation (fixes something already live) per the "three timescales" framing; transition to Iterate.

**Done-when:** recap matches the materialized state; quiz answerable from content; wrap-up reinforces the timescale distinction and points to Iterate.

---

## Phase 6: Polish

Same as `PHASES-release.md` Phase 7, scoped to Observability: narrative consistency, `fail-message` quality, setup/solve idempotency, `instruqt-observability/assets/` images, `track.yml` finalization, `DECISIONS.md` updates, and confirming the baseline-materializing setup fits the time budget (escalate to pre-baking if not).

**Done-when:** operator runs both delivery modes end-to-end; all polish items checked; track ready to publish.

---

## Open questions surfaced during scoping

1. **Observability SDK identity.** Package names and init for Python server + JS client are the top unknown. Blocking for Phase 2.
2. **Auto-remediation feature shape.** Managed self-healing vs. suggested-change/PR vs. app-side loop. Blocking for Phase 4. Fallback is the app-side loop.
3. **Separate observability ingest key?** If the observability SDK needs its own key, thread it through track-level setup. Phase 0 confirms.
4. **Baseline startup time.** Applying Release's solves at Observability's start may be slow. Phase 1 measures; fall back to pre-baking if past ~60s.
5. **Does the JS client participate in error reporting,** or is server-side instrumentation enough for the release-scoped story? ~~Lean server-side to keep it focused.~~ **Answered 2026-10-19: yes, both browser plugins are wired** — the operator added session replay to the track's scope, and it requires them. See Phase 0 notes §1 and `DECISIONS.md`.

---

## Phase 0 verification notes

Recorded 2026-10-19. Web findings verified against live LaunchDarkly docs (the `.md` renderings under `launchdarkly.com/docs/…`), PyPI/npm/jsDelivr, the `launchdarkly/observability-sdk` GitHub source, the Terraform registry, and the live OpenAPI spec (`GET https://app.launchdarkly.com/api/v2/openapi.json`) on that date. The Python plugin was also test-installed locally against `app/requirements.txt`.

**Headline:** every surface this track needs exists and is documented, including a first-class managed auto-remediation feature (**adaptive triggers**). Two things need operator confirmation before Phase 1: plan entitlement for observability + adaptive triggers (§9), and the choice of "real metric" for 04/06 (§9).

### 1. Observability SDKs (challenge 02)

**Python server — `launchdarkly-observability` 1.3.3 (pin this).** Released 2026-08-26. Requires Python ≥ 3.10 and `launchdarkly-server-sdk` ≥ 9.12 (< 10) — our 9.16.0 pin is fine. Import name is `ldobserve`. It is a **plugin** passed to the SDK `Config`; the SDK key is the only credential (no separate ingest/project key — the plugin uses the SDK key as its project id and the backend derives the environment).

```python
import ldclient
from ldclient import Context
from ldclient.config import Config
from ldobserve import ObservabilityConfig, ObservabilityPlugin, observe

ldclient.set_config(Config(
    os.environ["LD_SDK_KEY"],
    plugins=[ObservabilityPlugin(ObservabilityConfig(
        service_name="togglewear",
        service_version="workshop",   # docs recommend the deployed git SHA
    ))],
))
ld_client = ldclient.get()
```

- Manual error reporting: `observe.record_exception(exc, attributes=None)`. Also available: `observe.record_log`, `record_metric` (gauge), `record_count`/`record_incr`, `record_histogram`, `start_span(...)` context manager.
- **Automatic capture:** `ObservabilityPlugin.__init__` calls OpenTelemetry `auto_instrumentation.initialize()`, which patches FastAPI/Starlette (`opentelemetry-instrumentation-fastapi 0.55b1` is a hard dependency) so every request gets a server span; unhandled exceptions are recorded on that span as `exception` events and the response is a 500. **Ordering matters:** the plugin must be constructed before `app = FastAPI(...)` is created. In `server.py` the SDK-setup paste block sits above the catalog and well above `app = FastAPI(...)`, so the existing marker position works — no restructuring needed.
- **Flag attribution is automatic:** the plugin registers the `ldotel.tracing.Hook` (from `launchdarkly-server-sdk-otel`, pulled in as a dependency) with `include_value=True`, so every `variation()` call adds a `feature_flag` span event (`feature_flag.key`, `feature_flag.context.key`, `feature_flag.result.value`, …) to the current span. LaunchDarkly correlates "exception span events that occur **after** a feature flag span event on the same trace" — our `/recommendations` handler evaluates `recommendations-strategy` first and then throws inside `_recommend_personalized`, which is exactly the right order.
- Transport: OTLP **gRPC** to `https://otel.observability.app.launchdarkly.com:4317` (`/v1/traces`, `/v1/logs`, `/v1/metrics`); config fetched from `pub.observability.app.launchdarkly.com`. Override with `otlp_endpoint=` or `OTEL_EXPORTER_OTLP_ENDPOINT` (docs suggest `:443` where 4317/4318 egress is blocked — Instruqt GCP VMs normally have open egress; confirm on first live run).
- `instrument_logging=True` by default: the plugin takes over `logging.basicConfig` and ships INFO+ logs to LaunchDarkly. Our `server.py` already calls `basicConfig`; the plugin's own docs say configure logging *before* initializing the plugin, which is our current order. Expect our `log.info(...)` lines to show up under the flag's **Logs** monitoring chart — a free bonus for 03.
- **Install footprint:** the package pins `opentelemetry-*==1.34.1` / `0.55b1` and ~40 OTel instrumentations (incl. LLM-vendor ones we don't use). Verified: `pip install -r app/requirements.txt launchdarkly-observability==1.3.3` resolves cleanly with our fastapi 0.139.0 / uvicorn 0.50.2 pins; the venv is ~180 MB; `import ldobserve` works. **Bake it into the image** (add to `app/requirements.txt`) — the paste imports it, and pip at lab time is too slow.
- README still says "Early Access Preview — APIs subject to change until 1.x"; the package is at 1.3.3, so the public API (`ObservabilityPlugin`, `ObservabilityConfig`, `observe.*`) is past that gate. The product docs label the observability *features* "publicly available in early access — enable observability in the billing page" (see §9).

**JS browser — `@launchdarkly/observability` 1.2.1 and `@launchdarkly/session-replay` 1.2.1 (pin both; DECIDED 2026-10-19: wire both).** Each is a plugin passed to the v4 client via the `plugins: [...]` init option — confirmed present in the 4.9.1 typings (`BrowserOptions.plugins?: LDPlugin[]`), so our vendored `LDClient.createClient(clientSideId, context, options)` accepts them. They require only the client-side ID. Both ship **UMD builds** on jsDelivr (`dist/index.umd.js`; ~350 KB and ~430 KB), which we **vendor** next to the client SDK in `app/static/vendor/` for the same reason the SDK is vendored (no CDN dependency at lab time). UMD globals, read from the bundles: `window.Observability` (namespace: `.default` and `.Observability` = the plugin class, `.LDObserve` = the record API) and `window.SessionReplay` (namespace: `.default` and `.SessionReplay` = the plugin class, `.LDRecord` = the recording API); the bundles also set `globalThis.LDObserve` / `globalThis.LDRecord`. Draft paste shape for the 02 `app.js` block (export names confirmed by reading both UMD bundles on 2026-10-19):

```js
ldClient = LDClient.createClient(cfg.clientKey, ldContext(), {
  plugins: [
    new Observability.default({ serviceName: 'togglewear-web' }),
    new SessionReplay.default({ privacySetting: 'none' }),
  ],
});
```

- The observability plugin auto-captures `window.onerror` and `unhandledrejection`, patches `fetch` for network recording (`networkRecording: {enabled, recordHeadersAndBody}`), and records product-analytics span events by default. Manual: `LDObserve.recordError(err, message?, attrs?)`.
- **Privacy:** session replay defaults to `privacySetting: 'strict'`, which obfuscates *all* DOM text and images — the replay would be unreadable. `'default'` masks inputs plus PII-regex text; `'none'` records everything. The storefront has no PII (synthetic shoppers, no auth), so **use `'none'`** and say so in the 02 prose as a teaching beat ("in a real app you'd leave this at the default"). Per-element `highlight-mask` / `highlight-block` classes exist if anything ever needs hiding.
- **Attribution rule for client-side telemetry:** LaunchDarkly attributes a session/error to a flag variation only when the telemetry comes from the same context that evaluated the flag; for client SDKs that means events after `identify`. Our `app.js` identifies on tier change and evaluates `release-otto` client-side, but `recommendations-strategy` is evaluated **server-side**. For the **Sessions** chart on the flag's Monitoring tab to group by variation, the browser needs to evaluate `recommendations-strategy` too (or `show-recommendations`) — plan to have the 02/03 paste call `ldClient.variation('recommendations-strategy', 'bestsellers')` (value unused by the UI, evaluation is what matters) so the session carries the flag event. VERIFY on the first live run whether server-side-only evaluation already suffices via trace correlation.
- Sessions appear under **Telemetry → Sessions** (list, `Play`, 1x–8x speed, Dev Tools panel) and, flag-scoped, under the flag's **Monitoring → Sessions** chart; the session detail has **General / Logs / Traces / Flags / Performance** subsections. Searchable by `visited-url`, `eventType`, click selectors, and track-event properties. Not available on the EU instance (we're US).
- Both browser plugins depend only on `@launchdarkly/o11y` (bundled); no peer dependency on the client SDK package, so the vendored IIFE SDK and the UMD plugins can coexist. The plugin ↔ client contract is the `LDPlugin` interface (register + hooks), same as Python.

### 2. Errors attributed to a release (challenge 03)

The UI surface is **Feature monitoring**: a flag's **Monitoring** tab has **Errors / Logs / Traces / Sessions** charts, each "automatically scoped to the flag you have selected, with results grouped by the flag's variations". Clicking an error opens its detail (occurrences, users affected, instance metadata including the `feature_flag.*` attributes; stack traces for Python appear as the recorded exception's traceback — the sourcemap caveat is browser-only). Project-wide, the same errors appear under **Telemetry → Errors** (filterable by `feature_flag` / `key` / `result.value`), with Open / Resolved / Ignored / Snooze status management. The **Monitoring** tab also carries the **Flag history** section (evaluations graph + change history), which is the "what changed, when" half of attribution.

"Release" in this UI means **flag variation**, not a pipeline release — the per-variation grouping is the attribution. The challenge 03 prose should say "attributed to the `personalized` variation of `recommendations-strategy`" and avoid the word "release" as a product noun.

Caveat to VERIFY live: the feature-monitoring doc's prerequisites paragraph says flag-scoped charts need "the LaunchDarkly observability SDK plugins with a supported client-side SDK", then immediately lists the server-side plugin as supported for errors/logs/traces. Everything else in the docs (server-side error recording, OTel trace correlation) says server-side telemetry is attributed. Treat the first sentence as stale wording; confirm the Errors chart populates from Python-side exceptions on the first live run before authoring 03's screenshots.

### 3. Release-health metrics (challenge 04)

Three ways to get an error-rate metric attachable to a guarded rollout; the first two are viable, the third is not:

| Option | What it is | Learner work | Caveats |
|---|---|---|---|
| **A. Autogenerated OpenTelemetry metrics** | LaunchDarkly creates these automatically once traces with flag span events arrive: **User HTTP error rate** (`otel.http.error`), **User HTTP 5XX response rate** (`otel.http.5XX`), **User non-HTTP exception rate** (`otel.exception`), and **Average / P95 / P99 request latency** (`otel.http.latency`). The error ones are custom conversion binary, `user` analysis unit, lower-is-better, "units without events = 0", tagged `autogenerated` on the Metrics list, documented as "useful when running a guarded rollout". | None — they appear by themselves. 04 becomes "find the autogenerated metrics, open **Events**, see the 500s on `personalized`". | Metric *keys* in the UI aren't documented (only the event keys are) — capture live. Appearance latency after first trace unknown. Depends on LaunchDarkly backend processing, which we can't exercise from here. |
| **B. Custom conversion metric fed by `track()`** | The learner creates `recs-error-rate` (kind custom, not numeric, event key `recs-error`, lower-is-better) in the UI and pastes one `ld_client.track("recs-error", context)` line into the exception handler in `/recommendations`. | Create metric in UI + one paste. Mirrors Release 08's metric lab and is fully Terraform-able (`launchdarkly_metric`). | Second signal for the same error (the observability plugin already captured it); slightly undercuts "the guard watches the signal the observability SDK gave you". |
| C. Trace metrics (`kind: trace`, `traceQuery`) | Custom metric defined from a span query (e.g. `http.status_code >= 500`), guarded-rollout-only. | Would be elegant. | **Early Access Program only** — not authorable for a public workshop. Excluded. |

**Recommendation (open question 3):** primary = **A**, fallback = **B**. A is the truest "real instrumented signal" and needs zero extra wiring, which is the whole point of the Release/Observability depth split. B is the safety net if autogenerated metrics don't materialize in the sandbox project within presenter-friendly time. The naming in `NARRATIVE.md` (`recs-error-rate`) would then refer to the autogenerated **User HTTP error rate** metric in prose, or we rename. Decide after the first live run; either way the check script for 04 is `GET /api/v2/metrics/{proj}/{key}` on whichever key we settle on.

Provider: `launchdarkly_metric` covers option B fully. Autogenerated metrics can't (and needn't) be created by Terraform.

### 4. Guarded release on the real metric (challenge 06)

Same mechanism Release Phase 0 confirmed; all findings there still hold (Serve → **Guarded rollout**; health check; metric picker; per-metric **Automatic rollback** checkbox; **Target by**; duration; no user-settable threshold; frequentist sequential testing on **absolute** difference since Jan 2026 — relative difference is explicitly "no longer supported"). New details from the current docs:

- Regression checks run **approximately every 10 seconds** (not "every minute" — fix the Release 08 prose in its polish pass).
- **Minimum sample: 10 contexts per variation** before any decision; conversion metrics count unique exposed contexts. Not changeable in UI/release policy.
- No single rollout step may exceed **50%** (equal split required for the comparison).
- Metric direction matters: an error metric marked higher-is-better reads rising errors as success. Autogenerated error metrics are already lower-is-better; option-B metrics must be created with `LowerThanBaseline`.
- Autogenerated and custom conversion metrics are both explicitly supported in guarded rollouts; warehouse-native metrics are the only exclusion.
- Guarded rollout **health check** will show "Recently seen events for …" only after the metric has received events — the traffic generator must have driven some `personalized` errors before the learner opens the dialog (setup for 06 should run the bug-triggering traffic for a minute first, or 02–04 will already have done so).
- Vega (LaunchDarkly's AI agent) now auto-investigates guarded-rollout rollbacks and shows a diagnosis on the rolled-back release. Nice to point at in prose if the account has Vega; not a dependency.
- Check: `GET /api/v2/flags/{proj}?filter=guardedRollout:any` (stable, unchanged). Solve: beta release-pipeline path per `DECISIONS.md`, same script shape as `terraform/release-08/start-guarded-rollout.sh`, pointed at `recommendations-strategy` / `personalized`. The same VERIFY (does a pipeline monitored release register under the `guardedRollout:` filter, and how do metrics attach) still applies and is now shared by both tracks — resolve it once in the Release 08 click-through.

### 5. Auto-remediation (challenge 07) — the blocking question, answered

**It is a fully managed LaunchDarkly feature: adaptive triggers** (`launchdarkly.com/docs/home/flags/triggers`). Not an app-side loop, and not (only) a suggested-PR workflow:

> "An adaptive trigger serves a different flag variation in response to a metric's degraded performance over a specified time period. When the metric's performance crosses a threshold you specify, LaunchDarkly sends an alert…"

- **UI flow (draft for assignment.md):** flag → **Targeting** tab → **Add adaptive trigger** underneath the rule (the default rule, for us) → **Source** → **Threshold** (Type Constant/Anomaly, Condition Above/Below, Alert threshold, Alert window; advanced: Cooldown, Evaluation delay) → **Switch variation to** (→ **Bestsellers**) → optional notifications → **Add**. A summary appears under the rule; the fired alert shows on **Telemetry → Alerts**.
- **Sources:** LaunchDarkly hosted metrics (so the autogenerated `otel.http.error` or a custom `recs-error-rate` metric both qualify — "adaptive triggers work only with custom metrics and observability metrics", not click/pageview), or raw observability queries over **Errors**, **Logs**, **Traces**, **Sessions**, **Events**, **Observability Metrics** with filters/functions/group-by. The Errors source "alerts one time for every open error that matches the filters", which is a very presenter-friendly trigger for us (filter `feature_flag.key = recommendations-strategy`).
- **Behaviors to put in prose:** evaluates its source across the **whole environment**, not just the flag's audience; bypasses approvals; does not run on flags with an active experiment (relevant to Iterate — separate session, so no conflict); environment-scoped; metric definition is snapshotted at trigger creation.
- **Plan gating:** "available to customers on select plans" — operator must confirm the workshop account is entitled (open question 1). Not available in the EU instance (we're on US).
- **REST surface — stable, confirmed in the live spec** (tag "Adaptive triggers", no beta header):
  - `GET /api/v2/projects/{proj}/environments/{env}/adaptive-triggers?resourceKind=flag&resourceKey=recommendations-strategy` → list (gives 07 a solid API-driven **check**).
  - `POST …/adaptive-triggers` with `{name, resourceKind: "flag", resourceKey, triggerSource: {type: "observabilityAlert", alertId: <int>}, task: {instructions: [{kind: "updateFallthroughVariationOrRollout" | "updateRuleVariationOrRollout", variationId: <uuid>, ruleId?}]}}`.
  - `PATCH`, `DELETE`, `POST …/{id}/enable`, `POST …/{id}/disable`.
  - Terraform provider: **no** adaptive-trigger or alert resource at either 2.x or 3.x (`launchdarkly_flag_trigger` is the legacy webhook trigger) → REST fallback.
- **The solve gap:** the only `triggerSource` type is `observabilityAlert`, keyed by an integer `alertId`, and **there is no public REST API for observability alerts** anywhere in the spec (alerts are created in the UI; the adaptive-trigger UI creates one implicitly). So `solve-workstation` for 07 cannot create a real adaptive trigger from scratch. Proposal: solve materializes the **post-remediation end-state** (default rule → `bestsellers`, via stable semantic patch `updateFallthroughVariationOrRollout`), logs loudly that the trigger itself must be created in the UI, and exits 0 — the same accepted trade-off as `release-08/start-guarded-rollout.sh`. The check stays honest (it looks for a real trigger via the list endpoint), so a skipped learner's Check will fail unless the operator decides the check should also accept the healed end-state. Operator call (open question 4).
- **Timing risk:** alert-window and cooldown options aren't enumerated in the docs, and the evaluation cadence isn't published. The 60–90 s heal target in the phase plan may not be reachable if the smallest window is a minute or more. The **Errors**-source trigger ("one alert per matching open error") is the most promising for a fast, deterministic fire. Capture the real option values in the click-through and tune then.
- Legacy **flag triggers** (webhook URL → `turnFlagOn`/`turnFlagOff`; stable API; provider resource) remain the "any external APM can flip a flag" cousin — one line in prose, not a lab.
- **Vega for auto-remediation** is a separate, adjacent thing: an AI agent that investigates alerts/errors/rollbacks and can open a GitHub PR with a code fix (read-only vs agent mode, toggled per alert). It is the "suggested change / PR" flavor the marketing copy describes. Worth one sentence in 07's wrap ("the trigger heals the symptom; Vega can draft the fix"), not a dependency.

**Decision for Phase 4, pending operator confirmation of entitlement: author 07 against adaptive triggers.** Fallback remains the app-side loop (poll error rate, `PATCH` targeting with `LD_API_TOKEN`) if the account turns out not to have the feature.

### 6. Baseline and infra implications

- `app/requirements.txt` gains `launchdarkly-observability==1.3.3`; VM image re-bake required. `app/.env.example` needs no new keys (no ingest key). Consider `OTEL_SERVICE_NAME`-style env knobs unnecessary — set `service_name` in the paste.
- `recommendations-strategy` (string: `bestsellers` / `personalized`) and `show-recommendations` (boolean) are plain provider resources (`launchdarkly_feature_flag` + `_environment`). The `/recommendations` paste block already exists in `server.py`; the personalized bug (`viewed["category"]` KeyError on `rollout-tote`) throws → FastAPI 500 → `app.js` hides the carousel. That is the right shape for both the error signal and the "user-visible breakage" beat.
- Traffic generator: every third shopper hits `/recommendations` with a random product; 1 in 8 of those is `rollout-tote`, so ~4 % of shoppers error when on `personalized`. Expect to bias `viewed` toward `rollout-tote` (or add a track-specific mode via env var) so both the Monitoring charts and the trigger threshold move inside a lab's time budget. Tune in Phase 2/4.
- Replaying Release solves for the baseline: 02 → 03 → 04 → 05 → 07 → 08 → 09 then re-enable `release-otto`. Suggest replaying 08 with the **targeted apply** (flag + metric + pastes) rather than the full module, so the baseline doesn't start a live guarded rollout on `otto-style`; measure total time in Phase 1.
- **Terraform provider:** v3 has gone GA since the Release Phase 0 pass — latest is 3.1.7; the 2.x line has continued to 2.30.4, which our `~> 2.30` pin picks up automatically. Nothing we use changed; keep the pin for all three tracks and record a single "upgrade to 3.x" polish item for later rather than mixing major versions across modules.

### 7. Answers to the scoping questions

1. **Observability SDK identity** — Python: `launchdarkly-observability` 1.3.3 / `ldobserve` plugin; JS: `@launchdarkly/observability` 1.2.1 (not used in the recommended plan). See §1.
2. **Auto-remediation shape** — managed **adaptive triggers**, stable REST for read/update/enable/disable; creation requires an alert that has no public API → UI-created, with the solve limited to end-state. See §5.
3. **Separate ingest key?** — **No.** The SDK key is the only credential; nothing new to thread through setup.
4. **Baseline startup time** — unchanged concern; measured in Phase 1.
5. **JS client participation** — **yes, both browser plugins are wired** (observability + session replay), per the operator's 2026-10-19 scope decision. See §1.

### 8. UI-only values the operator must capture (added to the click-through list)

- Autogenerated metric **keys** and display names as they appear in the Metrics list, and how long after the first error they appear.
- Adaptive trigger **Alert window**, **Cooldown**, and **Evaluation delay** option values; observed time from threshold breach to variation switch.
- Whether Python-side exceptions populate the flag **Monitoring → Errors** chart (vs. only Telemetry → Errors).
- Session-replay recording-to-visible latency, and whether the flag's **Monitoring → Sessions** chart groups sessions by `recommendations-strategy` variation with server-side evaluation alone or needs the client-side evaluation described in §1.
- Guarded rollout default duration/steps (shared with Release 08).

### 9. Open questions for the operator — ANSWERED 2026-10-19 (recorded in `DECISIONS.md`)

1. **Entitlement:** → **yes** — observability is enabled and the account has adaptive triggers (and Guardian).
2. **Browser plugin:** → **wire both browser plugins; session replay is added to the track's scope** as flag-scoped evidence of the broken release (folded into 03). `CLAUDE.md`, `NARRATIVE.md`, and the operator checklist updated.
3. **Real metric for 04/06:** → **the autogenerated User HTTP error rate** (`otel.http.error`), with the `track()`-fed custom metric as fallback; `recs-error-rate` stays as prose shorthand.
4. **07 solve-on-skip:** → **solve materializes the healed end-state only; the check still requires a real trigger.**
5. **Vega:** → **one-line mention in 07.**
