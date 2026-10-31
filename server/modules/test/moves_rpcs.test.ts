// Owner #99 (module 0.2.20; spec §5.13 "As built (owner #99)"): the same name on a new device, with proof and never by
// the name alone. A new device asks for an account by its name (move_request "start") and shows the 6-digit code it
// gets; a device of that account sees the ask without the code (move_approve "list"; notification 110 "asked") and a
// grown-up types the code there ("approve"); the asking device then gets a one-time key ("status") and signs in with
// sign_in_with_key, as a grown-up's key does. Wrong codes, NOT ME, BACK and five minutes end an ask; asks are limited
// per name and per asking account; the old device stays signed in and hears "moved".
// The lead's security review (2026-10-15): the asking device learns nothing about the account beyond what
// claim_username's "taken" tells (not whether it plays now, not what its devices did, not how many others asked), and
// every count and use on the way is written by version and fails closed (a concurrent call never slips past a limit).
import { test, beforeEach, before, after } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const M = S.MoveRules;
const TEEN = A.defaults("13_plus");
const UNCLAIMED = {};
const NEW_DEVICE = "0b8f6a8e-3c1d-4a8e-9f00-1234567890ab";
const OTHER_DEVICE = "5d7e2c1a-9b8f-4e6d-8c7b-0a1b2c3d4e5f";

// A fake Nakama where another call can happen between a read and the write that follows it, as on a busy server.
class RacingNakama extends FakeNakama {
  private races: { on: string; times: number; run: (() => void) | null }[] = [];

  // Once, just before the next write to collection/key: `run` (another call, which reads and writes the same object).
  raceOnce(on: string, run: () => void): void {
    this.races.push({ on, times: 1, run });
  }

  // The next `times` writes to collection/key each find that object changed under them (its version moved on).
  interfere(on: string, times: number): void {
    this.races.push({ on, times, run: null });
  }

