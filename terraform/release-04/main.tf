# Solve for 04-contexts-and-targeting (Terraform half): the targeting rule
# serving true to beta-tier users, with the default rule serving false.
#
# release-otto's environment config is updated via REST (JSON patch) because
# the flag resource is owned by terraform/release-02. Boolean flag variation
# indexes: 0 = true, 1 = false.
resource "null_resource" "beta_targeting" {
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
          {"op": "replace", "path": "/environments/test/rules", "value": [
            {
              "clauses": [
                {"attribute": "tier", "op": "in", "values": ["beta"],
                 "contextKind": "user", "negate": false}
              ],
              "variation": 0,
              "trackEvents": false
            }
          ]},
          {"op": "replace", "path": "/environments/test/fallthrough",
           "value": {"variation": 1}}
        ]'
    EOT
  }
}
