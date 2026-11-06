# Preliminary beat analysis

Measured locally November 6, 2026. Source: all 17 files in `soundselection/beats/`. Originals are unchanged, with SHA-256 hashes recorded per track. Ethan confirms the supplied compositions are his originals and grants full permission for use in the game.

## Read the results

The complete machine-readable report is [beat_analysis.json](../data/music/beat_analysis.json). The [section-based A/B plan](MUSIC_AB_PLAN.md) records placements separately. A chapter may use several tracks; analysis does not assign one song per level or make A/B labels into unlock branches.

Each track includes duration, source codec/sample rate/channels, estimated tempo, half/double-time alternatives, three window-level results and the three highest-scoring key candidates. A low key-profile correlation or disagreement between windows is a reason to audition, not proof of a key change. Correlations are not statistical confidence percentages.

Tempo is folded into a 70–140 BPM comparison range. For example, a displayed 71.78 can represent a roughly 143.56 BPM double-time feel. The onset tracker uses discrete frame intervals, so values such as 129.20 should not be mistaken for a producer-confirmed project tempo. Window spread is computed after half/double-time folding; a wide spread indicates conflicting rhythm estimates rather than a verified tempo change.

Most keys remain ambiguous. The method correlates harmonic chroma with major/minor templates; it cannot establish a definitive key from drum-heavy, sparse, chromatic or changing material. Tuning warnings are retained with the affected windows. No hand-checked downbeats, phrase boundaries, transition compatibility, loudness normalization or human listening results are claimed.

## Reproduce

Requires Python, FFmpeg and ffprobe. Use an isolated environment:

```sh
python3 -m venv /tmp/miro-audio-analysis-venv
/tmp/miro-audio-analysis-venv/bin/pip install -r tools/audio-analysis-requirements.txt
/tmp/miro-audio-analysis-venv/bin/python tools/analyze_beats.py
/tmp/miro-audio-analysis-venv/bin/python tools/test_beat_analysis.py
```

The script decodes each original to mono 22,050 Hz in memory and samples three evenly spaced windows of up to 30 seconds. HPSS separates harmonic/percussive components. Librosa onset beat tracking estimates tempo from percussion; harmonic STFT chroma is compared with rotated Krumhansl major/minor profiles. The script averages window chroma for overall key candidates and takes the median of folded window tempos. Full-length originals and Godot runtime assets are not rewritten.

Validation includes synthetic C-major pitch material, a known 120 BPM click train (within the frame-grid tolerance), complete source coverage, source hashes, finite correlations and valid report values. These checks verify basic pipeline behavior, not real-world musical accuracy.

## Next review

Ask the composer to verify project BPM/key for shortlisted tracks and resolve the outro source file and plan any additional Level 1 section music. YZ33 is supplied and intended for both the intro and Level 1; “new beat” is excluded. Audition A/B over identical gameplay excerpts, then choose region boundaries and runtime edits. Use short fades initially where harmonic overlap is questionable; do not claim key-compatible mixing from these estimates alone.
