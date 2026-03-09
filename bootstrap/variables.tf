variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming. Must match var.project_name in the root module."
  type        = string
  default     = "platform-task"
}
