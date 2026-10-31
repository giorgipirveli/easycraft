#!/usr/bin/env python3
"""Builds Frostpeak's music loops (M3 Task 3, spec §14.1) from CC0 tracks on OpenGameArt.org:

  frost_day.ogg   <- "Village of Snow" by zesona   https://opengameart.org/content/village-of-snow
  frost_night.ogg <- "Icy Heights" by écrivain      https://opengameart.org/content/icy-heights  (theme-loop.ogg)

Both pages list CC0 as their only licence ("releasing it here into the public domain"; checked 2026-09-24),
and both are made to loop: the whole piece is the loop (Village of Snow 128.0 s, Icy Heights 42.0 s).
Loudness is evened out like tools/make_music.py (whose helpers this uses) and each loop is encoded as a small
stereo Ogg Vorbis. The boss fight keeps Green Meadows' boss loop (the descriptor names no Frostpeak boss track).

Run from the project root:  python3 tools/make_frost_music.py   (needs numpy and ffmpeg with libvorbis)
Downloads are cached in ~/.cache/easycraft-music. Credits: assets/CREDITS.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_music as base  # noqa: E402  (fetch, decode, normalize, encode, seam_report)

# track: (source url, sample rate, loop seconds, vorbis quality)
TRACKS = {
    "frost_day": ("https://opengameart.org/sites/default/files/VillageOfSnow.ogg", 32000, 128.0, 1),
    "frost_night": ("https://opengameart.org/sites/default/files/theme-loop.ogg", 32000, 42.0, 2),
}


SEAM_MS = 12.0


def smooth_seam(y, rate: int):
    """Bends the loop's last few ms to meet its first sample (Village of Snow ends a little off its start:
    a click at the seam)."""
    n = int(rate * SEAM_MS / 1000.0)
    ramp = base.np.linspace(0.0, 1.0, n)[:, None]
    y = y.copy()
    y[-n:] += (y[0] - y[-1]) * ramp
    return y


def main() -> None:
    os.makedirs(base.OUT, exist_ok=True)
    for name, (url, rate, seconds, quality) in TRACKS.items():
        x = base.decode(base.fetch(url), rate)
        loop_len = int(round(seconds * rate))
        assert abs(len(x) - loop_len) < rate // 10, f"{name}: the source is {len(x) / rate:.3f} s, not a {seconds:.1f} s loop"
        if len(x) < loop_len:
            x = base.np.concatenate([x, base.np.zeros((loop_len - len(x), 2))])
        y = smooth_seam(base.normalize(x[:loop_len]), rate)
        out = os.path.join(base.OUT, name + ".ogg")
        base.encode(y, rate, quality, out)
        back = base.decode(out, rate)
        print(f"MUSIC {name}: {loop_len / rate:.3f} s (source {len(x) / rate:.3f} s), {os.path.getsize(out) / 1024:.0f} KB, "
            f"decoded {len(back)} of {loop_len} samples; {base.seam_report(y, rate)}")


if __name__ == "__main__":
    main()
