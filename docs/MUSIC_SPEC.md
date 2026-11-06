# Miro — proposed music system and selection guide

Status: **design proposal only**, based on Ethan's latest direction. No music system, scoring, unlocks, tempo analysis or track selection has been implemented by this handoff. Sound effects and mute already exist separately. Musical taste and final selection remain with Ethan, Miro and the team.

## Latest team direction — November 6, 2026

The [agreed soundtrack placement plan](MUSIC_TRACKLIST.md) is authoritative for current chapter/section assignments and supersedes the earlier A/B sequences. Each level may contain multiple tracks. A/B labels describe listening comparisons, not the gameplay unlock branches. Ethan confirms the supplied beats are his original compositions and grants permission for game use. Automated estimates, when generated, live in `data/music/beat_analysis.json`; they require musical verification and do not replace team selection.

## Intent and terminology

Keep the five narrative **levels/chapters**, but allow each to contain multiple physical **tower floors** and musical sections. A descent within a level can mark a new mood without changing the chapter. Do not interpret a five-level game as a five-story tower.

Some chapters may be long enough for two or three musical selections. Levels 2–5 now each have two agreed section cues; see the placement plan for their order. Choose chapter length and music changes around its theme, goals and amount of conflict; do not extend traversal solely to play complete songs.

## Candidate library

- `soundselection/beats/`: current candidate playlist, copied from Ethan's supplied folder with original names and formats preserved. More songs may be added.
- `soundselection/finalcutbeats/`: selected-track destination, currently empty. A `.gitkeep` preserves it in Git.
- Audio is stored through Git LFS. After cloning or pulling elsewhere, run `git lfs install` and `git lfs pull` to obtain the actual media rather than pointer files.
- `.gdignore` keeps the unselected collection out of Godot imports and game exports. Once approved, copy only selected runtime versions into a dedicated music asset directory, with source attribution and permission information.

The placement plan records current selected chapter cues; “new beat” is excluded. Most were described by Ethan as trap-style/aggressive, with only one notably chill beat; that description has not been verified by listening or analysis.

## Proposed player experience

1. The intro may use a somber selection. The exact song and start/end points are undecided.
2. Miro can acquire a Walkman or MP3 player from the first guard. Choose the device and acquisition interaction later. Preserve a nonlethal way to obtain it—pickpocketing or another accessible pickup—so the soundtrack feature does not require killing.
3. After escaping the cell and descending to the first intended landing, the first exploration song begins. Identify the exact landing in the level blueprint; do not assume this means the transition into Chapter 2.
4. Reaching another meaningful floor/section can introduce a new track or suggest one. A small right-side popup from Miro could say that the music should fit the new atmosphere. Wording remains draft; the popup should not interrupt movement or cover important HUD information.
5. Stealthy and offensive play can unlock or recommend different beats. An unlocked track becomes available in the player's collection.
6. A dedicated control can cycle or select unlocked music. Key binding and whether selection pauses the game are undecided. Do not overwrite existing controls, particularly **2** for blanket stealth and **M** for sound mute.

## Regional transitions and track switching

Define explicit `music_region_id` triggers at authored landings or encounter boundaries. A region belongs to a chapter but may cover one or several physical floors. Trigger on a stable landing/entry, not every airborne change in Y position. Climbing back across a boundary, retrying an interaction or bouncing on a platform must not repeatedly restart the song.

Each region can offer a default track and optional stealth/offense alternatives. A proposed default policy is:

- Region entry suggests or selects a suitable unlocked track when automatic mode is enabled.
- Manual selection takes priority until the player re-enables automatic mode or explicitly accepts a later suggestion.
- Recent kill-count/play-style changes influence eligibility or recommendations; they do not abruptly interrupt a track after every action.
- Transition at an approved phrase/bar boundary where practical, or use a short configurable crossfade. Interrupted combat and cinematic transitions take precedence over beat-perfect timing.
- Returning to a previous area should not continuously replay introductions. Set a minimum change interval and a per-region visit policy during implementation.

Whether to ship automatic mode, manual mode, or both is a design decision—not an existing feature.

## Stealth and offense points / unlocks

Maintain two independent proposed measures rather than treating them as a morality score:

| Measure | Candidate earning events | Safeguards |
| --- | --- | --- |
| Stealth points | Pass an authored patrol encounter unseen; obtain the device/key nonlethally; finish a section without confirmed detection; finish a section without kills | Award encounter/section rewards once. Merely waiting concealed or toggling the blanket earns nothing. Distinguish brief suspicion from confirmed detection. |
| Offense points | Defeat a guard; finish a combat encounter; defeat the brother | Count each enemy/encounter once. No duplicate credit from corpses, repeated interactions or reload farming. |
| Kill count | Existing guard casualties, extended to chapter/run tracking if needed | Use as one signal for aggressive music, not the sole definition of play style. Define separately whether the scripted brother outcome counts. |

Thresholds, weighting, mixed-style behavior and actual track rewards are **TBD**. Do not make a player lose already unlocked music for trying another style. Both routes should have worthwhile rewards, and soundtrack preference must not force a particular combat choice.

Decide whether unlocks persist across attempts or only within a run. Current campaign state is in memory and casualty/inventory values do not carry between chapters; persistent music unlocks and reliable run-wide scoring will require new state handling. Restart rules must be explicit before scoring is implemented.

## Provisional chapter music guide

