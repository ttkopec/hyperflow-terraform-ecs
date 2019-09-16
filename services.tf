data "template_file" "task_def_hflow_worker" {
  template = "${file("${path.module}/task.json")}"
  vars {
    image_uri = "${var.hflow_image_uri}"
    container_name = "${var.hflow_container_name}"
    log_group = "${var.hflow_log_group}"
    region = "${var.region}"
  }
}

data "template_file" "task_def_influx" {
  template = "${file("${path.module}/task.json")}"
  vars {
    image_uri = "${var.influx_image_uri}"
    container_name = "${var.influx_container_name}"
    log_group = "${var.influx_log_group}"
    region = "${var.region}"
  }
}

data "template_file" "task_def_grafana" {
  template = "${file("${path.module}/task.json")}"
  vars {
    image_uri = "${var.grafana_image_uri}"
    container_name = "${var.grafana_container_name}"
    log_group = "${var.grafana_log_group}"
    region = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "task_hflow_worker" {
  container_definitions = "${data.template_file.task_def_hflow_worker.rendered}"
  family = "${var.hflow_worker_family}"

  # enable FARGATE
  requires_compatibilities = [
    "FARGATE"
  ]

  # use awsvpc, required by FARGATE
  network_mode = "awsvpc"

  # iam
  task_role_arn = "${aws_iam_role.hflow_worker_role.arn}"
  execution_role_arn = "${aws_iam_role.hflow_worker_role.arn}"

  # scaling parameters, required by FARGATE
  cpu = "256"
  memory = "512"
}

resource "aws_ecs_task_definition" "task_influx" {
  container_definitions = "${data.template_file.task_def_influx.rendered}"
  family = "${var.influx_family}"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  task_role_arn = "${aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn = "${aws_iam_role.ecs_task_execution_role.arn}"

  cpu = "256"
  memory = "512"
}

resource "aws_ecs_task_definition" "task_grafana" {
  container_definitions = "${data.template_file.task_def_grafana.rendered}"
  family = "${var.grafana_family}"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  task_role_arn = "${aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn = "${aws_iam_role.ecs_task_execution_role.arn}"

  cpu = "256"
  memory = "512"
}

resource "aws_ecs_service" "influx" {
  name = "influx"
  cluster = "${aws_ecs_cluster.hyperflow_cluster.id}"
  task_definition = "${aws_ecs_task_definition.task_influx.arn}"
  desired_count = 1

  launch_type = "FARGATE"
  platform_version = "LATEST"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets = ["${aws_subnet.hflow_subnet_public.id}"]
    security_groups = ["${aws_security_group.influx_sec_group.id}"]
    assign_public_ip = true
  }
}

//resource "aws_ecs_service" "grafana" {
//  name = "grafana"
//  cluster = "${aws_ecs_cluster.hyperflow_cluster.id}"
//  task_definition = "${aws_ecs_task_definition.task_grafana.arn}"
//  desired_count = 1
//
//  launch_type = "FARGATE"
//  platform_version = "LATEST"
//  scheduling_strategy = "REPLICA"
//
//  network_configuration {
//    subnets = ["${aws_subnet.hflow_subnet_public.id}"]
//    security_groups = ["${aws_security_group.grafana_sec_group.id}"]
//    assign_public_ip = true
//  }
//}

output "task_arn" {
  value = "${aws_ecs_task_definition.task_hflow_worker.arn}"
}

output "container_name" {
  value = "${var.hflow_container_name}"
}
