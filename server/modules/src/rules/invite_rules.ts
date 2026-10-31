// Invites into a host's world and who may join its relayed match (spec §17.0, §17.3; plan M4
// Wave 1). The host's phone runs the world and Nakama relays; the server keeps, per host, a
// "hosting" record (collection "invites", key "current"): the match it hosts and whom it invited.
// invite_friend adds to it; the MatchJoin hook reads it. At most 4 players, never a 5th.

namespace InviteRules {
  export const MAX_PLAYERS = 4;
  export const INVITE_TTL_MS = 60 * 60 * 1000; // an invite can be taken up for an hour
  export const REJOIN_MS = 24 * 60 * 60 * 1000; // once in, a guest may come back (a dropped phone) for a day
  export const RATE_COUNT = 20; // invites a host may send ...
  export const RATE_WINDOW_MS = 10 * 60 * 1000; // ... in any 10 minutes
  export const WORLD_NAME_MAX = 32;

  export interface Hosting {
    match_id: string;
    host_id: string;
    created_ms: number;
    invited: { [userId: string]: number }; // until when (server ms) that player may join
    sent: number[]; // when invites were sent (the rate limit)
  }

  const RELAYED_ID_RE = /^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.$/;

  // The stream subject of a relayed match id ("<uuid>.", as Nakama makes them), or null.
  export function matchSubject(matchId: unknown): string | null {
    if (typeof matchId !== "string") {
      return null;
    }
    const m = RELAYED_ID_RE.exec(matchId.toLowerCase());
    return m ? m[1] : null;
  }

  export function newHosting(matchId: string, hostId: string, nowMs: number): Hosting {
    return { match_id: matchId, host_id: hostId, created_ms: nowMs, invited: {}, sent: [] };
  }

  // The host removes a player (spec §17.3 "Safety in the world"): a copy without them on the invite list, so the
  // join hook refuses them from now on (a rejoin too).
  export function remove(h: Hosting, userId: string): Hosting {
    const invited: { [userId: string]: number } = {};
    for (const id in h.invited) {
      if (Util.has(h.invited, id) && id !== userId) {
        invited[id] = h.invited[id];
      }
    }
    return { match_id: h.match_id, host_id: h.host_id, created_ms: h.created_ms, invited: invited, sent: h.sent.slice() };
  }

  export function hostingFrom(value: unknown): Hosting | null {
    if (!Util.isObject(value) || matchSubject(value.match_id) === null || typeof value.host_id !== "string") {
      return null;
    }
    const invited: { [userId: string]: number } = {};
    if (Util.isObject(value.invited)) {
      for (const k in value.invited) {
        if (Util.has(value.invited, k) && Util.isInt(value.invited[k])) {
          invited[k] = value.invited[k];
        }
      }
    }
    const sent: number[] = [];
    if (value.sent instanceof Array) {
      for (let i = 0; i < value.sent.length; i++) {
        if (Util.isInt(value.sent[i])) {
          sent.push(value.sent[i]);
        }
      }
    }
    return {
      match_id: value.match_id, host_id: value.host_id,
      created_ms: Util.isInt(value.created_ms) ? value.created_ms : 0, invited: invited, sent: sent,
    };
  }

  function copy(h: Hosting): Hosting {
    const invited: { [userId: string]: number } = {};
    for (const k in h.invited) {
      if (Util.has(h.invited, k)) {
        invited[k] = h.invited[k];
      }
    }
    return { match_id: h.match_id, host_id: h.host_id, created_ms: h.created_ms, invited: invited, sent: h.sent.slice() };
  }

  // The record of the player in `ids` who hosts this match, if any.
  function hostHere(matchId: string, ids: string[], records: { [ownerId: string]: Hosting }): Hosting | null {
    for (let i = 0; i < ids.length; i++) {
      const r = records[ids[i]];
      if (r && r.match_id === matchId && r.host_id === ids[i]) {
        return r;
      }
    }
    return null;
  }

  export interface InviteCheck {
    matchId: string;
    callerId: string;
    targetId: string;
    caller: AccountRules.State;
    target: AccountRules.State | null; // null: no such player
    isFriend: boolean;
    presentIds: string[]; // players in the match now (distinct user ids)
    records: { [ownerId: string]: Hosting }; // hosting records of the caller and of the players in the match
    now: number;
  }

