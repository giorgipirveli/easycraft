// Throwaway adversarial checks for owner #99 (review only; not part of the project).
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const M = S.MoveRules;
const TEEN = A.defaults("13_plus");
const ATTACKER_DEVICE = "attacker-dev-000000000001";
const LEGIT_DEVICE = "legit-newdev-000000000001";

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
  A.ageRules = true;
});

const ask = (u: string, p: object): any => JSON.parse(S.rpcMoveRequest(ctx(u), log, nk, JSON.stringify(p)));
const appr = (u: string, p: object): any => JSON.parse(S.rpcMoveApprove(ctx(u), log, nk, JSON.stringify(p)));
const keyIn = (u: string, p: object): any => JSON.parse(S.rpcSignInWithKey(ctx(u), log, nk, JSON.stringify(p)));
const acctKey = (u: string, p: object): any => JSON.parse(S.rpcAccountKey(ctx(u), log, nk, JSON.stringify(p)));
const notes = (u: string): any[] => nk.notifications.filter((x) => x.userId === u && x.code === 110);

function fresh(): string {
  const id = nk.addUser("x" + ++n + "Rq2w", {});
  nk.linkDevice(id, "fresh-device-" + n + "-000");
  return id;
}

function anna(): string {
  const child = nk.addUser("Anna_7", TEEN);
  nk.linkDevice(child, "phone-device-0001");
  return child;
}

test("R1 chat (as shipped: no age rules) lets a 6-digit code through, in every common spelling", () => {
  A.ageRules = false;
  for (const t of ["type 482913 on the card", "482 913", "4 8 2 9 1 3", "code: 482-913 for free gold"]) {
    assert.deepEqual(S.ChatRules.check(t, "under_13"), { text: t }, t);
  }
  assert.equal(S.ChatRules.check("4829135", "under_13").error, "personal_info", "7 digits are caught");
});

test("R2 one approval of a stranger's code = full takeover: the stranger signs the child's phone out of her own account", () => {
  const child = anna();
  const stranger = fresh();
  const r = ask(stranger, { action: "start", username: "anna_7", kind: "phone" }); // kind is the stranger's choice
  assert.equal(r.ok, true);
  // the child types the code the stranger told her (the server has no notion of the parent gate)
  assert.deepEqual(appr(child, { action: "approve", id: r.id, code: r.code }), { ok: true });
  const st = ask(stranger, { action: "status", id: r.id });
  assert.equal(st.state, "approved");
  assert.equal(keyIn(stranger, { username: "Anna_7", key: st.key, device_id: ATTACKER_DEVICE }).ok, true);
  assert.equal(nk.deviceOwner(ATTACKER_DEVICE), child);
  // now signed in as Anna on the stranger's device, with a raw RPC (no game UI, no gate)
  const out = acctKey(child, { action: "sign_out_others", device_id: ATTACKER_DEVICE });
  assert.equal(out.ok, true, JSON.stringify(out));
  assert.equal(nk.deviceOwner("phone-device-0001"), undefined, "the child's phone is no longer a device of her account");
  const k = acctKey(child, { action: "new" });
  assert.equal(k.ok, true, "and the stranger keeps a way back in");
});

test("R3 a stranger with 4 throwaway accounts keeps a name's window full: the family's own ask is a decoy, all day", () => {
  const child = anna();
  const strangers = [fresh(), fresh(), fresh(), fresh()];
  let cards = 0;
  let legitDecoys = 0;
  for (let w = 0; w < 4 * 6; w++) { // 6 hours, 15-minute windows
    for (let i = 0; i < M.NAME_MAX; i++) {
      const s = strangers[(w * M.NAME_MAX + i) % strangers.length];
      const r = ask(s, { action: "start", username: "Anna_7", kind: "phone" });
      assert.equal(r.ok, true, JSON.stringify(r));
    }
    const before = notes(child).length;
    const legit = fresh();
    const r = ask(legit, { action: "start", username: "Anna_7", kind: "computer" });
    assert.equal(r.ok, true);
    if (notes(child).length === before) {
      legitDecoys++;
    }
    now += M.NAME_WINDOW_MS;
  }
  cards = notes(child).length;
  assert.equal(legitDecoys, 24, "every one of the family's asks was a decoy (nothing reached the phone)");
  assert.equal(cards, 24 * M.NAME_MAX, "the stranger's asks did reach the phone: 20 cards an hour");
});

