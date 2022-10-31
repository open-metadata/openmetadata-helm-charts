{{- if not (has .Values.global.authentication.provider (list "basic" "azure" "auth0" "custom-oidc" "google" "okta" "aws-cognito")) }}
  {{ required "The authentication provider must be basic, azure, auth0, custom-oidc, google, okta, aws-cognito" nil }}
{{- end }}
