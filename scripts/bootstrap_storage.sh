#!/bin/bash
set -e

echo "Running OpenMetadata bootstrap..."

/opt/openmetadata/bootstrap/openmetadata-ops.sh bootstrap

echo "Bootstrap complete!"
