// M4 Wave 3, agent I, against a REAL Nakama (like data_rights.server.ts): blueprint gifts, a showcase
// visited by a friend (a big one: the RPC carries ~40 KB), guestbook stickers, bottle mail, a report
// about a build, and the data rights of this wave on PostgreSQL itself (the SQL the fake Nakama only
// recognises by its text): a deleted sender's gifts and stickers, and the retention clean-up of old
// and orphaned things. Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7690 node --test test/integration/gifts.server.ts
//
// It needs the console (EASYCRAFT_CONSOLE, default the HTTP port + 1; EASYCRAFT_CONSOLE_PASSWORD) and
// the runtime HTTP key (EASYCRAFT_HTTP_KEY, default Nakama's development "defaulthttpkey").
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { server } from "../harness.ts";

const B = server().BuildRules;
const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const CONSOLE = process.env.EASYCRAFT_CONSOLE || BASE.replace(/:(\d+)$/, (_m, p) => ":" + (Number(p) + 1));
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const HTTP_KEY = process.env.EASYCRAFT_HTTP_KEY || "defaulthttpkey";
const SYSTEM = "00000000-0000-0000-0000-000000000000";
const TAG = Date.now().toString(36).slice(-5);
const DAY = 24 * 60 * 60 * 1000;

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

