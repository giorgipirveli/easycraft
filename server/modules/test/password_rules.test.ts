// Owner #105 (2026-10-15 23:14; module 0.2.20): a password, made when the name is claimed, for LOG IN on another device.
// The pure rules: what a password may be.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const P = S.PasswordRules;

test("a password: at least 6 characters, not the name, not one of the commonest", () => {
  assert.equal(P.problem("sunny-river-7", "Anna_7"), "");
  assert.equal(P.problem("abc12", "Anna_7"), "too_short");
  assert.equal(P.problem("anna_7", "Anna_7"), "is_name", "the name in any case");
  assert.equal(P.problem("ANNA_7", "Anna_7"), "is_name");
  for (const common of ["123456", "password", "qwerty", "111111", "abc123", "iloveyou", "Password1", "easycraft"]) {
    assert.equal(P.problem(common, "Anna_7"), "too_common", common);
  }
  assert.equal(P.problem("aaaaaaaa", "Anna_7"), "too_common", "one character again and again");
  assert.equal(P.problem("x".repeat(P.MAX_LEN + 1), "Anna_7"), "too_long");
  assert.equal(P.problem(123456 as any, "Anna_7"), "too_short");
  assert.equal(P.problem("bad\ntext!", "Anna_7"), "bad_chars", "no line breaks or control characters");
});

test("no straight runs: 123456, abcdef, qwerty or any six in a row on a keyboard row, either way", () => {
  for (const run of ["fedcba", "poiuyt", "lkjhgf", "098765", "moon234567", "tigerqwerty", "7mnbvcxz"]) {
    assert.equal(P.problem(run, "Anna_7"), "straight_run", run);
  }
  assert.equal(P.problem("willow3comet", "Anna_7"), "", "two words and a number");
  assert.equal(P.problem("moon7tiger", "Anna_7"), "too_common", "the example the game shows is never usable");
  assert.equal(P.problem("12345x7", "Anna_7"), "", "five in a row is fine");
});

test("a password over 72 bytes is refused with clear words (bcrypt's limit), under 64 characters", () => {
  const long = "a9é" + "ä".repeat(60); // 63 characters, 123 bytes
  assert.ok(long.length <= P.MAX_LEN);
  assert.equal(P.problem(long, "Anna_7"), "too_long");
});

test("not the name with numbers or signs around it", () => {
  for (const near of ["anna12", "12anna", "Anna2024", "anna_7!", "7ANNA77"]) {
    assert.equal(P.problem(near, "Anna_7"), "is_name", near);
  }
  assert.equal(P.problem("annamoon7", "Anna_7"), "", "the name with another word is fine");
});

test("a password is counted in characters as the game counts them", () => {
  assert.equal(P.problem("🙂🌟🙂🌟🙂🌟", "Anna_7"), "", "six characters");
  assert.equal(P.problem("🙂🌟🙂", "Anna_7"), "too_short");
});
