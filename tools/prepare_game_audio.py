"""Read-only originals -> leveled MP3 runtime copies. Requires ffmpeg/ffprobe."""
import hashlib,json,re,subprocess
from pathlib import Path

def level(source, output, target):
    measurement=subprocess.run(['ffmpeg','-hide_banner','-i',str(source),'-af',f'loudnorm=I={target}:TP=-2:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,check=True).stderr
    values=json.loads(re.findall(r'\{[^{}]*"input_i"[^{}]*\}',measurement,re.S)[-1])
    filt=f'loudnorm=I={target}:TP=-2:LRA=11:measured_I={values["input_i"]}:measured_TP={values["input_tp"]}:measured_LRA={values["input_lra"]}:measured_thresh={values["input_thresh"]}:offset={values["target_offset"]}:linear=true'
    output.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-af',filt,'-ar','44100','-c:a','libmp3lame','-q:a','2',str(output)],check=True)
    verified=subprocess.run(['ffmpeg','-hide_banner','-i',str(output),'-af',f'loudnorm=I={target}:TP=-2:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,check=True).stderr
    result=json.loads(re.findall(r'\{[^{}]*"input_i"[^{}]*\}',verified,re.S)[-1])
    return {'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'target_lufs':target,'true_peak_target_dbtp':-2,'input':values,'output_lufs':result['input_i'],'output_true_peak_dbtp':result['input_tp']}

def main():
    plan=json.loads(Path('data/music/section_candidates.json').read_text())
    files=list(dict.fromkeys(s['file'] for s in plan['sections'] if s['file']))
    ids=['yz33','bobblehead','dope2','swag','sumcrazy','plane_drums','cyberpunk','shit_crashed','robot_attack']
    tracks={}
    for ident,name in zip(ids,files):
        out=Path('assets/audio/music')/(ident+'.mp3')
        print('Leveling',ident,flush=True)
        tracks[ident]={'title':name,'stream':'res://'+str(out),'source':name,'leveling':level(Path('soundselection/beats')/name,out,-20)}
    Path('data/music/runtime_catalog.json').write_text(json.dumps({'tracks':tracks,'music_bus_db':-6,'duck_db':-8,'fade_seconds':1.5},indent=2)+'\n')

if __name__=='__main__':main()
