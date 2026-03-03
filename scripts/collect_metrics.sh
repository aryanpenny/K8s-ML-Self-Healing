#!/bin/bash
set -e

LABEL=$1
NAMESPACE=default
LABEL_SELECTOR="run=demo-app"
OUTPUT="data/real_metrics.csv"

# Get live pod
POD=$(kubectl get pods -n $NAMESPACE -l $LABEL_SELECTOR -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
  echo "[ERROR] No pod found with label $LABEL_SELECTOR"
  exit 1
fi

NODE=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}')

# Wait for metrics (retry instead of skip)
echo "[INFO] Waiting for metrics..."
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

# Collect metrics
POD_CPU=$(kubectl top pod $POD -n $NAMESPACE --no-headers | awk '{print $2}' | sed 's/m//')
POD_MEM=$(kubectl top pod $POD -n $NAMESPACE --no-headers | awk '{print $3}' | sed 's/Mi//')
NODE_CPU=$(kubectl top node $NODE --no-headers | awk '{print $2}' | sed 's/m//')

RESTARTS=$(kubectl get pod $POD -n $NAMESPACE --no-headers | awk '{print $4}')

READY=$(kubectl get node $NODE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

NODE_READY=0
[ "$READY" = "True" ] && NODE_READY=1

# Append row
echo "$RESTARTS,$POD_CPU,$POD_MEM,$NODE_CPU,$NODE_READY,$LABEL" >> "$OUTPUT"

echo "[INFO] Metrics collected for $LABEL"
