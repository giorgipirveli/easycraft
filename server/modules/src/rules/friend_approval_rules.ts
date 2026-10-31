// A grown-up approves an under-13 player's friends (spec §17.2 "parent controls: approve friends";
// M4 Wave 2, agent F). An under-13 account's friend request, or its "yes" to a request that came in,
// never reaches Nakama's friends directly: the AddFriends hook keeps it in parent/friend_requests,
// and the grown-up area on the phone (behind the parent gate) approves or declines it through
// approve_friend. 13+ players add friends as before.

namespace FriendApprovals {
  export const MAX = 20; // requests kept per account; the oldest go first
  export const KEEP_MS = 30 * 24 * 60 * 60 * 1000; // a request nobody answered goes away after 30 days
  export const IN = "in"; // they asked the child; approving makes them friends
  export const OUT = "out"; // the child asked them; approving sends the request on

  export interface Request {
    user_id: string;
    username: string;
    direction: string;
    at_ms: number;
  }

  export interface List {
    requests: Request[];
  }

  export function emptyList(): List {
    return { requests: [] };
  }

  // Under-13 accounts, and accounts with no band (they get the under-13 rules, AccountRules).
  export function needsApproval(state: AccountRules.State): boolean {
    return AccountRules.effectiveBand(state.age_band) === AccountRules.UNDER_13;
  }

  function isRequest(r: unknown): boolean {
    return Util.isObject(r) && typeof r.user_id === "string" && r.user_id !== "" && r.user_id.length <= 64 &&
      typeof r.username === "string" && r.username.length <= 64 && (r.direction === IN || r.direction === OUT) &&
      Util.isInt(r.at_ms);
  }

  export function listFrom(value: unknown): List {
    const out = emptyList();
    const list = Util.isObject(value) && value.requests instanceof Array ? value.requests : [];
    for (let i = 0; i < list.length && out.requests.length < MAX; i++) {
      if (isRequest(list[i])) {
        out.requests.push({ user_id: list[i].user_id, username: list[i].username, direction: list[i].direction, at_ms: list[i].at_ms });
      }
    }
    return out;
  }

  // Requests younger than KEEP_MS.
  export function live(list: List, nowMs: number): List {
    const out = emptyList();
    for (let i = 0; i < list.requests.length; i++) {
      if (nowMs - list.requests[i].at_ms < KEEP_MS) {
        out.requests.push(list.requests[i]);
      }
    }
    return out;
  }

  export function find(list: List, userId: string): Request | null {
    for (let i = 0; i < list.requests.length; i++) {
      if (list.requests[i].user_id === userId) {
        return list.requests[i];
      }
    }
    return null;
  }

  export function remove(list: List, userId: string): List {
    const out = emptyList();
    for (let i = 0; i < list.requests.length; i++) {
      if (list.requests[i].user_id !== userId) {
        out.requests.push(list.requests[i]);
      }
    }
    return out;
  }

  // Adds (or renews) one request, newest last; at most MAX.
  export function add(list: List, request: { user_id: string; username: string; direction: string }, nowMs: number): List {
    const out = remove(list, request.user_id);
    out.requests.push({ user_id: request.user_id, username: request.username, direction: request.direction, at_ms: nowMs });
    while (out.requests.length > MAX) {
      out.requests.shift();
    }
    return out;
  }
}
