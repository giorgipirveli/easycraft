// M4 ghost races (spec §17.5; docs/design T2): a player's best run on a course they built, shared as a
// ghost on their showcase or with a blueprint gift, raced by friends. Against the fake Nakama. Guards
// (spec §17.2, the same as showcases): friends only, nothing for an under-13 player without verified
// parental consent, the server checks every ghost against its course (GhostRules), small ghosts and few of
// them, rate limits, REPORT keeps a copy for the reviewer, everything deleted with the account; no ranking
// anyone else can see.
//   share_ghost  {"to": "showcase", "ghost"} | {"to": "gift", "user_id", "build", "ghost"} | {"remove": id}
//   list_ghosts  {"user_id" | "username"} a friend's showcase ghosts; {} your own
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const B = S.BuildRules;
const G = S.GiftRules;
const H = S.GhostRules;
const TEEN = A.defaults("13_plus");
const KID_OK = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const KID_NO = A.defaults("under_13");
const MINUTE = 60 * 1000;
const START = 203;
const FINISH = 205;
const STONE = 1;

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

function pair(meMeta: object = TEEN, palMeta: object = TEEN): { me: string; pal: string } {
  const me = nk.addUser("Me_1", meMeta);
  const pal = nk.addUser("Pal_1", palMeta);
  nk.befriend(me, pal);
  return { me, pal };
}

function objects(collection: string, userId?: string): any[] {
  return [...nk.storage.values()].filter((o) => o.collection === collection && (userId === undefined || o.userId === userId));
}

// A course area of `size`: a stone floor with START/FINISH pairs at the given cells (y 0).
function course(size: number[], pairs: number[][][]): string {
  const cells: number[] = [];
  for (let y = 0; y < size[1]; y++) {
    for (let z = 0; z < size[2]; z++) {
      for (let x = 0; x < size[0]; x++) {
        let id = y === 0 ? STONE : 0;
        for (const [s, f] of pairs) {
          if (y === 0 && x === s[0] && z === s[2]) {
            id = START;
          }
          if (y === 0 && x === f[0] && z === f[2]) {
            id = FINISH;
          }
        }
        cells.push(id);
      }
    }
  }
  return B.encode(size, cells);
}

// A 10 x 3 x 10 showcase with one course: START (1, 0, 1), FINISH (8, 0, 8).
const AREA = course([10, 3, 10], [[[1, 0, 1], [8, 0, 8]]]);

// A straight run from START's top to FINISH's top (decimetres), `ms` long.
function ghost(start: number[], finish: number[], ms: number, look = ""): any {
  const n = H.sampleCount(ms);
  const to = [(finish[0] - start[0]) * 10, 0, (finish[2] - start[2]) * 10];
  const points: number[][] = [];
  for (let k = 0; k < n; k++) {
    points.push([Math.round(to[0] * k / (n - 1)), 0, Math.round(to[2] * k / (n - 1))]);
  }
  return { start: start, finish: finish, ms: ms, path: H.encodePath(points), look: look };
}

const RUN = ghost([1, 0, 1], [8, 0, 8], 2000, "{\"hat\":\"cap\"}");

function shareOnShowcase(userId: string, g: any = RUN): any {
  return call("rpcShareGhost", userId, { to: "showcase", ghost: g });
}

// --- On the showcase ---

test("share_ghost: my best run on my showcase, kept by the server for friends to race", () => {
  const { me } = pair();
  assert.equal(call("rpcPublishShowcase", me, { build: AREA }).ok, true);
  const r = shareOnShowcase(me);
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.match(r.ghost_id, /^h\d+_[0-9a-f]{12}$/);
  assert.equal(r.ms, 2000);
  const kept = objects("ghosts", me);
  assert.equal(kept.length, 1);
  assert.equal(kept[0].key, "showcase");
  assert.equal(kept[0].permissionRead, 0, "only through the server");
  assert.equal(kept[0].permissionWrite, 0);
  const g = kept[0].value.ghosts[0];
  assert.equal(g.ghost_id, r.ghost_id);
  assert.deepEqual([g.start, g.finish, g.ms, g.path, g.look], [RUN.start, RUN.finish, 2000, RUN.path, RUN.look]);
  assert.equal(g.updated_ms, now);
});

