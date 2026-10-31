// Server-side codes, the Gold Farm clock and the Survivor gold wallet (spec §5.6, §5.11, §7.4,
// §17.6; plan M4 Task 8). Gold lives in the Nakama wallet (key "survivor_gold") with a ledger entry
// for every change: {"source": "code" | "farm" | "award", ...}.

namespace Economy {
  export function sha256(nk: nkruntime.Nakama): (text: string) => string {
    return function (text: string): string {
      return nk.sha256Hash(text);
    };
  }

  export function balance(nk: nkruntime.Nakama, userId: string): number {
    return Accounts.load(nk, userId).gold;
  }

  // Adds gold (capped at the wallet's maximum) with a ledger entry; returns what was added and the
  // balance after it. A negative amount spends and fails when there isn't enough.
  export function addGold(nk: nkruntime.Nakama, userId: string, amount: number, ledger: Util.Json): { added: number; gold: number } {
    const now = balance(nk, userId);
    const add = amount > 0 ? WalletRules.capAdd(now, amount) : amount;
    if (add === 0) {
      return { added: 0, gold: now };
    }
    const changes: { [key: string]: number } = {};
    changes[WalletRules.KEY] = add;
    const result = nk.walletUpdate(userId, changes, ledger, true);
    const updated: Util.Json = result && Util.isObject(result.updated) ? result.updated : {};
    return { added: add, gold: Util.isInt(updated[WalletRules.KEY]) ? updated[WalletRules.KEY] : now + add };
  }

  // Whose gold a wallet call is about (M4 Wave 2, agent F): the caller's own, or, with "user_id" and
  // "match_id", a player in the relayed match the caller hosts (the host's game decides gold in its
  // world, spec §7.3; the server keeps each player's balance and limits). `late` (0.2.19, a wallet_award with a
  // seq): also a player who has left the match, or after the host left it, while the caller's hosting record names
  // the match and the server saw the player there (WalletRules.lateAllowed). `present`: the player is in it now.
  export function target(nk: nkruntime.Nakama, callerId: string, request: Util.Json, late: boolean = false):
      { userId?: string; error?: string; matchId?: string; present?: boolean } {
    if (!Util.has(request, "user_id") || request.user_id === callerId) {
      return { userId: callerId };
    }
    const subject = InviteRules.matchSubject(request.match_id);
    if (!Social.isUuid(request.user_id) || subject === null) {
      return { error: "bad_request" };
    }
    const matchId = subject + ".";
    const hosting = Social.hostings(nk, [callerId]).records[callerId];
    const present = Social.matchUserIds(nk, subject);
    const hostsIt = !!hosting && hosting.match_id === matchId && hosting.host_id === callerId;
    if (hostsIt && present.indexOf(callerId) >= 0 && present.indexOf(request.user_id) >= 0) {
      return { userId: request.user_id, matchId: matchId, present: true };
    }
    if (late && hostsIt && WalletRules.lateAllowed(hostedOf(nk, request.user_id).record, matchId, callerId, Server.nowMs())) {
      return { userId: request.user_id, matchId: matchId, present: false };
    }
    if (!hostsIt || present.indexOf(callerId) < 0) {
      return { error: "not_host" };
    }
    return { error: "not_in_match" };
  }

  // 0.2.19: the last match the server saw a player in, its host, and the highest seq that host reported for it.
  export const HOSTED_KEY = "wallet_hosted";

  export function hostedOf(nk: nkruntime.Nakama, userId: string): { found: Store.Found | null; record: WalletRules.Hosted | null } {
    const found = Store.read(nk, Store.LIMITS, HOSTED_KEY, userId);
    return { found: found, record: found ? WalletRules.hostedFrom(found.value) : null };
  }

  // Notes that the host read the player's gold (seq 0) or reported a seq for it (WalletRules.hostedNext), by
  // version. Never fails the call it is part of (the gold has moved already): a write that can't be made is logged.
  export function noteHosted(nk: nkruntime.Nakama, logger: nkruntime.Logger, userId: string, matchId: string,
      hostId: string, seq: number, present: boolean): void {
    try {
      for (let attempt = 0; attempt < 3; attempt++) {
        const h = hostedOf(nk, userId);
        const next = WalletRules.hostedNext(h.record, matchId, hostId, seq, present, Server.nowMs());
        try {
          Store.write(nk, Store.LIMITS, HOSTED_KEY, userId, next as unknown as Util.Json, false, h.found ? h.found.version : "*");
          return;
        } catch (e) {
          if (!Social.isVersionClash(e)) {
            throw e;
          }
        }
      }
    } catch (e) {
      logger.warn("wallet_hosted for %s not written: %s", userId, Server.errorText(e));
    }
  }

