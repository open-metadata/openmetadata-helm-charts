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
{{- default "default" (tpl .Values.serviceAccount.name .) }}
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
{{- if .Values.openmetadata.config.upgradeMigrationConfigs.debug }}
- "/opt/openmetadata/bootstrap/openmetadata-ops.sh -d migrate {{ .Values.openmetadata.config.upgradeMigrationConfigs.additionalArgs }}"
{{- else }}
- "/opt/openmetadata/bootstrap/openmetadata-ops.sh migrate {{ .Values.openmetadata.config.upgradeMigrationConfigs.additionalArgs }}"
{{- end }}
{{- end }}

{{/*
Warning to update openmetadata global keyword to openmetadata.config */}}
{{- define "error-message" }}
{{- printf "Error: %s" . | fail }}
{{- end }}


{{/*
Function to check if passed value is empty string or null value */}}
{{- define "OpenMetadata.utils.checkEmptyString" -}}
{{- if or (empty .) (eq . "") -}}
{{- false -}}
{{- else -}}
{{- true -}}
{{- end -}}
{{- end -}}

{{/*
OpenMetadata Configurations AWS Additional Parameters Environment Variables for Secret Manager*/}}
{{- define "OpenMetadata.configs.secretManager.aws.additionalParameters" -}}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.accessKeyId }}
{{- if .secretRef }}
- name: OM_SM_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.secretAccessKey }}
{{- if .secretRef }}
- name: OM_SM_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
OpenMetadata Configurations Azure Additional Parameters Environment Variables for Secret Manager
*/}}
{{- define "OpenMetadata.configs.secretManager.azure.additionalParameters" -}}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.clientId }}
{{- if .secretRef }}
- name: OM_SM_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.clientSecret }}
{{- if .secretRef }}
- name: OM_SM_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.tenantId }}
{{- if .secretRef }}
- name: OM_SM_TENANT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.vaultName }}
{{- if .secretRef }}
- name: OM_SM_VAULT_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end -}}