test("list_ghosts: friends race them; strangers never see them, nor anyone while consent is missing", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  shareOnShowcase(me);
  const r = call("rpcListGhosts", pal, { user_id: me });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.owner_id, me);
  assert.equal(r.owner_username, "Me_1");
  assert.equal(r.ghosts.length, 1);
  assert.deepEqual([r.ghosts[0].start, r.ghosts[0].finish, r.ghosts[0].ms, r.ghosts[0].path, r.ghosts[0].look],
    [RUN.start, RUN.finish, 2000, RUN.path, RUN.look]);
  assert.equal(call("rpcListGhosts", pal, { username: "me_1" }).ghosts.length, 1, "by name, whatever its case");
  const mine = call("rpcListGhosts", me, {});
  assert.equal(mine.ok, true);
  assert.equal(mine.ghosts.length, 1, "your own");
  assert.equal(call("rpcListGhosts", pal, {}).ghosts.length, 0, "no ghosts yet is an empty list");
  const stranger = nk.addUser("Stranger", TEEN);
  assert.equal(call("rpcListGhosts", stranger, { user_id: me }).error, "not_friends", "no ranking a stranger can see");
  const kid = nk.addUser("Kiddo", KID_NO);
  nk.befriend(me, kid);
  assert.equal(call("rpcListGhosts", kid, { user_id: me }).error, "not_allowed_online");
  assert.equal(call("rpcListGhosts", me, { user_id: kid }).error, "not_found", "a child without consent is nobody");
  const kidOk = nk.addUser("KidOk", KID_OK);
  nk.befriend(me, kidOk);
  assert.equal(call("rpcListGhosts", kidOk, { user_id: me }).ghosts.length, 1, "with a grown-up's yes");
});

test("share_ghost: the server checks the run against the showcase", () => {
  const { me } = pair();
  assert.equal(shareOnShowcase(me).error, "no_showcase");
  call("rpcPublishShowcase", me, { build: AREA });
  assert.equal(shareOnShowcase(me, { ...RUN, ms: "fast" }).error, "bad_ghost");
  assert.equal(shareOnShowcase(me, ghost([2, 0, 1], [8, 0, 8], 2000)).error, "not_on_course", "no START there");
  assert.equal(shareOnShowcase(me, ghost([1, 0, 1], [8, 0, 8], 1000)).error, undefined, "a 10 m/s run is fine");
  const hop = ghost([1, 0, 1], [8, 0, 8], 2000);
  const points = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0],
    [0, 0, 0], [70, 0, 70]];
  assert.equal(shareOnShowcase(me, { ...hop, path: H.encodePath(points) }).error, "impossible_run", "a teleport onto FINISH");
  assert.equal(call("rpcShareGhost", me, { to: "moon", ghost: RUN }).error, "bad_request");
  const kid = nk.addUser("Kiddo", KID_NO);
  assert.equal(shareOnShowcase(kid).error, "not_allowed_online");
});

test("share_ghost: one ghost per course, at most 3 on a showcase; a better run replaces the old one", () => {
  const { me, pal } = pair();
  const four = course([20, 3, 20], [[[1, 0, 1], [8, 0, 1]], [[1, 0, 5], [8, 0, 5]], [[1, 0, 9], [8, 0, 9]], [[1, 0, 13], [8, 0, 13]]]);
  call("rpcPublishShowcase", me, { build: four });
  assert.equal(shareOnShowcase(me, ghost([1, 0, 1], [8, 0, 1], 3000)).ok, true);
  const better = shareOnShowcase(me, ghost([1, 0, 1], [8, 0, 1], 2000));
  assert.equal(better.ok, true);
  let list = call("rpcListGhosts", pal, { user_id: me }).ghosts;
  assert.equal(list.length, 1, "the same course: replaced");
  assert.equal(list[0].ms, 2000);
  assert.equal(list[0].ghost_id, better.ghost_id);
  assert.equal(shareOnShowcase(me, ghost([1, 0, 5], [8, 0, 5], 3000)).ok, true);
  assert.equal(shareOnShowcase(me, ghost([1, 0, 9], [8, 0, 9], 3000)).ok, true);
  assert.equal(shareOnShowcase(me, ghost([1, 0, 13], [8, 0, 13], 3000)).error, "too_many_ghosts");
  list = call("rpcListGhosts", pal, { user_id: me }).ghosts;
  assert.deepEqual(list.map((g: any) => g.start[2]), [1, 5, 9]);
});

