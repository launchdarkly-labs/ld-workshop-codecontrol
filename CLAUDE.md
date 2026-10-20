# CLAUDE.md

This file is the operational spec for Claude Code working on this project. Read it before doing anything else. When in doubt about *why* a decision was made, see `DECISIONS.md`. To know *what phase* of work we're in for a given track, see that track's `PHASES-<track>.md`. For the story and voice used in learner-facing prose, see `NARRATIVE.md`.

## What we're building

A three-track **Instruqt workshop** teaching LaunchDarkly's **CodeControl** product through hands-on labs. CodeControl is the non-agent half of the LaunchDarkly platform — feature flags, progressive delivery, guarded releases, release observability, and experimentation. (The agent half, AgentControl, is out of scope here; it has its own workshop.)

The workshop introduces CodeControl to:

1. Developers **new to LaunchDarkly** who are evaluating the platform.
2. Developers with light LD exposure who want a structured, hands-on path through the CodeControl surface.

**This is the important audience difference from the AgentControl workshop.** That workshop assumed LaunchDarkly fundamentals were already known and refused to re-teach flags, contexts, and environments. **This workshop assumes no LaunchDarkly knowledge.** The Release track teaches the fundamentals from zero, and the later tracks build on that foundation. Do not skip or hand-wave the basics.

**Three sibling tracks:**

- **Release (Track 1)** — `instruqt-release/`. Feature-flag fundamentals through a guarded release with automatic rollback. This is the foundation track; it teaches projects, flags, contexts, targeting, segments, SDK wiring, progressive rollout, guarded releases, and the kill switch. Ship Otto (the chat widget) safely.
- **Observability (Track 2)** — `instruqt-observability/`. Release-scoped observability: error monitoring attributed to releases, session replay of the broken experience, release health metrics, guarded releases driven by real instrumented metrics, and auto-remediation / self-healing. Scoped deliberately narrow (see below). Anchored on a new "Recommended for You" storefront feature.
- **Iterate (Track 3)** — `instruqt-iterate/`. Experimentation: metrics, A/B experiments, reading results, promoting a winner, and multi-armed bandits. Also anchored on the recommendations feature.

The three tracks share a single VM image and the `app/`, `terraform/student-bootstrap/`, `traffic-generator/`, and `vm-image/` directories. Each later track's `setup-workstation` runs prior-track solve scripts to materialize the starting state, so a learner can land in any track and arrive at a known-good baseline. Every track is deliverable on its own — Tracks 2 and 3 open with a recap challenge that re-establishes context for a learner who didn't just finish the previous track.

**Per-track format:** roughly 6–8 substantive hands-on labs plus a welcome, one quiz interstitial, and a wrap-up. Designed to run in ~2 hours each with a presenter delivering slide-based lecture between labs, or ~1 hour self-paced. Current challenge counts: Release = 10, Observability = 8, Iterate = 8.

**Lecture content lives in slides, not in the tracks.** Do not embed conceptual exposition in `assignment.md` files beyond what a self-paced learner needs to make sense of each step. Because the audience is new to LD, the `assignment.md` prose carries slightly more orientation than the AgentControl workshop's did — but concept teaching is still the presenter's/slides' job.

## The reference track and reference workshop

Each of our three tracks mirrors the structure and conventions of two things:

1. The public **"01-release" basics track** at `launchdarkly-labs/launchdarkly-workshops/launchdarkly-basics/instruqt/01-release`. This is the canonical reference for voice, specificity, and copy-paste-first coding. If you can read it, do so before scaffolding.
2. The **AgentControl intro workshop** (`launchdarkly-labs/ld-workshop-ai-configs-intro`), which established the repo layout, the planning-artifact set (this file, `DECISIONS.md`, `NARRATIVE.md`, per-track `PHASES-*.md`, per-track `OPERATOR-CHECKLIST-*.md`), the marker-based `server.py` paste pattern, the per-challenge Terraform solve model, and the single-shared-VM-image approach. We inherit those conventions wholesale except where this file or `DECISIONS.md` overrides them.

