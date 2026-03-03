from kubernetes import client, config

config.load_kube_config()

v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()


def restart_pod(namespace, pod_name):
    print(f"[ACTION] Restarting pod {pod_name} in namespace {namespace}")
    v1.delete_namespaced_pod(
        name=pod_name,
        namespace=namespace
    )

def scale_deployment(deployment_name: str, replicas: int):    
    print(f"[ACTION] scaling deployment: {deployment_name}")
    body = {"spec": {"replicas": replicas}}
    apps_v1.patch_namespaced_deployment_scale(
        name=deployment_name,
        namespace=namespace,
        body=body
    )
    

def cordon_node(node_name: str):
    print(f"[ACTION] cordoning node: {node_name}")
    body = {"spec": {"unschedulable": True}}
    v1.patch_node(node_name, body)

