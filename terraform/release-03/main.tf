# Solve for 03-wire-up-the-sdk (Terraform half): turn release-otto on.
#
# The flag resource is owned by terraform/release-02, so this module updates
# it through the REST API (JSON patch) rather than the provider — per-module
# state doesn't share resources across modules. The code pastes are applied
# by solve-workstation via terraform/lib/patch_block.py, not by Terraform.
resource "null_resource" "turn_flag_on" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    # LAUNCHDARKLY_ACCESS_TOKEN comes from the operator environment.
    command = <<-EOT
      curl -fsS -X PATCH \
        "https://app.launchdarkly.com/api/v2/flags/${var.project_key}/release-otto" \
        -H "Authorization: $LAUNCHDARKLY_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        --data-raw '[{"op":"replace","path":"/environments/test/on","value":true}]'
    EOT
  }
}
