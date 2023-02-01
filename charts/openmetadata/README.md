# Open Metadata

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/open-metadata)](https://artifacthub.io/packages/search?repo=open-metadata)

A Helm Chart for Open Metadata.

## Install OpenMetadata

Assuming kubectl context points to the correct kubernetes cluster, first create kubernetes secrets that contain MySQL and Airflow passwords as secrets.

```
kubectl create secret generic mysql-secrets --from-literal=openmetadata-mysql-password=openmetadata_password
kubectl create secret generic airflow-secrets --from-literal=openmetadata-airflow-password=admin
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
| global.authentication.provider | string | `basic` |
| global.authentication.publicKeys | list | `[http://openmetadata:8585/api/v1/config/jwks]` |
| global.authentication.authority | string | `https://accounts.google.com` |
| global.authentication.clientId | string | `Empty String` |
| global.authentication.callbackUrl | string | `Empty String` |
| global.authentication.enableSelfSignup | bool | `true` |
| global.authentication.jwtPrincipalClaims | list | `[email,preferred_username,sub]` |
| global.authorizer.allowedEmailRegistrationDomains | list | `[all]` |
| global.authorizer.className | string | `org.openmetadata.service.security.DefaultAuthorizer` |
| global.authorizer.containerRequestFilter | string | `org.openmetadata.service.security.JwtFilter` |
| global.authorizer.enforcePrincipalDomain | bool | `false` |
| global.authorizer.enableSecureSocketConnection | bool | `false` |
| global.authorizer.initialAdmins | list | `[admin]` |
| global.authorizer.principalDomain | string | `open-metadata.org` |
| global.airflow.auth.password.secretRef | string | `airflow-secrets` |
| global.airflow.auth.password.secretKey | string | `openmetadata-airflow-password` |
| global.airflow.auth.username | string | `admin` |
| global.airflow.enabled | bool | `true` |
| global.airflow.host | string | `http://openmetadata-dependencies-web.default.svc.cluster.local:8080` |
| global.airflow.openmetadata.serverHostApiUrl | string | `http://openmetadata.default.svc.cluster.local:8585/api` |
| global.airflow.sslCertificatePath | string | `/no/path` |
| global.airflow.verifySsl | string | `no-ssl` |
| global.basicLogin.maxLoginFailAttempts | int | 3 |
| global.basicLogin.accessBlockTime | int | 600 |
| global.clusterName | string | `openmetadata` |
| global.database.auth.password.secretRef | string | `mysql-secrets` |
| global.database.auth.password.secretKey | string | `openmetadata-mysql-password` |
| global.database.auth.username | string | `openmetadata_user` |
| global.database.databaseName | string | `openmetadata_db` |
| global.database.dbScheme| string | `mysql` |
| global.database.dbUseSSL| bool | `false` |
| global.database.driverClass| string | `com.mysql.cj.jdbc.Driver` |
| global.database.host | string | `mysql` |
| global.database.port | int | 3306 |
| global.elasticsearch.auth.enabled | bool | `false` |
| global.elasticsearch.auth.username | string | `elasticsearch` |
| global.elasticsearch.auth.password.secretRef | string | `elasticsearch-secrets` |
| global.elasticsearch.auth.password.secretKey | string | `openmetadata-elasticsearch-password` |
| global.elasticsearch.host | string | `elasticsearch` |
| global.elasticsearch.port | int | 9200 |
| global.elasticsearch.scheme | string | `http` |
| global.elasticsearch.searchIndexMappingLanguage | string | `EN`|
| global.elasticsearch.trustStore.enabled | bool | `false` |
| global.elasticsearch.trustStore.path | string | `Empty String` |
| global.elasticsearch.trustStore.password.secretRef | string | `elasticsearch-truststore-secrets` |
| global.elasticsearch.trustStore.password.secretKey | string | `openmetadata-elasticsearch-truststore-password` |
| global.eventMonitor.type | string | `prometheus` |
| global.eventMonitor.batchSize | int | `10` |
| global.fernetkey.value | string | `jJ/9sz0g0OHxsfxOoSfdFdmk3ysNmPRnH3TUAbz3IHA=` |
| global.fernetkey.secretRef | string | `` |
| global.fernetkey.secretKef | string | `` |
| global.jwtTokenConfiguration.enabled | bool | `true` |
| global.jwtTokenConfiguration.rsapublicKeyFilePath | string | `./conf/public_key.der` |
| global.jwtTokenConfiguration.rsaprivateKeyFilePath | string | `./conf/private_key.der` |
| global.jwtTokenConfiguration.jwtissuer | string | `open-metadata.org` |
| global.jwtTokenConfiguration.keyId | string | `Gb389a-9f76-gdjs-a92j-0242bk94356` |
| global.logLevel | string | `INFO` |
| global.openmetadata.adminPort | int | 8586 |
| global.openmetadata.host | string | `openmetadata` |
| global.openmetadata.port | int | 8585 |
| global.secretsManager.provider | string | `noop` |
| global.secretsManager.additionalParameters.enabled | bool | `false` |
| global.secretsManager.additionalParameters.accessKeyId.secretRef | string | `aws-access-key-secret` |
| global.secretsManager.additionalParameters.accessKeyId.secretKey | string | `aws-key-secret` |
| global.secretsManager.additionalParameters.region | string | `Empty String` |
| global.secretsManager.additionalParameters.secretAccessKey.secretRef | string | `aws-secret-access-key-secret` |
| global.secretsManager.additionalParameters.secretAccessKey.secretKey | string | `aws-key-secret` |
| global.smtpConfig.enableSmtpServer | bool | `false` |
| global.smtpConfig.emailingEntity | string | `OpenMetadata` |
| global.smtpConfig.openMetadataUrl | string | `Empty String` |
| global.smtpConfig.password.secretKey | string | `Empty String` |
| global.smtpConfig.password.secretRef | string | `Empty String` |
| global.smtpConfig.serverEndpoint | string | `Empty String` |
| global.smtpConfig.serverPort | string | `Empty String` |
| global.smtpConfig.supportUrl | string | `https://slack.open-metadata.org` |
| global.smtpConfig.transportationStrategy | string | `SMTP_TLS` |
| global.smtpConfig.username | string | `Empty String` |


## Chart Values

| Key | Type | Default |
|-----|------|---------|
| affinity | object | `{}` |
| extraEnvs | Extra [environment variables][] which will be appended to the `env:` definition for the container | `[]` |
| extraVolumes | Templatable string of additional `volumes` to be passed to the `tpl` function | "" |
| extraVolumeMounts | Templatable string of additional `volumeMounts` to be passed to the `tpl` function | "" |
| fullnameOverride | string | `"openmetadata"` |
| image.pullPolicy | string | `"Always"` |
| image.repository | string | `"docker.getcollate.io/openmetadata/server"` |
| image.tag | string | `0.13.2` |
| imagePullSecrets | list | `[]` |
| ingress.annotations | object | `{}` |
| ingress.className | string | `""` |
| ingress.enabled | bool | `false` |
| ingress.hosts[0].host | string | `"open-metadata.local"` |
| ingress.hosts[0].paths[0].path | string | `"/"` |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |
| livenessProbe.initialDelaySeconds | int | `60` |
| livenessProbe.periodSeconds | int | `30` |
| livenessProbe.failureThreshold | int | `5` |
| nameOverride | string | `""` |
| nodeSelector | object | `{}` |
| podAnnotations | object | `{}` |
| podSecurityContext | object | `{}` |
| readinessProbe.initialDelaySeconds | int | `60` |
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
| sidecars | list | `[]` |
| tolerations | list | `[]` |

