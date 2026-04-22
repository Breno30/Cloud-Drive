const STATE = {
    credentials: null,
    identityId: null,
    idToken: null,
    files: [],
    isUploading: false,
    uploadingFileName: ""
};

const MAX_UPLOAD_BYTES = 1 * 1024 * 1024;

window.addEventListener("DOMContentLoaded", () => {
    main().catch((error) => console.error(error));
});

async function main() {
    const params = new URLSearchParams(window.location.search);
    const code = params.get("code");

    const tokenResult = await getTokens(code);
    stripAuthorizationCodeFromUrl();
    const idToken = tokenResult?.id_token;
    if (!idToken) {
        throw new Error("Token response did not include an id_token.");
    }
    STATE.idToken = idToken;
    renderUserFromToken(idToken);
    const identityId = await getIdentityId(idToken);
    const credentials = await getCredentials(identityId, idToken);

    STATE.credentials = credentials;
    STATE.identityId = identityId;

    setupLogout();
    setupUpload();
    setupSearch();
    await listFiles({ credentials, identityId });
}

function stripAuthorizationCodeFromUrl() {
    const url = new URL(window.location.href);
    if (!url.searchParams.has("code")) {
        return;
    }
    url.searchParams.delete("code");
    window.history.replaceState(null, "", url.toString());
}

async function getTokens(code) {
    const cached = getCachedTokens();
    if (cached) {
        return cached;
    }
    if (!code) {
        redirectToLogin();
        return new Promise(() => {});
    }

    const headers = new Headers();
    headers.append("Content-Type", "application/x-www-form-urlencoded");

    const urlencoded = new URLSearchParams();
    urlencoded.append("grant_type", "authorization_code");
    urlencoded.append("client_id", CONFIG.clientId);
    urlencoded.append("code", code);
    urlencoded.append("redirect_uri", CONFIG.redirectUri);

    const response = await fetch(CONFIG.tokenUrl, {
        method: "POST",
        headers,
        body: urlencoded,
        redirect: "follow"
    });

    const result = await parseJsonResponse(response, "token");
    cacheTokens(result);
    return result;
}

function redirectToLogin() {
    const loginUrl = buildLoginUrl();
    if (!loginUrl) {
        throw new Error("Missing authorization code and no login URL configuration.");
    }
    window.location.replace(loginUrl);
}

function buildLoginUrl() {
    const url = new URL(CONFIG.loginUrl);

    // add /login to the path
    url.pathname = `${url.pathname.replace(/\/$/, "")}/login`;

    url.searchParams.set("response_type", "code");
    url.searchParams.set("client_id", CONFIG.clientId);
    url.searchParams.set("redirect_uri", CONFIG.redirectUri);

    if (!url.searchParams.get("scope")) {
        url.searchParams.set("scope", CONFIG.scopes || "email openid phone");
    }

    return url.toString();
}

async function getIdentityId(idToken) {
    const response = await fetch(CONFIG.identityUrl, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-amz-json-1.1",
            "X-Amz-Target": "AWSCognitoIdentityService.GetId"
        },
        body: JSON.stringify({
            IdentityPoolId: CONFIG.identityPoolId,
            Logins: {
                [cognitoLoginKey()]: idToken
            }
        }),
        redirect: "follow"
    });

    const result = await parseJsonResponse(response, "get-id");
    return result.IdentityId;
}

async function getCredentials(identityId, idToken) {
    const response = await fetch(CONFIG.identityUrl, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-amz-json-1.1",
            "X-Amz-Target": "AWSCognitoIdentityService.GetCredentialsForIdentity"
        },
        body: JSON.stringify({
            IdentityId: identityId,
            Logins: {
                [cognitoLoginKey()]: idToken
            }
        }),
        redirect: "follow"
    });

    const result = await parseJsonResponse(response, "get-creds");
    return result.Credentials;
}

