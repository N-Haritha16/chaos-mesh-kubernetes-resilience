# Chaos Mesh Kubernetes Resilience Lab

This repository contains a Kubernetes resilience lab built on Minikube. It deploys a small sample microservices application, a monitoring stack (Prometheus and Grafana), and defines Chaos Mesh experiments (Pod, Network, IO, CPU, and HTTP chaos) to study the impact of failures on Service Level Indicators (SLIs).

> Note: In this environment Chaos Mesh installation and image pulls are network‑constrained, so some chaos resources are demonstrated as configuration and design rather than all being executed end‑to‑end.

---

## 1. Architecture Overview

The lab consists of:

- **Kubernetes cluster**: Minikube running locally with the Docker driver.
- **Namespaces**:
  - `sample-app` – sample microservices application.
  - `monitoring` – Prometheus and Grafana.
  - `chaos-mesh` – intended Chaos Mesh control plane components.
- **Sample application**:
  - `frontend` – simple HTTP service exposed on port 8080.
  - `productcatalogservice` – backend service on port 3550.
- **Monitoring stack**:
  - **Prometheus** – scrapes metrics from annotated pods.
  - **Grafana** – visualizes metrics using Prometheus as a data source.
- **Chaos resources (design)**:
  - `PodChaos` – random frontend pod failures.
  - `NetworkChaos` – injected latency.
  - `IOChaos` – disk latency.
  - `StressChaos` – CPU pressure.
  - `HTTPChaos` – HTTP aborts.

---

## 2. Prerequisites

- **Windows 11**.
- **Docker Desktop** installed and running (Linux containers).
- **Minikube** installed (`minikube` available in PATH).
- **kubectl** installed and configured.
- **Git** installed for pushing to GitHub.
- A **GitHub account** and a **personal access token** (for HTTPS pushes).

Optional (for full Chaos Mesh install in a better network environment):

- **Helm** CLI installed.

---

## 3. Getting Started

### 3.1 Clone the repository

