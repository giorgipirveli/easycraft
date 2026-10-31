#!/usr/bin/env python3
"""Owner #123: the Android apps' updates (docs/devlog/parts/same-version.md; DEVELOPMENT.md "The Android apps follow the
web"). The shell scripts tools/export_android_update.sh and tools/deploy_android_update.sh call this; by hand:

  python3 tools/android_update.py keygen [--key PEM]
        the signing key, once: ~/.config/easycraft/update-signing.pem (chmod 600, never in git); prints the public key
        for UpdateRules.PUBLIC_KEYS (a new key reaches apps only in a new APK/AAB)
  python3 tools/android_update.py base <phone|quest> <APK or pack> [--bases DIR] [--engine ID] [--code N]
        keep an Android build in the wild as a base: DIR/<kind>/<commit>/base.apk|base.pck + base.json (its commit and
        version from its own files; the APK itself is the exact base, Godot 4.7 patches against it)
  python3 tools/android_update.py bases <phone|quest> [--bases DIR]
        the kept bases, one tab-separated line each: commit, version, engine, path of the base file
  python3 tools/android_update.py check <kind> <base file> <game pack> <patch>
        can that build take the patch? exit 0 (prints warnings) or 3 with the reasons it needs a new APK/AAB
  python3 tools/android_update.py manifest <kind> <game pack> <folder> [--bases DIR] [--key PEM] [--serial N]
        writes <folder>/update.json: the signed manifest naming each <kind>-<base>-<game>.pck in the folder
  python3 tools/android_update.py verify <update.json> [--public PEM]
        the signature with the game's own public key (core/platform/update_rules.gd) or the given one

A base is identified by the commit in its data/build_info.json (tools/write_build_info.py writes it before every
export); a build without one cannot be matched and keeps its own game.
"""
import base64
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time
import zipfile

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pck_tool  # noqa: E402

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_KEY = os.path.expanduser("~/.config/easycraft/update-signing.pem")
DEFAULT_BASES = os.path.join(GAME, "build", "android", "bases")
RULES = os.path.join(GAME, "core", "platform", "update_rules.gd")
KIND_PRESET = {"phone": "Android Phone", "quest": "Quest"}
KEY_ID = "k1"
FORMAT = 1
MAX_BYTES = 400 * 1024 * 1024
# Settings a patch may change: the updater takes them from the pack's project.binary (UpdateRules.project_changes).
PATCHABLE_SETTING = re.compile(r"^(application/config/version|input/.+)$")
# A setting for a platform the app never is changes nothing there.
FOREIGN = {"phone": {"web", "webxr", "quest", "windows", "macos", "linuxbsd", "ios", "visionos", "pc", "editor"},
           "quest": {"web", "webxr", "windows", "macos", "linuxbsd", "ios", "visionos", "pc", "editor"}}
NATIVE = (".so", ".dex", ".jar", ".aar", ".dylib", ".dll", ".gdextension")
# The updater's own scripts: frozen in each APK/AAB (the first autoload preloads them before a pack is in).
UPDATER_OWN = ("autoloads/updater.", "core/platform/update_rules.", "core/platform/update_flow.",
               "core/platform/update_fetch.")


def die(msg, code=1):
    print("android_update: " + msg, file=sys.stderr)
    sys.exit(code)


def opt(args, name, default=None):
    if name in args:
        i = args.index(name)
        if i + 1 >= len(args):
            die("%s needs a value" % name)
        v = args[i + 1]
        del args[i:i + 2]
        return v
    return default


# --- reading a build: an APK/AAB (zip, the game's files under assets/ or base/assets/) or a pack ---------------------------

