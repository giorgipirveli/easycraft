// Owner #67 (spec §5.13, §17.1): the account's sign-in key. A grown-up makes one on a device where the
// child plays; on a new phone or browser the child's name and this key sign that device in to the same
// account (no password, no e-mail: nothing personal). 8 Crockford base32 symbols (40 bits), shown as
// XXXX-XXXX; typed forgivingly (any case, spaces and dashes, O for 0, I or L for 1). The server keeps
// only a salted hash. Wrong keys lock: per name (whether or not it exists) and per asking account.
import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { server } from "./harness.ts";

const S = server();
const K = S.KeyRules;
const MIN = 60 * 1000;

test("a key is 8 symbols from 40 random bits", () => {
  assert.equal(K.fromHex("0000000000"), "00000000");
  assert.equal(K.fromHex("ffffffffff"), "ZZZZZZZZ");
  assert.equal(K.fromHex("0842108421"), "11111111", "5 bits a symbol");
  assert.equal(K.fromHex("ABCDEF0123"), K.fromHex("abcdef0123"));
  assert.equal(K.fromHex("xyz"), "", "not hex");
  assert.equal(K.fromHex("12345"), "", "too few bits");
  for (const c of K.fromHex("9f3c07a2e1")) {
    assert.ok(K.ALPHABET.includes(c), c);
  }
});

test("the alphabet leaves out letters that look like others", () => {
  assert.equal(K.ALPHABET.length, 32);
  for (const c of ["I", "L", "O", "U"]) {
    assert.ok(!K.ALPHABET.includes(c), c);
  }
});

test("shown in two groups of four", () => {
  assert.equal(K.pretty("7K3MQ9TD"), "7K3M-Q9TD");
});

test("typed forgivingly", () => {
  assert.equal(K.normalize("7k3m-q9td"), "7K3MQ9TD");
  assert.equal(K.normalize("  7K3M Q9TD "), "7K3MQ9TD");
  assert.equal(K.normalize("OIL1-oil1"), "01110111", "O is 0; I and L are 1");
  for (const bad of ["7K3MQ9T", "7K3MQ9TDX", "7K3MQ9TU", "7K3M_Q9TD", "", "ключ1234"]) {
    assert.equal(K.normalize(bad), null, bad);
  }
  for (const bad of [null, undefined, 12345678, {}, ["7K3MQ9TD"]]) {
    assert.equal(K.normalize(bad), null, String(bad));
  }
});

// A slow password hash (the server: bcrypt, which keeps its own salt): an 8-letter key is about 40 bits, fast to
// try offline with a fast hash if the database ever leaked (the lead's review, 2026-09-28).
const fakeBcrypt: K.Hasher = {
  hash: (text: string) => "$fake$" + createHash("sha256").update("pepper:" + text).digest("hex"),
  check: (hash: string, text: string) => hash === "$fake$" + createHash("sha256").update("pepper:" + text).digest("hex"),
};

test("the server keeps a slow hash, never the key", () => {
  const stored = K.store(fakeBcrypt, "7K3MQ9TD", 5000);
  assert.deepEqual(stored, { hash: fakeBcrypt.hash("7K3MQ9TD"), made_ms: 5000 });
  assert.ok(!JSON.stringify(stored).includes("7K3MQ9TD"));
  assert.equal(K.matches(fakeBcrypt, stored, "7K3MQ9TD"), true);
  assert.equal(K.matches(fakeBcrypt, stored, "7K3MQ9TE"), false);
  assert.equal(K.matches(fakeBcrypt, null, "7K3MQ9TD"), false);
});

test("a stored key is read back only when whole", () => {
  assert.deepEqual(K.storedFrom({ hash: "h", made_ms: 7 }), { hash: "h", made_ms: 7 });
  for (const bad of [undefined, null, [], {}, { hash: "", made_ms: 1 }, { hash: 5, made_ms: 1 }, { hash: "h", made_ms: "1" }]) {
    assert.equal(K.storedFrom(bad), null, JSON.stringify(bad));
  }
});

test("wrong keys for one name lock it for a while", () => {
  let t = K.emptyTries();
  const now = 1_000_000;
  for (let i = 0; i < K.NAME_MAX_WRONG - 1; i++) {
    t = K.wrong(t, now + i, K.NAME_MAX_WRONG, K.NAME_WINDOW_MS);
    assert.equal(K.wait(t, now + i), 0, "try " + (i + 1));
  }
  t = K.wrong(t, now + 10, K.NAME_MAX_WRONG, K.NAME_WINDOW_MS);
  assert.equal(K.wait(t, now + 10), Math.ceil(K.NAME_WINDOW_MS / 1000));
  assert.equal(K.wait(t, now + 10 + K.NAME_WINDOW_MS), 0, "then it opens again");
  const later = K.wrong(t, now + 10 + K.NAME_WINDOW_MS, K.NAME_MAX_WRONG, K.NAME_WINDOW_MS);
  assert.equal(later.wrong, 1, "a new window");
});

test("tries far apart never add up to a lock", () => {
  let t = K.emptyTries();
  for (let i = 0; i < 20; i++) {
    t = K.wrong(t, i * (K.NAME_WINDOW_MS + 1), K.NAME_MAX_WRONG, K.NAME_WINDOW_MS);
    assert.equal(K.wait(t, i * (K.NAME_WINDOW_MS + 1)), 0);
  }
});

test("tries are read carefully", () => {
  assert.deepEqual(K.triesFrom(null), K.emptyTries());
  assert.deepEqual(K.triesFrom("{}"), K.emptyTries());
  assert.deepEqual(K.triesFrom({ wrong: 2, since_ms: 5, locked_until_ms: 0 }), { wrong: 2, since_ms: 5, locked_until_ms: 0 });
  assert.deepEqual(K.triesFrom({ wrong: -1, since_ms: "x" }), K.emptyTries());
});

test("the limits", () => {
  assert.equal(K.NAME_MAX_WRONG, 5);
  assert.equal(K.NAME_WINDOW_MS, 15 * MIN);
  assert.equal(K.CALLER_MAX_WRONG, 10);
  assert.equal(K.CALLER_WINDOW_MS, 60 * MIN);
  assert.equal(K.NEW_MAX, 5);
  assert.equal(K.NEW_WINDOW_MS, 60 * MIN);
});

test("a device id is what Nakama takes and nothing odd", () => {
  assert.equal(K.isDeviceId("0b8f6a8e-3c1d-4a8e-9f00-1234567890ab"), true);
  for (const bad of ["short", "x".repeat(129), "has space in it", "semi;colon;id", 12345678901, null]) {
    assert.equal(K.isDeviceId(bad), false, String(bad));
  }
});
