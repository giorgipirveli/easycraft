// The invite (referral) program (owner #79, #81, #82, #85; spec §25.2; the world game plan §2, §2b), as pure rules.
// "Bringing a friend brings a friend to school": every reward is tied to learning.
//
// - Every player has an invite code of two kid-safe words and a number (BLUE-OTTER-42); a grown-up can make one class
//   code (CLASS-JADE-OWL-27) and one family code (FAMILY-MINT-YAK-11). A code is typed any way (case, spaces, dashes).
// - A NEW account (younger than NEW_ACCOUNT_MS) that uses a friend's code gets WELCOME_GOLD at once, once in its life,
//   never with its own code. A class or family code: anyone joins its group (one class, one family); a new account
//   is also its maker's referral (the welcome gift, the maker's rewards).
// - The inviter gets INVITER_GOLD when the friend really learns (their first School unit mastered, reported once),
//   and the friend LEARNER_GOLD with it (both win); the inviter's own inviter a small TREE_GOLD (the Explorer Tree:
//   two levels, never deeper); a friend's first Moon landing LANDED_GOLD. Each kind within a rolling monthly cap
//   (CAPS): past it, the friend still counts in the tree and the ranks, without gold.
// - Nothing about the friend is kept but account ids and the dates (names are read from the accounts when shown).
//
// Records: "referrals"/"me" per player (server only), "invite_codes"/<canonical code> and "invite_groups"/<canonical
// code> (the system's). Everything here is ES5 (Nakama's runtime).

namespace ReferralRules {
  export const KIND_FRIEND = "friend";
  export const KIND_CLASS = "class";
  export const KIND_FAMILY = "family";
  export const GROUP_KINDS = [KIND_CLASS, KIND_FAMILY];
  export const PREFIX: { [kind: string]: string } = { class: "CLASS", family: "FAMILY" };

  // Short words a child reads and types; every pair with every number passes the name filter (the tests).
  export const ADJECTIVES: string[] = ["RED", "BLUE", "GREEN", "GOLD", "PINK", "TEAL", "MINT", "RUBY", "JADE", "AQUA",
    "SUNNY", "HAPPY", "BRAVE", "CALM", "KIND", "SWIFT", "BRIGHT", "LUCKY", "JOLLY", "COSMIC", "STARRY", "MISTY", "SNOWY",
    "LEAFY", "SANDY", "SILVER", "AMBER", "CORAL", "LEMON", "PLUM", "CLEVER", "GENTLE"];
  export const ANIMALS: string[] = ["OTTER", "PANDA", "KOALA", "TIGER", "LION", "ZEBRA", "HIPPO", "RHINO", "MOOSE",
    "BISON", "LLAMA", "CAMEL", "PONY", "BUNNY", "MOUSE", "BEAVER", "BADGER", "FOX", "WOLF", "BEAR", "SEAL", "WHALE",
    "DOLPHIN", "TURTLE", "GECKO", "FROG", "OWL", "EAGLE", "HAWK", "ROBIN", "WREN", "PARROT", "PENGUIN", "PUFFIN", "SWAN",
    "DUCK", "CRANE", "FINCH", "BEE", "CRAB", "SLOTH", "LEMUR", "MEERKAT", "YAK", "GOAT", "LAMB", "KITTEN", "PUPPY",
    "DRAGON", "UNICORN"];
  export const NUMBER_MIN = 10;
  export const NUMBER_MAX = 99; // two digits: BLUE-OTTER-42
  export const WIDE_NUMBER_MAX = 9999; // when two-digit codes keep clashing (a big game)
  export const MAX_TYPED = 40;

  // The rewards (Survivor gold; the game's EarnRules names them for the child).
  export const WELCOME_GOLD = 100; // the new friend, at once
  export const INVITER_GOLD = 250; // the inviter, when the friend learned (about a day of learning, EarnRules)
  export const LEARNER_GOLD = 50; // the friend too, when they learned: both win
  export const TREE_GOLD = 25; // the inviter's inviter, when a friend's friend learned
  export const LANDED_GOLD = 150; // the inviter, when the friend first lands on the Moon
  export const WINDOW_MS = 30 * 24 * 60 * 60 * 1000;
  export const CAPS = { learned: 10, tree: 20, landed: 10 }; // rewards with gold per rolling 30 days, per inviter
  export const NEW_ACCOUNT_MS = 14 * 24 * 60 * 60 * 1000;
  export const MAX_FRIENDS = 500;
  export const TREE_READ = 100; // friends whose own friends are counted (the tree's second level)
  export const MAX_NEWS = 20;
  export const GROUP_MAX = { class: 40, family: 12 };
  export const WRONG_MAX = 5; // wrong codes in the window lock typing for the window
  export const WRONG_WINDOW_MS = 15 * 60 * 1000;
  export const EVENTS = ["learned", "landed"];
  export const LANDED_PLACES = ["moon"];
  export const NEWS_KINDS = ["joined", "learned", "tree", "landed"];

  export interface Friend {
    id: string;
    at_ms: number; // when they used this player's code
    learned_ms: number; // when they first learned (0: not yet)
    landed_ms: number; // when they first landed on the Moon (0: not yet)
  }

