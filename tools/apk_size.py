#!/usr/bin/env python3
"""What an APK or a Play bundle (.aab) is made of (M5 Task 3, the APK size pass; spec §15.3: the size is tracked).

    python3 tools/apk_size.py build/android/EasyCraft-phone.apk [top]
    python3 tools/apk_size.py build/android/EasyCraft-play.aab [top] --bundletool=<bundletool-all.jar>

Prints the size by kind (the bytes in the archive, and raw), then the biggest entries. For a bundle with
--bundletool (https://github.com/google/bundletool/releases, bundletool-all-<v>.jar; needs JAVA_HOME or java on
the PATH) it also builds the split APKs Play would make (signed with the debug keystore: the size does not depend on
the key) and prints Play's download size for an arm64 phone and the size those APKs take on it.
The numbers of every release are in docs/devlog/parts/m5-task-3.md.
"""
import os
import subprocess
import sys
import tempfile
import zipfile
from collections import defaultdict

DEBUG_KEYSTORE = os.path.expanduser("~/.local/share/godot/keystores/debug.keystore")


def kind(name: str) -> str:
    n = name.lower()
    if n.endswith(".so"):
        return "native libraries (.so)"
    if n.endswith(".dex"):
        return "java (.dex)"
    if any(k in n for k in ("_albedo.png", "_normal.png")):
        return "realistic block pages"
    if ".oggvorbisstr" in n or n.endswith(".sample") or ".mp3str" in n:
        return "audio"
    if ".jpg-" in n or ".jpeg-" in n:
        return "jpeg pictures"
    if n.endswith(".ctex") or ".png-" in n or ".hdr-" in n or ".svg-" in n:
        return "other textures"
    if n.endswith((".gdc", ".gd", ".gde")):
        return "scripts"
    if n.endswith((".scn", ".tscn", ".res", ".tres")):
        return "scenes and resources"
    return "other"


def breakdown(path: str, top: int) -> None:
    z = zipfile.ZipFile(path)
    stored, raw, count = defaultdict(int), defaultdict(int), defaultdict(int)
    items = []
    for info in z.infolist():
        k = kind(info.filename)
        stored[k] += info.compress_size
        raw[k] += info.file_size
        count[k] += 1
        items.append((info.compress_size, info.file_size, info.filename))
    print(f"{path}: {os.path.getsize(path):,} bytes ({os.path.getsize(path) / 1e6:.1f} MB)")
    for k in sorted(stored, key=lambda x: -stored[x]):
        print(f"  {k:24s} {count[k]:5d} files  {stored[k] / 1e6:7.2f} MB in the archive  {raw[k] / 1e6:7.2f} MB raw")
    print(f"  {'total':24s} {sum(count.values()):5d} files  {sum(stored.values()) / 1e6:7.2f} MB in the archive  "
          f"{sum(raw.values()) / 1e6:7.2f} MB raw")
    for s, r, n in sorted(items, reverse=True)[:top]:
        print(f"    {s / 1e6:6.2f} MB (raw {r / 1e6:6.2f})  {n}")


def play_sizes(aab: str, jar: str) -> None:
    java = os.path.join(os.environ["JAVA_HOME"], "bin", "java") if os.environ.get("JAVA_HOME") else "java"
    with tempfile.TemporaryDirectory() as tmp:
        apks = os.path.join(tmp, "out.apks")
        spec = os.path.join(tmp, "device.json")
        with open(spec, "w") as f:
            f.write('{"supportedAbis": ["arm64-v8a"], "supportedLocales": ["en"], "screenDensity": 420, "sdkVersion": 35}')
        subprocess.run([java, "-jar", jar, "build-apks", f"--bundle={aab}", f"--output={apks}", f"--ks={DEBUG_KEYSTORE}",
                        "--ks-pass=pass:android", "--ks-key-alias=androiddebugkey", "--key-pass=pass:android"],
                       check=True, capture_output=True)
        out = subprocess.run([java, "-jar", jar, "get-size", "total", f"--apks={apks}", f"--device-spec={spec}"],
                             check=True, capture_output=True, text=True).stdout.split()
        print(f"Play download (arm64 phone, Android 15): {int(out[-1].split(',')[0]) / 1e6:.1f} MB")
        z = zipfile.ZipFile(apks)
        on_phone = sum(i.file_size for i in z.infolist() if i.filename.endswith(".apk") and (
            "master" in i.filename or "arm64" in i.filename or "xxhdpi" in i.filename or "base-en" in i.filename))
        print(f"the APKs Play installs on it: {on_phone / 1e6:.1f} MB")


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    jar = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--bundletool=")), "")
    breakdown(args[0], int(args[1]) if len(args) > 1 else 20)
    if jar and args[0].endswith(".aab"):
        play_sizes(args[0], jar)


if __name__ == "__main__":
    main()
