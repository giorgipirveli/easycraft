// The "better together" half of the world game plan (owner #81, #82, #85; module 0.2.18) as pure rules: friendship
// levels by days together (Pokémon GO's lesson), presents a friend opens in the game, proud moments friends cheer with
// kind words only, study buddies whose shared days never fall (Duolingo's lesson without the loss), crews of 2-6 with a
// kid-safe name, a badge and a weekly learning goal (never a ranking).
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const R = S.SocialRules;
const U = S.UsernameRules;
const DAY = 24 * 60 * 60 * 1000;

test("days are UTC days; weeks start on Monday", () => {
  assert.equal(R.day(0), 0);
  assert.equal(R.day(DAY - 1), 0);
  assert.equal(R.day(DAY), 1);
  // 1970-01-04 was a Sunday, 1970-01-05 a Monday.
  assert.equal(R.week(3), R.week(0), "Thursday to Sunday: one week");
  assert.equal(R.week(4), R.week(3) + 1, "Monday starts the next");
  assert.equal(R.week(10), R.week(4), "Monday to Sunday");
  assert.equal(R.week(11), R.week(4) + 1);
  const monday = R.day(Date.UTC(2026, 8, 28)); // 2026-09-28 was a Monday
  assert.equal(R.week(monday), R.week(monday + 6));
  assert.equal(R.week(monday - 1), R.week(monday) - 1);
});

test("friendship levels grow with days together and never fall", () => {
  assert.equal(R.level(0), 0);
  assert.equal(R.level(1), 1);
  assert.equal(R.level(6), 1);
  assert.equal(R.level(7), 2);
  assert.equal(R.level(29), 2);
  assert.equal(R.level(30), 3);
  assert.equal(R.level(500), 3);
  assert.deepEqual(R.LEVELS.map((l: any) => l.at), [1, 7, 30]);
  assert.deepEqual(R.LEVELS.map((l: any) => l.id), ["good", "great", "best"]);
  assert.deepEqual(R.LEVELS.map((l: any) => l.reward), ["friendship_badge", "two_seat_rover", "dome_room"]);
  const r = R.emptyRecord();
  assert.equal(R.countDay(r, "sam", 100), true);
  assert.equal(R.countDay(r, "sam", 100), false, "one day counts once");
  assert.equal(R.countDay(r, "sam", 101), true);
  assert.equal(R.countDay(r, "sam", 99), false, "a clock turned back counts nothing");
  assert.deepEqual(r.friends.sam, { days: 2, last: 101 });
  // A long break loses nothing.
  assert.equal(R.countDay(r, "sam", 400), true);
  assert.equal(r.friends.sam.days, 3);
});

test("presents: the kinds, one a day to each friend, a few a day in all", () => {
  assert.deepEqual(R.PRESENT_KINDS, ["rocket_part", "seeds", "buddy_egg", "map_piece"]);
  const r = R.emptyRecord();
  const d = 500;
  for (let i = 0; i < R.SENDS_PER_DAY; i++) {
    assert.equal(R.sendCheck(r, "f" + i, d), "", "send " + i);
    R.noteSend(r, "f" + i, d);
  }
  assert.equal(R.sendCheck(r, "f0", d), "sent_today", "one a day to each friend");
  assert.equal(R.sendCheck(r, "other", d), "too_many_today");
  assert.equal(R.sendCheck(r, "f0", d + 1), "", "a new day");
  R.noteSend(r, "f0", d + 1);
  assert.equal(r.counts.sent, 1, "the day's counts start again");
  assert.equal(R.sendsLeft(r, d + 1), R.SENDS_PER_DAY - 1);
  assert.equal(R.sendsLeft(r, d + 2), R.SENDS_PER_DAY);
});

test("moments and cheers: known kinds and places, kind words only, a calm number a day", () => {
  assert.ok(R.MOMENT_KINDS.indexOf("landed") >= 0 && R.MOMENT_KINDS.indexOf("unit") >= 0);
  assert.equal(R.momentCheck("landed", "moon"), "");
  assert.equal(R.momentCheck("unit", "g4.maths.fractions"), "");
  assert.equal(R.momentCheck("grade", "g4.maths"), "");
  assert.equal(R.momentCheck("party", "moon"), "bad_request");
  assert.equal(R.momentCheck("landed", "Moon Base!"), "bad_request", "places are ids, never words");
  assert.equal(R.momentCheck("landed", ""), "bad_request");
  assert.equal(R.momentCheck("landed", "x".repeat(49)), "bad_request");
  assert.deepEqual(R.CHEERS, ["well_done", "amazing", "star", "high_five", "so_proud", "you_did_it"]);
  assert.ok(R.CHEERS_PER_DAY >= 10 && R.MOMENTS_PER_DAY >= 3);
});