  // get_account_state's "hosted": {"match_id", "seq"} of the player's last online match, or null.
  export function hostedReply(nk: nkruntime.Nakama, userId: string): Util.Json | null {
    const r = hostedOf(nk, userId).record;
    return r ? { match_id: r.match_id, seq: r.seq } : null;
  }

  // The player's farm clocks, counted up to FarmRules.MAX_FARMS (one page: more is "full" all the same).
  export function farmCount(nk: nkruntime.Nakama, userId: string): number {
    const list = nk.storageList(userId, Store.FARM, FarmRules.MAX_FARMS);
    return list && list.objects ? list.objects.length : 0;
  }

  // Codes used offline (redeem_code {"hashes"}): added to the redeemed list by version, never paid.
  export function recordOffline(nk: nkruntime.Nakama, userId: string, hashes: unknown): Util.Json {
    if (!(hashes instanceof Array) || hashes.length > CodeRules.MAX_RECORD) {
      return Server.fail("bad_request");
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      const found = Store.read(nk, Store.CODES, "redeemed", userId);
      const before = CodeRules.redeemedFrom(found ? found.value : undefined);
      const paid = CodeRules.paidFrom(found ? found.value : undefined);
      const r = CodeRules.record({ redeemed: before, tries: CodeRules.emptyTries() }, hashes);
      if (r.recorded > 0) {
        try {
          Store.write(nk, Store.CODES, "redeemed", userId, { hashes: r.redeemed, paid: paid }, true, found ? found.version : "*");
        } catch (e) {
          if (Social.isVersionClash(e)) {
            continue;
          }
          throw e;
        }
      }
      // 0.2.19: which of them the server had paid itself (a phone whose answer was lost paid it too): the phone then
      // counts that gold as the server's, never its own (the gold-double bug's leftover).
      return { ok: true, status: "recorded", recorded: r.recorded, already: r.already, gold: balance(nk, userId),
        paid: CodeRules.paidList(paid, hashes) };
    }
    return Server.fail("busy");
  }
}

// redeem_code {"code"}: {"ok": true, "status": "accepted", "reward", "gold"} or {"ok": false,
// "error": "unknown" | "already_used" | "locked" (+ "wait" seconds) | "empty"}. 0.2.19: "already_used" for a gold
// code the server paid itself also says "paid": {"gold", "at_ms"} (a phone whose answer was lost asks again: the
// server holds that gold; the phone must never pay it itself or report it).
// redeem_code {"hashes": [...]} (M4 Wave 2, agent F): codes the game redeemed offline, recorded so
// they can't pay again here; nothing is paid: {"ok": true, "status": "recorded", "recorded", "already", "gold",
// "paid" (0.2.19: [{"hash", "gold", "at_ms"}] of those the server had paid itself)}.
function rpcRedeemCode(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "redeem_code", payload, function (userId: string, request: Util.Json): Util.Json {
    if (Util.has(request, "hashes")) {
      return Economy.recordOffline(nk, userId, request.hashes);
    }
    if (typeof request.code !== "string") {
      return Server.fail("bad_request");
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      const found = nk.storageRead([
        { collection: Store.CODES, key: "redeemed", userId: userId },
        { collection: Store.CODES, key: "tries", userId: userId },
      ]);
      let redeemedValue: unknown;
      let redeemedVersion = "*";
      let triesValue: unknown;
      for (let i = 0; i < found.length; i++) {
        if (found[i].key === "redeemed") {
          redeemedValue = found[i].value;
          redeemedVersion = found[i].version;
        } else {
          triesValue = found[i].value;
        }
      }
      const before: CodeRules.State = { redeemed: CodeRules.redeemedFrom(redeemedValue), tries: CodeRules.triesFrom(triesValue) };
      const paid = CodeRules.paidFrom(redeemedValue);
      const r = CodeRules.redeem(before, request.code, Server.nowMs(), Economy.sha256(nk));
      if (r.status === "accepted") {
        const reward = r.reward as CodeRules.Reward;
        if (reward.kind === CodeRules.KIND_GOLD) {
          paid[r.hash as string] = { gold: reward.amount as number, at_ms: Server.nowMs() };
        }
        try {
          // First the list (by version: a second redemption at the same moment fails here), then the gold.
          Store.write(nk, Store.CODES, "redeemed", userId, { hashes: r.redeemed, paid: paid }, true, redeemedVersion);
        } catch (e) {
          if (Social.isVersionClash(e)) {
            continue;
          }
          throw e;
        }
      }
      if (r.tries.wrong !== before.tries.wrong || r.tries.locked_until !== before.tries.locked_until) {
        Store.write(nk, Store.CODES, "tries", userId, r.tries, true);
      }
      if (r.status === "already_used" && r.hash !== undefined && Util.has(paid, r.hash)) {
        return Server.fail("already_used", { paid: { gold: paid[r.hash].gold, at_ms: paid[r.hash].at_ms } });
      }
      if (r.status !== "accepted") {
        return r.status === "locked" ? Server.fail("locked", { wait: r.wait }) : Server.fail(r.status);
      }
      const reward = r.reward as CodeRules.Reward;
      let gold = Economy.balance(nk, userId);
      if (reward.kind === CodeRules.KIND_GOLD) {
        gold = Economy.addGold(nk, userId, reward.amount as number, { source: "code", code_hash: r.redeemed[r.redeemed.length - 1] }).gold;
      }
      logger.info("code redeemed by %s", userId);
      return { ok: true, status: "accepted", reward: reward, gold: gold };
    }
    return Server.fail("busy");
  });
}

