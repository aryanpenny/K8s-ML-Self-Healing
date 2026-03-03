# src/metrics_collector.py

from kubernetes import client, config
from kubernetes.client.exceptions import ApiException

config.load_kube_config()

v1 = client.CoreV1Api()
metrics_api = client.CustomObjectsApi()


def collect_metrics(namespace="default"):
    try:
        # --- Find pod belonging to demo-app deployment ---
        pods = v1.list_namespaced_pod(
            namespace=namespace,
            label_selector="app=demo-app"
        )

        if not pods.items:
            print("[WARN] No pods found for demo-app")
            return None

        pod = pods.items[0]
        pod_name = pod.metadata.name
        node_name = pod.spec.node_name

        # --- Restart count ---
        restarts = pod.status.container_statuses[0].restart_count

        # --- Pod metrics ---
        pod_metrics = metrics_api.get_namespaced_custom_object(
            group="metrics.k8s.io",
            version="v1beta1",
            namespace=namespace,
            plural="pods",
            name=pod_name,
        )

        container = pod_metrics["containers"][0]
        pod_cpu = int(container["usage"]["cpu"].replace("n", "")) // 1_000_000
        pod_mem = int(container["usage"]["memory"].replace("Ki", "")) // 1024

        # --- Node metrics ---
        node_metrics = metrics_api.get_cluster_custom_object(
            group="metrics.k8s.io",
            version="v1beta1",
            plural="nodes",
            name=node_name,
        )

        node_cpu = int(node_metrics["usage"]["cpu"].replace("n", "")) // 1_000_000

        # --- Node Ready status ---
        node = v1.read_node(node_name)
        ready_condition = next(
            c for c in node.status.conditions if c.type == "Ready"
        )
        node_ready = 1 if ready_condition.status == "True" else 0

        return {
            "pod_restart_rate": restarts,
            "container_cpu_usage": pod_cpu,
            "container_memory_usage": pod_mem,
            "node_cpu_usage": node_cpu,
            "node_ready_status": node_ready,
        }

    except ApiException as e:
        print(f"[WARN] Metrics collection failed: {e.reason}")
        return None
