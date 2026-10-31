// The "better together" half of the world game plan on Nakama (owner #81, #82, #85; module 0.2.18): the rules are
// SocialRules. Everything is between mutual friends who may be online (AccountRules.canPlayOnline), except a present
// that waited on an invite code (it comes from the new friend's guide) and its thank-you.
//
//   together/me   (per player, server only) SocialRules.Record: friendships (days together), the days this player
//                 learned, the week's learning, study buddies, friends' moments to cheer, the presents' inbox, presents
//                 waiting on the invite code, the day's counts, news, the crew and crew invitations
//   crews/<id>    (the system's) SocialRules.Crew: the name's two words, the badge, the members and their looks
//
// Gold (a thank-you) goes into the Nakama wallet with a ledger entry {"source": "together", "reason": "thanks"}; the
// game's wallet sync brings it to the phone. Notification 109 {"what"} nudges an open game (not persistent: the
// record is the mailbox). Everything a friend sees of another is their in-game name, ids of things and counts.

namespace Together {
  export const RECORD = "together";
  export const KEY = "me";
  export const CREWS = "crews";
  export const OWN_COLLECTIONS = [RECORD];
  export const NOTE = 109;
  const ACTIONS_BUDDY = ["ask", "yes", "no", "stop"];

  export interface Loaded {
    record: SocialRules.Record;
    version: string; // "" when there is none yet
  }

  export function load(nk: nkruntime.Nakama, userId: string): Loaded {
    const found = Store.read(nk, RECORD, KEY, userId);
    return { record: SocialRules.recordFrom(found ? found.value : undefined), version: found ? found.version : "" };
  }

  function exists(nk: nkruntime.Nakama, userId: string): boolean {
    return userId !== "" && nk.usersGetId([userId]).length > 0;
  }

