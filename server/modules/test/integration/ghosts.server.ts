// M4 ghost races against a REAL Nakama (like gifts.server.ts): the module 0.2.6 in Nakama's own JavaScript
// runtime: a ghost shared on a showcase and raced by a friend (list_ghosts), a better run replacing it, a
// stranger and a child without consent kept out, a gift that carries a ghost (open_gift gives it back), a
// 3-minute ghost with a gift's biggest build in one call, a report about a ghost (the server's copy kept), and
// the account's deletion taking the ghosts on PostgreSQL itself. Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7790 node --test test/integration/ghosts.server.ts
//
// It needs the console (EASYCRAFT_CONSOLE, default the HTTP port + 1; EASYCRAFT_CONSOLE_PASSWORD).
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { server } from "../harness.ts";

const S = server();
const B = S.BuildRules;
const H = S.GhostRules;
const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const CONSOLE = process.env.EASYCRAFT_CONSOLE || BASE.replace(/:(\d+)$/, (_m, p) => ":" + (Number(p) + 1));
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const SYSTEM = "00000000-0000-0000-0000-000000000000";
const TAG = Date.now().toString(36).slice(-5);
const START = 203;
const FINISH = 205;
const STONE = 1;

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

async function player(band = "13_plus"): Promise<Player> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: "itest-" + randomUUID() });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: "Ghost" + TAG + ++counter };
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

async function consoleApi(method: string, path: string): Promise<{ status: number; body: Json }> {
  if (consoleToken === "") {
    const login = await fetch(CONSOLE + "/v2/console/authenticate", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: process.env.EASYCRAFT_CONSOLE_PASSWORD || "easycraft-dev" }),
    });
    consoleToken = (await login.json()).token;
  }
  const r = await fetch(CONSOLE + path, { method, headers: { Authorization: "Bearer " + consoleToken } });
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : {} };
}

async function storageOf(userId: string, collection: string): Promise<Json[]> {
  return ((await consoleApi("GET", `/v2/console/storage?user_id=${userId}&collection=${collection}`)).body.objects || []) as Json[];
}

// A course area of `size`: a stone floor with START and FINISH (y 0).
function course(size: number[], start: number[], finish: number[]): string {
  const cells: number[] = [];
  for (let y = 0; y < size[1]; y++) {
    for (let z = 0; z < size[2]; z++) {
      for (let x = 0; x < size[0]; x++) {
        let id = y === 0 ? STONE : 0;
        if (y === 0 && x === start[0] && z === start[2]) {
          id = START;
        }
        if (y === 0 && x === finish[0] && z === finish[2]) {
          id = FINISH;
        }
        cells.push(id);
      }
    }
  }
  return B.encode(size, cells);
}

// A run from START's top to FINISH's top in `ms`, wandering sideways (up to `wander` blocks) on the way.
function ghost(start: number[], finish: number[], ms: number, wander = 0): Json {
  const n = H.sampleCount(ms);
  const to = [(finish[0] - start[0]) * 10, 0, (finish[2] - start[2]) * 10];
  const points: number[][] = [];
  for (let k = 0; k < n; k++) {
    const f = k / (n - 1);
    points.push([Math.round(to[0] * f), 0, Math.round(to[2] * f + wander * 10 * Math.sin(Math.PI * f))]);
  }
  return { start, finish, ms, path: H.encodePath(points), look: JSON.stringify({ hat: "crown", shirt: "red" }) };
}

const AREA = course([12, 3, 12], [1, 0, 1], [9, 0, 9]);