test("study buddies: a shared day when both learned; the week's row: both, one, rest", () => {
  const me = R.emptyRecord();
  const pal = R.emptyRecord();
  R.noteLearned(me, 100);
  R.noteLearned(me, 101);
  R.noteLearned(pal, 101);
  R.noteLearned(pal, 102);
  R.noteLearned(me, 101);
  assert.deepEqual(me.learned, [100, 101], "each day once");
  assert.deepEqual(R.weekRow(me.learned, pal.learned, 102), [0, 0, 0, 0, 1, 2, 1]);
  assert.deepEqual(R.weekRow(me.learned, pal.learned, 102, 101), [0, 0, 0, 0, 0, 2, 1], "counted from the day they said yes");
  for (let d = 0; d < 40; d++) {
    R.noteLearned(me, 200 + d);
  }
  assert.equal(me.learned.length, R.LEARNED_KEEP, "only the last days are kept");
  assert.equal(me.learned[me.learned.length - 1], 239);
});

test("the week's learning: days and the units mastered this week, for the crew page", () => {
  const r = R.emptyRecord();
  const monday = R.day(Date.UTC(2026, 8, 28));
  R.noteWeek(r, monday, "g4.maths.fractions");
  R.noteWeek(r, monday, "g4.maths.fractions");
  R.noteWeek(r, monday + 1, "");
  R.noteWeek(r, monday + 1, "g4.science.rocks");
  assert.deepEqual(r.week, { week: R.week(monday), days: 2, last: monday + 1, units: ["g4.maths.fractions", "g4.science.rocks"] });
  R.noteWeek(r, monday + 7, "");
  assert.deepEqual(r.week, { week: R.week(monday + 7), days: 1, last: monday + 7, units: [] }, "a new week starts at 0");
  assert.equal(R.unitCheck("g4.maths.fractions"), true);
  assert.equal(R.unitCheck("G4 maths"), false);
});

test("crews: names from two kid-safe lists, a badge, 1-6 members (a crew of 2-6 once a friend joins)", () => {
  assert.ok(R.CREW_ADJECTIVES.length >= 16 && R.CREW_NOUNS.length >= 16);
  assert.equal(R.crewNameCheck("Brave", "Comets"), "");
  assert.equal(R.crewNameCheck("brave", "Comets"), "bad_name", "exactly a word of the list");
  assert.equal(R.crewNameCheck("Rude", "Comets"), "bad_name");
  assert.equal(R.badgeCheck("rocket"), "");
  assert.equal(R.badgeCheck("skull"), "bad_badge");
  assert.equal(R.CREW_MIN, 2);
  assert.equal(R.CREW_MAX, 6);
  assert.equal(R.crewGoal(1), R.CREW_GOAL_PER_MEMBER * 2, "a crew waiting for its second member aims for two");
  assert.equal(R.crewGoal(4), R.CREW_GOAL_PER_MEMBER * 4);
});

test("every crew name passes the name filter: no rude word hides in one", () => {
  const all = R.CREW_ADJECTIVES.concat(R.CREW_NOUNS);
  assert.equal(new Set(all).size, all.length, "no word twice");
  for (const w of all) {
    assert.match(w, /^[A-Z][a-z]{2,11}$/, "a capital and small letters: " + w);
  }
  for (const a of R.CREW_ADJECTIVES) {
    for (const b of R.CREW_NOUNS) {
      const text = (a + b).toLowerCase();
      let unleet = text;
      for (const [from, to] of U.LEET) {
        unleet = unleet.split(from).join(to);
      }
      for (const word of U.BLOCKED_WORDS) {
        assert.ok(!text.includes(word) && !unleet.includes(word), a + " " + b + " hides " + word);
      }
    }
  }
});

test("a crew member's look: only short, known kinds of values (no boy / girl, nothing personal)", () => {
  assert.deepEqual(R.lookFrom({ hair: "curly", shirt: "#ff0000", hat: "none", base: "girl", extras: ["cape"] }),
    { hair: "curly", shirt: "#ff0000", hat: "none", extras: ["cape"] });
  assert.deepEqual(R.lookFrom("hi"), {});
  assert.deepEqual(R.lookFrom({ hair: "x".repeat(40) }), {});
  const big: any = {};
  for (let i = 0; i < 40; i++) {
    big["key_" + String.fromCharCode(97 + (i % 26)) + String.fromCharCode(97 + Math.floor(i / 26))] = "v";
  }
  assert.equal(Object.keys(R.lookFrom(big)).length, R.LOOK_KEYS_MAX);
});

