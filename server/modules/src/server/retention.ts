// The retention clean-up (spec §17.2; M4 Task 8b, agent G; docs/store/data-retention-and-security.md).
// Nakama's runtime has no cron, so it runs from a sign-in: every device sign-in records the player's
// last sign-in (activity/signed_in, server only) and, at most once a day (RetentionRules.due; an hour
// later when a run stopped at a limit), runs the clean-up. The owner can run it at once with
// retention_run (the runtime HTTP key or the console's API Explorer; never a game). One run:
//   1. accounts without a sign-in for 13 months: deleted as delete_account does (Deletion.run);
//   2. chat messages older than 30 days (E removes them only when a DM opens; this gets the rest);
//   3. what a deletion in the console leaves behind (its Delete button skips Deletion.run): invites
//      the deleted player sent, DMs with them, and their name on reports they made;
//   4. reports: the review time written in once, deleted 12 months after it;
//   5. report windows (the ids a player reported) an hour after their last report (0.2.10).

namespace Retention {
  export const JOB_KEY = "retention"; // Store.ACTIVITY, owned by the system user
  export const SIGNED_IN_KEY = "signed_in"; // Store.ACTIVITY, one per player
  // The last sign-in of every account (its activity record, else its last account change), oldest
  // first, before the cutoff ($1 ms), at most $2.
  export const SQL_INACTIVE = "SELECT id, last_ms FROM (SELECT u.id::text AS id, COALESCE(" +
    "CASE WHEN jsonb_typeof(s.value -> 'at_ms') = 'number' THEN (s.value ->> 'at_ms')::numeric::bigint END, " +
    "(EXTRACT(EPOCH FROM u.update_time) * 1000)::bigint) AS last_ms FROM users u LEFT JOIN storage s " +
    "ON s.collection = 'activity' AND s.key = 'signed_in' AND s.user_id = u.id " +
    "WHERE u.id <> '00000000-0000-0000-0000-000000000000'::uuid) AS seen " +
    "WHERE last_ms < $1::bigint ORDER BY last_ms LIMIT $2::bigint";
  export const SQL_OLD_MESSAGES = "DELETE FROM message WHERE id IN (SELECT id FROM message WHERE create_time < " +
    "to_timestamp($1::bigint / 1000.0) LIMIT $2::bigint)";
  export const SQL_ORPHAN_NOTES = "DELETE FROM notification n WHERE n.sender_id <> '00000000-0000-0000-0000-000000000000'::uuid " +
    "AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = n.sender_id)";
  // M4 Task 10 review: notifications older than RetentionRules.NOTE_DAYS (nothing reads them later).
  export const SQL_OLD_NOTES = "DELETE FROM notification WHERE id IN (SELECT id FROM notification WHERE create_time < " +
    "to_timestamp($1::bigint / 1000.0) LIMIT $2::bigint)";
  // M4 Task 10 review F: report windows (the ids a player reported) whose last report is an hour old.
  export const SQL_OLD_REPORT_WINDOWS = "DELETE FROM storage WHERE collection = 'limits' AND key = 'report' AND user_id IN (" +
    "SELECT user_id FROM storage WHERE collection = 'limits' AND key = 'report' AND update_time < " +
    "to_timestamp($1::bigint / 1000.0) LIMIT $2::bigint)";
  export const SQL_ORPHAN_DMS = "DELETE FROM message m WHERE m.stream_mode = 4 AND (" +
    "NOT EXISTS (SELECT 1 FROM users u WHERE u.id = m.stream_subject) OR " +
    "NOT EXISTS (SELECT 1 FROM users u WHERE u.id = m.stream_descriptor))";
  // Owner #105: password windows (the pair and the name's 24-hour count) not written for two days (none counts after a
  // day), and the device tombstones (`account/removed_device:*`, system user) past 13 months — the third review's N7.
  export const SQL_OLD_PASSWORD_WINDOWS = "DELETE FROM storage WHERE collection = 'limits' AND key LIKE 'password_%' AND " +
    "update_time < to_timestamp($1::bigint / 1000.0)";
  export const SQL_OLD_REMOVED_DEVICES = "DELETE FROM storage WHERE collection = 'account' AND key LIKE 'removed_device:%' AND " +
    "update_time < to_timestamp($1::bigint / 1000.0)";
  const PAGE = 100;
  const MAX_PAGES = 200;

