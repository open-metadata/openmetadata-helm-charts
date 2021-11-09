# Open Metadata Helm Charts

<div align="center">
  <img src="https://i.imgur.com/5VumwFS.png" align="center" alt="OpenMetadata" height="90"/>
  <hr />
</div>

- [Introduction](#introduction)
- [Setup](#setup)
- [Quickstart](#quickstart)
- [Documentation and Support](#documentation-and-support)
- [Contributors](#contributors)
- [License](#license)

## Introduction
---------------

[This Repository](https://github.com/open-metadata/openmetadata-helm-charts) houses Kubernetes [Helm](https://helm.sh) charts for deploying [Open Metadata](https://github.com/open-metadata/OpenMetadata) and it's dependencies (Elastic Search and MySQL) on a Kubernetes Cluster.

## Setup
---------------

Set up a Kubernetes Cluster
- In a cloud platform of your choice like Amazon EKS, Google Kubernetes Engine or Azure Kubernetes Service
<br />OR<br />
- On Local Environment using Minikube or Docker Desktop. Note, atleast 4 GB of RAM is required to run Open Metadata and it's dependencies.

Install the below tools:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) to manage Kubernetes Resources
- [Helm](https://helm.sh) to deploy resources based on Helm Charts from this repository. Note, we only support Helm 3

## Quickstart
---------------

Assuming Kubernetes setup is done and your kubernetes context is points to a correct kubernetes cluster, first we install Open Metadata dependencies.

1. Clone the exisitng repository
2. Run the below command -

    ```sh
    helm dependency up ./charts/deps
    ```
    This will update the dependencies required by openmetadata-dependencies helm chart.
3. Install the openmetadata-dependencies with below command - 

    ```sh
    helm install openmetadata-dependencies ./charts/deps/
    ```
4. Once the openmetadata-dependencies helm charts pods are in running state, will install openmetadata-server with below command -
    ```sh
    helm install openmetadata ./charts/openmetadata
    ```
    Values in [values.yaml](charts/openmetadata/values.yaml) file have been preset to point to the dependencies deployed using openmetadata-dependencies helm chart.

Run `kubectl get pods` command to check the statuses of pods running you should get a result similar to below.

To expose the Openmetadata UI locally, run the below command -

```sh
kubectl port-forward <openmetadata-front end pod name> 8585:8585
```

## Documentation and Support
---------------
Check out [OpenMetadata documentation](https://docs.open-metadata.org/) for a complete description of OpenMetadata's features.

Join [our Slack Community](https://slack.open-metadata.org/) if you get stuck, want to chat, or are thinking of a new feature.

Or join the group at [https://groups.google.com/g/openmetadata-users](https://groups.google.com/g/openmetadata-users)

We're here to help - and make OpenMetadata even better!

## Contributors
---------------
We ❤️ all contributions, big and small!

Read [Build Code and Run Tests](https://docs.open-metadata.org/open-source-community/developer/build-code-run-tests) for how to setup your local development environment. Get started with our [Good first issues](https://github.com/open-metadata/OpenMetadata/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

If you want to, you can reach out via [Slack](https://openmetadata.slack.com/join/shared_invite/zt-wksh1bww-iQGk45NTw6Tp4Q9UZd6QOw#/shared-invite/email) or [email](mailto:dev@open-metadata.org) and we'll set up a pair programming session to get you started.

## License
---------------
OpenMetadata is released under [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)