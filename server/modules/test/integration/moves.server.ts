// Owner #99 (module 0.2.20), against a REAL Nakama (like keys.server.ts): the same name on a new device, with proof.
// A new device's own account asks for the child's account by name and gets a 6-digit code; the child's phone, online
// on a realtime socket, hears the ask (notification 110) and approves it with that code; the new device then gets a
// one-time key and signs in with sign_in_with_key (Nakama's own device table links its new id); the phone stays signed
// in and hears "moved". Wrong codes end an ask; a stranger can't use a key that was handed to someone else. Not part of
// `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/moves.server.ts
import { test, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const WS = BASE.replace(/^http/, "ws");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const TAG = Date.now().toString(36).slice(-5);

type Json = { [key: string]: any };

interface Player {
  id: string;
  token: string;
  device: string;
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

async function signIn(device: string, create = true): Promise<{ status: number; id: string; token: string }> {
  const r = await http("POST", "/v2/account/authenticate/device?create=" + create, null, { id: device });
  if (r.status !== 200) {
    return { status: r.status, id: "", token: "" };
  }
  const token = r.body.token as string;
  return { status: 200, id: JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string, token };
}

let counter = 0;

async function device(): Promise<Player> {
  const d = "mtest-" + randomUUID();
  const s = await signIn(d);
  assert.equal(s.status, 200);
  return { id: s.id, token: s.token, device: d, name: "" };
}

async function claimed(): Promise<Player> {
  const p = await device();
  p.name = "Mov" + TAG + ++counter;
  assert.equal((await rpc(p, "claim_username", { username: p.name, age_band: "13_plus" })).ok, true);
  return p;
}

async function deleteAccount(p: Player): Promise<void> {
  const first = await rpc(p, "delete_account", {});
  if (first.ok) {
    await rpc(p, "delete_account", { confirm: first.confirm });
  }
}

const openSockets: Socket[] = [];
after(() => {
  openSockets.forEach((s) => s.close());
});

class Socket {
  ws: WebSocket;
  events: Json[] = [];
  ready: Promise<unknown>;

  constructor(p: Player) {
    openSockets.push(this);
    this.ws = new WebSocket(`${WS}/ws?lang=en&status=true&format=json&token=${p.token}`);
    this.ws.onmessage = (m: MessageEvent) => {
      this.events.push(JSON.parse(String(m.data)));
    };
    this.ready = new Promise((ok, bad) => {
      this.ws.onopen = ok;
      this.ws.onerror = bad;
    });
  }

  async notes(code: number, count: number, timeoutMs = 4000): Promise<Json[]> {
    const end = Date.now() + timeoutMs;
    for (;;) {
      const out: Json[] = [];
      for (const e of this.events) {
        for (const n of e.notifications?.notifications || []) {
          if (n.code === code) {
            out.push(JSON.parse(n.content));
          }
        }
      }
      if (out.length >= count || Date.now() > end) {
        return out;
      }
      await new Promise((done) => setTimeout(done, 50));
    }
  }

  close(): void {
    this.ws.close();
  }
}

test("the module is 0.2.20 or later", async () => {
  const p = await device();
  const h = await rpc(p, "healthcheck");
  const [a, b, c] = String(h.version).split(".").map(Number);
  assert.ok(a > 0 || b > 2 || (b === 2 && c >= 20), "module " + h.version);
  await deleteAccount(p);
});

// The move ships OFF (MoveRules.ENABLED, the lead's quick-ship round 2026-10-15): both RPCs answer not_available.
async function moveOn(): Promise<boolean> {
  const p = await device();
  const r = await rpc(p, "move_approve", { action: "list" });
  await deleteAccount(p);
  return r.error !== "not_available";
}

test("the move by code is off on this module: not_available, and nothing to approve", async () => {
  if (await moveOn()) {
    return; // a module built with the move on: the tests below check it
  }
  const child = await claimed();
  const asker = await device();
  assert.deepEqual(await rpc(asker, "move_request", { action: "start", username: child.name, kind: "computer" }),
    { ok: false, error: "not_available" });
  assert.deepEqual(await rpc(child, "move_approve", { action: "list" }), { ok: false, error: "not_available" });
  await deleteAccount(child);
  await deleteAccount(asker);
});

test("a taken name, proved with the code from the new screen typed on the phone: the computer plays as the child", async (t) => {
  if (!(await moveOn())) {
    t.skip("the move is off on this module (MoveRules.ENABLED)");
    return;
  }
  const child = await claimed();
  const phone = new Socket(child);
  await phone.ready;
  const computer = await device();
  const asked = await rpc(computer, "move_request", { action: "start", username: child.name.toLowerCase(), kind: "computer" });
  assert.equal(asked.ok, true, JSON.stringify(asked));
  assert.match(asked.code, /^[0-9]{6}$/);
  assert.deepEqual(Object.keys(asked).sort(), ["code", "id", "ok", "valid_s"],
    "nothing about the account (the lead's security review): not even whether it plays now");
  const heard = await phone.notes(110, 1);
  assert.deepEqual(heard[0], { what: "asked", kind: "computer" });
  const list = await rpc(child, "move_approve", { action: "list" });
  assert.equal(list.asks.length, 1);
  assert.ok(!JSON.stringify(list).includes(asked.code), "the phone never sees the code: it is typed from the other screen");
  assert.equal((await rpc(computer, "move_request", { action: "status", id: asked.id })).state, "waiting");
  assert.deepEqual(await rpc(child, "move_approve", { action: "approve", id: asked.id, code: asked.code }), { ok: true });
  const st = await rpc(computer, "move_request", { action: "status", id: asked.id });
  assert.equal(st.state, "approved", JSON.stringify(st));
  const newId = "mtest-" + randomUUID();
  const done = await rpc(computer, "sign_in_with_key", { username: child.name, key: st.key, device_id: newId });
  assert.deepEqual(done, { ok: true, user_id: child.id, username: child.name, left: "deleted" });
  const again = await signIn(newId, false);
  assert.equal(again.status, 200);
  assert.equal(again.id, child.id, "the computer's new id signs in to the child's account");
  assert.equal((await signIn(child.device, false)).id, child.id, "the phone still signs in (both play)");
  assert.equal((await signIn(computer.device, false)).status, 404, "the computer's own empty account is gone");
  const moved = await phone.notes(110, 2);
  assert.deepEqual(moved[1], { what: "moved", kind: "computer" });
  phone.close();
  await deleteAccount(child);
});

test("three wrong codes end an ask; a key handed to one device is no use to another", async (t) => {
  if (!(await moveOn())) {
    t.skip("the move is off on this module (MoveRules.ENABLED)");
    return;
  }
  const child = await claimed();
  const asker = await device();
  const a = await rpc(asker, "move_request", { action: "start", username: child.name, kind: "tablet" });
  const wrong = a.code === "000000" ? "111111" : "000000";
  assert.equal((await rpc(child, "move_approve", { action: "approve", id: a.id, code: wrong })).tries_left, 2);
  assert.equal((await rpc(child, "move_approve", { action: "approve", id: a.id, code: wrong })).tries_left, 1);
  assert.deepEqual(await rpc(child, "move_approve", { action: "approve", id: a.id, code: wrong }), { ok: false, error: "ended", why: "wrong_code" });
  assert.equal((await rpc(asker, "move_request", { action: "status", id: a.id })).state, "waiting",
    "the asker is not told what the account's device did");
  const b = await rpc(asker, "move_request", { action: "start", username: child.name, kind: "tablet" });
  assert.deepEqual(await rpc(child, "move_approve", { action: "approve", id: b.id, code: b.code }), { ok: true });
  const key = (await rpc(asker, "move_request", { action: "status", id: b.id })).key;
  const stranger = await device();
  assert.deepEqual(await rpc(stranger, "sign_in_with_key", { username: child.name, key, device_id: "mtest-" + randomUUID() }),
    { ok: false, error: "wrong_key" });
  assert.equal((await rpc(asker, "move_request", { action: "cancel", id: b.id })).ok, true);
  assert.deepEqual(await rpc(asker, "sign_in_with_key", { username: child.name, key, device_id: "mtest-" + randomUUID() }),
    { ok: false, error: "wrong_key" }, "BACK on the new device ends its key too");
  for (const p of [child, asker, stranger]) {
    await deleteAccount(p);
  }
});
