// Owner #105 (2026-10-15 23:14; module 0.2.20): "when starting playing create a password. so when logging in another
// device you can use password and username again to login, but if you login another device you should logout
// automatically from old device". The account's password (only its bcrypt hash, server-only), made once and changed with
// the old one or a grown-up's key; LOG IN on another device with the name and the password links that device and logs
// every other device out (one device at a time); wrong names and wrong passwords get one answer; tries are counted per
// name and per asking account by version and fail closed; DELETE needs the password once there is one.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const P = S.PasswordRules;
const TEEN = A.defaults("13_plus");
const UNCLAIMED = {};
const PW = "sunny-river-7";
const NEW_DEVICE = "0b8f6a8e-3c1d-4a8e-9f00-1234567890ab";
const OTHER_DEVICE = "5d7e2c1a-9b8f-4e6d-8c7b-0a1b2c3d4e5f";

// A fake Nakama where another call can write between a read and the write that follows it.
class RacingNakama extends FakeNakama {
  private races: { on: string; times: number; run: (() => void) | null }[] = [];

  raceOnce(on: string, run: () => void): void {
    this.races.push({ on, times: 1, run });
  }

  interfere(on: string, times: number): void {
    this.races.push({ on, times, run: null });
  }

  calm(): void {
    this.races = [];
  }

  storageWrite(writes: any[]): any[] {
    const w = writes[0];
    const race = this.races.find((r) => r.on === w.collection + "/" + w.key && r.times > 0);
    if (race) {
      race.times--;
      if (race.run) {
        race.run();
      } else {
        const o = this.object(w.collection, w.key, w.userId);
        super.storageWrite([{ collection: w.collection, key: w.key, userId: w.userId, value: o ? o.value : {},
          permissionRead: 0, permissionWrite: 0 }]);
      }
    }
    return super.storageWrite(writes);
  }
}

let nk: RacingNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;
let n = 0;

