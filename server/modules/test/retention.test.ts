// M4 Task 8b, agent G: the retention clean-up on the server (spec §17.2, the written policy in
// docs/store/data-retention-and-security.md), against the fake Nakama. Nakama's runtime has no cron:
// the job runs from a sign-in at most once a day (every sign-in is recorded for the 13-month rule),
// or when the owner calls retention_run (the server's HTTP key or the console, never a game).
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const R = S.RetentionRules;
const TEEN = A.defaults("13_plus");
const DAY = 24 * 60 * 60 * 1000;
const HOUR = 60 * 60 * 1000;

let nk: FakeNakama;
let log: FakeLogger;
let now = Date.parse("2027-10-24T12:00:00Z");

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = Date.parse("2027-10-24T12:00:00Z");
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function runAsOwner(): any {
  return JSON.parse(S.rpcRetentionRun(ctx(""), log, nk, "{}"));
}

function signIn(userId: string): void {
  S.afterAuthenticateDevice(ctx(userId), log, nk, { created: false, token: "t" }, { account: { id: "dev" } });
}

function lastSeen(userId: string, at: number): void {
  nk.storageWrite([{ collection: "activity", key: "signed_in", userId, value: { at_ms: at }, permissionRead: 0, permissionWrite: 0 }]);
}

function report(key: string, value: object, updateMs: number): void {
  const saved = nk.clock;
  nk.clock = () => updateMs;
  nk.storageWrite([{ collection: "reports", key, userId: SYSTEM_USER, value, permissionRead: 0, permissionWrite: 0 }]);
  nk.clock = saved;
}

function reportValue(key: string): any {
  return nk.object("reports", key, SYSTEM_USER)?.value;
}

// --- Who may run it ---

test("retention_run: only the owner (no session), never a game", () => {
  const me = nk.addUser("Me_1", TEEN);
  assert.deepEqual(JSON.parse(S.rpcRetentionRun(ctx(me), log, nk, "{}")), { ok: false, error: "not_allowed" });
  const r = runAsOwner();
  assert.equal(r.ok, true, JSON.stringify(r));
  for (const k of ["accounts", "messages", "orphan_notifications", "orphan_messages", "reports_deleted", "reports_stamped",
    "reports_anonymised", "report_windows"]) {
    assert.equal(r[k], 0, k);
  }
  assert.equal(r.more, false);
  const guard = nk.object("activity", "retention", SYSTEM_USER)!;
  assert.equal(guard.value.last_run_ms, now, "an owner's run counts as today's");
  assert.equal(guard.permissionRead, 0);
});

// --- Accounts without a sign-in for 13 months ---

test("accounts without a sign-in for 13 months are deleted like delete_account; the rest stay", () => {
  const old = nk.addUser("Old_1", TEEN);
  const edge = nk.addUser("Edge_1", TEEN);
  const recent = nk.addUser("Recent_1", TEEN);
  const cutoff = R.inactiveCutoffMs(now);
  lastSeen(old, cutoff - 1);
  lastSeen(edge, cutoff);
  lastSeen(recent, now - 30 * DAY);
  nk.storageWrite([{ collection: "profiles", key: "profile", userId: old, value: { a: 1 }, permissionRead: 1, permissionWrite: 1 }]);
  nk.cascade = false;
  const r = runAsOwner();
  assert.equal(r.accounts, 1);
  assert.deepEqual(nk.deleted, [{ userId: old, recorded: true }]);
  assert.equal([...nk.storage.values()].some((o) => o.userId === old), false, "with everything of it");
  assert.ok(nk.users.has(edge), "exactly 13 months: not yet");
  assert.ok(nk.users.has(recent));
  assert.ok(log.lines.some((l) => l.includes("account deleted: " + old + " (13 months without a sign-in)")), log.lines.join("\n"));
});

