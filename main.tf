# AWS Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Using an older version that might be more compatible
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudTrail Configuration
resource "aws_cloudtrail" "security_trail" {
  name                          = "${var.prefix}-security-trail"
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name = "${var.prefix}-security-trail"
  }
}

# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.prefix}-security-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.prefix}-security-logs-${random_string.bucket_suffix.result}"
  }
}

# Random suffix for S3 bucket name uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  
  # Wait for bucket to be created before setting policy
  depends_on = [aws_s3_bucket.log_bucket]
  
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket.id}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailList",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket.id}"
        }
    ]
}
POLICY
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Event Notification to SQS
resource "aws_s3_bucket_notification" "log_bucket_notification" {
  bucket = aws_s3_bucket.log_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.log_processing_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "AWSLogs/"
    filter_suffix = ".json.gz"
  }

  depends_on = [aws_sqs_queue_policy.log_processing_queue_policy]
}

# SQS Queue for Log Processing
resource "aws_sqs_queue" "log_processing_queue" {
  name                      = "${var.prefix}-log-processing-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 300  # Match Lambda function timeout

  tags = {
    Name = "${var.prefix}-log-processing-queue"
  }
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "log_processing_queue_policy" {
  queue_url = aws_sqs_queue.log_processing_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.log_processing_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.log_bucket.arn
          }
        }
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.prefix}-security-alerts"
  
  # Enable server-side encryption for the SNS topic
  kms_master_key_id = "alias/aws/sns"  # Use the AWS-managed KMS key for SNS
  
  tags = {
    Name = "${var.prefix}-security-alerts"
  }
}

# DynamoDB Table for Event Storage
resource "aws_dynamodb_table" "security_events" {
  name         = "${var.prefix}-security-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "EventId"
  range_key    = "Timestamp"

  attribute {
    name = "EventId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }

  tags = {
    Name = "${var.prefix}-security-events"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
