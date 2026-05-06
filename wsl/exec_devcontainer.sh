#!/usr/bin/env bash

set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo 'docker command not found' >&2
  exit 1
fi

mapfile -t containers < <(docker ps --format '{{.ID}}\t{{.Names}}')

if (( ${#containers[@]} > 1 )); then
  echo "multiple containers detected: ${#containers[@]} entries" >&2
  exit 1
fi

if (( ${#containers[@]} == 0 )); then
  echo 'no running containers detected' >&2
  exit 1
fi

container_id=$(awk -F'\t' '{print $1}' <<< "${containers[0]}")
container_name=$(awk -F'\t' '{print $2}' <<< "${containers[0]}")

echo "container name: ${container_name}"
devcontainer exec --container-id "${container_id}" /bin/bash
