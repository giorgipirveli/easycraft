// The "better together" half of the world game plan on the server (owner #81, #82, #85; module 0.2.18):
// social_info, social_learned (learning together: friendship days, study buddies, the crew's week), social_moment and
// social_cheer (proud moments friends cheer with kind words), present_send / present_open / present_thank (presents a
// friend opens in the game; one can wait on the invite code for a new friend), study_buddy, crew. Friends only
// (Nakama's mutual friends), server-only storage, nothing personal, deletion forgets everything that names a player.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const R = S.SocialRules;
const TEEN = A.defaults("13_plus");
const DAY = 24 * 60 * 60 * 1000;

let nk: FakeNakama;
let log: FakeLogger;
let now = Date.UTC(2026, 8, 30, 9, 0, 0); // a Wednesday

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = Date.UTC(2026, 8, 30, 9, 0, 0);
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function player(name: string, meta: object = TEEN): string {
  const id = nk.addUser(name, meta);
  nk.users.get(id)!.createTime = Math.floor((now - DAY) / 1000);
  return id;
}

function friends(...ids: string[]): void {
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      nk.befriend(ids[i], ids[j]);
    }
  }
}

function call(fn: string, userId: string, payload: object = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, JSON.stringify(payload)));
}

const info = (id: string, payload: object = {}) => call("rpcSocialInfo", id, payload);
const learned = (id: string, payload: object = {}) => call("rpcSocialLearned", id, payload);
const moment = (id: string, kind: string, place: string) => call("rpcSocialMoment", id, { kind, place });
const cheer = (id: string, momentId: string, c: string) => call("rpcSocialCheer", id, { moment_id: momentId, cheer: c });
const send = (id: string, payload: object) => call("rpcPresentSend", id, payload);
const open = (id: string, presentId: string) => call("rpcPresentOpen", id, { id: presentId });
const thank = (id: string, presentId: string) => call("rpcPresentThank", id, { id: presentId });
const buddy = (id: string, action: string, other: string) => call("rpcStudyBuddy", id, { action, user_id: other });
const crew = (id: string, payload: object) => call("rpcCrew", id, payload);
const gold = (id: string) => nk.users.get(id)!.wallet.survivor_gold || 0;
const friendOf = (r: any, name: string) => r.friends.find((f: any) => f.name === name);

test("social_info: a player with no friends yet gets empty lists and the rules' numbers; storage is the server's", () => {
  const alex = player("Alex_7");
  const r = info(alex);
  assert.equal(r.ok, true);
  assert.deepEqual(r.friends, []);
  assert.deepEqual(r.feed, []);
  assert.deepEqual(r.presents, []);
  assert.deepEqual(r.news, []);
  assert.equal(r.crew, null);
  assert.equal(r.allowed, true);
  assert.equal(r.rules.sends_per_day, R.SENDS_PER_DAY);
  assert.deepEqual(r.rules.levels, [1, 7, 30]);
  assert.equal(r.rules.crew_max, 6);
  assert.equal(r.sends_left, R.SENDS_PER_DAY);
  learned(alex);
  const o = nk.object("together", "me", alex)!;
  assert.equal(o.permissionRead, 0, "the game reads it through social_info only");
  assert.equal(o.permissionWrite, 0);
});

test("learning together: friends who both learn on a day get a day together; levels open shared rewards", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  const bo = player("Bo_9");
  friends(alex, sam);
  assert.equal(learned(alex, { unit: "g4.maths.fractions" }).together, 0, "Sam hasn't learned today yet");
  const r = learned(sam);
  assert.equal(r.ok, true);
  assert.equal(r.together, 1);
  learned(bo); // not a friend: nothing
  const a = info(alex);
  assert.equal(a.friends.length, 1);
  assert.deepEqual(friendOf(a, "Sam_22"), { id: sam, name: "Sam_22", days: 1, level: 1, today: true,
    buddy: { state: "", days: 0, row: [0, 0, 0, 0, 0, 0, 0] } });
  assert.deepEqual(a.news.map((n: any) => [n.what, n.name, n.kind]), [["level", "Sam_22", "good"]]);
  assert.equal(friendOf(info(sam), "Alex_7").days, 1);
  learned(sam);
  learned(alex);
  assert.equal(friendOf(info(alex), "Alex_7"), undefined);
  assert.equal(friendOf(info(alex), "Sam_22").days, 1, "one day counts once");
  // Six more days together: Great friends (a two-seat rover to share).
  for (let d = 1; d <= 6; d++) {
    now += DAY;
    learned(alex);
    learned(sam);
  }
  const later = info(alex, { seen: true });
  assert.equal(friendOf(later, "Sam_22").days, 7);
  assert.equal(friendOf(later, "Sam_22").level, 2);
  assert.deepEqual(later.news.filter((n: any) => n.what === "level").map((n: any) => n.kind), ["good", "great"]);
  assert.deepEqual(info(alex).news, [], "seen news go");
  // A long break loses nothing.
  now += 60 * DAY;
  assert.equal(friendOf(info(alex), "Sam_22").days, 7);
  assert.equal(friendOf(info(alex), "Sam_22").today, false);
});

