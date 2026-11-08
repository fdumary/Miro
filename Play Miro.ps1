param([switch]$Dev)
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64.exe'
$mode = if ($Dev) { '--dev' } else { '--player' }
& $engine --path $PSScriptRoot -- $mode
