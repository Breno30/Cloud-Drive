## Setup Terraform infrastructure

**Branch name:** `feature/terraform-infra`

**Description**

Create the Terraform configuration to provision all required AWS resources for CloudDrive as described in `README.md`, using the folder structure in `structure.md`.

**Scope**

- Define providers and backend (if needed) in `infrastructure/terraform`.
- Create Terraform modules or files for S3, Cognito, Lambda, API Gateway, DynamoDB, and IAM.
- Ensure resource names and outputs are suitable for use by the backend and frontend (e.g. bucket name, user pool IDs, API URL).

**Acceptance Criteria**

- Running `terraform init` and `terraform apply` from `infrastructure/terraform` provisions:
  - S3 bucket for user file storage under `users/{user_id}/`.
  - Cognito user pool and app client configured for Hosted UI.
  - API Gateway REST API under `/api`.
  - Lambda functions for all backend operations.
  - DynamoDB `files` table with `user_id` (partition key) and `file_id` (sort key).
  - IAM roles and policies granting least-privilege access.
- Key resource identifiers (bucket name, table name, API URL, user pool IDs) are exposed via Terraform outputs for use by application code.
