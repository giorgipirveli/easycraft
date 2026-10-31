// Account state in Nakama's account metadata (plan M4 Wave 1: age_band, consent, online_allowed,
// chat) and the parent's settings (spec §5.14, §17.2): high-privacy defaults, nothing online for
// under_13 without verified consent, quick chat only for under_13.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const A = server().AccountRules;

test("defaults: under_13 is offline with quick chat and no consent; 13_plus is online with filtered chat", () => {
  assert.deepEqual(A.defaults("under_13"), { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" });
  assert.deepEqual(A.defaults("13_plus"), { age_band: "13_plus", consent: "none", online_allowed: true, chat: "filtered" });
});

test("an account that never claimed a username reads as unclaimed under_13, offline", () => {
  for (const meta of [undefined, null, {}, { age_band: "adult" }, "junk", []]) {
    const s = A.fromMetadata(meta);
    assert.equal(s.claimed, false, JSON.stringify(meta));
    assert.equal(s.age_band, "", JSON.stringify(meta));
    assert.equal(A.effectiveBand(s.age_band), "under_13");
    assert.equal(A.canPlayOnline(s), false);
    assert.equal(A.chatLevel(s), "off");
  }
});

test("broken fields fall back to the strictest value", () => {
  const s = A.fromMetadata({ age_band: "under_13", consent: "yes!", online_allowed: "true", chat: "loud" });
  assert.deepEqual(A.toMetadata(s), { age_band: "under_13", consent: "none", online_allowed: false, chat: "off" });
  assert.equal(s.claimed, true);
});

test("metadata round trip keeps exactly the four shared keys", () => {
  const s = A.fromMetadata({ age_band: "13_plus", consent: "none", online_allowed: true, chat: "filtered", extra: 1 });
  assert.deepEqual(Object.keys(A.toMetadata(s)).sort(), ["age_band", "chat", "consent", "online_allowed"]);
});

test("under_13 plays online only with verified consent and the parent's switch on", () => {
  const base = A.defaults("under_13");
  assert.equal(A.canPlayOnline({ ...base, online_allowed: true }), false, "no consent");
  assert.equal(A.canPlayOnline({ ...base, consent: "pending", online_allowed: true }), false, "pending");
  assert.equal(A.canPlayOnline({ ...base, consent: "verified", online_allowed: false }), false, "switched off");
  assert.equal(A.canPlayOnline({ ...base, consent: "verified", online_allowed: true }), true);
});

test("13_plus plays online unless the parent switched it off", () => {
  assert.equal(A.canPlayOnline(A.defaults("13_plus")), true);
  assert.equal(A.canPlayOnline({ ...A.defaults("13_plus"), online_allowed: false }), false);
});

test("chat level: off when offline, never above quick for under_13", () => {
  const kid = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
  assert.equal(A.chatLevel(kid), "quick");
  assert.equal(A.chatLevel({ ...kid, chat: "filtered" }), "quick", "a stored 'filtered' can't lift under_13");
  assert.equal(A.chatLevel({ ...kid, chat: "off" }), "off");
  assert.equal(A.chatLevel({ ...kid, online_allowed: false }), "off");
  assert.equal(A.chatLevel(A.defaults("13_plus")), "filtered");
  assert.equal(A.chatLevel({ ...A.defaults("13_plus"), chat: "quick" }), "quick");
});

test("the first claim sets the band's defaults; a later claim keeps the account's state", () => {
  const first = A.onClaim(A.fromMetadata({}), "under_13");
  assert.deepEqual(first, { state: A.defaults("under_13") });
  const verified = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
  assert.deepEqual(A.onClaim(A.fromMetadata(verified), "13_plus"), { state: verified }, "the band changes only through the parent");
  assert.deepEqual(A.onClaim(A.fromMetadata({}), "adult"), { error: "bad_age_band" });
  assert.deepEqual(A.onClaim(A.fromMetadata({}), undefined), { error: "bad_age_band" });
});

test("parent settings: switches for 13_plus", () => {
  const teen = A.defaults("13_plus");
  assert.deepEqual(A.applyParentSettings(teen, { online_allowed: false }), { state: { ...teen, online_allowed: false } });
  assert.deepEqual(A.applyParentSettings(teen, { chat: "quick" }), { state: { ...teen, chat: "quick" } });
  assert.deepEqual(A.applyParentSettings(teen, { chat: "off" }), { state: { ...teen, chat: "off" } });
  assert.deepEqual(A.applyParentSettings(teen, {}), { state: teen }, "nothing asked, nothing changes");
});

test("parent settings: under_13 needs consent before online, and never gets free text", () => {
  const kid = A.defaults("under_13");
  assert.deepEqual(A.applyParentSettings(kid, { online_allowed: true }), { error: "consent_needed" });
  const consented = { ...kid, consent: "verified" };
  assert.deepEqual(A.applyParentSettings(consented, { online_allowed: true }), { state: { ...consented, online_allowed: true } });
  assert.deepEqual(A.applyParentSettings(consented, { chat: "filtered" }), { error: "chat_not_allowed" });
  assert.deepEqual(A.applyParentSettings(consented, { chat: "off", online_allowed: false }),
    { state: { ...consented, chat: "off", online_allowed: false } });
});

test("parent settings: bad values are refused", () => {
  const teen = A.defaults("13_plus");
  for (const bad of [{ online_allowed: "yes" }, { chat: "shout" }, { chat: 3 }, { age_band: "adult" }, { age_band: 13 }]) {
    assert.deepEqual(A.applyParentSettings(teen, bad), { error: "bad_request" }, JSON.stringify(bad));
  }
});

test("parent settings: changing the band starts from the new band's defaults and keeps consent", () => {
  const teen = A.defaults("13_plus");
  assert.deepEqual(A.applyParentSettings(teen, { age_band: "under_13" }),
    { state: { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" } });
  assert.deepEqual(A.applyParentSettings(teen, { age_band: "under_13", online_allowed: true }), { error: "consent_needed" });
});

test("parent settings need a claimed account", () => {
  assert.deepEqual(A.applyParentSettings(A.fromMetadata({}), { chat: "off" }), { error: "not_claimed" });
});

// M4 Task 10 review: the server can't see the phone's parent gate, and the game never asks for an older
// band, so a call that lifts an under_13 account to 13_plus (free text, friends without a grown-up, no
// consent) comes from a modified game: refused. The band only ever gets stricter (spec §17.2).
test("parent settings: the band only ever gets stricter; under_13 never becomes 13_plus from a game", () => {
  const kid = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
  assert.deepEqual(A.applyParentSettings(kid, { age_band: "13_plus" }), { error: "age_band_locked" });
  assert.deepEqual(A.applyParentSettings(A.defaults("under_13"), { age_band: "13_plus", chat: "filtered" }),
    { error: "age_band_locked" });
  assert.deepEqual(A.applyParentSettings(kid, { age_band: "under_13" }), { state: kid }, "the same band changes nothing");
  assert.deepEqual(A.applyParentSettings(A.defaults("13_plus"), { age_band: "13_plus" }), { state: A.defaults("13_plus") });
});
