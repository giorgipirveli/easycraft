// M4 Wave 2, agent F (spec §17.2, §17.6): a grown-up approves an under-13 player's friends, and a
// code used offline is recorded on the server at the next sign-in so it can't pay twice. Pure rules
// (FriendApprovals, CodeRules.record) and the glue (the AddFriends hook, approve_friend, redeem_code
// with "hashes") against the fake Nakama.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const FA = S.FriendApprovals;
const C = S.CodeRules;
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash
const DAY = 24 * 60 * 60 * 1000;

const TEEN = A.defaults("13_plus");
const KID_OK = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const KID_NO = A.defaults("under_13");

let nk: FakeNakama;
let log: FakeLogger;
let now = 5_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 5_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function edge(a: string, b: string): number | undefined {
  return nk.edges.get(a)?.get(b);
}

function refusedWith(code: string): (e: any) => boolean {
  return (e: any) => e.message === code;
}

// --- The pure rules ---

test("FriendApprovals: only under-13 accounts (and accounts with no band) need a grown-up's yes", () => {
  assert.equal(FA.needsApproval(A.fromMetadata(KID_OK)), true);
  assert.equal(FA.needsApproval(A.fromMetadata({})), true, "no band reads as under_13");
  assert.equal(FA.needsApproval(A.fromMetadata(TEEN)), false);
});

test("FriendApprovals: a list keeps one request per player, the newest, at most MAX, for KEEP_MS", () => {
  let list = FA.emptyList();
  list = FA.add(list, { user_id: "u1", username: "Ann", direction: "out" }, 1000);
  list = FA.add(list, { user_id: "u2", username: "Bob", direction: "in" }, 2000);
  list = FA.add(list, { user_id: "u1", username: "Ann", direction: "in" }, 3000);
  assert.deepEqual(list.requests.map((r: any) => [r.user_id, r.direction, r.at_ms]), [["u2", "in", 2000], ["u1", "in", 3000]]);
  for (let i = 0; i < FA.MAX + 5; i++) {
    list = FA.add(list, { user_id: "x" + i, username: "X" + i, direction: "out" }, 4000 + i);
  }
  assert.equal(list.requests.length, FA.MAX, "the oldest go first");
  assert.equal(list.requests[list.requests.length - 1].user_id, "x" + (FA.MAX + 4));
  assert.deepEqual(FA.live(FA.add(FA.emptyList(), { user_id: "u1", username: "Ann", direction: "out" }, 0), FA.KEEP_MS).requests, [],
    "a request nobody answered for KEEP_MS goes away");
  assert.deepEqual(FA.remove(FA.add(FA.emptyList(), { user_id: "u1", username: "Ann", direction: "out" }, 0), "u1").requests, []);
});

test("FriendApprovals: a stored list is read safely (broken entries dropped)", () => {
  const list = FA.listFrom({ requests: [
    { user_id: "u1", username: "Ann", direction: "in", at_ms: 5 },
    { user_id: "", username: "Nobody", direction: "in", at_ms: 5 },
    { user_id: "u2", username: "Bob", direction: "sideways", at_ms: 5 },
    { user_id: "u3", username: 7, direction: "out", at_ms: 5 },
    "junk",
  ] });
  assert.deepEqual(list.requests, [{ user_id: "u1", username: "Ann", direction: "in", at_ms: 5 }]);
  assert.deepEqual(FA.listFrom(undefined).requests, []);
  assert.deepEqual(FA.listFrom({ requests: "no" }).requests, []);
});

test("CodeRules.record: known hashes a game redeemed offline are added once, unknown ones ignored, nothing paid", () => {
  const h = C.hashCode(FIRST_CODE, nk.sha256Hash.bind(nk));
  const r = C.record({ redeemed: [], tries: C.emptyTries() }, [h, h, "f".repeat(64), "not a hash", 5]);
  assert.deepEqual(r.redeemed, [h]);
  assert.equal(r.recorded, 1);
  assert.equal(r.already, 0);
  const again = C.record({ redeemed: [h], tries: C.emptyTries() }, [h]);
  assert.equal(again.recorded, 0);
  assert.equal(again.already, 1);
});

