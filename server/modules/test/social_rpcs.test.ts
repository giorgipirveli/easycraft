// invite_friend, report_user and the social hooks against the fake Nakama (spec §17.0-17.4, plan
// M4 Wave 1): notification 101, the hosting record, MatchJoin (invited only, at most 4), friends
// and user lookups that hide children who may not be online, chat rules on channels, and storage
// a game may not write.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const DEV_ENV = { EASYCRAFT_DEV_OPEN_MATCHES: "true" };

let nk: FakeNakama;
let log: FakeLogger;
let now = 2_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 2_000_000;
  S.Server.nowMs = () => now;
});

function call(fn: string, userId: string, payload: unknown = {}, env: object = {}): any {
  return JSON.parse(S[fn](ctx(userId, env), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

const TEEN = A.defaults("13_plus");
const KID_OK = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const KID_NO = A.defaults("under_13");

// A host (13_plus) in a new relayed match, with the after-create hook's record, and a friend.
function hostWithFriend(friendMeta: object = KID_OK): { host: string; friend: string; match: string } {
  const host = nk.addUser("Hostie", TEEN);
  const friend = nk.addUser("Buddy_1", friendMeta);
  nk.befriend(host, friend);
  const match = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: match, self: { userId: host } } }, { matchCreate: {} });
  return { host, friend, match };
}

function joinHook(userId: string, match: string, env: object = {}): any {
  return S.rtBeforeMatchJoin(ctx(userId, env), log, nk, { cid: "1", matchJoin: { matchId: match, metadata: {} } });
}

test("after MatchCreate the creator is recorded as the match's host (server-only storage)", () => {
  const { host, match } = hostWithFriend();
  const rec = nk.object("invites", "current", host)!;
  assert.equal(rec.value.match_id, match);
  assert.equal(rec.value.host_id, host);
  assert.equal(rec.permissionRead, 0);
  assert.equal(rec.permissionWrite, 0);
});

test("invite_friend: notification 101 with the match, the host's name and the world's name", () => {
  const { host, friend, match } = hostWithFriend();
  const r = call("rpcInviteFriend", host, { username: "buddy_1", match_id: match, world_name: " Castle  Hill " });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.user_id, friend);
  assert.equal(r.expires_ms, now + S.InviteRules.INVITE_TTL_MS);
  assert.equal(nk.notifications.length, 1);
  const note = nk.notifications[0];
  assert.equal(note.code, 101);
  assert.equal(note.userId, friend);
  assert.equal(note.senderId, host);
  assert.equal(note.persistent, true);
  assert.deepEqual(note.content, { match_id: match, from_username: "Hostie", from_user_id: host, world_name: "Castle Hill" });
  assert.equal(nk.object("invites", "current", host)!.value.invited[friend], now + S.InviteRules.INVITE_TTL_MS);
});

test("invite_friend: by user id too, and the refusals", () => {
  const { host, friend, match } = hostWithFriend();
  assert.equal(call("rpcInviteFriend", host, { user_id: friend, match_id: match }).ok, true);
  const stranger = nk.addUser("Stranger", TEEN);
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: stranger, match_id: match }), { ok: false, error: "not_friends" });
  assert.deepEqual(call("rpcInviteFriend", host, { username: "Nobody", match_id: match }), { ok: false, error: "not_found" });
  assert.deepEqual(call("rpcInviteFriend", host, { username: "Buddy_1", match_id: "nope" }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcInviteFriend", host, { match_id: match }), { ok: false, error: "not_found" });
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: friend, match_id: match, world_name: "call 5551234567" }),
    { ok: false, error: "bad_world_name" });
  const pending = nk.addUser("Pending", TEEN);
  nk.befriend(host, pending, 1);
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: pending, match_id: match }), { ok: false, error: "not_friends" },
    "a friend request not yet accepted");
});