  // Changes a player's record by version (another call at the same moment: read again). `change` returns false when
  // there is nothing to write. The record as written (or read), or null when the account is gone.
  export function update(nk: nkruntime.Nakama, userId: string,
      change: (r: SocialRules.Record) => boolean): SocialRules.Record | null {
    if (!exists(nk, userId)) {
      return null;
    }
    for (let attempt = 0; attempt < 5; attempt++) {
      const l = load(nk, userId);
      if (!change(l.record)) {
        return l.record;
      }
      try {
        Store.write(nk, RECORD, KEY, userId, l.record as unknown as Util.Json, false, l.version === "" ? "*" : l.version);
        return l.record;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    throw new Error("busy");
  }

  function readCrew(nk: nkruntime.Nakama, crewId: string): { crew: SocialRules.Crew | null; version: string } {
    if (crewId === "") {
      return { crew: null, version: "" };
    }
    const found = Store.read(nk, CREWS, crewId, Store.SYSTEM_USER);
    return { crew: found ? SocialRules.crewFrom(found.value) : null, version: found ? found.version : "" };
  }

  // Changes a crew by version; a crew left with no members goes. The crew as written (null: gone, or it had gone).
  function updateCrew(nk: nkruntime.Nakama, crewId: string, change: (c: SocialRules.Crew) => boolean): SocialRules.Crew | null {
    for (let attempt = 0; attempt < 5; attempt++) {
      const r = readCrew(nk, crewId);
      if (r.crew === null) {
        return null;
      }
      if (!change(r.crew)) {
        return r.crew;
      }
      try {
        if (r.crew.members.length === 0) {
          Store.remove(nk, CREWS, crewId, Store.SYSTEM_USER);
          return null;
        }
        Store.write(nk, CREWS, crewId, Store.SYSTEM_USER, r.crew as unknown as Util.Json, false, r.version);
        return r.crew;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    throw new Error("busy");
  }

  function nudge(nk: nkruntime.Nakama, userId: string, what: string): void {
    try {
      nk.notificationSend(userId, "Friends", { what: what }, NOTE, null, false);
    } catch (_e) {
      // a nudge only: the record has it
    }
  }

  function allowed(nk: nkruntime.Nakama, userId: string): boolean {
    return AccountRules.canPlayOnline(Accounts.load(nk, userId).state);
  }

  // The player's mutual friends who may be online.
  export function friendIds(nk: nkruntime.Nakama, userId: string): string[] {
    const ids = Gifts.friendIds(nk, userId);
    const states = Accounts.states(nk, ids);
    const out: string[] = [];
    for (let i = 0; i < ids.length; i++) {
      if (Util.has(states as unknown as Util.Json, ids[i]) && AccountRules.canPlayOnline(states[ids[i]])) {
        out.push(ids[i]);
      }
    }
    return out;
  }

  // One day together for a and b (both records; a level reached is news for each).
  function pairDay(nk: nkruntime.Nakama, a: string, b: string, d: number, nowMs: number): boolean {
    let counted = false;
    const one = function (self: string, other: string): void {
      update(nk, self, function (r: SocialRules.Record): boolean {
        const before = SocialRules.level(SocialRules.days(r, other));
        if (!SocialRules.countDay(r, other, d)) {
          return false;
        }
        counted = true;
        const after = SocialRules.level(SocialRules.days(r, other));
        if (after > before) {
          SocialRules.addNews(r, { what: "level", id: other, kind: SocialRules.LEVELS[after - 1].id, gold: 0, place: "",
            at_ms: nowMs });
        }
        return true;
      });
    };
    one(a, b);
    one(b, a);
    return counted;
  }

  function newId(nk: nkruntime.Nakama, prefix: string, nowMs: number): string {
    return GiftRules.keyFor(prefix, nowMs, nk.uuidv4());
  }

  // --- social_info ---

  export function info(nk: nkruntime.Nakama, userId: string, seen: boolean, nowMs: number): Util.Json {
    const d = SocialRules.day(nowMs);
    const may = allowed(nk, userId);
    const r = load(nk, userId).record;
    const friends = may ? friendIds(nk, userId) : [];
    const theirs = Store.readMany(nk, RECORD, KEY, friends);
    let ids = friends.slice();
    for (let i = 0; i < r.presents.length; i++) {
      ids.push(r.presents[i].from);
    }
    for (let i = 0; i < r.news.length; i++) {
      ids.push(r.news[i].id);
    }
    for (let i = 0; i < r.crew_invites.length; i++) {
      ids.push(r.crew_invites[i].from);
    }
    const known = Referrals.names(nk, ids);
    const friendsOut: Util.Json[] = [];
    for (let i = 0; i < friends.length; i++) {
      const id = friends[i];
      if (!Util.has(known, id)) {
        continue;
      }
      const f = Util.has(r.friends as unknown as Util.Json, id) ? r.friends[id] : null;
      const b = Util.has(r.buddies as unknown as Util.Json, id) ? r.buddies[id] : null;
      const other = SocialRules.recordFrom(Util.has(theirs, id) ? theirs[id].value : undefined);
      const days = f ? f.days : 0;
      friendsOut.push({
        id: id, name: known[id], days: days, level: SocialRules.level(days), today: f !== null && f.last === d,
        buddy: {
          state: b ? b.state : "", days: b ? b.days : 0,
          row: b && b.state === "yes" ? SocialRules.weekRow(r.learned, other.learned, d, b.since) : [0, 0, 0, 0, 0, 0, 0],
        },
      });
    }
    friendsOut.sort(function (x: Util.Json, y: Util.Json): number {
      return x.name.toLowerCase() < y.name.toLowerCase() ? -1 : x.name.toLowerCase() > y.name.toLowerCase() ? 1 : 0;
    });
    // What no longer belongs: moments of players who are not friends now, presents of those (a guide's waiting
    // present stays while the guide's account exists), news naming deleted accounts.
    const feed: Util.Json[] = [];
    const keepFeed: string[] = [];
    for (let i = 0; i < r.feed.length; i++) {
      const m = r.feed[i];
      if (friends.indexOf(m.from) >= 0) {
        keepFeed.push(m.id);
        feed.push({ id: m.id, name: known[m.from], kind: m.kind, place: m.place, at_ms: m.at_ms });
      }
    }
    const presents: Util.Json[] = [];
    const keepPresents: string[] = [];
    for (let i = 0; i < r.presents.length; i++) {
      const p = r.presents[i];
      if (Util.has(known, p.from) && (p.link || friends.indexOf(p.from) >= 0)) {
        keepPresents.push(p.id);
        presents.push({ id: p.id, name: known[p.from], kind: p.kind, at_ms: p.at_ms, opened: p.opened, thanked: p.thanked,
          link: p.link });
      }
    }
    const news: Util.Json[] = [];
    for (let i = 0; i < r.news.length; i++) {
      const n = r.news[i];
      if (Util.has(known, n.id)) {
        news.push({ what: n.what, name: known[n.id], kind: n.kind, gold: n.gold, place: n.place, at_ms: n.at_ms });
      }
    }
    const crewNow = r.crew !== "" ? readCrew(nk, r.crew).crew : null;
    const inCrew = crewNow !== null && crewNow.members.indexOf(userId) >= 0;
    const invites: Util.Json[] = [];
    for (let i = 0; i < r.crew_invites.length; i++) {
      const v = r.crew_invites[i];
      const c = readCrew(nk, v.crew).crew;
      if (c !== null && c.members.indexOf(userId) < 0 && Util.has(known, v.from)) {
        invites.push({ crew: c.id, name: c.adjective + " " + c.noun, badge: c.badge, from: known[v.from],
          members: c.members.length, full: c.members.length >= SocialRules.CREW_MAX });
      }
    }
    const tidy = keepFeed.length !== r.feed.length || keepPresents.length !== r.presents.length || (r.crew !== "" && !inCrew);
    if (tidy || (seen && r.news.length > 0)) {
      update(nk, userId, function (x: SocialRules.Record): boolean {
        x.feed = x.feed.filter(function (m: SocialRules.Moment): boolean { return keepFeed.indexOf(m.id) >= 0; });
        x.presents = x.presents.filter(function (p: SocialRules.Present): boolean {
          return keepPresents.indexOf(p.id) >= 0 || p.at_ms >= nowMs; // a present that came since stays
        });
        if (seen) {
          x.news = [];
        }
        if (x.crew !== "" && !inCrew) {
          x.crew = "";
        }
        return true;
      });
    }
    return {
      ok: true, allowed: may, friends: friendsOut, feed: feed, presents: presents,
      link_gifts: r.link_gifts.map(function (g: SocialRules.LinkGift): string { return g.kind; }),
      news: news, crew: inCrew ? crewOut(nk, crewNow as SocialRules.Crew, userId, d) : null, crew_invites: invites,
      sends_left: SocialRules.sendsLeft(r, d),
      cheers_left: r.counts.day === d ? Math.max(SocialRules.CHEERS_PER_DAY - r.counts.cheers, 0) : SocialRules.CHEERS_PER_DAY,
      rules: rules(),
    };
  }

  function rules(): Util.Json {
    const levels: number[] = [];
    const ids: string[] = [];
    const rewards: string[] = [];
    for (let i = 0; i < SocialRules.LEVELS.length; i++) {
      levels.push(SocialRules.LEVELS[i].at);
      ids.push(SocialRules.LEVELS[i].id);
      rewards.push(SocialRules.LEVELS[i].reward);
    }
    return {
      levels: levels, level_ids: ids, level_rewards: rewards, sends_per_day: SocialRules.SENDS_PER_DAY,
      link_gifts_max: SocialRules.LINK_GIFTS_MAX, inbox_max: SocialRules.INBOX_MAX, thank_gold: SocialRules.THANK_GOLD,
      thanks_per_day: SocialRules.THANKS_PER_DAY, moments_per_day: SocialRules.MOMENTS_PER_DAY,
      cheers_per_day: SocialRules.CHEERS_PER_DAY, cheers: SocialRules.CHEERS, present_kinds: SocialRules.PRESENT_KINDS,
      buddies_max: SocialRules.BUDDIES_MAX, crew_min: SocialRules.CREW_MIN, crew_max: SocialRules.CREW_MAX,
      crew_goal_per_member: SocialRules.CREW_GOAL_PER_MEMBER,
    };
  }

  // The crew's page: each member's name, look and week (never a ranking), the goal.
  function crewOut(nk: nkruntime.Nakama, c: SocialRules.Crew, userId: string, d: number): Util.Json {
    const records = Store.readMany(nk, RECORD, KEY, c.members);
    const names = Referrals.names(nk, c.members);
    const w = SocialRules.week(d);
    let done = 0;
    const members: Util.Json[] = [];
    for (let i = 0; i < c.members.length; i++) {
      const id = c.members[i];
      if (!Util.has(names, id)) {
        continue;
      }
      const rec = SocialRules.recordFrom(Util.has(records, id) ? records[id].value : undefined);
      const wk = rec.week.week === w ? { days: rec.week.days, units: rec.week.units.slice() } : { days: 0, units: [] };
      done += Math.min(wk.days, 7);
      members.push({ name: names[id], me: id === userId, look: Util.has(c.looks, id) ? c.looks[id] : {}, week: wk });
    }
    return {
      id: c.id, name: c.adjective + " " + c.noun, adjective: c.adjective, noun: c.noun, badge: c.badge,
      mine: c.maker === userId, members: members,
      goal: { done: done, target: SocialRules.crewGoal(members.length) }, full: members.length >= SocialRules.CREW_MAX,
    };
  }

  // --- social_learned ---

  export function learned(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const d = SocialRules.day(nowMs);
    const unit = SocialRules.unitCheck(request.unit) ? request.unit as string : "";
    let first = false;
    update(nk, userId, function (r: SocialRules.Record): boolean {
      const before = JSON.stringify(r.week);
      first = SocialRules.noteLearned(r, d);
      SocialRules.noteWeek(r, d, unit);
      return first || JSON.stringify(r.week) !== before;
    });
    if (!first || !allowed(nk, userId)) {
      return { ok: true, first: first, together: 0 };
    }
    const friends = friendIds(nk, userId);
    const records = Store.readMany(nk, RECORD, KEY, friends);
    const mine = load(nk, userId).record;
    let together = 0;
    for (let i = 0; i < friends.length; i++) {
      const id = friends[i];
      const other = SocialRules.recordFrom(Util.has(records, id) ? records[id].value : undefined);
      if (other.learned.indexOf(d) < 0) {
        continue;
      }
      together++;
      pairDay(nk, userId, id, d, nowMs);
      const b = Util.has(mine.buddies as unknown as Util.Json, id) ? mine.buddies[id] : null;
      const theirs = Util.has(other.buddies as unknown as Util.Json, userId) ? other.buddies[userId] : null;
      if (b !== null && b.state === "yes" && theirs !== null && theirs.state === "yes") {
        buddyDay(nk, userId, id, d);
      }
    }
    return { ok: true, first: true, together: together };
  }

  // A day both study buddies learned (once a day, both records).
  function buddyDay(nk: nkruntime.Nakama, a: string, b: string, d: number): void {
    const shared = function (self: string, pal: string): void {
      update(nk, self, function (r: SocialRules.Record): boolean {
        const x = Util.has(r.buddies as unknown as Util.Json, pal) ? r.buddies[pal] : null;
        if (x === null || x.state !== "yes" || x.last >= d) {
          return false;
        }
        x.days += 1;
        x.last = d;
        return true;
      });
    };
    shared(a, b);
    shared(b, a);
  }

  // --- social_moment and social_cheer ---

  export function moment(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    if (!allowed(nk, userId)) {
      return Server.fail("not_allowed_online");
    }
    if (SocialRules.momentCheck(request.kind, request.place) !== "") {
      return Server.fail("bad_request");
    }
    const d = SocialRules.day(nowMs);
    let full = false;
    update(nk, userId, function (r: SocialRules.Record): boolean {
      const c = SocialRules.today(r, d);
      if (c.moments >= SocialRules.MOMENTS_PER_DAY) {
        full = true;
        return false;
      }
      c.moments += 1;
      return true;
    });
    if (full) {
      return Server.fail("too_many_today");
    }
    const id = newId(nk, "m", nowMs);
    const friends = friendIds(nk, userId).slice(0, SocialRules.FRIENDS_TOLD_MAX);
    let told = 0;
    for (let i = 0; i < friends.length; i++) {
      const done = update(nk, friends[i], function (r: SocialRules.Record): boolean {
        SocialRules.addFeed(r, { id: id, from: userId, kind: request.kind as string, place: request.place as string, at_ms: nowMs });
        return true;
      });
      if (done !== null) {
        told++;
        nudge(nk, friends[i], "moment");
      }
    }
    return { ok: true, told: told };
  }

  export function cheer(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    if (typeof request.moment_id !== "string" || SocialRules.CHEERS.indexOf(request.cheer as string) < 0) {
      return Server.fail("bad_request");
    }
    if (!allowed(nk, userId)) {
      return Server.fail("not_allowed_online");
    }
    const d = SocialRules.day(nowMs);
    const r = load(nk, userId).record;
    let m: SocialRules.Moment | null = null;
    for (let i = 0; i < r.feed.length; i++) {
      if (r.feed[i].id === request.moment_id) {
        m = r.feed[i];
      }
    }
    if (m === null) {
      return Server.fail("not_found");
    }
    const from = m.from;
    const drop = function (x: SocialRules.Record): void {
      x.feed = x.feed.filter(function (f: SocialRules.Moment): boolean { return f.id !== request.moment_id; });
    };
    if (!exists(nk, from) || !Social.areFriends(nk, userId, from)) {
      update(nk, userId, function (x: SocialRules.Record): boolean {
        drop(x);
        return true;
      });
      return Server.fail("not_found");
    }
    let full = false;
    update(nk, userId, function (x: SocialRules.Record): boolean {
      const c = SocialRules.today(x, d);
      if (c.cheers >= SocialRules.CHEERS_PER_DAY) {
        full = true;
        return false;
      }
      c.cheers += 1;
      drop(x);
      return true;
    });
    if (full) {
      return Server.fail("too_many_today");
    }
    const place = m.kind + ":" + m.place;
    update(nk, from, function (x: SocialRules.Record): boolean {
      SocialRules.addNews(x, { what: "cheer", id: userId, kind: request.cheer as string, gold: 0, place: place, at_ms: nowMs });
      return true;
    });
    pairDay(nk, userId, from, d, nowMs);
    nudge(nk, from, "cheer");
    return { ok: true };
  }

  // --- Presents ---

  export function send(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    if (SocialRules.PRESENT_KINDS.indexOf(request.kind as string) < 0) {
      return Server.fail("bad_request");
    }
    const kind = request.kind as string;
    const me = Accounts.load(nk, userId);
    if (!AccountRules.canPlayOnline(me.state)) {
      return Server.fail("not_allowed_online");
    }
    const d = SocialRules.day(nowMs);
    if (request.link === true) {
      if (!me.state.claimed) {
        return Server.fail("not_claimed");
      }
      let why = "";
      const r = update(nk, userId, function (x: SocialRules.Record): boolean {
        why = x.link_gifts.length >= SocialRules.LINK_GIFTS_MAX ? "too_many_waiting" : SocialRules.sendCheck(x, "", d);
        if (why !== "") {
          return false;
        }
        x.link_gifts.push({ kind: kind, at_ms: nowMs });
        SocialRules.noteSend(x, "", d);
        return true;
      }) as SocialRules.Record;
      return why !== "" ? Server.fail(why) : { ok: true, waiting: r.link_gifts.length, sends_left: SocialRules.sendsLeft(r, d) };
    }
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Server.fail(pair.error);
    }
    const friend = (pair.friend as Social.Player).userId;
    const check = SocialRules.sendCheck(load(nk, userId).record, friend, d);
    if (check !== "") {
      return Server.fail(check);
    }
    let full = false;
    update(nk, friend, function (x: SocialRules.Record): boolean {
      if (!SocialRules.makeRoom(x, 1)) {
        full = true;
        return false;
      }
      x.presents.push({ id: newId(nk, "p", nowMs), from: userId, kind: kind, at_ms: nowMs, opened: false, thanked: false,
        link: false });
      SocialRules.addNews(x, { what: "present", id: userId, kind: kind, gold: 0, place: "", at_ms: nowMs });
      return true;
    });
    if (full) {
      return Server.fail("inbox_full");
    }
    const r = update(nk, userId, function (x: SocialRules.Record): boolean {
      SocialRules.noteSend(x, friend, d);
      return true;
    }) as SocialRules.Record;
    pairDay(nk, userId, friend, d, nowMs);
    nudge(nk, friend, "present");
    return { ok: true, sends_left: SocialRules.sendsLeft(r, d) };
  }

  // Referrals.use: a new friend joined with the code of `guideId`: the first present waiting on it is theirs.
  export function welcomePresent(nk: nkruntime.Nakama, guideId: string, newId_: string, nowMs: number): string {
    const d = SocialRules.day(nowMs);
    let kind = "";
    update(nk, guideId, function (x: SocialRules.Record): boolean {
      if (x.link_gifts.length === 0) {
        return false;
      }
      kind = (x.link_gifts.shift() as SocialRules.LinkGift).kind;
      SocialRules.addNews(x, { what: "link_present", id: newId_, kind: kind, gold: 0, place: "", at_ms: nowMs });
      SocialRules.countDay(x, newId_, d);
      return true;
    });
    if (kind === "") {
      return "";
    }
    update(nk, newId_, function (x: SocialRules.Record): boolean {
      SocialRules.makeRoom(x, 1); // a new friend's inbox: always room for their guide's present
      x.presents.push({ id: newId(nk, "p", nowMs), from: guideId, kind: kind, at_ms: nowMs, opened: false, thanked: false,
        link: true });
      SocialRules.addNews(x, { what: "present", id: guideId, kind: kind, gold: 0, place: "", at_ms: nowMs });
      SocialRules.countDay(x, guideId, d);
      return true;
    });
    nudge(nk, guideId, "link_present");
    return kind;
  }

  function findPresent(r: SocialRules.Record, id: unknown): SocialRules.Present | null {
    for (let i = 0; i < r.presents.length; i++) {
      if (r.presents[i].id === id) {
        return r.presents[i];
      }
    }
    return null;
  }

  export function open(nk: nkruntime.Nakama, userId: string, request: Util.Json): Util.Json {
    if (typeof request.id !== "string" || request.id === "") {
      return Server.fail("not_found");
    }
    if (!allowed(nk, userId)) {
      return Server.fail("not_allowed_online");
    }
    const p = findPresent(load(nk, userId).record, request.id);
    if (p === null || p.opened) {
      return Server.fail("not_found");
    }
    if (!exists(nk, p.from) || (!p.link && !Social.areFriends(nk, userId, p.from))) {
      update(nk, userId, function (x: SocialRules.Record): boolean {
        x.presents = x.presents.filter(function (q: SocialRules.Present): boolean { return q.id !== request.id; });
        return true;
      });
      return Server.fail("not_found"); // no longer a friend: it goes away unopened
    }
    let got: SocialRules.Present | null = null;
    update(nk, userId, function (x: SocialRules.Record): boolean {
      const q = findPresent(x, request.id);
      if (q === null || q.opened) {
        got = null;
        return false;
      }
      q.opened = true;
      got = q;
      return true;
    });
    if (got === null) {
      return Server.fail("not_found");
    }
    const g = got as SocialRules.Present;
    const names = Referrals.names(nk, [g.from]);
    return { ok: true, kind: g.kind, name: Util.has(names, g.from) ? names[g.from] : "", link: g.link };
  }

  export function thank(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const p = findPresent(load(nk, userId).record, request.id);
    if (p === null) {
      return Server.fail("not_found");
    }
    if (!p.opened) {
      return Server.fail("not_opened");
    }
    if (p.thanked) {
      return Server.fail("already_thanked");
    }
    let first = false;
    update(nk, userId, function (x: SocialRules.Record): boolean {
      const q = findPresent(x, request.id);
      if (q === null || q.thanked) {
        return false;
      }
      q.thanked = true;
      first = true;
      return true;
    });
    if (!first) {
      return Server.fail("already_thanked");
    }
    const d = SocialRules.day(nowMs);
    let paid = 0;
    update(nk, p.from, function (x: SocialRules.Record): boolean {
      const c = SocialRules.today(x, d);
      paid = 0;
      if (c.thanks < SocialRules.THANKS_PER_DAY) {
        c.thanks += 1;
        paid = SocialRules.THANK_GOLD;
      }
      SocialRules.addNews(x, { what: "thanks", id: userId, kind: p.kind, gold: paid, place: "", at_ms: nowMs });
      return true;
    });
    if (paid > 0 && exists(nk, p.from)) {
      paid = Economy.addGold(nk, p.from, paid, { source: "together", reason: "thanks" }).added;
    }
    if (exists(nk, p.from) && Social.areFriends(nk, userId, p.from)) {
      pairDay(nk, userId, p.from, d, nowMs);
    }
    nudge(nk, p.from, "thanks");
    return { ok: true, gold: paid };
  }

  // --- study_buddy ---

  function buddyCount(r: SocialRules.Record, except: string): number {
    let n = 0;
    for (const k in r.buddies) {
      if (Util.has(r.buddies as unknown as Util.Json, k) && k !== except) {
        n++;
      }
    }
    return n;
  }

  function setBuddy(nk: nkruntime.Nakama, self: string, pal: string, state: string, d: number): void {
    update(nk, self, function (x: SocialRules.Record): boolean {
      if (state === "") {
        if (!Util.has(x.buddies as unknown as Util.Json, pal)) {
          return false;
        }
        delete x.buddies[pal];
        return true;
      }
      const had = Util.has(x.buddies as unknown as Util.Json, pal) ? x.buddies[pal] : null;
      x.buddies[pal] = { state: state, since: d, days: had && state === "yes" && had.state === "yes" ? had.days : 0,
        last: had && state === "yes" && had.state === "yes" ? had.last : -1 };
      return true;
    });
  }

  export function buddy(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const action = request.action as string;
    if (ACTIONS_BUDDY.indexOf(action) < 0) {
      return Server.fail("bad_request");
    }
    const d = SocialRules.day(nowMs);
    if (action === "no" || action === "stop") {
      const other = Social.findById(nk, request.user_id);
      if (other !== null) {
        setBuddy(nk, userId, other.userId, "", d);
        setBuddy(nk, other.userId, userId, "", d);
      }
      return { ok: true, state: "" };
    }
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Server.fail(pair.error);
    }
    const pal = (pair.friend as Social.Player).userId;
    const mine = load(nk, userId).record;
    const had = Util.has(mine.buddies as unknown as Util.Json, pal) ? mine.buddies[pal] : null;
    if (had !== null && had.state === "yes") {
      return { ok: true, state: "yes" };
    }
    const becomesYes = action === "yes" || (had !== null && had.state === "asking");
    if (action === "yes" && (had === null || had.state !== "asking")) {
      return Server.fail("not_found");
    }
    if (becomesYes) {
      setBuddy(nk, userId, pal, "yes", d);
      setBuddy(nk, pal, userId, "yes", d);
      if (load(nk, userId).record.learned.indexOf(d) >= 0 && load(nk, pal).record.learned.indexOf(d) >= 0) {
        buddyDay(nk, userId, pal, d); // both learned today already: their first shared day
      }
      update(nk, pal, function (x: SocialRules.Record): boolean {
        SocialRules.addNews(x, { what: "buddy_yes", id: userId, kind: "", gold: 0, place: "", at_ms: nowMs });
        return true;
      });
      nudge(nk, pal, "buddy_yes");
      return { ok: true, state: "yes" };
    }
    if (had !== null && had.state === "asked") {
      return { ok: true, state: "asked" };
    }
    const theirs = load(nk, pal).record;
    if (buddyCount(mine, pal) >= SocialRules.BUDDIES_MAX || buddyCount(theirs, userId) >= SocialRules.BUDDIES_MAX) {
      return Server.fail("too_many_buddies");
    }
    setBuddy(nk, userId, pal, "asked", d);
    setBuddy(nk, pal, userId, "asking", d);
    update(nk, pal, function (x: SocialRules.Record): boolean {
      SocialRules.addNews(x, { what: "buddy_ask", id: userId, kind: "", gold: 0, place: "", at_ms: nowMs });
      return true;
    });
    nudge(nk, pal, "buddy_ask");
    return { ok: true, state: "asked" };
  }

  // --- crew ---

  function myCrew(nk: nkruntime.Nakama, userId: string): SocialRules.Crew | null {
    const r = load(nk, userId).record;
    const c = readCrew(nk, r.crew).crew;
    return c !== null && c.members.indexOf(userId) >= 0 ? c : null;
  }

  function leaveCrew(nk: nkruntime.Nakama, userId: string, crewId: string): boolean {
    let left = false;
    updateCrew(nk, crewId, function (c: SocialRules.Crew): boolean {
      const at = c.members.indexOf(userId);
      if (at < 0) {
        return false;
      }
      c.members.splice(at, 1);
      delete c.looks[userId];
      left = true;
      return true;
    });
    return left;
  }

  export function crew(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const action = request.action;
    const me = Accounts.load(nk, userId);
    if (!AccountRules.canPlayOnline(me.state)) {
      return Server.fail("not_allowed_online");
    }
    const d = SocialRules.day(nowMs);
    if (action === "make") {
      if (!me.state.claimed) {
        return Server.fail("not_claimed");
      }
      if (myCrew(nk, userId) !== null) {
        return Server.fail("in_a_crew");
      }
      const bad = SocialRules.crewNameCheck(request.adjective, request.noun) || SocialRules.badgeCheck(request.badge);
      if (bad !== "") {
        return Server.fail(bad);
      }
      const looks: { [id: string]: Util.Json } = {};
      looks[userId] = SocialRules.lookFrom(request.look);
      const c: SocialRules.Crew = { id: newId(nk, "c", nowMs), adjective: request.adjective as string,
        noun: request.noun as string, badge: request.badge as string, maker: userId, members: [userId], looks: looks,
        made_ms: nowMs };
      Store.write(nk, CREWS, c.id, Store.SYSTEM_USER, c as unknown as Util.Json, false, "*");
      update(nk, userId, function (x: SocialRules.Record): boolean {
        x.crew = c.id;
        return true;
      });
      return { ok: true, crew: crewOut(nk, c, userId, d) };
    }
    if (action === "invite") {
      const c = myCrew(nk, userId);
      if (c === null) {
        return Server.fail("no_crew");
      }
      const pair = Gifts.friendOf(nk, userId, request);
      if (pair.error !== "") {
        return Server.fail(pair.error);
      }
      const pal = (pair.friend as Social.Player).userId;
      if (c.members.indexOf(pal) >= 0) {
        return Server.fail("already_in");
      }
      if (c.members.length >= SocialRules.CREW_MAX) {
        return Server.fail("crew_full");
      }
      update(nk, pal, function (x: SocialRules.Record): boolean {
        x.crew_invites = x.crew_invites.filter(function (v: SocialRules.CrewInvite): boolean { return v.crew !== c.id; });
        x.crew_invites.push({ crew: c.id, from: userId, at_ms: nowMs });
        if (x.crew_invites.length > SocialRules.CREW_INVITES_MAX) {
          x.crew_invites = x.crew_invites.slice(-SocialRules.CREW_INVITES_MAX);
        }
        SocialRules.addNews(x, { what: "crew_invite", id: userId, kind: c.id, gold: 0, place: "", at_ms: nowMs });
        return true;
      });
      nudge(nk, pal, "crew_invite");
      return { ok: true };
    }
    if (action === "join") {
      const crewId = request.crew;
      const r = load(nk, userId).record;
      let invite: SocialRules.CrewInvite | null = null;
      for (let i = 0; i < r.crew_invites.length; i++) {
        if (r.crew_invites[i].crew === crewId) {
          invite = r.crew_invites[i];
        }
      }
      if (invite === null) {
        return Server.fail("not_invited");
      }
      if (myCrew(nk, userId) !== null) {
        return Server.fail("in_a_crew");
      }
      let full = false;
      const c = updateCrew(nk, crewId as string, function (x: SocialRules.Crew): boolean {
        if (x.members.indexOf(userId) >= 0) {
          return false;
        }
        if (x.members.length >= SocialRules.CREW_MAX) {
          full = true;
          return false;
        }
        x.members.push(userId);
        x.looks[userId] = SocialRules.lookFrom(request.look);
        return true;
      });
      if (c === null) {
        return Server.fail("not_found");
      }
      if (full) {
        return Server.fail("crew_full");
      }
      update(nk, userId, function (x: SocialRules.Record): boolean {
        x.crew = c.id;
        x.crew_invites = x.crew_invites.filter(function (v: SocialRules.CrewInvite): boolean { return v.crew !== c.id; });
        return true;
      });
      for (let i = 0; i < c.members.length; i++) {
        if (c.members[i] !== userId) {
          update(nk, c.members[i], function (x: SocialRules.Record): boolean {
            SocialRules.addNews(x, { what: "crew_join", id: userId, kind: c.id, gold: 0, place: "", at_ms: nowMs });
            return true;
          });
          nudge(nk, c.members[i], "crew_join");
        }
      }
      return { ok: true, crew: crewOut(nk, c, userId, d) };
    }
    if (action === "decline") {
      update(nk, userId, function (x: SocialRules.Record): boolean {
        const before = x.crew_invites.length;
        x.crew_invites = x.crew_invites.filter(function (v: SocialRules.CrewInvite): boolean { return v.crew !== request.crew; });
        return x.crew_invites.length !== before;
      });
      return { ok: true };
    }
    if (action === "leave") {
      const r = load(nk, userId).record;
      if (r.crew !== "") {
        leaveCrew(nk, userId, r.crew);
        update(nk, userId, function (x: SocialRules.Record): boolean {
          x.crew = "";
          return true;
        });
      }
      return { ok: true };
    }
    if (action === "look") {
      const c = myCrew(nk, userId);
      if (c === null) {
        return Server.fail("no_crew");
      }
      const changed = updateCrew(nk, c.id, function (x: SocialRules.Crew): boolean {
        x.looks[userId] = SocialRules.lookFrom(request.look);
        return true;
      });
      return { ok: true, crew: changed ? crewOut(nk, changed, userId, d) : null };
    }
    return Server.fail("bad_request");
  }

  // --- Deletion.run: everything that names the player goes (its own record goes with its storage). Before the
  // friend edges go: the friends who heard its moments are found by them. ---

  export function forget(nk: nkruntime.Nakama, userId: string): number {
    const r = load(nk, userId).record;
    const ids = Gifts.friendIds(nk, userId);
    const more = Object.keys(r.friends).concat(Object.keys(r.buddies));
    for (let i = 0; i < more.length; i++) {
      if (ids.indexOf(more[i]) < 0) {
        ids.push(more[i]);
      }
    }
    let changed = 0;
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] === userId) {
        continue;
      }
      let did = false;
      update(nk, ids[i], function (x: SocialRules.Record): boolean {
        const before = JSON.stringify(x);
        delete x.friends[userId];
        delete x.buddies[userId];
        x.feed = x.feed.filter(function (m: SocialRules.Moment): boolean { return m.from !== userId; });
        x.presents = x.presents.filter(function (p: SocialRules.Present): boolean { return p.from !== userId; });
        x.news = x.news.filter(function (n: SocialRules.News): boolean { return n.id !== userId; });
        x.crew_invites = x.crew_invites.filter(function (v: SocialRules.CrewInvite): boolean { return v.from !== userId; });
        did = JSON.stringify(x) !== before;
        return did;
      });
      changed += did ? 1 : 0;
    }
    if (r.crew !== "" && leaveCrew(nk, userId, r.crew)) {
      changed++;
    }
    return changed;
  }
}

