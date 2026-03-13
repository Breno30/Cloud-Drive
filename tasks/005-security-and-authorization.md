## Enforce security and authorization requirements

**Branch name:** `feature/security-and-authorization`

**Description**

Ensure CloudDrive enforces the security requirements defined in `README.md`, including strict per-user isolation, short-lived presigned URLs, and correct use of Cognito-based authentication and authorization.

**Scope**

- Configure API Gateway to use a Cognito Authorizer for all `/api` routes.
- In every Lambda, validate the JWT and extract `user_id` from the `sub` claim.
- Ensure all S3 keys used by the backend follow `users/{user_id}/...` and that users cannot access or manipulate other users’ objects.
- Configure presigned URLs for both upload and download to expire within 60 seconds.
- Review IAM roles/policies to minimize permissions and avoid over-broad access (e.g. no wildcard access across all buckets/tables if avoidable).

**Acceptance Criteria**

- Requests without a valid Cognito token are rejected by API Gateway with an appropriate 4xx response.
- A user cannot list, download, rename, or delete files owned by another user, even with a crafted request.
- Generated presigned URLs for upload and download become unusable after ~60 seconds.
- Security review notes document how user isolation and token validation are enforced across the stack.