test("presents: to a friend, one a day each and a few a day in all; opened once; THANK YOU pays the sender", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  const bo = player("Bo_9");
  friends(alex, sam);
  assert.deepEqual(send(alex, { user_id: bo, kind: "seeds" }), { ok: false, error: "not_friends" });
  assert.deepEqual(send(alex, { user_id: sam, kind: "cake" }), { ok: false, error: "bad_request" });
  const s = send(alex, { user_id: sam, kind: "seeds" });
  assert.equal(s.ok, true);
  assert.equal(s.sends_left, R.SENDS_PER_DAY - 1);
  assert.deepEqual(send(alex, { user_id: sam, kind: "buddy_egg" }), { ok: false, error: "sent_today" });
  const note = nk.notifications.find((n: any) => n.userId === sam)!;
  assert.equal(note.code, 109);
  assert.equal(note.persistent, false);
  const inbox = info(sam);
  assert.equal(inbox.presents.length, 1);
  const p = inbox.presents[0];
  assert.deepEqual({ name: p.name, kind: p.kind, opened: p.opened, thanked: p.thanked, link: p.link },
    { name: "Alex_7", kind: "seeds", opened: false, thanked: false, link: false });
  assert.deepEqual(inbox.news.map((n: any) => [n.what, n.name, n.kind]), [["present", "Alex_7", "seeds"], ["level", "Alex_7", "good"]]);
  assert.equal(friendOf(inbox, "Alex_7").days, 1, "a present is a day together");
  assert.deepEqual(open(sam, p.id), { ok: true, kind: "seeds", name: "Alex_7", link: false });
  assert.deepEqual(open(sam, p.id), { ok: false, error: "not_found" }, "opened once: never twice");
  assert.deepEqual(thank(alex, p.id), { ok: false, error: "not_found" }, "only its receiver thanks");
  const before = gold(alex);
  assert.deepEqual(thank(sam, p.id), { ok: true, gold: R.THANK_GOLD });
  assert.equal(gold(alex), before + R.THANK_GOLD);
  assert.deepEqual(nk.ledger.at(-1)!.metadata, { source: "together", reason: "thanks" });
  assert.deepEqual(thank(sam, p.id), { ok: false, error: "already_thanked" });
  const news = info(alex).news.filter((n: any) => n.what === "thanks");
  assert.deepEqual(news.map((n: any) => [n.name, n.kind, n.gold]), [["Sam_22", "seeds", R.THANK_GOLD]]);
  assert.equal(info(sam).presents[0].thanked, true);
});

test("presents: a few a day in all, an inbox that fills, thank-you gold a few times a day", () => {
  const alex = player("Alex_7");
  const pals: string[] = [];
  for (let i = 0; i < R.SENDS_PER_DAY + 1; i++) {
    pals.push(player("Pal_" + i));
    friends(alex, pals[i]);
  }
  for (let i = 0; i < R.SENDS_PER_DAY; i++) {
    assert.equal(send(alex, { user_id: pals[i], kind: "map_piece" }).ok, true);
  }
  assert.deepEqual(send(alex, { user_id: pals[R.SENDS_PER_DAY], kind: "map_piece" }), { ok: false, error: "too_many_today" });
  assert.equal(info(alex).sends_left, 0);
  now += DAY;
  assert.equal(info(alex).sends_left, R.SENDS_PER_DAY, "a new day");
  // Thank-you gold: THANKS_PER_DAY times a day for one sender.
  const giver = player("Giver_1");
  const takers: string[] = [];
  for (let i = 0; i < R.THANKS_PER_DAY + 1; i++) {
    takers.push(player("Taker_" + i));
    friends(giver, takers[i]);
  }
  for (let d = 0; d < 2; d++) {
    for (let i = 0; i < 3; i++) {
      send(giver, { user_id: takers[i], kind: "seeds" });
    }
    now += DAY;
  }
  let paid = 0;
  for (let i = 0; i < 3; i++) {
    for (const p of info(takers[i]).presents) {
      open(takers[i], p.id);
      paid += thank(takers[i], p.id).gold;
    }
  }
  assert.equal(paid, R.THANK_GOLD * R.THANKS_PER_DAY, "six thank-yous in one day: five pay");
  // An inbox holds INBOX_MAX presents not opened yet.
  const full = player("Full_1");
  for (let i = 0; i < R.INBOX_MAX + 1; i++) {
    const s = player("Sender_" + i);
    friends(s, full);
    const r = send(s, { user_id: full, kind: "seeds" });
    assert.equal(r.ok, i < R.INBOX_MAX, "present " + i);
    if (i === R.INBOX_MAX) {
      assert.equal(r.error, "inbox_full");
    }
  }
});

