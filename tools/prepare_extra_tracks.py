"""Level the outro, completed-menu and MP3-unlock tracks into the runtime catalog.

Run from the project root after prepare_game_audio.py. Requires ffmpeg.
Leaves the nine level tracks untouched and appends these entries.
"""
import json
from pathlib import Path
from prepare_game_audio import level

EXTRA = {
    # id: (source file in soundselection/beats, role)
    'set_me_free': ('set me free_2.mp3', 'outro'),
    'lil_uzi2': ('LIL UZI2.mp3', 'menu_completed'),
    'birthday_melody': ('birthday melody YZ.mp3', 'mp3_unlock'),
    'pinkghost': ('not new jazz x pinkghost.mp3', 'mp3_unlock'),
    'jazzyhall': ('jazzyhall_4.mp3', 'mp3_unlock'),
    'dancehall': ('dancehall yf_2....\U0001F4CC.mp3', 'mp3_unlock'),
}

def main():
    catalog_path = Path('data/music/runtime_catalog.json')
    catalog = json.loads(catalog_path.read_text())
    for ident, (name, role) in EXTRA.items():
        out = Path('assets/audio/music') / (ident + '.mp3')
        print('Leveling', ident, flush=True)
        catalog['tracks'][ident] = {'title': Path(name).stem, 'stream': 'res://' + str(out), 'source': name, 'role': role, 'leveling': level(Path('soundselection/beats') / name, out, -20)}
    catalog_path.write_text(json.dumps(catalog, indent=2) + '\n')

if __name__ == '__main__':
    main()
