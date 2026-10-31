// Owner #99 (spec §5.13 "As built (owner #99)", §17.1): the same name on a new device, with proof and never by the name
// alone (a child's account must not be taken by someone typing its name). A new device asks for the account named
// (an "ask"): the server gives that device a 6-digit code that lives CODE_MS; a device already signed in to the account
// sees the ask without its code, and a grown-up types the code from the new device's screen there (the game's parent
// gate). The right code approves the ask, and the asking device then gets a one-time key for sign_in_with_key (keys.ts).
// WRONG_MAX wrong codes, NOT ME, BACK on the new device or CODE_MS end the ask. Pure rules; the glue is
// src/server/moves.ts.

namespace MoveRules {
  // The lead's quick-ship round (2026-10-15 23:06, the second review's HIGH finding: the parent gate is off in shipped
  // builds and chat can carry a code): the move by code is OFF. move_request and move_approve answer "not_available" and
  // sign_in_with_key takes no one-time key; everything stays here for its return after its fixes
  // (docs/devlog/parts/accounts-99-review.md). Tests written for the move switch it on for themselves.
  export let ENABLED = false;
  export const CODE_DIGITS = 6;
  export const CODE_MS = 5 * 60 * 1000; // an ask (and its code) lives this long
  export const KEY_MS = 5 * 60 * 1000; // after the approval, the one-time key can be fetched and used this long
  export const WRONG_MAX = 3; // wrong codes typed on the account's device end the ask
  export const OPEN_MAX = 3; // asks open for one account at once; a newer one ends the oldest
  export const NAME_MAX = 5; // asks for one name in NAME_WINDOW_MS (whoever asks)
  export const NAME_WINDOW_MS = 15 * 60 * 1000;
  export const ASKER_MAX = 6; // asks one asking account makes in ASKER_WINDOW_MS (any names)
  export const ASKER_WINDOW_MS = 60 * 60 * 1000;
  export const HANDOUT_MAX = 5; // one-time keys an approved ask hands out (an answer lost on the way: again)
  export const KEEP_MS = 30 * 60 * 1000; // an ended ask is kept this long (its asker hears why), then forgotten
  export const KINDS = ["phone", "tablet", "computer", "device"];

  // An ask's states, and why one ended.
  export const OPEN = "open";
  export const APPROVED = "approved";
  export const ENDED = "ended";
  export const DONE = "done"; // the asking device signed in with its key
  export const EXPIRED = "expired";
  export const WRONG_CODE = "wrong_code";
  export const DECLINED = "declined"; // NOT ME on the account's device
  export const CANCELLED = "cancelled"; // BACK on the asking device
  export const REPLACED = "replaced"; // a newer ask for the account (OPEN_MAX), or by the same device
  const STATES = [OPEN, APPROVED, ENDED, DONE];
  const ID_RE = /^[0-9A-Za-z_-]{1,64}$/;

  export interface Ask {
    id: string;
    from: string; // the asking account
    kind: string; // what the asking device is (the words on the card)
    code: string;
    made_ms: number;
    state: string;
    wrong: number;
    why: string;
    approved_ms: number;
    handed: number; // one-time keys handed out (HANDOUT_MAX)
    key_hash: string; // the newest one-time key's slow hash (bcrypt); "" before the approval
  }

  export interface Book {
    asks: Ask[];
  }

  export interface Window {
    count: number;
    since_ms: number;
  }

  // Six digits from the server's randomness (the first 8 hex digits of a random UUID, 32 bits); "" for anything else.
  export function codeFromHex(hex: unknown): string {
    if (typeof hex !== "string" || hex.length < 8 || !/^[0-9a-fA-F]{8}/.test(hex)) {
      return "";
    }
    const n = parseInt(hex.substring(0, 8), 16) % 1000000;
    return ("000000" + n).slice(-CODE_DIGITS);
  }

  // A code as typed (spaces or a dash between the digits), or null.
  export function normalizeCode(text: unknown): string | null {
    if (typeof text !== "string" || text.length > 20) {
      return null;
    }
    const plain = text.replace(/[\s-]/g, "");
    return /^[0-9]{6}$/.test(plain) ? plain : null;
  }

