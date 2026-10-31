// The gold-double bug's two leftovers (module 0.2.19; docs/devlog/parts/gold-double.md), against the fake Nakama:
// 1. A code's answer lost on the network: the server remembers that IT paid a code (codes/redeemed's "paid"), so a
//    retry answers "already used: paid N gold at T", and the codes a phone records after paying them itself learn
//    which of them the server had already paid (the phone then never reports that gold as its own).
// 2. The host's last batch for a guest who has just left (or after the host closed its world): a report with a "seq"
//    (the host's count of that guest's gold moves) is still taken for the match the server saw the guest in, and the
//    server keeps the last seq it heard (limits/wallet_hosted), which the guest's game reads (get_account_state's
//    "hosted") before it trusts the wallet after an online world.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const TEEN = A.defaults("13_plus");
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash
const FIRST_CODE_HASH = "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a";
const HERO_CODE_HASH = "8e79f20f226bca770f874899b8857906d11b6384903e2336272dbe3f89895885"; // a cosmetic

let nk: FakeNakama;
let log: FakeLogger;
let now = 5_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 5_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

function gold(userId: string): number {
  return nk.users.get(userId)!.wallet.survivor_gold || 0;
}

// --- 1. Codes: what the server paid itself ---

test("redeem_code: asking again for a code the server paid answers already_used with the gold and when", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: 25 });
  assert.equal(call("rpcRedeemCode", me, { code: FIRST_CODE }).status, "accepted");
  const paidAt = now;
  now += 7000; // the answer was lost; the phone asks again
  assert.deepEqual(call("rpcRedeemCode", me, { code: " " + FIRST_CODE.toUpperCase() }),
    { ok: false, error: "already_used", paid: { gold: 1000, at_ms: paidAt } });
  assert.equal(gold(me), 1025, "never paid twice");
  const stored = nk.object("codes", "redeemed", me)!;
  assert.deepEqual(stored.value.paid, { [FIRST_CODE_HASH]: { gold: 1000, at_ms: paidAt } });
  assert.equal(stored.permissionWrite, 0, "the game can't write it");
});

test("redeem_code: a code a phone recorded (it paid it itself) is used, but the server never paid it", () => {
  const me = nk.addUser("Me_1");
  assert.deepEqual(call("rpcRedeemCode", me, { hashes: [FIRST_CODE_HASH] }),
    { ok: true, status: "recorded", recorded: 1, already: 0, gold: 0, paid: [] });
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }), { ok: false, error: "already_used" },
    "no paid: the phone's own gold");
  assert.equal(gold(me), 0);
});

test("redeem_code with hashes: answers which of them the server paid itself, and keeps them paid", () => {
  const me = nk.addUser("Me_1", {}, { survivor_gold: 25 });
  assert.equal(call("rpcRedeemCode", me, { code: FIRST_CODE }).status, "accepted");
  const paidAt = now;
  now += 60_000;
  // The phone lost that answer, paid the code itself, and now tells the server what it paid (and a cosmetic code).
  const r = call("rpcRedeemCode", me, { hashes: [FIRST_CODE_HASH, HERO_CODE_HASH, FIRST_CODE_HASH, "0".repeat(64)] });
  assert.deepEqual(r, { ok: true, status: "recorded", recorded: 1, already: 1, gold: 1025,
    paid: [{ hash: FIRST_CODE_HASH, gold: 1000, at_ms: paidAt }] });
  assert.equal(gold(me), 1025, "recording never pays");
  const stored = nk.object("codes", "redeemed", me)!;
  assert.deepEqual(stored.value.hashes, [FIRST_CODE_HASH, HERO_CODE_HASH]);
  assert.deepEqual(stored.value.paid, { [FIRST_CODE_HASH]: { gold: 1000, at_ms: paidAt } }, "the record kept what was paid");
  assert.deepEqual(call("rpcRedeemCode", me, { code: FIRST_CODE }).paid, { gold: 1000, at_ms: paidAt });
});