test("a present waits on the invite code: the next new friend who joins with it opens it", () => {
  const alex = player("Alex_7");
  const code = call("rpcInviteInfo", alex).code;
  assert.equal(send(alex, { link: true, kind: "buddy_egg" }).waiting, 1);
  send(alex, { link: true, kind: "seeds" });
  send(alex, { link: true, kind: "seeds" });
  assert.deepEqual(send(alex, { link: true, kind: "seeds" }), { ok: false, error: "too_many_waiting" });
  assert.deepEqual(info(alex).link_gifts, ["buddy_egg", "seeds", "seeds"]);
  const sam = player("Sam_22");
  assert.equal(call("rpcInviteUse", sam, { code }).ok, true);
  const mine = info(sam);
  assert.equal(mine.presents.length, 1);
  assert.deepEqual({ name: mine.presents[0].name, kind: mine.presents[0].kind, link: mine.presents[0].link },
    { name: "Alex_7", kind: "buddy_egg", link: true });
  assert.deepEqual(info(alex).link_gifts, ["seeds", "seeds"]);
  assert.deepEqual(info(alex).news.filter((n: any) => n.what === "link_present").map((n: any) => [n.name, n.kind]),
    [["Sam_22", "buddy_egg"]]);
  // Not Nakama friends: the guide's present still opens and its thank-you still reaches the guide.
  assert.equal(open(sam, mine.presents[0].id).ok, true);
  assert.deepEqual(thank(sam, mine.presents[0].id), { ok: true, gold: R.THANK_GOLD });
});

test("proud moments go to friends' feeds; a friend cheers with kind words only, once", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  const bo = player("Bo_9");
  friends(alex, sam);
  assert.deepEqual(moment(alex, "landed", "Moon Base!"), { ok: false, error: "bad_request" });
  assert.deepEqual(moment(alex, "landed", "moon"), { ok: true, told: 1 });
  assert.deepEqual(info(bo).feed, [], "only friends hear");
  const feed = info(sam).feed;
  assert.deepEqual(feed.map((m: any) => [m.name, m.kind, m.place]), [["Alex_7", "landed", "moon"]]);
  assert.deepEqual(cheer(sam, feed[0].id, "You rock"), { ok: false, error: "bad_request" }, "never typed words");
  assert.deepEqual(cheer(bo, feed[0].id, "amazing"), { ok: false, error: "not_found" });
  assert.deepEqual(cheer(sam, feed[0].id, "amazing"), { ok: true });
  assert.deepEqual(cheer(sam, feed[0].id, "amazing"), { ok: false, error: "not_found" }, "once");
  assert.deepEqual(info(sam).feed, []);
  const news = info(alex).news.filter((n: any) => n.what === "cheer");
  assert.deepEqual(news.map((n: any) => [n.name, n.kind, n.place]), [["Sam_22", "amazing", "landed:moon"]]);
  assert.equal(friendOf(info(alex), "Sam_22").days, 1, "a cheer is a day together");
  for (let i = 1; i < R.MOMENTS_PER_DAY; i++) {
    assert.equal(moment(alex, "unit", "g4.maths.u" + i).ok, true);
  }
  assert.deepEqual(moment(alex, "unit", "g4.maths.more"), { ok: false, error: "too_many_today" });
});

test("a friend who is no longer a friend: their moments and presents go away unopened", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  friends(alex, sam);
  moment(alex, "landed", "moon");
  send(alex, { user_id: sam, kind: "seeds" });
  nk.friendsDelete(alex, "Alex_7", [sam]);
  const r = info(sam);
  assert.deepEqual(r.feed, []);
  assert.deepEqual(r.presents, []);
  assert.deepEqual(r.friends, []);
});

