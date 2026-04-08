{{- if not (has .Values.openmetadata.config.authentication.provider (list "basic" "azure" "auth0" "custom-oidc" "google" "okta" "aws-cognito" "ldap" "saml")) }}
  {{ required "The authentication provider must be basic, azure, auth0, custom-oidc, google, okta, aws-cognito, ldap, saml" nil }}
{{- end }}

{{- if not .Values.openmetadata.config.openmetadata }}
{{- include "error-message" "Global key has been replaced by openmetadata.config. Please refer docs for the further explaination." }}
{{- end }}

{{- $externalExposureModes := 0 }}
{{- if .Values.ingress.enabled }}
  {{- $externalExposureModes = add1 $externalExposureModes }}
{{- end }}
{{- if .Values.gateway.enabled }}
  {{- $externalExposureModes = add1 $externalExposureModes }}
{{- end }}
{{- if .Values.route.enabled }}
  {{- $externalExposureModes = add1 $externalExposureModes }}
{{- end }}
{{- if .Values.istio.enabled }}
  {{- $externalExposureModes = add1 $externalExposureModes }}
{{- end }}
{{- if gt $externalExposureModes 1 }}
{{- include "error-message" "Only one of ingress.enabled, gateway.enabled, route.enabled, or istio.enabled can be true." }}
{{- end }}

{{- if and .Values.istio.enabled (not .Values.istio.gateway.create) (empty .Values.istio.virtualService.gateways) }}
{{- include "error-message" "istio.virtualService.gateways must be set when istio.enabled=true and istio.gateway.create=false." }}
{{- end }}