test("redeem_code with hashes: a cosmetic code recorded again is already used, never paid", () => {
  const me = nk.addUser("Me_1");
  const table = S.CodeRules.REWARDS;
  assert.equal(table[HERO_CODE_HASH].kind, "cosmetic");
  call("rpcRedeemCode", me, { hashes: [HERO_CODE_HASH] });
  assert.deepEqual(call("rpcRedeemCode", me, { hashes: [HERO_CODE_HASH] }),
    { ok: true, status: "recorded", recorded: 0, already: 1, gold: 0, paid: [] });
});

test("CodeRules.paidFrom: only known-looking hashes with whole gold and times; anything else is dropped", () => {
  const C = S.CodeRules;
  assert.deepEqual(C.paidFrom(undefined), {});
  assert.deepEqual(C.paidFrom({ paid: "x" }), {});
  assert.deepEqual(C.paidFrom({ paid: { [FIRST_CODE_HASH]: { gold: 1000, at_ms: 5 }, nothash: { gold: 1, at_ms: 1 },
    ["b".repeat(64)]: { gold: -1, at_ms: 1 }, ["c".repeat(64)]: { gold: 1.5, at_ms: 1 }, ["d".repeat(64)]: "x" } }),
  { [FIRST_CODE_HASH]: { gold: 1000, at_ms: 5 } });
  assert.deepEqual(C.paidList({ [FIRST_CODE_HASH]: { gold: 1000, at_ms: 5 } }, [FIRST_CODE_HASH, FIRST_CODE_HASH, "e", 7]),
    [{ hash: FIRST_CODE_HASH, gold: 1000, at_ms: 5 }]);
});

// --- 2. The host's last report for a guest ---

// A host in its relayed match (the after-create hook's record) with a guest who joined and whose gold the host read
// (get_gold_of: the server saw the guest in this match).
function hosted(guestGold = 300): { host: string; guest: string; match: string } {
  const host = nk.addUser("Hostie", TEEN, { survivor_gold: 50 });
  const guest = nk.addUser("Guesty", TEEN, { survivor_gold: guestGold });
  const match = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: match, self: { userId: host } } }, { matchCreate: {} });
  nk.joinMatch(match, guest);
  assert.equal(call("rpcGetGoldOf", host, { user_id: guest, match_id: match }).gold, guestGold);
  return { host, guest, match };
}

function award(host: string, guest: string, match: string, amount: number, seq?: number): any {
  const p: any = { amount: amount, reason: "wave", user_id: guest, match_id: match };
  if (seq !== undefined) {
    p.seq = seq;
  }
  return call("rpcWalletAward", host, p);
}

test("wallet_award with a seq: the server keeps the host's last word for that guest; get_account_state tells it", () => {
  const { host, guest, match } = hosted(300);
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 0 }, "seen in the match, nothing reported");
  assert.deepEqual(award(host, guest, match, 40, 1), { ok: true, credited: 40, capped: false, gold: 340, seq: 1 });
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 1 });
  assert.equal(award(host, guest, match, -10, 3).gold, 330);
  assert.equal(award(host, guest, match, 5, 2).ok, true, "a late piece still pays");
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 3 }, "never back");
  assert.equal(call("rpcGetAccountState", host).hosted, null, "nobody reported for the host");
  const o = nk.object("limits", "wallet_hosted", guest)!;
  assert.equal(o.permissionRead, 0, "server only");
  assert.equal(o.permissionWrite, 0);
  assert.deepEqual(award(host, guest, match, 10), { ok: true, credited: 10, capped: false, gold: 345 }, "without a seq: as before");
});