test("an account that never signed in since the record began counts from its last account change", () => {
  nk.clock = () => R.inactiveCutoffMs(now) - DAY;
  const quiet = nk.addUser("Quiet_1", TEEN);
  nk.clock = () => now;
  const fresh = nk.addUser("Fresh_1", TEEN);
  assert.equal(runAsOwner().accounts, 1);
  assert.equal(nk.users.has(quiet), false);
  assert.equal(nk.users.has(fresh), true);
  const q = nk.sql.find((x) => x.query.includes("key = 'signed_in'"))!;
  assert.deepEqual(q.params, [R.inactiveCutoffMs(now), R.ACCOUNTS_PER_RUN + 1], "the rule's cutoff, one more than a run takes");
});

test("one run deletes at most ACCOUNTS_PER_RUN accounts and says there is more", () => {
  for (let i = 0; i < R.ACCOUNTS_PER_RUN + 3; i++) {
    lastSeen(nk.addUser("Gone" + i, TEEN), R.inactiveCutoffMs(now) - DAY);
  }
  const r = runAsOwner();
  assert.equal(r.accounts, R.ACCOUNTS_PER_RUN);
  assert.equal(r.more, true);
  assert.equal(runAsOwner().accounts, 3, "the rest next time");
});

// --- DM history older than 30 days ---

test("DM messages older than 30 days go even when nobody opens the DM again", () => {
  const a = nk.addUser("Ann_1", TEEN);
  const b = nk.addUser("Bob_1", TEEN);
  lastSeen(a, now);
  lastSeen(b, now);
  const dm = nk.channelIdBuild(a, b, 2);
  const cutoffSec = R.messageCutoffMs(now) / 1000;
  nk.addChannelMessage(dm, a, "Ann_1", cutoffSec - 1);
  nk.addChannelMessage(dm, b, "Bob_1", cutoffSec + 1);
  const r = runAsOwner();
  assert.equal(r.messages, 1);
  assert.deepEqual(nk.channelMessages.get(dm)!.map((m) => m.senderId), [b]);
  const q = nk.sql.find((x) => x.query.includes("FROM message WHERE create_time <"))!;
  assert.deepEqual(q.params, [R.messageCutoffMs(now), R.MESSAGES_PER_RUN]);
});

// --- M4 Task 10 review: notifications (invites, a grown-up's yes, Nakama's friend notes) ---
// The game never reads or removes them from the server (they only nudge an open game), and Nakama keeps
// a persistent one for good: the clean-up removes every notification older than 30 days.

test("notifications older than 30 days go (an invite lasts an hour; nothing reads them later)", () => {
  const a = nk.addUser("Ann_1", TEEN);
  const b = nk.addUser("Bob_1", TEEN);
  lastSeen(a, now);
  lastSeen(b, now);
  const saved = nk.clock;
  nk.clock = () => R.noteCutoffMs(now) - 1000;
  nk.notificationSend(b, "Ann invites you to play!", { match_id: "x" }, 101, a, true);
  nk.clock = () => R.noteCutoffMs(now) + 1000;
  nk.notificationSend(b, "Ann invites you to play!", { match_id: "y" }, 101, a, true);
  nk.clock = saved;
  const r = runAsOwner();
  assert.equal(r.old_notifications, 1, JSON.stringify(r));
  assert.deepEqual(nk.notifications.map((n) => n.content.match_id), ["y"]);
  const q = nk.sql.find((x) => x.query.includes("FROM notification WHERE create_time <"))!;
  assert.deepEqual(q.params, [R.noteCutoffMs(now), R.NOTES_PER_RUN]);
  assert.equal(R.noteCutoffMs(now), now - 30 * DAY);
});

// --- Left behind by a deletion in the console (its Delete button skips delete_account's clean-up) ---

