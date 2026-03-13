# CloudDrive – Serverless S3 Personal Storage

## Overview

CloudDrive is a serverless web application that allows users to store and manage files in a cloud storage system similar to Google Drive.

The system uses AWS serverless services to provide authentication, file uploads, and file management without managing servers.

Users authenticate via Cognito and can:

* upload files
* list files
* delete files
* rename files
* download files

Files are stored in S3 and metadata is stored in DynamoDB.

---

# Technology Stack

## Frontend

Vanilla web stack:

* HTML
* CSS
* JavaScript (no framework)

The frontend communicates with the backend via REST API.

Authentication is handled using Cognito Hosted UI.

---

## Backend

Language:

Python 3.11

Runtime environment:

AWS Lambda functions.

Python libraries:

* boto3
* json
* uuid
* datetime

---

## Infrastructure

All infrastructure must be defined using Terraform.

Services used:

* Amazon S3 (file storage)
* Amazon Cognito (authentication)
* AWS Lambda (backend functions)
* Amazon API Gateway (REST API)
* Amazon DynamoDB (file metadata)
* IAM (permissions)

---

# System Architecture

High level architecture:

User → Frontend → API Gateway → Lambda → AWS Services

Detailed flow:

1. User logs in through Cognito Hosted UI.
2. Cognito returns a JWT access token.
3. Frontend stores the token.
4. API Gateway uses a Cognito Authorizer to validate requests.
5. Valid requests trigger Lambda functions.
6. Lambda functions interact with S3 and DynamoDB.

---

# File Storage Structure

Each user has a dedicated namespace in S3.

Bucket structure:

bucket-name/
users/
{user_id}/
file1.png
document.pdf

The user_id must come from the Cognito JWT claim "sub".

---

# DynamoDB Table

Table name:

files

Partition key:

user_id

Sort key:

file_id

Attributes:

file_id
user_id
filename
s3_key
size
created_at

Example record:

{
"user_id": "abc123",
"file_id": "file789",
"filename": "photo.png",
"s3_key": "users/abc123/photo.png",
"size": 102394,
"created_at": "2026-03-12T12:00:00Z"
}

---

# Backend API

Base URL:

/api

Endpoints:

POST /upload-url

Purpose:

Generate a presigned URL to upload a file to S3.

Request:

{
"filename": "photo.png"
}

Response:

{
"upload_url": "https://..."
}

---

GET /files

Purpose:

List user files.

Response:

[
{
"file_id": "123",
"filename": "photo.png",
"size": 102394
}
]

---

DELETE /files/{file_id}

Purpose:

Delete a file.

Steps:

1. Retrieve metadata from DynamoDB
2. Delete object from S3
3. Remove record from DynamoDB

---

PATCH /files/{file_id}

Purpose:

Rename a file.

Request:

{
"filename": "new-name.png"
}

---

GET /download/{file_id}

Purpose:

Generate a presigned download URL.

Response:

{
"url": "https://..."
}

---

# Lambda Functions

The backend must contain the following Lambda functions:

create_upload_url
list_files
delete_file
rename_file
get_download_url

Each Lambda function must:

* extract user_id from Cognito token
* validate request
* interact with DynamoDB and/or S3
* return JSON responses

---

# Frontend Requirements

The frontend must contain:

index.html
dashboard.html

JavaScript modules:

auth.js
api.js
upload.js
files.js

Features:

Login button
File upload button
File list view
Delete file button
Download file button

Uploads must use S3 presigned URLs.

---

# Security Requirements

Authentication:

Cognito Hosted UI.

Authorization:

API Gateway Cognito Authorizer.

User isolation:

Each user may only access objects under:

users/{user_id}/

Presigned URLs must expire within 60 seconds.

---

# Terraform Infrastructure

Terraform must create:

S3 bucket
Cognito user pool
Cognito app client
API Gateway REST API
Lambda functions
DynamoDB table
IAM roles and policies

Terraform folder structure:

infrastructure/terraform/

Files required:

provider.tf
variables.tf
s3.tf
cognito.tf
lambda.tf
dynamodb.tf
api_gateway.tf
iam.tf

---

# Deployment

Deployment steps:

1. Run Terraform

terraform init
terraform apply

2. Upload Lambda code

3. Configure environment variables

4. Deploy frontend (static hosting or S3 website)

---

# Environment Variables

Lambda functions must use:

BUCKET_NAME
DYNAMODB_TABLE
AWS_REGION

---

# Project Structure

cloud-drive/

frontend/
index.html
dashboard.html
css/
js/

backend/
lambdas/
services/

infrastructure/
terraform/

docs/

---

# Future Improvements

Possible future features:

file sharing links
folder support
file search
file previews
versioning
desktop sync client

---

# Goal

The goal of this project is to demonstrate knowledge of:

serverless architecture
secure authentication
cloud storage design
Infrastructure as Code
scalable backend systems

This project should be suitable as a portfolio project for cloud engineering or backend roles.

# Cloud-Drive