async function ownerRpc(id: string, payload: Json): Promise<Json> {
  const r = await fetch(`${BASE}/v2/rpc/${id}?http_key=${encodeURIComponent(HTTP_KEY)}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
  });
  const text = await r.text();
  assert.equal(r.status, 200, id + ": " + text);
  return JSON.parse(text);
}

let counter = 0;

async function player(band = "13_plus"): Promise<Player> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: "itest-" + randomUUID() });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: "Gift" + TAG + ++counter };
  const claim = await rpc(p, "claim_username", { username: p.name, age_band: band });
  assert.equal(claim.ok, true, JSON.stringify(claim));
  return p;
}

async function befriend(a: Player, b: Player): Promise<void> {
  for (const [from, to] of [[a, b], [b, a]]) {
    const r = await http("POST", "/v2/friend?ids=" + to.id, from.token);
    assert.equal(r.status, 200, JSON.stringify(r.body));
  }
}

let consoleToken = "";

async function consoleApi(method: string, path: string, body?: unknown): Promise<{ status: number; body: Json }> {
  if (consoleToken === "") {
    const login = await fetch(CONSOLE + "/v2/console/authenticate", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: process.env.EASYCRAFT_CONSOLE_PASSWORD || "easycraft-dev" }),
    });
    consoleToken = (await login.json()).token;
  }
  const r = await fetch(CONSOLE + path, {
    method, headers: { Authorization: "Bearer " + consoleToken, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : {} };
}

async function storageOf(userId: string, collection: string): Promise<Json[]> {
  return ((await consoleApi("GET", `/v2/console/storage?user_id=${userId}&collection=${collection}`)).body.objects || []) as Json[];
}

async function stored(collection: string, key: string, userId: string): Promise<Json | null> {
  const r = await consoleApi("GET", `/v2/console/storage/${collection}/${encodeURIComponent(key)}/${userId}`);
  return r.status === 200 ? { ...r.body, value: JSON.parse(r.body.value) } : null;
}

async function put(collection: string, key: string, userId: string, value: Json): Promise<void> {
  const r = await consoleApi("PUT", `/v2/console/storage/${collection}/${encodeURIComponent(key)}/${userId}`, {
    value: JSON.stringify(value), permission_read: 0, permission_write: 0,
  });
  assert.equal(r.status, 200, JSON.stringify(r.body));
}

function cube(n: number, id = 6): string {
  return B.encode([n, n, n], new Array(n * n * n).fill(id));
}

// A showcase area of 32 x 16 x 32, twelve layers of mixed blocks: about 33 KB of text.
function bigShowcase(): string {
  const cells: number[] = [];
  for (let y = 0; y < 16; y++) {
    for (let z = 0; z < 32; z++) {
      for (let x = 0; x < 32; x++) {
        const id = (x + 3 * z + 5 * y) % 37 + 1;   // a new run nearly every cell: the worst kind of area
        cells.push(y < 12 ? (id === 18 ? 6 : id) : 0);
      }
    }
  }
  return B.encode([32, 16, 32], cells);
}

test("the module is 0.2.12", async () => {
  const p = await player();
  assert.equal((await rpc(p, "healthcheck")).version, "0.2.20");
});

test("gifts: a friend gets a build, lists it and opens it once; strangers can't send", async () => {
  const me = await player();
  const pal = await player();
  const stranger = await player();
  await befriend(me, pal);
  const t0 = Date.now();
  const sent = await rpc(me, "send_gift", { user_id: pal.id, build: cube(3) });
  console.log(`MEASURE send_gift ${Date.now() - t0} ms`);
  assert.equal(sent.ok, true, JSON.stringify(sent));
  assert.equal((await rpc(stranger, "send_gift", { user_id: pal.id, build: cube(3) })).error, "not_friends");
  const list = await rpc(pal, "list_gifts");
  assert.deepEqual(list.gifts.map((g: Json) => [g.gift_id, g.from_username, g.count]), [[sent.gift_id, me.name, 27]]);
  const opened = await rpc(pal, "open_gift", { gift_id: sent.gift_id });
  assert.equal(opened.gift.build, cube(3));
  assert.equal((await rpc(pal, "open_gift", { gift_id: sent.gift_id })).error, "not_found");
  assert.deepEqual(await storageOf(pal.id, "gifts"), []);
});

test("showcase: a big area goes up and a friend visits it; stickers reach the owner", async () => {
  const me = await player();
  const pal = await player();
  await befriend(me, pal);
  const text = bigShowcase();
  assert.ok(text.length > 30_000 && text.length <= 48 * 1024, String(text.length));
  let t0 = Date.now();
  const pub = await rpc(me, "publish_showcase", { build: text, buddy: { build: cube(2, 23), at: [4, 1, 4] } });
  console.log(`MEASURE publish_showcase ${text.length} chars ${Date.now() - t0} ms`);
  assert.equal(pub.ok, true, JSON.stringify(pub));
  t0 = Date.now();
  const seen = await rpc(pal, "get_showcase", { user_id: me.id });
  console.log(`MEASURE get_showcase ${Date.now() - t0} ms`);
  assert.equal(seen.build, text);
  assert.deepEqual(seen.size, [32, 16, 32]);
  assert.deepEqual(seen.buddy.at, [4, 1, 4]);
  assert.equal((await rpc(pal, "sign_guestbook", { user_id: me.id, sticker: "rainbow" })).ok, true);
  const mine = await rpc(me, "get_showcase", {});
  assert.deepEqual(mine.guestbook.map((e: Json) => [e.from_username, e.sticker]), [[pal.name, "rainbow"]]);
  const removed = await rpc(me, "remove_sticker", { entry_id: mine.guestbook[0].entry_id });
  assert.deepEqual(removed.guestbook, []);
  assert.equal(await stored("guestbook", "guestbook", me.id), null, "an empty guestbook is deleted");
});

test("bottles: a phrase and a tiny build, opened once", async () => {
  const me = await player();
  const pal = await player("under_13");
  const consent = await rpc(pal, "consent_start", {});
  assert.equal(consent.ok, true, JSON.stringify(consent));
  await new Promise((done) => setTimeout(done, 2500));   // the fake provider says yes after 2 s
  assert.equal((await rpc(pal, "consent_status", {})).consent, "verified");
  assert.equal((await http("POST", "/v2/friend?ids=" + pal.id, me.token)).status, 200);
  assert.notEqual((await http("POST", "/v2/friend?ids=" + me.id, pal.token)).status, 200, "a child's yes waits for a grown-up");
  assert.equal((await rpc(pal, "approve_friend", { user_id: me.id, approve: true })).ok, true);
  assert.equal((await rpc(me, "send_bottle", { user_id: pal.id, phrase: "free text!" })).error, "bad_phrase");
  const sent = await rpc(me, "send_bottle", { user_id: pal.id, phrase: "Nice build!", build: cube(2, 14) });
  assert.equal(sent.ok, true, JSON.stringify(sent));
  const list = await rpc(pal, "list_bottles");
  assert.deepEqual(list.bottles.map((b: Json) => b.bottle_id), [sent.bottle_id]);
  const opened = await rpc(pal, "open_bottle", { bottle_id: sent.bottle_id });
  assert.equal(opened.bottle.phrase, "Nice build!");
  assert.equal(opened.bottle.build, cube(2, 14));
});

test("report_build: the report keeps the showcase as the server has it", async () => {
  const me = await player();
  const pal = await player();
  await befriend(me, pal);
  await rpc(me, "publish_showcase", { build: cube(4, 9) });
  assert.deepEqual(await rpc(pal, "report_build", { user_id: me.id, what: "showcase" }), { ok: true });
  const reports = (await storageOf(SYSTEM, "reports")).filter((o) => o.key.endsWith("_" + pal.id + "_build"));
  assert.equal(reports.length, 1);
  const v = (await stored("reports", reports[0].key, SYSTEM))!.value;
  assert.deepEqual([v.reason, v.what, v.build.source, v.build.build], ["bad_build", "showcase", "server", cube(4, 9)]);
});

test("delete_account on PostgreSQL: the gifts a player sent and the stickers it left go with it", async () => {
  const me = await player();
  const pal = await player();
  await befriend(me, pal);
  assert.equal((await rpc(me, "send_gift", { user_id: pal.id, build: cube(2) })).ok, true);
  assert.equal((await rpc(me, "send_bottle", { user_id: pal.id, phrase: "Hi!" })).ok, true);
  await rpc(pal, "publish_showcase", { build: cube(3) });
  assert.equal((await rpc(me, "sign_guestbook", { user_id: pal.id, sticker: "star" })).ok, true);
  await rpc(me, "publish_showcase", { build: cube(3) });
  const c = await rpc(me, "delete_account", {});
  const done = await rpc(me, "delete_account", { confirm: c.confirm });
  assert.equal(done.deleted, true, JSON.stringify(done));
  assert.equal(done.gifts_sent, 2, JSON.stringify(done));
  assert.equal(done.stickers_left, 1);
  assert.deepEqual(await storageOf(pal.id, "gifts"), []);
  assert.deepEqual(await storageOf(pal.id, "bottles"), []);
  assert.equal(await stored("guestbook", "guestbook", pal.id), null);
  assert.equal(await stored("showcases", "showcase", me.id), null);
});

test("retention on PostgreSQL: old gifts and stickers, and what console deletions left, go", async () => {
  const pal = await player();
  const friend = await player();
  const ghost = randomUUID();   // a sender deleted in the console
  const old = Date.now() - 61 * DAY;
  await put("gifts", "g" + old + "_oldoldoldold", pal.id, { from_id: friend.id, from_username: friend.name, build: cube(2),
    size: [2, 2, 2], count: 8, created_ms: old });
  await put("gifts", "g" + Date.now() + "_ghostghost00", pal.id, { from_id: ghost, from_username: "Ghost", build: cube(2),
    size: [2, 2, 2], count: 8, created_ms: Date.now() });
  await put("bottles", "b" + Date.now() + "_freshfresh00", pal.id, { from_id: friend.id, from_username: friend.name,
    phrase: "Hi!", created_ms: Date.now() });
  await put("guestbook", "guestbook", pal.id, { oldest_ms: old, entries: [
    { entry_id: "e1", from_id: friend.id, from_username: friend.name, sticker: "star", at_ms: old },
    { entry_id: "e2", from_id: ghost, from_username: "Ghost", sticker: "wow", at_ms: Date.now() },
    { entry_id: "e3", from_id: friend.id, from_username: friend.name, sticker: "heart", at_ms: Date.now() },
  ] });
  const r = await ownerRpc("retention_run", {});
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.ok(r.gifts_expired >= 1 && r.gifts_orphaned >= 1, JSON.stringify(r));
  assert.deepEqual((await storageOf(pal.id, "gifts")).length, 0);
  assert.equal((await storageOf(pal.id, "bottles")).length, 1, "a fresh bottle stays");
  const book = await stored("guestbook", "guestbook", pal.id);
  assert.deepEqual(book!.value.entries.map((e: Json) => e.entry_id), ["e3"], JSON.stringify(book));
  const guard = await stored("activity", "retention", SYSTEM);
  assert.equal(guard!.value.result.error, undefined, "the clean-up's SQL runs on this PostgreSQL: " + JSON.stringify(guard!.value));
});
