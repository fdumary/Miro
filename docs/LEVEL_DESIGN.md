# Level design: Levels 2–4 (7 Nov 2026)

Each level is two sub-floors, one per song, of three storeys each. The route snakes east, west, east, then west, east, west, so every storey is a short puzzle to read: a patrol to time, a camera to slip past, a crawlspace, a step that needs the double jump, or a raised office.

- **Source of truth:** `tools/level_layouts.py`. Run it, then `tools/build_remaining_levels.gd`.
- **Maps:** `docs/level_maps/level_0N.txt` (ASCII, one character per 28 px tile).
- **Nothing is random.** Placement is fixed: guards, patrols, cases, hiding spots and cameras. Even the background art comes from each storey's index.
- **Second song:** it starts when Miro lands on the first storey of the lower sub-floor (y > 672). On Level 4 it waits for the ward seal as well.
- **Authored route:** each level has one (`"route"` in the JSON). The tests and the exported playthrough follow it with real inputs: walk, auto-jump, crouch, ladders and E. A level that stops being completable fails the checks.
- **Z hints:** three per objective (`"hints"` in the JSON). Each press of Z is more direct: a nudge, then where, then exactly what to do. After a minute on the same objective, the bottom strip suggests Z.
- **Obstacles:** every storey has something to hop over (one-tile crates, bed frames, carts), double-jump over (two-tile stacks), crawl under (Left Ctrl) or climb onto (bunks, raised offices, the drying rack). 7 Nov night added 4 or 5 per level; the routes still pass.
- **Crates:** stand on top (one-way, on their own physics layer, so they never block a walk, a patrol or a sight line) or press E beside one to hide inside. Three on Level 1, one each on Levels 2–4 (`hide` with title `CRATE` in the layouts).
- **Off-duty huddle (Level 2, top floor, east end):** three Keepers over a Bible. Climb the bunk behind them for the ammo case.

| Level | Sub-floor A (song A) | Sub-floor B (song B) | Mechanics taught |
|---|---|---|---|
| 2 The Symptoms | Sick corridor (DOPE 2) | Barracks (Swag) | Shadows, crawling under the cell-block wall, double-jump step, service port and practice camera, laundry crates, top bunks (lie on them and Keepers below can't see you), lockers, trapdoor shortcut, raised office |
| 3 The Order | Approach and checkpoint (Bobblehead) | Security office, holding bars (Cyberpunk) | Two linked cameras, the overheard password, the terminal opens the checkpoint gate, an independent camera below, a pipe crawl, the raised office |
| 4 The Ward | Outer ward (Plane Drums) | Containment (Sum Crazy Shi) | Observation-sill crawl, the release gantry opens the ward seal, sealed doors, the isolation chamber, charges on two supports, a brace crawl |

Per-level looks (`scripts/scaffold_art.gd`):
- Level 2: infirmary cots and bottles, then lockers and laundry lines.
- Level 3: monitor banks, cabinets, pipes and warning lights.
- Level 4: observation glass, carts and flasks, then green specimen tanks and hazard signs.

Every floor keeps the tower's constants: the masonry shell, the barred windows onto the woods (the trees grow closer as Miro descends), the emblem, and the lights.
