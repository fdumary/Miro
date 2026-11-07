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
- Order: L1 YZ33; L2 DOPE 2 → Swag; L3 Bobblehead → Cyberpunk; L4 Plane Drums → Sum Crazy Shi; L5 silent → (guitar) Shit Crashed → (third floor) Robot Attack; ending Set Me Free; menu after a finished Play run LIL UZI2.
- MusicDirector is the beat clock: `beat`/`bar` signals, `beat_position()`, `seconds_to_next_bar()`, `is_on_beat()`. Section changes wait for the next bar.
- Hiding: 800 Hz low-pass and −3 dB; suspicion opens it partly. Thought bus has a long reverb.
- New tracks are leveled by `tools/prepare_extra_tracks.py` (needs `soundselection/beats/LIL UZI2.mp3`, not committed).

## Level 5 flow (`scripts/foundation_flow.gd`)
Office (guitar, final sigil) → wave 1 → Niro #1 (reveal, rush) → retreat at 9 → hatch 1 → wave 2 → Niro #2 (+throw) → retreat at 6 → hatch 2 → Robot Attack, wave 3 → Niro #3 (+calls Keepers) → retreat at 3 → hatch 3 → deepest floor final fight → defeat exchange → woods.
- Guitar: key 6 or G, left click strums. Sleeps ordinary Keepers in ~120 px (170 on the beat), hurts Niro while he recovers. Sleeping Keepers are lootable and are not kills.
- Waves and Niro's arrival wait for the next bar; his telegraphs land on beats; his recovery window is one bar.

## Branches (`scripts/campaign.gd`, `data/branch_reactions.json`)
- Per floor, committed only on completion (retry-safe): kills, detections, stealth points (+2 unseen floor, +1 unseen pickpocket), offense points (+1 per kill, +1 per loud breach).
- HUNTED if total kills ≥ 3 or offense > stealth, else MISSING. Level 1 is neutral.
- Reactions: PA line, Niro's remote call, entry thought, poster, guard lines, an extra armed Keeper and faster suspicion on HUNTED, an extra wave Keeper in L5, the boss pre-fight line and the ending PA/thought.
- Kills: Niro's disappointment over the remote (once per floor), noise, body discovery.
- MP3 unlocks at 2/5/8/11 stealth points (saved; remote `music`, `play <n>`).

## UI
- Forced dialogue is a bubble over the speaker with E to continue; the bottom strip is objectives, cues and notices only. Z gives a hint in Miro's thought bubble.

## Tests
`Run Checks.ps1` (21 suites) plus `tools/run_playthrough_local.gd` (full game, 74 checks). Test and QA runs never write the player's save.

See `docs/CUTSCENE_HOOKS.md` for Sunday's art and cutscene hooks.
