module "public_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.8"

  name = "${local.name}-public"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_sg.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  associate_public_ip_address = true

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
    }
  ]
}

module "private_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.8"

  name = "${local.name}-private"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.private_sg.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
    }
  ]
}
