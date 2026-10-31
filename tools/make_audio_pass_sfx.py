#!/usr/bin/env python3
"""The audio pass's effects and ambience (owner feedback #27): assets/audio/sfx/*.ogg and
assets/audio/ambience/*.ogg.

Three kinds of source, every one CC0 (the licence was read on each source's own page, 2026-09-24):
- Kenney packs (kenney.nl, "Creative Commons CC0" on each pack page): Interface Sounds, Impact Sounds,
  RPG Audio, Music Jingles. Used as they are (copied) or lightly derived (pitch, filters, mixes).
- freesound.org sounds whose page says "Creative Commons 0" (the table's `fs`: user/id). The tool
  downloads each page's HQ preview (the same recording, a lossy copy), trims the silence, cuts single
  calls out of longer takes, makes it mono and evens out the level.
- Our own synthesis (numpy/scipy): goblin grunts, the other monsters' hurt voices, the wave horn and
  the wind loop. Original work.

Effects: mono Ogg Vorbis, 32 kHz. Ambience: seamless mono loops (the end cross-faded into the start),
imported with loop=true. Caches downloads in ~/.cache/easycraft-sounds. Prints what it wrote.

Needs numpy, scipy and ffmpeg with libvorbis.
    python3 tools/make_audio_pass_sfx.py [effects|animals|monsters|ambience|pack|universes ...]   (default: effects, ambience)
    (`pack`: owner feedback #41's new animals, the fox and the parrot)
    (`universes`: M5 Task 2, Frostpeak's and the Candy Kingdom's own ambience loops)
"""
import os
import re
import shutil
import subprocess
import zipfile

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
AMB = os.path.join(ROOT, "assets", "audio", "ambience")
CACHE = os.path.expanduser("~/.cache/easycraft-sounds")
RATE = 32000
RNG = np.random.default_rng(20260924)

KENNEY = {
    "interface-sounds": "https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip",
    "impact-sounds": "https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip",
    "rpg-audio": "https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip",
    "music-jingles": "https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip",
}


# --- sources ---------------------------------------------------------------------------------------

def kenney(pack: str, name: str) -> str:
    z = os.path.join(CACHE, pack + ".zip")
    d = os.path.join(CACHE, pack)
    if not os.path.exists(z):
        os.makedirs(CACHE, exist_ok=True)
        subprocess.run(["curl", "-s", "-L", "--fail", "-A", "Mozilla/5.0", "-o", z, KENNEY[pack]], check=True)
    if not os.path.isdir(d):
        zipfile.ZipFile(z).extractall(d)
    for root, _, files in os.walk(d):
        if name in files:
            return os.path.join(root, name)
    raise FileNotFoundError(pack + "/" + name)


def freesound(ref: str) -> str:
    """ref = "user/id". Checks that the page still says CC0, then fetches the HQ preview."""
    user, sid = ref.split("/")
    d = os.path.join(CACHE, "freesound")
    os.makedirs(d, exist_ok=True)
    dst = os.path.join(d, sid + ".mp3")
    if os.path.exists(dst):
        return dst
    page = subprocess.run(["curl", "-s", "-L", "-A", "Mozilla/5.0", "https://freesound.org/people/%s/sounds/%s/" % (user, sid)],
                          capture_output=True, text=True, check=True).stdout
    assert "creativecommons.org/publicdomain/zero/1.0" in page, ref + " is not CC0 on its page"
    hq = re.findall(r'https://cdn\.freesound\.org/previews/[^"\'\s]+?-hq\.mp3', page)
    subprocess.run(["curl", "-s", "-L", "--fail", "-A", "Mozilla/5.0", "-o", dst, hq[0]], check=True)
    return dst


def load(path: str) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


# --- processing -----------------------------------------------------------------------------------

def db(x: float) -> float:
    return 20.0 * np.log10(max(x, 1e-12))


