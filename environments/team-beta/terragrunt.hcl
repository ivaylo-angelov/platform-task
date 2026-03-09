# Team Beta environment
# To onboard a new team, copy this file to a new directory and update the inputs.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/team-environment"
}

locals {
  team_name   = "beta"
  environment = "dev"
}

# Generate provider with team-specific default tags
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }

    provider "aws" {
      region = "eu-west-1"

      default_tags {
        tags = {
          Project     = "platform-task"
          Team        = "${local.team_name}"
          Environment = "${local.environment}"
          ManagedBy   = "terragrunt"
        }
      }
    }
  EOF
}

inputs = {
  team_name     = local.team_name
  environment   = local.environment
  vpc_cidr      = "10.2.0.0/16"
  instance_type = "t4g.micro"
  allowed_ip    = "REPLACE_WITH_YOUR_IP/32" # curl -s https://checkip.amazonaws.com
}
