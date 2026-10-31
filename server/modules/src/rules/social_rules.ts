// The "better together" half of the world game plan (owner #81, #82, #85; docs/superpowers/plans/
// 2026-09-29-world-game-plan.md §1-§3; module 0.2.18), as pure rules. Everything is between friends (Nakama's mutual
// friends), learning-first and calm: nothing withers, nothing ranks children, nothing pushes.
//
// - Friendship levels (Pokémon GO's lesson): a day together counts once a day per pair when the two learned on the same
//   day, one sent the other a present, or one cheered the other. Good friends at 1 day, Great at 7, Best at 30; each
//   level opens a shared reward (hooks the game names: a friendship badge, a two-seat rover, a shared room in the
//   colony dome). Days together never fall.
// - Presents a friend opens in the game: a rocket part, seeds, a buddy egg, a quest map piece (ids only: nothing
//   personal travels). One a day to each friend, SENDS_PER_DAY in all; an inbox of INBOX_MAX. A present can also wait
//   on the sender's invite code for the next new friend who joins with it (LINK_GIFTS_MAX). THANK YOU gives the sender
//   THANK_GOLD, at most THANKS_PER_DAY a day.
// - Proud moments (a first landing, a unit or a grade mastered, a wonder's stamp, a deposit found) are told to friends,
//   who send a cheer: one of CHEERS (kind words only, never typed).
// - Study buddies (Duolingo's lesson, without the loss): a shared daily goal with a friend (both learn that day); the
//   days they both learned only grow; a missed day is a rest day.
// - Crews: 2-6 friends, a name of two words from kid-safe lists, a badge, a weekly learning goal (the crew's learning
//   days together), and a page with what each member learned this week (never a ranking).
//
// Records: "together"/"me" per player (server only); "crews"/<id> (the system's). ES5 (Nakama's runtime).

namespace SocialRules {
  export const DAY_MS = 24 * 60 * 60 * 1000;

  // --- Friendship levels ---
  export interface Level {
    at: number; // days together
    id: string;
    reward: string; // a hook the game names ("two_seat_rover")
  }
  export const LEVELS: Level[] = [
    { at: 1, id: "good", reward: "friendship_badge" },
    { at: 7, id: "great", reward: "two_seat_rover" },
    { at: 30, id: "best", reward: "dome_room" },
  ];
  export const FRIENDS_KEPT = 300; // friendships a record keeps

  // --- Presents ---
  export const PRESENT_KINDS = ["rocket_part", "seeds", "buddy_egg", "map_piece"];
  export const SENDS_PER_DAY = 5;
  export const INBOX_MAX = 20;
  export const LINK_GIFTS_MAX = 3;
  export const THANK_GOLD = 10;
  export const THANKS_PER_DAY = 5; // thank-you gold a player receives in a day (times)

  // --- Moments and cheers ---
  export const MOMENT_KINDS = ["landed", "mission", "unit", "grade", "stamp", "deposit"];
  export const PLACE_RE = /^[a-z0-9_.]{1,48}$/;
  export const MOMENTS_PER_DAY = 5;
  export const FEED_MAX = 20;
  export const FRIENDS_TOLD_MAX = 100;
  export const CHEERS = ["well_done", "amazing", "star", "high_five", "so_proud", "you_did_it"];
  export const CHEERS_PER_DAY = 30;

  // --- Study buddies and learning ---
  export const BUDDIES_MAX = 3;
  export const BUDDY_STATES = ["asked", "asking", "yes"]; // asked: I asked; asking: they asked me; yes: buddies
  export const LEARNED_KEEP = 14; // days a record keeps
  export const WEEK_UNITS_MAX = 12;
  export const UNIT_RE = /^g(1[0-2]|[1-9])\.[a-z][a-z_]*\.[a-z0-9_]+$/;

