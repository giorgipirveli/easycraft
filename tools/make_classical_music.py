#!/usr/bin/env python3
"""Builds the classical pieces in assets/music/classical/ (owner feedback #31, the audio pass).

Every recording is public domain or CC0 **as a recording** (the compositions are all long out of copyright);
the licence was read on each file's own Wikimedia Commons page (the `license` column; the page is `page`).
Eine kleine Nachtmusik is our own rendering of the public-domain Mutopia score (#900) with the small
synthesiser below (no soundfont, no samples).

For each piece the tool downloads the source (cached in ~/.cache/easycraft-music/classical), cuts an
excerpt of 1.5-3 minutes that ends at a quiet moment (a phrase end) with a gentle fade, evens out the
loudness and encodes Ogg Vorbis (mono for solo piano, stereo for orchestras) at 32 kHz. It prints the
length and size of every file; Godot imports them without loop (a piece plays once, then MusicPlan picks
the next).

Needs numpy and ffmpeg with libvorbis.   python3 tools/make_classical_music.py [piece ids...]
"""
import json
import os
import struct
import subprocess
import sys
import urllib.parse

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "music", "classical")
CACHE = os.path.expanduser("~/.cache/easycraft-music/classical")
UA = "EasyCraftAudioPass/1.0 (game asset build; https://commons.wikimedia.org)"
RATE = 32000
TARGET_RMS_DB = -19.0      # a little under the game loops (-18): classical has quiet passages
PEAK_DB = -1.0
FADE_OUT = 3.0             # seconds of fade at the end of an excerpt
COMMONS = "https://commons.wikimedia.org/wiki/"