## Repository layout

```
ld-workshop-codecontrol/
├── CLAUDE.md                       # this file
├── DECISIONS.md                    # why decisions were made
├── NARRATIVE.md                    # ToggleWear story, brand, voice, feature specs
├── PHASES-release.md               # build sequence for Track 1 (Release)
├── PHASES-observability.md         # build sequence for Track 2 (Observability)
├── PHASES-iterate.md               # build sequence for Track 3 (Iterate)
├── OPERATOR-CHECKLIST-release.md   # live-UI verification items for Track 1
├── OPERATOR-CHECKLIST-observability.md
├── OPERATOR-CHECKLIST-iterate.md
├── instruqt-release/               # Track 1 — Release
│   ├── track.yml
│   ├── config.yml
│   ├── track_scripts/
│   │   ├── setup-workstation
│   │   └── cleanup-workstation
│   ├── 01-welcome/
│   ├── 02-your-first-flag/
│   ├── 03-wire-up-the-sdk/
│   ├── 04-contexts-and-targeting/
│   ├── 05-segments/
│   ├── 06-quiz-flags-and-targeting/
│   ├── 07-progressive-rollout/
│   ├── 08-guarded-release/
│   ├── 09-kill-switch/
│   ├── 10-wrap-up/
│   └── assets/                     # images referenced from assignment.md
├── instruqt-observability/         # Track 2 — Observability
│   ├── track.yml
│   ├── config.yml
│   ├── track_scripts/
│   ├── 01-welcome-recap/
│   ├── 02-instrument-for-errors/
│   ├── 03-errors-in-context/
│   ├── 04-release-monitoring/
│   ├── 05-quiz-release-health/
│   ├── 06-guarded-release-real-metrics/
│   ├── 07-auto-remediation/
│   ├── 08-wrap-up/
│   └── assets/
├── instruqt-iterate/               # Track 3 — Iterate
│   ├── track.yml
│   ├── config.yml
│   ├── track_scripts/
│   ├── 01-welcome-recap/
│   ├── 02-your-first-metric/
│   ├── 03-design-an-experiment/
│   ├── 04-run-and-read/
│   ├── 05-quiz-experiments/
│   ├── 06-promote-the-winner/
│   ├── 07-multi-armed-bandit/
│   ├── 08-wrap-up/
│   └── assets/
├── app/                            # shared ToggleWear app, baked into the single VM image
│   ├── server.py                   # FastAPI server (also serves the static frontend)
│   ├── static/
│   │   ├── index.html
│   │   ├── app.js
│   │   └── style.css
│   ├── requirements.txt
│   └── .env.example
├── terraform/                      # Terraform modules for per-challenge solve scripts
│   ├── student-bootstrap/          # project + environment + base resources (root setup)
│   ├── release-02/ … release-09/   # Release challenge solves
│   ├── observability-02/ …         # Observability challenge solves
│   └── iterate-02/ …               # Iterate challenge solves
├── traffic-generator/              # scripts run by per-challenge setup
│   └── generate_traffic.py
└── vm-image/                       # inputs for baking the single shared VM image
    ├── README.md                   # build instructions for the operator
    └── build-image.sh
```

Terraform module directories are named per-track (`release-NN`, `observability-NN`, `iterate-NN`) matching the challenge numbers. Only substantive challenges that create or mutate LD resources get a module; welcome/quiz/wrap-up challenges do not.

## Instruqt conventions

These are non-negotiable unless explicitly overridden in `DECISIONS.md`.

### Challenges start at `01`, never `00`

**Instruqt ignores a challenge numbered `00`.** Every track's first challenge is `01-welcome` (or `01-welcome-recap`). Do not create a `00-` challenge folder. This differs from the AgentControl workshop, which used `00-welcome` — that is a known issue there, not a pattern to copy. Number sequentially from `01`.

### File pairs: `.remote` mirrors

