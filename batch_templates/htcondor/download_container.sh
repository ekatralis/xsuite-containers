ENGINE="${ENGINE:-}"

usage() {
  echo "Usage: $0 link.to.container/image:tag (optional, default 'ghcr.io/ekatralis/xsuite-slim:latest') exported_image_name (optional, default 'xsuite-slim.tar')"
  echo "Env: ENGINE=docker|podman (optional, auto-detected), JUPYTER_TOKEN=auto|<token> (optional, default 'xsuite')"
}

# Print usage if -h or --help flag is provided
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

IMAGE="${1:-"ghcr.io/ekatralis/xsuite-slim:latest"}"
EXPORTED_IMAGE_NAME="${2:-"xsuite-slim.tar"}"

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
echo "Saving image to ${EXPORTED_IMAGE_NAME}"
"${ENGINE}" save -o "${EXPORTED_IMAGE_NAME}" "${IMAGE}"