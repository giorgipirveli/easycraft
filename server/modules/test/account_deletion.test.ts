// M4 Task 8b, agent G (spec §5.14, §17.2; Google Play's account-deletion rule, COPPA parents' rights):
// delete_account deletes a player's online account and everything of it on the server, in two calls
// (the first only hands out a confirmation, so one stray tap can't do it). Reports the player MADE
// stay without their name (they protect others); reports ABOUT the player stay for the reviewer.
// The owner runs the same RPC for a parent's e-mail (no session: the server's HTTP key or the
// console's API Explorer, naming the account).
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const D = S.DeletionRules;
const TEEN = A.defaults("13_plus");
const KID_OK = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const MINUTE = 60 * 1000;
const COLLECTIONS = ["profiles", "parent", "codes", "farm", "invites", "limits", "activity"];

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
  return JSON.parse(S[fn](ctx(userId), log, nk, JSON.stringify(payload)));
}

function admin(payload: unknown): any {
  return JSON.parse(S.rpcDeleteAccount(ctx(""), log, nk, JSON.stringify(payload)));
}

function put(userId: string, collection: string, key: string, value: object): void {
  nk.storageWrite([{ collection, key, userId, value, permissionRead: 0, permissionWrite: 0 }]);
}

function objectsOf(userId: string): string[] {
  return [...nk.storage.values()].filter((o) => o.userId === userId).map((o) => o.collection + "/" + o.key).sort();
}

function reports(): any[] {
  return [...nk.storage.values()].filter((o) => o.collection === "reports");
}

// A player with something in every place the server keeps things, and players around them.
function world(): any {
  const me = nk.addUser("Me_1", TEEN, { survivor_gold: 40 });
  const pal = nk.addUser("Pal_1", TEEN);
  const kid = nk.addUser("Kiddo", KID_OK);
  const bad = nk.addUser("Meanie", TEEN);
  nk.befriend(me, pal, 0);
  put(me, "profiles", "profile", { survivor_gold: 40 });
  put(me, "parent", "settings", { online_allowed: true });
  put(me, "codes", "redeemed", { hashes: ["abc"] });
  put(me, "farm", "slot_1", { rate_per_hour: 10 });
  put(me, "invites", "current", { match_id: "x.", host_id: me });
  put(me, "limits", "report", { times: [] });
  put(me, "activity", "signed_in", { at_ms: now });
  put(pal, "profiles", "profile", { survivor_gold: 7 });
  put(kid, "parent", "friend_requests", { requests: [
    { user_id: me, username: "Me_1", direction: "out", at_ms: now },
    { user_id: pal, username: "Pal_1", direction: "in", at_ms: now },
  ] });
  nk.walletUpdate(me, { survivor_gold: 5 }, { source: "award" }, true);
  nk.notificationSend(pal, "Me_1 invites you to play!", { from_username: "Me_1" }, 101, me, true);
  nk.notificationSend(pal, "A grown-up said yes!", { what: "consent" }, 103, null, true);
  nk.notificationSend(me, "Pal_1 invites you to play!", { from_username: "Pal_1" }, 101, pal, true);
  const dm = nk.channelIdBuild(me, pal, 2);
  nk.addChannelMessage(dm, me, "Me_1", now / 1000 - 60);
  nk.addChannelMessage(dm, pal, "Pal_1", now / 1000 - 30);
  const other = nk.channelIdBuild(pal, bad, 2);
  nk.addChannelMessage(other, bad, "Meanie", now / 1000 - 30);
  assert.equal(call("rpcReportUser", me, { user_id: bad, reason: "mean_words" }).ok, true);
  assert.equal(call("rpcReportUser", bad, { user_id: me, reason: "bad_name" }).ok, true);
  return { me, pal, kid, bad, dm, other };
}

// --- The pure rules ---

