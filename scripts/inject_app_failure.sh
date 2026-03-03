#!/bin/bash
set -e

APP_NAME=demo-app
NAMESPACE=default
LABEL="run=demo-app"

echo "[INFO] Injecting APP_FAILURE"

# Ensure app exists
if ! kubectl get pods -n $NAMESPACE -l $LABEL | grep -q Running; then
  echo "[WARN] Pod not found. Recreating demo app..."
  kubectl delete pod -n $NAMESPACE -l $LABEL --ignore-not-found
  kubectl run $APP_NAME --image=nginx -n $NAMESPACE --labels=$LABEL
  kubectl wait --for=condition=Ready pod -l $LABEL -n $NAMESPACE --timeout=60s
fi

# Get live pod + container
POD=$(kubectl get pods -n $NAMESPACE -l $LABEL -o jsonpath='{.items[0].metadata.name}')
CONTAINER=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].name}')

echo "[INFO] Target pod: $POD (container: $CONTAINER)"

# Kill main process (APP_FAILURE)
kubectl exec -n $NAMESPACE $POD -c $CONTAINER -- sh -c "kill 1" || {
  echo "[ERROR] Failed to inject APP_FAILURE"
  exit 1
}

echo "[INFO] Waiting for pod to recover..."
kubectl wait --for=condition=Ready pod/$POD -n $NAMESPACE --timeout=60s

# Wait for metrics (bounded retry)
echo "[INFO] Waiting for metrics..."
for i in {1..6}; do
  if kubectl top pod $POD -n $NAMESPACE >/dev/null 2>&1; then
    break
  fi
  echo "[WARN] Metrics not ready yet, retrying..."
  sleep 10
done

# Final check
if ! kubectl top pod $POD -n $NAMESPACE >/dev/null 2>&1; then
  echo "[ERROR] Metrics unavailable after retries"
  exit 1
fi

./scripts/collect_metrics.sh APP_FAILURE

echo "[INFO] APP_FAILURE injection completed"
