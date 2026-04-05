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

# 🚀 Quick Start (Tutorial)

Just run:

```bash
terraform init
terraform apply
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
