#!/usr/bin/env python3
"""EasyCraft TV's channel list (owner #89; spec §5.12): check it, and keep it on the server.

The list is a JSON file like data/theater/channels.json (the one bundled with the game). The server keeps one
copy (Nakama storage theater/channels, module 0.2.17); every game that goes online reads it and keeps it, and a
game that never went online plays its bundled copy. So: edit data/theater/channels.json, `check` it, `push` it,
and commit it (the next build bundles the same list).

    python3 tools/theater_list.py check [FILE]      every video: its page on YouTube (title, channel), embedding
                                                    allowed, playable, set "made for kids" by its maker; and the
                                                    list's shape (the server's own rules). Exit 1 on any problem.
    python3 tools/theater_list.py sources [FILE]    the same check as a Markdown table (the notes' source list)
    python3 tools/theater_list.py push [FILE]       sends the list to the server (it checks the shape again and
                                                    refuses a list with any mistake, naming each one)
    python3 tools/theater_list.py show              the list the server keeps now (or "none")
    python3 tools/theater_list.py off               the kill-switch: a list with "enabled": false (no Theater)
    python3 tools/theater_list.py clear             deletes the server's list: games play their bundled one

push, show, off and clear need the server's runtime HTTP key (NAKAMA_RUNTIME_HTTP_KEY in the server's .env) in
the environment variable EASYCRAFT_HTTP_KEY; --server picks another server (default: the game's release server;
http://127.0.0.1:7350 with EASYCRAFT_HTTP_KEY=defaulthttpkey for this PC's server/dev.sh).

YouTube's own "made for kids" setting shows on the video's page: the miniplayer is off for such videos ("Miniplayer
is off for videos made for kids"). No API key is needed for the check.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_FILE = os.path.join(ROOT, "data", "theater", "channels.json")
DEFAULT_SERVER = "https://178-104-20-64.sslip.io"   # OnlineConfig.RELEASE_SERVER
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"

# The server's rules (server/modules/src/rules/theater_rules.ts), checked here first so a mistake shows before
# anything is sent.
MAX_CHANNELS = 12
MAX_VIDEOS = 50
MAX_TITLE = 40
MAX_FROM = 30
PLATFORMS = ["youtube", "tiktok"]
ICONS = ["tv", "planet", "flask", "paw", "gear", "note", "palette", "pyramid", "star"]
CHANNEL_ID = re.compile(r"^[a-z0-9_]{1,32}$")
VIDEO_ID = {"youtube": re.compile(r"^[A-Za-z0-9_-]{11}$"), "tiktok": re.compile(r"^[0-9]{6,25}$")}
COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")


def _text_ok(value, most):
    return isinstance(value, str) and 0 < len(value.strip()) <= most and not any(ord(c) < 32 or ord(c) == 127 for c in value)


def shape_problems(data):
    """The list's shape, as the server checks it: a list of problems ([] when it is fine)."""
    out = []
    if not isinstance(data, dict):
        return ["the list is not a JSON object"]
    if not isinstance(data.get("enabled"), bool):
        out.append("enabled: must be true or false")
    channels = data.get("channels")
    if not isinstance(channels, list):
        return out + ["channels: must be a list"]
    if len(channels) > MAX_CHANNELS:
        out.append("channels: at most %d" % MAX_CHANNELS)
    seen = set()
    for i, c in enumerate(channels):
        at = "channels[%d]" % i
        if not isinstance(c, dict):
            out.append(at + ": must be an object")
            continue
        if not isinstance(c.get("id"), str) or not CHANNEL_ID.match(c["id"]):
            out.append(at + ".id: 1-32 of a-z, 0-9 and _")
        elif c["id"] in seen:
            out.append(at + ".id: twice")
        seen.add(c.get("id"))
        if not _text_ok(c.get("title"), MAX_TITLE):
            out.append(at + ".title: 1-%d characters" % MAX_TITLE)
        platform = c.get("platform")
        if platform not in PLATFORMS:
            out.append(at + ".platform: youtube or tiktok")
        if "color" in c and (not isinstance(c["color"], str) or not COLOR.match(c["color"])):
            out.append(at + ".color: like #3a7be8")
        if "icon" in c and c["icon"] not in ICONS:
            out.append(at + ".icon: one of " + ", ".join(ICONS))
        videos = c.get("videos")
        if not isinstance(videos, list) or not videos:
            out.append(at + ".videos: a list of at least one video")
            continue
        if len(videos) > MAX_VIDEOS:
            out.append(at + ".videos: at most %d" % MAX_VIDEOS)
        vseen = set()
        for j, v in enumerate(videos):
            vat = "%s.videos[%d]" % (at, j)
            if not isinstance(v, dict):
                out.append(vat + ": must be an object")
                continue
            vid = v.get("id")
            if platform in VIDEO_ID and (not isinstance(vid, str) or not VIDEO_ID[platform].match(vid)):
                out.append(vat + ".id: not a %s video id" % platform)
            elif vid in vseen:
                out.append(vat + ".id: twice")
            vseen.add(vid)
            if not _text_ok(v.get("title"), MAX_TITLE):
                out.append(vat + ".title: 1-%d characters" % MAX_TITLE)
            if not isinstance(v.get("made_for_kids"), bool):
                out.append(vat + ".made_for_kids: true or false")
            if "from" in v and not _text_ok(v["from"], MAX_FROM):
                out.append(vat + ".from: 1-%d characters" % MAX_FROM)
    return out


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9",
                                               "Cookie": "CONSENT=YES+1; SOCS=CAI"})
    return urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")


