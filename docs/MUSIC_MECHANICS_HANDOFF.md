# Music mechanics — implementation handoff

Prepared November 6, 2026. Current focus: soundtrack progression and music branches.
Latest source integrated: `fcbc803` from `https://github.com/ethanrxla/Miro`. Official team repository and push destination: `https://github.com/xynprize/Miro.` (`origin`); Ethan’s repository is the read-only source remote (`upstream`). This is a scoped design backlog, not an implemented music system. Keep Fran's existing playtest handoff for the playable baseline.

The detailed [music specification](MUSIC_SPEC.md) is the design reference; this handoff orders its implementation. Preserve its chapter/physical-floor distinction, authored landing triggers, nonblocking suggestions and manual-selection priority. Current five-floor blockouts are implementation structure, not a limit on tower height.

## User direction

Miro can acquire different music through the levels, potentially by taking a Walkman or MP3 player from the first-floor guard. Different beats can unlock through kill count and stealth, with separate stealth points and offense points.

The device type, scoring values, unlock thresholds, music selection behavior and actual tracks are not yet approved. “Branches” here means musical progression; changing story outcomes is outside this scope.

## Proposed playable loop

1. Acquire a portable music player on Floor 1.
2. Start with a base beat; earn stealth and offense points through distinct actions.
3. Unlock beats along either branch as the campaign progresses. Both branches can remain available in a mixed-style run.
4. Carry earned music progress between floors. Show what unlocked and why.

Recommended defaults for the first prototype: support both pickpocketing and corpse looting for the device so music never requires a kill; keep kill count as an input to offense scoring rather than a third currency. Use points to unlock music, without spending them. Music should not modify damage, stealth duration or guard hearing. These are proposals, not existing mechanics.

## Progress — November 6, 2026

MUSIC-05 analysis tooling and a preliminary 16-track report are available; see [analysis method and limits](BEAT_ANALYSIS.md). The [A/B section plan](MUSIC_AB_PLAN.md) and `data/music/section_candidates.json` preserve Ethan’s candidates and permission statement. Levels may use multiple tracks; A/B means listening comparison, not unlock branches. Track approval, runtime edits, in-game music playback and scoring are still unimplemented. MUSIC-01 remains the first gameplay implementation task.

## Ordered tasks

### MUSIC-01 — Define the scoring and branch contract

Dependencies: none. Deliverable: approved rules and a small data-driven unlock catalog.

- Decide Walkman versus MP3 player, starting beat, manual beat selection versus automatic branching, and whether unlocks are run-only or saved between runs.
- Define separate `stealth_points`, `offense_points`, and `kill_count`; give each unlock a stable ID and explicit requirements.
- Proposed stealth rewards: one-time undetected pickpocket/hack milestones and a no-confirmed-detection floor bonus. Do not award points simply for waiting concealed or repeatedly activating the blanket.
- Proposed offense reward: one award per confirmed enemy death. Decide whether stealth kills also qualify for any stealth reward and whether the brother counts; do not silently double-award.
- Specify confirmed detection from guards and cameras, as distinct from suspicion, noise investigation or body discovery. Decide whether detection merely loses the clean-floor bonus or also deducts points.
- Pick thresholds after counting available rewards across all five floors. Ensure both routes have attainable unlocks; avoid rewarding only kill-heavy play with more musical variety.

Acceptance: examples cover a clean nonlethal run, combat run, mixed run and detected nonlethal run; every point and unlock has an unambiguous cause. Numeric tuning remains open until this task is settled.

### MUSIC-02 — Track progress and retry behavior

Dependencies: MUSIC-01. Deliverable: music state and one-time event accounting.

- Extend the campaign model with device ownership, separate scores, kill count, unlocked beat IDs and selected beat ID. Keep current-floor changes separate from committed floor-entry state.
- Add stable source IDs for reward events so repeated interaction, repeated hits or repeated death callbacks cannot farm points.
- Follow the existing floor-commit boundary: descent commits current-floor results; retry restores entry music state; a new run clears run progress. If persistent unlocks are chosen, define their separate save/reset rules explicitly.
- Define direct-floor debug entry with explicit seed state; do not pretend earlier rewards were earned.

Acceptance: retries cannot accumulate rewards; prior-floor unlocks survive descent/retry; new-run and debug-entry behavior match the agreed contract.

### MUSIC-03 — Add the first-floor music-player pickup

Dependencies: MUSIC-02. Deliverable: one acquisition interaction and clear feedback.

- Integrate device acquisition with the first guard's pickpocket/loot paths. Preserve existing key, gun, ammo and escape-route behavior.
- Resolve the C4 bypass route: recommended option is to leave the device optional and obtainable later, without blocking descent. Define what plays before acquisition.
- Add one-time acquisition text and starter-beat unlock. Choose final prop/art after device type is decided.