test("DeletionRules: a confirmation lasts 10 minutes and must be the one handed out", () => {
  const c = D.newConfirm("tok-1", now);
  assert.deepEqual(c, { token: "tok-1", expires_ms: now + D.CONFIRM_MS });
  assert.equal(D.CONFIRM_MS, 10 * MINUTE);
  assert.equal(D.check(c, "tok-1", now + D.CONFIRM_MS - 1), "");
  assert.equal(D.check(c, "tok-1", now + D.CONFIRM_MS), "confirm_expired");
  assert.equal(D.check(c, "tok-2", now), "confirm_wrong");
  assert.equal(D.check(c, undefined, now), "confirm_wrong");
  assert.equal(D.check(null, "tok-1", now), "confirm_expired", "none handed out (or used): ask again");
  assert.deepEqual(D.confirmFrom({ token: "t", expires_ms: 5 }), { token: "t", expires_ms: 5 });
  assert.equal(D.confirmFrom({ token: 5, expires_ms: 5 }), null);
  assert.equal(D.confirmFrom(undefined), null);
});

test("DeletionRules: a report made by a deleted player keeps what was reported, without who reported it", () => {
  const report = { reporter_id: "u1", reporter_username: "Me_1", reported_id: "u2", reported_username: "Meanie",
    reason: "mean_words", created_ms: 5, status: "new", message: { text: "go away", at_ms: 4, source: "server" } };
  const anon = D.anonymised(report, now);
  assert.equal(anon.reporter_id, "");
  assert.equal(anon.reporter_username, "");
  assert.equal(anon.reporter_deleted_ms, now);
  assert.equal(anon.reported_id, "u2");
  assert.deepEqual(anon.message, report.message, "the reported message stays for the reviewer");
  assert.equal(report.reporter_id, "u1", "a copy");
  assert.equal(D.madeBy(report, "u1"), true);
  assert.equal(D.madeBy(anon, "u1"), false);
  assert.equal(D.madeBy(anon, ""), false, "an anonymised report is nobody's");
  assert.match(D.anonymousKey(5, "0123abcd-0000-4000-8000-000000000000"), /^5_deleted_[0-9a-f]{12}$/);
});

// --- delete_account ---

test("delete_account: the first call only hands out a confirmation; nothing is deleted", () => {
  const w = world();
  const before = objectsOf(w.me);
  const r = call("rpcDeleteAccount", w.me, {});
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(typeof r.confirm, "string");
  assert.ok(r.confirm.length >= 16);
  assert.equal(r.expires_ms, now + D.CONFIRM_MS);
  assert.equal(r.username, "Me_1");
  assert.equal(r.user_id, w.me);
  assert.equal(nk.users.has(w.me), true);
  assert.deepEqual(objectsOf(w.me), [...before, "limits/delete_account"].sort(), "only the confirmation is kept");
  assert.equal(nk.object("limits", "delete_account", w.me)!.permissionRead, 0, "the game can't read it");
});

test("delete_account: a wrong or late confirmation deletes nothing", () => {
  const w = world();
  const first = call("rpcDeleteAccount", w.me, {});
  assert.deepEqual(call("rpcDeleteAccount", w.me, { confirm: "not-it" }), { ok: false, error: "confirm_wrong" });
  now += D.CONFIRM_MS;
  assert.deepEqual(call("rpcDeleteAccount", w.me, { confirm: first.confirm }), { ok: false, error: "confirm_expired" });
  assert.equal(nk.users.has(w.me), true);
  assert.deepEqual(nk.deleted, []);
  const again = call("rpcDeleteAccount", w.me, {});
  assert.notEqual(again.confirm, first.confirm, "a new confirmation each time");
  assert.equal(call("rpcDeleteAccount", w.me, { confirm: again.confirm }).ok, true);
});

