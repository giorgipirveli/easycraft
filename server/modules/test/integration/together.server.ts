// Owner #81, #82, #85 (module 0.2.18): better together against a REAL Nakama, in its own JavaScript runtime: two friends
// learning the same day (a day together), a present sent, opened once and thanked (the sender's gold in the wallet), a
// proud moment cheered, study buddies, a crew made and joined, a present waiting on the invite code for a new friend,
// and a deletion taking the player out of everything. Not part of `npm test` (it needs a server; run it before
// deploying 0.2.18):
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test test/integration/together.server.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const TAG = Date.now().toString(36).slice(-5);

type Json = { [key: string]: any };

interface Player {
  id: string;
  token: string;
  name: string;
}

async function http(method: string, path: string, token: string | null, body?: unknown): Promise<{ status: number; body: Json }> {
  const r = await fetch(BASE + path, {
    method,
    headers: { Authorization: token ? "Bearer " + token : SERVER_KEY, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  let parsed: Json = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch {
    parsed = { raw: text };
  }
  return { status: r.status, body: parsed };
}

async function rpc(p: Player, id: string, payload: Json = {}): Promise<Json> {
  const r = await http("POST", "/v2/rpc/" + id, p.token, JSON.stringify(payload));
  assert.equal(r.status, 200, id + ": " + JSON.stringify(r.body));
  return JSON.parse(r.body.payload);
}

let counter = 0;

async function player(): Promise<Player> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: "itest-" + randomUUID() });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: "Tog" + TAG + ++counter };
  const c = await rpc(p, "claim_username", { username: p.name, age_band: "13_plus" });
  assert.equal(c.ok, true, JSON.stringify(c));
  return p;
}

async function befriend(a: Player, b: Player): Promise<void> {
  for (const [from, to] of [[a, b], [b, a]]) {
    const r = await http("POST", "/v2/friend?ids=" + to.id, from.token);
    assert.equal(r.status, 200, JSON.stringify(r.body));
  }
}

async function gold(p: Player): Promise<number> {
  return (await rpc(p, "get_account_state")).gold as number;
}

test("the module is 0.2.20", async () => {
  const p = await player();
  assert.equal((await rpc(p, "healthcheck")).version, "0.2.20");
});

test("friends learn the same day, a present opened once and thanked, a moment cheered, study buddies", async () => {
  const alex = await player();
  const sam = await player();
  await befriend(alex, sam);
  assert.equal((await rpc(alex, "social_learned", { unit: "g4.maths.big_numbers" })).ok, true);
  assert.equal((await rpc(sam, "social_learned", {})).together, 1);
  let info = await rpc(alex, "social_info");
  assert.equal(info.friends.length, 1);
  assert.equal(info.friends[0].days, 1);
  assert.equal(info.friends[0].level, 1);
  const sent = await rpc(alex, "present_send", { user_id: sam.id, kind: "seeds" });
  assert.equal(sent.ok, true, JSON.stringify(sent));
  assert.equal((await rpc(alex, "present_send", { user_id: sam.id, kind: "seeds" })).error, "sent_today");
  const inbox = await rpc(sam, "social_info");
  assert.equal(inbox.presents.length, 1);
  const opened = await rpc(sam, "present_open", { id: inbox.presents[0].id });
  assert.deepEqual([opened.ok, opened.kind, opened.name], [true, "seeds", alex.name]);
  assert.equal((await rpc(sam, "present_open", { id: inbox.presents[0].id })).error, "not_found");
  const before = await gold(alex);
  assert.equal((await rpc(sam, "present_thank", { id: inbox.presents[0].id })).gold, 10);
  assert.equal(await gold(alex), before + 10, "the thank-you's gold is in the wallet");
  assert.equal((await rpc(alex, "social_moment", { kind: "landed", place: "moon" })).told, 1);
  const feed = (await rpc(sam, "social_info")).feed;
  assert.equal((await rpc(sam, "social_cheer", { moment_id: feed[0].id, cheer: "amazing" })).ok, true);
  info = await rpc(alex, "social_info", { seen: true });
  assert.ok(info.news.some((n: Json) => n.what === "cheer" && n.name === sam.name && n.place === "landed:moon"));
  assert.equal((await rpc(alex, "study_buddy", { action: "ask", user_id: sam.id })).state, "asked");
  assert.equal((await rpc(sam, "study_buddy", { action: "yes", user_id: alex.id })).state, "yes");
  // The game can't read or write the records itself.
  const read = await http("POST", "/v2/storage", alex.token, { object_ids: [{ collection: "together", key: "me", user_id: alex.id }] });
  assert.deepEqual(read.body.objects || [], [], "server-only storage");
});

test("a crew made and joined; a present waiting on the code; deletion forgets the player", async () => {
  const alex = await player();
  const sam = await player();
  await befriend(alex, sam);
  const made = await rpc(alex, "crew", { action: "make", adjective: "Brave", noun: "Comets", badge: "rocket", look: { hair: "curly" } });
  assert.equal(made.ok, true, JSON.stringify(made));
  assert.equal((await rpc(alex, "crew", { action: "invite", user_id: sam.id })).ok, true);
  const invites = (await rpc(sam, "social_info")).crew_invites;
  const joined = await rpc(sam, "crew", { action: "join", crew: invites[0].crew });
  assert.equal(joined.crew.members.length, 2);
  const code = (await rpc(alex, "invite_info")).code;
  assert.equal((await rpc(alex, "present_send", { link: true, kind: "buddy_egg" })).waiting, 1);
  const newbie = await player();
  assert.equal((await rpc(newbie, "invite_use", { code })).ok, true);
  const mine = await rpc(newbie, "social_info");
  assert.deepEqual([mine.presents[0].kind, mine.presents[0].name, mine.presents[0].link], ["buddy_egg", alex.name, true]);
  const first = await rpc(alex, "delete_account");
  const done = await rpc(alex, "delete_account", { confirm: first.confirm });
  assert.equal(done.ok, true, JSON.stringify(done));
  assert.ok(done.together >= 1, JSON.stringify(done));
  const left = await rpc(sam, "social_info");
  assert.equal(left.crew.members.length, 1, "the crew goes on without the deleted player");
  assert.deepEqual(left.friends, []);
});
