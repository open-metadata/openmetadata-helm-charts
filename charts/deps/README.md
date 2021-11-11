# Open Metadata Helm Dependencies

A Helm chart for installing components required to run Open Metadata.

## Install

Run the below command -
```sh
helm dependency up .
```
This will update the dependencies required by openmetadata-dependencies helm chart.

Install the openmetadata-dependencies with below command - 

```sh
helm install openmetadata-dependencies .
```

If the default configuration is not applicable, you can update the values listed below in a `values.yaml` file and run
```
helm install openmetadata-dependencies . --values <<path-to-values-file>>
```