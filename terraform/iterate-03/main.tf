# Solve for 03-design-an-experiment: the A/B experiment on
# recommendations-strategy's default rule — Bestsellers (control) vs
# Personalized, 50/50, randomized by user, primary metric recs-engagement,
# Bayesian analysis. Created but NOT started (04 starts it).
#
# The Terraform provider has no experiment resource at our pin, so this is
# a REST call (see terraform/lib/exp.sh). The metric key is resolved by
# event key because UI-created metrics get their key from their name.
resource "null_resource" "create_experiment" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      METRIC=$(bash ${path.module}/../lib/exp.sh metric-key ${var.project_key} recs-engagement)
      [ -n "$METRIC" ] || { echo "ERROR: no metric with event key recs-engagement — run the 02 solve first" >&2; exit 1; }
      bash ${path.module}/../lib/exp.sh create ${var.project_key} recs-strategy-experiment \
        "Recommendations strategy: Bestsellers vs Personalized" \
        "Personalized recommendations will increase the share of shoppers who click a recommended item compared to Bestsellers." \
        "$METRIC" experiment
    EOT
  }
}
