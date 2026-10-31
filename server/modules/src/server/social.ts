// Friends, invites and reports on the server (spec §17.0, §17.2-17.3; plan M4 Wave 1):
// invite_friend (notification 101), the hosting record kept at match creation, the MatchJoin hook
// (invited players only, at most 4), matchmaking and parties switched off, friend requests and
// user lookups that never find a child who may not be online, and report_user.

namespace Social {
  export const SQL_USERNAME_ID = "SELECT id::text AS id FROM users WHERE lower(username) = $1 LIMIT 1";
  export const RELAYED_STREAM = 5; // Nakama's stream mode for a relayed match (subject = the match's uuid)
  export const ROOM_STREAM = 2; // a chat room (label = its name)
  export const MAX_LOOKUPS = 100;
  // M4 Task 10 review: new friend requests a player may send in an hour (Nakama has no limit of its own).
  export const FRIEND_REQUESTS_PER_HOUR = 20;
  export const FRIEND_REQUESTS_KEY = "friend_requests"; // Store.LIMITS: {"times"}

  // `count` more new friend requests in the player's hour, or false (nothing written) when they don't fit.
  export function takeRequests(nk: nkruntime.Nakama, userId: string, count: number, nowMs: number): boolean {
    const found = Store.read(nk, Store.LIMITS, FRIEND_REQUESTS_KEY, userId);
    let times = GiftRules.timesFrom(found ? found.value : undefined);
    for (let i = 0; i < count; i++) {
      const step = GiftRules.allow(times, nowMs, FRIEND_REQUESTS_PER_HOUR, GiftRules.HOUR_MS);
      if (!step.ok) {
        return false;
      }
      times = step.times;
    }
    Store.write(nk, Store.LIMITS, FRIEND_REQUESTS_KEY, userId, { times: times }, false);
    return true;
  }
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  export interface Player {
    userId: string;
    username: string;
    state: AccountRules.Read;
  }

  export function isUuid(value: unknown): boolean {
    return typeof value === "string" && UUID_RE.test(value);
  }

  export function findById(nk: nkruntime.Nakama, userId: unknown): Player | null {
    if (!isUuid(userId)) {
      return null;
    }
    const users = nk.usersGetId([userId as string]);
    if (!users || users.length === 0) {
      return null;
    }
    return { userId: users[0].userId, username: users[0].username, state: AccountRules.fromMetadata(users[0].metadata) };
  }

  // By username, whatever its case (Nakama's own lookups are exact-case).
  export function findByName(nk: nkruntime.Nakama, name: unknown): Player | null {
    if (typeof name !== "string" || UsernameRules.validate(name) === "too_long" || Util.stripEdges(name) === "") {
      return null;
    }
    const rows = nk.sqlQuery(SQL_USERNAME_ID, [UsernameRules.uniquenessKey(name)]);
    return rows.length > 0 ? findById(nk, rows[0].id) : null;
  }

  // The player a request names by "user_id" or else "username".
  export function find(nk: nkruntime.Nakama, request: Util.Json): Player | null {
    if (typeof request.user_id === "string" && request.user_id !== "") {
      return findById(nk, request.user_id);
    }
    return findByName(nk, request.username);
  }

  // A report's player (M4 Task 10 review): by id anyone (a player met while allowed online may have lost
  // it since); by name only a player who may be online (a hidden child's name is never confirmed).
  export function findReported(nk: nkruntime.Nakama, request: Util.Json): Player | null {
    const p = find(nk, request);
    const byId = typeof request.user_id === "string" && request.user_id !== "";
    return p !== null && (byId || AccountRules.canPlayOnline(p.state)) ? p : null;
  }

  // Mutual friends (Nakama friend state 0), not a request or a block.
  export function areFriends(nk: nkruntime.Nakama, userId: string, otherId: string): boolean {
    let cursor: string | undefined = undefined;
    for (let page = 0; page < 10; page++) {
      const list = nk.friendsList(userId, 100, 0, cursor);
      const friends = list.friends || [];
      for (let i = 0; i < friends.length; i++) {
        if (friends[i].user && friends[i].user!.userId === otherId && friends[i].state === 0) {
          return true;
        }
      }
      if (!list.cursor) {
        return false;
      }
      cursor = list.cursor;
    }
    return false;
  }

