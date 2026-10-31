// Owner #79, #81, #82, #85 (spec §25.2; the world game plan §2, §2b): the invite program on the server (module
// 0.2.16). invite_info (my code, my friends and my tree, the month's rewards, my groups, news), invite_use (a
// friend's, class or family code: a new account only, never your own, never twice; the welcome gift at once),
// invite_progress (the friend learned: the inviter, the friend and the inviter's inviter are paid once, within the
// monthly caps; a first Moon landing's bonus), invite_group (a grown-up makes a class or family code). Account
// deletion removes everything that names the player.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const R = S.ReferralRules;
const TEEN = A.defaults("13_plus");
const DAY = 24 * 60 * 60 * 1000;

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

// A claimed player whose account is `ageDays` old.
function player(name: string, ageDays = 1, claimed = true): string {
  const id = nk.addUser(name, claimed ? TEEN : {});
  nk.users.get(id)!.createTime = Math.floor((now - ageDays * DAY) / 1000);
  return id;
}

function call(fn: string, userId: string, payload: object = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, JSON.stringify(payload)));
}

const info = (id: string, payload: object = {}) => call("rpcInviteInfo", id, payload);
const use = (id: string, code: string) => call("rpcInviteUse", id, { code });
const progress = (id: string, payload: object) => call("rpcInviteProgress", id, payload);
const group = (id: string, payload: object) => call("rpcInviteGroup", id, payload);
const gold = (id: string) => nk.users.get(id)!.wallet.survivor_gold || 0;

test("a claimed player gets an invite code at once; the server keeps it, the game can't read or write it", () => {
  const alex = player("Alex_7");
  const r = info(alex);
  assert.equal(r.ok, true);
  assert.match(r.code, /^[A-Z]+-[A-Z]+-\d{2}$/);
  assert.equal(info(alex).code, r.code, "the same code every time");
  const key = R.canonical(r.code);
  const o = nk.object("invite_codes", key, SYSTEM_USER)!;
  assert.deepEqual(o.value, { user_id: alex, kind: "friend", code: r.code, made_ms: now });
  assert.equal(o.permissionRead, 0);
  assert.equal(o.permissionWrite, 0);
  const mine = nk.object("referrals", "me", alex)!;
  assert.equal(mine.permissionRead, 0, "the game reads it through invite_info only");
  assert.equal(mine.permissionWrite, 0);
  assert.deepEqual(r.rewards, { welcome: R.WELCOME_GOLD, inviter: R.INVITER_GOLD, learner: R.LEARNER_GOLD, tree: R.TREE_GOLD,
    landed: R.LANDED_GOLD });
  assert.deepEqual(r.caps, R.CAPS);
});

test("a player who never claimed a name gets no code yet (the friend would see no name)", () => {
  const fresh = player("x9Rq2w", 0, false);
  const r = info(fresh);
  assert.equal(r.ok, true);
  assert.equal(r.claimed, false);
  assert.equal(r.code, "");
  assert.equal(nk.storageList(SYSTEM_USER, "invite_codes").objects.length, 0);
});

test("a new friend uses the code: the welcome gift at once; the inviter hears who joined, with no gold yet", () => {
  const alex = player("Alex_7");
  const code = info(alex).code;
  const sam = player("Sam_22");
  const r = use(sam, code.toLowerCase().replace(/-/g, " "));
  assert.deepEqual(r, { ok: true, kind: "friend", guide: "Alex_7", welcome: R.WELCOME_GOLD, gold: R.WELCOME_GOLD, group: "" });
  assert.equal(gold(sam), R.WELCOME_GOLD);
  assert.equal(gold(alex), 0, "a bare sign-up pays the inviter nothing");
  const ledger = nk.ledger.find((e) => e.userId === sam)!;
  assert.deepEqual(ledger.metadata, { source: "invite", reason: "welcome" });
  const a = info(alex, { seen: true });
  assert.deepEqual(a.friends.map((f: any) => [f.name, f.learned]), [["Sam_22", false]]);
  assert.deepEqual(a.news.map((n: any) => [n.what, n.name, n.gold]), [["joined", "Sam_22", 0]]);
  assert.equal(info(alex).news.length, 0, "seen news go");
  const note = nk.notifications.find((n) => n.userId === alex)!;
  assert.equal(note.code, 108);
  assert.deepEqual(note.content, { what: "joined", gold: 0 });
  assert.equal(note.persistent, false, "the news list is the mailbox; the note only nudges an open game");
  const s = info(sam);
  assert.equal(s.guide, "Alex_7");
  assert.equal(s.can_use_code, false, "once");
});

