# Cutscene scripts

Every cutscene in one place: what is on screen, what is said, how long it runs. Shot-by-shot timings for the opening, MP3 pickup, ending and finale live in [CUTSCENE_HOOKS.md](CUTSCENE_HOOKS.md); the code is under `scripts/`. All cutscenes are in-engine, letterboxed, subtitled, and skippable with Tab (Enter or Esc where noted); skipping gives the same progression as watching.

## C1 Opening (15 s) — `opening_cinematic.gd`
A storm over the woods, a bolt strikes the far tower, the camera tilts up through the rain to cell 07's window, Miro sits up on the thunder. Title card: MIRO / Last Man Standing. PA (Daniel, calm broadcaster): "Lights out. Cells sealed. Report every cough, including your own." (`opening_pa` in data/interludes.json).

## C1b MP3 pickup (2.8 s) — `remote_pickup_card.gd`
Close-up as Miro takes the MP3 player (the remote) off the first Keeper; its screen wakes to PLAY. Does not pause play.

## Between-level interludes (about 22 s each) — `interlude_cinematic.gd`, lines in `data/interludes.json`
A split-screen call over the MP3: Miro inside the tower on the left (cell bars, torchlight, the MP3 glowing), his brother on the right at his desk. The speaker's side lights up and the scene waits for every clip, so each line plays in full. Until Level 3 reveals his name the brother is a dark shape marked UNKNOWN CALLER ("THE VOICE"); from Level 3 on he is Kael (Julia's sprite) and labelled NIRO. Shown after the floor report when the player presses Enter to descend; Tab / Enter / Esc skips.

**After Level 1** (next: LEVEL 2)

- THE VOICE: "You have the remote. Keep it close, and keep quiet."
- MIRO: "Who is this? How do you know my name?"
- THE VOICE: "Someone who wants you out alive. Go down. The coughing started on the floors below, and it is spreading."
- MIRO: "Someone is guiding me down. I should find out why."

**After Level 2** (next: LEVEL 3)

- THE VOICE: "If you go any lower, I can't protect you."
- MIRO: "From who?"
- THE VOICE: "From what they keep in the records. The sickness did not start in the cells, Miro."
- MIRO: "Then where did it start?"
- THE VOICE: "Find the personnel records on three. You will understand why I kept calling you back."

**After Level 3** (next: LEVEL 4)

- NIRO: "Now you know my name. Please, stop at the records."
- MIRO: "You kept me in here, Niro. Was I sick too?"
- NIRO: "Not over a remote. Read what the ward kept, then decide what I am to you."
- MIRO: "Brother. The word feels true, and I hate that."

**After Level 4** (next: LEVEL 5)

- NIRO: "Don't come down here, Miro. Please."
- MIRO: "The seals, the supports. Everything rests on the floor below."
- NIRO: "Everything rests on what we kept down there. I never lied about the sickness. I only never told you whose it was."
- MIRO: "Then I'm coming down anyway."

The story beats: the voice sends Miro down toward the spreading cough (L1), warns that the sickness did not begin in the cells and points him to the personnel records (L2), reveals itself as his brother and asks him to read the ward's records first (L3), and admits he never told Miro whose sickness it was (L4). Level 5 pays that off: Miro is immune.

## C2 Niro appears (Level 3 and Level 5)
Name card NIRO in the lower third while the reveal plays in-game (dialogue scripts: `data/levels/level_03.json` station `BrotherReveal`, `data/levels/level_05.json`).

## C5 Alarm (Level 5)
Red alarm pulse and ALARM when the guitar is taken.

## C10 Tower explosion and ending (15 s) — `ending_cinematic.gd`
Miro steps out of the tree line, the C4 trigger fills the screen, sigils ignite bottom to top, the PA line, detonation with chained blasts and the tower falling, Miro lowers his head, title card.

## Finale — `finale.gd`
The beach at dawn ("Finally free."), then the credits from `data/credits.json` over Set Me Free.
