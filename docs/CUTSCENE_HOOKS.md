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

## Ending (`scripts/ending_cinematic.gd`)

Timeline: 0–1.2 s woods, 1.2–2.6 s full-screen remote "SIGNAL SENT", 2.5 s sigils ignite, 5 s branch PA line, 7.5 s collapse + Set Me Free starts, 11 s Miro lowers his head with the branch's last thought, 12–14 s fade. Replace the `_draw()` storyboard with panels, keeping `elapsed`, skip (Tab) and pause.

## Branch text

All MISSING/HUNTED lines (PA, remote calls, guard lines, boss pre-fight line, ending PA and last thought) live in `data/branch_reactions.json`. Between-floor stings (C6–C9) can read `Campaign.reputation()`.
