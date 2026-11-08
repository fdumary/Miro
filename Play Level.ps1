param([ValidateRange(1, 5)][int]$Level = 1)
$ErrorActionPreference = 'Stop'
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64.exe'
$scene = if ($Level -eq 1) { 'res://scenes/intro.tscn' } else { 'res://scenes/levels/level_{0:00}.tscn' -f $Level }
& $engine --path $PSScriptRoot $scene -- --dev
