<a href="https://drive.brenodonascimento.com/" target="_blank" rel="noopener noreferrer"><img src="preview.png" alt="Preview" /></a>

Live demo: <a href="https://drive.brenodonascimento.com/" target="_blank" rel="noopener noreferrer">https://drive.brenodonascimento.com/</a>

# ☁️ Cloud Drive

A clean, minimal cloud storage application that allows users to upload, view, and delete files.

This project is designed for **quick setup** — just run Terraform and open the CloudFront URL.

---

<details>
<summary>🚀 What This Project Creates</summary>

Terraform automatically provisions:

* 🔐 Amazon Cognito User Pool
* ⚡ Cognito App Client
* 🌐 Cognito Hosted UI
* 🎨 Cognito Hosted UI Branding
* 📦 S3 Bucket (Frontend + Storage)
* 🔑 IAM Roles & Policies
* 🌍 CloudFront Distribution
* :robot: Lambda function

</details>

---

<details>
<summary>📦 Prerequisites</summary>

Install:

* Terraform ≥ 1.5
* AWS CLI
* AWS Account

Verify:

```bash
terraform -v
aws configure
```

</details>

---

<details>
<summary>🧰 Terraform Init</summary>

Set up backend.hcl with your own values

```bash
cp infra/backend.hcl.example infra/backend.hcl
```

You must pass it during `init`.

```bash
terraform -chdir=infra init -backend-config="backend.hcl"
```

</details>

---

<details>
<summary>🚀 Terraform Apply</summary>

<details>
<summary>Custom Domain (Optional)</summary>

If you want to use a custom domain, duplicate the tfvars file before applying:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

Then edit `infra/terraform.tfvars` and set **both**:

- `domain_name` -> "example.com"
- `acm_certificate_arn` -> must be an existing ACM certificate you create in AWS Certificate Manager with domain "*.example.com"

If you don't create `infra/terraform.tfvars`, Terraform will deploy using the default AWS URLs (CloudFront `*.cloudfront.net` and Cognito `*.amazoncognito.com`).

</details>

<details>
<summary>Command</summary>

Run:

```bash
terraform -chdir=infra apply
```
</details>

---

<details>
<summary>🌍 Access the Application</summary>

After Terraform finishes, it will output:

```
cloudfront_url = https://xxxxxxxx.cloudfront.net
```

Open the **CloudFront URL** in your browser.

You will automatically be:

1. Redirected to Cognito login
2. Authenticated
3. Redirected back to Cloud Drive
4. Access your dashboard

</details>

---

<details>
<summary>🔐 Authentication Flow</summary>

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

</details>

---

<details>
<summary>🧹 Destroy Resources</summary>

To remove everything:

```bash
terraform -chdir=infra destroy
```

</details>

---
