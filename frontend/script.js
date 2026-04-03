async function main() {
    try {
        const params = new URLSearchParams(window.location.search);
        const code = params.get("code");

        console.log(code);

        let tokenResult = getCachedTokens();
        if (!tokenResult) {
            if (!code) {
                throw new Error("Missing authorization code and no cached tokens.");
            }

            const myHeaders = new Headers();
            myHeaders.append("Content-Type", "application/x-www-form-urlencoded");

            const urlencoded = new URLSearchParams();
            urlencoded.append("grant_type", "authorization_code");
            urlencoded.append("client_id", CONFIG.clientId);
            urlencoded.append("code", code);
            urlencoded.append("redirect_uri", CONFIG.redirectUri);

            const tokenResponse = await fetch(CONFIG.tokenUrl, {
                method: "POST",
                headers: myHeaders,
                body: urlencoded,
                redirect: "follow"
            });

            tokenResult = await parseJsonResponse(tokenResponse, "token");
            cacheTokens(tokenResult);
        }

        console.log(tokenResult);

        const idToken = tokenResult.id_token;

        const myHeaders = new Headers();
        myHeaders.append("Content-Type", "application/x-amz-json-1.1");
        myHeaders.append("X-Amz-Target", "AWSCognitoIdentityService.GetId");

        const getIdResponse = await fetch(CONFIG.identityUrl, {
            method: "POST",
            headers: myHeaders,
            body: JSON.stringify({
                IdentityPoolId: CONFIG.identityPoolId,
                Logins: {
                    [`cognito-idp.us-east-1.amazonaws.com/${CONFIG.userPoolId}`]: idToken
                }
            }),
            redirect: "follow"
        });

        const getIdResult = await parseJsonResponse(getIdResponse, "get-id");
        console.log(getIdResult);

        const identityId = getIdResult.IdentityId;
        console.log(identityId);

        const credsResponse = await fetch(CONFIG.identityUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-amz-json-1.1",
                "X-Amz-Target": "AWSCognitoIdentityService.GetCredentialsForIdentity"
            },
            body: JSON.stringify({
                IdentityId: identityId,
                Logins: {
                    [`cognito-idp.us-east-1.amazonaws.com/${CONFIG.userPoolId}`]: idToken
                }
            }),
            redirect: "follow"
        });

        const credsResult = await parseJsonResponse(credsResponse, "get-creds");
        console.log(credsResult);

        await listFiles(credsResult.Credentials, identityId);
    } catch (error) {
        console.error(error);
    }
}

async function parseJsonResponse(response, label) {
    const text = await response.text();
    if (!text) {
        throw new Error(`${label} response was empty (status ${response.status})`);
    }
    try {
        return JSON.parse(text);
    } catch (error) {
        throw new Error(`${label} response was not valid JSON (status ${response.status}): ${text}`);
    }
}

function cacheTokens(tokenResult) {
    if (!CONFIG.useSessionStorage) {
        return;
    }
    sessionStorage.setItem("authTokens", JSON.stringify(tokenResult));
}

function getCachedTokens() {
    if (!CONFIG.useSessionStorage) {
        return null;
    }
    const raw = sessionStorage.getItem("authTokens");
    if (!raw) {
        return null;
    }
    try {
        const tokens = JSON.parse(raw);
        if (!tokens.id_token || isTokenExpired(tokens.id_token)) {
            sessionStorage.removeItem("authTokens");
            return null;
        }
        return tokens;
    } catch {
        sessionStorage.removeItem("authTokens");
        return null;
    }
}

function isTokenExpired(jwt) {
    const payload = parseJwt(jwt);
    if (!payload || typeof payload.exp !== "number") {
        return true;
    }
    const nowSeconds = Math.floor(Date.now() / 1000);
    return payload.exp <= nowSeconds;
}

function parseJwt(jwt) {
    const parts = jwt.split(".");
    if (parts.length !== 3) {
        return null;
    }
    try {
        const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
        const json = atob(base64);
        return JSON.parse(json);
    } catch {
        return null;
    }
}

async function listFiles(credentials, identityId) {
    if (CONFIG.bucket && CONFIG.region && credentials) {
        await listFilesWithCredentials(credentials, identityId);
        return;
    }
    if (CONFIG.listUrl) {
        await listFilesWithPresignedUrl(CONFIG.listUrl);
    }
}

async function listFilesWithCredentials(credentials, identityId) {
    await loadAwsSdk();

    window.AWS.config.update({
        region: CONFIG.region,
        credentials: new window.AWS.Credentials(
            credentials.AccessKeyId,
            credentials.SecretKey,
            credentials.SessionToken
        )
    });

    const s3 = new window.AWS.S3({ apiVersion: "2006-03-01" });
    const response = await s3
        .listObjectsV2({
            Bucket: CONFIG.bucket,
            Prefix: `${CONFIG.listPrefix}/${identityId}`
        })
        .promise();

    const items = (response.Contents || [])
        .map((item) => ({
            key: item.Key || "",
            lastModified: item.LastModified ? item.LastModified.toISOString() : "",
            size: item.Size || 0
        }))
        .filter((item) => item.key && !item.key.endsWith("/"));

    renderFileList(items);
}

