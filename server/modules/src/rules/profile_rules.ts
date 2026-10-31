// The account's profile on the server (owner #67; spec §7.4, §17.1): the game's backup of the child's
// progress and choices, which it writes itself into its private profiles/profile object (M4 F) and
// reads back at sign-in on any device. A modified game can write anything there, so every write is
// cleaned here first (guards.ts): a JSON object of sane size and shape, never the Survivor gold (the
// wallet ledger is the only truth for gold), never what fits only one device, and the account's own
// name and age band. Fields a newer game adds pass within the same limits, so an app update never
// waits for the server. Only the account's own devices read it back, and each checks it again.

namespace ProfileRules {
  export const KEY = "profile"; // the one object a game writes in "profiles"
  // Owner #70/#71: the School grows to every subject of every grade (4000 units, each a key of school.units).
  export const MAX_CHARS = 1024 * 1024;
  export const MAX_DEPTH = 8;
  export const MAX_LIST = 2000;
  export const MAX_KEYS = 5000;
  export const MAX_TEXT = 1024;
  export const MAX_FIELDS = 64; // top-level fields
  export const MAX_SETTING_TEXT = 64;
  // Never kept: gold is the wallet's; the rest fits one device (moved thumb buttons, the farm's phone note).
  export const DROPPED = ["survivor_gold", "hud_moves", "farm_note_at"];
  // Settings of one device: its power and screen, the browser's install card, the phone's farm note.
  export const DEVICE_SETTINGS = ["graphics", "view_distance", "show_fps", "install_not_now", "install_asked_at", "farm_note"];
  // The kind of every field the game knows (ProfileData.to_json); a known field of another kind is dropped.
  const KINDS: { [field: string]: string } = {
    version: "int", backup: "int", username: "text", age_band: "text", settings: "object", codes_redeemed: "list",
    avatar: "object", cosmetics: "list", purchases: "list", wishes: "list", theater_switch: "text", photo_share: "text",
    universe_unlocked: "int", hints_seen: "list", secret_book: "object", treasures: "list", stickers: "object",
    updated_at: "number", progress: "object", pip: "object", crystals_given: "int", crystal_gifts: "list",
    baby_dragon: "object", wonder: "object", buddy_magic: "object", tutorial: "object", stamps: "object",
  };
  const FIELD_RE = /^[a-z][a-z0-9_]{0,39}$/;

  export interface Account {
    username: string;
    age_band: string;
  }

  export interface Cleaned {
    value?: string;
    error?: string; // "too_big" | "bad_profile"
  }

  export function clean(text: unknown, account: Account): Cleaned {
    if (typeof text !== "string") {
      return { error: "bad_profile" };
    }
    if (text.length > MAX_CHARS) {
      return { error: "too_big" };
    }
    let data: unknown;
    try {
      data = JSON.parse(text);
    } catch (_e) {
      return { error: "bad_profile" };
    }
    if (!Util.isObject(data) || !isVersion(data.version) || (Util.has(data, "backup") && !isVersion(data.backup)) ||
        !sane(data, 0)) {
      return { error: "bad_profile" };
    }
    const out: Util.Json = {};
    let fields = 0;
    for (const field in data) {
      if (!Util.has(data, field) || DROPPED.indexOf(field) >= 0 || !FIELD_RE.test(field)) {
        continue;
      }
      const kind = Util.has(KINDS, field) ? KINDS[field] : "";
      if (kind !== "" && !isKind(data[field], kind)) {
        continue;
      }
      if (++fields > MAX_FIELDS) {
        return { error: "bad_profile" };
      }
      out[field] = data[field];
    }
    if (Util.isObject(out.settings)) {
      out.settings = settings(out.settings);
    }
    if (Util.isObject(out.avatar)) {
      delete out.avatar.base; // boy / girl stays on the device (owner #48: personal data)
    }
    out.username = account.username;
    if (AccountRules.isValidBand(account.age_band)) {
      out.age_band = account.age_band;
    } else if (!AccountRules.isValidBand(out.age_band)) {
      delete out.age_band;
    }
    return { value: JSON.stringify(out) };
  }

  function settings(s: Util.Json): Util.Json {
    const out: Util.Json = {};
    for (const key in s) {
      if (!Util.has(s, key) || DEVICE_SETTINGS.indexOf(key) >= 0) {
        continue;
      }
      const v = s[key];
      if (typeof v === "boolean" || typeof v === "number" || (typeof v === "string" && v.length <= MAX_SETTING_TEXT)) {
        out[key] = v;
      }
    }
    return out;
  }

  function isVersion(v: unknown): boolean {
    return Util.isInt(v) && v >= 1 && v <= 99;
  }

  function isKind(v: unknown, kind: string): boolean {
    switch (kind) {
      case "int":
        return Util.isInt(v);
      case "number":
        return typeof v === "number";
      case "text":
        return typeof v === "string";
      case "list":
        return v instanceof Array;
      default:
        return Util.isObject(v);
    }
  }

  // Every value: finite numbers, short texts, short lists, few keys, not too deep.
  function sane(v: unknown, depth: number): boolean {
    if (v === null || typeof v === "boolean") {
      return true;
    }
    if (typeof v === "number") {
      return isFinite(v);
    }
    if (typeof v === "string") {
      return v.length <= MAX_TEXT;
    }
    if (depth >= MAX_DEPTH) {
      return false;
    }
    if (v instanceof Array) {
      if (v.length > MAX_LIST) {
        return false;
      }
      for (let i = 0; i < v.length; i++) {
        if (!sane(v[i], depth + 1)) {
          return false;
        }
      }
      return true;
    }
    if (!Util.isObject(v)) {
      return false;
    }
    let keys = 0;
    for (const k in v) {
      if (!Util.has(v, k)) {
        continue;
      }
      if (++keys > MAX_KEYS || k.length > MAX_TEXT || !sane(v[k], depth + 1)) {
        return false;
      }
    }
    return true;
  }
}