test("share_ghost: at most 12 shares an hour", () => {
  const { me } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  for (let i = 0; i < H.SHARES_PER_HOUR; i++) {
    now += 1;
    assert.equal(shareOnShowcase(me).ok, true, String(i));
  }
  assert.equal(shareOnShowcase(me).error, "too_fast");
  now += 60 * MINUTE;
  assert.equal(shareOnShowcase(me).ok, true);
});

test("share_ghost: taking a ghost down always works; a new showcase, or none, takes its ghosts down", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  const id = shareOnShowcase(me).ghost_id;
  assert.equal(call("rpcShareGhost", me, { remove: "h0_000000000000" }).error, "not_found");
  nk.users.get(me)!.metadata = { ...KID_NO };   // even when the player may not be online any more
  assert.deepEqual(call("rpcShareGhost", me, { remove: id }), { ok: true, removed: true });
  assert.equal(objects("ghosts", me).length, 0, "the last one: the object goes");
  nk.users.get(me)!.metadata = { ...TEEN };
  shareOnShowcase(me);
  call("rpcPublishShowcase", me, { build: AREA });
  assert.equal(call("rpcListGhosts", pal, { user_id: me }).ghosts.length, 0, "a new showcase is a new area: its ghosts go");
  shareOnShowcase(me);
  call("rpcPublishShowcase", me, { remove: true });
  assert.equal(objects("ghosts", me).length, 0, "no showcase: no ghosts");
});

// --- With a blueprint gift ---

test("share_ghost to a gift: the course and my ghost as one present; open_gift gives the ghost", () => {
  const { me, pal } = pair();
  const small = course([8, 2, 8], [[[0, 0, 0], [7, 0, 7]]]);
  const g = ghost([0, 0, 0], [7, 0, 7], 2000, "{\"hat\":\"cap\"}");
  const r = call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small, ghost: g });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.match(r.gift_id, /^g\d+_[0-9a-f]{12}$/);
  const note = nk.notifications.find((n) => n.code === 104)!;
  assert.deepEqual(note.content, { from_username: "Me_1", from_user_id: me, kind: "gift" }, "a present, like any gift");
  const listed = call("rpcListGifts", pal, {}).gifts;
  assert.equal(listed.length, 1);
  assert.equal(listed[0].ghost, true, "the list says a ghost comes with it");
  const opened = call("rpcOpenGift", pal, { gift_id: r.gift_id }).gift;
  assert.equal(opened.build, small);
  assert.deepEqual([opened.ghost.start, opened.ghost.finish, opened.ghost.ms, opened.ghost.path, opened.ghost.look],
    [g.start, g.finish, 2000, g.path, g.look]);
  // A plain gift says no ghost.
  call("rpcSendGift", me, { user_id: pal, build: small });
  assert.equal(call("rpcListGifts", pal, {}).gifts[0].ghost, undefined);
});

test("share_ghost to a gift: the gift's own rules, and the ghost must fit its build", () => {
  const { me, pal } = pair();
  const small = course([8, 2, 8], [[[0, 0, 0], [7, 0, 7]]]);
  const g = ghost([0, 0, 0], [7, 0, 7], 2000);
  const stranger = nk.addUser("Stranger", TEEN);
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: stranger, build: small, ghost: g }).error, "not_friends");
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: me, build: small, ghost: g }).error, "cannot_gift_self");
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: pal, build: AREA, ghost: ghost([1, 0, 1], [8, 0, 8], 2000) }).error,
    "too_big", "a gift is 8 x 8 x 8 at most");
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small, ghost: ghost([0, 0, 0], [6, 0, 6], 2000) }).error,
    "not_on_course");
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small }).error, "bad_ghost", "a gift without a ghost: send_gift");
  assert.equal(objects("gifts").length, 0, "nothing was delivered");
  for (let i = 0; i < G.GIFTS_PER_FRIEND; i++) {
    now += 1;
    assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small, ghost: g }).ok, true);
  }
  assert.equal(call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small, ghost: g }).error, "too_many_gifts");
});

