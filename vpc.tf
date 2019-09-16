# VPC
resource "aws_vpc" "hflow_vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "hflow vpc"
  }
}

# subnets
resource "aws_subnet" "hflow_subnet_public" {
  cidr_block = "192.168.0.0/24"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  tags = {
    Name = "hflow public subnet"
  }
}

resource "aws_subnet" "hflow_subnet_private" {
  cidr_block = "192.168.1.0/24"
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  tags = {
    Name = "hflow private subnet"
  }
}

# internet gateway setup
resource "aws_internet_gateway" "hflow_igw" {
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  tags = {
    Name = "hflow igw"
  }
}

# NAT gateway setup
resource "aws_eip" "hflow_eip" {
  vpc = true

  tags = {
    Name = "hflow eip"
  }
}

resource "aws_nat_gateway" "hflow_nat" {
  allocation_id = "${aws_eip.hflow_eip.id}"
  subnet_id = "${aws_subnet.hflow_subnet_public.id}"

  tags = {
    Name = "hflow nat-gw"
  }
}

# routing tables
resource "aws_route_table" "hflow_rtb_public" {
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.hflow_igw.id}"
  }

  tags = {
    Name = "hflow rtb public"
  }
}

resource "aws_route_table_association" "associate_rtb_public_with_public_subnet" {
  route_table_id = "${aws_route_table.hflow_rtb_public.id}"
  subnet_id = "${aws_subnet.hflow_subnet_public.id}"
}

resource "aws_route_table" "hflow_rtb_private" {
  vpc_id = "${aws_vpc.hflow_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.hflow_nat.id}"
//    gateway_id = "${aws_internet_gateway.hflow_igw.id}"
  }

  tags = {
    Name = "hflow rtb private"
  }
}

resource "aws_main_route_table_association" "set_rtb_private_as_main" {
  route_table_id = "${aws_route_table.hflow_rtb_private.id}"
  vpc_id = "${aws_vpc.hflow_vpc.id}"
}

# setup service discovery
resource "aws_service_discovery_private_dns_namespace" "local" {
  name = "local"
  vpc = "${aws_vpc.hflow_vpc.id}"
}

resource "aws_service_discovery_service" "hflow_sd_service" {
  name = "hyperflow-service"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.local.id}"

    dns_records {
      ttl = 60
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

output "subnet" {
  value = "${aws_subnet.hflow_subnet_private.id}"
}