function cognitoLoginKey() {
    return `cognito-idp.${CONFIG.region}.amazonaws.com/${CONFIG.userPoolId}`;
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
    if (typeof jwt !== "string" || !jwt) {
        return null;
    }
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

function renderUserFromToken(idToken) {
    const claims = parseJwt(idToken);
    if (!claims) {
        return;
    }

    const name =
        claims.name ||
        [claims.given_name, claims.family_name].filter(Boolean).join(" ") ||
        claims.preferred_username ||
        claims["cognito:username"] ||
        claims.email ||
        "User";
    const email = claims.email || claims["cognito:username"] || "";

    const nameEl = document.getElementById("user-name");
    if (nameEl) {
        nameEl.textContent = name;
    }

    const emailEl = document.getElementById("user-email");
    if (emailEl) {
        emailEl.textContent = email || "-";
    }

    const avatarEl = document.getElementById("user-avatar");
    if (avatarEl) {
        avatarEl.textContent = initialsForUser(name || email);
    }
}

function initialsForUser(value) {
    if (!value) {
        return "--";
    }
    const base = value.includes("@") ? value.split("@")[0] : value;
    const parts = base.trim().split(/\s+/).filter(Boolean);
    if (!parts.length) {
        return "--";
    }
    if (parts.length === 1) {
        return parts[0].slice(0, 2).toUpperCase();
    }
    return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

async function listFiles({ credentials, identityId }) {
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

    const s3 = createS3Client(credentials);
    const response = await s3
        .listObjectsV2({
            Bucket: CONFIG.bucket,
            Prefix: buildUserPrefix(identityId)
        })
        .promise();

    const items = (response.Contents || [])
        .map((item) => ({
            key: item.Key || "",
            lastModified: item.LastModified ? item.LastModified.toISOString() : "",
            size: item.Size || 0
        }))
        .filter((item) => item.key && !item.key.endsWith("/"));

    STATE.files = items;
    renderFileList(items);
    updateStorageUsage(items);
}

async function listFilesWithPresignedUrl(url) {
    const listResponse = await fetch(url, {
        method: "GET",
        redirect: "follow"
    });

    const xmlText = await listResponse.text();
    const items = parseS3ListXml(xmlText);
    STATE.files = items;
    renderFileList(items);
    updateStorageUsage(items);
}

function buildUserPrefix(identityId) {
    const base = (CONFIG.listPrefixBase || "users/").replace(/\/?$/, "/");
    if (!identityId) {
        return base;
    }
    return `${base}${identityId}/`;
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
        if (!STATE.isUploading) {
            listEl.appendChild(buildEmptyRow("No files found."));
            return;
        }
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
    name.textContent = filenameFromKey(item.key);


        meta.appendChild(name);
        nameCell.appendChild(icon);
        nameCell.appendChild(meta);

        const dateCell = document.createElement("div");
        dateCell.className = "file-cell";
        dateCell.innerHTML = `<span class="file-label">Modified</span>${formatDate(
            item.lastModified
        )}`;

        const sizeCell = document.createElement("div");
        sizeCell.className = "file-cell";
        sizeCell.innerHTML = `<span class="file-label">Size</span>${formatBytes(item.size)}`;

        const downloadCell = document.createElement("div");
        downloadCell.className = "file-actions";
        const downloadLabel = document.createElement("span");
        downloadLabel.className = "file-label";
        downloadLabel.textContent = "Download";
        downloadCell.appendChild(downloadLabel);
        const downloadButton = document.createElement("button");
        downloadButton.type = "button";
        downloadButton.className = "tiny-icon primary";
        downloadButton.title = "Download";
        downloadButton.setAttribute("aria-label", "Download");
        downloadButton.innerHTML = `<i class="fa-solid fa-download"></i><span class="button-text">Download</span>`;
        downloadButton.addEventListener("click", (event) => {
            event.stopPropagation();
            downloadFile(item.key).catch((error) => console.error(error));
        });
        downloadCell.appendChild(downloadButton);

        const deleteCell = document.createElement("div");
        deleteCell.className = "file-actions";
        const deleteLabel = document.createElement("span");
        deleteLabel.className = "file-label";
        deleteLabel.textContent = "Delete";
        deleteCell.appendChild(deleteLabel);
        const deleteButton = document.createElement("button");
        deleteButton.type = "button";
        deleteButton.className = "tiny-icon danger";
        deleteButton.title = "Delete";
        deleteButton.setAttribute("aria-label", "Delete");
        deleteButton.innerHTML = `<i class="fa-solid fa-trash"></i><span class="button-text">Delete</span>`;
        deleteButton.addEventListener("click", async (event) => {
            event.stopPropagation();
            try {
                const confirmed = window.confirm(
                    `Delete "${filenameFromKey(item.key)}"? This cannot be undone.`
                );
                if (!confirmed) {
                    return;
                }
                await deleteFile(item.key);
                await listFiles({ credentials: STATE.credentials, identityId: STATE.identityId });
            } catch (error) {
                console.error(error);
            }
        });
        deleteCell.appendChild(deleteButton);

        row.addEventListener("click", () => {
            downloadFile(item.key).catch((error) => console.error(error));
        });

        row.appendChild(nameCell);
        row.appendChild(dateCell);
        row.appendChild(sizeCell);
        row.appendChild(downloadCell);
        row.appendChild(deleteCell);
        listEl.appendChild(row);
    });

    if (STATE.isUploading) {
        const uploadingRow = buildUploadingRow(STATE.uploadingFileName);
        listEl.prepend(uploadingRow);
    }
}

