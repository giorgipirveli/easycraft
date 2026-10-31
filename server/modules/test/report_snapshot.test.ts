// M4 Task 8b, agent G (spec §5.14: reports are reviewed by a person): a report about a chat message
// keeps a snapshot of that message (its text or emote and time) so the reviewer can read what was
// said. The server's own copy first: every sent message is remembered for an hour (Nakama's local
// cache; team rooms and under-13 chats keep no history), and kept DMs are looked up in their history.
// Only when the server has no copy does it keep the message as the reporter's game showed it, marked
// "reporter". Only that one message; the snapshot is part of the report and goes with it.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx, SYSTEM_USER } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const RR = S.ReportRules;
const TEEN = A.defaults("13_plus");

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function report(me: string, payload: object): any {
  const r = JSON.parse(S.rpcReportUser(ctx(me), log, nk, JSON.stringify(payload)));
  assert.equal(r.ok, true, JSON.stringify(r));
  const all = [...nk.storage.values()].filter((o) => o.collection === "reports" && o.userId === SYSTEM_USER);
  return all[all.length - 1].value;
}

// The after hook, as Nakama calls it once a message went out (the before hook cleaned the content).
function sent(sender: string, channelId: string, content: object, messageId = crypto.randomUUID()): string {
  S.rtAfterChannelMessageSend(ctx(sender), log, nk,
    { channelMessageAck: { channelId, messageId, code: 0, username: "x", persistent: false } },
    { channelMessageSend: { channelId, content: JSON.stringify(content) } });
  return messageId;
}

function players(): { me: string; bad: string; room: string } {
  const me = nk.addUser("Me_1", TEEN);
  const bad = nk.addUser("Meanie", TEEN);
  return { me, bad, room: "2...3dcf6dca-ba73-4e08-a89e-8c538234f741." };
}

// --- The pure rules ---

test("the reporter's copy: one text or one emote, tidied and capped like chat, a time never in the future", () => {
  assert.deepEqual(RR.shownMessage({ text: "  you   are\nbad  ", at_ms: now - 5000 }, now), { text: "you are bad", at_ms: now - 5000 });
  assert.deepEqual(RR.shownMessage({ emote: "wave" }, now), { emote: "wave", at_ms: 0 });
  assert.equal(RR.shownMessage({ text: "x".repeat(500) }, now).text.length, 120);
  assert.equal(RR.shownMessage({ text: "hi", at_ms: now + 60_000 }, now).at_ms, 0, "a time from the future is dropped");
  for (const bad of [null, "hi", { text: "" }, { text: "   " }, { text: 5 }, { emote: "Not An Id!" }, { text: "a", emote: "wave" },
    { text: "a", extra: 1 }]) {
    assert.equal(RR.shownMessage(bad, now), null, JSON.stringify(bad));
  }
});

test("the snapshot: the server's copy when it has one (marked server), else the reporter's (marked reporter), else none", () => {
  const record = { s: "bad", c: "chan", content: '{"text":"go away"}', at: now - 1000 };
  const shown = { text: "something else", at_ms: now - 900 };
  assert.deepEqual(RR.snapshot(record, shown), { text: "go away", at_ms: now - 1000, source: "server" });
  assert.deepEqual(RR.snapshot({ ...record, content: '{"emote":"laugh"}' }, null), { emote: "laugh", at_ms: now - 1000, source: "server" });
  assert.deepEqual(RR.snapshot(null, shown), { text: "something else", at_ms: now - 900, source: "reporter" });
  assert.equal(RR.snapshot(null, null), null);
  assert.deepEqual(RR.snapshot({ ...record, content: "not json" }, shown), { ...shown, source: "reporter" },
    "an unreadable server copy counts as none");
});

// --- report_user with a message ---