class Build:
    def __init__(self, path):
        self.path = path
        self.zip = None
        self.pack = None
        if zipfile.is_zipfile(path):
            self.zip = zipfile.ZipFile(path)
            names = set(self.zip.namelist())
            self.prefix = "base/assets/" if "base/assets/project.binary" in names else "assets/"
            self.names = {n[len(self.prefix):] for n in names if n.startswith(self.prefix)}
        else:
            self.pack = pck_tool.read_pck(path)
            self.entries = {e["name"].removeprefix("res://"): e for e in self.pack["entries"]}
            self.names = set(self.entries)

    def read(self, name):
        if name not in self.names:
            return None
        if self.zip:
            return self.zip.read(self.prefix + name)
        e = self.entries[name]
        start = self.pack["file_base"] + e["offset"]
        return self.pack["data"][start:start + e["size"]]


def project_binary(data):
    """{key: the value's encode_variant bytes}; {} for a missing or broken file."""
    out = {}
    if not data or len(data) < 8 or data[:4] != b"ECFG":
        return out
    count = struct.unpack_from("<I", data, 4)[0]
    pos = 8
    for _ in range(count):
        kl = struct.unpack_from("<I", data, pos)[0]
        key = data[pos + 4:pos + 4 + kl].decode("utf-8")
        pos += 4 + kl
        vl = struct.unpack_from("<I", data, pos)[0]
        out[key] = bytes(data[pos + 4:pos + 4 + vl])
        pos += 4 + vl
    return out


def variant_string(raw):
    """A String's encode_variant (type 4: u32 type, u32 length, UTF-8), else None."""
    if raw is None or len(raw) < 8 or struct.unpack_from("<I", raw, 0)[0] & 0xFF != 4:
        return None
    n = struct.unpack_from("<I", raw, 4)[0]
    return raw[8:8 + n].decode("utf-8")


def identity(build):
    info = json.loads(build.read("data/build_info.json") or b"{}")
    settings = project_binary(build.read("project.binary"))
    commit = info.get("commit", "")
    if not re.fullmatch(r"[0-9a-f]{8,40}", commit or ""):
        die("%s has no data/build_info.json with a commit: export it after tools/write_build_info.py" % build.path)
    return {"commit": commit, "date": info.get("date", ""), "net": info.get("net", ""),
            "version": variant_string(settings.get("application/config/version")) or ""}


def engine_id():
    out = subprocess.run([os.environ.get("GODOT", "godot"), "--version"], capture_output=True, text=True).stdout.strip()
    parts = out.split(".")
    if len(parts) < 4:
        die("cannot read the engine's version from `godot --version`: %r" % out)
    return ".".join(parts[:4])


def preset_code(kind):
    cfg = open(os.path.join(GAME, "export_presets.cfg"), encoding="utf-8").read()
    for block in re.split(r"\n(?=\[preset\.\d+\]\n)", cfg):
        if re.search(r'^name="%s"$' % re.escape(KIND_PRESET[kind]), block, re.M):
            m = re.search(r"^version/code=(\d+)$", block, re.M)
            return int(m.group(1)) if m else 0
    return 0


def version_key(v):
    return [int(p) if p.isdigit() else 0 for p in (v or "0").split(".")]


# --- commands -------------------------------------------------------------------------------------------------------------

def cmd_keygen(args):
    key = opt(args, "--key", DEFAULT_KEY)
    if not os.path.exists(key):
        os.makedirs(os.path.dirname(key), exist_ok=True)
        old = os.umask(0o077)
        try:
            subprocess.run(["openssl", "genpkey", "-algorithm", "RSA", "-pkeyopt", "rsa_keygen_bits:3072", "-out", key],
                           check=True, capture_output=True)
        finally:
            os.umask(old)
        print("made %s" % key, file=sys.stderr)
    os.chmod(key, 0o600)
    print(public_pem(key), end="")


def public_pem(key):
    return subprocess.run(["openssl", "pkey", "-in", key, "-pubout"], check=True, capture_output=True,
                          text=True).stdout


