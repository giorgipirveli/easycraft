#!/usr/bin/env python3
"""Builds the Candy Kingdom's music loops (M3 Task 4, spec §14.1) — an original little waltz, composed and
synthesised here (original work, CC0 like everything this project makes):

  candy_day.ogg    "Candy Waltz": a music-box celesta tune over an oom-pah-pah of soft bells and a plucked
                   bass, C major, 3/4 at 138 bpm, 32 bars (the second time round a glockenspiel doubles it)
  candy_night.ogg  "Sugar Lullaby": the same tune slowed to 92 bpm, an octave lower and softer, over held
                   chords, 16 bars

Every note is rendered into a buffer exactly one loop long; what still rings past the end is added back at the
start, so the loop has no seam. Loudness is evened out like tools/make_music.py (whose helpers this uses) and
each loop is encoded as a small stereo Ogg Vorbis.

The owner loves classical music (feedback #31): the kingdom's descriptor names the Nutcracker pieces that fit
it (world/universes/candy.gd `classical`) for the audio pass, which may render one of them into these same files.

Run from the project root:  python3 tools/make_candy_music.py   (needs numpy and ffmpeg with libvorbis)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_music as base  # noqa: E402  (normalize, encode, decode, seam_report)

RATE = 32000
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(name: str) -> float:
    """'C#5' -> Hz (A4 = 440)."""
    letter, rest = name[0], name[1:]
    shift = 0
    if rest and rest[0] in "#b":
        shift = 1 if rest[0] == "#" else -1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + NOTE[letter] + shift
    return 440.0 * 2 ** ((midi - 69) / 12)


# The tune: one entry per beat (3 a bar), "-" holds the note before, "." is a rest.
MELODY = [
    "E5 G5 C6", "B5 A5 G5", "D5 F5 B5", "A5 G5 F5", "C5 F5 A5", "G5 E5 C5", "D5 G5 F5", "E5 - .",
    "A5 C6 E6", "D6 C6 A5", "G5 C6 E6", "D6 - B5", "A5 C6 F6", "E6 D6 C6", "B5 D6 G5", "C6 - .",
]
# A chord a bar: the bass note, then the chord for beats 2 and 3.
CHORDS = [
    ("C3", "C4 E4 G4"), ("C3", "C4 E4 G4"), ("G2", "B3 D4 F4"), ("G2", "B3 D4 F4"),
    ("F2", "A3 C4 F4"), ("C3", "C4 E4 G4"), ("G2", "B3 D4 F4"), ("C3", "C4 E4 G4"),
    ("A2", "A3 C4 E4"), ("F2", "A3 C4 F4"), ("C3", "C4 E4 G4"), ("G2", "B3 D4 G4"),
    ("F2", "A3 C4 F4"), ("G2", "C4 E4 G4"), ("G2", "B3 D4 F4"), ("C3", "C4 E4 G4"),
]


def bell(freq: float, seconds: float, bright: float = 1.0) -> np.ndarray:
    """A celesta or music-box note: a few inharmonic partials that ring down, a soft click at the start."""
    t = np.arange(int(RATE * seconds)) / RATE
    x = np.zeros(t.size)
    for ratio, amp, rate in [(1.0, 1.0, 3.2), (2.0, 0.35 * bright, 5.0), (3.01, 0.18 * bright, 8.0), (4.2, 0.1 * bright, 12.0)]:
        x += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t * rate)
    attack = np.minimum(t / 0.004, 1.0)
    return x * attack


def pluck(freq: float, seconds: float) -> np.ndarray:
    """A soft plucked bass (pizzicato-like): a round tone that dies away quickly."""
    t = np.arange(int(RATE * seconds)) / RATE
    x = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * 2 * freq * t) * np.exp(-t * 8)
    return x * np.exp(-t * 4.5) * np.minimum(t / 0.006, 1.0)


def pad(freq: float, seconds: float) -> np.ndarray:
    """A held, breathing chord tone for the night."""
    t = np.arange(int(RATE * seconds)) / RATE
    x = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 2 * freq * t)
    return x * np.sin(np.pi * np.clip(t / seconds, 0, 1)) ** 2


def add(buf: np.ndarray, at: int, note: np.ndarray, gain: float, pan: float) -> None:
    """Adds a mono note into the stereo loop at sample `at`, wrapping round the end (a seamless loop)."""
    left, right = gain * (1 - pan) * 0.5 * 2 ** 0.5, gain * (1 + pan) * 0.5 * 2 ** 0.5
    idx = (at + np.arange(note.size)) % buf.shape[0]
    np.add.at(buf[:, 0], idx, note * left)
    np.add.at(buf[:, 1], idx, note * right)


def melody_notes() -> list:
    """(beat index, note name, beats held) for the whole tune."""
    out = []
    beats = [b for bar in MELODY for b in bar.split()]
    for i, b in enumerate(beats):
        if b in "-.":
            continue
        held = 1
        while i + held < len(beats) and beats[i + held] == "-":
            held += 1
        out.append((i, b, held))
    return out


def transpose(name: str, octaves: int) -> str:
    return name[:-1] + str(int(name[-1]) + octaves)


def day() -> np.ndarray:
    bpm, bars = 138.0, 32
    beat = int(round(RATE * 60.0 / bpm))
    buf = np.zeros((beat * 3 * bars, 2))
    tune = melody_notes()
    for rep in range(2):
        start = rep * 16 * 3
        for i, name, held in tune:
            at = (start + i) * beat
            add(buf, at, bell(hz(name), 0.3 + held * 0.45), 0.55, 0.0)
            if rep == 1:
                add(buf, at, bell(hz(transpose(name, 1)), 0.5, 0.5), 0.18, 0.25)    # the glockenspiel doubles it
        for bar, (bass, chord) in enumerate(CHORDS):
            at = (start + bar * 3) * beat
            add(buf, at, pluck(hz(bass), 0.9), 0.5, -0.1)
            for k in (1, 2):
                for n, name in enumerate(chord.split()):
                    add(buf, at + k * beat, bell(hz(name), 0.5, 0.4), 0.13, -0.35 + 0.35 * n)
    return buf


def night() -> np.ndarray:
    bpm, bars = 92.0, 16
    beat = int(round(RATE * 60.0 / bpm))
    buf = np.zeros((beat * 3 * bars, 2))
    for i, name, held in melody_notes():
        add(buf, i * beat, bell(hz(transpose(name, -1)), 0.6 + held * 0.6, 0.6), 0.5, 0.05)
    for bar, (bass, chord) in enumerate(CHORDS):
        at = bar * 3 * beat
        add(buf, at, pluck(hz(bass), 1.4), 0.45, -0.05)
        for n, name in enumerate(chord.split()):
            add(buf, at, pad(hz(name), 3 * beat / RATE), 0.08, -0.4 + 0.4 * n)
    return buf


def main() -> None:
    os.makedirs(base.OUT, exist_ok=True)
    for name, fn, quality in [("candy_day", day, 2), ("candy_night", night, 2)]:
        y = base.normalize(fn())
        out = os.path.join(base.OUT, name + ".ogg")
        base.encode(y, RATE, quality, out)
        back = base.decode(out, RATE)
        print(f"MUSIC {name}: {len(y) / RATE:.3f} s, {os.path.getsize(out) / 1024:.0f} KB, decoded {len(back)} of "
            f"{len(y)} samples; {base.seam_report(y, RATE)}")


if __name__ == "__main__":
    main()
