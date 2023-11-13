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
{{- with .Values.commonLabels }}
{{ toYaml .}}
{{- end }}
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

{{/*
Quoted Array of strings with base64 encoding
*/}}
{{- define "OpenMetadata.commaJoinedQuotedEncodedList" }}
{{- $list := list }}
{{- range .value }}
{{- $list = append $list (. | quote ) }}
{{- end }}
{{- $list := join "," $list | toString }}
{{- $list := printf "[%s]" $list }}
{{- $list | b64enc }}
{{- end -}}

{{/*
Build the OpenMetadata Migration Command */}}
{{- define "OpenMetadata.buildUpgradeCommand" }}
command:
- "/bin/bash"
- "-c"
{{- if .Values.openmetadata.config.upgradeMigrationConfigs.force }}
- "/opt/openmetadata/bootstrap/bootstrap_storage.sh migrate-all debug force"
{{- else }}
- "/opt/openmetadata/bootstrap/bootstrap_storage.sh migrate-all"
{{- end }}
{{- end }}

{{/* 
Warning to update openmetadata global keyword to openmetadata.config */}}
{{- define "error-message" }}
{{- printf "Error: %s" . | fail }}
{{- end }}

{{/*
OpenMetadata Configurations Environment Variables*/}}
{{- define "OpenMetadata.configs" -}}
{{- if .Values.openmetadata.config.fernetkey.secretRef -}}
- name: FERNET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.openmetadata.config.fernetkey.secretRef }}
      key: {{ .Values.openmetadata.config.fernetkey.secretKey }}
{{- end }}
{{- if eq .Values.openmetadata.config.authentication.provider "ldap" }}
{{- with .Values.openmetadata.config.authentication.ldapConfiguration.dnAdminPassword }}
- name: AUTHENTICATION_LOOKUP_ADMIN_PWD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- if eq .Values.openmetadata.config.authentication.ldapConfiguration.truststoreConfigType "CustomTrustStore" }}
{{- with .Values.openmetadata.config.authentication.ldapConfiguration.trustStoreConfig.customTrustManagerConfig.trustStoreFilePassword }}
- name: AUTHENTICATION_LDAP_KEYSTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- if eq .Values.openmetadata.config.authentication.provider "saml" }}
{{- with .Values.openmetadata.config.authentication.saml.idp.idpX509Certificate }}
- name: SAML_IDP_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- with .Values.openmetadata.config.authentication.saml.sp.spX509Certificate }}
- name: SAML_SP_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- if or .Values.openmetadata.config.authentication.saml.security.wantAssertionEncrypted .Values.openmetadata.config.authentication.saml.security.wantNameIdEncrypted }}
# Key Store should only be considered if either wantAssertionEncrypted or wantNameIdEncrypted will be true
{{- with .Values.openmetadata.config.authentication.saml.security.keyStoreAlias }}
- name: SAML_KEYSTORE_ALIAS
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- with .Values.openmetadata.config.authentication.saml.security.keyStorePassword }}
- name: SAML_KEYSTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.elasticsearch.auth.enabled -}}
{{- with .Values.openmetadata.config.elasticsearch.auth }}
- name: ELASTICSEARCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .password.secretRef }}
      key: {{ .password.secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.elasticsearch.trustStore.enabled }}
{{- with .Values.openmetadata.config.elasticsearch.trustStore }}
- name: ELASTICSEARCH_TRUST_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .password.secretRef }}
      key: {{ .password.secretKey }}
{{- end }}
{{- end }}
{{- with .Values.openmetadata.config.database.auth }}
- name: DB_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .password.secretRef }}
      key: {{ .password.secretKey }}
{{- end }}
{{- if .Values.openmetadata.config.pipelineServiceClientConfig.enabled }}
{{- with .Values.openmetadata.config.pipelineServiceClientConfig.auth }}
- name: AIRFLOW_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .password.secretRef }}
      key: {{ .password.secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.secretsManager.additionalParameters.enabled }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.accessKeyId }}
- name: OM_SM_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.secretAccessKey }}
- name: OM_SM_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.smtpConfig.enableSmtpServer }}
{{- with .Values.openmetadata.config.smtpConfig.password }}
- name: SMTP_SERVER_PWD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}

{{- end }}