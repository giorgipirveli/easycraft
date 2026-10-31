// M4 Wave 3, agent I: friends when they are not online together (spec §17.5 research additions;
// docs/design T3, T4, D5), against the fake Nakama. Guards for everything (spec §17.2): friends only;
// nothing for an under-13 player without verified parental consent; the server checks every size and
// block id; preset stickers and phrases only; every received thing can be deleted; REPORT keeps a copy
// of the build for the reviewer.
//   send_gift / list_gifts / open_gift          a build to a friend, opened as a stamp
//   publish_showcase / get_showcase             one read-only build area a friend can visit
//   sign_guestbook / remove_sticker             preset stickers left by visitors
//   send_bottle / list_bottles / open_bottle    a quick phrase and maybe a tiny build
//   report_build                                a person reviews a build (a copy kept)
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const B = S.BuildRules;
const G = S.GiftRules;
const TEEN = A.defaults("13_plus");
const KID_OK = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const KID_NO = A.defaults("under_13");
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function cube(n: number, id = 6): string {
  return B.encode([n, n, n], new Array(n * n * n).fill(id));
}

function pair(meMeta: object = TEEN, palMeta: object = TEEN): { me: string; pal: string } {
  const me = nk.addUser("Me_1", meMeta);
  const pal = nk.addUser("Pal_1", palMeta);
  nk.befriend(me, pal);
  return { me, pal };
}

function objects(collection: string, userId?: string): any[] {
  return [...nk.storage.values()].filter((o) => o.collection === collection && (userId === undefined || o.userId === userId));
}

// --- Blueprint gifts ---

test("send_gift: a build to a friend, kept for them on the server, with a nudge (notification 104)", () => {
  const { me, pal } = pair();
  const r = call("rpcSendGift", me, { user_id: pal, build: cube(3) });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.match(r.gift_id, /^g\d+_[0-9a-f]{12}$/);
  const kept = objects("gifts", pal);
  assert.equal(kept.length, 1);
  assert.equal(kept[0].key, r.gift_id);
  assert.equal(kept[0].value.from_id, me);
  assert.equal(kept[0].value.from_username, "Me_1");
  assert.equal(kept[0].value.count, 27);
  assert.equal(kept[0].permissionRead, 0, "only through the server");
  assert.equal(kept[0].permissionWrite, 0);
  const note = nk.notifications.find((n) => n.code === 104)!;
  assert.equal(note.userId, pal);
  assert.equal(note.senderId, me);
  assert.deepEqual(note.content, { from_username: "Me_1", from_user_id: me, kind: "gift" });
  assert.equal(note.persistent, false, "list_gifts is the mailbox; the note only nudges an open game");
  assert.equal(call("rpcSendGift", me, { username: "pal_1", build: cube(2) }).ok, true, "by name, whatever its case");
});

test("send_gift: friends only, consent first, never to yourself", () => {
  const { me, pal } = pair();
  const stranger = nk.addUser("Stranger", TEEN);
  const kid = nk.addUser("Kiddo", KID_NO);
  nk.befriend(me, kid);
  const kidOk = nk.addUser("KidOk", KID_OK);
  nk.befriend(me, kidOk);
  const asked = nk.addUser("Asked", TEEN);
  nk.befriend(me, asked, 1);
  const blocker = nk.addUser("Blocker", TEEN);
  nk.befriend(me, blocker, 3);
  assert.equal(call("rpcSendGift", me, { user_id: stranger, build: cube(2) }).error, "not_friends");
  assert.equal(call("rpcSendGift", me, { user_id: asked, build: cube(2) }).error, "not_friends", "a request is not a friend");
  assert.equal(call("rpcSendGift", me, { user_id: blocker, build: cube(2) }).error, "not_friends");
  assert.equal(call("rpcSendGift", me, { user_id: kid, build: cube(2) }).error, "not_found", "a child without consent is nobody");
  assert.equal(call("rpcSendGift", me, { user_id: kidOk, build: cube(2) }).ok, true);
  assert.equal(call("rpcSendGift", me, { user_id: me, build: cube(2) }).error, "cannot_gift_self");
  assert.equal(call("rpcSendGift", me, { username: "Nobody_9", build: cube(2) }).error, "not_found");
  const lonelyKid = nk.addUser("LonelyKid", KID_NO);
  nk.befriend(lonelyKid, pal);
  assert.equal(call("rpcSendGift", lonelyKid, { user_id: pal, build: cube(2) }).error, "not_allowed_online");
  assert.equal(objects("gifts").length, 1);
});

