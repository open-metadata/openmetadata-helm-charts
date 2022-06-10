{{/*
Expand the name of the chart.
*/}}
{{- define "OpenMetadata.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "OpenMetadata.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "OpenMetadata.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "OpenMetadata.labels" -}}
helm.sh/chart: {{ include "OpenMetadata.chart" . }}
{{ include "OpenMetadata.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "OpenMetadata.selectorLabels" -}}
app.kubernetes.io/name: {{ include "OpenMetadata.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "OpenMetadata.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "OpenMetadata.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "OpenMetadata.Airflow.authProviderConfig" }}
{{- if eq .Values.global.airflow.openmetadata.authProvider "azure" -}}
- name: OM_AUTH_AIRFLOW_AZURE_CLIENT_ID
  value: "{{ .Values.global.airflow.openmetadata.authConfig.azure.clientId }}"
{{- with .Values.global.airflow.openmetadata.authConfig.azure.clientSecret }}
- name: OM_AUTH_AIRFLOW_AZURE_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
- name: OM_AUTH_AIRFLOW_AZURE_AUTHORITY_URL
  value: "{{ .Values.global.airflow.openmetadata.authConfig.azure.authority }}"
- name: OM_AUTH_AIRFLOW_AZURE_SCOPES
  value: "[{{ .Values.global.airflow.openmetadata.authConfig.azure.scopes | join "," }}]"
{{- else if eq .Values.global.airflow.openmetadata.authProvider "google" -}}
- name: OM_AUTH_AIRFLOW_GOOGLE_SECRET_KEY_PATH
  value: "{{ .Values.global.airflow.openmetadata.authConfig.google.secretKeyPath }}"
- name: OM_AUTH_AIRFLOW_GOOGLE_AUDIENCE
  value: "{{ .Values.global.airflow.openmetadata.authConfig.google.audience }}"
{{- else if eq .Values.global.airflow.openmetadata.authProvider "okta" -}}
- name: OM_AUTH_AIRFLOW_OKTA_CLIENT_ID
  value: "{{ .Values.global.airflow.openmetadata.authConfig.okta.clientId }}"
- name: OM_AUTH_AIRFLOW_OKTA_ORGANIZATION_URL
  value: "{{ .Values.global.airflow.openmetadata.authConfig.okta.orgUrl }}"
{{- with .Values.global.airflow.openmetadata.authConfig.okta.privateKey }}
- name: OM_AUTH_AIRFLOW_OKTA_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
- name: OM_AUTH_AIRFLOW_OKTA_SA_EMAIL
  value: "{{ .Values.global.airflow.openmetadata.authConfig.okta.email }}"
- name: OM_AUTH_AIRFLOW_OKTA_SCOPES
  value: "[{{ .Values.global.airflow.openmetadata.authConfig.okta.scopes | join "," }}]"
{{- else if eq .Values.global.airflow.openmetadata.authProvider "auth0" -}}
- name: OM_AUTH_AIRFLOW_AUTH0_CLIENT_ID
  value: "{{ .Values.global.airflow.openmetadata.authConfig.auth0.clientId }}"
{{- with .Values.global.airflow.openmetadata.authConfig.auth0.secretKey }}
- name: OM_AUTH_AIRFLOW_AUTH0_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
- name: OM_AUTH_AIRFLOW_AUTH0_DOMAIN_URL
  value: "{{ .Values.global.airflow.openmetadata.authConfig.auth0.domain }}"
{{- else if eq .Values.global.airflow.openmetadata.authProvider "custom-oidc" -}}
- name: OM_AUTH_AIRFLOW_CUSTOM_OIDC_CLIENT_ID
  value: "{{ .Values.global.airflow.openmetadata.authConfig.customOidc.clientId }}"
- name: OM_AUTH_AIRFLOW_CUSTOM_OIDC_SECRET_KEY_PATH
  value: "{{ .Values.global.airflow.openmetadata.authConfig.customOidc.secretKeyPath }}"
- name: OM_AUTH_AIRFLOW_CUSTOM_OIDC_TOKEN_ENDPOINT_URL
  value: "{{ .Values.global.airflow.openmetadata.authConfig.customOidc.tokenEndpoint }}"
{{- else if eq .Values.global.airflow.openmetadata.authProvider "openmetadata" -}}
{{- with .Values.global.airflow.openmetadata.authConfig.openMetadataJWT.jwtToken }}
- name: OM_AUTH_JWT_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end -}}
{{- end -}}