test("study buddies: ask, yes, a shared day when both learn, a week row with rest days, stop", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  const bo = player("Bo_9");
  friends(alex, sam);
  assert.deepEqual(buddy(alex, "ask", bo), { ok: false, error: "not_friends" });
  assert.deepEqual(buddy(alex, "ask", sam), { ok: true, state: "asked" });
  assert.equal(friendOf(info(sam), "Alex_7").buddy.state, "asking");
  assert.deepEqual(info(sam).news.map((n: any) => [n.what, n.name]), [["buddy_ask", "Alex_7"]]);
  assert.deepEqual(buddy(sam, "yes", alex), { ok: true, state: "yes" });
  assert.equal(friendOf(info(alex), "Sam_22").buddy.state, "yes");
  assert.deepEqual(info(alex).news.map((n: any) => [n.what, n.name]), [["buddy_yes", "Sam_22"]]);
  learned(alex);
  learned(sam);
  now += DAY;
  learned(alex); // Sam rests
  now += DAY;
  learned(alex);
  learned(sam);
  const b = friendOf(info(alex), "Sam_22").buddy;
  assert.equal(b.days, 2);
  assert.deepEqual(b.row, [0, 0, 0, 0, 2, 1, 2]);
  assert.deepEqual(buddy(alex, "stop", sam), { ok: true, state: "" });
  // Saying yes on a day both learned already: that day is their first shared one.
  const kai = player("Kai_4");
  friends(alex, kai);
  learned(kai);
  buddy(kai, "ask", alex);
  buddy(alex, "yes", kai);
  assert.deepEqual(friendOf(info(alex), "Kai_4").buddy, { state: "yes", days: 1, row: [0, 0, 0, 0, 0, 0, 2] });
  buddy(alex, "stop", kai);
  assert.equal(friendOf(info(sam), "Alex_7").buddy.state, "");
  // At most BUDDIES_MAX.
  const pals = [player("P_1"), player("P_2"), player("P_3"), player("P_4")];
  for (const p of pals) {
    friends(alex, p);
  }
  for (let i = 0; i < R.BUDDIES_MAX; i++) {
    assert.equal(buddy(alex, "ask", pals[i]).ok, true);
  }
  assert.deepEqual(buddy(alex, "ask", pals[3]), { ok: false, error: "too_many_buddies" });
  // Asking someone who asked you makes you buddies.
  const kim = player("Kim_5");
  friends(kim, sam);
  buddy(kim, "ask", sam);
  assert.deepEqual(buddy(sam, "ask", kim), { ok: true, state: "yes" });
});

test("crews: a kid-safe name, a badge, friends invited, 2-6 members, a weekly goal, what each learned this week", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  const bo = player("Bo_9");
  friends(alex, sam);
  assert.deepEqual(crew(alex, { action: "make", adjective: "Rude", noun: "Comets", badge: "rocket" }), { ok: false, error: "bad_name" });
  assert.deepEqual(crew(alex, { action: "make", adjective: "Brave", noun: "Comets", badge: "skull" }), { ok: false, error: "bad_badge" });
  const made = crew(alex, { action: "make", adjective: "Brave", noun: "Comets", badge: "rocket",
    look: { hair: "curly", shirt: "orange", base: "girl" } });
  assert.equal(made.ok, true);
  assert.equal(made.crew.name, "Brave Comets");
  assert.equal(made.crew.badge, "rocket");
  assert.equal(made.crew.members.length, 1);
  assert.deepEqual(made.crew.members[0].look, { hair: "curly", shirt: "orange" }, "never the boy / girl choice");
  assert.deepEqual(made.crew.goal, { done: 0, target: R.CREW_GOAL_PER_MEMBER * 2 });
  assert.equal(nk.object("crews", made.crew.id, SYSTEM_USER)!.permissionRead, 0);
  assert.deepEqual(crew(alex, { action: "make", adjective: "Kind", noun: "Owls", badge: "owl" }), { ok: false, error: "in_a_crew" });
  assert.deepEqual(crew(alex, { action: "invite", user_id: bo }), { ok: false, error: "not_friends" });
  assert.deepEqual(crew(alex, { action: "invite", user_id: sam }), { ok: true });
  const invites = info(sam).crew_invites;
  assert.deepEqual(invites.map((v: any) => [v.name, v.badge, v.from]), [["Brave Comets", "rocket", "Alex_7"]]);
  assert.deepEqual(crew(bo, { action: "join", crew: made.crew.id }), { ok: false, error: "not_invited" });
  const joined = crew(sam, { action: "join", crew: made.crew.id, look: { hair: "short" } });
  assert.equal(joined.ok, true);
  assert.deepEqual(joined.crew.members.map((m: any) => [m.name, m.me]), [["Alex_7", false], ["Sam_22", true]]);
  assert.deepEqual(info(sam).crew_invites, []);
  assert.deepEqual(info(alex).news.filter((n: any) => n.what === "crew_join").map((n: any) => n.name), ["Sam_22"]);
  // The week: learning days and the units mastered, each member's own, and the goal (never a ranking).
  learned(alex, { unit: "g4.maths.fractions" });
  learned(sam, { unit: "g4.science.rocks" });
  now += DAY;
  learned(sam);
  const c = info(alex).crew;
  assert.deepEqual(c.members.map((m: any) => [m.name, m.week.days, m.week.units]),
    [["Alex_7", 1, ["g4.maths.fractions"]], ["Sam_22", 2, ["g4.science.rocks"]]]);
  assert.deepEqual(c.goal, { done: 3, target: R.CREW_GOAL_PER_MEMBER * 2 });
  now += 7 * DAY;
  assert.deepEqual(info(alex).crew.goal, { done: 0, target: R.CREW_GOAL_PER_MEMBER * 2 }, "a new week starts again");
  assert.deepEqual(crew(sam, { action: "leave" }), { ok: true });
  assert.equal(info(alex).crew.members.length, 1);
  assert.deepEqual(crew(alex, { action: "leave" }), { ok: true });
  assert.equal(nk.object("crews", made.crew.id, SYSTEM_USER), undefined, "the last one out: the crew goes");
  assert.equal(info(alex).crew, null);
});

