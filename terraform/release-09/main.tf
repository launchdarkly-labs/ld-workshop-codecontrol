# Solve for 09-kill-switch: release-otto toggled off — the state the check
# validates (the learner killed the feature).
#
# NOTE for later tracks: the assignment tells the learner to turn Otto back
# ON after the check passes, so a finished-track baseline has Otto live.
# The Observability/Iterate track-level setups must re-enable release-otto
# after replaying this solve (or skip this module) when materializing their
# baselines.
resource "null_resource" "kill_switch" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -fsS -X PATCH \
        "https://app.launchdarkly.com/api/v2/flags/${var.project_key}/release-otto" \
        -H "Authorization: $LAUNCHDARKLY_ACCESS_TOKEN" \
        -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
        --data-raw '{
          "environmentKey": "test",
          "instructions": [{"kind": "turnFlagOff"}]
        }'
    EOT
  }
}
