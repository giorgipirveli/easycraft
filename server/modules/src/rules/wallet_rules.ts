// Survivor gold in the Nakama wallet (spec §7.4, §17.1; plan M4 Task 8). The host's game decides
// gold during play (host-authoritative gameplay) and reports what it gave through wallet_award;
// the server keeps the ledger and limits what one account can be given, so a modified game can't
// mint gold without bound. A negative award is a purchase (the trader, flying).
//
// The limits scale with the universe like every reward (spec §5.1: 2^(u-1)). They are generous on
// purpose (the M2/M3 balance is not final): a single award at most AWARD_MAX_BASE, an hour at most
// HOUR_MAX_BASE, times 2^(u-1), with u clamped to 1..MAX_UNIVERSE.

namespace WalletRules {
  export const KEY = "survivor_gold";
  export const MAX_GOLD = 999999999; // the game's Wallet.MAX_GOLD
  export const MAX_UNIVERSE = 12;
  export const AWARD_MAX_BASE = 2000;
  export const HOUR_MAX_BASE = 20000;
  export const HOUR_MS = 60 * 60 * 1000;
  export const REASONS: string[] = ["wave", "monster", "boss", "secret", "mission", "sell", "treasure", "tutorial",
    "gift", "shop", "fly", "other"];

  export interface Window {
    awards: number[][]; // [server ms, amount credited] of this hour's awards
  }

  // How much of `amount` fits under the wallet's cap.
  export function capAdd(balance: number, amount: number): number {
    return Math.max(0, Math.min(amount, MAX_GOLD - balance));
  }

  export function reason(raw: unknown): string {
    return typeof raw === "string" && REASONS.indexOf(raw) >= 0 ? raw : "other";
  }

  export function emptyWindow(): Window {
    return { awards: [] };
  }

  export function windowFrom(value: unknown): Window {
    const w = emptyWindow();
    const list = Util.isObject(value) && value.awards instanceof Array ? value.awards : [];
    for (let i = 0; i < list.length; i++) {
      const a = list[i];
      if (a instanceof Array && a.length === 2 && Util.isInt(a[0]) && Util.isInt(a[1])) {
        w.awards.push([a[0], a[1]]);
      }
    }
    return w;
  }

  export function universeMultiplier(universe: unknown): number {
    const u = Util.isInt(universe) ? Util.clamp(universe, 1, MAX_UNIVERSE) : 1;
    return Math.pow(2, u - 1);
  }

  // An award (amount > 0) or a purchase (amount < 0): how much to credit now, and this hour's
  // window with it counted.
  export function award(window: Window, amount: unknown, universe: unknown, nowMs: number):
      { error?: string; credit: number; capped: boolean; window: Window } {
    const kept: Window = { awards: [] };
    let sum = 0;
    for (let i = 0; i < window.awards.length; i++) {
      if (nowMs - window.awards[i][0] < HOUR_MS) {
        kept.awards.push(window.awards[i]);
        sum += window.awards[i][1];
      }
    }
    if (!Util.isInt(amount) || amount === 0) {
      return { error: "bad_request", credit: 0, capped: false, window: kept };
    }
    if (amount < 0) {
      return { credit: amount, capped: false, window: kept };
    }
    const mult = universeMultiplier(universe);
    if (amount > AWARD_MAX_BASE * mult) {
      return { error: "too_much", credit: 0, capped: false, window: kept };
    }
    const room = HOUR_MAX_BASE * mult - sum;
    if (room <= 0) {
      return { error: "limit", credit: 0, capped: true, window: kept };
    }
    const credit = Math.min(amount, room);
    kept.awards.push([nowMs, credit]);
    return { credit: credit, capped: credit < amount, window: kept };
  }

  // M4 Task 10 review C: a spend (amount < 0) that another player reports (the host for a guest in
  // its match) is counted in the guest's own hourly window (limits/wallet_spent, entries [ms, gold
  // spent]): at most SPEND_HOUR_MAX_BASE x 2^(u-1) an hour, so a modified host can't empty a guest's
  // gold. A spend that doesn't fit is refused whole ("spend_limit") and counts nothing; the guest
  // keeps that gold on the server (the next online world starts from it). A player's own spends are
  // never limited here (only the balance).
  export const SPEND_HOUR_MAX_BASE = 20000;

  // 0.2.19 (the gold-double bug's leftover, docs/devlog/parts/gold-double.md): the host's game counts every gold move
  // it tells a guest (a "seq", 1, 2, 3, ...) and sends the count with the last piece of each batch it reports for that
  // guest. The server keeps, per guest, the last match it saw the guest in, by whom it is hosted, the highest seq heard
  // and when it last saw the guest there (limits/wallet_hosted). The guest's game reads it (get_account_state's
  // "hosted") after an online world: its wallet is right once the server has heard the seq the host last told it.
  // A batch the host sends after the guest left (it flushes at once on a leave; or it closed its world first) is
  // still taken when it carries a seq, for that match and host, within LATE_MS of the server last seeing the guest.
  export const SEQ_MAX = 2147483647;
  export const LATE_MS = 24 * 60 * 60 * 1000; // as long as a guest may come back into the match (InviteRules.REJOIN_MS)

  export interface Hosted {
    match_id: string;
    host_id: string;
    seq: number; // the highest seq the host reported for this player in this match (0: none yet)
    seen_ms: number; // when the server last saw the player in the match (the host read its gold or reported)
  }

  export function isSeq(value: unknown): boolean {
    return Util.isInt(value) && value >= 1 && value <= SEQ_MAX;
  }

  export function hostedFrom(value: unknown): Hosted | null {
    if (!Util.isObject(value) || typeof value.match_id !== "string" || typeof value.host_id !== "string" ||
        !Util.isInt(value.seq) || !Util.isInt(value.seen_ms)) {
      return null;
    }
    return { match_id: value.match_id, host_id: value.host_id, seq: Util.clamp(value.seq, 0, SEQ_MAX), seen_ms: value.seen_ms };
  }

  // The record after the host read the player's gold (seq 0) or reported a seq for it; `present`: the player is in
  // the match now. The same match and host keep the highest seq; another match starts over.
  export function hostedNext(old: Hosted | null, matchId: string, hostId: string, seq: number, present: boolean,
      nowMs: number): Hosted {
    const same = old !== null && old.match_id === matchId && old.host_id === hostId;
    return {
      match_id: matchId, host_id: hostId, seq: same ? Math.max(old!.seq, seq) : seq,
      seen_ms: present || !same ? nowMs : old!.seen_ms,
    };
  }

  // A batch for a player no longer in the match (a seq report only): the server saw the player in this host's match,
  // and not in another since, at most LATE_MS ago.
  export function lateAllowed(record: Hosted | null, matchId: string, hostId: string, nowMs: number): boolean {
    return record !== null && record.match_id === matchId && record.host_id === hostId && nowMs - record.seen_ms <= LATE_MS;
  }

  export function spend(window: Window, amount: unknown, universe: unknown, nowMs: number): { error?: string; window: Window } {
    const kept: Window = { awards: [] };
    let sum = 0;
    for (let i = 0; i < window.awards.length; i++) {
      if (nowMs - window.awards[i][0] < HOUR_MS) {
        kept.awards.push(window.awards[i]);
        sum += window.awards[i][1];
      }
    }
    if (!Util.isInt(amount) || amount >= 0) {
      return { error: "bad_request", window: kept };
    }
    if (sum - amount > SPEND_HOUR_MAX_BASE * universeMultiplier(universe)) {
      return { error: "spend_limit", window: kept };
    }
    kept.awards.push([nowMs, -amount]);
    return { window: kept };
  }
}