def smooth_env(x: np.ndarray, ms: float = 10.0) -> np.ndarray:
    k = max(int(RATE * ms / 1000.0), 1)
    c = np.concatenate(([0.0], np.cumsum(np.abs(x))))
    e = (c[k:] - c[:-k]) / k
    return np.concatenate((e, np.full(k - 1, e[-1] if len(e) else 0.0)))


def trim(x: np.ndarray, floor_db: float = -38.0) -> np.ndarray:
    """Cuts the silence before and after (relative to the loudest moment), keeping short pads."""
    e = smooth_env(x)
    thr = e.max() * 10 ** (floor_db / 20)
    on = np.nonzero(e > thr)[0]
    if len(on) == 0:
        return x
    a = max(on[0] - int(0.005 * RATE), 0)
    b = min(on[-1] + int(0.06 * RATE), len(x))
    return x[a:b]


def calls(x: np.ndarray, count: int, lo: float = 0.12, hi: float = 0.9, gap: float = 0.08) -> list:
    """The `count` loudest single calls in a longer take: loud stretches split by `gap` s of quiet."""
    e = smooth_env(x, 15.0)
    loud = e > e.max() * 10 ** (-24 / 20)
    parts, i, n = [], 0, len(x)
    while i < n:
        if not loud[i]:
            i += 1
            continue
        j = i
        quiet = 0
        while j < n and quiet < gap * RATE:
            quiet = quiet + 1 if not loud[j] else 0
            j += 1
        a, b = max(i - int(0.01 * RATE), 0), j - int(quiet)
        if lo * RATE <= b - a <= hi * RATE:
            parts.append((float(e[a:b].max()), a, b))
        i = j
    parts.sort(reverse=True)
    return [x[a:b + int(0.05 * RATE)] for _, a, b in sorted(parts[:count], key=lambda p: p[1])]


def fades(x: np.ndarray, fin: float = 0.004, fout: float = 0.03) -> np.ndarray:
    x = x.copy()
    a, b = max(int(fin * RATE), 1), max(int(fout * RATE), 1)
    x[:a] *= np.linspace(0.0, 1.0, a)
    x[-b:] *= np.linspace(1.0, 0.0, b)
    return x


def highpass(x: np.ndarray, hz: float) -> np.ndarray:
    return signal.sosfilt(signal.butter(2, hz, "highpass", fs=RATE, output="sos"), x)


def lowpass(x: np.ndarray, hz: float, order: int = 2) -> np.ndarray:
    return signal.sosfilt(signal.butter(order, hz, "lowpass", fs=RATE, output="sos"), x)


def bandpass(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    return signal.sosfilt(signal.butter(2, [lo, hi], "bandpass", fs=RATE, output="sos"), x)


def pitch(x: np.ndarray, factor: float) -> np.ndarray:
    """Plays it `factor` times faster (higher and shorter), like a tape."""
    n = int(len(x) / factor)
    return np.interp(np.arange(n) * factor, np.arange(len(x)), x)


def level(x: np.ndarray, peak_db: float = -3.0) -> np.ndarray:
    return x / max(np.abs(x).max(), 1e-9) * 10 ** (peak_db / 20)


def rms_level(x: np.ndarray, rms_db: float, peak_db: float = -3.0) -> np.ndarray:
    g = 10 ** ((rms_db - db(float(np.sqrt(np.mean(x ** 2))))) / 20)
    p = np.abs(x).max() * g
    if p > 10 ** (peak_db / 20):
        g *= 10 ** (peak_db / 20) / p
    return x * g


def loop(x: np.ndarray, seconds: float, xfade: float = 4.0, start: float = 0.0) -> np.ndarray:
    """A seamless loop of `seconds`: the `xfade` s after the cut are faded (equal power) over the start."""
    a = int(start * RATE)
    n, f = int(seconds * RATE), int(xfade * RATE)
    body = x[a:a + n + f].copy()
    assert len(body) == n + f, "source too short for the loop"
    t = np.linspace(0.0, np.pi / 2, f)
    body[:f] = body[:f] * np.sin(t) + body[n:n + f] * np.cos(t)
    return body[:n]


def save(path: str, x: np.ndarray, q: int = 3) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = np.clip(x, -1.0, 1.0).astype(np.float32).tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(q), path], input=pcm, check=True)
    print("%-32s %6.2f s %6d B" % (os.path.relpath(path, ROOT), len(x) / RATE, os.path.getsize(path)))


