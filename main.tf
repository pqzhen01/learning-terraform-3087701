data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

#data "aws_vpc" "default" {
#  default = true
#}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-dev"
  cidr = "10.0.0.0/16"

  azs             = ["use-east-1a", "us-east-1b", "us-east-1c"]
  #private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  #enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}



resource "aws_instance" "web" {
  ami                     = data.aws_ami.app_ami.id
  instance_type           = var.instance_type

  #this is to use the security group id defined directly
  #vpc_security_group_ids = [aws_security_group.blog.id]

  #this is to use the module to define the sg and sg rules
  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tags = {
    Name = "Learning Terraform"
  }
}

resource "aws_security_group" "blog" {
  name = "blog"
  tags = {
    Terraform = "true"
  }
  
  #vpc_id = data.aws_vpc.default.id
  vpc_id              = module.vpc.public_subnets[0]
}



module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name    = "blog_new"

  #vpc_id              = data.aws_vpc.default.id
  vpc_id              = module.vpc.public_subnets[0]


  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]
}

resource "aws_security_group_rule" "blog_http_in" {
  type = "ingress"
  from_port    = 80
  to_port      = 80
  protocol     = "tcp"
  cidr_blocks  = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type = "ingress"
  from_port    = 443
  to_port      = 443
  protocol     = "tcp"
  cidr_blocks  = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_out" {
  type = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.blog.id
}