// --- The AddFriends hook: an under-13 player's request waits for a grown-up ---

test("AddFriends: an under-13 player's request is kept for a grown-up and refused with needs_grown_up", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { usernames: ["pal_1"] }),
    (e: any) => e.message === "needs_grown_up" && e.code === 7);
  assert.equal(edge(kid, pal), undefined, "nothing reached Nakama's friends");
  const r = call("rpcApproveFriend", kid);
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.deepEqual(r.requests, [{ user_id: pal, username: "Pal_1", direction: "out", at_ms: now }]);
  const stored = nk.object("parent", "friend_requests", kid)!;
  assert.equal(stored.permissionWrite, 0, "only the server writes it");
});

test("AddFriends: accepting a request that came in also waits (direction in); a 13+ player adds as before", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  nk.befriend(pal, kid, 1); // Pal asked Kiddo: Pal's edge 1, Kiddo's edge 2
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { ids: [pal] }), refusedWith("needs_grown_up"));
  assert.equal(call("rpcApproveFriend", kid).requests[0].direction, "in");
  const teen = nk.addUser("Teeny", TEEN);
  const out = S.beforeAddFriends(ctx(teen), log, nk, { usernames: ["Pal_1"] });
  assert.deepEqual(out.ids, [pal], "13+ players need nobody's yes");
});

test("AddFriends: the older rules still come first (not online, not found), and friends already made pass", () => {
  const kidNo = nk.addUser("Kiddo", KID_NO);
  nk.addUser("Pal_1", TEEN);
  assert.throws(() => S.beforeAddFriends(ctx(kidNo), log, nk, { usernames: ["Pal_1"] }), refusedWith("not_allowed_online"));
  const kid = nk.addUser("Kiddo_2", KID_OK);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { usernames: ["Ghost"] }), refusedWith("not_found"));
  const friend = nk.addUser("Old_Pal", TEEN);
  nk.befriend(kid, friend);
  const out = S.beforeAddFriends(ctx(kid), log, nk, { ids: [friend] });
  assert.deepEqual(out.ids, [friend], "already friends: nothing to approve");
  assert.deepEqual(call("rpcApproveFriend", kid).requests, []);
});

// --- approve_friend ---

test("approve_friend: yes to a request the child sent sends it on (the friend sees a request)", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { usernames: ["Pal_1"] }));
  now += 1000;
  const r = call("rpcApproveFriend", kid, { user_id: pal, approve: true });
  assert.deepEqual(r, { ok: true, requests: [], friend: { user_id: pal, username: "Pal_1", state: "asked" } });
  assert.equal(edge(kid, pal), 1, "Kiddo asked");
  assert.equal(edge(pal, kid), 2, "Pal sees a request");
  const note = nk.notifications.find((n) => n.userId === kid && n.code === 103);
  assert.deepEqual(note?.content, { what: "friend", user_id: pal });
  assert.equal(note?.persistent, true, "the child's game hears it even after a reconnect");
});

test("approve_friend: yes to a request that came in makes them friends", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  nk.befriend(pal, kid, 1);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { ids: [pal] }));
  const r = call("rpcApproveFriend", kid, { user_id: pal, approve: true });
  assert.equal(r.friend.state, "friend");
  assert.equal(edge(kid, pal), 0);
  assert.equal(edge(pal, kid), 0);
});

