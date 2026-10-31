// Friends when they are not online together (M4 Wave 3, agent I; spec §17.5 research additions,
// docs/design T3, T4, D5): the limits of blueprint gifts, showcases, guestbook stickers and bottle
// mail. Guards (spec §17.2): sizes capped here and checked by the server (BuildRules); preset stickers
// and quick phrases only (no free text); at most a few unopened things per friend; nothing received
// is kept longer than KEEP_DAYS (the retention clean-up); every received thing can be deleted.

namespace GiftRules {
  // A blueprint gift (BuildPicker: the connected build around a tapped block).
  export const GIFT: BuildRules.Limits = { maxDim: 8, maxCount: 512, maxText: 2800 };
  // The tiny build in a bottle.
  export const BOTTLE: BuildRules.Limits = { maxDim: 4, maxCount: 64, maxText: 400 };
  // A showcase: the build area around the player (ShowcaseArea), up to 48 KiB of text.
  export const SHOWCASE: BuildRules.Limits = { maxDim: 32, maxCount: 32 * 32 * 32, maxText: 48 * 1024 };
  // A buddy waving in a showcase (CaptureRules: at most 200 blocks within 8 of the tapped block).
  export const BUDDY: BuildRules.Limits = { maxDim: 17, maxCount: 200, maxText: 3000 };
  // publish_showcase's payload (the RPC's own cap: every other RPC takes 4 KiB, Util.MAX_PAYLOAD).
  export const SHOWCASE_PAYLOAD = 56 * 1024;

  export const GIFTS_PER_FRIEND = 10; // unopened, from one friend
  export const GIFT_INBOX_MAX = 50; // unopened, from everyone
  export const BOTTLES_PER_FRIEND = 5;
  export const BOTTLE_INBOX_MAX = 30;
  export const SENDS_PER_HOUR = 30; // gifts, and bottles, each
  export const PUBLISHES_PER_HOUR = 12;
  export const HOUR_MS = 60 * 60 * 1000;
  export const DAY_MS = 24 * HOUR_MS;
  // Unopened gifts and bottles, and guestbook stickers, are kept this long (the retention clean-up).
  export const KEEP_DAYS = 60;

  // The guestbook's stickers (pictures in the game: ui/gifts/sticker_pictures.gd).
  export const STICKERS: string[] = ["star", "heart", "smile", "wow", "thumbs_up", "rainbow", "trophy", "flower"];
  export const GUESTBOOK_MAX = 30;
  export const STICKER_GAP_MS = 10 * 60 * 1000; // the same visitor in the same guestbook

  export function isSticker(value: unknown): boolean {
    return typeof value === "string" && STICKERS.indexOf(value) >= 0;
  }

  export function expired(createdMs: number, nowMs: number): boolean {
    return createdMs <= cutoffMs(nowMs);
  }

  // Anything received at or before this time is gone.
  export function cutoffMs(nowMs: number): number {
    return nowMs - KEEP_DAYS * DAY_MS;
  }

  // A storage key: the prefix, the time and twelve hex digits of a uuid.
  export function keyFor(prefix: string, nowMs: number, uuid: string): string {
    return prefix + nowMs + "_" + uuid.replace(/-/g, "").toLowerCase().substring(0, 12);
  }

  // --- Send windows (limits collection: {"times": [...]}) ---

  export function timesFrom(value: unknown): number[] {
    const out: number[] = [];
    if (Util.isObject(value) && value.times instanceof Array) {
      for (let i = 0; i < value.times.length; i++) {
        if (Util.isInt(value.times[i])) {
          out.push(value.times[i]);
        }
      }
    }
    return out;
  }

  // Whether one more send fits `max` in the last `windowMs`; the window's times afterwards.
  export function allow(times: number[], nowMs: number, max: number, windowMs: number): { ok: boolean; times: number[] } {
    const kept: number[] = [];
    for (let i = 0; i < times.length; i++) {
      if (nowMs - times[i] < windowMs && times[i] <= nowMs) {
        kept.push(times[i]);
      }
    }
    if (kept.length >= max) {
      return { ok: false, times: kept };
    }
    kept.push(nowMs);
    return { ok: true, times: kept };
  }

  // --- The guestbook (one object per showcase owner) ---

  export interface Entry {
    entry_id: string;
    from_id: string;
    from_username: string;
    sticker: string;
    at_ms: number;
  }

  export interface Book {
    entries: Entry[]; // oldest first
    oldest_ms: number; // the first entry's time (the retention clean-up finds old books by it), 0 if empty
  }

  function nonEmpty(value: unknown): boolean {
    return typeof value === "string" && value !== "";
  }

  export function entryFrom(value: unknown): Entry | null {
    if (!Util.isObject(value) || !nonEmpty(value.entry_id) || !nonEmpty(value.from_id) || !nonEmpty(value.from_username) ||
        !isSticker(value.sticker) || !Util.isInt(value.at_ms)) {
      return null;
    }
    return { entry_id: value.entry_id, from_id: value.from_id, from_username: value.from_username, sticker: value.sticker,
      at_ms: value.at_ms };
  }

  function book(entries: Entry[]): Book {
    const kept = entries.slice(Math.max(0, entries.length - GUESTBOOK_MAX));
    return { entries: kept, oldest_ms: kept.length > 0 ? kept[0].at_ms : 0 };
  }

  // A stored guestbook as the rules keep it: well-formed entries of the last KEEP_DAYS, the newest 30.
  export function bookFrom(value: unknown, nowMs: number): Book {
    const out: Entry[] = [];
    const raw = Util.isObject(value) && value.entries instanceof Array ? value.entries : [];
    for (let i = 0; i < raw.length; i++) {
      const e = entryFrom(raw[i]);
      if (e !== null && !expired(e.at_ms, nowMs)) {
        out.push(e);
      }
    }
    return book(out);
  }

  // A visitor's sticker: at most one every STICKER_GAP_MS from the same visitor.
  export function sign(current: Book, entry: Entry, nowMs: number): { book?: Book; error?: string } {
    for (let i = 0; i < current.entries.length; i++) {
      const e = current.entries[i];
      if (e.from_id === entry.from_id && nowMs - e.at_ms < STICKER_GAP_MS) {
        return { error: "too_fast" };
      }
    }
    return { book: book(current.entries.concat([entry])) };
  }

  // The book without one entry, or null when it has no such entry.
  export function remove(current: Book, entryId: unknown): Book | null {
    const kept: Entry[] = [];
    for (let i = 0; i < current.entries.length; i++) {
      if (current.entries[i].entry_id !== entryId) {
        kept.push(current.entries[i]);
      }
    }
    return kept.length === current.entries.length ? null : book(kept);
  }

  // The book without the entries of these players (deleted accounts).
  export function without(current: Book, fromIds: string[]): Book {
    const kept: Entry[] = [];
    for (let i = 0; i < current.entries.length; i++) {
      if (fromIds.indexOf(current.entries[i].from_id) < 0) {
        kept.push(current.entries[i]);
      }
    }
    return book(kept);
  }
}
