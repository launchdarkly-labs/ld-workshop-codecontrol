# LaunchDarkly reference for Instruqt tracks

## What the sandbox gets (from terraform apply in track setup)

`/opt/ld/ld-workshop-participant` (github.com/launchdarkly-labs/ld-workshop-participant)
creates, per sandbox:

- A LaunchDarkly **project** with a random-pet key (e.g. `brave-otter`), name
  `instruqt-workshop - <key>`, tagged `workshop-org`, `terraform`.
- One **environment**: key `test`, name `Test`. Flags default to client-side
  available (`using_environment_id = true`, `using_mobile_key = true`).
- A **team member** `instruqt+<key>@launchdarkly.com` with a custom role granting
  full access to that project only, plus a signed magic login URL stored in
  DynamoDB keyed by `_SANDBOX_ID`. The `launchdarkly` virtual browser's Lambda URL
  reads that record and logs the learner in. This is why the browser URL must not change.
- `terraform output -json | jq '.students.value[0]'` ->
  `project_id, project_key, project_name, student_email, login_email, login_expires_at, login_url`.

Terraform state is local to `/opt/ld/ld-workshop-participant`, so `terraform destroy`
in track cleanup MUST run from that directory.

## Environment variables available after track setup

| Variable          | Where                                        | Meaning                                  |
|-------------------|----------------------------------------------|------------------------------------------|
| `LD_PROJECT_KEY`  | ~/.profile, ~/.bashrc, /opt/ld/ld.env, agent var | project key                          |
| `LD_ENV_KEY`      | same                                         | `test`                                   |
| `LD_SDK_KEY`      | same                                         | server-side SDK key (`sdk-...`)          |
| `LD_CLIENT_KEY`   | same                                         | client-side ID (environment `_id`)       |
| `LAUNCHDARKLY_ACCESS_TOKEN` | lifecycle scripts only (Instruqt secret) | REST API token, org-wide. Never persist. |

Lifecycle scripts: `source /opt/ld/ld.env`. Assignments:
`[[ Instruqt-Var key="LD_PROJECT_KEY" hostname="workstation" ]]`.

## REST API cheat sheet (base `https://app.launchdarkly.com/api/v2`)

Header is `Authorization: <token>` (no `Bearer`). Set `AUTH=(-H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" -H "Content-Type: application/json")`.

Environment keys:
```bash
curl -fsS "$LD_API/projects/$LD_PROJECT_KEY/environments/test" "${AUTH[@]}" | jq '{_id, apiKey, mobileKey}'
```

Create a boolean flag (201 created, 409 already exists -> treat as success):
```bash
curl -s -o /dev/null -w '%{http_code}' -X POST "$LD_API/flags/$LD_PROJECT_KEY" "${AUTH[@]}" -d '{
  "key": "new-feature", "name": "New Feature", "description": "...",
  "variations": [{"value": true, "name": "On"}, {"value": false, "name": "Off"}],
  "defaults": {"onVariation": 0, "offVariation": 1},
  "clientSideAvailability": {"usingEnvironmentId": true, "usingMobileKey": false},
  "tags": ["workshop"]
}'
```
String/number/JSON flags: set `"kind": "multivariate"` and list variations with values
of that type, e.g. `{"value": "control"}, {"value": "treatment"}`.

Read flag state in an environment:
```bash
curl -fsS "$LD_API/flags/$LD_PROJECT_KEY/new-feature?env=test" "${AUTH[@]}" \
  | jq '.environments.test | {on, fallthrough, rules, targets, contextTargets, offVariation}'
```

Semantic patch (preferred for solve scripts and targeted checks). Header:
`-H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch"`,
method PATCH on `$LD_API/flags/$LD_PROJECT_KEY/<flag>`, body
`{"environmentKey": "test", "instructions": [ ... ]}`. Useful instructions:

```json
{"kind": "turnFlagOn"}                      {"kind": "turnFlagOff"}
{"kind": "addTargets", "variationId": "<id>", "contextKind": "user", "values": ["alice"]}
{"kind": "addRule", "variationId": "<id>", "clauses": [
   {"contextKind": "user", "attribute": "country", "op": "in", "values": ["US"], "negate": false}]}
{"kind": "updateFallthroughVariationOrRollout", "variationId": "<id>"}
{"kind": "updateFallthroughVariationOrRollout", "rolloutWeights": {"<idA>": 50000, "<idB>": 50000}, "rolloutContextKind": "user"}
{"kind": "addPrerequisite", "key": "other-flag", "variationId": "<id>"}
```
Variation ids: `jq -r '.variations[] | select(.value==true) | ._id'` on the flag JSON.

