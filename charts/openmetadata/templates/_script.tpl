{{- define "check-db-migrations-script" }}
#!/bin/bash
/openmetadata-${OPENMETADATA_APP_VERSION}/bootstrap/bootstrap_storage.sh validate &> /dev/null
if [ $? -ne 0 ]
then
    echo "Failed to validate database migrations. Self healing using bootstrap_storage.sh repair command..."
    /openmetadata-${OPENMETADATA_APP_VERSION}/bootstrap/bootstrap_storage.sh repair
else
    echo "Everything Looks Good!"
fi
{{- end -}}