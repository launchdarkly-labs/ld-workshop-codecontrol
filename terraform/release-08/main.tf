# 08-guarded-release infrastructure.
#
# Two halves:
#  - Supporting infra the learner finds PRE-BUILT (otto-style flag serving
#    concise, the otto-response-latency metric). setup-workstation applies
#    just these with `terraform apply -target=...`.
#  - The learner's own work (the guarded rollout on otto-style), which
#    solve-workstation materializes by applying the whole module, including
#    null_resource.start_guarded_rollout below.
provider "launchdarkly" {}

resource "launchdarkly_feature_flag" "otto_style" {
  project_key    = var.project_key
  key            = "otto-style"
  name           = "Otto Style"
  description    = "Chooses Otto's reply style: concise (control) or chatty (the new variation)."
  variation_type = "string"

  variations {
    value = "concise"
    name  = "Concise Otto"
  }
  variations {
    value = "chatty"
    name  = "Chatty Otto"
  }

  defaults {
    on_variation  = 0
    off_variation = 0
  }
}

# Flag on, serving Concise Otto to everyone. The learner's guarded rollout
# ships Chatty against this baseline.
resource "launchdarkly_feature_flag_environment" "otto_style_test" {
  flag_id = launchdarkly_feature_flag.otto_style.id
  env_key = "test"

  on = true
  fallthrough {
    variation = 0
  }
  off_variation = 0
}

resource "launchdarkly_metric" "otto_response_latency" {
  project_key = var.project_key
  key         = "otto-response-latency"
  name        = "Otto response latency"
  description = "Milliseconds from chat request to Otto's reply, tracked by server.py."

  kind                  = "custom"
  event_key             = "otto-response-latency"
  is_numeric            = true
  unit                  = "ms"
  success_criteria      = "LowerThanBaseline"
  analysis_type         = "mean"
  unit_aggregation_type = "average"
  randomization_units   = ["user"]
}

# Start the guarded rollout of Chatty Otto (solve only — excluded from
# setup's -target list). Uses the beta release APIs per DECISIONS.md.
resource "null_resource" "start_guarded_rollout" {
  depends_on = [
    launchdarkly_feature_flag_environment.otto_style_test,
    launchdarkly_metric.otto_response_latency,
  ]

  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/start-guarded-rollout.sh ${var.project_key}"
  }
}
