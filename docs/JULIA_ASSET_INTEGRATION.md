# Julia asset integration

Canonical repository: [xynprize/Miro.](https://github.com/xynprize/Miro.) — the repository name includes the trailing period. Asset source commit: `cb73f9d` (Keeper, crate, key and mushrooms). The local checkout was fast-forwarded from the older repository's `fcbc803` through all eight newer commits before integration; soundtrack, menu, voice and additional stealth work were preserved.

## Placement map

| Original asset | In-game use | Integration |
| --- | --- | --- |
| `assets/characters/standard_keeper_idle.png` | Standard Keepers across all five scenes where guards are present, including the sick cell guard; Keeper dialogue token | `scripts/intro_guard.gd` draws the 32×32 idle image. `scripts/dialogue_portrait.gd` uses it for the KEEPER speaker. |
| `assets/characters/standard_keeper_walk.png` | Moving standard Keepers | Two 32×32 frames, animated at eight frame steps per second; facing mirrors the artwork. Stationary/dialogue states use idle. |
| `assets/environment/key.png` | The cell Keeper's carried key and remaining unlooted key on his body | Replaces the drawn circle/line key marker; disappears when pickpocketed or looted. Existing key inventory and door rules remain authoritative. |
| `assets/environment/crate.png` | Existing intro crate decorations and matching later-floor set dressing | `scripts/prison_art.gd` and `scripts/scaffold_art.gd` use Julia's native 28×27 texture. |
| `assets/environment/shrooms.png` | Damp floor dressing on the three traversal tiers | Replaces intro moss-like placeholder clusters and adds matching later-floor decoration. No illness or pickup behavior is inferred from the art. |

Original PNG bytes and palette are unchanged. Nearest filtering comes from the existing project/scene settings. The shared `scripts/environment_props.gd` places decorations against the tile tops across their width, including raised steps, so tiles do not bury the sprites. These architectural props are decorative, as the previous drawn props were; no new crate collision or mushroom mechanic was added. Interactive suppressor cases and hiding recesses retain their distinct visuals and behavior.

Guard physics shapes, sight rules, patrols, damage, loot, conversations and stealth behavior are unchanged. Coughing uses a restrained transform/particle overlay on the supplied idle/walk art. Until dedicated death art arrives, a rotated idle sprite represents the body. The brother keeps his distinct placeholder because Julia supplied standard Keeper art, not brother/boss art. Attack wind-up and alert indicators remain visible overlays.

## Verification and build

- All 14 existing source test suites passed after the guard/prop integration, including detection, loot, timed stealth, music and world features.
- The exported QA playthrough passed 64/64 checks across the five chapters, boss and watched ending.
- Rendered screenshots were inspected for guard appearance/facing, the key, native prop scale and raised-tile alignment.
- The normal Windows build was rebuilt and all five direct-floor startup checks passed.
- Direct `--level=N` launching from the newly added menu initially produced nested scene-change errors through the intro. `scripts/main_menu.gd` now launches the requested chapter directly, matching its existing level buttons; all five standalone checks then passed.

Local release: `build/windows/Miro.exe` (ignored by Git). Rebuild with `Build Windows.ps1`; use `Check Windows Build.ps1` and `Check Exported Playthrough.ps1` for packaged verification. Runtime captures under `tmp/` are also ignored.

## November 10 submission correction

The equipped knife and shared HUD/inventory icon now use `assets/weapons/julia_knife.png`, lifted from Julia's original `miro_attack.png` sheet at `(14, 8, 12, 12)`. Its 50 opaque pixels retain the original metal/edge colors; the surrounding character pixels are transparent. The original sheet is unchanged (SHA256 `5c03c4e1e02472eba630d7025e5c92845124fb9086dbee5e0edd20ec60ec46ae`). Both the held knife and the HUD use the shared `WeaponArt.TEXTURES.shank` entry.

The supplied Miro, Keeper and Kael idle/walk/attack/jump art, heart, key, crates, mushrooms, torches, standard/cracked/connector tiles, spikes, turret parts/projectile and watcher animation are already connected to their gameplay scenes. Tile references are in `assets/environment/prison_tiles.tres`. No standalone Julia replacements for the pistol, SMG, blanket, C4 or MP3 icons are present in the supplied assets; those existing review icons remain in use. No Julia art was redrawn or regenerated.

`tools/test_julia_assets_cursor.gd` checks the shared knife texture, source pixel colors/hash and Julia tile mappings. Its native Windows run also checks pointer visibility during dialogue in windowed and fullscreen modes, and restores the pointer for inventory, terminals, settings and pause. Headless runs verify assets only because Godot reports its dummy window as minimized.
