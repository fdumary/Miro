"""Run with the audio-analysis virtualenv, from repository root."""
import hashlib
import json
import unittest
from pathlib import Path

import librosa
import numpy as np
from analyze_beats import key_candidates


class BeatAnalysisChecks(unittest.TestCase):
    def test_known_pitch_distribution(self):
        sr = 22050
        audio = np.concatenate([
            np.sin(2 * np.pi * librosa.midi_to_hz(n) * np.arange(sr // 2) / sr)
            for n in [60, 64, 67, 60, 64, 67, 60, 62, 65, 69, 71, 72]])
        chroma = librosa.feature.chroma_stft(y=audio, sr=sr, n_fft=4096).mean(axis=1)
        self.assertEqual(key_candidates(chroma)[0]['key'], 'C major')

    def test_known_click_tempo(self):
        sr = 22050
        audio = librosa.clicks(times=np.arange(0, 20, .5), sr=sr, length=sr * 20)
        onset = librosa.onset.onset_strength(y=audio, sr=sr)
        tempo, _ = librosa.beat.beat_track(onset_envelope=onset, sr=sr)
        self.assertLess(abs(float(np.asarray(tempo).item()) - 120), 4)

    def test_catalog_covers_unmodified_sources(self):
        report = json.loads(Path('data/music/beat_analysis.json').read_text())
        sources = {p.name: p for p in Path('soundselection/beats').iterdir()
                   if p.suffix.lower() in {'.mp3', '.wav', '.ogg', '.flac'}}
        self.assertEqual({t['filename'] for t in report['tracks']}, set(sources))
        self.assertEqual(len(report['tracks']), len(sources))
        for track in report['tracks']:
            with self.subTest(track=track['filename']):
                self.assertEqual(track['sha256'], hashlib.sha256(sources[track['filename']].read_bytes()).hexdigest())
                self.assertGreater(track['duration_seconds'], 0)
                self.assertGreaterEqual(track['bpm_estimate'], 70)
                self.assertLess(track['bpm_estimate'], 140)
                self.assertEqual(len(track['windows']), 3)
                for candidate in track['key_candidates']:
                    self.assertTrue(np.isfinite(candidate['correlation']))


if __name__ == '__main__':
    unittest.main()
