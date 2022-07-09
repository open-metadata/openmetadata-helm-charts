<div align="center">
  <img src="https://i.imgur.com/5VumwFS.png" align="center" alt="OpenMetadata" height="90"/>
  <hr />
</div>

# Open Metadata Helm Charts [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/open-metadata)](https://artifacthub.io/packages/search?repo=open-metadata)

- [Introduction](#introduction)
- [Setup](#setup)
- [Quickstart](#quickstart)
- [Documentation and Support](#documentation-and-support)
- [Contributors](#contributors)
- [License](#license)

## Introduction


[This Repository](https://github.com/open-metadata/openmetadata-helm-charts) houses Kubernetes [Helm](https://helm.sh) charts for deploying [Open Metadata](https://github.com/open-metadata/OpenMetadata) and it's dependencies (Elastic Search and MySQL) on a Kubernetes Cluster.

## Setup


Set up a Kubernetes Cluster
- In a cloud platform of your choice like [Amazon EKS](https://aws.amazon.com/eks/), [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) or [Azure Kubernetes Service](https://azure.microsoft.com/en-in/services/kubernetes-service/#overview)
<br />OR<br />
- On Local Environment using [Minikube](https://minikube.sigs.k8s.io/docs) or [Docker Desktop](https://www.docker.com/products/docker-desktop). Note, atleast 4 GB of RAM is required to run Open Metadata and it's dependencies.

Install the below tools:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) to manage Kubernetes Resources
- [Helm](https://helm.sh) to deploy resources based on Helm Charts from this repository. Note, we only support Helm 3

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
NAME                            READY   STATUS    RESTARTS   AGE
elasticsearch-0                 1/1     Running   0          3m56s
mysql-0                         1/1     Running   0          3m56s
```

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
