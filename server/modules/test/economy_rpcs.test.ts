// redeem_code, farm_collect and wallet_award against the fake Nakama (spec §5.6, §5.11, §17.6):
// the wallet ledger holds Survivor gold, codes work once per account, the farm pays by the
// server's clock, and the host's awards are limited.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash

let nk: FakeNakama;
let log: FakeLogger;
let now = 3_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 3_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function gold(userId: string): number {
  return nk.users.get(userId)!.wallet.survivor_gold || 0;
}

test("redeem_code: the first code gives 1,000 gold into the wallet ledger, once per account", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: 25 });
  const r = call("rpcRedeemCode", me, { code: "  SASA192974 " });
  assert.deepEqual(r, { ok: true, status: "accepted", reward: { kind: "gold", amount: 1000 }, gold: 1025 });
  assert.equal(gold(me), 1025);
  assert.equal(nk.ledger.length, 1);
  assert.equal(nk.ledger[0].metadata.source, "code");
  const stored = nk.object("codes", "redeemed", me)!;
  assert.equal(stored.permissionWrite, 0);
  assert.ok(!JSON.stringify(stored.value).includes(FIRST_CODE), "the hash is kept, never the code");
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }),
    { ok: false, error: "already_used", paid: { gold: 1000, at_ms: now } }, "0.2.19: what the server paid, and when");
  assert.equal(gold(me), 1025, "no second payout");
  const other = nk.addUser("Other");
  assert.equal(call("rpcRedeemCode", other, { code: FIRST_CODE }).gold, 1000, "another account may use it");
});

test("redeem_code: wrong codes, the lock, and bad payloads", () => {
  const me = nk.addUser("Me_1");
  assert.deepEqual(call("rpcRedeemCode", me, { code: "banana" }), { ok: false, error: "unknown" });
  assert.deepEqual(call("rpcRedeemCode", me, { code: "  " }), { ok: false, error: "empty" });
  assert.deepEqual(call("rpcRedeemCode", me, { code: 5 }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcRedeemCode", me, {}), { ok: false, error: "bad_request" });
  for (let i = 0; i < 4; i++) {
    call("rpcRedeemCode", me, { code: "guess" + i });
  }
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }), { ok: false, error: "locked", wait: 30 });
  now += 30_000;
  assert.equal(call("rpcRedeemCode", me, { code: FIRST_CODE }).status, "accepted");
});

test("redeem_code: two redemptions at the same moment pay once (the redeemed list is written first, by version)", () => {
  const me = nk.addUser("Me_1");
  const realWrite = nk.storageWrite.bind(nk);
  let raced = false;
  nk.storageWrite = (writes: any[]) => {
    if (!raced && writes[0].collection === "codes" && writes[0].key === "redeemed") {
      raced = true; // another call redeems between our read and our write
      assert.equal(JSON.parse(S.rpcRedeemCode(ctx(me), log, nk, JSON.stringify({ code: FIRST_CODE }))).status, "accepted");
    }
    return realWrite(writes);
  };
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }),
    { ok: false, error: "already_used", paid: { gold: 1000, at_ms: now } }, "the other call paid it");
  assert.equal(gold(me), 1000);
});

test("farm_collect: start, then collect by the server's clock (the phone's clock is never asked)", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: 10 });
  const started = call("rpcFarmCollect", me, { action: "start", world: "survivor_u1", rate_per_hour: 100, universe: 2, phone_time_ms: 9e15 });
  assert.deepEqual(started, { ok: true, started_ms: now, rate_per_hour: 100, universe: 2, cap_hours: 12 });
  const rec = nk.object("farm", "survivor_u1", me)!;
  assert.equal(rec.permissionWrite, 0);
  now += 3 * 60 * 60 * 1000;
  assert.deepEqual(call("rpcFarmCollect", me, { action: "peek", world: "survivor_u1" }),
    { ok: true, earned: 600, away_ms: 3 * 60 * 60 * 1000, capped: false });
  const got = call("rpcFarmCollect", me, { action: "collect", world: "survivor_u1" });
  assert.deepEqual(got, { ok: true, earned: 600, away_ms: 3 * 60 * 60 * 1000, capped: false, gold: 610 });
  assert.equal(gold(me), 610);
  assert.equal(nk.ledger.at(-1).metadata.source, "farm");
  assert.equal(nk.object("farm", "survivor_u1", me), undefined, "collected: the farm starts again only with a new start");
  assert.deepEqual(call("rpcFarmCollect", me, { action: "collect", world: "survivor_u1" }), { ok: false, error: "not_started" });
});

