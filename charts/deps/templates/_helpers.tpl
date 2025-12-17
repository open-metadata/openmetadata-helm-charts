{{/*
Common labels
*/}}
{{- define "OpenMetadataDeps.labels" -}}
app: airflow
component: logs-cleanup
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- with .Values.cronJobLabels }}
{{ toYaml .}}
{{- end }}
{{- end }}
