import joblib
import pandas as pd
from pathlib import Path

BASE_DIR= Path(__file__).resolve().parent.parent
MODEL_PATH= BASE_DIR / "models" / "model.pkl"

model=joblib.load(MODEL_PATH)

FEATURE_ORDER=[
    "pod_restart_rate",
    "container_cpu_usage",
    "container_memory_usage",
    "node_cpu_usage",
    "node_ready_status"
]

def predict_failure(metrics: dict):
    X=pd.DataFrame(
        [[metrics[f] for f in FEATURE_ORDER]],
        columns=FEATURE_ORDER)

    prediction = model.predict(X)[0]
    confidence = max(model.predict_proba(X)[0])

    return {
        "failure_type": prediction,
        "confidence": round(float(confidence), 2)   
    }