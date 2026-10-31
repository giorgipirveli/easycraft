// Deleting an online account (spec §5.14, §17.2; M4 Task 8b, agent G; Google Play's account-deletion
// rule and COPPA parents' rights). delete_account takes two calls: the first hands out a
// confirmation that lasts CONFIRM_MS, the second (with it) deletes. A report the player made is kept
// without who made it (it protects other children); a report about the player stays for the reviewer.

namespace DeletionRules {
  export const CONFIRM_MS = 10 * 60 * 1000;
  export const CONFIRM_KEY = "delete_account"; // in Store.LIMITS (server only)

  export interface Confirm {
    token: string;
    expires_ms: number;
  }

  export function newConfirm(token: string, nowMs: number): Confirm {
    return { token: token, expires_ms: nowMs + CONFIRM_MS };
  }

  export function confirmFrom(value: unknown): Confirm | null {
    if (!Util.isObject(value) || typeof value.token !== "string" || value.token === "" || !Util.isInt(value.expires_ms)) {
      return null;
    }
    return { token: value.token, expires_ms: value.expires_ms };
  }

  // "" when `given` confirms the deletion now, else the error code.
  export function check(stored: Confirm | null, given: unknown, nowMs: number): string {
    if (stored === null || nowMs >= stored.expires_ms) {
      return "confirm_expired";
    }
    return given === stored.token ? "" : "confirm_wrong";
  }

  export function madeBy(report: unknown, userId: string): boolean {
    return userId !== "" && Util.isObject(report) && report.reporter_id === userId;
  }

  // The report without who made it (a copy); what was reported, and the message, stay.
  export function anonymised(report: Util.Json, nowMs: number): Util.Json {
    const out: Util.Json = {};
    for (const k in report) {
      if (Util.has(report, k)) {
        out[k] = report[k];
      }
    }
    out.reporter_id = "";
    out.reporter_username = "";
    out.reporter_deleted_ms = nowMs;
    return out;
  }

  // A report's new key once its reporter is gone (the old key, "<ms>_<reporter id>", named them).
  export function anonymousKey(createdMs: number, uuid: string): string {
    return createdMs + "_deleted_" + uuid.replace(/-/g, "").toLowerCase().substring(0, 12);
  }
}