```bash
git clone https://github.com/<YOUR_GITHUB_USERNAME>/chaos-mesh-kubernetes-resilience-lab.git
cd chaos-mesh-kubernetes-resilience-lab

3.2 Start Minikube
Start (or recreate) the Minikube cluster using Docker:

bash
minikube stop
minikube delete

minikube start --driver=docker --cpus=3 --memory=3500
kubectl get nodes
You should see the minikube node in Ready state.[web:22]

3.3 Create namespaces
bash
kubectl apply -f k8s-manifests/namespaces.yaml
This creates sample-app, monitoring, and chaos-mesh namespaces.[file:1]

4. Deploy Monitoring Stack
4.1 Prometheus
Apply the Prometheus manifests:

bash
kubectl apply -f k8s-manifests/monitoring/prometheus.yaml
kubectl -n monitoring rollout status deployment/prometheus --timeout=180s
kubectl -n monitoring get pods
The prometheus-... pod should reach Running. In constrained networks, you can build and reference a local Prometheus image (local-prometheus:latest) inside Minikube to avoid external pulls.[web:72][web:80]

Prometheus is configured via the prometheus-config ConfigMap and uses scrape_configs that discover Kubernetes pods with prometheus.io/scrape: "true" annotations.[file:1][web:52]

4.2 Grafana
Apply the Grafana manifests:

bash
kubectl apply -f k8s-manifests/monitoring/grafana.yaml
kubectl -n monitoring rollout status deployment/grafana --timeout=180s
kubectl -n monitoring get pods
The grafana-... pod should reach Running. As with Prometheus, a local local-grafana:latest image can be used if Docker Hub access is restricted.[web:72][web:80]

5. Deploy Sample Application
5.1 Frontend
The frontend is a simple HTTP service (Node.js) listening on port 8080, used as the primary target for chaos.

Deploy:

bash
kubectl apply -f k8s-manifests/sample-app/deployments/frontend.yaml
This deployment:

Runs 3 replicas in the sample-app namespace.

Exposes port 8080.

Annotates pods with:

text
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
so Prometheus can scrape it as a target.[file:1][web:52]

5.2 Product Catalog Service
Deploy the backend service:

bash
kubectl apply -f k8s-manifests/sample-app/deployments/product-catalog.yaml
This service:

Exposes port 3550.

Also includes scrape annotations for Prometheus (if configured).

5.3 Services
Apply the service definitions:

bash
kubectl apply -f k8s-manifests/sample-app/services.yaml
5.4 Verify steady state
bash
kubectl -n sample-app rollout status deployment/frontend --timeout=180s
kubectl -n sample-app rollout status deployment/productcatalogservice --timeout=180s
kubectl -n sample-app get pods
All frontend and productcatalogservice pods should be in Running state. This constitutes the baseline steady state before chaos experiments.[file:1]

6. Accessing Monitoring UIs
6.1 Prometheus UI
Port‑forward the Prometheus service:

bash
kubectl -n monitoring port-forward svc/prometheus 9090:9090
Then open:

text
http://localhost:9090
In Status → Targets, you should see the configured scrape jobs. If scrape configs and annotations are in place, targets for the sample app appear as UP.[web:52][web:56]

In the Graph tab, you can run a basic query:

text
up
to visualize target availability over time.[web:52][web:61]

6.2 Grafana UI
Port‑forward the Grafana service:

bash
kubectl -n monitoring port-forward svc/grafana 3000:3000
Then open:

text
http://localhost:3000
Log in with default credentials:

Username: admin

Password: admin
Then set a new password when prompted.

7. Creating Grafana Dashboards
7.1 Create a basic SLI panel
In the left sidebar, click Dashboards.

Click New → New dashboard (top right).

Click Add visualization.

Choose Prometheus as the data source.

In the query editor, use:

text
up{namespace="sample-app"}
Click Run query to visualize pod availability for the sample app.

Click Apply, then Save, and name the dashboard, for example Sample App Availability SLI.

You can capture this as the main SLI visualization in your resilience report.

8. Chaos Experiments (Design and YAML)
Due to Helm/network limitations on this environment, Chaos Mesh is not fully installed; the following manifests illustrate the intended experiments and can be applied in a cluster with a working Chaos Mesh deployment.[web:21][web:86]

8.1 PodChaos – frontend pod failure
chaos-experiments/pod-chaos/pod-failure.yaml:

text
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
      app.kubernetes.io/part-of: online-boutique
  duration: "30s"
When Chaos Mesh is installed correctly, this experiment randomly kills one frontend pod for 30 seconds, then lets it recover.[web:21]

8.2 NetworkChaos – add latency
chaos-experiments/network-chaos/latency.yaml (example):

text
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
This would inject additional latency into network traffic to the targeted pods.[web:12][web:86]

8.3 IOChaos – disk latency
Example iochaos manifest targeting a specific container path to introduce disk latency:

text
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
8.4 StressChaos – CPU pressure
text
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
8.5 HTTPChaos – abort requests
text
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
These experiments together cover multiple failure modes commonly used in chaos engineering.

9. Chaos Workflows and Schedules (Conceptual)
You can define higher‑level Chaos Mesh resources to orchestrate experiments:

Workflow – chains multiple chaos experiments into a complex scenario.[web:45][web:86]

Schedule – runs an experiment periodically (e.g., nightly).

Example workflow and schedule manifests are located under:

chaos-experiments/workflows/complex-failure.yaml

chaos-experiments/schedules/nightly.yaml

In a fully installed Chaos Mesh cluster, you would apply them via:

bash
kubectl apply -f chaos-experiments/workflows/complex-failure.yaml
kubectl apply -f chaos-experiments/schedules/nightly.yaml
and observe them in the Chaos Mesh dashboard.

10. Cleaning Up
To remove all resources:

bash
kubectl delete -f k8s-manifests/sample-app/deployments/frontend.yaml
kubectl delete -f k8s-manifests/sample-app/deployments/product-catalog.yaml
kubectl delete -f k8s-manifests/sample-app/services.yaml

kubectl delete -f k8s-manifests/monitoring/prometheus.yaml
kubectl delete -f k8s-manifests/monitoring/grafana.yaml

kubectl delete -f k8s-manifests/namespaces.yaml

minikube delete
This tears down the sample app, monitoring stack, namespaces, and Minikube cluster.

11. Known Limitations
Image pulls from Docker Hub / external registries may fail in restricted networks, leading to ImagePullBackOff. In such cases, build images inside Minikube’s Docker (minikube docker-env) and reference them with local tags (e.g., local-prometheus:latest, local-grafana:latest).

Chaos Mesh installation is network‑dependent (Helm charts and controller images). In this lab, Chaos Mesh resources are provided primarily as YAML examples and architectural design, not all executed end‑to‑end.

TLS handshake timeouts or cluster instability can require deleting and recreating Minikube.

12. References
Minikube start and drivers.

Prometheus getting started and querying.

Grafana with Prometheus dashboards.

Chaos Mesh concepts and experiments.

GitHub docs for pushing existing code.
