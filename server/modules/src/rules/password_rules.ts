// Owner #105 (2026-10-15 23:14; spec §5.13 "As built (owner #99, #105)"): "when starting playing create a password. so
// when logging in another device you can use password and username again to login, but if you login another device you
// should logout automatically from old device". What a password may be, and the limits on trying one. The glue is
// src/server/passwords.ts; the server keeps only a slow salted hash (bcrypt).

namespace PasswordRules {
  export const MIN_LEN = 6;
  export const MAX_LEN = 64;
  // The brake, FROZEN after three rounds (the lead, 2026-10-16): exactly two windows, no network window, no growth and
  // no decay logic. Every wrong try is counted before the password is checked; a correct login clears ONLY its own pair
  // window and nothing else is ever released or decremented.
  //
  // 1) The PAIR window, per (target account x asking account): 5 wrong in 15 minutes, then a hard wait to the window's
  //    end. A stranger's tries are counted against the stranger's own asking account, never the child's, so a child's
  //    own device is never slowed by anyone else; a child's own repeated typos cost at most PAIR_WINDOW_MS (15 min).
  export const PAIR_MAX_WRONG = 5;
  export const PAIR_WINDOW_MS = 15 * 60 * 1000;
  // 2) The NAME window, per target account, counting ONLY tries from devices NOT known to that account: a 24-hour
  //    window from its first wrong try. Past NAME_SOFT_MAX wrong, each further try from an unknown device is allowed only once every
  //    NAME_WAIT_MS per name (one fixed wait for everyone; no growth, no decay). About 144 + NAME_SOFT_MAX guesses a
  //    day per name at most; the child's longest wait on a brand-new device is NAME_WAIT_MS (10 minutes).
  export const NAME_SOFT_MAX = 10;
  export const NAME_WINDOW_MS = 24 * 60 * 60 * 1000;
  export const NAME_WAIT_MS = 10 * 60 * 1000;
  // Known devices (still LINKED to the account right now) and the grown-up key path are never braked by either window.
  export const DAY_MS = 24 * 60 * 60 * 1000;
  // Straight runs (either way) of RUN_LEN or more are refused: 123456, abcdef, qwerty, any six on a keyboard row.
  export const RUN_LEN = 6;
  export const RUNS = ["0123456789", "1234567890", "abcdefghijklmnopqrstuvwxyz", "qwertyuiop", "asdfghjkl", "zxcvbnm"];
  // The account's devices hear of a new device's wrong try at most this often.
  export const NOTE_EVERY_MS = 60 * 60 * 1000;
  // An asking account must be at least this old: a brand-new one asking at once is a throwaway's pattern (the game makes
  // its asking account when LOG IN opens, so a child typing name and password rarely waits).
  export const ASKER_MIN_AGE_MS = 30 * 1000;
  export const KNOWN_MAX = 20; // devices remembered per account
  // Wrong old passwords (or keys) when changing it or deleting the account, on the account.
  export const CHANGE_MAX_WRONG = 5;
  export const CHANGE_WINDOW_MS = 15 * 60 * 1000;
  // The commonest passwords (lower case), never allowed; plus one character again and again.
  export const COMMON = ["123456", "1234567", "12345678", "123456789", "1234567890", "0123456789", "654321", "987654321",
    "111111", "000000", "121212", "123123", "112233", "666666", "696969", "password", "password1", "password12",
    "password123", "passw0rd", "qwerty", "qwerty1", "qwerty123", "qwertyuiop", "asdfgh", "asdfghjkl", "zxcvbn",
    "zxcvbnm", "abc123", "abcdef", "abcdefg", "abcd1234", "iloveyou", "letmein", "welcome", "monkey", "dragon",
    "football", "baseball", "soccer", "princess", "sunshine", "superman", "batman", "pokemon", "starwars", "secret",
    "hello123", "admin", "admin123", "trustno1", "freedom", "master", "shadow", "michael", "ashley", "jessica",
    "charlie", "computer", "internet", "easycraft", "easycraft1", "gamer123", "player1",
    // the examples the game has ever shown, so a child who copies one is told to pick their own (the second review)
    "moon7tiger", "moontiger", "moontiger7", "moon7tigre", "sea4lantern", "river5stone"];
  // bcrypt reads at most 72 bytes; a password over that is refused with clear words (not silently truncated).
  export const MAX_BYTES = 72;

