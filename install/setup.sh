#!/bin/sh

pushd ..

printf "\nInstall Keycloak ...\n"
# Create Keycloak namespace if it does not yet exist
kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f keycloak/keycloak-secrets.yaml
kubectl apply -f keycloak/keycloak-db-pv.yaml
kubectl apply -f keycloak/keycloak-postgres.yaml
printf "\nWait for Keycloak Postgres readiness ...\n"
kubectl -n keycloak rollout status deploy/postgres

kubectl apply -f keycloak/keycloak.yaml
printf "\nWait for Keycloak readiness ...\n"
kubectl -n keycloak rollout status deploy/keycloak

printf "\nDeploy HTTPBin service ...\n"
kubectl apply -f apis/httpbin.yaml

printf "\nDeploy OAuth ExtAuthPolicy ...\n"
kubectl apply -f policies/extauth/auth-server.yaml
kubectl apply -f policies/extauth/oauth-api-auth-policy.yaml

printf "\nDeploy VirtualGateway ...\n"
kubectl apply -f virtualgateways/vg.yaml

printf "\nDeploy RouteTables ...\n"
kubectl apply -f routetables/api-example-com-rt.yaml
kubectl apply -f routetables/keycloak-example-com-rt.yaml

popd