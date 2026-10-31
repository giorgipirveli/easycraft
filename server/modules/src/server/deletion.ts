// Deleting an online account (spec §5.14, §17.2; M4 Task 8b, agent G): delete_account, the same
// deletion for the retention clean-up's inactive accounts, and Nakama's own client DeleteAccount
// refused (it would skip the clean-up below). Order: everything that names the player elsewhere
// first, their own storage, then Nakama's deletion last (its database cascade also removes their
// devices, wallet and ledger, friend edges, notifications to them and messages they sent, and it
// logs them out and closes their sockets: they leave every match and channel). A failure part way
// leaves the account in place, so the same request can run again.

namespace Deletion {
  export const COLLECTIONS = [Store.PROFILES, Store.PARENT, Store.CODES, Store.FARM, Store.INVITES, Store.LIMITS, Store.ACTIVITY,
    Store.ACCOUNT] // owner #67: the sign-in key
    .concat(Gifts.OWN_COLLECTIONS) // M4 I: gifts, bottles, showcases, guestbook
    .concat(Ghosts.OWN_COLLECTIONS) // M4 ghosts: a showcase's ghosts (a gift's go with the gift)
    .concat(Referrals.OWN_COLLECTIONS) // 0.2.16: the invite record (its codes, groups and links: Referrals.forget)
    .concat(Together.OWN_COLLECTIONS); // 0.2.18: friendships, presents, moments, buddies (Together.forget); crews
  // Children whose requests waiting for a grown-up name this player (parent/friend_requests).
  export const SQL_HELD = "SELECT user_id::text AS id FROM storage WHERE collection = 'parent' AND key = 'friend_requests' " +
    "AND value -> 'requests' @> $1::jsonb";
  // Notifications this player sent (invites name them); Nakama's cascade removes only those to them.
  export const SQL_NOTES_FROM = "DELETE FROM notification WHERE sender_id = $1::uuid";
  // Every DM with this player, both sides: nobody can open it any more (stream mode 4 = a DM).
  export const SQL_DMS_OF = "DELETE FROM message WHERE stream_mode = 4 AND (stream_subject = $1::uuid OR stream_descriptor = $1::uuid)";
  export const SQL_REPORTS_BY = "SELECT key FROM storage WHERE collection = 'reports' " +
    "AND user_id = '00000000-0000-0000-0000-000000000000'::uuid AND value ->> 'reporter_id' = $1";
  const PAGE = 100;
  const MAX_PAGES = 100;

  export interface Summary {
    friends: number;
    held: number;
    notifications: number;
    messages: number;
    reports_anonymised: number;
    objects: number;
    gifts_sent: number; // M4 I: gifts and bottles it sent, still unopened in friends' inboxes
    stickers_left: number; // M4 I: its stickers in friends' guestbooks
    invites: number; // 0.2.16: its invite codes and groups, its place in others' groups and lists, its friends' links
    together: number; // 0.2.18: friends' records that named it (days together, buddies, presents, moments, news), its crew
  }

  export function run(nk: nkruntime.Nakama, logger: nkruntime.Logger, userId: string, why: string): Summary {
    const username = nk.accountGetId(userId).user.username;
    const together = Together.forget(nk, userId); // 0.2.18: first, while its friend edges still find who heard its moments
    const s: Summary = {
      friends: removeFriends(nk, userId, username),
      held: clearHeld(nk, userId),
      notifications: nk.sqlExec(SQL_NOTES_FROM, [userId]).rowsAffected,
      messages: nk.sqlExec(SQL_DMS_OF, [userId]).rowsAffected,
      reports_anonymised: anonymiseReportsBy(nk, userId),
      invites: Referrals.forget(nk, userId), // before its own storage goes: it reads the player's invite record
      objects: removeStorage(nk, userId),
      gifts_sent: Gifts.forgetSent(nk, userId),
      stickers_left: Gifts.forgetStickers(nk, userId),
      together: together,
    };
    // Owner #105 (the second review's HIGH): remember a CLAIMED account's device ids as removed, so a guest device that
    // rejoins after the account is gone (create=true) never makes a new empty account and re-claims the freed name.
    // The third review's N2: a never-claimed account (an unclaimed asking account cleaned up after 13 months, which has
    // no name to re-claim and whose id the honest client reuses to ask) is NEVER tombstoned, so LOG IN keeps working.
    if (Accounts.load(nk, userId).state.claimed) {
      const deletedAt = Server.nowMs();
      const ids = Keys.deviceIds(nk, userId);
      for (let i = 0; i < ids.length; i++) {
        Keys.recordRemoved(nk, ids[i], deletedAt);
      }
    }
    nk.accountDeleteId(userId, true); // recorded: Nakama keeps a tombstone of the id, nothing else
    logger.info("account deleted: %s (%s)", userId, why);
    return s;
  }

