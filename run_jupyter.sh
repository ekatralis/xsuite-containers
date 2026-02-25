#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/ekatralis/xsuite-containers:latest"
PORT="${PORT:-8888}"
ENGINE="${ENGINE:-}"

usage() {
  echo "Usage: $0 /PATH/TO/NOTEBOOKS"
  echo "Env: PORT=8888 (optional), ENGINE=docker|podman (optional, auto-detected)"
}

NOTEBOOKS_DIR="${1:-}"
if [[ -z "${NOTEBOOKS_DIR}" ]]; then
  usage
  exit 1
fi

if [[ ! -d "${NOTEBOOKS_DIR}" ]]; then
  echo "Error: '${NOTEBOOKS_DIR}' is not a directory."
  exit 1
fi

if [[ -z "${ENGINE}" ]]; then
    echo "Automatically selecting container engine..."
    # Prefer podman if present, otherwise docker
    if command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
    elif command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
    else
    echo "Error: neither 'podman' nor 'docker' found in PATH."
    exit 1
    fi
fi

echo "Using container engine: ${ENGINE}"
echo "Pulling image: ${IMAGE}"
"${ENGINE}" pull "${IMAGE}"

JUPYTER_CMD="source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace"

# Detect OS
OS="$(uname -s)"

# Build engine args depending on OS + podman mode rules
ENGINE_ARGS=()
VOLUME_ARG=( -v "${NOTEBOOKS_DIR}:/workspace" )
PORT_ARG=( -p "${PORT}:8888" )

if [[ "${ENGINE}" == "docker" ]]; then
  # Docker is the same as podman rootful mode
  ENGINE_ARGS+=( "--group-add=$(id -g)" )
elif [[ "${OS}" == "Darwin" ]]; then
  # macOS podman runs in a VM (rootful), use macOS-specific user/group setup
  ENGINE_ARGS+=( "--user" "$(id -u):$(id -g)" "--group-add" "2020" )
else
  # Linux + podman: choose rootless vs rootful
  ROOTLESS="$("${ENGINE}" info --format '{{.Host.Security.Rootless}}' 2>/dev/null || echo "false")"
  if [[ "${ROOTLESS}" == "true" ]]; then
    ENGINE_ARGS+=( "--userns=keep-id" )
  else
    ENGINE_ARGS+=( "--group-add=$(id -g)" )
  fi
fi

echo "Starting Jupyter Lab on http://localhost:${PORT}"
echo "Mounting notebooks: ${NOTEBOOKS_DIR} -> /workspace"

exec "${ENGINE}" run --rm -it \
  "${ENGINE_ARGS[@]}" \
  "${PORT_ARG[@]}" \
  "${VOLUME_ARG[@]}" \
  "${IMAGE}" \
  bash -lc "${JUPYTER_CMD}"