module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${local.name}-public-sg"
  description = "Security group for public instance - restricted to a single IP"
  vpc_id      = module.vpc.vpc_id

  # Spec requirement: "Restrict access to the VM in the Public subnet to a single IP address"
  # SSM Session Manager uses outbound HTTPS (agent -> AWS endpoints), so no inbound rules are
  # strictly needed for connectivity. We add both HTTPS and SSH restricted to the allowed IP
  # to satisfy the spec and provide a fallback access method alongside SSM.
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from allowed IP only"
      cidr_blocks = var.allowed_ip
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from allowed IP only (fallback access)"
      cidr_blocks = var.allowed_ip
    }
  ]

  egress_rules = ["all-all"]
}

module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${local.name}-private-sg"
  description = "Security group for private instance - traffic only from public instance"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      description              = "All traffic from public instance SG"
      source_security_group_id = module.public_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}
