cloud-drive/
│
├── README.md
├── .gitignore
│
├── frontend/
│   ├── index.html
│   ├── dashboard.html
│   │
│   ├── css/
│   │   └── styles.css
│   │
│   ├── js/
│   │   ├── config.js
│   │   ├── auth.js
│   │   ├── api.js
│   │   ├── upload.js
│   │   ├── files.js
│   │   └── dashboard.js
│   │
│   └── assets/
│       └── logo.png
│
├── backend/
│   ├── requirements.txt
│   │
│   ├── lambdas/
│   │   ├── create_upload_url/
│   │   │   └── handler.py
│   │   │
│   │   ├── list_files/
│   │   │   └── handler.py
│   │   │
│   │   ├── delete_file/
│   │   │   └── handler.py
│   │   │
│   │   ├── rename_file/
│   │   │   └── handler.py
│   │   │
│   │   └── get_download_url/
│   │       └── handler.py
│   │
│   ├── services/
│   │   ├── s3_service.py
│   │   ├── dynamodb_service.py
│   │   └── auth_service.py
│   │
│   ├── models/
│   │   └── file_model.py
│   │
│   └── utils/
│       ├── response.py
│       └── logger.py
│
├── infrastructure/
│   └── terraform/
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
│       │
│       ├── s3.tf
│       ├── dynamodb.tf
│       ├── cognito.tf
│       ├── lambda.tf
│       ├── api_gateway.tf
│       └── iam.tf
│
├── scripts/
│   ├── deploy.sh
│   └── destroy.sh
│
├── docs/
│   ├── architecture.md
│   ├── api.md
│   └── security.md
│
└── tests/
    ├── unit/
    │   └── test_s3_service.py
    │
    └── integration/
        └── test_upload_flow.py