// farm_collect {"action": "start" | "peek" | "collect", "world", ...}: "start" when the player
// leaves inside their farm ({"rate_per_hour", "universe"?, "cap_hours"?}), "peek" to show what it
// made so far, "collect" to pay it into the wallet. Times are the server's only. At most
// FarmRules.MAX_FARMS clocks per player (0.2.10: a new world's start over it is too_many_farms).
function rpcFarmCollect(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "farm_collect", payload, function (userId: string, request: Util.Json): Util.Json {
    const now = Server.nowMs();
    if (!FarmRules.isWorld(request.world)) {
      return Server.fail("bad_request");
    }
    const world = request.world as string;
    if (request.action === "start") {
      const started = FarmRules.start(request, now);
      if (!started.farm) {
        return Server.fail(started.error || "bad_request");
      }
      const refusal = FarmRules.startRefusal(Store.read(nk, Store.FARM, world, userId) !== null, Economy.farmCount(nk, userId));
      if (refusal !== null) {
        return Server.fail(refusal);
      }
      Store.write(nk, Store.FARM, world, userId, started.farm, true);
      return {
        ok: true, started_ms: started.farm.started_ms, rate_per_hour: started.farm.rate_per_hour,
        universe: started.farm.universe, cap_hours: started.farm.cap_hours,
      };
    }
    if (request.action !== "peek" && request.action !== "collect") {
      return Server.fail("bad_request");
    }
    const found = Store.read(nk, Store.FARM, world, userId);
    const farm = found ? FarmRules.farmFrom(found.value) : null;
    if (farm === null) {
      return Server.fail("not_started");
    }
    const e = FarmRules.earned(farm, now);
    if (request.action === "peek") {
      return { ok: true, earned: e.earned, away_ms: e.away_ms, capped: e.capped };
    }
    // Deleting first (by version) means a second collect at the same moment finds nothing to pay.
    try {
      nk.storageDelete([{ collection: Store.FARM, key: world, userId: userId, version: found!.version }]);
    } catch (err) {
      if (Social.isVersionClash(err)) {
        return Server.fail("not_started");
      }
      throw err;
    }
    const paid = Economy.addGold(nk, userId, e.earned, { source: "farm", world: world, away_ms: e.away_ms });
    return { ok: true, earned: paid.added, away_ms: e.away_ms, capped: e.capped, gold: paid.gold };
  });
}

