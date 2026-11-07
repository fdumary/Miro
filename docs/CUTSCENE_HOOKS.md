# Cutscene and art hooks (for Sunday, 8 Nov)

Everything below already works with placeholder art. Drop a file at the listed path and the game uses it on the next run; no code changes are needed. Where a hook is a signal, connect it from a cutscene scene or script.

## Art drop-in paths

| Asset | Path | Used by |
|---|---|---|
| Niro portrait (dialogue) | `assets/characters/niro_portrait.png` | `scripts/dialogue_portrait.gd` |
| Guitar icon (hotbar slot 6) | `assets/weapons/guitar.png` | `scripts/weapon_inventory.gd` |
| Remote / detonator screen | `assets/ui/remote_screen.png` (portrait; screen in the middle ~70%) | `scripts/remote_screen.gd` (pop-up on every detonation, full screen in the ending) |
| MISSING poster | `assets/environment/poster_missing.png` (28x36 or larger, same ratio) | `scripts/wanted_poster.gd` |
| WANTED poster | `assets/environment/poster_wanted.png` | `scripts/wanted_poster.gd` |
| Voiced Miro thoughts | `assets/audio/voice/thought_<floor>_<id>.mp3` (ids in `data/inner_dialogue.json`) | Thought bus, long reverb |

Niro's in-game body, kneel pose and retreat fade are drawn in `scripts/brother_boss.gd` `_draw()` (marked "Hook").

## Level 5 signals (`scripts/foundation_flow.gd`, node `FoundationFlow` in level_05)

| Signal | When | Planned cutscene |
|---|---|---|
| `guitar_taken` | Guitar pickup finished; Shit Crashed starts | C5 guitar discovery (alarm light) |
| `wave_started(row)` / `wave_cleared(row)` | Each wave enters (on a bar line) / is cleared | — |
| `niro_appeared(engagement)` | Niro arrives (1 = reveal, 4 = final fight) | C2 first appearance and reveal |
| `niro_retreated(engagement)` | Niro escapes through hatch 1–3 | C2b retreat x3 |
| `final_fight_started` | Miro lands on the deepest floor | — |

The defeat exchange (C3) runs when `brother_defeated()` fires in `scripts/scaffold_level.gd`.

## Cutscenes (in-engine, drawn; replace any shot with your panels)

All cutscenes share one look from `scripts/cinema.gd`: 2.35:1 letterbox bars, vignette, fixed film grain, letter-spaced titles, eased camera moves, and silhouettes rim-lit by the moon. To swap in art, draw your panel inside the matching `shot_*` function. Keep `elapsed`, skip and pause.

| Cutscene | Script | When | Shots |
|---|---|---|---|
| Opening (C1) | `scripts/opening_cinematic.gd`, `scenes/opening_cinematic.tscn` | New run from the menu, before Level 1 (17 s; Tab/Enter/E/Space skips) | Storm over the woods with lightning on the far tower, then a tilt up the tower with the PA line, then a push into the cell 07 window where a figure sits up, then the MIRO / LAST MAN STANDING title |
| Floor cards | `scripts/floor_card.gd` (`level.show_card`) | First 3.4 s of every floor | Letterbox, the camera settles in from a closer zoom, then a lower-third with the emblem, floor number, title and the branch report. Doesn't block input or dialogue. |
| Alarm (C5) | same, mode `alarm` | Level 5 guitar pickup | Red alarm pulse and ALARM |
| Niro name card (C2) | same, mode `name` | Niro's first appearance | NIRO in the lower third while the reveal plays |
| Ending (C10) | `scripts/ending_cinematic.gd` | Forest viewpoint (14 s) | 0–1.2 s Miro steps out of the tree line (parallax dolly); 1.2–2.6 s the remote fills the screen, SIGNAL SENT, white flash; 2.5–5 s wide shot, slow push-in, sigils ignite bottom to top; 5–7.5 s the branch PA line while windows flicker; 7.5–11 s collapse with dust and camera shake, Set Me Free starts; 11 s Miro, in the foreground, lowers his head over the last thought; 12–14 s LAST MAN STANDING, fade |

Stills for review are written by `tools/capture_cinematics.gd` (run under xvfb).

## Branch text

All MISSING/HUNTED lines (PA, remote calls, guard lines, boss pre-fight line, ending PA and last thought) live in `data/branch_reactions.json`. Between-floor stings (C6–C9) can read `Campaign.reputation()`.
