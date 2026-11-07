# Coding-agent prompt for Fran

Copy the following into your coding agent and append Fran's completed report or selected issue IDs.

---

You are working on `https://github.com/xynprize/Miro.` (the repository name includes the trailing period). Help Fran playtest and fix the Godot game. Start by inspecting the checkout, Git status and current commit; preserve other people's edits. Read any applicable AGENTS.md, then `docs/FRAN_PLAYTEST_HANDOFF.md`, `docs/GAMEPLAY_DECISIONS.md`, `docs/INTRO.md`, both level source maps, `docs/class.md`, `docs/mirospec.md`, both meeting docs and `docs/miroguide.pdf`. Read Fran's attached findings before changing gameplay.

Your deliverables are reproducible fixes for the assigned issues, updated test coverage where useful, a concise implementation/status update, and a rebuilt verified release when the task requires one. Use `docs/PLAYTEST_REPORT_TEMPLATE.md` to record manual results. Do not mark something manually tested based only on automated output.

Prioritize soft locks, crashes, scene transitions, collision, required objectives, input/pause/retry and exported-build failures before polish. Reproduce each assigned issue, identify the relevant code, make the smallest coherent fix, and verify both the failure case and neighboring gameplay paths. Reference the source requirement or explicit user decision for behavior changes.

Important constraints:

1. The blanket is Miro's stealth tool for hiding, including in shadows. The implemented revision allows activation anywhere for 5 seconds, an 8-second cooldown after ending, and 55% movement speed. Movement/jump/climb preserve concealment; live guard contact breaks it and alerts that guard. Attacks, gunfire, dodge, damage and manual cancellation also reveal. The latest handoff request mentions shadows again but does not explicitly revoke anywhere activation. Surface this ambiguity to Fran/Ethan if changing the rule; do not silently revert to the historical stationary-shadow implementation.
2. No in-game level-selection menu exists. Pause/resume, restart and Enter descent do exist. Direct-floor scripts/arguments are development tools. If assigned the menu deliverable, distinguish campaign progression from a debug level picker; do not fabricate completed sigils or allow ordinary progression to bypass required objectives.
3. Preserve Julia's original textures, Oil 6 palette and Forward+ baseline. Current room, NPC, boss and cinematic visuals are provisional. Do not introduce generated artwork or replace supplied assets without a request.
4. Keep five required sigils, all three intro escape routes, the earlier brother reveal, two readable boss attacks/recovery windows, fatal exchange and morally unresolved ending. Do not invent final answers to unresolved narrative questions.
5. Keep pause/skip/retry deterministic. Watching and skipping must apply identical progression flags. Repeated interactions must not duplicate loot, consume another sigil charge, spawn another boss or retrigger the ending. Preserve guard sight occlusion and remembered-location searches; bodies do not grant magical player tracking.
6. Later-floor layout and milestones are authored in `data/levels/level_0N.json` and generated into scenes by the tools scripts. Regeneration overwrites scene edits. Choose the blueprint workflow or preserve manual changes before rebuilding; keep source references and implementation-status notes current.
7. Campaign state is in memory; inventory/casualty carryover and disk campaign saves are not implemented. Do not claim they exist. Only audio mute is persisted currently.

Repository map:

- `scripts/intro_player.gd`: movement, stealth, combat, inventory, contact reveal.
- `scripts/intro_guard.gd`: sight, patrol/search/alert, bodies and standard combat.
- `scripts/intro_level.gd`: intro routes, shared interaction/HUD/dialogue/pause code.
- `scripts/scaffold_level.gd`: later-floor milestones, terminal timer, camera/boss/cinematic orchestration.
- `scripts/security_camera.gd`, `progress_gate.gd`, `brother_boss.gd`, `ending_cinematic.gd`: reusable systems.
- `scripts/campaign.gd`: session progress and direct-floor launch; `sound_fx.gd`: effects/mute.
- `scenes/`, `data/levels/`, `assets/`: saved scenes, editable blueprints and assets.
- `tools/test_*.gd`: focused tests; `tools/export_playthrough.gd`: QA-only continuous exported run.

Verification:

- Use Godot 4.7.2. PowerShell wrappers hardcode Ethan's installation path; adapt the local executable path on Fran's machine without committing an accidental machine-specific rewrite.
- Run relevant tests while iterating. Run `Run Checks.ps1` for cross-cutting mechanics changes.
- Run `Build Windows.ps1` and `Check Windows Build.ps1` for release packaging/startup changes.
- Run `Check Exported Playthrough.ps1` for campaign/progression or packaging changes. It builds a separate QA export and currently verifies 64 checks through all floors, the boss and the watched ending. Do not weaken assertions to hide regressions.
- Headless tests load audio but do not validate audible mix or subjective control feel. Perform and report visual/manual validation when needed.
- Inspect logs for script/engine errors, not only process exit codes. Keep generated builds/logs out of Git. The final executable is `build/windows/Miro.exe` and must be rebuilt after gameplay edits.

Finish with: issue IDs fixed, behavior before/after, changed files and source rationale, automated/manual verification, remaining gaps, and the exact build/commit tested. Leave original reference documents intact; record superseding decisions in current implementation docs. Commit/push only within Fran's or Ethan's instructions for that coding task.

---
