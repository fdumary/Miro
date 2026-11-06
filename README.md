# Miro
Miro's Tower Escape: Last One Standing

**Current focus:** [music mechanics handoff and ordered tasks](docs/MUSIC_MECHANICS_HANDOFF.md) — portable player pickup, stealth/offense points, beat unlocks and soundtrack branches (planned).

**Fran's playtesting:** [handoff and checklist](docs/FRAN_PLAYTEST_HANDOFF.md) · [report template](docs/PLAYTEST_REPORT_TEMPLATE.md) · [coding-agent prompt](docs/FRAN_AGENT_PROMPT.md).

Godot 4.7 / Forward+. Main scene: `scenes/intro.tscn`.

The playable first floor includes the cell opening, three escape choices, guard sight and searches, blanket stealth, combat, ladders, a sigil objective, and an intro completion screen.

See [intro guide](docs/INTRO.md) for controls, editing and verification. Use `Open Miro.ps1`, `Play Miro.ps1`, or the desktop shortcuts. Run `Run Checks.ps1` for the automated playthroughs.

The original movement sandbox remains in `scenes/asset_sandbox.tscn`.

All five floors now have editable scene scaffolds. See [Level 1 sources and authoring](docs/LEVEL_01_SCAFFOLD.md) and [Levels 2–5 sources and unfinished systems](docs/LEVELS_02_05.md). Launch a specific floor with `./Play Level.ps1 -Level 2`. Later floors contain draft dialogue and explicit mechanic/cinematic placeholders.

Playable milestone: linked five-floor progression, Level 3 sweeping cameras and one-second hacking, Level 5 two-attack boss and a skippable in-engine ending. Art remains provisional; see the per-floor guide for remaining work.

Latest controls: press **2** for 5-second mobile stealth (8-second cooldown, 55% speed); contact with a living guard reveals Miro. Dialogue uses a simpler bottom text/speaker panel. See [current decisions](docs/GAMEPLAY_DECISIONS.md). Build with `Build Windows.ps1`, then validate standalone startup using `Check Windows Build.ps1`.

Press **M** to toggle sound effects. `Check Exported Playthrough.ps1` verifies a continuous five-floor run in a separate QA export (64 checks), including the boss and watched ending.
