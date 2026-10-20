# Observability-track baseline: the "Recommended for You" carousel, shipped
# and flagged, as a learner landing cold in Track 2 (or Track 3) should find
# it. Applied by the track-level setup-workstation AFTER the Release solves
# have been replayed — never by a challenge, and never as learner work.
#
#  - show-recommendations      boolean; ON, serving true: the carousel is live.
#  - recommendations-strategy  string; ON, serving "bestsellers" (the safe
#                              control). "personalized" is the new strategy
#                              with the lurking bug; the Observability
#                              challenges ship it, watch it fail, guard it,
#                              and auto-heal back to bestsellers.
#
# The matching server-side wiring lives in pastes/server-recommendations.py
# and is applied to app/server.py by setup via terraform/lib/patch_block.py.
provider "launchdarkly" {}

resource "launchdarkly_feature_flag" "show_recommendations" {
  project_key    = var.project_key
  key            = "show-recommendations"
  name           = "Show Recommendations"
  description    = "Gates the \"Recommended for You\" carousel on the storefront."
  variation_type = "boolean"
  tags           = ["recommendations"]

  client_side_availability {
    using_environment_id = true
  }

  defaults {
    on_variation  = 0
    off_variation = 1
  }
}

resource "launchdarkly_feature_flag_environment" "show_recommendations_test" {
  flag_id = launchdarkly_feature_flag.show_recommendations.id
  env_key = "test"

  on = true
  fallthrough {
    variation = 0
  }
  off_variation = 1
}

resource "launchdarkly_feature_flag" "recommendations_strategy" {
  project_key    = var.project_key
  key            = "recommendations-strategy"
  name           = "Recommendations Strategy"
  description    = "Which strategy fills the carousel: bestsellers (same popular items for everyone) or personalized (items matching what the shopper viewed)."
  variation_type = "string"
  tags           = ["recommendations"]

  # Client-side availability so the browser can evaluate the flag too — the
  # observability plugins attribute a session to a variation only when that
  # session evaluated the flag.
  client_side_availability {
    using_environment_id = true
  }

  variations {
    value       = "bestsellers"
    name        = "Bestsellers"
    description = "The same popular items for everyone. Safe, boring."
  }
  variations {
    value       = "personalized"
    name        = "Personalized"
    description = "Items in the same category as the product the shopper viewed."
  }

  defaults {
    on_variation  = 0
    off_variation = 0
  }
}

resource "launchdarkly_feature_flag_environment" "recommendations_strategy_test" {
  flag_id = launchdarkly_feature_flag.recommendations_strategy.id
  env_key = "test"

  on = true
  fallthrough {
    variation = 0
  }
  off_variation = 0
}
