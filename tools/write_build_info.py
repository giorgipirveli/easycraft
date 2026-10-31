#!/usr/bin/env python3
"""Owner #123: writes data/build_info.json before an export (BuildInfo reads it; git-ignored).

  /usr/bin/python3 tools/write_build_info.py          # write it (the export scripts run this first)
  /usr/bin/python3 tools/write_build_info.py --print  # only print what it would write
  /usr/bin/python3 tools/write_build_info.py --clean  # remove it (after an export: the editor shows the version alone)

commit: the short commit the build comes from (with "+" in the label's sense when the tree has changes: the hash is
        still the commit's, and "dirty": true is printed, not written).
date:   now, ISO with the local offset.
net:    online play's fingerprint: what two games must share to play together. Godot's remote calls line up only
        between scripts with the same @rpc functions, and a block id one game lacks shows as nothing in the other, so it
        is a hash of every @rpc annotation with the function it marks (its file, name and parameters), every
        rpc_config() call, and BlockIds.COUNT. School lessons, Life, pictures and words never change it.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(GAME, "data", "build_info.json")
SKIP = ("addons/gut/", "tests/", "spikes/", ".godot/", ".claude/", "build/", "tools/")


def net_fingerprint() -> str:
    lines = []
    for root, dirs, files in os.walk(GAME):
        rel_root = os.path.relpath(root, GAME).replace(os.sep, "/")
        rel_root = "" if rel_root == "." else rel_root + "/"
        if rel_root.startswith(SKIP):
            dirs[:] = []
            continue
        for name in sorted(files):
            if not name.endswith(".gd"):
                continue
            rel = rel_root + name
            with open(os.path.join(root, name), encoding="utf-8") as f:
                src = f.read().split("\n")
            for i, line in enumerate(src):
                s = line.strip()
                if s.startswith("@rpc"):
                    # the function it marks: the next line that starts with "func" (or the same line)
                    rest = s[s.index(")") + 1:].strip() if ")" in s else ""
                    sig = rest if rest.startswith("func") else ""
                    j = i + 1
                    while not sig and j < len(src):
                        t = src[j].strip()
                        if t.startswith("func") or t.startswith("static func"):
                            sig = t
                        elif t and not t.startswith("#") and not t.startswith("@"):
                            break
                        j += 1
                    sig = re.sub(r"\s+", " ", sig[:-1] if sig.endswith(":") else sig)
                    lines.append(f"{rel}|{s[:s.index(')') + 1] if ')' in s else s}|{sig}")
                elif "rpc_config(" in s and not s.startswith("#"):
                    lines.append(f"{rel}|{re.sub(chr(32) + '+', ' ', s)}")
    with open(os.path.join(GAME, "data", "blocks", "block_ids.gd"), encoding="utf-8") as f:
        m = re.search(r"^const COUNT := (\d+)", f.read(), re.M)
    lines.append(f"blocks|{m.group(1) if m else '?'}")
    lines.sort()
    return hashlib.sha1("\n".join(lines).encode()).hexdigest()[:12]


def git(*args: str) -> str:
    return subprocess.run(["git", "-C", GAME, *args], capture_output=True, text=True, check=True).stdout.strip()


def main() -> int:
    if "--clean" in sys.argv:
        if os.path.exists(OUT):
            os.remove(OUT)
        return 0
    info = {
        "commit": git("rev-parse", "--short=8", "HEAD"),
        "date": datetime.now().astimezone().isoformat(timespec="seconds"),
        "net": net_fingerprint(),
    }
    dirty = any(l and not l.endswith("data/build_info.json") for l in git("status", "--porcelain").split("\n"))
    print(json.dumps(info) + ("  (the tree has changes not in the commit)" if dirty else ""))
    if "--print" not in sys.argv:
        with open(OUT, "w", encoding="utf-8") as f:
            json.dump(info, f, indent=1)
            f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
