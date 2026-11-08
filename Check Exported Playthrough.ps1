$ErrorActionPreference = 'Stop'
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
$directory = Join-Path $PSScriptRoot 'build/qa'
$log = Join-Path $PSScriptRoot 'tmp/qa-playthrough.log'
New-Item -ItemType Directory -Force $directory | Out-Null
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'tmp') | Out-Null
$executable = Join-Path $directory 'MiroQA.exe'
& $engine --headless --path $PSScriptRoot --export-debug 'Windows QA' $executable
if ($LASTEXITCODE -ne 0) { throw 'QA export failed.' }
$process = Start-Process -FilePath $executable -ArgumentList @('--headless', '--fixed-fps', '60', '--quit-after', '50000', '--log-file', $log, '--', '--verify-playthrough') -WindowStyle Hidden -Wait -PassThru
$output = Get-Content -LiteralPath $log
if ($process.ExitCode -ne 0 -or ($output -match 'ERROR:|SCRIPT ERROR:') -or -not ($output | Where-Object { $_ -match 'EXPORTED_PLAYTHROUGH_RESULT: (\d+)/(\d+) passed' -and $Matches[1] -eq $Matches[2] })) {
    $output | Write-Output
    throw 'Exported playthrough failed.'
}
$output | Select-String 'EXPORTED_PLAYTHROUGH_RESULT'