test("never your own code, never twice, never for an old account; unknown codes lock typing for a while", () => {
  const alex = player("Alex_7");
  const code = info(alex).code;
  assert.deepEqual(use(alex, code), { ok: false, error: "own_code" });
  const sam = player("Sam_22");
  assert.equal(use(sam, code).ok, true);
  assert.deepEqual(use(sam, code), { ok: false, error: "already_used" });
  const bo = player("Bo_9");
  assert.deepEqual(use(sam, info(bo).code), { ok: false, error: "already_used" }, "one inviter, forever");
  const old = player("Old_1", 60);
  assert.deepEqual(use(old, code), { ok: false, error: "not_new" });
  assert.equal(info(old).can_use_code, false);
  assert.equal(info(player("Kim_3", 3)).can_use_code, true);
  const tryer = player("Try_4");
  for (let i = 0; i < R.WRONG_MAX - 1; i++) {
    assert.deepEqual(use(tryer, "RED-FOX-" + (10 + i)), { ok: false, error: "unknown" });
  }
  assert.deepEqual(use(tryer, "bad code!"), { ok: false, error: "unknown" });
  const locked = use(tryer, code);
  assert.equal(locked.error, "locked", "even a right code waits");
  assert.ok(locked.wait > 0 && locked.wait <= R.WRONG_WINDOW_MS / 1000);
  now += R.WRONG_WINDOW_MS + 1000;
  assert.equal(use(tryer, code).ok, true);
});

test("the friend learns: the inviter's gold, the friend's gold (both win), the tree's small gift; once", () => {
  const gran = player("Gran_5");
  const alex = player("Alex_7");
  assert.equal(use(alex, info(gran).code).ok, true, "Gran brought Alex");
  const sam = player("Sam_22");
  assert.equal(use(sam, info(alex).code).ok, true, "Alex brought Sam");
  const before = { alex: gold(alex), sam: gold(sam), gran: gold(gran) };
  const r = progress(sam, { event: "learned", unit: "g4.maths.big_numbers" });
  assert.deepEqual(r, { ok: true, counted: true, gold: R.LEARNER_GOLD, guide: "Alex_7" });
  assert.equal(gold(alex) - before.alex, R.INVITER_GOLD);
  assert.equal(gold(sam) - before.sam, R.LEARNER_GOLD);
  assert.equal(gold(gran) - before.gran, R.TREE_GOLD, "the Explorer Tree: a friend's friend learned");
  assert.deepEqual(progress(sam, { event: "learned" }), { ok: true, counted: false, gold: 0, guide: "Alex_7" }, "once");
  assert.equal(gold(alex) - before.alex, R.INVITER_GOLD);
  const a = info(alex, { seen: true });
  assert.deepEqual(a.news.map((n: any) => [n.what, n.name, n.gold]), [["joined", "Sam_22", 0], ["learned", "Sam_22", R.INVITER_GOLD]]);
  assert.deepEqual(a.counts, { friends: 1, learned: 1, tree_friends: 0, tree_learned: 0, children_learning: 1 });
  assert.equal(a.earned, R.INVITER_GOLD);
  const g = info(gran);
  assert.deepEqual(g.counts, { friends: 1, learned: 0, tree_friends: 1, tree_learned: 1, children_learning: 1 });
  assert.deepEqual(g.news.map((n: any) => [n.what, n.name, n.gold]), [["joined", "Alex_7", 0], ["tree", "", R.TREE_GOLD]],
    "a friend's friend is never named");
  assert.deepEqual(g.friends, [{ name: "Alex_7", learned: false, joined_ms: now, friends: 1, learned_friends: 1 }]);
  const notes = nk.notifications.filter((n) => n.code === 108 && n.userId === alex).map((n) => n.content);
  assert.deepEqual(notes, [{ what: "joined", gold: 0 }, { what: "learned", gold: R.INVITER_GOLD }]);
});

