// Verifiable parental consent for under_13 (spec §17.2). A provider adapter checks the parent; the
// only provider today is the FAKE one for developer builds (runtime env
// EASYCRAFT_CONSENT_PROVIDER=fake, server/nakama/local.yml). The real one (Epic's Kids Web Services
// or an equivalent) needs the owner to register the app; until then a server without a provider
// answers "consent_unavailable" and under_13 players stay with solo, LAN and bot friends.
//
// Nothing about the parent is stored: a provider may need the parent's contact to reach them, but
// the record keeps only the state, the provider's name and its reference for the request.

namespace Consent {
  export const NONE = "none";
  export const PENDING = "pending";
  export const VERIFIED = "verified";
  export const DENIED = "denied";

  // Stored in the "parent" collection, key "consent" (server/modules/src/server/store.ts).
  export interface Record {
    status: string; // none, pending, verified, denied
    provider: string;
    ref: string;
    started_ms: number;
    updated_ms: number;
  }

  export interface Answer {
    status: string; // pending, verified, denied
    ref: string;
    // What the parent allowed, when the provider tells (Kids Web Services has per-feature permissions).
    permissions?: { online_allowed?: boolean; chat?: string };
  }

  export interface Provider {
    name: string;
    delayMs: number;
    // Asks the provider to reach the parent. request.parent_contact is passed on, never stored.
    start(userId: string, request: Util.Json, nowMs: number): Answer;
    check(ref: string, nowMs: number): Answer;
  }

  export const FAKE_DEFAULT_DELAY_MS = 2000;
  export const FAKE_MAX_DELAY_MS = 600000;

  // The fake provider: "a parent" answers FAKE delay after the start. It keeps no state (Nakama runs
  // each call in its own runtime), so the answer and the time are in the reference itself:
  // "fake:<approve|deny>:<ready at ms>". A request can ask for {"fake_answer": "deny"} to test a no.
  export function fakeProvider(delayMs: number): Provider {
    return {
      name: "fake",
      delayMs: delayMs,
      start: function (_userId: string, request: Util.Json, nowMs: number): Answer {
        const answer = request.fake_answer === "deny" ? "deny" : "approve";
        return { status: PENDING, ref: "fake:" + answer + ":" + (nowMs + delayMs) };
      },
      check: function (ref: string, nowMs: number): Answer {
        const parts = typeof ref === "string" ? ref.split(":") : [];
        const readyAt = parts.length === 3 ? Number(parts[2]) : NaN;
        if (parts[0] !== "fake" || (parts[1] !== "approve" && parts[1] !== "deny") || !Util.isInt(readyAt)) {
          return { status: DENIED, ref: String(ref) };
        }
        if (nowMs < readyAt) {
          return { status: PENDING, ref: ref };
        }
        if (parts[1] === "deny") {
          return { status: DENIED, ref: ref };
        }
        return { status: VERIFIED, ref: ref, permissions: { online_allowed: true, chat: AccountRules.CHAT_QUICK } };
      },
    };
  }

  // The provider this server uses, from Nakama's runtime env; null when none is set up. A production
  // server (EASYCRAFT_ENV=production) never uses the fake one, whatever its env says: consent_start
  // then answers "consent_unavailable" and a pending fake request is never approved.
  export function providerFor(env: unknown): Provider | null {
    const e: Util.Json = Util.isObject(env) ? env : {};
    if (e.EASYCRAFT_CONSENT_PROVIDER === "fake" && !Util.isProduction(e)) {
      const raw = Number(e.EASYCRAFT_FAKE_CONSENT_DELAY_MS);
      const delay = e.EASYCRAFT_FAKE_CONSENT_DELAY_MS === undefined || !isFinite(raw)
        ? FAKE_DEFAULT_DELAY_MS
        : Util.clamp(Math.floor(raw), 0, FAKE_MAX_DELAY_MS);
      return fakeProvider(delay);
    }
    return null;
  }

  export function emptyRecord(): Record {
    return { status: NONE, provider: "", ref: "", started_ms: 0, updated_ms: 0 };
  }

  export function recordFrom(value: unknown): Record {
    if (!Util.isObject(value)) {
      return emptyRecord();
    }
    const okStatus = value.status === NONE || value.status === PENDING || value.status === VERIFIED || value.status === DENIED;
    if (!okStatus || typeof value.provider !== "string" || typeof value.ref !== "string") {
      return emptyRecord();
    }
    return {
      status: value.status,
      provider: value.provider,
      ref: value.ref,
      started_ms: Util.isInt(value.started_ms) ? value.started_ms : 0,
      updated_ms: Util.isInt(value.updated_ms) ? value.updated_ms : 0,
    };
  }

  export interface Step {
    error?: string;
    state: AccountRules.State;
    record: Record;
    changed: boolean; // state or record must be saved
    approved?: boolean; // the parent said yes just now (notification 103)
  }

  // consent_start: under_13 only, with a claimed username and a provider.
  export function start(state: AccountRules.State, record: Record, provider: Provider | null, userId: string,
      request: Util.Json, nowMs: number): Step {
    const same: Step = { state: AccountRules.toMetadata(state), record: record, changed: false };
    if (!AccountRules.isClaimed(state)) {
      same.error = "not_claimed";
      return same;
    }
    if (state.age_band !== AccountRules.UNDER_13) {
      same.error = "not_needed";
      return same;
    }
    if (state.consent === AccountRules.CONSENT_VERIFIED) {
      return same;
    }
    if (provider === null) {
      same.error = "consent_unavailable";
      return same;
    }
    const answer = provider.start(userId, request, nowMs);
    const next = AccountRules.toMetadata(state);
    next.consent = AccountRules.CONSENT_PENDING;
    return {
      state: next,
      record: { status: PENDING, provider: provider.name, ref: answer.ref, started_ms: nowMs, updated_ms: nowMs },
      changed: true,
    };
  }

  // consent_status: asks the provider about a pending request and applies its answer.
  export function check(state: AccountRules.State, record: Record, provider: Provider | null, nowMs: number): Step {
    const same: Step = { state: AccountRules.toMetadata(state), record: record, changed: false };
    if (record.status !== PENDING || provider === null || record.provider !== provider.name) {
      return same;
    }
    const answer = provider.check(record.ref, nowMs);
    if (answer.status === PENDING) {
      return same;
    }
    const next = AccountRules.toMetadata(state);
    const done: Record = { status: answer.status, provider: record.provider, ref: record.ref,
      started_ms: record.started_ms, updated_ms: nowMs };
    if (answer.status !== VERIFIED) {
      next.consent = AccountRules.CONSENT_NONE;
      next.online_allowed = false;
      done.status = DENIED;
      return { state: next, record: done, changed: true, approved: false };
    }
    next.consent = AccountRules.CONSENT_VERIFIED;
    const allowed = answer.permissions || {};
    if (typeof allowed.online_allowed === "boolean") {
      next.online_allowed = allowed.online_allowed;
    }
    if (AccountRules.isChat(allowed.chat)) {
      next.chat = allowed.chat as string;
    }
    if (next.age_band === AccountRules.UNDER_13 && next.chat === AccountRules.CHAT_FILTERED) {
      next.chat = AccountRules.CHAT_QUICK;
    }
    return { state: next, record: done, changed: true, approved: true };
  }
}
