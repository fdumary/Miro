from pathlib import Path
import os,json,sys,importlib.util,time
root=Path(__file__).resolve().parents[1]
limit=time.monotonic()+900
while not (root/'tmp/performance/final-pipeline-done.txt').exists():
 if time.monotonic()>limit: raise TimeoutError('Waiting for isolated performance run')
 time.sleep(2)
os.environ['PATH']=str(root/'tmp/voice-tools')+os.pathsep+os.environ['PATH']
spec=importlib.util.spec_from_file_location('prepare_game_audio',root/'tools/prepare_game_audio.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
source=root/'soundselection/beats/additional_beats/carson jbau.mp3'
target=root/'assets/audio/music/trapdoor_bonus.mp3'
leveling=module.level(source,target,-20)
import librosa,numpy as np
y,sr=librosa.load(source,sr=22050,duration=90,mono=True)
tempo,_=librosa.beat.beat_track(y=y,sr=sr)
bpm=float(np.asarray(tempo).item())
path=root/'data/music/runtime_catalog.json'
catalog=json.loads(path.read_text(encoding='utf-8-sig'))
if any(entry.get('leveling',{}).get('source_sha256') == leveling['source_sha256'] for key,entry in catalog['tracks'].items() if key != 'trapdoor_bonus'):
 raise ValueError('Chosen source is already used by another runtime track')
catalog['tracks']['trapdoor_bonus']={'title':'carson jbau','stream':'res://assets/audio/music/trapdoor_bonus.mp3','source':source.name,'leveling':leveling,'bpm':bpm}
path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
result={'source':str(source),'track':'trapdoor_bonus','title':'carson jbau','artist':'RXLA','loop_credit':'prodbybeven','bpm':bpm,'leveling':leveling}
(root/'tmp/performance/trapdoor-reward.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result),flush=True)