  function distinctUserIds(presences: nkruntime.Presence[]): string[] {
    const out: string[] = [];
    for (let i = 0; i < presences.length; i++) {
      if (out.indexOf(presences[i].userId) < 0) {
        out.push(presences[i].userId);
      }
    }
    return out;
  }

  // The players in a relayed match now.
  export function matchUserIds(nk: nkruntime.Nakama, subject: string): string[] {
    return distinctUserIds(nk.streamUserList({ mode: RELAYED_STREAM, subject: subject }) || []);
  }

  export function roomUserIds(nk: nkruntime.Nakama, label: string): string[] {
    return distinctUserIds(nk.streamUserList({ mode: ROOM_STREAM, label: label }) || []);
  }

  export interface Hostings {
    records: { [ownerId: string]: InviteRules.Hosting };
    versions: { [ownerId: string]: string };
  }

  export function hostings(nk: nkruntime.Nakama, userIds: string[]): Hostings {
    const found = Store.readMany(nk, Store.INVITES, "current", userIds);
    const out: Hostings = { records: {}, versions: {} };
    for (const id in found) {
      if (Util.has(found, id)) {
        const h = InviteRules.hostingFrom(found[id].value);
        out.versions[id] = found[id].version;
        if (h !== null) {
          out.records[id] = h;
        }
      }
    }
    return out;
  }

  export function withId(ids: string[], id: string): string[] {
    return ids.indexOf(id) >= 0 ? ids : ids.concat([id]);
  }

  export function isVersionClash(e: unknown): boolean {
    return /version check/i.test(Server.errorText(e));
  }
}

// After a player creates a relayed match: that player is its host (the MatchJoin hook and
// invite_friend read this record). A new match replaces the host's old record and its invites.
// (Nakama passes the answer, {"match": {"matchId", "self", ...}}, as `output`.)
function afterMatchCreate(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    output: nkruntime.EnvelopeMatchCreateMessage | null, _input: nkruntime.EnvelopeMatchCreateMessage): void {
  const answer = output as unknown as Util.Json | null;
  const match: Util.Json = answer && Util.isObject(answer.match) ? answer.match : {};
  const subject = InviteRules.matchSubject(match.matchId);
  if (!ctx.userId || subject === null) {
    return;
  }
  try {
    const hosting = InviteRules.newHosting(subject + ".", ctx.userId, Server.nowMs());
    const old = Social.hostings(nk, [ctx.userId]).records[ctx.userId];
    if (old) {
      hosting.sent = old.sent; // M4 Task 10 review: a new match keeps the invite window (20 in 10 minutes)
    }
    Store.write(nk, Store.INVITES, "current", ctx.userId, hosting, false);
  } catch (e) {
    logger.warn("hosting record for %s not written: %s", ctx.userId, Server.errorText(e));
  }
}

// remove_guest {"user_id", "match_id"} (spec §17.3 "Safety in the world", the M4 Task 10 review's finding A): the
// host of a relayed match takes a player out of it (their presences are kicked off the match's stream: the others'
// games see them leave) and off its invite list (no rejoin), and their game gets notification 107 {"match_id"} so it
// goes to the menu without trying to come back. Only the match's host; nothing of the guest's is touched.
// {"ok", "in_match"}; bad_request, not_host, busy.
function rpcRemoveGuest(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "remove_guest", payload, function (userId: string, request: Util.Json): Util.Json {
    const subject = InviteRules.matchSubject(request.match_id);
    if (subject === null || !Social.isUuid(request.user_id) || request.user_id === userId) {
      return Server.fail("bad_request");
    }
    const guestId = request.user_id as string;
    const matchId = subject + ".";
    for (let attempt = 0; attempt < 3; attempt++) {
      const present = Social.matchUserIds(nk, subject);
      const hs = Social.hostings(nk, [userId]);
      const hosting = hs.records[userId];
      if (!hosting || hosting.match_id !== matchId || hosting.host_id !== userId || present.indexOf(userId) < 0) {
        return Server.fail("not_host");
      }
      try {
        Store.write(nk, Store.INVITES, "current", userId, InviteRules.remove(hosting, guestId), false,
          hs.versions[userId] || "*");
      } catch (e) {
        if (Social.isVersionClash(e)) {
          continue; // an invite at the same moment: read again
        }
        throw e;
      }
      const stream = { mode: Social.RELAYED_STREAM, subject: subject };
      const presences = nk.streamUserList(stream) || [];
      let inMatch = false;
      for (let i = 0; i < presences.length; i++) {
        if (presences[i].userId === guestId) {
          nk.streamUserKick(presences[i], stream);
          inMatch = true;
        }
      }
      nk.notificationSend(guestId, "The host asked you to leave their world.", { match_id: matchId }, Notes.REMOVED,
        userId, false);
      return { ok: true, in_match: inMatch };
    }
    return Server.fail("busy");
  });
}