test("invite_friend: a child without a parent's yes can't be invited, and can't invite", () => {
  const { host, match } = hostWithFriend(KID_NO);
  assert.deepEqual(call("rpcInviteFriend", host, { username: "Buddy_1", match_id: match }), { ok: false, error: "friend_cannot_join" });
  const kid = nk.addUser("Kiddo", KID_NO);
  const other = nk.addUser("Pal", TEEN);
  nk.befriend(kid, other);
  const kidMatch = nk.createMatch(kid);
  assert.deepEqual(call("rpcInviteFriend", kid, { user_id: other, match_id: kidMatch }), { ok: false, error: "not_allowed_online" });
});

// M4 Task 10 review: a child who may not be online is "nobody" to a stranger's name lookups everywhere
// (spec §17.2: no findable username before consent): invite_friend and report_user by name said
// "not_friends" and "ok" for them, which told a stranger that the name exists.
test("a child who may not be online looks like nobody to a stranger's invite or report by name", () => {
  const { host, match } = hostWithFriend();
  nk.addUser("Hidden_1", KID_NO);
  assert.deepEqual(call("rpcInviteFriend", host, { username: "hidden_1", match_id: match }), { ok: false, error: "not_found" });
  assert.deepEqual(call("rpcInviteFriend", host, { username: "Nobody_9", match_id: match }), { ok: false, error: "not_found" });
  assert.deepEqual(call("rpcReportUser", host, { username: "Hidden_1", reason: "other" }), { ok: false, error: "not_found" });
  const was = nk.addUser("WasFriend", KID_NO);   // met while allowed online, reported by id afterwards: still works
  assert.equal(call("rpcReportUser", host, { user_id: was, reason: "mean_words" }).ok, true);
});

// M4 Task 10 review: the invite window (20 in 10 minutes) lived in the hosting record, which a new match
// replaced: a host could make matches to send a friend invite after invite (each a persistent notification).
test("invite_friend: a new match does not start a new invite window", () => {
  const { host, friend, match } = hostWithFriend();
  for (let i = 0; i < S.InviteRules.RATE_COUNT; i++) {
    assert.equal(call("rpcInviteFriend", host, { user_id: friend, match_id: match }).ok, true, String(i));
  }
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: friend, match_id: match }), { ok: false, error: "too_fast" });
  const again = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: again, self: { userId: host } } }, { matchCreate: {} });
  assert.equal(nk.object("invites", "current", host)!.value.match_id, again, "the new match is the host's now");
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: friend, match_id: again }), { ok: false, error: "too_fast" });
  now += S.InviteRules.RATE_WINDOW_MS;
  assert.equal(call("rpcInviteFriend", host, { user_id: friend, match_id: again }).ok, true);
});

test("invite_friend: only the host invites, and never into a full match", () => {
  const { host, friend, match } = hostWithFriend();
  call("rpcInviteFriend", host, { user_id: friend, match_id: match });
  nk.joinMatch(match, friend);
  const pal = nk.addUser("Pal", TEEN);
  nk.befriend(friend, pal);
  assert.deepEqual(call("rpcInviteFriend", friend, { user_id: pal, match_id: match }), { ok: false, error: "not_host" });
  for (const name of ["G2", "G3"]) {
    nk.joinMatch(match, nk.addUser(name, TEEN));
  }
  nk.befriend(host, pal);
  assert.deepEqual(call("rpcInviteFriend", host, { user_id: pal, match_id: match }), { ok: false, error: "match_full" });
});

