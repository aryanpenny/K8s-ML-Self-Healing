import json
import joblib
import pandas as pd

model = joblib.load("../models/model.pkl")

with open("metrics.json") as f:
    metrics = json.load(f)

X=pd.DataFrame([metrics])

prediction = model.predict(X)[0]
confidence = max(model.predict_proba(X)[0])

output = {
    "failure_type": prediction,
    "confidence": confidence
}

print(json.dumps(output, indent=2))
