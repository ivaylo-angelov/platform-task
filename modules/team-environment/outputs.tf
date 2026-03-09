output "vpc_id" {
  description = "ID of the team's VPC"
  value       = module.vpc.vpc_id
}

output "public_instance_id" {
  description = "ID of the public EC2 instance"
  value       = module.public_instance.id
}

output "private_instance_id" {
  description = "ID of the private EC2 instance"
  value       = module.private_instance.id
}

output "public_instance_public_ip" {
  description = "Public IP of the public instance"
  value       = module.public_instance.public_ip
}

output "ssm_connect_public" {
  description = "AWS CLI command to connect to the public instance via SSM"
  value       = "aws ssm start-session --target ${module.public_instance.id}"
}

output "ssm_connect_private" {
  description = "AWS CLI command to connect to the private instance via SSM"
  value       = "aws ssm start-session --target ${module.private_instance.id}"
}