# id: what, who, where from, which part.
#   start: where the excerpt begins (s); span: (shortest, longest) excerpt in seconds; the cut falls at the
#   quietest moment in the last third of the span. channels 1 = mono. q = Vorbis quality.
PIECES = {
    "fur_elise": {
        "composer": "Beethoven", "title": "Für Elise",
        "performer": "Gaodifan (V Gao)", "file": "File:FurElise.ogg",
        "license": "PD-self + CC0 (released by the performer)",
        "start": 0.0, "span": (100.0, 150.0), "channels": 1, "q": 2,
    },
    "ode_to_joy": {
        "composer": "Beethoven", "title": "Ode to Joy (Symphony No. 9)",
        "performer": "United States Air Force Band of the Rockies, Concert Band",
        "file": "File:Ode to Joy - Concert Band - United States Air Force Band of the Rockies.mp3",
        "license": "PD-USGov-Military-Air Force (performance and recording)",
        "start": 0.0, "span": (110.0, 170.0), "channels": 2, "q": 1,
    },
    "moonlight": {
        "composer": "Beethoven", "title": "Moonlight Sonata",
        "performer": "Paul Pitman for Musopen",
        "file": "File:Ludwig van Beethoven - sonata no. 14 in c sharp minor 'moonlight', op. 27 no. 2 - i. adagio sostenuto.ogg",
        "license": "PD-author (Musopen: recording released into the public domain)",
        "start": 0.0, "span": (120.0, 170.0), "channels": 1, "q": 2,
    },
    "nachtmusik": {
        "composer": "Mozart", "title": "Eine kleine Nachtmusik",
        "performer": "EasyCraft music box (our own rendering of the Mutopia score)",
        "midi": "https://www.mutopiaproject.org/ftp/MozartWA/KV525/eine-kleine-nachtmusik-mvt1/eine-kleine-nachtmusik-mvt1.mid",
        "page": "https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=900",
        "license": "score: Public Domain (Mutopia #900); rendering: original work",
        "start": 0.0, "span": (95.0, 130.0), "channels": 2, "q": 2,
    },
    "figaro": {
        "composer": "Mozart", "title": "The Marriage of Figaro: Overture",
        "performer": "Musopen Symphony (Czech National Symphony Orchestra)",
        "file": "File:Mozart - Le nozze di Figaro, K492 - Overture (Musopen Symphony).flac",
        "license": "PD-author (Musopen)",
        "start": 0.0, "span": (120.0, 175.0), "channels": 2, "q": 1,
    },
    "symphony_40": {
        "composer": "Mozart", "title": "Symphony No. 40",
        "performer": "Musopen Symphony (Czech National Symphony Orchestra)",
        "file": "File:Mozart - Symphony No. 40 in G minor, K550 - I. Molto allegro (Musopen Symphony).flac",
        "license": "PD-author (Musopen)",
        "start": 0.0, "span": (100.0, 150.0), "channels": 2, "q": 1,
    },
    "air": {
        "composer": "Bach", "title": "Air on the G String",
        "performer": "Air Force Strings, United States Air Force Band",
        "file": "File:Air - Air Force Strings - United States Air Force Band.mp3",
        "license": "PD-USGov-Military-Air Force (performance and recording)",
        "start": 0.0, "span": (120.0, 175.0), "channels": 2, "q": 1,
    },
    "goldberg_aria": {
        "composer": "Bach", "title": "Goldberg Variations: Aria",
        "performer": "Shelley Katz for Musopen",
        "file": "File:Bach, Goldberg Variations, Aria (Musopen version).ogg",
        "license": "CC0 (Musopen)",
        "start": 0.0, "span": (110.0, 160.0), "channels": 1, "q": 2,
    },
    "morning_mood": {
        "composer": "Grieg", "title": "Morning Mood",
        "performer": "Musopen Symphony (Czech National Symphony Orchestra)",
        "file": "File:Musopen - Morning.ogg",
        "license": "PD-author (Musopen)",
        "start": 0.0, "span": (120.0, 170.0), "channels": 2, "q": 1,
    },
    "mountain_king": {
        "composer": "Grieg", "title": "In the Hall of the Mountain King",
        "performer": "Musopen Symphony (Czech National Symphony Orchestra)",
        "file": "File:Musopen - In the Hall Of The Mountain King.ogg",
        "license": "PD-author (Musopen)",
        "start": 0.0, "span": (140.0, 160.0), "channels": 2, "q": 1,
    },
    "waltz_flowers": {
        "composer": "Tchaikovsky", "title": "Waltz of the Flowers (The Nutcracker)",
        "performer": "United States Air Force Band, Concert Band (arr. Lawrence Odom)",
        "file": "File:Waltz of the Flowers - Concert Band - United States Air Force Band.mp3",
        "license": "PD-USGov-Military-Air Force (arrangement, performance and recording)",
        "start": 0.0, "span": (120.0, 170.0), "channels": 2, "q": 1,
    },
    "spring": {
        "composer": "Vivaldi", "title": "Spring (The Four Seasons)",
        "performer": "The Modena Chamber Orchestra (Musopen)",
        "file": "File:The Modena Chamber Orchestra - Vivaldi's Spring, RV 269 - I. Allegro.ogg",
        "license": "Public Domain Mark by the owner (Musopen)",
        "start": 0.0, "span": (110.0, 160.0), "channels": 2, "q": 1,
    },
    "gymnopedie": {
        "composer": "Satie", "title": "Gymnopédie No. 1",
        "performer": "Robin Alciatore (Musopen)",
        "file": "File:Erik Satie - gymnopedies - la 1 ere. lent et douloureux.ogg",
        "license": "PD-author (Musopen)",
        "start": 0.0, "span": (120.0, 184.0), "channels": 1, "q": 2,
    },
    # M5 Task 2 (spec §15.2): Frostpeak's and the Candy Kingdom's own pieces (MusicPieces "own": they play only
    # where they are a universe's favourite).
    "winter_largo": {
        "composer": "Vivaldi", "title": "Winter (The Four Seasons): Largo",
        "performer": "The Modena Chamber Orchestra (Musopen)",
        "file": "File:The Modena Chamber Orchestra - Vivaldi's Winter, RV 297 - II. Largo.ogg",
        "license": "Public Domain Mark by the owner (Musopen)",
        "start": 0.0, "span": (110.0, 160.0), "channels": 2, "q": 1,
    },
    "snow_dancing": {
        "composer": "Debussy", "title": "The Snow Is Dancing",
        "performer": "Pracchia-78 (a virtual piano)",
        "file": "File:Claude Debussy - Children's Corner.ogg",
        "license": "PD-self (released into the public domain by the author)",
        "start": 569.6, "span": (135.0, 145.0), "channels": 1, "q": 2,
    },
    "minute_waltz": {
        "composer": "Chopin", "title": "Minute Waltz",
        "performer": "Musopen (the pianist is not named)",
        "file": "File:Waltz Op. 64 no. 1 in D flat major.mp3",
        "license": "CC0 (Musopen)",
        "start": 0.0, "span": (100.0, 115.0), "channels": 1, "q": 2,
    },
    "bumblebee": {
        "composer": "Rimsky-Korsakov", "title": "Flight of the Bumblebee",
        "performer": "Strolling Strings, United States Air Force Band",
        "file": "File:Flight of the Bumblebee - Strolling Strings - United States Air Force Band.mp3",
        "license": "PD-USGov-Military-Air Force (performance and recording)",
        "start": 0.0, "span": (70.0, 82.0), "channels": 2, "q": 1,
    },
}


