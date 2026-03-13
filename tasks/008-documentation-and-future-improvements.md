## Improve documentation and future features

**Branch name:** `chore/docs-and-future-features`

**Description**

Enhance project documentation so that CloudDrive is easy to understand as a portfolio project, and capture next-step feature ideas as follow-up issues based on the “Future Improvements” section in `README.md`.

**Scope**

- Update `README.md` with:
  - Clear setup instructions (prerequisites, AWS, Terraform, Node/Python versions if applicable).
  - Step-by-step run/deploy instructions for backend and frontend.
  - Explanation of architecture with reference to `docs/architecture.md`.
- Ensure `docs/architecture.md` is aligned with the current implementation and includes key design decisions.
- Convert “Future Improvements” from the README into a short list of concrete issue ideas (e.g. file sharing links, folder support, search, previews, versioning, desktop sync) and, if desired, outline them in this file or as separate GitHub issues later.

**Acceptance Criteria**

- A new reader can understand what CloudDrive does, how it’s architected, and how to run/deploy it within a few minutes of reading the docs.
- `README.md` and `docs/architecture.md` accurately reflect the implemented stack and AWS resources.
- The “Future Improvements” section clearly maps to potential follow-up GitHub issues with brief descriptions.