// match_players {"match_id"} (0.2.11, the M4 Task 10 review's finding B): the players in the relayed match the
// caller hosts now, each as the server knows them: {"user_id", "username", "age_band", "chat_level"} (the band read
// strictly: no valid band is under_13; the chat level as the team room applies it, AccountRules.chatLevel). The
// host's game names its players and checks its relay chat and trades with this, never with a guest's own word.
// Only the match's host (as get_gold_of's Economy.target). {"ok", "players"}; bad_request, not_host.
function rpcMatchPlayers(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "match_players", payload, function (userId: string, request: Util.Json): Util.Json {
    const subject = InviteRules.matchSubject(request.match_id);
    if (subject === null) {
      return Server.fail("bad_request");
    }
    const present = Social.matchUserIds(nk, subject);
    const hosting = Social.hostings(nk, [userId]).records[userId];
    if (!hosting || hosting.match_id !== subject + "." || hosting.host_id !== userId || present.indexOf(userId) < 0) {
      return Server.fail("not_host");
    }
    const users = nk.usersGetId(present) || [];
    const players: Util.Json[] = [];
    for (let i = 0; i < users.length; i++) {
      const state = AccountRules.fromMetadata(users[i].metadata);
      players.push({
        user_id: users[i].userId,
        username: users[i].username,
        age_band: AccountRules.effectiveBand(state.age_band),
        chat_level: AccountRules.chatLevel(state),
      });
    }
    return { ok: true, players: players };
  });
}

// invite_friend {"user_id" | "username", "match_id", "world_name"?}: the host invites a friend into
// its relayed match. Both must be allowed online (consent for under_13), the match not full (4).
// The friend gets notification 101 {"match_id", "from_username", "from_user_id", "world_name"}.
function rpcInviteFriend(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "invite_friend", payload, function (userId: string, request: Util.Json): Util.Json {
    const subject = InviteRules.matchSubject(request.match_id);
    if (subject === null) {
      return Server.fail("bad_request");
    }
    const matchId = subject + ".";
    const world = InviteRules.worldName(request.world_name);
    if (world.error) {
      return Server.fail(world.error);
    }
    const caller = Accounts.load(nk, userId);
    const target = Social.find(nk, request);
    const isFriend = target !== null && target.userId !== userId && Social.areFriends(nk, userId, target.userId);
    for (let attempt = 0; attempt < 3; attempt++) {
      const present = Social.matchUserIds(nk, subject);
      const hs = Social.hostings(nk, Social.withId(present, userId));
      const result = InviteRules.invite({
        matchId: matchId, callerId: userId, targetId: target ? target.userId : "", caller: caller.state,
        target: target ? target.state : null, isFriend: isFriend, presentIds: present, records: hs.records, now: Server.nowMs(),
      });
      if (!result.hosting || !target) {
        return Server.fail(result.error || "not_found");
      }
      try {
        Store.write(nk, Store.INVITES, "current", userId, result.hosting, false, hs.versions[userId] || "*");
      } catch (e) {
        if (Social.isVersionClash(e)) {
          continue; // another invite at the same moment: read again
        }
        throw e;
      }
      nk.notificationSend(target.userId, caller.username + " invites you to play!", {
        match_id: matchId, from_username: caller.username, from_user_id: userId, world_name: world.name,
      }, Notes.INVITE, userId, true);
      return { ok: true, user_id: target.userId, username: target.username, expires_ms: result.hosting.invited[target.userId] };
    }
    return Server.fail("busy");
  });
}