  export function kindOf(value: unknown): string {
    return typeof value === "string" && KINDS.indexOf(value) >= 0 ? value : "device";
  }

  export function isId(value: unknown): value is string {
    return typeof value === "string" && ID_RE.test(value);
  }

  export function askFrom(value: unknown): Ask | null {
    if (!Util.isObject(value) || !isId(value.id) || typeof value.from !== "string" || value.from === "" ||
        typeof value.code !== "string" || !/^[0-9]{6}$/.test(value.code) || !Util.isInt(value.made_ms) ||
        STATES.indexOf(value.state) < 0) {
      return null;
    }
    return {
      id: value.id, from: value.from, kind: kindOf(value.kind), code: value.code, made_ms: value.made_ms,
      state: value.state, wrong: Util.isInt(value.wrong) && value.wrong > 0 ? value.wrong : 0,
      why: typeof value.why === "string" ? value.why : "",
      approved_ms: Util.isInt(value.approved_ms) ? value.approved_ms : 0,
      handed: Util.isInt(value.handed) && value.handed > 0 ? value.handed : 0,
      key_hash: typeof value.key_hash === "string" ? value.key_hash : "",
    };
  }

  export function bookFrom(value: unknown): Book {
    const out: Book = { asks: [] };
    if (!Util.isObject(value) || !Array.isArray(value.asks)) {
      return out;
    }
    for (let i = 0; i < value.asks.length && out.asks.length < 4 * OPEN_MAX; i++) {
      const a = askFrom(value.asks[i]);
      if (a !== null) {
        out.asks.push(a);
      }
    }
    return out;
  }

  export function copy(a: Ask): Ask {
    return {
      id: a.id, from: a.from, kind: a.kind, code: a.code, made_ms: a.made_ms, state: a.state, wrong: a.wrong,
      why: a.why, approved_ms: a.approved_ms, handed: a.handed, key_hash: a.key_hash,
    };
  }

  export function end(a: Ask, why: string): Ask {
    const out = copy(a);
    out.state = ENDED;
    out.why = why;
    return out;
  }

  // The book at nowMs: open asks past CODE_MS and approved ones past KEY_MS end ("expired"); ended and done asks older
  // than KEEP_MS go. A new book.
  export function tidy(book: Book, nowMs: number): Book {
    const out: Book = { asks: [] };
    for (let i = 0; i < book.asks.length; i++) {
      let a = copy(book.asks[i]);
      if (a.state === OPEN && nowMs - a.made_ms >= CODE_MS) {
        a = end(a, EXPIRED);
      } else if (a.state === APPROVED && nowMs - a.approved_ms >= KEY_MS) {
        a = end(a, EXPIRED);
      }
      if ((a.state === ENDED || a.state === DONE) && nowMs - a.made_ms >= KEEP_MS) {
        continue;
      }
      out.asks.push(a);
    }
    return out;
  }

  export function open(book: Book): Ask[] {
    return book.asks.filter(function (a: Ask): boolean { return a.state === OPEN; });
  }

  export function find(book: Book, id: unknown): Ask | null {
    for (let i = 0; i < book.asks.length; i++) {
      if (book.asks[i].id === id) {
        return book.asks[i];
      }
    }
    return null;
  }

  export function replace(book: Book, a: Ask): Book {
    const out: Book = { asks: [] };
    for (let i = 0; i < book.asks.length; i++) {
      out.asks.push(book.asks[i].id === a.id ? copy(a) : copy(book.asks[i]));
    }
    return out;
  }

  // A new ask into the book; beyond OPEN_MAX open asks the oldest end ("replaced"): {book, replaced: those asks}.
  export function add(book: Book, a: Ask): { book: Book; replaced: Ask[] } {
    const out: Book = { asks: [] };
    for (let i = 0; i < book.asks.length; i++) {
      out.asks.push(copy(book.asks[i]));
    }
    out.asks.push(copy(a));
    const replaced: Ask[] = [];
    let opened = open(out).length;
    for (let i = 0; i < out.asks.length && opened > OPEN_MAX; i++) {
      if (out.asks[i].state === OPEN) {
        out.asks[i] = end(out.asks[i], REPLACED);
        replaced.push(out.asks[i]);
        opened--;
      }
    }
    return { book: out, replaced: replaced };
  }

