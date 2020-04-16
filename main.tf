provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "ayush-vpc" {
  # (resource arguments)
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet-1" {
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.ayush-vpc.id
  cidr_block = "192.168.64.0/18"
  tags = {
	"kubernetes.io/cluster/cluster" = "shared"
  }
}

resource "aws_subnet" "subnet-2" {
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.ayush-vpc.id
  cidr_block = "192.168.128.0/18"
  tags = {
        "kubernetes.io/cluster/cluster" = "shared"
  }
}

terraform {
  backend "s3" {
    bucket = "ec2-ttn"
    key    = "ayush/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "role-eks-master" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role" "role-eks-node" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_security_group" "master-sg" {
  name        = "terraform-eks-master-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.ayush-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.default_tags
}

resource "aws_security_group" "node-sg" {
  name        = "terraform-eks-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.ayush-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.default_tags
}


resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node-sg.id
  source_security_group_id = aws_security_group.node-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control      plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node-sg.id
  source_security_group_id = aws_security_group.master-sg.id
  to_port                  = 65535
  type                     = "ingress"
 }

resource "aws_security_group_rule" "demo-cluster-ingress-node-http" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.master-sg.id
  source_security_group_id = aws_security_group.node-sg.id
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_eks_cluster" "cluster" {
  name            = var.cluster-name
  role_arn        = aws_iam_role.role-eks-master.arn

  vpc_config {
    security_group_ids = [aws_security_group.master-sg.id]
    subnet_ids         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id,]
  }
}

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: aws_eks_cluster.cluster.endpoint
    certificate-authority-data: aws_eks_cluster.cluster.certificate_authority.0.data
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - var.cluster-name
KUBECONFIG
}

output "kubeconfig" {
  value = local.kubeconfig
}

data "aws_ami" "eks-worker" {
   filter {
     name   = "name"
     values = ["amazon-eks-node-${aws_eks_cluster.cluster.version}-v*"]
   }

   most_recent = true
   owners      = ["602401143452"] # Amazon EKS AMI Account ID
 }

data "aws_region" "current" {
}

locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint aws_eks_cluster.cluster.endpoint --b64-cluster-ca aws_eks_cluster.cluster.certificate_authority[0].data var.cluster-name
USERDATA

}

resource "aws_launch_configuration" "cluster-lc" {
  associate_public_ip_address = true
  iam_instance_profile        = "EKSNodeInstanceRole"
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "t3.medium"
  name_prefix                 = "terraform-eks-launch-config"
  security_groups  = [aws_security_group.node-sg.id]
  user_data_base64 = base64encode(local.node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}
/*
resource "aws_autoscaling_group" "cluster-asg" {
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.cluster-lc.id
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-asg"
  vpc_zone_identifier = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
*/
locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: aws_iam_role.role-eks-node.arn
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "ayush-ng"
  node_role_arn   = aws_iam_role.role-eks-node.arn
  subnet_ids      = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
}

resource "aws_elb" "bar"{
  count = var.enable_route53 ? 1 : 0

  listener {
    instance_port     = var.protocol
    instance_protocol = "TCP"
    lb_port           = 80
    lb_protocol       = "TCP"
  }

       tags                        = {
           "kubernetes.io/cluster/${var.cluster-name}" = "owned"
           "kubernetes.io/service-name"                = "default/loadbalancer"
        }
cross_zone_load_balancing   = false
}



resource "aws_route53_zone" "private" {
  count = var.enable_route53 ? 1 : 0
  name = "ttn-internal.com"

  vpc {
    vpc_id = aws_vpc.ayush-vpc.id
  }
}


resource "aws_route53_record" "www" {
  count = var.enable_route53 ? 1 : 0
  zone_id = aws_route53_zone.private[count.index].zone_id
  name    = "loadbalancer.com"
  type    = "A"

  alias {
    name                   = aws_elb.bar[count.index].dns_name
    zone_id                = aws_elb.bar[count.index].zone_id
    evaluate_target_health = true
  }
}

