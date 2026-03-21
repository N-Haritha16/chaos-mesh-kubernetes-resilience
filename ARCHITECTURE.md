# Chaos Mesh Kubernetes Resilience Lab – Architecture

This document describes the architecture of the Kubernetes resilience lab built with a sample microservices application, Prometheus, Grafana, and Chaos Mesh (conceptual), all running on a local Minikube cluster.[web:8][web:115]

---

## 1. High-Level View

At a high level, the lab consists of:

- A **single-node Kubernetes cluster** provisioned by Minikube.
- A **sample microservices application** in the `sample-app` namespace.
- A **monitoring stack** (Prometheus + Grafana) in the `monitoring` namespace.
- **Chaos engineering components** (Chaos Mesh CRDs and controllers – conceptual in this environment) in the `chaos-mesh` namespace.[web:8][web:113]

All components run on top of the same Minikube node and communicate via standard Kubernetes Services within the cluster network.

---

## 2. Kubernetes Cluster Layer

- **Platform**: Minikube on local machine, using the Docker driver.
- **Node topology**: Single worker node (`minikube`) that also functions as the control plane node.
- **Resource configuration** (example): 3 vCPUs and 3.5 GB RAM allocated to the Minikube VM/container.[web:22]

This simplifies the environment to focus on application behavior and resilience rather than multi-node cluster complexity.

---

## 3. Application Layer (sample-app namespace)

### 3.1 Frontend Service

- **Workload type**: Deployment with multiple replicas (e.g., 3).
- **Role**: Acts as the entrypoint for users and synthetic traffic.
- **Port**: Exposes HTTP on port 8080.
- **Service**: ClusterIP Service `frontend` routes traffic to frontend pods.
- **Observability**:
  - Pods are annotated with `prometheus.io/scrape: "true"` and `prometheus.io/port: "8080"`, enabling Prometheus to discover them automatically via Kubernetes service discovery.[web:52][web:115]

### 3.2 Product Catalog Service

- **Workload type**: Deployment (backend microservice).
- **Port**: Exposes gRPC/HTTP on port 3550 (or similar).
- **Service**: ClusterIP Service `productcatalogservice`.
- **Relationship**: Frontend calls `productcatalogservice` as an internal dependency, creating a simple multi-service topology for resilience testing.

---

## 4. Monitoring Layer (monitoring namespace)

### 4.1 Prometheus

Prometheus is the metrics backend and time‑series database.[web:115]

- **Components**:
  - Prometheus server Deployment.
  - ConfigMap that defines `scrape_configs` using Kubernetes service and pod discovery.
- **Discovery**:
  - Uses the Kubernetes API to discover pods/services with specific labels and annotations (e.g., `prometheus.io/scrape: "true"`).
- **Responsibilities**:
  - Periodically **scrapes** HTTP `/metrics` endpoints from the sample app and system components.
  - Stores time‑series data (e.g., `up`, request rate, error rate) with labels such as `namespace`, `pod`, `service`.[web:52][web:115]
- **Access**:
  - Exposed via a ClusterIP Service `prometheus`.
  - Accessed from the host using `kubectl port-forward svc/prometheus 9090:9090`.

### 4.2 Grafana

Grafana is the visualization and dashboarding layer.[web:60][web:115]

- **Components**:
  - Grafana Deployment.
  - ConfigMap/Secret for data source configuration and credentials.
- **Data source**:
  - A Prometheus data source pointing to the in‑cluster Prometheus service.
- **Responsibilities**:
  - Renders dashboards showing:
    - Service availability (SLI: e.g., percentage of `up` targets).
    - Error rates and latency if such metrics exist.
    - Time windows before/during/after chaos experiments.
- **Access**:
  - Exposed via ClusterIP Service `grafana`.
  - Accessed from the host using `kubectl port-forward svc/grafana 3000:3000` and browsing to `http://localhost:3000`.[web:60]

---

## 5. Chaos Engineering Layer (chaos-mesh namespace)