test("a ghost on a showcase is raced by a friend; a better run replaces it; strangers never see it", async () => {
  const me = await player();
  const pal = await player();
  const stranger = await player();
  const kid = await player("under_13");
  await befriend(me, pal);
  assert.equal((await rpc(me, "publish_showcase", { build: AREA })).ok, true);
  const first = await rpc(me, "share_ghost", { to: "showcase", ghost: ghost([1, 0, 1], [9, 0, 9], 3000) });
  assert.equal(first.ok, true, JSON.stringify(first));
  const listed = await rpc(pal, "list_ghosts", { user_id: me.id });
  assert.equal(listed.ok, true, JSON.stringify(listed));
  assert.equal(listed.owner_username, me.name);
  assert.equal(listed.ghosts.length, 1);
  assert.equal(listed.ghosts[0].ms, 3000);
  assert.deepEqual(listed.ghosts[0].start, [1, 0, 1]);
  assert.equal(JSON.parse(listed.ghosts[0].look).hat, "crown");
  const better = await rpc(me, "share_ghost", { to: "showcase", ghost: ghost([1, 0, 1], [9, 0, 9], 2400) });
  assert.equal(better.ok, true);
  const again = await rpc(pal, "list_ghosts", { username: me.name.toLowerCase() });
  assert.deepEqual(again.ghosts.map((g: Json) => g.ms), [2400], "replaced, one per course");
  assert.equal((await rpc(stranger, "list_ghosts", { user_id: me.id })).error, "not_friends");
  assert.equal((await rpc(kid, "list_ghosts", { user_id: me.id })).error, "not_allowed_online", "no consent: nothing");
  const hop = ghost([1, 0, 1], [9, 0, 9], 2000);
  hop.path = H.encodePath([[0, 0, 0], ...new Array(9).fill([0, 0, 0]), [80, 0, 80]]);
  assert.equal((await rpc(me, "share_ghost", { to: "showcase", ghost: hop })).error, "impossible_run");
  assert.equal((await rpc(me, "share_ghost", { to: "showcase", ghost: ghost([2, 0, 1], [9, 0, 9], 2000) })).error, "not_on_course");
});

test("a gift carries a ghost; a 3-minute ghost with a gift's biggest build fits one call", async () => {
  const me = await player();
  const pal = await player();
  await befriend(me, pal);
  const small = course([8, 2, 8], [0, 0, 0], [7, 0, 7]);
  const sent = await rpc(me, "share_ghost", { to: "gift", user_id: pal.id, build: small, ghost: ghost([0, 0, 0], [7, 0, 7], 2000) });
  assert.equal(sent.ok, true, JSON.stringify(sent));
  const list = await rpc(pal, "list_gifts");
  assert.equal(list.gifts[0].ghost, true);
  const opened = await rpc(pal, "open_gift", { gift_id: sent.gift_id });
  assert.equal(opened.gift.ghost.ms, 2000);
  assert.equal(opened.gift.build, small);
  // The biggest: an 8 x 8 x 8 build of mixed blocks and a 3-minute run wandering around it.
  const cells: number[] = [];
  for (let i = 0; i < 512; i++) {
    cells.push(i < 64 ? (i === 0 ? START : i === 63 ? FINISH : (i * 7) % 37 + 1 === 18 ? 6 : (i * 7) % 37 + 1) : 0);
  }
  const big = B.encode([8, 8, 8], cells);
  const long = ghost([0, 0, 0], [7, 0, 7], 180000, 4);
  const payload = JSON.stringify({ to: "gift", user_id: pal.id, build: big, ghost: long });
  const t0 = Date.now();
  const r = await rpc(me, "share_ghost", JSON.parse(payload));
  console.log("MEASURE share_ghost with a gift: %d characters, %d ms", payload.length, Date.now() - t0);
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.ok(payload.length < H.PAYLOAD);
});

test("a report about a ghost keeps the server's copy; the account's deletion takes the ghosts", async () => {
  const me = await player();
  const pal = await player();
  await befriend(me, pal);
  await rpc(me, "publish_showcase", { build: AREA });
  const id = (await rpc(me, "share_ghost", { to: "showcase", ghost: ghost([1, 0, 1], [9, 0, 9], 3000) })).ghost_id;
  assert.equal((await rpc(pal, "report_build", { user_id: me.id, what: "ghost", ghost_id: id })).ok, true);
  const reports: Json[] = [];
  for (const o of await storageOf(SYSTEM, "reports")) {
    const r = await consoleApi("GET", `/v2/console/storage/reports/${encodeURIComponent(o.key)}/${SYSTEM}`);
    const v = JSON.parse(r.body.value);
    if (v.reported_id === me.id && v.what === "ghost") {
      reports.push(v);
    }
  }
  assert.equal(reports.length, 1);
  assert.equal(reports[0].ghost.source, "server");
  assert.equal(reports[0].ghost.ms, 3000);
  assert.equal((await storageOf(me.id, "ghosts")).length, 1);
  const c = await rpc(me, "delete_account", {});
  const done = await rpc(me, "delete_account", { confirm: c.confirm });
  assert.equal(done.deleted, true, JSON.stringify(done));
  assert.equal((await storageOf(me.id, "ghosts")).length, 0, "gone with the account");
});

test("the module is 0.2.12", async () => {
  const p = await player();
  assert.equal((await rpc(p, "healthcheck")).version, "0.2.20");
});
