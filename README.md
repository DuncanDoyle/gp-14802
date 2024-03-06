# Gloo-Platform-14802 Reproducer


## Installation

Add Gloo Platform Helm repo:
```
helm repo add gloo-platform https://storage.googleapis.com/gloo-platform/helm-charts
```

Export your Gloo Gateway License Key to an environment variable:
```
export GLOO_GATEWAY_LICENSE_KEY={your license key}
```

Install Gloo Gateway:
```
cd install
./install-gloo-gateway-with-helm.sh
```

> NOTE
> The Gloo Gateway version that will be installed is set in a variable at the top of the `install/install-gloo-gateway-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:
- Deploy Keycloak
- Deploy the HTTPBin service
- Deploy the VirtualGateway
- Deploy the OAuth ExtAuth policy
- Deploy the RouteTables

```
./setup.sh
```

## Create an OAuth Client.

Run the `keycloak.sh` script to create an OAuth client in Keycloak. The script will return the client-id and client-secret needed to fetch an accesstoken for a Client Credentials Grant login flow.

```
./keycloak.sh
```

## Run the test

1. Access the HTTPBin service without access-token. You will get a 403-Forbidden:

```
curl -v -H "Authorization: Bearer $ACCESS_TOKEN" http://api.example.com/httpbin/get
```

2. Fetch a an access-token from Keycloak using client-credentials grant flow and access the HTTPBin service. This request should be authorized and provide the valid response from upstream:

```
export CLIENT_ID={your client id}
export CLIENT_SECRET={your client secret}

export ACCESS_TOKEN=$(curl --request POST \
  --url 'http://keycloak.example.com/realms/master/protocol/openid-connect/token' \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data grant_type=client_credentials \
  --data client_id=$CLIENT_ID \
  --data client_secret=$CLIENT_SECRET | jq -r '.access_token')

curl -v -H "Authorization: Bearer $ACCESS_TOKEN" http://api.example.com/httpbin/get
```

3. Wait a minute for the token to expire and access the HTTPBin service again with the same token. You will now get a 401-Unauthorized:

```
curl -v -H "Authorization: Bearer $ACCESS_TOKEN" http://api.example.com/httpbin/get
```

## Conclusion
It seems that, according to the HTTP and OAuth specification, you should get a `401 - Unauthorized` both when you have not provided a token, or when the token is expired/invalid/malformed/revoken.

Second, the OAuth spec seems to dictate that in those cases, the response should contain a `WWW-Authenticate` header in the reponse.