  export interface By {
    user_id: string; // "" when that account was deleted
    kind: string;
    at_ms: number;
  }

  export interface News {
    what: string; // NEWS_KINDS
    id: string; // the friend's account ("" for the tree: a friend's friend is never named)
    gold: number;
    at_ms: number;
  }

  export interface Record {
    code: string; // this player's own code ("" until made)
    made: { [kind: string]: string }; // the class and family codes this account made
    by: By | null; // who brought this player: once, forever
    learned_ms: number; // this player's first School unit mastered, as reported (the reward ran)
    landed_ms: number; // this player's first Moon landing (the inviter's bonus ran)
    groups: { [kind: string]: string }; // the class and the family this player is in
    friends: Friend[]; // accounts this player brought, oldest first
    times: { [kind: string]: number[] }; // when each capped reward was paid (the rolling window)
    earned: number; // gold from invites, all time
    news: News[]; // not shown yet, newest last
  }

  export interface CodeInfo {
    user_id: string;
    kind: string;
    code: string; // as shown
    made_ms: number;
  }

  export interface Group {
    kind: string;
    owner_id: string;
    code: string;
    members: string[];
    made_ms: number;
  }

  // What a person typed, as the code's key: capitals and digits only ("" when it can't be a code).
  export function canonical(text: unknown): string {
    if (typeof text !== "string" || text.length > MAX_TYPED) {
      return "";
    }
    let out = "";
    const upper = text.toUpperCase();
    for (let i = 0; i < upper.length; i++) {
      const c = upper.charCodeAt(i);
      if ((c >= 65 && c <= 90) || (c >= 48 && c <= 57)) {
        out += upper.charAt(i);
      } else if (c !== 32 && c !== 45 && c !== 95 && c !== 9) {
        return ""; // letters and digits of the codes only, with spaces, dashes or underscores between
      }
    }
    return out;
  }

  // A new code as shown (pick(n) gives 0..n-1). `wide`: numbers up to WIDE_NUMBER_MAX.
  export function makeCode(kind: string, pick: (n: number) => number, wide: boolean): string {
    const adjective = ADJECTIVES[pick(ADJECTIVES.length)];
    const animal = ANIMALS[pick(ANIMALS.length)];
    const top = wide ? WIDE_NUMBER_MAX : NUMBER_MAX;
    const number = NUMBER_MIN + pick(top - NUMBER_MIN + 1);
    const words = adjective + "-" + animal + "-" + number;
    return Util.has(PREFIX, kind) ? PREFIX[kind] + "-" + words : words;
  }

  // An account created at createdMs (0: unknown, counted as new) is new enough to be brought by a friend.
  export function isNewAccount(createdMs: number, nowMs: number): boolean {
    return createdMs <= 0 || nowMs - createdMs <= NEW_ACCOUNT_MS;
  }

  export function emptyRecord(): Record {
    return { code: "", made: {}, by: null, learned_ms: 0, landed_ms: 0, groups: {}, friends: [],
      times: { learned: [], tree: [], landed: [] }, earned: 0, news: [] };
  }

  function whole(v: unknown): number {
    return Util.isInt(v) && v >= 0 ? v : 0;
  }

  function kindCodes(v: unknown): { [kind: string]: string } {
    const out: { [kind: string]: string } = {};
    if (!Util.isObject(v)) {
      return out;
    }
    for (let i = 0; i < GROUP_KINDS.length; i++) {
      const k = GROUP_KINDS[i];
      if (typeof v[k] === "string" && canonical(v[k]) !== "") {
        out[k] = v[k];
      }
    }
    return out;
  }

  function times(v: unknown): number[] {
    const out: number[] = [];
    if (v instanceof Array) {
      for (let i = 0; i < v.length; i++) {
        if (Util.isInt(v[i])) {
          out.push(v[i]);
        }
      }
    }
    return out;
  }

  // A stored record, field by field (a broken field falls back on its own).
  export function recordFrom(value: unknown): Record {
    const r = emptyRecord();
    if (!Util.isObject(value)) {
      return r;
    }
    r.code = typeof value.code === "string" && canonical(value.code) !== "" ? value.code : "";
    r.made = kindCodes(value.made);
    const by = value.by;
    if (Util.isObject(by) && typeof by.user_id === "string" && typeof by.kind === "string" && Util.isInt(by.at_ms)) {
      r.by = { user_id: by.user_id, kind: by.kind, at_ms: by.at_ms };
    }
    r.learned_ms = whole(value.learned_ms);
    r.landed_ms = whole(value.landed_ms);
    r.groups = kindCodes(value.groups);
    if (value.friends instanceof Array) {
      for (let i = 0; i < value.friends.length && r.friends.length < MAX_FRIENDS; i++) {
        const f = value.friends[i];
        if (Util.isObject(f) && typeof f.id === "string" && f.id !== "") {
          r.friends.push({ id: f.id, at_ms: whole(f.at_ms), learned_ms: whole(f.learned_ms), landed_ms: whole(f.landed_ms) });
        }
      }
    }
    const t = Util.isObject(value.times) ? value.times : {};
    r.times = { learned: times(t.learned), tree: times(t.tree), landed: times(t.landed) };
    r.earned = whole(value.earned);
    if (value.news instanceof Array) {
      for (let i = 0; i < value.news.length; i++) {
        const n = value.news[i];
        if (Util.isObject(n) && typeof n.what === "string" && NEWS_KINDS.indexOf(n.what) >= 0 && typeof n.id === "string") {
          r.news.push({ what: n.what, id: n.id, gold: whole(n.gold), at_ms: whole(n.at_ms) });
        }
      }
      r.news = r.news.slice(-MAX_NEWS);
    }
    return r;
  }

