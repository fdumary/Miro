# Audio, overheard guards and stealth — review build

November 6, 2026. This document specifies the implemented review prototype and its remaining production work. Source of truth for track order: [MUSIC_TRACKLIST.md](MUSIC_TRACKLIST.md). All generation is build-time; the game works offline and never receives an ElevenLabs credential.

## Implemented soundtrack and mix

Nine runtime MP3 copies play through a dedicated Music bus. Originals remain unchanged under Git LFS. Intro and Level 1 use YZ33; Levels 2–5 follow the agreed two-track order. Re-entering a region does not restart its cue. Two bounded audio players crossfade over 1.5 seconds. Songs currently loop as whole files; exact musical loop/excerpt edits and bar-synchronized transitions are not claimed.

A simple leveling pass is sufficient for this review. Runtime music targets **−20 LUFS**, with a **−6 dB Music bus** default. Measured encoded music is −20.27 to −19.99 LUFS. Speech targets −18 LUFS, measures −19.76 to −18.20 LUFS, and uses a separate Voice bus. Encoded peak measurements stay below −1.7 dBTP in this batch. The normalization target was −2 dBTP; lossy reconstruction can differ slightly. Measurements are stored with provenance rather than represented as perfectly exact targets.

Music ducks a further **8 dB** during nearby guard speech and blocking dialogue, with a quick attack and slower recovery. Effects retain their existing per-cue levels on a separate Effects bus. M still mutes the master bus. The menu exposes saved Music, Effects and Voice sliders (−40 to 0 dB). This is a conservative starting balance, not headphone/speaker listening sign-off. Check low-volume speech, shots and simultaneous cues before adjusting defaults; no elaborate mastering is needed.

Current triggers are prototype authoring choices and can be tuned without changing platform geometry:

- Level 2: DOPE 2 starts on landing below Y=330, leaving the initial exploration tier.
- Level 3: Sum Crazy Shi starts on a grounded entry at X≥260 on the top tier (Y≤300), approaching the checkpoint terminal. Detection is not required.
- Level 4: Cyberpunk starts on landing below Y=330 after WardRelease.
- Level 5: Robot Attack starts when the brother is spawned for active combat, after FinalOffer. Boss defeat fades combat music before the fatal exchange.

The Level 2–4 thresholds are editable `music_region` entries in floor JSON; these are not promises of final pacing. No chapter was enlarged. The emotional outro composition is still missing, so the fatal exchange/ending uses the deliberate music fade rather than an invented replacement. Music currently plays as a background score without requiring portable-player ownership; acquisition, score thresholds and unlock UI remain separate unimplemented tasks.

## Overheard conversations and guard reactions

Levels 2, 3 and 4 have one finite, pre-generated two-guard exchange each. A nearby conversation starts within 250 world units; subtitles/clue recognition require 230 units. Voice uses positional distance falloff out to 300 units. This is distance-based spatial audio, not a wall-occlusion simulation. Miro can move, hide, attack or leave while they talk. Muting never removes subtitles or the non-audio clue path.

During an exchange, the pair hold their positions and face one another while perception/damage remain active. On completion both turn right for a five-second opening, then resume normal patrol. Detection, damage/death and noise-driven search release the conversation pose; interrupted exchanges do not endlessly replay. A speaker's death stops its speech. Living guards remain vulnerable throughout, and attackers are not granted immunity.

Level 3 places the pair beside the terminal. They discuss a forgotten login, reveal **root** (lowercase, spelling it out), then explain that the login can disable both checkpoint cameras. Level 2/4 dialogue provides draft local lore and existing mechanic hints. Text, speaker slots and voice IDs live in `data/guard_dialogue.json`.

Guard names are draft per-floor identities, displayed over actors and in subtitles. Three ElevenLabs voice IDs are used: George, Roger and Callum; an added conversation partner reuses the Roger slot. A discovered corpse is identified by name in the notification; the discovering guard gives a concerned voiced reaction about having worked with the victim and investigates. Confirmed detection also has a short voiced alert. One shared foreground voice prevents overlapping conversation/bark clutter; it is not a full individual speech scheduler for every NPC. Generic concerned clips do not pronounce every victim name.

Generated library: 16 clips (10 conversation lines, three body reactions and three alerts), using `eleven_multilingual_v2`. `assets/audio/voice/provenance.json` records exact text, voice/model IDs, generation signatures and leveling. Generate distinct additional voices or personalized name barks later if the team wants them; do not imply each NPC already has a unique voice.

## Terminal login

E at the Level 3 terminal opens a password form. Only exact `root` authenticates it. Correct login starts the existing one-second hack; leaving range interrupts the hack, pause freezes it, and completion disables both cameras and releases the checkpoint gate. Authentication lasts for the current floor attempt and resets on retry.

A maintenance-slip button inside the panel reveals the same password. This is an intentional fallback if the pair are killed, missed, muted or interrupted. Hearing the exchange is helpful but is not a mandatory progression flag. The form supports keyboard submission, mouse login and Close; normal movement/combat are locked only while the form is open.

## Suppressor cases

One case is chosen randomly per floor from a small set of authored, walkable anchors. Floor ray checks run after physics initialization; anchors near existing interactables are rejected. The selected anchor is retained across retries in the same run to prevent reroll farming. New run / review-level launch clears the selection. The case grants three suppressor charges, not a gun or ammunition; repeated looting cannot refill it.

The next three fired rounds consume one charge each. Empty triggers and cooldown attempts consume none. Suppressed shots use quieter placeholder shot audio (−32 versus −20 dB) and an AI noise radius of 90 versus 600 units. They still break blanket stealth, can be seen, and can alert nearby guards. The fourth round is normal. Existing damage, ammo and range are unchanged. Inventory remains floor-local, consistent with current supplies; cross-floor inventory carryover is not implemented.

