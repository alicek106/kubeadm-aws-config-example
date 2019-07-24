############################
# K8s Control Pane instances
############################

resource "aws_instance" "master" {
    count = 1
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.master_instance_type}"

    iam_instance_profile = "k8s-master-role"

    subnet_id = "${aws_subnet.kubeadm-subnet.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 20 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubeadm-sg.id}"]
    key_name = "${var.default_keypair_name}"
    tags = "${merge(
    local.common_tags,
      map(
        "Owner", "${var.owner}",
        "Name", "kubeadm-master",
      )
    )}"
}

###############################
## Kubernetes API Load Balancer
###############################

resource "aws_elb" "kubeadm-api-elb" {
    count = 0
    name = "kubeadm-api-elb"
    instances = ["${aws_instance.master.*.id}"]
    subnets = ["${aws_subnet.kubeadm-subnet.id}"]
    cross_zone_load_balancing = false

    security_groups = ["${aws_security_group.kubeadm-api-sg.id}"]

    listener {
      lb_port = 6443
      instance_port = 6443
      lb_protocol = "TCP"
      instance_protocol = "TCP"
    }

    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 15
      target = "HTTPS:6443/"
      interval = 30
    }

    tags = "${merge(
      local.common_tags,
        map(
          "Name", "kubeadm-api-elb",
          "Owner", "${var.owner}"
        )
    )}"
}

############
## Security
############

resource "aws_security_group" "kubeadm-api-sg" {
  vpc_id = "${aws_vpc.kubeadm-vpc.id}"
  name = "kubernetes-api"

  # Allow inbound traffic to the port used by Kubernetes API HTTPS
  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "TCP"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.common_tags,
      map(
        "Name", "kubeadm-api-sg",
        "Owner", "${var.owner}"
      )
  )}"
}

############
## Outputs
############

# output "kubernetes_api_dns_name" {
#  value = "${aws_elb.kubeadm-api-elb.dns_name}"
# }
