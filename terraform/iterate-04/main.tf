# Solve for 04-run-and-read: the experiment's iteration is running. (The
# experiment itself is 03's artifact; the 04 solve script runs 03's solve
# first so a learner who skipped both still lands in the right state.)
resource "null_resource" "start_iteration" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../lib/exp.sh start ${var.project_key} recs-strategy-experiment"
  }
}
