#!/bin/bash
set -e

echo "Running OpenMetadata bootstrap..."

# Run DB migrations, seed metadata, setup roles and policies
/openmetadata/scripts/upgrade_schema.sh
/openmetadata/scripts/bootstrap_data.sh

echo "Bootstrap complete!"