> In this lab, Chaos Mesh components are described architecturally and via YAML, but actual installation may be limited by network and image-pull constraints. The following describes an ideal setup.[web:8][web:113]

### 5.1 Chaos Mesh Core Components

Chaos Mesh extends Kubernetes with multiple **CRDs (Custom Resource Definitions)** and associated controllers.[web:8][web:113]

Key elements:

- **Chaos Controller Manager**:
  - Watches Chaos CRDs such as `PodChaos`, `NetworkChaos`, `StressChaos`, `IOChaos`, and `HTTPChaos`.
  - Reconciles desired state (spec) into actual faults injected into target pods.
- **Chaos Daemon**:
  - Runs as a DaemonSet on each node.
  - Performs low-level fault injection (network manipulation, I/O faults, CPU stress, etc.) when instructed by the controller.
- **Chaos Dashboard** (optional):
  - Web UI to create, schedule, and monitor experiments.
  - Communicates with the Kubernetes API server to manage CRD objects.[web:8]

### 5.2 Chaos CRDs Used

The lab defines or plans to define the following CRDs targeting application pods in `sample-app`:

- **PodChaos**: Simulates pod failures, such as killing or pausing pods.
- **NetworkChaos**: Introduces latency, packet loss, or partition between services.
- **StressChaos**: Generates CPU/memory stress in containers.
- **IOChaos**: Injects I/O delay or faults on specified volume paths.
- **HTTPChaos**: Injects HTTP faults (abort, delay, etc.) at the application protocol level.[web:8][web:114]

Each chaos resource includes:

- **selector** (namespaces, label selectors) to identify target pods.
- **mode** (e.g., `one`, `all`, `fixed`) to control blast radius.
- **duration** and scheduling options to bound the experiment.[web:8][web:119]

---

## 6. Data Flow and Observability

### 6.1 Normal (Steady-State) Flow

1. User or synthetic traffic hits the **frontend** Service.
2. Frontend queries **productcatalogservice** for product data.
3. All services expose metrics via HTTP `/metrics` endpoints.
4. **Prometheus** periodically scrapes these endpoints and stores metrics.
5. **Grafana** reads metrics from Prometheus and renders dashboards.[web:52][web:115]

Under steady state, SLIs such as availability (\(up == 1\) for all targets), error rate, and latency remain within acceptable thresholds.

### 6.2 During Chaos Experiments

1. A Chaos Mesh experiment (e.g., `PodChaos`) is created and applied.
2. The **Chaos Controller Manager** sees the new CRD object and instructs the **Chaos Daemon** on the relevant node to perform the fault injection.[web:8]
3. The target pods experience failures:
   - Pod terminations or restarts.
   - Added latency or packet loss.
   - CPU/IO pressure.
   - HTTP aborts on specific routes.[web:113][web:114]
4. The system’s behavior changes:
   - Requests may fail or be delayed.
   - New pods may be scheduled by Kubernetes to maintain desired replicas.
5. **Prometheus** continues scraping metrics, capturing the impact over time.
6. **Grafana dashboards** visualize SLI/SLO deviation during the chaos window.

This tight integration between chaos injection and observability enables measuring resilience quantitatively.

---

## 7. Logical Architecture Diagram (Textual)

A simplified textual diagram of the architecture:

```text
+------------------------------+
|        Local Machine         |
|  (Docker + Minikube + kubectl)
+------------------------------+
              |
              v
+---------------------------------------------+
|           Minikube Kubernetes Cluster       |
|                                             |
|  +------------------+   +----------------+  |
|  |  sample-app ns   |   |  monitoring ns |  |
|  |                  |   |                |  |
|  |  [frontend]      |   | [Prometheus]   |  |
|  |  [productcatalog]|   | [Grafana]      |  |
|  +------------------+   +----------------+  |
|             ^                 ^             |
|             |                 |             |
|     chaos-mesh ns (conceptual)             |
|  [Chaos Controller] <--> [Chaos Daemon(s)] |
+---------------------------------------------+