Every challenge has files like `assignment.md`, `setup-workstation`, `check-workstation`, `solve-workstation`. Each gets a `.remote` sibling when published. **The `.remote` files are auto-generated by the Instruqt CLI on publish. Author only the non-`.remote` version. Do not create `.remote` files yourself.**

### Challenge folder structure

Each substantive challenge folder contains:
- `assignment.md` — learner-facing instructions, front-matter YAML at top
- `setup-workstation` — shell script, runs when the challenge starts
- `check-workstation` — shell script, runs when the learner clicks "Check"; exits non-zero with `fail-message` on failure
- `solve-workstation` — shell script, runs if the learner clicks "Skip"; must leave the workstation in the same state a successful learner would

Welcome, recap, quiz, and wrap-up challenges have only `assignment.md` (no scripts), or trivial empty scripts if the reference track requires them.

### `assignment.md` front-matter

```yaml
---
slug: kebab-case-slug
id: <12-char random alphanumeric>
type: challenge          # or "quiz"
title: Human Title
teaser: One-sentence summary
notes:
- type: text
  contents: One-paragraph framing the learner sees before starting.
tabs:
- id: <12-char random>
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: <12-char random>
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: <12-char random>
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 600           # seconds; 900-1200 for code-touching labs
enhanced_loading: null
---
```

Use the three-tab layout above for every challenge. Tab IDs are random 12-character alphanumeric strings; generate fresh ones per challenge.

### `assignment.md` body voice

- Short directive prose. Numbered click-by-click steps.
- Exact text the learner types or pastes goes in fenced code blocks — code is always a **clean copy-paste**, never something the learner has to write from scratch. The point of the code is to show how CodeControl is wired (flag evaluation, context construction, metric/event emission, error instrumentation, SDK setup), not to test the learner's coding.
- Reasoning lives in section intros, not mid-step.
- Sections delimited by `# Heading` (H1).
- Reference tabs by index: `[Code Editor](#tab-2)`, `[LaunchDarkly](#tab-0)`, `[ToggleWear](#tab-1)`. Tab indices are 0-based and match the order in front-matter.
- See `NARRATIVE.md` for tone and the ToggleWear storyline.
- Because the audience is new to LD, the first time a concept appears (a flag, a context, a segment) the section intro gives a one- or two-sentence plain-language definition. This is orientation, not a lecture — keep it to a couple of sentences and let the slides carry the depth.

### Setup scripts

Setup scripts run as root on the workstation. Typical pattern: clone or pull a per-challenge Terraform module, seed `terraform.tfvars` with the project key, `terraform init`. **Setup scripts do NOT apply Terraform — `solve-workstation` does.** Setup may pre-create supporting infrastructure the learner needs to find pre-built, or start a traffic generator.

### Check scripts

Check scripts validate the learner's work by hitting the LaunchDarkly REST API with `curl` and `jq`, using `fail-message "..."` to give specific guidance, then `exit 1` on failure and `exit 0` on success. **Verify the current endpoint shape in the LaunchDarkly API docs before writing checks. Do not invent endpoints.** Reference the public 01-release track's `check-workstation` files for the idiom.

### Solve scripts

Solve scripts apply the per-challenge Terraform module to materialize the resources the learner would have created. Keep them dead-simple: `cd` into the module directory, `terraform apply -auto-approve`, `exit 0`.

### `track.yml` and `config.yml`

`config.yml` declares the virtual browser (the LaunchDarkly IdP simulator lambda — same one the reference tracks point at), the VM, and required secrets. Because we dropped the LLM provider (see `DECISIONS.md`), the **only** secret this workshop needs is `LAUNCHDARKLY_ACCESS_TOKEN`. There is no AWS, no Bedrock, no GCP federation.

There are **two** LaunchDarkly credential pathways, separated by security boundary — do not conflate them:

