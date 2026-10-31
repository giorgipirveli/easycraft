// The account RPCs and hooks against the fake Nakama: claim_username, get_account_state,
// set_parent_settings, consent_start, consent_status (plan M4 Wave 1, spec §17.1-17.2), and the
// username filter on Nakama's own account update and sign-in (a modified game can't skip it).
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const FAKE_ENV = { EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "2000" };

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}, env: object = {}): any {
  const text = typeof payload === "string" ? payload : JSON.stringify(payload);
  return JSON.parse(S[fn](ctx(userId, env), log, nk, text));
}

let kids = 0;

function claimed(band: string, extra: object = {}): string {
  kids++;
  const id = nk.addUser("rnd" + kids);
  const r = call("rpcClaimUsername", id, { username: "Kid" + kids, age_band: band });
  assert.equal(r.ok, true, JSON.stringify(r));
  if (Object.keys(extra).length) {
    const meta = { ...nk.users.get(id)!.metadata, ...extra };
    nk.users.get(id)!.metadata = meta;
  }
  return id;
}

test("claim_username: the name becomes the Nakama username and the band's defaults the metadata", () => {
  const id = nk.addUser("xKqPzRandom");
  const r = call("rpcClaimUsername", id, { username: "  Hopper_7 ", age_band: "under_13" });
  assert.equal(r.ok, true);
  assert.equal(r.username, "Hopper_7");
  assert.equal(r.claimed, true);
  assert.equal(r.age_band, "under_13");
  assert.equal(r.can_play_online, false);
  assert.equal(nk.users.get(id)!.username, "Hopper_7");
  assert.deepEqual(nk.users.get(id)!.metadata, { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" });
});

test("claim_username: the filter's codes come back and nothing changes", () => {
  const id = nk.addUser("xKqPzRandom");
  for (const [name, code] of [["ab", "too_short"], ["7hopper", "must_start_with_letter"], ["iamstupid", "blocked_word"],
      ["call5551234567", "personal_info"], ["hop per", "bad_chars"], ["abcdefghijklmnopq", "too_long"]]) {
    assert.deepEqual(call("rpcClaimUsername", id, { username: name, age_band: "13_plus" }), { ok: false, error: code }, name);
  }
  assert.equal(nk.users.get(id)!.username, "xKqPzRandom");
  assert.deepEqual(nk.users.get(id)!.metadata, {});
});

test("claim_username: unique whatever the case, but my own name in another case is fine", () => {
  const a = nk.addUser("rnd1");
  const b = nk.addUser("rnd2");
  assert.equal(call("rpcClaimUsername", a, { username: "Hopper_7", age_band: "13_plus" }).ok, true);
  assert.deepEqual(call("rpcClaimUsername", b, { username: "hopper_7", age_band: "13_plus" }), { ok: false, error: "taken" });
  assert.deepEqual(call("rpcClaimUsername", b, { username: "HOPPER_7", age_band: "13_plus" }), { ok: false, error: "taken" });
  assert.equal(call("rpcClaimUsername", a, { username: "HOPPER_7" }).ok, true, "a rename to my own name");
  assert.equal(nk.users.get(a)!.username, "HOPPER_7");
});

test("claim_username: Nakama's own uniqueness answer is 'taken' too (a race the check missed)", () => {
  const a = nk.addUser("rnd1");
  nk.sqlQuery = () => [];   // the case-insensitive check sees nothing ...
  nk.addUser("Hopper_7");   // ... but Nakama refuses the exact name
  assert.deepEqual(call("rpcClaimUsername", a, { username: "Hopper_7", age_band: "13_plus" }), { ok: false, error: "taken" });
});

test("claim_username: the first claim needs a band; a later claim keeps the state and ignores one", () => {
  const id = nk.addUser("rnd");
  assert.deepEqual(call("rpcClaimUsername", id, { username: "Hopper_7" }), { ok: false, error: "bad_age_band" });
  assert.deepEqual(call("rpcClaimUsername", id, { username: "Hopper_7", age_band: "adult" }), { ok: false, error: "bad_age_band" });
  assert.equal(nk.users.get(id)!.username, "rnd", "nothing half-done");
  call("rpcClaimUsername", id, { username: "Hopper_7", age_band: "under_13" });
  const again = call("rpcClaimUsername", id, { username: "Bunny_2", age_band: "13_plus" });
  assert.equal(again.ok, true);
  assert.equal(again.age_band, "under_13", "the band changes only through the parent");
});

test("every RPC refuses a broken payload and a caller without an account", () => {
  const id = nk.addUser("rnd");
  for (const fn of ["rpcClaimUsername", "rpcGetAccountState", "rpcSetParentSettings", "rpcConsentStart", "rpcConsentStatus"]) {
    assert.deepEqual(call(fn, id, "[1,2]"), { ok: false, error: "bad_request" }, fn);
    assert.deepEqual(call(fn, id, "{nope"), { ok: false, error: "bad_request" }, fn);
    assert.deepEqual(call(fn, "", {}), { ok: false, error: "not_signed_in" }, fn);
  }
});

test("get_account_state: an unclaimed account, the wallet's gold and whether consent can be asked", () => {
  const id = nk.addUser("rnd", {}, { survivor_gold: 125 });
  const r = call("rpcGetAccountState", id);
  assert.equal(r.ok, true);
  assert.equal(r.user_id, id);
  assert.equal(r.claimed, false);
  assert.equal(r.can_play_online, false);
  assert.equal(r.chat_level, "off");
  assert.equal(r.gold, 125);
  assert.equal(r.consent_available, false);
  assert.equal(r.server_time_ms, now);
  assert.equal(call("rpcGetAccountState", id, {}, FAKE_ENV).consent_available, true);
});

test("set_parent_settings: switches stored in metadata and in the parent collection (server-written)", () => {
  const id = claimed("13_plus");
  const r = call("rpcSetParentSettings", id, { online_allowed: false, chat: "quick" });
  assert.equal(r.ok, true);
  assert.equal(r.online_allowed, false);
  assert.equal(r.chat, "quick");
  assert.equal(r.can_play_online, false);
  assert.deepEqual(nk.users.get(id)!.metadata, { age_band: "13_plus", consent: "none", online_allowed: false, chat: "quick" });
  const stored = nk.object("parent", "settings", id)!;
  assert.equal(stored.permissionRead, 1, "the game can read it");
  assert.equal(stored.permissionWrite, 0, "only the server writes it");
  assert.equal(stored.value.online_allowed, false);
  assert.equal(stored.value.chat, "quick");
  assert.equal(stored.value.updated_ms, now);
  assert.equal(stored.value.history.length, 1, "a short history the parent corner can show");
});

test("set_parent_settings: under_13 can't go online without consent or get free text", () => {
  const id = claimed("under_13");
  assert.deepEqual(call("rpcSetParentSettings", id, { online_allowed: true }), { ok: false, error: "consent_needed" });
  assert.deepEqual(call("rpcSetParentSettings", id, { age_band: "13_plus", chat: "filtered" }), { ok: false, error: "age_band_locked" },
    "a game never lifts a child to 13+ (M4 Task 10 review)");
  assert.equal(nk.users.get(id)!.metadata.age_band, "under_13");
  assert.deepEqual(call("rpcSetParentSettings", "", {}), { ok: false, error: "not_signed_in" });
  const unclaimed = nk.addUser("rnd");
  assert.deepEqual(call("rpcSetParentSettings", unclaimed, { chat: "off" }), { ok: false, error: "not_claimed" });
});

test("consent: start without a provider is unavailable; 13_plus doesn't need it", () => {
  const kid = claimed("under_13");
  assert.deepEqual(call("rpcConsentStart", kid, {}), { ok: false, error: "consent_unavailable" });
  const teen = claimed("13_plus");
  assert.deepEqual(call("rpcConsentStart", teen, {}, FAKE_ENV), { ok: false, error: "not_needed" });
});

test("consent on a production server: the fake provider is refused, and a fake request never turns verified", () => {
  const PROD_FAKE = { ...FAKE_ENV, EASYCRAFT_ENV: "production" };
  const kid = claimed("under_13");
  assert.deepEqual(call("rpcConsentStart", kid, {}, PROD_FAKE), { ok: false, error: "consent_unavailable" });
  assert.equal(call("rpcGetAccountState", kid, {}, PROD_FAKE).consent_available, false);
  assert.equal(call("rpcConsentStart", kid, {}, FAKE_ENV).consent, "pending", "a request from a development server ...");
  now += 60_000;
  const r = call("rpcConsentStatus", kid, {}, PROD_FAKE);
  assert.equal(r.consent, "pending", "... is never approved by the fake on a production server");
  assert.equal(r.can_play_online, false);
  assert.equal(nk.notifications.length, 0);
});

test("consent: the fake flow, pending then verified, with notification 103 and online play", () => {
  const kid = claimed("under_13");
  const started = call("rpcConsentStart", kid, { parent_contact: "mum@example.com" }, FAKE_ENV);
  assert.equal(started.ok, true);
  assert.equal(started.consent, "pending");
  assert.equal(nk.users.get(kid)!.metadata.consent, "pending");
  const record = nk.object("parent", "consent", kid)!;
  assert.equal(record.permissionWrite, 0);
  assert.ok(!JSON.stringify(record.value).includes("example.com"), "the parent's contact is never stored");

  now += 1_000;
  const early = call("rpcConsentStatus", kid, {}, FAKE_ENV);
  assert.equal(early.consent, "pending");
  assert.equal(nk.notifications.length, 0);

  now += 1_000;
  const done = call("rpcConsentStatus", kid, {}, FAKE_ENV);
  assert.equal(done.ok, true);
  assert.equal(done.consent, "verified");
  assert.equal(done.can_play_online, true);
  assert.equal(done.chat_level, "quick");
  assert.deepEqual(nk.users.get(kid)!.metadata, { age_band: "under_13", consent: "verified", online_allowed: true, chat: "quick" });
  assert.equal(nk.notifications.length, 1);
  const note = nk.notifications[0];
  assert.equal(note.code, 103);
  assert.equal(note.userId, kid);
  assert.deepEqual(note.content, { what: "consent" });
  assert.equal(note.persistent, true);

  call("rpcConsentStatus", kid, {}, FAKE_ENV);
  assert.equal(nk.notifications.length, 1, "told once");
});

test("consent: a parent's no leaves the child offline", () => {
  const kid = claimed("under_13");
  call("rpcConsentStart", kid, { fake_answer: "deny" }, FAKE_ENV);
  now += 5_000;
  const r = call("rpcConsentStatus", kid, {}, FAKE_ENV);
  assert.equal(r.consent, "none");
  assert.equal(r.consent_request, "denied");
  assert.equal(r.can_play_online, false);
  assert.equal(nk.notifications.length, 0);
});

test("hook: Nakama's account update runs the username filter and the case-insensitive check", () => {
  const a = claimed("13_plus");
  const b = nk.addUser("rnd");
  nk.accountUpdateId(a, "Hopper_7");
  const hook = (userId: string, data: object) => S.beforeUpdateAccount(ctx(userId), log, nk, data);
  assert.throws(() => hook(b, { username: "iamstupid" }), (e: any) => e.message === "blocked_word" && e.code === 3);
  assert.throws(() => hook(b, { username: "hopper_7" }), (e: any) => e.message === "taken" && e.code === 6);
  assert.deepEqual(hook(b, { username: "Bunny_2" }), { username: "Bunny_2" });
  assert.deepEqual(hook(b, { langTag: "de" }), { langTag: "de" }, "no username, nothing to check");
});

test("hook: account fields that could carry personal info are refused", () => {
  const b = nk.addUser("rnd");
  for (const field of ["displayName", "avatarUrl", "location", "timezone"]) {
    assert.throws(() => S.beforeUpdateAccount(ctx(b), log, nk, { [field]: "call me 5551234567" }),
      (e: any) => e.message === "field_not_allowed", field);
    assert.deepEqual(S.beforeUpdateAccount(ctx(b), log, nk, { [field]: "" }), { [field]: "" }, "clearing is fine");
  }
});

test("hook: a username sent with the sign-in passes the filter too", () => {
  const hook = (data: object) => S.beforeAuthenticateUsername(ctx(""), log, nk, data);
  assert.throws(() => hook({ account: { id: "device-1234567890" }, create: true, username: "BigDick" }),
    (e: any) => e.message === "blocked_word");
  const ok = { account: { id: "device-1234567890" }, create: true, username: "Hopper_7" };
  assert.deepEqual(hook(ok), ok);
  const none = { account: { id: "device-1234567890" }, create: true };
  assert.deepEqual(hook(none), none, "Nakama picks a random name");
});

// M4 Task 10 review: the phone's band got stricter (the store's age signal) after a 13+ claim: the game
// tells the server, and the account gets under-13's rules at once (offline until consent, quick chat).
test("set_parent_settings: a 13+ account made under_13 loses free text, friends' rules and online play", () => {
  const id = claimed("13_plus");
  const r = call("rpcSetParentSettings", id, { age_band: "under_13" });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.age_band, "under_13");
  assert.equal(r.can_play_online, false);
  assert.equal(r.chat_level, "off");
  assert.deepEqual(nk.users.get(id)!.metadata, { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" });
});