test("approve_friend: no forgets it, and removes a request that came in", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  const other = nk.addUser("Other_1", TEEN);
  nk.befriend(pal, kid, 1);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { ids: [pal] }));
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { ids: [other] }));
  const r = call("rpcApproveFriend", kid, { user_id: pal, approve: false });
  assert.deepEqual(r.requests.map((x: any) => x.user_id), [other]);
  assert.equal(edge(kid, pal), undefined, "Pal's request is gone from the child's list");
  assert.equal(edge(pal, kid), undefined);
  call("rpcApproveFriend", kid, { user_id: other, approve: false });
  assert.equal(edge(other, kid), undefined, "a request the child only wanted to send never reached Other");
  assert.deepEqual(call("rpcApproveFriend", kid).requests, []);
});

test("approve_friend: refusals (unknown request, bad payload, no consent, the friend can't be online, 13+)", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  const pal = nk.addUser("Pal_1", TEEN);
  assert.deepEqual(call("rpcApproveFriend", kid, { user_id: pal, approve: true }), { ok: false, error: "not_found" });
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { ids: [pal] }));
  assert.deepEqual(call("rpcApproveFriend", kid, { user_id: pal, approve: "yes" }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcApproveFriend", kid, { user_id: 5 }), { ok: false, error: "bad_request" });
  // The grown-up turned online play off meanwhile: nothing can be approved, the request stays.
  nk.users.get(kid)!.metadata = { ...KID_OK, online_allowed: false };
  assert.deepEqual(call("rpcApproveFriend", kid, { user_id: pal, approve: true }), { ok: false, error: "consent_needed" });
  assert.equal(call("rpcApproveFriend", kid).requests.length, 1);
  nk.users.get(kid)!.metadata = { ...KID_OK };
  // The friend can't be online any more: approving says so and drops the request.
  nk.users.get(pal)!.metadata = { ...KID_NO };
  const gone = call("rpcApproveFriend", kid, { user_id: pal, approve: true });
  assert.deepEqual(gone, { ok: false, error: "not_found", requests: [] });
  const teen = nk.addUser("Teeny", TEEN);
  assert.deepEqual(call("rpcApproveFriend", teen), { ok: true, requests: [] }, "13+: nothing waits");
  assert.equal(call("rpcApproveFriend", kid, "not json").error, "bad_request");
});

test("approve_friend: old requests run out", () => {
  const kid = nk.addUser("Kiddo", KID_OK);
  nk.addUser("Pal_1", TEEN);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { usernames: ["Pal_1"] }));
  now += FA.KEEP_MS + DAY;
  assert.deepEqual(call("rpcApproveFriend", kid).requests, []);
});

// --- redeem_code {"hashes"}: codes used offline ---

test("redeem_code with hashes records codes used offline without paying; the code can't pay again online", () => {
  const me = nk.addUser("Me_1", TEEN, { survivor_gold: 25 });
  const h = C.hashCode(FIRST_CODE, nk.sha256Hash.bind(nk));
  const r = call("rpcRedeemCode", me, { hashes: [h, "0".repeat(64)] });
  assert.deepEqual(r, { ok: true, status: "recorded", recorded: 1, already: 0, gold: 25, paid: [] });
  assert.equal(nk.users.get(me)!.wallet.survivor_gold, 25, "paid on the phone already: nothing more");
  assert.equal(nk.ledger.length, 0);
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }), { ok: false, error: "already_used" });
  assert.deepEqual(call("rpcRedeemCode", me, { hashes: [h] }), { ok: true, status: "recorded", recorded: 0, already: 1, gold: 25, paid: [] });
});

test("redeem_code with hashes: bad payloads, and never a wrong-code lock", () => {
  const me = nk.addUser("Me_1", TEEN);
  assert.deepEqual(call("rpcRedeemCode", me, { hashes: "abc" }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcRedeemCode", me, { hashes: new Array(C.MAX_RECORD + 1).fill("0".repeat(64)) }),
    { ok: false, error: "bad_request" });
  for (let i = 0; i < 6; i++) {
    call("rpcRedeemCode", me, { hashes: ["1".repeat(64)] });
  }
  assert.equal(call("rpcRedeemCode", me, { code: FIRST_CODE }).status, "accepted", "unknown hashes are not wrong guesses");
});
