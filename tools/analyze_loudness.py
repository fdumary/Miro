from pathlib import Path
import json,re,subprocess,sys
root=Path('C:/Users/ethan/Miro'); out=root/'tmp/performance'; ffmpeg=root/'tmp/voice-tools/ffmpeg.exe'
results=[]
files=sorted(out.glob('mix_*.wav'))
catalog=json.loads((root/'data/music/runtime_catalog.json').read_text(encoding='utf-8-sig'))
files+=list(dict.fromkeys(root/v['stream'].removeprefix('res://') for v in catalog['tracks'].values()))
files += sorted((root/'assets/audio/cine').glob('*.*'))
files = [p for p in files if p.suffix.lower() in ['.mp3','.wav','.ogg']]
for p in files:
 r=subprocess.run([str(ffmpeg),'-hide_banner','-nostdin','-i',str(p),'-af','loudnorm=I=-24:TP=-1:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,timeout=180)
 matches=re.findall(r'\{[^{}]*"input_i"[^{}]*\}',r.stderr,re.S)
 if not matches: results.append({'path':str(p.relative_to(root)),'error':r.stderr[-500:]});continue
 m=json.loads(matches[-1]); results.append({'path':str(p.relative_to(root)),'integrated_lufs':float(m['input_i']),'true_peak_dbtp':float(m['input_tp']),'loudness_range_lu':float(m['input_lra'])})
 (out/'audio-loudness.json').write_text(json.dumps(results,indent=2))
 print(p.name, m['input_i'], m['input_tp'],flush=True)
