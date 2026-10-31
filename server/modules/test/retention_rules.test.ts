// M4 Task 8b, agent G (spec §17.2; docs/store/data-retention-and-security.md): how long the server
// keeps things. Accounts without a sign-in for 13 months go, DM history after 30 days, reports 12
// months after a person reviewed them; the clean-up runs at most once a day (an hour later when a run
// had more to do than one run takes). Dates are calendar months in UTC.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const R = server().RetentionRules;
const DAY = 24 * 60 * 60 * 1000;
const HOUR = 60 * 60 * 1000;

function utc(text: string): number {
  return Date.parse(text);
}

test("months back in UTC keep the day and time; a day the month lacks becomes its last day", () => {
  assert.equal(R.monthsBefore(utc("2027-10-24T12:00:00.000Z"), 13), utc("2026-09-24T12:00:00.000Z"));
  assert.equal(R.monthsBefore(utc("2027-01-15T00:00:00.000Z"), 1), utc("2026-12-15T00:00:00.000Z"), "over a year's end");
  assert.equal(R.monthsBefore(utc("2027-03-31T08:30:00.000Z"), 13), utc("2026-02-28T08:30:00.000Z"), "no 31 February");
  assert.equal(R.monthsBefore(utc("2029-03-31T08:30:00.000Z"), 13), utc("2028-02-29T08:30:00.000Z"), "a leap year");
  assert.equal(R.monthsBefore(utc("2027-05-31T23:59:59.999Z"), 12), utc("2026-05-31T23:59:59.999Z"));
  assert.equal(R.monthsBefore(utc("2027-07-31T10:00:00.000Z"), 1), utc("2027-06-30T10:00:00.000Z"));
});

test("an account is inactive after 13 months without a sign-in, not a moment before", () => {
  const now = utc("2027-10-24T12:00:00.000Z");
  const cutoff = utc("2026-09-24T12:00:00.000Z");
  assert.equal(R.INACTIVE_MONTHS, 13);
  assert.equal(R.inactiveCutoffMs(now), cutoff);
  assert.equal(R.isInactive(cutoff - 1, now), true, "13 months and a millisecond");
  assert.equal(R.isInactive(cutoff, now), false, "exactly 13 months: not yet");
  assert.equal(R.isInactive(now - 30 * DAY, now), false);
  assert.equal(R.isInactive(0, now), true, "never signed in since the record began: as old as it gets");
});

test("DM history: messages from before the last 30 days go (the same 30 days as the game and agent E's purge)", () => {
  const now = utc("2026-10-24T12:00:00.000Z");
  assert.equal(R.DM_DAYS, 30);
  assert.equal(R.messageCutoffMs(now), now - 30 * DAY);
  assert.equal(R.messageCutoffMs(now), now - server().ChatRules.HISTORY_DAYS * DAY);
});

test("storage times read as milliseconds: Nakama's seconds, milliseconds or a time text", () => {
  assert.equal(R.timeMs(1_790_000_000), 1_790_000_000_000, "seconds");
  assert.equal(R.timeMs(1_790_000_000_123), 1_790_000_000_123, "already milliseconds");
  assert.equal(R.timeMs("2026-09-24T12:00:00Z"), utc("2026-09-24T12:00:00Z"));
  assert.equal(R.timeMs("soon"), 0);
  assert.equal(R.timeMs(undefined), 0);
});

test("a report counts as reviewed when its status says so; the time is its own or the console's edit", () => {
  const edited = utc("2026-10-01T09:00:00Z");
  assert.equal(R.reviewedMs({ status: "new" }, edited), null, "not reviewed yet: kept");
  assert.equal(R.reviewedMs({ status: "reviewed" }, edited), edited, "the console's save is the review");
  assert.equal(R.reviewedMs({ status: " Reviewed " }, edited), edited, "whatever the case and spaces");
  assert.equal(R.reviewedMs({ status: "reviewed", reviewed_ms: 123456 }, edited), 123456, "a stamped time wins");
  assert.equal(R.reviewedMs({ status: "reviewed", reviewed_ms: "yesterday" }, edited), edited);
  assert.equal(R.reviewedMs({ status: "reviewed" }, 0), null, "no time to count from: kept (never guessed away)");
  assert.equal(R.reviewedMs("junk", edited), null);
});

test("a reviewed report is deleted 12 months after the review, not before", () => {
  const reviewed = utc("2026-10-01T09:00:00Z");
  assert.equal(R.REPORT_MONTHS, 12);
  assert.equal(R.reportExpired(reviewed, utc("2027-10-01T08:59:59.999Z")), false);
  assert.equal(R.reportExpired(reviewed, utc("2027-10-01T09:00:00Z")), true, "12 months to the millisecond");
  assert.equal(R.reportExpired(utc("2026-02-28T09:00:00Z"), utc("2027-02-28T09:00:00Z")), true);
});

test("what the clean-up does with a report: keep, stamp the review time once, or delete", () => {
  const edited = utc("2026-10-01T09:00:00Z");
  const soon = utc("2026-10-02T09:00:00Z");
  const later = utc("2027-10-02T09:00:00Z");
  assert.deepEqual(R.reportStep({ status: "new", created_ms: 1 }, edited, later), { action: "keep" },
    "a report nobody reviewed stays for the reviewer, however old");
  assert.deepEqual(R.reportStep({ status: "reviewed" }, edited, soon), { action: "stamp", reviewed_ms: edited },
    "the review time is written into the report the first time, so later writes can't move it");
  assert.deepEqual(R.reportStep({ status: "reviewed", reviewed_ms: edited }, soon, soon), { action: "keep" });
  assert.deepEqual(R.reportStep({ status: "reviewed", reviewed_ms: edited }, soon, later), { action: "delete" });
  assert.deepEqual(R.reportStep({ status: "reviewed" }, edited, later), { action: "delete" },
    "found only after 12 months: deleted at once");
});

test("the once-a-day guard: due with no record, 24 h after the last run, an hour after a run with more to do", () => {
  const now = utc("2026-09-24T12:00:00Z");
  assert.equal(R.due(null, now), true, "never ran");
  const ran = R.ranAt(now, { more: false });
  assert.equal(ran.last_run_ms, now);
  assert.equal(R.due(ran, now + DAY - 1), false);
  assert.equal(R.due(ran, now + DAY), true, "24 hours later");
  const busy = R.ranAt(now, { more: true });
  assert.equal(R.due(busy, now + HOUR - 1), false);
  assert.equal(R.due(busy, now + HOUR), true, "a backlog goes on an hour later");
  assert.equal(R.due(ran, now - HOUR), false, "a clock a little behind waits");
  assert.equal(R.due(ran, now - DAY - 1), true, "a clock set back more than a day never blocks the job");
});

test("the guard's stored record is read safely", () => {
  assert.equal(R.jobFrom(undefined), null);
  assert.equal(R.jobFrom({ last_run_ms: "x" }), null);
  assert.deepEqual(R.jobFrom({ last_run_ms: 5, more: true, result: { accounts: 1 } }), { last_run_ms: 5, more: true });
  assert.deepEqual(R.jobFrom({ last_run_ms: 5 }), { last_run_ms: 5, more: false });
});

test("one run does a bounded amount of work", () => {
  assert.ok(R.ACCOUNTS_PER_RUN >= 10 && R.ACCOUNTS_PER_RUN <= 100);
  assert.ok(R.MESSAGES_PER_RUN >= 1000);
  assert.ok(R.REPORTS_PER_RUN >= 100);
});
