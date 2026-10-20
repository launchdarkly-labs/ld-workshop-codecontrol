# Solve for 02-instrument-for-errors (Terraform half): the learner "ships"
# the personalized recommendations strategy the naive way — default rule of
# recommendations-strategy switched to "personalized" with nothing watching.
# (The pastes that wire the observability plugins are applied by the solve
# script with terraform/lib/patch_block.py.)
#
# The flag is owned by terraform/observability-baseline, so this module
# updates it over REST (semantic patch) rather than with a provider resource.
resource "null_resource" "ship_personalized" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../lib/set-fallthrough.sh ${var.project_key} recommendations-strategy personalized"
  }
}
