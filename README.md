# AWS Security Monitoring Pipeline

This Terraform project implements a comprehensive security monitoring pipeline for AWS CloudTrail events. It enables real-time detection and alerting for security-relevant events in your AWS account, helping you maintain compliance and quickly respond to potential security incidents.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Components](#components)
  - [CloudTrail](#cloudtrail)
  - [S3 Bucket](#s3-bucket)
  - [SQS Queue](#sqs-queue)
  - [Lambda Function](#lambda-function)
  - [SNS Topic](#sns-topic)
  - [DynamoDB Table](#dynamodb-table)
- [Security Events](#security-events)
- [Prerequisites](#prerequisites)
- [Deployment Instructions](#deployment-instructions)
- [Configuration Options](#configuration-options)
- [Testing the Solution](#testing-the-solution)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Cost Optimization](#cost-optimization)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Extending the Solution](#extending-the-solution)
- [Cleanup](#cleanup)

# Architecture Overview

The solution implements a serverless event-driven architecture to monitor AWS CloudTrail logs for security events:

1. CloudTrail captures all API activity across your AWS account
2. CloudTrail logs are stored in a secure S3 bucket
3. When new log files are created, S3 event notifications trigger an SQS message
4. An SQS queue manages the processing workload and provides resilience
5. A Lambda function processes the logs, scanning for security events defined in a configuration file
6. When security events are detected, alerts are sent via SNS
7. Event details are stored in DynamoDB for auditing and investigation

## Components

### CloudTrail

CloudTrail is configured to:
- Capture all API events across all regions
- Include global service events
- Enable log file validation for integrity
- Store logs in a dedicated S3 bucket

### S3 Bucket

The S3 bucket for CloudTrail logs is configured with:
- Server-side encryption (AES-256)
- Public access blocking
- Versioning enabled
- Appropriate bucket policies for CloudTrail
- Event notifications to trigger processing

### SQS Queue

The SQS queue provides:
- Decoupling between S3 events and Lambda processing
- Buffering to handle traffic spikes
- Retry capabilities for processing failures

### Lambda Function

The Lambda function:
- Processes CloudTrail log files from S3
- Decompresses and parses the JSON content
- Scans for security events based on patterns defined in `monitored_events.json`
- Sends alerts via SNS when security events are detected
- Stores event details in DynamoDB
- Includes comprehensive error handling and logging

### SNS Topic

The SNS topic:
- Delivers security alerts to subscribed endpoints
- Supports email notifications (configurable)
- Can be extended to support additional notification channels (SMS, HTTP endpoints, etc.)

### DynamoDB Table

The DynamoDB table:
- Stores security event details for auditing
- Uses EventId as the partition key and Timestamp as the sort key
- Implements TTL for automatic data expiration (configurable)
- Uses on-demand capacity for cost optimization

## Security Events

The solution monitors for various security events, including:

- Unauthorized API calls
- Root account usage
- IAM policy changes
- CloudTrail configuration changes
- Console login failures
- Network configuration changes (VPC, security groups, etc.)
- S3 bucket policy changes
- AWS Config changes
- KMS key deletion

The full list of monitored events is defined in `monitored_events.json`

## Prerequisites

Before deploying this solution, you need to have the following:

- AWS CLI installed and configured with appropriate credentials
- Terraform installed (v1.0.0 or later)
- Python (for local testing of the Lambda function)
- Sufficient permissions to create the required AWS resources
- An AWS account

## Deployment Instructions

### Step 1: Clone and Prepare

1. Clone this repository to your local machine
2. Navigate to the project directory

### Step 2: Configure Variables

Review and update the variables in `variables.tf` as needed:

- `aws_region`: AWS region to deploy resources (default: us-east-1)
- `prefix`: Prefix for resource names (default: security-monitoring)
- `environment`: Environment name (default: test)
- `retention_days`: Number of days to retain events in DynamoDB (default: 90)
- `log_level`: Log level for Lambda function (default: INFO)
- `alert_email`: Email address to receive security alerts (optional)
- `terraform.tfvars`: You may change all of these variables here and leave variables.tf untouched

### Step 3: Initialize Terraform

Initialize the Terraform working directory:

```bash
terraform init
```

### Step 4: Review the Deployment Plan

Generate and review the Terraform execution plan:

```bash
terraform plan
```

This will show you all the resources that will be created.

### Step 5: Deploy the Solution

Apply the Terraform configuration:

```bash
terraform apply
```

Confirm the deployment by typing `yes` when prompted.

### Step 6: Verify Deployment

After deployment completes, Terraform will output important information about the created resources, including:

- CloudTrail name
- S3 bucket name
- SNS topic ARN
- Lambda function name
- DynamoDB table name

## Configuration Options

### Customizing Security Events

To customize the security events monitored by the solution:

1. Edit the `monitored_events.json` file
2. Add, modify, or remove event definitions based on your requirements
3. Each event definition can include:
   - `id`: Unique identifier for the event
   - `eventName`: CloudTrail event name to match
   - `eventSource`: AWS service source to match
   - `userIdentityType`: Type of user identity to match
   - `errorCode`: Error code to match
   - `resourceType`: Resource type to match
   - `description`: Human-readable description of the event
   - `severity`: Event severity (LOW, MEDIUM, HIGH, CRITICAL)

### Email Notifications

To receive email notifications for security alerts:

1. Set the `alert_email` variable to your email address
2. After deployment, confirm the subscription by clicking the link in the confirmation email

### Lambda Function Configuration

The Lambda function can be configured through environment variables:

- `SNS_TOPIC_ARN`: ARN of the SNS topic for alerts (set automatically)
- `DYNAMODB_TABLE`: Name of the DynamoDB table (set automatically)
- `LOG_LEVEL`: Logging level (INFO, DEBUG, etc.)
- `SECURITY_EVENTS_PATH`: Path to the security events configuration file

## Testing the Solution

To test the solution after deployment:

### Manual Testing

1. Perform actions that trigger security events, such as:
   - Attempting to use the root account
   - Creatiing and Deleting Access Key
   - Modifying security groups
   - Creating and Deleting S3 buckets

2. Check the CloudWatch Logs for the Lambda function to verify processing

3. Verify that events are stored in the DynamoDB table:

4. Confirm that alerts are sent to the SNS topic and delivered to subscribed endpoints

### Automated Testing

You can create a test script to simulate CloudTrail events:

1. Create a sample CloudTrail log file
2. Upload it to the S3 bucket
3. Monitor the Lambda function execution
4. Verify DynamoDB entries and SNS notifications

## Monitoring and Maintenance

### CloudWatch Metrics

Monitor the following CloudWatch metrics:

- Lambda function invocations and errors
- SQS queue depth and age of oldest message
- DynamoDB read/write capacity consumption
- S3 bucket size and request rates

### Logs

Review the following logs regularly:

- Lambda function logs in CloudWatch Logs
- CloudTrail logs for the monitoring infrastructure itself
- S3 access logs (if enabled)

### Updates

Periodically update:

- The `monitored_events.json` file to cover new security threats
- Lambda function runtime to the latest supported version
- IAM policies to follow security best practices

## Cost Optimization

This solution is designed to minimize costs for test environments:

- CloudTrail is configured with minimal settings
- Lambda uses minimal memory (256MB) and timeout (300s)
- DynamoDB uses on-demand capacity to avoid over-provisioning
- SQS standard queue with minimal retention period
- No additional CloudWatch alarms or dashboards by default

For further cost optimization:

- Add S3 lifecycle policies to transition older logs to cheaper storage classes
- Implement DynamoDB TTL to automatically expire old events
- Adjust Lambda memory based on actual usage patterns
- Consider using Reserved Capacity for DynamoDB in production environments

## Security Considerations

### Data Protection

- All S3 buckets are configured with server-side encryption
- Public access to S3 buckets is blocked
- CloudTrail log file validation is enabled
- DynamoDB tables are encrypted by default

### Identity and Access Management

- IAM roles follow the principle of least privilege
- Lambda function has minimal permissions required for operation
- S3 bucket policies restrict access to authorized services

### Logging and Monitoring

- Lambda function includes comprehensive logging
- CloudTrail itself is monitored for configuration changes
- Security events are stored in DynamoDB for auditing

### Compliance

This solution helps with compliance requirements by:

- Maintaining an audit trail of security-relevant events
- Providing real-time alerting for security incidents
- Storing event details for investigation and reporting

## Troubleshooting

### Common Issues

1. **Lambda function errors**:
   - Check CloudWatch Logs for error messages
   - Verify IAM permissions
   - Ensure the security_events.json file is properly formatted

2. **Missing alerts**:
   - Verify SNS topic subscriptions are confirmed
   - Check Lambda function logs for processing errors
   - Ensure the security event definitions match your expectations

3. **Performance issues**:
   - Increase Lambda memory if processing large log files
   - Adjust SQS visibility timeout if processing takes longer than expected
   - Consider implementing batching for high-volume environments


## Cleanup

To remove all resources created by this Terraform configuration:

```bash
terraform destroy
```

Confirm the destruction by typing `yes` when prompted.

This will remove all resources, including the CloudTrail trail, S3 bucket, and stored logs.