// social_info {"seen"?: true} -> {"ok", "allowed", "friends": [{"id", "name", "days" (together), "level" (0-3), "today"
// (a day together counted today), "buddy": {"state" ("", asked, asking, yes), "days", "row" (the last 7 days: 2 both
// learned, 1 one, 0 rest)}}] (by name), "feed": [{"id", "name", "kind", "place", "at_ms"}] (friends' moments to cheer),
// "presents": [{"id", "name", "kind", "at_ms", "opened", "thanked", "link"}], "link_gifts": [kinds waiting on the invite
// code], "news": [{"what", "name", "kind", "gold", "place", "at_ms"}], "crew": null or {"id", "name", "adjective",
// "noun", "badge", "mine", "members": [{"name", "me", "look", "week": {"days", "units"}}], "goal": {"done", "target"},
// "full"}, "crew_invites": [{"crew", "name", "badge", "from", "members", "full"}], "sends_left", "cheers_left",
// "rules"}. "seen": the news were shown (they go).
function rpcSocialInfo(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "social_info", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.info(nk, userId, request.seen === true, Server.nowMs());
  });
}

// social_learned {"unit"?} (a School round finished or the Daily Mission done today; "unit": one mastered now) ->
// {"ok", "first" (today's first), "together" (friends who learned today too: a day together each; study buddies' shared
// day)}.
function rpcSocialLearned(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "social_learned", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.learned(nk, userId, request, Server.nowMs());
  });
}

