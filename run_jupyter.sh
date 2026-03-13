#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/ekatralis/xsuite-containers:latest"
PORT="${PORT:-8888}"
ENGINE="${ENGINE:-}"
JUPYTER_TOKEN="${JUPYTER_TOKEN:-"xsuite"}"

usage() {
  echo "Usage: $0 /PATH/TO/NOTEBOOKS"
  echo "Env: PORT=8888 (optional), ENGINE=docker|podman (optional, auto-detected), JUPYTER_TOKEN=auto|<token> (optional, default 'xsuite')"
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

# Promote to absolute path for best compatibility
NOTEBOOKS_DIR="$(cd "${NOTEBOOKS_DIR}" && pwd -P)"

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

JUPYTER_CMD="jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace"

if [[ "${JUPYTER_TOKEN}" != "auto" ]]; then
    JUPYTER_CMD+=" --ServerApp.token='${JUPYTER_TOKEN}'"
    echo "Starting Jupyter Lab on http://localhost:${PORT}/lab?token=${JUPYTER_TOKEN}"
else
    echo "Starting Jupyter Lab on http://localhost:${PORT}"
fi

# Detect OS
OS="$(uname -s)"

# Build engine args depending on OS + podman mode rules
[[ -e /sys/fs/selinux/enforce ]] && MOUNT_SUFFIX=":Z" || MOUNT_SUFFIX=""
ENGINE_ARGS=()
VOLUME_ARG=( -v "${NOTEBOOKS_DIR}:/workspace${MOUNT_SUFFIX}" )
PORT_ARG=( -p "${PORT}:8888" )

if [[ "${ENGINE}" == "docker" ]]; then
  # Docker is the same as podman rootful mode but requires specifying the home directory
  ENGINE_ARGS+=(  "--user" "$(id -u):$(id -g)" "--group-add" "2020" "-e" "HOME=/home/xsuiteuser/" )
elif [[ "${OS}" == "Darwin" ]]; then
  # macOS podman runs in a VM (rootful), use macOS-specific user/group setup
  ENGINE_ARGS+=( "--user" "$(id -u):$(id -g)" "--group-add" "2020" )
else
  # Linux + podman: choose rootless vs rootful
  ROOTLESS="$("${ENGINE}" info --format '{{.Host.Security.Rootless}}' 2>/dev/null || echo "false")"
  if [[ "${ROOTLESS}" == "true" ]]; then
    ENGINE_ARGS+=( "--userns=keep-id" "--user" "$(id -u):$(id -g)" "--group-add" "2020" )
  else
    ENGINE_ARGS+=( "--user" "$(id -u):$(id -g)" "--group-add" "2020")
  fi
fi

echo "Mounting notebooks: ${NOTEBOOKS_DIR} -> /workspace"

exec "${ENGINE}" run --rm -it \
  "${ENGINE_ARGS[@]}" \
  "${PORT_ARG[@]}" \
  "${VOLUME_ARG[@]}" \
  "${IMAGE}" \
  bash -lc "${JUPYTER_CMD}"