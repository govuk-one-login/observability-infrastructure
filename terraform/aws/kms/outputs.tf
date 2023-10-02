output "aws_kms_key_this_id" {
  description = "The id of the KMS key."
  value       = aws_kms_key.this.id
}

output "aws_kms_key_this_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.this.arn
}

output "aws_iam_policy_read_write_arn" {
  description = "The ARN of the read write IAM policy."
  value       = aws_iam_policy.read_write.arn
}

output "aws_iam_policy_read_write_id" {
  description = "The id of the read write IAM policy."
  value       = aws_iam_policy.read_write.id
}

output "aws_iam_policy_read_arn" {
  description = "The ARN of the read IAM policy."
  value       = aws_iam_policy.read.arn
}

output "aws_iam_policy_read_id" {
  description = "The id of the read IAM policy."
  value       = aws_iam_policy.read.id
}