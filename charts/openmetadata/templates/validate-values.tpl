{{- if not (has .Values.openmetadata.config.authentication.provider (list "basic" "azure" "auth0" "custom-oidc" "google" "okta" "aws-cognito" "ldap" "saml")) }}
  {{ required "The authentication provider must be basic, azure, auth0, custom-oidc, google, okta, aws-cognito, ldap, saml" nil }}
{{- end }}

{{- if .Values.global.openmetadata }}
{{- include "error-message" "Global key has been replaced by openmetadata.config" }}
{{- end }}