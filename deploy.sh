#!/bin/bash
# Security Monitoring Pipeline Deployment Script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}AWS Security Monitoring Pipeline Deployment${NC}"
echo "=================================================="
echo ""

# Skip AWS CLI configuration check for now
echo -e "${YELLOW}Note: Skipping AWS CLI configuration check.${NC}"
echo "Make sure your AWS credentials are properly configured before deploying."
echo ""

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
  echo -e "${RED}Error: Terraform is not installed.${NC}"
  echo "Please install Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli"
  exit 1
fi

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

# Plan Terraform deployment
echo -e "${YELLOW}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Prompt for confirmation
echo ""
echo -e "${YELLOW}Ready to deploy the security monitoring pipeline.${NC}"
read -p "Do you want to continue with the deployment? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
  echo -e "${RED}Deployment cancelled.${NC}"
  exit 0
fi

# Apply Terraform configuration
echo -e "${YELLOW}Deploying security monitoring pipeline...${NC}"
terraform apply tfplan

# Display outputs
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "=================================================="
echo ""
echo "Important resource information:"
terraform output

# Provide testing instructions
echo ""
echo -e "${YELLOW}Testing Instructions:${NC}"
echo "1. To trigger security events, perform actions like:"
echo "   - Modify IAM policies"
echo "   - Change security groups"
echo "   - Update S3 bucket policies"
echo ""
echo "2. To check DynamoDB for captured events:"
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
echo "   aws dynamodb scan --table-name $DYNAMODB_TABLE"
echo ""
echo "3. To view Lambda logs:"
LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)
echo "   aws logs get-log-events --log-group-name /aws/lambda/$LAMBDA_FUNCTION --limit 10"
echo ""
echo "4. To clean up all resources:"
echo "   terraform destroy"
echo ""
echo -e "${GREEN}Happy monitoring!${NC}"
