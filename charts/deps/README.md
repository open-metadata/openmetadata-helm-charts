# Open Metadata Helm Dependencies

A Helm chart for installing components required to run Open Metadata.

## Install OpenMetadata

Run the following command to install openmetadata with default configuration.

```
helm repo add open-metadata https://helm.open-metadata.org
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies
```

If the default configuration is not applicable, you can update the values listed below in a `values.yaml` file and run

```
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies --values <<path-to-values-file>>
```