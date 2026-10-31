// The server's economy rules (spec §5.6, §5.11, §17.6; plan M4 Task 8): secret codes redeemed
// once per account with the game's salt and hashes (cases from tests/unit/test_code_rules.gd), the
// wrong-code lock, the Gold Farm by the server's clock, and the wallet award limits.
import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { server } from "./harness.ts";

const S = server();
const C = S.CodeRules;
const F = S.FarmRules;
const W = S.WalletRules;
const sha = (t: string) => createHash("sha256").update(t, "utf8").digest("hex");

// The owner's first code. Like the game's tests, only test files hold it; the module ships its hash.
const FIRST_CODE = "sasa192974";
// sha256("easycraft:codes:v1:5d3f8a61c2" + "abc"), as tests/unit/test_code_rules.gd pins it.
const KNOWN_VECTOR = "8764c42a183660d928b90caff8f0be2a5b9d811dde5df56970079ea15e439208";

function fresh(): any {
  return { redeemed: [], tries: C.emptyTries() };
}

test("codes are trimmed and lowercased; the hash is the game's salted SHA-256", () => {
  assert.equal(C.normalize("  HeLLo2026 \n"), "hello2026");
  assert.equal(C.normalize("\tAbC 12  "), "abc 12");
  assert.equal(C.hashCode("abc", sha), KNOWN_VECTOR);
  assert.equal(C.hashCode("  ABC ", sha), KNOWN_VECTOR);
  assert.equal(C.SALT, "easycraft:codes:v1:5d3f8a61c2");
});

test("only hashes ship, and the first code gives 1,000 Survivor gold", () => {
  for (const key of Object.keys(C.REWARDS)) {
    assert.match(key, /^[0-9a-f]{64}$/);
  }
  assert.deepEqual(C.REWARDS[C.hashCode(FIRST_CODE, sha)], { kind: "gold", amount: 1000 });
});

test("a right code gives its reward once; the hash is kept, never the code", () => {
  const r = C.redeem(fresh(), FIRST_CODE, 0, sha);
  assert.equal(r.status, "accepted");
  assert.deepEqual(r.reward, { kind: "gold", amount: 1000 });
  assert.deepEqual(r.redeemed, [C.hashCode(FIRST_CODE, sha)]);
  const again = C.redeem({ redeemed: r.redeemed, tries: r.tries }, "  " + FIRST_CODE.toUpperCase() + " ", 10, sha);
  assert.equal(again.status, "already_used");
  assert.equal(again.reward, undefined);
});

test("an unknown code changes nothing but the wrong-try count; an empty one is not a try", () => {
  const r = C.redeem(fresh(), "banana", 0, sha);
  assert.equal(r.status, "unknown");
  assert.deepEqual(r.redeemed, []);
  assert.equal(r.tries.wrong, 1);
  let state = fresh();
  for (let i = 0; i < C.MAX_WRONG + 1; i++) {
    const e = C.redeem(state, "   ", i, sha);
    assert.equal(e.status, "empty");
    state = { redeemed: e.redeemed, tries: e.tries };
  }
  assert.equal(state.tries.locked_until, 0);
});

test("five wrong tries lock for 30 seconds, even the right code", () => {
  let state = fresh();
  for (let i = 0; i < C.MAX_WRONG; i++) {
    const r = C.redeem(state, "guess" + i, i, sha);
    state = { redeemed: r.redeemed, tries: r.tries };
  }
  const locked = C.redeem(state, FIRST_CODE, 1000, sha);
  assert.equal(locked.status, "locked");
  assert.equal(locked.wait, 30);
  assert.equal(C.redeem(state, FIRST_CODE, 4 + C.LOCK_MS - 1500, sha).wait, 2, "rounded up");
  assert.equal(C.redeem(state, FIRST_CODE, 4 + C.LOCK_MS, sha).status, "accepted", "30 s after the fifth wrong try");
});

test("repeats are not wrong, and a right code resets the count", () => {
  const first = C.redeem(fresh(), FIRST_CODE, 0, sha);
  let state = { redeemed: first.redeemed, tries: first.tries };
  for (let i = 0; i < C.MAX_WRONG + 2; i++) {
    const r = C.redeem(state, FIRST_CODE, 0, sha);
    state = { redeemed: r.redeemed, tries: r.tries };
  }
  assert.equal(state.tries.wrong, 0);
  assert.equal(state.tries.locked_until, 0);
});