test("things that name a player deleted in the console are cleaned: their invites, DMs, and their name on reports", () => {
  const gone = nk.addUser("Gone_1", TEEN);
  const pal = nk.addUser("Pal_1", TEEN);
  const bad = nk.addUser("Meanie", TEEN);
  lastSeen(pal, now);
  lastSeen(bad, now);
  lastSeen(gone, now);
  nk.notificationSend(pal, "Gone_1 invites you to play!", { from_username: "Gone_1" }, 101, gone, true);
  nk.notificationSend(pal, "A grown-up said yes!", { what: "consent" }, 103, null, true);
  const dm = nk.channelIdBuild(gone, pal, 2);
  nk.addChannelMessage(dm, pal, "Pal_1", now / 1000 - 60);
  report("1_" + gone, { reporter_id: gone, reporter_username: "Gone_1", reported_id: bad, reported_username: "Meanie",
    reason: "scary", created_ms: 1, status: "new" }, now - DAY);
  nk.accountDeleteId(gone, true); // the console's Delete (the database's cascade only)
  const r = runAsOwner();
  assert.equal(r.orphan_notifications, 1);
  assert.equal(r.orphan_messages, 1);
  assert.equal(r.reports_anonymised, 1);
  assert.deepEqual(nk.notifications.map((n) => n.code), [103]);
  assert.deepEqual(nk.channelMessages.get(dm), []);
  const reports = [...nk.storage.values()].filter((o) => o.collection === "reports");
  assert.equal(reports.length, 1);
  assert.equal(reports[0].value.reporter_id, "");
  assert.equal(reports[0].value.reporter_username, "");
  assert.equal(reports[0].value.reported_username, "Meanie", "what was reported stays");
});

// --- Reports: 12 months after a person reviewed them ---

test("reports: deleted 12 months after the review, the review time written in once, unreviewed ones kept", () => {
  const bad = nk.addUser("Meanie", TEEN);
  const pal = nk.addUser("Pal_1", TEEN);
  lastSeen(bad, now);
  lastSeen(pal, now);
  const base = { reporter_id: pal, reporter_username: "Pal_1", reported_id: bad, reported_username: "Meanie", reason: "scary" };
  const yearAgo = R.monthsBefore(now, 12);
  report("old", { ...base, created_ms: 1, status: "reviewed" }, yearAgo);
  report("stamped", { ...base, created_ms: 2, status: "reviewed", reviewed_ms: yearAgo + 1 }, now - DAY);
  report("fresh", { ...base, created_ms: 3, status: "reviewed" }, now - DAY);
  report("waiting", { ...base, created_ms: 4, status: "new" }, R.monthsBefore(now, 24));
  const r = runAsOwner();
  assert.equal(r.reports_deleted, 1);
  assert.equal(r.reports_stamped, 1);
  assert.equal(reportValue("old"), undefined, "reviewed 12 months ago");
  assert.equal(reportValue("stamped").reviewed_ms, yearAgo + 1, "a day short of 12 months: kept");
  assert.equal(reportValue("fresh").reviewed_ms, now - DAY, "the console's save is written in as the review time");
  assert.equal(reportValue("waiting").status, "new", "nobody reviewed it yet: kept for the reviewer");
  now += DAY + 1;
  assert.equal(runAsOwner().reports_deleted, 1, "the stamped one a day later");
  assert.equal(reportValue("stamped"), undefined);
});

// M4 Task 10 review F: a reporter's window (limits/report) named the players they reported until their next report.
test("report windows (the ids a player reported) go once their last report is an hour old; other windows stay", () => {
  const a = nk.addUser("Ann_1", TEEN);
  const b = nk.addUser("Bob_1", TEEN);
  lastSeen(a, now);
  lastSeen(b, now);
  const saved = nk.clock;
  nk.clock = () => now - HOUR - 1000;
  nk.storageWrite([{ collection: "limits", key: "report", userId: a, value: { times: [now - HOUR - 1000], last: { [b]: now - HOUR - 1000 } },
    permissionRead: 0, permissionWrite: 0 }]);
  nk.storageWrite([{ collection: "limits", key: "wallet_award", userId: a, value: { awards: [] }, permissionRead: 0, permissionWrite: 0 }]);
  nk.clock = () => now - 10 * 60 * 1000;
  nk.storageWrite([{ collection: "limits", key: "report", userId: b, value: { times: [now - 600_000], last: { [a]: now - 600_000 } },
    permissionRead: 0, permissionWrite: 0 }]);
  nk.clock = saved;
  const r = runAsOwner();
  assert.equal(r.report_windows, 1, JSON.stringify(r));
  assert.equal(nk.object("limits", "report", a), undefined, "an hour old: gone");
  assert.ok(nk.object("limits", "report", b), "ten minutes old: still counting");
  assert.ok(nk.object("limits", "wallet_award", a), "other windows name nobody");
  const q = nk.sql.find((x) => x.query.includes("key = 'report' AND update_time <"))!;
  assert.deepEqual(q.params, [now - HOUR, R.REPORT_WINDOWS_PER_RUN]);
});

