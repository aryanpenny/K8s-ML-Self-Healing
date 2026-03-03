from controller import handle_failure

simulated_predictions = [
    "APP_FAILURE",
    "RESOURCE_EXHAUSTION",
    "NODE_DEGRADATION",
]

for failure_type in simulated_predictions:
    print("\n---")
    handle_failure(failure_type)

