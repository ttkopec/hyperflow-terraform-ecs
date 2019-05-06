# security groups
resource "aws_security_group" "grafana_sec_group" {
  name = "grafana_sec_group"
  description = "Rules for grafana"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound traffic on http://0.0.0.0:3000"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hflow"
  }
}

resource "aws_security_group" "prometheus_sec_group" {
  name = "promeheus_sec_group"
  description = "Rules for prometheus"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.grafana_sec_group.id}"]
    description = "Allow all inbound trafic from grafana"
  }

  ingress {
    from_port = 9090
    protocol = "tcp"
    to_port = 9090
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hflow"
  }
}

resource "aws_security_group" "pushgateway_sec_group" {
  name = "pushgateway_sec_group"
  description = "Rules for pushgateway"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.prometheus_sec_group.id}", "${aws_security_group.hflow_workers_sec_group.id}"]
    description = "Allow all inbound trafic from prometheus and workers"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hflow"
  }
}

resource "aws_security_group" "hflow_workers_sec_group" {
  name = "hflow_workers_sec_group"
  description = "Rules for hyperflow workers"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hflow"
  }
}

output "security_group" {
  value = "${aws_security_group.hflow_workers_sec_group.id}"
}