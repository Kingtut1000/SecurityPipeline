variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "prefix" {
  description = "Prefix to be added to all resource names"
  type        = string
  default     = "security-monitoring"
}


variable "retention_days" {
  description = "Number of days to retain events in DynamoDB"
  type        = number
  default     = 90
}

variable "log_level" {
  description = "Log level for Lambda function"
  type        = string
  default     = "INFO"
}

variable "alert_email" {
  description = "Email address to receive security alerts"
  type        = string
  default     = "default"
}