  // invite_friend: the caller's updated hosting record, or an error code.
  export function invite(c: InviteCheck): { error?: string; hosting?: Hosting } {
    if (!AccountRules.canPlayOnline(c.caller)) {
      return { error: "not_allowed_online" };
    }
    if (c.target === null) {
      return { error: "not_found" };
    }
    if (c.targetId === c.callerId) {
      return { error: "cannot_invite_self" };
    }
    if (!c.isFriend) {
      // M4 Task 10 review: a child who may not be online is nobody to a stranger (no findable name).
      return { error: AccountRules.canPlayOnline(c.target) ? "not_friends" : "not_found" };
    }
    if (!AccountRules.canPlayOnline(c.target)) {
      return { error: "friend_cannot_join" };
    }
    if (c.presentIds.indexOf(c.callerId) < 0) {
      return { error: "not_in_match" };
    }
    const own = c.records[c.callerId];
    let hosting: Hosting;
    if (own && own.match_id === c.matchId && own.host_id === c.callerId) {
      hosting = copy(own);
    } else if (hostHere(c.matchId, c.presentIds, c.records) !== null) {
      return { error: "not_host" };
    } else {
      hosting = newHosting(c.matchId, c.callerId, c.now);
      if (own) {
        hosting.sent = own.sent.slice(); // M4 Task 10 review: a new match keeps the invite window
      }
    }
    if (c.presentIds.length >= MAX_PLAYERS) {
      return { error: "match_full" };
    }
    const recent: number[] = [];
    for (let i = 0; i < hosting.sent.length; i++) {
      if (c.now - hosting.sent[i] < RATE_WINDOW_MS) {
        recent.push(hosting.sent[i]);
      }
    }
    if (recent.length >= RATE_COUNT) {
      return { error: "too_fast" };
    }
    recent.push(c.now);
    hosting.sent = recent;
    const invited: { [userId: string]: number } = {};
    for (const k in hosting.invited) {
      if (Util.has(hosting.invited, k) && hosting.invited[k] > c.now) {
        invited[k] = hosting.invited[k];
      }
    }
    invited[c.targetId] = Math.max(invited[c.targetId] || 0, c.now + INVITE_TTL_MS);
    hosting.invited = invited;
    return { hosting: hosting };
  }

  export interface JoinCheck {
    matchId: string;
    userId: string;
    joiner: AccountRules.Read;
    presentIds: string[];
    records: { [ownerId: string]: Hosting }; // of the joiner and of the players in the match
    devOpen: boolean; // a developer server (EASYCRAFT_DEV_OPEN_MATCHES)
    now: number;
  }

  // The MatchJoin hook: "" to let in (renew: the host's record to save), or an error code.
  export function join(c: JoinCheck): { error?: string; renew?: { ownerId: string; hosting: Hosting } } {
    if (c.presentIds.indexOf(c.userId) >= 0 || c.presentIds.length === 0) {
      return {}; // already in (another session), or no such match: Nakama answers that itself
    }
    if (c.joiner.claimed && !AccountRules.canPlayOnline(c.joiner)) {
      return { error: "not_allowed_online" };
    }
    if (c.presentIds.length >= MAX_PLAYERS) {
      return { error: "match_full" };
    }
    const own = c.records[c.userId];
    if (own && own.match_id === c.matchId && own.host_id === c.userId) {
      return {}; // the host coming back
    }
    const host = hostHere(c.matchId, c.presentIds, c.records);
    if (host !== null && (host.invited[c.userId] || 0) > c.now) {
      const renewed = copy(host);
      renewed.invited[c.userId] = Math.max(renewed.invited[c.userId], c.now + REJOIN_MS);
      return { renew: { ownerId: host.host_id, hosting: renewed } };
    }
    if (c.devOpen && !c.joiner.claimed) {
      return {};
    }
    return { error: "not_invited" };
  }

  // The world's name as friends see it in the invite: cleaned like chat, at most 32 characters, and
  // passing the chat filter (it is typed by a child).
  export function worldName(raw: unknown): { name?: string; error?: string } {
    if (raw === undefined || raw === null) {
      return { name: "" };
    }
    if (typeof raw !== "string") {
      return { error: "bad_request" };
    }
    const name = Util.stripEdges(Util.firstChars(ChatRules.clean(raw), WORLD_NAME_MAX));
    if (name !== "" && ChatRules.filterCode(name) !== "") {
      return { error: "bad_world_name" };
    }
    return { name: name };
  }
}
