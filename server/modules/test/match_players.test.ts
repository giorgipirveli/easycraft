// match_players (the M4 Task 10 review's finding B, module 0.2.11): online, the host's game took each guest's name
// and age band from the guest's own game (chat_join) for its relay chat, trades and name tags; a modified guest
// could show another name or claim 13+. The host now asks the server who is in the relayed match it hosts: each
// player's username, age band and chat level from their account (only the server writes those). Only the match's
// host may ask, as get_gold_of's host check (Economy.target).
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const TEEN = A.defaults("13_plus");
const KID_WITH_CONSENT = { age_band: "under_13", consent: "verified", online_allowed: true, chat: "quick" };

let nk: FakeNakama;
let log: FakeLogger;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  S.Server.nowMs = () => 5_000_000;
});

function call(fn: string, userId: string, payload: unknown = {}): any {
  return JSON.parse(S[fn](ctx(userId), log, nk, typeof payload === "string" ? payload : JSON.stringify(payload)));
}

// A host in its relayed match (the after-create hook's record) with these guests in it.
function hosted(...guests: string[]): { host: string; match: string } {
  const host = nk.addUser("Hostie", TEEN);
  const match = nk.createMatch(host);
  S.afterMatchCreate(ctx(host), log, nk, { match: { matchId: match, self: { userId: host } } }, { matchCreate: {} });
  for (const g of guests) {
    nk.joinMatch(match, g);
  }
  return { host, match };
}

function byId(players: any[]): { [id: string]: any } {
  const out: { [id: string]: any } = {};
  for (const p of players) {
    out[p.user_id] = p;
  }
  return out;
}

test("match_players: the host gets everyone in its match with the server's name, band and chat level", () => {
  const kid = nk.addUser("Kiddo", KID_WITH_CONSENT);
  const teen = nk.addUser("Teeny", { ...TEEN, chat: "quick" }); // a grown-up chose QUICK for this 13+ player
  const { host, match } = hosted(kid, teen);
  const r = call("rpcMatchPlayers", host, { match_id: match });
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.players.length, 3, "the host too");
  const p = byId(r.players);
  assert.deepEqual(p[kid], { user_id: kid, username: "Kiddo", age_band: "under_13", chat_level: "quick" });
  assert.deepEqual(p[teen], { user_id: teen, username: "Teeny", age_band: "13_plus", chat_level: "quick" });
  assert.deepEqual(p[host], { user_id: host, username: "Hostie", age_band: "13_plus", chat_level: "filtered" });
});

test("match_players: the strictest reading of a broken or unclaimed account", () => {
  const odd = nk.addUser("Oddly", { age_band: "adult", chat: "shout" });
  const off = nk.addUser("Quiet", { ...TEEN, chat: "off" }); // a grown-up switched chat off
  const { host, match } = hosted(odd, off);
  const p = byId(call("rpcMatchPlayers", host, { match_id: match }).players);
  assert.equal(p[odd].age_band, "under_13", "no band on the server: the child's rules");
  assert.equal(p[odd].chat_level, "off");
  assert.equal(p[off].age_band, "13_plus");
  assert.equal(p[off].chat_level, "off", "a grown-up's chat off holds");
});

test("match_players: a player who left is not in it", () => {
  const guest = nk.addUser("Guesty", TEEN);
  const { host, match } = hosted(guest);
  nk.leaveMatch(match, guest);
  const r = call("rpcMatchPlayers", host, { match_id: match });
  assert.deepEqual(r.players.map((x: any) => x.user_id), [host]);
});

test("match_players: only the host of that match may ask", () => {
  const guest = nk.addUser("Guesty", TEEN);
  const { host, match } = hosted(guest);
  assert.deepEqual(call("rpcMatchPlayers", guest, { match_id: match }), { ok: false, error: "not_host" }, "a guest");
  const stranger = nk.addUser("Strngr", TEEN);
  const theirs = nk.createMatch(stranger);
  assert.deepEqual(call("rpcMatchPlayers", host, { match_id: theirs }), { ok: false, error: "not_host" },
    "someone else's match");
  nk.leaveMatch(match, host);
  assert.deepEqual(call("rpcMatchPlayers", host, { match_id: match }), { ok: false, error: "not_host" },
    "a host who left its own match");
  assert.deepEqual(call("rpcMatchPlayers", host, { match_id: "junk" }), { ok: false, error: "bad_request" });
  assert.deepEqual(call("rpcMatchPlayers", host, {}), { ok: false, error: "bad_request" });
});

test("the module is 0.2.12 (0.2.11 or later) and registers match_players", () => {
  const registered: string[] = [];
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  assert.ok(registered.includes("match_players"));
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});
