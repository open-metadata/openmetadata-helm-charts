{{/*
Common labels
*/}}
{{- define "OpenMetadataDeps.labels" -}}
app: {{ include "airflow.labels.app" . }}
component: logs-cleanup
chart: {{ include "airflow.labels.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- with .Values.cronJobLabels }}
{{ toYaml .}}
{{- end }}
{{- end }}
