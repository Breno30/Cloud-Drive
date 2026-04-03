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

main();