Acceptance: lethal and nonlethal acquisition work once; repeated E grants no duplicate reward; bypass and retry behave as specified.

### MUSIC-04 — Connect gameplay events to beat unlocks

Dependencies: MUSIC-02, MUSIC-03. Deliverable: both branches work across five floors.

- Connect confirmed guard deaths, approved stealth milestones, guard/camera detection and floor completion to the scoring model.
- Use the central unlock catalog rather than scattering thresholds through controllers.
- Show concise point/unlock feedback and floor-end totals. Clarify how mixed play advances both branches.

Acceptance: stealth, offense and mixed play unlock their intended beats, with no duplicate awards from corpses, repeated terminals, dialogue skipping or floor retries.

### MUSIC-05 — Review candidates and build the soundtrack playback layer

Dependencies: MUSIC-01; can proceed with placeholder audio while MUSIC-02–04 are implemented. Deliverable: dedicated music playback and initial licensed loops.

- Inventory and analyze the supplied Git LFS candidates in `soundselection/beats/`, then have the team audition and shortlist them; keep originals unchanged and put approved selections in `soundselection/finalcutbeats/`. Record measured tempo/key with uncertainty, metadata, loudness and useful section/loop markers. Select a base beat plus initial stealth/offense variants. Record source, usage rights, loop boundaries, BPM and loudness. No tracks have been chosen yet.
- Add a dedicated music controller/bus, separate from the bounded sound-effects pool. Agree crossfade versus beat/bar-synchronized transitions before implementation; matched tempo/loop structure is required for synchronized layers.
- Author stable `music_region_id` landing/encounter triggers within chapters, including the first intended landing after cell escape (not automatically Chapter 2). Prevent re-entry/jumping from spamming switches; manual selection takes priority over automatic suggestions. Define behavior during acquisition, region/floor transitions, dialogue, pause, death, retry, boss encounter and ending. Avoid restarting the loop every frame or playing duplicate controllers after scene changes.
- Preserve M's existing mute behavior; clarify whether it becomes global mute and whether independent music/effects volume controls are needed.

Acceptance: loops and branch changes sound clean; effects/dialogue remain readable; mute works across scenes; missing music resources fail safely without interrupting play.

### MUSIC-06 — Expose selection and validate the complete loop

Dependencies: MUSIC-03–05. Deliverable: usable music feedback/selection, verification and updated playtest handoff.

- If manual selection is chosen, add a compact unlocked-beat selector with locked requirements and active selection. Automatic mode still needs clear branch/unlock feedback. Do not bind a new control without checking existing controls.
- Add meaningful state tests for scoring, duplicate protection, thresholds, mixed progression, retry and new-run rules; exercise both pickup routes and the C4 bypass.
- Run relevant existing gameplay checks after integration. Validate a continuous five-floor run and exported resource inclusion; audition actual playback, transitions and mixing manually because headless checks cannot prove sound quality.
- Update Fran's checklist and current gameplay decisions with implemented behavior, exact commit, test evidence and remaining tuning. Rebuild the ignored release executable when distributing a playable build.

Acceptance: a player can acquire music, understand both branches, unlock and hear beats through a full campaign, then retry/start fresh with correct state. Record any manual checks not performed.

## Code entry points and constraints

- `scripts/campaign.gd`: in-memory campaign progress; `enter_floor()` and `complete_floor()` establish current retry/commit boundaries. No disk campaign save currently exists.
- `scripts/intro_level.gd`: Floor 1 interaction, pickpocket/loot, completion and HUD; `scripts/scaffold_level.gd`: later-floor interactions and completion.
- `scripts/intro_guard.gd`: `die()` already guards duplicate death recording and increments local player casualties. Current casualty count is not a campaign-wide scoring system.
- `scripts/intro_player.gd`: current-floor player state and timed blanket behavior. Stealth activation alone is not proof of an undetected objective.
- `scripts/security_camera.gd`: camera detection; include it in any clean-floor scoring rule.
- `scripts/sound_fx.gd`: seven sound effects and persisted master-bus mute. No music controller or music assets currently exist.
- `assets/audio/sources.json`: existing effects provenance. Add equivalent provenance for new music. Candidate beats already exist under `soundselection/` (Git LFS, excluded from Godot via `.gdignore`); approved runtime music is still absent.

Next implementation task: MUSIC-01, followed by MUSIC-02. Keep tasks reviewable and report implementation separately from proposals. Do not change blanket rules, narrative branches, combat balance or the unrelated level-menu backlog as part of this music work.