  // "" when `text` may be the password of the account named `username`; else why not: too_short, too_long, bad_chars
  // (a line break or another control character), is_name, too_common.
  export function problem(text: unknown, username: string): string {
    if (typeof text !== "string") {
      return "too_short";
    }
    const chars = Util.chars(text);
    if (chars.length < MIN_LEN) {
      return "too_short";
    }
    if (chars.length > MAX_LEN || Util.utf8Bytes(text) > MAX_BYTES) {
      return "too_long";
    }
    for (let i = 0; i < text.length; i++) {
      const c = text.charCodeAt(i);
      if (c < 32 || c === 127) {
        return "bad_chars";
      }
    }
    const lower = text.toLowerCase();
    const name = String(username || "").toLowerCase();
    const nameLetters = name.replace(/[^a-z]/g, "");
    if (lower === name || (nameLetters.length >= 3 && lower.replace(/[^a-z]/g, "") === nameLetters)) {
      return "is_name"; // the name, or the name with numbers and signs around it (anna12, Anna2024)
    }
    if (COMMON.indexOf(lower) >= 0) {
      return "too_common";
    }
    let same = true;
    for (let i = 1; i < chars.length && same; i++) {
      same = chars[i] === chars[0];
    }
    if (same) {
      return "too_common";
    }
    return hasRun(lower) ? "straight_run" : "";
  }

  // A straight run of RUN_LEN or more (either way) from RUNS anywhere in `lower`.
  export function hasRun(lower: string): boolean {
    for (let r = 0; r < RUNS.length; r++) {
      const runs = [RUNS[r], RUNS[r].split("").reverse().join("")];
      for (let k = 0; k < 2; k++) {
        for (let i = 0; i + RUN_LEN <= runs[k].length; i++) {
          if (lower.indexOf(runs[k].substring(i, i + RUN_LEN)) >= 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // One more try in a window, counted BEFORE anything is checked: {ok, next (to write by version), wait (seconds, when
  // not ok)}. The try that fills the window still goes on; the next one waits until the window is over.
  export function reserve(t: KeyRules.Tries, nowMs: number, max: number, windowMs: number): { ok: boolean; next: KeyRules.Tries; wait: number } {
    if (t.locked_until_ms > nowMs) {
      return { ok: false, next: t, wait: Math.ceil((t.locked_until_ms - nowMs) / 1000) };
    }
    const fresh = t.wrong === 0 || nowMs - t.since_ms >= windowMs;
    const wrong = fresh ? 0 : t.wrong;
    const since = fresh ? nowMs : t.since_ms;
    if (wrong >= max) {
      return { ok: false, next: t, wait: Math.max(1, Math.ceil((since + windowMs - nowMs) / 1000)) };
    }
    const next: KeyRules.Tries = { wrong: wrong + 1, since_ms: since, locked_until_ms: 0 };
    if (next.wrong >= max) {
      next.locked_until_ms = nowMs + windowMs;
    }
    return { ok: true, next: next, wait: 0 };
  }

  // A try taken back (the right password), only in the window it was counted in (`since`): one less, and no lock below
  // the maximum. Another window (it rolled over) gives nothing back: nothing beyond this request's own try.
  export function release(t: KeyRules.Tries, max: number, since: number): KeyRules.Tries | null {
    if (t.since_ms !== since || t.wrong <= 0) {
      return null;
    }
    const wrong = t.wrong - 1;
    return { wrong: wrong, since_ms: t.since_ms, locked_until_ms: wrong < max ? 0 : t.locked_until_ms };
  }

  // The NAME window (per target account), counting only wrong tries from devices NOT known to the account: a 24-hour
  // window from its first wrong try. Past NAME_SOFT_MAX wrong, each further unknown-device try passes only once every NAME_WAIT_MS (one
  // fixed wait for everyone; no growth, no decay — the frozen design). The 24-hour window is the only reset, so a short
  // pause can never bring the brake back to zero.
  export interface Name {
    wrong: number;
    since_ms: number; // the 24-hour window the count belongs to
    last_ms: number; // the last unknown-device try
  }

  export function nameFrom(value: unknown): Name {
    const v: Util.Json = Util.isObject(value) ? value : {};
    const int = (x: unknown) => (Util.isInt(x) && x > 0 ? x : 0);
    return { wrong: int(v.wrong), since_ms: int(v.since_ms), last_ms: int(v.last_ms) };
  }

  export function reserveName(t: Name, nowMs: number): { ok: boolean; next: Name; wait: number } {
    const fresh = t.wrong === 0 || nowMs - t.since_ms >= NAME_WINDOW_MS;
    const wrong = fresh ? 0 : t.wrong;
    const since = fresh ? nowMs : t.since_ms;
    if (wrong >= NAME_SOFT_MAX && t.last_ms > 0 && nowMs - t.last_ms < NAME_WAIT_MS) {
      return { ok: false, next: t, wait: Math.max(1, Math.ceil((t.last_ms + NAME_WAIT_MS - nowMs) / 1000)) };
    }
    return { ok: true, next: { wrong: wrong + 1, since_ms: since, last_ms: nowMs }, wait: 0 };
  }

  // A name as a counter's key ("?" for anything that can't be a name).
  export function nameKey(typed: unknown): string {
    const n = typeof typed === "string" ? UsernameRules.uniquenessKey(typed) : "";
    return /^[a-z0-9_]{1,16}$/.test(n) ? n : "?";
  }

  // What a typed password may be checked against at all (long texts are never hashed).
  export function checkable(text: unknown): text is string {
    return typeof text === "string" && text !== "" && text.length <= 4 * MAX_LEN;
  }
}