## Hiding recesses

Additive vent/crawlspace props sit on existing supported tiers, away from interaction points. They do not remove tiles, create a new traversable tunnel, or change ladders/gates. E enters/exits. Nearby unlooted corpses take interaction priority so a death beside a vent cannot block loot. These are stationary enclosed hiding spots, separate from the timed blanket: no blanket charge/cooldown is needed; movement and attacks are disabled inside. Guards and cameras cannot visually detect an occupant. Taking damage reveals Miro; entering while a guard sees Miro is rejected. Ordinary projectile/contact collision is not replaced with invulnerability. Vent traversal and crawling animations are future work.

## Start, level review and end-screen behavior

The game now starts at a title/review menu with Start new run, five direct-level buttons, saved audio sliders and a soundtrack audition selector. F10 returns from gameplay. Direct launch is for review and does not fabricate earlier chapter progress. `--level=N` and QA launch continue to bypass the menu. Existing chapter completion and ending screens remain; boss defeat fades the combat track. No new image/video/avatar has been generated or embedded in these screens.

## ElevenLabs opportunities and boundaries

Speech is the best immediate use: guard exchanges, body/alert variants, optional menu narration, Miro/brother dialogue and ending VO. Keep subtitles and game-state events authoritative, and pre-generate approved scripts so runtime behavior is deterministic. The [speech API](https://elevenlabs.io/docs/api-reference/text-to-speech/convert) supports fixed voice IDs; [Text to Dialogue](https://elevenlabs.io/docs/overview/capabilities/text-to-dialogue) could improve future multi-speaker performance, but per-line clips currently make interruptions and spatial actors easier to control.

For sound design, use [ElevenLabs Sound Effects](https://elevenlabs.io/docs/overview/capabilities/sound-effects) later for a distinct suppressed shot, terminal login/failure, ventilation, distant cells and small transition stings. Existing licensed effects remain sufficient for this prototype. Keep Ethan's compositions as the soundtrack; generated music is only an option for an unfilled outro/sting after a brief is agreed, not a replacement for his beats.

For visuals, ElevenLabs' [creative tools include image/video and lipsync](https://elevenlabs.io/blog/introducing-voice-music-image-and-video-generation-in-the-elevenlabs-mcp). Potential later assets: title background, chapter cards, guarded terminal portrait, and a short brother/ending shot aligned with prerecorded VO. Maintain the game's established art direction; generating a talking avatar is not automatically the right presentation for this side-scroller. API-key access to speech has been verified; image/video model entitlement and outputs have not been verified here.

Live conversational agents could eventually support optional interrogation or lore questions. They should not invent canonical facts/passwords or control combat/gates. Use a server-side service with constrained approved lore and authenticated sessions if added; never ship an account key or depend on a live LLM to finish a level. There is no live agent, microphone access or cloud request in this build.

## Ordered work status

1. AUDIO-01 — Runtime soundtrack copies, leveling, section playback and ducking: implemented for review.
2. AUDIO-02 — Offline voice generation, subtitles and finite guard exchanges/reactions: implemented for review.
3. STEALTH-01 — root login and a non-audio fallback: implemented for review.
4. STEALTH-02 — constrained random cases, three-shot suppression and enclosed hiding: implemented for review.
5. REVIEW-01 — title/level/audio review menu, source checks and platform exports: validation recorded below.
6. NEXT — human listening/pacing review; approve voice casting, script and exact loop points; supply outro cue. Scoring/unlocks and portable-player acquisition stay in their existing backlog.

## Build and verify

Set `GODOT` to Godot 4.7.2 or pass its executable path:

```sh
python3 tools/build_review.py --godot /path/to/godot --platform windows
python3 tools/build_review.py --godot /path/to/godot --platform macos
```

Matching official export templates are required. Windows output: `build/windows/Miro.exe`; macOS output: `build/macos/Miro.zip`. Builds are ignored by Git. Local `.env` credentials, raw candidate library, documentation and generation scripts are explicitly excluded from normal exports.

Rebuild music copies with `python3 tools/prepare_game_audio.py` (FFmpeg required); generate/cache speech using `python3 tools/generate_voices.py` and a local `ELEVENLABS_API_KEY`. The key is never printed, committed or needed to play. The generator submits text to ElevenLabs and uses account credits; unchanged text/voice/settings clips are cached. Do not delete provenance when revising lines.

Run the existing game suites and `tools/test_music_and_world.gd`; `Run Checks.ps1` includes the new suite. Final build evidence and manual listening limits belong in the next handoff update. Review on headphones/speakers is still required for voice performance, transitions, volume balance, loop seams and chapter pacing.

## Verification recorded for this increment

- 14 source scenarios passed (13 suites plus the separate C4 intro route); the new music/world suite passes 41 checks. Existing later-level traversal passes 120/120 checks.
- A separate QA pack completed a continuous five-level exported playthrough and watched ending: 64/64 checks. It runs under matching Godot 4.7.2 on macOS, not a native Windows execution claim.
- Normal Windows and unsigned macOS review exports were built with official 4.7.2 templates; the template archive SHA-512 was checked against the official release list. The native macOS executable starts successfully.
- Isolated pack checks decode all nine music files and all 16 voice clips and verify credential/raw-library/generator exclusions. Source-folder fallback must be disabled by checking outside the checkout.
- Automated rendered captures were inspected for the title/audio menu, overheard subtitles and password panel. Headless checks validate resources/state; they do not approve artistic voice performance or the listening mix.
- Remaining manual review: headphones/speakers, simultaneous alerts/shots/VO, loop seams and song switches, casting, extra-guard difficulty, hiding/case placement across random anchors, and a continuous native Windows run. No outro composition or live conversational agent was generated.
