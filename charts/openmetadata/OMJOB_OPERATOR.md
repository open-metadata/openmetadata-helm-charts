# OMJob Operator for OpenMetadata

## Overview

The OMJob Operator is a Kubernetes operator that manages ingestion pipeline jobs with guaranteed exit handler execution. It ensures that pipeline status is properly updated in OpenMetadata regardless of how the main ingestion pod terminates (success, failure, OOM, external kill, etc.).

## Architecture

```
OMJob CR → OMJob Operator → Main Pod → Exit Handler Pod
```

1. **OMJob Custom Resource**: Defines the pipeline job specification
2. **OMJob Operator**: Watches OMJob resources and manages pod lifecycle
3. **Main Pod**: Runs the actual ingestion pipeline
4. **Exit Handler Pod**: Automatically created after main pod completion to update pipeline status

## Installation

### Enable the operator in values.yaml:

```yaml
omjobOperator:
  enabled: true
  image:
    repository: docker.getcollate.io/openmetadata/omjob-operator
    tag: latest
    pullPolicy: IfNotPresent
  logLevel: INFO
```

### Deploy using Helm:

```bash
helm upgrade --install openmetadata openmetadata-helm-charts/charts/openmetadata \
  --namespace openmetadata \
  --set omjobOperator.enabled=true
```

## Usage

The K8sPipelineClient will automatically create OMJob resources instead of regular Jobs when the operator is enabled. The OMJob resource structure mirrors a Kubernetes Job but with additional guarantees for exit handler execution.

### OMJob Lifecycle

1. **Pending**: OMJob created, waiting to start
2. **Running**: Main ingestion pod is running
3. **ExitHandlerRunning**: Main pod completed, exit handler is running
4. **Succeeded/Failed**: Both pods completed, final status determined

### Status Fields

- `phase`: Current phase of the OMJob
- `mainPodName`: Name of the main ingestion pod
- `exitHandlerPodName`: Name of the exit handler pod
- `mainPodExitCode`: Exit code from the main pod
- `startTime`: When the job started
- `completionTime`: When the job completed
- `message`: Human-readable status message

## Key Features

### Guaranteed Exit Handler Execution

The exit handler pod is **always** created after the main pod completes, regardless of:
- Normal completion (exit code 0)
- Application failures (exit code != 0)
- Out of Memory (OOM) kills
- External pod termination (`kubectl delete pod`)
- Node failures
- Resource limit violations

### Debug-Friendly

- Pods are retained based on TTL configuration (default: 24 hours)
- Exit handler logs are preserved separately from main pod logs
- Clear status progression through phases
- Kubernetes events track all state transitions

### Production Ready

- Single responsibility: operator only manages pod lifecycle
- No complex lifecycle hooks or sidecar containers
- Clean separation between ingestion and status reporting
- Resilient to operator restarts
- Handles edge cases (pod deletions, node failures)

## Monitoring

### View OMJob status:

```bash
kubectl get omjobs -n openmetadata
```

### Detailed status:

```bash
kubectl describe omjob <job-name> -n openmetadata
```

### Watch exit handler logs:

```bash
kubectl logs -l app.kubernetes.io/component=exit-handler -n openmetadata
```

## Configuration

### Pipeline Service Client Settings

The operator respects all existing `pipelineServiceClient` configurations:

```yaml
pipelineServiceClient:
  enabled: true
  ingestionImage: docker.getcollate.io/openmetadata/ingestion:latest
  serviceAccountName: openmetadata-ingestion
  ttlSecondsAfterFinished: 86400  # 24 hours
  resources:
    requests:
      cpu: "100m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "2Gi"
```

### Security Context

Both main and exit handler pods use the same security context:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

## Troubleshooting

### OMJob stuck in Running state

Check if the main pod is still running:
```bash
kubectl get pods -l omjob=<job-name> -n openmetadata
```

### Exit handler not created

Check operator logs:
```bash
kubectl logs deployment/openmetadata-omjob-operator -n openmetadata
```

### View operator events

```bash
kubectl get events --field-selector reason=OMJobOperator -n openmetadata
```

## Benefits Over Lifecycle Hooks

1. **Reliable**: Exit handler runs for ALL termination scenarios
2. **Debuggable**: Separate pods with distinct logs
3. **Simple**: No complex hooks or sidecars
4. **Kubernetes-native**: Uses standard operator pattern
5. **Maintainable**: Clean separation of concerns