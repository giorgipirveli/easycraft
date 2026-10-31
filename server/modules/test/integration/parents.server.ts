// M4 Wave 2, agent F, against a REAL Nakama (like nakama.server.ts): a grown-up approves an under-13
// player's friends through the real friends API, codes used offline are recorded, and the profile
// backup is a private "profiles" object the game writes itself. Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 npm run test:server
//
// The server needs server/nakama/local.yml's switches (the fake consent provider, 2 s).
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash
const FIRST_CODE_HASH = "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a";
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

async function player(band: string, prefix: string): Promise<Player> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: "ftest-" + randomUUID() });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: prefix + TAG + ++counter };
  const claim = await rpc(p, "claim_username", { username: p.name, age_band: band });
  assert.equal(claim.ok, true, JSON.stringify(claim));
  return p;
}

async function consentedKid(): Promise<Player> {
  const kid = await player("under_13", "Fkid");
  assert.equal((await rpc(kid, "consent_start", {})).consent, "pending");
  await new Promise((done) => setTimeout(done, 2200));
  assert.equal((await rpc(kid, "consent_status", {})).consent, "verified");
  return kid;
}

async function stateOf(p: Player, otherId: string): Promise<number | undefined> {
  const r = await http("GET", "/v2/friend?limit=100", p.token);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const f = (r.body.friends || []).find((x: Json) => x.user && x.user.id === otherId);
  return f ? (f.state === undefined ? 0 : f.state) : undefined; // Nakama leaves 0 out of the JSON
}

test("a child's friend request waits for a grown-up, then reaches the friend", async () => {
  const kid = await consentedKid();
  const teen = await player("13_plus", "Fteen");
  const add = await http("POST", "/v2/friend?usernames=" + teen.name.toLowerCase(), kid.token);
  assert.equal(add.status, 403, JSON.stringify(add.body));
  assert.equal(add.body.message, "needs_grown_up");
  assert.equal(await stateOf(teen, kid.id), undefined, "the friend sees nothing yet");
  const list = await rpc(kid, "approve_friend", {});
  assert.deepEqual(list.requests.map((r: Json) => [r.user_id, r.username, r.direction]), [[teen.id, teen.name, "out"]]);
  const yes = await rpc(kid, "approve_friend", { user_id: teen.id, approve: true });
  assert.equal(yes.ok, true, JSON.stringify(yes));
  assert.equal(yes.friend.state, "asked");
  assert.equal(await stateOf(teen, kid.id), 2, "now the friend has a request");
  assert.equal(await stateOf(kid, teen.id), 1);
  const notes = await http("GET", "/v2/notification?limit=100", kid.token);
  const note = (notes.body.notifications || []).find((n: Json) => n.code === 103 && JSON.parse(n.content).what === "friend");
  assert.ok(note, "notification 103 {what: friend}: " + JSON.stringify(notes.body));
});

test("a grown-up's yes to a request that came in makes them friends; a no removes it", async () => {
  const kid = await consentedKid();
  const teen = await player("13_plus", "Fteen");
  const other = await player("13_plus", "Fothr");
  for (const p of [teen, other]) {
    assert.equal((await http("POST", "/v2/friend?ids=" + kid.id, p.token)).status, 200);
  }
  assert.equal(await stateOf(kid, teen.id), 2);
  for (const p of [teen, other]) {
    const accept = await http("POST", "/v2/friend?ids=" + p.id, kid.token);
    assert.equal(accept.body.message, "needs_grown_up");
  }
  const list = await rpc(kid, "approve_friend", {});
  assert.deepEqual(list.requests.map((r: Json) => r.direction), ["in", "in"]);
  assert.equal((await rpc(kid, "approve_friend", { user_id: teen.id, approve: true })).friend.state, "friend");
  assert.equal(await stateOf(kid, teen.id), 0);
  assert.equal(await stateOf(teen, kid.id), 0);
  const no = await rpc(kid, "approve_friend", { user_id: other.id, approve: false });
  assert.deepEqual(no.requests, []);
  assert.equal(await stateOf(kid, other.id), undefined, "the request that came in is gone");
  assert.equal(await stateOf(other, kid.id), undefined);
});

test("a code used offline is recorded without pay, and can't pay again online", async () => {
  const me = await player("13_plus", "Fcode");
  const r = await rpc(me, "redeem_code", { hashes: [FIRST_CODE_HASH] });
  assert.deepEqual(r, { ok: true, status: "recorded", recorded: 1, already: 0, gold: 0, paid: [] });
  assert.deepEqual(await rpc(me, "redeem_code", { code: FIRST_CODE }), { ok: false, error: "already_used" });
});

test("the profile backup: a private object the game writes and reads back; other collections refused", async () => {
  const me = await player("13_plus", "Fback");
  const value = JSON.stringify({ version: 1, username: "Someone_else", survivor_gold: 321, updated_at: 1800000000,
    universe_unlocked: 3 });
  const w = await http("PUT", "/v2/storage", me.token,
    { objects: [{ collection: "profiles", key: "profile", value, permission_read: 1, permission_write: 1 }] });
  assert.equal(w.status, 200, JSON.stringify(w.body));
  const read = await http("POST", "/v2/storage", me.token, { object_ids: [{ collection: "profiles", key: "profile", user_id: me.id }] });
  assert.equal(read.status, 200);
  const kept = JSON.parse(read.body.objects[0].value);
  assert.equal(kept.universe_unlocked, 3);
  // Owner #67 (module 0.2.12): cleaned on the way in: no gold (the wallet's), the account's own name.
  assert.equal(kept.survivor_gold, undefined);
  assert.equal(kept.username, me.name);
  const other = await player("13_plus", "Fpeek");
  const peek = await http("POST", "/v2/storage", other.token, { object_ids: [{ collection: "profiles", key: "profile", user_id: me.id }] });
  assert.deepEqual(peek.body.objects || [], [], "nobody else reads it");
  const bad = await http("PUT", "/v2/storage", me.token,
    { objects: [{ collection: "parent", key: "consent", value: "{\"status\":\"verified\"}", permission_read: 1, permission_write: 1 }] });
  assert.notEqual(bad.status, 200, "only profiles");
});
