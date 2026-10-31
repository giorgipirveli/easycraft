#!/usr/bin/env python3
"""EasyCraft's learning reels, round 2 (owner #94 and #96: "educational, like how to build a rocket, lessons
explanations, learning animations ... we must keep reels high quality"; spec §5.12b): writes each reel's JSON
(data/shorts/cinematic/<id>.json) from its script in tools/learning_reels/<id>.py (made with tools/learning_reels/
reelkit.py), so a reel's camera, its models' shapes and its timing can be tuned after a review of its frame sheet and
made again.

    python3 tools/make_learning_reels.py              # every reel
    python3 tools/make_learning_reels.py volcano_erupts water_cycle_3d

Then: godot --headless --path . --script res://tools/reel_check.gd -- --short=<id> (the checkers), and the frame sheet
(tools/reel_preview.gd -- --sheet --short=<id>): review it and fix what looks cheap. Each reel is a live 3D stage (the
Reel Studio's StudioRules format; the rigs in docs/devlog/parts/reels-2.md) under the Short's own scenes (captions, the
voice, stickers, sounds). Every number a reel says is worked out again by tests/unit/test_reel_studio_learning.gd from
the game's tables or a cited source (the notes list them).
"""
import importlib
import os
import sys

sys.dont_write_bytecode = True   # no __pycache__ in the repository
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "learning_reels"))

import reelkit  # noqa: E402

## The reels, in the order they were made (data/shorts/shorts.json places each in the feed).
REELS = ["volcano_erupts", "water_cycle_3d", "seasons_tilt", "day_and_night", "pyramid_build", "lever_pulley",
    "moon_phases_3d", "plants_food", "plates_mountains", "volume_blocks", "gold_prospecting", "float_or_sink"]


def main(args):
    names = args or [r for r in REELS if os.path.exists(os.path.join(HERE, "learning_reels", r + ".py"))]
    for n in names:
        if n not in REELS:
            sys.exit("no reel %s (%s)" % (n, ", ".join(REELS)))
        reelkit.write(importlib.import_module(n).make())


if __name__ == "__main__":
    main(sys.argv[1:])
