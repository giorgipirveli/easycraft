#!/usr/bin/env python3
"""Builds the Sandstorm Desert's music loops (M3 Task 2, spec §14.1) from CC0 tracks on OpenGameArt.org:

  desert_day.ogg   <- "Desert Loop" by iamoneabe                 https://opengameart.org/content/desert-loop
  desert_night.ogg <- "Desert Loop (Lo-Fi Remaster)" by iamoneabe https://opengameart.org/content/desert-loop-lo-fi-remaster

Both pages list CC0 as their only licence ("CC Zero, as always"). The sources are made to loop (64.0 s:
32 bars at 120 bpm), so the loop is the whole piece; the decoder's padding is cut back to the bar grid.
Loudness is evened out like tools/make_music.py (whose helpers this uses) and each loop is encoded as a small
stereo Ogg Vorbis. The boss fight keeps Green Meadows' boss loop (the descriptor names no desert boss track).

Run from the project root:  python3 tools/make_desert_music.py   (needs numpy and ffmpeg with libvorbis)
Downloads are cached in ~/.cache/easycraft-music. Credits: assets/CREDITS.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_music as base  # noqa: E402  (fetch, decode, normalize, encode, seam_report)

# track: (source url, sample rate, bpm, beats per bar, bars in the loop, vorbis quality)
TRACKS = {
    "desert_day": ("https://opengameart.org/sites/default/files/desert_loop_0.mp3", 32000, 120.0, 4, 32, 2),
    "desert_night": ("https://opengameart.org/sites/default/files/desert_loops_2_0.mp3", 32000, 120.0, 4, 32, 2),
}


def main() -> None:
    os.makedirs(base.OUT, exist_ok=True)
    for name, (url, rate, bpm, beats, bars, quality) in TRACKS.items():
        x = base.decode(base.fetch(url), rate)
        loop_len = int(round(bars * beats * 60.0 / bpm * rate))
        assert abs(len(x) - loop_len) < rate // 10, f"{name}: the source is {len(x) / rate:.3f} s, not a {loop_len / rate:.1f} s loop"
        if len(x) < loop_len:
            x = base.np.concatenate([x, base.np.zeros((loop_len - len(x), 2))])
        y = base.normalize(x[:loop_len])
        out = os.path.join(base.OUT, name + ".ogg")
        base.encode(y, rate, quality, out)
        back = base.decode(out, rate)
        print(f"MUSIC {name}: {bars} bars at {bpm:g} bpm = {loop_len / rate:.3f} s (source {len(x) / rate:.3f} s), "
            f"{os.path.getsize(out) / 1024:.0f} KB, decoded {len(back)} of {loop_len} samples; {base.seam_report(y, rate)}")


if __name__ == "__main__":
    main()