def cmd_base(args):
    bases = opt(args, "--bases", DEFAULT_BASES)
    engine = opt(args, "--engine") or engine_id()
    code = opt(args, "--code")
    if len(args) != 2 or args[0] not in KIND_PRESET:
        die("usage: base <phone|quest> <APK or pack>")
    kind, path = args
    who = identity(Build(path))
    folder = os.path.join(bases, kind, who["commit"])
    os.makedirs(folder, exist_ok=True)
    ext = ".pck" if path.endswith(".pck") else ".apk"
    for old in ("base.apk", "base.pck"):
        if os.path.exists(os.path.join(folder, old)):
            os.remove(os.path.join(folder, old))
    shutil.copyfile(path, os.path.join(folder, "base" + ext))
    record = dict(who, kind=kind, engine=engine, code=int(code) if code else preset_code(kind),
                  file="base" + ext, kept=time.strftime("%Y-%m-%dT%H:%M:%S%z"), source=os.path.basename(path))
    with open(os.path.join(folder, "base.json"), "w", encoding="utf-8") as f:
        json.dump(record, f, indent=1)
        f.write("\n")
    print("BASE %s %s v%s (%s, code %s) kept in %s" % (kind, who["commit"], who["version"], engine, record["code"],
                                                      folder))


def list_bases(bases, kind):
    out = []
    root = os.path.join(bases, kind)
    if not os.path.isdir(root):
        return out
    for commit in sorted(os.listdir(root)):
        meta = os.path.join(root, commit, "base.json")
        if os.path.exists(meta):
            b = json.load(open(meta, encoding="utf-8"))
            b["path"] = os.path.join(root, commit, b.get("file", "base.pck"))
            out.append(b)
    return out


def cmd_bases(args):
    bases = opt(args, "--bases", DEFAULT_BASES)
    if len(args) != 1 or args[0] not in KIND_PRESET:
        die("usage: bases <phone|quest>")
    for b in list_bases(bases, args[0]):
        print("\t".join([b["commit"], b.get("version", ""), b.get("engine", ""), b["path"]]))


def patch_problems(kind, base, game, patch):
    """(reasons it needs a new APK/AAB, warnings)."""
    need, warn = [], []
    names = {e["name"].removeprefix("res://") for e in pck_tool.read_pck(patch)["entries"]}
    for n in sorted(names):
        if n.endswith(NATIVE) or re.match(r"addons/[^/]+/bin/", n) or n == ".godot/extension_list.cfg":
            need.append("native code or a GDExtension changed: %s" % n)
        if n.startswith(UPDATER_OWN):
            warn.append("the updater's own %s changed: apps take it only from a new APK/AAB" % n)
    a = project_binary(base.read("project.binary"))
    b = project_binary(game.read("project.binary"))
    for key in sorted(set(a) | set(b)):
        if a.get(key) == b.get(key) or PATCHABLE_SETTING.match(key):
            continue
        if "." in key.rsplit("/", 1)[-1] and key.rsplit(".", 1)[-1] in FOREIGN[kind]:
            continue
        what = "added" if key not in a else "removed" if key not in b else "changed"
        need.append("project setting %s %s (read once at the start)" % (key, what))
    return need, warn


def cmd_check(args):
    if len(args) != 4 or args[0] not in KIND_PRESET:
        die("usage: check <kind> <base file> <game pack> <patch>")
    kind, base, game, patch = args
    need, warn = patch_problems(kind, Build(base), Build(game), patch)
    for w in warn:
        print("WARNING " + w)
    for n in need:
        print("NEEDS A NEW APK/AAB: " + n)
    sys.exit(3 if need else 0)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for piece in iter(lambda: f.read(1 << 20), b""):
            h.update(piece)
    return h.hexdigest()


def sign(text, key):
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "signed.txt")
        sig = os.path.join(tmp, "sig.bin")
        open(src, "wb").write(text.encode("utf-8"))
        subprocess.run(["openssl", "dgst", "-sha256", "-sign", key, "-out", sig, src], check=True, capture_output=True)
        return base64.b64encode(open(sig, "rb").read()).decode("ascii")


