provider "aws" {
  region = "${var.region}"
}

resource "aws_ecs_cluster" "hyperflow_cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "null_resource" "on_finish" {
  triggers {
    always_run = "${timestamp()}"
  }

  # store all configuration details in output.txt file
  provisioner "local-exec" {
    command = "echo 'containerName=${var.hflow_container_name}\nclusterArn=${aws_ecs_cluster.hyperflow_cluster.arn}\ntaskArn=${aws_ecs_task_definition.task_hflow_worker.arn}\nsubnets=[${aws_subnet.hflow_subnet_private.id}]\nsecurityGroups=[${aws_security_group.hflow_workers_sec_group.id}]\nassignPublicIp=${var.assign_public_ip}' > output.txt"
  }
}

output "cluster_arn" {
  value = "${aws_ecs_cluster.hyperflow_cluster.arn}"
}
