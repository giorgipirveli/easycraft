#!/usr/bin/env python3
"""Builds the background music loops (M2 Task 11, spec §12.10) from CC0 tracks by The Cynic Project
(cynicmusic), made for the game Pixelsphere and published on OpenGameArt.org as CC0:

  day.ogg   <- "Happy Lullaby (song17)"  https://opengameart.org/content/happy-lullaby-song17
  night.ogg <- "Crystal Cave (song18)"   https://opengameart.org/content/crystal-cave-song18
  boss.ogg  <- "Battle Theme A"          https://opengameart.org/content/battle-theme-a

Each source is a loop region followed by its reverb tail. The script cuts the loop at a bar line
(tempo and bar count measured from the audio: onset autocorrelation, see docs/devlog/parts/m2-task-11.md),
mixes the tail back onto the start so the loop is seamless, evens out the loudness (RMS target, peak
limit), and encodes a small stereo Ogg Vorbis file. Godot imports them with loop=true.

Run from the project root:  python3 tools/make_music.py    (needs numpy and ffmpeg with libvorbis)
Downloads are cached in ~/.cache/easycraft-music. Deterministic for the same ffmpeg.
"""
import os
import subprocess
import tempfile
import urllib.request

import numpy as np

OUT = "assets/music"
CACHE = os.path.expanduser("~/.cache/easycraft-music")
UA = {"User-Agent": "Mozilla/5.0 (EasyCraft asset build)"}
TARGET_RMS_DB = -18.0
PEAK_LIMIT = 0.89                 # -1 dBFS
TAIL_FADE_MS = 60.0

# track: (source url, sample rate, bpm, beats per bar, bars in the loop, vorbis quality)
TRACKS = {
    "day": ("https://opengameart.org/sites/default/files/song17.mp3", 32000, 100.0, 4, 16, 3),
    "night": ("https://opengameart.org/sites/default/files/song18_0.mp3", 32000, 100.0, 4, 20, 3),
    "boss": ("https://opengameart.org/sites/default/files/battleThemeA.mp3", 44100, 146.0, 4, 56, 2),
}


def fetch(url: str) -> str:
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, url.rsplit("/", 1)[-1])
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
    return path


def decode(path: str, rate: int) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(rate), "-"],
        capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype="<f4").reshape(-1, 2).astype(np.float64)


def make_loop(x: np.ndarray, loop_len: int, rate: int) -> np.ndarray:
    """The loop region with the tail after it mixed back onto its start (the tail's last ms faded)."""
    loop = x[:loop_len].copy()
    tail = x[loop_len:loop_len * 2].copy()
    n = min(len(tail), int(rate * TAIL_FADE_MS / 1000.0))
    if n > 0:
        tail[-n:] *= np.linspace(1.0, 0.0, n)[:, None]
    loop[:len(tail)] += tail
    return loop


def normalize(x: np.ndarray) -> np.ndarray:
    rms = np.sqrt(np.mean(x ** 2))
    gain = 10 ** (TARGET_RMS_DB / 20.0) / max(rms, 1e-9)
    gain = min(gain, PEAK_LIMIT / max(np.max(np.abs(x)), 1e-9))
    return x * gain


def seam_report(x: np.ndarray, rate: int) -> str:
    """Spectral jump across the loop seam compared with ordinary frame-to-frame jumps inside the piece."""
    win, hop = 1024, rate // 100
    def spec(a: np.ndarray) -> np.ndarray:
        return np.log1p(np.abs(np.fft.rfft(a.mean(axis=1) * np.hanning(win))) * 10)
    wrapped = np.concatenate([x[-win:], x[:win]])
    seam = np.linalg.norm(spec(wrapped[win // 2:win // 2 + win]) - spec(wrapped[win // 2 - hop:win // 2 - hop + win]))
    inner = [np.linalg.norm(spec(x[i + hop:i + hop + win]) - spec(x[i:i + win]))
        for i in range(0, len(x) - win - hop, len(x) // 400)]
    step = np.max(np.abs(x[0] - x[-1]))            # a click would be a big sample step
    steps = np.max(np.abs(np.diff(x, axis=0)), axis=1)
    return (f"seam spectral jump {seam:.1f} (inside: median {np.median(inner):.1f}, p95 {np.percentile(inner, 95):.1f}; "
        f"a phrase starting on the seam is bigger), seam sample step {step:.4f} (inside: p99 {np.percentile(steps, 99):.4f})")


def encode(x: np.ndarray, rate: int, quality: int, out: str) -> None:
    with tempfile.NamedTemporaryFile(suffix=".f32") as tmp:
        tmp.write(x.astype("<f4").tobytes())
        tmp.flush()
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(rate), "-ac", "2", "-i", tmp.name,
            "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
            "-c:a", "libvorbis", "-q:a", str(quality), out], check=True)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, (url, rate, bpm, beats, bars, quality) in TRACKS.items():
        x = decode(fetch(url), rate)
        loop_len = int(round(bars * beats * 60.0 / bpm * rate))
        assert loop_len < len(x), f"{name}: loop longer than the source"
        y = normalize(make_loop(x, loop_len, rate))
        out = os.path.join(OUT, name + ".ogg")
        encode(y, rate, quality, out)
        back = decode(out, rate)
        print(f"MUSIC {name}: {bars} bars at {bpm:g} bpm = {loop_len / rate:.3f} s (source {len(x) / rate:.2f} s), "
            f"{os.path.getsize(out) / 1024:.0f} KB, decoded {len(back)} of {loop_len} samples; {seam_report(y, rate)}")


if __name__ == "__main__":
    main()
