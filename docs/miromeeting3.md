## Key Concepts

- Add reusable stealth and combat encounters: security cameras, alerted guards, turrets, drones, traps, and projectile dodging.
- Let players optionally disable cameras through terminal/panel puzzles, potentially using passwords discovered in guard dialogue.
- Expand immersion with voiced guard dialogue, lore clues, ambient music, level-based music transitions, notes, and environmental Easter eggs.
- Reuse existing or asset-store content wherever possible; keep new assets simple and modular.
- Preserve the brother storyline while simplifying its implementation through dialogue, a remote device, and a recolored/modified Miro sprite.
- Prioritize core gameplay, including attacks, stealth, dodge, aiming, movement, and a final boss encounter.
- Target game completion by Sunday, followed by bug fixing, playtesting, and polish on Monday.

## Worked Examples

- If Miro leaves a camera’s line of sight while maintaining stealth, the camera does not trigger an alarm. If Miro is revealed, additional guards spawn or respond.
- A terminal can be optional: a password heard in guard dialogue lets the player hack it and disable or manipulate security systems.
- The dodge should move Miro rapidly forward near the ground while using the existing jump-frame sprite.
- A turret can fire projectiles that require the player to dodge while moving through a level.
- The brother can communicate through a simple hacking remote and appear as a recolored version of Miro rather than requiring a complex new character.

## Quick Checks

- Confirm all recent changes are pushed to and pulled from the correct organization repository.
- Verify music transitions, dialogue triggers, stealth cooldowns, weapon bindings, C4 placement/detonation, and level restart behavior.
- Test whether the brother dialogue and final encounter are understandable and achievable within the remaining schedule.
- Check that movement supports required traversal, including ladders, returning to upper areas, and possible wall-slide or climb behavior.
- Identify which props can come from the existing asset library before creating new assets.
- Ensure credits, final packaging, and a downloadable release option are planned after the game-jam build.

## Decisions

- Implement security cameras that detect Miro and alert additional guards when stealth fails.
- Add optional terminal or panel hacking, potentially unlocked by passwords found in guard dialogue.
- Create or source reusable assets for cameras, turrets, drones or robots, and traps, while minimizing custom asset work.
- Use existing or asset-store content for supplementary props whenever it fits.
- Use the existing jump animation frame for a forward ground-level dodge.
- Continue the brother storyline in a simplified form using dialogue, a remote device, and a modified Miro sprite.
- Include a final boss encounter, while keeping its implementation lightweight enough for the schedule.
- Prioritize the basic character attack before optional features such as the scythe.
- Program cutscenes in Godot rather than paying for an external cutscene tool.
- Aim to finish the game by Sunday and reserve Monday for testing, bug fixes, and polish.
- Explore mouse aiming and a simple pistol or gun implementation.
- Treat mushrooms as background decoration rather than power-ups.

## Risks

- The remaining schedule may not support fully implementing the brother storyline, meaningful dialogue, and a final boss encounter.
- Movement and traversal gaps, including ladders, returning to upper platforms, wall sliding, or climbing, may block progression.
- Recent playtesting exposed bugs involving bindings, stealth cooldowns, C4 behavior, level restarts, dialogue, and missing animations.
- Asset creation could consume too much time if suitable reusable or asset-store content is not found.
- The team may have limited testing capacity because one contributor is unavailable or balancing other projects.
- Music transitions and voice integration have been added but still need thorough playtesting.
- Repository confusion or incorrect push/pull targets could cause team members to miss changes.
- The game-jam presentation and submission requirements are not yet confirmed.
- Microphone issues and communication interruptions may hinder coordination and testing.

## Recommendations

- Implement security cameras with stealth detection, line-of-sight behavior, and guard alerts when the player is revealed.
- Add optional camera-disabling terminals or panel boxes using a simple hacking puzzle.
- Create or source reusable assets for turrets, cameras, drones, and traps, prioritizing existing asset-store resources where suitable.
- Continue development of the character's basic attack and determine whether a simple pistol asset can be created or sourced.
- Modify the dodge to use the jump sprite while keeping the movement close to the floor and moving rapidly forward.
- Add mouse aiming and shooting behavior when the player has the gun equipped.
- Implement or refine guard dialogue and voice lines that can provide lore, clues, and terminal passwords.
- Create a simple visual representation for the brother, such as a recolored and slightly modified version of Miro, and support communication through the remote.

## Action items

- [ ] Create reusable security camera, turret, drone, and trap assets for the game, using existing asset-store resources where appropriate.
- [ ] Implement gameplay interactions for security cameras, including stealth line-of-sight detection, player reveal behavior, and guards being alerted.
- [ ] Add optional terminal or panel-box hacking as a puzzle, potentially using passwords revealed through guard dialogue.
- [ ] Continue implementing the character's basic attack.
- [ ] Implement or refine the dodge using the jump sprite while keeping the character close to the floor and moving forward quickly.
- [ ] Complete the character animations. — Fran
- [ ] Play through the latest game build from a player perspective and identify bugs or improvement opportunities. — Fran
- [ ] Pull the latest repository changes and test the updated music, dialogue, assets, and gameplay.
- [ ] Replace or integrate the new assets into the game.
- [ ] Implement cutscenes in Godot rather than using an external tool.
- [ ] Create or integrate a simple visual design for the brother character, potentially using a recolored and modified version of Miro.
- [ ] Add or refine the brother's communication dialogue and remote interaction, including his appearance in the final boss-fight sequence.
- [ ] Develop a final boss fight for the end of the game.
- [ ] Flesh out the game, verify that levels work, and complete the game by Sunday.
- [ ] Test and polish the game, fix bugs, and ensure overall stability on Monday.
- [ ] Implement mouse aiming and gun functionality so players can aim when the gun is equipped.
- [ ] Look for suitable gun, turret, drone, robot, and other supplemental assets in the existing asset store and share references.