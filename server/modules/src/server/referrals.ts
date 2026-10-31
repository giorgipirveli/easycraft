// The invite program on Nakama (owner #79, #81, #82, #85; spec §25.2; module 0.2.16): the rules are ReferralRules.
//
//   referrals/me          (per player, server only) ReferralRules.Record: the player's code, who brought them, the
//                         friends they brought (ids and dates), the month's paid rewards, their groups, news
//   invite_codes/<CODE>   (the system's) {user_id, kind, code, made_ms}: the key is the canonical code (BLUEOTTER42)
//   invite_groups/<CODE>  (the system's) {kind, owner_id, code, members, made_ms}: a class or a family
//   invite_stats/world    (the system's) {joined, learned}: children brought by children (no names)
//   wrong codes           the node's local cache (per asking account), like wrong sign-in keys
//
// Gold goes into the Nakama wallet with a ledger entry {"source": "invite", "reason"}; the game's wallet sync brings
// it to the phone. Notification 108 {"what", "gold"} nudges an open game (not persistent: the news list is the mailbox).

namespace Referrals {
  export const RECORD = "referrals";
  export const KEY = "me";
  export const CODES = "invite_codes";
  export const GROUPS = "invite_groups";
  export const STATS = "invite_stats";
  export const OWN_COLLECTIONS = [RECORD];
  export const NOTE = 108;
  const TRIES = "invite_tries:";
  const ATTEMPTS = 8; // new codes tried before giving up (the later half with wider numbers)

  export interface Loaded {
    record: ReferralRules.Record;
    version: string; // "" when there is none yet
  }

  export function load(nk: nkruntime.Nakama, userId: string): Loaded {
    const found = Store.read(nk, RECORD, KEY, userId);
    return { record: ReferralRules.recordFrom(found ? found.value : undefined), version: found ? found.version : "" };
  }

  function save(nk: nkruntime.Nakama, userId: string, record: ReferralRules.Record, version: string): void {
    Store.write(nk, RECORD, KEY, userId, record as unknown as Util.Json, false, version === "" ? "*" : version);
  }