  export function codeInfoFrom(value: unknown): CodeInfo | null {
    if (!Util.isObject(value) || typeof value.user_id !== "string" || value.user_id === "" || typeof value.code !== "string" ||
        [KIND_FRIEND, KIND_CLASS, KIND_FAMILY].indexOf(value.kind) < 0) {
      return null;
    }
    return { user_id: value.user_id, kind: value.kind, code: value.code, made_ms: whole(value.made_ms) };
  }

  export function groupFrom(value: unknown): Group | null {
    if (!Util.isObject(value) || GROUP_KINDS.indexOf(value.kind) < 0 || typeof value.owner_id !== "string" ||
        typeof value.code !== "string") {
      return null;
    }
    const members: string[] = [];
    const list = value.members instanceof Array ? value.members : [];
    for (let i = 0; i < list.length; i++) {
      if (typeof list[i] === "string" && list[i] !== "" && members.indexOf(list[i]) < 0) {
        members.push(list[i]);
      }
    }
    return { kind: value.kind, owner_id: value.owner_id, code: value.code, members: members, made_ms: whole(value.made_ms) };
  }

  // Using the code `info` (null: no such code) by `callerId`, whose account was made at createdMs: "" or the error,
  // whether it is a referral (the welcome gift, the maker's rewards later) and the group it joins ("" for none).
  // groupSize: how many are in that group now.
  export function useCheck(me: Record, info: CodeInfo | null, callerId: string, createdMs: number, nowMs: number,
      groupSize: number): { error: string; referral: boolean; group: string } {
    const no = function (error: string) {
      return { error: error, referral: false, group: "" };
    };
    if (info === null) {
      return no("unknown");
    }
    if (info.user_id === callerId) {
      return no("own_code");
    }
    const fresh = isNewAccount(createdMs, nowMs);
    if (info.kind === KIND_FRIEND) {
      if (me.by !== null) {
        return no("already_used");
      }
      return fresh ? { error: "", referral: true, group: "" } : no("not_new");
    }
    if (Util.has(me.groups, info.kind)) {
      return no("already_in");
    }
    const max = info.kind === KIND_CLASS ? GROUP_MAX.class : GROUP_MAX.family;
    if (groupSize >= max) {
      return no("group_full");
    }
    return { error: "", referral: me.by === null && fresh, group: info.kind };
  }

  export function addFriend(r: Record, friendId: string, nowMs: number): boolean {
    if (r.friends.length >= MAX_FRIENDS || findFriend(r, friendId) !== null) {
      return false;
    }
    r.friends.push({ id: friendId, at_ms: nowMs, learned_ms: 0, landed_ms: 0 });
    return true;
  }

  export function findFriend(r: Record, friendId: string): Friend | null {
    for (let i = 0; i < r.friends.length; i++) {
      if (r.friends[i].id === friendId) {
        return r.friends[i];
      }
    }
    return null;
  }

  export function markLearned(r: Record, friendId: string, nowMs: number): boolean {
    const f = findFriend(r, friendId);
    if (f === null || f.learned_ms > 0) {
      return false;
    }
    f.learned_ms = nowMs;
    return true;
  }

  export function markLanded(r: Record, friendId: string, nowMs: number): boolean {
    const f = findFriend(r, friendId);
    if (f === null || f.landed_ms > 0) {
      return false;
    }
    f.landed_ms = nowMs;
    return true;
  }

  export function counts(r: Record): { friends: number; learned: number } {
    let learned = 0;
    for (let i = 0; i < r.friends.length; i++) {
      if (r.friends[i].learned_ms > 0) {
        learned++;
      }
    }
    return { friends: r.friends.length, learned: learned };
  }

  function recent(list: number[], nowMs: number): number[] {
    const out: number[] = [];
    for (let i = 0; i < list.length; i++) {
      if (nowMs - list[i] < WINDOW_MS) {
        out.push(list[i]);
      }
    }
    return out;
  }

  // Whether one more reward of a kind fits in its monthly cap.
  export function hasRoom(list: number[], cap: number, nowMs: number): boolean {
    return recent(list, nowMs).length < cap;
  }

  // The list with a reward at nowMs (older than the window left out).
  export function take(list: number[], nowMs: number): number[] {
    const out = recent(list, nowMs);
    out.push(nowMs);
    return out;
  }

  export function addNews(r: Record, n: News): void {
    r.news.push(n);
    if (r.news.length > MAX_NEWS) {
      r.news = r.news.slice(-MAX_NEWS);
    }
  }
}
