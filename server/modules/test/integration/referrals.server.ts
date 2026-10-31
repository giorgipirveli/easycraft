// Owner #79 (module 0.2.16): the invite program against a REAL Nakama, in its own JavaScript runtime: a claimed
// player's code, a new friend using it (the welcome gift in the wallet), the friend learning (the inviter's gold,
// the friend's, the news), never twice, a family code, and the friend's deletion taking it out of the inviter's list.
// Not part of `npm test` (it needs a server; run it before deploying 0.2.16):
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test test/integration/referrals.server.ts
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

async function player(claim = true): Promise<Player> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: "itest-" + randomUUID() });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: "Inv" + TAG + ++counter };
  if (claim) {
    const c = await rpc(p, "claim_username", { username: p.name, age_band: "13_plus" });
    assert.equal(c.ok, true, JSON.stringify(c));
  }
  return p;
}

async function gold(p: Player): Promise<number> {
  return (await rpc(p, "get_account_state")).gold as number;
}

test("the module is 0.2.20", async () => {
  const p = await player();
  assert.equal((await rpc(p, "healthcheck")).version, "0.2.20");
});

test("a code, a new friend's welcome, the friend learns: both paid once, the news, the deletion", async () => {
  const alex = await player();
  const info = await rpc(alex, "invite_info");
  assert.equal(info.ok, true, JSON.stringify(info));
  assert.match(info.code, /^[A-Z]+-[A-Z]+-\d{2,4}$/);
  assert.equal(info.can_use_code, true, "a new account (Nakama's create time read right)");
  const sam = await player();
  const used = await rpc(sam, "invite_use", { code: info.code.toLowerCase().replace(/-/g, " ") });
  assert.deepEqual({ ok: used.ok, kind: used.kind, guide: used.guide, welcome: used.welcome },
    { ok: true, kind: "friend", guide: alex.name, welcome: 100 });
  assert.equal(await gold(sam), 100);
  assert.deepEqual(await rpc(sam, "invite_use", { code: info.code }), { ok: false, error: "already_used" });
  assert.deepEqual(await rpc(alex, "invite_use", { code: info.code }), { ok: false, error: "own_code" });
  const before = await gold(alex);
  const learned = await rpc(sam, "invite_progress", { event: "learned", unit: "g4.maths.big_numbers" });
  assert.deepEqual(learned, { ok: true, counted: true, gold: 50, guide: alex.name });
  assert.equal(await gold(alex) - before, 250);
  assert.equal((await rpc(sam, "invite_progress", { event: "learned" })).counted, false, "once");
  const a = await rpc(alex, "invite_info", { seen: true });
  assert.deepEqual(a.friends.map((f: Json) => [f.name, f.learned]), [[sam.name, true]]);
  assert.deepEqual(a.news.map((n: Json) => [n.what, n.gold]), [["joined", 0], ["learned", 250]]);
  const first = await rpc(sam, "delete_account");
  const done = await rpc(sam, "delete_account", { confirm: first.confirm });
  assert.equal(done.deleted, true, JSON.stringify(done));
  assert.deepEqual((await rpc(alex, "invite_info")).friends, [], "out of the inviter's list");
});

test("a family code joins a new player and an older one; the storage is the server's alone", async () => {
  const mum = await player();
  const made = await rpc(mum, "invite_group", { action: "make", kind: "family" });
  assert.equal(made.ok, true, JSON.stringify(made));
  const kid = await player();
  const r = await rpc(kid, "invite_use", { code: made.code });
  assert.equal(r.group, "family");
  assert.equal((await rpc(mum, "invite_info")).groups.family.members, 2);
  const read = await http("GET", "/v2/storage/referrals?user_id=" + kid.id, kid.token);
  assert.deepEqual(read.body.objects || [], [], "the game can't read its invite record");
  const write = await http("PUT", "/v2/storage", kid.token, { objects: [{ collection: "referrals", key: "me", value: "{}" }] });
  assert.notEqual(write.status, 200, "nor write it");
});
