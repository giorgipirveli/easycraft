#!/usr/bin/env python3
"""The rocket engine's roar (owner #79, spec §25.3; entities/flight/flight_sounds.gd): our own sound, no recording.
One second of deep rumbling noise (brown noise with a little hiss), 22,050 Hz mono 16-bit, whose end fades into its
start so it loops without a click; imported as a forward loop. RocketFlight plays it louder and higher as the fire grows.

Run from the project root:  python3 tools/make_flight_sounds.py      (needs numpy; seed 20260929)
Writes assets/flight/engine_roar.wav. Credits: assets/CREDITS.md (original work).
"""
import wave

import numpy as np

RATE = 22050
SECONDS = 1.0
FADE = 0.1
OUT = "assets/flight/engine_roar.wav"


def main():
    rng = np.random.default_rng(20260929)
    n = int(RATE * SECONDS)
    fade = int(RATE * FADE)
    white = rng.uniform(-1.0, 1.0, n + fade)
    brown = np.zeros_like(white)
    hiss = np.zeros_like(white)
    b = h = 0.0
    for i, w in enumerate(white):
        b = (b + w * 0.035) * 0.996
        h += (w - h) * 0.12
        brown[i] = b
        hiss[i] = h
    raw = brown + hiss * 0.12
    loop = raw[:n].copy()
    t = np.arange(fade) / fade
    loop[:fade] = raw[:fade] * t + raw[n:n + fade] * (1.0 - t)   # the start takes over from the end: no seam
    loop = loop / np.abs(loop).max() * 0.85
    pcm = (loop * 32767.0).astype("<i2")
    with wave.open(OUT, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())
    print("wrote", OUT)


if __name__ == "__main__":
    main()
