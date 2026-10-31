// Owner #105 (module 0.2.20), against a REAL Nakama: the account's password and LOG IN with it on another device, one
// device at a time. The phone claims a name and makes a password; a computer's own account (old enough) logs in with the
// name and the password: Nakama links the computer's new id and the phone's id is gone (its sign-in with create=false is
// a 403 device_logged_out: it can never make a new account by itself); wrong passwords get one answer; no network address is kept in storage;
// DELETE needs the password. Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/passwords.server.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const TAG = Date.now().toString(36).slice(-5);
const PW = "sunny-river-" + TAG;

type Json = { [key: string]: any };

interface Player {
  id: string;
  token: string;
  device: string;
  name: string;
}

async function http(method: string, path: string, token: string | null, body?: unknown, headers: Json = {}): Promise<{ status: number; body: Json }> {
  const r = await fetch(BASE + path, {
    method,
    headers: { Authorization: token ? "Bearer " + token : SERVER_KEY, "Content-Type": "application/json", ...headers },
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

async function rpc(p: Player, id: string, payload: Json = {}, headers: Json = {}): Promise<Json> {
  const r = await http("POST", "/v2/rpc/" + id, p.token, JSON.stringify(payload), headers);
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
  const d = "ptest-" + randomUUID();
  const s = await signIn(d);
  assert.equal(s.status, 200);
  return { id: s.id, token: s.token, device: d, name: "" };
}

async function claimed(): Promise<Player> {
  const p = await device();
  p.name = "Pw" + TAG + ++counter;
  assert.equal((await rpc(p, "claim_username", { username: p.name, age_band: "13_plus" })).ok, true);
  return p;
}

async function deleteAccount(p: Player, password?: string): Promise<Json> {
  const first = await rpc(p, "delete_account", {});
  return first.ok ? await rpc(p, "delete_account", { confirm: first.confirm, password }) : first;
}

// The asking account must be a few seconds old (a brand-new one asking at once is a throwaway's pattern).
async function aged(p: Player): Promise<Player> {
  for (let i = 0; i < 40; i++) {
    const r = await rpc(p, "sign_in_with_password", { username: "Nobody" + TAG, password: "x", device_id: "ptest-" + randomUUID() });
    if (r.error !== "too_new") {
      return p;
    }
    await new Promise((done) => setTimeout(done, 1000));
  }
  throw new Error("the asking account never got old enough");
}

test("the module has passwords (0.2.20)", async () => {
  const p = await device();
  const r = await rpc(p, "password", { action: "state" });
  assert.deepEqual(r, { ok: true, has_password: false, tried_ms: 0 });
  await deleteAccount(p);
});

test("a password made on the phone logs the computer in, and the phone out: its id can't make a new account", { timeout: 120_000 }, async () => {
  const phone = await claimed();
  assert.deepEqual(await rpc(phone, "password", { action: "set", password: "123456" }), { ok: false, error: "too_common" });
  assert.deepEqual(await rpc(phone, "password", { action: "set", password: PW }), { ok: true });
  const computer = await aged(await device());
  assert.deepEqual(await rpc(computer, "sign_in_with_password", { username: phone.name, password: "wrong-" + TAG,
    device_id: "ptest-" + randomUUID() }, { "X-Forwarded-For": "203.0.113.77" }), { ok: false, error: "wrong_password" });
  const newId = "ptest-" + randomUUID();
  const r = await rpc(computer, "sign_in_with_password", { username: phone.name.toLowerCase(), password: PW, device_id: newId },
    { "X-Forwarded-For": "203.0.113.77" });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.user_id, phone.id);
  assert.equal(r.left, "kept", "the device keeps its own asking account for the next LOG IN");
  const there = await signIn(newId, false);
  assert.equal(there.id, phone.id, "the computer plays as the account");
  assert.equal((await signIn(phone.device, false)).status, 403, "the phone is logged out: its tombstoned id is refused (device_logged_out)");
  assert.equal((await signIn(phone.device, true)).status, 403, "and create=true makes no new account for it either");
  const first = await rpc({ ...phone, token: there.token }, "delete_account", {});
  assert.equal((await rpc({ ...phone, token: there.token }, "delete_account", { confirm: first.confirm })).error, "password_needed");
  const gone = await rpc({ ...phone, token: there.token }, "delete_account", { confirm: first.confirm, password: PW });
  assert.equal(gone.deleted, true, JSON.stringify(gone));
  assert.equal((await signIn(newId, true)).status, 403, "deleted: its devices are tombstoned, nothing signs in or makes an account");
});

test("a name nobody has answers as slowly as a real name with a wrong password (no timing tell)", { timeout: 180_000 }, async () => {
  const anna = await claimed();
  assert.deepEqual(await rpc(anna, "password", { action: "set", password: PW }), { ok: true });
  const asker = await aged(await device());
  const time = async (username: string): Promise<number> => {
    const t0 = performance.now();
    const r = await rpc(asker, "sign_in_with_password", { username, password: "wrong-" + randomUUID().slice(0, 8),
      device_id: "ptest-" + randomUUID() });
    assert.equal(r.error, "wrong_password", JSON.stringify(r));
    return performance.now() - t0;
  };
  const nobody: number[] = [];
  const real: number[] = [];
  for (let i = 0; i < 4; i++) {
    nobody.push(await time("Nobody" + TAG + "t" + i));
    real.push(await time(anna.name));
  }
  const median = (xs: number[]) => xs.slice().sort((a, b) => a - b)[Math.floor(xs.length / 2)];
  const ratio = median(nobody) / median(real);
  console.log("nobody ms", nobody.map((x) => x.toFixed(0)).join(","), "real ms", real.map((x) => x.toFixed(0)).join(","));
  assert.ok(ratio > 0.6 && ratio < 1.6, "the two answers take about as long: ratio " + ratio.toFixed(2));
  await deleteAccount(anna, PW);
  await deleteAccount(asker);
});

test("LOG OUT unlinks this device (refused for good after) and LOG IN with the password brings the account back", { timeout: 120_000 }, async () => {
  const phone = await claimed();
  assert.equal((await rpc(phone, "log_out", { device_id: phone.device })).error, "password_needed", "a password first");
  assert.deepEqual(await rpc(phone, "password", { action: "set", password: PW }), { ok: true });
  assert.deepEqual(await rpc(phone, "log_out", { device_id: phone.device }), { ok: true });
  assert.equal((await signIn(phone.device, true)).status, 403, "the logged-out id is refused: no new account for it");
  const asker = await aged(await device());
  const newId = "ptest-" + randomUUID();
  const r = await rpc(asker, "sign_in_with_password", { username: phone.name, password: PW, device_id: newId });
  assert.equal(r.ok, true, JSON.stringify(r));
  const back = await signIn(newId, false);
  assert.equal(back.id, phone.id, "the same account again");
  assert.equal((await deleteAccount({ ...phone, token: back.token }, PW)).deleted, true);
  await deleteAccount(asker);
});
