// Owner #67 (spec §17.1): the account's profile on the server. A game writes its own profile backup
// (profiles/profile) itself, so the server checks every write: a JSON object of sane size and shape,
// never the gold (the wallet ledger keeps that), never what fits only one device, the account's own
// name and age band. Unknown fields a newer game adds pass (within the same limits).
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const P = S.ProfileRules;
const ACCOUNT = { username: "Sasa_7", age_band: "under_13" };

function backup(extra: object = {}): any {
  return {
    version: 1, backup: 2, username: "Sasa_7", age_band: "under_13", updated_at: 1_800_000_000,
    settings: { volume: 0.5, style: "blocky", simple_controls: true },
    avatar: { hair: "short", hat: "none" }, cosmetics: ["hat.party"], codes_redeemed: [], universe_unlocked: 3,
    secret_book: { treasure: 4 }, treasures: [512], progress: { xp: 1200, badges: ["first_home"] },
    stamps: { look: 1_800_000_000 },
    ...extra,
  };
}

function clean(value: unknown, account: object = ACCOUNT): any {
  const r = P.clean(typeof value === "string" ? value : JSON.stringify(value), account);
  return r.value !== undefined ? { value: JSON.parse(r.value) } : r;
}

test("an honest backup passes as it is", () => {
  const b = backup();
  assert.deepEqual(clean(b).value, b);
});

test("the gold never travels in the profile: the wallet ledger keeps it", () => {
  const r = clean(backup({ survivor_gold: 999_999_999 }));
  assert.equal(r.value.survivor_gold, undefined);
});

test("what fits only one device stays there: graphics, the install card, the farm note, moved buttons, boy or girl", () => {
  const r = clean(backup({
    settings: { volume: 0.5, graphics: "high", view_distance: 256, show_fps: true, install_not_now: 2, install_asked_at: 5,
      farm_note: true },
    hud_moves: { big: { jump: [1, 2] } }, farm_note_at: 1_800_000_000,
    avatar: { hair: "short", base: "girl" },
  }));
  assert.deepEqual(r.value.settings, { volume: 0.5 });
  assert.equal(r.value.hud_moves, undefined);
  assert.equal(r.value.farm_note_at, undefined);
  assert.deepEqual(r.value.avatar, { hair: "short" });
});

test("the name and the age band are the account's, whatever the game wrote", () => {
  const r = clean(backup({ username: "Someone_else", age_band: "13_plus" }));
  assert.equal(r.value.username, "Sasa_7");
  assert.equal(r.value.age_band, "under_13");
  const teen = clean(backup({ age_band: "under_13" }), { username: "Teen_1", age_band: "13_plus" });
  assert.equal(teen.value.age_band, "13_plus");
  const none = clean(backup({ age_band: "13_plus" }), { username: "New_1", age_band: "" });
  assert.equal(none.value.age_band, "13_plus", "an account without a band yet keeps the game's valid one");
  assert.equal(clean(backup({ age_band: "adult" }), { username: "New_1", age_band: "" }).value.age_band, undefined);
});

test("not a profile: refused", () => {
  for (const bad of ["", "x", "[]", "null", "12", '"text"']) {
    assert.deepEqual(P.clean(bad, ACCOUNT), { error: "bad_profile" }, bad);
  }
  assert.deepEqual(P.clean(undefined, ACCOUNT), { error: "bad_profile" });
  assert.deepEqual(clean({ username: "Sasa_7" }), { error: "bad_profile" }, "no version");
  for (const v of [0, 100, 1.5, "1", -1]) {
    assert.deepEqual(clean(backup({ version: v })), { error: "bad_profile" }, "version " + v);
  }
  assert.deepEqual(clean(backup({ backup: "2" })), { error: "bad_profile" }, "the backup's layout number is a whole number");
});

test("too big: refused before it is read", () => {
  assert.deepEqual(P.clean("{" + " ".repeat(P.MAX_CHARS) + "}", ACCOUNT), { error: "too_big" });
});

// Owner #70/#71 (2026-09-29): the School grows to every subject of every grade (SchoolData.MAX_UNITS, 4000 units).
// A child who has practised all of them still backs up: its progress is one object with a key per unit.
test("a School with 4000 practised units passes", () => {
  const units: any = {};
  for (let i = 0; i < 4000; i++) {
    units[`g${3 + (i % 6)}.geography.unit_number_${i}`] =
      { l: true, s: 3, r: 12, a: 72, f: 60, b: 100, x: 3, d: 20400, t: 20380, m: 20370, p: true };
  }
  const b = backup({ school: { grade: 5, locked: false, units } });
  assert.ok(JSON.stringify(b).length < P.MAX_CHARS, `${JSON.stringify(b).length} characters`);
  assert.equal(Object.keys(clean(b).value.school.units).length, 4000);
});

test("known fields of the wrong kind are dropped; the rest stays", () => {
  const r = clean(backup({ cosmetics: "hat.party", settings: [1, 2], universe_unlocked: "lots", progress: 5, stamps: [] }));
  for (const key of ["cosmetics", "settings", "universe_unlocked", "progress", "stamps"]) {
    assert.equal(r.value[key], undefined, key);
  }
  assert.equal(r.value.secret_book.treasure, 4);
});

test("settings are plain values only", () => {
  const r = clean(backup({ settings: { volume: 0.5, style: "x".repeat(65), nested: { a: 1 }, list: [1], ok: false } }));
  assert.deepEqual(r.value.settings, { volume: 0.5, ok: false });
});

test("a newer game's own fields pass, within the same limits", () => {
  assert.deepEqual(clean(backup({ school: { grade: 4, done: ["fractions"] } })).value.school, { grade: 4, done: ["fractions"] });
  assert.deepEqual(clean(backup({ "Bad Key": 1 })).value["Bad Key"], undefined, "an odd field name is dropped");
});

test("shape limits: depth, list length, keys, text length, finite numbers", () => {
  let deep: any = 1;
  for (let i = 0; i < P.MAX_DEPTH + 1; i++) {
    deep = { a: deep };
  }
  assert.deepEqual(clean(backup({ wonder: deep })), { error: "bad_profile" }, "too deep");
  assert.deepEqual(clean(backup({ treasures: new Array(P.MAX_LIST + 1).fill(1) })), { error: "bad_profile" }, "too long a list");
  const many: any = {};
  for (let i = 0; i <= P.MAX_KEYS; i++) {
    many["k" + i] = 1;
  }
  assert.deepEqual(clean(backup({ secret_book: many })), { error: "bad_profile" }, "too many keys");
  assert.deepEqual(clean(backup({ pip: { name: "x".repeat(P.MAX_TEXT + 1) } })), { error: "bad_profile" }, "too long a text");
  assert.deepEqual(P.clean(JSON.stringify(backup()).replace('"xp":1200', '"xp":1e999'), ACCOUNT), { error: "bad_profile" },
    "not a finite number");
  const top: any = backup();
  for (let i = 0; i < P.MAX_FIELDS; i++) {
    top["extra_" + i] = 1;
  }
  assert.deepEqual(clean(top), { error: "bad_profile" }, "too many fields");
});
