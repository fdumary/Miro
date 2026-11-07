# Weapon upgrade tasks

Requested after updating the organization repository to `8de4093`.

## Meeting notes received

The supplied [meeting 3 notes](miromeeting3.md) are now preserved verbatim in the repository. They record intended behavior and reported problem areas, not reproducible bug reports or proof that every listed system is absent.

## Meeting gaps to verify

- **Bindings, stealth cooldown, C4 and retries:** reproduce each reported issue before changing the established rules. The notes provide no exact failure steps, so keep regression checks and new player-perspective observations separate.
- **Hacking scope clarification:** Ethan confirmed that Level 3 RemoteTerminal and its physical checkpoint gate remain mandatory story progression. Optional terminal/panel encounters apply before Level 3 where consistent with `mirospec.md`; do not add a bypass to the Level 3 gate.
- **Camera response:** current cameras direct existing guards to investigate. Additional reinforcement spawning is a separate missing behavior, requiring bounded spawn counts and authored positions; do not call current investigation reinforcement spawning.
- **Ground dodge:** use the existing jump-frame sprite during a rapid forward dodge near the ground. Validate collision, ladder entry/exit and action cancellation.
- **Traversal:** verify return routes to upper tiers, ladder transitions and required jumps. Wall-slide/climb are possibilities in the notes, not automatically mandatory new mechanics.
- **Brother:** retain the existing playable boss and Godot ending while reviewing dialogue clarity, remote representation and a modified/recolored Miro appearance. A new external cinematic tool is not needed.
- **Encounter library:** cameras already exist; turrets, drones and traps remain separate reusable encounter work. Scope these after basic attacks and weapon mechanics.
- **Assets and polish:** preserve Julia's keeper/crate artwork and decorative mushrooms; check inventory visibility, missing animations, music transitions and voiced conversations in actual play.
- **Delivery:** credits, submission requirements and downloadable release distribution need their own review. The notes' Sunday/Monday schedule is historical planning, not a newly assigned calendar deadline.

The explicit weapon request adds requirements beyond this meeting: three armed guard classes, two carried guns, mouse aim, visible projectiles/casings, flamethrower effects, inventory icons and three-use suppressors.

## Ordered implementation

1. **COMBAT-01 — Meeting bugs and asset inventory.** Import the meeting notes, reproduce reported problems, and inventory Julia's art and the licensed library. Locate suitable pistol, SMG, flamethrower, shank, C4, blanket, bullet, casing and flame assets. Preserve attribution and distinguish final art from placeholders.
2. **COMBAT-02 — Two-slot weapon inventory.** Model pistol, SMG and flamethrower separately with ammo/fuel and selected slot. Miro can carry at most two guns. Picking up a third opens an explicit replace-slot/cancel choice; never silently discard a gun. Display gun, blanket, shank and C4 icons and quantities. Preserve existing melee/explosive controls while defining weapon switching.
3. **COMBAT-03 — Mouse aiming and visible fire.** Aim in world coordinates through the camera transform. Implement muzzle position/direction, visible bullet travel or a tracer, muzzle flash and ejected casings. Sweep bullet collisions between frames to avoid tunneling; walls block shots and damage applies once. Casings are cosmetic, bounded and cleaned up. UI clicks must not fire weapons.
4. **COMBAT-04 — Three guard classes.** Equip light guards with pistols, assault guards with SMGs and heavy guards with flamethrowers. Give each clear visual/readable attack tells, range, cooldown and matching loot. Tune threats without silently redesigning level geometry.
5. **COMBAT-05 — Flame behavior.** Implement a visible short-range flame stream with wall occlusion, controlled damage cadence, fuel consumption and bounded effects. No suppressor compatibility. Do not assume persistent fire spread or destructible architecture is required.
6. **COMBAT-06 — Julia's crates and suppressors.** Use Julia's crate asset for accessible, sensible suppressor pickups. A suppressor has exactly three fired-shot uses; empty triggers do not consume it. Treat it as pistol-only for the first implementation: the user excluded flamethrowers and described SMG use as impractical. Document this interpretation for review. Suppressed shots should be silent to guard hearing; visual detection remains possible. This supersedes the existing reduced 90-unit noise prototype.
7. **COMBAT-07 — Audio and verification.** Distinct weapon firing effects, full unsuppressed guard-hearing events, quiet suppressed presentation, and flame audio. Verify both player and guard shots, walls, aim at different viewport sizes, two-slot replacement/cancel, burst consumption, exactly three suppressed rounds, flame restrictions, death/retry and campaign progression. Rebuild the review exports and update the handoff with actual results.

## Current implementation status

First combat increment: mouse motion enables world-space aiming; left mouse fires when gameplay input is available, while 4 retains the existing keyboard firing control. Visible swept bullets replace instant hit selection, stop at walls, damage the first struck guard and expire by range. Cosmetic casings eject and expire after 1.2 seconds. A project-native review pistol SVG is held by Miro; shank, C4, blanket and casing SVG assets are available for the inventory pass. These are authored placeholders, not Julia's artwork or third-party finds. Suppressor pickups use Julia's crate texture. Suppressed pistol shots now emit no AI hearing event. Dodge displays the existing jump sprite.

The new projectile checks cover travel-before-impact, impact damage, wall blocking and silent-shot charge consumption. Two-slot selection/replacement, inventory icon integration, three armed guard classes, SMG/flame behavior and weapon-specific sound design remain unfinished. Existing generic gun fields still represent the pistol; no SMG or flamethrower availability is claimed. Review exports have not been rebuilt for this increment.

Level 3's required terminal, password and checkpoint gate remain intact, matching the story spec and Ethan's clarification. Optional early-level encounters are a separate task.