test("MatchJoin: the invited friend gets in; a stranger and a 5th player don't", () => {
  const { host, friend, match } = hostWithFriend();
  const stranger = nk.addUser("Stranger", TEEN);
  assert.throws(() => joinHook(friend, match), (e: any) => e.message === "not_invited" && e.code === 7, "not invited yet");
  call("rpcInviteFriend", host, { user_id: friend, match_id: match });
  const env = { cid: "1", matchJoin: { matchId: match, metadata: {} } };
  assert.deepEqual(joinHook(friend, match), env, "the envelope goes on unchanged");
  assert.equal(nk.object("invites", "current", host)!.value.invited[friend], now + S.InviteRules.REJOIN_MS,
    "once in, the friend may come back for a day");
  assert.throws(() => joinHook(stranger, match), (e: any) => e.message === "not_invited");
  nk.joinMatch(match, friend);
  const more = ["G2", "G3", "G4"].map((n) => nk.addUser(n, TEEN));
  for (const g of more) {
    nk.befriend(host, g);
    call("rpcInviteFriend", host, { user_id: g, match_id: match });
  }
  nk.joinMatch(match, more[0]);
  nk.joinMatch(match, more[1]);
  assert.throws(() => joinHook(more[2], match), (e: any) => e.message === "match_full" && e.code === 8, "the 5th player");
});

// M4 Task 10 review: an invite (1 h) and the way back (24 h) end when the host unfriends or blocks the guest.
test("MatchJoin: a guest the host unfriended or blocked can't come (back) in", () => {
  const { host, friend, match } = hostWithFriend();
  call("rpcInviteFriend", host, { user_id: friend, match_id: match });
  nk.friendsDelete(host, "Hostie", [friend]);
  assert.throws(() => joinHook(friend, match), (e: any) => e.message === "not_invited", "unfriended before joining");
  nk.befriend(host, friend);
  call("rpcInviteFriend", host, { user_id: friend, match_id: match });
  assert.equal(joinHook(friend, match).matchJoin.matchId, match);
  nk.joinMatch(match, friend);
  nk.leaveMatch(match, friend);   // the phone dropped: it may come back for a day ...
  assert.equal(joinHook(friend, match).matchJoin.matchId, match);
  nk.edges.get(host)!.set(friend, 3);   // ... unless the host blocks it meanwhile
  nk.edges.get(friend)!.delete(host);
  assert.throws(() => joinHook(friend, match), (e: any) => e.message === "not_invited", "blocked");
});

test("MatchJoin: the host comes back to its match after a drop", () => {
  const { host, friend, match } = hostWithFriend();
  call("rpcInviteFriend", host, { user_id: friend, match_id: match });
  nk.joinMatch(match, friend);
  nk.leaveMatch(match, host);
  assert.deepEqual(joinHook(host, match).matchJoin.matchId, match);
});

test("MatchJoin: matchmaker tokens are refused (no strangers through the matchmaker)", () => {
  const { friend } = hostWithFriend();
  assert.throws(() => S.rtBeforeMatchJoin(ctx(friend), log, nk, { matchJoin: { token: "abc", metadata: {} } }),
    (e: any) => e.message === "not_invited");
});

test("MatchJoin on a developer server: unclaimed developer accounts join by id, claimed ones need an invite", () => {
  const { match } = hostWithFriend();
  const dev = nk.addUser("xRandomDev");
  assert.equal(joinHook(dev, match, DEV_ENV).matchJoin.matchId, match);
  assert.throws(() => joinHook(dev, match, {}), (e: any) => e.message === "not_invited", "not on a production server");
  const claimedStranger = nk.addUser("Stranger", TEEN);
  assert.throws(() => joinHook(claimedStranger, match, DEV_ENV), (e: any) => e.message === "not_invited");
});

test("MatchJoin on a production server: the developer switch is ignored", () => {
  const { match } = hostWithFriend();
  const dev = nk.addUser("xRandomDev");
  assert.throws(() => joinHook(dev, match, { ...DEV_ENV, EASYCRAFT_ENV: "production" }), (e: any) => e.message === "not_invited");
});

test("matchmaking and parties are switched off (strangers could meet there)", () => {
  const id = nk.addUser("Anyone", TEEN);
  assert.throws(() => S.rtBeforeRefuse(ctx(id), log, nk, { matchmakerAdd: {} }), (e: any) => e.message === "not_available");
});

