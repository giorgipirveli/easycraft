// The chat rules, ported from core/rules/chat_rules.gd with the cases of tests/unit/test_chat_rules.gd
// (spec §5.13, §17.4): under_13 sends and receives quick phrases only; 13_plus free text passes the
// bad-word and personal-info filter. The server runs them on channel messages so a modified game
// can't skip them.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const C = S.ChatRules;
const TEEN = "13_plus";
const KID = "under_13";

test("clean trims and squeezes spaces", () => {
  assert.equal(C.clean("   hello    there  "), "hello there");
});

test("clean strips control characters and invisible formatting", () => {
  assert.equal(C.clean("hi\nthere\t!\u0007"), "hi there !");
  assert.equal(C.clean("a‮b​c"), "abc");
});

test("clean caps at 120 characters (counted as the game counts them)", () => {
  assert.equal(C.clean("a".repeat(300)).length, 120);
  assert.equal(C.MAX_LENGTH, 120);
  assert.equal(S.Util.codePointLength(C.clean("😀".repeat(300))), 120, "an emoji is one character");
});

test("only spaces is empty", () => {
  assert.equal(C.check("   \n ", TEEN).error, "empty");
});

test("under_13 free text is refused; quick phrases pass", () => {
  assert.equal(C.check("hello, want to build a castle?", KID).error, "quick_chat_only");
  for (const phrase of C.QUICK_PHRASES) {
    assert.equal(C.check(phrase, KID).text, phrase, phrase);
  }
});

test("quick phrases are short and clean, the same 13 as the game's", () => {
  assert.equal(C.QUICK_PHRASES.length, 13);
  for (const p of ["Hi!", "Follow me!", "Bye!"]) {
    assert.ok(C.QUICK_PHRASES.includes(p));
  }
  for (const phrase of C.QUICK_PHRASES) {
    assert.equal(C.clean(phrase), phrase);
    assert.equal(C.filterCode(phrase), "", phrase);
  }
});

test("an unknown band is treated as under_13", () => {
  assert.equal(C.check("hello there", "adult").error, "quick_chat_only");
  assert.equal(C.check("hello there", "").error, "quick_chat_only");
});

test("teen free text passes, cleaned", () => {
  assert.equal(C.check("  Want to build a castle?  ", TEEN).text, "Want to build a castle?");
});

test("phone numbers are filtered for teens", () => {
  for (const text of ["call me 555 123 4567", "my number is 555-1234567", "(555) 123-4567", "5 5 5 1 2 3 4"]) {
    assert.equal(C.check(text, TEEN).error, "personal_info", text);
  }
});

test("a few numbers are fine", () => {
  for (const text of ["I built 25 towers", "meet at 100 64", "level 3 in 2 minutes"]) {
    assert.equal(C.check(text, TEEN).error, undefined, text);
  }
});

test("emails, links and contact apps are filtered", () => {
  for (const text of ["mail me at kid@example.com", "go to www.example.com", "see http://x.io", "add me on snapchat",
      "what is your address", "where do you live?"]) {
    assert.equal(C.filterCode(text), "personal_info", text);
  }
});

test("bad words are filtered for teens", () => {
  for (const text of ["you are STUPID", "you're a l0ser", "s t u p i d", "such an idiot!", "stupidest build ever"]) {
    assert.equal(C.check(text, TEEN).error, "blocked_word", text);
  }
});

test("innocent words that contain bad ones pass", () => {
  for (const text of ["whatever you say", "nice skill", "that is a scrappy tower", "this hit the wall", "grass and class"]) {
    assert.equal(C.filterCode(text), "", text);
  }
});

test("under_13 players only receive quick phrases", () => {
  assert.equal(C.canReceive("Hi!", KID), true);
  assert.equal(C.canReceive("want to build a castle?", KID), false);
  assert.equal(C.canReceive("want to build a castle?", ""), false);
  assert.equal(C.canReceive("want to build a castle?", TEEN), true);
});

test("phone numbers in any digits are filtered (review M9)", () => {
  for (const text of ["try ５５５１２３４", "٥٥٥١٢٣٤", "ring ۵۵۵ ۱۲۳۴", "५५५-१२३४", "๕๕๕๑๒๓๔", "555 ١٢٣٤",
      "𝟓𝟓𝟓𝟏𝟐𝟑𝟒", "⑤⑤⑤①②③④", "555 123–4"]) {
    assert.equal(C.check(text, TEEN).error, "personal_info", text);
  }
});

