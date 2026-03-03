#!/bin/bash
set -e

APP_FAILURE_COUNT=10
RESOURCE_EXHAUSTION_COUNT=7
NODE_DEGRADATION_COUNT=10

NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

cleanup() {
  sudo systemctl start kubelet || true
}
trap cleanup EXIT

log "===== FAULT INJECTION STARTED ====="

# APP_FAILURE
log "Running APP_FAILURE $APP_FAILURE_COUNT times"
for i in $(seq 1 $APP_FAILURE_COUNT); do
  log "APP_FAILURE run $i"
  ./scripts/inject_app_failure.sh
  sleep 20
done

# RESOURCE_EXHAUSTION
log "Running RESOURCE_EXHAUSTION $RESOURCE_EXHAUSTION_COUNT times"
for i in $(seq 1 $RESOURCE_EXHAUSTION_COUNT); do
  log "RESOURCE_EXHAUSTION run $i"
  ./scripts/inject_resource_exhaustion.sh
  sleep 30
done

# NODE_DEGRADATION
log "Running NODE_DEGRADATION $NODE_DEGRADATION_COUNT times"
for i in $(seq 1 $NODE_DEGRADATION_COUNT); do
  log "NODE_DEGRADATION run $i"
  ./scripts/inject_node_degradation.sh

  log "Waiting for node $NODE to become Ready..."
  until kubectl get node "$NODE" | grep -q " Ready "; do
    sleep 10
  done

  log "Node is Ready. Continuing."
  sleep 30
done

log "===== FAULT INJECTION COMPLETED ====="