  storageWrite(writes: any[]): any[] {
    const w = writes[0];
    const race = this.races.find((r) => r.on === w.collection + "/" + w.key && r.times > 0);
    if (race) {
      race.times--;
      if (race.run) {
        race.run();
      } else {
        const o = this.object(w.collection, w.key, w.userId); // another call wrote it (or made it) meanwhile
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

// The move ships OFF (MoveRules.ENABLED, the lead's quick-ship round); these tests are for when it is on again.
before(() => {
  S.MoveRules.ENABLED = true;
});

after(() => {
  S.MoveRules.ENABLED = false;
});

beforeEach(() => {
  nk = new RacingNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function ask(userId: string, payload: object): any {
  return JSON.parse(S.rpcMoveRequest(ctx(userId), log, nk, JSON.stringify(payload)));
}

function approve(userId: string, payload: object): any {
  return JSON.parse(S.rpcMoveApprove(ctx(userId), log, nk, JSON.stringify(payload)));
}

function keySignIn(userId: string, payload: object): any {
  return JSON.parse(S.rpcSignInWithKey(ctx(userId), log, nk, JSON.stringify(payload)));
}

function fresh(): string {
  const id = nk.addUser("x" + ++n + "Rq2w", UNCLAIMED);
  nk.linkDevice(id, "fresh-device-" + n + "-000");
  return id;
}

// Anna plays on her phone; a computer's new, never-claimed account asks for her name.
function family(): { child: string; asker: string } {
  const child = nk.addUser("Anna_7", TEEN);
  nk.linkDevice(child, "phone-device-0001");
  return { child, asker: fresh() };
}

function online(userId: string): void {
  nk.streams.set("0|" + userId + "|", [nk.presence(userId)]);
}

function notes(userId: string): any[] {
  return nk.notifications.filter((x) => x.userId === userId && x.code === 110);
}

function wrongFor(code: string): string {
  return code === "000000" ? "111111" : "000000";
}

function approvedKey(f: { child: string; asker: string }): { id: string; key: string } {
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: true });
  return { id: r.id, key: ask(f.asker, { action: "status", id: r.id }).key };
}

test("a taken name asks: the new device gets a 6-digit code, the account's devices hear of the ask but never its code", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "anna_7", kind: "computer" });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.match(r.code, /^[0-9]{6}$/);
  assert.deepEqual(Object.keys(r).sort(), ["code", "id", "ok", "valid_s"], "nothing about the account: not its name's case");
  assert.equal(r.valid_s, M.CODE_MS / 1000);
  const heard = notes(f.child);
  assert.equal(heard.length, 1);
  assert.deepEqual(heard[0].content, { what: "asked", kind: "computer" });
  assert.equal(heard[0].persistent, false, "an old device that comes online later asks the list");
  const list = approve(f.child, { action: "list" });
  assert.deepEqual(list, { ok: true, username: "Anna_7", asks: [{ id: r.id, kind: "computer", left_s: 300 }] });
  const stored = nk.object("account", "move_asks", f.child)!;
  assert.equal(stored.permissionRead, 0, "the game can't read the asks (or their codes) itself");
  assert.equal(stored.permissionWrite, 0);
  assert.ok(!JSON.stringify(notes(f.child)).includes(r.code));
});

test("the asking device never learns whether the account plays now", () => {
  const f = family();
  const quiet = ask(f.asker, { action: "start", username: "Anna_7", kind: "computer" });
  const statusQuiet = ask(f.asker, { action: "status", id: quiet.id });
  online(f.child);
  const busy = ask(fresh(), { action: "start", username: "Anna_7", kind: "computer" });
  assert.deepEqual(Object.keys(busy).sort(), Object.keys(quiet).sort());
  assert.ok(!("online" in busy) && !("online" in statusQuiet), JSON.stringify([busy, statusQuiet]));
  assert.deepEqual(ask(f.asker, { action: "status", id: quiet.id }), statusQuiet, "the same answer, the phone online or not");
});

test("the right code on the old device approves; the new device gets a one-time key and signs in to the account", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "computer" });
  assert.deepEqual(ask(f.asker, { action: "status", id: r.id }), { ok: true, state: "waiting", left_s: 300 });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code.slice(0, 3) + " " + r.code.slice(3) }), { ok: true });
  assert.deepEqual(notes(f.asker).map((x) => x.content), [{ what: "approved" }], "the new device hears it at once");
  const st = ask(f.asker, { action: "status", id: r.id });
  assert.equal(st.ok, true);
  assert.equal(st.state, "approved");
  assert.equal(st.username, "Anna_7", "the account's name, once its device said yes");
  assert.match(st.key, /^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
  const kept = nk.object("account", "move_asks", f.child)!;
  assert.ok(!JSON.stringify(kept.value).includes(st.key.replace("-", "")), "only the key's hash is kept");
  const done = keySignIn(f.asker, { username: "Anna_7", key: st.key, device_id: NEW_DEVICE });
  assert.deepEqual(done, { ok: true, user_id: f.child, username: "Anna_7", left: "deleted" });
  assert.equal(nk.deviceOwner(NEW_DEVICE), f.child, "the computer signs in to Anna's account now");
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "one device at a time: the phone is logged out (owner #105)");
  assert.deepEqual(notes(f.child).map((x) => x.content), [{ what: "asked", kind: "computer" }, { what: "moved", kind: "computer" }],
    "the phone hears: your game is on a computer now too");
  assert.deepEqual(approve(f.child, { action: "list" }).asks, []);
});

test("the one-time key works only for the device that asked, once, and only for a while", () => {
  const f = family();
  const k = approvedKey(f);
  const stranger = fresh();
  assert.deepEqual(keySignIn(stranger, { username: "Anna_7", key: k.key, device_id: NEW_DEVICE }), { ok: false, error: "wrong_key" },
    "a key seen over someone's shoulder is no use on another device");
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: k.key, device_id: NEW_DEVICE }).ok, true);
  const g = family2(f.child);
  const late = approvedKey(g);
  now += M.KEY_MS;
  assert.deepEqual(keySignIn(g.asker, { username: "Anna_7", key: late.key, device_id: OTHER_DEVICE }), { ok: false, error: "wrong_key" },
    "too late");
});

// The same family again, after the first one's asker went (its own account was deleted by the move).
// The same account again, for a second ask (its phone was logged out by the first key sign-in: one device at a time).
function family2(child: string): { child: string; asker: string } {
  return { child, asker: fresh() };
}