test("a few digits in any script are fine", () => {
  for (const text of ["I built ２５ towers", "level ٣ in ٢ minutes"]) {
    assert.equal(C.check(text, TEEN).error, undefined, text);
  }
});

test("fullwidth emails and links are filtered", () => {
  for (const text of ["kid＠example．com", "ｗｗｗ．example．com"]) {
    assert.equal(C.filterCode(text), "personal_info", text);
  }
});

test("accented and look-alike swears are filtered (review M9)", () => {
  for (const text of ["fück this", "shít", "FÜCK", "you are stüpid", "ｆｕｃｋ", "fück", "ѕhit", "fuсk",
      "ΙDIOT", "a l٠ser"]) {
    assert.equal(C.check(text, TEEN).error, "blocked_word", text);
  }
});

test("accented words pass and keep their accents", () => {
  for (const text of ["naïve café", "über cool build", "piñata party", "ça va?", "Ελληνικά", "привет всем"]) {
    assert.equal(C.filterCode(text), "", text);
  }
  assert.equal(C.check("Café crème!", TEEN).text, "Café crème!");
});

test("a message's content: text or an emote, nothing else", () => {
  assert.deepEqual(C.parseContent('{"text": "Hi!"}'), { text: "Hi!" });
  assert.deepEqual(C.parseContent('{"emote": "wave"}'), { emote: "wave" });
  for (const bad of ['{"text": 5}', '{"emote": "Wave Hi"}', '{"text": "Hi!", "emote": "wave"}', '{"text": "Hi!", "x": 1}',
      "[]", "nope", '{"emote": ""}', "{}"]) {
    assert.equal(C.parseContent(bad), null, bad);
  }
});

test("a message for a chat level: off refuses, quick needs a phrase or an emote, filtered filters", () => {
  assert.deepEqual(C.checkContent({ text: "Hi!" }, "off"), { error: "chat_off" });
  assert.deepEqual(C.checkContent({ emote: "wave" }, "off"), { error: "chat_off" });
  assert.deepEqual(C.checkContent({ text: " Hi! " }, "quick"), { content: { text: "Hi!" } });
  assert.deepEqual(C.checkContent({ emote: "wave" }, "quick"), { content: { emote: "wave" } });
  assert.deepEqual(C.checkContent({ text: "hello friend" }, "quick"), { error: "quick_chat_only" });
  assert.deepEqual(C.checkContent({ text: "  hello   friend " }, "filtered"), { content: { text: "hello friend" } });
  assert.deepEqual(C.checkContent({ text: "you are stupid" }, "filtered"), { error: "blocked_word" });
  assert.deepEqual(C.checkContent({ text: "   " }, "filtered"), { error: "empty" });
});

test("the strictest level wins when players of both bands share a channel", () => {
  assert.equal(C.strictest(["filtered", "quick"]), "quick");
  assert.equal(C.strictest(["filtered", "filtered"]), "filtered");
  assert.equal(C.strictest(["filtered", "off"]), "off");
  assert.equal(C.strictest([]), "off");
});

// --- History (M4 Wave 2, agent E; spec §17.2): 13+ only, 30 days ---

test("history is kept only for a DM between two players at the text level, never with an under_13 player", () => {
  assert.equal(C.keepsHistory(C.DM_TYPE, ["filtered", "filtered"]), true);
  assert.equal(C.keepsHistory(C.DM_TYPE, ["filtered", "quick"]), false, "an under_13 player (or quick chat) is there");
  assert.equal(C.keepsHistory(C.DM_TYPE, ["quick", "quick"]), false);
  assert.equal(C.keepsHistory(C.DM_TYPE, ["filtered"]), false);
  assert.equal(C.keepsHistory(1, ["filtered", "filtered"]), false, "team rooms keep nothing");
});

test("messages older than 30 days expire (Nakama's seconds, or a time text)", () => {
  const now = 400 * 86400 * 1000;
  assert.equal(C.HISTORY_DAYS, 30);
  assert.equal(C.isExpired(now / 1000 - 31 * 86400, now), true);
  assert.equal(C.isExpired(now / 1000 - 29 * 86400, now), false);
  assert.equal(C.createSeconds(1234), 1234);
  assert.equal(C.createSeconds(1234000000000), 1234000000, "milliseconds read as seconds");
  assert.equal(C.createSeconds("1970-01-02T00:00:00Z"), 86400);
  assert.equal(C.createSeconds("nonsense"), 0);
  assert.equal(C.isExpired(C.createSeconds("nonsense"), now), false, "an unreadable time is kept, never guessed away");
});
