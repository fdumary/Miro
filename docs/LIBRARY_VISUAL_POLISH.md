# Library visual polish

This pass adds scenery and interface art from the local Kenney Game Assets All-in-1 3.8.0 archive while retaining Julia's characters, tiles, connectors, crates, key and mushrooms. All 11 original Julia PNGs were checked against their pre-change SHA-256 hashes and remain unchanged.

## Delivered

- Prison dressing: chains, barred windows and torches.
- Industrial chapters: pipes, vents, control panels, warning markings and beacons. The ward also has cabinets, records, a microscope and flasks.
- Interactables: terminal and release-lever icons, barred exits, textured security gates, suppressor briefcases and hiding recesses.
- Interface: textured menu/dialogue panels, pixel input hints and a compact stealth duration/cooldown bar. Guard alert, search and audible-conversation markers use emote sprites.
- Effects: landing dust, hit sparks, C4 smoke, fading blood and ending foreground foliage.

These are visual changes. Level geometry, collision, objectives, sigils, detection rules, stealth timing, combat and progression remain governed by the existing game code. No turret, drone, robot, walkie-talkie or scythe mechanic was added. Some imported prompt/emote variants are available for later use rather than displayed everywhere.

## Implementation and sources

`tools/import_kenney_polish.py` copies 41 original PNGs from the archive into `assets/library`. `assets/library/sources.json` records each archive path and SHA-256; accompanying license files retain the CC0 notices. Sources include Pixel Platformer Industrial Expansion, Tiny Dungeon, Generic Items, Input Prompts Pixel, Pixel Adventure UI, Emote Pack, Particle Pack, Smoke Particles, Splat Pack and Foliage Sprites.

`scripts/visual_assets.gd` retains shared texture resources and supplies UI styles. `scripts/level_dressing.gd` attaches through `environment_props.gd`; its palette shader applies only to the new background dressing. Julia's textures are not processed by that shader. Existing area, gate, guard, prop and art scripts draw the appropriate library sprites without changing their collision shapes.

`scripts/visual_effects.gd` limits particles to 128 and uses a separate random generator. Effects respect gameplay control locks and do not generate AI noise. `scripts/stealth_meter.gd` draws the small HUD meter. The Windows export includes source attribution and license notices.

To repeat the import from the project folder:

```powershell
python tools/import_kenney_polish.py 'C:\towerdefense\kenney_game_assets\Kenney Game Assets All-in-1 3.8.0.zip'
```

## Verification

- All 14 existing source check suites passed.
- Continuous exported five-floor playthrough: 64/64 checks passed.
- Standard Windows export rebuilt; all five standalone floor startup checks passed.
- All 41 imported PNG hashes matched their source manifest; all 11 Julia originals matched the pre-change snapshot.
- Rendered menu, dialogue, C4 breach, checkpoint and ward captures reviewed with `tools/capture_library_polish.gd`. Captures are local QA output under `tmp/polish`.

For manual review, walk through each chapter, trigger guard suspicion and conversation, use C4, take a hit, open dialogue and return to the menu. Check readability, layer order and effects during pause/resume. The new visuals do not replace a full human playtest of the existing mechanics; Fran's broader checklist remains in `FRAN_PLAYTEST_HANDOFF.md`.
