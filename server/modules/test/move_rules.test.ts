// Owner #99 (module 0.2.20; spec §5.13 "As built (owner #99)"): moving a game to another device with proof, never by
// the name alone. The pure rules: the 6-digit code, the ask's life (5 minutes, three wrong codes, at most three open
// for one account), the rate windows, and what each side is told.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const M = S.MoveRules;
const NOW = 1_790_000_000_000;

function ask(over: object = {}): any {
  return { id: "a1", from: "asker-1", kind: "computer", code: "123456", made_ms: NOW, state: M.OPEN, wrong: 0, why: "",
    approved_ms: 0, handed: 0, key_hash: "", ...over };
}

test("a code is six digits from the server's randomness, zeros kept", () => {
  assert.equal(M.codeFromHex("00000000ffff"), "000000");
  assert.equal(M.codeFromHex("000f4240"), "000000", "1,000,000 wraps round");
  assert.equal(M.codeFromHex("0001e240"), "123456");
  assert.equal(M.codeFromHex("ffffffff"), "967295");
  for (const bad of ["", "abc", "zzzzzzzz", 12 as any, null as any]) {
    assert.equal(M.codeFromHex(bad), "", String(bad));
  }
  assert.match(M.codeFromHex("9f86d081884c7d65"), /^[0-9]{6}$/);
});

test("a typed code: digits with spaces or a dash, exactly six", () => {
  assert.equal(M.normalizeCode("123456"), "123456");
  assert.equal(M.normalizeCode(" 123 456 "), "123456");
  assert.equal(M.normalizeCode("123-456"), "123456");
  for (const bad of ["12345", "1234567", "12a456", "", 123456 as any, null as any, "x".repeat(50)]) {
    assert.equal(M.normalizeCode(bad), null, String(bad));
  }
});

test("the device kinds the game names; anything else is just a device", () => {
  for (const k of ["phone", "tablet", "computer"]) {
    assert.equal(M.kindOf(k), k);
  }
  assert.equal(M.kindOf("toaster"), "device");
  assert.equal(M.kindOf(7), "device");
});

test("a book read from storage keeps only well-formed asks", () => {
  const good = ask();
  const book = M.bookFrom({ asks: [good, { id: 3 }, "x", { ...good, id: "a2", state: "weird" }, { ...good, id: "a3", code: "12" }] });
  assert.deepEqual(book.asks.map((a: any) => a.id), ["a1"]);
  assert.equal(M.bookFrom({ asks: [{ ...good, key_hash: 5 }] }).asks[0].key_hash, "");
  assert.deepEqual(M.bookFrom(undefined), { asks: [] });
  assert.deepEqual(M.bookFrom({ asks: "no" }), { asks: [] });
});

test("an open ask ends after five minutes; an approved one when its key's time is over; old ones go", () => {
  const book = { asks: [ask(), ask({ id: "a2", state: M.APPROVED, approved_ms: NOW }), ask({ id: "a3", state: M.ENDED, why: M.DECLINED })] };
  let t = M.tidy(book, NOW + M.CODE_MS - 1);
  assert.equal(t.asks[0].state, M.OPEN);
  t = M.tidy(book, NOW + M.CODE_MS);
  assert.equal(t.asks[0].state, M.ENDED);
  assert.equal(t.asks[0].why, M.EXPIRED);
  assert.equal(t.asks[1].state, M.ENDED, "the one-time key's time is over too");
  assert.equal(book.asks[0].state, M.OPEN, "the book given is not changed");
  t = M.tidy(book, NOW + M.KEEP_MS);
  assert.deepEqual(t.asks, [], "ended asks are kept a while (the asker hears why), then forgotten");
});

test("at most three asks open for one account: a fourth ends the oldest", () => {
  let book = { asks: [] as any[] };
  const replaced: any[] = [];
  for (let i = 0; i < M.OPEN_MAX + 1; i++) {
    const r = M.add(book, ask({ id: "a" + i, from: "asker-" + i, made_ms: NOW + i }));
    book = r.book;
    replaced.push(...r.replaced);
  }
  assert.deepEqual(M.open(book).map((a: any) => a.id), ["a1", "a2", "a3"]);
  assert.equal(replaced.length, 1);
  assert.equal(replaced[0].id, "a0");
  assert.equal(book.asks.find((a: any) => a.id === "a0").why, M.REPLACED);
});

test("the right code approves; three wrong ones end the ask", () => {
  const right = M.check(ask(), "123456", NOW + 1000);
  assert.equal(right.result, "approved");
  assert.equal(right.ask.state, M.APPROVED);
  assert.equal(right.ask.approved_ms, NOW + 1000);
  let a = ask();
  const first = M.check(a, "000000", NOW);
  assert.deepEqual([first.result, first.tries_left], ["wrong", 2]);
  a = first.ask;
  const second = M.check(a, "000001", NOW);
  assert.deepEqual([second.result, second.tries_left], ["wrong", 1]);
  const third = M.check(second.ask, "000002", NOW);
  assert.equal(third.result, "ended");
  assert.equal(third.ask.state, M.ENDED);
  assert.equal(third.ask.why, M.WRONG_CODE);
  assert.equal(M.check(third.ask, "123456", NOW).result, "ended", "the right code is too late now");
  assert.equal(M.check(ask({ state: M.APPROVED }), "123456", NOW).result, "ended", "approved once only");
});

test("a rate window counts asks and says how long to wait", () => {
  let w = M.emptyWindow();
  for (let i = 0; i < 3; i++) {
    const r = M.count(w, NOW + i, 3, 60_000);
    assert.equal(r.ok, true);
    w = r.window;
  }
  const over = M.count(w, NOW + 10, 3, 60_000);
  assert.equal(over.ok, false);
  assert.equal(over.wait, 60);
  const later = M.count(w, NOW + 60_000, 3, 60_000);
  assert.equal(later.ok, true, "a new window");
  assert.equal(later.window.count, 1);
  assert.deepEqual(M.windowFrom({ count: "x" }), M.emptyWindow());
});

test("the old device sees the ask without its code (or its key's hash); the asker sees how it stands", () => {
  const a = ask({ made_ms: NOW, key_hash: "$2a$10$secret" });
  assert.deepEqual(M.pendingView(a, NOW + 60_000), { id: "a1", kind: "computer", left_s: 240 });
  assert.ok(!JSON.stringify(M.pendingView(a, NOW)).includes("123456"));
  assert.deepEqual(M.askerView(a, NOW + 60_000), { state: "waiting", left_s: 240 });
  assert.deepEqual(M.askerView(ask({ state: M.APPROVED, key_hash: "$2a$10$secret" }), NOW), { state: "approved" });
  assert.deepEqual(M.askerView(ask({ state: M.DONE }), NOW), { state: "done" });
  assert.deepEqual(M.askerView(ask({ state: M.ENDED, why: M.CANCELLED }), NOW), { state: "ended", why: "cancelled" },
    "its own BACK");
});

test("what the account's side did never shows to the asker: it waits until its code's time is over", () => {
  for (const why of [M.DECLINED, M.WRONG_CODE, M.REPLACED, M.EXPIRED]) {
    const a = ask({ state: M.ENDED, why });
    assert.deepEqual(M.askerView(a, NOW + 1000), { state: "waiting", left_s: 299 }, why);
    assert.deepEqual(M.askerView(a, NOW + M.CODE_MS), { state: "ended", why: "expired" }, why);
  }
  assert.deepEqual(M.quietView(NOW, NOW), { state: "waiting", left_s: 300 }, "a decoy looks the same");
});