// Joining a relayed match: only the host and players it invited; never a 5th player. Refusing
// throws (the game gets the code, e.g. "not_invited", "match_full"); returning nothing would close
// the player's session.
function rtBeforeMatchJoin(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    envelope: nkruntime.EnvelopeMatchJoin): nkruntime.EnvelopeMatchJoin {
  const join: Util.Json = Util.isObject(envelope.matchJoin) ? envelope.matchJoin : {};
  const subject = InviteRules.matchSubject(join.matchId !== undefined ? join.matchId : join.match_id);
  if (subject === null || !ctx.userId) {
    Server.refuse("not_invited", Server.PERMISSION_DENIED); // a matchmaker token, or not a relayed match
  }
  const userId = ctx.userId as string;
  const present = Social.matchUserIds(nk, subject as string);
  const hs = Social.hostings(nk, Social.withId(present, userId));
  const result = InviteRules.join({
    matchId: subject + ".", userId: userId, joiner: Accounts.load(nk, userId).state, presentIds: present,
    records: hs.records, devOpen: Server.flag(ctx, "EASYCRAFT_DEV_OPEN_MATCHES"), now: Server.nowMs(),
  });
  if (result.error) {
    Server.refuse(result.error, result.error === "match_full" ? Server.RESOURCE_EXHAUSTED : Server.PERMISSION_DENIED);
  }
  // M4 Task 10 review: an invite, and the day's way back, last only while the host and the guest are
  // friends: a guest the host unfriended or blocked stays out.
  if (result.renew && !Social.areFriends(nk, result.renew.ownerId, userId)) {
    Server.refuse("not_invited", Server.PERMISSION_DENIED);
  }
  if (result.renew) {
    try {
      Store.write(nk, Store.INVITES, "current", result.renew.ownerId, result.renew.hosting, false, hs.versions[result.renew.ownerId]);
    } catch (e) {
      logger.warn("invite for %s not renewed: %s", userId, Server.errorText(e));
    }
  }
  return envelope;
}

// Matchmaking and parties would let strangers meet: switched off (spec §17.3: friends only).
function rtBeforeRefuse(_ctx: nkruntime.Context, _logger: nkruntime.Logger, _nk: nkruntime.Nakama, _envelope: unknown): never {
  return Server.refuse("not_available", Server.PERMISSION_DENIED);
}

// M4 Task 10 review: groups (a free-text name and description anyone can list, members anyone can see)
// and friends imported from Facebook or Steam (they skip AddFriends: no consent check, no grown-up's
// yes) are switched off; the game uses neither.
function beforeRefuseSocial(_ctx: nkruntime.Context, _logger: nkruntime.Logger, _nk: nkruntime.Nakama, _data: unknown): never {
  return Server.refuse("not_available", Server.PERMISSION_DENIED);
}

// Friend requests (and accepting one): only by players who may be online, only to players who may
// be online (a child without a parent's yes is not findable: "not_found", as for nobody), by exact
// username whatever its case. An under-13 player's requests wait for a grown-up (parents.ts).
function beforeAddFriends(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    data: nkruntime.AddFriendsRequest): nkruntime.AddFriendsRequest {
  const caller = ctx.userId ? Accounts.load(nk, ctx.userId) : null;
  if (caller === null || !AccountRules.canPlayOnline(caller.state)) {
    Server.refuse("not_allowed_online", Server.PERMISSION_DENIED);
  }
  const ids: string[] = [];
  const players: Social.Player[] = [];
  const add = function (p: Social.Player | null): void {
    if (p === null || !AccountRules.canPlayOnline(p.state)) {
      Server.refuse("not_found", Server.NOT_FOUND);
    }
    if (ids.indexOf(p!.userId) < 0) {
      ids.push(p!.userId);
      players.push(p!);
    }
  };
  const byId = (data.ids || []).slice(0, Social.MAX_LOOKUPS);
  for (let i = 0; i < byId.length; i++) {
    add(Social.findById(nk, byId[i]));
  }
  const byName = (data.usernames || []).slice(0, Social.MAX_LOOKUPS);
  for (let i = 0; i < byName.length; i++) {
    add(Social.findByName(nk, byName[i]));
  }
  // M4 Task 10 review: new requests (no edge yet) count against the hour's limit; a "yes" to a request
  // that came in, or a player already a friend, never does.
  const edges = Parents.edgeStates(nk, ctx.userId as string, ids);
  let fresh = 0;
  for (let i = 0; i < ids.length; i++) {
    if (edges[ids[i]] === undefined) {
      fresh++;
    }
  }
  if (fresh > 0 && !Social.takeRequests(nk, ctx.userId as string, fresh, Server.nowMs())) {
    Server.refuse("too_many", Server.RESOURCE_EXHAUSTED);
  }
  // M4 Wave 2, agent F: an under-13 player's friends wait for a grown-up's yes (approve_friend).
  if (FriendApprovals.needsApproval(caller!.state) && Parents.hold(nk, ctx.userId as string, players)) {
    Server.refuse("needs_grown_up", Server.PERMISSION_DENIED);
  }
  data.ids = ids;
  data.usernames = [];
  return data;
}

