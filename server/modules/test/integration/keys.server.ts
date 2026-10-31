// Owner #67 (module 0.2.12), against a REAL Nakama (like nakama.server.ts): the account on every device. A key
// made on the child's device links a new device id to the account (Nakama's own device table), the asking device's
// never-claimed account is deleted, wrong keys lock the asking account, the other devices are logged out (owner #105,
// 0.2.20: one device at a time), and every profile write is
// cleaned (no gold, the account's own name) and checked by version. Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/keys.server.ts
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
  const d = "ktest-" + randomUUID();
  const s = await signIn(d);
  assert.equal(s.status, 200);
  return { id: s.id, token: s.token, device: d, name: "" };
}

async function claimed(band = "under_13"): Promise<Player> {
  const p = await device();
  p.name = "Key" + TAG + ++counter;
  assert.equal((await rpc(p, "claim_username", { username: p.name, age_band: band })).ok, true);
  return p;
}

async function deleteAccount(p: Player): Promise<void> {
  const first = await rpc(p, "delete_account", {});
  if (first.ok) {
    await rpc(p, "delete_account", { confirm: first.confirm });
  }
}

test("the module is 0.2.12 or later", async () => {
  const p = await device();
  const h = await rpc(p, "healthcheck");
  const [a, b, c] = String(h.version).split(".").map(Number);
  assert.ok(a > 0 || b > 2 || (b === 2 && c >= 12), "module " + h.version);
  await deleteAccount(p);
});

