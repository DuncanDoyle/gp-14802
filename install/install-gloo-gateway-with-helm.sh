#!/bin/sh

##### ENV vars #####

export GLOO_PLATFORM_VERSION="2.5.0"
export GLOO_PLATFORM_HELM_VALUES_FILE="gloo-gateway-single-helm-values.yaml"

# export GLOO_PLATFORM_VERSION="2.4.11"
# export GLOO_PLATFORM_HELM_VALUES_FILE="gloo-gateway-single-helm-values-2_4.yaml"

export CLUSTER_NAME=gg-demo-single

# TODO Check that ENV VARs have been set
if [ -z "$GLOO_GATEWAY_LICENSE_KEY" ]
then
   echo "Gloo Gateway License Key not specified. Please configure the environment variable 'GLOO_GATEWAY_LICENSE_KEY' with your Gloo Platform License Key."
fi

##### Install Gloo Platform CRDs #####

echo "\nInstalling Gloo Platform CRDs"

helm upgrade --install gloo-platform-crds gloo-platform/gloo-platform-crds \
   --namespace=gloo-mesh \
   --create-namespace \
   --version $GLOO_PLATFORM_VERSION

##### Install Gloo Platform #####

echo "\nCreate gloo-mesh-addons namespace if it does not yet exist."
kubectl create namespace gloo-mesh-addons --dry-run=client -o yaml | kubectl apply -f -

echo "\nInstalling Gloo Platform"

helm upgrade --install gloo-platform gloo-platform/gloo-platform \
   --namespace gloo-mesh \
   --version $GLOO_PLATFORM_VERSION \
   --values $GLOO_PLATFORM_HELM_VALUES_FILE \
   --set common.cluster=$CLUSTER_NAME \
   --set licensing.glooGatewayLicenseKey=$GLOO_GATEWAY_LICENSE_KEY
   # --set licensing.glooMeshLicenseKey=$GLOO_MESH_LICENSE_KEY \
   
   