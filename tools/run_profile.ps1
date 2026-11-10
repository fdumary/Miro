param([switch]$Smoke, [switch]$WorkerOnly, [int]$TargetFps=60, [string]$SelectedFloors="", [switch]$After)
$ErrorActionPreference = 'Stop'
$project = 'C:\Users\ethan\Miro'
$out = "$project\tmp\performance"
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64.exe'
Start-Transcript -Path "$out\$(if($After){'after-'+$TargetFps+'-runner'}elseif($TargetFps -ne 60){'fps'+$TargetFps+'-runner'}elseif($WorkerOnly){'worker-runner'}else{'runner'}).log" -Force
Get-CimInstance Win32_Processor | Select-Object Name | ConvertTo-Json | Set-Content "$out\cpu.json"
Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,TotalVisibleMemorySize,FreePhysicalMemory | ConvertTo-Json | Set-Content "$out\os.json"
Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,AdapterRAM | ConvertTo-Json | Set-Content "$out\gpu.json"
Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'Miro|Godot' } | Select-Object Name,ProcessId,ParentProcessId,SessionId,CommandLine | ConvertTo-Json | Set-Content "$out\existing-processes.json"
$modes = @('off','on')
$floors = 1..5
if ($WorkerOnly) { $modes = @('worker') }
if ($SelectedFloors) { $floors = @($SelectedFloors.Split(',') | ForEach-Object { [int]$_ }) }
if ($TargetFps -ne 60) { $modes = @('off') }
if ($Smoke) { $modes = @('on'); $floors = @(1) }
foreach ($floor in $floors) {
 foreach ($mode in $modes) {
  $stem = "$out\floor_${floor}_${mode}"
  if ($TargetFps -ne 60) { $stem += "_fps$TargetFps" }
  if ($After) { $stem += "_after" }
  $arguments = @('--path',$project,'--resolution','1280x720','--position','40,40','--max-fps',"$TargetFps",'--log-file',"${stem}.log",'--script','res://tools/profile_runtime.gd','--','--dev',"--perf-floor=$floor", "--perf-expected-fps=$TargetFps")
  if ($mode -in @('on','worker')) { $arguments += '--perf-speaker' }
  if ($mode -eq 'worker') { $arguments += '"--perf-endpoint=L2251x Wide (NVIDIA High Definition Audio)"' }
  if ($Smoke) { $arguments += '--perf-smoke' }
  if ($TargetFps -ne 60) { $arguments = @('--disable-vsync') + $arguments }
  $tag = $(if($TargetFps -ne 60){'fps'+$TargetFps}else{''})
  if ($After) { $tag += $(if($tag){'_after'}else{'after'}) }
  if ($tag) { $arguments += "--perf-tag=$tag" }
  Write-Output "Starting floor=$floor speaker=$mode"
  $proc = Start-Process $engine -ArgumentList $arguments -PassThru
  $samples = [System.Collections.Generic.List[object]]::new()
  $timer = [Diagnostics.Stopwatch]::StartNew()
  while (-not $proc.HasExited) {
   if ($timer.Elapsed.TotalSeconds -gt 150) { Stop-Process -Id $proc.Id -Force; throw "Timeout floor $floor $mode" }
   $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
   $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($proc.Id)" -ErrorAction SilentlyContinue)
   $ids = @($proc.Id) + @($children | Select-Object -ExpandProperty ProcessId)
   $gpuCounters = Get-Counter '\GPU Process Memory(*)\Dedicated Usage','\GPU Process Memory(*)\Shared Usage' -ErrorAction SilentlyContinue
   foreach ($processId in $ids) {
    $p = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $p) { continue }
    $dedicated = 0; $shared = 0; $found = $false
    foreach ($c in $gpuCounters.CounterSamples) {
     if ($c.InstanceName -match "^pid_${processId}_") {
      $found = $true
      if ($c.Path -like '*\dedicated usage') { $dedicated += $c.CookedValue }
      if ($c.Path -like '*\shared usage') { $shared += $c.CookedValue }
     }
    }
    $samples.Add([pscustomobject]@{unix_ms=$stamp;elapsed_ms=$timer.Elapsed.TotalMilliseconds;pid=$processId;role=$(if($processId -eq $proc.Id){'main'}else{'worker'});working_set_bytes=$p.WorkingSet64;private_bytes=$p.PrivateMemorySize64;cpu_seconds=$p.CPU;dedicated_gpu_bytes=$dedicated;shared_gpu_bytes=$shared;gpu_counter_available=$found})
   }
   Start-Sleep -Milliseconds 500
   $proc.Refresh()
  }
  $samples | Export-Csv "${stem}_os.csv" -NoTypeInformation
  if ($proc.ExitCode -ne 0) { throw "Failed floor $floor $mode exit $($proc.ExitCode)" }
  Write-Output "Finished floor=$floor speaker=$mode samples=$($samples.Count)"
 }
}
'DONE' | Set-Content "$out\$(if($Smoke){'smoke'}elseif($After){'after-'+$TargetFps}elseif($TargetFps -ne 60){'fps'+$TargetFps}elseif($WorkerOnly){'worker'}else{'all'})-done.txt"
Stop-Transcript