test("farm_collect: 12 hours at most, and bad requests", () => {
  const me = nk.addUser("Me_1");
  call("rpcFarmCollect", me, { action: "start", world: "w1", rate_per_hour: 10 });
  now += 100 * 60 * 60 * 1000;
  assert.equal(call("rpcFarmCollect", me, { action: "collect", world: "w1" }).earned, 120);
  assert.deepEqual(call("rpcFarmCollect", me, { action: "dance", world: "w1" }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcFarmCollect", me, { action: "start", world: "w 1", rate_per_hour: 10 }), { ok: false, error: "bad_request" });
});

// M4 Task 10 review D: any world key made a new farm clock, each paying for 24 h.
test("farm_collect: at most 20 farm clocks per player; one already there starts again, a collected one frees its place", () => {
  const me = nk.addUser("Me_1");
  for (let i = 0; i < 20; i++) {
    assert.equal(call("rpcFarmCollect", me, { action: "start", world: "w" + i, rate_per_hour: 10 }).ok, true, "farm " + i);
  }
  assert.deepEqual(call("rpcFarmCollect", me, { action: "start", world: "w20", rate_per_hour: 10 }), { ok: false, error: "too_many_farms" });
  assert.equal(nk.object("farm", "w20", me), undefined);
  now += 60 * 60 * 1000;
  assert.equal(call("rpcFarmCollect", me, { action: "start", world: "w3", rate_per_hour: 10 }).ok, true, "the same world again");
  assert.equal(call("rpcFarmCollect", me, { action: "collect", world: "w5" }).ok, true);
  assert.equal(call("rpcFarmCollect", me, { action: "start", world: "w20", rate_per_hour: 10 }).ok, true, "a place came free");
  const other = nk.addUser("Other");
  assert.equal(call("rpcFarmCollect", other, { action: "start", world: "w0", rate_per_hour: 10 }).ok, true, "each player has their own 20");
});

test("wallet_award: the host reports gold it gave; the wallet and ledger follow", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: 25 });
  assert.deepEqual(call("rpcWalletAward", me, { amount: 120, reason: "wave", universe: 1 }),
    { ok: true, credited: 120, capped: false, gold: 145 });
  assert.equal(nk.ledger.at(-1).metadata.source, "award");
  assert.equal(nk.ledger.at(-1).metadata.reason, "wave");
  assert.deepEqual(call("rpcWalletAward", me, { amount: -45, reason: "shop" }), { ok: true, credited: -45, capped: false, gold: 100 });
  assert.deepEqual(call("rpcWalletAward", me, { amount: -500, reason: "shop" }), { ok: false, error: "not_enough_gold", gold: 100 });
  assert.deepEqual(call("rpcWalletAward", me, { amount: 999999 }), { ok: false, error: "too_much" });
  assert.deepEqual(call("rpcWalletAward", me, { amount: "5" }), { ok: false, error: "bad_request" });
  assert.equal(call("rpcWalletAward", me, { amount: 10, reason: "made up" }).ok, true, "an unknown reason is 'other'");
  assert.equal(nk.ledger.at(-1).metadata.reason, "other");
});

test("wallet_award: the hourly limit is kept across calls", () => {
  const me = nk.addUser("Me_1");
  let total = 0;
  for (let i = 0; i < 20; i++) {
    const r = call("rpcWalletAward", me, { amount: S.WalletRules.AWARD_MAX_BASE, reason: "boss" });
    if (!r.ok) {
      assert.equal(r.error, "limit");
      break;
    }
    total += r.credited;
    now += 1000;
  }
  assert.equal(total, S.WalletRules.HOUR_MAX_BASE);
  assert.equal(gold(me), S.WalletRules.HOUR_MAX_BASE);
});

test("wallet_award: the wallet never passes its cap", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: S.WalletRules.MAX_GOLD - 5 });
  assert.deepEqual(call("rpcWalletAward", me, { amount: 50 }), { ok: true, credited: 5, capped: true, gold: S.WalletRules.MAX_GOLD });
});