// M4 Task 10 review: groups (a free-text name and description anyone can list, members anyone can see)
// and friends imported from Facebook or Steam (they skip AddFriends: no consent check, no grown-up's yes).
test("groups and imported friends are switched off (strangers, free text, friends without a grown-up)", () => {
  const registered: string[] = [];
  const init: any = new Proxy({}, { get: (_t, name: string) => (id: any, fn: any) => {
    registered.push(typeof id === "string" ? name + ":" + id + ":" + (fn && fn.name) : name + ":" + (id && id.name));
  } });
  S.InitModule(ctx(""), log, nk, init);
  for (const want of ["registerBeforeCreateGroup:beforeRefuseSocial", "registerBeforeImportFacebookFriends:beforeRefuseSocial",
    "registerBeforeImportSteamFriends:beforeRefuseSocial"]) {
    assert.ok(registered.includes(want), want + " in " + registered.join(", "));
  }
  const id = nk.addUser("Anyone", TEEN);
  assert.throws(() => S.beforeRefuseSocial(ctx(id), log, nk, { name: "free robux", open: true }),
    (e: any) => e.message === "not_available" && e.code === 7);
});

test("AddFriends: only players who may be online, by exact name whatever the case; hidden children look like nobody", () => {
  const me = nk.addUser("Me_1", TEEN);
  nk.addUser("Buddy_1", KID_OK);
  const hidden = nk.addUser("Hidden_1", KID_NO);
  const out = S.beforeAddFriends(ctx(me), log, nk, { ids: [], usernames: ["buddy_1"], metadata: "" });
  assert.deepEqual(out.usernames, []);
  assert.equal(out.ids.length, 1);
  assert.equal(nk.users.get(out.ids[0])!.username, "Buddy_1");
  assert.throws(() => S.beforeAddFriends(ctx(me), log, nk, { usernames: ["Hidden_1"] }), (e: any) => e.message === "not_found");
  assert.throws(() => S.beforeAddFriends(ctx(me), log, nk, { ids: [hidden] }), (e: any) => e.message === "not_found");
  assert.throws(() => S.beforeAddFriends(ctx(me), log, nk, { usernames: ["Ghost"] }), (e: any) => e.message === "not_found");
  const kid = nk.addUser("Kiddo", KID_NO);
  assert.throws(() => S.beforeAddFriends(ctx(kid), log, nk, { usernames: ["Me_1"] }),
    (e: any) => e.message === "not_allowed_online" && e.code === 7);
});

// M4 Task 10 review: Nakama has no limit on friend requests; a stranger who guesses names could send
// hundreds to children. New requests (not a "yes" to one that came in) are 20 an hour.
test("AddFriends: at most 20 new friend requests an hour; saying yes to a request never counts", () => {
  const me = nk.addUser("Me_1", TEEN);
  const names: string[] = [];
  for (let i = 0; i < 21; i++) {
    nk.addUser("Pal_" + i, TEEN);
    names.push("Pal_" + i);
  }
  for (let i = 0; i < S.Social.FRIEND_REQUESTS_PER_HOUR; i++) {
    const out = S.beforeAddFriends(ctx(me), log, nk, { usernames: [names[i]] });
    assert.equal(out.ids.length, 1, names[i]);
    nk.friendsAdd(me, "Me_1", out.ids);
  }
  assert.throws(() => S.beforeAddFriends(ctx(me), log, nk, { usernames: [names[20]] }),
    (e: any) => e.message === "too_many" && e.code === 8, "the 21st new request this hour");
  const asker = nk.addUser("Asker", TEEN);
  nk.friendsAdd(asker, "Asker", [me]);   // they asked me: my yes is not a new request
  assert.equal(S.beforeAddFriends(ctx(me), log, nk, { ids: [asker] }).ids[0], asker);
  now += 60 * 60 * 1000;
  assert.equal(S.beforeAddFriends(ctx(me), log, nk, { usernames: [names[20]] }).ids.length, 1, "an hour later");
});