  export function run(nk: nkruntime.Nakama, logger: nkruntime.Logger, nowMs: number): Util.Json {
    const result: Util.Json = {
      accounts: 0, messages: 0, orphan_notifications: 0, orphan_messages: 0,
      reports_deleted: 0, reports_stamped: 0, reports_anonymised: 0, more: false,
    };
    const rows = nk.sqlQuery(SQL_INACTIVE, [RetentionRules.inactiveCutoffMs(nowMs), RetentionRules.ACCOUNTS_PER_RUN + 1]);
    for (let i = 0; i < rows.length && i < RetentionRules.ACCOUNTS_PER_RUN; i++) {
      if (RetentionRules.isInactive(Number(rows[i].last_ms), nowMs)) {
        Deletion.run(nk, logger, String(rows[i].id), "13 months without a sign-in");
        result.accounts++;
      }
    }
    result.more = rows.length > RetentionRules.ACCOUNTS_PER_RUN;
    result.messages = nk.sqlExec(SQL_OLD_MESSAGES, [RetentionRules.messageCutoffMs(nowMs), RetentionRules.MESSAGES_PER_RUN]).rowsAffected;
    if (result.messages >= RetentionRules.MESSAGES_PER_RUN) {
      result.more = true;
    }
    result.old_notifications = nk.sqlExec(SQL_OLD_NOTES, [RetentionRules.noteCutoffMs(nowMs), RetentionRules.NOTES_PER_RUN]).rowsAffected;
    if (result.old_notifications >= RetentionRules.NOTES_PER_RUN) {
      result.more = true;
    }
    result.report_windows = nk.sqlExec(SQL_OLD_REPORT_WINDOWS,
      [RetentionRules.reportWindowCutoffMs(nowMs), RetentionRules.REPORT_WINDOWS_PER_RUN]).rowsAffected;
    if (result.report_windows >= RetentionRules.REPORT_WINDOWS_PER_RUN) {
      result.more = true;
    }
    result.password_windows = nk.sqlExec(SQL_OLD_PASSWORD_WINDOWS, [nowMs - 2 * 24 * 60 * 60 * 1000]).rowsAffected;
    result.removed_devices = nk.sqlExec(SQL_OLD_REMOVED_DEVICES, [RetentionRules.inactiveCutoffMs(nowMs)]).rowsAffected;
    result.orphan_notifications = nk.sqlExec(SQL_ORPHAN_NOTES, []).rowsAffected;
    result.orphan_messages = nk.sqlExec(SQL_ORPHAN_DMS, []).rowsAffected;
    if (reports(nk, nowMs, result)) {
      result.more = true;
    }
    Gifts.retention(nk, nowMs, result); // M4 I: gifts, bottles and stickers after 60 days, and orphans
    logger.info("retention clean-up: %s", JSON.stringify(result));
    return result;
  }

  // Every report once; at most REPORTS_PER_RUN changes. True when it stopped at that limit.
  function reports(nk: nkruntime.Nakama, nowMs: number, result: Util.Json): boolean {
    let changes = 0;
    let cursor: string | undefined = undefined;
    for (let page = 0; page < MAX_PAGES; page++) {
      const list = nk.storageList(Store.SYSTEM_USER, Store.REPORTS, PAGE, cursor);
      const objects = list && list.objects ? list.objects : [];
      const living = existing(nk, objects);
      for (let i = 0; i < objects.length; i++) {
        if (changes >= RetentionRules.REPORTS_PER_RUN) {
          return true;
        }
        const o = objects[i];
        const value: Util.Json = Util.isObject(o.value) ? o.value : {};
        const step = RetentionRules.reportStep(value, RetentionRules.timeMs(o.updateTime), nowMs);
        if (step.action === "delete") {
          nk.storageDelete([{ collection: Store.REPORTS, key: o.key, userId: Store.SYSTEM_USER, version: o.version }]);
          result.reports_deleted++;
          changes++;
        } else if (typeof value.reporter_id === "string" && value.reporter_id !== "" && !living[value.reporter_id]) {
          if (Deletion.anonymiseReport(nk, o.key, "")) {
            result.reports_anonymised++;
            changes++;
          }
        } else if (step.action === "stamp") {
          const stamped: Util.Json = {};
          for (const k in value) {
            if (Util.has(value, k)) {
              stamped[k] = value[k];
            }
          }
          stamped.reviewed_ms = step.reviewed_ms;
          Store.write(nk, Store.REPORTS, o.key, Store.SYSTEM_USER, stamped, false, o.version);
          result.reports_stamped++;
          changes++;
        }
      }
      if (!list || !list.cursor) {
        return false;
      }
      cursor = list.cursor;
    }
    return false;
  }

