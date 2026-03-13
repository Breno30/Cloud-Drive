## Implement backend Lambda functions and API

**Branch name:** `feature/backend-lambdas-api`

**Description**

Implement the backend Lambda functions and API Gateway integration for CloudDrive, matching the endpoints and behaviors defined in `README.md` while aligning with the existing `backend/` structure in `structure.md`.

**Scope**

- Implement Lambda handlers for:
  - `create_upload_url`
  - `list_files`
  - `delete_file`
  - `rename_file`
  - `get_download_url`
- Wire handlers to API Gateway routes:
  - `POST /api/upload-url`
  - `GET /api/files`
  - `DELETE /api/files/{file_id}`
  - `PATCH /api/files/{file_id}`
  - `GET /api/download/{file_id}`
- Use Cognito JWT (`sub` claim) to derive `user_id` in every function.
- Use S3 and DynamoDB according to the schema and S3 key layout in `README.md`.
- Reuse or create `backend/services` and `backend/utils` modules as appropriate to keep handlers thin.

**Acceptance Criteria**

- All five Lambda functions exist and are deployed, following the naming and responsibilities in `README.md`.
- Each Lambda:
  - Extracts and validates `user_id` from the Cognito token.
  - Validates request parameters and returns appropriate HTTP status codes and JSON payloads.
  - Uses DynamoDB `files` table for metadata CRUD where appropriate.
  - Uses S3 keys under `users/{user_id}/` for all file operations.
- API Gateway routes correctly invoke the corresponding Lambdas and are protected by a Cognito Authorizer.
- Happy-path manual tests with a real token succeed for upload URL creation, listing, deletion, renaming, and download URL generation.