test("GetUsers: finds by name whatever the case, never a child who may not be online (but always yourself)", () => {
  const me = nk.addUser("Me_1", KID_NO);
  const buddy = nk.addUser("Buddy_1", TEEN);
  const hidden = nk.addUser("Hidden_1", KID_NO);
  const out = S.beforeGetUsers(ctx(me), log, nk, { ids: [hidden, me], usernames: ["BUDDY_1", "hidden_1", "ghost"], facebookIds: ["x"] });
  assert.deepEqual(out.ids.sort(), [buddy, me].sort());
  assert.deepEqual(out.usernames, []);
  assert.deepEqual(out.facebookIds, []);
});

test("report_user: stored for the console (system-owned), the reason as a code, never twice in 10 minutes", () => {
  const me = nk.addUser("Me_1", TEEN);
  const bad = nk.addUser("Meanie", TEEN);
  const match = nk.createMatch(bad);
  const r = call("rpcReportUser", me, { username: "meanie", reason: "mean_words", match_id: match, message_id: "not a uuid!" });
  assert.equal(r.ok, true, JSON.stringify(r));
  const reports = [...nk.storage.values()].filter((o) => o.collection === "reports");
  assert.equal(reports.length, 1);
  const rep = reports[0];
  assert.equal(rep.userId, SYSTEM_USER);
  assert.equal(rep.permissionRead, 0);
  assert.equal(rep.permissionWrite, 0);
  assert.deepEqual(rep.value, {
    reporter_id: me, reporter_username: "Me_1", reported_id: bad, reported_username: "Meanie",
    reason: "mean_words", match_id: match, channel_id: "", message_id: "", created_ms: now, status: "new",
  });
  assert.equal(call("rpcReportUser", me, { user_id: bad, reason: "scary" }).ok, true, "thanked again ...");
  assert.equal([...nk.storage.values()].filter((o) => o.collection === "reports").length, 1, "... but not stored twice");
});

test("report_user: refusals", () => {
  const me = nk.addUser("Me_1", TEEN);
  assert.deepEqual(call("rpcReportUser", me, { username: "Ghost" }), { ok: false, error: "not_found" });
  assert.deepEqual(call("rpcReportUser", me, { user_id: me }), { ok: false, error: "cannot_report_self" });
  for (let i = 0; i < S.ReportRules.MAX_PER_HOUR; i++) {
    const u = nk.addUser("Kid" + i, TEEN);
    assert.equal(call("rpcReportUser", me, { user_id: u, reason: "other" }).ok, true);
  }
  const one = nk.addUser("OneMore", TEEN);
  assert.deepEqual(call("rpcReportUser", me, { user_id: one }), { ok: false, error: "too_many" });
});

// --- chat ---

function send(userId: string, channelId: string, content: unknown): any {
  return S.rtBeforeChannelMessageSend(ctx(userId), log, nk,
    { cid: "3", channelMessageSend: { channelId, content: typeof content === "string" ? content : JSON.stringify(content) } });
}

