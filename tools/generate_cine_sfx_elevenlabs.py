"""Replace the synthesized cutscene sounds with ElevenLabs sound effects. Never ships credentials.

    python3 tools/generate_cine_sfx_elevenlabs.py --list     # prompts only, no key, no credits
    python3 tools/generate_cine_sfx_elevenlabs.py            # generate all cues (needs ELEVENLABS_API_KEY)
    python3 tools/generate_cine_sfx_elevenlabs.py thunder_near explosion_big   # only these

Writes assets/audio/cine/<cue>.ogg (ffmpeg converts the mp3 the API returns). The game loads
whatever file sits at that path, so a cue you don't like can be regenerated or reverted with
`git checkout`, or rebuilt as a placeholder by tools/synth_cine_audio.py.
Needs api.elevenlabs.io to be reachable (allowed in the project's cloud environment).
"""
import json, os, subprocess, sys, tempfile, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/cine'
API = 'https://api.elevenlabs.io/v1/sound-generation'

# cue: (prompt, seconds, loop)
CUES = {
    'rain_loop': ('Heavy night rain pouring on a pine forest and stone, steady downpour, no thunder, seamless ambience', 10, True),
    'thunder_near': ('Close lightning strike: sharp electric crack then a huge deep rolling thunder rumble, cinematic', 7, False),
    'thunder_far': ('Distant thunder rolling slowly across hills, low and soft, cinematic', 7, False),
    'explosion_big': ('Massive building demolition explosion: deep sub-bass boom, shockwave, crumbling concrete and stone debris falling, long rumbling tail, cinematic trailer impact', 9, False),
    'rumble_loop': ('Low ominous ground rumble, tremor building under a stone tower, deep sub bass, no music', 6, True),
    'fire_loop': ('Large fire burning a collapsed building, roaring flames and crackling wood, ambience', 8, True),
    'waves_loop': ('Gentle ocean waves washing onto a sandy beach at dawn, calm, seamless ambience', 12, True),
    'wind_loop': ('Soft wind gusting over a hill with pine trees and grass, evening ambience, no birds', 10, True),
    'gulls': ('A few seagulls calling over a quiet beach, distant', 4, False),
}


def api_key():
    key = os.environ.get('ELEVENLABS_API_KEY')
    env = ROOT / '.env'
    if not key and env.exists():
        for line in env.read_text().splitlines():
            if line.startswith('ELEVENLABS_API_KEY='):
                key = line.split('=', 1)[1].strip().strip('"\'')
    if not key:
        raise SystemExit('ELEVENLABS_API_KEY not configured (environment or .env)')
    return key


def generate(cue, key):
    prompt, seconds, loop = CUES[cue]
    body = {'text': prompt, 'duration_seconds': seconds, 'prompt_influence': 0.5}
    if loop:
        body['loop'] = True
    req = urllib.request.Request(API + '?output_format=mp3_44100_128', data=json.dumps(body).encode(),
                                 headers={'xi-api-key': key, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=180) as response:
        audio = response.read()
    with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp:
        tmp.write(audio)
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / f'{cue}.ogg'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp.name, '-af', 'loudnorm=I=-16:TP=-1.5',
                    '-c:a', 'libvorbis', '-q:a', '5', str(target)], check=True)
    os.unlink(tmp.name)
    print('wrote', target.relative_to(ROOT))


def main():
    args = sys.argv[1:]
    if '--list' in args:
        for cue, (prompt, seconds, loop) in CUES.items():
            print(f'{cue:14} {seconds:>3}s {"loop" if loop else "    "}  {prompt}')
        return
    cues = [a for a in args if a in CUES] or list(CUES)
    key = api_key()
    for cue in cues:
        generate(cue, key)


if __name__ == '__main__':
    main()
