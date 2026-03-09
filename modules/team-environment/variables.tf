variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "team_name" {
  description = "Team name - used for resource naming and isolation"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the team's VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "EC2 instance type (Graviton)"
  type        = string
  default     = "t4g.micro"
}

variable "allowed_ip" {
  description = "IP address allowed to access the public instance (CIDR notation)"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ip, 0))
    error_message = "The allowed_ip must be a valid CIDR block (e.g. 203.0.113.1/32)."
  }
}
