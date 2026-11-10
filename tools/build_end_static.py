"""Deterministic original noise/crackle for Miro's post-credits MP3 scene."""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).resolve().parents[1]
out=root/'assets/audio/cine/end_radio_static.wav'
out.parent.mkdir(parents=True,exist_ok=True)
rng=random.Random(1202)
rate=22050; duration=6.0; burst=0.0; previous=0.0; samples=[]
for i in range(int(rate*duration)):
    t=i/rate
    white=rng.uniform(-1,1)
    high=white-previous*0.65; previous=white
    if rng.random()<0.0015:burst=rng.uniform(-0.85,0.85)
    burst*=0.976
    envelope=min(1.0,t/0.08)*min(1.0,(duration-t)/0.025)
    dropout=0.22 if (t%1.37)<0.045 else 1.0
    value=math.tanh((0.26*high+burst)*1.6)*0.83*envelope*dropout
    samples.append(max(-32768,min(32767,round(value*32767))))
with wave.open(str(out),'wb') as f:
    f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
    f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print(out)
