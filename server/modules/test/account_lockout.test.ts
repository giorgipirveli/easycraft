// Owner #105 (the second adversarial review, 2026-10-16): the fixes to its findings, as tests that assert the fix.
// - Finding 1 (HIGH): a device id unlinked by a LOG IN elsewhere, SIGN OUT OTHER DEVICES or a DELETE never makes a NEW
//   account for itself (beforeAuthenticateDevice forces create=false for a remembered id).
// - Finding 2: a logged-out device id is forgotten from the known list and is no longer a free pass.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const TEEN = S.AccountRules.defaults("13_plus");
const PW = "sunny-river-7";
const NEW_DEVICE = "0b8f6a8e-3c1d-4a8e-9f00-1234567890ab";

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;
let n = 0;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function fresh(): string {
  const id = nk.addUser("x" + ++n + "Rq2w", {});
  nk.linkDevice(id, "fresh-device-" + n + "-000");
  return id;
}

function logIn(userId: string, payload: object, ip = "203.0.113.7"): any {
  return JSON.parse(S.rpcSignInWithPassword({ ...ctx(userId), clientIp: ip }, log, nk, JSON.stringify(payload)));
}

function anna(): string {
  const child = nk.addUser("Anna_7", TEEN);
  nk.linkDevice(child, "phone-device-0001");
  assert.deepEqual(JSON.parse(S.rpcPassword(ctx(child), log, nk, JSON.stringify({ action: "set", password: PW }))), { ok: true });
  return child;
}

// The before-authenticate-device hook, as Nakama would call it: a tombstoned id is refused with its own code (the game
// shows the logged-out words); any other id passes unchanged. {create} when it passes, {refused: message} when not.
function authDevice(deviceId: string, create: boolean): { create?: boolean; refused?: string; code?: number } {
  try {
    const out = (globalThis as any).beforeAuthenticateDevice(ctx(""), log, nk, { account: { id: deviceId }, create: create });
    return { create: out.create };
  } catch (e: any) {
    return { refused: e.message, code: e.code };
  }
}

test("finding 1: a device unlinked by a LOG IN elsewhere never makes a new account for itself", () => {
  const child = anna();
  const first = logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(first.ok, true);
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "the phone was logged out");
  assert.equal(S.Keys.wasRemoved(nk, "phone-device-0001"), true, "its id is remembered as removed");
  // Nakama would otherwise create a fresh empty account for create=true; the hook forces create=false, so it 404s.
  assert.deepEqual(authDevice("phone-device-0001", true), { refused: "device_logged_out", code: 7 }, "the logged-out id is refused with its own code");
  assert.equal(authDevice(NEW_DEVICE, true).create, true, "the device that plays now is untouched");
  void child;
});

test("finding 1: a DELETE remembers the account's device ids, so a guest device makes no new account and no re-claim", () => {
  const child = anna();
  nk.linkDevice(child, NEW_DEVICE);   // the phone is a guest on another device too
  const first = S.rpcDeleteAccount(ctx(child), log, nk, JSON.stringify({}));
  const confirm = JSON.parse(first).confirm;
  assert.equal(JSON.parse(S.rpcDeleteAccount(ctx(child), log, nk, JSON.stringify({ confirm, password: PW }))).deleted, true);
  assert.equal(S.Keys.wasRemoved(nk, "phone-device-0001"), true);
  assert.equal(S.Keys.wasRemoved(nk, NEW_DEVICE), true);
  assert.equal(authDevice("phone-device-0001", true).refused, "device_logged_out", "the deleted account device cannot come back");
});

test("finding 1: a never-removed id still signs in and creates normally", () => {
  anna();
  assert.equal(S.Keys.wasRemoved(nk, "unseen-device-000000"), false);
  assert.equal(authDevice("unseen-device-000000", true).create, true);
  assert.equal(authDevice("0000", true).create, true, "an odd id is left for Nakama to reject");
});

test("SIGN OUT OTHER DEVICES tombstones each unlinked id, and an unlinked id is no longer known", () => {
  const child = anna();
  nk.linkDevice(child, NEW_DEVICE);
  const r = S.Keys.signOutOthers(nk, child, NEW_DEVICE);
  assert.equal(r.ok, true);
  assert.equal(S.Keys.wasRemoved(nk, "phone-device-0001"), true);
  assert.equal(S.Passwords.knows(nk, child, "phone-device-0001"), false, "known means linked right now");
  assert.equal(S.Passwords.knows(nk, child, NEW_DEVICE), true, "the kept device is still known");
});

test("N2: deleting a never-claimed account (the 13-month clean-up) tombstones nothing, so its id can ask again", () => {
  const asker = fresh();   // a never-claimed asking account
  S.Deletion.run(nk, log, asker, "13 months without a sign-in");
  assert.equal(S.Keys.wasRemoved(nk, "fresh-device-" + n + "-000"), false, "no tombstone for a never-claimed account");
  assert.equal(authDevice("fresh-device-" + n + "-000", true).create, true, "its id may make an asking account again");
});

test("N7: an account keeps at most MAX_LINKED device ids; a link beyond that unlinks an older one", () => {
  const child = anna();
  for (let i = 0; i < S.KeyRules.MAX_LINKED + 3; i++) {
    nk.linkDevice(child, "extra-device-" + String(i).padStart(4, "0") + "-00");
  }
  S.Keys.capLinkedDevices(nk, child, "extra-device-0012-00");
  const ids = S.Keys.deviceIds(nk, child);
  assert.ok(ids.length <= S.KeyRules.MAX_LINKED, "capped: " + ids.length);
  assert.ok(ids.indexOf("extra-device-0012-00") >= 0, "the newest link stays");
});

test("N5: the compare never gets an empty probe, and a compare that throws gives the same answer on every path", () => {
  anna();
  const noPass = nk.addUser("Old_1", TEEN);   // an account with no password
  void noPass;
  const probes: string[] = [];
  nk.bcryptCompare = (_h: string, t: string) => {
    probes.push(t);
    throw new Error("bcrypt failed");
  };
  const answers = [
    logIn(fresh(), { username: "Nobody_9", password: "", device_id: NEW_DEVICE }),
    logIn(fresh(), { username: "Old_1", password: "anything-1", device_id: NEW_DEVICE }),
    logIn(fresh(), { username: "Anna_7", password: "wrong-pass-1", device_id: NEW_DEVICE }),
  ];
  for (const a of answers) {
    assert.deepEqual(a, { ok: false, error: "wrong_password" }, JSON.stringify(a));
  }
  assert.equal(probes.length, 3, "one compare on every path");
  assert.ok(probes.every((p) => p !== ""), "never an empty probe");
});

test("N7: device tombstones have a 13-month clean-up", () => {
  assert.ok(S.Retention.SQL_OLD_REMOVED_DEVICES.includes("removed_device:"));
});