| Chapter / moment | Desired function | Candidate approach, subject to listening |
| --- | --- | --- |
| 1: imprisoned intro | Establish isolation, uncertainty and Miro's amnesia | Somber, restrained selection if one fits the library; do not assume the only chill track belongs here |
| 1: first descent after cell escape | Introduce the device/music feature and a sense of forward movement | First exploration cue, aligned to the chosen landing trigger |
| 2: symptoms and persecution | Leave space for illness, observation and patrol avoidance | Calmer or more restrained options; an offensive route can suggest a more intense alternative |
| 3: checkpoint and former-rank reveal | Escalate pressure while preserving story clarity | A possible longer chapter with two or three regions/songs: approach, checkpoint conflict, aftermath. Placement is illustrative only |
| 4: experimentation and containment | Support unease and the conflict in the evidence | Tension-oriented cue with sufficient space for dialogue; do not resolve the moral ambiguity musically through an unapproved story interpretation |
| 5: brother encounter | Support readable boss tells and sustained intensity | Aggressive/trap candidates may fit; compare rhythm and energy against the rush/projectile cadence rather than selecting on genre alone |
| 5: fatal exchange and ending | Make the personal loss, reveal and collapse legible | Duck, change, fade or briefly silence music as authored; ending must remain morally unresolved |

Dialogue intelligibility and attack cues outrank soundtrack loudness. Avoid rapid track changes between the final offer, combat, fatal exchange and ending. Specify those transitions as one authored sequence.

## Tempo / key analysis method and review

Audio-analysis tools can estimate tempo and musical key, but cannot determine which track the team should prefer. Trap half-time/double-time readings and ambiguous tonal material need human checking. Treat estimated BPM/key as evidence for arranging and transitions, not as an automatic quality ranking.

For each candidate, record:

- Stable track ID, original filename, source/creator and usage permission.
- Duration, codec/sample rate and channel count.
- Estimated BPM with confidence and plausible half/double-time alternatives.
- Beat grid/downbeat or phrase markers, manually checked at useful transition points.
- Estimated key/mode with confidence; mark uncertain or changing key instead of forcing a label.
- Loudness, true peak and broad energy changes to support consistent playback levels.
- Intro/outro lengths, major section timestamps, possible loop points, and whether vocals compete with dialogue.
- Human mood notes, preferred chapters/regions, and approval status.

Possible analysis tooling includes FFmpeg/ffprobe for metadata/loudness and an offline music-analysis library for tempo/onsets/chroma. Tool availability and results must be verified before claiming any measurement. Consult the generated analysis JSON for measured estimates and uncertainty; no human listening ranking or final transition recommendation is implied.

Select music by listening to candidates over actual recorded traversal/combat. Compare fit at a common playback loudness. Only then approve runtime edits, loops or excerpts; keep the original candidates unchanged.

## Proposed implementation boundaries

- A dedicated music director and audio bus manage playback, fades, ducking, queueing and manual/automatic selection. Keep music separate from the existing sound-effect pool.
- A catalog resource maps track IDs to approved streams, metadata, allowed regions and unlock conditions. Region IDs live in the level blueprints and saved scenes.
- Acquisition, region entry, encounter completion, confirmed detection and chapter completion emit events. Do not tie soundtrack logic directly to every physics frame or every guard AI update.
- Store device ownership, selected mode/track, earned unlocks and awarded encounter IDs separately from transient playback position. Define rollback/checkpoint rules before adding saves.
- The Walkman/MP3 player is a player-facing framing device unless another design is explicitly approved. Music playback and switching must not generate AI noise or change guard FOV.
- Keep pause/resume, mute and volume behavior explicit. Separate music/effects volume controls may be needed; existing M mute must retain a clear meaning.
- The right-side popup must be brief, nonblocking and readable. Coalesce unlock notifications so multiple awards cannot cover the screen.
- Expand levels only after validating pacing. The current chapters share compact multi-tier blockouts; additional authored floors, routes and encounters are new level-design work.

## Acceptance checklist for future work

- [ ] Team approves device, nonlethal acquisition route, scoring rules and persistence policy.
- [ ] Candidate catalog contains measured metadata with uncertainty and human listening notes.
- [ ] Team selects tracks; selected versions and provenance are recorded without removing originals.
- [ ] Every music region has a chapter/floor purpose; long chapters justify two or three songs through pacing.
- [ ] First post-cell descent starts the intended song once; re-entry/jumping does not spam changes.
- [ ] Manual switching only selects available tracks and has a clear priority over automatic suggestions.
- [ ] Stealth/offense unlocks are deterministic and cannot be farmed through repeated events or retries.
- [ ] Both nonlethal and offensive play can access the feature without progression soft locks.
- [ ] Popups never interrupt combat, dialogue or control responsiveness.
- [ ] Transitions, loudness and dialogue/attack readability are checked by listening in-game.
- [ ] Pause, resume, retry, chapter transitions and cinematic skip preserve consistent music state.
- [ ] Export contains only approved runtime tracks; candidate collection stays excluded.
- [ ] Full playthroughs cover stealth, offense and mixed styles, including the boss and ending.

## Next decision session

Choose the device, whether music selection is manual/automatic/hybrid, intended acquisition landing, unlock persistence, and which chapters merit extra physical floors. Then perform metadata analysis and a human listening shortlist. This document authorizes no implementation by itself; the user asked to preserve the proposal while committing the supplied beats.
