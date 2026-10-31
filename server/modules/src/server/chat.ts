// Chat on Nakama channels (spec §5.13, §17.4): friends' direct messages and a match's team room,
// nothing else (no public rooms, no groups). A message is {"text": ...} or {"emote": ...}; its
// channel's chat level is the strictest of its players' (AccountRules.chatLevel): "off" refuses,
// "quick" allows the quick phrases and emotes only (an under_13 player is there), "filtered" runs
// the chat filter. The game's host still checks in-game chat itself (ChatRules on the host).

namespace Chat {
  export const TYPE_ROOM = 1;
  export const TYPE_DM = 2;

  // The chat levels of the players who would read a message on this channel (the sender too).
  export function channelLevels(nk: nkruntime.Nakama, userId: string, channelId: unknown): string[] {
    const parts = typeof channelId === "string" ? channelId.split(".") : [];
    let ids: string[];
    if (parts[0] === "4" && parts.length >= 3) {
      ids = [parts[1], parts[2]]; // a direct message: "4.<user one>.<user two>."
      if (ids.indexOf(userId) < 0) {
        Server.refuse("not_in_channel", Server.PERMISSION_DENIED);
      }
      // M4 Task 10 review: Nakama checks friendship only when a DM is joined; an unfriended or blocked
      // player who stayed in the channel sends nothing more.
      if (!Social.areFriends(nk, userId, ids[0] === userId ? ids[1] : ids[0])) {
        Server.refuse("not_friends", Server.PERMISSION_DENIED);
      }
    } else if (parts[0] === "2" && parts.length >= 4) {
      const label = parts.slice(3).join("."); // a room: "2...<name>", named after its match
      // M4 Task 10 review: only a player in that match now (the join checked it once; a player who left or
      // was dropped, and may not come back, stays out of the team's chat).
      const subject = InviteRules.matchSubject(label);
      if (subject === null || Social.matchUserIds(nk, subject).indexOf(userId) < 0) {
        Server.refuse("room_not_allowed", Server.PERMISSION_DENIED);
      }
      ids = Social.withId(Social.roomUserIds(nk, label), userId);
    } else {
      return Server.refuse("not_available", Server.PERMISSION_DENIED);
    }
    const states = Accounts.states(nk, ids);
    const levels: string[] = [];
    for (let i = 0; i < ids.length; i++) {
      levels.push(states[ids[i]] ? AccountRules.chatLevel(states[ids[i]]) : AccountRules.CHAT_OFF);
    }
    return levels;
  }

  // The content to send instead of `raw` (cleaned), or a refusal.
  export function checked(nk: nkruntime.Nakama, userId: string, channelId: unknown, raw: unknown): string {
    const content = ChatRules.parseContent(raw);
    if (content === null) {
      Server.refuse("bad_message", Server.INVALID_ARGUMENT);
    }
    const result = ChatRules.checkContent(content as ChatRules.Content, ChatRules.strictest(channelLevels(nk, userId, channelId)));
    if (result.error) {
      Server.refuse(result.error, result.error === "chat_off" ? Server.PERMISSION_DENIED : Server.INVALID_ARGUMENT);
    }
    return JSON.stringify(result.content);
  }

  // M4 Wave 2, agent E: removes a kept channel's messages older than 30 days (oldest first, a batch
  // at a time, each time the DM opens). A failure is logged and never stops the join.
  export function purgeExpired(nk: nkruntime.Nakama, logger: nkruntime.Logger, channelId: string): number {
    let removed = 0;
    try {
      const list = nk.channelMessagesList(channelId, ChatRules.PURGE_BATCH, true);
      const messages = list && list.messages ? list.messages : [];
      const now = Server.nowMs();
      for (let i = 0; i < messages.length; i++) {
        const m = messages[i];
        if (!ChatRules.isExpired(ChatRules.createSeconds(m.createTime), now)) {
          break; // oldest first: the rest are newer
        }
        nk.channelMessageRemove(channelId, m.messageId || "", m.senderId, m.username, true);
        removed++;
      }
    } catch (e) {
      logger.warn("chat history cleanup failed for %s: %s", channelId, Server.errorText(e));
    }
    return removed;
  }
}

// Joining a channel: a friend's DM (both may chat) or the team room of a match the player is in.
// History (agent E, §17.2): kept only for a DM between two players at the text level (never with an
// under_13 player, never in a team room), whatever the game asked; opening it clears what is older
// than 30 days.
function rtBeforeChannelJoin(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    envelope: nkruntime.EnvelopeChannelJoin): nkruntime.EnvelopeChannelJoin {
  const join: Util.Json = Util.isObject(envelope.channelJoin) ? envelope.channelJoin : {};
  const userId = ctx.userId || "";
  const myLevel = userId ? AccountRules.chatLevel(Accounts.load(nk, userId).state) : AccountRules.CHAT_OFF;
  if (!userId || myLevel === AccountRules.CHAT_OFF) {
    Server.refuse("chat_off", Server.PERMISSION_DENIED);
  }
  if (join.type === Chat.TYPE_DM) {
    const other = Social.findById(nk, join.target);
    if (other === null || !Social.areFriends(nk, userId, other.userId)) {
      Server.refuse("not_friends", Server.PERMISSION_DENIED);
    }
    if (AccountRules.chatLevel(other!.state) === AccountRules.CHAT_OFF) {
      Server.refuse("chat_off", Server.PERMISSION_DENIED);
    }
    join.persistence = join.persistence === true &&
      ChatRules.keepsHistory(Chat.TYPE_DM, [myLevel, AccountRules.chatLevel(other!.state)]);
    if (join.persistence) {
      Chat.purgeExpired(nk, logger, nk.channelIdBuild(userId, other!.userId, Chat.TYPE_DM as nkruntime.ChanType));
    }
  } else if (join.type === Chat.TYPE_ROOM) {
    const subject = InviteRules.matchSubject(join.target);
    if (subject === null || Social.matchUserIds(nk, subject).indexOf(userId) < 0) {
      Server.refuse("room_not_allowed", Server.PERMISSION_DENIED);
    }
    join.persistence = false; // team rooms keep nothing
  } else {
    Server.refuse("not_available", Server.PERMISSION_DENIED);
  }
  return envelope;
}

function rtBeforeChannelMessageSend(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    envelope: nkruntime.EnvelopeChannelMessageSend): nkruntime.EnvelopeChannelMessageSend {
  const send = envelope.channelMessageSend;
  send.content = Chat.checked(nk, ctx.userId || "", send.channelId, send.content);
  return envelope;
}

function rtBeforeChannelMessageUpdate(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    envelope: nkruntime.EnvelopeChannelMessageUpdate): nkruntime.EnvelopeChannelMessageUpdate {
  const update = envelope.channelMessageUpdate;
  update.content = Chat.checked(nk, ctx.userId || "", update.channelId, update.content);
  return envelope;
}