def verify(text, signature, public):
    with tempfile.TemporaryDirectory() as tmp:
        src, sig, pub = (os.path.join(tmp, n) for n in ("signed.txt", "sig.bin", "pub.pem"))
        open(src, "wb").write(text.encode("utf-8"))
        open(sig, "wb").write(base64.b64decode(signature))
        open(pub, "w").write(public)
        r = subprocess.run(["openssl", "dgst", "-sha256", "-verify", pub, "-signature", sig, src], capture_output=True)
        return r.returncode == 0


def game_public_key(key_id=KEY_ID):
    src = open(RULES, encoding="utf-8").read()
    m = re.search(r'"%s":\s*"""(-----BEGIN PUBLIC KEY-----.*?-----END PUBLIC KEY-----\n?)"""' % re.escape(key_id), src,
                  re.S)
    if not m:
        die("no public key %s in %s" % (key_id, RULES))
    return m.group(1)


def cmd_manifest(args):
    bases = opt(args, "--bases", DEFAULT_BASES)
    key = opt(args, "--key", DEFAULT_KEY)
    serial = int(opt(args, "--serial", str(int(time.time()))))
    engine = opt(args, "--engine") or engine_id()
    public = opt(args, "--public")
    if len(args) != 3 or args[0] not in KIND_PRESET:
        die("usage: manifest <kind> <game pack> <folder>")
    kind, game_pack, folder = args
    if not os.path.exists(key):
        die("no signing key %s (python3 tools/android_update.py keygen, once)" % key)
    game = identity(Build(game_pack))
    entries, versions = {}, []
    for b in list_bases(bases, kind):
        if b.get("engine") != engine:
            continue
        if b["commit"] == game["commit"]:
            versions.append(b.get("version", ""))
            continue
        name = "%s-%s-%s.pck" % (kind, b["commit"][:8], game["commit"][:8])
        path = os.path.join(folder, name)
        if not os.path.exists(path):
            continue
        size = os.path.getsize(path)
        if size > MAX_BYTES:
            die("%s is %d bytes: over the limit an app takes" % (name, size))
        entries[b["commit"]] = {"file": name, "size": size, "sha256": sha256(path)}
        versions.append(b.get("version", ""))
    lowest = min(versions, key=version_key) if versions else game["version"]
    manifest = {"format": FORMAT, "kind": kind, "serial": serial, "engine": engine,
                "game": {"commit": game["commit"], "date": game["date"], "version": game["version"], "net": game["net"]},
                "min_base": lowest, "bases": entries}
    signed = json.dumps(manifest, sort_keys=True, separators=(",", ":"))
    envelope = {"key": KEY_ID, "signed": signed, "signature": sign(signed, key)}
    if not verify(signed, envelope["signature"], open(public).read() if public else game_public_key()):
        die("the signature does not verify with the game's public key (UpdateRules.PUBLIC_KEYS[%s]): another key?" % KEY_ID)
    with open(os.path.join(folder, "update.json"), "w", encoding="utf-8") as f:
        json.dump(envelope, f, indent=1)
        f.write("\n")
    print("MANIFEST %s game %s v%s, serial %d, %d base(s), lowest base v%s: %s" % (
        kind, game["commit"], game["version"], serial, len(entries), lowest, os.path.join(folder, "update.json")))


def cmd_verify(args):
    public = opt(args, "--public")
    if len(args) != 1:
        die("usage: verify <update.json>")
    env = json.load(open(args[0], encoding="utf-8"))
    ok = verify(env["signed"], env["signature"], open(public).read() if public else game_public_key(env.get("key", "")))
    m = json.loads(env["signed"])
    print("VERIFY %s: %s (%s, game %s, %d base(s))" % (args[0], "OK" if ok else "BAD SIGNATURE", m.get("kind"),
                                                     m.get("game", {}).get("commit"), len(m.get("bases", {}))))
    sys.exit(0 if ok else 2)


def main(argv):
    if not argv or argv[0] not in ("keygen", "base", "bases", "check", "manifest", "verify"):
        print(__doc__)
        return 1
    globals()["cmd_" + argv[0]](list(argv[1:]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
