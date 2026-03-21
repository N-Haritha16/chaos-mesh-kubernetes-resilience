#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="chaos-mesh-demo"

if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME"
fi

kubectl apply -f k8s-manifests/namespaces.yaml