def curl(url: str, dst: str = "") -> str:
    args = ["curl", "-s", "-L", "--fail", "--retry", "3", "-A", UA]
    if dst:
        subprocess.run(args + ["-o", dst, url], check=True)
        return dst
    return subprocess.run(args + [url], check=True, capture_output=True, text=True).stdout


def page_url(p: dict) -> str:
    return p.get("page") or COMMONS + urllib.parse.quote(p["file"].replace(" ", "_"))


def source(pid: str, p: dict) -> str:
    os.makedirs(CACHE, exist_ok=True)
    if "midi" in p:
        dst = os.path.join(CACHE, pid + ".mid")
        if not os.path.exists(dst):
            curl(p["midi"], dst)
        return dst
    info = json.loads(curl("https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
        "action": "query", "format": "json", "titles": p["file"], "prop": "imageinfo", "iiprop": "url"})))
    url = next(iter(info["query"]["pages"].values()))["imageinfo"][0]["url"].split("?", 1)[0]
    dst = os.path.join(CACHE, urllib.parse.unquote(url.rsplit("/", 1)[1]))
    if not os.path.exists(dst):
        curl(url, dst)
    return dst


def decode(path: str, channels: int) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", str(channels), "-ar", str(RATE), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, channels).astype(np.float64)


def db(x: float) -> float:
    return 20.0 * np.log10(max(x, 1e-12))


