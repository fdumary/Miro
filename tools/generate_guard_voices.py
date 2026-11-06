"""Build-time ElevenLabs only. Never put credentials in game assets or exports.
Cached by text/model/voice/settings hash; re-running does not regenerate matching clips.
"""
import hashlib,json,os,subprocess,urllib.request
from pathlib import Path
from prepare_game_audio import level

def main():
    key=os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        for line in Path('.env').read_text().splitlines():
            if line.startswith('ELEVENLABS_API_KEY='):key=line.split('=',1)[1].strip().strip('\"\'')
    if not key:raise SystemExit('ELEVENLABS_API_KEY not configured')
    config=json.loads(Path('data/guard_dialogue.json').read_text())
    output=Path('assets/audio/voice');output.mkdir(parents=True,exist_ok=True)
    manifest=output/'provenance.json'
    records=json.loads(manifest.read_text()) if manifest.exists() else {}
    lines=[line for conversation in config['conversations'].values() for line in conversation]
    for kind,bark in config['barks'].items():
        for voice in range(3):lines.append({'id':f'{kind}_{voice}','speaker':voice,'text':bark['text']})
    for line in lines:
        voice=config['voices'][str(line['speaker'])]
        body={'text':line['text'],'model_id':config['model_id'],'voice_settings':{'stability':.5,'similarity_boost':.75,'style':.15,'use_speaker_boost':True}}
        signature=hashlib.sha256(json.dumps({'voice':voice['voice_id'],**body},sort_keys=True).encode()).hexdigest()
        dest=output/(line['id']+'.mp3')
        if dest.exists() and records.get(line['id'],{}).get('signature')==signature:continue
        print('Generating',line['id'],voice['name'],flush=True)
        req=urllib.request.Request('https://api.elevenlabs.io/v1/text-to-speech/'+voice['voice_id']+'?output_format=mp3_44100_128',headers={'xi-api-key':key,'Content-Type':'application/json'},data=json.dumps(body).encode())
        raw=Path('/tmp')/('miro-voice-'+line['id']+'-'+signature[:12]+'.mp3')
        try:
            audio=raw.read_bytes() if raw.exists() else urllib.request.urlopen(req,timeout=120).read()
        except Exception as error:
            raise SystemExit(f'ElevenLabs request failed: {type(error).__name__} status={getattr(error,"code","unknown")}') from None
        raw=Path('/tmp')/('miro-voice-'+line['id']+'-'+signature[:12]+'.mp3');raw.write_bytes(audio)
        measurement=level(raw,dest,-18)
        records[line['id']]={'provider':'ElevenLabs','voice_id':voice['voice_id'],'voice_name':voice['name'],'model_id':config['model_id'],'text':line['text'],'signature':signature,'leveling':measurement}
        manifest.write_text(json.dumps(records,indent=2)+'\n')
    print('Guard voice library ready:',len(records),'clips',flush=True)

if __name__=='__main__':main()