test("a used key is used up", () => {
  const f = family();
  const sibling = nk.addUser("Bro_9", TEEN); // an asker that claimed a name of its own is kept by the move
  const r = ask(sibling, { action: "start", username: "Anna_7", kind: "tablet" });
  approve(f.child, { action: "approve", id: r.id, code: r.code });
  const key = ask(sibling, { action: "status", id: r.id }).key;
  assert.equal(keySignIn(sibling, { username: "Anna_7", key, device_id: NEW_DEVICE }).left, "kept");
  assert.deepEqual(keySignIn(sibling, { username: "Anna_7", key, device_id: OTHER_DEVICE }), { ok: false, error: "wrong_key" });
  assert.equal(nk.deviceOwner(OTHER_DEVICE), undefined);
});

test("the key is handed again when an answer was lost, a few times at most; only the newest works", () => {
  const f = family();
  const k = approvedKey(f);
  const second = ask(f.asker, { action: "status", id: k.id }).key;
  assert.notEqual(k.key, second);
  for (let i = 2; i < M.HANDOUT_MAX; i++) {
    assert.equal(ask(f.asker, { action: "status", id: k.id }).state, "approved");
  }
  const over = ask(f.asker, { action: "status", id: k.id });
  assert.equal(over.state, "waiting", "no more keys");
  assert.equal(over.key, undefined);
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: k.key, device_id: NEW_DEVICE }).error, "wrong_key");
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: second, device_id: NEW_DEVICE }).error, "wrong_key",
    "the hand-outs are over: no key of this ask works any more");
});

test("a name alone moves nothing: unknown and never-claimed names, and the asker's own name", () => {
  const f = family();
  assert.deepEqual(ask(f.asker, { action: "start", username: "Nobody_1", kind: "phone" }), { ok: false, error: "no_such_player" });
  const other = fresh();
  const otherName = nk.accountGetId(other).user.username;
  assert.deepEqual(ask(f.asker, { action: "start", username: otherName, kind: "phone" }), { ok: false, error: "no_such_player" },
    "a never-claimed account's random name");
  assert.deepEqual(ask(f.child, { action: "start", username: "ANNA_7", kind: "phone" }), { ok: false, error: "self" },
    "only the account itself hears self: it says nothing about anyone else");
  for (const guess of ["0000-0000", "123456"]) {
    assert.equal(keySignIn(f.asker, { username: "Anna_7", key: guess, device_id: NEW_DEVICE }).error, "wrong_key");
  }
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("three wrong codes end the ask on the old device; the new device just waits until its code is over", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "tablet" });
  const wrong = wrongFor(r.code);
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: wrong }), { ok: false, error: "wrong_code", tries_left: 2 });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: wrong }), { ok: false, error: "wrong_code", tries_left: 1 });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: wrong }), { ok: false, error: "ended", why: "wrong_code" });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: false, error: "ended", why: "wrong_code" });
  assert.deepEqual(ask(f.asker, { action: "status", id: r.id }), { ok: true, state: "waiting", left_s: 300 },
    "the asker can't tell what the account's devices did");
  assert.deepEqual(notes(f.asker), []);
  now += M.CODE_MS;
  assert.deepEqual(ask(f.asker, { action: "status", id: r.id }), { ok: true, state: "ended", why: "expired" });
});

test("NOT ME on the old device ends the ask (quietly for the asker); BACK on the new one ends it at once", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  assert.deepEqual(approve(f.child, { action: "decline", id: r.id }), { ok: true });
  assert.deepEqual(approve(f.child, { action: "list" }).asks, []);
  assert.equal(ask(f.asker, { action: "status", id: r.id }).state, "waiting");
  assert.deepEqual(notes(f.asker), [], "no word that a device of the account is there");
  const again = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  assert.deepEqual(ask(f.asker, { action: "cancel", id: again.id }), { ok: true });
  assert.deepEqual(approve(f.child, { action: "list" }).asks, []);
  assert.deepEqual(approve(f.child, { action: "approve", id: again.id, code: again.code }), { ok: false, error: "ended", why: "cancelled" });
  assert.deepEqual(ask(f.asker, { action: "status", id: again.id }), { ok: false, error: "not_found" });
});