- **`LAUNCHDARKLY_ACCESS_TOKEN` (Instruqt secret)** — the operator's master API token. Available in the environment of `setup-workstation` / `check-workstation` / `solve-workstation` scripts and Terraform `local-exec` blocks. **Never** written into `app/.env` or anywhere the participant's app or shell can read it.
- **`LD_API_TOKEN` (minted per lab session)** — a scoped LaunchDarkly API token created at track-level `setup-workstation` time by exchanging the operator token via `POST /api/v2/tokens`, with an inline role restricting it to the participant's project (`proj/<key>` and `proj/<key>:*`). Written into `app/.env` so the ToggleWear service can make runtime REST calls (e.g. the auto-remediation flag flip in Observability). Safe to expose because the blast radius is a sandbox project destroyed at cleanup.

Runtime code in `app/` and `traffic-generator/` reads only `LD_API_TOKEN`. Anywhere `LAUNCHDARKLY_ACCESS_TOKEN` appears, it must be in operator-context code.

`track.yml` declares slug, ID, title, teaser, description, owner, time limit (7200 = 2hr), and lab config. Use `default_layout: AssignmentRight` and `default_layout_sidebar_size: 25` to match the reference.

### Track-level setup script

The track-level `track_scripts/setup-workstation` runs once when the lab starts. For **Release** it:
1. Applies `terraform/student-bootstrap/` to create the LD project and `test` environment.
2. Pulls the SDK key, client key, and project key from the LD API.
3. Mints the scoped `LD_API_TOKEN`.
4. Writes keys to `~/.profile`, `~/.bashrc`, and `app/.env`.
5. Restarts the ToggleWear service.

For **Observability** and **Iterate**, the track-level setup does all of the above, then applies the prior track's solve modules in order to materialize the baseline state (Otto shipped and rolled out; SDK wired; for Iterate, optionally the observability instrumentation too). Time this: if applying prior solves pushes startup past ~60s, escalate to the operator about pre-baking the baseline state into the VM image instead. (This is the same trade-off the AgentControl Evaluate track flagged.)

## Tech stack — pinned versions

When implementing, **verify the latest stable version** of each before pinning. Do not assume training-data knowledge of version numbers is current. Pin versions in `requirements.txt` and in `terraform { required_providers { ... } }` blocks.

- **Python** — use the VM image's system `python3` (Ubuntu 24.04 noble ships 3.12). Verify the LD SDKs' minimum version and confirm 3.12 satisfies it.
- **FastAPI** + **uvicorn** for the server.
- **launchdarkly-server-sdk** (Python) — for flag evaluation and `track` events server-side.
- **LaunchDarkly observability SDK** — for the Observability track's error/metric instrumentation. Verified 2026-10-19 (see `PHASES-observability.md` Phase 0 notes): Python server plugin `launchdarkly-observability` (import `ldobserve`), browser plugins `@launchdarkly/observability` and `@launchdarkly/session-replay` (vendored UMD builds, like the client SDK). Re-verify versions before pinning.
- **launchdarkly-js-client-sdk** (browser) — for client-side flag evaluation driving show/hide of Otto and the recommendations carousel.
- **Vanilla JavaScript** for the frontend — no React, no Vue, no build step.
- **Terraform** with the `launchdarkly/launchdarkly` provider — verify the current provider version and which resources it supports (flags, environments, segments, metrics, experiments, guarded rollouts). Where the provider lacks a resource, fall back to the REST API via `null_resource` + `local-exec curl`, and record the gap in the relevant `PHASES-<track>.md` Phase 0 notes.

There is **no LLM provider dependency.** Otto is a mock: `server.py` returns canned responses from a small scripted set. This removes Bedrock, boto3, AWS credentials, and the GCP-federation apparatus entirely.

## Out of scope

Things this workshop must **not** do:

