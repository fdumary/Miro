param([ValidatePattern('^[\w.-]+\.exe$')][string]$ExecutableName = 'Miro.exe')
$ErrorActionPreference = 'Stop'
$executable = Join-Path $PSScriptRoot "build/windows/$ExecutableName"
if (-not (Test-Path -LiteralPath $executable)) { throw 'Run Build Windows.ps1 first.' }
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'tmp') | Out-Null
foreach ($number in 1..5) {
    $log = Join-Path $PSScriptRoot "tmp/export-floor-$number.log"
    $process = Start-Process -FilePath $executable -ArgumentList @('--headless', '--quit-after', '60', '--log-file', $log, '--', "--level=$number") -WindowStyle Hidden -Wait -PassThru
    $output = Get-Content -LiteralPath $log
    if ($process.ExitCode -ne 0 -or ($output -match 'ERROR:|SCRIPT ERROR:') -or -not ($output -match "FLOOR_READY: $number")) {
        $output | Write-Output
        throw "Exported floor $number failed."
    }
    Write-Output "Exported floor $number startup passed."
}
