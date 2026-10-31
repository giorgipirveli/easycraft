// remove_guest (spec §17.3 "Safety in the world", the M4 Task 10 review's finding A): the host of a relayed match
// takes a guest out of it and off its invite list, and the guest's game is told why. Only the match's host may.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;

let nk: FakeNakama;
let log: FakeLogger;
let now = 2_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 2_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, JSON.stringify(payload)));
}

const TEEN = A.defaults("13_plus");

// A host with two invited friends in its relayed match.
function hostWithGuests(): { host: string; guest: string; other: string; match: string } {
  const host = nk.addUser("Hostie", TEEN);
  const guest = nk.addUser("Guesty", TEEN);
  const other = nk.addUser("Otter", TEEN);
  nk.befriend(host, guest);
  nk.befriend(host, other);
  const match = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: match, self: { userId: host } } }, { matchCreate: {} });
  for (const who of [guest, other]) {
    const r = call("rpcInviteFriend", host, { user_id: who, match_id: match });
    assert.equal(r.ok, true, JSON.stringify(r));
    S.rtBeforeMatchJoin(ctx(who), log, nk, { cid: "1", matchJoin: { matchId: match, metadata: {} } });
    nk.joinMatch(match, who);
  }
  return { host, guest, other, match };
}

function joinHook(userId: string, match: string): any {
  return S.rtBeforeMatchJoin(ctx(userId), log, nk, { cid: "1", matchJoin: { matchId: match, metadata: {} } });
}

test("the host removes a guest: kicked off the match, off the invite list, told why", () => {
  const { host, guest, other, match } = hostWithGuests();
  const r = call("rpcRemoveGuest", host, { user_id: guest, match_id: match });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.in_match, true);
  assert.deepEqual(nk.kicks.map((k) => k.userId), [guest], "only that guest");
  assert.equal(nk.kicks[0].stream.mode, 5, "the relayed match's stream");
  const present = S.Social.matchUserIds(nk, match.split(".")[0]);
  assert.ok(present.indexOf(guest) < 0 && present.indexOf(other) >= 0 && present.indexOf(host) >= 0);
  const rec = nk.object("invites", "current", host)!;
  assert.equal(rec.value.invited[guest], undefined, "off the invite list");
  assert.ok(rec.value.invited[other] > now, "the other guest stays invited");
  const note = nk.notifications.find((n) => n.userId === guest && n.code === S.Notes.REMOVED);
  assert.ok(note, "the guest's game is told");
  assert.equal(note!.content.match_id, match);
  assert.equal(nk.notifications.filter((n) => n.code === S.Notes.REMOVED).length, 1, "only the removed guest");
});

test("a removed guest can't come back, even within the rejoin window", () => {
  const { host, guest, match } = hostWithGuests();
  call("rpcRemoveGuest", host, { user_id: guest, match_id: match });
  now += 1000;
  assert.throws(() => joinHook(guest, match), (e: any) => e.message === "not_invited");
});

test("only the match's host may remove anyone", () => {
  const { guest, other, match } = hostWithGuests();
  const r = call("rpcRemoveGuest", guest, { user_id: other, match_id: match });
  assert.equal(r.ok, false);
  assert.equal(r.error, "not_host");
  assert.equal(nk.kicks.length, 0);
});

test("a guest who already left is still taken off the invite list", () => {
  const { host, guest, match } = hostWithGuests();
  nk.leaveMatch(match, guest);
  const r = call("rpcRemoveGuest", host, { user_id: guest, match_id: match });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.in_match, false);
  assert.equal(nk.object("invites", "current", host)!.value.invited[guest], undefined);
  assert.throws(() => joinHook(guest, match), (e: any) => e.message === "not_invited");
});

test("removing yourself or a junk id is a bad request", () => {
  const { host, match } = hostWithGuests();
  assert.equal(call("rpcRemoveGuest", host, { user_id: host, match_id: match }).error, "bad_request");
  assert.equal(call("rpcRemoveGuest", host, { user_id: "nobody", match_id: match }).error, "bad_request");
  assert.equal(call("rpcRemoveGuest", host, { user_id: nk.addUser("X", TEEN), match_id: "junk" }).error, "bad_request");
});

test("InviteRules.remove strikes one player and keeps the rest", () => {
  const h = S.InviteRules.newHosting("m.", "host", 5);
  h.invited = { a: 100, b: 200 };
  const out = S.InviteRules.remove(h, "a");
  assert.deepEqual(out.invited, { b: 200 });
  assert.deepEqual(h.invited, { a: 100, b: 200 }, "a copy");
});
