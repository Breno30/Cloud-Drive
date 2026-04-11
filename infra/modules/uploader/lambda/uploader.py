import base64
import json
import os
import urllib.parse

import boto3
from botocore.exceptions import ClientError

s3 = boto3.client("s3")
cognito = boto3.client("cognito-identity")

BUCKET = os.environ["BUCKET"]
REGION = os.environ["REGION"]
USER_POOL_ID = os.environ["USER_POOL_ID"]
IDENTITY_POOL_ID = os.environ["IDENTITY_POOL_ID"]
QUOTA_BYTES = int(os.environ.get("QUOTA_BYTES", "104857600"))
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")

LOGIN_KEY = f"cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}"


def _cors_headers():
    return {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Headers": "authorization,content-type,x-file-name",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Max-Age": "300",
        "Vary": "Origin",
    }


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            **_cors_headers(),
        },
        "body": json.dumps(body),
    }


def _get_header(headers, name):
    if not headers:
        return ""
    return headers.get(name) or headers.get(name.lower()) or headers.get(name.upper()) or ""


def _sanitize_filename(value):
    if not value:
        return ""
    decoded = urllib.parse.unquote(value)
    decoded = decoded.replace("\\", "/")
    name = decoded.split("/")[-1]
    return name.strip()


def _get_identity_id(id_token):
    result = cognito.get_id(
        IdentityPoolId=IDENTITY_POOL_ID,
        Logins={LOGIN_KEY: id_token},
    )
    return result["IdentityId"]


def _get_usage_bytes(prefix):
    total = 0
    token = None
    while True:
        params = {"Bucket": BUCKET, "Prefix": prefix}
        if token:
            params["ContinuationToken"] = token
        response = s3.list_objects_v2(**params)
        for obj in response.get("Contents", []):
            total += int(obj.get("Size", 0))
            if total >= QUOTA_BYTES:
                return total
        if not response.get("IsTruncated"):
            break
        token = response.get("NextContinuationToken")
    return total


def handler(event, context):
    method = (((event.get("requestContext") or {}).get("http") or {}).get("method") or "").upper()
    if method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": _cors_headers(),
            "body": "",
        }

    if method != "POST":
        return _response(405, {"error": "method_not_allowed"})

    headers = event.get("headers") or {}
    auth = _get_header(headers, "authorization").strip()
    if not auth.lower().startswith("bearer "):
        return _response(401, {"error": "missing_bearer_token"})
    id_token = auth.split(" ", 1)[1].strip()
    if not id_token:
        return _response(401, {"error": "missing_bearer_token"})

    filename = _sanitize_filename(_get_header(headers, "x-file-name"))
    if not filename:
        return _response(400, {"error": "missing_file_name"})

    body = event.get("body")
    if body is None:
        return _response(400, {"error": "missing_body"})

    if event.get("isBase64Encoded"):
        try:
            data = base64.b64decode(body)
        except Exception:
            return _response(400, {"error": "invalid_base64_body"})
    else:
        if isinstance(body, str):
            data = body.encode("utf-8")
        else:
            data = body

    content_type = _get_header(headers, "content-type") or "application/octet-stream"
    file_size = len(data)
    if file_size <= 0:
        return _response(400, {"error": "empty_file"})

    try:
        identity_id = _get_identity_id(id_token)
    except Exception:
        return _response(401, {"error": "invalid_token"})

    prefix = f"users/{identity_id}/"
    key = f"{prefix}{filename}"
    usage_bytes = _get_usage_bytes(prefix)
    existing_size = 0
    try:
        head = s3.head_object(Bucket=BUCKET, Key=key)
        existing_size = int(head.get("ContentLength", 0))
    except ClientError as error:
        code = error.response.get("Error", {}).get("Code", "")
        if code not in {"404", "NoSuchKey", "NotFound"}:
            raise
    effective_usage = usage_bytes - existing_size + file_size
    if effective_usage > QUOTA_BYTES:
        return _response(
            413,
            {
                "error": "quota_exceeded",
                "quotaBytes": QUOTA_BYTES,
                "usageBytes": usage_bytes,
                "incomingBytes": file_size,
            },
        )
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=data,
        ContentType=content_type,
    )

    return _response(
        200,
        {
            "key": key,
            "size": file_size,
            "usageBytes": effective_usage,
            "quotaBytes": QUOTA_BYTES,
        },
    )
