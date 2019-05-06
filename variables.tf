variable "region"
{
  default = "eu-central-1"
}

variable "zone"
{
  default = "eu-central-1a"
}

variable "ecs_cluster_name" {
  default = "cluster-hyperflow"
}

variable "hflow_image_uri" {
  default = "511281668954.dkr.ecr.eu-central-1.amazonaws.com/hyperflow:0.20"
}

variable "hflow_container_name" {
  default = "hyperflow"
}

variable "hflow_log_group" {
  default = "/ecs/hyperflow-worker"
}

variable "hflow_worker_family" {
  default = "hyperflow-worker"
}

variable "pushgateway_image_uri" {
  default = "docker.io/prom/pushgateway:latest"
}

variable "pushgateway_container_name" {
  default = "pushgateway"
}

variable "pushgateway_log_group" {
  default = "/ecs/pushgateway"
}

variable "pushgateway_family" {
  default = "pushgateway"
}

variable "prometheus_image_uri" {
  default = "511281668954.dkr.ecr.eu-central-1.amazonaws.com/prometheus:0.2"
}

variable "prometheus_container_name" {
  default = "prometheus"
}

variable "prometheus_log_group" {
  default = "/ecs/prometheus"
}

variable "prometheus_family" {
  default = "prometheus"
}

variable "grafana_image_uri" {
  default = "511281668954.dkr.ecr.eu-central-1.amazonaws.com/grafana:0.1"
}

variable "grafana_container_name" {
  default = "grafana"
}

variable "grafana_log_group" {
  default = "/ecs/grafana"
}

variable "grafana_family" {
  default = "grafana"
}

variable "s3_full_access_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

variable "cloud_map_instance_access_policy_arn" {
  default = "arn:aws:iam::aws:policy/AWSCloudMapRegisterInstanceAccess"
}

variable "ecs_task_execution_policy_arn" {
  default = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

variable "assign_public_ip" {
  default = "DISABLED"
}