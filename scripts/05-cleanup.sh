#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="chaos-mesh-demo"

if kind get clusters | grep -q "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
fi
