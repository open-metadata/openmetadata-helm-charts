set -e

echo "Running OpenMetadata bootstrap..."

# Ensure the ops script exists
if [ -f "/opt/openmetadata/bootstrap/openmetadata-ops.sh" ]; then
    /opt/openmetadata/bootstrap/openmetadata-ops.sh bootstrap
else
    echo "Error: openmetadata-ops.sh not found!"
    exit 1
fi

echo "Bootstrap complete!"