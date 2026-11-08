# Miro: Last Man Standing — Claude handoff, November 7, 2026

Miro is feature complete enough to enter **player-first playtesting, debugging, and release polish**. Start with a normal player run. Use dev mode to reproduce and isolate problems, then verify the fix in player mode. Treat the old feature proposals in earlier revisions of this file as historical context, not a backlog to implement wholesale.

Work from the official `xynprize/Miro.` repository, branch `codex/keeper-voices`. PRs #1–#3 are merged; there were no open PRs at handoff. The playtest branch contains work beyond `main`; do not assume a build from `main` has the current hazards, voices, or controller support. Check the working tree before editing. Ethan’s original Mac checkout has unrelated local changes; use a separate checkout or the existing `Miro-julia-assets` worktree.

## Launch the right build

- **Player, default:** Run `./Play Miro.ps1` on Windows, or open the ordinary Windows release export. From Godot/editor CLI use `Godot --path . -- --player`. Start at the title and choose Play; do not launch a floor scene or pass a dev shortcut. Player mode honors saved floor and MP3 unlocks. Use a clean test profile for first-run checks; preserve Ethan’s real save.
- **Dev:** Run `./Play Miro.ps1 -Dev` or `Godot --path . -- --dev`. For a single floor, use `./Play Level.ps1 -Level 4` or `Godot --path . -- --dev --level=4`. Editor and QA runs default to dev unless explicitly given `--player`. Dev can open all floors and does not write player progression. Shared volume and controller settings can still persist.
- Use Godot 4.7.2. Windows launchers currently point at `C:\towerdefense\tools\godot`. Build the player export with `Build Windows.ps1`; use the separate Windows QA preset for automation. The two build paths use the same game scenes.

## What is in the playtest branch

- Five playable floors, mandatory Level 3 checkpoint, MISSING/HUNTED reactions, play-style artwork and lore, opening and ending cinematics, and unlockable music. Keep the immunity and engineered-sickness reveal for Level 5. Niro is defeated, not killed.
- Julia’s hearts, torch, moss watcher, turret and spike sprites. Levels 2–5 have 13 turrets and 18 lethal spike traps, including wall and ceiling mounts. First watcher alert calls two named reserves on that floor. Turrets take any three bullets/stabs; guitar stuns them for five seconds. Retrying resets the floor.
- 59 named Keepers with individual writing and ElevenLabs voices, including watcher reserves. Niro remains on preview 1. Voice assets ship offline; do not regenerate or commit credentials during routine QA.
- Records terminals on every floor. E reads lore; T opens local security without the MP3. The unlocked MP3 runs the same security commands in terminal range. `cameras off` and `turrets off` are separate. C4 is its own item; placement and detonation do not require the MP3.
- Timed wall jumps and slides, 3-second air-jump recharge, and a compact remote-shaped C4 confirmation. PlayStation binds and Settings → Controller are in both menus. The controller speaker route is Windows-only and applies to Niro’s remote lines, not his in-room dialogue. A Bluetooth bridge needs a Windows playback endpoint; native Bluetooth without one falls back to ordinary audio.

## Gaps and release priorities

1. **Final objective and ending state:** Level 5 tells Miro to place the final sigil, but Forest Viewpoint only requires Defeat Exchange. Check the intended result if Miro defeats Niro without placing the sigil; the current code can start the ending without recording it. Also review the explosion cinematic’s close-up: it still depicts the Keeper MP3 sending the detonation signal even though C4 and MP3 are separate in gameplay. Verify victory, the blast, beach, credits, and completed title screen as one player run.
2. **Level select is not a full checkpoint:** The game persists which levels and tracks are unlocked, not a complete inventory and story snapshot. Reopening an unlocked later floor after relaunch does not restore the MP3 or earlier branch history from the prior run. Verify the floor remains completable with its starting supplies and local terminal. Decide whether to communicate a fresh floor start or restore more state.
3. **Controller-only progression:** Verify a fresh controller run, especially the required Level 3 password. The console currently accepts keyboard text. Check whether a controller-only text-entry or equivalent puzzle path is needed for release. Test Cross’s jump/interact priority around ladders, loot, notes, spikes and wall moves. Use real Windows hardware to verify speaker output, fallback on unplug and bridge-based Bluetooth separately.
4. **Level balance and objective clarity:** Automated routes demonstrate reachability, but use fixtures, combat assistance and extra health on later floors. They do not prove the new hazards are fair at normal health or that a clean stealth route works on each floor. Play every floor in order at Medium, then sample Easy and Hard, MISSING and HUNTED. Look for prompts that obscure the next objective, unsafe landings or retries, mandatory hacking that can be blocked, and C4 expenditure that could strand a player.
5. **Presentation and credits:** Niro still uses provisional art based on Miro’s sprite. Confirm Julia’s and Fran’s credit names, soundtrack labels, and attribution; remove `(confirm surname)` placeholders from `data/credits.json` before release. Verify audio levels and subtitle readability in the actual export.

## Verification at handoff

- The 28 Godot scripts in `Run Checks.ps1` pass on macOS with Godot 4.7.2.
- The five-floor bot reported 38/38 in both `--player` and `--dev`. The prior 34/38 was a QA timing issue: it waited 850 frames for a 15-second ending. It now waits for completion with a bounded timeout. The bot is not a substitute for a fresh human playthrough.
- The controller audio worker has been exercised with a separate desktop audio endpoint and from an exported pack. Physical Windows controller speaker playback and the standalone Windows build remain manual release checks.

For bugs, record commit, mode, floor, difficulty, input device, reproduction steps, expected/actual result and a screenshot or log if useful. Fix reproducible blockers first. Do not add new mechanics to compensate for unclear prompts until the existing interaction has been tested.
