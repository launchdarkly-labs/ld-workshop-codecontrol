# Solve for 02-your-first-metric (Terraform half): the recs-engagement
# metric the learner creates in the UI — a custom conversion binary metric
# ("Occurrence (Percent)"): did this user click a recommended item, higher
# is better, analyzed per user. The paste that emits the event is applied
# by the solve script with terraform/lib/patch_block.py.
provider "launchdarkly" {}

resource "launchdarkly_metric" "recs_engagement" {
  project_key = var.project_key
  key         = "recs-engagement"
  name        = "Recs engagement"
  description = "A shopper clicked an item in the Recommended for You carousel. Tracked by server.py on /recommendations/click."

  kind                = "custom"
  event_key           = "recs-engagement"
  is_numeric          = false
  success_criteria    = "HigherThanBaseline"
  randomization_units = ["user"]
  tags                = ["recommendations"]
}
