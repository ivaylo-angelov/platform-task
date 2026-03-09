output "state_bucket_name" {
  description = "Name of the S3 bucket for OpenTofu state"
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "region" {
  description = "AWS region"
  value       = var.region
}