test("a stored record is read field by field; broken fields fall back on their own", () => {
  const r = R.recordFrom({
    friends: { sam: { days: 3, last: 100 }, bad: { days: -1 }, x: "no" },
    learned: [100, "x", 101],
    buddies: { sam: { state: "yes", since: 90, days: 4, last: 100 }, bo: { state: "boss" } },
    feed: [{ id: "m1", from: "sam", kind: "landed", place: "moon", at_ms: 5 }, { id: "m2", kind: "party" }],
    presents: [{ id: "p1", from: "sam", kind: "seeds", at_ms: 5, opened: true, thanked: false }, { id: "p2", kind: "cake" }],
    link_gifts: [{ kind: "seeds", at_ms: 1 }, { kind: "cake" }],
    news: [{ what: "cheer", id: "sam", kind: "star", gold: 0, at_ms: 1 }, { what: "boo" }],
    crew: "c1", crew_invites: [{ crew: "c2", from: "sam", at_ms: 3 }, { crew: 7 }],
    counts: { day: 7, sent: 2, sent_to: ["sam"], cheers: 1, moments: 1, thanks: 0 },
    week: { week: 5, days: 2, last: 36, units: ["g4.maths.fractions", "BAD"] },
  });
  assert.deepEqual(r.friends, { sam: { days: 3, last: 100 } });
  assert.deepEqual(r.learned, [100, 101]);
  assert.deepEqual(Object.keys(r.buddies), ["sam"]);
  assert.equal(r.feed.length, 1);
  assert.equal(r.presents.length, 1);
  assert.equal(r.link_gifts.length, 1);
  assert.equal(r.news.length, 1);
  assert.equal(r.crew, "c1");
  assert.equal(r.crew_invites.length, 1);
  assert.deepEqual(r.counts, { day: 7, sent: 2, sent_to: ["sam"], cheers: 1, moments: 1, thanks: 0 });
  assert.deepEqual(r.week.units, ["g4.maths.fractions"]);
  assert.deepEqual(R.recordFrom(undefined), R.emptyRecord());
});

test("the inbox makes room: done presents go first, then opened ones, never one not opened", () => {
  const r = R.emptyRecord();
  for (let i = 0; i < R.INBOX_MAX; i++) {
    r.presents.push({ id: "p" + i, from: "s", kind: "seeds", at_ms: i, opened: i < 5, thanked: i < 2, link: false });
  }
  assert.equal(R.makeRoom(r, 1), true);
  assert.equal(r.presents.length, R.INBOX_MAX - 1, "the oldest done one went");
  assert.equal(r.presents[0].id, "p1");
  assert.equal(R.makeRoom(r, 3), true);
  assert.deepEqual(r.presents.slice(0, 2).map((p: any) => p.id), ["p3", "p4"], "then the other done one, then opened ones");
  const unopened = R.emptyRecord();
  for (let i = 0; i < R.INBOX_MAX; i++) {
    unopened.presents.push({ id: "q" + i, from: "s", kind: "seeds", at_ms: i, opened: false, thanked: false, link: false });
  }
  assert.equal(R.makeRoom(unopened, 1), false, "a full inbox of presents not opened yet");
  assert.equal(unopened.presents.length, R.INBOX_MAX);
  const stored: any[] = [];
  for (let i = 0; i < R.INBOX_MAX + 5; i++) {
    stored.push({ id: "s" + i, from: "s", kind: "seeds", at_ms: i, opened: false, thanked: false });
  }
  const back = R.recordFrom({ presents: stored });
  assert.equal(back.presents.length, R.INBOX_MAX);
  assert.equal(back.presents[back.presents.length - 1].id, "s" + (R.INBOX_MAX + 4), "the newest are read back");
});

test("lists stay small: news, the feed and the inbox keep their newest", () => {
  const r = R.emptyRecord();
  for (let i = 0; i < 50; i++) {
    R.addNews(r, { what: "cheer", id: "s", kind: "star", gold: 0, place: "", at_ms: i });
    R.addFeed(r, { id: "m" + i, from: "s", kind: "landed", place: "moon", at_ms: i });
  }
  assert.equal(r.news.length, R.NEWS_MAX);
  assert.equal(r.news[r.news.length - 1].at_ms, 49);
  assert.equal(r.feed.length, R.FEED_MAX);
  assert.equal(r.feed[0].id, "m" + (50 - R.FEED_MAX));
});
