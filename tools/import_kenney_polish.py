"""Copy selected original Kenney files and provenance; never edits Julia's PNGs."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("archive", type=Path)
args = parser.parse_args()
destination = Path(__file__).resolve().parents[1] / "assets/library"
files = {}
for name, index in dict(chain_top=8, chain=39, chain_end=55, pipe=58,
                       pipe_corner=76, vent=11, control=27, terminal=73,
                       lever=74, warning=42, hazard=25, beacon=64,
                       beacon_blue=65).items():
    files[name] = f"2D assets/Pixel Platformer Industrial Expansion/Tiles/tile_{index:04}.png"
for name, index in dict(bars=41, torch=125, bottle=113, flask=115, cabinet=75).items():
    files[name] = f"2D assets/Tiny Dungeon/Tiles/tile_{index:04}.png"
for name, index in dict(record=37, microscope=111, medical_case=102, case=145).items():
    files[name] = f"2D assets/Generic Items/PNG/Colored/genericItem_color_{index:03}.png"
for name, index in dict(key_e=87, key_w=86, key_a=120, key_1=51, key_2=52,
                       key_3=53, key_4=54, key_esc=18).items():
    files[name] = f"Icons/Input Prompts Pixel/Tiles/tile_{index:04}.png"
files.update({
    "panel": "UI assets/UI Pack - Pixel Adventure/Tiles/Large tiles/Thick outline/tile_0003.png",
    "panel_hover": "UI assets/UI Pack - Pixel Adventure/Tiles/Large tiles/Thick outline/tile_0002.png",
    "alert": "2D assets/Emote Pack/PNG/Pixel/Style 1/emote_exclamation.png",
    "question": "2D assets/Emote Pack/PNG/Pixel/Style 1/emote_question.png",
    "thought": "2D assets/Emote Pack/PNG/Pixel/Style 5/emote__.png",
    "speech": "2D assets/Emote Pack/PNG/Pixel/Style 1/emote_dots3.png",
    "dust": "2D assets/Particle Pack/PNG (Transparent)/dirt_01.png",
    "spark": "2D assets/Particle Pack/PNG (Transparent)/spark_01.png",
    "smoke": "2D assets/Smoke Particles/PNG/White puff/whitePuff00.png",
    "splat": "2D assets/Splat Pack/PNG/Default (256px)/splat02.png",
    "grass": "2D assets/Foliage Sprites/PNG/Flat/sprite_0001.png",
})
with zipfile.ZipFile(args.archive) as archive:
    for source in files.values():
        archive.getinfo(source)
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name, source in files.items():
        content = archive.read(source)
        (destination / f"{name}.png").write_bytes(content)
        manifest[name] = {"source": source, "sha256": hashlib.sha256(content).hexdigest()}
    for pack in sorted({"/".join(source.split("/")[:2]) for source in files.values()}):
        notice = archive.read(f"{pack}/License.txt").decode("utf-8-sig")
        (destination / (pack.split("/")[-1].replace(" ", "_") + "_LICENSE.txt")).write_text(
            "\n".join(line.rstrip() for line in notice.splitlines()).strip() + "\n", encoding="utf-8")
(destination / "sources.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"Copied {len(files)} original assets with CC0 notices and SHA-256 provenance.")
