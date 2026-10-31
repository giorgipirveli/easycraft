#!/usr/bin/env python3
"""Godot 4 resource packs (.pck, format 3 and 4) for the web export (M7, tools/export_web.sh):

  python3 tools/pck_tool.py list <pack>                               every file: size, md5, path
  python3 tools/pck_tool.py strip <in> <out> --preset "Web Assets"    keep only the files that preset chose
  python3 tools/pck_tool.py strip <in> <out> --keep "a/*.wav, b/x.ogg"

`strip` exists because Godot's exporter adds the autoload scripts, project.binary, the uid and
class caches, the icon and the boot splash to every pack it exports, also to a pack of chosen files. A content pack
(the music, the realistic pictures, the game's media) is named by the hash of its bytes, and the browser keeps it by
that name: with the scripts inside, a change to an autoload or to project.godot renamed every pack, and every returning
visitor downloaded them all again. The game loads a content pack with load_resource_pack(path, false), so its copies of
those files were never used anyway (the main pack's win). `strip` keeps the files the filter names (source paths as
Godot matches them: `*` crosses `/`, no case), their `.import` / `.remap` and the imported data those name; nothing else.
It refuses to write a pack with nothing in it or with code in it, and the same input always gives the same bytes.
"""
import fnmatch
import os
import re
import struct
import sys

MAGIC = 0x43504447  # "GDPC"
ALIGN = 32          # PCKPacker's default
DIR_ENCRYPTED = 1
SPARSE_BUNDLE = 4
FILE_ENCRYPTED = 1
CODE = (".gd", ".gdc", ".gde", ".cs")


def read_pck(path):
    """The pack's header bytes, its file base, and its entries: dicts of name, offset (from the file base), size,
    md5, flags and the raw directory record."""
    with open(path, "rb") as f:
        data = f.read()
    magic, version, major, minor, patch, flags = struct.unpack_from("<6I", data, 0)
    if magic != MAGIC:
        raise ValueError("%s: not a Godot pack" % path)
    if version < 3:
        raise ValueError("%s: pack format %d (4.0-4.3) is not supported" % (path, version))
    if flags & (DIR_ENCRYPTED | SPARSE_BUNDLE):
        raise ValueError("%s: an encrypted or sparse pack is not supported" % path)
    file_base, dir_offset = struct.unpack_from("<QQ", data, 24)
    pos = dir_offset
    count = struct.unpack_from("<I", data, pos)[0]
    pos += 4
    entries = []
    for _ in range(count):
        start = pos
        name_len = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        name = data[pos:pos + name_len].rstrip(b"\0").decode("utf-8")
        pos += name_len
        offset, size = struct.unpack_from("<QQ", data, pos)
        pos += 16
        md5 = data[pos:pos + 16]
        pos += 16
        file_flags = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        entries.append({"name": name, "offset": offset, "size": size, "md5": md5, "flags": file_flags,
                        "record": data[start:pos]})
    return {"data": data, "version": version, "engine": (major, minor, patch), "file_base": file_base,
            "entries": entries}


def write_pck(pack, keep, out_path):
    """A pack with the header of `pack` and only the entries in `keep` (in their order), each aligned to ALIGN."""
    data, file_base = pack["data"], pack["file_base"]
    body = bytearray()
    records = bytearray()
    for e in keep:
        body += b"\0" * (-len(body) % ALIGN)
        offset = len(body)
        body += data[file_base + e["offset"]:file_base + e["offset"] + e["size"]]
        rec = bytearray(e["record"])
        name_len = struct.unpack_from("<I", rec, 0)[0]
        struct.pack_into("<Q", rec, 4 + name_len, offset)
        records += rec
    dir_offset = file_base + len(body) + (-(file_base + len(body)) % ALIGN)
    header = bytearray(data[:file_base])
    struct.pack_into("<Q", header, 32, dir_offset)
    out = header + body + b"\0" * (dir_offset - file_base - len(body)) + struct.pack("<I", len(keep)) + records
    tmp = out_path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(out)
    os.replace(tmp, out_path)