// Looking players up: by id, or by username whatever its case; a child who may not be online is
// never found (spec §17.2: no findable username before consent), except by themselves.
function beforeGetUsers(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    data: nkruntime.GetUsersRequest): nkruntime.GetUsersRequest {
  const keep: string[] = [];
  const consider = function (p: Social.Player | null): void {
    if (p !== null && keep.indexOf(p.userId) < 0 && (p.userId === ctx.userId || AccountRules.canPlayOnline(p.state))) {
      keep.push(p.userId);
    }
  };
  const byId = (data.ids || []).slice(0, Social.MAX_LOOKUPS);
  for (let i = 0; i < byId.length; i++) {
    consider(Social.findById(nk, byId[i]));
  }
  const byName = (data.usernames || []).slice(0, Social.MAX_LOOKUPS);
  for (let i = 0; i < byName.length; i++) {
    consider(Social.findByName(nk, byName[i]));
  }
  data.ids = keep;
  data.usernames = [];
  data.facebookIds = [];
  return data;
}

// report_user {"user_id" | "username", "reason", "match_id"?, "channel_id"?, "message_id"?,
// "message"?}: stored in "reports" (owned by the system user, read by a person in the Nakama
// console). With a message id, the report keeps a snapshot of that message (M4 G, snapshots.ts):
// the server's own copy, else "message" as the reporter's game showed it ({"text"} or {"emote"},
// "at_ms"), marked "source": "server" or "reporter".
function rpcReportUser(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "report_user", payload, function (userId: string, request: Util.Json): Util.Json {
    const target = Social.findReported(nk, request);
    if (target === null) {
      return Server.fail("not_found");
    }
    if (target.userId === userId) {
      return Server.fail("cannot_report_self");
    }
    const now = Server.nowMs();
    const found = Store.read(nk, Store.LIMITS, "report", userId);
    const step = ReportRules.accept(ReportRules.windowFrom(found ? found.value : undefined), target.userId, now);
    if (step.error) {
      return Server.fail(step.error);
    }
    if (step.store) {
      const me = Accounts.load(nk, userId);
      const subject = InviteRules.matchSubject(request.match_id);
      const channel = typeof request.channel_id === "string" && /^[0-9A-Za-z.\-_]{1,256}$/.test(request.channel_id)
        ? request.channel_id : "";
      const messageId = Social.isUuid(request.message_id) ? request.message_id as string : "";
      const value: Util.Json = {
        reporter_id: userId, reporter_username: me.username,
        reported_id: target.userId, reported_username: target.username,
        reason: ReportRules.reason(request.reason),
        match_id: subject ? subject + "." : "", channel_id: channel,
        message_id: messageId,
        created_ms: now, status: "new",
      };
      if (messageId !== "") {
        value.message = Snapshots.of(nk, userId, target.userId, channel, messageId, request.message, now); // M4 G
      }
      Store.write(nk, Store.REPORTS, now + "_" + userId, Store.SYSTEM_USER, value, false);
      Store.write(nk, Store.LIMITS, "report", userId, step.window, false);
      logger.info("report stored: %s reported %s", userId, target.userId);
    }
    return { ok: true };
  });
}