Segments:
```bash
curl -fsS -X POST "$LD_API/segments/$LD_PROJECT_KEY/test" "${AUTH[@]}" \
  -d '{"key": "beta-users", "name": "Beta users", "tags": ["workshop"]}'
# add members: PATCH $LD_API/segments/$LD_PROJECT_KEY/test/beta-users (semantic patch, kind "addIncludedUsers"/"addIncludedTargets")
```

Metrics (for experimentation tracks):
```bash
curl -fsS -X POST "$LD_API/metrics/$LD_PROJECT_KEY" "${AUTH[@]}" \
  -d '{"key": "checkout-click", "name": "Checkout click", "kind": "custom", "eventKey": "checkout-click", "isNumeric": false, "unitAggregationType": "sum"}'
```

Delete a flag: `DELETE $LD_API/flags/$LD_PROJECT_KEY/<flag>`.

Check-script idioms (1 min timeout, so one or two API calls max):
```bash
on=$(curl -fsS "$LD_API/flags/$LD_PROJECT_KEY/$F?env=test" "${AUTH[@]}" | jq -r '.environments.test.on')
rules=$(curl -fsS ... | jq '.environments.test.rules | length')
has_target=$(curl -fsS ... | jq -r '[.environments.test.contextTargets[]?.values[]?, .environments.test.targets[]?.values[]?] | index("alice") != null')
```

## SDK snippets

Python server SDK (`launchdarkly-server-sdk` 9.x, import `ldclient`, Python >= 3.10):
```python
import ldclient
from ldclient import Context
from ldclient.config import Config

ldclient.set_config(Config(os.environ["LD_SDK_KEY"]))   # blocks up to start_wait=5s
client = ldclient.get()
ctx = Context.builder("alice").kind("user").name("Alice").set("country", "US").build()
client.variation("new-feature", ctx, False)
client.variation_detail("new-feature", ctx, False).reason
client.all_flags_state(ctx).to_values_map()
client.track("checkout-click", ctx)          # custom metric event
client.flush(); client.close()
```

JavaScript client SDK 3.x, vendored in the image at `/static/ldclient.min.js`
(global `LDClient`). Use the client-side ID, never the SDK key, in the browser:
```html
<script src="/static/ldclient.min.js"></script>
<script>
  const ld = LDClient.initialize("{{ client_side_id }}", { kind: "user", key: "alice", country: "US" });
  ld.on("ready", () => render(ld.variation("new-feature", false)));
  ld.on("change:new-feature", (v) => render(v));     // streaming: updates instantly
</script>
```
Flags must be client-side available (`clientSideAvailability.usingEnvironmentId`) to
appear in the JS SDK; the workshop project defaults new flags to available.

Node server SDK: `@launchdarkly/node-server-sdk` -> `init(sdkKey)`, `await client.waitForInitialization({timeout: 10})`,
`client.variation(key, ctx, default)`. Go: `github.com/launchdarkly/go-server-sdk/v7`.
Java: `com.launchdarkly:launchdarkly-java-server-sdk:7.x`. If the requester wants one
of these, bake the runtime into image.sh and keep the same `/opt/ld/app` + `ld-app.service`
+ `/opt/ld/ld.env` contract so the track scripts stay unchanged.

## Pitfalls

- `Authorization` header has no `Bearer` prefix.
- Flag POST returns 409 if the flag exists; setup scripts must treat that as success
  so skipping (solve) and re-running setup are safe.
- Check scripts time out after 1 minute; don't poll SDK propagation, read the API.
- Writing LD_SDK_KEY into /opt/ld/ld.env is fine (project is sandbox-scoped and the
  learner is its admin). Writing LAUNCHDARKLY_ACCESS_TOKEN anywhere on disk is not.
- The environment key is `test`, not `production`. Hard-coding `production` in API
  calls returns 404.
- Semantic-patch bodies need `environmentKey`; without it the API returns 400.
