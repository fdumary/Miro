# Cutscene scripts

Every cutscene in one place: what is on screen, what is said, how long it runs. Shot-by-shot timings for the opening, MP3 pickup, ending and finale live in [CUTSCENE_HOOKS.md](CUTSCENE_HOOKS.md); the code is under `scripts/`. All cutscenes are in-engine, letterboxed, subtitled, and skippable with Tab (Enter or Esc where noted); skipping gives the same progression as watching.

## C1 Opening (15 s) — `opening_cinematic.gd`
A storm over the woods, a bolt strikes the far tower, the camera tilts up through the rain to cell 07's window, Miro sits up on the thunder. Title card: MIRO / Last Man Standing. PA line: tower announcement over the rain.

## C1b MP3 pickup (2.8 s) — `remote_pickup_card.gd`
Close-up as Miro takes the MP3 player (the remote) off the first Keeper; its screen wakes to PLAY. Does not pause play.

## Between-level interludes (12 s each) — `interlude_cinematic.gd`
One shared scene: the tower at night with one more sigil lit per finished floor, Miro in the rain, the remote glowing while the voice speaks (subtitled, and voiced where a clip exists), then Miro's thought and the next level's title. Shown after the floor report when the player presses Enter to descend. The voice is "THE VOICE" until Niro's name is revealed on Level 3, then "NIRO".

| After | Speaker | Voice line | Miro's thought | Next title |
|---|---|---|---|---|
| Level 1 | THE VOICE | "You have the remote. Keep it close, and keep quiet." | "Someone is guiding me down. I should find out why." | LEVEL 2 |
| Level 2 | THE VOICE | "If you go any lower, I can't protect you." | "From who?" | LEVEL 3 |
| Level 3 | NIRO | "Now you know my name. Please, stop at the records." | "Brother. The word feels true, and I hate that." | LEVEL 4 |
| Level 4 | NIRO | "Don't come down here, Miro. Please." | "The seals, the supports. Everything rests on the floor below." | LEVEL 5 |

These lines have no ElevenLabs clips yet (no new voice generation was spent on them); they play as subtitles with the remote's glow and the sigil sound. Variations by MISSING/HUNTED reputation can read `Campaign.reputation()` (see CUTSCENE_HOOKS.md, Branch text).

## C2 Niro appears (Level 3 and Level 5)
Name card NIRO in the lower third while the reveal plays in-game (dialogue scripts: `data/levels/level_03.json` station `BrotherReveal`, `data/levels/level_05.json`).

## C5 Alarm (Level 5)
Red alarm pulse and ALARM when the guitar is taken.

## C10 Tower explosion and ending (15 s) — `ending_cinematic.gd`
Miro steps out of the tree line, the C4 trigger fills the screen, sigils ignite bottom to top, the PA line, detonation with chained blasts and the tower falling, Miro lowers his head, title card.

## Finale — `finale.gd`
The beach at dawn ("Finally free."), then the credits from `data/credits.json` over Set Me Free.
