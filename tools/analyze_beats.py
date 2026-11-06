"""Offline, repeatable estimates. Originals are decoded read-only through FFmpeg.
Install tools/audio-analysis-requirements.txt in a virtualenv; requires ffmpeg/ffprobe.
"""
import argparse
import hashlib
import json
import subprocess
import warnings
from pathlib import Path

import librosa
import numpy as np

NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
PROFILES = {
    'major': np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]),
    'minor': np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]),
}

def key_candidates(chroma):
    candidates = []
    for mode, profile in PROFILES.items():
        for root in range(12):
            correlation = float(np.corrcoef(chroma, np.roll(profile, root))[0, 1])
            candidates.append({'key': f'{NOTES[root]} {mode}', 'correlation': round(correlation, 4)})
    return sorted(candidates, key=lambda x: x['correlation'], reverse=True)[:3]

def analyze(path):
    metadata = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_format', '-show_streams', '-of', 'json', str(path)]))
    stream = next(s for s in metadata['streams'] if s['codec_type'] == 'audio')
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
        '-f', 'f32le', '-ac', '1', '-ar', '22050', '-'])
    audio = np.frombuffer(raw, dtype='<f4')
    sr = 22050
    duration = len(audio) / sr
    windows = []
    chromas = []
    # Three evenly spaced windows, up to 30s each; no claim of full-song beat grid.
    width = min(30., duration / 3)
    for start in np.linspace(0, max(0, duration - width), 3):
        y = audio[int(start * sr):int((start + width) * sr)]
        if not len(y) or np.max(np.abs(y)) < 1e-6:
            continue
        harmonic, percussion = librosa.effects.hpss(y)
        envelope = librosa.onset.onset_strength(y=percussion, sr=sr)
        tempo, beats = librosa.beat.beat_track(onset_envelope=envelope, sr=sr)
        bpm = float(np.asarray(tempo).item())
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter('always')
            chroma = librosa.feature.chroma_stft(y=harmonic, sr=sr, n_fft=4096).mean(axis=1)
        chromas.append(chroma)
        keys = key_candidates(chroma)
        windows.append({'start_seconds': round(float(start), 2), 'length_seconds': round(width, 2),
            'bpm': round(bpm, 2), 'tracked_beats': len(beats), 'key_candidates': keys,
            'analysis_warnings': [str(w.message) for w in caught]})
    if not windows:
        raise ValueError(f'No usable non-silent windows: {path}')
    # Fold octave-related tempo estimates into the 70–140 BPM comparison range.
    def fold(bpm):
        if bpm <= 0:
            return None
        while bpm < 70: bpm *= 2
        while bpm >= 140: bpm /= 2
        return bpm
    folded = [fold(w['bpm']) for w in windows if w['bpm'] > 0]
    bpm = float(np.median(folded)) if folded else None
    keys = key_candidates(np.mean(chromas, axis=0))
    votes = sum(w['key_candidates'][0]['key'] == keys[0]['key'] for w in windows)
    gap = keys[0]['correlation'] - keys[1]['correlation']
    return {'filename': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'duration_seconds': round(duration, 2), 'sample_rate': int(stream['sample_rate']),
        'channels': stream['channels'], 'codec': stream['codec_name'],
        'bpm_estimate': round(bpm, 2) if bpm else None,
        'half_time_bpm': round(bpm / 2, 2) if bpm else None,
        'double_time_bpm': round(bpm * 2, 2) if bpm else None,
        'tempo_window_spread_bpm': round(max(folded) - min(folded), 2) if folded else None,
        'key_candidates': keys, 'key_window_agreement': f'{votes}/{len(windows)}',
        'key_review': 'provisional' if votes == len(windows) and gap >= .08 and keys[0]['correlation'] >= .65 else 'ambiguous — audition required',
        'windows': windows}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path('soundselection/beats'))
    parser.add_argument('--output', type=Path, default=Path('data/music/beat_analysis.json'))
    args = parser.parse_args()
    tracks = []
    for path in sorted(args.source.iterdir()):
        if path.suffix.lower() not in {'.wav', '.mp3', '.ogg', '.flac'}: continue
        print(f'Analyzing {path.name}', flush=True)
        tracks.append(analyze(path))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps({'method': 'Three up-to-30s windows; HPSS percussion/onset beat tracking; harmonic STFT chroma correlated with Krumhansl major/minor profiles. Tempo octave-folded to 70–140 BPM for comparison; not a verified performance tempo. Correlations are not probabilities. No manual audition or beat-grid verification performed.',
            'librosa_version': librosa.__version__, 'rights': 'Ethan states these are his original compositions and grants full permission for game use (2026-11-06).',
            'tracks': tracks}, indent=2, ensure_ascii=False) + '\n')
    print(f'Analyzed {len(tracks)} tracks → {args.output}', flush=True)

if __name__ == '__main__': main()