  // The code typed on the account's device: "approved" (the ask, approved at nowMs), "wrong" (+ tries_left; the last
  // wrong one ends it: "ended") or "ended" (it was not open).
  export function check(a: Ask, typed: unknown, nowMs: number): { result: string; ask: Ask; tries_left: number } {
    if (a.state !== OPEN) {
      return { result: "ended", ask: copy(a), tries_left: 0 };
    }
    const code = normalizeCode(typed);
    const out = copy(a);
    if (code !== null && code === a.code) {
      out.state = APPROVED;
      out.approved_ms = nowMs;
      return { result: "approved", ask: out, tries_left: WRONG_MAX - a.wrong };
    }
    out.wrong = a.wrong + 1;
    if (out.wrong >= WRONG_MAX) {
      return { result: "ended", ask: end(out, WRONG_CODE), tries_left: 0 };
    }
    return { result: "wrong", ask: out, tries_left: WRONG_MAX - out.wrong };
  }

  export function emptyWindow(): Window {
    return { count: 0, since_ms: 0 };
  }

  export function windowFrom(value: unknown): Window {
    if (!Util.isObject(value) || !Util.isInt(value.count) || value.count < 0 || !Util.isInt(value.since_ms)) {
      return emptyWindow();
    }
    return { count: value.count, since_ms: value.since_ms };
  }

  // One more ask at nowMs: {ok, window (to keep when ok), wait (seconds until the window ends, when not ok)}.
  export function count(w: Window, nowMs: number, max: number, windowMs: number): { ok: boolean; window: Window; wait: number } {
    if (w.count === 0 || nowMs - w.since_ms >= windowMs) {
      return { ok: true, window: { count: 1, since_ms: nowMs }, wait: 0 };
    }
    if (w.count >= max) {
      return { ok: false, window: w, wait: Math.ceil((w.since_ms + windowMs - nowMs) / 1000) };
    }
    return { ok: true, window: { count: w.count + 1, since_ms: w.since_ms }, wait: 0 };
  }

  export function leftSeconds(a: Ask, nowMs: number): number {
    return Math.max(0, Math.ceil((a.made_ms + CODE_MS - nowMs) / 1000));
  }

  // What the account's devices see of an open ask: never its code, never who asked.
  export function pendingView(a: Ask, nowMs: number): Util.Json {
    return { id: a.id, kind: a.kind, left_s: leftSeconds(a, nowMs) };
  }

  // What the asking device hears about its ask (the glue adds the key and the account's name once approved). The lead's
  // security review (2026-10-15): the asker learns nothing about the account beyond what claim_username's "taken"
  // tells. So whatever the account's devices did (NOT ME, three wrong codes) or others did (newer asks: REPLACED), and
  // whether a device of the account is online at all, the asker sees "waiting" until its code's time is over, then
  // "expired"; only its own BACK says "cancelled", and only the owner's right code says "approved".
  export function askerView(a: Ask, nowMs: number): Util.Json {
    if (a.state === APPROVED) {
      return { state: "approved" };
    }
    if (a.state === DONE) {
      return { state: "done" };
    }
    if (a.state === ENDED && a.why === CANCELLED) {
      return { state: "ended", why: CANCELLED };
    }
    return quietView(a.made_ms, nowMs);
  }

  // An ask that is not approved, as its asker sees it: waiting until CODE_MS after it was made, then expired. Also what
  // a decoy ask shows (an ask past a name's limit, which reaches no device: Moves.start).
  export function quietView(madeMs: number, nowMs: number): Util.Json {
    if (nowMs - madeMs < CODE_MS) {
      return { state: "waiting", left_s: Math.max(0, Math.ceil((madeMs + CODE_MS - nowMs) / 1000)) };
    }
    return { state: "ended", why: EXPIRED };
  }
}
