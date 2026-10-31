#!/usr/bin/env python3
"""Finishes a web export so browsers offer to install it as an app (M7, spec §20; owner 2026-09-28: "they should get
shortcut on the app so next time they just click and open it").

  python3 tools/web_finish.py build/web        # after every export of the "Web" preset (deploy_web.sh runs it)

Godot's manifest has no short name, no id and no 192 px icon; Chrome's install prompt needs a 192 px and a 512 px
icon. This adds them (the 192 px one made from the 512 px icon Godot wrote), a description, the scope, and marks the
512 px icon as maskable too (the buddy sits in the middle of a full teal square). Idempotent. Needs Pillow.
"""
import json
import pathlib
import sys

from PIL import Image


def main() -> None:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
    manifest_path = root / "index.manifest.json"
    manifest = json.loads(manifest_path.read_text())
    big = root / "index.512x512.png"
    small = root / "index.192x192.png"
    Image.open(big).convert("RGBA").resize((192, 192), Image.LANCZOS).save(small)
    manifest.update({
        "id": "./",
        "name": "EasyCraft",
        "short_name": "EasyCraft",
        "description": "Build anything, wake it up and explore five magical universes.",
        "scope": "./",
        "start_url": "./index.html",
        "theme_color": "#139e9b",
        "prefer_related_applications": False,
        "icons": [
            {"src": "index.144x144.png", "sizes": "144x144", "type": "image/png"},
            {"src": "index.180x180.png", "sizes": "180x180", "type": "image/png"},
            {"src": "index.192x192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "index.512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "any"},
            {"src": "index.512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
    })
    manifest_path.write_text(json.dumps(manifest, separators=(",", ":")))
    print(f"WEB_FINISH {manifest_path} icons={len(manifest['icons'])}")


if __name__ == "__main__":
    main()
