# Solve for 06-promote-the-winner: the iteration is stopped with
# Personalized named the winner, and the flag's default rule serves
# Personalized to everyone.
resource "null_resource" "ship_winner" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../lib/exp.sh ship ${var.project_key} recs-strategy-experiment personalized"
  }
}