beforeEach(() => {
  nk = new RacingNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function pw(userId: string, payload: object): any {
  return JSON.parse(S.rpcPassword(ctx(userId), log, nk, JSON.stringify(payload)));
}

function logIn(userId: string, payload: object, ip = "203.0.113.7"): any {
  return JSON.parse(S.rpcSignInWithPassword({ ...ctx(userId), clientIp: ip }, log, nk, JSON.stringify(payload)));
}

let ipN = 0;
// A different public address each time (a stranger with many networks), unless one is given.
function anyIp(): string {
  ipN++;
  return "198.51." + Math.floor(ipN / 250) + "." + (ipN % 250 + 1);
}

function del(userId: string, payload: object): any {
  return JSON.parse(S.rpcDeleteAccount(ctx(userId), log, nk, JSON.stringify(payload)));
}

function dev(): string { return "0b8f6a8e-3c1d-4a8e-9f00-" + String(++n).padStart(12, "0"); }
function fresh(): string {
  const id = nk.addUser("x" + ++n + "Rq2w", UNCLAIMED);
  nk.linkDevice(id, "fresh-device-" + n + "-000");
  return id;
}

// Anna plays on her phone (online now) and made her password.
function anna(): string {
  const child = nk.addUser("Anna_7", TEEN);
  nk.linkDevice(child, "phone-device-0001");
  nk.streams.set("0|" + child + "|", [nk.presence(child)]);
  assert.deepEqual(pw(child, { action: "set", password: PW }), { ok: true });
  return child;
}

test("a claimed account makes its password once: only a slow hash is kept, server-only", () => {
  const child = nk.addUser("Anna_7", TEEN);
  assert.deepEqual(pw(child, { action: "state" }), { ok: true, has_password: false, tried_ms: 0 });
  assert.equal(pw(child, { action: "set", password: "abc" }).error, "too_short");
  assert.equal(pw(child, { action: "set", password: "anna_7" }).error, "is_name");
  assert.equal(pw(child, { action: "set", password: "123456" }).error, "too_common");
  assert.deepEqual(pw(child, { action: "set", password: PW }), { ok: true });
  assert.deepEqual(pw(child, { action: "state" }), { ok: true, has_password: true, tried_ms: 0 });
  const o = nk.object("account", "password", child)!;
  assert.equal(o.permissionRead, 0, "the game can't read it back");
  assert.equal(o.permissionWrite, 0);
  assert.ok(!JSON.stringify(o.value).includes(PW), "never the password itself");
  assert.equal(pw(child, { action: "set", password: "another-one-9" }).error, "has_password", "changing needs the old one");
});

test("no password before the name is claimed", () => {
  assert.equal(pw(fresh(), { action: "set", password: PW }).error, "not_claimed");
});

test("changing needs the old password, or a grown-up's key made on a device still logged in", () => {
  const child = anna();
  assert.equal(pw(child, { action: "change", password: "new-word-42" }).error, "wrong_password", "no proof");
  assert.equal(pw(child, { action: "change", password: "new-word-42", old: "nope-nope" }).error, "wrong_password");
  assert.deepEqual(pw(child, { action: "change", password: "new-word-42", old: PW }), { ok: true });
  const key = JSON.parse(S.rpcAccountKey(ctx(child), log, nk, JSON.stringify({ action: "new" }))).key;
  assert.deepEqual(pw(child, { action: "change", password: "third-word-77", key: key.toLowerCase() }), { ok: true },
    "FORGOT PASSWORD: a grown-up's key");
  assert.equal(pw(child, { action: "change", password: "abc", old: "third-word-77" }).error, "too_short");
  const asker = fresh();
  assert.equal(logIn(asker, { username: "Anna_7", password: "third-word-77", device_id: NEW_DEVICE }).ok, true);
});

test("a change's tries are counted first too: two at once can't pass the limit", () => {
  const child = anna();
  for (let i = 0; i < P.CHANGE_MAX_WRONG - 1; i++) {
    pw(child, { action: "change", password: "new-word-42", old: "wrong-" + i });
  }
  let inner: any = null;
  nk.raceOnce("limits/password_change", () => {
    inner = pw(child, { action: "change", password: "new-word-42", old: "wrong-x" });
  });
  const outer = pw(child, { action: "change", password: "new-word-42", old: PW });
  assert.equal(inner.error, "wrong_password");
  assert.equal(outer.error, "locked");
});

test("wrong old passwords lock the change for a while (fail closed)", () => {
  const child = anna();
  for (let i = 0; i < P.CHANGE_MAX_WRONG; i++) {
    assert.equal(pw(child, { action: "change", password: "new-word-42", old: "wrong-" + i }).error, "wrong_password");
  }
  const locked = pw(child, { action: "change", password: "new-word-42", old: PW });
  assert.equal(locked.error, "locked");
  assert.ok(locked.wait > 0);
});

test("LOG IN with the name and the password on another device: one device at a time", () => {
  const child = anna();
  const computer = fresh();
  const r = logIn(computer, { username: "anna_7", password: PW, device_id: NEW_DEVICE });
  assert.deepEqual(r, { ok: true, user_id: child, username: "Anna_7", left: "kept" });
  assert.equal(nk.deviceOwner(NEW_DEVICE), child, "the computer plays as Anna now");
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "the phone is logged out: its link is gone");
  assert.ok(nk.loggedOut.includes(child), "the account's sessions end");
  assert.equal(nk.disconnected.length, 1, "the phone's open socket closes: it hears it at once");
  assert.equal(nk.users.has(computer), true, "the device keeps its asking account (old enough for the next LOG IN)");
});

test("a wrong name and a wrong password get the same answer, with nothing about the account", () => {
  const child = anna();
  nk.addUser("NoPass_1", TEEN);
  const asker = fresh();
  for (const c of [{ username: "Nobody_1", password: PW }, { username: "Anna_7", password: "wrong-word-1" },
    { username: "NoPass_1", password: PW }, { username: "Anna_7", password: 7 }]) {
    assert.deepEqual(logIn(asker, { ...c, device_id: NEW_DEVICE }), { ok: false, error: "wrong_password" }, JSON.stringify(c));
  }
  assert.equal(nk.deviceOwner("phone-device-0001"), child, "nothing happened to Anna");
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("the pair window: five wrong from one asking device, then a wait to the window's end; other devices not slowed", () => {
  anna();
  const tablet = fresh();
  for (let i = 0; i < P.PAIR_MAX_WRONG; i++) {
    assert.equal(logIn(tablet, { username: "Anna_7", password: "wrong-" + i, device_id: NEW_DEVICE }).error, "wrong_password");
  }
  const locked = logIn(tablet, { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(locked.error, "locked", "this asking device must wait to the pair window's end");
  assert.ok(locked.wait > 0 && locked.wait <= P.PAIR_WINDOW_MS / 1000);
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true,
    "another asking device has its own pair window: a stranger's tries never slow the child's own");
});

test("the right password clears this asking device's own pair window: four wrong and one right leave nothing counted", () => {
  const child = anna();
  const tablet = fresh();
  for (let i = 0; i < P.PAIR_MAX_WRONG - 1; i++) {
    logIn(tablet, { username: "Anna_7", password: "wrong-" + i, device_id: NEW_DEVICE });
  }
  assert.equal(logIn(tablet, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true);
  assert.equal(nk.object("limits", "password_pair:" + child, tablet), undefined, "this device's pair window is cleared");
});

test("the child's device that is still linked (known) is never braked, however many strangers try", () => {
  const child = anna();   // phone-device-0001 is linked and known
  for (let i = 0; i < P.NAME_SOFT_MAX + 20; i++) {
    logIn(fresh(), { username: "Anna_7", password: "guess-" + i, device_id: dev() });
  }
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE, known_device: "phone-device-0001" }).ok,
    true, "a device KNOWN to the account (linked now) is never braked");
  assert.equal(nk.deviceOwner(NEW_DEVICE), child);
});

test("a logged-out device id is no longer known (known means linked right now, not a stored list)", () => {
  const child = anna();
  const first = logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(first.ok, true);
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "the phone was logged out");
  assert.equal(S.Passwords.knows(nk, child, "phone-device-0001"), false, "a logged-out id is not known (not a bearer token)");
  assert.equal(S.Passwords.knows(nk, child, NEW_DEVICE), true, "the device linked now is known");
});

test("every try is counted before the password is checked: tries at the same moment can't pass the pair window", () => {
  const child = anna();
  const tablet = fresh();
  for (let i = 0; i < P.PAIR_MAX_WRONG - 1; i++) {
    logIn(tablet, { username: "Anna_7", password: "wrong-" + i, device_id: NEW_DEVICE });
  }
  let inner: any = null;
  nk.raceOnce("limits/password_pair:" + child, () => {
    inner = logIn(tablet, { username: "Anna_7", password: "wrong-x", device_id: NEW_DEVICE });
  });
  const outer = logIn(tablet, { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(inner.error, "wrong_password", "the one that counted first took the last place");
  assert.equal(outer.error, "locked", "the other read the window again and found it full: not even the right one passes");
  assert.equal(nk.object("limits", "password_pair:" + child, tablet)!.value.wrong, P.PAIR_MAX_WRONG);
});

test("many tries at once each hit a write conflict: none of them is ever checked", () => {
  const child = anna();
  let compared = 0;
  const compare = nk.bcryptCompare.bind(nk);
  nk.bcryptCompare = (h: string, t: string) => {
    compared++;
    return compare(h, t);
  };
  nk.interfere("limits/password_pair:" + child, 30);
  const tablet = fresh();
  for (let i = 0; i < 10; i++) {
    assert.equal(logIn(tablet, { username: "Anna_7", password: "guess-" + i, device_id: NEW_DEVICE }).error, "locked");
  }
  assert.equal(compared, 0, "a try that could not be counted is never compared");
});

test("a count that can't be written fails closed: locked, never a pass", () => {
  const child = anna();
  for (const counter of ["limits/password_pair:" + child, "limits/password_name"]) {
    nk.interfere(counter, 10);
    const r = logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
    assert.equal(r.error, "locked", counter);
    assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
    nk.calm();
  }
});

test("the same account typing its own password links nothing", () => {
  const child = anna();
  assert.deepEqual(logIn(child, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }),
    { ok: true, user_id: child, username: "Anna_7", left: "same" });
  assert.equal(nk.deviceOwner("phone-device-0001"), child);
});

test("a claimed asking account (a sibling's) is kept; a used or odd device id is refused", () => {
  const child = anna();
  const sibling = nk.addUser("Bro_9", TEEN);
  assert.equal(logIn(sibling, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).left, "kept");
  assert.equal(nk.users.has(sibling), true);
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: "x" }).error, "bad_request");
  nk.linkDevice(sibling, OTHER_DEVICE);
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: OTHER_DEVICE }).error, "bad_request");
  assert.equal(nk.deviceOwner(NEW_DEVICE), child, "the last login's device stays");
});

