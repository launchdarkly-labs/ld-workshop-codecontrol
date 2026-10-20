# Instruqt reference (condensed, verified Oct 2026)

## Track directory layout

```
<track-slug>/
  track.yml                 # track metadata
  config.yml                # sandbox: hosts, virtual browsers, secrets
  track_scripts/
    setup-<hostname>        # runs once before the learner gets access (55 min timeout)
    cleanup-<hostname>      # runs when the track ends / idles out
  01-<challenge-slug>/      # numeric prefix sets order
    assignment.md           # frontmatter + markdown body
    setup-<hostname>        # before challenge starts (55 min)
    check-<hostname>        # on "Check" click (1 MINUTE timeout; exit 0 = pass)
    solve-<hostname>        # on "Skip" click; must leave state as if the learner did it
    cleanup-<hostname>      # after challenge completes
```

Scripts: any language, but bash is standard. Exit code 0 = success. Max 5 MB. Scripts
run as root on the host via the Instruqt agent, so they do NOT inherit ~/.profile —
source `/opt/ld/ld.env` for LaunchDarkly keys. If no check script exists the button
reads "Next" instead of "Check".

Do NOT put non-track files (image.sh, app source) inside the track directory.

## track.yml

```yaml
slug: my-track            # URL slug; immutable after first push
title: ...
teaser: ...               # one line, shown in catalog
description: |-          # markdown
  ...
icon: https://launchdarkly.com/favicon-dark-mode.png
tags: [launchdarkly]
owner: launchdarkly       # team slug
developers: [you@launchdarkly.com]
show_timer: true
idle_timeout: 1200        # seconds
timelimit: 7200           # seconds
lab_config:
  default_layout: AssignmentRight   # AssignmentLeft | AssignmentBottom
  default_layout_sidebar_size: 25
  override_challenge_layout: false
enhanced_loading: false
```

No `id:` is needed for a brand-new track; `instruqt track push` assigns ids to the
track, challenges, and tabs and writes them back into your files. Keep those ids
once they exist.

## config.yml

```yaml
version: "3"
virtualbrowsers:
- name: launchdarkly
  url: https://...?sandboxId=${_SANDBOX_ID}     # ${_SANDBOX_ID} is templated by Instruqt
virtualmachines:
- name: workstation
  image: launchdarkly/core-image                 # TEAM/IMAGE for Instruqt host images
  shell: /bin/bash
  machine_type: n1-standard-1
secrets:
- name: SECRET_NAME                              # injected as env var into ALL lifecycle scripts
```

Secrets are environment variables only during lifecycle scripts; they are not
visible in learner terminals. Never write LAUNCHDARKLY_ACCESS_TOKEN to disk.

## assignment.md frontmatter

```yaml
---
slug: toggle-a-flag
type: challenge
title: Toggle a flag
teaser: One line shown in the challenge list.
notes:                       # loading-screen cards shown during challenge setup
- type: text
  contents: |-
    Markdown allowed. Add 1-3 notes that prime the concept.
- type: image
  url: https://...
tabs:
- title: LaunchDarkly        # virtual browser (logs into the learner's LD project)
  type: browser
  hostname: launchdarkly
- title: Demo App            # anything listening on a port on a host
  type: service
  hostname: workstation
  port: 8000
  path: /                    # optional
  new_window: false          # optional; use true if the app refuses iframes
- title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/app       # optional
- title: Docs                # external site (must be https and iframe-friendly)
  type: website
  url: https://launchdarkly.com/docs
  new_window: true
- title: Files               # Instruqt's built-in simple editor (we use code-server instead)
  type: code
  hostname: workstation
  path: /opt/ld
difficulty: basic            # basic | intermediate | advanced | expert
timelimit: 600               # seconds for this challenge
---
```

Body is markdown. Supported extras:

- `[[ Instruqt-Var key="LD_PROJECT_KEY" hostname="workstation" ]]` renders a runtime
  variable set via `agent variable set LD_PROJECT_KEY <value>` in a lifecycle script.
- GitHub-style callouts `> [!NOTE]`, `> [!WARNING]`, `> [!TIP]` render as admonitions.
- Reference tabs in bold by their title: "In the **LaunchDarkly** tab, ...".

## Lifecycle script helpers and environment

- `fail-message "text"` in a check script prints `FAIL: text`, which Instruqt shows to
  the learner. Follow it with `exit 1`.
- `agent variable set KEY VALUE` / `agent variable get KEY` — per-sandbox runtime
  variables usable in assignments. Not for secrets.
- Injected env vars: `_SANDBOX_ID`, `INSTRUQT_TRACK_ID`, `INSTRUQT_TRACK_SLUG`,
  `INSTRUQT_CHALLENGE_ID`, `INSTRUQT_PARTICIPANT_ID`, `INSTRUQT_USER_ID`,
  `INSTRUQT_USER_NAME`, `INSTRUQT_USER_EMAIL` (last three may be empty).
- Track setup must wait for `/opt/instruqt/bootstrap/host-bootstrap-completed`.
- Pattern: `set -euo pipefail` at the top so a failed API call fails the script loudly.

## CLI

```bash
instruqt auth login                 # once
instruqt track validate             # structural checks, run from the track dir
instruqt track push                 # create/update remote; assigns ids on first push
instruqt track push --force         # overwrite remote edits made in the web UI
instruqt track open                 # open in browser
instruqt track logs                 # lifecycle script output from plays
instruqt track test                 # runs the track's lifecycle scripts end to end
instruqt challenge create --title "..."   # scaffold a new numbered challenge dir
instruqt track pull                 # fetch remote (e.g. to pick up ids / UI edits)
```

## Custom host images (where image.sh runs)

Instruqt host images (Settings -> Host images -> Create image): pick an Ubuntu base
image, open the terminal, run the image script as root, click Save. Reference it in
config.yml as `<team>/<image-name>`, e.g. `launchdarkly/my-track-image`.
Requirements: Google guest environment present (Ubuntu GCE bases have it), ports
15778/15779 open for the agent. Edit existing image: Host images -> image -> Edit.

Alternative: build in your own GCP project, create a disk image (NOT a machine image),
grant `instruqt-track@instruqt-prod.iam.gserviceaccount.com` the Compute Image User
role, reference as `<gcp-project>/<image-name>`.