{{/*
OpenMetadata Configurations GCP Additional Parameters Environment Variables for Secret Manager
*/}}
{{- define "OpenMetadata.configs.secretManager.gcp.additionalParameters" -}}
{{- with .Values.openmetadata.config.secretsManager.additionalParameters.projectId }}
{{- if .secretRef }}
- name: OM_SM_PROJECT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
OpenMetadata Configurations Environment Variables*/}}
{{- define "OpenMetadata.configs" -}}
{{- if .Values.openmetadata.config.fernetkey.secretRef -}}
{{- with .Values.openmetadata.config.fernetkey -}}
- name: FERNET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if and (eq .Values.openmetadata.config.authentication.clientType "confidential") (.Values.openmetadata.config.authentication.oidcConfiguration.enabled) }}
{{- with .Values.openmetadata.config.authentication.oidcConfiguration.clientId }}
- name: OIDC_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- with .Values.openmetadata.config.authentication.oidcConfiguration.clientSecret }}
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if eq .Values.openmetadata.config.authentication.provider "ldap" }}
{{- if .Values.openmetadata.config.authentication.ldapConfiguration.dnAdminPassword.secretRef }}
{{- with .Values.openmetadata.config.authentication.ldapConfiguration.dnAdminPassword }}
- name: AUTHENTICATION_LOOKUP_ADMIN_PWD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if and ( eq .Values.openmetadata.config.authentication.ldapConfiguration.truststoreConfigType "CustomTrustStore" ) ( .Values.openmetadata.config.authentication.ldapConfiguration.trustStoreConfig.customTrustManagerConfig.trustStoreFilePassword.secretRef ) }}
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
{{- if .Values.openmetadata.config.authentication.saml.idp.idpX509Certificate.secretRef }}
{{- with .Values.openmetadata.config.authentication.saml.idp.idpX509Certificate }}
- name: SAML_IDP_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.authentication.saml.sp.spX509Certificate.secretRef }}
{{- with .Values.openmetadata.config.authentication.saml.sp.spX509Certificate }}
- name: SAML_SP_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.authentication.saml.sp.spPrivateKey.secretRef }}
{{- with .Values.openmetadata.config.authentication.saml.sp.spPrivateKey }}
- name: SAML_SP_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.authentication.saml.security.wantAssertionEncrypted }}
# Key Store should only be considered if wantAssertionEncrypted will be true
{{- if .Values.openmetadata.config.authentication.saml.security.keyStoreAlias.secretRef }}
{{- with .Values.openmetadata.config.authentication.saml.security.keyStoreAlias }}
- name: SAML_KEYSTORE_ALIAS
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.authentication.saml.security.keyStorePassword.secretRef }}
{{- with .Values.openmetadata.config.authentication.saml.security.keyStorePassword }}
- name: SAML_KEYSTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if and ( .Values.openmetadata.config.elasticsearch.auth.enabled ) ( .Values.openmetadata.config.elasticsearch.auth.password.secretRef ) }}
{{- with .Values.openmetadata.config.elasticsearch.auth.password }}
- name: ELASTICSEARCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if and ( .Values.openmetadata.config.elasticsearch.trustStore.enabled ) ( .Values.openmetadata.config.elasticsearch.trustStore.password.secretRef ) }}
{{- with .Values.openmetadata.config.elasticsearch.trustStore.password }}
- name: ELASTICSEARCH_TRUST_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.database.auth.password.secretRef }}
{{- with .Values.openmetadata.config.database.auth.password }}
- name: DB_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if and ( .Values.openmetadata.config.pipelineServiceClientConfig.enabled ) ( .Values.openmetadata.config.pipelineServiceClientConfig.auth.enabled )}}
{{- if .Values.openmetadata.config.pipelineServiceClientConfig.auth.password.secretRef }}
{{- with .Values.openmetadata.config.pipelineServiceClientConfig.auth.password }}
- name: AIRFLOW_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.pipelineServiceClientConfig.auth.trustStorePassword.secretRef }}
{{- with .Values.openmetadata.config.pipelineServiceClientConfig.auth.trustStorePassword }}
- name: AIRFLOW_TRUST_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.secretsManager.additionalParameters.enabled }}
{{- if has .Values.openmetadata.config.secretsManager.provider (list "aws" "aws-ssm" "managed-aws" "managed-aws-ssm") }}
{{ include "OpenMetadata.configs.secretManager.aws.additionalParameters" . }}
{{- end }}
{{- if has .Values.openmetadata.config.secretsManager.provider (list "managed-azure-kv" "azure-kv") }}
{{ include "OpenMetadata.configs.secretManager.azure.additionalParameters" . }}
{{- end }}
{{- if has .Values.openmetadata.config.secretsManager.provider (list "gcp") }}
{{ include "OpenMetadata.configs.secretManager.gcp.additionalParameters" . }}
{{- end }}
{{- end }}
{{- if .Values.openmetadata.config.rdf.enabled }}
{{- if .Values.openmetadata.config.rdf.password.secretRef }}
{{- with .Values.openmetadata.config.rdf.password }}
- name: RDF_REMOTE_PASSWORD
  valueFrom:
    secretKeyRef: 
      name: {{ .secretRef }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Build the OpenMetadata Deploy Pipelines Command using deployPipelinesConfig */}}
{{- define "OpenMetadata.buildDeployPipelinesCommand" }}
  - "/bin/bash"
  - "-c"
  {{- if .Values.openmetadata.config.deployPipelinesConfig.debug }}
  - "/opt/openmetadata/bootstrap/openmetadata-ops.sh -d deploy-pipelines {{ default "" .Values.openmetadata.config.deployPipelinesConfig.additionalArgs }}"
  {{- else }}
  - "/opt/openmetadata/bootstrap/openmetadata-ops.sh deploy-pipelines {{ default "" .Values.openmetadata.config.deployPipelinesConfig.additionalArgs }}"
  {{- end }}
{{- end }}


{{/*
Build the OpenMetadata Deploy Pipelines Command using reindexConfig */}}
{{- define "OpenMetadata.buildReindexCommand" }}
  - "/bin/bash"
  - "-c"
  {{- if .Values.openmetadata.config.reindexConfig.debug }}
  - "/opt/openmetadata/bootstrap/openmetadata-ops.sh -d reindex {{ default "" .Values.openmetadata.config.reindexConfig.additionalArgs }}"
  {{- else }}
  - "/opt/openmetadata/bootstrap/openmetadata-ops.sh reindex {{ default "" .Values.openmetadata.config.reindexConfig.additionalArgs }}"
  {{- end }}
{{- end }}