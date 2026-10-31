#!/usr/bin/env python3
"""Generates universe 6, the Glow Caves' sounds (original work, synthesised here with tools/make_monster_sounds.py's
helpers; no recording, no third-party audio) into assets/audio/sfx/. Soft and friendly: nothing growls.

  spore_puff      a spore puff about: a soft breathy "pff" with a little rising hum
  spore_swell     a spore puff swells up before its bump (its 1.0 s signal): a rising, bubbly hum
  spore_hurt      a spore puff is hit: a squeaky "pop-oop"
  crawler_click   a cave crawler about: a soft, quick chitter of clicks
  crawler_chitter a cave crawler raises its feelers before its nip (its 0.9 s signal): faster clicks rising
  crawler_hurt    a cave crawler is hit: a little "tk-tk-eek"
  mother_hum      the Spore Mother wakes or cheers: a deep, warm, sleepy hum with a bubbly glow
  mother_spores   her spore clouds rise and land: a soft airy whoosh with sparkles
  mother_puff     her big glittering puff: a round "poof" with a sparkly tail
  mother_ring     her spore ring rolls out: a whirling whoosh that sweeps by
  echo_click      a bat's click at the Echo Fork (and, quieter, its echo): a short bright tick
  drip_plink      a drop landing at the Drip Stone: a clear water "plink"
  fizz            rainwater on limestone at the Rain Carver: a soft fizz of tiny bubbles

Run from the project root:  python3 tools/make_glow_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20261017)


def _noise(n: int, smooth: int) -> np.ndarray:
    return lowpass(RNG.standard_normal(n), smooth)


def _click(n: int = 60) -> np.ndarray:
    tick = RNG.standard_normal(n)
    return (tick - lowpass(tick, 3)) * np.linspace(1, 0, n) ** 2


def spore_puff() -> np.ndarray:
    tt = t(0.55)
    breath = _noise(tt.size, 18) * np.sin(np.pi * np.clip(tt / 0.3, 0, 1)) ** 2 * 0.8
    hum = tone(260 + 120 * np.clip(tt / 0.5, 0, 1), (1.0, 0.3)) * np.sin(np.pi * tt / 0.55) ** 2 * 0.35
    return (breath + hum) * env(tt.size, 0.01, 0.12)


def spore_swell() -> np.ndarray:
    tt = t(1.0)
    f = 200 + 260 * (tt / 1.0) ** 1.3
    hum = tone(f, (1.0, 0.45, 0.2)) * (0.3 + 0.7 * tt)
    bubbles = np.zeros(tt.size)
    for i in range(12):
        at = int(RATE * (0.05 + i * 0.075))
        n = int(RATE * 0.04)
        bt = np.arange(n) / RATE
        bubbles[at:at + n] += np.sin(2 * np.pi * (600 + 40 * i) * bt * (1 + bt * 8)) * decay(n, 60) * 0.3
    return (hum + bubbles) * env(tt.size, 0.03, 0.05)


def spore_hurt() -> np.ndarray:
    tt = t(0.3)
    f = 700 + 500 * np.clip(tt / 0.05, 0, 1) - 450 * np.clip((tt - 0.08) / 0.2, 0, 1)
    pop = tone(f, (1.0, 0.25)) * env(tt.size, 0.004, 0.1)
    return pop + _noise(tt.size, 6) * decay(tt.size, 30) * 0.3


def crawler_click() -> np.ndarray:
    out = np.zeros(int(RATE * 0.45))
    for i in range(7):
        at = int(RATE * (0.02 + i * 0.05 + 0.01 * RNG.random()))
        c = _click(70) * (0.9 - 0.08 * i)
        out[at:at + c.size] += c
    return out


def crawler_chitter() -> np.ndarray:
    out = np.zeros(int(RATE * 0.9))
    at = 0.02
    gap = 0.07
    while at < 0.85:
        c = _click(60)
        i = int(RATE * at)
        out[i:i + c.size] += c * (0.5 + 0.5 * at / 0.9)
        at += gap
        gap = max(0.025, gap * 0.9)
    tt = t(0.9)
    tone_up = tone(1800 + 900 * tt, (1.0,)) * 0.06 * (tt / 0.9)
    return out + tone_up


def crawler_hurt() -> np.ndarray:
    out = np.zeros(int(RATE * 0.35))
    for i in range(2):
        c = _click(80)
        at = int(RATE * i * 0.05)
        out[at:at + c.size] += c
    tt = t(0.22)
    eek = tone(1400 + 600 * np.sin(np.pi * tt / 0.22), (1.0, 0.2)) * env(tt.size, 0.005, 0.08) * 0.6
    at = int(RATE * 0.12)
    out[at:at + eek.size] += eek[: out.size - at]
    return out


def mother_hum() -> np.ndarray:
    tt = t(1.4)
    hum = tone(np.full(tt.size, 110.0) + 4 * np.sin(2 * np.pi * 2.5 * tt), (1.0, 0.6, 0.3, 0.15))
    swell = np.sin(np.pi * tt / 1.4) ** 1.5
    glow = tone(np.full(tt.size, 880.0) + 30 * np.sin(2 * np.pi * 5 * tt), (1.0,)) * 0.08 * swell
    return (hum * swell * 0.7 + glow) * env(tt.size, 0.05, 0.2)


def mother_spores() -> np.ndarray:
    tt = t(1.1)
    whoosh = _noise(tt.size, 10) * np.sin(np.pi * tt / 1.1) ** 2
    sparkles = np.zeros(tt.size)
    for i in range(10):
        at = int(RATE * (0.2 + 0.08 * i))
        n = int(RATE * 0.12)
        bt = np.arange(n) / RATE
        sparkles[at:at + n] += np.sin(2 * np.pi * (2000 + 150 * (i % 4)) * bt) * decay(n, 25) * 0.18
    return (whoosh * 0.7 + sparkles) * env(tt.size, 0.05, 0.15)


def mother_puff() -> np.ndarray:
    tt = t(0.9)
    poof = _noise(tt.size, 25) * decay(tt.size, 6) * 1.2
    thump = tone(np.full(tt.size, 120.0) * np.exp(-tt * 3), (1.0, 0.3)) * decay(tt.size, 9) * 0.6
    sparkles = np.zeros(tt.size)
    for i in range(8):
        at = int(RATE * (0.15 + 0.07 * i))
        n = int(RATE * 0.1)
        bt = np.arange(n) / RATE
        sparkles[at:at + n] += np.sin(2 * np.pi * (2400 - 120 * i) * bt) * decay(n, 30) * 0.15
    return (poof + thump + sparkles) * env(tt.size, 0.005, 0.2)


def mother_ring() -> np.ndarray:
    tt = t(1.0)
    rate = 4 + 10 * tt
    whirl = 0.6 + 0.4 * np.sin(2 * np.pi * np.cumsum(rate) / RATE)
    sweep = _noise(tt.size, 8) * whirl * np.sin(np.pi * tt / 1.0) ** 1.2
    return sweep * env(tt.size, 0.03, 0.15)


def echo_click() -> np.ndarray:
    tt = t(0.08)
    tick = tone(np.full(tt.size, 3200.0), (1.0, 0.3)) * decay(tt.size, 90)
    tick[:80] += _click(80) * 0.3
    return tick


def drip_plink() -> np.ndarray:
    tt = t(0.45)
    f = 900 + 1400 * np.exp(-tt * 40)
    return tone(f, (1.0, 0.2)) * decay(tt.size, 11) * env(tt.size, 0.002, 0.1)


def fizz() -> np.ndarray:
    tt = t(1.0)
    hiss = _noise(tt.size, 2) * 0.25 * np.sin(np.pi * tt / 1.0)
    pops = np.zeros(tt.size)
    for i in range(40):
        at = int(RATE * (0.05 + 0.9 * RNG.random()))
        c = _click(30) * (0.3 + 0.4 * RNG.random())
        pops[at:at + c.size] += c[: tt.size - at]
    return (hiss + pops) * env(tt.size, 0.03, 0.2)


if __name__ == "__main__":
    for name, fn, peak in [("spore_puff", spore_puff, 0.45), ("spore_swell", spore_swell, 0.5),
            ("spore_hurt", spore_hurt, 0.5), ("crawler_click", crawler_click, 0.4), ("crawler_chitter", crawler_chitter, 0.45),
            ("crawler_hurt", crawler_hurt, 0.5), ("mother_hum", mother_hum, 0.55), ("mother_spores", mother_spores, 0.5),
            ("mother_puff", mother_puff, 0.55), ("mother_ring", mother_ring, 0.5), ("echo_click", echo_click, 0.6),
            ("drip_plink", drip_plink, 0.5), ("fizz", fizz, 0.45)]:
        save(name, fn(), peak)
    print("GLOW sounds saved to assets/audio/sfx/")
