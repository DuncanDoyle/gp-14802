#!/bin/bash

set +x -e

export KEYCLOAK_HOST=keycloak.example.com
export KC_ADMIN_PASS=admin
export PORTAL_HOST=developer.example.com


export KEYCLOAK_URL=http://$KEYCLOAK_HOST
echo "Keycloak URL: $KEYCLOAK_URL"
export APP_URL=http://$PORTAL_HOST

[[ -z "$KC_ADMIN_PASS" ]] && { echo "You must set KC_ADMIN_PASS env var to the password for a Keycloak admin account"; exit 1;}

# Set the Keycloak admin token
export KEYCLOAK_TOKEN=$(curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=$KC_ADMIN_PASS" -d "grant_type=password" "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | jq -r .access_token)

[[ -z "$KEYCLOAK_TOKEN" ]] && { echo "Failed to get Keycloak token - check KEYCLOAK_URL and KC_ADMIN_PASS"; exit 1;}


################################################ Service Account: portal-sa ################################################

# Register Service Account Client
export PORTAL_SA_CLIENT_ID=portal-sa
CREATE_PORTAL_SA_CLIENT_JSON=$(cat <<EOM
{ 
  "clientId": "$PORTAL_SA_CLIENT_ID" 
}
EOM
)
read -r regid secret <<<$(curl -k -X POST  -H "Authorization: bearer ${KEYCLOAK_TOKEN}" -H "Content-Type:application/json" -d "$CREATE_PORTAL_SA_CLIENT_JSON" ${KEYCLOAK_URL}/realms/master/clients-registrations/default|  jq -r '[.id, .secret] | @tsv')

export PORTAL_SA_CLIENT_SECRET=${secret}
export REG_ID=${regid}
[[ -z "$PORTAL_SA_CLIENT_SECRET" || $PORTAL_SA_CLIENT_SECRET == null ]] && { echo "Failed to create client in Keycloak"; exit 1;}

printf "\nCreated service account:\n"
printf "Client-ID: $PORTAL_SA_CLIENT_ID\n"
printf "Client-Secret: $PORTAL_SA_CLIENT_SECRET\n\n"
export CLIENT_ID=$PORTAL_SA_CLIENT_ID
export CLIENT_SECRET=$PORTAL_SA_CLIENT_SECRET

#Configure the Portal Service Account
CONFIGURE_CLIENT_SERVICE_ACCOUNT_JSON=$(cat <<EOM
{
  "publicClient": false, 
  "standardFlowEnabled": false, 
  "serviceAccountsEnabled": true, 
  "directAccessGrantsEnabled": false, 
  "authorizationServicesEnabled": false
}
EOM
)
curl -k -X PUT  -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_CLIENT_SERVICE_ACCOUNT_JSON" $KEYCLOAK_URL/admin/realms/master/clients/${REG_ID}

# Add the group attribute to the JWT token returned by Keycloak
# Add the group attribute in the JWT token returned by Keycloak
CONFIGURE_GROUP_CLAIM_IN_JWT_JSON=$(cat <<EOM
{
  "name": "group", 
  "protocol": "openid-connect", 
  "protocolMapper": "oidc-usermodel-attribute-mapper", 
  "config": {
    "claim.name": "group", 
    "jsonType.label": "String", 
    "user.attribute": "group", 
    "id.token.claim": "true", 
    "access.token.claim": "true"
  }
}
EOM
)
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/master/clients/${REG_ID}/protocol-mappers/models