test("wallet_award: a seq-only report (amount 0) moves no gold; amount 0 without a seq is still bad", () => {
  const { host, guest, match } = hosted(300);
  const before = nk.ledger.length;
  assert.deepEqual(award(host, guest, match, 0, 4), { ok: true, credited: 0, capped: false, gold: 300, seq: 4 });
  assert.equal(nk.ledger.length, before, "nothing on the ledger");
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 4 });
  assert.deepEqual(award(host, guest, match, 0), { ok: false, error: "bad_request" });
  assert.deepEqual(award(host, guest, match, 5, 0), { ok: false, error: "bad_request" }, "a seq is a whole number from 1");
  assert.deepEqual(award(host, guest, match, 5, 1.5), { ok: false, error: "bad_request" });
});

test("wallet_award: a report the rules refuse is still the host's word (its seq counts)", () => {
  const { host, guest, match } = hosted(10);
  assert.deepEqual(award(host, guest, match, -50, 2), { ok: false, error: "not_enough_gold", gold: 10 });
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 2 });
  assert.equal(award(host, guest, match, 99_999, 3).error, "too_much");
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 3 });
});

test("wallet_award: the host's last batch for a guest who just left is taken (with a seq), also after the host left", () => {
  const { host, guest, match } = hosted(300);
  nk.leaveMatch(match, guest);
  assert.deepEqual(award(host, guest, match, 10), { ok: false, error: "not_in_match" }, "an older host's report: as before");
  assert.deepEqual(award(host, guest, match, 25, 5), { ok: true, credited: 25, capped: false, gold: 325, seq: 5 });
  nk.leaveMatch(match, host); // the host closed its world: its game sends what it still holds
  assert.deepEqual(award(host, guest, match, -5, 6), { ok: true, credited: -5, capped: false, gold: 320, seq: 6 });
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 6 });
  assert.equal(nk.ledger[nk.ledger.length - 1].metadata.by, host);
});

test("wallet_award: late reports only for the match the server saw the guest in, from its host, within a day", () => {
  const { host, guest, match } = hosted(300);
  const stranger = nk.addUser("Strngr", TEEN);
  nk.leaveMatch(match, guest);
  assert.equal(call("rpcWalletAward", stranger, { amount: 5, user_id: guest, match_id: match, seq: 9 }).error, "not_host");
  // Never seen: a guest who left before the host read its gold.
  const quick = nk.addUser("Quick", TEEN);
  assert.equal(award(host, quick, match, 5, 1).error, "not_in_match");
  // Seen in another host's match since: that host's word is the one that counts now.
  const other = nk.addUser("Other", TEEN);
  const match2 = nk.createMatch(other);
  S.afterMatchCreate(ctx(other), log, nk, { match: { matchId: match2, self: { userId: other } } }, { matchCreate: {} });
  nk.joinMatch(match2, guest);
  assert.equal(call("rpcGetGoldOf", other, { user_id: guest, match_id: match2 }).ok, true);
  assert.equal(award(host, guest, match, 5, 7).error, "not_in_match");
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match2, seq: 0 });
  // A day after the server last saw the guest in a match: no more late reports.
  nk.leaveMatch(match2, guest);
  now += 24 * 60 * 60 * 1000 + 1;
  assert.equal(award(other, guest, match2, 5, 1).error, "not_in_match");
  assert.equal(gold(guest), 300);
});

test("wallet_award: a host that made a new match reports no more for its old one", () => {
  const { host, guest, match } = hosted(300);
  nk.leaveMatch(match, guest);
  nk.leaveMatch(match, host);
  const next = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: next, self: { userId: host } } }, { matchCreate: {} });
  assert.equal(award(host, guest, match, 5, 2).error, "not_host");
});

test("get_gold_of again in the same match (a guest back in) keeps the seq", () => {
  const { host, guest, match } = hosted(300);
  award(host, guest, match, 1, 4);
  assert.equal(call("rpcGetGoldOf", host, { user_id: guest, match_id: match }).ok, true, "the guest came back");
  assert.deepEqual(call("rpcGetAccountState", guest).hosted, { match_id: match, seq: 4 });
});

test("the module is 0.2.20", () => {
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