// social_moment {"kind" (landed, mission, unit, grade, stamp, deposit), "place" (an id: "moon", "g4.maths.fractions")}
// -> {"ok", "told"}: into each friend's feed to cheer; too_many_today, bad_request, not_allowed_online.
function rpcSocialMoment(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "social_moment", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.moment(nk, userId, request, Server.nowMs());
  });
}

// social_cheer {"moment_id", "cheer" (SocialRules.CHEERS)} -> {"ok"}: news for the friend, a day together;
// not_found (once, friends only), too_many_today, bad_request.
function rpcSocialCheer(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "social_cheer", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.cheer(nk, userId, request, Server.nowMs());
  });
}

// present_send {"user_id", "kind"} -> {"ok", "sends_left"} (not_friends, sent_today, too_many_today, inbox_full); or
// {"link": true, "kind"} -> {"ok", "waiting", "sends_left"}: it waits on the invite code (too_many_waiting, not_claimed).
function rpcPresentSend(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "present_send", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.send(nk, userId, request, Server.nowMs());
  });
}

// present_open {"id"} -> {"ok", "kind", "name" (the sender), "link"}: once (not_found after).
function rpcPresentOpen(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "present_open", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.open(nk, userId, request);
  });
}

// present_thank {"id"} (an opened present) -> {"ok", "gold" (paid to the sender: SocialRules.THANK_GOLD a few times a
// day)}; not_found, not_opened, already_thanked.
function rpcPresentThank(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "present_thank", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.thank(nk, userId, request, Server.nowMs());
  });
}

// study_buddy {"action": "ask" | "yes" | "no" | "stop", "user_id"} -> {"ok", "state"}; not_friends, too_many_buddies,
// not_found (a "yes" nobody asked for).
function rpcStudyBuddy(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "study_buddy", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.buddy(nk, userId, request, Server.nowMs());
  });
}

// crew {"action": "make", "adjective", "noun", "badge", "look"?} | {"action": "invite", "user_id"} | {"action": "join",
// "crew", "look"?} | {"action": "decline", "crew"} | {"action": "leave"} | {"action": "look", "look"} -> {"ok", "crew"?};
// bad_name, bad_badge, in_a_crew, no_crew, not_friends, already_in, crew_full, not_invited, not_claimed.
function rpcCrew(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "crew", payload, function (userId: string, request: Util.Json): Util.Json {
    return Together.crew(nk, userId, request, Server.nowMs());
  });
}
