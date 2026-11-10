$ErrorActionPreference = 'Stop'
$engine = 'C:\towerdefense\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
$checks = @(
    @('res://tools/test_menu_privacy_and_credits.gd'),
    @('res://tools/test_guard_floor_contacts.gd'),
    @('res://tools/test_scene_retry_soak.gd'),
    @('res://tools/test_music_prefetch_shutdown.gd'),
    @('res://tools/test_music_prefetch.gd'),
    @('res://tools/test_prompt_cache.gd'),
    @('res://tools/test_controller_prompts_and_aim.gd'),
    @('res://tools/test_completion_persistence.gd', '--', '--player'),
    @('res://tools/test_intro.gd'),
    @('res://tools/test_intro.gd', '--', '--c4'),
    @('res://tools/test_stealth_route.gd'),
    @('res://tools/test_intro_controls.gd'),
    @('res://tools/test_scaffold.gd'),
    @('res://tools/test_remaining_levels.gd', '--', '2'),
    @('res://tools/test_remaining_levels.gd', '--', '3'),
    @('res://tools/test_remaining_levels.gd', '--', '4'),
    @('res://tools/test_security.gd'),
    @('res://tools/test_tower_hazards.gd'),
    @('res://tools/test_keeper_cast.gd'),
    @('res://tools/test_brother.gd'),
    @('res://tools/test_ending.gd'),
    @('res://tools/test_gates_and_loot.gd'),
    @('res://tools/test_timed_stealth.gd'),
    @('res://tools/test_dialogue_layout.gd'),
    @('res://tools/test_audio.gd'),
    @('res://tools/test_music_and_world.gd'),
    @('res://tools/test_final_controls.gd'),
    @('res://tools/test_playstation_controls.gd'),
    @('res://tools/test_remote.gd'),
    @('res://tools/test_traversal_access.gd'),
    @('res://tools/test_weapon_inventory.gd'),
    @('res://tools/test_mouse_projectiles.gd'),
    @('res://tools/test_narrative_bubbles.gd'),
    @('res://tools/test_branches.gd'),
    @('res://tools/test_menus_and_progress.gd', '--', '--player'),
    @('res://tools/test_inner_conflict.gd'),
    @('res://tools/test_release_gaps.gd'),
    @('res://tools/test_hunt_waves.gd'),
    @('res://tools/test_final_gaps.gd'),
    @('res://tools/test_easter_eggs.gd'),
    @('res://tools/test_terminal_focus.gd'),
    @('res://tools/test_prelaunch_regressions.gd', '--', '--player'),
    @('res://tools/test_launch_checklist.gd', '--', '--player'),
    @('res://tools/test_saves_and_loot.gd', '--', '--player'),
    @('res://tools/test_combat_zones.gd', '--', '--player'),
    @('res://tools/test_quiet_walk_and_voice.gd', '--', '--player'),
    @('res://tools/test_supplies_and_closing.gd', '--', '--player'),
    @('res://tools/test_rebinding.gd', '--', '--player'),
    @('res://tools/test_strangle_reactions.gd', '--', '--player'),
    @('res://tools/test_display_settings.gd'),
    @('res://tools/test_performance_regressions.gd'),
    @('res://tools/test_spatial_audio.gd'),
    @('res://tools/test_art_thumbnails.gd'),
    @('res://tools/test_trapdoor_reward.gd'),
    @('res://tools/test_display_startup.gd', '--max-fps', '60')
)
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'tmp') | Out-Null
& $engine --headless --editor --path $PSScriptRoot --import *> (Join-Path $PSScriptRoot 'tmp/check-import.log')
if ($LASTEXITCODE -ne 0) { throw 'Godot resource import failed before checks.' }
& python (Join-Path $PSScriptRoot 'tools/check_voice_coverage.py') *> (Join-Path $PSScriptRoot 'tmp/check-voice-coverage.log')
if ($LASTEXITCODE -ne 0) { Get-Content (Join-Path $PSScriptRoot 'tmp/check-voice-coverage.log'); throw 'Voice library has missing or outdated clips.' }
$index = 0
foreach ($check in $checks) {
    $index += 1
    $arguments = @('--headless', '--path', $PSScriptRoot, '--fixed-fps', '60', '--script') + $check
    $ErrorActionPreference = 'Continue'
    $result = & $engine @arguments 2>&1
    $ErrorActionPreference = 'Stop'
    $exitCode = $LASTEXITCODE
    $result | Set-Content (Join-Path $PSScriptRoot "tmp/check-$index.log")
    if ($exitCode -ne 0 -or ($result -match 'SCRIPT ERROR:|ERROR:|FAIL:')) {
        $result | Write-Output
        throw "Level check $index failed."
    }
    $result | Select-String 'RESULT|failures='
}
Write-Output 'All level checks passed; no engine/script errors.'
