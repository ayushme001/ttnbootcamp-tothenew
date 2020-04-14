provider "aws" {
  region = "us-east-1"
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "ayush-ec2"
  instance_count = 1

  associate_public_ip_address = true
  key_name               = "ayush-pem"
  ami                    = "ami-07ebfd5b3428b6f4d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-03105b60052b9d72c"]
  subnet_id              = "subnet-0a5a6b106347d1b70"
  iam_instance_profile   = "ec2-s3-ayush"
  user_data = "${file("install_apache2.sh")}"
  tags = {
    owner = "ayush"
    purpose = "ayush-terraform"
  }
}

