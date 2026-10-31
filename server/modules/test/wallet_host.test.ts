// M4 Wave 2, agent F (spec §17.1, §17.6; the lead's review): in an online world the host's game
// decides gold (§7.3) but the server keeps each player's balance. The host reads a guest's starting
// gold from the server (get_gold_of) instead of trusting the guest's own word, and reports every
// change of any player in its match through wallet_award ("user_id" + "match_id"); the server's
// limits apply per player. Nobody else may read or change another player's gold.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const TEEN = A.defaults("13_plus");

let nk: FakeNakama;
let log: FakeLogger;
let now = 7_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 7_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function gold(userId: string): number {
  return nk.users.get(userId)!.wallet.survivor_gold || 0;
}

// A host in its relayed match (the after-create hook's record) with a guest who joined.
function hosted(guestGold = 300): { host: string; guest: string; match: string } {
  const host = nk.addUser("Hostie", TEEN, { survivor_gold: 50 });
  const guest = nk.addUser("Guesty", TEEN, { survivor_gold: guestGold });
  const match = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: match, self: { userId: host } } }, { matchCreate: {} });
  nk.joinMatch(match, guest);
  return { host, guest, match };
}

test("get_gold_of: the host reads a guest's gold from the server; the guest's own word is not needed", () => {
  const { host, guest, match } = hosted(300);
  assert.deepEqual(call("rpcGetGoldOf", host, { user_id: guest, match_id: match }), { ok: true, user_id: guest, gold: 300 });
  assert.deepEqual(call("rpcGetGoldOf", guest, {}), { ok: true, user_id: guest, gold: 300 }, "everyone may read their own");
});

test("get_gold_of: only the host of a match the player is in", () => {
  const { host, guest, match } = hosted();
  const stranger = nk.addUser("Strngr", TEEN, { survivor_gold: 9 });
  assert.deepEqual(call("rpcGetGoldOf", guest, { user_id: host, match_id: match }), { ok: false, error: "not_host" });
  assert.deepEqual(call("rpcGetGoldOf", host, { user_id: stranger, match_id: match }), { ok: false, error: "not_in_match" });
  const other = nk.createMatch(stranger);
  assert.deepEqual(call("rpcGetGoldOf", host, { user_id: guest, match_id: other }), { ok: false, error: "not_host" });
  assert.deepEqual(call("rpcGetGoldOf", host, { user_id: "nope", match_id: match }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcGetGoldOf", host, { user_id: guest }), { ok: false, error: "bad_request" });
});

test("wallet_award: the host reports a guest's gold (earned and spent), with the guest's own limits", () => {
  const { host, guest, match } = hosted(300);
  const r = call("rpcWalletAward", host, { amount: 40, reason: "wave", user_id: guest, match_id: match });
  assert.deepEqual(r, { ok: true, credited: 40, capped: false, gold: 340 });
  assert.equal(gold(guest), 340);
  assert.equal(gold(host), 50, "the host's own gold is untouched");
  assert.equal(nk.ledger[nk.ledger.length - 1].metadata.by, host, "the ledger says who reported it");
  assert.equal(call("rpcWalletAward", host, { amount: -100, reason: "shop", user_id: guest, match_id: match }).gold, 240);
  assert.deepEqual(call("rpcWalletAward", host, { amount: -1000, user_id: guest, match_id: match }),
    { ok: false, error: "not_enough_gold", gold: 240 });
  for (let i = 0; i < 10; i++) {
    call("rpcWalletAward", host, { amount: 2000, user_id: guest, match_id: match });
  }
  assert.equal(call("rpcWalletAward", host, { amount: 10, user_id: guest, match_id: match }).error, "limit",
    "the hour's limit is the guest's");
  assert.equal(call("rpcWalletAward", host, { amount: 10 }).ok, true, "the host's own limit is its own");
});

test("wallet_award: only the host may report for another player, only for players in its match", () => {
  const { host, guest, match } = hosted();
  const stranger = nk.addUser("Strngr", TEEN);
  assert.equal(call("rpcWalletAward", guest, { amount: 10, user_id: host, match_id: match }).error, "not_host");
  assert.equal(call("rpcWalletAward", host, { amount: 10, user_id: stranger, match_id: match }).error, "not_in_match");
  nk.leaveMatch(match, guest);
  assert.equal(call("rpcWalletAward", host, { amount: 10, user_id: guest, match_id: match }).error, "not_in_match",
    "a guest who left");
  assert.equal(call("rpcWalletAward", host, { amount: 10, user_id: host, match_id: match }).credited, 10, "itself: as before");
});

// M4 Task 10 review C: a modified host could empty a guest's server gold with negative awards.
test("wallet_award: spends a host reports for a guest are limited per hour (limits/wallet_spent); the guest's own are not", () => {
  const { host, guest, match } = hosted(100_000);
  for (let i = 0; i < 4; i++) {
    assert.equal(call("rpcWalletAward", host, { amount: -5000, reason: "shop", user_id: guest, match_id: match }).ok, true);
    now += 1000;
  }
  assert.equal(gold(guest), 80_000);
  assert.deepEqual(call("rpcWalletAward", host, { amount: -1, user_id: guest, match_id: match }),
    { ok: false, error: "spend_limit" });
  assert.equal(gold(guest), 80_000, "nothing more went");
  const w = nk.object("limits", "wallet_spent", guest)!;
  assert.equal(w.permissionRead, 0, "server only");
  assert.equal(w.permissionWrite, 0);
  assert.equal(nk.object("limits", "wallet_spent", host), undefined, "the window is the guest's");
  assert.equal(call("rpcWalletAward", guest, { amount: -30_000, reason: "shop" }).ok, true, "a player's own spends are their own");
  assert.equal(call("rpcWalletAward", host, { amount: -20_000, universe: 2, user_id: guest, match_id: match }).ok, true,
    "universe 2 allows twice as much");
  assert.equal(call("rpcWalletAward", host, { amount: 40, user_id: guest, match_id: match }).ok, true,
    "earning is not held back by spending");
  now += 60 * 60 * 1000;
  assert.equal(call("rpcWalletAward", host, { amount: -5000, user_id: guest, match_id: match }).ok, true, "an hour later");
  assert.equal(gold(guest), 25_040);
});

test("wallet_award: a spend over the guest's gold counts nothing against the window", () => {
  const { host, guest, match } = hosted(1000);
  assert.deepEqual(call("rpcWalletAward", host, { amount: -5000, user_id: guest, match_id: match }),
    { ok: false, error: "not_enough_gold", gold: 1000 });
  assert.equal(nk.object("limits", "wallet_spent", guest), undefined);
});

test("the module is 0.2.12 (0.2.11 or later)", () => {
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
