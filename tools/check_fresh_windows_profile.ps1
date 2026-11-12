param([Parameter(Mandatory=$true)][string]$Executable)
$ErrorActionPreference = 'Stop'
$originalAppData = $env:APPDATA
$profile = Join-Path $PSScriptRoot ('../tmp/fresh-retail-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $profile | Out-Null
try {
    $env:APPDATA = (Resolve-Path $profile).Path
    $process = Start-Process -FilePath (Resolve-Path $Executable).Path -ArgumentList @('--headless', '--quit-after', '120', '--log-file', (Join-Path $env:APPDATA 'startup.log')) -WindowStyle Hidden -Wait -PassThru
    $log = Get-Content (Join-Path $env:APPDATA 'startup.log') -Raw
    if ($process.ExitCode -ne 0 -or $log -match 'ERROR:|SCRIPT ERROR:') { throw 'Fresh retail startup failed.' }
    $progress = Join-Path $env:APPDATA 'Godot/app_userdata/Miro/progress.cfg'
    if (Test-Path -LiteralPath $progress) { throw 'The title screen wrote progress before the new player entered a floor.' }
    Write-Output 'FRESH_WINDOWS_PROFILE_RESULT: title screen has zero achievements and no inherited progress.'
} finally {
    $env:APPDATA = $originalAppData
}
