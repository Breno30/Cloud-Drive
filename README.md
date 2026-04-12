# ☁️ Cloud Drive — AWS Cognito + S3 + CloudFront (Terraform)

A minimal cloud drive project using **AWS Cognito**, **S3**, **CloudFront**, and **Terraform**.

This project is designed for **quick setup** — just run Terraform and open the CloudFront URL.

---

# 🚀 What This Project Creates

Terraform automatically provisions:

* 🔐 Amazon Cognito User Pool
* ⚡ Cognito App Client
* 🌐 Cognito Hosted UI
* 📦 S3 Bucket (Frontend + Storage)
* 🔑 IAM Roles & Policies
* 🌍 CloudFront Distribution
* 🎨 Cognito Hosted UI Branding

---

# 📦 Prerequisites

Install:

* Terraform ≥ 1.5
* AWS CLI
* AWS Account

Verify:

```bash
terraform -v
aws configure
```

---

# 🧰 Terraform State (S3 Backend)

This repo now includes an `s3` backend block. You must configure it on init.
Create the S3 bucket (and optional DynamoDB table) separately before running `init`.

Option A: use the example file.

```bash
cp infra/backend.hcl.example infra/backend.hcl
terraform -chdir=infra init -backend-config=backend.hcl
```

Option B: pass values directly.

```bash
terraform -chdir=infra init \\
  -backend-config=\"bucket=your-terraform-state-bucket\" \\
  -backend-config=\"key=cloud-drive/terraform.tfstate\" \\
  -backend-config=\"region=us-east-1\" \\
  -backend-config=\"encrypt=true\"
```

If you also use a DynamoDB table for state locking, add:

```bash
  -backend-config=\"dynamodb_table=terraform-state-locks\"
```

---

# 🚀 Quick Start (Tutorial)

Just run:

```bash
terraform -chdir=infra init
terraform -chdir=infra apply
```

Optional: set a custom Cognito Hosted UI domain for the login URL (e.g. if you mapped your own domain to Cognito). You can pass it directly on the command line:

```bash
terraform -chdir=infra apply \
  -var="cognito_login_url=https://auth.example.com"
```

Terraform will automatically create:

* Cognito Authentication
* S3 Bucket
* CloudFront Distribution
* IAM Permissions

---

# 🌍 Access the Application

After Terraform finishes, Terraform will output:

```
cloudfront_url = https://xxxxxxxx.cloudfront.net
```

Open the **CloudFront URL** in your browser.

You will automatically be:

1. Redirected to Cognito login
2. Authenticate
3. Redirected back to Cloud Drive
4. Access your dashboard

No need to manually open Cognito Hosted UI.

---

# 🔐 Authentication Flow

```
User
 │
 ▼
CloudFront URL
 │
 ▼
Redirect to Cognito
 │
 ▼
Login
 │
 ▼
Redirect Back
 │
 ▼
Cloud Drive App
```

---

# 🧹 Destroy Resources

To remove everything:

```bash
terraform destroy
```

---
