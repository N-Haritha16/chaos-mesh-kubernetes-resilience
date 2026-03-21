#!/usr/bin/env bash
set -euo pipefail

./scripts/healthcheck.sh

kubectl apply -f chaos-experiments/pod-chaos/pod-failure.yaml
kubectl apply -f chaos-experiments/network-chaos/latency.yaml
kubectl apply -f chaos-experiments/io-chaos/disk-latency.yaml
kubectl apply -f chaos-experiments/stress-chaos/cpu-stress.yaml
kubectl apply -f chaos-experiments/http-chaos/abort.yaml

kubectl apply -f chaos-experiments/workflows/complex-failure.yaml
