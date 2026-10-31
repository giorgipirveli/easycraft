// Secret codes on the server (spec §5.11, §14.10, §17.6), ported from the game's
// core/codes/code_rules.gd and code_tries.gd: a code is normalised (trimmed, lowercased) and
// hashed with the game's salt; only hashes are kept here; each code works once per ACCOUNT (the
// game kept it per device profile before M4); 5 wrong codes in a row lock the field for 30 s.

namespace CodeRules {
  // The game's salt: changing it changes every hash (core/codes/code_rules.gd SALT).
  export const SALT = "easycraft:codes:v1:5d3f8a61c2";
  export const MAX_REDEEMED = 256;
  export const MAX_RECORD = 50; // hashes per redeem_code {"hashes"} call (RPC payloads are at most 4 KiB)
  export const MAX_WRONG = 5;
  export const LOCK_MS = 30000;
  export const KIND_GOLD = "gold";
  export const KIND_COSMETIC = "cosmetic";

  export interface Reward {
    kind: string;
    amount?: number;
    item?: string;
  }

  // Salted hash of a normalised code -> its reward (the same table as the game's REWARDS). Add a
  // code by its hash only; never write the plain code in the module.
  export const REWARDS: { [hash: string]: Reward } = {
    // the first code (spec §5.11): 1,000 Survivor gold
    "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a": { kind: KIND_GOLD, amount: 1000 },
    // owner #36: the Cube Hero costume (the game gives it: a cosmetic of "costume.cube_hero")
    "8e79f20f226bca770f874899b8857906d11b6384903e2336272dbe3f89895885": { kind: KIND_COSMETIC, item: "costume.cube_hero" },
  };

  export interface Tries {
    wrong: number; // wrong codes in a row since the last lock or right code
    locked_until: number; // server ms
  }

  export interface State {
    redeemed: string[];
    tries: Tries;
  }

  export interface Result extends State {
    status: string; // accepted, unknown, already_used, locked, empty
    reward?: Reward;
    wait?: number; // whole seconds, when locked
    hash?: string; // the code's hash (accepted, already_used)
  }

  // 0.2.19 (the gold-double bug's leftover, docs/devlog/parts/gold-double.md): gold codes the server paid itself, by
  // hash, kept beside the redeemed list (codes/redeemed {"hashes", "paid"}). A code a phone paid itself (offline, or
  // when the server's answer was lost) and recorded later is in "hashes" only.
  export interface Paid {
    gold: number;
    at_ms: number; // server ms
  }

  export function paidFrom(value: unknown): { [hash: string]: Paid } {
    const out: { [hash: string]: Paid } = {};
    const paid = Util.isObject(value) && Util.isObject(value.paid) ? value.paid : {};
    let n = 0;
    for (const h in paid) {
      const p = paid[h];
      if (Util.has(paid, h) && isHash(h) && Util.isObject(p) && Util.isInt(p.gold) && p.gold >= 0 && Util.isInt(p.at_ms)
          && n < MAX_REDEEMED) {
        out[h] = { gold: p.gold, at_ms: p.at_ms };
        n += 1;
      }
    }
    return out;
  }

  // The hashes in `hashes` the server paid itself, once each, in their order: [{"hash", "gold", "at_ms"}].
  export function paidList(paid: { [hash: string]: Paid }, hashes: unknown[]): Util.Json[] {
    const out: Util.Json[] = [];
    const seen: string[] = [];
    for (let i = 0; i < hashes.length; i++) {
      const h = hashes[i];
      if (typeof h === "string" && Util.has(paid, h) && seen.indexOf(h) < 0) {
        seen.push(h);
        out.push({ hash: h, gold: paid[h].gold, at_ms: paid[h].at_ms });
      }
    }
    return out;
  }

  export function normalize(code: string): string {
    return Util.stripEdges(code).toLowerCase();
  }

  export function hashCode(code: string, sha256: (text: string) => string): string {
    return sha256(SALT + normalize(code));
  }

