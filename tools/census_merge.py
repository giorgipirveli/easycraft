"""Merges one world's census run (tools/shader_probe_steps.gd --shader-probe=<phase> --shader-census) into
data/shader_warmup.json: a draw already there gains the run's style and <phase> (in phases and shown) only; a draw not
there is added at the end with what the run saw. Usage:
  census_merge.py <base.json> <run.json> <out.json> <phase> [--check | --list]
--check: only round-trips the base (prints whether it stays byte-identical); --list: prints the run's draws."""
import json
import sys

FIELDS = ("styles", "phases", "shown", "at")


def key(d):
    return json.dumps({k: v for k, v in d.items() if k not in FIELDS}, sort_keys=True)


def dump(data):
    return json.dumps(data, indent="\t", ensure_ascii=False) + "\n"


def main():
    base_path, run_path, out_path, phase = sys.argv[1:5]
    base_text = open(base_path, encoding="utf-8").read()
    base = json.loads(base_text)
    if "--check" in sys.argv:
        print("identical" if dump(base) == base_text else "differs")
        return
    run = json.loads(open(run_path, encoding="utf-8").read())
    index = {key(d): d for d in base["draws"]}
    if "--list" in sys.argv:
        for d in run["draws"]:
            print("NEW" if key(d) not in index else "old", d.get("phases"), d.get("shown"), str(d.get("at"))[:100])
        return
    added = 0
    merged = 0
    for d in run["draws"]:
        k = key(d)
        if k in index:
            e = index[k]
            for f in ("phases", "shown"):
                if phase in d.get(f, []) and phase not in e[f]:
                    e[f].append(phase)
                    merged += 1
            if phase in d.get("phases", []):
                for s in d.get("styles", []):
                    if s not in e["styles"]:
                        e["styles"].append(s)
                        merged += 1
        else:
            base["draws"].append(d)
            index[k] = d
            added += 1
    if phase not in base["phases"]:
        base["phases"].append(phase)
    open(out_path, "w", encoding="utf-8").write(dump(base))
    print("merged %d new marks, added %d draws" % (merged, added))


main()
