
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cidrs = [for i in range(min(length(data.aws_availability_zones.available.names), 4)) : cidrsubnet(var.vpc_cidr, 4, i)]
  ingress_cidr = var.ingress_cidr != "" ? var.ingress_cidr : module.myip.cidr
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = local.cidrs

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_security_group" "alephium_broker_protocol" {
  name        = "${local.instance_name_prefix}broker-protocol"
  description = "${local.instance_name_prefix}broker-protocol dedicated sg"
  vpc_id      = module.vpc.vpc_id
  # BlockFlow - Protocol
  ingress {
    from_port   = 39973
    to_port     = 39973
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # BlockFlow - Discovery
  ingress {
    from_port   = 39973
    to_port     = 39973
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Miner - Protocol
  ingress {
    from_port   = 10973
    to_port     = 10973
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  # HTTP - API broker
  ingress {
    from_port   = 12973
    to_port     = 12973
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.extra_tags
}

resource "aws_security_group" "alephium_broker_ssh" {
  name        = "${local.instance_name_prefix}broker-ssh"
  description = "${local.instance_name_prefix}broker-ssh dedicated sg"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.ingress_cidr]
  }
  tags = var.extra_tags
}
