# Music section plan and A/B listening test

Updated November 6, 2026. Status: candidate placements, not final runtime selections.

## Current direction

A level can contain several tracks. Author changes around landings, atmosphere, story beats and encounter boundaries; do not stretch a chapter simply to finish a song. The slots below are starting candidates for a chapter's musical identity, not a one-track cap. A/B refers to comparative playtests, not stealth/offense branches or randomized playback.

Ethan confirms that the supplied beats are his original compositions and grants full permission to use them in the game. Keep source names unchanged; runtime titles can differ. This statement applies to the supplied compositions, not future third-party samples/assets whose rights have not been specified.

## Candidate sequence A

- Intro: `YZ33.mp3` — supplied and added November 6, 2026. This is distinct from `YZ2.mp3` and `birthday melody YZ.mp3`.
- Level 1: selection open. Ethan removed “new beat” from consideration; no replacement is assumed.
- Level 2: `DOPE2.mp3`.
- Level 3: `sum crazy shi_3.mp3`.
- Level 4: `plane drums nig.wav` or `cyberpunk_2.mp3`; compare these separately.
- Level 5: `robot attack.wav`.
- Outro: emotional chord progression — intended cue/composition, exact file unresolved.

## Candidate sequence B

Keep intro, Level 1, Level 5 and outro as above. Compare these chapter candidates:

- Level 2: `BOBBLEHEAD2.mp3`.
- Level 3: `DOPE2.mp3`.
- Level 4: `swag.wav`.

Additional contender: `shit crashed 2.wav`; chapter and section assignment remains open. Bobblehead and Swag are both named contenders and sequence-B candidates.

## Multiple tracks within a level

Start with region roles such as approach/exploration, pressure/encounter and aftermath/reveal where the authored level supports them. These are roles, not three mandatory tracks in every chapter. For example, compare Level 3's Sum Crazy Shi versus DOPE 2 over the same checkpoint section, then consider whether one belongs in the approach and the other in the conflict. No final order is assigned without listening.

A region should carry an ordered list of eligible track IDs, entry/exit triggers and transition policy. Stealth/offense unlock requirements determine availability separately from its A/B test label. Manual selection retains priority over suggestions. Returning across a landing must not restart or cycle tracks repeatedly. Boss, fatal exchange and outro need one authored transition sequence.

## Fair comparison procedure

1. Use the same recorded traversal/combat/dialogue for A and B; keep effects and playback gain consistent and loudness-match excerpts before preference scoring.
2. Compare each section independently before comparing the whole chapter. Alternate presentation order so A is not always first.
3. Record listener, sequence, chapter/region, source excerpt timestamps and gain adjustment. Rate atmosphere, movement flow, dialogue/attack readability and transition feel; keep freeform notes.
4. Test both Level 4 candidates separately so a choice between Plane Drums and Cyberpunk is not confused with the A-versus-B comparison.
5. Use estimated tempo/key to propose transition points, then check beat phase, downbeats and harmonic overlap by ear. Half/double-time tempo readings and relative keys can be ambiguous.
6. Approve section assignments, runtime excerpts and loops only after this audition. No A/B playback, normalized preview or human listening result is claimed yet.

## Analysis and next tasks

`tools/analyze_beats.py` provides reproducible metadata and provisional tempo/key estimates in `data/music/beat_analysis.json`. It uses FFmpeg plus Librosa in an isolated Python environment; originals remain unchanged. The report records the method, source hashes, window-level alternatives and uncertainty. It is not a verified beat grid or a final musical-key transcription.

1. Finish automated analysis and review ambiguous tempo/key estimates with the composer.
2. Identify the intended outro file and choose Level 1 section music; YZ33 is now supplied and “new beat” is excluded.
3. Audition chapter sections using the A/B procedure and record exact excerpt markers.
4. Feed approved track/region choices into MUSIC-01 and MUSIC-05 in the implementation handoff. Gameplay progression, pickup and branch scoring remain separate ordered tasks.