- **AgentControl / AI Configs.** No judges, no agent-mode Configs, no prompt snippets, no LLM evaluation. That's the other workshop.
- **A real LLM.** Otto returns canned responses. No Bedrock, no OpenAI, no Anthropic-direct.
- **Broad observability beyond releases.** No distributed tracing UI, no log aggregation/search, no general APM. The Observability track covers *only* release-scoped observability: errors attributed to a release, session replay scoped to a flag variation (watching the session where the feature broke), release health metrics, guarded releases on real metrics, and auto-remediation. Session replay is in scope **only** as flag-scoped evidence of a broken release (decided 2026-10-19; see `DECISIONS.md`) — not as a general UX-analytics tour. If a step tempts you toward trace waterfalls, log search, or rage-click analytics, stop — it's out of scope.
- **Commerce.** No cart, checkout, authentication, or payment. The app is a storefront shell that hosts flaggable features.
- **Re-using the legacy Toggle Outfitters / `talkin-ship-workshop-app` code.** Fresh codebase, copied from the AgentControl workshop's `app/` and stripped of AI-Config wiring.

## Things Claude Code does not own

- **The VM image build itself.** Claude Code produces the *inputs* (Packer/Docker config, app source, install scripts, systemd unit files) in `vm-image/`. A human bakes the image and registers it with Instruqt.
- **The LaunchDarkly IdP simulator lambda.** Already exists; URL is in the reference track's `config.yml`. We point at the same lambda.
- **Publishing to Instruqt.** Done via the Instruqt CLI by a human.

Document all handoff points clearly in `vm-image/README.md`.

## Working agreement with the human operator

- **Work one phase at a time.** Read the relevant `PHASES-<track>.md`. Pick the current phase. Complete it. Stop. Wait for review before the next phase.
- **When a decision arises that isn't in `DECISIONS.md`, ask the operator.** Do not invent product/UX/architectural decisions silently. Record the answer in `DECISIONS.md` when you proceed.
- **Verify, don't assume.** Before writing code that calls a specific API, library, or product feature, web-search the current LaunchDarkly docs. Guarded releases, release observability, and auto-remediation are actively evolving; API shapes and SDK ergonomics may have changed since this file was written.
- **Don't ship the `.remote` files.**
- **Don't reformat the reference conventions for "consistency."** The public 01-release track lands well with learners; match it even where a pattern looks suboptimal.

## UI instructions in assignment.md are drafts pending operator verification

Claude Code cannot drive a browser and cannot click through the LaunchDarkly UI to verify flows. UI-specific instructions in `assignment.md` files (button labels, menu paths, step ordering, dialog field names) are **drafts based on reading the public LaunchDarkly docs**, not verified facts. The operator walks through each flow with the draft open and marks corrections during phase review.

- Base click-by-click steps on the current LaunchDarkly CodeControl docs (web-search to confirm) and mirror the reference voice. Be specific (bold button labels, numbered steps) — the operator needs concrete drafts to verify, not vague hedges.
- **Do not invent UI elements.** If the docs don't make a step clear, write the step as best you can and add a `<!-- VERIFY: <what to check> -->` HTML comment flagging what the operator should confirm.
- **Do not generate screenshots.** Image references point to placeholder filenames in the track's `assets/` directory (e.g. `assets/rel-02-create-flag.png`) that the operator populates after verifying. List expected screenshots in each phase's deliverables.
- **API-driven checks are not UI-driven.** `check-workstation` scripts hit the REST API and don't depend on UI-flow accuracy. Write them confidently from authoritative API docs.
- When a step is genuinely uncertain (docs don't cover it, or the feature is too new for stable docs), surface the uncertainty in the phase summary rather than writing a confident-sounding guess.

## Definition of done for the project

Each track is done when:

1. A presenter can deliver the 2-hour version with slide breaks and have every lab complete successfully.
2. A self-paced learner can complete all labs in ~1 hour following only `assignment.md` prose.
3. Every substantive challenge's `solve-workstation` produces the correct end-state.
4. Every `check-workstation` correctly passes valid completions and fails common mistakes with helpful `fail-message` output.
5. The track is deliverable standalone — its track-level setup materializes the correct baseline, and (for Observability and Iterate) the recap challenge re-establishes context.
6. The VM image build inputs in `vm-image/` produce a working image when followed by a human operator.
7. `DECISIONS.md` records every meaningful decision; `NARRATIVE.md` keeps ToggleWear's voice and feature specs consistent across all three tracks.
