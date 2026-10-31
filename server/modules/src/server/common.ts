// The glue between Nakama and the rules: how an RPC reads its payload and answers, how a hook
// refuses, and the server's clock. RPCs answer JSON {"ok": true, ...} or {"ok": false, "error":
// "<code>"} (plan M4 Wave 1); the game turns each short code into plain words for the child.

namespace Server {
  // The server clock (spec §5.6: the farm and the codes use the server's time, never the phone's).
  // Tests replace it.
  export let nowMs = function (): number {
    return Date.now();
  };

  export function fail(error: string, extra?: Util.Json): Util.Json {
    const out: Util.Json = { ok: false, error: error };
    if (extra) {
      for (const k in extra) {
        if (Util.has(extra, k)) {
          out[k] = extra[k];
        }
      }
    }
    return out;
  }

  export function errorText(e: unknown): string {
    if (Util.isObject(e) && typeof e.message === "string") {
      return e.message;
    }
    return String(e);
  }

  // Runs an RPC for a signed-in player whose payload is a JSON object ("" counts as {}). A rule
  // that says no is an answer ({"ok": false, ...}), not a failure; a real failure is logged and
  // answered "server_error".
  export function rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, name: string, payload: string,
      body: (userId: string, request: Util.Json) => Util.Json): string {
    const request = Util.parsePayload(payload);
    if (request === null) {
      return JSON.stringify(fail("bad_request"));
    }
    if (!ctx.userId) {
      return JSON.stringify(fail("not_signed_in"));
    }
    try {
      return JSON.stringify(body(ctx.userId, request));
    } catch (e) {
      logger.error("%s failed for %s: %s", name, ctx.userId, errorText(e));
      return JSON.stringify(fail("server_error"));
    }
  }

  // M4 Task 8b, agent G: like rpc(), but also for the owner without a session (the server's runtime
  // HTTP key, or the console's API Explorer with no user id): the body gets "" as the caller then.
  // A game can't call an RPC without a session (only the secret HTTP key can), so "" means the owner.
  export function rpcOrAdmin(ctx: nkruntime.Context, logger: nkruntime.Logger, name: string, payload: string,
      body: (callerId: string, request: Util.Json) => Util.Json): string {
    const request = Util.parsePayload(payload);
    if (request === null) {
      return JSON.stringify(fail("bad_request"));
    }
    try {
      return JSON.stringify(body(ctx.userId || "", request));
    } catch (e) {
      logger.error("%s failed for %s: %s", name, ctx.userId || "the owner", errorText(e));
      return JSON.stringify(fail("server_error"));
    }
  }

  // gRPC codes Nakama maps to HTTP statuses (nkruntime.Codes).
  export const INVALID_ARGUMENT = 3;
  export const NOT_FOUND = 5;
  export const ALREADY_EXISTS = 6;
  export const PERMISSION_DENIED = 7;
  export const RESOURCE_EXHAUSTED = 8;
  export const FAILED_PRECONDITION = 9;

  // A hook refuses by throwing: the game gets the code as the error's message and the session stays
  // open (a hook that returns nothing would close a realtime session).
  export function refuse(message: string, code: number): never {
    throw { message: message, code: code };
  }

  // A developer server's switch (runtime env in server/nakama/local.yml); off unless exactly "true",
  // and always off on a production server (EASYCRAFT_ENV=production).
  export function flag(ctx: nkruntime.Context, name: string): boolean {
    return Util.isObject(ctx.env) && ctx.env[name] === "true" && !Util.isProduction(ctx.env);
  }
}

// Nakama notification codes (plan M4 Wave 1).
namespace Notes {
  export const INVITE = 101; // {"match_id", "from_username", "world_name"} (+ "from_user_id")
  export const INVITE_CANCELLED = 102; // not sent yet: a match ends with its host (spec §17.3)
  export const PARENT_APPROVED = 103; // {"what": "consent"}
  export const REMOVED = 107; // {"match_id"}: the host took this player out of its world (spec §17.3)
}