def copy(src: str, name: str) -> None:
    dst = os.path.join(SFX, name)
    shutil.copyfile(src, dst)
    print("%-32s  (copied) %6d B" % (os.path.relpath(dst, ROOT), os.path.getsize(dst)))


def voice(ref: str, peak: float = -3.0, floor: float = -38.0) -> np.ndarray:
    return fades(level(highpass(trim(load(freesound(ref)), floor), 90.0), peak))


# --- synthesis (original work) ----------------------------------------------------------------------

def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def env(n: int, attack: float = 0.01, release: float = 0.08) -> np.ndarray:
    e = np.ones(n)
    a, r = max(int(RATE * attack), 1), max(int(RATE * release), 1)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def buzz(f0: np.ndarray) -> np.ndarray:
    """A voice's buzz (band-limited sawtooth-ish pulse) following f0 (Hz per sample)."""
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    return sum(np.sin(k * phase) / k for k in range(1, 18))


def formants(x: np.ndarray, peaks: list) -> np.ndarray:
    out = np.zeros_like(x)
    for f, gain, q in peaks:
        b, a = signal.iirpeak(f, q, fs=RATE)
        out += gain * signal.lfilter(b, a, x)
    return out


def grunt(f_start: float, f_end: float, seconds: float, vowel: list, rough: float) -> np.ndarray:
    n = int(seconds * RATE)
    f0 = np.linspace(f_start, f_end, n) * (1.0 + 0.03 * np.sin(2 * np.pi * 7.0 * t(seconds)))
    src = buzz(f0) + rough * RNG.standard_normal(n) * 0.4
    x = formants(src, vowel) * env(n, 0.015, seconds * 0.45)
    return fades(level(lowpass(x, 4200.0)))


UH = [(600, 1.0, 5), (1100, 0.6, 6), (2400, 0.25, 8)]
OH = [(450, 1.0, 5), (850, 0.7, 6), (2300, 0.2, 8)]
EE = [(300, 0.9, 5), (2200, 0.7, 7), (3000, 0.35, 8)]
AH = [(750, 1.0, 5), (1250, 0.8, 6), (2600, 0.3, 8)]


def goblin_grunts() -> list:
    return [grunt(150, 110, 0.32, UH, 0.25), grunt(170, 140, 0.24, OH, 0.2), grunt(130, 175, 0.28, AH, 0.3)]


def goblin_ouch() -> np.ndarray:
    return grunt(320, 190, 0.3, AH, 0.15)


def slime_ouch() -> np.ndarray:
    n = int(0.28 * RATE)
    f = np.geomspace(900, 380, n)
    x = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t(0.28) * 9) + 0.3 * lowpass(RNG.standard_normal(n), 1400) * np.exp(-t(0.28) * 25)
    return fades(level(x))


def mummy_ouch() -> np.ndarray:
    return grunt(115, 85, 0.5, OH, 0.5)


def scorpion_click() -> np.ndarray:
    x = np.zeros(int(0.45 * RATE))
    for i, at in enumerate([0.0, 0.07, 0.12, 0.21, 0.26, 0.34]):
        a = int(at * RATE)
        n = int(0.012 * RATE)
        c = bandpass(RNG.standard_normal(n), 2500 + 400 * (i % 3), 6500) * np.exp(-np.arange(n) / n * 5)
        x[a:a + n] += c * (0.7 + 0.3 * (i % 2))
    return fades(level(x))