test("after five minutes the code is over; an old device that comes online meanwhile still sees the ask", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "computer" });
  now += 4 * 60 * 1000;
  assert.deepEqual(approve(f.child, { action: "list" }).asks, [{ id: r.id, kind: "computer", left_s: 60 }]);
  now += 60 * 1000;
  assert.deepEqual(approve(f.child, { action: "list" }).asks, []);
  assert.deepEqual(ask(f.asker, { action: "status", id: r.id }), { ok: true, state: "ended", why: "expired" });
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: false, error: "ended", why: "expired" });
});

test("asks for one name are limited without telling anyone: past the limit an ask looks the same but reaches no device", () => {
  const f = family();
  for (let i = 0; i < M.NAME_MAX; i++) {
    assert.equal(ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" }).ok, true);
  }
  const heardBefore = notes(f.child).length;
  const askedBefore = approve(f.child, { action: "list" }).asks.map((x: any) => x.id);
  const asker = fresh();
  const over = ask(asker, { action: "start", username: "Anna_7", kind: "phone" });
  assert.deepEqual(Object.keys(over).sort(), ["code", "id", "ok", "valid_s"], "no rate_limited: nothing tells that others asked");
  assert.equal(notes(f.child).length, heardBefore, "the phone is not bothered again");
  assert.deepEqual(approve(f.child, { action: "list" }).asks.map((x: any) => x.id), askedBefore);
  assert.deepEqual(approve(f.child, { action: "approve", id: over.id, code: over.code }), { ok: false, error: "not_found" },
    "its code approves nothing");
  assert.deepEqual(ask(asker, { action: "status", id: over.id }), { ok: true, state: "waiting", left_s: 300 });
  now += M.CODE_MS;
  assert.deepEqual(ask(asker, { action: "status", id: over.id }), { ok: true, state: "ended", why: "expired" });
  now += M.NAME_WINDOW_MS;
  assert.equal(ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" }).ok, true);
  assert.equal(notes(f.child).length, heardBefore + 1, "a new window: asks reach the phone again");
});

test("one device's asks are limited (that says only what the device did itself)", () => {
  const names: string[] = [];
  for (let i = 0; i < M.ASKER_MAX + 1; i++) {
    const id = nk.addUser("Kid_" + i, TEEN);
    names.push(nk.accountGetId(id).user.username);
  }
  const one = fresh();
  for (let i = 0; i < M.ASKER_MAX; i++) {
    assert.equal(ask(one, { action: "start", username: names[i], kind: "phone" }).ok, true, String(i));
  }
  const over = ask(one, { action: "start", username: names[M.ASKER_MAX], kind: "phone" });
  assert.equal(over.error, "rate_limited");
  assert.ok(over.wait > 0 && over.wait <= M.ASKER_WINDOW_MS / 1000, String(over.wait));
});

test("at most three asks open for an account: a fourth ends the oldest, quietly for its asker", () => {
  const f = family();
  const askers = [fresh(), fresh(), fresh(), fresh()];
  const ids = askers.map((a) => ask(a, { action: "start", username: "Anna_7", kind: "phone" }).id);
  assert.deepEqual(approve(f.child, { action: "list" }).asks.map((x: any) => x.id), ids.slice(1));
  assert.equal(ask(askers[0], { action: "status", id: ids[0] }).state, "waiting", "it can't tell that others asked");
  assert.deepEqual(notes(askers[0]), []);
});

test("a new ask by the same device ends its earlier one", () => {
  const f = family();
  const first = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  const second = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  assert.notEqual(first.id, second.id);
  assert.deepEqual(approve(f.child, { action: "list" }).asks.map((x: any) => x.id), [second.id]);
  assert.deepEqual(ask(f.asker, { action: "status", id: first.id }), { ok: false, error: "not_found" }, "it asks about its newest");
});

test("only the account's own devices see and approve its asks; only the asker sees its own", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  const stranger = nk.addUser("Other_1", TEEN);
  assert.deepEqual(approve(stranger, { action: "list" }).asks, []);
  assert.deepEqual(approve(stranger, { action: "approve", id: r.id, code: r.code }), { ok: false, error: "not_found" });
  assert.deepEqual(ask(stranger, { action: "status", id: r.id }), { ok: false, error: "not_found" });
  assert.deepEqual(ask(f.asker, { action: "status", id: r.id }).state, "waiting", "nothing changed");
});

// --- Concurrent calls (the lead's security review): every count and every use fails closed ---

test("two asks at once from one device can't both pass its last place in the window", () => {
  const names: string[] = [];
  for (let i = 0; i < M.ASKER_MAX + 1; i++) {
    names.push(nk.accountGetId(nk.addUser("Kid_" + i, TEEN)).user.username);
  }
  const one = fresh();
  for (let i = 0; i < M.ASKER_MAX - 1; i++) {
    assert.equal(ask(one, { action: "start", username: names[i], kind: "phone" }).ok, true);
  }
  let inner: any = null;
  nk.raceOnce("limits/move_ask", () => {
    inner = ask(one, { action: "start", username: names[M.ASKER_MAX - 1], kind: "phone" });
  });
  const outer = ask(one, { action: "start", username: names[M.ASKER_MAX], kind: "phone" });
  assert.equal(inner.ok, true, "the call that wrote first took the last place");
  assert.equal(outer.error, "rate_limited", "the other one read the window again and found it full");
  assert.equal(nk.object("limits", "move_ask", one)!.value.count, M.ASKER_MAX);
});

test("two asks at once for one name can't both pass its last place: one reaches the phone, the other is a decoy", () => {
  const f = family();
  for (let i = 0; i < M.NAME_MAX - 1; i++) {
    ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" });
  }
  const heard = notes(f.child).length;
  let inner: any = null;
  nk.raceOnce("limits/move_name", () => {
    inner = ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" });
  });
  const outer = ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" });
  assert.equal(inner.ok, true);
  assert.equal(outer.ok, true, "it looks the same...");
  assert.equal(notes(f.child).length, heard + 1, "...but only one more ask reached the phone");
  assert.equal(nk.object("limits", "move_name", f.child)!.value.count, M.NAME_MAX);
});

test("a window that keeps changing under an ask is never passed", () => {
  const f = family();
  nk.interfere("limits/move_ask", 10);
  assert.equal(ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" }).error, "rate_limited");
  assert.deepEqual(notes(f.child), []);
});

test("two wrong codes at once both count: the third wrong one still ends the ask", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  const wrong = wrongFor(r.code);
  approve(f.child, { action: "approve", id: r.id, code: wrong });
  let inner: any = null;
  nk.raceOnce("account/move_asks", () => {
    inner = approve(f.child, { action: "approve", id: r.id, code: wrong });
  });
  const outer = approve(f.child, { action: "approve", id: r.id, code: wrong });
  assert.deepEqual(inner, { ok: false, error: "wrong_code", tries_left: 1 });
  assert.deepEqual(outer, { ok: false, error: "ended", why: "wrong_code" }, "re-read and counted on top of the other one");
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: false, error: "ended", why: "wrong_code" });
});

