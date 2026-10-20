---
name: launchdarkly-instruqt-track
description: Build a complete Instruqt track for a LaunchDarkly workshop, lab, or demo - track.yml, config.yml, lifecycle scripts, challenge assignments, an optional demo web app, and the image.sh used to bake a custom VM image. Use when asked to create, scaffold, extend, or fix an Instruqt track/lab/workshop that uses LaunchDarkly.
argument-hint: "<what the track should teach, e.g. 'intro to targeting rules with a Python app, 4 challenges'>"
---

# LaunchDarkly Instruqt track builder

You are producing a deployable Instruqt track whose sandbox gets its own LaunchDarkly
project per learner. The infrastructure contract (Terraform, magic-login virtual
browser, secrets) is fixed; your job is the content: challenges, scripts, and the
demo app the learner interacts with.

`SKILL_DIR` below means the directory containing this SKILL.md (e.g.
`~/.claude/skills/launchdarkly-instruqt-track` or `<repo>/.claude/skills/launchdarkly-instruqt-track`). Everything you need is in:

- `SKILL_DIR/templates/track/` - track skeleton with placeholders (`__TRACK_SLUG__`, `__FLAG_KEY__`, ...)
- `SKILL_DIR/templates/image/` - `image.base.sh`, `app/` (Flask demo), `app-install.sh`, `build-image.sh`
- `SKILL_DIR/reference/instruqt.md` - file formats, tab types, script rules, CLI
- `SKILL_DIR/reference/launchdarkly.md` - what Terraform provisions, env vars, REST API + SDK snippets

Read both reference files before writing anything.

## Non-negotiables (do not change, remove, or "improve")

1. `config.yml` virtual browser named `launchdarkly` with URL exactly
   `https://l5vv6unuu4ycp6vt3bzlm6tczu0cyrqt.lambda-url.us-east-2.on.aws/?sandboxId=${_SANDBOX_ID}`
2. `config.yml` secrets: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `LAUNCHDARKLY_ACCESS_TOKEN`.
3. `track_scripts/setup-workstation` runs `terraform apply -auto-approve` in `/opt/ld/ld-workshop-participant`
   after writing `terraform.tfvars` with `sandbox_id`.
4. `track_scripts/cleanup-workstation` runs `terraform destroy -auto-approve` in `/opt/ld/ld-workshop-participant`.
5. `image.sh` must: clone `https://github.com/launchdarkly-labs/ld-workshop-participant.git` to `/opt/ld`,
   run `terraform init` there, install code-server on port 8080 rooted at `/opt/ld`, and ensure `python3` exists.

The templates already satisfy all five. Copy them; edit around them.

## Workflow

### 1. Pin down the brief

From the request (and `$ARGUMENTS`) decide:

- **Topic and audience** -> track title, slug (kebab-case, <= 40 chars), teaser, description.
- **Challenge list** - 3 to 6 is typical. Each challenge teaches ONE idea and ends with a
  verifiable state in LaunchDarkly (flag on, rule added, segment created, metric exists...).
  Default arc if none given: create a flag -> toggle it and see the app change ->
  target an individual -> add a rule on an attribute -> percentage rollout.
- **Does the learner need a running app?** Yes for almost anything about evaluation,
  targeting, or SDKs. No for pure UI/admin tracks (approvals, roles, audit log).
- **Language/SDK** - default to the bundled Python Flask app. Only build another stack if asked.
- **Developer email** for `track.yml` (`git config user.email` is a fine default; ask only if absent).

Do not stop to ask about things with sensible defaults. Ask only if the topic itself is
unclear, and then ask one compact question.

### 2. Scaffold the track

```bash
OUT=<where the user wants it, default ./>      # NOT inside SKILL_DIR
cp -R "$SKILL_DIR/templates/track" "$OUT/<track-slug>"
cd "$OUT/<track-slug>"
# fill placeholders in track.yml: __TRACK_SLUG__ __TRACK_TITLE__ __TRACK_TEASER__ __TRACK_DESCRIPTION__ __DEVELOPER_EMAIL__
# for each challenge N: cp -R 01-challenge-slug 0N-<challenge-slug>, then edit; finally rm -rf 01-challenge-slug
```

Challenge directories are `01-`, `02-`, ... in play order. Every script file must be
executable and start with `#!/bin/bash`. Leave `config.yml` and `track_scripts/`
unchanged except: set `image:` to the new host image name if (and only if) you bake an
app (step 4), and append to `track_scripts/setup-workstation` only if the whole track
needs shared state (e.g. a seed flag used by every challenge). Never shorten it.

### 3. Write each challenge

`assignment.md` frontmatter: no `id:` fields (Instruqt assigns them on first push).
Keep the four template tabs; drop `Demo App` when there is no app. Body conventions:

- Open with 1-2 sentences of why, then a numbered `## Steps` list naming the tab in
  bold for each action ("In the **LaunchDarkly** tab, ...").
