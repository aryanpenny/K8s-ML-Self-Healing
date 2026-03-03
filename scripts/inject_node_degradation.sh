#!/bin/bash
set -e

NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

echo "[INFO] Injecting NODE_DEGRADATION on node: $NODE"

echo "[INFO] Stopping kubelet"
sudo systemctl stop kubelet

# Wait for NotReady (bounded)
echo "[INFO] Waiting for node to become NotReady..."
for i in {1..12}; do
  if kubectl get nodes | grep "$NODE" | grep -q NotReady; then
    break
  fi
  sleep 5
done

if ! kubectl get nodes | grep "$NODE" | grep -q NotReady; then
  echo "[ERROR] Node did not transition to NotReady"
  sudo systemctl start kubelet
  exit 1
fi

sleep 30

./scripts/collect_metrics.sh NODE_DEGRADATION

echo "[INFO] Restarting kubelet"
sudo systemctl start kubelet

# Wait for Ready (bounded)
echo "[INFO] Waiting for node to recover..."
for i in {1..12}; do
  if kubectl get nodes | grep "$NODE" | grep -q " Ready "; then
    break
  fi
  sleep 10
done

if ! kubectl get nodes | grep "$NODE" | grep -q " Ready "; then
  echo "[ERROR] Node did not recover properly"
  exit 1
fi

echo "[INFO] NODE_DEGRADATION injection completed"
