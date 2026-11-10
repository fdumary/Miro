from pathlib import Path
import subprocess,json,sys
root=Path('C:/Users/ethan/Miro'); ffmpeg=root/'tmp/voice-tools/ffmpeg.exe'
files=sorted(p for p in (root/'assets/audio').rglob('*') if p.suffix.lower() in ('.mp3','.ogg','.wav'))
failed=[]
for p in files:
 try:
  r=subprocess.run([str(ffmpeg),'-v','error','-nostdin','-i',str(p),'-f','null','-'],capture_output=True,text=True,timeout=60)
  if r.returncode or r.stderr.strip(): failed.append({'path':str(p.relative_to(root)),'exit':r.returncode,'stderr':r.stderr[:500]})
 except Exception as exc: failed.append({'path':str(p.relative_to(root)),'error':str(exc)})
result={'checked':len(files),'failures':failed,'pass':not failed}
(root/'tmp/performance/regressions/audio-decode.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
sys.exit(bool(failed))
