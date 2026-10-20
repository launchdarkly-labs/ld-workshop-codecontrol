# Auth: the provider reads LAUNCHDARKLY_ACCESS_TOKEN from the environment.
# This module only ever runs in operator context (track_scripts), never
# in the participant's shell.
provider "launchdarkly" {}

locals {
  project_key  = "codecontrol-${var.sandbox_id}"
  project_name = "ToggleWear CodeControl — ${var.sandbox_id}"
}

resource "launchdarkly_project" "student" {
  key  = local.project_key
  name = local.project_name
  tags = ["instruqt", "codecontrol"]

  environments {
    key   = "test"
    name  = "Test"
    color = "417505"
  }
}
