## Define deployment process and environments

**Branch name:** `chore/deployment-and-environments`

**Description**

Define and document the deployment workflow for CloudDrive, covering Terraform, Lambda packaging, and frontend hosting, so the system can be reliably deployed to at least one environment.

**Scope**

- Document and/or script deployment steps described in `README.md`:
  - `terraform init` and `terraform apply` from `infrastructure/terraform`.
  - Packaging and deploying Lambda code (e.g. via zip + upload or CI/CD).
  - Deploying the frontend (e.g. S3 static hosting, CloudFront, or similar).
- Provide environment variable configuration for Lambdas (`BUCKET_NAME`, `DYNAMODB_TABLE`, `AWS_REGION`) and ensure they are wired from Terraform where possible.
- Optionally define separate configuration for dev vs prod (even if both use the same AWS account initially).

**Acceptance Criteria**

- A new developer can follow a single document or script to deploy CloudDrive end-to-end.
- After deployment, all core flows work in the target environment: login, upload, list, rename, delete, and download.
- Environment variables in all Lambdas are correctly set and no hard-coded environment-specific values remain in code.
