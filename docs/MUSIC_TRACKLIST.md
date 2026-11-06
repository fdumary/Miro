# Agreed soundtrack placement and section plan

Approved by Ethan November 6, 2026. This is the current placement plan and supersedes the earlier A/B candidate sequences. Prototype music playback is implemented; see [review build details and actual triggers](AUDIO_AND_STEALTH_REVIEW.md). Each chapter can contain multiple tracks; changes follow meaningful gameplay sections rather than a song timer or a fixed number of physical tower floors.

## Intro and Level 1 — YZ33

Use `YZ33.mp3` for the intro and first level, carrying the musical identity through the cell escape. “New beat” is excluded. Exact intro start point, whether playback is continuous across the intro/escape, and the relationship to device acquisition still need authoring; do not gate all intro audio behind obtaining the player.

## Level 2 — Bobblehead → DOPE 2

- Exploration / observation: `BOBBLEHEAD2.mp3`.
- Increased pressure: `DOPE2.mp3`.

Switch when exploration gives way to a sustained pressure section, not on every guard suspicion. The current compact blockout has no authored music-region boundary for this transition. Add one after reviewing traversal and the SickPrisoner / BrotherOffer / TransferLedger pacing; do not claim that a specific existing milestone already triggers it.

## Level 3 — Swag → Sum Crazy Shi 3

- Checkpoint approach: `swag.wav`.
- Checkpoint conflict: `sum crazy shi_3.mp3`.

The intended transition is entry into the checkpoint conflict section. Author an approach/conflict boundary around the terminal encounter; `RemoteTerminal` completion resolves the security system and is not automatically the start of conflict. Preserve a meaningful transition on a clean stealth route, without requiring confirmed detection or combat to hear the second track.

## Level 4 — Plane Drums → Cyberpunk

- Ward traversal: `plane drums nig.wav` (display title: Plane Drums).
- Deeper containment / experimentation: `cyberpunk_2.mp3`.

Use the physical threshold into deeper containment for the change. `ExperimentRecords` and `WardRelease` provide authoring context; the exact threshold must be placed in the level blueprint. Both tracks belong in this chapter, rather than being mutually exclusive alternatives.

## Level 5 — Shit Crashed 2 → Robot Attack

- Final approach and buildup: `shit crashed 2.wav`.
- Brother boss fight: `robot attack.wav`.

Start Robot Attack when the brother actually enters active combat, after the final offer/dialogue releases control. `FinalOffer` and boss spawning are integration points; `BrotherEncounter` currently records boss defeat, so it must not be mistaken for the combat-start trigger. Do not alternate tracks during boss phases or restart on each attack.

On defeat, stop the combat music with an authored fade/duck before the fatal exchange. No additional battle cue is assigned to the dying dialogue.

## Outro — emotional chord progression

Use an emotional chord progression after the fatal exchange, supporting the ending. Exact composition/file and entry point remain unresolved. Author the fatal exchange → viewpoint → collapse/fade as one sequence. Keep the ending's narrative ambiguity; the cue does not establish a new story outcome.

## Transition and branch contract

- Track order within each chapter is established above. Exact excerpt timestamps, loop points, fade lengths, beat grids and loudness are still to be chosen through in-game listening.
- Trigger changes once on authored section entry. Backtracking, jumping, repeated interaction and repeated detection must not cycle or restart tracks. Intro-to-Level-1 should not restart YZ33 solely because the section label changes.
- Use a short configurable fade as the initial implementation approach; beat/bar-synchronized overlap requires verified timing and musical compatibility. Current tempo/key estimates are provisional.
- Support both nonlethal and offensive traversal. Placement is separate from the still-unsettled stealth/offense unlock rules; do not silently lock these chapter cues behind kill counts or points.
- Existing manual-selection priority remains the proposed behavior until the selection mode is settled. An authored boss/ending sequence must define whether it overrides a manual choice.
- Pause freezes playback progression; retry restores section-entry behavior without duplicate players. Final pause/retry/selection details belong in MUSIC-01/MUSIC-05 before shipping.
- If the current blockout is too short for two meaningful sections, improve/author the relevant section pacing or record the limitation for review. Do not switch every few seconds or pad traversal just to include a whole song. No chapter-length expansion is implemented by this document. The review build now uses the prototype thresholds listed in AUDIO_AND_STEALTH_REVIEW.md.

## Repository handoff

The implementation now supplies the prototype region boundaries described in the review spec; exact musical excerpts and outro remain open. The structured counterpart is `data/music/section_candidates.json` (legacy filename, now the agreed section plan). Originals remain in `soundselection/beats/` under Git LFS and outside Godot imports/exports. Ethan confirms these are his original compositions and grants full game-use permission. Runtime copies/edits still need to be made after audition.

Next work: author the missing region boundaries, resolve the outro file, confirm excerpts/transitions by listening, and integrate the dedicated music director under MUSIC-05. MUSIC-01–04 still cover device acquisition and scoring/unlocks; this placement approval does not invent their unresolved rules. Verify both stealth and combat routes, continuous chapter progression, boss start/defeat, retry and ending skip before declaring playback complete.
