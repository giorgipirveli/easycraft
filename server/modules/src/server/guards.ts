// What a game may write to Nakama storage itself: its own profile backup (profiles/profile, private),
// nothing else. Every other collection is written by the server only (store.ts). Without this, a
// game could create parent/consent {"status": "verified"} before the server ever writes it.
// Owner #67: the profile itself is cleaned before Nakama keeps it (ProfileRules: no gold, nothing that fits
// one device only, the account's own name and band, sane size and shape).

namespace Guards {
  export const MAX_VALUE = ProfileRules.MAX_CHARS; // characters of JSON per object (a profile is a few KB; the School's progress can grow it to ~600 KB)
  const KEY_RE = /^[a-z0-9_]{1,64}$/;

  export function checkObject(collection: unknown, key: unknown): void {
    if (collection !== Store.PROFILES) {
      Server.refuse("not_allowed", Server.PERMISSION_DENIED);
    }
    if (typeof key !== "string" || !KEY_RE.test(key)) {
      Server.refuse("bad_request", Server.INVALID_ARGUMENT);
    }
    if (key !== ProfileRules.KEY) {
      Server.refuse("not_allowed", Server.PERMISSION_DENIED); // owner #67: one object, not a storage locker
    }
  }

  // The account's own name and band (read fresh: the session's name is the random one until it signs in again).
  export function account(nk: nkruntime.Nakama, userId: string): ProfileRules.Account {
    const loaded = Accounts.load(nk, userId);
    return { username: loaded.username, age_band: loaded.state.age_band };
  }
}

function beforeWriteStorageObjects(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    data: nkruntime.WriteStorageObjectsRequest): nkruntime.WriteStorageObjectsRequest {
  const objects = data.objects || [];
  for (let i = 0; i < objects.length; i++) {
    const o = objects[i];
    Guards.checkObject(o.collection, o.key);
    if (o.permissionRead === 2) {
      Server.refuse("not_allowed", Server.PERMISSION_DENIED); // profiles are private (spec §17.2)
    }
    if (typeof o.value === "string" && o.value.length > Guards.MAX_VALUE) {
      Server.refuse("too_big", Server.INVALID_ARGUMENT);
    }
    const cleaned = ProfileRules.clean(o.value, Guards.account(nk, ctx.userId || ""));
    if (cleaned.value === undefined) {
      Server.refuse(cleaned.error || "bad_profile", Server.INVALID_ARGUMENT);
    }
    o.value = cleaned.value as string;
  }
  return data;
}

function beforeDeleteStorageObjects(_ctx: nkruntime.Context, _logger: nkruntime.Logger, _nk: nkruntime.Nakama,
    data: nkruntime.DeleteStorageObjectsRequest): nkruntime.DeleteStorageObjectsRequest {
  const ids = data.objectIds || [];
  for (let i = 0; i < ids.length; i++) {
    Guards.checkObject(ids[i].collection, ids[i].key);
  }
  return data;
}