test("a reward the server can't give is not used up; cosmetics are given by the game", () => {
  const table: any = {};
  table[C.hashCode("minus", sha)] = { kind: "gold", amount: -500 };
  table[C.hashCode("test-hat", sha)] = { kind: "cosmetic", item: "hat_crown" };
  const bad = C.redeem(fresh(), "minus", 0, sha, table);
  assert.equal(bad.status, "unknown");
  assert.deepEqual(bad.redeemed, []);
  assert.equal(bad.tries.wrong, 0, "not a wrong guess");
  const hat = C.redeem(fresh(), "test-hat", 0, sha, table);
  assert.equal(hat.status, "accepted");
  assert.deepEqual(hat.reward, { kind: "cosmetic", item: "hat_crown" });
});

test("at most 256 redeemed codes per account", () => {
  const full = { redeemed: Array.from({ length: C.MAX_REDEEMED }, (_: unknown, i: number) => sha("x" + i)), tries: C.emptyTries() };
  assert.equal(C.redeem(full, FIRST_CODE, 0, sha).status, "unknown");
});

test("stored code state is sanitised", () => {
  assert.deepEqual(C.redeemedFrom({ hashes: ["ABC", KNOWN_VECTOR.toUpperCase(), KNOWN_VECTOR, 5] }), [KNOWN_VECTOR]);
  assert.deepEqual(C.triesFrom({ wrong: "x", locked_until: 5 }), { wrong: 0, locked_until: 5 });
  assert.deepEqual(C.triesFrom(undefined), C.emptyTries());
});

// --- the wallet ---

test("the wallet never passes 999,999,999", () => {
  assert.equal(W.KEY, "survivor_gold");
  assert.equal(W.capAdd(10, 25), 25);
  assert.equal(W.capAdd(W.MAX_GOLD - 10, 25), 10);
  assert.equal(W.capAdd(W.MAX_GOLD, 25), 0);
});

test("wallet_award: whole positive amounts up to the per-award limit, scaled by the universe", () => {
  const w = W.emptyWindow();
  assert.equal(W.award(w, 500, 1, 0).credit, 500);
  assert.equal(W.award(w, W.AWARD_MAX_BASE + 1, 1, 0).error, "too_much");
  assert.equal(W.award(w, W.AWARD_MAX_BASE * 4, 3, 0).credit, W.AWARD_MAX_BASE * 4, "universe 3 pays 4x");
  assert.equal(W.award(w, W.AWARD_MAX_BASE * 4, 99, 0).credit, W.AWARD_MAX_BASE * 4, "the universe is clamped, not refused");
  for (const bad of [0, 1.5, "10", null, NaN, Infinity]) {
    assert.equal(W.award(w, bad, 1, 0).error, "bad_request", String(bad));
  }
});

test("wallet_award: at most the hourly limit; the rest of an award that crosses it is dropped", () => {
  let w = W.emptyWindow();
  let total = 0;
  for (let i = 0; total < W.HOUR_MAX_BASE; i++) {
    const r = W.award(w, W.AWARD_MAX_BASE, 1, i * 1000);
    total += r.credit;
    w = r.window;
  }
  assert.equal(total, W.HOUR_MAX_BASE);
  assert.equal(W.award(w, 10, 1, 60_000).error, "limit");
  const later = W.award(w, 10, 1, W.HOUR_MS + 1);
  assert.equal(later.credit, 10, "the first awards left the window");
  const nearlyFull = { awards: [[0, W.HOUR_MAX_BASE - 100]] };
  const r2 = W.award(nearlyFull, W.AWARD_MAX_BASE, 1, 1);
  assert.equal(r2.credit, 100, "partly");
  assert.equal(r2.capped, true);
});

test("wallet_award: a negative amount is a purchase (no limit but the balance)", () => {
  const r = W.award(W.emptyWindow(), -300, 1, 0);
  assert.equal(r.credit, -300);
  assert.equal(r.error, undefined);
});

