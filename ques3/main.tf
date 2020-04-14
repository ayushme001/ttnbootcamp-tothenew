provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "ayush-vpc" {
  # (resource arguments)
  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "ayush-subnet" {
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.ayush-vpc.id
  cidr_block = "192.168.128.0/18"
  tags = var.default_tags
}

resource "aws_subnet" "ayush-subnet-1" {
  vpc_id     = aws_vpc.ayush-vpc.id
  cidr_block = "192.168.192.0/18"
  tags = var.default_tags
}

resource "aws_security_group" "ayush-sg" {
  name        = "ayush-sg-terraform"
  description = "for terraform"
  vpc_id      = aws_vpc.ayush-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.87.56.94/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    owner = "ayush"
    purpose = "ayush-sg-terraform"
    Name = "ayush-sg-terraform"
  }
}

resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ayush-sg.id
}

resource "aws_instance" "ayush" {
  ami           = "ami-05055726077359305"
  instance_type = "t2.micro"
  key_name = "ayush-pem" 
  subnet_id = aws_subnet.ayush-subnet.id 
  security_groups = [aws_security_group.ayush-sg.id]	
  tags = var.default_tags
}

resource "aws_lb_target_group" "ayush-tg" {
  name     = "ayush-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ayush-vpc.id
  tags = var.default_tags
}

resource "aws_lb_target_group_attachment" "ayush-tg-attach" {
  target_group_arn = aws_lb_target_group.ayush-tg.arn
  target_id        = aws_instance.ayush.id
  port             = 80
}


resource "aws_lb" "ayush-alb" {
  name               = "ayush-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ayush-sg.id]
  subnets            = [aws_subnet.ayush-subnet.id, aws_subnet.ayush-subnet-1.id]
  tags = var.default_tags
}

resource "aws_lb_listener" "ayush-lb-listener" {
  load_balancer_arn = aws_lb.ayush-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ayush-tg.arn
  }
}

terraform {
  backend "s3" {
    bucket = "ec2-ttn"
    key    = "ayush/terraform.tfstate"
    region = "us-east-1"
  }
}