test("ChannelJoin: direct messages only between friends who may chat; rooms only for a match's team; no groups", () => {
  const teen = nk.addUser("Teen_1", TEEN);
  const kid = nk.addUser("Kid_1", KID_OK);
  const offline = nk.addUser("Kid_2", KID_NO);
  const stranger = nk.addUser("Stranger", TEEN);
  nk.befriend(teen, kid);
  nk.befriend(teen, offline);
  const joinCh = (u: string, target: string, type: number) =>
    S.rtBeforeChannelJoin(ctx(u), log, nk, { channelJoin: { target, type, persistence: false, hidden: false } });
  assert.equal(joinCh(teen, kid, 2).channelJoin.target, kid);
  assert.throws(() => joinCh(teen, stranger, 2), (e: any) => e.message === "not_friends");
  assert.throws(() => joinCh(teen, offline, 2), (e: any) => e.message === "chat_off", "the friend's parent switched chat off");
  assert.throws(() => joinCh(offline, teen, 2), (e: any) => e.message === "chat_off");
  assert.throws(() => joinCh(teen, "lobby", 1), (e: any) => e.message === "room_not_allowed");
  const match = nk.createMatch(teen);
  assert.equal(joinCh(teen, match, 1).channelJoin.target, match, "team chat: a room named after my match");
  assert.throws(() => joinCh(stranger, match, 1), (e: any) => e.message === "room_not_allowed", "not in that match");
  assert.throws(() => joinCh(teen, "some-group", 3), (e: any) => e.message === "not_available");
});

test("ChannelMessageSend: a DM between a teen and an under-13 carries quick phrases and emotes only", () => {
  const teen = nk.addUser("Teen_1", TEEN);
  const kid = nk.addUser("Kid_1", KID_OK);
  nk.befriend(teen, kid);
  const dm = "4." + [teen, kid].sort().join(".") + ".";
  assert.equal(JSON.parse(send(teen, dm, { text: " Hi! " }).channelMessageSend.content).text, "Hi!", "cleaned");
  assert.equal(JSON.parse(send(teen, dm, { emote: "wave" }).channelMessageSend.content).emote, "wave");
  assert.throws(() => send(teen, dm, { text: "want to build a castle?" }), (e: any) => e.message === "quick_chat_only");
  assert.throws(() => send(kid, dm, { text: "hello" }), (e: any) => e.message === "quick_chat_only");
  assert.throws(() => send(teen, dm, "plain text"), (e: any) => e.message === "bad_message");
  assert.throws(() => send(teen, dm, { text: "Hi!", link: "x" }), (e: any) => e.message === "bad_message");
});

test("ChannelMessageSend: two teens chat in filtered free text", () => {
  const a = nk.addUser("Teen_1", TEEN);
  const b = nk.addUser("Teen_2", TEEN);
  nk.befriend(a, b);
  const dm = "4." + [a, b].sort().join(".") + ".";
  assert.equal(JSON.parse(send(a, dm, { text: "  want   to build? " }).channelMessageSend.content).text, "want to build?");
  assert.throws(() => send(a, dm, { text: "my number is 555 123 4567" }), (e: any) => e.message === "personal_info");
  assert.throws(() => send(a, dm, { text: "you are stupid" }), (e: any) => e.message === "blocked_word");
  const stranger = nk.addUser("Stranger", TEEN);
  assert.throws(() => send(stranger, dm, { text: "hi" }), (e: any) => e.message === "not_in_channel");
});

// M4 Task 10 review: Nakama checks friendship only when a DM is joined; a player who stays in the
// channel after being unfriended or blocked must not go on sending to the child who did it.
test("ChannelMessageSend: a DM stops the moment the two are no longer friends (unfriended or blocked)", () => {
  const a = nk.addUser("Teen_1", TEEN);
  const b = nk.addUser("Teen_2", TEEN);
  nk.befriend(a, b);
  const dm = "4." + [a, b].sort().join(".") + ".";
  assert.equal(JSON.parse(send(a, dm, { text: "Hi!" }).channelMessageSend.content).text, "Hi!");
  nk.friendsDelete(b, "Teen_2", [a]);
  assert.throws(() => send(a, dm, { text: "Hi!" }), (e: any) => e.message === "not_friends" && e.code === 7, "unfriended");
  nk.befriend(a, b);
  nk.edges.get(b)!.set(a, 3);   // b blocked a (Nakama: 3 on the blocker's side)
  nk.edges.get(a)!.delete(b);
  assert.throws(() => send(a, dm, { emote: "wave" }), (e: any) => e.message === "not_friends", "blocked");
  assert.throws(() => S.rtBeforeChannelMessageUpdate(ctx(a), log, nk,
    { channelMessageUpdate: { channelId: dm, messageId: "m1", content: JSON.stringify({ text: "Hi!" }) } }),
    (e: any) => e.message === "not_friends", "an edit too");
});