- Show the project key with `[[ Instruqt-Var key="LD_PROJECT_KEY" hostname="workstation" ]]` when it helps.
- Use `> [!NOTE]` / `> [!TIP]` callouts sparingly. End with "Click **Check** when you are done."
- Add 1-3 `notes:` that preview the concept; they display while setup runs.
- `timelimit` per challenge 600-900 s; `difficulty` basic/intermediate/advanced.

Scripts (all `set -euo pipefail`, `source /opt/ld/ld.env`, API via `LAUNCHDARKLY_ACCESS_TOKEN`):

- `setup-workstation`: create prerequisites via REST API, idempotently (409 = fine).
  If a challenge changes which flag drives the app's featured card, write
  `FEATURE_FLAG_KEY=<key>` into `/opt/ld/ld.env` and `systemctl restart ld-app`.
- `check-workstation`: read the API (1 min timeout, so 1-2 calls), compare, and on
  failure call `fail-message "<specific, actionable hint>"` then `exit 1`.
- `solve-workstation`: achieve the same end state via semantic patch so later
  challenges work when a learner skips. Every challenge with a check needs a solve.
- `cleanup-workstation`: usually just `exit 0`.

Use the recipes in `reference/launchdarkly.md`. Verify every flag key, variation
index, and attribute name is consistent across assignment text, scripts, and app code.

### 4. The demo app and image (when an app is needed)

```bash
cp -R "$SKILL_DIR/templates/image" "$OUT/image"
```

- Customize `image/app/` for the brief: flag keys, context attributes
  (`CONTEXT_ATTRIBUTES` in `app.py`), copy in `templates/index.html`, extra routes.
  Keep the contract the track scripts rely on: app at `/opt/ld/app`, systemd unit
  `ld-app.service`, keys from `/opt/ld/ld.env`, listens on `PORT` (8000), `/healthz`.
  Keep it small and readable - learners open it in the Code Editor tab.
- If the brief needs a client-side (JS SDK) demo, the image vendors
  `/static/ldclient.min.js`; pass `client_side_id` into the page (already in `index.html`
  context) and use `LDClient.initialize(...)`. Never put `LD_SDK_KEY` in the browser.
- Another language: replace `app/` and the install lines in `app-install.sh` (runtime
  install + `ExecStart`), keep the unit name, env file, and port.
- Run `image/build-image.sh`. It assembles a self-contained `image/image.sh` from
  `image.base.sh` + every file in `app/` (as heredocs) + `app-install.sh` and runs `bash -n`.
  Re-run it after every change to `app/`. `image.sh` is what gets executed on the host image.
- Set `config.yml` -> `image: launchdarkly/<track-slug>-image` and tell the user to build
  that host image from `image/image.sh` (Instruqt: Settings -> Host images -> Create image
  -> Ubuntu base -> run the script in the terminal -> Save).

No app needed: skip this step entirely, keep `image: launchdarkly/core-image`, and remove
the `Demo App` tab from every assignment.

### 5. Verify before handing over

```bash
cd "$OUT/<track-slug>"
for f in track_scripts/* */*-workstation; do bash -n "$f" || exit 1; done
ls -l track_scripts/* */*-workstation            # all executable
grep -rn "__[A-Z_]*__" . && echo "UNFILLED PLACEHOLDERS"   # must print nothing
instruqt track validate
```

If an app was built:
```bash
cd "$OUT/image/app" && python3 -m venv /tmp/ldapp && /tmp/ldapp/bin/pip install -q -r requirements.txt \
  && PORT=8765 /tmp/ldapp/bin/python app.py &   # then: curl -fs localhost:8765/healthz ; curl -fs localhost:8765/ >/dev/null ; kill %1
cd "$OUT/image" && ./build-image.sh && bash -n image.sh
```
Also test with a real key if the user has one in the environment (`LD_SDK_KEY`); the page
should list flags under "All flags for this context".

Cross-check once more: flag keys in assignments == scripts == `FEATURE_FLAG_KEY`; every
challenge dir has `assignment.md`; `config.yml` image name matches what you told the user
to build; the five non-negotiables are intact (`grep` for the Lambda URL, the four secret
names, `terraform apply`, `terraform destroy`, `git clone .*ld-workshop-participant`,
`terraform init`, `code-server`).

### 6. Hand over

Report, in this order: where the files are; the challenge list in one line each; what
the learner sees in each tab; exact next steps:

1. (if app) Build host image `launchdarkly/<track-slug>-image` from `image/image.sh`.
2. `instruqt auth login` (once), then from the track dir `instruqt track validate && instruqt track push`.
3. `instruqt track open`, play it once, watch `instruqt track logs` for script failures.

Flag anything you could not verify locally (host image build, `terraform apply`, the
LaunchDarkly API calls) as unverified rather than claiming it works.