test("a player nobody brought learns: nothing is paid, and the class still counts it", () => {
  const solo = player("Solo_1");
  assert.deepEqual(progress(solo, { event: "learned" }), { ok: true, counted: true, gold: 0, guide: "" });
  assert.deepEqual(progress(solo, { event: "nap" }), { ok: false, error: "bad_request" });
});

test("the monthly cap: past it the friend still counts in the tree, without gold; 30 days later gold again", () => {
  const alex = player("Alex_7");
  const code = info(alex).code;
  const friends: string[] = [];
  for (let i = 0; i < R.CAPS.learned + 2; i++) {
    const f = player("Pal_" + i);
    assert.equal(use(f, code).ok, true);
    friends.push(f);
  }
  for (const f of friends.slice(0, R.CAPS.learned + 1)) {
    progress(f, { event: "learned" });
  }
  assert.equal(gold(alex), R.CAPS.learned * R.INVITER_GOLD);
  const a = info(alex);
  assert.equal(a.counts.learned, R.CAPS.learned + 1, "counted all the same");
  assert.equal(a.month.learned, R.CAPS.learned);
  assert.equal(a.news[a.news.length - 1].gold, 0);
  now += R.WINDOW_MS + 1;
  progress(friends[friends.length - 1], { event: "learned" });
  assert.equal(gold(alex), (R.CAPS.learned + 1) * R.INVITER_GOLD);
});

test("a friend's first Moon landing: the inviter's bonus once (the missions call it later)", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  use(sam, info(alex).code);
  assert.deepEqual(progress(sam, { event: "landed", where: "moon" }), { ok: true, counted: true, gold: 0, guide: "Alex_7" });
  assert.equal(gold(alex), R.LANDED_GOLD);
  assert.equal(progress(sam, { event: "landed", where: "moon" }).counted, false);
  assert.equal(progress(sam, { event: "landed", where: "mars" }).counted, false, "the Moon's bonus only");
  assert.equal(gold(alex), R.LANDED_GOLD);
  assert.deepEqual(info(alex).news.map((n: any) => n.what), ["joined", "landed"]);
});

test("the inviter's list is kept small, and never a stranger's name: unclaimed friends show without one", () => {
  const alex = player("Alex_7");
  const code = info(alex).code;
  const anon = player("x9Rq2w", 0, false);
  assert.equal(use(anon, code).ok, true, "a code works before the name is claimed");
  assert.deepEqual(info(alex).friends.map((f: any) => f.name), [""]);
  assert.equal(use(player("Bo_9"), code).ok, true);
  assert.deepEqual(info(alex).friends.map((f: any) => f.name), ["Bo_9", ""], "newest first");
});

test("a grown-up makes a class code; the class joins it, old accounts too; its maker's referrals are the new ones", () => {
  const teacher = player("MsLee_1", 90);
  const made = group(teacher, { action: "make", kind: "class" });
  assert.equal(made.ok, true);
  assert.match(made.code, /^CLASS-[A-Z]+-[A-Z]+-\d{2}$/);
  assert.deepEqual(group(teacher, { action: "make", kind: "class" }), made, "one class code; asking again shows it");
  const kid = player("Kid_1", 1);
  const r = use(kid, made.code);
  assert.deepEqual(r, { ok: true, kind: "class", guide: "MsLee_1", welcome: R.WELCOME_GOLD, gold: R.WELCOME_GOLD, group: "class" });
  const old = player("Old_1", 200);
  assert.deepEqual(use(old, made.code), { ok: true, kind: "class", guide: "MsLee_1", welcome: 0, gold: 0, group: "class" },
    "an older account joins the class, no welcome gift");
  assert.deepEqual(use(old, made.code), { ok: false, error: "already_in" });
  progress(kid, { event: "learned" });
  const t = info(teacher);
  assert.deepEqual(t.groups.class, { code: made.code, members: 3, learned: 1, mine: true });
  assert.equal(t.made.class, made.code);
  assert.deepEqual(info(old).groups.class, { code: made.code, members: 3, learned: 1, mine: false });
  assert.equal(t.counts.friends, 1, "only the new account is the teacher's referral");
  assert.deepEqual(group(kid, { action: "leave", kind: "class" }), { ok: true });
  assert.equal(info(teacher).groups.class.members, 2);
});

