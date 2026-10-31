#!/usr/bin/env python3
"""Loudness of the game's universe music loops, ambience loops and monster voices (M5 Task 2, spec §15.2).

The way owner #50 measured the animals (docs/devlog/parts/owner-50-sounds.md): EBU R128 integrated loudness
(ffmpeg's ebur128 filter), full band and through a phone's small speaker (two 500 Hz high-passes: a phone gives
almost nothing below that). Short takes are looped until they last 3 s so the 400 ms windows fit. Where a group
has several takes (a monster's grunts), the takes' mean is the group's.

    python3 tools/measure_loudness.py [music|pieces|ambience|voices ...] [--json out.json]

Prints one table per group (music loops by universe, ambience loops, monster idle voices) and each item's gain
towards the group's target through a phone (music -18 LUFS, ambience -22 LUFS, voices -17 LUFS; boosts capped at
+6 dB). The gains in the game (MusicRules.LOOP_GAIN_DB, AmbienceSoundRules.LOOPS, VoiceRules.MONSTER_GAIN_DB) come
from this table; docs/devlog/parts/m5-task-2.md has the run.
Needs ffmpeg.
"""
import glob
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC = "assets/music/"
AMB = "assets/audio/ambience/"
SFX = "assets/audio/sfx/"
TARGETS = {"music": -18.0, "pieces": -18.0, "ambience": -22.0, "voices": -17.0}
MAX_BOOST = 6.0

# group -> [(label, [files])]
GROUPS = {
    "music": [
        ("meadows day", [MUSIC + "day.ogg"]), ("meadows night", [MUSIC + "night.ogg"]),
        ("boss (every universe)", [MUSIC + "boss.ogg"]),
        ("desert day", [MUSIC + "desert_day.ogg"]), ("desert night", [MUSIC + "desert_night.ogg"]),
        ("frost day", [MUSIC + "frost_day.ogg"]), ("frost night", [MUSIC + "frost_night.ogg"]),
        ("candy day", [MUSIC + "candy_day.ogg"]), ("candy night", [MUSIC + "candy_night.ogg"]),
    ],
    "pieces": [(os.path.basename(f)[:-4], [os.path.relpath(f, ROOT)])
               for f in sorted(glob.glob(os.path.join(ROOT, MUSIC, "classical", "*.ogg")))],
    "ambience": [(n, [AMB + n + ".ogg"]) for n in
                 ["birds", "crickets", "wind", "waves", "drips", "snow_wind", "snow_night", "chimes", "brook"]],
    "voices": [
        ("slime (squish)", [SFX + "monster_squish.wav"]),
        ("goblin (grunt)", [SFX + "goblin_grunt_%d.ogg" % i for i in (1, 2, 3)]),
        ("mummy (moan)", [SFX + "mummy_moan.wav"]),
        ("scorpion (click)", [SFX + "scorpion_click.ogg"]),
        ("yeti (roar)", [SFX + "yeti_roar.wav"]),
        ("ice bat (screech)", [SFX + "bat_screech.wav"]),
        ("gummy (squeak)", [SFX + "gummy_squeak.wav"]),
        ("sneaker (jingle)", [SFX + "sneaker_jingle.wav"]),
        ("archer (growl)", [SFX + "monster_growl.wav"]),
        ("shadow bat (flutter)", [SFX + "shadow_flutter.wav"]),
        ("wisp (hum)", [SFX + "wisp_hum.wav"]),
        ("spore puff (puff)", [SFX + "spore_puff.wav"]),
        ("crawler (click)", [SFX + "crawler_click.wav"]),
    ],
}


def duration(path: str) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True, check=True).stdout.strip()
    return float(out)


def lufs(path: str, phone: bool) -> float:
    loops = max(0, int(3.0 / max(duration(path), 0.05)))
    chain = ("highpass=f=500,highpass=f=500," if phone else "") + "ebur128=framelog=quiet"
    err = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-stream_loop", str(loops), "-i", path,
                          "-af", chain, "-f", "null", "-"], capture_output=True, text=True).stderr
    m = re.findall(r"I:\s+(-?[\d.]+|-inf) LUFS", err)
    return float(m[-1]) if m and m[-1] != "-inf" else float("-inf")


def peak(path: str) -> float:
    """The file's true peak (dBTP), for the headroom a boost has."""
    err = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-i", path, "-af", "ebur128=peak=true:framelog=quiet",
                          "-f", "null", "-"], capture_output=True, text=True).stderr
    m = re.findall(r"Peak:\s+(-?[\d.]+|-inf) dBFS", err)
    return float(m[-1]) if m and m[-1] != "-inf" else float("-inf")


def main() -> None:
    out = {}
    only = [a for a in sys.argv[1:] if a in GROUPS]
    for group, items in GROUPS.items():
        if only and group not in only:
            continue
        print("\n## %s (target %.0f LUFS through a phone)\n" % (group, TARGETS[group]))
        print("| Item | Takes (full band, LUFS) | Through a phone | Mean (phone) | True peak (dBTP) | Gain towards the target |")
        print("|---|---|---|---|---|---|")
        for label, files in items:
            files = [f for f in files if os.path.exists(os.path.join(ROOT, f))]
            if not files:
                continue
            full = [lufs(os.path.join(ROOT, f), False) for f in files]
            phone = [lufs(os.path.join(ROOT, f), True) for f in files]
            mean = sum(phone) / len(phone)
            top = max(peak(os.path.join(ROOT, f)) for f in files)
            gain = min(TARGETS[group] - mean, MAX_BOOST)
            out.setdefault(group, {})[label] = {"full": full, "phone": phone, "mean_phone": mean, "peak": top,
                                                "gain": gain}
            print("| %s | %s | %s | %.1f | %.1f | %+.1f dB |" % (label, ", ".join("%.1f" % v for v in full),
                  ", ".join("%.1f" % v for v in phone), mean, top, gain))
    if "--json" in sys.argv:
        with open(sys.argv[sys.argv.index("--json") + 1], "w") as f:
            json.dump(out, f, indent=1)


if __name__ == "__main__":
    main()
