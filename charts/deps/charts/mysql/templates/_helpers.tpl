{{- define "mysql.name" -}}
{{- default (printf "%s-mysql" .Release.Name) .Values.fullnameOverride | trunc 54 | trimSuffix "-" -}}
{{- end -}}
{{- define "mysql.labels" -}}
app.kubernetes.io/name: mysql
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: official-mysql
{{- end -}}
{{- define "mysql.secret" -}}
{{- default (include "mysql.name" .) .Values.auth.existingSecret -}}
{{- end -}}