test("share_ghost: the payload may be 16 KiB (a gift's build and a 3-minute ghost), no more", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  const long = { ...RUN, look: "{\"x\":\"" + "y".repeat(2100) + "\"}" };
  assert.equal(shareOnShowcase(me, long).error, "bad_ghost", "a look over 2 KiB");
  const big = JSON.stringify({ to: "gift", user_id: pal, build: "A".repeat(H.PAYLOAD), ghost: RUN });
  assert.equal(call("rpcShareGhost", me, big).error, "too_big");
});

// --- REPORT covers ghosts ---

test("report_build: a ghost can be reported; the report keeps the server's copy (else the child's)", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  const id = shareOnShowcase(me).ghost_id;
  assert.equal(call("rpcReportBuild", pal, { user_id: me, what: "ghost", ghost_id: id, reason: "other" }).ok, true);
  const reports = () => [...nk.storage.values()].filter((o) => o.collection === "reports" && o.userId === SYSTEM_USER).map((o) => o.value);
  const first = reports().find((v) => v.what === "ghost")!;
  assert.equal(first.reported_id, me);
  assert.equal(first.reason, "other");
  assert.equal(first.ghost.source, "server");
  assert.equal(first.ghost.path, RUN.path);
  assert.equal(first.ghost.look, RUN.look);
  // A showcase's report keeps its ghosts too.
  now += 11 * MINUTE;
  assert.equal(call("rpcReportBuild", pal, { user_id: me, what: "showcase" }).ok, true);
  const second = reports().find((v) => v.what === "showcase")!;
  assert.equal(second.ghosts.length, 1);
  assert.equal(second.ghosts[0].path, RUN.path);
  // A gift's ghost, already opened: only the child's game has it.
  now += 11 * MINUTE;
  const other = nk.addUser("Other_2", TEEN);
  nk.befriend(other, pal);
  const g = ghost([0, 0, 0], [7, 0, 7], 2000);
  assert.equal(call("rpcReportBuild", pal, { user_id: other, what: "ghost", ghost: g }).ok, true);
  const third = reports().filter((v) => v.what === "ghost").find((v) => v.reported_id === other)!;
  assert.equal(third.ghost.source, "reporter");
  assert.equal(third.ghost.path, g.path);
  now += 11 * MINUTE;
  assert.equal(call("rpcReportBuild", pal, { user_id: other, what: "ghost", ghost: { path: 5 } }).ok, true, "never lost for a broken copy");
  assert.equal(reports().filter((v) => v.what === "ghost" && v.reported_id === other).some((v) => v.ghost === null), true);
});

// --- Deleted with the account ---

test("delete_account: the player's ghosts go, and the ghosts it sent in gifts", () => {
  const { me, pal } = pair();
  call("rpcPublishShowcase", me, { build: AREA });
  shareOnShowcase(me);
  const small = course([8, 2, 8], [[[0, 0, 0], [7, 0, 7]]]);
  call("rpcShareGhost", me, { to: "gift", user_id: pal, build: small, ghost: ghost([0, 0, 0], [7, 0, 7], 2000) });
  nk.cascade = false;   // the module's own clean-up, not the database's cascade
  const c = call("rpcDeleteAccount", me, {});
  const done = call("rpcDeleteAccount", me, { confirm: c.confirm });
  assert.equal(done.deleted, true, JSON.stringify(done));
  assert.deepEqual(objects("ghosts", me), []);
  assert.deepEqual(objects("gifts", pal), [], "the gift with its ghost is gone from its friend");
});

test("the module is 0.2.12 (0.2.11 or later) and registers share_ghost and list_ghosts", () => {
  const registered: string[] = [];
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  for (const id of ["share_ghost", "list_ghosts"]) {
    assert.ok(registered.includes(id), id);
  }
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