def scorpion_ouch() -> np.ndarray:
    n = int(0.3 * RATE)
    f = np.linspace(1500, 900, n)
    x = buzz(f) * 0.3 + bandpass(RNG.standard_normal(n), 2000, 7000)
    return fades(level(x * env(n, 0.005, 0.2)))


def horn() -> np.ndarray:
    """The wave-start horn: two long brass notes, a fifth up, with a soft vibrato."""
    out = np.zeros(int(1.9 * RATE))
    for at, f, dur in [(0.0, 196.0, 0.55), (0.5, 293.7, 1.25)]:
        n = int(dur * RATE)
        tt = t(dur)
        f0 = f * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * tt) * np.clip(tt / 0.4, 0, 1))
        x = buzz(f0)
        bright = np.clip(tt / 0.12, 0, 1)
        x = lowpass(x, 900.0) * (1 - 0.5 * bright) + lowpass(x, 2600.0) * 0.5 * bright
        x = x * env(n, 0.06, 0.3)
        a = int(at * RATE)
        out[a:a + n] += x
    return fades(level(out), fout=0.1)


def wind_loop(seconds: float) -> np.ndarray:
    """Soft wind: noise through a slowly wandering band-pass, with gusts (original work)."""
    global RNG
    RNG = np.random.default_rng(3601)   # every part has its own seed: running one part alone gives the same file
    n = int((seconds + 4.0) * RATE)
    noise = RNG.standard_normal(n)
    slow = lowpass(RNG.standard_normal(n), 0.35, 1)
    slow = (slow - slow.min()) / (slow.max() - slow.min())
    gust = lowpass(RNG.standard_normal(n), 0.8, 1)
    gust = (gust - gust.min()) / (gust.max() - gust.min())
    low = lowpass(noise, 420.0, 2)
    mid = bandpass(noise, 500.0, 1400.0)
    x = low * (0.6 + 0.6 * gust) + mid * (0.15 + 0.5 * slow * gust)
    return loop(x, seconds)


# --- the table -------------------------------------------------------------------------------------

def effects() -> None:
    os.makedirs(SFX, exist_ok=True)
    # UI: a softer switch for toggles, a tick for the hotbar, a pop for pickups, a clink for gold
    copy(kenney("interface-sounds", "toggle_001.ogg"), "ui_toggle.ogg")
    copy(kenney("interface-sounds", "tick_002.ogg"), "ui_tick.ogg")
    copy(kenney("interface-sounds", "pluck_001.ogg"), "pickup_pop.ogg")
    save(os.path.join(SFX, "gold_clink.ogg"), fades(level(trim(load(kenney("rpg-audio", "handleCoins2.ogg")))), 0.002, 0.05))
    # jingles: level up, goal done, new badge
    copy(kenney("music-jingles", "jingles_STEEL02.ogg"), "jingle_level.ogg")
    copy(kenney("music-jingles", "jingles_PIZZI03.ogg"), "jingle_goal.ogg")
    copy(kenney("music-jingles", "jingles_PIZZI12.ogg"), "jingle_badge.ogg")
    # footsteps by block (grass: the existing step_*.ogg)
    for i in range(5):
        copy(kenney("impact-sounds", "footstep_concrete_%03d.ogg" % i), "step_stone_%d.ogg" % (i + 1))
        copy(kenney("impact-sounds", "footstep_wood_%03d.ogg" % i), "step_wood_%d.ogg" % (i + 1))
        copy(kenney("impact-sounds", "footstep_snow_%03d.ogg" % i), "step_snow_%d.ogg" % (i + 1))
        copy(kenney("impact-sounds", "footstep_carpet_%03d.ogg" % i), "step_cloth_%d.ogg" % (i + 1))
    for i, n in enumerate([0, 1, 2, 8, 9]):
        copy(kenney("rpg-audio", "footstep%02d.ogg" % n), "step_dirt_%d.ogg" % (i + 1))
    for i in range(4):   # sand: snow crunch, lower and duller; leaves: grass with a dry crackle
        snow = load(kenney("impact-sounds", "footstep_snow_%03d.ogg" % i))
        save(os.path.join(SFX, "step_sand_%d.ogg" % (i + 1)), fades(level(lowpass(pitch(snow, 0.82), 2600.0), -6.0)))
        grass = load(kenney("impact-sounds", "footstep_grass_%03d.ogg" % i))
        crackle = highpass(pitch(load(kenney("impact-sounds", "footstep_snow_%03d.ogg" % ((i + 2) % 5))), 1.25), 2500.0)
        m = min(len(grass), len(crackle))
        save(os.path.join(SFX, "step_leaves_%d.ogg" % (i + 1)), fades(level(grass[:m] + 0.6 * level(crackle[:m], -3.0) * np.max(np.abs(grass)), -4.0)))
    for i in range(3):
        g = load(kenney("impact-sounds", "impactGlass_light_%03d.ogg" % i))
        save(os.path.join(SFX, "step_glass_%d.ogg" % (i + 1)), fades(level(g, -9.0)))
    animals()
    monsters()


