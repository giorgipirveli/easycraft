#!/usr/bin/env python3
"""Bot friends' skins for the REALISTIC style (M2 Task 15).

Each bot look (BotRules.LOOKS in core/rules/bot_rules.gd) wears one of the two Kenney "Animated
Characters 3" skins (CC0) with its shirt dyed in the look's torso colour, so bot friends never look
like clones of the player. Writes assets/characters/bot_skins/bot_<look>.png (256 x 256).

The shirt is the pale, unsaturated cloth in the lower-left quarter of the skin atlas; skin tones
(saturated) and everything else stay as they are. Keep TORSO and BASE in step with BotRules.LOOKS.

Run from the project root:  python3 tools/make_bot_skins.py   (needs Pillow and numpy)
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/characters/kenney_human"
OUT = ROOT / "assets/characters/bot_skins"
BASES = ["humanMaleA.png", "humanFemaleA.png"]
# (torso colour, base body) per look, as in BotRules.LOOKS
LOOKS = [
    ("3cbf5a", 0),
    ("e8413c", 1),
    ("a05be0", 0),
    ("f08a2c", 1),
    ("34c6c9", 0),
    ("e05ba8", 1),
]
SHIRT = (0, 118, 152, 256)   # x0, y0, x1, y1 of the shirt cloth in the atlas


def dye(img: np.ndarray, colour: str) -> np.ndarray:
    out = img.copy()
    rgb = out[..., :3].astype(np.float32) / 255.0
    x0, y0, x1, y1 = SHIRT
    region = rgb[y0:y1, x0:x1]
    hi = region.max(axis=2)
    lo = region.min(axis=2)
    sat = np.where(hi > 0, (hi - lo) / np.maximum(hi, 1e-6), 0)
    cloth = (sat < 0.12) & (hi > 0.45)          # pale grey-white fabric, not skin
    tint = np.array([int(colour[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)
    shade = (hi / np.percentile(hi[cloth], 90)).clip(0.0, 1.15)[..., None]   # keep the folds
    dyed = (tint[None, None, :] * shade).clip(0.0, 1.0)
    region[cloth] = dyed[cloth]
    rgb[y0:y1, x0:x1] = region
    out[..., :3] = (rgb * 255.0 + 0.5).astype(np.uint8)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    bases = [np.array(Image.open(SRC / name).convert("RGBA")) for name in BASES]
    for i, (colour, base) in enumerate(LOOKS):
        Image.fromarray(dye(bases[base], colour)).save(OUT / f"bot_{i}.png", optimize=True)
        print(f"bot_{i}.png  base={BASES[base]}  shirt=#{colour}")


if __name__ == "__main__":
    main()
