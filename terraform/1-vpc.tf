############
## VPC
############

resource "aws_vpc" "kubeadm-vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "${var.vpc_name}",
        "Owner", "${var.owner}"
    )
  )}"
}

# DHCP Options are not actually required, being identical to the Default Option Set
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "${var.vpc_name}",
        "Owner", "${var.owner}"
    )
  )}"
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id ="${aws_vpc.kubeadm-vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

############
## Subnets
############

# Subnet (public)
resource "aws_subnet" "kubeadm-subnet" {
  vpc_id = "${aws_vpc.kubeadm-vpc.id}"
  cidr_block = "${var.vpc_cidr}"
  availability_zone = "${var.zone}"

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "kubeadm-subnet",
        "Owner", "${var.owner}"
    )
  )}"
}

resource "aws_internet_gateway" "kubeadm-gw" {
  vpc_id = "${aws_vpc.kubeadm-vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "kubeadm-gw",
        "Owner", "${var.owner}"
    )
  )}"
}

############
## Routing
############

resource "aws_route_table" "kubeadm-routing" {
   vpc_id = "${aws_vpc.kubeadm-vpc.id}"

   # Default route through Internet Gateway
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_internet_gateway.kubeadm-gw.id}"
   }

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "kubeadm-routing",
        "Owner", "${var.owner}"
    )
  )}"
}

resource "aws_route_table_association" "kubeadm-route-association" {
  subnet_id = "${aws_subnet.kubeadm-subnet.id}"
  route_table_id = "${aws_route_table.kubeadm-routing.id}"
}


############
## Security
############

resource "aws_security_group" "kubeadm-sg" {
  vpc_id = "${aws_vpc.kubeadm-vpc.id}"
  name = "kubeadm-sg"

  # Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP from control host IP
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all internal
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow all traffic from control host IP
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all traffic from the API ELB
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.kubeadm-api-sg.id}"]
  }

  tags = "${merge(
    local.common_tags,
    map(
        "Name", "kubeadm-sg",
        "Owner", "${var.owner}"
    )
  )}"
}
