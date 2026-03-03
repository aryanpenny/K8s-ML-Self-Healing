import json
import time
from pathlib import Path
from metrics_collector import collect_metrics
from k8s_action import restart_pod, scale_deployment, cordon_node
from prediction import predict_failure
from decision_engine import decide_action

ENABLE_REAL_ACTIONS = True

BASE_DIR = Path(__file__).resolve().parent.parent
METRICS_FILE = BASE_DIR / "src" / "metrics.json"


def load_metrics():
    with open(METRICS_FILE) as f:
        return json.load(f)


def main():
    print("[INFO] self-healing controller started")

    while True:
        metrics = collect_metrics()
        
        if metrics is None:
            print("[WARN] Skipping this cycle due to missing metrics")
            time.sleep(30)
            continue

        prediction = predict_failure(metrics)
        print(f"[PREDICTION] {prediction}")

        action = decide_action(prediction)
        print(f"[DECISION] {action}")

        if ENABLE_REAL_ACTIONS:
            if action == "RESTART_POD":
                restart_pod("default", "demo-app")

            elif action == "SCALE_DEPLOYMENT":
                scale_deployment("default", "demo-app", 2)

            elif action == "CORDON_AND_DRAIN_NODE":
                cordon_node("aryan-victus-by-hp-laptop-16-d0xxx")

        else:
            print("[DRY-RUN] No real Kubernetes action executed")

        time.sleep(45)


if __name__ == "__main__":
    main()
