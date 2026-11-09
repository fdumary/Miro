# Controller playtest fixes

Prompts follow the active input device from startup and hotplug. Controller input switches gameplay hints, dialogue continue/skip, objectives/notices, blanket status, death/floor reports and pause controls to controller buttons. Keyboard/mouse input restores keyboard labels; small stick drift does not switch them. PS4 uses Cross/Circle/Square/Triangle, L1/R1, L2/R2, Share, Options and Touchpad. Xbox-style formatting uses A/B/X/Y, LB/RB, LT/RT, View and Menu. Dialogue choice prompts use the D-pad.

D-pad Down opens a nearby terminal, matching the displayed console hint. Existing Share skips dialogue, Cross advances/interacts, and pause-menu buttons cover retry and level selection. Controller terminal text entry still uses the keyboard; this pass does not add a virtual keyboard.

Analog movement now stores facing as +1 or -1 instead of the stick's fractional strength. Movement speed remains analog; Miro no longer becomes paper-thin. Gun drawing, projectile direction and L2 focus reticle share the same aim calculation. The controller reticle follows the right stick instead of the mouse cursor; releasing L2 clears focus.

`tools/test_controller_prompts_and_aim.gd` covers the reported issues (15 checks). Existing PlayStation input, mouse projectiles and dialogue suites also pass. Rendered dialogue, aiming and pause-control previews are under tmp locally.
