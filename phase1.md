## Problem Definition

Goal:
Classify Kubernetes failures using ML based on metric snapshots.

Failure Classes (LOCKED):
1. APP_FAILURE
2. RESOURCE_EXHAUSTION
3. NODE_DEGRADATION

Why:
Changing labels breaks ML validity and makes evaluation meaningless.



## ML Scope

### Input (to ML)
- Single snapshot of metrics
- Format: JSON or CSV
- Collected at a specific timestamp

### Output (from ML)
- One failure class:
  - APP_FAILURE
  - RESOURCE_EXHAUSTION
  - NODE_DEGRADATION

### Explicit Non-Goals
The ML model will NOT:
- Restart pods
- Scale nodes
- Modify Kubernetes resources
- Execute recovery actions

Reason:
Clear separation between intelligence (ML) and action (Kubernetes controllers).


## Feature Schema (Locked)

1. pod_restart_rate
2. http_error_rate
3. request_latency_p95
4. container_memory_usage
5. container_cpu_usage
6. node_cpu_usage
7. node_memory_pressure
8. node_disk_pressure
9. node_ready_status

