// Owner #79, #81, #82, #85 (spec §25.2; the world game plan §2, §2b): the invite (referral) program as pure rules.
// Every player has an invite code of kid-safe words and a number (BLUE-OTTER-42), typed any way; a grown-up can make
// a class code and a family code. A NEW account that uses a code gets a welcome gift at once; the inviter gets gold
// only when the friend really learns (their first School unit mastered), once, within a monthly cap; the inviter's
// inviter gets a small gift (the Explorer Tree: two levels); a friend's first Moon landing brings a bonus. Never your
// own code, never twice, nothing about the friend but two account ids and the dates.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const R = S.ReferralRules;
const U = S.UsernameRules;
const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_790_000_000_000;

// A picker that takes the numbers it is given in turn (then 0).
function picks(...values: number[]): (n: number) => number {
  let i = 0;
  return (n: number) => {
    const v = i < values.length ? values[i] : 0;
    i++;
    return v % n;
  };
}

test("a code is two kid-safe words and a number: BLUE-OTTER-42", () => {
  const blue = R.ADJECTIVES.indexOf("BLUE");
  const otter = R.ANIMALS.indexOf("OTTER");
  assert.ok(blue >= 0 && otter >= 0);
  assert.equal(R.makeCode(R.KIND_FRIEND, picks(blue, otter, 42 - R.NUMBER_MIN), false), "BLUE-OTTER-42");
  assert.match(R.makeCode(R.KIND_FRIEND, (n: number) => n - 1, false), /^[A-Z]+-[A-Z]+-99$/);
  assert.match(R.makeCode(R.KIND_FRIEND, () => 0, true), /^[A-Z]+-[A-Z]+-10$/, "wide numbers start at 10 too");
  assert.match(R.makeCode(R.KIND_FRIEND, (n: number) => n - 1, true), /^[A-Z]+-[A-Z]+-9999$/, "after clashes: up to 9999");
});

test("class and family codes carry their kind in front", () => {
  assert.match(R.makeCode(R.KIND_CLASS, () => 0, false), /^CLASS-[A-Z]+-[A-Z]+-10$/);
  assert.match(R.makeCode(R.KIND_FAMILY, () => 0, false), /^FAMILY-[A-Z]+-[A-Z]+-10$/);
});

test("every word pair and number passes the name filter: no rude word hides in a code", () => {
  assert.ok(R.ADJECTIVES.length >= 30 && R.ANIMALS.length >= 45, "enough codes: " + R.ADJECTIVES.length * R.ANIMALS.length * 90);
  const all = R.ADJECTIVES.concat(R.ANIMALS);
  assert.equal(new Set(all).size, all.length, "no word twice");
  for (const w of all) {
    assert.match(w, /^[A-Z]{3,7}$/, "short words in capitals: " + w);
  }
  for (const a of R.ADJECTIVES) {
    for (const b of R.ANIMALS) {
      for (let n = R.NUMBER_MIN; n <= R.NUMBER_MAX; n++) {
        // UsernameRules checks at most 16 characters: the blocked stems are looked for in the whole text here.
        const text = (a + b + n).toLowerCase();
        let unleet = text;
        for (const [from, to] of U.LEET) {
          unleet = unleet.split(from).join(to);
        }
        for (const word of U.BLOCKED_WORDS) {
          assert.ok(!text.includes(word) && !unleet.includes(word), a + "-" + b + "-" + n + " hides " + word);
        }
      }
    }
  }
});

test("a code is typed any way: case, spaces, dashes and no dashes are one code", () => {
  assert.equal(R.canonical("BLUE-OTTER-42"), "BLUEOTTER42");
  assert.equal(R.canonical("  blue otter 42 "), "BLUEOTTER42");
  assert.equal(R.canonical("Blue_Otter-42"), "BLUEOTTER42");
  assert.equal(R.canonical("blueotter42"), "BLUEOTTER42");
  assert.equal(R.canonical("class-jade-owl-27"), "CLASSJADEOWL27");
  assert.equal(R.canonical(""), "");
  assert.equal(R.canonical("   "), "");
  assert.equal(R.canonical(42), "");
  assert.equal(R.canonical("A".repeat(R.MAX_TYPED + 1)), "", "too long to be a code");
  assert.equal(R.canonical("BLUE-ÖTTER-42"), "", "letters of the codes only");
});

test("a new account is younger than NEW_ACCOUNT_MS (an unknown age counts as new)", () => {
  assert.equal(R.isNewAccount(NOW - DAY, NOW), true);
  assert.equal(R.isNewAccount(NOW - R.NEW_ACCOUNT_MS + 1000, NOW), true);
  assert.equal(R.isNewAccount(NOW - R.NEW_ACCOUNT_MS - 1000, NOW), false);
  assert.equal(R.isNewAccount(0, NOW), true);
  assert.ok(R.NEW_ACCOUNT_MS >= 7 * DAY && R.NEW_ACCOUNT_MS <= 30 * DAY);
});