def excerpt(a: np.ndarray, start: float, span: tuple) -> tuple:
    """Cut [start, cut]: `cut` is the quietest 0.4 s in the last third of the span (a breath between
    phrases), so the fade-out rounds off a phrase instead of chopping a note."""
    a = a[int(start * RATE):]
    lo, hi = span
    total = len(a) / RATE
    if total <= hi:                                  # the whole (rest of the) piece fits
        return a, total, "whole"
    mono = np.abs(a).mean(axis=1)
    win = int(0.4 * RATE)
    first = int((lo + (hi - lo) * 0.34) * RATE)
    last = int(hi * RATE)
    sq = np.concatenate(([0.0], np.cumsum(mono[first - win // 2:last + win // 2] ** 2)))
    energy = (sq[win:] - sq[:-win])[: last - first] / win       # moving mean square, centred (cumulative sums)
    i = int(np.argmin(energy)) + first
    return a[:i], i / RATE, "cut at %.1f s (%.1f dB)" % (i / RATE, db(np.sqrt(energy.min())))


def shape(a: np.ndarray, faded: bool) -> np.ndarray:
    n = len(a)
    env = np.ones(n)
    fin = int(0.02 * RATE)
    env[:fin] = np.linspace(0.0, 1.0, fin)
    if faded:
        fout = int(FADE_OUT * RATE)
        env[n - fout:] *= np.cos(np.linspace(0.0, np.pi / 2, fout)) ** 2
    else:
        fout = int(0.05 * RATE)
        env[n - fout:] *= np.linspace(1.0, 0.0, fout)
    # trim the silence before the first note
    mono = np.abs(a).mean(axis=1)
    on = int(np.argmax(mono > 10 ** (-50 / 20)))
    a = a * env[:, None]
    return a[max(on - int(0.05 * RATE), 0):]


def loudness(a: np.ndarray) -> np.ndarray:
    # RMS over the louder half of 1 s blocks, so a quiet intro does not push the whole piece up
    blocks = [np.sqrt(np.mean(a[i:i + RATE] ** 2)) for i in range(0, len(a) - RATE, RATE)] or [np.sqrt(np.mean(a ** 2))]
    blocks = sorted(blocks)[len(blocks) // 2:]
    rms = float(np.sqrt(np.mean(np.square(blocks))))
    gain = 10 ** ((TARGET_RMS_DB - db(rms)) / 20)
    peak = float(np.abs(a).max()) * gain
    if peak > 10 ** (PEAK_DB / 20):
        gain *= 10 ** (PEAK_DB / 20) / peak
    return a * gain


def encode(a: np.ndarray, dst: str, q: int) -> None:
    ch = a.shape[1]
    pcm = np.clip(a, -1.0, 1.0).astype(np.float32).tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(ch), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(q), dst], input=pcm, check=True)


# --- A small synthesiser for our own renderings (music box, soft marimba, plucked bass) --------------

def read_midi(path: str) -> list:
    """[(start s, length s, pitch, velocity 0..1, track)] from a Standard MIDI File (format 0 or 1)."""
    data = open(path, "rb").read()
    assert data[:4] == b"MThd"
    _, fmt, ntrk, div = struct.unpack(">IHHH", data[4:14])
    pos = 8 + struct.unpack(">I", data[4:8])[0]
    tracks = []
    for _ in range(ntrk):
        assert data[pos:pos + 4] == b"MTrk", data[pos:pos + 4]
        ln = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        tracks.append(data[pos + 8:pos + 8 + ln])
        pos += 8 + ln
    events = []          # (tick, kind, track, a, b)
    for ti, t in enumerate(tracks):
        i, tick, status = 0, 0, 0
        while i < len(t):
            delta = 0
            while True:
                c = t[i]
                i += 1
                delta = (delta << 7) | (c & 0x7F)
                if c < 0x80:
                    break
            tick += delta
            c = t[i]
            if c == 0xFF:
                typ, i = t[i + 1], i + 2
                ln = 0
                while True:
                    c = t[i]
                    i += 1
                    ln = (ln << 7) | (c & 0x7F)
                    if c < 0x80:
                        break
                if typ == 0x51:
                    events.append((tick, "tempo", ti, int.from_bytes(t[i:i + 3], "big"), 0))
                i += ln
                continue
            if c in (0xF0, 0xF7):
                i += 1
                ln = 0
                while True:
                    c = t[i]
                    i += 1
                    ln = (ln << 7) | (c & 0x7F)
                    if c < 0x80:
                        break
                i += ln
                continue
            if c & 0x80:
                status = c
                i += 1
            kind = status & 0xF0
            if kind in (0xC0, 0xD0):
                i += 1
                continue
            a, b = t[i], t[i + 1]
            i += 2
            if kind == 0x90 and b > 0:
                events.append((tick, "on", ti, a, b))
            elif kind == 0x80 or (kind == 0x90 and b == 0):
                events.append((tick, "off", ti, a, 0))
    events.sort(key=lambda e: (e[0], 0 if e[1] == "tempo" else 1))
    # ticks -> seconds through the tempo map
    tempo, last_tick, last_sec = 500000, 0, 0.0
    notes, open_ = [], {}
    for tick, kind, ti, a, b in events:
        sec = last_sec + (tick - last_tick) * tempo / 1e6 / div
        last_tick, last_sec = tick, sec
        if kind == "tempo":
            tempo = a
        elif kind == "on":
            open_.setdefault((ti, a), []).append((sec, b / 127.0))
        elif kind == "off" and open_.get((ti, a)):
            s, v = open_[(ti, a)].pop(0)
            notes.append((s, max(sec - s, 0.05), a, v, ti))
    return sorted(notes)


def voice(freq: float, length: float, vel: float, timbre: str) -> np.ndarray:
    """One note. music box: bright bell partials, long ring; marimba: warm, shorter; bass: plucked."""
    ring = {"box": 1.6, "marimba": 0.9, "bass": 1.1}[timbre]
    n = int((max(length, 0.12) + ring) * RATE)
    t = np.arange(n) / RATE
    if timbre == "box":
        partials = [(1.0, 1.0, 1.0), (2.0, 0.28, 2.2), (3.0, 0.07, 3.5), (4.07, 0.12, 4.5), (6.3, 0.03, 7.0)]
        decay = 2.4
    elif timbre == "marimba":
        partials = [(1.0, 1.0, 1.0), (3.93, 0.16, 4.0), (9.2, 0.03, 9.0)]
        decay = 4.2
    else:
        partials = [(1.0, 1.0, 1.0), (2.0, 0.45, 1.8), (3.0, 0.18, 2.8), (4.0, 0.08, 3.6)]
        decay = 3.0
    s = np.zeros(n)
    for ratio, amp, dk in partials:
        f = freq * ratio
        if f < RATE * 0.45:
            s += amp * np.sin(2 * np.pi * f * t) * np.exp(-t * decay * dk * (0.7 + freq / 1200.0))
    attack = int(0.004 * RATE)
    s[:attack] *= np.linspace(0.0, 1.0, attack)
    rel = int(0.08 * RATE)
    end = min(int((length + ring * 0.5) * RATE), n - rel)
    s[end:end + rel] *= np.linspace(1.0, 0.0, rel)
    s[end + rel:] = 0.0
    return s * vel


def reverb(a: np.ndarray, seconds: float = 1.6, mix: float = 0.22) -> np.ndarray:
    """A soft room: convolution with decaying noise (FFT), different per channel for width."""
    rng = np.random.default_rng(525)
    n = int(seconds * RATE)
    out = np.empty_like(a)
    for c in range(a.shape[1]):
        ir = rng.standard_normal(n) * np.exp(-np.arange(n) / RATE * 6.9 / seconds)
        ir[: int(0.012 * RATE)] = 0.0
        ir /= np.sqrt(np.sum(ir ** 2))
        size = 1 << int(np.ceil(np.log2(len(a) + n)))
        wet = np.fft.irfft(np.fft.rfft(a[:, c], size) * np.fft.rfft(ir, size), size)[: len(a)]
        out[:, c] = a[:, c] * (1.0 - mix) + wet * mix * 2.0
    return out


def render(midi_path: str, seconds: float) -> np.ndarray:
    notes = [n for n in read_midi(midi_path) if n[0] < seconds]
    tracks = sorted({n[4] for n in notes})
    # the highest track sings (music box), the lowest plucks (bass), the middle ones are soft marimbas
    by_pitch = sorted(tracks, key=lambda ti: -np.mean([n[2] for n in notes if n[4] == ti]))
    role = {ti: ("box" if i == 0 else "bass" if i == len(by_pitch) - 1 else "marimba") for i, ti in enumerate(by_pitch)}
    gain = {"box": 0.55, "marimba": 0.22, "bass": 0.34}
    pan = {"box": 0.0, "marimba": 0.35, "bass": -0.25}
    out = np.zeros((int((seconds + 3.0) * RATE), 2))
    flip = 1.0
    for start, length, pitch, vel, ti in notes:
        r = role[ti]
        freq = 440.0 * 2 ** ((pitch - 69) / 12.0)
        s = voice(freq, length, 0.6 + 0.4 * vel, r) * gain[r]
        i = int(start * RATE)
        s = s[: len(out) - i]
        p = pan[r] * (flip if r == "marimba" else 1.0)
        flip = -flip
        out[i:i + len(s), 0] += s * np.sqrt(0.5 * (1.0 - p))
        out[i:i + len(s), 1] += s * np.sqrt(0.5 * (1.0 + p))
    return reverb(out)


def build(pid: str, p: dict) -> None:
    src = source(pid, p)
    if "midi" in p:
        a = render(src, p["span"][1] + 4.0)
        if p["channels"] == 1:
            a = a.mean(axis=1, keepdims=True)
    else:
        a = decode(src, p["channels"])
    cut, length, how = excerpt(a, p["start"], p["span"])
    a = loudness(shape(cut, how != "whole"))
    os.makedirs(OUT, exist_ok=True)
    dst = os.path.join(OUT, pid + ".ogg")
    encode(a, dst, p["q"])
    got = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration,bit_rate", "-of", "json", dst],
                                    capture_output=True, text=True).stdout)["format"]
    print("%-14s %6.1f s  %5d KB  %3d kbps  %s  %s" % (pid, float(got["duration"]), os.path.getsize(dst) // 1024,
                                                     int(got.get("bit_rate", 0)) // 1000, how, page_url(p)))


def main() -> None:
    wanted = sys.argv[1:] or list(PIECES)
    for pid in wanted:
        build(pid, PIECES[pid])


if __name__ == "__main__":
    main()
