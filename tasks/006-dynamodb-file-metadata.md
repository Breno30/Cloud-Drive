## Implement DynamoDB file metadata handling

**Branch name:** `feature/dynamodb-file-metadata`

**Description**

Implement and wire up the DynamoDB `files` table usage across backend operations so that file metadata is consistently stored, listed, and cleaned up as described in `README.md`.

**Scope**

- Ensure Terraform creates the `files` table with:
  - Partition key `user_id`
  - Sort key `file_id`
- Implement `backend/services/dynamoService` (or equivalent) functions to:
  - Create metadata entries on upload.
  - List files for a given `user_id`.
  - Update filename on rename.
  - Delete metadata records when files are deleted.
- Ensure each Lambda uses these service functions instead of direct SDK calls where appropriate.

**Acceptance Criteria**

- After upload completes, a record exists in DynamoDB with:
  - `user_id`, `file_id`, `filename`, `s3_key`, `size`, `created_at`.
- `GET /api/files` returns data derived from DynamoDB and matches the example response shape in `README.md`.
- Renaming a file updates the `filename` (and any derived attributes if needed) in DynamoDB.
- Deleting a file removes the corresponding DynamoDB record.
- Basic failure paths (missing record, mismatched user, etc.) return clear 4xx/5xx errors.
