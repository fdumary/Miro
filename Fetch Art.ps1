# Downloads the public-domain paintings for the reactive gallery and records their rights.
# See tools/fetch_art.py and docs/INNER_CONFLICT.md. Open Godot afterwards so the images import.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
python tools/fetch_art.py @args
