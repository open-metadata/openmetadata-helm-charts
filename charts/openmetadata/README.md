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

| Key | Type | Default | Conf/Openmetadata.yaml | 
|-----|------|---------| ---------------------- |
| global.authentication.provider | string | `basic` | AUTHENTICATION_PROVIDER |
| global.authentication.publicKeys | list | `[http://openmetadata:8585/api/v1/config/jwks]` | AUTHENTICATION_PUBLIC_KEYS |
| global.authentication.authority | string | `https://accounts.google.com` | AUTHENTICATION_AUTHORITY |
| global.authentication.clientId | string | `Empty String` | AUTHENTICATION_CLIENT_ID |
| global.authentication.callbackUrl | string | `Empty String` | AUTHENTICATION_CALLBACK_URL |
| global.authentication.enableSelfSignup | bool | `true` | AUTHENTICATION_ENABLE_SELF_SIGNUP |
| global.authentication.jwtPrincipalClaims | list | `[email,preferred_username,sub]` | AUTHENTICATION_JWT_PRINCIPAL_CLAIMS |
| global.authorizer.allowedEmailRegistrationDomains | list | `[all]` | AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN |
| global.authorizer.className | string | `org.openmetadata.service.security.DefaultAuthorizer` | AUTHORIZER_CLASS_NAME |
| global.authorizer.containerRequestFilter | string | `org.openmetadata.service.security.JwtFilter` | AUTHORIZER_REQUEST_FILTER |
| global.authorizer.enforcePrincipalDomain | bool | `false` | AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN |
| global.authorizer.enableSecureSocketConnection | bool | `false` | AUTHORIZER_ENABLE_SECURE_SOCKET |
| global.authorizer.initialAdmins | list | `[admin]` | AUTHORIZER_ADMIN_PRINCIPALS |
| global.authorizer.principalDomain | string | `open-metadata.org` | AUTHORIZER_PRINCIPAL_DOMAIN |
| global.airflow.auth.password.secretRef | string | `airflow-secrets` | AIRFLOW_PASSWORD |
| global.airflow.auth.password.secretKey | string | `openmetadata-airflow-password` | AIRFLOW_PASSWORD |
| global.airflow.auth.username | string | `admin` | AIRFLOW_USERNAME |
| global.airflow.enabled | bool | `true` | |
| global.airflow.host | string | `http://openmetadata-dependencies-web.default.svc.cluster.local:8080` | |
| global.airflow.openmetadata.serverHostApiUrl | string | `http://openmetadata.default.svc.cluster.local:8585/api` | |
| global.airflow.sslCertificatePath | string | `/no/path` | |
| global.airflow.verifySsl | string | `no-ssl` | |
| global.basicLogin.maxLoginFailAttempts | int | 3 | OM_MAX_FAILED_LOGIN_ATTEMPTS |
| global.basicLogin.accessBlockTime | int | 600 | OM_LOGIN_ACCESS_BLOCK_TIME |
| global.clusterName | string | `openmetadata` | OPENMETADATA_CLUSTER_NAME |
| global.database.auth.password.secretRef | string | `mysql-secrets` | DB_USER_PASSWORD |
| global.database.auth.password.secretKey | string | `openmetadata-mysql-password` | DB_USER_PASSWORD |
| global.database.auth.username | string | `openmetadata_user` | DB_USER|
| global.database.databaseName | string | `openmetadata_db` | OM_DATABASE |
| global.database.dbScheme| string | `mysql` | DB_SCHEME |
| global.database.dbUseSSL| bool | `false` | |
| global.database.driverClass| string | `com.mysql.cj.jdbc.Driver` | DB_DRIVER_CLASS |
| global.database.host | string | `mysql` | DB_HOST |
| global.database.port | int | 3306 | DB_PORT |
| global.elasticsearch.auth.enabled | bool | `false` | |
| global.elasticsearch.auth.username | string | `elasticsearch` | ELASTICSEARCH_USER |
| global.elasticsearch.auth.password.secretRef | string | `elasticsearch-secrets` | ELASTICSEARCH_PASSWORD |
| global.elasticsearch.auth.password.secretKey | string | `openmetadata-elasticsearch-password` | ELASTICSEARCH_PASSWORD |
| global.elasticsearch.host | string | `elasticsearch` | ELASTICSEARCH_HOST |
| global.elasticsearch.port | int | 9200 | ELASTICSEARCH_PORT |
| global.elasticsearch.scheme | string | `http` | ELASTICSEARCH_SCHEME |
| global.elasticsearch.searchIndexMappingLanguage | string | `EN`| ELASTICSEARCH_INDEX_MAPPING_LANG |
| global.elasticsearch.trustStore.enabled | bool | `false` | |
| global.elasticsearch.trustStore.path | string | `Empty String` | ELASTICSEARCH_TRUST_STORE_PATH |
| global.elasticsearch.trustStore.password.secretRef | string | `elasticsearch-truststore-secrets` | ELASTICSEARCH_TRUST_STORE_PASSWORD |
| global.elasticsearch.trustStore.password.secretKey | string | `openmetadata-elasticsearch-truststore-password` | ELASTICSEARCH_TRUST_STORE_PASSWORD |
| global.eventMonitor.type | string | `prometheus` | EVENT_MONITOR |
| global.eventMonitor.batchSize | int | `10` | EVENT_MONITOR_BATCH_SIZE |
| global.fernetkey.value | string | `jJ/9sz0g0OHxsfxOoSfdFdmk3ysNmPRnH3TUAbz3IHA=` | FERNET_KEY |
| global.fernetkey.secretRef | string | `` | |
| global.fernetkey.secretKef | string | `` | |
| global.jwtTokenConfiguration.enabled | bool | `true` | |
| global.jwtTokenConfiguration.rsapublicKeyFilePath | string | `./conf/public_key.der` | RSA_PUBLIC_KEY_FILE_PATH |
| global.jwtTokenConfiguration.rsaprivateKeyFilePath | string | `./conf/private_key.der` | RSA_PRIVATE_KEY_FILE_PATH |
| global.jwtTokenConfiguration.jwtissuer | string | `open-metadata.org` | JWT_ISSUER |
| global.jwtTokenConfiguration.keyId | string | `Gb389a-9f76-gdjs-a92j-0242bk94356` | JWT_KEY_ID |
| global.logLevel | string | `INFO` | LOG_LEVEL |
| global.openmetadata.adminPort | int | 8586 | SERVER_ADMIN_PORT |
| global.openmetadata.host | string | `openmetadata` | |
| global.openmetadata.port | int | 8585 | SERVER_PORT |
| global.secretsManager.provider | string | `noop` | SECRET_MANAGER |
| global.secretsManager.additionalParameters.enabled | bool | `false` | |
| global.secretsManager.additionalParameters.accessKeyId.secretRef | string | `aws-access-key-secret` | OM_SM_ACCESS_KEY_ID |
| global.secretsManager.additionalParameters.accessKeyId.secretKey | string | `aws-key-secret` | OM_SM_ACCESS_KEY_ID |
| global.secretsManager.additionalParameters.region | string | `Empty String` | OM_SM_REGION |
| global.secretsManager.additionalParameters.secretAccessKey.secretRef | string | `aws-secret-access-key-secret` | OM_SM_ACCESS_KEY |
| global.secretsManager.additionalParameters.secretAccessKey.secretKey | string | `aws-key-secret` | OM_SM_ACCESS_KEY |
| global.smtpConfig.enableSmtpServer | bool | `false` | AUTHORIZER_ENABLE_SMTP |
| global.smtpConfig.emailingEntity | string | `OpenMetadata` | OM_EMAIL_ENTITY |
| global.smtpConfig.openMetadataUrl | string | `Empty String` | OPENMETADATA_SERVER_URL |
| global.smtpConfig.password.secretKey | string | `Empty String` | SMTP_SERVER_PWD |
| global.smtpConfig.password.secretRef | string | `Empty String` | SMTP_SERVER_PWD |
| global.smtpConfig.serverEndpoint | string | `Empty String` | SMTP_SERVER_ENDPOINT |
| global.smtpConfig.serverPort | string | `Empty String` | SMTP_SERVER_PORT |
| global.smtpConfig.supportUrl | string | `https://slack.open-metadata.org` | OM_SUPPORT_URL |
| global.smtpConfig.transportationStrategy | string | `SMTP_TLS` | SMTP_SERVER_STRATEGY |
| global.smtpConfig.username | string | `Empty String` | SMTP_SERVER_USERNAME |


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

