# Story and systems implementation (7 Nov 2026)

Implements the approved plan (`/research/miro_design_research_and_story_plan.md` in the project folder). This is a map of what changed and where.

## Story
- Niro is the brother's name ("THE VOICE" on floors 1–2, "NIRO" from the L3 reveal). He is beaten, not killed; the defeat exchange is in `data/levels/level_05.json` (`DefeatExchange`).
- Level 5 is **The Foundation**. The reveal is spoken face to face at Niro's first appearance, not read from a lab file.
- The L1 Keeper is corrupt through favours ("Is there anything you can do for me?"). No coin, no medicine.
- Treason stays a rumour in L2 guard chatter. L3 closes on "The voice has a name now." L4 records are one line each and don't name the physician.

## Removed
- Flamethrower and suppressors. Every gunshot is loud. The suppressor case is now an ammunition case.

## Music (`scripts/music_director.gd`, `data/music/runtime_catalog.json`)
- Order: L1 YZ33; L2 DOPE 2 → Swag; L3 Bobblehead → Cyberpunk; L4 Plane Drums → Sum Crazy Shi; L5 silent → (guitar) Shit Crashed → (third floor) Hot Shit; ending Set Me Free; start screen Drill Shxt, or LIL UZI2 once the game has been finished.
- MusicDirector is the beat clock: `beat`/`bar` signals, `beat_position()`, `seconds_to_next_bar()`, `is_on_beat()`. Section changes wait for the next bar.
- Hiding: 800 Hz low-pass and −3 dB; suspicion opens it partly. Thought bus has a long reverb.
- New tracks are leveled by `tools/prepare_extra_tracks.py` (needs `soundselection/beats/LIL UZI2.mp3`, not committed).

## Level 5 flow (`scripts/foundation_flow.gd`)
Office (guitar, final sigil) → wave 1 → Niro #1 (reveal, rush) → retreat at 9 → hatch 1 → wave 2 → Niro #2 (+throw) → retreat at 6 → hatch 2 → Hot Shit, wave 3 → Niro #3 (+calls Keepers) → retreat at 3 → hatch 3 → deepest floor final fight → defeat exchange → woods.
- Guitar: key 6 or G, left click strums. Sleeps ordinary Keepers in ~120 px (170 on the beat), hurts Niro while he recovers. Sleeping Keepers are lootable and are not kills.
- Waves and Niro's arrival wait for the next bar; his telegraphs land on beats; his recovery window is one bar.

## Branches (`scripts/campaign.gd`, `data/branch_reactions.json`)
- Per floor, committed only on completion (retry-safe): kills, detections, stealth points (+2 unseen floor, +1 unseen pickpocket), offense points (+1 per kill, +1 per loud breach).
- HUNTED if total kills ≥ 3 or offense > stealth, else MISSING. Level 1 is neutral.
- Reactions: PA line, Niro's remote call, entry thought, poster, guard lines, an extra armed Keeper and faster suspicion on HUNTED, an extra wave Keeper in L5, the boss pre-fight line and the ending PA/thought.
- Kills: Niro's disappointment over the remote (once per floor), noise, body discovery.
- MP3 beats (`mp3_unlocks`, saved): calm beats for stealth points (Birthday Melody 2, Destroyed Lonely 3, Pink Ghost 5, Dancehall 64 6, Jazzy Hall 8, New Age Dancehall 9, Dancehall Lonesome 10, Dancehall YF 11); aggressive beats for Keepers killed (Drill 2 1, Drill Shxt 3, Reaper Beat 5, OX 8, Hot Shit 12). LIL UZI2 is the reward for finishing the game.
- On a floor, [B] (or `next` on the remote) steps through the unlocked beats, then back to the floor's own music; `music` and `play <n>` still work.

## UI
- Forced dialogue is a bubble over the speaker with E to continue. The bottom strip is for objectives, cues and notices only.
- Speech bubbles have a pointed tail. Thought bubbles have a trail of puffs and no name tag. Neither one shows the old "..." icon.
- Each floor opens on Miro's thought, and the thought is also the cue (no title speaker).
- Z hints: three per objective (a nudge, then where, then exactly what to do), from the level JSON `"hints"` (Level 1 in `intro_level.gd`). After 60 s on the same objective, the strip suggests "[Z] Think it through".