def youtube_facts(vid):
    """What YouTube says about one video: its page's title and channel, embedding, playability, made for kids."""
    facts = {"id": vid, "page": "https://www.youtube.com/watch?v=" + vid}
    try:
        o = json.loads(_get("https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote(facts["page"])))
        facts["oembed"] = True
        facts["channel_url"] = o.get("author_url", "")
    except urllib.error.HTTPError as e:
        facts["oembed"] = False   # 401: embedding turned off; 404: no such video
        facts["oembed_error"] = e.code
    html = _get(facts["page"] + "&hl=en")
    m = re.search(r"var ytInitialPlayerResponse = (\{.*?\});(?:var|</script>)", html, re.S)
    pr = json.loads(m.group(1)) if m else {}
    ps = pr.get("playabilityStatus", {})
    vd = pr.get("videoDetails", {})
    mf = pr.get("microformat", {}).get("playerMicroformatRenderer", {})
    mini = json.dumps(ps.get("miniplayer", {}))
    facts.update({
        "title": vd.get("title", ""),
        "channel": vd.get("author", ""),
        "channel_id": vd.get("channelId", ""),
        "seconds": int(vd.get("lengthSeconds", "0") or 0),
        "playable": ps.get("status") == "OK",
        "embeddable": ps.get("playableInEmbed") is True,
        "family_safe": mf.get("isFamilySafe") is True,
        "made_for_kids": "made for kids" in mini and "PLAYBACK_MODE_PAUSED_ONLY" in mini,
        "live": vd.get("isLiveContent") is True and vd.get("isLive") is True,
    })
    return facts


def video_problems(facts):
    out = []
    if not facts.get("oembed"):
        out.append("YouTube does not allow embedding it (oEmbed %s)" % facts.get("oembed_error"))
    if not facts.get("playable"):
        out.append("not playable")
    if not facts.get("embeddable"):
        out.append("not playable in an embedded player")
    if not facts.get("family_safe"):
        out.append("not family safe")
    if not facts.get("made_for_kids"):
        out.append("its maker did not set it 'made for kids'")
    if facts.get("live"):
        out.append("a live stream (never an endless show)")
    return out


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def cmd_check(args, markdown=False):
    data = load(args.file)
    problems = shape_problems(data)
    for p in problems:
        print("SHAPE " + p)
    rows = []
    for c in data.get("channels", []) if isinstance(data, dict) else []:
        if c.get("platform") != "youtube":
            print("SKIP  %s: only YouTube channels are checked" % c.get("id"))
            continue
        for v in c.get("videos", []):
            try:
                facts = youtube_facts(v["id"])
            except Exception as e:   # the network: say so, count it as a problem
                facts = {"id": v["id"], "page": "https://www.youtube.com/watch?v=" + v["id"], "error": str(e)}
            bad = [facts["error"]] if "error" in facts else video_problems(facts)
            if v.get("made_for_kids") is True and not facts.get("made_for_kids", False) and "error" not in facts:
                bad.append("the list says made for kids; YouTube does not")
            if v.get("from") and facts.get("channel") and v["from"] != facts["channel"]:
                note = " (the list says %s)" % v["from"]
            else:
                note = ""
            problems.extend("%s/%s: %s" % (c["id"], v["id"], b) for b in bad)
            rows.append((c, v, facts, bad))
            if not markdown:
                print("%s %s/%s | %s | %s%s | %ss | %s" % ("OK  " if not bad else "BAD ", c["id"], v["id"],
                      facts.get("title", ""), facts.get("channel", ""), note, facts.get("seconds", "?"),
                      "; ".join(bad) if bad else "embeddable, made for kids"))
    if markdown:
        print("| Channel | Video | Its page | Title on YouTube | YouTube channel | Length | Checked |")
        print("|---|---|---|---|---|---|---|")
        for c, v, facts, bad in rows:
            secs = facts.get("seconds", 0)
            print("| %s | %s | %s | %s | %s | %d:%02d | %s |" % (
                c["title"], v["title"], facts["page"], facts.get("title", "").replace("|", "/"),
                facts.get("channel", ""), secs // 60, secs % 60,
                "embeddable, made for kids" if not bad else "; ".join(bad)))
    print("THEATER_LIST %s: %d videos, %d problems" % ("ok" if not problems else "FAIL", len(rows), len(problems)))
    return 0 if not problems else 1


def rpc(args, name, payload):
    key = os.environ.get("EASYCRAFT_HTTP_KEY", "")
    if not key:
        sys.exit("EASYCRAFT_HTTP_KEY is empty: set it to the server's NAKAMA_RUNTIME_HTTP_KEY (its .env)")
    url = "%s/v2/rpc/%s?http_key=%s&unwrap" % (args.server.rstrip("/"), name, urllib.parse.quote(key))
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), method="POST",
                                 headers={"Content-Type": "application/json", "User-Agent": "EasyCraft theater_list"})
    try:
        return json.loads(urllib.request.urlopen(req, timeout=30).read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        sys.exit("the server answered %d: %s" % (e.code, body))


def cmd_push(args):
    data = load(args.file)
    problems = shape_problems(data)
    if problems:
        print("\n".join("SHAPE " + p for p in problems))
        sys.exit("not sent: fix the list first")
    answer = rpc(args, "theater_set_channels", {"list": data})
    print(json.dumps(answer, indent=1))
    return 0 if answer.get("ok") else 1


def cmd_show(args):
    answer = rpc(args, "theater_channels", {})
    if answer.get("ok") and answer.get("list") is None:
        print("none: games play their bundled list")
    else:
        print(json.dumps(answer.get("list", answer), indent=1, ensure_ascii=False))
    return 0 if answer.get("ok") else 1


def cmd_off(args):
    answer = rpc(args, "theater_set_channels", {"list": {"enabled": False, "channels": []}})
    print(json.dumps(answer))
    return 0 if answer.get("ok") else 1


def cmd_clear(args):
    answer = rpc(args, "theater_set_channels", {"clear": True})
    print(json.dumps(answer))
    return 0 if answer.get("ok") else 1


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("command", choices=["check", "sources", "push", "show", "off", "clear"])
    p.add_argument("file", nargs="?", default=DEFAULT_FILE)
    p.add_argument("--server", default=DEFAULT_SERVER)
    args = p.parse_args()
    if args.command == "check":
        return cmd_check(args)
    if args.command == "sources":
        return cmd_check(args, markdown=True)
    return {"push": cmd_push, "show": cmd_show, "off": cmd_off, "clear": cmd_clear}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