test("send_gift: the server checks the build (ids, sizes) and keeps at most 10 unopened gifts per friend", () => {
  const { me, pal } = pair();
  assert.equal(call("rpcSendGift", me, { user_id: pal, build: cube(9) }).error, "too_big");
  assert.equal(call("rpcSendGift", me, { user_id: pal, build: B.encode([1, 1, 1], [110]) }).error, "bad_build");
  assert.equal(call("rpcSendGift", me, { user_id: pal, build: B.encode([1, 1, 1], [0]) }).error, "empty_build");
  assert.equal(call("rpcSendGift", me, { user_id: pal }).error, "bad_build");
  const ids: string[] = [];
  for (let i = 0; i < G.GIFTS_PER_FRIEND; i++) {
    now += 1;
    const r = call("rpcSendGift", me, { user_id: pal, build: cube(2) });
    assert.equal(r.ok, true, JSON.stringify(r));
    ids.push(r.gift_id);
  }
  assert.equal(call("rpcSendGift", me, { user_id: pal, build: cube(2) }).error, "too_many_gifts");
  assert.equal(call("rpcOpenGift", pal, { gift_id: ids[0] }).ok, true);
  assert.equal(call("rpcSendGift", me, { user_id: pal, build: cube(2) }).ok, true, "room again once one is opened");
});

test("send_gift: at most 30 sends an hour", () => {
  const { me } = pair();
  const pals: string[] = [];
  for (let i = 0; i < 4; i++) {
    const p = nk.addUser("Pal_x" + i, TEEN);
    nk.befriend(me, p);
    pals.push(p);
  }
  for (let i = 0; i < G.SENDS_PER_HOUR; i++) {
    now += 1;
    assert.equal(call("rpcSendGift", me, { user_id: pals[i % 4], build: cube(2) }).ok, true, String(i));
  }
  assert.equal(call("rpcSendGift", me, { user_id: pals[0], build: cube(2) }).error, "too_fast");
  now += 60 * MINUTE;
  assert.equal(call("rpcSendGift", me, { user_id: pals[1], build: cube(2) }).ok, true);
});

test("list_gifts and open_gift: the friend opens a gift once; the server forgets it then", () => {
  const { me, pal } = pair();
  const g1 = call("rpcSendGift", me, { user_id: pal, build: cube(2) }).gift_id;
  now += 5;
  const g2 = call("rpcSendGift", me, { user_id: pal, build: cube(3, 9) }).gift_id;
  const list = call("rpcListGifts", pal);
  assert.equal(list.ok, true, JSON.stringify(list));
  assert.deepEqual(list.gifts.map((g: any) => g.gift_id), [g1, g2], "oldest first");
  assert.deepEqual(list.gifts[1], { gift_id: g2, from_user_id: me, from_username: "Me_1", count: 27, size: [3, 3, 3],
    created_ms: now }, "no build in the list: it is opened one by one");
  const opened = call("rpcOpenGift", pal, { gift_id: g2 });
  assert.equal(opened.ok, true, JSON.stringify(opened));
  assert.equal(opened.gift.build, cube(3, 9));
  assert.equal(opened.gift.from_username, "Me_1");
  assert.deepEqual(opened.gift.size, [3, 3, 3]);
  assert.equal(call("rpcOpenGift", pal, { gift_id: g2 }).error, "not_found", "once");
  assert.equal(call("rpcOpenGift", me, { gift_id: g1 }).error, "not_found", "only the one it was sent to");
  assert.deepEqual(call("rpcOpenGift", pal, { gift_id: g1, discard: true }), { ok: true, discarded: true }, "deleted unopened");
  assert.equal(objects("gifts").length, 0);
  assert.deepEqual(call("rpcListGifts", pal).gifts, []);
});

test("list_gifts: a gift from someone who is no longer a friend (or blocked) goes away", () => {
  const { me, pal } = pair();
  call("rpcSendGift", me, { user_id: pal, build: cube(2) });
  nk.befriend(pal, me, 3);   // pal blocks me
  assert.deepEqual(call("rpcListGifts", pal).gifts, []);
  assert.equal(objects("gifts").length, 0, "deleted, not only hidden");
  const kid = nk.addUser("Kiddo", KID_NO);
  assert.equal(call("rpcListGifts", kid).error, "not_allowed_online");
});