  // Changes a player's record by version (another call at the same moment: read again). `change` returns false when
  // there is nothing to write. The record as written (or as read), or null when the player's account is gone.
  export function update(nk: nkruntime.Nakama, userId: string,
      change: (r: ReferralRules.Record) => boolean): ReferralRules.Record | null {
    if (userId === "" || nk.usersGetId([userId]).length === 0) {
      return null;
    }
    for (let attempt = 0; attempt < 5; attempt++) {
      const l = load(nk, userId);
      if (!change(l.record)) {
        return l.record;
      }
      try {
        save(nk, userId, l.record, l.version);
        return l.record;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    throw new Error("busy");
  }

  // Random whole numbers 0..n-1 from the server's UUIDs.
  export function picker(nk: nkruntime.Nakama): (n: number) => number {
    return function (n: number): number {
      return parseInt(nk.uuidv4().replace(/-/g, "").substring(0, 8), 16) % n;
    };
  }

  // A new code of `kind` for userId, written only if nobody has it; the code as shown.
  export function newCode(nk: nkruntime.Nakama, userId: string, kind: string, nowMs: number): string {
    const pick = picker(nk);
    for (let attempt = 0; attempt < ATTEMPTS; attempt++) {
      const code = ReferralRules.makeCode(kind, pick, attempt >= ATTEMPTS / 2);
      try {
        Store.write(nk, CODES, ReferralRules.canonical(code), Store.SYSTEM_USER,
          { user_id: userId, kind: kind, code: code, made_ms: nowMs }, false, "*");
        return code;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    throw new Error("no free code");
  }

  // A code's record, or null (no such code, or its maker's account is gone: the console's Delete skips Deletion.run).
  export function codeInfo(nk: nkruntime.Nakama, canonicalCode: string): ReferralRules.CodeInfo | null {
    if (canonicalCode === "") {
      return null;
    }
    const found = Store.read(nk, CODES, canonicalCode, Store.SYSTEM_USER);
    const info = found ? ReferralRules.codeInfoFrom(found.value) : null;
    return info !== null && nk.usersGetId([info.user_id]).length > 0 ? info : null;
  }

  function readGroup(nk: nkruntime.Nakama, code: string): { group: ReferralRules.Group | null; version: string } {
    const found = Store.read(nk, GROUPS, ReferralRules.canonical(code), Store.SYSTEM_USER);
    return { group: found ? ReferralRules.groupFrom(found.value) : null, version: found ? found.version : "" };
  }

  // Changes a group by version; false when it is gone.
  function updateGroup(nk: nkruntime.Nakama, code: string, change: (g: ReferralRules.Group) => boolean): boolean {
    for (let attempt = 0; attempt < 5; attempt++) {
      const r = readGroup(nk, code);
      if (r.group === null) {
        return false;
      }
      if (!change(r.group)) {
        return true;
      }
      try {
        Store.write(nk, GROUPS, ReferralRules.canonical(code), Store.SYSTEM_USER, r.group as unknown as Util.Json, false, r.version);
        return true;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    throw new Error("busy");
  }

  // Players' names as the game shows them: a claimed name, else "" (an unclaimed account's name is Nakama's random one).
  export function names(nk: nkruntime.Nakama, ids: string[]): { [id: string]: string } {
    const out: { [id: string]: string } = {};
    const wanted: string[] = [];
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] !== "" && wanted.indexOf(ids[i]) < 0) {
        wanted.push(ids[i]);
      }
    }
    for (let i = 0; i < wanted.length; i += Social.MAX_LOOKUPS) {
      const users = nk.usersGetId(wanted.slice(i, i + Social.MAX_LOOKUPS));
      for (let j = 0; j < users.length; j++) {
        out[users[j].userId] = AccountRules.fromMetadata(users[j].metadata).claimed ? users[j].username : "";
      }
    }
    return out;
  }

  function name(nk: nkruntime.Nakama, id: string): string {
    const n = names(nk, [id]);
    return Util.has(n, id) ? n[id] : "";
  }

  function pay(nk: nkruntime.Nakama, userId: string, amount: number, reason: string): number {
    if (amount <= 0 || userId === "" || nk.usersGetId([userId]).length === 0) {
      return 0;
    }
    return Economy.addGold(nk, userId, amount, { source: "invite", reason: reason }).added;
  }

  function nudge(nk: nkruntime.Nakama, userId: string, what: string, gold: number): void {
    try {
      nk.notificationSend(userId, "Invite news", { what: what, gold: gold }, NOTE, null, false);
    } catch (_e) {
      // a nudge only: the news list has it
    }
  }

  // Children brought by children, for everyone to see (no names). Best effort.
  function countWorld(nk: nkruntime.Nakama, field: string): void {
    for (let attempt = 0; attempt < 3; attempt++) {
      const found = Store.read(nk, STATS, "world", Store.SYSTEM_USER);
      const v: Util.Json = found ? found.value : {};
      const next = { joined: Util.isInt(v.joined) ? v.joined : 0, learned: Util.isInt(v.learned) ? v.learned : 0 } as Util.Json;
      next[field] = next[field] + 1;
      try {
        Store.write(nk, STATS, "world", Store.SYSTEM_USER, next, false, found ? found.version : "*");
        return;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          return;
        }
      }
    }
  }

  function createdMs(nk: nkruntime.Nakama, userId: string): number {
    return RetentionRules.timeMs(nk.accountGetId(userId).user.createTime);
  }

  // --- invite_info ---

  export function info(nk: nkruntime.Nakama, userId: string, seen: boolean, nowMs: number): Util.Json {
    const claimed = Accounts.load(nk, userId).state.claimed;
    let l = load(nk, userId);
    const dropped = dropMissingGroups(nk, l.record);
    if ((claimed && l.record.code === "") || dropped) {
      let made = ""; // made once: a retry after a clash keeps it (no second code left behind)
      const record = update(nk, userId, function (r: ReferralRules.Record): boolean {
        let changed = dropMissingGroups(nk, r);
        if (claimed && r.code === "") {
          made = made !== "" ? made : newCode(nk, userId, ReferralRules.KIND_FRIEND, nowMs);
          r.code = made;
          changed = true;
        }
        return changed;
      });
      l = { record: record as ReferralRules.Record, version: "" };
    }
    const r = l.record;
    // The friends, newest first; each with their own friends counted (the tree's second level, never named).
    const shown = r.friends.slice(-ReferralRules.TREE_READ).reverse();
    const ids: string[] = [];
    for (let i = 0; i < shown.length; i++) {
      ids.push(shown[i].id);
    }
    const theirs = Store.readMany(nk, RECORD, KEY, ids);
    const known = names(nk, ids.concat(r.by ? [r.by.user_id] : []).concat(newsIds(r)));
    const friends: Util.Json[] = [];
    let treeFriends = 0;
    let treeLearned = 0;
    for (let i = 0; i < shown.length; i++) {
      const f = shown[i];
      const c = ReferralRules.counts(ReferralRules.recordFrom(Util.has(theirs, f.id) ? theirs[f.id].value : undefined));
      treeFriends += c.friends;
      treeLearned += c.learned;
      if (Util.has(known, f.id)) {
        friends.push({ name: known[f.id], learned: f.learned_ms > 0, joined_ms: f.at_ms, friends: c.friends, learned_friends: c.learned });
      }
    }
    const mine = ReferralRules.counts(r);
    const news: Util.Json[] = [];
    for (let i = 0; i < r.news.length; i++) {
      const n = r.news[i];
      news.push({ what: n.what, name: Util.has(known, n.id) ? known[n.id] : "", gold: n.gold, at_ms: n.at_ms });
    }
    if (seen && r.news.length > 0) {
      update(nk, userId, function (x: ReferralRules.Record): boolean {
        x.news = [];
        return true;
      });
    }
    const month: Util.Json = {};
    for (const k in ReferralRules.CAPS) {
      if (Util.has(ReferralRules.CAPS, k)) {
        month[k] = ReferralRules.take(r.times[k] || [], nowMs).length - 1;
      }
    }
    const world = Store.read(nk, STATS, "world", Store.SYSTEM_USER);
    return {
      ok: true, claimed: claimed, code: r.code,
      can_use_code: r.by === null && ReferralRules.isNewAccount(createdMs(nk, userId), nowMs),
      guide: r.by && Util.has(known, r.by.user_id) ? known[r.by.user_id] : "",
      friends: friends,
      counts: { friends: mine.friends, learned: mine.learned, tree_friends: treeFriends, tree_learned: treeLearned,
        children_learning: mine.learned + treeLearned },
      month: month, caps: ReferralRules.CAPS, earned: r.earned,
      groups: groupsOf(nk, userId, r), made: r.made, news: news,
      world: { joined: world && Util.isInt(world.value.joined) ? world.value.joined : 0,
        learned: world && Util.isInt(world.value.learned) ? world.value.learned : 0 },
      rewards: { welcome: ReferralRules.WELCOME_GOLD, inviter: ReferralRules.INVITER_GOLD, learner: ReferralRules.LEARNER_GOLD,
        tree: ReferralRules.TREE_GOLD, landed: ReferralRules.LANDED_GOLD },
    };
  }

  function newsIds(r: ReferralRules.Record): string[] {
    const out: string[] = [];
    for (let i = 0; i < r.news.length; i++) {
      out.push(r.news[i].id);
    }
    return out;
  }

  // Groups that no longer exist (a grown-up removed them) leave the record; true when one did.
  function dropMissingGroups(nk: nkruntime.Nakama, r: ReferralRules.Record): boolean {
    let changed = false;
    const kinds = ReferralRules.GROUP_KINDS;
    for (let i = 0; i < kinds.length; i++) {
      if (Util.has(r.groups, kinds[i]) && readGroup(nk, r.groups[kinds[i]]).group === null) {
        delete r.groups[kinds[i]];
        changed = true;
      }
    }
    return changed;
  }

  // The player's class and family: the code, how many are in it and how many learned (counts only, never names).
  function groupsOf(nk: nkruntime.Nakama, userId: string, r: ReferralRules.Record): Util.Json {
    const out: Util.Json = {};
    const kinds = ReferralRules.GROUP_KINDS;
    for (let i = 0; i < kinds.length; i++) {
      if (!Util.has(r.groups, kinds[i])) {
        continue;
      }
      const g = readGroup(nk, r.groups[kinds[i]]).group;
      if (g === null) {
        continue;
      }
      const records = Store.readMany(nk, RECORD, KEY, g.members);
      let learned = 0;
      for (let m = 0; m < g.members.length; m++) {
        const id = g.members[m];
        if (Util.has(records, id) && ReferralRules.recordFrom(records[id].value).learned_ms > 0) {
          learned++;
        }
      }
      out[kinds[i]] = { code: g.code, members: g.members.length, learned: learned, mine: g.owner_id === userId };
    }
    return out;
  }

  // --- invite_use ---

  export function use(nk: nkruntime.Nakama, userId: string, typed: unknown, nowMs: number): Util.Json {
    const triesKey = TRIES + userId;
    const tries = Keys.tries(nk, triesKey);
    const wait = KeyRules.wait(tries, nowMs);
    if (wait > 0) {
      return Server.fail("locked", { wait: wait });
    }
    const key = ReferralRules.canonical(typed);
    const found = codeInfo(nk, key);
    if (found === null) {
      Keys.saveTries(nk, triesKey, KeyRules.wrong(tries, nowMs, ReferralRules.WRONG_MAX, ReferralRules.WRONG_WINDOW_MS),
        ReferralRules.WRONG_WINDOW_MS);
      return Server.fail("unknown");
    }
    const created = createdMs(nk, userId);
    let size = 0;
    if (found.kind !== ReferralRules.KIND_FRIEND) {
      const g = readGroup(nk, found.code).group;
      if (g === null) {
        return Server.fail("unknown");
      }
      size = g.members.length;
    }
    const check = ReferralRules.useCheck(load(nk, userId).record, found, userId, created, nowMs, size);
    if (check.error !== "") {
      return Server.fail(check.error);
    }
    if (check.group !== "") {
      let full = false;
      const there = updateGroup(nk, found.code, function (g: ReferralRules.Group): boolean {
        if (g.members.indexOf(userId) >= 0) {
          return false;
        }
        const max = g.kind === ReferralRules.KIND_CLASS ? ReferralRules.GROUP_MAX.class : ReferralRules.GROUP_MAX.family;
        if (g.members.length >= max) {
          full = true;
          return false;
        }
        g.members.push(userId);
        return true;
      });
      if (!there) {
        return Server.fail("unknown");
      }
      if (full) {
        return Server.fail("group_full");
      }
    }
    // This player's record first (by version): a second use at the same moment finds it used and pays nothing.
    let referral = false;
    let refused = "";
    update(nk, userId, function (r: ReferralRules.Record): boolean {
      const again = ReferralRules.useCheck(r, found, userId, created, nowMs, 0);
      if (again.error !== "" && again.error !== "group_full") {
        refused = again.error;
        return false;
      }
      referral = again.referral;
      if (referral) {
        r.by = { user_id: found.user_id, kind: found.kind, at_ms: nowMs };
      }
      if (check.group !== "") {
        r.groups[check.group] = found.code;
      }
      return true;
    });
    if (refused !== "") {
      return Server.fail(refused);
    }
    let welcome = 0;
    if (referral) {
      update(nk, found.user_id, function (r: ReferralRules.Record): boolean {
        if (!ReferralRules.addFriend(r, userId, nowMs)) {
          return false;
        }
        ReferralRules.addNews(r, { what: "joined", id: userId, gold: 0, at_ms: nowMs });
        return true;
      });
      nudge(nk, found.user_id, "joined", 0);
      welcome = pay(nk, userId, ReferralRules.WELCOME_GOLD, "welcome");
      countWorld(nk, "joined");
      Together.welcomePresent(nk, found.user_id, userId, nowMs); // 0.2.18: a present that waited on the code
    }
    return {
      ok: true, kind: found.kind, guide: name(nk, found.user_id), welcome: welcome, gold: Economy.balance(nk, userId),
      group: check.group,
    };
  }

  // --- invite_progress ---

  export function progress(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const event = request.event;
    if (typeof event !== "string" || ReferralRules.EVENTS.indexOf(event) < 0) {
      return Server.fail("bad_request");
    }
    let first = false;
    const landing = event === "landed";
    const me = update(nk, userId, function (r: ReferralRules.Record): boolean {
      if (landing) {
        if (r.landed_ms > 0 || ReferralRules.LANDED_PLACES.indexOf(request.where) < 0) {
          return false;
        }
        r.landed_ms = nowMs;
      } else {
        if (r.learned_ms > 0) {
          return false;
        }
        r.learned_ms = nowMs;
      }
      first = true;
      return true;
    }) as ReferralRules.Record;
    const inviter = me.by ? me.by.user_id : "";
    const guide = inviter !== "" ? name(nk, inviter) : "";
    if (!first) {
      return { ok: true, counted: false, gold: 0, guide: guide };
    }
    if (!landing) {
      countWorld(nk, "learned");
    }
    if (inviter === "") {
      return { ok: true, counted: true, gold: 0, guide: guide };
    }
    const kind = landing ? "landed" : "learned";
    let paid = 0;
    let grand = "";
    update(nk, inviter, function (r: ReferralRules.Record): boolean {
      const fresh = landing ? ReferralRules.markLanded(r, userId, nowMs) : ReferralRules.markLearned(r, userId, nowMs);
      if (!fresh) {
        return false;
      }
      paid = 0;
      if (ReferralRules.hasRoom(r.times[kind] || [], (ReferralRules.CAPS as Util.Json)[kind], nowMs)) {
        r.times[kind] = ReferralRules.take(r.times[kind] || [], nowMs);
        paid = landing ? ReferralRules.LANDED_GOLD : ReferralRules.INVITER_GOLD;
        r.earned += paid;
      }
      ReferralRules.addNews(r, { what: kind, id: userId, gold: paid, at_ms: nowMs });
      grand = r.by ? r.by.user_id : "";
      return true;
    });
    pay(nk, inviter, paid, landing ? "friend_landed" : "friend_learned");
    nudge(nk, inviter, kind, paid);
    let mine = 0;
    if (!landing) {
      mine = pay(nk, userId, ReferralRules.LEARNER_GOLD, "learned_with_guide");
      if (grand !== "" && grand !== userId) {
        let gift = 0;
        update(nk, grand, function (r: ReferralRules.Record): boolean {
          gift = 0;
          if (ReferralRules.hasRoom(r.times.tree || [], ReferralRules.CAPS.tree, nowMs)) {
            r.times.tree = ReferralRules.take(r.times.tree || [], nowMs);
            gift = ReferralRules.TREE_GOLD;
            r.earned += gift;
          }
          ReferralRules.addNews(r, { what: "tree", id: "", gold: gift, at_ms: nowMs });
          return true;
        });
        pay(nk, grand, gift, "tree_learned");
        nudge(nk, grand, "tree", gift);
      }
    }
    return { ok: true, counted: true, gold: mine, guide: guide };
  }

  // --- invite_group ---

  export function group(nk: nkruntime.Nakama, userId: string, request: Util.Json, nowMs: number): Util.Json {
    const kind = request.kind;
    if (typeof kind !== "string" || ReferralRules.GROUP_KINDS.indexOf(kind) < 0) {
      return Server.fail("bad_request");
    }
    if (request.action === "make") {
      if (!Accounts.load(nk, userId).state.claimed) {
        return Server.fail("not_claimed");
      }
      const had = load(nk, userId).record;
      if (Util.has(had.made, kind) && readGroup(nk, had.made[kind]).group !== null) {
        return { ok: true, code: had.made[kind] };
      }
      // The maker is its first member unless they are in another group of that kind already.
      const code = newCode(nk, userId, kind, nowMs);
      Store.write(nk, GROUPS, ReferralRules.canonical(code), Store.SYSTEM_USER,
        { kind: kind, owner_id: userId, code: code, members: Util.has(had.groups, kind) ? [] : [userId], made_ms: nowMs },
        false, "*");
      update(nk, userId, function (r: ReferralRules.Record): boolean {
        r.made[kind] = code;
        if (!Util.has(r.groups, kind)) {
          r.groups[kind] = code;
        }
        return true;
      });
      return { ok: true, code: code };
    }
    if (request.action === "leave") {
      const r = load(nk, userId).record;
      if (Util.has(r.groups, kind)) {
        const code = r.groups[kind];
        updateGroup(nk, code, function (g: ReferralRules.Group): boolean {
          const at = g.members.indexOf(userId);
          if (at < 0) {
            return false;
          }
          g.members.splice(at, 1);
          return true;
        });
        update(nk, userId, function (x: ReferralRules.Record): boolean {
          delete x.groups[kind];
          return true;
        });
      }
      return { ok: true };
    }
    if (request.action === "remove") {
      const r = load(nk, userId).record;
      if (Util.has(r.made, kind)) {
        removeGroup(nk, r.made[kind]);
        update(nk, userId, function (x: ReferralRules.Record): boolean {
          if (x.groups[kind] === x.made[kind]) {
            delete x.groups[kind];
          }
          delete x.made[kind];
          return true;
        });
      }
      return { ok: true };
    }
    return Server.fail("bad_request");
  }

  function removeGroup(nk: nkruntime.Nakama, code: string): number {
    const key = ReferralRules.canonical(code);
    let removed = 0;
    if (Store.read(nk, CODES, key, Store.SYSTEM_USER) !== null) {
      Store.remove(nk, CODES, key, Store.SYSTEM_USER);
      removed++;
    }
    if (Store.read(nk, GROUPS, key, Store.SYSTEM_USER) !== null) {
      Store.remove(nk, GROUPS, key, Store.SYSTEM_USER);
      removed++;
    }
    return removed;
  }

  // --- Deletion.run: everything that names the player goes (its own record goes with its storage) ---

  export function forget(nk: nkruntime.Nakama, userId: string): number {
    const r = load(nk, userId).record;
    let changed = 0;
    if (r.code !== "" && Store.read(nk, CODES, ReferralRules.canonical(r.code), Store.SYSTEM_USER) !== null) {
      Store.remove(nk, CODES, ReferralRules.canonical(r.code), Store.SYSTEM_USER);
      changed++;
    }
    const kinds = ReferralRules.GROUP_KINDS;
    for (let i = 0; i < kinds.length; i++) {
      if (Util.has(r.made, kinds[i])) {
        changed += removeGroup(nk, r.made[kinds[i]]); // its code and its group
      }
    }
    for (let i = 0; i < kinds.length; i++) {
      if (Util.has(r.groups, kinds[i]) && !(Util.has(r.made, kinds[i]) && r.made[kinds[i]] === r.groups[kinds[i]])) {
        let left = false;
        updateGroup(nk, r.groups[kinds[i]], function (g: ReferralRules.Group): boolean {
          const at = g.members.indexOf(userId);
          if (at < 0) {
            return false;
          }
          g.members.splice(at, 1);
          left = true;
          return true;
        });
        changed += left ? 1 : 0;
      }
    }
    if (r.by !== null && r.by.user_id !== "") {
      let out = false;
      update(nk, r.by.user_id, function (x: ReferralRules.Record): boolean {
        const before = x.friends.length + x.news.length;
        x.friends = x.friends.filter(function (f: ReferralRules.Friend): boolean { return f.id !== userId; });
        x.news = x.news.filter(function (n: ReferralRules.News): boolean { return n.id !== userId; });
        out = x.friends.length + x.news.length !== before;
        return out;
      });
      changed += out ? 1 : 0;
    }
    for (let i = 0; i < r.friends.length; i++) {
      let unlinked = false;
      update(nk, r.friends[i].id, function (x: ReferralRules.Record): boolean {
        if (x.by === null || x.by.user_id !== userId) {
          return false;
        }
        x.by.user_id = "";
        unlinked = true;
        return true;
      });
      changed += unlinked ? 1 : 0;
    }
    return changed;
  }
}

// invite_info {"seen"?: true} -> {"ok", "claimed", "code" (made for a claimed account on the first call; "" before),
// "can_use_code", "guide", "friends": [{"name", "learned", "joined_ms", "friends", "learned_friends"}] (newest first;
// "" for a friend with no claimed name), "counts": {"friends", "learned", "tree_friends", "tree_learned",
// "children_learning"}, "month" and "caps" (rewards paid in the last 30 days, per kind), "earned", "groups": {kind:
// {"code", "members", "learned", "mine"}}, "made": {kind: code}, "news": [{"what", "name", "gold", "at_ms"}],
// "world": {"joined", "learned"}, "rewards"}. "seen": the news were shown (they go).
function rpcInviteInfo(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "invite_info", payload, function (userId: string, request: Util.Json): Util.Json {
    return Referrals.info(nk, userId, request.seen === true, Server.nowMs());
  });
}

// invite_use {"code"} -> {"ok", "kind" (friend, class, family), "guide" (the code's maker's name), "welcome" (gold
// given now), "gold" (the balance), "group" ("" or the kind joined)}; unknown, own_code, already_used, not_new,
// already_in, group_full, locked (+ "wait" seconds: ReferralRules.WRONG_MAX wrong codes in the window).
function rpcInviteUse(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "invite_use", payload, function (userId: string, request: Util.Json): Util.Json {
    return Referrals.use(nk, userId, request.code, Server.nowMs());
  });
}

// invite_progress {"event": "learned", "unit"?} (the first School unit mastered) or {"event": "landed", "where":
// "moon"} -> {"ok", "counted" (false: already counted), "gold" (paid to this player now), "guide"}.
function rpcInviteProgress(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "invite_progress", payload, function (userId: string, request: Util.Json): Util.Json {
    return Referrals.progress(nk, userId, request, Server.nowMs());
  });
}

// invite_group {"action": "make" | "leave" | "remove", "kind": "class" | "family"} -> make: {"ok", "code"} (one of each
// kind; asking again shows it; a claimed account: not_claimed); leave: {"ok"}; remove (its maker): {"ok"}, the code
// stops working. The game asks behind its parent gate.
function rpcInviteGroup(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "invite_group", payload, function (userId: string, request: Util.Json): Util.Json {
    return Referrals.group(nk, userId, request, Server.nowMs());
  });
}