test("DELETE needs the password once there is one (the owner's own path does not)", () => {
  const child = anna();
  const first = del(child, {});
  assert.equal(first.ok, true);
  assert.equal(del(child, { confirm: first.confirm }).error, "password_needed");
  assert.equal(del(child, { confirm: first.confirm, password: "wrong-one-1" }).error, "wrong_password");
  assert.equal(nk.users.has(child), true);
  const r = del(child, { confirm: first.confirm, password: PW });
  assert.equal(r.deleted, true);
  assert.equal(nk.users.has(child), false);
  assert.equal(nk.object("account", "password", child), undefined, "its hash goes with it");
  const noPass = nk.addUser("Old_1", TEEN);
  const c = del(noPass, {});
  assert.equal(del(noPass, { confirm: c.confirm }).deleted, true, "an account with no password: as before");
});

// --- The lead's second review of the passwords (2026-10-15) ---

test("every spelling of a name shares one window: the pair is the account, not what was typed", () => {
  const child = anna();
  const tablet = fresh();
  const spellings = ["Anna_7", "anna_7", "ANNA_7", " anna_7 ", "aNnA_7"];
  for (const name of spellings) {
    assert.equal(logIn(tablet, { username: name, password: "wrong-" + name, device_id: NEW_DEVICE }).error, "wrong_password");
  }
  assert.equal(logIn(tablet, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).error, "locked",
    "five spellings were five tries of one pair");
  assert.equal(nk.object("limits", "password_pair:" + child, tablet)!.value.wrong, P.PAIR_MAX_WRONG);
  for (const name of ["Nobody_9", "NOBODY_9", " nobody_9"]) {
    logIn(tablet, { username: name, password: "x-" + name, device_id: NEW_DEVICE });
  }
  assert.equal(nk.object("limits", "password_pair:nobody_9", tablet)!.value.wrong, 3, "a name nobody has: one window too");
});

