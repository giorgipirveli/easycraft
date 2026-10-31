// Reports (spec §5.14, §17.3): a child reports another player with a reason code (no free text);
// the server stores it in "reports" for a person to review in the Nakama console. A reporter may
// send at most MAX_PER_HOUR, and the same player again within SAME_USER_GAP_MS is not stored twice.

namespace ReportRules {
  export const REASONS: string[] = ["mean_words", "bad_name", "bad_build", "personal_info", "scary", "cheating", "other"];
  export const MAX_PER_HOUR = 10;
  export const HOUR_MS = 60 * 60 * 1000;
  export const SAME_USER_GAP_MS = 10 * 60 * 1000;

  export interface Window {
    times: number[]; // when this reporter's last reports were stored
    last: { [userId: string]: number }; // when each player was last reported by them
  }

  export function reason(raw: unknown): string {
    return typeof raw === "string" && REASONS.indexOf(raw) >= 0 ? raw : "other";
  }

  export function emptyWindow(): Window {
    return { times: [], last: {} };
  }

  export function windowFrom(value: unknown): Window {
    const w = emptyWindow();
    if (!Util.isObject(value)) {
      return w;
    }
    if (value.times instanceof Array) {
      for (let i = 0; i < value.times.length; i++) {
        if (Util.isInt(value.times[i])) {
          w.times.push(value.times[i]);
        }
      }
    }
    if (Util.isObject(value.last)) {
      for (const k in value.last) {
        if (Util.has(value.last, k) && Util.isInt(value.last[k])) {
          w.last[k] = value.last[k];
        }
      }
    }
    return w;
  }

  // Whether to store a report about `reportedId` now; the reporter's window afterwards.
  export function accept(window: Window, reportedId: string, nowMs: number): { error?: string; store: boolean; window: Window } {
    const times: number[] = [];
    for (let i = 0; i < window.times.length; i++) {
      if (nowMs - window.times[i] < HOUR_MS) {
        times.push(window.times[i]);
      }
    }
    const last: { [userId: string]: number } = {};
    for (const k in window.last) {
      if (Util.has(window.last, k) && nowMs - window.last[k] < HOUR_MS) {
        last[k] = window.last[k];
      }
    }
    const kept: Window = { times: times, last: last };
    if (Util.has(last, reportedId) && nowMs - last[reportedId] < SAME_USER_GAP_MS) {
      return { store: false, window: kept };
    }
    if (times.length >= MAX_PER_HOUR) {
      return { error: "too_many", store: false, window: kept };
    }
    times.push(nowMs);
    last[reportedId] = nowMs;
    return { store: true, window: kept };
  }

  // --- A snapshot of the reported message (M4 Task 8b, agent G) ---
  // The server remembers each message it passed on for RECENT_SECONDS (team rooms and under-13 chats
  // keep no history); a kept DM is looked up in its history. Only without a server copy is the
  // message kept as the reporter's game showed it ("source": "reporter").

  export const RECENT_SECONDS = 60 * 60;
  export const SERVER = "server";
  export const REPORTER = "reporter";

  export interface Shown {
    text?: string;
    emote?: string;
    at_ms: number; // 0 = unknown
  }

  // The server's copy of a message: sender, channel, its content (JSON text) and when it went out.
  export interface Record {
    s: string;
    c: string;
    content: unknown;
    at: number;
  }

  // The message as the reporter's game showed it: exactly one text or emote (tidied and capped as
  // chat is), and when it was shown (never in the future). null if it is anything else.
  export function shownMessage(raw: unknown, nowMs: number): Shown | null {
    const content = Util.isObject(raw) ? ChatRules.parseContent(onlyContent(raw)) : null;
    if (content === null) {
      return null;
    }
    const at = Util.isInt((raw as Util.Json).at_ms) && (raw as Util.Json).at_ms > 0 && (raw as Util.Json).at_ms <= nowMs
      ? (raw as Util.Json).at_ms : 0;
    if (content.emote !== undefined) {
      return { emote: content.emote, at_ms: at };
    }
    const text = ChatRules.clean(content.text || "");
    return text === "" ? null : { text: text, at_ms: at };
  }

  function onlyContent(raw: Util.Json): Util.Json {
    const out: Util.Json = {};
    for (const k in raw) {
      if (Util.has(raw, k) && k !== "at_ms") {
        out[k] = raw[k];
      }
    }
    return out;
  }

  // What the report keeps: the server's copy, else the reporter's, else null.
  export function snapshot(record: Record | null, shown: Shown | null): Util.Json | null {
    const content = record !== null ? ChatRules.parseContent(record.content) : null;
    if (record !== null && content !== null) {
      return content.emote !== undefined
        ? { emote: content.emote, at_ms: record.at, source: SERVER }
        : { text: content.text, at_ms: record.at, source: SERVER };
    }
    if (shown === null) {
      return null;
    }
    const out: Util.Json = shown.emote !== undefined ? { emote: shown.emote } : { text: shown.text };
    out.at_ms = shown.at_ms;
    out.source = REPORTER;
    return out;
  }
}