// M4 Task 10 review: list_gifts and list_bottles refuse a child a grown-up took offline, and opening
// must too (the ids are known from an earlier list); deleting unopened always works.
test("open_gift and open_bottle: nothing opens while a grown-up keeps online play off; discarding still works", () => {
  const { me, pal } = pair(TEEN, KID_OK);
  const g = call("rpcSendGift", me, { user_id: pal, build: cube(2) }).gift_id;
  const b = call("rpcSendBottle", me, { user_id: pal, phrase: "Hi!" }).bottle_id;
  nk.users.get(pal)!.metadata = { ...KID_OK, online_allowed: false };
  assert.deepEqual(call("rpcOpenGift", pal, { gift_id: g }), { ok: false, error: "not_allowed_online" });
  assert.deepEqual(call("rpcOpenBottle", pal, { bottle_id: b }), { ok: false, error: "not_allowed_online" });
  assert.equal(objects("gifts", pal).length, 1, "kept for when a grown-up turns online play back on");
  assert.deepEqual(call("rpcOpenBottle", pal, { bottle_id: b, discard: true }), { ok: true, discarded: true });
  nk.users.get(pal)!.metadata = KID_OK;
  assert.equal(call("rpcOpenGift", pal, { gift_id: g }).ok, true);
});

// --- Showcases and the guestbook ---

test("publish_showcase and get_showcase: a friend visits even when the owner is away; strangers never", () => {
  const { me, pal } = pair();
  const stranger = nk.addUser("Stranger", TEEN);
  nk.befriend(stranger, pal, 1);
  assert.equal(call("rpcGetShowcase", pal, { user_id: me }).error, "no_showcase");
  const area = B.encode([20, 10, 20], new Array(4000).fill(0).map((_, i) => (i < 400 ? 1 : i % 7 === 0 ? 6 : 0)));
  const p = call("rpcPublishShowcase", me, { build: area });
  assert.equal(p.ok, true, JSON.stringify(p));
  assert.equal(p.count, 400 + [...Array(3600).keys()].filter((i) => (i + 400) % 7 === 0).length);
  const saved = objects("showcases", me)[0];
  assert.equal(saved.key, "showcase");
  assert.equal(saved.permissionRead, 0);
  const seen = call("rpcGetShowcase", pal, { username: "ME_1" });
  assert.equal(seen.ok, true, JSON.stringify(seen));
  assert.equal(seen.owner_id, me);
  assert.equal(seen.owner_username, "Me_1");
  assert.equal(seen.build, area);
  assert.deepEqual(seen.size, [20, 10, 20]);
  assert.equal(seen.guestbook, undefined, "a visitor never reads the guestbook");
  assert.equal(call("rpcGetShowcase", stranger, { user_id: me }).error, "not_friends");
  assert.equal(call("rpcGetShowcase", pal, { user_id: "0000" }).error, "not_found");
  const kid = nk.addUser("Kiddo", KID_NO);
  nk.befriend(kid, pal);
  assert.equal(call("rpcGetShowcase", pal, { user_id: kid }).error, "not_found", "a child without consent is nobody");
  assert.equal(call("rpcGetShowcase", kid, { user_id: pal }).error, "not_allowed_online");
});

test("publish_showcase: at most 32 x 32 x 32 and 48 KiB of text; a buddy may wave there; remove takes it down", () => {
  const { me, pal } = pair();
  assert.equal(call("rpcPublishShowcase", me, { build: B.encode([33, 1, 1], new Array(33).fill(6)) }).error, "too_big");
  // A checkerboard of two-byte ids: 32 x 32 x 32 cells, far over the text cap.
  const noisy: number[] = [];
  for (let i = 0; i < 32 * 32 * 32; i++) {
    noisy.push(i % 2 === 0 ? 200 : 201);
  }
  const text = B.encode([32, 32, 32], noisy);
  assert.ok(text.length > G.SHOWCASE.maxText);
  assert.equal(call("rpcPublishShowcase", me, { build: text }).error, "too_big");
  const area = cube(4);
  const buddy = { build: cube(2, 23), at: [1, 1, 1] };
  assert.equal(call("rpcPublishShowcase", me, { build: area, buddy: { build: cube(2, 23), at: [40, 0, 0] } }).error, "bad_buddy");
  assert.equal(call("rpcPublishShowcase", me, { build: area, buddy: { build: B.encode([18, 1, 1], new Array(18).fill(6)), at: [0, 0, 0] } }).error, "bad_buddy");
  assert.equal(call("rpcPublishShowcase", me, { build: area, buddy }).ok, true);
  const seen = call("rpcGetShowcase", pal, { user_id: me });
  assert.deepEqual(seen.buddy, { build: cube(2, 23), at: [1, 1, 1] }, "no name travels: the game names a buddy from its blocks");
  call("rpcSignGuestbook", pal, { user_id: me, sticker: "star" });
  assert.deepEqual(call("rpcPublishShowcase", me, { remove: true }), { ok: true, removed: true });
  assert.equal(call("rpcGetShowcase", pal, { user_id: me }).error, "no_showcase");
  assert.equal(objects("guestbook", me).length, 0, "the guestbook goes with it");
});