  // --- Crews ---
  export const CREW_MIN = 2;
  export const CREW_MAX = 6;
  export const CREW_INVITES_MAX = 5;
  export const CREW_GOAL_PER_MEMBER = 3; // learning days a week each member brings to the goal
  export const CREW_ADJECTIVES = ["Brave", "Bright", "Clever", "Cosmic", "Curious", "Daring", "Friendly", "Galactic",
    "Happy", "Jolly", "Kind", "Lucky", "Mighty", "Shining", "Speedy", "Starry", "Super", "Swift", "Wise", "Golden"];
  export const CREW_NOUNS = ["Astronauts", "Comets", "Explorers", "Rockets", "Stars", "Planets", "Pioneers", "Inventors",
    "Owls", "Otters", "Foxes", "Dolphins", "Eagles", "Pandas", "Penguins", "Dragons", "Builders", "Scientists", "Voyagers",
    "Moonwalkers"];
  export const BADGES = ["rocket", "star", "moon", "planet", "comet", "owl", "fox", "whale"];
  export const LOOK_KEYS_MAX = 24;
  const LOOK_KEY_RE = /^[a-z_]{1,20}$/;
  const LOOK_TEXT_RE = /^[a-z0-9_#.]{0,24}$/i;

  // --- News a player reads once ---
  export const NEWS_KINDS = ["cheer", "thanks", "present", "link_present", "buddy_ask", "buddy_yes", "crew_invite",
    "crew_join", "level"];
  export const NEWS_MAX = 20;

  export interface Friendship {
    days: number; // days together
    last: number; // the last day counted (a UTC day number; -1 never)
  }

  export interface Buddy {
    state: string; // BUDDY_STATES
    since: number; // the day it began
    days: number; // days both learned since (never falls)
    last: number; // the last shared day counted
  }

  export interface Moment {
    id: string;
    from: string; // the friend's account id
    kind: string;
    place: string;
    at_ms: number;
  }

  export interface Present {
    id: string;
    from: string; // the sender's account id
    kind: string;
    at_ms: number;
    opened: boolean;
    thanked: boolean;
    link: boolean; // it waited on the sender's invite code: from the new friend's guide (not a Nakama friend yet)
  }

  export interface LinkGift {
    kind: string;
    at_ms: number;
  }

  export interface News {
    what: string; // NEWS_KINDS
    id: string; // the friend's account id
    kind: string; // a cheer, a present kind, a level id, a crew id
    gold: number;
    place: string; // for a cheer: the moment ("landed:moon")
    at_ms: number;
  }

  export interface Counts {
    day: number; // the UTC day these counts are for
    sent: number;
    sent_to: string[];
    cheers: number;
    moments: number;
    thanks: number; // thank-you gold received today (times)
  }

  export interface Week {
    week: number;
    days: number; // days learned this week
    last: number; // the last day counted
    units: string[]; // units mastered this week
  }

  export interface CrewInvite {
    crew: string;
    from: string;
    at_ms: number;
  }

  export interface Record {
    friends: { [id: string]: Friendship };
    learned: number[]; // UTC days this player learned (the last LEARNED_KEEP)
    week: Week;
    buddies: { [id: string]: Buddy };
    feed: Moment[]; // friends' proud moments not cheered yet
    presents: Present[]; // the inbox
    link_gifts: LinkGift[]; // presents waiting on the invite code
    news: News[];
    counts: Counts;
    crew: string; // the crew's id ("" none)
    crew_invites: CrewInvite[];
  }

  export interface Crew {
    id: string;
    adjective: string;
    noun: string;
    badge: string;
    maker: string;
    members: string[];
    looks: { [id: string]: Util.Json };
    made_ms: number;
  }

  export function day(ms: number): number {
    return Math.floor(ms / DAY_MS);
  }

  // Weeks start on Monday (day 0, 1970-01-01, was a Thursday).
  export function week(d: number): number {
    return Math.floor((d + 3) / 7);
  }

  // 0 none, 1 good, 2 great, 3 best.
  export function level(days: number): number {
    let out = 0;
    for (let i = 0; i < LEVELS.length; i++) {
      if (days >= LEVELS[i].at) {
        out = i + 1;
      }
    }
    return out;
  }

  export function emptyCounts(d: number): Counts {
    return { day: d, sent: 0, sent_to: [], cheers: 0, moments: 0, thanks: 0 };
  }

  export function emptyRecord(): Record {
    return { friends: {}, learned: [], week: { week: -1, days: 0, last: -1, units: [] }, buddies: {}, feed: [], presents: [],
      link_gifts: [], news: [], counts: emptyCounts(-1), crew: "", crew_invites: [] };
  }

  // The day's counts (a new day starts them again).
  export function today(r: Record, d: number): Counts {
    if (r.counts.day !== d) {
      r.counts = emptyCounts(d);
    }
    return r.counts;
  }

  // One day together with `friendId` on day d: true when it counted (once a day, never back in time).
  export function countDay(r: Record, friendId: string, d: number): boolean {
    let f = Util.has(r.friends as unknown as Util.Json, friendId) ? r.friends[friendId] : null;
    if (f === null) {
      if (Object.keys(r.friends).length >= FRIENDS_KEPT) {
        return false;
      }
      f = { days: 0, last: -1 };
      r.friends[friendId] = f;
    }
    if (d <= f.last) {
      return false;
    }
    f.days += 1;
    f.last = d;
    return true;
  }

  export function days(r: Record, friendId: string): number {
    return Util.has(r.friends as unknown as Util.Json, friendId) ? r.friends[friendId].days : 0;
  }

  // "" or why a present to `friendId` can't go today.
  export function sendCheck(r: Record, friendId: string, d: number): string {
    const c = r.counts.day === d ? r.counts : emptyCounts(d);
    if (c.sent_to.indexOf(friendId) >= 0) {
      return "sent_today";
    }
    return c.sent >= SENDS_PER_DAY ? "too_many_today" : "";
  }

  export function noteSend(r: Record, friendId: string, d: number): void {
    const c = today(r, d);
    c.sent += 1;
    if (friendId !== "" && c.sent_to.indexOf(friendId) < 0) {
      c.sent_to.push(friendId);
    }
  }

  export function sendsLeft(r: Record, d: number): number {
    return r.counts.day === d ? Math.max(SENDS_PER_DAY - r.counts.sent, 0) : SENDS_PER_DAY;
  }

  export function momentCheck(kind: unknown, place: unknown): string {
    return typeof kind === "string" && MOMENT_KINDS.indexOf(kind) >= 0 && typeof place === "string" && PLACE_RE.test(place)
      ? "" : "bad_request";
  }

  export function unitCheck(unit: unknown): boolean {
    return typeof unit === "string" && unit.length <= 64 && UNIT_RE.test(unit);
  }

  // This player learned on day d (each day once; the last LEARNED_KEEP kept).
  export function noteLearned(r: Record, d: number): boolean {
    if (r.learned.indexOf(d) >= 0) {
      return false;
    }
    r.learned.push(d);
    r.learned.sort(function (a: number, b: number): number { return a - b; });
    if (r.learned.length > LEARNED_KEEP) {
      r.learned = r.learned.slice(-LEARNED_KEEP);
    }
    return true;
  }

  // The week's learning (a new week starts at 0): a day once, a unit mastered once.
  export function noteWeek(r: Record, d: number, unit: string): void {
    const w = week(d);
    if (r.week.week !== w) {
      r.week = { week: w, days: 0, last: -1, units: [] };
    }
    if (r.week.last !== d) {
      r.week.days += 1;
      r.week.last = d;
    }
    if (unitCheck(unit) && r.week.units.indexOf(unit) < 0 && r.week.units.length < WEEK_UNITS_MAX) {
      r.week.units.push(unit);
    }
  }

  // The last 7 days ending today, oldest first: 2 both learned, 1 one of them, 0 a rest day (and any day before
  // `since`, the day they became study buddies).
  export function weekRow(mine: number[], theirs: number[], d: number, since?: number): number[] {
    const out: number[] = [];
    const from = since === undefined ? 0 : since;
    for (let i = 6; i >= 0; i--) {
      out.push(d - i < from ? 0 : (mine.indexOf(d - i) >= 0 ? 1 : 0) + (theirs.indexOf(d - i) >= 0 ? 1 : 0));
    }
    return out;
  }

  export function crewNameCheck(adjective: unknown, noun: unknown): string {
    return CREW_ADJECTIVES.indexOf(adjective as string) >= 0 && CREW_NOUNS.indexOf(noun as string) >= 0 ? "" : "bad_name";
  }

  export function badgeCheck(badge: unknown): string {
    return BADGES.indexOf(badge as string) >= 0 ? "" : "bad_badge";
  }

  // Learning days the crew aims for this week (a crew of one waiting for a friend aims for two).
  export function crewGoal(members: number): number {
    return CREW_GOAL_PER_MEMBER * Math.max(members, CREW_MIN);
  }

  // A crew member's avatar look as the game sends it (AvatarLook.to_dict): short ids, colours, numbers and lists of
  // ids; never the boy / girl choice (owner #48: it stays on the device).
  export function lookFrom(v: unknown): Util.Json {
    const out: Util.Json = {};
    if (!Util.isObject(v)) {
      return out;
    }
    let n = 0;
    for (const k in v) {
      if (!Util.has(v, k) || k === "base" || !LOOK_KEY_RE.test(k) || n >= LOOK_KEYS_MAX) {
        continue;
      }
      const x = v[k];
      if (typeof x === "string" && LOOK_TEXT_RE.test(x)) {
        out[k] = x;
      } else if (typeof x === "number" && isFinite(x)) {
        out[k] = x;
      } else if (typeof x === "boolean") {
        out[k] = x;
      } else if (x instanceof Array && x.length <= 8) {
        const list: string[] = [];
        for (let i = 0; i < x.length; i++) {
          if (typeof x[i] === "string" && LOOK_TEXT_RE.test(x[i])) {
            list.push(x[i]);
          }
        }
        out[k] = list;
      } else {
        continue;
      }
      n++;
    }
    return out;
  }

  // Room in the inbox for `more` presents: opened and thanked ones go first, then opened ones (oldest first); never an
  // unopened one. True when there is room.
  export function makeRoom(r: Record, more: number): boolean {
    const drop = function (done: boolean): boolean {
      for (let i = 0; i < r.presents.length; i++) {
        if (r.presents[i].opened && (r.presents[i].thanked || !done)) {
          r.presents.splice(i, 1);
          return true;
        }
      }
      return false;
    };
    while (r.presents.length + more > INBOX_MAX && (drop(true) || drop(false))) {
      // the oldest done present goes first, then the oldest opened one
    }
    if (more === 0 && r.presents.length > INBOX_MAX) {
      r.presents = r.presents.slice(-INBOX_MAX); // a broken record: the newest stay
    }
    return r.presents.length + more <= INBOX_MAX;
  }

  export function addNews(r: Record, n: News): void {
    r.news.push(n);
    if (r.news.length > NEWS_MAX) {
      r.news = r.news.slice(-NEWS_MAX);
    }
  }

  export function addFeed(r: Record, m: Moment): void {
    r.feed.push(m);
    if (r.feed.length > FEED_MAX) {
      r.feed = r.feed.slice(-FEED_MAX);
    }
  }

  function whole(v: unknown): number {
    return Util.isInt(v) && v >= 0 ? v : 0;
  }

  function dayOrNone(v: unknown): number {
    return Util.isInt(v) && v >= -1 ? v : -1;
  }

  function id(v: unknown): boolean {
    return typeof v === "string" && v !== "" && v.length <= 64;
  }

  // A stored record, field by field (a broken field falls back on its own).
  export function recordFrom(value: unknown): Record {
    const r = emptyRecord();
    if (!Util.isObject(value)) {
      return r;
    }
    if (Util.isObject(value.friends)) {
      for (const k in value.friends) {
        const f = value.friends[k];
        if (Util.has(value.friends, k) && id(k) && Util.isObject(f) && Util.isInt(f.days) && f.days >= 0 &&
            Object.keys(r.friends).length < FRIENDS_KEPT) {
          r.friends[k] = { days: f.days, last: dayOrNone(f.last) };
        }
      }
    }
    if (value.learned instanceof Array) {
      for (let i = 0; i < value.learned.length; i++) {
        if (Util.isInt(value.learned[i]) && value.learned[i] >= 0) {
          noteLearned(r, value.learned[i]);
        }
      }
    }
    const w = value.week;
    if (Util.isObject(w) && Util.isInt(w.week)) {
      r.week = { week: w.week, days: whole(w.days), last: dayOrNone(w.last), units: [] };
      if (w.units instanceof Array) {
        for (let i = 0; i < w.units.length && r.week.units.length < WEEK_UNITS_MAX; i++) {
          if (unitCheck(w.units[i]) && r.week.units.indexOf(w.units[i]) < 0) {
            r.week.units.push(w.units[i]);
          }
        }
      }
    }
    if (Util.isObject(value.buddies)) {
      for (const k in value.buddies) {
        const b = value.buddies[k];
        if (Util.has(value.buddies, k) && id(k) && Util.isObject(b) && BUDDY_STATES.indexOf(b.state) >= 0) {
          r.buddies[k] = { state: b.state, since: whole(b.since), days: whole(b.days), last: dayOrNone(b.last) };
        }
      }
    }
    if (value.feed instanceof Array) {
      for (let i = 0; i < value.feed.length; i++) {
        const m = value.feed[i];
        if (Util.isObject(m) && id(m.id) && id(m.from) && momentCheck(m.kind, m.place) === "") {
          addFeed(r, { id: m.id, from: m.from, kind: m.kind, place: m.place, at_ms: whole(m.at_ms) });
        }
      }
    }
    if (value.presents instanceof Array) {
      for (let i = 0; i < value.presents.length; i++) {
        const p = value.presents[i];
        if (Util.isObject(p) && id(p.id) && id(p.from) && PRESENT_KINDS.indexOf(p.kind) >= 0) {
          r.presents.push({ id: p.id, from: p.from, kind: p.kind, at_ms: whole(p.at_ms), opened: p.opened === true,
            thanked: p.thanked === true, link: p.link === true });
        }
      }
      makeRoom(r, 0);
    }
    if (value.link_gifts instanceof Array) {
      for (let i = 0; i < value.link_gifts.length && r.link_gifts.length < LINK_GIFTS_MAX; i++) {
        const g = value.link_gifts[i];
        if (Util.isObject(g) && PRESENT_KINDS.indexOf(g.kind) >= 0) {
          r.link_gifts.push({ kind: g.kind, at_ms: whole(g.at_ms) });
        }
      }
    }
    if (value.news instanceof Array) {
      for (let i = 0; i < value.news.length; i++) {
        const n = value.news[i];
        if (Util.isObject(n) && NEWS_KINDS.indexOf(n.what) >= 0 && typeof n.id === "string") {
          addNews(r, { what: n.what, id: n.id, kind: typeof n.kind === "string" ? n.kind : "", gold: whole(n.gold),
            place: typeof n.place === "string" ? n.place : "", at_ms: whole(n.at_ms) });
        }
      }
    }
    const c = value.counts;
    if (Util.isObject(c) && Util.isInt(c.day)) {
      const to: string[] = [];
      if (c.sent_to instanceof Array) {
        for (let i = 0; i < c.sent_to.length && to.length < SENDS_PER_DAY; i++) {
          if (id(c.sent_to[i])) {
            to.push(c.sent_to[i]);
          }
        }
      }
      r.counts = { day: c.day, sent: whole(c.sent), sent_to: to, cheers: whole(c.cheers), moments: whole(c.moments),
        thanks: whole(c.thanks) };
    }
    r.crew = id(value.crew) ? value.crew : "";
    if (value.crew_invites instanceof Array) {
      for (let i = 0; i < value.crew_invites.length && r.crew_invites.length < CREW_INVITES_MAX; i++) {
        const v = value.crew_invites[i];
        if (Util.isObject(v) && id(v.crew) && id(v.from)) {
          r.crew_invites.push({ crew: v.crew, from: v.from, at_ms: whole(v.at_ms) });
        }
      }
    }
    return r;
  }

  export function crewFrom(value: unknown): Crew | null {
    if (!Util.isObject(value) || !id(value.id) || crewNameCheck(value.adjective, value.noun) !== "" ||
        badgeCheck(value.badge) !== "") {
      return null;
    }
    const members: string[] = [];
    const list = value.members instanceof Array ? value.members : [];
    for (let i = 0; i < list.length && members.length < CREW_MAX; i++) {
      if (id(list[i]) && members.indexOf(list[i]) < 0) {
        members.push(list[i]);
      }
    }
    const looks: { [id: string]: Util.Json } = {};
    if (Util.isObject(value.looks)) {
      for (let i = 0; i < members.length; i++) {
        if (Util.has(value.looks, members[i])) {
          looks[members[i]] = lookFrom(value.looks[members[i]]);
        }
      }
    }
    return { id: value.id, adjective: value.adjective, noun: value.noun, badge: value.badge,
      maker: typeof value.maker === "string" ? value.maker : "", members: members, looks: looks, made_ms: whole(value.made_ms) };
  }
}
