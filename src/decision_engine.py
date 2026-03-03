import time

COOLDOWN_SECONDS = 300  # 5 minutes cooldown
CONFIDENCE_THRESHOLD = 0.4

FAILURE_ACTION_MAP = {
    "APP_FAILURE": "RESTART_POD",
    "RESOURCE_EXHAUSTION": "SCALE_DEPLOYMENT",
    "NODE_DEGRADATION": "CORDON_AND_DRAIN_NODE"
}

_last_action_time = 0

def decide_action(prediction: dict):

    global _last_action_time

    failure= prediction["failure_type"]
    confidence = prediction["confidence"]

    if confidence < CONFIDENCE_THRESHOLD:
        return "NO_ACTION"
    
    now = time.time()
    if now - _last_action_time < COOLDOWN_SECONDS:
        return "NO_ACTION"
    
    action = FAILURE_ACTION_MAP.get(failure, "NO_ACTION")
    _last_action_time = now
    return action