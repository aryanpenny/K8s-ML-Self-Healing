#!/bin/bash
set -e

APP_NAME=demo-app
NAMESPACE=default
LABEL="run=demo-app"

echo "[INFO] Injecting RESOURCE_EXHAUSTION (CPU stress)"

# Ensure pod exists
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

# Start CPU stress
kubectl exec -n $NAMESPACE $POD -c $CONTAINER -- sh -c "yes > /dev/null &" || {
  echo "[ERROR] Failed to start CPU stress"
  exit 1
}

echo "[INFO] Waiting for metrics to stabilize..."
sleep 45

# Bounded wait for metrics
for i in {1..6}; do
  if kubectl top pod $POD -n $NAMESPACE >/dev/null 2>&1; then
    break
  fi
  echo "[WARN] Metrics not ready yet, retrying..."
  sleep 10
done

if ! kubectl top pod $POD -n $NAMESPACE >/dev/null 2>&1; then
  echo "[ERROR] Metrics unavailable after retries"
  exit 1
fi

./scripts/collect_metrics.sh RESOURCE_EXHAUSTION

# Cleanup
echo "[INFO] Cleaning up CPU stress"
kubectl exec -n $NAMESPACE $POD -c $CONTAINER -- pkill yes || true

echo "[INFO] RESOURCE_EXHAUSTION injection completed"