// M4 Task 10 review C: a modified host could empty a guest's gold with negative wallet_awards.
test("spends another player reports: at most the hour's limit (20,000 x 2^(u-1)), a spend that doesn't fit is refused whole", () => {
  let w = W.emptyWindow();
  for (let i = 0; i < 4; i++) {
    const r = W.spend(w, -5000, 1, i * 1000);
    assert.equal(r.error, undefined);
    w = r.window;
  }
  assert.equal(W.SPEND_HOUR_MAX_BASE, 20000);
  assert.deepEqual(W.spend(w, -1, 1, 60_000).error, "spend_limit");
  assert.deepEqual(W.spend(w, -1, 1, 60_000).window, w, "a refusal counts nothing");
  assert.equal(W.spend(w, -20000, 2, 60_000).error, undefined, "universe 2 allows 40,000");
  assert.equal(W.spend(w, -20001, 2, 60_000).error, "spend_limit");
  assert.equal(W.spend(w, -20000, 1, W.HOUR_MS + 3000).error, undefined, "an hour later the spends left the window");
  assert.deepEqual(W.spend(W.emptyWindow(), -300, 1, 7).window, { awards: [[7, 300]] }, "kept as [ms, gold spent]");
  for (const bad of [0, 5, 1.5, "-10", null]) {
    assert.equal(W.spend(W.emptyWindow(), bad, 1, 0).error, "bad_request", String(bad));
  }
});

test("wallet windows are sanitised", () => {
  assert.deepEqual(W.windowFrom({ awards: [[1, 5], ["x", 2], [3]] }), { awards: [[1, 5]] });
  assert.deepEqual(W.windowFrom(null), W.emptyWindow());
});

// --- the Gold Farm by the server clock ---

test("farm start: rate, universe and cap are checked and clamped", () => {
  assert.deepEqual(F.start({ world: "survivor_u1", rate_per_hour: 60 }, 5000), {
    farm: { started_ms: 5000, rate_per_hour: 60, universe: 1, cap_hours: 12 },
  });
  assert.deepEqual(F.start({ world: "survivor_u2", rate_per_hour: 999999, universe: 99, cap_hours: 99 }, 0).farm,
    { started_ms: 0, rate_per_hour: F.MAX_RATE_PER_HOUR, universe: F.MAX_UNIVERSE, cap_hours: F.MAX_CAP_HOURS });
  for (const bad of [{ rate_per_hour: 60 }, { world: "../x", rate_per_hour: 60 }, { world: "w", rate_per_hour: -1 },
      { world: "w", rate_per_hour: "60" }, { world: "w", rate_per_hour: 60, universe: 0 }, { world: "w", rate_per_hour: 60, cap_hours: 0 }]) {
    assert.deepEqual(F.start(bad, 0), { error: "bad_request" }, JSON.stringify(bad));
  }
});

test("farm earnings: rate x 2^(u-1) for the time away by the server clock, capped", () => {
  const farm = { started_ms: 0, rate_per_hour: 100, universe: 1, cap_hours: 12 };
  assert.deepEqual(F.earned(farm, 30 * 60_000), { earned: 50, away_ms: 30 * 60_000, capped: false });
  assert.deepEqual(F.earned({ ...farm, universe: 3 }, 2 * F.HOUR_MS), { earned: 800, away_ms: 2 * F.HOUR_MS, capped: false });
  assert.deepEqual(F.earned(farm, 20 * F.HOUR_MS), { earned: 1200, away_ms: 20 * F.HOUR_MS, capped: true });
  assert.deepEqual(F.earned(farm, -5000), { earned: 0, away_ms: 0, capped: false }, "a clock that went back earns nothing");
});

// M4 Task 10 review D: farm clocks were unlimited in number (any world key made a new one).
test("farm start: at most 20 farm clocks per player; one already there may start again", () => {
  assert.equal(F.MAX_FARMS, 20);
  assert.equal(F.startRefusal(false, 19), null);
  assert.equal(F.startRefusal(false, 20), "too_many_farms");
  assert.equal(F.startRefusal(false, 150), "too_many_farms");
  assert.equal(F.startRefusal(true, 20), null, "the same world's clock is started again, not a new one");
});

test("stored farms are sanitised", () => {
  assert.equal(F.farmFrom(undefined), null);
  assert.equal(F.farmFrom({ started_ms: "x" }), null);
  assert.deepEqual(F.farmFrom({ started_ms: 1, rate_per_hour: 5000000, universe: 2, cap_hours: 12 }),
    { started_ms: 1, rate_per_hour: F.MAX_RATE_PER_HOUR, universe: 2, cap_hours: 12 });
});
