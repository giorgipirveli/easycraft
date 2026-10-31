// The username filter, ported from core/validation/username_rules.gd with the same test cases as
// tests/unit/test_username_rules.gd (spec §5.13: 3-16 letters, digits and _, starting with a letter,
// no bad words, no phone numbers). The server checks it too, so a modified game can't skip it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const U = server().UsernameRules;

test("a valid name passes", () => {
  assert.equal(U.validate("Hopper_7"), "");
});

test("too short, too long, and only spaces", () => {
  assert.equal(U.validate("ab"), "too_short");
  assert.equal(U.validate("abcdefghijklmnopq"), "too_long");
  assert.equal(U.validate("   "), "too_short");
});

test("must start with a letter", () => {
  assert.equal(U.validate("7hopper"), "must_start_with_letter");
  assert.equal(U.validate("_hopper"), "must_start_with_letter");
});

test("spaces inside, emoji and look-alike letters are bad characters", () => {
  assert.equal(U.validate("hop per"), "bad_chars");
  assert.equal(U.validate("hop😀er"), "bad_chars");
  assert.equal(U.validate("hоpper"), "bad_chars", "a Cyrillic o");
});

test("length counts characters as the game does (an emoji is one character)", () => {
  // 15 letters and an emoji are 16 characters: the length is fine, the emoji is not. (UTF-16 would
  // count 17 and say too_long, unlike Godot.)
  assert.equal(U.validate("abcdefghijklmno😀"), "bad_chars");
});

test("the ends are trimmed like Godot's strip_edges", () => {
  assert.equal(U.normalize("  Hopper_7 \n\t"), "Hopper_7");
  assert.equal(U.validate("  Hopper_7  "), "");
});

test("phone numbers are personal info, also split by underscores", () => {
  assert.equal(U.validate("call5551234567"), "personal_info");
  assert.equal(U.validate("a555_123_4567"), "personal_info");
  assert.equal(U.validate("Mom555_12_34_567"), "personal_info");
});

test("a few digits are fine", () => {
  assert.equal(U.validate("Hopper2025_12"), "");
});

test("bad words are refused in any case", () => {
  assert.equal(U.validate("xxStupidxx"), "blocked_word");
});

test("innocent names that contain a blocked word pass (the Scunthorpe problem)", () => {
  for (const name of ["Peacock", "Whatever", "Skillful", "Scrappy", "Dickens", "Tweedle", "Skyscraper",
      "Closer_7", "Cockatoo", "Dumbledore", "Hitchcock", "Sk1llz", "Chateau"]) {
    assert.equal(U.validate(name), "", name);
  }
});

test("real bad names stay blocked, also next to an innocent word, run together or in l33t", () => {
  for (const name of ["xxStupidxx", "iamstupid", "BigDick", "bigdick", "Killer99", "k1ll3r", "UrDumb",
      "Peacock_dick", "SkillKill", "Scrap_crap", "sh1thead", "Hitler_1", "Whatever_idiot"]) {
    assert.equal(U.validate(name), "blocked_word", name);
  }
});

test("the word lists match the game's", () => {
  assert.equal(U.BLOCKED_WORDS.length, 33);
  assert.equal(U.INNOCENT_WORDS.length, 23);
  assert.equal(U.MIN_LEN, 3);
  assert.equal(U.MAX_LEN, 16);
});

test("uniqueness ignores case", () => {
  assert.equal(U.uniquenessKey("Hopper_7"), U.uniquenessKey("  hOPPER_7 "));
  assert.equal(U.uniquenessKey("Hopper_7"), "hopper_7");
});

test("non-strings are refused", () => {
  assert.equal(U.validate(undefined), "too_short");
  assert.equal(U.validate(12345), "too_short");
});