test("ChannelMessageSend: team chat takes the strictest level of the match's players", () => {
  const teen = nk.addUser("Teen_1", TEEN);
  const kid = nk.addUser("Kid_1", KID_OK);
  const match = nk.createMatch(teen);
  const room = "2..." + match;
  nk.streams.set("2||" + match, [nk.presence(teen)]);
  assert.equal(JSON.parse(send(teen, room, { text: "who wants to build?" }).channelMessageSend.content).text, "who wants to build?");
  nk.streams.get("2||" + match)!.push(nk.presence(kid));
  assert.throws(() => send(teen, room, { text: "who wants to build?" }), (e: any) => e.message === "quick_chat_only");
  assert.equal(JSON.parse(send(teen, room, { text: "Wow!" }).channelMessageSend.content).text, "Wow!");
});

// M4 Task 10 review: the team room is checked at the join only; a player who left the match (or was dropped
// and may not come back: the host blocked them) but stayed in the room must not go on talking to it.
test("ChannelMessageSend: team chat only from a player who is in the match now", () => {
  const teen = nk.addUser("Teen_1", TEEN);
  const guest = nk.addUser("Teen_2", TEEN);
  const match = nk.createMatch(teen);
  nk.joinMatch(match, guest);
  const room = "2..." + match;
  nk.streams.set("2||" + match, [nk.presence(teen), nk.presence(guest)]);
  assert.equal(JSON.parse(send(guest, room, { text: "Hi!" }).channelMessageSend.content).text, "Hi!");
  nk.leaveMatch(match, guest);
  assert.throws(() => send(guest, room, { text: "Hi!" }), (e: any) => e.message === "room_not_allowed" && e.code === 7);
  assert.throws(() => send(guest, "2...lobby", { text: "Hi!" }), (e: any) => e.message === "room_not_allowed", "not a match's room");
});

test("ChannelMessageUpdate: an edit follows the same rules", () => {
  const teen = nk.addUser("Teen_1", TEEN);
  const kid = nk.addUser("Kid_1", KID_OK);
  nk.befriend(teen, kid);
  const dm = "4." + [teen, kid].sort().join(".") + ".";
  const upd = (content: object) => S.rtBeforeChannelMessageUpdate(ctx(teen), log, nk,
    { channelMessageUpdate: { channelId: dm, messageId: "m1", content: JSON.stringify(content) } });
  assert.equal(JSON.parse(upd({ text: "Bye!" }).channelMessageUpdate.content).text, "Bye!");
  assert.throws(() => upd({ text: "sneaky free text" }), (e: any) => e.message === "quick_chat_only");
});

// --- storage a game may write ---

