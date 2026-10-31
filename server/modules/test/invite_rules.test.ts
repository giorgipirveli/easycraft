// Invites and who may join a relayed match (spec §17.0, §17.3; plan M4 Wave 1): a host invites
// friends who may play online, at most 4 players; the MatchJoin hook lets in only the invited
// (and the host coming back), never a 5th player.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const I = S.InviteRules;
const A = S.AccountRules;

const MATCH = "2d675801-2c15-4378-b88e-0bc7d0606b77.";
const OTHER_MATCH = "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d.";
const TEEN = A.fromMetadata(A.defaults("13_plus"));
const KID_OK = A.fromMetadata({ ...A.defaults("under_13"), consent: "verified", online_allowed: true });
const KID_NO = A.fromMetadata(A.defaults("under_13"));
const UNCLAIMED = A.fromMetadata({});
const NOW = 1_000_000;

function invite(over: object = {}): any {
  return I.invite({
    matchId: MATCH, callerId: "host", targetId: "friend", caller: TEEN, target: KID_OK, isFriend: true,
    presentIds: ["host"], records: { host: I.newHosting(MATCH, "host", NOW - 5) }, now: NOW, ...over,
  });
}

test("match ids: only relayed ones (\"<uuid>.\"), lower case", () => {
  assert.equal(I.matchSubject(MATCH), "2d675801-2c15-4378-b88e-0bc7d0606b77");
  assert.equal(I.matchSubject(MATCH.toUpperCase()), "2d675801-2c15-4378-b88e-0bc7d0606b77");
  for (const bad of ["", "abc", MATCH + "node", MATCH.slice(0, -1), 5, null, " " + MATCH]) {
    assert.equal(I.matchSubject(bad), null, String(bad));
  }
});

test("a host invites a friend who may play online: the invite lasts an hour", () => {
  const r = invite();
  assert.equal(r.error, undefined);
  assert.equal(r.hosting.match_id, MATCH);
  assert.equal(r.hosting.host_id, "host");
  assert.equal(r.hosting.invited.friend, NOW + I.INVITE_TTL_MS);
  assert.deepEqual(r.hosting.sent, [NOW]);
});

test("invite: who may and who may not", () => {
  assert.equal(invite({ caller: KID_NO }).error, "not_allowed_online");
  assert.equal(invite({ caller: UNCLAIMED }).error, "not_allowed_online");
  assert.equal(invite({ target: null }).error, "not_found");
  assert.equal(invite({ targetId: "host" }).error, "cannot_invite_self");
  assert.equal(invite({ isFriend: false }).error, "not_friends");
  assert.equal(invite({ target: KID_NO }).error, "friend_cannot_join");
  assert.equal(invite({ presentIds: ["someone"] }).error, "not_in_match");
});

test("invite: only the host; a player without a record becomes the host of a match nobody hosts", () => {
  const guestRecords = { host: I.newHosting(MATCH, "host", NOW) };
  assert.equal(invite({ callerId: "guest", presentIds: ["host", "guest"], records: guestRecords }).error, "not_host");
  const fresh = invite({ records: {} });
  assert.equal(fresh.error, undefined, "the after-create hook's record may not be there yet");
  assert.equal(fresh.hosting.host_id, "host");
  const moved = invite({ records: { host: { ...I.newHosting(OTHER_MATCH, "host", 0), invited: { old: NOW + 99 } } } });
  assert.equal(moved.hosting.match_id, MATCH, "a new match replaces the old one's invites");
  assert.equal(moved.hosting.invited.old, undefined);
});

test("invite: a full match (4 players) and too many invites are refused", () => {
  assert.equal(invite({ presentIds: ["host", "a", "b", "c"] }).error, "match_full");
  assert.equal(invite({ presentIds: ["host", "a", "b"] }).error, undefined, "3 players: one more may come");
  const busy = I.newHosting(MATCH, "host", 0);
  busy.sent = Array.from({ length: I.RATE_COUNT }, (_: unknown, i: number) => NOW - i);
  assert.equal(invite({ records: { host: busy } }).error, "too_fast");
  busy.sent = Array.from({ length: I.RATE_COUNT }, () => NOW - I.RATE_WINDOW_MS);
  const later = invite({ records: { host: busy } });
  assert.equal(later.error, undefined, "old invites left the window");
  assert.deepEqual(later.hosting.sent, [NOW]);
});

