{{- if (
  and
    (eq .Values.global.authentication.provider "azure")
    (.Values.global.airflow.openmetadata.authConfig.azure.clientSecret.secretRef)
    (.Values.global.airflow.openmetadata.authConfig.azure.clientSecret.secretKey)
    (.Values.global.airflow.openmetadata.authConfig.azure.authority)
    (.Values.global.airflow.openmetadata.authConfig.azure.clientId )
    (.Values.global.airflow.openmetadata.authConfig.azure.scopes)
) }}
  {{ required "The authentication provider azure must be configured in .global.airflow.openmetadata.authConfig.azure" nil }}
{{- end }}

{{- if (
  and
    (eq .Values.global.authentication.provider "google")
    (.Values.global.airflow.openmetadata.authConfig.google.secretKeyPath)
    (.Values.global.airflow.openmetadata.authConfig.google.audience)
) }}
  {{ required "The authentication provider google must be configured in .global.airflow.openmetadata.authConfig.google" nil }}
{{- end }}

{{- if (
  and
    (eq .Values.global.authentication.provider "okta")
    (.Values.global.airflow.openmetadata.authConfig.okta.privateKey.secretRef)
    (.Values.global.airflow.openmetadata.authConfig.okta.privateKey.secretKey)
    (.Values.global.airflow.openmetadata.authConfig.okta.email)
    (.Values.global.airflow.openmetadata.authConfig.okta.clientId)
    (.Values.global.airflow.openmetadata.authConfig.okta.orgUrl)
    (.Values.global.airflow.openmetadata.authConfig.okta.scope)
) }}
  {{ required "The authentication provider okta must be configured in .global.airflow.openmetadata.authConfig.okta" nil }}
{{- end }}

{{- if (
  and
    (eq .Values.global.authentication.provider "auth0")
    (.Values.global.airflow.openmetadata.authConfig.auth0.secretKey.sercretRef)
    (.Values.global.airflow.openmetadata.authConfig.auth0.secretKey.secretKey)
    (.Values.global.airflow.openmetadata.authConfig.auth0.domain)
    (.Values.global.airflow.openmetadata.authConfig.auth0.clientId)
) }}
  {{ required "The authentication provider auth0 must be configured in .global.airflow.openmetadata.authConfig.auth0" nil }}
{{- end }}

{{- if (
  and
    (eq .Values.global.authentication.provider "openmetadata")
    (.Values.global.airflow.openmetadata.authConfig.openmetadata.jwtToken.secretRef)
    (.Values.global.airflow.openmetadata.authConfig.openmetadata.jwtToken.secretKey)
) }}
  {{ required "The authentication provider openmetadata must be configured in .global.airflow.openmetadata.authConfig.openmetadata" nil }}
{{- end }}

{{- if (
 and
    (eq .Values.global.authentication.provider "custom-oidc")
    (.Values.global.airflow.openmetadata.authConfig.customOidc.secretKey.sercretRef)
    (.Values.global.airflow.openmetadata.authConfig.customOidc.secretKey.secretKey)
    (.Values.global.airflow.openmetadata.authConfig.customOidc.tokenEndpoint)
    (.Values.global.airflow.openmetadata.authConfig.customOidc.clientId)
) }}
  {{ required "The authentication provider custom-oidc must be configured in .global.airflow.openmetadata.authConfig.customOidc" nil }}
{{- end }}