  // Every friend edge (friends, requests both ways, blocks) goes from both players' lists.
  function removeFriends(nk: nkruntime.Nakama, userId: string, username: string): number {
    const ids: string[] = [];
    let cursor: string | undefined = undefined;
    for (let page = 0; page < MAX_PAGES; page++) {
      const list = nk.friendsList(userId, PAGE, undefined, cursor);
      const friends = list.friends || [];
      for (let i = 0; i < friends.length; i++) {
        const u = friends[i].user;
        if (u && ids.indexOf(u.userId) < 0) {
          ids.push(u.userId);
        }
      }
      if (!list.cursor) {
        break;
      }
      cursor = list.cursor;
    }
    for (let i = 0; i < ids.length; i += PAGE) {
      nk.friendsDelete(userId, username, ids.slice(i, i + PAGE), []);
    }
    return ids.length;
  }

  // Requests waiting for a grown-up in other children's accounts that name this player (id and name).
  function clearHeld(nk: nkruntime.Nakama, userId: string): number {
    const rows = nk.sqlQuery(SQL_HELD, [JSON.stringify([{ user_id: userId }])]);
    let cleared = 0;
    for (let i = 0; i < rows.length; i++) {
      const childId = String(rows[i].id);
      for (let attempt = 0; attempt < 3; attempt++) {
        const h = Parents.held(nk, childId);
        try {
          Parents.save(nk, childId, FriendApprovals.remove(h.list, userId), h.version);
          cleared++;
          break;
        } catch (e) {
          if (!Social.isVersionClash(e)) {
            throw e;
          }
        }
      }
    }
    return cleared;
  }

  function anonymiseReportsBy(nk: nkruntime.Nakama, userId: string): number {
    const rows = nk.sqlQuery(SQL_REPORTS_BY, [userId]);
    let done = 0;
    for (let i = 0; i < rows.length; i++) {
      if (anonymiseReport(nk, String(rows[i].key), userId)) {
        done++;
      }
    }
    return done;
  }

  // Rewrites one report without its reporter under a new key (the old key named them), keeping its
  // review time (RetentionRules: the console's save counts as the review until it is written in).
  // `reporterId`: only a report by this player ("" = whoever made it: the retention clean-up's
  // reports whose reporter no longer exists).
  export function anonymiseReport(nk: nkruntime.Nakama, key: string, reporterId: string): boolean {
    const found = nk.storageRead([{ collection: Store.REPORTS, key: key, userId: Store.SYSTEM_USER }]);
    if (!found || found.length === 0 || !Util.isObject(found[0].value)) {
      return false;
    }
    const old = found[0];
    const value = old.value as Util.Json;
    if (reporterId !== "" ? !DeletionRules.madeBy(value, reporterId) : value.reporter_id === "") {
      return false;
    }
    const now = Server.nowMs();
    const anon = DeletionRules.anonymised(value, now);
    const step = RetentionRules.reportStep(value, RetentionRules.timeMs(old.updateTime), now);
    if (step.reviewed_ms !== undefined) {
      anon.reviewed_ms = step.reviewed_ms;
    }
    const created = Util.isInt(value.created_ms) ? value.created_ms : now;
    Store.write(nk, Store.REPORTS, DeletionRules.anonymousKey(created, nk.uuidv4()), Store.SYSTEM_USER, anon, false, "*");
    nk.storageDelete([{ collection: Store.REPORTS, key: key, userId: Store.SYSTEM_USER, version: old.version }]);
    return true;
  }