test("delete_account: every storage object in every collection, friends, held requests, notifications and DMs go, then Nakama's own deletion (recorded)", () => {
  const w = world();
  nk.cascade = false; // prove the module removes these itself, not only the database's cascade
  const c = call("rpcDeleteAccount", w.me, {});
  const r = call("rpcDeleteAccount", w.me, { confirm: c.confirm });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.deleted, true);
  assert.deepEqual(nk.deleted, [{ userId: w.me, recorded: true }], "Nakama's deletion, recorded");
  assert.equal(nk.users.has(w.me), false);
  assert.deepEqual(objectsOf(w.me), [], "profiles, parent, codes, farm, invites, limits, activity: all gone");
  for (const collection of COLLECTIONS) {
    assert.equal([...nk.storage.values()].some((o) => o.userId === w.me && o.collection === collection), false, collection);
  }
  assert.equal(nk.edges.get(w.pal)?.has(w.me), false, "gone from friends' lists");
  assert.deepEqual(nk.object("parent", "friend_requests", w.kid)!.value.requests.map((q: any) => q.user_id), [w.pal],
    "gone from a child's requests waiting for a grown-up (name and id)");
  assert.equal(nk.notifications.some((n) => n.senderId === w.me), false, "invites the player sent");
  assert.equal(nk.notifications.filter((n) => n.userId === w.pal).length, 1, "the friend's other notes stay");
  assert.deepEqual(nk.channelMessages.get(w.dm), [], "the DM with the player, both sides (nobody can open it now)");
  assert.equal(nk.channelMessages.get(w.other)!.length, 1, "other players' DMs stay");
  assert.deepEqual(objectsOf(w.pal), ["profiles/profile"], "other players' things stay");
  assert.equal(r.objects, 8, "seven collections and the confirmation");
  assert.ok(log.lines.some((l) => l.startsWith("INFO account deleted: " + w.me)), log.lines.join("\n"));
  assert.equal(log.lines.some((l) => l.includes("Me_1")), false, "no username in the server's log");
});

test("delete_account: with the database's cascade (a real server) the wallet ledger goes too", () => {
  const w = world();
  const c = call("rpcDeleteAccount", w.me, {});
  assert.equal(call("rpcDeleteAccount", w.me, { confirm: c.confirm }).ok, true);
  assert.equal(nk.ledger.some((e) => e.userId === w.me), false);
  assert.equal(nk.notifications.some((n) => n.userId === w.me), false);
});

test("delete_account: reports made by the player stay without their name; reports about them stay for the reviewer", () => {
  const w = world();
  const c = call("rpcDeleteAccount", w.me, {});
  assert.equal(call("rpcDeleteAccount", w.me, { confirm: c.confirm }).ok, true);
  const all = reports();
  assert.equal(all.length, 2);
  const made = all.find((o) => o.value.reported_id === w.bad)!;
  assert.equal(made.userId, SYSTEM_USER);
  assert.equal(made.value.reporter_id, "");
  assert.equal(made.value.reporter_username, "");
  assert.equal(made.value.reason, "mean_words");
  assert.equal(made.key.includes(w.me), false, "the key named the reporter: it is a new key now");
  assert.equal(made.permissionRead, 0);
  const about = all.find((o) => o.value.reported_id === w.me)!;
  assert.equal(about.value.reported_username, "Me_1", "the reviewer still sees who was reported");
  assert.equal(about.value.reporter_id, w.bad);
});

test("delete_account: the owner deletes an account by name without a session (the HTTP key or the console), in the same two steps", () => {
  const w = world();
  assert.deepEqual(admin({}), { ok: false, error: "bad_request" }, "which account?");
  assert.deepEqual(admin({ username: "Nobody" }), { ok: false, error: "not_found" });
  const c = admin({ username: "me_1" });
  assert.equal(c.ok, true, JSON.stringify(c));
  assert.equal(c.user_id, w.me, "the owner sees the id and name before deleting");
  assert.equal(c.username, "Me_1");
  assert.equal(nk.users.has(w.me), true);
  assert.deepEqual(admin({ username: "Me_1", confirm: "nope" }), { ok: false, error: "confirm_wrong" });
  const r = admin({ user_id: w.me, confirm: c.confirm });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(nk.users.has(w.me), false);
});

test("delete_account: a signed-in player can only delete their own account", () => {
  const w = world();
  assert.deepEqual(call("rpcDeleteAccount", w.me, { user_id: w.pal }), { ok: false, error: "not_allowed" });
  assert.deepEqual(call("rpcDeleteAccount", w.me, { username: "Pal_1" }), { ok: false, error: "not_allowed" });
  const own = call("rpcDeleteAccount", w.me, { username: "Me_1" });
  assert.equal(own.ok, true, "naming oneself is fine");
  assert.equal(nk.users.has(w.pal), true);
});

test("Nakama's own account deletion from a game is refused: only delete_account cleans everything", () => {
  const w = world();
  assert.throws(() => S.beforeDeleteAccount(ctx(w.me), log, nk), (e: any) => e.message === "use_delete_account");
});
