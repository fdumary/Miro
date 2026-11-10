"""Verify the exported PE embeds every image in the project's ICO (stdlib only)."""
from pathlib import Path
import struct,sys,json,hashlib
exe,ico=map(Path,sys.argv[1:3]); data=exe.read_bytes(); icon=ico.read_bytes()
pe=struct.unpack_from('<I',data,0x3c)[0]
assert data[pe:pe+4]==b'PE\0\0'
sections=struct.unpack_from('<H',data,pe+6)[0]; optsize=struct.unpack_from('<H',data,pe+20)[0]; opt=pe+24
magic=struct.unpack_from('<H',data,opt)[0]
dirs=opt+(112 if magic==0x20b else 96)
resource_rva,resource_size=struct.unpack_from('<II',data,dirs+16)
section_start=opt+optsize
section=[]
for i in range(sections):
    pos=section_start+40*i
    vsize,vaddr,rsize,rptr=struct.unpack_from('<IIII',data,pos+8)
    section.append((vaddr,max(vsize,rsize),rptr))
def offset(rva):
    for va,size,raw in section:
        if va<=rva<va+size:return raw+rva-va
    raise ValueError('RVA not in a section')
root=offset(resource_rva)
def walk(relative=0,path=()):
    pos=root+relative
    named,ids=struct.unpack_from('<HH',data,pos+12)
    for i in range(named+ids):
        name,dest=struct.unpack_from('<II',data,pos+16+8*i)
        key=name if not name&0x80000000 else 'named'
        if dest&0x80000000:yield from walk(dest&0x7fffffff,path+(key,))
        else:
            rva,length=struct.unpack_from('<II',data,root+dest)
            yield path+(key,),data[offset(rva):offset(rva)+length]
resources=list(walk())
images=[blob for path,blob in resources if path[0]==3]
count=struct.unpack_from('<H',icon,4)[0]
sizes=[]
for i in range(count):
    w,h,_,_,planes,bpp,length,start=struct.unpack_from('<BBBBHHII',icon,6+16*i)
    expected=icon[start:start+length]
    assert expected in images,f'Missing embedded icon {w or 256}x{h or 256}'
    sizes.append((w or 256,h or 256))
assert set(sizes)=={(n,n) for n in (16,32,48,64,128,256)}
# Preserve an exact extracted 256px image for visual review.
for blob in images:
    if blob.startswith(b'\x89PNG') and struct.unpack_from('>II',blob,16)==(256,256):
        (exe.parent.parent/'icon-from-exe.png').write_bytes(blob);break
print(json.dumps({'result':'PASS','sizes':sizes,'exe_sha256':hashlib.sha256(data).hexdigest()}))