test("a record is read field by field: junk falls back on its own", () => {
  const empty = R.emptyRecord();
  assert.deepEqual(R.recordFrom(undefined), empty);
  assert.deepEqual(R.recordFrom("x"), empty);
  const r = R.recordFrom({
    code: "BLUE-OTTER-42", made: { class: "CLASS-JADE-OWL-27", bogus: "X" }, by: { user_id: "u-1", kind: "friend", at_ms: 5 },
    learned_ms: 7, landed_ms: "no", groups: { family: "FAMILY-MINT-YAK-11", class: 3 },
    friends: [{ id: "f-1", at_ms: 1, learned_ms: 2, landed_ms: 0 }, { id: 5 }, "x", { id: "f-2", at_ms: 3 }],
    times: { learned: [1, 2, "x"], tree: "no" }, earned: 250, news: [{ what: "learned", id: "f-1", gold: 250, at_ms: 9 }, { what: 1 }],
  });
  assert.equal(r.code, "BLUE-OTTER-42");
  assert.deepEqual(r.made, { class: "CLASS-JADE-OWL-27" });
  assert.deepEqual(r.by, { user_id: "u-1", kind: "friend", at_ms: 5 });
  assert.equal(r.learned_ms, 7);
  assert.equal(r.landed_ms, 0);
  assert.deepEqual(r.groups, { family: "FAMILY-MINT-YAK-11" });
  assert.deepEqual(r.friends, [{ id: "f-1", at_ms: 1, learned_ms: 2, landed_ms: 0 }, { id: "f-2", at_ms: 3, learned_ms: 0, landed_ms: 0 }]);
  assert.deepEqual(r.times, { learned: [1, 2], tree: [], landed: [] });
  assert.equal(r.earned, 250);
  assert.deepEqual(r.news, [{ what: "learned", id: "f-1", gold: 250, at_ms: 9 }]);
});

function info(userId: string, kind: string, code = "BLUE-OTTER-42"): any {
  return { user_id: userId, kind: kind, code: code, made_ms: 1 };
}

test("a friend's code: a new account, once, never your own", () => {
  const me = R.emptyRecord();
  const fresh = NOW - DAY;
  assert.deepEqual(R.useCheck(me, info("pal", R.KIND_FRIEND), "me", fresh, NOW, 0), { error: "", referral: true, group: "" });
  assert.equal(R.useCheck(me, null, "me", fresh, NOW, 0).error, "unknown");
  assert.equal(R.useCheck(me, info("me", R.KIND_FRIEND), "me", fresh, NOW, 0).error, "own_code");
  assert.equal(R.useCheck(me, info("pal", R.KIND_FRIEND), "me", NOW - 60 * DAY, NOW, 0).error, "not_new");
  const brought = { ...R.emptyRecord(), by: { user_id: "other", kind: R.KIND_FRIEND, at_ms: 1 } };
  assert.equal(R.useCheck(brought, info("pal", R.KIND_FRIEND), "me", fresh, NOW, 0).error, "already_used");
  const gone = { ...R.emptyRecord(), by: { user_id: "", kind: R.KIND_FRIEND, at_ms: 1 } };
  assert.equal(R.useCheck(gone, info("pal", R.KIND_FRIEND), "me", fresh, NOW, 0).error, "already_used",
    "even when the inviter's account was deleted: once is once");
});

test("a class or family code: anyone joins (one of each); a new account is also its maker's referral", () => {
  const me = R.emptyRecord();
  assert.deepEqual(R.useCheck(me, info("teacher", R.KIND_CLASS, "CLASS-JADE-OWL-27"), "me", NOW - DAY, NOW, 5),
    { error: "", referral: true, group: R.KIND_CLASS });
  assert.deepEqual(R.useCheck(me, info("teacher", R.KIND_CLASS, "CLASS-JADE-OWL-27"), "me", NOW - 90 * DAY, NOW, 5),
    { error: "", referral: false, group: R.KIND_CLASS }, "an older account joins the class, no welcome gift");
  const brought = { ...R.emptyRecord(), by: { user_id: "pal", kind: R.KIND_FRIEND, at_ms: 1 } };
  assert.deepEqual(R.useCheck(brought, info("mum", R.KIND_FAMILY, "FAMILY-MINT-YAK-11"), "me", NOW - DAY, NOW, 3),
    { error: "", referral: false, group: R.KIND_FAMILY }, "already brought by a friend: joins the family only");
  const inClass = { ...R.emptyRecord(), groups: { class: "CLASS-JADE-OWL-27" } };
  assert.equal(R.useCheck(inClass, info("t2", R.KIND_CLASS, "CLASS-RED-FOX-44"), "me", NOW - DAY, NOW, 1).error, "already_in");
  assert.equal(R.useCheck(inClass, info("teacher", R.KIND_CLASS, "CLASS-JADE-OWL-27"), "me", NOW - DAY, NOW, 1).error,
    "already_in");
  assert.equal(R.useCheck(me, info("teacher", R.KIND_CLASS), "me", NOW - DAY, NOW, R.GROUP_MAX.class).error, "group_full");
  assert.equal(R.useCheck(me, info("mum", R.KIND_FAMILY), "me", NOW - DAY, NOW, R.GROUP_MAX.family).error, "group_full");
  assert.equal(R.useCheck(me, info("me", R.KIND_FAMILY), "me", NOW - DAY, NOW, 1).error, "own_code");
  assert.ok(R.GROUP_MAX.class >= 30 && R.GROUP_MAX.family >= 8);
});