def cut(ref: str, count: int, lo: float = 0.12, hi: float = 0.9, hp: float = 90.0) -> list:
    """`count` single calls cut out of a longer freesound take, each levelled."""
    return [fades(level(c), fout=0.06) for c in calls(highpass(load(freesound(ref)), hp), count, lo, hi)]


def animals() -> None:
    """Animal voices (owner, 20:42: "animals should have sounds, like real ones"): real CC0 field
    recordings from freesound.org, 2-3 of each call so they don't repeat; a hurt voice and a happy one."""
    def put(name: str, sounds: list) -> None:
        for i, x in enumerate(sounds):
            save(os.path.join(SFX, "%s_%d.ogg" % (name, i + 1)), x)
    put("dog", [voice(r) for r in ["kwahmah_02/277058", "JovianSounds/502655", "exe2be/535457"]])
    put("dog_happy", [voice("AustinXYZ/350593")] + cut("esperri/118970", 1, 0.3, 1.6))
    put("dog_hurt", cut("unfa/160478", 2, 0.12, 0.8))
    put("cat", [voice(r) for r in ["tuberatanka/110011", "skymary/412017", "TRNGLE/362652"]])
    purr = highpass(load(freesound("Trautwein/260881")), 60.0)
    put("cat_purr", [fades(level(purr[int(a * RATE):int((a + 2.4) * RATE)], -6.0), 0.25, 0.5) for a in (6.0, 21.0)])
    put("cat_hurt", [voice("Reitanna/343927")])
    put("pig", [voice(r) for r in ["qubodup/442906", "qubodup/442907", "qubodup/442905"]])
    put("pig_hurt", [voice("qubodup/442904")])
    put("cow", [voice("Zozzy/59245"), voice("Bird_man/275154")] + cut("JosephSardin/177253", 1, 0.6, 2.5))
    put("cow_hurt", cut("gibarroule/365134", 1, 0.4, 1.6))
    put("sheep", [voice(r) for r in ["esperar/171149", "esperar/171151", "michaelperfect/710300"]])
    put("sheep_hurt", [fades(level(pitch(trim(load(freesound("esperar/171152"))), 1.12)))])
    put("chicken", cut("Breviceps/456803", 3, 0.12, 0.9, 150.0))
    put("chicken_hurt", [voice("Rudmer_Rotteveel/316920")])
    put("rabbit", cut("kessir/372075", 2, 0.06, 0.7, 200.0) + cut("policemouse67/697093", 1, 0.06, 0.9, 200.0))
    put("rabbit_hurt", cut("kessir/386007", 1, 0.03, 0.5, 40.0) + [fades(level(pitch(c, 1.2))) for c in cut("kessir/372075", 1, 0.06, 0.7, 200.0)])
    put("fish_splash", [voice("dslrguide/321490", -6.0), voice("paulprit/507094", -6.0)])


