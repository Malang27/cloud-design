# Terraform State Backend Configuration
# This file configures S3 backend for remote state storage with DynamoDB locking

# IMPORTANT: Before running terraform init, you must:
# 1. Create the S3 bucket: cloud-design-terraform-state
# 2. Create the DynamoDB table: terraform-locks
#
# Run these commands:
# aws s3api create-bucket --bucket cloud-design-terraform-state --region us-east-1
# aws s3api put-bucket-versioning --bucket cloud-design-terraform-state --versioning-configuration Status=Enabled
# aws s3api put-bucket-encryption --bucket cloud-design-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# aws dynamodb create-table \
#   --table-name terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1

# The actual backend configuration is in main.tf under terraform.backend
# This file is kept for documentation purposes
