# Solve for 05-segments: the Beta Testers segment, plus re-pointing
# release-otto's targeting rule at it.
provider "launchdarkly" {}

resource "launchdarkly_segment" "beta_testers" {
  key         = "beta-testers"
  project_key = var.project_key
  env_key     = "test"
  name        = "Beta Testers"
  description = "ToggleWear's beta cohort, defined by tier."

  rules {
    clauses {
      attribute    = "tier"
      op           = "in"
      values       = ["beta"]
      context_kind = "user"
      value_type   = "string"
    }
  }
}

# Replace the flag's tier rule with a segment-match rule. REST because the
# flag's environment config is owned by earlier modules.
# VERIFY: segmentMatch clause shape (attribute "segmentMatch", op
# "segmentMatch", values = segment keys) against the flags API docs before
# first live run.
resource "null_resource" "segment_targeting" {
  depends_on = [launchdarkly_segment.beta_testers]

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
          {"op": "replace", "path": "/environments/test/rules", "value": [
            {
              "clauses": [
                {"attribute": "segmentMatch", "op": "segmentMatch",
                 "values": ["beta-testers"], "contextKind": "user",
                 "negate": false}
              ],
              "variation": 0,
              "trackEvents": false
            }
          ]}
        ]'
    EOT
  }
}
