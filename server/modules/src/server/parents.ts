// Parent controls on the server (spec §17.2; M4 Wave 2, agent F): an under-13 player's friend
// requests wait in parent/friend_requests until a grown-up approves them on the phone, behind the
// parent gate (the same trust as set_parent_settings: the server can't see the gate).

namespace Parents {
  export const KEY = "friend_requests";
  const FRIEND = 0;

  export interface Held {
    list: FriendApprovals.List;
    version: string;
  }

  export function held(nk: nkruntime.Nakama, userId: string): Held {
    const found = Store.read(nk, Store.PARENT, KEY, userId);
    return {
      list: FriendApprovals.live(FriendApprovals.listFrom(found ? found.value : undefined), Server.nowMs()),
      version: found ? found.version : "*",
    };
  }

  export function save(nk: nkruntime.Nakama, userId: string, list: FriendApprovals.List, version: string): void {
    Store.write(nk, Store.PARENT, KEY, userId, { requests: list.requests }, true, version);
  }

  // This player's friend states towards these players (Nakama: 0 friend, 1 asked, 2 asked me, 3 blocked).
  export function edgeStates(nk: nkruntime.Nakama, userId: string, otherIds: string[]): { [id: string]: number } {
    const out: { [id: string]: number } = {};
    let cursor: string | undefined = undefined;
    for (let page = 0; page < 10; page++) {
      const list = nk.friendsList(userId, 100, undefined, cursor);
      const friends = list.friends || [];
      for (let i = 0; i < friends.length; i++) {
        const u = friends[i].user;
        if (u && otherIds.indexOf(u.userId) >= 0 && typeof friends[i].state === "number") {
          out[u.userId] = friends[i].state as number;
        }
      }
      if (!list.cursor) {
        break;
      }
      cursor = list.cursor;
    }
    return out;
  }

  // The AddFriends hook for a player who needs a grown-up's yes: every player not yet a friend is
  // kept for the grown-up; the ones already friends pass (Nakama does nothing with them). True when
  // something was kept (the hook then refuses with "needs_grown_up").
  export function hold(nk: nkruntime.Nakama, userId: string, players: Social.Player[]): boolean {
    const states = edgeStates(nk, userId, players.map(function (p: Social.Player): string { return p.userId; }));
    for (let attempt = 0; attempt < 3; attempt++) {
      const h = held(nk, userId);
      let list = h.list;
      let kept = false;
      for (let i = 0; i < players.length; i++) {
        const state = states[players[i].userId];
        if (state === FRIEND) {
          continue;
        }
        list = FriendApprovals.add(list, {
          user_id: players[i].userId, username: players[i].username,
          direction: state === 2 ? FriendApprovals.IN : FriendApprovals.OUT,
        }, Server.nowMs());
        kept = true;
      }
      if (!kept) {
        return false;
      }
      try {
        save(nk, userId, list, h.version);
        return true;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    return true; // kept by the other writer, or tried three times: the child asks again
  }
}

// approve_friend {} lists the requests waiting for a grown-up: {"ok", "requests": [{"user_id",
// "username", "direction": "in" | "out", "at_ms"}]}. approve_friend {"user_id", "approve": bool}
// answers one: yes sends the child's request on ("out") or makes them friends ("in"), with
// notification 103 {"what": "friend", "user_id"}; no forgets it (and removes a request that came in).
// Errors: not_found (no such request, or the player can't be online any more: dropped),
// consent_needed (the child may not be online now), bad_request.
function rpcApproveFriend(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "approve_friend", payload, function (userId: string, request: Util.Json): Util.Json {
    const listing = !Util.has(request, "user_id") && !Util.has(request, "approve");
    if (!listing && (typeof request.user_id !== "string" || typeof request.approve !== "boolean")) {
      return Server.fail("bad_request");
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      const h = Parents.held(nk, userId);
      if (listing) {
        return { ok: true, requests: h.list.requests };
      }
      const wanted = FriendApprovals.find(h.list, request.user_id);
      if (wanted === null) {
        return Server.fail("not_found");
      }
      const me = Accounts.load(nk, userId);
      if (request.approve && !AccountRules.canPlayOnline(me.state)) {
        return Server.fail("consent_needed");
      }
      const target = request.approve ? Social.findById(nk, wanted.user_id) : null;
      const rest = FriendApprovals.remove(h.list, wanted.user_id);
      try {
        Parents.save(nk, userId, rest, h.version);
      } catch (e) {
        if (Social.isVersionClash(e)) {
          continue;
        }
        throw e;
      }
      if (!request.approve) {
        if (wanted.direction === FriendApprovals.IN) {
          nk.friendsDelete(userId, me.username, [wanted.user_id], []);
        }
        return { ok: true, requests: rest.requests };
      }
      if (target === null || !AccountRules.canPlayOnline(target.state)) {
        return Server.fail("not_found", { requests: rest.requests });
      }
      nk.friendsAdd(userId, me.username, [target.userId], [], {});
      nk.notificationSend(userId, "A grown-up said yes to a friend!", { what: "friend", user_id: target.userId },
        Notes.PARENT_APPROVED, null, true);
      logger.info("friend approved for %s", userId);
      return {
        ok: true, requests: rest.requests,
        friend: { user_id: target.userId, username: target.username, state: wanted.direction === FriendApprovals.IN ? "friend" : "asked" },
      };
    }
    return Server.fail("busy");
  });
}
