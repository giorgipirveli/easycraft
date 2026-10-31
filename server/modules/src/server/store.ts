// Storage the server owns (plan M4 Wave 1): what the collections hold and who may read them. Every
// object here is written by the server with permissionWrite 0, so a game can't change it; the
// beforeWriteStorageObjects hook (guards.ts) also stops a game from creating one first.
//
//   profiles  the game's profile backup (the only collection a game writes itself)
//   parent    "settings" (the parent's switches + a short history), "consent" (the consent request)
//   reports   one object per report, owned by the system user, read in the Nakama console
//   codes     "redeemed" (salted hashes this account used), "tries" (the wrong-code lock)
//   farm      one object per world: when the player left the Gold Farm, at what rate
//   invites   (server only) "current": the match this player hosts and whom they invited
//   limits    (server only) rate-limit windows: "report", "wallet_award"; "delete_account" (M4 G:
//             the confirmation delete_account handed out, 10 minutes)
//   activity  (server only, M4 G) "signed_in": the player's last sign-in (the 13-month rule); the
//             system user's "retention": the clean-up's once-a-day guard and its last result
//   account   (server only, owner #67) "sign_in_key": the salted hash of the key that signs another
//             device in to this account (keys.ts); the game can't read it

namespace Store {
  export const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
  export const PROFILES = "profiles";
  export const PARENT = "parent";
  export const REPORTS = "reports";
  export const CODES = "codes";
  export const FARM = "farm";
  export const INVITES = "invites";
  export const LIMITS = "limits";
  export const ACTIVITY = "activity"; // M4 G: sign-ins and the retention clean-up
  export const ACCOUNT = "account"; // owner #67: the sign-in key's hash

  export interface Found {
    value: Util.Json;
    version: string;
  }

  export function read(nk: nkruntime.Nakama, collection: string, key: string, userId: string): Found | null {
    const found = nk.storageRead([{ collection: collection, key: key, userId: userId }]);
    if (!found || found.length === 0) {
      return null;
    }
    return { value: Util.isObject(found[0].value) ? found[0].value : {}, version: found[0].version };
  }

  // Reads several objects of one collection and key, one per owner; the map has only those found.
  export function readMany(nk: nkruntime.Nakama, collection: string, key: string, userIds: string[]): { [userId: string]: Found } {
    const out: { [userId: string]: Found } = {};
    if (userIds.length === 0) {
      return out;
    }
    const keys: nkruntime.StorageReadRequest[] = [];
    for (let i = 0; i < userIds.length; i++) {
      keys.push({ collection: collection, key: key, userId: userIds[i] });
    }
    const found = nk.storageRead(keys);
    for (let i = 0; i < found.length; i++) {
      out[found[i].userId] = { value: Util.isObject(found[i].value) ? found[i].value : {}, version: found[i].version };
    }
    return out;
  }

  // Writes as the server. ownerCanRead: the owner's game may read it (permissionRead 1) or not (0).
  // version: "" or a version from read() (else Nakama refuses the write), "*" for "only if new".
  export function write(nk: nkruntime.Nakama, collection: string, key: string, userId: string, value: Util.Json,
      ownerCanRead: boolean, version?: string): void {
    const request: nkruntime.StorageWriteRequest = {
      collection: collection, key: key, userId: userId, value: value,
      permissionRead: ownerCanRead ? 1 : 0, permissionWrite: 0,
    };
    if (version) {
      request.version = version;
    }
    nk.storageWrite([request]);
  }

  export function remove(nk: nkruntime.Nakama, collection: string, key: string, userId: string): void {
    nk.storageDelete([{ collection: collection, key: key, userId: userId }]);
  }
}
