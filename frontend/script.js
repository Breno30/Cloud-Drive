async function main() {
    try {
        const params = new URLSearchParams(window.location.search);
        const code = params.get("code");

        console.log(code);
        var myHeaders = new Headers();
        myHeaders.append("Content-Type", "application/x-www-form-urlencoded");

        var urlencoded = new URLSearchParams();
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

        const tokenResult = await tokenResponse.json();
        console.log(tokenResult);

        const idToken = tokenResult.id_token;

        myHeaders = new Headers();
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

        const getIdResult = await getIdResponse.json();
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

        const credsResult = await credsResponse.json();
        console.log(credsResult);
    } catch (error) {
        console.error(error);
    }
}

main();