test("a family code: at most GROUP_MAX.family; nobody else's group is reachable by name", () => {
  const mum = player("Mum_1", 100);
  const code = group(mum, { action: "make", kind: "family" }).code;
  assert.match(code, /^FAMILY-/);
  for (let i = 1; i < R.GROUP_MAX.family; i++) {
    assert.equal(use(player("Fam_" + i), code).ok, true);
  }
  assert.deepEqual(use(player("Late_1"), code), { ok: false, error: "group_full" });
  assert.deepEqual(group(mum, { action: "make", kind: "crew" }), { ok: false, error: "bad_request" });
  assert.deepEqual(group(player("x9Rq2w", 0, false), { action: "make", kind: "family" }), { ok: false, error: "not_claimed" });
});

test("a grown-up removes the class: its code stops working and the members' pages forget it", () => {
  const teacher = player("MsLee_1", 90);
  const code = group(teacher, { action: "make", kind: "class" }).code;
  const kid = player("Kid_1");
  use(kid, code);
  assert.deepEqual(group(teacher, { action: "remove", kind: "class" }), { ok: true });
  assert.deepEqual(use(player("Kid_2"), code), { ok: false, error: "unknown" });
  assert.equal(info(kid).groups.class, undefined);
  assert.equal(info(teacher).made.class, undefined);
});

test("the world's count of children brought by children (no names)", () => {
  const alex = player("Alex_7");
  const sam = player("Sam_22");
  use(sam, info(alex).code);
  progress(sam, { event: "learned" });
  assert.deepEqual(info(alex).world, { joined: 1, learned: 1 });
});

test("deleting an account removes everything about it: codes, groups, the inviter's list, the friends' links", () => {
  const gran = player("Gran_5");
  const alex = player("Alex_7");
  use(alex, info(gran).code);
  const alexCode = info(alex).code;
  const fam = group(alex, { action: "make", kind: "family" }).code;
  const sam = player("Sam_22");
  use(sam, alexCode);
  const cls = group(gran, { action: "make", kind: "class" }).code;
  use(alex, cls);
  progress(alex, { event: "learned" });
  const confirm = call("rpcDeleteAccount", alex, {}).confirm;
  const r = call("rpcDeleteAccount", alex, { confirm });
  assert.equal(r.deleted, true);
  assert.equal(nk.object("invite_codes", R.canonical(alexCode), SYSTEM_USER), undefined, "the code is gone");
  assert.equal(nk.object("invite_codes", R.canonical(fam), SYSTEM_USER), undefined, "the family code it made");
  assert.equal(nk.object("invite_groups", R.canonical(fam), SYSTEM_USER), undefined);
  assert.deepEqual(nk.object("invite_groups", R.canonical(cls), SYSTEM_USER)!.value.members, [gran], "out of the class");
  assert.equal(nk.object("referrals", "me", alex), undefined);
  const g = info(gran);
  assert.deepEqual(g.friends, [], "out of its inviter's list");
  assert.ok(g.news.every((n: any) => n.name !== "Alex_7"));
  assert.equal(nk.object("referrals", "me", sam)!.value.by.user_id, "", "the friend no longer names it");
  assert.equal(info(sam).guide, "");
  assert.equal(info(sam).can_use_code, false, "a code used is used, even when its maker left");
  assert.equal(r.invites, 6, "its two codes, the family it made, its place in the class, its inviter's list, its friend's link");
});

test("a code whose maker was removed in the console (no clean-up) is unknown", () => {
  const alex = player("Alex_7");
  const code = info(alex).code;
  nk.accountDeleteId(alex, true); // the console's Delete skips Deletion.run
  assert.deepEqual(use(player("Sam_22"), code), { ok: false, error: "unknown" });
});

test("the module is 0.2.20", () => {
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