async function listFilesWithPresignedUrl(url) {
    const listResponse = await fetch(url, {
        method: "GET",
        redirect: "follow"
    });

    const xmlText = await listResponse.text();
    const items = parseS3ListXml(xmlText);
    renderFileList(items);
}

function parseS3ListXml(xmlText) {
    const parser = new DOMParser();
    const xml = parser.parseFromString(xmlText, "application/xml");
    const contents = Array.from(xml.getElementsByTagName("Contents"));
    return contents
        .map((node) => ({
            key: getXmlText(node, "Key"),
            lastModified: getXmlText(node, "LastModified"),
            size: Number(getXmlText(node, "Size") || 0)
        }))
        .filter((item) => item.key && !item.key.endsWith("/"));
}

function getXmlText(parent, tagName) {
    const node = parent.getElementsByTagName(tagName)[0];
    return node ? node.textContent : "";
}

function renderFileList(items) {
    const listEl = document.getElementById("file-list");
    if (!listEl) {
        return;
    }
    listEl.innerHTML = "";

    const subtitle = document.getElementById("file-subtitle");
    if (subtitle) {
        subtitle.textContent = "Live data · S3 list";
    }

    if (!items.length) {
        listEl.appendChild(buildEmptyRow("No files found."));
        return;
    }

    items.forEach((item) => {
        const row = document.createElement("div");
        row.className = "file-row";

        const nameCell = document.createElement("div");
        nameCell.className = "file-name-cell";

        const icon = document.createElement("div");
        icon.className = "file-icon";
        icon.innerHTML = `<i class="${iconClassForKey(item.key)}"></i>`;

        const meta = document.createElement("div");
        meta.className = "file-meta";

        const name = document.createElement("div");
        name.className = "file-name";
        name.textContent = item.key.split("/").pop() || item.key;

        const sub = document.createElement("div");
        sub.className = "file-sub";
        sub.textContent = item.key;

        meta.appendChild(name);
        meta.appendChild(sub);
        nameCell.appendChild(icon);
        nameCell.appendChild(meta);

        const ownerCell = document.createElement("div");
        ownerCell.className = "file-cell";
        ownerCell.textContent = "You";

        const dateCell = document.createElement("div");
        dateCell.className = "file-cell";
        dateCell.textContent = formatDate(item.lastModified);

        const sizeCell = document.createElement("div");
        sizeCell.className = "file-cell";
        sizeCell.textContent = formatBytes(item.size);

        row.appendChild(nameCell);
        row.appendChild(ownerCell);
        row.appendChild(dateCell);
        row.appendChild(sizeCell);
        listEl.appendChild(row);
    });
}

function buildEmptyRow(message) {
    const row = document.createElement("div");
    row.className = "file-row";
    row.textContent = message;
    return row;
}

function iconClassForKey(key) {
    const lower = key.toLowerCase();
    if (lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".gif")) {
        return "fa-regular fa-image";
    }
    if (lower.endsWith(".zip")) {
        return "fa-solid fa-box-archive";
    }
    if (lower.endsWith(".pdf")) {
        return "fa-regular fa-file-pdf";
    }
    if (lower.endsWith(".doc") || lower.endsWith(".docx")) {
        return "fa-regular fa-file-word";
    }
    if (lower.endsWith(".txt") || lower.endsWith(".md")) {
        return "fa-regular fa-file-lines";
    }
    return "fa-regular fa-file";
}

function formatBytes(bytes) {
    if (!Number.isFinite(bytes) || bytes <= 0) {
        return "0 B";
    }
    const units = ["B", "KB", "MB", "GB", "TB"];
    let size = bytes;
    let unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex += 1;
    }
    const value = size >= 10 || unitIndex === 0 ? Math.round(size) : Math.round(size * 10) / 10;
    return `${value} ${units[unitIndex]}`;
}

function formatDate(iso) {
    if (!iso) {
        return "-";
    }
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) {
        return iso;
    }
    return date.toLocaleString();
}

let awsSdkLoadPromise = null;
function loadAwsSdk() {
    if (window.AWS) {
        return Promise.resolve();
    }
    if (awsSdkLoadPromise) {
        return awsSdkLoadPromise;
    }
    awsSdkLoadPromise = new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.src = CONFIG.awsSdkUrl;
        script.async = true;
        script.onload = () => resolve();
        script.onerror = () => reject(new Error("Failed to load AWS SDK."));
        document.head.appendChild(script);
    });
    return awsSdkLoadPromise;
}

window.addEventListener("DOMContentLoaded", main);