test("crews: six at most; a friend already in a crew leaves it first", () => {
  const maker = player("Maker_1");
  const made = crew(maker, { action: "make", adjective: "Swift", noun: "Rockets", badge: "star" }).crew;
  const pals: string[] = [];
  for (let i = 0; i < 6; i++) {
    pals.push(player("Crew_" + i));
    friends(maker, pals[i]);
  }
  for (let i = 0; i < 5; i++) {
    assert.deepEqual(crew(maker, { action: "invite", user_id: pals[i] }), { ok: true });
    assert.equal(crew(pals[i], { action: "join", crew: made.id }).ok, true);
  }
  assert.deepEqual(crew(maker, { action: "invite", user_id: pals[5] }), { ok: false, error: "crew_full" });
  const other = player("Other_1");
  friends(other, pals[0]);
  const second = crew(other, { action: "make", adjective: "Wise", noun: "Owls", badge: "owl" }).crew;
  crew(other, { action: "invite", user_id: pals[0] });
  assert.deepEqual(crew(pals[0], { action: "join", crew: second.id }), { ok: false, error: "in_a_crew" });
  assert.deepEqual(crew(pals[0], { action: "decline", crew: second.id }), { ok: true });
  assert.deepEqual(info(pals[0]).crew_invites, []);
});

test("deleting an account forgets it everywhere: friendships, buddies, presents, moments, news and crews", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  friends(alex, sam);
  learned(alex);
  learned(sam);
  buddy(alex, "ask", sam);
  buddy(sam, "yes", alex);
  send(alex, { user_id: sam, kind: "seeds" });
  moment(alex, "landed", "moon");
  const c = crew(alex, { action: "make", adjective: "Happy", noun: "Otters", badge: "fox" }).crew;
  crew(alex, { action: "invite", user_id: sam });
  crew(sam, { action: "join", crew: c.id });
  const confirm = call("rpcDeleteAccount", alex, {}).confirm;
  const done = call("rpcDeleteAccount", alex, { confirm });
  assert.equal(done.ok, true);
  assert.ok(done.together >= 1, JSON.stringify(done));
  const record = nk.object("together", "me", sam)!.value;
  assert.deepEqual(Object.keys(record.friends), []);
  assert.deepEqual(Object.keys(record.buddies), []);
  assert.deepEqual(record.presents, []);
  assert.deepEqual(record.feed, []);
  assert.deepEqual(record.news.filter((n: any) => n.id === alex), []);
  const left = nk.object("crews", c.id, SYSTEM_USER)!.value;
  assert.deepEqual(left.members, [sam]);
  assert.equal(nk.object("together", "me", alex), undefined);
});

test("a player who may not be online: nothing social (no friends, no presents); learning still counts for later", () => {
  const kid = player("Kid_1", A.defaults("under_13"));
  const r = info(kid);
  assert.equal(r.allowed, false);
  assert.deepEqual(send(kid, { link: true, kind: "seeds" }), { ok: false, error: "not_allowed_online" });
  assert.deepEqual(moment(kid, "landed", "moon"), { ok: false, error: "not_allowed_online" });
  assert.equal(learned(kid).ok, true);
});

test("the module is 0.2.20", () => {
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
