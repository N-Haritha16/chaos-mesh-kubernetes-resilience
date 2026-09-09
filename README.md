# Chaos Mesh Kubernetes Resilience Lab

A production-ready Kubernetes resilience testing environment built on Minikube. Deploys a sample microservices application, complete monitoring stack (Prometheus + Grafana), and comprehensive Chaos Mesh experiments to study failure impact on Service Level Indicators (SLIs).

> **Note:** In this environment, Chaos Mesh installation and image pulls are network-constrained. Chaos resources are demonstrated as configuration and design examples for deployment in fully-connected clusters.

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue?logo=kubernetes)
![Minikube](https://img.shields.io/badge/Minikube-Docker%20Driver-blue?logo=linux)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-green?logo=grafana)
![Chaos Mesh](https://img.shields.io/badge/Chaos%20Mesh-Experiments-red?logo=github)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Project Structure](#project-structure)
- [Monitoring Pipeline](#monitoring-pipeline)
- [Chaos Experiments](#chaos-experiments)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Accessing Monitoring UIs](#accessing-monitoring-uis)
- [Creating Grafana Dashboards](#creating-grafana-dashboards)
- [Testing](#testing)
- [Docker Deployment](#docker-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Model Performance](#model-performance)
- [Troubleshooting](#troubleshooting)
- [Tech Stack](#tech-stack)

---

## Overview

This resilience lab is built on **Minikube with Docker driver** and exposes chaos engineering capabilities through:

- A **sample microservices application** (frontend + product catalog service)
- **Prometheus monitoring** with auto-discovery of annotated pods
- **Grafana dashboards** for SLI visualization
- **5 chaos experiment types** (Pod, Network, IO, CPU, HTTP) for comprehensive failure testing

The project is designed to be **interview-ready** — demonstrating Kubernetes best practices, monitoring setup, chaos engineering principles, modular architecture, and containerization.

---

## Features

| Capability | Detail |
|------------|--------|
| 🏗️ **Modular architecture** | Separate namespaces for app, monitoring, and chaos components |
| 📊 **Auto-discovery monitoring** | Prometheus scrapes pods with `prometheus.io/scrape: "true"` annotations |
| 🎯 **SLI visualization** | Pre-configured Grafana dashboard for pod availability metrics |
| 🔥 **5 chaos types** | Pod failure, Network latency, IO latency, CPU stress, HTTP aborts |
| 📦 **Local image support** | Build images inside Minikube to avoid network pull failures |
| ✅ **Validation scripts** | Health checks for all deployments before chaos injection |
| 📖 **Detailed documentation** | Step-by-step guides for setup, monitoring, and chaos experiments |
| 🐳 **Docker ready** | Containerized components with local image builds |

---

## System Architecture

### High-Level Overview

  Minikube Cluster
┌────────────────────────────────────────┐
│ │
│ Frontend:8080 ──┐ │
│ Product:3550 ───┼──▶ Prometheus:9090 ─┐
│ │ │
│ │ Grafana
│ │ :3000
│ │ │
│ │ Chaos Mesh │
│ │ Controller │
│ └────────────────────▶│
│ │
└────────────────────────────────────────┘

### Data Flow — Monitoring

Application Pods (annotated)
↓
Prometheus Service Discovery
↓
Metrics Scraping (every 15s)
↓
Prometheus TSDB Storage
↓
Grafana Dashboard Visualization

### Chaos Injection Flow

Chaos Experiment YAML
↓
Chaos Mesh Controller
↓
Target Pod/Network/IO Selection
↓
Failure Injection (duration-based)
↓
Automatic Recovery
↓
Metrics Impact (visible in Grafana)


### Text Preprocessing Pipeline

Every pod is annotated for Prometheus scraping:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
```

Prometheus discovers these pods via Kubernetes service discovery and scrapes the `/metrics` endpoint.

---

## Project Structure

chaos-mesh-kubernetes-resilience-lab/
│
├── 📁 k8s-manifests/
│ ├── 📄 namespaces.yaml # Creates sample-app, monitoring, chaos-mesh
│ ├── 📁 monitoring/
│ │ ├── 📄 prometheus.yaml # Prometheus deployment + ConfigMap + Service
│ │ └── 📄 grafana.yaml # Grafana deployment + Service
│ └── 📁 sample-app/
│ ├── 📁 deployments/
│ │ ├── 📄 frontend.yaml # Frontend deployment (3 replicas, port 8080)
│ │ └── 📄 product-catalog.yaml # Backend deployment (port 3550)
│ └── 📄 services.yaml # Service definitions for frontend + backend
│
├── 📁 chaos-experiments/
│ ├── 📁 pod-chaos/
│ │ └── 📄 pod-failure.yaml # Random pod kills (30s duration)
│ ├── 📁 network-chaos/
│ │ └── 📄 latency.yaml # Network delay injection (100ms + 10ms jitter)
│ ├── 📁 io-chaos/
│ │ └── 📄 io-latency.yaml # Disk latency (100ms on /data)
│ ├── 📁 stress-chaos/
│ │ └── 📄 cpu-stress.yaml # CPU pressure (80% load, 2 workers)
│ ├── 📁 http-chaos/
│ │ └── 📄 http-abort.yaml # HTTP request aborts on /health
│ ├── 📁 workflows/
│ │ └── 📄 complex-failure.yaml # Multi-stage chaos workflow
│ └── 📁 schedules/
│ └── 📄 nightly.yaml # Scheduled chaos runs
│
├── 📄 README.md
└── 📄 .gitignore

### Module Dependency Graph

namespaces.yaml ──► monitoring/ ──► Prometheus + Grafana running
│
▼
sample-app/ ──► Frontend + Product Catalog running
│
▼
chaos-experiments/ ──► Ready for injection (design)


---

## Monitoring Pipeline

### Dataset

The sample application consists of:

- **Frontend service**: 3 replicas, HTTP on port 8080, annotated for Prometheus scraping
- **Product Catalog service**: Backend service on port 3550, annotated for metrics

### Preprocessing (Prometheus Auto-Discovery)

Every pod goes through the same discovery pipeline:

| Step | Configuration | Result |
|------|---------------|--------|
| 1. Namespace label | `istio-injection=enabled` | Sidecar injection ready |
| 2. Pod annotation | `prometheus.io/scrape: "true"` | Marked for scraping |
| 3. Port annotation | `prometheus.io/port: "8080"` | Scrape endpoint identified |
| 4. Service discovery | Prometheus `kubernetes_sd_configs` | Auto-discovered as target |
| 5. Metrics collection | `/metrics` endpoint | Time-series data stored |

### Model Selection

| Component | Technology | Purpose | Selected |
|-----------|------------|---------|----------|
| Metrics Collection | Prometheus v2.45 | Scrapes annotated pods | ✅ |
| Visualization | Grafana v10.0 | Dashboards and alerts | ✅ |
| Service Discovery | Kubernetes SD | Auto-discovers pods | ✅ |
| Storage | Prometheus TSDB | Time-series database | ✅ |

Prometheus is configured via the `prometheus-config` ConfigMap with scrape configs that discover Kubernetes pods with `prometheus.io/scrape: "true"` annotations.

---

## Chaos Experiments

> **Note:** Due to Helm/network limitations, Chaos Mesh is not fully installed in this environment. The following manifests illustrate intended experiments and can be applied in a cluster with a working Chaos Mesh deployment.

### 1. PodChaos – Frontend Pod Failure

**File:** `chaos-experiments/pod-chaos/pod-failure.yaml`

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: frontend-pod-failure
  namespace: sample-app
spec:
  action: pod-failure
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: frontend
  duration: "30s"
```

**Effect:** Randomly kills one frontend pod for 30 seconds, then recovery.

### 2. NetworkChaos – Add Latency

**File:** `chaos-experiments/network-chaos/latency.yaml`

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: frontend-network-latency
  namespace: sample-app
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: frontend
  delay:
    latency: "100ms"
    jitter: "10ms"
  duration: "60s"
```

**Effect:** Injects 100ms latency (+/- 10ms jitter) for 60 seconds.

### 3. IOChaos – Disk Latency

**File:** `chaos-experiments/io-chaos/io-latency.yaml`

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: frontend-io-latency
  namespace: sample-app
spec:
  action: latency
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: frontend
  volumePath: /data
  delay: "100ms"
  duration: "60s"
```

**Effect:** Adds 100ms disk latency on `/data` volume for 60 seconds.

### 4. StressChaos – CPU Pressure

**File:** `chaos-experiments/stress-chaos/cpu-stress.yaml`

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: frontend-cpu-stress
  namespace: sample-app
spec:
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: frontend
  stressors:
    cpu:
      workers: 2
      load: 80
  duration: "60s"
```

**Effect:** Applies 80% CPU load with 2 workers for 60 seconds.

### 5. HTTPChaos – Abort Requests

**File:** `chaos-experiments/http-chaos/http-abort.yaml`

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: HTTPChaos
metadata:
  name: frontend-http-abort
  namespace: sample-app
spec:
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: frontend
  target: Request
  port: 8080
  path: /health
  method: GET
  abort: true
  duration: "30s"
```

**Effect:** Aborts all GET requests to `/health` endpoint for 30 seconds.

---

## Getting Started

### Prerequisites

- **Windows 11**
- **Docker Desktop** installed and running (Linux containers)
- **Minikube** installed (`minikube` available in PATH)
- **kubectl** installed and configured
- **Git** installed for pushing to GitHub
- **GitHub account** and **personal access token** (for HTTPS pushes)

**Optional (for full Chaos Mesh install):**
- **Helm** CLI installed

### 1. Clone / Enter the Project

```bash
git clone https://github.com/N-Haritha16/chaos-mesh-kubernetes-resilience-lab.git
cd chaos-mesh-kubernetes-resilience-lab
```

### 2. Start Minikube

```bash
minikube stop
minikube delete
minikube start --driver=docker --cpus=3 --memory=3500
kubectl get nodes
```

**Expected output:**