# Root Terragrunt configuration
# All team environments inherit from this file.

locals {
  project_name = "platform-task"
  region       = "eu-west-1"
}

# Generate the provider configuration for each team environment
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
      region = "${local.region}"

      default_tags {
        tags = {
          Project     = "${local.project_name}"
          ManagedBy   = "terragrunt"
        }
      }
    }
  EOF
}

# Remote state configuration — each team gets its own state file
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "${local.project_name}-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.project_name}-tflock"
  }
}

# Common inputs inherited by all team environments
inputs = {
  project_name = local.project_name
}
