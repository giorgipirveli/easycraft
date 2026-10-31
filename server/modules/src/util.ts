// Small helpers for the rules and the Nakama glue: text as the game counts it, and safe reading of
// JSON payloads. No Nakama calls here, so the Node tests use them as they are.
//
// Everything is ES5 (Nakama's JavaScript runtime): no regular-expression "u" flag, no for...of over
// strings, no Array.from on strings.

namespace Util {
  // The Unicode code points of a string: a surrogate pair is one character, as Godot counts them.
  export function codePoints(text: string): number[] {
    const out: number[] = [];
    for (let i = 0; i < text.length; i++) {
      const c = text.charCodeAt(i);
      if (c >= 0xd800 && c <= 0xdbff && i + 1 < text.length) {
        const d = text.charCodeAt(i + 1);
        if (d >= 0xdc00 && d <= 0xdfff) {
          out.push((c - 0xd800) * 0x400 + (d - 0xdc00) + 0x10000);
          i++;
          continue;
        }
      }
      out.push(c);
    }
    return out;
  }

  export function codePointLength(text: string): number {
    return codePoints(text).length;
  }

  export function fromCodePoint(c: number): string {
    if (c < 0x10000) {
      return String.fromCharCode(c);
    }
    const v = c - 0x10000;
    return String.fromCharCode(0xd800 + (v >> 10), 0xdc00 + (v & 0x3ff));
  }

  // The characters of a string, a surrogate pair as one (Godot's `for ch in text`).
  export function chars(text: string): string[] {
    const cps = codePoints(text);
    const out: string[] = [];
    for (let i = 0; i < cps.length; i++) {
      out.push(fromCodePoint(cps[i]));
    }
    return out;
  }

  // The UTF-8 byte length of a string (bcrypt reads at most 72 bytes; a password is checked against this).
  export function utf8Bytes(text: string): number {
    const cps = codePoints(text);
    let n = 0;
    for (let i = 0; i < cps.length; i++) {
      const c = cps[i];
      n += c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
    }
    return n;
  }

  // Godot's String.substr(0, count): the first count characters.
  export function firstChars(text: string, count: number): string {
    return chars(text).slice(0, count).join("");
  }

  // Godot's String.strip_edges(): characters with codes 0-32 go from both ends.
  export function stripEdges(text: string): string {
    let begin = 0;
    let end = text.length;
    while (begin < end && text.charCodeAt(begin) <= 32) {
      begin++;
    }
    while (end > begin && text.charCodeAt(end - 1) <= 32) {
      end--;
    }
    return text.substring(begin, end);
  }

  export function replaceAll(text: string, find: string, replacement: string): string {
    return find === "" ? text : text.split(find).join(replacement);
  }

  export type Json = { [key: string]: any };

  export function isObject(value: unknown): value is Json {
    return typeof value === "object" && value !== null && Object.prototype.toString.call(value) === "[object Object]";
  }

  // An RPC's JSON payload as an object; "" (no payload) is {}. Anything else (a list, a number,
  // broken JSON, more than MAX_PAYLOAD characters) is null.
  export const MAX_PAYLOAD = 4096;

  export function parsePayload(payload: string): Json | null {
    if (payload === undefined || payload === null || payload === "") {
      return {};
    }
    if (typeof payload !== "string" || payload.length > MAX_PAYLOAD) {
      return null;
    }
    try {
      const data = JSON.parse(payload);
      return isObject(data) ? data : null;
    } catch (_e) {
      return null;
    }
  }

  export function isInt(value: unknown): value is number {
    return typeof value === "number" && isFinite(value) && Math.floor(value) === value;
  }

  export function has(object: Json, key: string): boolean {
    return Object.prototype.hasOwnProperty.call(object, key);
  }

  export function clamp(value: number, low: number, high: number): number {
    return Math.max(low, Math.min(high, value));
  }

  // A production server: its module env has EASYCRAFT_ENV=production (server/deploy/ always sets it).
  // Developer switches (the fake consent provider, open developer matches) never work there.
  export function isProduction(env: unknown): boolean {
    return isObject(env) && typeof env.EASYCRAFT_ENV === "string" &&
      env.EASYCRAFT_ENV.replace(/^\s+|\s+$/g, "").toLowerCase() === "production";
  }
}
