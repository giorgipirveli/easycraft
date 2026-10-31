#!/usr/bin/env python3
"""Region masks for the realistic avatar's recolour shader (M3 Task 9).

For each Kenney "Animated Characters 3" skin texture (CC0, 256 x 256, one shared UV layout) this writes
assets/characters/avatar_masks/<skin>_regions.png: an RGBA mask of how much each pixel is skin (R),
hair (G), shirt (B) and pants (A). The shader (entities/player/avatar_skin.gdshader) recolours those
regions with the look's colours and keeps the rest (eyes, lips, belt buckle...) as painted. The shoes
are recoloured by their UV rectangle in the shader, so they are not in the mask.

It also prints each region's reference brightness and the skin's reference colour (linear), which go
into AvatarSkin.REFERENCES, and with --preview writes recoloured previews next to this script's
output (in the scratch folder given) to check the result by eye.

Usage: python3 tools/make_avatar_masks.py [--preview <dir>]      (needs Pillow + numpy)
The masks are original work (generated), CC0 like the textures they are measured from.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "characters", "kenney_human")
OUT = os.path.join(ROOT, "assets", "characters", "avatar_masks")
SKINS = ["humanMaleA", "humanFemaleA"]

# UV rectangles in the 256 px layout (x0, y0, x1, y1), shared by both textures.
HEAD = (0, 0, 160, 124)       # hair all round and the face
SHOES = (160, 32, 208, 130)   # recoloured by the shader's own rectangle
SHIRT = (0, 120, 160, 256)
PANTS = (150, 188, 256, 256)
# The face (eyes, brows, lips): kept as painted unless it is skin.
FACE = {"humanMaleA": (58, 46, 102, 76), "humanFemaleA": (60, 46, 100, 76)}
# Below this row the head rectangle is face and neck: not-warm pixels there are stubble (skin).
HAIRLINE = 72


def srgb_to_linear(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luma(lin):
    return lin[..., 0] * 0.2126 + lin[..., 1] * 0.7152 + lin[..., 2] * 0.0722


def in_rect(xs, ys, r):
    return (xs >= r[0]) & (xs < r[2]) & (ys >= r[1]) & (ys < r[3])


def classify(name, rgb):
    """Per-pixel weights (skin, hair, shirt, pants) as 0/1 arrays, before softening."""
    h, w, _ = rgb.shape
    ys, xs = np.mgrid[0:h, 0:w]
    r, g, b = (rgb[..., i].astype(int) for i in range(3))
    lum = luma(srgb_to_linear(rgb.astype(float)))
    warm = (r - b > 22) & (r >= g - 4) & (r > 118) & (lum > 0.2)   # skin, lit or shaded
    neutral = (np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)) < 40
    bluish_light = neutral & (b >= r - 4) & (lum > 0.12)            # the pale blue-grey shirt and its seams
    head = in_rect(xs, ys, HEAD)
    face = in_rect(xs, ys, FACE[name])
    shirt_area = in_rect(xs, ys, SHIRT)
    pants_area = in_rect(xs, ys, PANTS)
    shoes = in_rect(xs, ys, SHOES)

    below = ys >= HAIRLINE
    skin = (warm | (head & below & ~face)) & ~shoes
    hair = head & ~warm & ~face & ~below
    shirt = shirt_area & ~warm & bluish_light & ~pants_area
    pants = pants_area & ~warm
    # everything else stays as painted (eyes, lips, the shirt's seams, the shoes' rectangle)
    return skin, hair, shirt, pants, lum


def soften(mask):
    img = Image.fromarray((mask * 255).astype(np.uint8), "L").filter(ImageFilter.BoxBlur(0.6))
    return np.asarray(img).astype(float) / 255.0


def reference(lum, weight):
    sel = weight > 0.95
    return float(np.median(lum[sel])) if sel.any() else 1.0


def preview(rgb, weights, refs, colors):
    lin = srgb_to_linear(rgb.astype(float))
    lum = luma(lin)[..., None]
    skin_w, hair_w, shirt_w, pants_w = (w[..., None] for w in weights)
    out = lin * np.clip(1 - skin_w - hair_w - shirt_w - pants_w, 0, 1)
    out += np.clip(lin * colors["skin_tint"], 0, 1) * skin_w
    out += np.clip(colors["hair"] * np.clip(lum / refs["hair"], 0, 2) ** 0.75, 0, 1) * hair_w
    out += np.clip(colors["shirt"] * lum / refs["shirt"], 0, 1) * shirt_w
    out += np.clip(colors["pants"] * lum / refs["pants"], 0, 1) * pants_w
    srgb = np.where(out <= 0.0031308, out * 12.92, 1.055 * out ** (1 / 2.4) - 0.055)
    return Image.fromarray((np.clip(srgb, 0, 1) * 255).astype(np.uint8), "RGB")


def hex_lin(h):
    return srgb_to_linear(np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float))


def main():
    preview_dir = sys.argv[sys.argv.index("--preview") + 1] if "--preview" in sys.argv else None
    os.makedirs(OUT, exist_ok=True)
    for name in SKINS:
        rgb = np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGB"))
        skin, hair, shirt, pants, lum = classify(name, rgb)
        weights = [soften(m) for m in (skin, hair, shirt, pants)]
        total = np.maximum(sum(weights), 1.0)
        weights = [w / total for w in weights]   # never more than 1 in all
        mask = np.stack([np.round(w * 255) for w in weights], axis=-1).astype(np.uint8)
        Image.fromarray(mask, "RGBA").save(os.path.join(OUT, name + "_regions.png"))
        lin = srgb_to_linear(rgb.astype(float))
        refs = {"hair": reference(lum, weights[1]), "shirt": reference(lum, weights[2]),
                "pants": reference(lum, weights[3])}
        shoe_sel = in_rect(*np.mgrid[0:256, 0:256][::-1], SHOES) & (lum > 0.3)
        refs["shoes"] = float(np.median(lum[shoe_sel]))
        skin_ref = np.median(lin[weights[0] > 0.95], axis=0)
        print("%s refs hair=%.4f shirt=%.4f pants=%.4f shoes=%.4f skin=(%.4f, %.4f, %.4f)" % (
            name, refs["hair"], refs["shirt"], refs["pants"], refs["shoes"], *skin_ref))
        if preview_dir:
            os.makedirs(preview_dir, exist_ok=True)
            looks = {
                "green_red_blond_brown": {"skin_tint": hex_lin("8d5a3b") / skin_ref, "hair": hex_lin("e8c15a"),
                                          "shirt": hex_lin("2e9d4a"), "pants": hex_lin("e53935")},
                "classic": {"skin_tint": np.ones(3), "hair": hex_lin("5a3a22"), "shirt": hex_lin("0d69ac"),
                            "pants": hex_lin("33406b")},
            }
            for look, colors in looks.items():
                preview(rgb, weights, refs, colors).resize((512, 512), Image.NEAREST).save(
                    os.path.join(preview_dir, "%s_%s.png" % (name, look)))
            Image.fromarray(mask[..., :3]).resize((512, 512), Image.NEAREST).save(
                os.path.join(preview_dir, "%s_mask_rgb.png" % name))
            Image.fromarray(mask[..., 3]).resize((512, 512), Image.NEAREST).save(
                os.path.join(preview_dir, "%s_mask_pants.png" % name))


if __name__ == "__main__":
    main()