test("R4 three stranger asks after the family's push it out (replaced); the family's device still says waiting", () => {
  const child = anna();
  const legit = fresh();
  const mine = ask(legit, { action: "start", username: "Anna_7", kind: "computer" });
  for (let i = 0; i < M.OPEN_MAX; i++) {
    now += 1000;
    ask(fresh(), { action: "start", username: "Anna_7", kind: "phone" });
  }
  const list = appr(child, { action: "list" });
  assert.ok(!list.asks.some((a: any) => a.id === mine.id), "the family's ask is gone from the phone's card");
  assert.equal(ask(legit, { action: "status", id: mine.id }).state, "waiting");
  // the right code typed for it now: ended
  assert.equal(appr(child, { action: "approve", id: mine.id, code: mine.code }).error, "ended");
});

test("R5 a stranger locks the name's key sign-in: the family's approved one-time key is refused (locked)", () => {
  const child = anna();
  const legit = fresh();
  const r = ask(legit, { action: "start", username: "Anna_7", kind: "computer" });
  appr(child, { action: "approve", id: r.id, code: r.code });
  const key = ask(legit, { action: "status", id: r.id }).key;
  const stranger = fresh();
  for (let i = 0; i < 5; i++) {
    keyIn(stranger, { username: "Anna_7", key: "AAAA-AAAA", device_id: "strdev-0000000000" + i });
  }
  const out = keyIn(legit, { username: "Anna_7", key, device_id: LEGIT_DEVICE });
  assert.equal(out.error, "locked", JSON.stringify(out));
  now += 15 * 60 * 1000; // the lock outlives the key (KEY_MS 5 min)
  assert.equal(keyIn(legit, { username: "Anna_7", key, device_id: LEGIT_DEVICE }).error, "wrong_key");
});

test("R6 an ended ask stays in storage for good when nothing writes the book again (KEEP_MS is only applied on a write)", () => {
  const child = anna();
  const asker = fresh();
  const r = ask(asker, { action: "start", username: "Anna_7", kind: "computer" });
  appr(child, { action: "decline", id: r.id });
  now += 90 * 24 * 3600 * 1000;
  appr(child, { action: "list" }); // every sign-in of the phone
  const stored = nk.object("account", "move_asks", child)!;
  assert.equal(stored.value.asks.length, 1, "still kept 90 days later");
  assert.equal(stored.value.asks[0].from, asker);
  assert.match(stored.value.asks[0].code, /^[0-9]{6}$/);
});

test("R7 deleting the asking account leaves its id (and its code) in the child's book", () => {
  const child = anna();
  const asker = fresh();
  ask(asker, { action: "start", username: "Anna_7", kind: "computer" });
  S.Deletion.run(nk, log, asker, "test");
  const stored = nk.object("account", "move_asks", child)!;
  assert.equal(stored.value.asks[0].from, asker, "the deleted account's id stays in another account's storage");
});

test("R8 deleting the child's account leaves its id in the stranger's move_asked", () => {
  const child = anna();
  const asker = nk.addUser("Bob_9", TEEN); // a claimed asker that is never deleted by a move
  ask(asker, { action: "start", username: "Anna_7", kind: "computer" });
  S.Deletion.run(nk, log, child, "test");
  const stored = nk.object("account", "move_asked", asker)!;
  assert.equal(stored.value.target, child);
});

test("R9 a lost sign_in_with_key answer: the key is spent, the device is linked, the asker deleted; a retry is wrong_key", () => {
  const child = anna();
  const asker = fresh();
  const r = ask(asker, { action: "start", username: "Anna_7", kind: "computer" });
  appr(child, { action: "approve", id: r.id, code: r.code });
  const key = ask(asker, { action: "status", id: r.id }).key;
  const first = keyIn(asker, { username: "Anna_7", key, device_id: LEGIT_DEVICE });
  assert.equal(first.left, "deleted");
  // the answer never reached the game; it tries again with a new device id (the old session's account is gone)
  const again = JSON.parse(S.rpcSignInWithKey(ctx(asker), log, nk, JSON.stringify({ username: "Anna_7", key, device_id: "retry-device-000001" })));
  assert.notEqual(again.ok, true);
});