  // Every object the player owns in every collection the server uses.
  function removeStorage(nk: nkruntime.Nakama, userId: string): number {
    let removed = 0;
    for (let c = 0; c < COLLECTIONS.length; c++) {
      for (let page = 0; page < MAX_PAGES; page++) {
        const list = nk.storageList(userId, COLLECTIONS[c], PAGE);
        const objects = list && list.objects ? list.objects : [];
        if (objects.length === 0) {
          break;
        }
        const ids: nkruntime.StorageDeleteRequest[] = [];
        for (let i = 0; i < objects.length; i++) {
          ids.push({ collection: objects[i].collection, key: objects[i].key, userId: userId });
        }
        nk.storageDelete(ids);
        removed += ids.length;
      }
    }
    return removed;
  }
}

// delete_account (M4 Task 8b, agent G). A signed-in player: {} hands out a confirmation
// {"ok", "confirm", "expires_ms", "user_id", "username"} (nothing is deleted), then {"confirm"}
// deletes: {"ok", "deleted": true, "user_id", and what went}. Errors: confirm_wrong, confirm_expired
// (ask again), not_allowed (a player naming another account). The owner, without a session (the
// runtime HTTP key, or the console's API Explorer with no user id), names the account: {"user_id"
// or "username"} and then the same with "confirm"; not_found, bad_request.
function rpcDeleteAccount(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpcOrAdmin(ctx, logger, "delete_account", payload, function (callerId: string, request: Util.Json): Util.Json {
    const names = Util.has(request, "user_id") || Util.has(request, "username");
    let userId = callerId;
    if (callerId === "") {
      if (!names) {
        return Server.fail("bad_request");
      }
      const target = Social.find(nk, request);
      if (target === null) {
        return Server.fail("not_found");
      }
      userId = target.userId;
    } else if (names) {
      const named = Social.find(nk, request);
      if (named === null || named.userId !== callerId) {
        return Server.fail("not_allowed");
      }
    }
    const now = Server.nowMs();
    if (!Util.has(request, "confirm")) {
      const c = DeletionRules.newConfirm(nk.uuidv4(), now);
      Store.write(nk, Store.LIMITS, DeletionRules.CONFIRM_KEY, userId, c, false);
      return { ok: true, confirm: c.token, expires_ms: c.expires_ms, user_id: userId, username: Accounts.load(nk, userId).username };
    }
    const found = Store.read(nk, Store.LIMITS, DeletionRules.CONFIRM_KEY, userId);
    const problem = DeletionRules.check(found ? DeletionRules.confirmFrom(found.value) : null, request.confirm, now);
    if (problem !== "") {
      return Server.fail(problem);
    }
    // Owner #105: once the account has a password, the player's own delete needs it too (the owner's path does not)
    if (callerId !== "" && Passwords.stored(nk, userId) !== null) {
      const out: Util.Json = {};
      const why = Passwords.prove(nk, userId, request.password, undefined, now, out);
      if (why !== "") {
        return Server.fail(why, out);
      }
    }
    const s = Deletion.run(nk, logger, userId, callerId === "" ? "the owner" : "the player");
    return {
      ok: true, deleted: true, user_id: userId, friends: s.friends, held: s.held, notifications: s.notifications,
      messages: s.messages, reports_anonymised: s.reports_anonymised, objects: s.objects,
      gifts_sent: s.gifts_sent, stickers_left: s.stickers_left, invites: s.invites, together: s.together,
    };
  });
}

// Nakama's own "delete my account" from a game (DELETE /v2/account) would skip the clean-up above.
function beforeDeleteAccount(_ctx: nkruntime.Context, _logger: nkruntime.Logger, _nk: nkruntime.Nakama, _data?: void): void {
  Server.refuse("use_delete_account", Server.FAILED_PRECONDITION);
}
