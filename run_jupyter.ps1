param(
  [Parameter(Mandatory=$true)]
  [string]$NotebooksDir,

  [int]$Port = 8888
)

$ErrorActionPreference = "Stop"

$Image = "ghcr.io/ekatralis/xsuite-containers:latest"

function Find-Engine {
  if (Get-Command podman -ErrorAction SilentlyContinue) { return "podman" }
  if (Get-Command docker  -ErrorAction SilentlyContinue) { return "docker"  }
  throw "Neither 'podman' nor 'docker' found in PATH."
}

if (-not (Test-Path -LiteralPath $NotebooksDir -PathType Container)) {
  throw "Not a directory: $NotebooksDir"
}

$Engine = Find-Engine
Write-Host "Using container engine: $Engine"
Write-Host "Pulling image: $Image"
& $Engine pull $Image

# Windows podman runs a Linux VM (rootful), and your Windows command matches rootful behavior.
# Docker is also equivalent to rootful.
$GroupAdd = (& $Engine run --rm alpine:3.19 sh -lc "id -g" 2>$null)
if (-not $GroupAdd) {
  # Fallback: try without probing; many setups still have GNU id inside the VM/container
  $GroupAdd = "0"
}

$JupyterCmd = "source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace"

Write-Host "Starting Jupyter Lab on http://localhost:$Port"
Write-Host "Mounting notebooks: $NotebooksDir -> /workspace"

& $Engine run --rm -it `
  "--group-add=$GroupAdd" `
  "-p" "$Port`:8888" `
  "-v" "$NotebooksDir`:/workspace" `
  $Image `
  "bash" "-lc" $JupyterCmd