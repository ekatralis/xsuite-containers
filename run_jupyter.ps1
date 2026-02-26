param(
  [Parameter(Mandatory=$true)]
  [string]$NotebooksDir,

  [int]$Port = 8888,
  [string]$JUPYTER_TOKEN = 'xsuite',
  [string]$Engine = $null
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

# Respect the explicit $Engine parameter first, otherwise auto-detect
if (-not $Engine) {
    $Engine = Find-Engine
}

Write-Host "Using container engine: $Engine"
Write-Host "Pulling image: $Image"
& $Engine pull $Image

$JupyterCmd = "source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace"

if ($JUPYTER_TOKEN -ne 'auto') {
  $JupyterCmd += " --ServerApp.token='$JUPYTER_TOKEN'"
  Write-Host "Starting Jupyter Lab on http://localhost:$Port/lab?token=$JUPYTER_TOKEN"
} else {
  Write-Host "Starting Jupyter Lab on http://localhost:$Port"
}

Write-Host "Mounting notebooks: $NotebooksDir -> /workspace"

& $Engine run --rm -it `
  "-p" "$Port`:8888" `
  "-v" "$NotebooksDir`:/workspace" `
  $Image `
  "bash" "-lc" $JupyterCmd