## Menus (`scripts/main_menu.gd`, `scripts/menu_screens.gd`, `scripts/pause_menu.gd`)
- Start screen: Play, Beats, Settings, Quit. Play opens level select: floors the player has reached can be played, cleared ones carry a check, the rest show a padlock. Progress is saved (`progress.cfg` `levels/highest`).
- Dev: editor runs, QA builds and `--dev` open every floor and add a soundtrack review picker on the Beats screen; `--player` forces the player view.
- Beats: every MP3 beat, unlocked ones playable, locked ones greyed with what earns them.
- Pause (Esc): Resume, Restart floor, Controls, Settings, Level select, Main menu, with the current beat shown.
- The first child of the start screen is `Backdrop`; the animated start screen replaces it.

## Difficulty (`Campaign.DIFFICULTIES`, Settings)
| | Easy | Medium | Hard |
|---|---|---|---|
| Miro's hearts | 5 | 3 | 2 |
| Blanket active / recharge | 6 s / 5 s | 5 s / 8 s | 4 s / 11 s |
| Level 5 waves | one Keeper fewer (min 1) | as built | one extra armed Keeper |
| Keeper sight / suspicion | 140 px / 0.65× | 165 px / 1× | 190 px / 1.4× |
| Keeper wind-up / gap between shots | 0.9 s / 2.8 s | 0.65 s / 2.1 s | 0.5 s / 1.6 s |
| Niro's health | 0.8× | 1× | 1.3× |
Saved in `settings.cfg`; it applies when a floor loads. Tests always run on Medium (`--difficulty=` overrides).

## Keepers (`data/guard_roster.json`)
- Each named Keeper has an individual personality, voice, alert and body lines, and two patrol mutters. The five original themes guide characterization; characters in the same theme have different concerns and lines. This includes the HUNTED patrols and every possible Foundation reinforcement.
- The first Keeper is Judas (Level 1).
- Off-duty huddles (`features.huddles`, `K` on the maps): three Keepers on Level 2, one reading John 3:16 to the other two. Absorbed, they only notice Miro right next to them. Behind them is a bunk with an ammo case.
- `world_features.add_casual_lines(lines, actors)` queues more overheard scenes after the main conversation.

## Niro over the remote (`scripts/remote_radio.gd`, autoload RemoteRadio)
- Radio bus: band-pass (420 Hz to 3.4 kHz), LOFI distortion (bitcrush), overdrive, a static bed, and dropouts on a fixed stutter pattern.
- Plays every remote line: the dialogue lines for NIRO / THE VOICE when anchored to Miro, the kill disappointment, and the Level 5 taunts. Face to face, his clips play dry.
- Level 5 taunts (`niro.taunts` in `level_05.json`) play whenever he is off screen after the reveal. They come in the authored order, on a bar line, every 6 bars.

## Voices (`data/voice_cast.json`, `tools/generate_voices.py`)
- The cast has a separate ElevenLabs voice for each of the 55 named Keepers, plus Niro (designed voice, preview 1) and the PA (Daniel).
- eleven_v3 with emotion audio tags per line (`guard_delivery`). Niro's tags are picked per line: pleading, mocking, unhinged.
- Keeper clips use `<keeper>_<line_id>.mp3`, including branch conversations, verses and the John 3:16 huddle. Judas's opening uses `judas_<hash>.mp3`. Run `python3 tools/generate_voices.py --keepers-only` to refresh Keeper audio without regenerating Niro or the PA.
- Niro and PA clips are named by a hash of the line, so editing text picks up a new clip. Run it locally with `ELEVENLABS_API_KEY`; `--list` shows the jobs without spending credits.

## Beat sync outside Level 5
- Keepers turn at patrol ends on a beat line (sick Keepers on every other beat) and lean into each step on the beat. The average speed is unchanged.
- Cameras sweep over four bars.

## Levels 2–4
See `docs/LEVEL_DESIGN.md`: two sub-floors per level (one per song), six storeys, authored routes and maps.

## Tests
`Run Checks.ps1` (24 suites, including `test_menus_and_progress.gd` for menus, difficulty, beats and the roster) plus `tools/run_playthrough_local.gd` (the full game). `test_remaining_levels.gd` plays each authored level's route with real inputs. Test and QA runs never write the player's save.

See `docs/CUTSCENE_HOOKS.md` for Sunday's art and cutscene hooks.