test("publish_showcase: taking it down always works, even when a grown-up switched online play off", () => {
  const { me, pal } = pair(KID_OK, TEEN);
  call("rpcPublishShowcase", me, { build: cube(3) });
  nk.users.get(me)!.metadata = { ...KID_OK, online_allowed: false };
  assert.equal(call("rpcPublishShowcase", me, { build: cube(3) }).error, "not_allowed_online", "no new one");
  assert.equal(call("rpcGetShowcase", pal, { user_id: me }).error, "not_found", "nobody can visit it meanwhile");
  assert.deepEqual(call("rpcPublishShowcase", me, { remove: true }), { ok: true, removed: true }, "but it can come down");
  assert.equal(objects("showcases", me).length, 0);
});

test("publish_showcase: at most 12 an hour", () => {
  const { me } = pair();
  for (let i = 0; i < G.PUBLISHES_PER_HOUR; i++) {
    now += 1;
    assert.equal(call("rpcPublishShowcase", me, { build: cube(2) }).ok, true);
  }
  assert.equal(call("rpcPublishShowcase", me, { build: cube(2) }).error, "too_fast");
});

test("sign_guestbook: a friend leaves a preset sticker; the owner reads (and deletes) them next time", () => {
  const { me, pal } = pair();
  const other = nk.addUser("Other_2", KID_OK);
  nk.befriend(me, other);
  assert.equal(call("rpcSignGuestbook", pal, { user_id: me, sticker: "star" }).error, "no_showcase");
  call("rpcPublishShowcase", me, { build: cube(3) });
  assert.equal(call("rpcSignGuestbook", pal, { user_id: me, sticker: "hello there" }).error, "bad_sticker");
  const r = call("rpcSignGuestbook", pal, { user_id: me, sticker: "star" });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(call("rpcSignGuestbook", pal, { user_id: me, sticker: "heart" }).error, "too_fast");
  now += 1;
  assert.equal(call("rpcSignGuestbook", other, { user_id: me, sticker: "rainbow" }).ok, true);
  const note = nk.notifications.find((n) => n.code === 106)!;
  assert.deepEqual(note.content, { from_username: "Pal_1", from_user_id: pal, sticker: "star" });
  assert.equal(note.userId, me);
  const mine = call("rpcGetShowcase", me, {});
  assert.equal(mine.ok, true, JSON.stringify(mine));
  assert.deepEqual(mine.guestbook.map((e: any) => [e.from_username, e.sticker]), [["Pal_1", "star"], ["Other_2", "rainbow"]]);
  const stranger = nk.addUser("Stranger", TEEN);
  assert.equal(call("rpcSignGuestbook", stranger, { user_id: me, sticker: "star" }).error, "not_friends");
  const removed = call("rpcRemoveSticker", me, { entry_id: mine.guestbook[0].entry_id });
  assert.equal(removed.ok, true);
  assert.deepEqual(removed.guestbook.map((e: any) => e.sticker), ["rainbow"]);
  assert.equal(call("rpcRemoveSticker", me, { entry_id: "nope" }).error, "not_found");
  assert.equal(call("rpcRemoveSticker", pal, { entry_id: mine.guestbook[1].entry_id }).error, "not_found", "only your own guestbook");
});

// --- Bottle mail ---

