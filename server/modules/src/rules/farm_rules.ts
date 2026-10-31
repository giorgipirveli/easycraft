// The Gold Farm by the server's clock (spec §5.6, §14.8, §17.6): a player inside their farm when
// they leave earns rate_per_hour x 2^(u-1) for the time away, capped (12 h by default; upgrades
// raise it). The server records when the player left ("start") and pays by its own clock when
// they come back ("collect"), so changing the phone's clock earns nothing.
//
// The farm itself (M3 Task 10) is not built yet: the rate and cap come from the game and are
// clamped to MAX_RATE_PER_HOUR and MAX_CAP_HOURS here; the time is always the server's.

namespace FarmRules {
  export const HOUR_MS = 60 * 60 * 1000;
  export const DEFAULT_CAP_HOURS = 12;
  export const MAX_CAP_HOURS = 24;
  export const MAX_RATE_PER_HOUR = 1000; // the best farm in universe 1 (before 2^(u-1))
  export const MAX_UNIVERSE = 12;
  const WORLD_RE = /^[A-Za-z0-9_\-]{1,64}$/;

  export interface Farm {
    started_ms: number; // when the player left, by the server's clock
    rate_per_hour: number;
    universe: number;
    cap_hours: number;
  }

  // M4 Task 10 review D: farm clocks a player may have at once (one per world key; a collect removes
  // it). The game uses one per Survivor save slot (survivor_1 .. survivor_12).
  export const MAX_FARMS = 20;

  // Why a "start" can't make a clock: `already` = this world has one (it starts again), `count` =
  // the clocks the player has. null when it may.
  export function startRefusal(already: boolean, count: number): string | null {
    return already || count < MAX_FARMS ? null : "too_many_farms";
  }

  export function isWorld(world: unknown): boolean {
    return typeof world === "string" && WORLD_RE.test(world);
  }

  function positiveInt(value: unknown, fallback: number): number | null {
    if (value === undefined) {
      return fallback;
    }
    return Util.isInt(value) && value >= 1 ? value : null;
  }

  // "start" {"world", "rate_per_hour", "universe"?, "cap_hours"?}.
  export function start(request: Util.Json, nowMs: number): { farm?: Farm; error?: string } {
    if (!isWorld(request.world)) {
      return { error: "bad_request" };
    }
    const rate = Util.isInt(request.rate_per_hour) && request.rate_per_hour >= 0 ? request.rate_per_hour : null;
    const universe = positiveInt(request.universe, 1);
    const cap = positiveInt(request.cap_hours, DEFAULT_CAP_HOURS);
    if (rate === null || universe === null || cap === null) {
      return { error: "bad_request" };
    }
    return { farm: {
      started_ms: nowMs,
      rate_per_hour: Math.min(rate, MAX_RATE_PER_HOUR),
      universe: Math.min(universe, MAX_UNIVERSE),
      cap_hours: Math.min(cap, MAX_CAP_HOURS),
    } };
  }

  export function earned(farm: Farm, nowMs: number): { earned: number; away_ms: number; capped: boolean } {
    const away = Math.max(0, nowMs - farm.started_ms);
    const capMs = farm.cap_hours * HOUR_MS;
    const paid = Math.min(away, capMs);
    const gold = Math.floor(farm.rate_per_hour * Math.pow(2, farm.universe - 1) * paid / HOUR_MS);
    return { earned: gold, away_ms: away, capped: away > capMs };
  }

  export function farmFrom(value: unknown): Farm | null {
    if (!Util.isObject(value) || !Util.isInt(value.started_ms) || !Util.isInt(value.rate_per_hour) ||
        !Util.isInt(value.universe) || !Util.isInt(value.cap_hours)) {
      return null;
    }
    return {
      started_ms: value.started_ms,
      rate_per_hour: Util.clamp(value.rate_per_hour, 0, MAX_RATE_PER_HOUR),
      universe: Util.clamp(value.universe, 1, MAX_UNIVERSE),
      cap_hours: Util.clamp(value.cap_hours, 1, MAX_CAP_HOURS),
    };
  }
}
