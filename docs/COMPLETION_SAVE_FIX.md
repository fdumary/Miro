# Ending completion persistence

Level 5 previously saved the completed-game flag only when played_from_start was true. The level-select checkmark depends on that flag, so a completed resumed or selected finale could appear unfinished after relaunch.

Campaign.complete_floor now records completion whenever Level 5 reaches ForestViewpoint. Boss defeat alone is insufficient. Existing can_persist rules continue to prevent editor/dev/QA runs from writing player saves. The internal project name and save directory remain Miro. A progress_path method allows isolated persistence regression checks without touching a player save.

Run tools/test_completion_persistence.gd with -- --player. It checks boss-only state, resumed ending, a fresh campaign instance, the Level 5 checkmark, and preserved level unlocks using an isolated temporary config. The source check runner includes it.

For Ethan's previously completed playtest, progress.cfg was backed up before restoring the missing game/completed flag. No snapshots, unlocks or settings were removed.