test("the name window: past 10 unknown-device wrong tries, each further unknown try waits 10 minutes (one fixed wait)", () => {
  const child = anna();
  for (let i = 0; i < P.NAME_SOFT_MAX; i++) {
    logIn(fresh(), { username: "Anna_7", password: "guess-" + i, device_id: dev() });
  }
  const braked = logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(braked.error, "slow_down", "the name's brake, never a lock");
  assert.ok(braked.wait > 0 && braked.wait <= P.NAME_WAIT_MS / 1000, String(braked.wait));
  now += P.NAME_WAIT_MS;
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true, "ten minutes later: in");
  assert.equal(nk.deviceOwner(NEW_DEVICE), child);
});

test("under a steady attack a name gets at most about 144 + 10 unknown-device guesses a day, never a longer wait", () => {
  anna();
  let passed = 0;
  let longest = 0;
  const day = 24 * 60 * 60 * 1000;
  const start = now;
  while (now < start + day) {
    const r = logIn(fresh(), { username: "Anna_7", password: "guess-" + now, device_id: dev() });
    if (r.error === "wrong_password") {
      passed++;
    } else {
      longest = Math.max(longest, r.wait);
    }
    now += 60 * 1000;
  }
  assert.ok(longest <= P.NAME_WAIT_MS / 1000, "never a longer wait than 10 minutes: " + longest);
  assert.ok(passed <= P.NAME_SOFT_MAX + day / P.NAME_WAIT_MS + 2, "guesses checked in a day: " + passed);
  assert.ok(passed >= day / P.NAME_WAIT_MS - 2, "a queue, not a wall: " + passed);
});

