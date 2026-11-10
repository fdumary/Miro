param([ValidatePattern('^[\w.-]+\.exe$')][string]$ExecutableName = 'Miro.exe')
$ErrorActionPreference = 'Stop'
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
$outputDirectory = Join-Path $PSScriptRoot 'build/windows'
New-Item -ItemType Directory -Force $outputDirectory | Out-Null
& $engine --headless --editor --path $PSScriptRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Resource import failed.' }
& $engine --headless --path $PSScriptRoot --script res://tools/build_art_thumbnails.gd
if ($LASTEXITCODE -ne 0) { throw 'Artwork thumbnail build failed.' }
& $engine --headless --path $PSScriptRoot --export-release 'Windows Desktop' (Join-Path $outputDirectory $ExecutableName)
if ($LASTEXITCODE -ne 0) { throw 'Godot Windows export failed.' }
Write-Output "Windows build: $outputDirectory\$ExecutableName"

$archive = Join-Path $PSScriptRoot 'build/Miro-Playtest-Windows.zip'
Compress-Archive -LiteralPath (Join-Path $outputDirectory $ExecutableName) -DestinationPath $archive -Force
Write-Output "Windows ZIP: $archive"
Get-FileHash -LiteralPath (Join-Path $outputDirectory $ExecutableName), $archive -Algorithm SHA256 | Format-Table -AutoSize