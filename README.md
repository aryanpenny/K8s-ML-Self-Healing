# ML-Assisted Kubernetes Self-Healing System

## Overview

This project implements an ML-driven self-healing controller for Kubernetes.

Instead of relying on static threshold rules, the system uses a trained machine learning model to classify cluster failures and trigger automated recovery actions.

The goal is to move toward intelligent, context-aware infrastructure automation.

---

## Problem Statement

Kubernetes provides built-in self-healing (pod restarts, replica rescheduling), but:

- It relies on static rules
- It lacks cross-layer failure diagnosis
- It cannot differentiate between application and infrastructure failures

This project introduces ML-assisted failure classification before triggering recovery actions.

---

## Failure Classes

The system classifies failures into:

- `APP_FAILURE`
- `RESOURCE_EXHAUSTION`
- `NODE_DEGRADATION`

Each class maps to a different recovery strategy.

---

## Architecture
Kubernetes Metrics
↓
Metrics Collector (Python)
↓
Random Forest Classifier
↓
Decision Engine (confidence threshold)
↓
Kubernetes API Actions


---

## Components

### 1. Metrics Collector
- Uses Kubernetes Python client
- Fetches pod and node metrics from metrics-server
- Extracts restart count, CPU, memory, node readiness

### 2. ML Model
- Random Forest classifier
- Trained on injected fault data
- Outputs failure class + confidence score

### 3. Decision Engine
- Applies confidence threshold gating
- Prevents low-confidence automated actions
- Maps failure → recovery strategy

### 4. Controller Loop
- Runs continuously
- Collects live cluster metrics
- Predicts failure
- Executes Kubernetes action safely

---

## Automated Recovery Actions

| Failure Type | Action |
|--------------|--------|
| APP_FAILURE | Restart deployment (scale down/up) |
| RESOURCE_EXHAUSTION | Scale replicas |
| NODE_DEGRADATION | Cordon node |

---

## Technologies Used

- Python
- scikit-learn
- Kubernetes Python client
- kubeadm cluster
- metrics-server
- Bash fault injection scripts

---

## Fault Injection

The system was tested using:

- Manual pod termination
- CPU stress inside container
- kubelet shutdown (node degradation)

Real cluster metrics were collected and used for model retraining.

---

## Safety Mechanisms

- Confidence threshold gating
- Dry-run mode
- Deployment-level restarts (not direct pod deletion)

---

## Current Status

Phase 6 Complete  
Fully automated ML → Kubernetes recovery loop operational.

---

## Future Improvements

- Prometheus integration
- Model retraining automation
- Cooldown logic
- Observability dashboard
- Replace rule-based decision layer with policy engine

---
