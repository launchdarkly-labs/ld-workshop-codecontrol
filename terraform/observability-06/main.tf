# Solve for 06-guarded-release-real-metrics: the END-STATE of the lab.
#
# A guarded rollout can only be started from the LaunchDarkly UI — there is
# no public API for it (the beta release-pipelines API that once stood in
# returned 404 in live sandboxes and the product is deprecated; removed
# 2026-10-20 without replacement). A learner who finishes this lab watched
# the guard roll Personalized back, so the end-state is the default rule on
# "bestsellers". Skip → Check fails honestly, as with 07's adaptive trigger.
resource "null_resource" "post_rollback_state" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      bash ${path.module}/../lib/set-fallthrough.sh ${var.project_key} recommendations-strategy bestsellers
      echo "NOTE: 06 solve materialized the post-rollback end-state (bestsellers) only; guarded rollouts can only be started in the UI." >&2
    EOT
  }
}