test("send_bottle: a quick phrase and maybe a tiny build (4 x 4 x 4 at most) to a friend", () => {
  const { me, pal } = pair(TEEN, KID_OK);
  assert.equal(call("rpcSendBottle", me, { user_id: pal, phrase: "meet me at school" }).error, "bad_phrase");
  assert.equal(call("rpcSendBottle", me, { user_id: pal, phrase: "Hi!", build: cube(5) }).error, "too_big");
  const plain = call("rpcSendBottle", me, { user_id: pal, phrase: "Hi!" });
  assert.equal(plain.ok, true, JSON.stringify(plain));
  now += 1;
  const withBuild = call("rpcSendBottle", me, { user_id: pal, phrase: "Look!", build: cube(4, 12) });
  assert.equal(withBuild.ok, true, JSON.stringify(withBuild));
  const note = nk.notifications.find((n) => n.code === 105)!;
  assert.deepEqual(note.content, { from_username: "Me_1", from_user_id: me, kind: "bottle" });
  const list = call("rpcListBottles", pal);
  assert.deepEqual(list.bottles.map((b: any) => b.bottle_id), [plain.bottle_id, withBuild.bottle_id]);
  assert.equal(list.bottles[0].from_username, "Me_1");
  assert.equal(list.bottles[0].phrase, undefined, "what is inside shows when it is opened");
  const opened = call("rpcOpenBottle", pal, { bottle_id: withBuild.bottle_id });
  assert.deepEqual(opened.bottle.phrase, "Look!");
  assert.equal(opened.bottle.build, cube(4, 12));
  assert.equal(call("rpcOpenBottle", pal, { bottle_id: plain.bottle_id }).bottle.build, undefined);
  assert.deepEqual(call("rpcListBottles", pal).bottles, []);
  const stranger = nk.addUser("Stranger", TEEN);
  assert.equal(call("rpcSendBottle", stranger, { user_id: pal, phrase: "Hi!" }).error, "not_friends");
});

test("send_bottle: at most 5 unopened bottles per friend; discard deletes one unopened", () => {
  const { me, pal } = pair();
  const ids: string[] = [];
  for (let i = 0; i < G.BOTTLES_PER_FRIEND; i++) {
    now += 1;
    ids.push(call("rpcSendBottle", me, { user_id: pal, phrase: "Wow!" }).bottle_id);
  }
  assert.equal(call("rpcSendBottle", me, { user_id: pal, phrase: "Wow!" }).error, "too_many_bottles");
  assert.deepEqual(call("rpcOpenBottle", pal, { bottle_id: ids[0], discard: true }), { ok: true, discarded: true });
  assert.equal(call("rpcSendBottle", me, { user_id: pal, phrase: "Wow!" }).ok, true);
});

// --- REPORT on everything received ---

test("report_build: a person reviews the build; the report keeps the server's copy, else the child's", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: cube(3) });
  const r = call("rpcReportBuild", pal, { user_id: me, what: "showcase" });
  assert.equal(r.ok, true, JSON.stringify(r));
  const reports = [...nk.storage.values()].filter((o) => o.collection === "reports" && o.userId === SYSTEM_USER);
  assert.equal(reports.length, 1);
  const v = reports[0].value;
  assert.equal(v.reason, "bad_build");
  assert.equal(v.what, "showcase");
  assert.equal(v.reported_id, me);
  assert.equal(v.reporter_id, pal);
  assert.equal(v.status, "new");
  assert.deepEqual(v.build, { build: cube(3), size: [3, 3, 3], source: "server" });
  // A gift already opened: only the child's game has it now.
  now += 11 * MINUTE;
  const other = nk.addUser("Other_2", TEEN);
  nk.befriend(other, pal);
  assert.equal(call("rpcReportBuild", pal, { user_id: other, what: "gift", build: cube(2, 9), reason: "scary" }).ok, true);
  const second = [...nk.storage.values()].filter((o) => o.collection === "reports").map((o) => o.value).find((x) => x.what === "gift")!;
  assert.deepEqual(second.build, { build: cube(2, 9), size: [2, 2, 2], source: "reporter" });
  assert.equal(second.reason, "scary");
  assert.equal(call("rpcReportBuild", pal, { user_id: pal, what: "gift" }).error, "cannot_report_self");
  assert.equal(call("rpcReportBuild", pal, { user_id: "0000", what: "gift" }).error, "not_found");
  assert.equal(call("rpcReportBuild", pal, { user_id: me, what: "painting" }).error, "bad_request");
  now += 11 * MINUTE;
  const bad = call("rpcReportBuild", pal, { user_id: me, what: "bottle", build: "junk" });
  assert.equal(bad.ok, true, "a report is never lost for a broken copy");
  const third = [...nk.storage.values()].map((o) => o.value).find((x) => x.what === "bottle")!;
  assert.equal(third.build, null);
});

test("report_build: shares report_user's limit (10 an hour)", () => {
  const { me, pal } = pair();
  for (let i = 0; i < 10; i++) {
    const p = nk.addUser("Pal_y" + i, TEEN);
    assert.equal(call("rpcReportUser", me, { user_id: p, reason: "other" }).ok, true);
  }
  assert.equal(call("rpcReportBuild", me, { user_id: pal, what: "gift", build: cube(2) }).error, "too_many");
});

