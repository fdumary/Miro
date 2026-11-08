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
    # 7 Nov night (Ethan): start screen, final-level second half, and more MP3 unlocks.
    'drill_shxt': ('drill shxt.mp3', 'menu'),
    'hot_shit': ('hot shit_23.wav', 'level'),
    'drill2': ('drill2_3.mp3', 'mp3_unlock'),
    'reaper': ('reaper beat2.wav', 'mp3_unlock'),
    'ox': ('OX.wav', 'mp3_unlock'),
    'destroyed_lonely': ('destroyed lonely.mp3', 'mp3_unlock'),
    'dancehall_lonesome': ('dancehall lonesome 3 155 rxla fmaj.mp3', 'mp3_unlock'),
    'dancehall64': ('dancehallbeat64.mp3', 'mp3_unlock'),
    'new_age_dancehall': ('new age dancehall_52.mp3', 'mp3_unlock'),
}
# Estimated (onset autocorrelation; dancehall lonesome from its file name). Used by the beat clock.
BPM = {'drill_shxt': 143.55, 'hot_shit': 132.55, 'drill2': 141.6, 'reaper': 136.9, 'ox': 103.35,
       'destroyed_lonely': 139.7, 'dancehall_lonesome': 155.0, 'dancehall64': 99.4, 'new_age_dancehall': 116.15}
# Display names on the MP3 and the start-screen beats tracker.
TITLES = {'drill_shxt': 'Drill Shxt', 'hot_shit': 'Hot Shit', 'drill2': 'Drill 2', 'reaper': 'Reaper Beat', 'ox': 'OX',
          'destroyed_lonely': 'Destroyed Lonely', 'dancehall_lonesome': 'Dancehall Lonesome', 'dancehall64': 'Dancehall 64',
          'new_age_dancehall': 'New Age Dancehall', 'birthday_melody': 'Birthday Melody', 'pinkghost': 'Pink Ghost',
          'jazzyhall': 'Jazzy Hall', 'dancehall': 'Dancehall YF'}

def main():
    catalog_path = Path('data/music/runtime_catalog.json')
    catalog = json.loads(catalog_path.read_text())
    for ident, (name, role) in EXTRA.items():
        out = Path('assets/audio/music') / (ident + '.mp3')
        if ident in catalog['tracks'] and out.exists():
            continue  # already leveled; sources are not all kept in the repo
        print('Leveling', ident, flush=True)
        catalog['tracks'][ident] = {'title': Path(name).stem, 'stream': 'res://' + str(out), 'source': name, 'role': role, 'leveling': level(Path('soundselection/beats') / name, out, -20)}
        if ident in BPM:
            catalog['tracks'][ident]['bpm'] = BPM[ident]
    for ident, title in TITLES.items():
        if ident in catalog['tracks']:
            catalog['tracks'][ident]['title'] = title
    catalog_path.write_text(json.dumps(catalog, indent=2) + '\n')

if __name__ == '__main__':
    main()
