// Verifiable parental consent (spec §17.2): a provider adapter, and a fake provider for developer
// builds (the real one, e.g. Epic's Kids Web Services, needs the owner's registration). Only the
// consent state is kept, never the parent's contact.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const C = S.Consent;
const A = S.AccountRules;

const KID = A.fromMetadata(A.defaults("under_13"));
const NO_RECORD = C.emptyRecord();

test("no provider unless the server names one; 'fake' is the developer provider", () => {
  assert.equal(C.providerFor({}), null);
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "" }), null);
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "kws" }), null, "not built yet: no consent rather than a wrong one");
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake" }).name, "fake");
  assert.equal(C.providerFor(undefined), null);
});

test("a production server never uses the fake provider, even if its env asks for it", () => {
  // server/deploy/ always puts EASYCRAFT_ENV=production into the module's env (agent D).
  for (const prod of ["production", "Production", " production "]) {
    assert.equal(C.providerFor({ EASYCRAFT_ENV: prod, EASYCRAFT_CONSENT_PROVIDER: "fake" }), null, prod);
  }
  assert.equal(C.providerFor({ EASYCRAFT_ENV: "development", EASYCRAFT_CONSENT_PROVIDER: "fake" }).name, "fake");
  assert.equal(S.Util.isProduction({ EASYCRAFT_ENV: "production" }), true);
  assert.equal(S.Util.isProduction({}), false);
  assert.equal(S.Util.isProduction(undefined), false);
});

test("the fake provider answers after its delay: pending, then the parent's answer", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "2000" });
  const started = fake.start("user-1", {}, 10_000);
  assert.equal(started.status, "pending");
  assert.equal(fake.check(started.ref, 11_999).status, "pending");
  const done = fake.check(started.ref, 12_000);
  assert.equal(done.status, "verified");
  assert.deepEqual(done.permissions, { online_allowed: true, chat: "quick" });
  const denied = fake.start("user-1", { fake_answer: "deny" }, 0);
  assert.equal(fake.check(denied.ref, 2_000).status, "denied");
  assert.equal(fake.check("garbage", 99_999).status, "denied", "an unknown request is not consent");
});

test("the fake provider's delay defaults to 2 s and is clamped", () => {
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake" }).delayMs, 2000);
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "-5" }).delayMs, 0);
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "x" }).delayMs, 2000);
  assert.equal(C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "99999999" }).delayMs, 600000);
});

test("start: under_13 goes to pending with the provider's reference, and nothing about the parent is kept", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake" });
  const r = C.start(KID, NO_RECORD, fake, "user-1", { parent_contact: "mum@example.com" }, 5_000);
  assert.equal(r.error, undefined);
  assert.equal(r.state.consent, "pending");
  assert.equal(r.state.online_allowed, false, "still offline while pending");
  assert.equal(r.record.status, "pending");
  assert.equal(r.record.provider, "fake");
  assert.equal(r.record.started_ms, 5_000);
  assert.ok(!JSON.stringify(r.record).includes("example.com"), "the parent's contact is not stored");
});

test("start: refused without a claimed username, for 13_plus, and without a provider", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake" });
  assert.equal(C.start(A.fromMetadata({}), NO_RECORD, fake, "u", {}, 0).error, "not_claimed");
  assert.equal(C.start(A.fromMetadata(A.defaults("13_plus")), NO_RECORD, fake, "u", {}, 0).error, "not_needed");
  assert.equal(C.start(KID, NO_RECORD, null, "u", {}, 0).error, "consent_unavailable");
});

test("start: already verified is a no-op", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake" });
  const verified = { ...KID, consent: "verified" };
  const r = C.start(verified, { ...NO_RECORD, status: "verified" }, fake, "u", {}, 0);
  assert.equal(r.error, undefined);
  assert.equal(r.changed, false);
  assert.equal(r.state.consent, "verified");
});

test("status: pending turns verified with the parent's permissions (under_13 chat stays quick at most)", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "1000" });
  const started = C.start(KID, NO_RECORD, fake, "user-1", {}, 0);
  const early = C.check(started.state, started.record, fake, 500);
  assert.equal(early.changed, false);
  assert.equal(early.state.consent, "pending");
  const later = C.check(started.state, started.record, fake, 1_000);
  assert.equal(later.changed, true);
  assert.equal(later.approved, true);
  assert.equal(later.state.consent, "verified");
  assert.equal(later.state.online_allowed, true);
  assert.equal(later.state.chat, "quick");
  assert.equal(later.record.status, "verified");
  assert.equal(later.record.updated_ms, 1_000);
  assert.equal(A.canPlayOnline(later.state), true);
});

test("status: a denial goes back to no consent, offline", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "0" });
  const started = C.start(KID, NO_RECORD, fake, "user-1", { fake_answer: "deny" }, 0);
  const r = C.check(started.state, started.record, fake, 1);
  assert.equal(r.changed, true);
  assert.equal(r.approved, false);
  assert.equal(r.state.consent, "none");
  assert.equal(r.state.online_allowed, false);
  assert.equal(r.record.status, "denied");
});

test("status: nothing pending, or a record from another provider, changes nothing", () => {
  const fake = C.providerFor({ EASYCRAFT_CONSENT_PROVIDER: "fake", EASYCRAFT_FAKE_CONSENT_DELAY_MS: "0" });
  assert.equal(C.check(KID, NO_RECORD, fake, 5).changed, false);
  const other = { status: "pending", provider: "kws", ref: "x", started_ms: 0, updated_ms: 0 };
  assert.equal(C.check({ ...KID, consent: "pending" }, other, fake, 5).changed, false);
  assert.equal(C.check({ ...KID, consent: "pending" }, other, null, 5).changed, false);
});

test("records read from storage are sanitised", () => {
  assert.deepEqual(C.recordFrom(undefined), C.emptyRecord());
  assert.deepEqual(C.recordFrom({ status: "hacked", provider: 3 }), C.emptyRecord());
  const good = { status: "pending", provider: "fake", ref: "fake:approve:5", started_ms: 1, updated_ms: 2 };
  assert.deepEqual(C.recordFrom(good), good);
});