def seg(ref: str, a: float, b: float, hp: float = 90.0, peak: float = -3.0) -> np.ndarray:
    """The stretch a..b seconds of a freesound take (one call), high-passed, trimmed, levelled and faded."""
    x = load(freesound(ref))
    x = x[int(a * RATE):int(b * RATE)]
    return fades(level(trim(highpass(x, hp), -40.0), peak), 0.004, 0.05)


def animal_pack() -> None:
    """Owner feedback #41 (spec §14.19): the new animals' voices, real CC0 recordings from freesound.org (each
    page's licence read by `freesound`), a call of 2-3 takes, a hurt voice and (the horse) a happy one; the fox
    and the parrot get their own real voices instead of M3 Task 11's stand-ins. Where no CC0 recording of a
    hurt voice exists, a call cut short and played higher stands in (the fennec and the arctic fox are red-fox
    recordings, the polar bear a grizzly's: no CC0 recordings of those exist). Times are the calls in each take."""
    def put(name: str, sounds: list) -> None:
        for i, x in enumerate(sounds):
            save(os.path.join(SFX, "%s_%d.ogg" % (name, i + 1)), x)
    # Green Meadows
    put("horse", [seg("poodaddy69/521246", 0.35, 1.55), seg("TheKingOfGeeks360/832631", 0.08, 1.62),
                  seg("Lydmakeren/510903", 0.35, 3.3)])
    put("horse_hurt", [seg("craigsmith/479674", 0.7, 1.95), seg("craigsmith/479674", 6.35, 7.2)])
    put("horse_happy", [seg("TheKingOfGeeks360/861234", 0.08, 0.62), seg("TheKingOfGeeks360/861233", 0.0, 0.68)])
    put("donkey", [seg("TheKingOfGeeks360/787564", 0.1, 3.0), seg("felix.blume/133761", 0.02, 2.75)])
    put("donkey_hurt", [fades(level(pitch(seg("felix.blume/133761", 5.5, 6.4), 1.15)))])
    put("goat", [seg("Kinoton/581240", 0.34, 1.14), seg("TheKingOfGeeks360/842307", 0.05, 1.16),
                 seg("satoristudios3/677220", 0.03, 1.34)])
    put("goat_hurt", [seg("jsbarrett/200333", 1.3, 2.12), seg("jsbarrett/200333", 4.76, 5.46)])
    put("deer", [seg("msantoro11/351113", 1.05, 2.55, 200.0), seg("msantoro11/351113", 9.3, 11.55, 200.0),
                 seg("mattl83/710264", 16.2, 17.5, 250.0)])
    put("deer_hurt", [fades(level(pitch(seg("msantoro11/351113", 4.42, 5.16, 200.0), 1.25)))])
    put("duck", [voice("OwennewO/719114"), voice("OwennewO/719109"), voice("OwennewO/719110")])
    put("duck_hurt", [voice("OwennewO/719111")])
    put("frog", [seg("craigsmith/479818", 1.3, 1.7), seg("stomachache/53259", 0.05, 0.7),
                 seg("craigsmith/479833", 0.72, 1.14)])
    put("frog_hurt", [seg("Breviceps/462863", 3.72, 3.9), seg("Breviceps/462863", 10.34, 10.56)])
    put("turtle", [voice("TheKingOfGeeks360/850006"), voice("TheKingOfGeeks360/871251")])
    put("turtle_hurt", [fades(level(pitch(voice("TheKingOfGeeks360/850006"), 1.3)))])
    put("squirrel", [seg("genghisattenborough/744596", 0.34, 0.88, 200.0), seg("philberts/111393", 1.4, 2.4, 200.0),
                     seg("BullSam/509507", 0.0, 1.2, 200.0)])
    put("squirrel_hurt", [seg("burgersmoke/640990", 0.5, 0.8, 200.0), seg("burgersmoke/640990", 18.94, 19.16, 200.0)])
    put("owl", [seg("faxfaxfax/655380", 0.18, 1.36), seg("Gerent/558396", 1.0, 2.92), seg("sound368/864872", 1.6, 2.66)])
    put("owl_hurt", [seg("Proxmo_Kashacir/583544", 0.22, 1.46)])
    put("hedgehog", [seg("fthgurdy/528177", 0.12, 1.84, 150.0), seg("fthgurdy/528183", 0.05, 1.6, 150.0)])
    put("hedgehog_hurt", [fades(level(pitch(seg("fthgurdy/528177", 2.18, 2.7, 150.0), 1.2)))])
    # the Sandstorm Desert
    put("camel", [seg("jlseagull/685761", 3.8, 6.0), seg("Pól/385912", 0.22, 2.95)])
    put("camel_hurt", [seg("craigsmith/437937", 0.08, 0.9)])
    put("lizard", [seg("SieuAmThanh/546287", 4.08, 4.86), voice("SieuAmThanh/677430")])
    put("lizard_hurt", [fades(level(pitch(seg("SieuAmThanh/400573", 0.04, 0.3), 1.2)))])
    put("fennec", [seg("timsc/546948", 1.6, 2.22), seg("timsc/546948", 9.52, 9.82), seg("timsc/546948", 17.16, 17.6)])
    put("fennec_hurt", [seg("timsc/546948", 25.1, 26.0)])
    # Frostpeak
    put("penguin", [seg("Bidone/66150", 93.44, 96.08, 150.0), seg("al.barbosa/150873", 4.72, 6.08, 150.0)])
    put("penguin_hurt", [voice("Breviceps/705839")])
    put("polar_bear", [seg("Nivatius/519518", 16.32, 18.4, 60.0), seg("Nivatius/519596", 2.34, 3.9, 60.0)])
    put("polar_bear_hurt", [seg("Nivatius/519518", 33.0, 34.6, 60.0)])
    put("arctic_fox", [seg("SoundsLikeYukon/865257", 21.36, 22.04), seg("qubodup/854733", 3.08, 3.96),
                       seg("qubodup/854733", 15.84, 16.72)])
    put("arctic_fox_hurt", [seg("nielstii/554308", 10.66, 11.86, 300.0)])
    put("seal", [seg("RavenWolfProds/503682", 1.24, 1.84), seg("RavenWolfProds/503682", 2.02, 2.64),
                 seg("Diim_1/849186", 0.78, 1.34)])
    put("seal_hurt", [seg("schaarsen/495932", 37.9, 39.6)])
    # the Candy Kingdom: a real squeaky rubber toy for the gummy bunnies, real songbirds for the candy birds
    put("gummy_bunny", [seg("survivalzombie/240015", 0.16, 1.0), seg("Breviceps/483922", 0.02, 0.32),
                        seg("Aiyumi/245083", 0.22, 0.94)])
    put("gummy_bunny_hurt", [seg("LamaMakesMusic/403507", 6.82, 8.2)])
    put("candy_bird", [seg("nfrae/703254", 0.0, 1.2, 300.0), seg("ReadeOnly/85403", 0.02, 1.16, 300.0),
                       seg("Lovewerk/522187", 0.56, 0.98, 300.0)])
    put("candy_bird_hurt", [seg("qubodup/812026", 0.0, 0.9, 300.0)])
    # M3 Task 11's pets: real voices instead of the stand-ins
    put("fox", [seg("felix.blume/832436", 1.02, 1.56), seg("felix.blume/832436", 3.62, 4.2),
                seg("craigsays/537587", 6.78, 7.76)])
    put("fox_hurt", [seg("Soundburst/634005", 1.04, 1.56)])
    put("parrot", [seg("TheKingOfGeeks360/844340", 0.18, 1.1), seg("felix.blume/504988", 5.84, 6.26),
                   seg("Breviceps/535815", 0.82, 1.6)])
    put("parrot_hurt", [seg("TheKingOfGeeks360/777592", 0.1, 1.02)])


