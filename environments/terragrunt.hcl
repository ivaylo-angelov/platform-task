# Root Terragrunt configuration
# All team environments inherit from this file.

locals {
  project_name = "platform-task"
  region       = "eu-west-1"
  account_id   = get_aws_account_id()
}

# Remote state configuration — each team gets its own state file
# Bucket name matches bootstrap: ${project_name}-tfstate-${account_id}
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "${local.project_name}-tfstate-${local.account_id}"
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