test("a team-room message the server passed on is stored with the report from the server's own copy", () => {
  const p = players();
  const id = sent(p.bad, p.room, { text: "you are a baby" });
  const v = report(p.me, { user_id: p.bad, reason: "mean_words", channel_id: p.room, message_id: id,
    message: { text: "(what the game showed)", at_ms: now } });
  assert.equal(v.message_id, id);
  assert.deepEqual(v.message, { text: "you are a baby", at_ms: now, source: "server" }, "the server's copy wins");
  const e = sent(p.bad, p.room, { emote: "laugh" });
  now += 11 * 60 * 1000; // past the 10-minute "same player again" window
  assert.deepEqual(report(p.me, { user_id: p.bad, reason: "mean_words", channel_id: p.room, message_id: e }).message,
    { emote: "laugh", at_ms: now - 11 * 60 * 1000, source: "server" }, "no copy from the reporter needed");
});

test("the server's copy lasts an hour; after that the reporter's copy is kept, marked as shown by the reporter", () => {
  const p = players();
  const id = sent(p.bad, p.room, { text: "you are a baby" });
  now += RR.RECENT_SECONDS * 1000;
  const v = report(p.me, { user_id: p.bad, reason: "mean_words", channel_id: p.room, message_id: id,
    message: { text: "you are a baby", at_ms: now - RR.RECENT_SECONDS * 1000 } });
  assert.deepEqual(v.message, { text: "you are a baby", at_ms: now - RR.RECENT_SECONDS * 1000, source: "reporter" });
});

test("a copy from another sender or another channel is not the reported message", () => {
  const p = players();
  const other = nk.addUser("Other_1", TEEN);
  const byOther = sent(other, p.room, { text: "hello" });
  assert.deepEqual(report(p.me, { user_id: p.bad, reason: "scary", channel_id: p.room, message_id: byOther,
    message: { text: "scary words" } }).message, { text: "scary words", at_ms: 0, source: "reporter" });
  const elsewhere = sent(p.bad, "2...another-room", { text: "hello" });
  now += 11 * 60 * 1000;
  assert.equal(report(p.me, { user_id: p.bad, reason: "scary", channel_id: p.room, message_id: elsewhere }).message, null,
    "no copy at all: nothing to show");
});

test("a kept DM message is found in the DM's history (after the hour, or after a server restart)", () => {
  const p = players();
  const dm = nk.channelIdBuild(p.me, p.bad, 2);
  nk.addChannelMessage(dm, p.me, "Me_1", now / 1000 - 120);
  const id = nk.addChannelMessage(dm, p.bad, "Meanie", now / 1000 - 60);
  nk.channelMessages.get(dm)!.find((m) => m.messageId === id)!.content = '{"text":"give me your address"}';
  const v = report(p.me, { user_id: p.bad, reason: "personal_info", channel_id: dm, message_id: id });
  assert.deepEqual(v.message, { text: "give me your address", at_ms: now - 60_000, source: "server" });
});

test("another player's DM history is never read for a report", () => {
  const p = players();
  const pal = nk.addUser("Pal_1", TEEN);
  const theirs = nk.channelIdBuild(pal, p.bad, 2);
  const id = nk.addChannelMessage(theirs, p.bad, "Meanie", now / 1000 - 60);
  assert.equal(report(p.me, { user_id: p.bad, reason: "scary", channel_id: theirs, message_id: id }).message, null);
});

test("a report without a message has no snapshot (as before)", () => {
  const p = players();
  const v = report(p.me, { user_id: p.bad, reason: "bad_name" });
  assert.equal("message" in v, false);
});

test("the after hook never breaks chat: odd input is ignored", () => {
  const p = players();
  for (const [output, input] of [[null, {}], [{}, {}], [{ channelMessageAck: {} }, { channelMessageSend: {} }]] as any[]) {
    assert.doesNotThrow(() => S.rtAfterChannelMessageSend(ctx(p.bad), log, nk, output, input));
  }
  assert.equal(nk.cache.size, 0);
});

test("the snapshot goes when the report goes (it is part of the report)", () => {
  const p = players();
  const id = sent(p.bad, p.room, { text: "you are a baby" });
  report(p.me, { user_id: p.bad, reason: "mean_words", channel_id: p.room, message_id: id });
  const key = [...nk.storage.values()].find((o) => o.collection === "reports")!.key;
  nk.storageDelete([{ collection: "reports", key, userId: SYSTEM_USER }]);
  assert.equal(JSON.stringify([...nk.storage.values()]).includes("you are a baby"), false);
});