test("the name's 24-hour window cannot be reset to zero by a short pause", () => {
  anna();
  for (let i = 0; i < P.NAME_SOFT_MAX; i++) {
    logIn(fresh(), { username: "Anna_7", password: "guess-" + i, device_id: dev() });
  }
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).error, "slow_down");
  now += 2 * 60 * 60 * 1000;   // a two-hour pause
  assert.equal(logIn(fresh(), { username: "Anna_7", password: "guess-after", device_id: dev() }).error, "wrong_password",
    "after the pause one try has its 10-minute turn");
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).error, "slow_down",
    "and the next waits again: the pause gave no fresh run of 10 (the 24-hour count stays at the cap)");
  now += P.NAME_WINDOW_MS;
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true, "a fresh day: in");
});

test("the key is never limited by password tries: a grown-up's key always gets her in", () => {
  const child = anna();
  const key = JSON.parse(S.rpcAccountKey(ctx(child), log, nk, JSON.stringify({ action: "new" }))).key;
  for (let i = 0; i < P.NAME_SOFT_MAX + 10; i++) {
    logIn(fresh(), { username: "Anna_7", password: "guess-" + i, device_id: dev() });
  }
  const viaKey = JSON.parse(S.rpcSignInWithKey(ctx(fresh()), log, nk, JSON.stringify({ username: "Anna_7", key, device_id: OTHER_DEVICE })));
  assert.equal(viaKey.ok, true, JSON.stringify(viaKey));
  assert.equal(nk.deviceOwner(OTHER_DEVICE), child);
});

test("the account's devices hear of a new device's wrong try, at most once an hour; the asker hears nothing", () => {
  const child = anna();
  assert.equal(pw(child, { action: "state" }).tried_ms, 0);
  const asker = fresh();
  logIn(asker, { username: "Anna_7", password: "guess-1", device_id: NEW_DEVICE });
  const first = pw(child, { action: "state" }).tried_ms;
  assert.equal(first, now, "kept on the account for a device that was offline");
  const told = nk.notifications.filter((x) => x.userId === child && x.code === S.Passwords.NOTE);
  assert.equal(told.length, 1, "an online device hears it at once");
  assert.equal(told[0].persistent, true, "kept as a note too");
  now += 10 * 60 * 1000;
  logIn(fresh(), { username: "Anna_7", password: "guess-2", device_id: NEW_DEVICE }, anyIp());
  assert.equal(pw(child, { action: "state" }).tried_ms, first, "not again within the hour");
  assert.equal(nk.notifications.filter((x) => x.userId === child && x.code === S.Passwords.NOTE).length, 1);
  assert.equal(nk.notifications.filter((x) => x.userId === asker).length, 0, "nothing goes back to the asker");
  now += 60 * 60 * 1000;
  logIn(fresh(), { username: "Anna_7", password: "guess-3", device_id: NEW_DEVICE }, anyIp());
  assert.equal(pw(child, { action: "state" }).tried_ms, now, "an hour later: once more");
});

