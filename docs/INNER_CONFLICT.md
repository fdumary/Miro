# Inner conflict: reactive paintings, two-option replies, lore terminals, verses

Ethan's idea (7 Nov 2026): Miro has two ways of answering people, and together with how he plays
(stealth or offense) that picks the artwork the player sees through the tower. The paintings
represent Miro's inner conflict. The tree stays simple and never changes the story.
Full art direction: `artspec.md` (Ethan's spec, in the project uploads).

## How it fits the existing branches

`MISSING / HUNTED` (`data/branch_reactions.json`) is how the **tower** reacts to Miro.
The inner conflict is how **Miro** sees the tower. They read the same play but are separate:

| Side | Leaning | What feeds it |
|---|---|---|
| Quiet | **ghost** | finishing a floor unseen (+3), unseen pickpockets (+1, max 3), quiet replies |
| Quiet | **blackhat** | each camera turned off (+3, max 2 per floor), the checkpoint console (+2) |
| Quiet | **seeker** | reading a records terminal (+2, max 2 per floor), looking at the painting (+1), asking replies |
| Loud | **defiant** | each kill (+2, max 2 per floor), a loud breach (+2), angry replies |
| Loud | **survivor** | breaking a chase and living (+2, max 2), finishing an objective at 1 heart (+2), hard replies |

Replies are worth +2 each, so they matter as much as a kill or an escape, but play decides most runs.
Scores only count once a floor is completed, so a retry restores the entry state (same as Campaign).

## The pieces

- `scripts/player_behavior.gd` (autoload **PlayerBehavior**): scores, the branch rule (artspec §4.3:
  unique leader wins, a tie keeps the previous pick, otherwise neutral), `side()` quiet/loud/torn,
  `ending_line()` for an optional ending panel ("They never saw him leave." etc.).
- `scripts/inner_conflict.gd`: attached to every level scene by the autoload, so `intro_level.gd`,
  `scaffold_level.gd` and `campaign.gd` need no hooks. It reads `level.dialogue`, `dialogue_index`,
  `dialogue_panel`, `player`, `areas`, `world_features` and `Campaign.floor_stats`.
- **Replies** (`data/dialogue_choices.json`): 8 choices, two per floor on 1–4. Each is spliced in after
  a line whose text contains its anchor. Miro's bubble shows `[1]` and `[2]`; 1/2 or W/S picks, E confirms
  (E alone takes option 1, so routes and tests never stall), Tab still skips. The chosen reply replaces the
  choice line, an optional one-line reaction follows, and the scene continues as written.
- **Paintings** (`data/art_catalog.json`, `data/art_branch_matrix.json`, `scripts/art_frame.gd`):
  one frame per floor. Floors 1–4 hang it near the stair gate and pick the painting when Miro first
  comes within 420 px (off screen), from completed floors plus this floor so far. Floor 5 hangs it in
  Niro's office and picks on arrival, from the whole run. E shows the image large, then a short
  prison-authored line scratched into the frame (original copy, never attributed to the artist).
- **Lore terminals** (`data/terminal_logs.json`, `scripts/lore_terminal.gd`): 8 logs across the floors
  about Prisoner M-07, which reveal in the Ward's own records that he is also a test subject (intake record, behaviour log, roster, camera audit, revoked access, sample
  draws, the Board memo, an unsigned note in the office). Rules: no immunity, no lab origin, no Niro or
  "brother" before L5's face-to-face reveal, no "former Keeper" before L3's personnel record.
- **Verses** (`data/branch_verses.json`): one KJV exchange per floor (L2–L4) joins the Keepers'
  overheard conversation, picked by Miro's leaning (e.g. ghost: Psalm 139 "whither shall I flee";
  defiant: Matthew 26:52 "they that take the sword"; seeker: John 8:32). Uses
  `world_features.add_casual_lines()` when present.
- Placement is data-driven and self-correcting: each prop snaps to the floor and steps sideways until
  it is clear of stations, ladders, props and the stair gate, so geometry changes don't break it.
- **F9** in a debug build shows the five scores, the leaning and the floor's painting.

## Art rights (the release gate)

No image is bundled from this cloud session: the museum sites are blocked here. Run locally:

```
.\Fetch Art.ps1          # or: python tools/fetch_art.py
```

It reads each source's own rights field (Met `isPublicDomain`, NGA open-access flag, AIC
`is_public_domain`, Commons licence) and only then saves the image to `assets/art/`, writing
`data/art_rights.json` and `docs/art_rights_manifest.csv` (the spec's columns). Files that need a
human call (e.g. the Giotto file's CC BY-SA photo licence) are marked `rejected` with the reason.
The game shows a painting only when its entry is `verified` and the file exists; otherwise the slot's
neutral painting, otherwise a frame under a dust sheet whose brass plate still names the work.
Open Godot once after fetching so the images import. Commit `assets/art/*.jpg`, `data/art_rights.json`
and the manifest together.

## Tests

`tools/test_inner_conflict.gd` (added to `Run Checks.ps1`): data coverage (27 works, 12 themes),
spoiler rules for the logs, the branch rule and caps, a reply splice on Level 1 with both options,
reading a terminal, the covered fallback, commit and retry, and prop placement on all five floors.
