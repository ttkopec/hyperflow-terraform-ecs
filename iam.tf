data "aws_iam_policy" "ecs_task_execution_policy" {
  arn = "${var.ecs_task_execution_policy_arn}"
}

data "aws_iam_policy" "s3_full_access_policy" {
  arn = "${var.s3_full_access_policy_arn}"
}

data "aws_iam_policy" "cloud_map_instance_access_policy" {
  arn = "${var.cloud_map_instance_access_policy_arn}"
}

# role for hyperflow workers
resource "aws_iam_role" "hflow_worker_role" {
  name_prefix = "hflowWorkerRole"
  assume_role_policy = "${file("${path.module}/ecs-task-execution-role.json")}"
}

resource "aws_iam_role_policy_attachment" "attach_ecs_policy_to_worker" {
  policy_arn = "${data.aws_iam_policy.ecs_task_execution_policy.arn}"
  role = "${aws_iam_role.hflow_worker_role.name}"
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy_to_worker" {
  policy_arn = "${data.aws_iam_policy.s3_full_access_policy.arn}"
  role = "${aws_iam_role.hflow_worker_role.name}"
}

# role for entities using dns service discovery
resource "aws_iam_role" "dns_discoverable_role" {
  name_prefix = "dnsDiscoverableRole"
  assume_role_policy = "${file("${path.module}/ecs-task-execution-role.json")}"
}

resource "aws_iam_role_policy_attachment" "attach_ecs_policy_to_discoverable" {
  policy_arn = "${data.aws_iam_policy.ecs_task_execution_policy.arn}"
  role = "${aws_iam_role.dns_discoverable_role.name}"
}

resource "aws_iam_role_policy_attachment" "attach_cloud_map_policy_to_discoverable" {
  policy_arn = "${data.aws_iam_policy.cloud_map_instance_access_policy.arn}"
  role = "${aws_iam_role.dns_discoverable_role.name}"
}

# simple role for ecs tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "ecsTaskExecutionRole"
  assume_role_policy = "${file("${path.module}/ecs-task-execution-role.json")}"
}

resource "aws_iam_role_policy_attachment" "attach_ecs_policy_to_task_executor" {
  policy_arn = "${data.aws_iam_policy.ecs_task_execution_policy.arn}"
  role = "${aws_iam_role.ecs_task_execution_role.name}"
}
