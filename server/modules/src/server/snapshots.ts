// A snapshot of a reported chat message (spec §5.14; M4 Task 8b, agent G). Team rooms and chats
// with an under-13 player keep no history, so the server remembers every message it passed on for
// an hour (ReportRules.RECENT_SECONDS) in Nakama's in-memory cache (one server; a restart forgets
// it); a kept DM is looked up in its history, only by one of its two players. report_user stores
// the snapshot inside the report, so it goes when the report goes.

namespace Snapshots {
  export const CACHE_PREFIX = "easycraft_msg:";
  const HISTORY_PAGES = 5; // 500 messages back in a kept DM (30 days of history at most)

  export function remember(nk: nkruntime.Nakama, senderId: string, channelId: string, messageId: string, content: unknown,
      nowMs: number): void {
    const record: ReportRules.Record = { s: senderId, c: channelId, content: content, at: nowMs };
    nk.localcachePut(CACHE_PREFIX + messageId, JSON.stringify(record), ReportRules.RECENT_SECONDS);
  }

  // The server's copy of a message, or null.
  export function find(nk: nkruntime.Nakama, reporterId: string, channelId: string, messageId: string): ReportRules.Record | null {
    const cached = nk.localcacheGet(CACHE_PREFIX + messageId);
    if (typeof cached === "string") {
      try {
        const r = JSON.parse(cached);
        if (Util.isObject(r) && typeof r.s === "string" && typeof r.c === "string" && Util.isInt(r.at)) {
          return { s: r.s, c: r.c, content: r.content, at: r.at };
        }
      } catch (_e) {
        // an odd cache entry is no copy
      }
    }
    const parts = channelId.split(".");
    if (parts[0] !== "4" || parts.length < 3 || (parts[1] !== reporterId && parts[2] !== reporterId)) {
      return null; // only a DM, and only one the reporter is in
    }
    let cursor: string | undefined = undefined;
    for (let page = 0; page < HISTORY_PAGES; page++) {
      const list = nk.channelMessagesList(channelId, 100, false, cursor);
      const messages = list && list.messages ? list.messages : [];
      for (let i = 0; i < messages.length; i++) {
        if (messages[i].messageId === messageId) {
          return { s: messages[i].senderId || "", c: channelId, content: messages[i].content,
            at: RetentionRules.timeMs(messages[i].createTime) };
        }
      }
      if (!list || !list.nextCursor) {
        return null;
      }
      cursor = list.nextCursor;
    }
    return null;
  }

  // The report's "message": the server's copy of that message from that player on that channel, else
  // the reporter's copy (ReportRules.snapshot), else null.
  export function of(nk: nkruntime.Nakama, reporterId: string, reportedId: string, channelId: string, messageId: string,
      shown: unknown, nowMs: number): Util.Json | null {
    let record = find(nk, reporterId, channelId, messageId);
    if (record !== null && (record.s !== reportedId || (channelId !== "" && record.c !== channelId))) {
      record = null;
    }
    return ReportRules.snapshot(record, ReportRules.shownMessage(shown, nowMs));
  }
}

// After a chat message went out (the before hook checked and cleaned it): remember it for an hour,
// for a report about it. Never breaks chat.
function rtAfterChannelMessageSend(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    output: nkruntime.EnvelopeChannelMessageSend | null, input: nkruntime.EnvelopeChannelMessageSend): void {
  try {
    const out = output as unknown as Util.Json | null;
    const ack: Util.Json | null = out && Util.isObject(out.channelMessageAck) ? out.channelMessageAck : null;
    const inp = input as unknown as Util.Json | null;
    const send: Util.Json | null = inp && Util.isObject(inp.channelMessageSend) ? inp.channelMessageSend : null;
    if (ack === null || send === null || !ctx.userId || typeof ack.messageId !== "string" || ack.messageId === "") {
      return;
    }
    const channelId = typeof ack.channelId === "string" && ack.channelId !== "" ? ack.channelId : String(send.channelId || "");
    Snapshots.remember(nk, ctx.userId, channelId, ack.messageId, send.content, Server.nowMs());
  } catch (e) {
    logger.warn("a message was not remembered for reports: %s", Server.errorText(e));
  }
}
