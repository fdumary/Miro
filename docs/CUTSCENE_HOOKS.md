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
| Opening (C1) | `scripts/opening_cinematic.gd`, `scenes/opening_cinematic.tscn` | New run from the menu, before Level 1 (15 s; Tab/Enter/E/Space/Esc skips) | 0–4.5 s storm over the woods: rolling clouds, two-depth rain with splashes, a forked bolt strikes the far tower, thunder follows each flash; 4.5–8.5 s tilt up the tower through the rain, a flash rakes the stone, PA line; 8.5–12 s push into the cell 07 window, bar shadows on the flash, the figure sits up on the thunder; 12–15 s gothic MIRO / Last Man Standing lit by a last flash. YZ33 starts at 12.4 s; the rain bed carries into Level 1 and fades over 6 s. |
| MP3 pickup | `scripts/remote_pickup_card.gd` (from `player_controls.collect_remote()`) | When Miro takes the MP3 player/remote off the first guard (searching or pickpocketing) | 2.8 s close-up on the right edge: the player slides up in Miro's hand, its screen wakes to PLAY. Doesn't pause play. |
| Floor cards | `scripts/floor_card.gd` (`level.show_card`) | First 3.4 s of every floor | Letterbox, the camera settles in from a closer zoom, then a lower-third with the emblem, floor number, title and the branch report. Doesn't block input or dialogue. |
| Alarm (C5) | same, mode `alarm` | Level 5 guitar pickup | Red alarm pulse and ALARM |
| Niro name card (C2) | same, mode `name` | Niro's first appearance | NIRO in the lower third while the reveal plays |
| Ending (C10) | `scripts/ending_cinematic.gd` | Forest viewpoint (15 s) | 0–1.5 s Miro steps out of the tree line; 1.5–2.8 s the remote fills the screen, ARMED, his thumb comes down, SIGNAL SENT, white flash; 2.8–5 s sigils ignite bottom to top while a rumble and tremor build; 5–6.8 s the branch PA line; 6.8 s DETONATION: white flash, a base blast plus chained blasts up each floor and a second fireball, shock rings, ballistic debris that lands and stops, embers, smoke column, heavy camera shake with roll, sub-bass hit, the tower falls into a burning base and the sky turns orange; 11–13.5 s Miro rim-lit by the fire lowers his head over the last thought; 13.5–15 s Last Man Standing, fade. Music drops out at 1.5 s: the blast is carried by sound design. |
| Finale | `scripts/finale.gd` (started by the ending, own CanvasLayer) | Straight after the ending | 0–12 s the beach at dawn: waves on a 6 s swell, sun glitter, gulls, a palm in the breeze, a thin smoke trail on the far horizon; Miro sits back with earbuds in, "Finally free."; the camera lifts to the sun. Music: Ethan's chord progression (`assets/audio/cine/ending_chords.ogg`). Then the end credits from `data/credits.json` (about 70 s) over Set Me Free, then the start screen. Tab/Esc/Enter skips the beach, then the credits. |
| Start screen | `scripts/start_backdrop.gd` (node `Backdrop` in the main menu) | Menu | Before completion: the tower at dusk with its banner rippling, birds, rolling cloud, distant lightning every 11 s, pines and grass leaning in gusts, blown leaves, a wind bed. After completion (`Campaign.game_completed()`): daylight, the tower a broken smoking stump with grass coming back, gulls. Draws the gothic title at the top; the menu sits below y = 100. |

## Cutscene audio

`scripts/cine_audio.gd` plays one-shots, fading loops and timed cues on the Effects bus from `assets/audio/cine/`. The current files are synthesized placeholders from `tools/synth_cine_audio.py` (rain, thunder near/far, the big explosion with a 70→28 Hz sub drop, rumble, fire, waves, wind, gulls). `tools/generate_cine_sfx_elevenlabs.py` replaces any of them with ElevenLabs sound effects (`--list` shows the prompts; needs `ELEVENLABS_API_KEY` and api.elevenlabs.io reachable). `ending_chords.ogg` is Ethan's own track.

## Fonts

`assets/fonts/`: UnifrakturMaguntia (Dracula-style blackletter) for titles, Pirata One for all other text. Autoload `Typeface` (`scripts/typeface.gd`) sets it as the default for every Control and `draw_string`.

Stills for review are written by `tools/capture_cinematics.gd` (run under xvfb).

## Branch text

All MISSING/HUNTED lines (PA, remote calls, guard lines, boss pre-fight line, ending PA and last thought) live in `data/branch_reactions.json`. Between-floor stings (C6–C9) can read `Campaign.reputation()`.