function setupSearch() {
    const input = document.getElementById("search-input");
    if (!input) {
        return;
    }
    input.addEventListener("input", () => {
        const query = input.value.trim().toLowerCase();
        if (!query) {
            renderFileList(STATE.files);
            return;
        }
        const filtered = STATE.files.filter((item) =>
            filenameFromKey(item.key).toLowerCase().includes(query)
        );
        renderFileList(filtered);
    });
}

function updateStorageUsage(items) {
    const fillEl = document.getElementById("storage-meter-fill");
    const usedEl = document.getElementById("storage-used");
    const totalEl = document.getElementById("storage-total");
    const percentEl = document.getElementById("storage-percent");
    if (!fillEl || !usedEl || !totalEl || !percentEl) {
        return;
    }
    const totalBytes = Array.isArray(items)
        ? items.reduce((sum, item) => sum + (Number(item.size) || 0), 0)
        : 0;
    const quotaBytes =
        Number.isFinite(Number(CONFIG.storageQuotaBytes)) && Number(CONFIG.storageQuotaBytes) > 0
            ? Number(CONFIG.storageQuotaBytes)
            : 10 * 1024 * 1024 * 1024;
    const ratio = quotaBytes > 0 ? totalBytes / quotaBytes : 0;
    const percent = Math.min(100, Math.max(0, Math.round(ratio * 100)));

    fillEl.style.width = `${percent}%`;
    usedEl.textContent = formatBytes(totalBytes);
    totalEl.textContent = formatBytes(quotaBytes);
    percentEl.textContent = `≈ ${percent}%`;
}

function showStorageWarning(message) {
    const warningEl = document.getElementById("storage-warning");
    if (!warningEl) {
        return;
    }
    warningEl.textContent = message;
    warningEl.classList.add("is-visible");
}

function clearStorageWarning() {
    const warningEl = document.getElementById("storage-warning");
    if (!warningEl) {
        return;
    }
    warningEl.textContent = "";
    warningEl.classList.remove("is-visible");
}

