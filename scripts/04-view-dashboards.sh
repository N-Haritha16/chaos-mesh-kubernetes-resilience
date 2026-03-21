#!/usr/bin/env bash
set -euo pipefail

kubectl -n chaos-mesh port-forward svc/chaos-dashboard 2333:2333 >/dev/null 2>&1 &
kubectl -n monitoring port-forward svc/grafana 3000:3000 >/dev/null 2>&1 &

echo "Chaos Mesh dashboard: http://localhost:2333"
echo "Grafana dashboard:    http://localhost:3000 (admin/admin)"
