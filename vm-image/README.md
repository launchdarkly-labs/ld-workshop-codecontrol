# VM image build — operator handoff

This directory holds the *inputs* for the single VM image shared by all three
CodeControl tracks (Release, Observability, Iterate). A human bakes the image
and registers it with Instruqt; Claude Code only maintains what's in this
repo (see "Things Claude Code does not own" in `CLAUDE.md`).

**Image name:** `launchdarkly/workshop-codecontrol` — must match the
`virtualmachines.image` value in every track's `config.yml`.

**Contents of this directory** (shape set by the `launchdarkly-instruqt-track` skill):

| File | Purpose |
|---|---|
| `image.base.sh` | Skill-contract base, do not edit around the REQUIRED markers: tools (Terraform via the HashiCorp apt repo, python3), clone + `terraform init` of `ld-workshop-participant` at `/opt/ld`, code-server on :8080 rooted at `/opt/ld`. |
| `app-install.sh` | This workshop's half: places the repo at `/opt/ld/codecontrol` (git clone, or `SOURCE_DIR` copy), builds the venv at `/opt/ld/venv`, pre-inits every Terraform module through a shared plugin cache, installs and enables the ToggleWear units. |
| `build-image.sh` | Assembles `image.sh` from the two files above and `bash -n`s it. Re-run after editing either. |
| `image.sh` | **Generated.** What the operator runs on the Instruqt host image. Committed so the bake needs nothing but this one file. |
| `systemd/togglewear.service` | The storefront on :3000 (enabled at boot). |
| `systemd/togglewear-traffic.service` | Synthetic shopper traffic (installed, disabled; labs start it). |
| `verify-image.sh` | Post-bake checks; run before saving the image. |

Sizing note: `machine_type: n1-standard-1` is declared in `config.yml` — the
app is a single FastAPI process with no LLM, so this should suffice; confirm
during the first bake (the observability plugin adds OpenTelemetry threads
but little CPU).

## How to build

1. **Instruqt: Settings → Host images → Create image**, pick an Ubuntu 24.04
   base, and open its terminal as root (`sudo -i`).
2. **Point `app-install.sh` at the source** and re-run `./build-image.sh`:
   either set `REPO_URL` / `REPO_REF` to the commit you want baked, or —
   while this repo has no remote — `scp` a checkout to the VM and export
   `SOURCE_DIR=/path/to/checkout` before running (it copies only the
   directories the VM needs and never `.git`).
3. **Run `image.sh`** (paste it, or `scp` it and `bash image.sh`). It stops
   on the first failure. Expect several minutes; the venv pulls ~180 MB of
   OpenTelemetry packages for the observability plugin.
4. **Run `/opt/ld/codecontrol/vm-image/verify-image.sh`.** Every line must
   read `OK`; the last line says "save the image."
5. **Click Save** in the Instruqt console and name the image
   `launchdarkly/workshop-codecontrol` (or a suffixed name, updating every
   track's `config.yml` to match, so labs in flight keep their current image).

Re-bake whenever `app/requirements.txt`, a unit file, an apt dependency, or
— because setup scripts don't `git pull` at lab start — any `instruqt-*/`
script, assignment, paste file, or Terraform module changes. The
`.remote` files the Instruqt CLI generates on publish are never baked.

## What the image contains

### Skill contract (`image.base.sh`)

- Ubuntu 24.04 (noble); system `python3` 3.12 (the participant Terraform runs a
  python3 external data source; the LD SDK needs >= 3.10).
- `terraform` from the HashiCorp apt repo, `jq`, `curl`, `git`, `unzip`, `vim`.
- `/opt/ld/ld-workshop-participant`: clone of
  `launchdarkly-labs/ld-workshop-participant`, `terraform init` already run.
  Track setup applies it per sandbox; track cleanup destroys it.
- code-server on :8080, `--auth none`, as root, rooted at `/opt/ld` (so the
  Code Editor tab shows both `codecontrol/` and `ld-workshop-participant/`).

### This workshop (`app-install.sh`)

```
/opt/ld/codecontrol/
├── app/                    # ToggleWear app (app/.env seeded from .env.example)
├── terraform/              # lib/, observability-baseline/, per-challenge solve modules
├── traffic-generator/      # synthetic traffic scripts
├── instruqt-release/       # the three tracks — baked only so later tracks can call
├── instruqt-observability/ #   earlier tracks' solve-workstation scripts
├── instruqt-iterate/
└── vm-image/               # for verify-image.sh
/opt/ld/venv                # one venv: app + generators, incl. launchdarkly-observability
/opt/ld/terraform-plugin-cache   # shared provider cache; every module is pre-inited
/opt/ld/traffic.env         # optional traffic profile (empty = generator defaults)
```

Services: `togglewear.service` (uvicorn `--reload` on :3000, enabled) and
`togglewear-traffic.service` (installed, disabled; labs start it via
`terraform/lib/traffic.sh`). `--reload` matters: learners paste into
`server.py` and the server picks it up on save; it does not re-read `.env`,
so track scripts `stop`/`start` the service after rewriting it.

Egress: once instrumented, the app sends telemetry over gRPC to
`otel.observability.app.launchdarkly.com:4317` and fetches config from
`pub.observability.app.launchdarkly.com:443`; browser plugins use the same
hosts over HTTPS. If a network blocks 4317, uncomment the
`OTEL_EXPORTER_OTLP_ENDPOINT` line in `systemd/togglewear.service`.

### Written at lab start, never baked

`/opt/ld/ld.env` (project/env/SDK/client keys for lifecycle scripts),
`app/.env` values, the scoped `LD_API_TOKEN`, and the sandbox's LaunchDarkly
project itself. `LAUNCHDARKLY_ACCESS_TOKEN` and the AWS secrets arrive from
Instruqt only inside lifecycle scripts and are never written to disk.

## Handoff checklist

1. Build the image from `image.sh` as described above.
2. Run `/opt/ld/codecontrol/vm-image/verify-image.sh` on the VM; every line
   must read `OK`.
3. Save it as `launchdarkly/workshop-codecontrol`.
4. From each track directory: `instruqt track validate && instruqt track push`,
   then `instruqt track open`, play it, and watch `instruqt track logs`.
   The first push writes `id:` fields into the files — commit them.
5. Confirm each track-level `setup-workstation` stays near the ~60s budget
   (the Observability and Iterate ones log `[setup +Ns]` per step). If it
   runs long, the fallback is pre-baking the post-Release LaunchDarkly state
   into the image — raise it with the workshop owner rather than trimming
   the replay.
