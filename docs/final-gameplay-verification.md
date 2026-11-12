# Final gameplay pass — Windows verification

- Guard crossings, last-seen pursuit, Niro recovery phases and safe spawn placement updated.
- Existing ward flasks converted to pickups; story interactions take precedence over healing.
- Turrets retain legacy security/checkpoint identity after wall mounting.
- Ending moved to the existing final door; it owns the interaction even beside loot.
- 101 matching lost-target recordings queue by speaker. All 935 expected voice clips pass coverage.
- Fresh-profile title startup no longer awards Level 1 before play.

Validation on Windows: 80 configured regression checks pass (resumed after updating obsolete C4 and tonic-priority expectations); final gameplay 88/88; real-map guard queues 21/21; guard intelligence 19/19; full boss/door route 49/49; exported five-floor playthrough 38/38; native dialogue/audio assertions 39/39; all five retail floor startups and icon checks pass. Native audio test teardown reports retained resources; the retail startup/exit logs are clean.

Fresh retail profile creates no progress at title. An isolated copy of the existing profile retains all 43 achievements; original progress.cfg hash is unchanged. ZIP CRC and extracted executable SHA-256 match the tested release. Evidence and logs: `tmp/final-pass/` (27 real-map location/queue screenshots). Original marked-view attachments were not available in this continuation; placements were checked against current map geometry and captured views.