test("a right code whose write never lands approves nothing", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  nk.interfere("account/move_asks", 10);
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: false, error: "server_error" });
  assert.equal(ask(f.asker, { action: "status", id: r.id }).state, "waiting", "not approved");
  assert.deepEqual(notes(f.asker), []);
});

test("two hand-outs at once: both counted, and only the key written last works", () => {
  const f = family();
  const k = approvedKey(f); // hand-out 1
  let inner: any = null;
  nk.raceOnce("account/move_asks", () => {
    inner = ask(f.asker, { action: "status", id: k.id }); // hand-out 2
  });
  const outer = ask(f.asker, { action: "status", id: k.id }); // hand-out 3, after reading the book again
  assert.equal(inner.state, "approved");
  assert.equal(outer.state, "approved");
  const stored = nk.object("account", "move_asks", f.child)!.value.asks.find((a: any) => a.id === k.id);
  assert.equal(stored.handed, 3);
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: inner.key, device_id: NEW_DEVICE }).error, "wrong_key");
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: outer.key, device_id: NEW_DEVICE }).ok, true);
});

test("one key used twice at once: only one device is linked", () => {
  const f = family();
  const sibling = nk.addUser("Bro_9", TEEN);
  const r = ask(sibling, { action: "start", username: "Anna_7", kind: "tablet" });
  approve(f.child, { action: "approve", id: r.id, code: r.code });
  const key = ask(sibling, { action: "status", id: r.id }).key;
  let inner: any = null;
  nk.raceOnce("account/move_asks", () => {
    inner = keySignIn(sibling, { username: "Anna_7", key, device_id: OTHER_DEVICE });
  });
  const outer = keySignIn(sibling, { username: "Anna_7", key, device_id: NEW_DEVICE });
  assert.equal(inner.ok, true);
  assert.deepEqual(outer, { ok: false, error: "wrong_key" }, "the key was used up while this one looked");
  assert.equal(nk.deviceOwner(OTHER_DEVICE), f.child);
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("a key whose use can't be written links nothing", () => {
  const f = family();
  const k = approvedKey(f);
  nk.interfere("account/move_asks", 10);
  assert.equal(keySignIn(f.asker, { username: "Anna_7", key: k.key, device_id: NEW_DEVICE }).error, "server_error");
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("a note that can't be sent (the asker's account went meanwhile) never undoes what was written", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  const send = nk.notificationSend.bind(nk);
  nk.notificationSend = () => {
    throw new Error("user not found");
  };
  assert.deepEqual(approve(f.child, { action: "approve", id: r.id, code: r.code }), { ok: true });
  nk.notificationSend = send;
  assert.equal(ask(f.asker, { action: "status", id: r.id }).state, "approved");
});

test("the move ships off: both RPCs answer not_available and no one-time key signs anyone in", () => {
  const f = family();
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "phone" });
  approve(f.child, { action: "approve", id: r.id, code: r.code });
  const key = ask(f.asker, { action: "status", id: r.id }).key;
  S.MoveRules.ENABLED = false;
  try {
    for (const action of ["start", "status", "cancel"]) {
      assert.deepEqual(ask(f.asker, { action, username: "Anna_7", id: r.id }), { ok: false, error: "not_available" }, action);
    }
    for (const action of ["list", "approve", "decline"]) {
      assert.deepEqual(approve(f.child, { action, id: r.id, code: r.code }), { ok: false, error: "not_available" }, action);
    }
    assert.deepEqual(keySignIn(f.asker, { username: "Anna_7", key, device_id: NEW_DEVICE }), { ok: false, error: "wrong_key" },
      "a key handed out before the switch is no use either");
    assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
  } finally {
    S.MoveRules.ENABLED = true;
  }
});

test("bad requests", () => {
  const f = family();
  assert.equal(ask(f.asker, { action: "what" }).error, "bad_request");
  assert.equal(ask(f.asker, { action: "start", username: 7, kind: "phone" }).error, "no_such_player");
  assert.equal(approve(f.child, { action: "approve", id: "x", code: "123456" }).error, "not_found");
  assert.equal(approve(f.child, { action: "approve", id: 7 }).error, "bad_request");
  assert.equal(approve(f.child, { action: "what" }).error, "bad_request");
  const r = ask(f.asker, { action: "start", username: "Anna_7", kind: "toaster" });
  assert.deepEqual(approve(f.child, { action: "list" }).asks[0].kind, "device");
  assert.equal(approve(f.child, { action: "approve", id: r.id, code: "12" }).error, "wrong_code", "a short code is a wrong one");
  assert.equal(JSON.parse(S.rpcMoveRequest(ctx(""), log, nk, "{}")).error, "not_signed_in");
});

test("deleting the account takes its asks with it", () => {
  const f = family();
  approvedKey(f);
  S.Deletion.run(nk, log, f.child, "test");
  assert.equal(nk.object("account", "move_asks", f.child), undefined);
  assert.equal(nk.object("limits", "move_name", f.child), undefined);
});

test("the module is 0.2.20 and registers move_request and move_approve", () => {
  const registered: string[] = [];
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  for (const id of ["move_request", "move_approve", "sign_in_with_key"]) {
    assert.ok(registered.includes(id), id);
  }
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
