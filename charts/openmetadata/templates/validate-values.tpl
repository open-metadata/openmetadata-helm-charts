{{- if not (has .Values.openmetadata.config.authentication.provider (list "basic" "azure" "auth0" "custom-oidc" "google" "okta" "aws-cognito" "ldap" "saml")) }}
  {{ required "The authentication provider must be basic, azure, auth0, custom-oidc, google, okta, aws-cognito, ldap, saml" nil }}
{{- end }}
