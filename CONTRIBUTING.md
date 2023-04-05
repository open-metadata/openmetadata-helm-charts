# Contributors

We ❤️ all contributions, big and small!

Read [Kubennetes Deployment](https://docs.open-metadata.org/deployment/kubernetes#quickstart) for how to setup your local helm environment. Get started with our [Good first issues](https://github.com/open-metadata/openmetadata-helm-charts/issues).

You can reach out to us via [Slack](https://slack.open-metadata.org/).

# Contributing

Open MetaData Helm is a collection of **community maintained** charts. Therefore we rely on you to test your changes sufficiently. 

## Pull Requests

All submissions, including submissions by project members, require review. We use GitHub pull requests for this purpose. Consult [GitHub Help](https://help.github.com/articles/about-pull-requests/) for more information on using pull requests. See the above stated requirements for PR on this project.

## Documentation

The documentation is updated [here](https://docs.open-metadata.org/deployment/kubernetes). This ensures that the values are consistent with the chart documentation.


There are two Helm Chart repositories that we maintain:

[openmetadata-dependencies](https://github.com/open-metadata/openmetadata-helm-charts/tree/main/charts/deps): This chart contains dependencies for Open Metadata Helm Charts.
[openmetadata](https://github.com/open-metadata/openmetadata-helm-charts/tree/main/charts/openmetadata): This chart contains the core Open Metadata Helm Chart.

## Versioning

Each chart's version follows the [semver standard](https://semver.org/).

### New Application Versions

The app version number of the application being deployed is updated [here](https://github.com/open-metadata/openmetadata-helm-charts/blob/main/charts/openmetadata/Chart.yaml)

Please ensure chart version changes adhere to semantic versioning standards:

* Major: Large chart rewrites, major non-backwards compatible or destructive changes
* Minor: New chart functionality (sidecars), major application updates or minor non-backwards compatible changes
* Patch: App version patch updates, backwards compatible optional chart features

### Immutability

Each release for each chart must be immutable. Any change to a chart (even just documentation) requires a version bump. Trying to release the same version twice will result in an error.

### Chart Versioning

Currently we require a chart version bump for every change to a chart, including updating information for older verions.  This may change in the future.

## Testing

### Testing Open MetaData Workflows Changes

Create kubernetes secrets that contains MySQL and Airflow passwords as secrets

```shell
kubectl create secret generic mysql-secrets --from-literal=openmetadata-mysql-password=openmetadata_password
kubectl create secret generic airflow-secrets --from-literal=openmetadata-airflow-password=admin
kubectl create secret generic airflow-mysql-secrets --from-literal=airflow-mysql-password=airflow_pass
```

install the OpenMetaData dependencies:

```shell
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies
```
From the dependency repo you can updated and install the dependency. This will be used to download the dependency charts you can find [here](https://github.com/open-metadata/openmetadata-helm-charts/blob/afa8c5e6b551f65b6a11dafafb3e22f95b9330c9/charts/deps/Chart.yaml#L60)

```shell
helm dependency update .
```

Check the pods are running or not

```shell
kubectl get pods
```

Deploy Open Metadata
```shell
helm install openmetadata open-metadata/openmetadata
```
Follow [these](https://docs.open-metadata.org/deployment/kubernetes) instructions for running Open MetaData.


### Testing Helm Changes

To Test around the charts and values you can refer [Helm lint](https://helm.sh/docs/helm/helm_lint/) and [Helm values](https://helm.sh/docs/helm/helm_show_values/)

```shell
helm lint . --values values.yaml
```

Test your values:

```shell
helm template --dry-run openmetadata . --values values.yaml --debug
```
Ref: [Helm template](https://helm.sh/docs/helm/helm_template/)

Clean-up:

```shell
helm uninstall openmetadata
helm uninstall openmetadata-dependencies
```


## Publishing Changes

Changes are automatically publish whenever a commit is merged to the `main` branch by the CI job (see `./.github/workflows/publish.yml`).
We release our charts on Artifact Hub, please refer the chart annotations.[Artifact Hub-OpenMetadata](https://artifacthub.io/packages/helm/open-metadata/openmetadata)
