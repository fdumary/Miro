"""Offline coverage/signature audit. Does not contact the speech provider."""
import hashlib, importlib.util, json, re, sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('miro_voice_jobs', root / 'tools/generate_voices.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
cast = json.loads(module.CAST.read_text(encoding='utf-8-sig'))
jobs = module.collect_lines(cast)
records = json.loads((module.OUT / 'provenance.json').read_text(encoding='utf-8-sig'))
missing, stale = [], []
for job in jobs:
    voice = cast['voices'][job['voice']]
    words = re.sub(r'\([^)]*\)', '', job['text'])
    body = {'text': (job['delivery'] + ' ' + words).strip().replace('\n', ' '), 'model_id': cast['model_id'], 'voice_settings': {'stability': voice.get('stability', 0.5), 'similarity_boost': 0.75, 'use_speaker_boost': True}}
    signature = hashlib.sha256(json.dumps({'voice': voice['voice_id'], **body}, sort_keys=True).encode()).hexdigest()
    if not (module.OUT / (job['clip'] + '.mp3')).is_file():
        missing.append(job['clip'])
    elif records.get(job['clip'], {}).get('signature') != signature:
        stale.append(job['clip'])
(root / 'tmp').mkdir(exist_ok=True)
(root / 'tmp/voice-expected.json').write_text(json.dumps([job['clip'] for job in jobs]))
print(json.dumps({'expected_lines': len(jobs), 'missing': missing, 'stale': stale, 'result': 'PASS' if not missing and not stale else 'FAIL'}))
sys.exit(1 if missing or stale else 0)
