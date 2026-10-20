terraform {
  required_version = ">= 1.5.0"

  required_providers {
    launchdarkly = {
      source = "launchdarkly/launchdarkly"
      # Pin below 3.0.0: a breaking v3 (typed-client field renames) was in
      # beta as of 2026-07-07. See PHASES-release.md Phase 0 notes.
      version = "~> 2.30"
    }
  }
}
