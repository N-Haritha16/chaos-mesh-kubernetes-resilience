#!/usr/bin/env bash
set -euo pipefail

echo "Waiting for frontend deployment to be ready..."
kubectl -n sample-app rollout status deployment/frontend --timeout=180s

echo "Waiting for productcatalogservice deployment to be ready..."
kubectl -n sample-app rollout status deployment/productcatalogservice --timeout=180s

echo "Sample app appears healthy."
