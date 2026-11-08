# Miro: Last Man Standing

![Miro title screen: the tower at dusk](docs/images/menu_title.png)

**Miro** is a 2D pixel-art stealth platformer about escape, isolation and distrust. You play Miro, Prisoner M-07, who wakes in a cell at the top of a tower with no memory of how he got there. A sickness is spreading through the building, and the guards are coughing too. Miro has to get down five floors to the ground, sneaking past guards or fighting through them, and the tower reacts to which one he chooses. The tower itself is the antagonist: a power structure of ranks, rules and records that traps prisoners and guards alike.

![The tower in the storm, from the opening cinematic](docs/images/opening.png)

<p>
  <img src="docs/images/mp3_pickup.png" width="49%" alt="Floor 1: Miro takes the MP3 player off the guard">
  <img src="docs/images/rumour.png" width="49%" alt="Floor 2: If nobody sees me, I'm only a rumour">
</p>
<p>
  <img src="docs/images/symptoms.png" width="49%" alt="Floor 2: two Keepers talking about the transfer orders">
  <img src="docs/images/order.png" width="49%" alt="Floor 3: a Keeper quoting Isaiah on his rounds">
</p>
<p>
  <img src="docs/images/ward.png" width="49%" alt="Floor 4: Keepers talking about the sealed ward">
  <img src="docs/images/terminal.png" width="49%" alt="Reading Prisoner M-07's file on a terminal">
</p>
<p>
  <img src="docs/images/gallery.png" width="49%" alt="Inspecting a public-domain painting in the tower">
  <img src="docs/images/beats.png" width="49%" alt="The Beats screen: MP3 tracks unlocked by stealth and combat">
</p>
<p>
  <img src="docs/images/level_select.png" width="49%" alt="Floor select screen">
  <img src="docs/images/pause_controls.png" width="49%" alt="Pause menu with the controls">
</p>

## Tech stack

- **Engine:** Godot 4.7 (Forward+), written in GDScript, rendered at 640×360 and scaled up for pixel art
- **Levels and story:** JSON data in `data/`, with Python and GDScript tools that build the level scenes from it
- **Music:** original soundtrack by RXLA, played by a music director that also acts as a beat clock, so guards and waves move on the beat
- **Voices:** ElevenLabs (`eleven_v3`), generated at build time
- **Art:** original sprites and tiles by Julia, Kenney CC0 asset packs provided by Fran, and public-domain paintings with checked rights
- **Testing:** headless Godot test scripts (`Run Checks.ps1`) and a bot that plays through all five floors (`Check Exported Playthrough.ps1`)
- **Build:** Windows export with `Build Windows.ps1`

![Miro and Keeper sprites](docs/images/sprites.png)

To play from source, open the folder in Godot 4.7 or run `Play Miro.ps1` on Windows. Run `git lfs pull` after cloning to get the music.
