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
Quoted Array of strings
*/}}
{{- define "OpenMetadata.commaJoinedQuotedList" }}
{{- $list := list }}
{{- range .value }}
{{- $list = append $list (. | quote) }}
{{- end }}
{{- join "," $list }}
{{- end -}}


{{/* 
Warning to update openmetadata global keyword to openmetadata.config */}}
{{- define "error-message" }}
{{- printf "Error: %s" . | fail }}
{{- end }}
