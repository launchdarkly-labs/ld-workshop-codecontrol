# Solve for 07-multi-armed-bandit: a running multi-armed bandit on
# recommendations-strategy's default rule, optimizing recs-engagement.
# Created via the experiments API with type "mab" (Bayesian, Thompson
# sampling, reallocating hourly — the API's minimum update frequency is one
# hour, confirmed in the first live play).
resource "null_resource" "create_and_start_mab" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      METRIC=$(bash ${path.module}/../lib/exp.sh metric-key ${var.project_key} recs-engagement)
      [ -n "$METRIC" ] || { echo "ERROR: no metric with event key recs-engagement — run the 02 solve first" >&2; exit 1; }
      bash ${path.module}/../lib/exp.sh create ${var.project_key} recs-strategy-bandit \
        "Recommendations strategy bandit" \
        "Keep routing shoppers to whichever recommendation strategy is currently winning on engagement." \
        "$METRIC" mab
      bash ${path.module}/../lib/exp.sh start ${var.project_key} recs-strategy-bandit
    EOT
  }
}
