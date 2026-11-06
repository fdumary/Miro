"""Cross-platform build/check entry point. Set GODOT or pass --godot.
Matching 4.7.2 export templates are required for executable builds.
"""
import argparse,os,shutil,subprocess
from pathlib import Path

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',default=os.environ.get('GODOT') or shutil.which('godot') or shutil.which('godot4'))
    p.add_argument('--platform',choices=['windows','macos','qa','pack'],default='windows')
    args=p.parse_args()
    if not args.godot:raise SystemExit('Pass --godot PATH or set GODOT.')
    root=Path(__file__).resolve().parents[1]
    presets={'windows':('Windows Desktop','build/windows/Miro.exe'),'macos':('macOS Review','build/macos/Miro.zip'),'qa':('Windows QA','build/qa/MiroQA.exe'),'pack':('Windows Desktop','build/review/Miro.pck')}
    preset,dest=presets[args.platform]
    (root/dest).parent.mkdir(parents=True,exist_ok=True)
    subprocess.run([args.godot,'--headless','--path',str(root),'--editor','--import','--quit'],check=True)
    subprocess.run([args.godot,'--headless','--path',str(root),'--export-pack' if args.platform=='pack' else '--export-release',preset,dest],check=True)
    print('Built',root/dest)

if __name__=='__main__':main()
