# Open Metadata

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/open-metadata)](https://artifacthub.io/packages/search?repo=open-metadata)

A Helm Chart for Open Metadata.

Current chart version is `0.0.6`

## Install OpenMetadata

Assuming kubectl context points to the correct kubernetes cluster, first create kubernetes secrets that contain MySQL and Airflow passwords as secrets.

```
kubectl create secret generic mysql-secrets --from-literal=openmetadata-user-password=openmetadata_password
kubectl create secret generic airflow-secrets --from-literal=openmetadata-airflow-admin-password=admin
```

The above commands sets the passwords as an example. Change to any password of choice.

Run the following command to install openmetadata with default configuration.

```
helm repo add open-metadata https://helm.open-metadata.org
helm install openmetadata open-metadata/openmetadata
```

If the default configuration is not applicable, you can update the values listed below in a `values.yaml` file and run

```
helm install openmetadata open-metadata/openmetadata --values <<path-to-values-file>>
```

---
**NOTE**

Starting from version `0.0.6` openmetadata Helm charts supports automatic repair and migration of Databases. This will ONLY be handle on Helm chart upgrades to latest versions here-forward.

This is achieved by Helm Hooks currently.

---

## Global Chart Values

| Key | Type | Default |
|-----|------|---------|
| global.airflow.auth.password.secretRef | string | `airflow-secrets` |
| global.airflow.auth.password.secretKey | string | `openmetadata-airflow-admin-password` |
| global.airflow.auth.username | string | `admin` |
| global.airflow.enabled | bool | `true` |
| global.airflow.host | string | `airflow` |
| global.airflow.port | int | 8080 |
| global.elasticsearch.host | string | `elasticsearch` |
| global.elasticsearch.port | int | 9200 |
| global.elasticsearch.scheme | string | `http` |
| global.mysql.auth.password.secretRef | string | `mysql-secrets` |
| global.mysql.auth.password.secretKey | string | `openmetadata-user-password` |
| global.mysql.auth.username | string | `openmetadata_user` |
| global.mysql.databaseName | string | `openmetadata_db` |
| global.mysql.host | string | `mysql` |
| global.mysql.port | int | 3306 |
| global.openmetadata.adminPort | int | 8586 |
| global.openmetadata.host | string | `openmetadata` |
| global.openmetadata.port | int | 8585 |

## Chart Values

| Key | Type | Default |
|-----|------|---------|
| affinity | object | `{}` |
| extraEnvs | Extra [environment variables][] which will be appended to the `env:` definition for the container | `[]` |
| extraVolumes | Templatable string of additional `volumes` to be passed to the `tpl` function | "" |
| extraVolumeMounts | Templatable string of additional `volumeMounts` to be passed to the `tpl` function | "" |
| fullnameOverride | string | `"openmetadata"` |
| image.pullPolicy | string | `"Always"` |
| image.repository | string | `"openmetadata/server"` |
| image.tag | string | `0.8.0` |
| imagePullSecrets | list | `[]` |
| livenessProbe.initialDelaySeconds | int | `80` |
| livenessProbe.periodSeconds | int | `30` |
| livenessProbe.failureThreshold | int | `5` |
| nameOverride | string | `""` |
| nodeSelector | object | `{}` |
| podAnnotations | object | `{}` |
| podSecurityContext | object | `{}` |
| readinessProbe.initialDelaySeconds | int | `80` |
| readinessProbe.periodSeconds | int | `30` |
| readinessProbe.failureThreshold | int | `5` |
| replicaCount | int | `1` |
| resources | object | `{}` |
| securityContext | object | `{}` |
| service.port | int | `8585` |
| service.type | string | `"ClusterIP"` |
| serviceAccount.annotations | object | `{}` |
| serviceAccount.create | bool | `true` |
| serviceAccount.name | string | `nil` |
| tolerations | list | `[]` |

