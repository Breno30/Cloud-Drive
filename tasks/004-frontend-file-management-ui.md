## Build frontend file management UI

**Branch name:** `feature/frontend-file-management-ui`

**Description**

Create the dashboard UI for managing files (upload, list, delete, rename, download) using vanilla HTML/CSS/JS, leveraging the REST API and presigned URLs defined in `README.md` and the structure from `structure.md`.

**Scope**

- Implement `frontend/dashboard.html` layout for:
  - File upload control and button.
  - File list/table with filename, size, and actions.
  - Buttons/controls for delete, rename, and download.
- Implement or update JS modules:
  - `frontend/js/upload.js` to request upload URLs and perform S3 uploads.
  - `frontend/js/files.js` to list files and invoke delete/rename/download operations.
  - `frontend/js/api.js` and `frontend/js/dashboard.js` to orchestrate API calls and DOM updates.
- Ensure uploads use the presigned URL returned by `POST /api/upload-url`.

**Acceptance Criteria**

- After login, navigating to `dashboard.html` shows:
  - A file upload control that successfully uploads to S3 using a presigned URL.
  - A file list populated via `GET /api/files` for the logged-in user.
  - Working delete action that removes a file (both S3 object and DynamoDB record) via `DELETE /api/files/{file_id}`.
  - Working rename action via `PATCH /api/files/{file_id}` with an inline or modal rename UI.
  - Working download action that uses `GET /api/download/{file_id}` to obtain a presigned URL and triggers a browser download.
- UI is reasonably styled using `frontend/css/styles.css` and looks clean and usable on desktop.
