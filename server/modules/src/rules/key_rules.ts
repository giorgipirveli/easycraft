// The account's sign-in key (owner #67; spec §5.13, §17.1). A grown-up makes one on a device where the
// child plays (account_key "new"); on a new phone or browser the child's name and this key link that
// device to the same account (sign_in_with_key). No password and no e-mail: nothing personal. The key
// is 8 symbols of Crockford's base32 (40 random bits), shown as XXXX-XXXX and typed forgivingly; the
// server keeps only a slow salted hash (bcrypt). Wrong keys lock the name (whether or not it exists, so a lock says
// nothing about who plays) and the asking account.

namespace KeyRules {
  export const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"; // Crockford: no I, L, O, U
  export const LENGTH = 8;
  export const HEX_CHARS = 10; // 40 bits
  // A name: this many wrong keys in the window lock it for the window.
  export const NAME_MAX_WRONG = 5;
  export const NAME_WINDOW_MS = 15 * 60 * 1000;
  // An asking account, over every name it tries.
  export const CALLER_MAX_WRONG = 10;
  export const CALLER_WINDOW_MS = 60 * 60 * 1000;
  // New keys an account may make in a window (each stops the one before).
  export const NEW_MAX = 5;
  export const NEW_WINDOW_MS = 60 * 60 * 1000;
  // The third review's N7: at most this many device ids linked to one account; a link beyond it unlinks an older id.
  export const MAX_LINKED = 10;
  const DEVICE_RE = /^[A-Za-z0-9_-]{10,128}$/; // Nakama takes 10-128 bytes; the game's ids are UUIDs

  export interface Stored {
    hash: string;
    made_ms: number;
  }

  export interface Tries {
    wrong: number;
    since_ms: number;
    locked_until_ms: number;
  }

  // 40 random bits (the first 10 hex digits of a random UUID) as a key; "" for anything else.
  export function fromHex(hex: string): string {
    if (typeof hex !== "string" || hex.length < HEX_CHARS || !/^[0-9a-fA-F]+$/.test(hex.substring(0, HEX_CHARS))) {
      return "";
    }
    // Two halves of 20 bits each: every number stays exact in ES5.
    let out = "";
    for (let half = 0; half < 2; half++) {
      const bits = parseInt(hex.substring(half * 5, half * 5 + 5), 16);
      for (let i = 3; i >= 0; i--) {
        out += ALPHABET.charAt((bits >> (i * 5)) & 31);
      }
    }
    return out;
  }

  export function pretty(key: string): string {
    return key.substring(0, 4) + "-" + key.substring(4);
  }

  // What a person typed as a key, or null: any case, spaces and dashes, O for 0, I and L for 1.
  export function normalize(text: unknown): string | null {
    if (typeof text !== "string" || text.length > 40) {
      return null;
    }
    const plain = text.toUpperCase().replace(/[\s-]/g, "").replace(/O/g, "0").replace(/[IL]/g, "1");
    if (plain.length !== LENGTH) {
      return null;
    }
    for (let i = 0; i < plain.length; i++) {
      if (ALPHABET.indexOf(plain.charAt(i)) < 0) {
        return null;
      }
    }
    return plain;
  }

  // A slow password hash that keeps its own salt (the server: bcrypt, Keys.hasher). A key is 8 of 32 symbols, about
  // 40 bits: a fast hash (SHA-256) could be tried through offline in minutes if the database ever leaked (the lead's
  // review, 2026-09-28).
  export interface Hasher {
    hash(text: string): string;
    check(hash: string, text: string): boolean;
  }

  export function store(hasher: Hasher, key: string, nowMs: number): Stored {
    return { hash: hasher.hash(key), made_ms: nowMs };
  }

  export function storedFrom(value: unknown): Stored | null {
    if (!Util.isObject(value) || typeof value.hash !== "string" || value.hash === "" || !Util.isInt(value.made_ms)) {
      return null;
    }
    return { hash: value.hash, made_ms: value.made_ms };
  }

  export function matches(hasher: Hasher, stored: Stored | null, key: string): boolean {
    return stored !== null && hasher.check(stored.hash, key);
  }

  export function isDeviceId(id: unknown): boolean {
    return typeof id === "string" && DEVICE_RE.test(id);
  }

  export function emptyTries(): Tries {
    return { wrong: 0, since_ms: 0, locked_until_ms: 0 };
  }

  export function triesFrom(value: unknown): Tries {
    if (!Util.isObject(value) || !Util.isInt(value.wrong) || value.wrong < 0 || !Util.isInt(value.since_ms) ||
        !Util.isInt(value.locked_until_ms)) {
      return emptyTries();
    }
    return { wrong: value.wrong, since_ms: value.since_ms, locked_until_ms: value.locked_until_ms };
  }

  // One more wrong key at nowMs: a new window after the last one ended; `max` in a window locks for a window.
  export function wrong(t: Tries, nowMs: number, max: number, windowMs: number): Tries {
    const fresh = t.wrong === 0 || nowMs - t.since_ms > windowMs;
    const out: Tries = fresh ? { wrong: 1, since_ms: nowMs, locked_until_ms: 0 }
      : { wrong: t.wrong + 1, since_ms: t.since_ms, locked_until_ms: t.locked_until_ms };
    if (out.wrong >= max) {
      out.locked_until_ms = nowMs + windowMs;
    }
    return out;
  }

  // Seconds until a locked name or account may try again (0 = now).
  export function wait(t: Tries, nowMs: number): number {
    return t.locked_until_ms > nowMs ? Math.ceil((t.locked_until_ms - nowMs) / 1000) : 0;
  }
}
