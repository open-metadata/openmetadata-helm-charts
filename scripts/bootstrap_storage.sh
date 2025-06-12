#!/bin/bash
set -e

echo "Running OpenMetadata bootstrap..."

/openmetadata/bootstrap/openmetadata-ops.sh bootstrap

echo "Bootstrap complete!"
