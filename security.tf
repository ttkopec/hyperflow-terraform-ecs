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

resource "aws_security_group" "influx_sec_group" {
  name = "influx_sec_group"
  description = "Rules for influx"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  ingress {
    from_port = 8086
    to_port = 8086
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound trafic on 8086"
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