test("invite: expired invites are dropped from the record", () => {
  const h = I.newHosting(MATCH, "host", 0);
  h.invited = { gone: NOW - 1, still: NOW + 10 };
  const r = invite({ records: { host: h } });
  assert.deepEqual(Object.keys(r.hosting.invited).sort(), ["friend", "still"]);
});

function join(over: object = {}): any {
  const hosting = I.newHosting(MATCH, "host", 0);
  hosting.invited = { friend: NOW + 1000 };
  return I.join({ matchId: MATCH, userId: "friend", joiner: KID_OK, presentIds: ["host"], records: { host: hosting },
    devOpen: false, now: NOW, ...over });
}

test("join: the invited friend comes in and may come back for a day", () => {
  const r = join();
  assert.equal(r.error, undefined);
  assert.equal(r.renew.ownerId, "host");
  assert.equal(r.renew.hosting.invited.friend, NOW + I.REJOIN_MS);
});

test("join: the uninvited, the expired and a 5th player are refused", () => {
  assert.equal(join({ userId: "stranger", joiner: TEEN }).error, "not_invited");
  assert.equal(join({ now: NOW + 1000 }).error, "not_invited", "the invite ran out");
  assert.equal(join({ records: {} }).error, "not_invited", "nobody hosts it here");
  assert.equal(join({ presentIds: ["host", "a", "b", "c"] }).error, "match_full");
  assert.equal(join({ presentIds: ["host", "a", "b"] }).error, undefined, "the 4th is fine");
});

test("join: an invited child whose parent switched online off is refused", () => {
  assert.equal(join({ joiner: KID_NO }).error, "not_allowed_online");
});

test("join: someone already in the match, and the host coming back, get in", () => {
  assert.equal(join({ userId: "a", joiner: TEEN, presentIds: ["host", "a"] }).error, undefined);
  const hosting = I.newHosting(MATCH, "host", 0);
  assert.equal(I.join({ matchId: MATCH, userId: "host", joiner: TEEN, presentIds: ["friend"],
    records: { host: hosting }, devOpen: false, now: NOW }).error, undefined);
});

test("join: a match with nobody in it is left to Nakama (it answers 'not found')", () => {
  assert.equal(join({ userId: "stranger", joiner: TEEN, presentIds: [] }).error, undefined);
});

test("join: a developer server lets unclaimed developer accounts in by match id, nobody else", () => {
  assert.equal(join({ userId: "dev", joiner: UNCLAIMED, devOpen: true }).error, undefined);
  assert.equal(join({ userId: "dev", joiner: UNCLAIMED, devOpen: false }).error, "not_invited");
  assert.equal(join({ userId: "stranger", joiner: TEEN, devOpen: true }).error, "not_invited",
    "a claimed account needs an invite even on a developer server");
  assert.equal(join({ userId: "dev", joiner: UNCLAIMED, devOpen: true, presentIds: ["host", "a", "b", "c"] }).error,
    "match_full");
});

test("hosting records read from storage are sanitised", () => {
  assert.equal(I.hostingFrom(undefined), null);
  assert.equal(I.hostingFrom({ match_id: "x", host_id: "h" }), null);
  const h = I.hostingFrom({ match_id: MATCH, host_id: "h", created_ms: 5, invited: { a: 10, b: "x" }, sent: [1, "y", 2] });
  assert.deepEqual(h, { match_id: MATCH, host_id: "h", created_ms: 5, invited: { a: 10 }, sent: [1, 2] });
});

test("world names: cleaned, at most 32 characters, filtered like chat", () => {
  assert.deepEqual(I.worldName("  My   Castle "), { name: "My Castle" });
  assert.deepEqual(I.worldName(undefined), { name: "" });
  assert.equal(I.worldName("x".repeat(50)).name.length, 32);
  assert.deepEqual(I.worldName("call me 555 123 4567"), { error: "bad_world_name" });
  assert.deepEqual(I.worldName("stupid land"), { error: "bad_world_name" });
  assert.deepEqual(I.worldName(42), { error: "bad_request" });
});
