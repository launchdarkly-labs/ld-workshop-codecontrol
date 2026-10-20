# Solve for 02-your-first-flag: the release-otto boolean flag the learner
# creates in the LaunchDarkly UI.
provider "launchdarkly" {}

resource "launchdarkly_feature_flag" "release_otto" {
  project_key    = var.project_key
  key            = "release-otto"
  name           = "Release Otto"
  description    = "Gates Otto, the ToggleWear chat widget."
  variation_type = "boolean"

  # The JS client SDK can only see flags with client-side availability on.
  # Learner-created flags get this from the create-flag dialog checkbox
  # (on by default for new accounts); the solve sets it explicitly.
  client_side_availability {
    using_environment_id = true
  }

  defaults {
    on_variation  = 0
    off_variation = 1
  }
}