function setupUpload() {
    const button = document.getElementById("upload-button");
    const input = document.getElementById("upload-input");
    if (!button || !input) {
        return;
    }

    button.addEventListener("click", () => {
        input.click();
    });

    input.addEventListener("change", async () => {
        const file = input.files && input.files[0];
        if (!file) {
            return;
        }
        clearStorageWarning();
        if (file.size > MAX_UPLOAD_BYTES) {
            showStorageWarning(
                `Max upload size is ${formatBytes(MAX_UPLOAD_BYTES)}. Selected file is ${formatBytes(file.size)}.`
            );
            input.value = "";
            return;
        }
        try {
            setUploadingState(true, file);
            await uploadFile(file);
            input.value = "";
            await listFiles({ credentials: STATE.credentials, identityId: STATE.identityId });
        } catch (error) {
            console.error(error);
        } finally {
            setUploadingState(false);
        }
    });
}

function setUploadingState(isUploading, file) {
    STATE.isUploading = isUploading;
    STATE.uploadingFileName = isUploading && file ? file.name : "";

    const button = document.getElementById("upload-button");
    const input = document.getElementById("upload-input");
    if (button) {
        button.classList.toggle("is-uploading", isUploading);
        button.setAttribute("aria-busy", isUploading ? "true" : "false");
        const label = button.querySelector(".upload-label");
        if (label) {
            label.textContent = isUploading ? "Uploading" : "Upload";
        }
    }
    if (input) {
        input.disabled = isUploading;
    }

    const listEl = document.getElementById("file-list");
    if (!listEl) {
        return;
    }

    const existing = document.getElementById("uploading-row");
    if (isUploading) {
        if (!existing) {
            listEl.prepend(buildUploadingRow(STATE.uploadingFileName));
        } else if (file) {
            const nameEl = existing.querySelector(".file-name");
            if (nameEl) {
                nameEl.textContent = file.name;
            }
        }
    } else if (existing) {
        existing.remove();
    }
}

function buildUploadingRow(filename) {
    const row = document.createElement("div");
    row.className = "file-row uploading-row";
    row.id = "uploading-row";

    const nameCell = document.createElement("div");
    nameCell.className = "file-name-cell";

    const icon = document.createElement("div");
    icon.className = "file-icon";
    icon.innerHTML = '<i class="fa-solid fa-cloud-arrow-up"></i>';

    const meta = document.createElement("div");
    meta.className = "file-meta";

    const name = document.createElement("div");
    name.className = "file-name";
    name.textContent = filename || "Uploading file";

    const sub = document.createElement("div");
    sub.className = "file-sub upload-ellipsis";
    sub.textContent = "Uploading";

    meta.appendChild(name);
    meta.appendChild(sub);
    nameCell.appendChild(icon);
    nameCell.appendChild(meta);

    const dateCell = document.createElement("div");
    dateCell.className = "file-cell";
    dateCell.textContent = "In progress";

    const sizeCell = document.createElement("div");
    sizeCell.className = "file-cell";
    sizeCell.textContent = "--";

    const downloadCell = document.createElement("div");
    downloadCell.className = "file-actions";
    downloadCell.innerHTML =
        '<span class="file-label">Download</span><button class="tiny-icon" type="button" disabled aria-hidden="true"><i class="fa-solid fa-ellipsis"></i></button>';

    const deleteCell = document.createElement("div");
    deleteCell.className = "file-actions";
    deleteCell.innerHTML =
        '<span class="file-label">Delete</span><button class="tiny-icon" type="button" disabled aria-hidden="true"><i class="fa-solid fa-ellipsis"></i></button>';

    row.appendChild(nameCell);
    row.appendChild(dateCell);
    row.appendChild(sizeCell);
    row.appendChild(downloadCell);
    row.appendChild(deleteCell);

    return row;
}

function setupLogout() {
    const button = document.getElementById("logout-button");
    if (!button) {
        return;
    }
    button.addEventListener("click", () => {
        if (CONFIG.useSessionStorage) {
            sessionStorage.removeItem("authTokens");
        }
        STATE.credentials = null;
        STATE.identityId = null;
        STATE.idToken = null;
        const loginUrl = buildLoginUrl();
        if (loginUrl) {
            window.location.replace(loginUrl);
            return;
        }
        const cleanUrl = new URL(window.location.href);
        cleanUrl.searchParams.delete("code");
        window.location.replace(cleanUrl.toString());
    });
}