  // Which reporters of these reports still have an account.
  function existing(nk: nkruntime.Nakama, objects: nkruntime.StorageObject[]): { [id: string]: boolean } {
    const ids: string[] = [];
    for (let i = 0; i < objects.length; i++) {
      const id = Util.isObject(objects[i].value) ? objects[i].value.reporter_id : "";
      if (Social.isUuid(id) && ids.indexOf(id) < 0) {
        ids.push(id);
      }
    }
    const out: { [id: string]: boolean } = {};
    const users = ids.length > 0 ? nk.usersGetId(ids) : [];
    for (let i = 0; i < users.length; i++) {
      out[users[i].userId] = true;
    }
    return out;
  }

  // The day's run, if it is due and no other sign-in claimed it first (the guard is written by
  // version before the run). A failing run is logged and recorded, never retried at every sign-in.
  export function maybeRun(nk: nkruntime.Nakama, logger: nkruntime.Logger, nowMs: number): Util.Json | null {
    const found = Store.read(nk, Store.ACTIVITY, JOB_KEY, Store.SYSTEM_USER);
    if (!RetentionRules.due(RetentionRules.jobFrom(found ? found.value : undefined), nowMs)) {
      return null;
    }
    try {
      Store.write(nk, Store.ACTIVITY, JOB_KEY, Store.SYSTEM_USER, RetentionRules.ranAt(nowMs, { running: true }), false,
        found ? found.version : "*");
    } catch (e) {
      if (Social.isVersionClash(e)) {
        return null;
      }
      throw e;
    }
    let result: Util.Json;
    try {
      result = run(nk, logger, nowMs);
    } catch (e) {
      logger.error("retention clean-up failed: %s", Server.errorText(e));
      result = { error: Server.errorText(e) };
    }
    Store.write(nk, Store.ACTIVITY, JOB_KEY, Store.SYSTEM_USER, RetentionRules.ranAt(nowMs, result), false);
    return result;
  }
}

// After every device sign-in: the player's last sign-in (the 13-month rule), then the day's
// clean-up if it is due. Never stops the sign-in.
function afterAuthenticateDevice(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    _data: nkruntime.Session, _request: nkruntime.AuthenticateDeviceRequest): void {
  if (!ctx.userId) {
    return;
  }
  const now = Server.nowMs();
  try {
    Store.write(nk, Store.ACTIVITY, Retention.SIGNED_IN_KEY, ctx.userId, { at_ms: now }, false);
    Retention.maybeRun(nk, logger, now);
  } catch (e) {
    logger.error("after sign-in for %s: %s", ctx.userId, Server.errorText(e));
  }
}

// retention_run {}: the clean-up now, for the owner (the runtime HTTP key or the console's API
// Explorer with no user id); a game gets not_allowed. {"ok", "accounts", "messages",
// "orphan_notifications", "orphan_messages", "reports_deleted", "reports_stamped", "reports_anonymised",
// "report_windows" (0.2.10), "more"} (more: call it again). It counts as the day's run.
function rpcRetentionRun(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpcOrAdmin(ctx, logger, "retention_run", payload, function (callerId: string): Util.Json {
    if (callerId !== "") {
      return Server.fail("not_allowed");
    }
    const now = Server.nowMs();
    const result = Retention.run(nk, logger, now);
    Store.write(nk, Store.ACTIVITY, Retention.JOB_KEY, Store.SYSTEM_USER, RetentionRules.ranAt(now, result), false);
    const out: Util.Json = { ok: true };
    for (const k in result) {
      if (Util.has(result, k)) {
        out[k] = result[k];
      }
    }
    return out;
  });
}
