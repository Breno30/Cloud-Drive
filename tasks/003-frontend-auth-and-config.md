## Implement frontend authentication and config

**Branch name:** `feature/frontend-auth-config`

**Description**

Implement the frontend authentication flow using Cognito Hosted UI and central configuration for API endpoints and Cognito details, wiring this into `index.html` and the JavaScript modules defined in `structure.md`.

**Scope**

- Implement `frontend/js/config.js` to hold:
  - API base URL (e.g. `/api` or full API Gateway URL).
  - Cognito user pool details and Hosted UI URLs.
- Implement `frontend/js/auth.js` to:
  - Redirect to Cognito Hosted UI for login.
  - Handle the callback and extract/store the JWT access token.
  - Expose helpers to get the current token and attach it to API requests.
- Update `frontend/index.html` to include a login button and load the appropriate JS modules.

**Acceptance Criteria**

- A user can click a login button on `index.html` and be redirected to the Cognito Hosted UI.
- After successful login, the app receives a valid JWT, stores it (e.g. in memory or local storage), and can read the `sub` claim when needed.
- All API calls from the frontend include the access token in the `Authorization` header using the format required by API Gateway + Cognito Authorizer.
- Configuration values (API URL, Cognito pool/app client IDs, region, etc.) are centralized in `config.js` and are easy to adjust per environment.
