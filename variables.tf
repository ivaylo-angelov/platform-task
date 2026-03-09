variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "platform-task"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use (defaults to all available in the region)"
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "EC2 instance type (Graviton)"
  type        = string
  default     = "t4g.micro"
}

variable "allowed_ip" {
  description = "IP address allowed to access the public instance (CIDR notation, e.g. 203.0.113.1/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ip, 0))
    error_message = "The allowed_ip must be a valid CIDR block (e.g. 203.0.113.1/32)."
  }
}
