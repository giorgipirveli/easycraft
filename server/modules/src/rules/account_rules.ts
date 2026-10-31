// A player's account state (plan M4 Wave 1), kept in Nakama's account metadata, which only the
// server can write: {"age_band": "under_13"|"13_plus", "consent": "none"|"pending"|"verified",
// "online_allowed": bool, "chat": "off"|"quick"|"filtered"}. Spec §5.14, §17.2: high-privacy
// defaults, nothing online for under_13 without verified parental consent, quick chat only for
// under_13. A missing or broken value reads as the strictest one.

namespace AccountRules {
  export const UNDER_13 = "under_13";
  export const TEEN_PLUS = "13_plus";
  export const CONSENT_NONE = "none";
  export const CONSENT_PENDING = "pending";
  export const CONSENT_VERIFIED = "verified";
  export const CHAT_OFF = "off";
  export const CHAT_QUICK = "quick";
  export const CHAT_FILTERED = "filtered";

  export interface State {
    age_band: string; // "" until the player claims a username (then the account is "claimed")
    consent: string;
    online_allowed: boolean;
    chat: string;
  }

  export interface Read extends State {
    claimed: boolean;
  }

  // The owner (2026-09-29): "remove all such restrictions … this is not a priority for now". Off: no age rules on
  // the server: every claimed account plays online with the filtered chat (the word filter stays), whatever its band,
  // and a band may be raised. The rules stay behind this switch (a store may ask for them later); the tests switch it
  // on (test/harness.ts). The game has the same switch (AgeBand.restrictions).
  export let ageRules = false;

  export function isValidBand(band: unknown): boolean {
    return band === UNDER_13 || band === TEEN_PLUS;
  }

  // A missing or unknown band gets the under_13 rules (as the game's ChatRules.effective_band).
  export function effectiveBand(band: unknown): string {
    if (!ageRules) {
      return TEEN_PLUS;
    }
    return band === TEEN_PLUS ? TEEN_PLUS : UNDER_13;
  }

  export function isChat(value: unknown): boolean {
    return value === CHAT_OFF || value === CHAT_QUICK || value === CHAT_FILTERED;
  }

  function isConsent(value: unknown): boolean {
    return value === CONSENT_NONE || value === CONSENT_PENDING || value === CONSENT_VERIFIED;
  }

  export function defaults(band: string): State {
    if (band === TEEN_PLUS || !ageRules) {
      return { age_band: TEEN_PLUS, consent: CONSENT_NONE, online_allowed: true, chat: CHAT_FILTERED };
    }
    return { age_band: UNDER_13, consent: CONSENT_NONE, online_allowed: false, chat: CHAT_QUICK };
  }

  export function fromMetadata(meta: unknown): Read {
    const m: Util.Json = Util.isObject(meta) ? meta : {};
    const band = isValidBand(m.age_band) ? (m.age_band as string) : "";
    return {
      age_band: band,
      consent: isConsent(m.consent) ? m.consent : CONSENT_NONE,
      online_allowed: m.online_allowed === true,
      chat: isChat(m.chat) ? m.chat : CHAT_OFF,
      claimed: band !== "",
    };
  }

  // Exactly the four shared keys.
  export function toMetadata(state: State): State {
    return { age_band: state.age_band, consent: state.consent, online_allowed: state.online_allowed, chat: state.chat };
  }

  export function isClaimed(state: State): boolean {
    return isValidBand(state.age_band);
  }

  // Friends, invites, matches with friends and chat: only when this is true (spec §17.2).
  export function canPlayOnline(state: State): boolean {
    if (!ageRules) {
      return isClaimed(state);
    }
    if (!isClaimed(state) || state.online_allowed !== true) {
      return false;
    }
    return state.age_band === TEEN_PLUS || state.consent === CONSENT_VERIFIED;
  }

  // The chat this account may use now: off when it can't play online, never above quick for under_13.
  export function chatLevel(state: State): string {
    if (!ageRules) {
      return isClaimed(state) ? CHAT_FILTERED : CHAT_OFF;
    }
    if (!canPlayOnline(state) || !isChat(state.chat) || state.chat === CHAT_OFF) {
      return CHAT_OFF;
    }
    if (state.age_band !== TEEN_PLUS) {
      return CHAT_QUICK;
    }
    return state.chat;
  }

  // Claiming a username: the first claim sets the band's defaults. Afterwards the band changes only
  // through the parent's settings, so a later claim (a new name) keeps the account's state.
  export function onClaim(state: State, band: unknown): { state?: State; error?: string } {
    if (isClaimed(state)) {
      return { state: toMetadata(state) };
    }
    if (!isValidBand(band)) {
      return { error: "bad_age_band" };
    }
    return { state: defaults(band as string) };
  }

  // The parent's settings (behind the parent gate on the phone): online play on/off, chat level,
  // the age band. A band change starts from that band's defaults; consent is kept either way.
  // M4 Task 10 review: the band only ever gets stricter here (13_plus -> under_13: the store's age signal
  // on the phone). The server can't see the phone's parent gate and the game never asks for an older
  // band, so lifting an under_13 account to 13_plus (free text, friends without a grown-up, no consent)
  // is refused ("age_band_locked"); the owner changes it in the console on a parent's request.
  export function applyParentSettings(state: State, request: Util.Json): { state?: State; error?: string } {
    if (!isClaimed(state)) {
      return { error: "not_claimed" };
    }
    if (Util.has(request, "age_band") && !isValidBand(request.age_band)) {
      return { error: "bad_request" };
    }
    if (ageRules && Util.has(request, "age_band") && request.age_band === TEEN_PLUS && state.age_band !== TEEN_PLUS) {
      return { error: "age_band_locked" };
    }
    if (Util.has(request, "online_allowed") && typeof request.online_allowed !== "boolean") {
      return { error: "bad_request" };
    }
    if (Util.has(request, "chat") && !isChat(request.chat)) {
      return { error: "bad_request" };
    }
    let next = toMetadata(state);
    if (Util.has(request, "age_band") && request.age_band !== state.age_band) {
      next = defaults(request.age_band);
      next.consent = state.consent;
    }
    if (Util.has(request, "online_allowed")) {
      next.online_allowed = request.online_allowed;
    }
    if (Util.has(request, "chat")) {
      next.chat = request.chat;
    }
    if (next.age_band === UNDER_13) {
      if (next.online_allowed && next.consent !== CONSENT_VERIFIED) {
        return { error: "consent_needed" };
      }
      if (next.chat === CHAT_FILTERED) {
        return { error: "chat_not_allowed" };
      }
    }
    return { state: next };
  }
}
