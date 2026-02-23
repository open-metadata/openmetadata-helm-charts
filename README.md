<div align="center">
  <img src="https://i.imgur.com/5VumwFS.png" align="center" alt="OpenMetadata" height="90"/>
  <hr />
</div>

# Open Metadata Helm Charts [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/open-metadata)](https://artifacthub.io/packages/search?repo=open-metadata)

- [Introduction](#introduction)
- [Setup](#setup)
- [Quickstart](#quickstart)
- [OpenShift (ROSA) Installation](#openshift-rosa-installation)
- [Documentation and Support](#documentation-and-support)
- [Contributors](#contributors)
- [License](#license)

## Introduction


[This Repository](https://github.com/open-metadata/openmetadata-helm-charts) houses Kubernetes [Helm](https://helm.sh) charts for deploying [Open Metadata](https://github.com/open-metadata/OpenMetadata) and it's dependencies (Elastic Search and MySQL) on a Kubernetes Cluster.

---

## Setup


Set up a Kubernetes Cluster
- In a cloud platform of your choice like [Amazon EKS](https://aws.amazon.com/eks/), [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) or [Azure Kubernetes Service](https://azure.microsoft.com/en-in/services/kubernetes-service/#overview)
<br />OR<br />
- On Local Environment using [Minikube](https://minikube.sigs.k8s.io/docs) or [Docker Desktop](https://www.docker.com/products/docker-desktop). Note, atleast 4 GB of RAM is required to run Open Metadata and it's dependencies.

Install the below tools:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) to manage Kubernetes Resources
- [Helm](https://helm.sh) to deploy resources based on Helm Charts from this repository. Note, we only support Helm 3

---

## Quickstart

Assuming kubectl context points to the correct kubernetes cluster, first create kubernetes secrets that contain MySQL and Airflow passwords as secrets.

```
kubectl create secret generic mysql-secrets --from-literal=openmetadata-mysql-password=openmetadata_password
kubectl create secret generic airflow-secrets --from-literal=openmetadata-airflow-password=admin
```

The above commands sets the passwords as an example. Change to any password of choice.

Next, we install Open Metadata dependencies.

Add openmetadata helm repo by running the following - 

```
helm repo add open-metadata https://helm.open-metadata.org/
```
Run the command `helm repo list` to list the addition of openmetadata helm repo -

```
NAME        	URL                            
open-metadata	https://helm.open-metadata.org/
```

Assuming kubectl context points to the correct kubernetes cluster, first create kubernetes secrets that contain airflow mysql password as secrets.

```
kubectl create secret generic airflow-mysql-secrets --from-literal=airflow-mysql-password=airflow_pass
```

Deploy the dependencies by running

```
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies
```

Note - The above command uses configurations defined [here](charts/deps/values.yaml). You can modify any configuration and deploy by passing your own `values.yaml`

```
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies --values <<path-to-values-file>>
```

Run `kubectl get pods` to check whether all the pods for the dependencies are running. You should get a result similar to below.

```
NAME                                                       READY   STATUS    RESTARTS   AGE
mysql-0                                                    1/1     Running   0          5m
opensearch-0                                               1/1     Running   0          5m
openmetadata-dependencies-api-server-xxxxx                 1/1     Running   0          5m
openmetadata-dependencies-scheduler-0                      2/2     Running   0          5m
openmetadata-dependencies-dag-processor-xxxxx              2/2     Running   0          5m
openmetadata-dependencies-triggerer-0                      2/2     Running   0          5m
openmetadata-dependencies-statsd-xxxxx                     1/1     Running   0          5m
```

**Note**: This chart now uses Apache Airflow 3 with the official Apache Airflow Helm chart. See [charts/deps/README.md](charts/deps/README.md) for Airflow 3 compatibility details.

Next, deploy the openmetadata by running the following

```
helm install openmetadata open-metadata/openmetadata
```

Values in [values.yaml](charts/openmetadata/values.yaml) are preset to match with dependencies deployed using [openmetadata-dependencies](charts/deps) with release name "openmetadata-dependencies". If you deployed helm chart using different release name, make sure to update values.yaml accordingly before installing.

Run `kubectl get pods` command to check the statuses of pods running you should get a result similar to below.

```
NAME                            READY   STATUS    RESTARTS   AGE
elasticsearch-0                 1/1     Running   0          5m34s
mysql-0                         1/1     Running   0          5m34s
openmetadata-5566f4d8b9-544gb   1/1     Running   0          98s
```

To expose the Openmetadata UI locally, run the below command -

```
kubectl port-forward deployment/openmetadata 8585:8585
```

---

## OpenShift (ROSA) Installation

OpenMetadata can be deployed on Red Hat OpenShift, including ROSA (Red Hat OpenShift Service on AWS). The OpenShift setup uses the Kubernetes-native pipeline service client (`K8sPipelineClient`) instead of Airflow — no Airflow installation is required.

### Prerequisites

Install the [OpenShift CLI (`oc`)](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html) and ensure your `kubectl`/`helm` context points to your OpenShift cluster.

Run these commands once before installing the charts:

```bash
# Create the namespace
oc new-project openmetadata

# Allow OpenSearch's sysctl init container to run privileged
# (needed to set vm.max_map_count=262144)
oc adm policy add-scc-to-user privileged \
  -z opensearch -n openmetadata

# Allow the OpenMetadata server to run as a fixed non-root UID
oc adm policy add-scc-to-user anyuid \
  -z openmetadata -n openmetadata
```

| SCC | Granted to | Reason |
|-----|-----------|--------|
| `privileged` | `opensearch` ServiceAccount | OpenSearch requires a privileged init container to set the kernel parameter `vm.max_map_count=262144`. |
| `anyuid` | `openmetadata` ServiceAccount | The OpenMetadata server image runs as a fixed non-root UID, which OpenShift's default `restricted` SCC rejects. |

### Step 1 — Install dependencies (MySQL + OpenSearch)

Save the following as `values-openshift-deps.yaml` and adjust the image tags and storage sizes for your environment:

```yaml
# Airflow is not needed — using the Kubernetes-native pipeline service client
airflow:
  enabled: false

mysql:
  enabled: true
  fullnameOverride: "mysql"
  architecture: standalone
  image:
    registry: docker.io
    repository: bitnamilegacy/mysql
    tag: 8.0.37-debian-12-r2
    pullPolicy: "Always"
  auth:
    rootPassword: password         # change this
    database: openmetadata_db
    username: openmetadata_user
    password: openmetadata_password  # change this
  # Override base chart initdbScripts with no-ops to prevent the airflow_db
  # script from failing on restart with "Can't create database; database exists"
  initdbScripts:
    init_airflow_db_scripts.sql: "SELECT 1;"
    init_openmetadata_db_scripts.sql: "SELECT 1;"
  primary:
    extraFlags: "--sort_buffer_size=10M"
    persistence:
      size: 50Gi

opensearch:
  enabled: true
  clusterName: opensearch
  fullnameOverride: opensearch
  nodeGroup: ""
  # Fully-qualify the image: ROSA's CRI-O rejects short image names
  image:
    repository: "docker.io/opensearchproject/opensearch"
  imagePullPolicy: Always
  opensearchJavaOpts: "-Xmx1g -Xms1g"
  persistence:
    size: 30Gi
  protocol: http
  config:
    opensearch.yml: |
      plugins.security.disabled: true
      indices.query.bool.max_clause_count: 4096
  singleNode: true
  resources:
    requests:
      cpu: "100m"
      memory: "256M"
    limits:
      cpu: "2000m"
      memory: "2048M"
  # Dedicated SA so the privileged SCC grant is scoped to OpenSearch only
  rbac:
    create: true
    serviceAccountName: "opensearch"
  # Privileged init container to set vm.max_map_count=262144
  sysctlInit:
    enabled: true
    image: docker.io/library/busybox   # fully-qualified for CRI-O
    imageTag: latest
```

Then install:

```bash
helm upgrade --install openmetadata-dependencies open-metadata/openmetadata-dependencies \
  --namespace openmetadata --create-namespace \
  --values values-openshift-deps.yaml
```

Wait for the pods to be ready:

```bash
oc rollout status deployment/mysql -n openmetadata
oc rollout status statefulset/opensearch -n openmetadata
```

### Step 2 — Install OpenMetadata

Save the following as `values-openshift.yaml`. Update `image.tag` and `ingestionImage` to match your target OpenMetadata version:

```yaml
image:
  tag: "<version>"  # e.g. 1.12.0

openmetadata:
  config:
    # No Airflow deploy step needed with the k8s pipeline client
    deployPipelinesConfig:
      enabled: false

    pipelineServiceClientConfig:
      enabled: true
      # Use the Kubernetes-native pipeline client
      type: "k8s"
      metadataApiEndpoint: "http://openmetadata:8585/api"
      k8s:
        className: "org.openmetadata.service.clients.pipeline.k8s.K8sPipelineClient"
        # Must match image.tag above
        ingestionImage: "docker.getcollate.io/openmetadata/ingestion:<version>"
        imagePullPolicy: "Always"
        # SA that runs ingestion Jobs (created automatically when rbac.enabled: true)
        serviceAccountName: "openmetadata-ingestion"
        rbac:
          # Creates ServiceAccount, Role, and RoleBinding for ingestion Jobs
          enabled: true

    # Point at the MySQL installed above.
    # Bitnami stores the user password in a Secret named "mysql" under key "mysql-password".
    database:
      enabled: true
      host: mysql
      port: 3306
      driverClass: com.mysql.cj.jdbc.Driver
      dbScheme: mysql
      databaseName: openmetadata_db
      auth:
        username: openmetadata_user
        password:
          secretRef: mysql
          secretKey: mysql-password
      dbParams: "allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC"

    elasticsearch:
      enabled: true
      host: opensearch
      searchType: opensearch
      port: 9200
      scheme: http

# Leave security contexts empty — OpenShift assigns UIDs via the anyuid SCC
podSecurityContext: {}
securityContext: {}
```

Then install:

```bash
helm upgrade --install openmetadata open-metadata/openmetadata \
  --namespace openmetadata \
  --values values-openshift.yaml
```

Wait for the server to be ready:

```bash
oc rollout status deployment/openmetadata -n openmetadata
```

### Step 3 — Expose the UI

**For production**, add a `route` block to your `values-openshift.yaml` to create an OpenShift `Route`. When `host` is omitted, OpenShift auto-assigns a hostname under the cluster's default application subdomain:

```yaml
route:
  enabled: true
  # host: openmetadata.apps.<your-cluster-domain>  # optional — auto-assigned if omitted
  tls:
    enabled: true
    termination: edge                  # TLS terminated at the router; pod receives plain HTTP
    insecureEdgeTerminationPolicy: Redirect  # redirect HTTP → HTTPS
```

Then re-apply:

```bash
helm upgrade openmetadata open-metadata/openmetadata \
  --namespace openmetadata \
  --values values-openshift.yaml
```

Get the assigned hostname:

```bash
oc get route openmetadata -n openmetadata -o jsonpath='{.spec.host}'
```

**For local testing only**, use a port-forward instead of a Route:

```bash
kubectl port-forward svc/openmetadata 8585:8585 -n openmetadata
```

Open `http://localhost:8585` — default credentials: `admin / admin`.

#### TLS termination modes

| `tls.termination` | Description |
|-------------------|-------------|
| `edge` | TLS terminated at the OpenShift router; traffic to the pod is plain HTTP. Most common. |
| `reencrypt` | TLS terminated at the router and re-encrypted before forwarding to the pod. |
| `passthrough` | TLS passed through unchanged; the pod must serve TLS directly. |

### How it works — Kubernetes pipeline client

Instead of Airflow, OpenMetadata uses the `K8sPipelineClient` to schedule ingestion. When you trigger a pipeline in the UI, the server creates a Kubernetes `Job` in the configured namespace and monitors it via the API. No separate pipeline orchestrator is needed.

Setting `pipelineServiceClientConfig.k8s.rbac.enabled: true` automatically creates the `ServiceAccount`, `Role`, and `RoleBinding` that the ingestion Jobs need to run.

### Key differences from a standard Kubernetes install

| Aspect | Standard Kubernetes | OpenShift |
|--------|--------------------|-----------|
| Pipeline runner | Airflow (`AirflowRESTClient`) | Kubernetes Jobs (`K8sPipelineClient`) |
| Airflow required | Yes | No |
| Security contexts | Set via `podSecurityContext` | Left empty — OpenShift assigns UIDs via the `anyuid` SCC |
| Image names | Short names accepted | Fully-qualified names required (`docker.io/...`) — ROSA's CRI-O enforces this |
| RBAC | Not required | `pipelineServiceClientConfig.k8s.rbac.enabled: true` |

---

## Setting Up Chart Testing Lint with Pre-commit Hook
#### Why Chart Testing Lint?
When working with Helm charts, it's important to ensure that they meet best practices, are free from errors, and follow the defined guidelines. **Chart Testing (ct) Lint** is a tool designed to automate this process by linting your Helm charts before committing them to the repository. It helps to:
- Catch errors early.
- Enforce best practices in chart development.
- Automatically validate changes to Helm charts during pull requests or commits.


This guide will show you how to integrate `chart-testing` linting into your pre-commit hooks to automatically lint charts before committing them. It also allows you to manually trigger linting when needed.

#### Prerequisites
Before setting up the pre-commit hook, make sure you have the following dependencies installed:

##### 1. Install `chart-testing`
`chart-testing` is a command-line tool used to lint and validate Helm charts. It can be installed using **Homebrew** on macOS.

To install `chart-testing`, run the following command:

```bash
brew install chart-testing
```
##### 2. Install `pre-commit`
To install the pre-commit tool, run:
```bash
pip install pre-commit
```
#### Setting Up Pre-commit Hook for Chart Testing Lint
##### 1. Install the Pre-commit Hook
Once the dependencies are installed, navigate to your repository and run the following command to install the pre-commit hook:
```bash
pre-commit install
```
This will set up the pre-commit hook in the .git/hooks directory of your repository.
##### 2. Manually Trigger the Linting Process
If you need to manually trigger the linting of charts at any time, navigate to the root of your repository and run:
```bash
ct lint --all --check-version-increment=false --use-helmignore
```
---
## Documentation and Support

Check out [OpenMetadata documentation](https://docs.open-metadata.org/) for a complete description of OpenMetadata's features.

Join [our Slack Community](https://slack.open-metadata.org/) if you get stuck, want to chat, or are thinking of a new feature.

Or join the group at [https://groups.google.com/g/openmetadata-users](https://groups.google.com/g/openmetadata-users)

We're here to help - and make OpenMetadata even better!

## Contributors

We ❤️ all contributions, big and small!

Read [Build Code and Run Tests](https://docs.open-metadata.org/developer/build-code-and-run-tests) for how to setup your local development environment. Get started with our [Good first issues](https://github.com/open-metadata/OpenMetadata/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

If you want to, you can reach out via [Slack](https://openmetadata.slack.com/join/shared_invite/zt-wksh1bww-iQGk45NTw6Tp4Q9UZd6QOw#/shared-invite/email) or [email](mailto:dev@open-metadata.org) and we'll set up a pair programming session to get you started.

## License

OpenMetadata is released under [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
