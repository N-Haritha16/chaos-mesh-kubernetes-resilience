
***

## `RESILIENCEREPORT.md`

```markdown
# Chaos Mesh Kubernetes Resilience Lab – Resilience Report

This document summarizes how the lab validates resilience of a sample microservices application on Kubernetes using chaos engineering principles, with Prometheus and Grafana providing observability.

---

## 1. Objectives

- Validate that the sample application maintains acceptable **availability** and **responsiveness** under controlled failure scenarios.
- Ensure that core **observability signals** (metrics and dashboards) clearly reflect the system’s behavior before, during, and after failures.
- Practice **safe chaos engineering** in a contained environment (Minikube).

---

## 2. Steady-State Definition

Before introducing chaos, the expected steady state is:

- All frontend and product catalog pods are in `Running` state.
- The `up` metric for application targets in Prometheus is consistently `1` (healthy).
- Requests to the frontend return successful responses (e.g., HTTP 200) with normal latency.
- Grafana dashboards show stable metrics over a baseline observation window.

Example Prometheus query used to validate steady state:

```promql
up{namespace="sample-app"}

3. Experiment Design
Each experiment follows the common chaos engineering workflow:

Hypothesis: Define how the system should behave under a specific failure.

Blast radius: Limit the scope (namespaces, labels, number of pods).

Duration and intensity: Configure how long and how severe the fault is.

Observability: Identify which metrics and dashboards to watch.

Abort and rollback: Know when to stop the experiment if impact is too high.

In this lab, experiments are defined as Chaos Mesh CRDs (YAML) and conceptually applied to workloads in the sample-app namespace.

4. Experiments
4.1 PodChaos – Frontend Pod Failure
Goal: Validate that the application remains available when a subset of frontend pods fails.

Chaos type: PodChaos with pod-failure or pod-kill action.

Target: Pods with labels app=frontend in sample-app namespace.

Mode: one (affects a single pod at a time).

Duration: 30 seconds per injection.[web:8][web:113]

Hypothesis:

Kubernetes should reschedule/restart the failed pod.

Service availability (e.g., fraction of successful requests) should remain within acceptable limits due to remaining replicas.

Metrics and dashboards:

Prometheus up{namespace="sample-app", service="frontend"}.

Request success rate and error rate, if instrumented.

Grafana panel showing availability over time.

Outcome (expected):

Temporary dip in the number of ready replicas.

Overall SLI remains high; users see minimal or no error spikes.

4.2 NetworkChaos – Latency Injection
Goal: Understand the impact of increased network latency between clients and the frontend service (or between frontend and backend).

Chaos type: NetworkChaos with delay action.

Target: app=frontend (or both frontend and product catalog).

Latency config: ~100 ms added latency with some jitter.

Duration: 60 seconds.[web:8][web:114]

Hypothesis:

End‑to‑end response time will increase, but the system should remain functional.

Retry or timeout behavior (if implemented) should prevent total failure.

Metrics and dashboards:

Latency metrics (if exposed) or approximated via derived metrics.

Any available error rate or timeout counters.

Prometheus up to confirm targets remain reachable.

Outcome (expected):

Increased latency visible on Grafana dashboards during the chaos window.

No major increase in error rates if the system tolerates additional latency.

4.3 StressChaos – CPU Saturation
Goal: Validate service behavior under CPU pressure.

Chaos type: StressChaos with cpu stressor.

Target: app=frontend.

Config: For example, 2 workers at ~80% load.

Duration: 60 seconds.[web:8][web:114]

Hypothesis:

Response times may degrade, but service should remain mostly available.

Kubernetes may not reschedule pods unless resource limits are hit, but metrics should clearly show increased CPU usage.

Metrics and dashboards:

CPU usage metrics at container/pod level.

Request latency and error rates.

up metric to confirm instances remain alive.

Outcome (expected):

Noticeable CPU spike on Grafana charts.

Some increase in response times; error rates should remain within acceptable limits if the system is resilient.

4.4 IOChaos – Disk Latency
Goal: Observe the effect of increased disk I/O latency on the frontend (or backend) service.

Chaos type: IOChaos with latency action.

Target: app=frontend pods, volume path /data (example).

Duration: 60 seconds.[web:8][web:114]

Hypothesis:

Any disk‑bound operations (caching, logging, file reads/writes) become slower.

Overall service behavior remains acceptable if I/O is not the primary bottleneck.

Metrics and dashboards:

I/O-related metrics (if available) or high-level latency/error metrics.

Pod restarts if probes fail under I/O delay.

Outcome (expected):

Subtle performance degradation; may not cause visible outages unless workloads are heavily disk‑dependent.

4.5 HTTPChaos – Request Aborts
Goal: Test how the system behaves when health or critical endpoints intermittently fail.

Chaos type: HTTPChaos with abort action.

Target: HTTP GET requests on /health at port 8080.

Duration: 30 seconds.

Hypothesis:

Health checks will fail transiently.

Liveness/readiness probes might cause pod restarts if integrated, which should be visible in deployment status and metrics.

Metrics and dashboards:

Kubernetes events and pod restart counts.

Availability metrics (SLI) on Grafana.

up metric for the service.

Outcome (expected):

Short‑lived availability dip if probes trigger restarts.

Automatic recovery after chaos ends, with metrics returning to baseline.

5. Observations and Findings
Note: Fill this section with your actual observations from running experiments. Below is a suggested template

5.1 What Worked Well
Prometheus successfully scraped all annotated sample app pods, and Grafana dashboards reflected changes in near real time.

Steady state was easy to validate using simple SLI queries like up{namespace="sample-app"}.

Kubernetes self‑healing (Deployments maintaining replicas) helped mitigate pod failures without manual intervention.

5.2 Issues Encountered
Image pulls from external registries occasionally failed (e.g., ImagePullBackOff, TLS handshake timeout), impacting Prometheus/Grafana or Chaos Mesh installation in constrained networks.

Full Chaos Mesh deployment might not be possible in offline or restricted environments; experiments may remain at the design/YAML level instead of being executed end‑to‑end.

5.3 Gaps in Resilience
Limited metrics: if the sample app lacks detailed application‑level metrics (request latency, error codes), it becomes difficult to quantify user‑perceived impact.

No automated alerting: without Alertmanager or notifications, engineers must manually watch dashboards during experiments.

6. Improvements and Next Steps
Enhance instrumentation:

Add application metrics (e.g., request duration histogram, error counters) and expose them to Prometheus.

Introduce alerting:

Deploy Prometheus Alertmanager and define SLO‑based alerts for availability and latency.

Automate experiments:

Use Chaos Mesh Workflows and Schedules to run experiments regularly (e.g., nightly or during game days).

Expand scenarios:

Add experiments for node failures (if running on multi-node clusters), dependency outages, and configuration errors.

Document runbooks:

Create incident runbooks based on observed failure modes and recovery patterns.

7. Conclusion
This lab demonstrates how a simple Kubernetes microservices application behaves under controlled failures when observed through Prometheus and Grafana, and conceptually orchestrated by Chaos Mesh.By iterating on experiments and instrumentation, teams can gradually build confidence in the system’s ability to withstand real‑world incidents and improve overall resilience.