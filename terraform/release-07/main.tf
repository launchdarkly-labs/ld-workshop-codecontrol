# Solve for 07-progressive-rollout: the end-state of a COMPLETED progressive
# rollout — the default rule serves true to everyone (the beta segment rule
# stays in place above it).
#
# Deliberately NOT the beta release APIs, despite the general decision to use
# them for rollout solves: a solve (and the later tracks' baseline setup that
# replays it) must materialize state instantly. Starting a real timed rollout
# here would leave the flag mid-ramp for minutes and block challenge 08 — a
# guarded rollout can't start while another rollout is active. A learner who
# finishes this lab ends with the ramp complete, and that is the state this
# solve produces.
resource "null_resource" "completed_rollout" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -fsS -X PATCH \
        "https://app.launchdarkly.com/api/v2/flags/${var.project_key}/release-otto" \
        -H "Authorization: $LAUNCHDARKLY_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        --data-raw '[
          {"op": "replace", "path": "/environments/test/on", "value": true},
          {"op": "replace", "path": "/environments/test/fallthrough",
           "value": {"variation": 0}}
        ]'
    EOT
  }
}