  export function emptyTries(): Tries {
    return { wrong: 0, locked_until: 0 };
  }

  export function isHash(text: unknown): boolean {
    return typeof text === "string" && /^[0-9a-f]{64}$/.test(text);
  }

  export function redeemedFrom(value: unknown): string[] {
    const out: string[] = [];
    const list = Util.isObject(value) && value.hashes instanceof Array ? value.hashes : [];
    for (let i = 0; i < list.length && out.length < MAX_REDEEMED; i++) {
      if (isHash(list[i]) && out.indexOf(list[i]) < 0) {
        out.push(list[i]);
      }
    }
    return out;
  }

  export function triesFrom(value: unknown): Tries {
    if (!Util.isObject(value)) {
      return emptyTries();
    }
    return {
      wrong: Util.isInt(value.wrong) ? Util.clamp(value.wrong, 0, MAX_WRONG) : 0,
      locked_until: Util.isInt(value.locked_until) ? value.locked_until : 0,
    };
  }

  // Whether the server can give it: gold of a positive whole amount, or a cosmetic item the game
  // unlocks (the server doesn't know the avatar catalogue; the game refuses an unknown item).
  function canGive(reward: Reward): boolean {
    if (reward.kind === KIND_GOLD) {
      return Util.isInt(reward.amount) && reward.amount > 0;
    }
    if (reward.kind === KIND_COSMETIC) {
      return typeof reward.item === "string" && reward.item !== "";
    }
    return false;
  }

  // Codes the game redeemed offline (it paid them itself), recorded at the next sign-in so they
  // can't pay again here (M4 Wave 2, agent F). Only known hashes count; nothing is paid, and an
  // unknown hash is not a wrong guess (a hash is no code: guessing hashes finds nothing to redeem).
  export function record(state: State, hashes: unknown[], rewards: { [hash: string]: Reward } = REWARDS):
      { redeemed: string[]; recorded: number; already: number } {
    const redeemed = state.redeemed.slice();
    let recorded = 0;
    let already = 0;
    const seen: string[] = [];
    for (let i = 0; i < hashes.length; i++) {
      const h = hashes[i];
      if (!isHash(h) || seen.indexOf(h as string) >= 0 || !Util.has(rewards, h as string)) {
        continue;
      }
      seen.push(h as string);
      if (redeemed.indexOf(h as string) >= 0) {
        already += 1;
      } else if (redeemed.length < MAX_REDEEMED) {
        redeemed.push(h as string);
        recorded += 1;
      }
    }
    return { redeemed: redeemed, recorded: recorded, already: already };
  }

  export function redeem(state: State, code: unknown, nowMs: number, sha256: (text: string) => string,
      rewards: { [hash: string]: Reward } = REWARDS): Result {
    const redeemed = state.redeemed.slice();
    const tries: Tries = { wrong: state.tries.wrong, locked_until: state.tries.locked_until };
    const out: Result = { status: "empty", redeemed: redeemed, tries: tries };
    const norm = typeof code === "string" ? normalize(code) : "";
    if (norm === "") {
      return out;
    }
    if (nowMs < tries.locked_until) {
      out.status = "locked";
      out.wait = Math.ceil((tries.locked_until - nowMs) / 1000);
      return out;
    }
    const h = hashCode(norm, sha256);
    if (!Util.has(rewards, h)) {
      tries.wrong += 1;
      if (tries.wrong >= MAX_WRONG) {
        tries.wrong = 0;
        tries.locked_until = nowMs + LOCK_MS;
      }
      out.status = "unknown";
      return out;
    }
    if (redeemed.indexOf(h) >= 0) {
      out.status = "already_used";
      out.hash = h;
      return out;
    }
    if (redeemed.length >= MAX_REDEEMED || !canGive(rewards[h])) {
      out.status = "unknown"; // not used up, and not a wrong guess
      return out;
    }
    redeemed.push(h);
    tries.wrong = 0;
    out.status = "accepted";
    out.reward = rewards[h];
    out.hash = h;
    return out;
  }
}
