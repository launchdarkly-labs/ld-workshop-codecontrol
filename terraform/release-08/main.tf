# 08-guarded-release infrastructure.
#
# Two halves:
#  - Supporting infra the learner finds PRE-BUILT (otto-style flag serving
#    concise, the otto-response-latency metric). setup-workstation applies
#    just these with `terraform apply -target=...`.
#  - The learner's own work — the guarded rollout on otto-style — which has
#    NO public API (the UI drives an internal measured-rollouts service; the
#    beta release-pipelines API that once stood in for it returned 404 in
#    live sandboxes and release pipelines are deprecated, so it was removed
#    on 2026-10-20 without replacement). The solve therefore materializes the
#    state a learner is in AFTER the guarded release rolls back: otto-style
#    serving Concise, which is exactly this module's baseline. Skip → Check
#    on 08 fails honestly, like 07's adaptive trigger in Observability.
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