test("a brand-new asking account waits a moment first (a throwaway's pattern); an older one does not", () => {
  anna();
  const asker = fresh();
  nk.users.get(asker)!.createTime = Math.floor(now / 1000) - 5;
  const r = logIn(asker, { username: "Anna_7", password: PW, device_id: NEW_DEVICE });
  assert.equal(r.error, "too_new");
  assert.ok(r.wait > 0 && r.wait <= P.ASKER_MIN_AGE_MS / 1000, String(r.wait));
  assert.equal(nk.object("limits", "password_by", asker), undefined, "nothing was counted or checked");
  now += P.ASKER_MIN_AGE_MS;
  assert.equal(logIn(asker, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true);
});

test("a correct login clears only its own pair window; the name window is never decremented", () => {
  const child = anna();
  const tablet = fresh();
  for (let i = 0; i < P.NAME_SOFT_MAX - 1; i++) {
    logIn(fresh(), { username: "Anna_7", password: "guess-" + i, device_id: dev() });
  }
  const before = nk.object("limits", "password_name", child)!.value.wrong;
  assert.equal(logIn(tablet, { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true, "a correct login");
  assert.equal(nk.object("limits", "password_name", child)!.value.wrong, before + 1,
    "the correct login counted on the name too and was NOT taken back (only the pair is released)");
});

test("old password windows and device tombstones go in the daily clean-up", () => {
  anna();
  logIn(fresh(), { username: "Anna_7", password: "wrong-1", device_id: NEW_DEVICE });
  assert.ok(S.Retention.SQL_OLD_PASSWORD_WINDOWS.includes("password_"), "the pair and name windows' clean-up query");
  assert.ok(S.Retention.SQL_OLD_REMOVED_DEVICES.includes("removed_device"), "the device tombstones' clean-up query");
});

test("the module registers password and sign_in_with_password", () => {
  const registered: string[] = [];
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  for (const id of ["password", "sign_in_with_password", "sign_in_with_key", "delete_account", "log_out"]) {
    assert.ok(registered.includes(id), id);
  }
  assert.equal(typeof nk.localcacheGet("password_probe_hash"), "string", "the probe hash is made at startup");
});

// --- LOG OUT (the final review's simple model) ---

function logOut(userId: string, payload: object): any {
  return JSON.parse(S.rpcLogOut(ctx(userId), log, nk, JSON.stringify(payload)));
}

test("LOG OUT needs a password first, then unlinks this device (even the last one), tombstones it, ends the sessions", () => {
  const noPass = nk.addUser("Pip_4", TEEN);
  nk.linkDevice(noPass, "pip-device-000001");
  assert.equal(logOut(noPass, { device_id: "pip-device-000001" }).error, "password_needed", "make a password first");
  assert.equal(nk.deviceOwner("pip-device-000001"), noPass, "nothing changed");
  const child = anna();   // phone-device-0001 is her only device
  assert.equal(logOut(child, { device_id: "someone-elses-001" }).error, "not_allowed");
  assert.deepEqual(logOut(child, { device_id: "phone-device-0001" }), { ok: true });
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "this device is unlinked (her last one)");
  assert.equal(S.Keys.wasRemoved(nk, "phone-device-0001"), true, "and tombstoned: it never signs in again by itself");
  assert.ok(nk.loggedOut.includes(child), "the account's sessions end");
  assert.equal(nk.users.has(child), true, "the account stays safe on the server");
  assert.equal(logIn(fresh(), { username: "Anna_7", password: PW, device_id: NEW_DEVICE }).ok, true,
    "LOG IN with the name and the password brings it back");
  assert.equal(logOut(fresh(), { device_id: "x" }).error, "not_claimed");
});

test("the dummy compare uses a hash made by the server's own bcrypt (the same cost as a real password's)", () => {
  anna();
  const made: string[] = [];
  const hash = nk.bcryptHash.bind(nk);
  nk.bcryptHash = (t: string) => { const h = hash(t); made.push(h); return h; };
  nk.localcacheDelete("password_probe_hash");
  logIn(fresh(), { username: "Nobody_9", password: "guess-1", device_id: NEW_DEVICE });
  assert.equal(made.length, 1, "made once with nk.bcryptHash");
  logIn(fresh(), { username: "Nobody_8", password: "guess-2", device_id: NEW_DEVICE });
  assert.equal(made.length, 1, "then kept in the node's cache");
});