test("the module is 0.2.12 (0.2.11 or later) and registers every RPC of this wave", () => {
  const registered: string[] = [];
  // Every other register* call (hooks) does nothing here.
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  for (const id of ["send_gift", "list_gifts", "open_gift", "publish_showcase", "get_showcase", "sign_guestbook",
    "remove_sticker", "send_bottle", "list_bottles", "open_bottle", "report_build"]) {
    assert.ok(registered.includes(id), id);
  }
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});

// --- The data rights (M4 Task 8b) reach every collection of this wave ---

test("delete_account: everything this wave keeps goes with the account, both what it got and what it sent", () => {
  const { me, pal } = pair();
  const third = nk.addUser("Third_3", TEEN);
  nk.befriend(me, third);
  nk.befriend(pal, third);
  call("rpcSendGift", me, { user_id: pal, build: cube(2) });
  call("rpcSendBottle", me, { user_id: pal, phrase: "Hi!" });
  call("rpcSendGift", pal, { user_id: me, build: cube(2) });
  call("rpcSendBottle", third, { user_id: me, phrase: "Wow!" });
  call("rpcPublishShowcase", me, { build: cube(3) });
  call("rpcPublishShowcase", pal, { build: cube(3) });
  call("rpcPublishShowcase", third, { build: cube(3) });
  call("rpcSignGuestbook", pal, { user_id: me, sticker: "star" });
  call("rpcSignGuestbook", me, { user_id: pal, sticker: "heart" });
  call("rpcSignGuestbook", third, { user_id: pal, sticker: "wow" });
  call("rpcSignGuestbook", me, { user_id: third, sticker: "smile" });
  nk.cascade = false;   // the module's own clean-up, not the database's cascade
  const c = call("rpcDeleteAccount", me, {});
  const done = call("rpcDeleteAccount", me, { confirm: c.confirm });
  assert.equal(done.deleted, true, JSON.stringify(done));
  for (const col of ["gifts", "bottles", "showcases", "guestbook"]) {
    assert.deepEqual(objects(col, me), [], col + ": the player's own");
  }
  assert.deepEqual(objects("gifts", pal), [], "the gift it sent is gone from its friend");
  assert.deepEqual(objects("bottles", pal), [], "and its bottle");
  const palBook = objects("guestbook", pal)[0].value;
  assert.deepEqual(palBook.entries.map((e: any) => e.from_username), ["Third_3"], "its sticker is gone, the others stay");
  assert.equal(objects("guestbook", third).length, 0, "a guestbook left empty is deleted");
  assert.equal(done.gifts_sent, 2);
  assert.equal(done.stickers_left, 2);
});

test("retention: unopened gifts and bottles, and stickers, go after 60 days; what deleted players left goes too", () => {
  const { me, pal } = pair();
  call("rpcSendGift", me, { user_id: pal, build: cube(2) });
  call("rpcSendBottle", me, { user_id: pal, phrase: "Hi!" });
  call("rpcPublishShowcase", pal, { build: cube(3) });
  call("rpcSignGuestbook", me, { user_id: pal, sticker: "star" });
  now += 30 * DAY;
  const fresh = call("rpcSendGift", me, { user_id: pal, build: cube(2) }).gift_id;
  call("rpcSignGuestbook", me, { user_id: pal, sticker: "heart" });
  now += 30 * DAY;
  const r = JSON.parse(S.rpcRetentionRun(ctx(""), log, nk, "{}"));
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.gifts_expired, 2, "the first gift and the bottle");
  assert.deepEqual(objects("gifts", pal).map((o) => o.key), [fresh]);
  assert.deepEqual(objects("bottles", pal), []);
  assert.deepEqual(objects("guestbook", pal)[0].value.entries.map((e: any) => e.sticker), ["heart"]);
  assert.equal(r.stickers_expired, 1);
  // A sender deleted in the console (no module clean-up): what it left behind goes at the next run.
  nk.cascade = true;
  nk.accountDeleteId(me);
  now += 2 * DAY;
  const again = JSON.parse(S.rpcRetentionRun(ctx(""), log, nk, "{}"));
  assert.equal(again.gifts_orphaned, 1);
  assert.deepEqual(objects("gifts", pal), []);
  assert.equal(again.stickers_orphaned, 1);
  assert.equal(objects("guestbook", pal).length, 0);
});