// wallet_award {"amount", "reason"?, "universe"?, "user_id"?, "match_id"?}: the host's game reports
// Survivor gold it gave a player (or, negative, what they spent): its own, or (M4 Wave 2, agent F)
// a guest's in the relayed match it hosts. Limited per award and per hour, per player (WalletRules);
// a guest's spends the host reports have their own hourly limit (0.2.10: spend_limit).
// 0.2.19 (the gold-double bug's leftover): "seq" (1, 2, 3, ...: the host's count of the gold moves it told that guest),
// sent with the last piece of each batch for a guest. The server keeps the highest one (limits/wallet_hosted, also
// when the rules refuse the piece: the host never sends it again) and answers it back; amount 0 with a seq is a
// report of the seq alone (a batch that netted to nothing). With a seq a batch is also taken after the guest left
// the match or the host closed it (Economy.target's `late`). A report without a seq is answered as before.
function rpcWalletAward(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "wallet_award", payload, function (callerId: string, request: Util.Json): Util.Json {
    const hasSeq = Util.has(request, "seq");
    if (hasSeq && !WalletRules.isSeq(request.seq)) {
      return Server.fail("bad_request");
    }
    const who = Economy.target(nk, callerId, request, hasSeq);
    if (!who.userId) {
      return Server.fail(who.error || "bad_request");
    }
    const answer = hasSeq && request.amount === 0
      ? { ok: true, credited: 0, capped: false, gold: Economy.balance(nk, who.userId) }
      : walletAward(nk, callerId, who.userId, request);
    if (hasSeq && who.userId !== callerId) {
      Economy.noteHosted(nk, logger, who.userId, who.matchId as string, callerId, request.seq, who.present === true);
    }
    if (hasSeq && answer.ok) {
      answer.seq = request.seq;
    }
    return answer;
  });
}

// wallet_award's gold for `userId` (the caller or a guest Economy.target allowed): the answer.
function walletAward(nk: nkruntime.Nakama, callerId: string, userId: string, request: Util.Json): Util.Json {
  const now = Server.nowMs();
  const found = Store.read(nk, Store.LIMITS, "wallet_award", userId);
  const step = WalletRules.award(WalletRules.windowFrom(found ? found.value : undefined), request.amount, request.universe, now);
  if (step.error) {
    return Server.fail(step.error);
  }
  const reason = WalletRules.reason(request.reason);
  if (step.credit < 0) {
    // M4 Task 10 review C: another player's spends for this player are limited per hour.
    const byOther = userId !== callerId;
    const spentBefore = byOther ? Store.read(nk, Store.LIMITS, "wallet_spent", userId) : null;
    const counted = byOther
      ? WalletRules.spend(WalletRules.windowFrom(spentBefore ? spentBefore.value : undefined), step.credit, request.universe, now)
      : null;
    if (counted !== null && counted.error) {
      return Server.fail(counted.error);
    }
    const have = Economy.balance(nk, userId);
    if (have + step.credit < 0) {
      return Server.fail("not_enough_gold", { gold: have });
    }
    if (counted !== null) {
      Store.write(nk, Store.LIMITS, "wallet_spent", userId, counted.window, false);
    }
    const spent = Economy.addGold(nk, userId, step.credit, { source: "award", reason: reason, by: callerId });
    return { ok: true, credited: spent.added, capped: false, gold: spent.gold };
  }
  Store.write(nk, Store.LIMITS, "wallet_award", userId, step.window, false);
  const paid = Economy.addGold(nk, userId, step.credit, { source: "award", reason: reason, by: callerId });
  return { ok: true, credited: paid.added, capped: step.capped || paid.added < step.credit, gold: paid.gold };
}

// get_gold_of {"user_id"?, "match_id"?} (M4 Wave 2, agent F): a player's Survivor gold on the server:
// the caller's own, or a guest's in the relayed match the caller hosts (the host starts a guest's
// wallet from this, never from the guest's own word). {"ok", "user_id", "gold"}; not_host, not_in_match.
// 0.2.19: the server notes it saw the guest in this host's match (limits/wallet_hosted; a late batch needs it).
function rpcGetGoldOf(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "get_gold_of", payload, function (callerId: string, request: Util.Json): Util.Json {
    const who = Economy.target(nk, callerId, request);
    if (!who.userId) {
      return Server.fail(who.error || "bad_request");
    }
    if (who.userId !== callerId) {
      Economy.noteHosted(nk, logger, who.userId, who.matchId as string, callerId, 0, true);
    }
    return { ok: true, user_id: who.userId, gold: Economy.balance(nk, who.userId) };
  });
}