def preset_filter(cfg_path, preset_name):
    """The patterns and files a preset of export_presets.cfg chooses (its include_filter and export_files). The file is
    Godot's ConfigFile format (a value may span lines, e.g. html/head_include): only one-line keys are read."""
    sections = {}
    section = None
    with open(cfg_path) as f:
        for line in f:
            head = re.match(r"^\[([^\]]+)\]\s*$", line)
            if head:
                section = sections.setdefault(head.group(1), {})
                continue
            kv = re.match(r"^([A-Za-z0-9_/]+)=(.*)$", line.rstrip("\n"))
            if kv and section is not None:
                section[kv.group(1)] = kv.group(2)
    for name, keys in sections.items():
        if re.fullmatch(r"preset\.\d+", name) and keys.get("name", "").strip('"') == preset_name:
            include = keys.get("include_filter", '""').strip('"')
            files = re.findall(r'"res://([^"]+)"', keys.get("export_files", ""))
            return [p.strip() for p in include.split(",") if p.strip()] + files
    raise ValueError("no preset named %r in %s" % (preset_name, cfg_path))


def chosen(path, patterns):
    low = path.lower()
    return any(fnmatch.fnmatchcase(low, p.lower()) for p in patterns)


def remap_targets(text):
    """The files an exported .import or .remap points at (its [remap] path= and path.<format>= lines)."""
    return [t for t in re.findall(r'^path(?:\.[a-z0-9_]+)?="res://([^"]+)"', text, flags=re.M)]


def strip(in_path, out_path, patterns):
    pack = read_pck(in_path)
    data, file_base = pack["data"], pack["file_base"]
    by_name = {e["name"]: e for e in pack["entries"]}
    wanted = set()
    for e in pack["entries"]:
        name = e["name"]
        for suffix in (".import", ".remap"):
            if name.endswith(suffix) and chosen(name[:-len(suffix)], patterns):
                wanted.add(name)
                text = data[file_base + e["offset"]:file_base + e["offset"] + e["size"]].decode("utf-8", "replace")
                for target in remap_targets(text):
                    if target not in by_name:
                        raise ValueError("%s names %s, which is not in the pack" % (name, target))
                    wanted.add(target)
                break
        else:
            if chosen(name, patterns):
                wanted.add(name)
    keep = [e for e in pack["entries"] if e["name"] in wanted]
    if not keep:
        raise ValueError("nothing in %s matches %s" % (in_path, patterns))
    code = [e["name"] for e in keep if e["name"].endswith(CODE) or e["name"] == "project.binary"]
    if code:
        raise ValueError("a content pack must hold no code: %s" % code)
    if any(e["flags"] & FILE_ENCRYPTED for e in keep):
        raise ValueError("encrypted files are not supported")
    write_pck(pack, keep, out_path)
    left = [e["name"] for e in pack["entries"] if e["name"] not in wanted]
    print("PCK_STRIP %s: kept %d files (%d bytes), left out %d (%d bytes)%s" % (
        os.path.basename(out_path), len(keep), sum(e["size"] for e in keep), len(left),
        sum(by_name[n]["size"] for n in left), (": " + ", ".join(left[:6]) + (" …" if len(left) > 6 else "")) if left else ""))


def main(argv):
    if len(argv) >= 2 and argv[0] == "list":
        pack = read_pck(argv[1])
        print("# format %d, Godot %d.%d.%d, %d files" % ((pack["version"],) + pack["engine"] + (len(pack["entries"]),)))
        for e in pack["entries"]:
            print("%10d %s %s" % (e["size"], e["md5"].hex(), e["name"]))
        return 0
    if len(argv) == 5 and argv[0] == "strip" and argv[3] in ("--keep", "--preset"):
        if argv[3] == "--keep":
            patterns = [p.strip() for p in argv[4].split(",") if p.strip()]
        else:
            cfg = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "export_presets.cfg")
            patterns = preset_filter(cfg, argv[4])
        try:
            strip(argv[1], argv[2], patterns)
        except ValueError as err:
            print("PCK_STRIP refused: %s" % err, file=sys.stderr)
            return 1
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