def monsters() -> None:
    """Monster voices (synthesised, original work) and the wave-start horn."""
    global RNG
    RNG = np.random.default_rng(20260924)
    for i, g in enumerate(goblin_grunts()):
        save(os.path.join(SFX, "goblin_grunt_%d.ogg" % (i + 1)), g)
    save(os.path.join(SFX, "goblin_hurt.ogg"), goblin_ouch())
    save(os.path.join(SFX, "slime_hurt.ogg"), slime_ouch())
    save(os.path.join(SFX, "mummy_hurt.ogg"), mummy_ouch())
    save(os.path.join(SFX, "scorpion_click.ogg"), scorpion_click())
    save(os.path.join(SFX, "scorpion_hurt.ogg"), scorpion_ouch())
    save(os.path.join(SFX, "wave_horn.ogg"), horn())


AMBIENCE_RMS = -24.0


def ambience() -> None:
    os.makedirs(AMB, exist_ok=True)
    birds = highpass(load(freesound("nick121087/342462")), 180.0)
    save(os.path.join(AMB, "birds.ogg"), rms_level(loop(birds, 40.0, 4.0, 20.0), AMBIENCE_RMS), 2)
    crickets = highpass(load(freesound("hdfreema/333221")), 300.0)
    save(os.path.join(AMB, "crickets.ogg"), rms_level(loop(crickets, 36.0, 4.0, 30.0), AMBIENCE_RMS), 2)
    waves = highpass(load(freesound("Noted451/531015")), 60.0)
    save(os.path.join(AMB, "waves.ogg"), rms_level(loop(waves, 48.0, 6.0, 8.0), AMBIENCE_RMS + 1.0), 2)
    drips = highpass(load(freesound("Sclolex/177958")), 120.0)
    save(os.path.join(AMB, "drips.ogg"), rms_level(loop(drips, 40.0, 4.0, 10.0), AMBIENCE_RMS - 2.0), 2)
    save(os.path.join(AMB, "wind.ogg"), rms_level(wind_loop(36.0), AMBIENCE_RMS), 2)


