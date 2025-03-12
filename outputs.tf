# Output values for the security monitoring infrastructure

output "cloudtrail_name" {
  description = "The name of the CloudTrail trail"
  value       = aws_cloudtrail.security_trail.name
}

output "log_bucket_name" {
  description = "The name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.log_bucket.id
}

output "log_bucket_arn" {
  description = "The ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.log_bucket.arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue for log processing"
  value       = aws_sqs_queue.log_processing_queue.url
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue for log processing"
  value       = aws_sqs_queue.log_processing_queue.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function processing logs"
  value       = aws_lambda_function.log_processor.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function processing logs"
  value       = aws_lambda_function.log_processor.arn
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table storing security events"
  value       = aws_dynamodb_table.security_events.name
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "subscription_status" {
  description = "Status of email subscription to SNS topic"
  value       = var.alert_email != "" ? "Email subscription created for ${var.alert_email}" : "No email subscription created"
}
