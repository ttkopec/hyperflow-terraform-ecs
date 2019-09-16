resource "aws_cloudwatch_log_group" "hflow_logs" {
  name = "${var.hflow_log_group}"
}

resource "aws_cloudwatch_log_group" "prometheus_logs" {
  name = "${var.influx_log_group}"
}

resource "aws_cloudwatch_log_group" "grafana_logs" {
  name = "${var.grafana_log_group}"
}