test("a key signs a new device in to the account; the new device's own empty account goes; the old device is logged out", async () => {
  const child = await claimed();
  const made = await rpc(child, "account_key", { action: "new" });
  assert.equal(made.ok, true, JSON.stringify(made));
  assert.match(made.key, /^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
  assert.deepEqual((await rpc(child, "account_key", { action: "state" })).has_key, true);
  const browser = await device();
  const newId = "ktest-" + randomUUID();
  const r = await rpc(browser, "sign_in_with_key", { username: child.name.toLowerCase(), key: made.key.toLowerCase(), device_id: newId });
  assert.deepEqual(r, { ok: true, user_id: child.id, username: child.name, left: "deleted" });
  const again = await signIn(newId, false);
  assert.equal(again.status, 200, "the new id signs in without making an account");
  assert.equal(again.id, child.id, "to the child's account");
  const old = await signIn(browser.device, false);
  assert.equal(old.status, 404, "the browser's own empty account is gone");
  // Owner #105 (0.2.20): one device at a time: the child's phone is logged out, its session and its id
  const ended = await http("POST", "/v2/rpc/account_key", child.token, JSON.stringify({ action: "state" }));
  assert.equal(ended.status, 401, "the phone's session ended");
  const phone = await signIn(child.device, false);
  assert.equal(phone.status, 403, "the phone's id is refused (device_logged_out), never a new account");
  const onNew: Player = { ...child, token: again.token, device: newId };
  assert.equal((await rpc(onNew, "account_key", { action: "state" })).devices, 1);
  await deleteAccount(onNew);
  assert.equal((await signIn(newId, false)).status, 403, "deleting the account logs every device out for good");
});

test("wrong keys: one answer for everything; only the asking account is locked, never the child's name", async () => {
  const child = await claimed("13_plus");
  const made = await rpc(child, "account_key", { action: "new" });
  const askers: Player[] = [];
  for (let i = 0; i < 5; i++) {
    const asker = await device();
    askers.push(asker);
    const wrong = await rpc(asker, "sign_in_with_key", { username: child.name, key: "0000-0000", device_id: "ktest-" + randomUUID() });
    assert.deepEqual(wrong, { ok: false, error: "wrong_key" });
  }
  // The second review's finding 3: wrong keys count per asking account only, so strangers never keep the right key out
  const attacker = await device();
  for (let i = 0; i < 10; i++) {
    const wrong = await rpc(attacker, "sign_in_with_key", { username: child.name, key: "0000-0000", device_id: "ktest-" + randomUUID() });
    assert.deepEqual(wrong, { ok: false, error: "wrong_key" });
  }
  const locked = await rpc(attacker, "sign_in_with_key", { username: child.name, key: made.key, device_id: "ktest-" + randomUUID() });
  assert.equal(locked.error, "locked", "the asking account is locked, even with the right key");
  assert.ok(locked.wait > 3500 && locked.wait <= 3600, String(locked.wait));
  const late = await device();
  assert.deepEqual(await rpc(late, "sign_in_with_key", { username: "Nobody" + TAG, key: made.key, device_id: "ktest-" + randomUUID() }),
    { ok: false, error: "wrong_key" }, "an unknown name: the same answer");
  const lateId = "ktest-" + randomUUID();
  const right = await rpc(late, "sign_in_with_key", { username: child.name, key: made.key, device_id: lateId });
  assert.equal(right.user_id, child.id, "the grown-up's right key still works");
  for (const p of [...askers, attacker]) {
    await deleteAccount(p);
  }
  await deleteAccount({ ...child, token: (await signIn(lateId, false)).token, device: lateId });
});

test("a key sign-in logs the lost phone out: its open socket closes and its id can't sign in any more", async () => {
  const child = await claimed();
  const made = await rpc(child, "account_key", { action: "new" });
  // The lost phone is online: its realtime socket is open.
  const ws = new WebSocket(BASE.replace(/^http/, "ws") + "/ws?lang=en&status=true&token=" + encodeURIComponent(child.token));
  await new Promise<void>((done, fail) => {
    ws.onopen = () => done();
    ws.onerror = () => fail(new Error("the phone's socket did not open"));
  });
  const closed = new Promise<boolean>((done) => {
    ws.onclose = () => done(true);
    setTimeout(() => done(false), 3000);
  });
  const tablet = await device();
  const tabletId = "ktest-" + randomUUID();
  assert.equal((await rpc(tablet, "sign_in_with_key", { username: child.name, key: made.key, device_id: tabletId })).ok, true);
  // Owner #105 (0.2.20): the sign-in itself logs every other device out (SIGN OUT OTHER DEVICES then has none left)
  assert.equal(await closed, true, "the phone's open socket closed");
  assert.equal((await signIn(child.device, false)).status, 403, "the phone's id is refused (device_logged_out)");
  const onTablet = await signIn(tabletId, false);
  const t: Player = { id: onTablet.id, token: onTablet.token, device: tabletId, name: child.name };
  assert.deepEqual(await rpc(t, "account_key", { action: "sign_out_others", device_id: tabletId }), { ok: true, removed: 0, devices: 1 });
  const back = await signIn(tabletId, false);
  assert.equal(back.id, child.id, "the tablet signs in again");
  await deleteAccount({ ...t, token: back.token });
});

test("the owner makes a key for a family whose every device lost the account (the runtime HTTP key)", async () => {
  const child = await claimed();
  const httpKey = process.env.EASYCRAFT_HTTP_KEY || "defaulthttpkey";
  const r = await fetch(`${BASE}/v2/rpc/account_key?http_key=${encodeURIComponent(httpKey)}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action: "new", username: child.name.toLowerCase() }),
  });
  const made = JSON.parse(await r.text());
  assert.equal(made.ok, true, JSON.stringify(made));
  const browser = await device();
  const newId = "ktest-" + randomUUID();
  assert.equal((await rpc(browser, "sign_in_with_key", { username: child.name, key: made.key, device_id: newId })).user_id, child.id);
  await deleteAccount({ ...child, token: (await signIn(newId, false)).token, device: newId });   // #105: the old device was logged out
});

test("a profile write is cleaned and checked by version", async () => {
  const child = await claimed();
  const value = JSON.stringify({ version: 1, backup: 2, username: "Someone", survivor_gold: 999999, universe_unlocked: 3,
    settings: { volume: 0.5, graphics: "high" }, hud_moves: { big: {} } });
  const w = await http("PUT", "/v2/storage", child.token,
    { objects: [{ collection: "profiles", key: "profile", value, permission_read: 1, permission_write: 1, version: "*" }] });
  assert.equal(w.status, 200, JSON.stringify(w.body));
  const version = w.body.acks[0].version as string;
  const read = await http("POST", "/v2/storage", child.token, { object_ids: [{ collection: "profiles", key: "profile", user_id: child.id }] });
  const kept = JSON.parse(read.body.objects[0].value);
  assert.equal(kept.survivor_gold, undefined, "never the gold");
  assert.equal(kept.hud_moves, undefined);
  assert.deepEqual(kept.settings, { volume: 0.5 });
  assert.equal(kept.username, child.name);
  assert.equal(kept.age_band, "under_13");
  const again = await http("PUT", "/v2/storage", child.token,
    { objects: [{ collection: "profiles", key: "profile", value, permission_read: 1, permission_write: 1, version: "*" }] });
  assert.notEqual(again.status, 200, "'*': only if new");
  const stale = await http("PUT", "/v2/storage", child.token,
    { objects: [{ collection: "profiles", key: "profile", value, permission_read: 1, permission_write: 1, version: "not-" + version }] });
  assert.notEqual(stale.status, 200);
  assert.match(String(stale.body.message).toLowerCase(), /version check/, "the game reads it as version_clash: " + stale.body.message);
  const fresh = await http("PUT", "/v2/storage", child.token,
    { objects: [{ collection: "profiles", key: "profile", value, permission_read: 1, permission_write: 1, version }] });
  assert.equal(fresh.status, 200, JSON.stringify(fresh.body));
  await deleteAccount(child);
});