// --- The sign-in hook: the last sign-in, and the job at most once a day ---

test("every sign-in is recorded (server only); the first one of a day runs the clean-up", () => {
  const me = nk.addUser("Me_1", TEEN);
  const old = nk.addUser("Old_1", TEEN);
  lastSeen(old, R.inactiveCutoffMs(now) - DAY);
  signIn(me);
  const seen = nk.object("activity", "signed_in", me)!;
  assert.deepEqual(seen.value, { at_ms: now });
  assert.equal(seen.permissionRead, 0, "the game can't read it");
  assert.equal(nk.users.has(old), false, "the day's clean-up ran");
  const guard = nk.object("activity", "retention", SYSTEM_USER)!;
  assert.equal(guard.value.last_run_ms, now);
  assert.equal(guard.value.result.accounts, 1);
  const again = nk.addUser("Old_2", TEEN);
  lastSeen(again, R.inactiveCutoffMs(now) - DAY);
  now += HOUR;
  signIn(me);
  assert.equal(nk.object("activity", "signed_in", me)!.value.at_ms, now, "recorded again");
  assert.ok(nk.users.has(again), "not twice in a day");
  now += 23 * HOUR;
  signIn(me);
  assert.equal(nk.users.has(again), false, "24 hours after the last run");
});

test("two sign-ins at the same moment: only one runs the clean-up", () => {
  const me = nk.addUser("Me_1", TEEN);
  const write = nk.storageWrite.bind(nk);
  let raced = false;
  nk.storageWrite = (writes: any[]) => {
    if (!raced && writes[0].key === "retention") {
      raced = true; // another sign-in claims the day's run between our read and our write
      write([{ collection: "activity", key: "retention", userId: SYSTEM_USER, value: { last_run_ms: now, more: false },
        permissionRead: 0, permissionWrite: 0 }]);
    }
    return write(writes);
  };
  signIn(me);
  assert.equal(nk.sql.some((x) => x.query.includes("key = 'signed_in'")), false, "this one stood back");
  assert.equal(nk.object("activity", "signed_in", me)!.value.at_ms, now);
});

test("a failing clean-up never stops a sign-in, and is not retried at every sign-in", () => {
  const me = nk.addUser("Me_1", TEEN);
  nk.sqlQuery = () => {
    throw new Error("database away");
  };
  assert.doesNotThrow(() => signIn(me));
  assert.ok(log.lines.some((l) => l.startsWith("ERROR retention clean-up failed")), log.lines.join("\n"));
  const guard = nk.object("activity", "retention", SYSTEM_USER)!;
  assert.equal(guard.value.last_run_ms, now);
  assert.match(guard.value.result.error, /database away/);
  assert.equal(R.due(R.jobFrom(guard.value), now + HOUR), false);
});

test("the module registers the sign-in hook, retention_run and delete_account", () => {
  const registered: string[] = [];
  const init: any = new Proxy({}, { get: (_t, name: string) => (id: any) => { registered.push(typeof id === "string" ? name + ":" + id : name); } });
  S.InitModule(ctx(""), log, nk, init);
  for (const want of ["registerRpc:delete_account", "registerRpc:retention_run", "registerAfterAuthenticateDevice",
    "registerBeforeDeleteAccount", "registerRtAfter:ChannelMessageSend"]) {
    assert.ok(registered.includes(want), want + " in " + registered.join(", "));
  }
});
