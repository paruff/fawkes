#!/usr/bin/env bash
# Set up Docker Machine environment for Git Bash on Windows

set -euo pipefail

DOCKER_MACHINE="C:\\Program Files\\Docker\\Docker\\Resources\\bin\\docker-machine.exe"
MACHINE_NAME="default"

# Check if Docker Machine executable exists
if [ ! -x "$DOCKER_MACHINE" ]; then
  echo "Error: Docker Machine not found at $DOCKER_MACHINE"
  exit 1
fi

# Check if Docker Machine is running
if ! "$DOCKER_MACHINE" status "$MACHINE_NAME" | grep -qi "Running"; then
  echo "Starting Docker Machine '$MACHINE_NAME'..."
  "$DOCKER_MACHINE" start "$MACHINE_NAME"
fi

# Set environment variables for Docker (fixes SC2046)
eval "$("$DOCKER_MACHINE" env "$MACHINE_NAME")"

echo "Docker environment set for machine '$MACHINE_NAME'."