def universe_ambience() -> None:
    """M5 Task 2 (spec §15.2): Frostpeak's and the Candy Kingdom's own loops (CC0 recordings from freesound)."""
    os.makedirs(AMB, exist_ok=True)
    snow = highpass(load(freesound("craigsmith/817187")), 120.0)      # Icy Yellow Sky Wind: cold, a soft whistle
    save(os.path.join(AMB, "snow_wind.ogg"), rms_level(loop(snow, 40.0, 4.0, 4.0), AMBIENCE_RMS), 2)
    pines = highpass(load(freesound("bruno.auzet/670307")), 120.0)    # silent windy pine forest (the night)
    save(os.path.join(AMB, "snow_night.ogg"), rms_level(loop(pines, 40.0, 5.0, 60.0), AMBIENCE_RMS - 1.0), 2)
    chimes = highpass(load(freesound("_natiKatz/530603")), 300.0)     # Wind Chime Gentle: the kingdom by day
    save(os.path.join(AMB, "chimes.ogg"), rms_level(loop(chimes, 26.0, 5.0, 0.5), AMBIENCE_RMS - 2.0), 2)
    brook = highpass(load(freesound("pepasystem/819768")), 150.0)    # a small brook: the chocolate river at night
    save(os.path.join(AMB, "brook.ogg"), rms_level(loop(brook, 36.0, 4.0, 10.0), AMBIENCE_RMS), 2)


if __name__ == "__main__":
    import sys
    parts = {"effects": effects, "animals": animals, "monsters": monsters, "ambience": ambience, "pack": animal_pack,
             "universes": universe_ambience}
    for part in sys.argv[1:] or ["effects", "ambience"]:
        parts[part]()