async function uploadFile(file) {
    if (CONFIG.uploadUrl) {
        await uploadViaLambda(file);
        return;
    }

    if (!STATE.credentials || !STATE.identityId) {
        throw new Error("Missing credentials or identityId for upload.");
    }

    await loadAwsSdk();

    const s3 = createS3Client(STATE.credentials);
    const key = `${buildUserPrefix(STATE.identityId)}${file.name}`;

    await s3
        .upload({
            Bucket: CONFIG.bucket,
            Key: key,
            Body: file,
            ContentType: file.type || "application/octet-stream"
        })
        .promise();
}

async function uploadViaLambda(file) {
    if (!STATE.idToken) {
        throw new Error("Missing id token for upload.");
    }
    if (!CONFIG.uploadUrl) {
        throw new Error("Missing upload URL configuration.");
    }

    const response = await fetch(CONFIG.uploadUrl, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${STATE.idToken}`,
            "X-File-Name": file.name,
            "Content-Type": file.type || "application/octet-stream"
        },
        body: file
    });

    if (!response.ok) {
        const text = await response.text();
        let payload = null;
        try {
            payload = JSON.parse(text);
        } catch {
            payload = null;
        }
        if (payload && payload.error === "quota_exceeded") {
            const usage = formatBytes(payload.usageBytes);
            const quota = formatBytes(payload.quotaBytes);
            const incoming = formatBytes(payload.incomingBytes);
            showStorageWarning(
                `Storage limit reached. ${usage} used of ${quota}. File size ${incoming}.`
            );
        }
        throw new Error(`Upload failed (status ${response.status}): ${text}`);
    }

    clearStorageWarning();
}

async function downloadFile(key) {
    if (!key) {
        return;
    }

    let url = "";
    if (STATE.credentials && STATE.identityId && CONFIG.bucket && CONFIG.region) {
        await loadAwsSdk();
        const s3 = createS3Client(STATE.credentials);
        url = s3.getSignedUrl("getObject", {
            Bucket: CONFIG.bucket,
            Key: key,
            Expires: 60
        });
    }

    await triggerBrowserDownload(url, key);
}

async function deleteFile(key) {
    if (!key) {
        return;
    }
    if (!STATE.credentials || !STATE.identityId) {
        throw new Error("Missing credentials or identityId for delete.");
    }
    await loadAwsSdk();
    const s3 = createS3Client(STATE.credentials);
    await s3
        .deleteObject({
            Bucket: CONFIG.bucket,
            Key: key
        })
        .promise();
}

async function triggerBrowserDownload(url, key) {
    const filename = filenameFromKey(key) || "download";
    try {
        const response = await fetch(url, { method: "GET" });
        if (!response.ok) {
            throw new Error(`Download failed (status ${response.status})`);
        }
        const blob = await response.blob();
        const objectUrl = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = objectUrl;
        link.download = filename;
        link.rel = "noopener";
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(objectUrl);
    } catch (error) {
        console.error(error);
        // Fallback: attempt a direct navigation download.
        const link = document.createElement("a");
        link.href = url;
        link.download = filename;
        link.rel = "noopener";
        document.body.appendChild(link);
        link.click();
        link.remove();
    }
}

function encodeS3Key(key) {
    return encodeURIComponent(key).replace(/%2F/g, "/");
}

function filenameFromKey(key) {
    return key.split("/").pop() || key;
}

function createS3Client(credentials) {
    window.AWS.config.update({
        region: CONFIG.region,
        credentials: new window.AWS.Credentials(
            credentials.AccessKeyId,
            credentials.SecretKey,
            credentials.SessionToken
        )
    });
    return new window.AWS.S3({ apiVersion: "2006-03-01" });
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