test("a game writes only its profile backup: private, a sane key and size", () => {
  const me = nk.addUser("Me_1", TEEN);
  const w = (objects: object[]) => S.beforeWriteStorageObjects(ctx(me), log, nk, { objects });
  // Owner #67 (module 0.2.12): the one object "profile", its value cleaned (the account's own name and band).
  const value = '{"version":1,"username":"Me_1","age_band":"13_plus","universe_unlocked":2}';
  const ok = { objects: [{ collection: "profiles", key: "profile", value, version: "", permissionRead: null, permissionWrite: null }] };
  assert.deepEqual(w(structuredClone(ok.objects)), ok);
  for (const collection of ["parent", "codes", "farm", "reports", "invites", "limits", "account", "anything"]) {
    assert.throws(() => w([{ collection, key: "consent", value: "{}" }]), (e: any) => e.message === "not_allowed" && e.code === 7, collection);
  }
  assert.throws(() => w([{ collection: "profiles", key: "profile", value, permissionRead: 2 }]),
    (e: any) => e.message === "not_allowed", "profiles are private");
  assert.throws(() => w([{ collection: "profiles", key: "../x", value }]), (e: any) => e.message === "bad_request");
  assert.throws(() => w([{ collection: "profiles", key: "backup", value }]), (e: any) => e.message === "not_allowed",
    "owner #67: one object only");
  assert.throws(() => w([{ collection: "profiles", key: "profile", value: "x".repeat(S.ProfileRules.MAX_CHARS + 1) }]), (e: any) => e.message === "too_big");
  const del = (ids: object[]) => S.beforeDeleteStorageObjects(ctx(me), log, nk, { objectIds: ids });
  assert.deepEqual(del([{ collection: "profiles", key: "profile" }]), { objectIds: [{ collection: "profiles", key: "profile" }] });
  assert.throws(() => del([{ collection: "parent", key: "consent" }]), (e: any) => e.message === "not_allowed");
});

// --- chat history (M4 Wave 2, agent E; spec §17.2): kept for two 13+ players only, 30 days ---

test("ChannelJoin keeps history only for two teens with text chat; never with an under-13 player or in a room", () => {
  const a = nk.addUser("Teen_1", TEEN);
  const b = nk.addUser("Teen_2", TEEN);
  const kid = nk.addUser("Kid_1", KID_OK);
  nk.befriend(a, b);
  nk.befriend(a, kid);
  const joinCh = (u: string, target: string, type: number, persistence: boolean) =>
    S.rtBeforeChannelJoin(ctx(u), log, nk, { channelJoin: { target, type, persistence, hidden: false } }).channelJoin;
  assert.equal(joinCh(a, b, 2, true).persistence, true);
  assert.equal(joinCh(a, b, 2, false).persistence, false, "the game asked for none");
  assert.equal(joinCh(a, kid, 2, true).persistence, false, "an under-13 friend: nothing kept (a modified game can't ask)");
  assert.equal(joinCh(kid, a, 2, true).persistence, false);
  const quiet = nk.addUser("Teen_3", { ...TEEN, chat: "quick" });
  nk.befriend(a, quiet);
  assert.equal(joinCh(a, quiet, 2, true).persistence, false, "quick chat keeps nothing either");
  const match = nk.createMatch(a);
  assert.equal(joinCh(a, match, 1, true).persistence, false, "team rooms keep nothing");
});

test("opening a kept DM clears its messages older than 30 days", () => {
  const a = nk.addUser("Teen_1", TEEN);
  const b = nk.addUser("Teen_2", TEEN);
  nk.befriend(a, b);
  now = 400 * 86400 * 1000;
  const dm = nk.channelIdBuild(a, b, 2);
  nk.addChannelMessage(dm, b, "Teen_2", now / 1000 - 40 * 86400);
  nk.addChannelMessage(dm, a, "Teen_1", now / 1000 - 31 * 86400);
  nk.addChannelMessage(dm, b, "Teen_2", now / 1000 - 2 * 86400);
  S.rtBeforeChannelJoin(ctx(a), log, nk, { channelJoin: { target: b, type: 2, persistence: true, hidden: false } });
  assert.equal(nk.channelMessagesList(dm, 100, true).messages.length, 1, "only the last 30 days stay");
  const kid = nk.addUser("Kid_1", KID_OK);
  nk.befriend(a, kid);
  const kidDm = nk.channelIdBuild(a, kid, 2);
  nk.addChannelMessage(kidDm, a, "Teen_1", now / 1000 - 40 * 86400);
  S.rtBeforeChannelJoin(ctx(a), log, nk, { channelJoin: { target: kid, type: 2, persistence: true, hidden: false } });
  assert.equal(nk.channelMessagesList(kidDm, 100, true).messages.length, 1, "nothing to clear where nothing is kept");
});
