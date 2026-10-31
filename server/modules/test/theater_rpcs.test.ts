// Owner #89 (spec §5.12, §14.12; module 0.2.18): the Theater's channel list on the server. The owner keeps a list
// (theater_set_channels, tools/theater_list.py) after the server checked every field; every game reads it
// (theater_channels) and keeps the last one; a list with a mistake is refused whole, with each mistake named.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, SYSTEM_USER, ctx } from "./fake_nakama.ts";

const S = server();
const R = S.TheaterListRules;
const BUNDLED = fileURLToPath(new URL("../../../data/theater/channels.json", import.meta.url));

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  S.Server.nowMs = () => now;
});

function owner(payload: unknown): any {
  return JSON.parse(S.rpcTheaterSetChannels(ctx(""), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function read(userId: string): any {
  return JSON.parse(S.rpcTheaterChannels(ctx(userId), log, nk, "{}"));
}

function list(): any {
  return {
    enabled: true,
    channels: [
      { id: "easycraft_tv", title: "EasyCraft TV", platform: "youtube", color: "#3a7be8", icon: "tv",
        videos: [{ id: "fYa-hmNzlAQ", title: "Who is Paxi?", made_for_kids: true, from: "European Space Agency, ESA" }] },
      { id: "space", title: "Space", platform: "youtube", icon: "planet",
        videos: [{ id: "mibxJwpennU", title: "Paxi: The Solar System", made_for_kids: true },
          { id: "--xEE7K67Xo", title: "  All About Polar Bears ", made_for_kids: true }] },
    ],
  };
}

test("the owner keeps a list: everyone may read it, only the server writes it", () => {
  const r = owner({ list: list() });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.enabled, true);
  assert.equal(r.channels, 2);
  assert.equal(r.videos, 3);
  assert.equal(r.updated_ms, now);
  const o = nk.object("theater", "channels", SYSTEM_USER)!;
  assert.ok(o, "kept as the system user's object");
  assert.equal(o.permissionRead, 2, "public: every game may read it");
  assert.equal(o.permissionWrite, 0, "only the server writes it");
  assert.equal(o.value.source, "server");
  assert.equal(o.value.updated_ms, now);
  assert.equal(o.value.version, 1);
  assert.equal(o.value.channels[1].videos[1].title, "All About Polar Bears", "titles trimmed");
  assert.equal(o.value.channels[0].videos[0].from, "European Space Agency, ESA");
});

test("a game reads the kept list, and null before there is one", () => {
  assert.deepEqual(read("u1"), { ok: true, list: null });
  owner({ list: list() });
  const r = read("u1");
  assert.equal(r.ok, true);
  assert.equal(r.list.source, "server");
  assert.equal(r.list.channels[0].id, "easycraft_tv");
  assert.equal(r.list.channels[0].videos[0].made_for_kids, true);
});

test("a game can't send a list, nor write the collection itself", () => {
  const u = nk.addUser("Kid_1");
  const r = JSON.parse(S.rpcTheaterSetChannels(ctx(u), log, nk, JSON.stringify({ list: list() })));
  assert.deepEqual(r, { ok: false, error: "not_allowed" });
  assert.equal(nk.object("theater", "channels", SYSTEM_USER), undefined, "nothing kept");
  assert.throws(() => S.beforeWriteStorageObjects(ctx(u), log, nk,
    { objects: [{ collection: "theater", key: "channels", value: "{}" }] }), { message: "not_allowed" });
});

test("the kill-switch is a list too: enabled false with no channels", () => {
  const r = owner({ list: { enabled: false, channels: [] } });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.enabled, false);
  assert.equal(read("u1").list.enabled, false);
});

test("clear deletes the list: games go back to their bundled one", () => {
  owner({ list: list() });
  assert.deepEqual(owner({ clear: true }), { ok: true, cleared: true });
  assert.equal(read("u1").list, null);
});

test("only the known fields are kept", () => {
  const l = list();
  l.extra = "x";
  l.channels[0].secret = "<script>";
  l.channels[0].videos[0].url = "https://example.com";
  owner({ list: l });
  const kept = nk.object("theater", "channels", SYSTEM_USER)!.value;
  assert.equal(kept.extra, undefined);
  assert.equal(kept.channels[0].secret, undefined);
  assert.equal(kept.channels[0].videos[0].url, undefined);
  assert.deepEqual(Object.keys(kept.channels[0].videos[0]).sort(), ["from", "id", "made_for_kids", "title"]);
});

test("a list with a mistake is refused whole, each mistake named", () => {
  const cases: [string, (l: any) => void, RegExp][] = [
    ["no switch", (l) => { delete l.enabled; }, /^enabled:/],
    ["a string switch", (l) => { l.enabled = "true"; }, /^enabled:/],
    ["channels not a list", (l) => { l.channels = {}; }, /^channels:/],
    ["too many channels", (l) => { l.channels = Array.from({ length: 13 }, (_, i) => ({ ...list().channels[1], id: "c" + i })); }, /at most 12/],
    ["a bad channel id", (l) => { l.channels[1].id = "Space!"; }, /channels\[1\]\.id/],
    ["a channel twice", (l) => { l.channels[1].id = "easycraft_tv"; }, /twice/],
    ["a long channel title", (l) => { l.channels[1].title = "x".repeat(41); }, /channels\[1\]\.title/],
    ["an empty title", (l) => { l.channels[1].title = "   "; }, /channels\[1\]\.title/],
    ["a title with a control character", (l) => { l.channels[1].videos[0].title = "a\u0000b"; }, /videos\[0\]\.title/],
    ["a platform", (l) => { l.channels[1].platform = "vimeo"; }, /platform/],
    ["a colour", (l) => { l.channels[1].color = "red"; }, /color/],
    ["an icon", (l) => { l.channels[1].icon = "skull"; }, /icon/],
    ["no videos", (l) => { l.channels[1].videos = []; }, /videos: a list/],
    ["too many videos", (l) => { l.channels[1].videos = Array.from({ length: 51 }, (_, i) => ({ id: "abcdefghi" + String(i).padStart(2, "0"), title: "V", made_for_kids: true })); }, /at most 50/],
    ["a video id that is code", (l) => { l.channels[1].videos[0].id = "');alert(1)"; }, /videos\[0\]\.id: not a youtube video id/],
    ["a short video id", (l) => { l.channels[1].videos[0].id = "abc"; }, /videos\[0\]\.id/],
    ["a video twice", (l) => { l.channels[1].videos[1].id = "mibxJwpennU"; }, /twice/],
    ["made for kids as a word", (l) => { l.channels[1].videos[0].made_for_kids = "yes"; }, /made_for_kids/],
    ["a long maker", (l) => { l.channels[1].videos[0].from = "x".repeat(31); }, /from/],
  ];
  for (const [what, spoil, expected] of cases) {
    const l = list();
    spoil(l);
    const r = owner({ list: l });
    assert.equal(r.ok, false, what);
    assert.equal(r.error, "bad_list", what);
    assert.ok(r.problems.some((p: string) => expected.test(p)), what + ": " + JSON.stringify(r.problems));
    assert.equal(nk.object("theater", "channels", SYSTEM_USER), undefined, what + ": nothing kept");
  }
});

test("a list that is not an object, or a payload that is not JSON, is refused", () => {
  assert.equal(owner({ list: [1, 2] }).error, "bad_list");
  assert.equal(owner({}).error, "bad_list");
  assert.equal(owner("not json").error, "bad_request");
  assert.equal(owner("x".repeat(70_000)).error, "too_big");
});

test("TikTok ids are digits; YouTube ids are 11 letters, digits, - and _", () => {
  assert.equal(R.isVideoId("youtube", "aqz-KE-bpKQ"), true);
  assert.equal(R.isVideoId("youtube", "7000000000000000001"), false);
  assert.equal(R.isVideoId("tiktok", "7000000000000000001"), true);
  assert.equal(R.isVideoId("tiktok", "aqz-KE-bpKQ"), false);
  assert.equal(R.isVideoId("vimeo", "12345678"), false);
});

test("the game's bundled list passes the server's rules as it is", () => {
  const bundled = JSON.parse(readFileSync(BUNDLED, "utf8"));
  const r = owner({ list: bundled });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.ok(r.channels >= 8, "EasyCraft TV and seven more");
  const kept = nk.object("theater", "channels", SYSTEM_USER)!.value;
  assert.equal(kept.channels[0].id, "easycraft_tv", "EasyCraft TV first");
  for (const c of kept.channels) {
    assert.equal(c.platform, "youtube", c.id);
    assert.ok(c.videos.length >= 6 && c.videos.length <= 12, c.id + ": 6-12 videos");
    for (const v of c.videos) {
      assert.equal(v.made_for_kids, true, c.id + "/" + v.id + " made for kids");
      assert.ok(v.from, c.id + "/" + v.id + " names its maker");
    }
  }
});

test("module 0.2.20", () => {
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
