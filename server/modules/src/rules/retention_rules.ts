// How long the server keeps things (spec §17.2; M4 Task 8b, agent G; the written policy is
// docs/store/data-retention-and-security.md): an account without a sign-in for 13 months is deleted,
// DM history after 30 days, a report 12 months after a person reviewed it. Nakama's runtime has no
// cron, so the clean-up runs at most once a day, from the first sign-in after a day has passed (or
// an hour later when one run had more to do than it takes on), or when the owner runs retention_run.
// Months are calendar months in UTC.

namespace RetentionRules {
  export const INACTIVE_MONTHS = 13;
  export const REPORT_MONTHS = 12;
  export const DM_DAYS = 30; // ChatRules.HISTORY_DAYS: the game shows 30 days, agent E purges on open
  export const DAY_MS = 24 * 60 * 60 * 1000;
  export const RUN_EVERY_MS = DAY_MS;
  export const AGAIN_MS = 60 * 60 * 1000; // a run that stopped at a limit goes on an hour later
  export const REVIEWED = "reviewed";
  // One run's work, so the sign-in that runs it stays quick (the rest waits for the next run).
  export const ACCOUNTS_PER_RUN = 50;
  export const MESSAGES_PER_RUN = 5000;
  export const REPORTS_PER_RUN = 1000;

  // `ms` moved back `months` calendar months in UTC, the same day and time; a day the month lacks
  // (31 February) becomes that month's last day.
  export function monthsBefore(ms: number, months: number): number {
    const d = new Date(ms);
    const total = d.getUTCFullYear() * 12 + d.getUTCMonth() - months;
    const year = Math.floor(total / 12);
    const month = total - year * 12;
    const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
    return Date.UTC(year, month, Math.min(d.getUTCDate(), lastDay), d.getUTCHours(), d.getUTCMinutes(),
      d.getUTCSeconds(), d.getUTCMilliseconds());
  }

  // A sign-in before this time is more than 13 months ago.
  export function inactiveCutoffMs(nowMs: number): number {
    return monthsBefore(nowMs, INACTIVE_MONTHS);
  }

  export function isInactive(lastSignInMs: number, nowMs: number): boolean {
    return lastSignInMs < inactiveCutoffMs(nowMs);
  }

  // Chat messages created before this time are removed.
  export function messageCutoffMs(nowMs: number): number {
    return nowMs - DM_DAYS * DAY_MS;
  }

  // M4 Task 10 review: notifications (invites, a grown-up's yes, Nakama's friend notes) only nudge an
  // open game; the game never reads or removes them on the server, so they go after NOTE_DAYS.
  export const NOTE_DAYS = 30;
  export const NOTES_PER_RUN = 5000;

  export function noteCutoffMs(nowMs: number): number {
    return nowMs - NOTE_DAYS * DAY_MS;
  }

  // M4 Task 10 review F: a reporter's window (limits/report) names the players they reported. It is
  // written only with a stored report, so one whose last write is an hour old holds nothing the
  // limit still counts (ReportRules.accept drops it all): it goes.
  export const REPORT_WINDOW_MS = 60 * 60 * 1000; // ReportRules.HOUR_MS
  export const REPORT_WINDOWS_PER_RUN = 5000;

  export function reportWindowCutoffMs(nowMs: number): number {
    return nowMs - REPORT_WINDOW_MS;
  }

  // A time from Nakama as milliseconds: its storage times are unix seconds, some answers milliseconds
  // or a time text. 0 when unreadable.
  export function timeMs(value: unknown): number {
    if (typeof value === "number" && isFinite(value) && value > 0) {
      return value > 1e11 ? Math.floor(value) : Math.floor(value * 1000);
    }
    if (typeof value === "string") {
      const ms = Date.parse(value);
      return isNaN(ms) ? 0 : ms;
    }
    return 0;
  }

  export function isReviewed(value: unknown): boolean {
    return Util.isObject(value) && typeof value.status === "string" &&
      Util.stripEdges(value.status).toLowerCase() === REVIEWED;
  }

  // When a person reviewed this report: its "reviewed_ms" (the clean-up writes it the first time it
  // sees the review), else the object's last write (the console's save that set "status": "reviewed").
  // null: not reviewed, or no time to count from (never guessed away).
  export function reviewedMs(value: unknown, updateTimeMs: number): number | null {
    if (!isReviewed(value)) {
      return null;
    }
    const v = value as Util.Json;
    if (Util.isInt(v.reviewed_ms) && v.reviewed_ms > 0) {
      return v.reviewed_ms;
    }
    return updateTimeMs > 0 ? updateTimeMs : null;
  }

  export function reportExpired(reviewedAtMs: number, nowMs: number): boolean {
    return reviewedAtMs <= monthsBefore(nowMs, REPORT_MONTHS);
  }

  // What the clean-up does with a report: keep it, write its review time into it, or delete it.
  export function reportStep(value: unknown, updateTimeMs: number, nowMs: number): { action: string; reviewed_ms?: number } {
    const at = reviewedMs(value, updateTimeMs);
    if (at === null) {
      return { action: "keep" };
    }
    if (reportExpired(at, nowMs)) {
      return { action: "delete" };
    }
    if (!Util.isInt((value as Util.Json).reviewed_ms)) {
      return { action: "stamp", reviewed_ms: at };
    }
    return { action: "keep" };
  }

  // --- The once-a-day guard (a system-owned record: Store.ACTIVITY / JOB_KEY) ---

  export interface Job {
    last_run_ms: number;
    more: boolean; // the last run stopped at a limit
  }

  export function jobFrom(value: unknown): Job | null {
    if (!Util.isObject(value) || !Util.isInt(value.last_run_ms)) {
      return null;
    }
    return { last_run_ms: value.last_run_ms, more: value.more === true };
  }

  export function due(job: Job | null, nowMs: number): boolean {
    if (job === null) {
      return true;
    }
    if (nowMs < job.last_run_ms - RUN_EVERY_MS) {
      return true; // the clock went back more than a day: never stuck waiting
    }
    return nowMs - job.last_run_ms >= (job.more ? AGAIN_MS : RUN_EVERY_MS);
  }

  // The guard's record after a run at nowMs (result: what the run did, kept for the console).
  export function ranAt(nowMs: number, result: Util.Json): Util.Json {
    return { last_run_ms: nowMs, more: result.more === true, result: result };
  }
}
