# Fran — playtest handoff

**New review increment:** [audio and stealth feature spec](AUDIO_AND_STEALTH_REVIEW.md) supersedes the older no-menu/no-music and one-interaction terminal descriptions below. Test the title menu, separate volumes, both section cues per later chapter, finite voiced conversations/turn-away openings, root login and maintenance-slip fallback, three-shot suppressors and E-entry hiding recesses. The historical baseline checks remain useful; they do not claim manual approval of these additions.

Prepared November 6, 2026. Gameplay baseline: [`83e3e96`](https://github.com/ethanrxla/Miro/commit/83e3e96). This handoff documents the implemented build; unchecked boxes below are **manual tests still to perform**, not claims that they passed.

## Start here

1. Pull the latest `main` from [ethanrxla/Miro](https://github.com/ethanrxla/Miro).
2. Open `project.godot` with Godot **4.7.2**, using the existing Forward+ configuration. Run the main scene for the full campaign.
3. For isolated checks, run `scenes/levels/level_02.tscn` through `level_05.tscn` in the editor. On Ethan's PC, `Play Level.ps1 -Level 3` also works.
4. On Ethan's PC the current release is `C:\towerdefense\Miro\build\windows\Miro.exe`. **The executable is local and ignored by Git; cloning the repo does not download it.** `Build Windows.ps1` rebuilds it with matching export templates installed. PowerShell launch/build/check scripts currently hardcode Ethan's Godot executable path; update that path on another PC, or export the **Windows Desktop** preset from Godot.
5. The release supports `Miro.exe -- --level=3` for direct-floor testing. This is a development shortcut, not a level menu or a completed campaign save.

Use [the report template](PLAYTEST_REPORT_TEMPLATE.md) for findings and [the coding-agent prompt](FRAN_AGENT_PROMPT.md) when handing fixes to an agent.

## Two important scope distinctions

**Blanket intent:** Ethan reaffirmed that the blanket is the stealth tool, so Miro can hide in shadows. Test that scenario explicitly. The current implementation follows his earlier mobile-stealth revision: it can also activate **outside shadows**, lasts 5 seconds, slows movement to 55%, and then has an 8-second cooldown. The newest handoff request does not explicitly say whether outside-shadow activation should be removed. Record this as a design clarification for Ethan/Fran; do not silently revert the mechanic or claim shadow-only activation already exists. The original stationary-shadow rule in `class.md` is historical, not the current implementation.

**Level menu:** a player-facing main menu / level-selection screen is **not implemented**. There is an Esc pause overlay, R retry, Enter descent after completion, and direct-floor development launching. Test those implemented controls; report the actual level menu as an outstanding deliverable, not a failing button that exists somewhere.

## Controls and test locations

| Control | Current action |
| --- | --- |
| A/D or Left/Right | Move |
| Space | Jump |
| W/S or Up/Down | Climb ladder |
| C | Dodge; ends stealth |
| E | Interact, pickpocket, loot, use terminal, place sigil |
| 1 | Shank |
| 2 | Activate/cancel blanket stealth after collecting supplies |
| 3 | Breach Level 1's cell lock with C4; later charges are reserved for sigils placed with E |
| 4 | Fire looted gun |
| Esc | Pause/resume |
| R | Restart the current floor from its entry state |
| Enter | Advance dialogue; descend after floor completion; new run after ending |
| Tab | Skip dialogue/cinematic with the same progression result |
| M | Mute/unmute effects; preference persists |

| Floor | Main checks |
| --- | --- |
| 1 — The Prisoner | Bed supplies; key/shank/C4 escape routes; movement, guard perception, loot, two ladders, first sigil, brother voice |
| 2 — The Symptoms | Coughing prisoner, patrol avoidance, mobile stealth in/out of shadows, transfer record and second sigil |
| 3 — The Order | One-second terminal hack, two cameras, physical checkpoint gate, rank/brother reveal, third sigil |
| 4 — The Ward | Experiment records, manual ward release and physical seal, containment evidence, brother warning, fourth sigil |
| 5 — The Brother | Final sigil and offer, two-attack boss, fatal exchange, viewpoint, prepared ending sequence |

## Implementation status and repository map

“Implemented” means functioning code and automated coverage exist. It does not mean Fran has approved feel, difficulty, art or narrative.

| System | Current status / behavior | How it is achieved |
| --- | --- | --- |
| Player movement and health | Implemented: movement, jumping, ladder climbing, dodge, three hearts and damage recovery | [intro_player.gd](../scripts/intro_player.gd), [base_character.gd](../scripts/base_character.gd), [intro_player.tscn](../scenes/intro_player.tscn) |
| Blanket | Implemented: timed mobile concealment; guards/cameras cannot see concealed Miro; live guard overlap reveals and alerts | Exported tuning properties, timers and `check_guard_contact()` in [intro_player.gd](../scripts/intro_player.gd). Shadow areas remain scenery/route landmarks, not activation gates. |
| Shank, gun and loot | Implemented: one unaware/two frontal shank hits for standard guards; limited gun ammo; one-time corpse loot; shots raise searches | [intro_player.gd](../scripts/intro_player.gd), [intro_guard.gd](../scripts/intro_guard.gd), interactions in [intro_level.gd](../scripts/intro_level.gd) and [scaffold_level.gd](../scripts/scaffold_level.gd) |
| C4 and sigils | Implemented: fixed Level 1 lock breach; mandatory fixed sigil per floor; repeated interaction cannot duplicate placement | [intro_level.gd](../scripts/intro_level.gd), [scaffold_level.gd](../scripts/scaffold_level.gd), [sigil_anchor.tscn](../scenes/sigil_anchor.tscn). No free placement or early tower detonation. |
| Guard AI / sight | Implemented: patrol → suspicion → alert → search, facing/range/height/wall checks, last-seen memory, body discovery and noise investigation | [intro_guard.gd](../scripts/intro_guard.gd); shared sight rays/noise queries in [intro_level.gd](../scripts/intro_level.gd). Guards do not climb ladders. |
| Cameras / hacking | Implemented on Floor 3: sweeping, wall-clipped visible cones; floor-wide guard investigation; one-second proximity hack disables both linked cameras | [security_camera.tscn](../scenes/security_camera.tscn), [security_camera.gd](../scripts/security_camera.gd), timer/linking in [scaffold_level.gd](../scripts/scaffold_level.gd). Cameras currently spawn at controller-defined positions. |
| Checkpoint / ward gates | Implemented physical barriers, opened by named milestones; ward/room art is provisional | [progress_gate.tscn](../scenes/progress_gate.tscn), [progress_gate.gd](../scripts/progress_gate.gd), `gates` entries in floor JSON. Ward release follows experiment records. |
| Five floors | Traversable blockouts, linked in sequence; shared three-tier layout family with different objective/ladder placements | [intro.tscn](../scenes/intro.tscn), [scenes/levels](../scenes/levels), [data/levels](../data/levels), [build_intro.gd](../tools/build_intro.gd), [build_remaining_levels.gd](../tools/build_remaining_levels.gd) |
| Campaign / retries | In-memory floor, sigil, narrative, boss and ending flags; retries restore entry progress; new run clears it | [campaign.gd](../scripts/campaign.gd) autoload. **No disk campaign save or inter-floor inventory/casualty carryover**; later floors start with supplies and fresh local player state. |
| Dialogue | Simple bottom text panel with speaker token/name; continue/skip; draft narrative | HUD/dialogue in [intro_level.gd](../scripts/intro_level.gd), [dialogue_portrait.gd](../scripts/dialogue_portrait.gd), later-floor `stations` in JSON |
| Boss | Implemented: alternating telegraphed rush/projectile, recovery-only vulnerability, six health, automatic fatal dialogue handoff | [brother_boss.tscn](../scenes/brother_boss.tscn), [brother_boss.gd](../scripts/brother_boss.gd). Shape art is provisional. |
| Ending | Implemented in-engine fallback: woods, five sigils activating, prepared collapse, head bow and fade; subtitles/pause/skip | [ending_cinematic.tscn](../scenes/ending_cinematic.tscn), [ending_cinematic.gd](../scripts/ending_cinematic.gd). Not the final Higgsfield production or a polished outdoor playable level. |
| Pause / resume | Implemented Esc overlay; R restarts; timers respect pause and dialogue | Input/overlays in [intro_level.gd](../scripts/intro_level.gd), timer handling in player/camera/boss/cinematic controllers |
| Level menu | **Not implemented** as an in-game selection UI | Only `Play Level.ps1`, release `--level=N`, and completion-screen transitions currently exist |
| Assets / sound | Julia's player/tile PNGs integrated; Oil 6 placeholders; coughing prisoner and ward props; seven Kenney effects and persistent mute | [assets](../assets), [story_prop.gd](../scripts/story_prop.gd), [sound_fx.gd](../scripts/sound_fx.gd), audio source/license notices in [assets/audio](../assets/audio) |
| Windows export | Working local release and separate automated QA export | [export_presets.cfg](../export_presets.cfg), [Build Windows.ps1](../Build%20Windows.ps1), [Check Exported Playthrough.ps1](../Check%20Exported%20Playthrough.ps1). Build output stays outside Git. |

## Manual playtest checklist

Mark each as PASS / FAIL / BLOCKED / NOT RUN in the report, with a clip or screenshot for failures. Do one continuous run before relying on direct-floor shortcuts.

### Movement, traversal and restart

- [ ] Run left/right, reverse direction, jump at platform edges and land on narrow/raised tiles. Check snagging, sliding and camera framing.
- [ ] Enter and leave both ladders from each end; jump off; test simultaneous horizontal/vertical input. Verify slow climbing during stealth feels intentional.
- [ ] Dodge into open space, walls and attack wind-ups. Verify cooldown and damage avoidance without clipping through gates.
- [ ] Complete floors 1–5 in order, with every required sigil and story dependency. Confirm no accidental skips or soft locks.
- [ ] Attempt an exit before its prerequisites, and interact repeatedly with sigils/exits. No duplicate charge consumption or unwanted scene changes.
- [ ] Die and press R on each floor. Repeat R during dialogue, hacking, boss combat and the ending. No stuck pause, controls, gates or old enemies.
- [ ] Confirm current-floor retry preserves prior committed floors but resets current-floor actions. Starting a new run clears campaign progress.

### Supplies, C4, combat and loot

- [ ] Before retrieving bed supplies, verify item actions give clear feedback. Retrieve supplies once; repeated E must not duplicate them.
- [ ] Complete Level 1 separately by unseen key theft, shank/loot/key, and C4 breach.
- [ ] Pickpocket while facing the Keeper and while behind him; verify the distinction is understandable.
- [ ] Use C4 close to and far from the locked cell door. Only valid breach consumes a charge, opens collision and draws investigation.
- [ ] Keep the reserved sigil charge after breaching. Test 3 again after the door opens and on later floors; no arbitrary explosives or premature detonation.
- [ ] Kill an unaware guard with one shank hit, then an alerted guard with two. Test reach, facing, cooldown and walls preventing through-wall hits.
- [ ] Search dead guards on floors 1–4. Obtain the key where appropriate and a gun/two rounds; repeat loot without gaining more ammo.
- [ ] Fire with no weapon, no ammo and valid ammo; test facing/range/wall obstruction and ammunition consumption. A shot should attract investigation.
- [ ] Verify three-heart damage, brief hit immunity, death and restart. Compare guard telegraph readability with dodge timing.

### Blanket / shadows / detection

- [ ] **Use the blanket in a shadow area:** activation hides Miro from guards and cameras; visual feedback and the HUD timer are clear.
- [ ] Activate outside shadow, while walking and in midair. Current expected behavior: allowed. Record whether Ethan wants this retained or restricted to shadows.
- [ ] Measure approximately 5s active, 8s recharge after ending, and slower movement. Check the HUD against actual availability.
- [ ] Walk, climb and jump while concealed. These preserve stealth; attack, gunfire, dodge, damage or pressing 2 again end it.
- [ ] Walk into a living guard while concealed, and let a guard walk into Miro. Both should blow cover and alert that guard immediately.
- [ ] Pass near a guard without overlap and over a dead guard. Neither should reveal Miro solely because of proximity/corpse contact.
- [ ] Face a guard briefly, remain exposed, then break sight. Check suspicion, confirmed detection, search at the last seen location, and return to patrol.
- [ ] Test guard vision from behind, beyond range, through walls, above/below platforms and beside doors. Check perceived cone versus actual detection at edges.
- [ ] Let a guard discover a body without seeing Miro. It should investigate the body, not track an unseen moving player magically.
- [ ] Verify concealed movement does not grant immunity to physical contact or incoming attacks. A body discovered elsewhere must not itself reveal Miro.
- [ ] Complete a nonlethal route without damage or confirmed detection. Record whether waiting for cooldown is understandable and enjoyable.

### Terminal, cameras and sealed access

- [ ] On Floor 3, observe both camera sweeps and visible cones. Test exposed player, concealment and wall occlusion.
- [ ] Trigger a camera alert. Keepers should investigate the reported location; verify guards do not gain continuous hidden-player tracking.
- [ ] Start terminal hacking with E. It must take one second; repeated E must not complete it instantly.
- [ ] Leave interaction range before completion, then return. Interrupted work must restart rather than grant camera/gate completion.
- [ ] Pause during the hack, resume, then finish/skip completion dialogue. Both cameras disable; checkpoint collision opens after the completion milestone.
- [ ] Retry Floor 3 and verify cameras, terminal and gate return to their entry state.
- [ ] On Floor 4, try the ward release before reading records. Then read records, operate the release and physically cross the opened seal.

### Pause, dialogue, menus and feedback

- [ ] Pause/resume while running, midair, cloaked, cooling down, during dialogue, hacking, boss telegraphs/projectiles and the ending. Nothing should progress unexpectedly.
- [ ] Resume without a movement burst, skipped dialogue line, extra interaction or immediately completed timer.
- [ ] Inspect every dialogue speaker and long passage. No cropped text, overlapping speaker panel or hidden continue/skip prompt.
- [ ] Compare finishing dialogue naturally with Tab skipping. Identical required flags; movement always returns when appropriate.
- [ ] Verify Enter descends only after completion and returns to a new run after the ending; R retries the current floor.
- [ ] **Level menu deliverable:** record as NOT IMPLEMENTED. Agree the desired level-list, back/resume, restart, and locked/unlocked behavior before implementation; distinguish a debug picker from normal campaign progression.
- [ ] Test mute with M during play and pause; restart the application to verify the preference. Listen for excessive volume, overlapping effects or missing feedback.
- [ ] Check at multiple window sizes and the PC's normal display scaling; validate readable HUD/controls and stable performance.

### Boss, ending and exported build

- [ ] Final sigil and final offer precede the boss. Repeated E must not spawn another brother.
- [ ] Identify both attack tells, evade rush/projectile, and hit during recovery. Guarded phases should reject shank and gun damage.
- [ ] Defeat triggers the fatal exchange once, with no second combat phase. Projectiles stop after defeat; continue to the viewpoint.
- [ ] Watch the ending fully, then retry and skip it. Both commit the boss/ending flags and cannot retrigger the sequence accidentally.
- [ ] Verify the five matching marks, collapse, head bow and fade communicate the action without a moral-resolution epilogue.
- [ ] Repeat a continuous run in the normal Windows release, not only the editor or QA executable. Record hardware, frame-rate issues and any missing packaged assets.

## Automated evidence and limits

At the baseline commit, 13 source test suites passed, release startup was checked on all five floors, and a separate exported QA build completed a 64-check continuous run. These are prior engineering results, **not a substitute for Fran's manual sign-off**.

| Command | What it verifies |
| --- | --- |
| `./Run Checks.ps1` | Escape routes, natural-patrol nonlethal run, controls, scaffold integrity, later-floor traversal, security, boss, ending, gates/loot, timed stealth, dialogue layout and audio assets |
| `./Build Windows.ps1` | Builds normal Windows release |
| `./Check Windows Build.ps1` | Starts each floor in the normal release; checks logs and expected floor marker |
| `./Check Exported Playthrough.ps1` | Builds QA export; traverses all five floors through actual scene transitions, defeats boss and watches ending; confirms five sigils and outcome |

Logs are under `tmp/` and are ignored by Git. Attach relevant excerpts to the playtest report. The QA runner is `tools/export_playthrough.gd`, gated by the `qa` export feature and excluded from the normal release. Headless runs validate audio resources but do not audition their mix.

## Deliverables and known unfinished work

- [ ] Fran supplies a completed [playtest report](PLAYTEST_REPORT_TEMPLATE.md), including the exact commit/build and test date.
- [ ] Every failure has reproducible steps, expected/actual behavior, floor/location and evidence; distinguish blockers from polish feedback.
- [ ] Provide one recorded continuous release playthrough and one nonlethal/stealth attempt, or clearly mark either not run.
- [ ] Resolve blanket activation intent: shadows required, shadows preferred, or anywhere as currently implemented. Also approve/tune duration, recharge and movement penalty.
- [ ] Define and implement the missing level menu in a follow-up task; do not mark development shortcuts as the finished UI.
- [ ] Re-run relevant tests after fixes and provide before/after results. Full campaign/build verification is required for progression or packaging changes.
- [ ] Review final room layouts, NPC/guard/boss portraits and animation, music/voice, cinematic production and difficulty. Current shapes, dialogue and repeated three-tier layouts remain provisional.
- [ ] Decide inventory/health/casualty continuity and whether a disk save is required; neither should be assumed from the current in-memory campaign tracker.
- [ ] Settle the still-open narrative decisions in `mirospec.md` (specific treason, illness evidence, remaining tower occupants, sigil capability) before treating draft text as final.
- [ ] Deliver a rebuilt release plus changelog when approved; source commits alone do not distribute the ignored executable.

## Reference priority and documentation inventory

Read [current gameplay decisions](GAMEPLAY_DECISIONS.md), [intro guide](INTRO.md), [Level 1 source map](LEVEL_01_SCAFFOLD.md), [Levels 2–5 source map](LEVELS_02_05.md), and [setup](SETUP.md). The original supplied references remain [class guide](class.md), [specification](mirospec.md), [meeting 1](miromeeting1.md), [meeting 2](miromeeting2.md), and [reference PDF](miroguide.pdf).

Explicit current user direction takes priority over historical docs. Record conflicts rather than pretending both versions describe implemented behavior. During this handoff, every file in `C:\towerdefense\docs` was compared with the repo copy; all matched, including the user-saved `LEVELS_02_05.md`. No supplied document was missing or overwritten.
