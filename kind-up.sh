#!/bin/bash

# A simple script to automate provisioning a kind cluster and a load balancer with metallb
# This is useful for local development and testing Istio or other Kubernetes based projects
#
# Example usage: (Setup environment variables required) 
# $ KIND_CLUSTER_NAME="istioio"
# $ KIND_CLUSTER_CONFIG="$GOPATH/src/istio.io/istio/prow/config/trustworthy-jwt.yaml" 
# $ METALLB_SETUP_REQUIRED=1 
# $ METALLB_START_IP=172.18.255.1 
# $ METALLB_END_IP=172.18.255.250 
# ./kind-up.sh
#
# OR in a single line (specified configuration is in Istio repository)
# $ KIND_CLUSTER_NAME="istioio" KIND_CLUSTER_CONFIG="$GOPATH/src/istio.io/istio/prow/config/trustworthy-jwt.yaml" METALLB_SETUP_REQUIRED=1 METALLB_START_IP=172.18.255.1 METALLB_END_IP=172.18.255.250 ./kind-up.sh

set -e

if [[ -z "${KIND_CLUSTER_NAME}" ]]; then
    echo "KIND_CLUSTER_NAME is not set"
    exit 1
fi

if [[ -z "${KIND_CLUSTER_CONFIG}" ]]; then
    echo "KIND_CLUSTER_CONFIG is not set"
    exit 1
fi

kind create cluster \
    --name="${KIND_CLUSTER_NAME}" \
    --config="${KIND_CLUSTER_CONFIG}"
    
KUBECONFIG=${INSTALL_CONFIG:-"$HOME/.kube/config"}

if [[ ! -z "${METALLB_SETUP_REQUIRED}" ]]; then
    if [[ -z "${METALLB_START_IP}" ]]; then
        echo "METALLB_START_IP should be specified"
        exit 1
    fi
    if [[ -z "${METALLB_END_IP}" ]]; then
        echo "METALLB_END_ID should be specified"
        exit 1
    fi
    
    # This is taken from Metallb documentation page
    echo "Installing MetalLB for supporting LoadBalancer services"
    kubectl apply --kubeconfig="${KUBECONFIG}" -f "https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml"
    kubectl apply --kubeconfig="${KUBECONFIG}" -f "https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml"
    kubectl create --kubeconfig="${KUBECONFIG}" secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    
    # This is from Istio repository  
    echo 'apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - '"${METALLB_START_IP}-${METALLB_END_IP}" | kubectl apply --kubeconfig="${KUBECONFIG}" -f -
fi