test("the inviter's list: a friend once, at most MAX_FRIENDS", () => {
  const r = R.emptyRecord();
  assert.equal(R.addFriend(r, "f-1", NOW), true);
  assert.equal(R.addFriend(r, "f-1", NOW + 5), false, "once");
  assert.deepEqual(r.friends, [{ id: "f-1", at_ms: NOW, learned_ms: 0, landed_ms: 0 }]);
  const full = R.emptyRecord();
  for (let i = 0; i < R.MAX_FRIENDS; i++) {
    full.friends.push({ id: "x" + i, at_ms: 1, learned_ms: 0, landed_ms: 0 });
  }
  assert.equal(R.addFriend(full, "late", NOW), false);
});

test("a friend learned once, landed once", () => {
  const r = R.emptyRecord();
  R.addFriend(r, "f-1", NOW);
  assert.equal(R.markLearned(r, "f-1", NOW + 1), true);
  assert.equal(R.markLearned(r, "f-1", NOW + 2), false, "once");
  assert.equal(R.markLearned(r, "nobody", NOW), false);
  assert.equal(r.friends[0].learned_ms, NOW + 1);
  assert.equal(R.markLanded(r, "f-1", NOW + 3), true);
  assert.equal(R.markLanded(r, "f-1", NOW + 4), false);
  assert.deepEqual(R.counts(r), { friends: 1, learned: 1 });
});

test("the monthly caps: a rolling 30 days per kind", () => {
  assert.equal(R.WINDOW_MS, 30 * DAY);
  let times: number[] = [];
  for (let i = 0; i < R.CAPS.learned; i++) {
    assert.equal(R.hasRoom(times, R.CAPS.learned, NOW + i), true);
    times = R.take(times, NOW + i);
  }
  assert.equal(R.hasRoom(times, R.CAPS.learned, NOW + 100), false, "the cap is reached");
  assert.equal(R.hasRoom(times, R.CAPS.learned, NOW + R.WINDOW_MS + 1), true, "30 days later there is room again");
  assert.deepEqual(R.take(times, NOW + R.WINDOW_MS + 10).length, 1, "old times fall out");
  assert.ok(R.CAPS.tree >= R.CAPS.learned);
});

test("the rewards: tied to learning, the friend's welcome at once, never for a bare sign-up", () => {
  assert.equal(R.WELCOME_GOLD, 100);
  assert.equal(R.INVITER_GOLD, 250);
  assert.equal(R.LEARNER_GOLD, 50);
  assert.equal(R.TREE_GOLD, 25);
  assert.equal(R.LANDED_GOLD, 150);
  assert.ok(R.TREE_GOLD < R.INVITER_GOLD, "the second level is a small gift");
  assert.deepEqual(R.EVENTS, ["learned", "landed"]);
  assert.deepEqual(R.LANDED_PLACES, ["moon"]);
});

test("news: newest last, at most MAX_NEWS, only what is known", () => {
  const r = R.emptyRecord();
  for (let i = 0; i < R.MAX_NEWS + 5; i++) {
    R.addNews(r, { what: "joined", id: "f" + i, gold: 0, at_ms: i });
  }
  assert.equal(r.news.length, R.MAX_NEWS);
  assert.equal(r.news[r.news.length - 1].id, "f" + (R.MAX_NEWS + 4));
  assert.equal(R.recordFrom({ news: [{ what: "spam", id: "", gold: 1, at_ms: 1 }] }).news.length, 0, "known kinds only");
});

test("a code's record says whose it is and what kind", () => {
  assert.deepEqual(R.codeInfoFrom({ user_id: "u", kind: "class", code: "CLASS-JADE-OWL-27", made_ms: 3 }),
    { user_id: "u", kind: "class", code: "CLASS-JADE-OWL-27", made_ms: 3 });
  assert.equal(R.codeInfoFrom({ user_id: "u", kind: "boss", code: "X", made_ms: 3 }), null);
  assert.equal(R.codeInfoFrom(null), null);
});

test("a group's members: once each, the maker first", () => {
  const g = R.groupFrom({ kind: "family", owner_id: "mum", code: "FAMILY-MINT-YAK-11", members: ["mum", "kid", 5, "kid"], made_ms: 2 });
  assert.deepEqual(g, { kind: "family", owner_id: "mum", code: "FAMILY-MINT-YAK-11", members: ["mum", "kid"], made_ms: 2 });
  assert.equal(R.groupFrom({ kind: "friend", owner_id: "x", code: "X", members: [], made_ms: 1 }), null);
});
