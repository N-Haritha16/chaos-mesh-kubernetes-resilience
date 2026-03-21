#!/usr/bin/env bash
set -euo pipefail

# Chaos Mesh core bits (you already have CRDs/controller/dashboard)
kubectl apply -f k8s-manifests/chaos-mesh/crds.yaml
kubectl apply -f k8s-manifests/chaos-mesh/controller.yaml
kubectl apply -f k8s-manifests/chaos-mesh/dashboard.yaml

# Monitoring stack
kubectl apply -f k8s-manifests/monitoring/prometheus.yaml
kubectl apply -f k8s-manifests/monitoring/grafana.yaml

# Sample application (at minimum frontend + product-catalog)
kubectl apply -f k8s-manifests/sample-app/deployments/frontend.yaml
kubectl apply -f k8s-manifests/sample-app/deployments/product-catalog.yaml
kubectl apply -f k8s-manifests/sample-app/services.yaml
