$ErrorActionPreference = 'Stop'
$project='C:\Users\ethan\Miro'
$out="$project\tmp\performance\regressions"
New-Item -ItemType Directory -Force $out | Out-Null
$engine='C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
Start-Transcript "$out\runner.log" -Force
$userdata = "$env:APPDATA\Godot\app_userdata\Miro"
$backup="$out\userdata-before"
New-Item -ItemType Directory -Force $backup | Out-Null
$before=@(Get-ChildItem $userdata -Filter '*.cfg' -File -ErrorAction SilentlyContinue)
$before | Copy-Item -Destination $backup
$results=[System.Collections.Generic.List[object]]::new()
try {
 $import=Start-Process $engine -ArgumentList @('--headless','--editor','--path',$project,'--import') -RedirectStandardOutput "$out\import.log" -RedirectStandardError "$out\import.err" -Wait -PassThru -WindowStyle Hidden
 if ($import.ExitCode -ne 0 -or ((Get-Content "$out\import.err") -match 'ERROR:|SCRIPT ERROR:')) { throw 'Import failed' }
 $ErrorActionPreference = 'Continue'
 & python "$project\tools\check_voice_coverage.py" *> "$out\voice.log"
 $ErrorActionPreference = 'Stop'
 $results.Add([pscustomobject]@{test='voice coverage';exit=$LASTEXITCODE;pass=($LASTEXITCODE -eq 0)})
 $ErrorActionPreference = 'Continue'
 Push-Location $project
 & "$project\tmp\audio-analysis-env\Scripts\python.exe" "$project\tools\test_beat_analysis.py" *> "$out\beat-analysis.log"
 $ErrorActionPreference = 'Stop'
 Pop-Location
 $results.Add([pscustomobject]@{test='beat analysis';exit=$LASTEXITCODE;pass=($LASTEXITCODE -eq 0)})
 $source=Get-Content "$project\Run Checks.ps1" -Raw
 $begin=$source.IndexOf('$checks = @(')
 $end=$source.IndexOf('New-Item -ItemType Directory', $begin)
 Invoke-Expression $source.Substring($begin,$end-$begin)
 $index=0
 foreach ($check in $checks) {
  $index++
  $arguments=@('--headless','--path',$project,'--fixed-fps','60','--script')+$check
  $ErrorActionPreference='Continue'
  & $engine @arguments > "$out\check-$index.log" 2> "$out\check-$index.err"
  $exitCode=$LASTEXITCODE
  $ErrorActionPreference='Stop'
  $ended=$true
  $text=(Get-Content "$out\check-$index.log","$out\check-$index.err" -ErrorAction SilentlyContinue) -join "`n"
  $ok=$ended -and $exitCode -eq 0 -and $text -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:'
  $results.Add([pscustomobject]@{test=($check -join ' ');exit=$exitCode;pass=$ok;timeout=(-not $ended);summary=(($text -split "`n" | Select-String 'RESULT|failures=') -join ' | ')})
  $results | ConvertTo-Json -Depth 5 | Set-Content "$out\results.json"
  Write-Output "CHECK $index $ok $($check -join ' ')"
 }
 $listed=($checks | ForEach-Object { $_[0] })
 $unlisted=@(Get-ChildItem "$project\tools\test_*.gd" | Where-Object { "res://tools/$($_.Name)" -notin $listed -and $_.BaseName -ne "test_pack_assets" })
 foreach ($test in $unlisted) {
  $name=$test.BaseName
  $ErrorActionPreference='Continue'
  & $engine --headless --path $project --fixed-fps 60 --script "res://tools/$($test.Name)" > "$out\$name.log" 2> "$out\$name.err"
  $exitCode=$LASTEXITCODE
  $ErrorActionPreference='Stop'
  $ended=$true
  $text=(Get-Content "$out\$name.log","$out\$name.err" -ErrorAction SilentlyContinue) -join "`n"
  $results.Add([pscustomobject]@{test=$name;exit=$exitCode;pass=($ended -and $exitCode -eq 0 -and $text -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:');timeout=(-not $ended)})
 }
 & powershell -NoProfile -ExecutionPolicy Bypass -File "$project\Check Exported Playthrough.ps1" *> "$out\exported-playthrough.log"
 $results.Add([pscustomobject]@{test='exported playthrough';exit=$LASTEXITCODE;pass=($LASTEXITCODE -eq 0)})
 $audit="$out\pack-root"
 New-Item -ItemType Directory -Force $audit | Out-Null
 $ErrorActionPreference='Continue'
 & $engine --headless --path $audit --main-pack "$project\build\qa\MiroQA.exe" --script "$project\tools\test_pack_assets.gd" > "$out\pack-assets.log" 2> "$out\pack-assets.err"
 $packExit=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 $results.Add([pscustomobject]@{test='packaged asset integrity and exclusions';exit=$packExit;pass=($packExit -eq 0)})

 & powershell -NoProfile -ExecutionPolicy Bypass -File "$project\Check Windows Build.ps1" *> "$out\retail-startup.log"
 $results.Add([pscustomobject]@{test='retail five-floor startup and icon';exit=$LASTEXITCODE;pass=($LASTEXITCODE -eq 0)})
 $ErrorActionPreference = 'Continue'
 & python "$project\tools\decode_audio.py" *> "$out\audio-decode.log"
 $ErrorActionPreference = 'Stop'
 $results.Add([pscustomobject]@{test='all runtime audio decode';exit=$LASTEXITCODE;pass=($LASTEXITCODE -eq 0)})
 $results | ConvertTo-Json -Depth 5 | Set-Content "$out\results.json"
 'DONE'  | Set-Content "$out\done.txt"
} finally {
 # Restore pre-test player config, including removing only newly created root .cfg files.
 Get-ChildItem $userdata -Filter '*.cfg' -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $before.Name } | Remove-Item
 Get-ChildItem $backup -File | Copy-Item -Destination $userdata -Force
 Stop-Transcript
}
