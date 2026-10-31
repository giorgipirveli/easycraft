// M4 Wave 3, agent I (spec §17.5 research additions; docs/design T3, T4, D5): the pure rules behind
// blueprint gifts, showcase visits with guestbook stickers and bottle mail. A build travels as one
// base64 text (BuildRules, the same format as the game's core/gifts/build_codec.gd: a version byte,
// the box's size, then runs of (count, block id) as unsigned LEB128, cells x fastest, then z, then
// y); the server decodes every build it keeps, so sizes and block ids are its own check, never the
// game's word.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const B = S.BuildRules;
const G = S.GiftRules;
const DAY = 24 * 60 * 60 * 1000;
const MINUTE = 60 * 1000;

// A build of size [sx, sy, sz] from its cells (x fastest, then z, then y), as the game encodes it.
function build(size: number[], cells: number[]): string {
  return B.encode(size, cells);
}

function cellsOf(size: number[], fill: (x: number, y: number, z: number) => number): number[] {
  const out: number[] = [];
  for (let y = 0; y < size[1]; y++) {
    for (let z = 0; z < size[2]; z++) {
      for (let x = 0; x < size[0]; x++) {
        out.push(fill(x, y, z));
      }
    }
  }
  return out;
}

// --- base64 and the byte format ---

test("BuildRules: base64 both ways, and anything else is refused", () => {
  const bytes = [0, 1, 2, 250, 251, 252, 253, 254, 255, 64, 65];
  for (let n = 0; n <= bytes.length; n++) {
    const part = bytes.slice(0, n);
    const text = B.base64Encode(part);
    assert.equal(text, Buffer.from(part).toString("base64"), "standard base64 with padding");
    assert.deepEqual(B.base64Decode(text), part);
  }
  for (const bad of ["abc", "ab!d", "a===", "=abc", "ab=c", "ab c", 5, null, undefined]) {
    assert.equal(B.base64Decode(bad), null, String(bad));
  }
  assert.deepEqual(B.base64Decode(""), []);
});

test("BuildRules: the game's format: version 1, the size, then runs of (count, id) in LEB128", () => {
  // 2 x 1 x 1: planks then air -> [1, 2, 1, 1, run 1 x 6, run 1 x 0]
  const text = build([2, 1, 1], [6, 0]);
  assert.deepEqual(B.base64Decode(text), [1, 2, 1, 1, 1, 6, 1, 0]);
  // 200 cells of id 200: a two-byte count and a two-byte id
  const big = build([10, 2, 10], new Array(200).fill(200));
  assert.deepEqual(B.base64Decode(big), [1, 10, 2, 10, 0xc8, 0x01, 0xc8, 0x01]);
  const d = B.decode(big, G.SHOWCASE);
  assert.deepEqual(d.build.size, [10, 2, 10]);
  assert.equal(d.build.count, 200);
  assert.equal(d.build.cells.length, 200);
  assert.equal(d.build.cells[199], 200);
});

test("BuildRules: block ids are the game's blocks: never an item (100-175, 400-511) and never bedrock", () => {
  // owner #45b: 256-399 are blocks too; cosmos: block pages go on past the items (Titan's page 29 is 512-527)
  for (const id of [0, 1, 6, 17, 19, 99, 176, 208, 255, 256, 271, 399, 512, 522, 527, 1023]) {
    assert.equal(B.isBlockId(id), true, String(id));
  }
  for (const id of [18, 100, 101, 150, 175, 400, 451, 499, 511, 1024, -1, 1.5, "6", null]) {
    assert.equal(B.isBlockId(id), false, String(id));
  }
});

test("BuildRules: a build decodes only when it is whole and inside the limits", () => {
  const house = cellsOf([3, 3, 3], (x, y, z) => (y === 0 || x === 1 ? 6 : 0));
  const ok = B.decode(build([3, 3, 3], house), G.GIFT);
  assert.equal(ok.error, undefined, JSON.stringify(ok));
  assert.equal(ok.build.count, house.filter((c) => c !== 0).length);
  const cases: [unknown, string][] = [
    [5, "bad_build"],
    ["not base64!", "bad_build"],
    [B.base64Encode([2, 1, 1, 1, 1, 6]), "bad_build"],               // an unknown version
    [B.base64Encode([1, 0, 1, 1]), "bad_build"],                     // a side of 0
    [B.base64Encode([1, 2, 1, 1, 1, 6]), "bad_build"],               // one cell missing
    [B.base64Encode([1, 1, 1, 1, 2, 6]), "bad_build"],               // one cell too many
    [B.base64Encode([1, 1, 1, 1, 1, 6, 9]), "bad_build"],            // bytes after the last run
    [B.base64Encode([1, 1, 1, 1, 0, 6, 1, 6]), "bad_build"],         // a run of nothing
    [B.base64Encode([1, 1, 1, 1, 1, 18]), "bad_build"],              // bedrock
    [B.base64Encode([1, 1, 1, 1, 1, 0x86]), "bad_build"],             // a varint cut short
    [build([1, 1, 1], [110]), "bad_build"],                          // a sword is no block
    [build([1, 1, 1], [0]), "empty_build"],
    [build([9, 1, 1], new Array(9).fill(6)), "too_big"],            // a gift's side is at most 8
  ];
  for (const [raw, code] of cases) {
    assert.equal(B.decode(raw, G.GIFT).error, code, JSON.stringify(raw));
  }
  // At most 512 blocks in a gift: 8 x 8 x 8 full is exactly the cap.
  assert.equal(B.decode(build([8, 8, 8], new Array(512).fill(9)), G.GIFT).error, undefined);
  // The text itself is capped too (a gift fits one small RPC).
  assert.equal(B.decode("A".repeat(G.GIFT.maxText + 4), G.GIFT).error, "too_big");
});

test("GiftRules: the limits of each kind of build", () => {
  assert.deepEqual([G.GIFT.maxDim, G.GIFT.maxCount], [8, 512]);
  assert.deepEqual([G.BOTTLE.maxDim, G.BOTTLE.maxCount], [4, 64]);
  assert.deepEqual([G.SHOWCASE.maxDim, G.SHOWCASE.maxCount], [32, 32 * 32 * 32]);
  assert.deepEqual([G.BUDDY.maxDim, G.BUDDY.maxCount], [17, 200]);
  // The worst gift (every cell a new run of a two-byte id) still fits the text cap.
  const worst = build([8, 8, 8], cellsOf([8, 8, 8], (x, y, z) => ((x + y + z) % 2 === 0 ? 200 : 201)));
  assert.ok(worst.length <= G.GIFT.maxText, String(worst.length));
  assert.equal(B.decode(build([5, 1, 1], new Array(5).fill(6)), G.BOTTLE).error, "too_big");
  assert.equal(B.decode(build([33, 1, 1], new Array(33).fill(6)), G.SHOWCASE).error, "too_big");
});

// --- Stickers, the guestbook, rate windows, keys ---

test("GiftRules: stickers are a preset list (no free text anywhere)", () => {
  assert.deepEqual(G.STICKERS, ["star", "heart", "smile", "wow", "thumbs_up", "rainbow", "trophy", "flower"]);
  assert.equal(G.isSticker("star"), true);
  for (const bad of ["Star", "star ", "hello", "", 5, null]) {
    assert.equal(G.isSticker(bad), false, String(bad));
  }
});

test("GiftRules: a guestbook keeps the newest 30 stickers of the last 60 days; one visitor every 10 minutes", () => {
  const now = 1_790_000_000_000;
  let book = G.bookFrom(undefined, now);
  assert.deepEqual(book.entries, []);
  const entry = (from: string, at: number, id: string) => ({ entry_id: id, from_id: from, from_username: "P_" + from, sticker: "star", at_ms: at });
  let r = G.sign(book, entry("a", now, "e1"), now);
  assert.equal(r.error, undefined);
  book = r.book;
  assert.equal(G.sign(book, entry("a", now + 9 * MINUTE, "e2"), now + 9 * MINUTE).error, "too_fast");
  r = G.sign(book, entry("a", now + 10 * MINUTE, "e3"), now + 10 * MINUTE);
  assert.equal(r.error, undefined, "the same visitor again after 10 minutes");
  book = r.book;
  for (let i = 0; i < 40; i++) {
    book = G.sign(book, entry("v" + i, now + 11 * MINUTE + i, "x" + i), now + 11 * MINUTE + i).book;
  }
  assert.equal(book.entries.length, G.GUESTBOOK_MAX);
  assert.equal(book.entries[book.entries.length - 1].entry_id, "x39", "newest last");
  assert.equal(book.oldest_ms, book.entries[0].at_ms);
  // Old stickers go when the book is read: 60 days.
  const later = G.bookFrom(book, book.entries[0].at_ms + 60 * DAY);
  assert.equal(later.entries.length, G.GUESTBOOK_MAX - 1);
  // A broken entry never comes back out.
  const messy = G.bookFrom({ entries: [entry("a", now, "ok1"), { entry_id: "bad", sticker: "free text", at_ms: now },
    { ...entry("b", now, "e"), from_username: 5 }, "x"] }, now);
  assert.deepEqual(messy.entries.map((e: any) => e.entry_id), ["ok1"]);
  // Removing one.
  assert.equal(G.remove(messy, "nope"), null);
  assert.deepEqual(G.remove(messy, "ok1").entries, []);
});

test("GiftRules: send windows and keys", () => {
  const now = 1_790_000_000_000;
  let times: number[] = [];
  for (let i = 0; i < 3; i++) {
    const r = G.allow(times, now + i, 3, 60 * MINUTE);
    assert.equal(r.ok, true);
    times = r.times;
  }
  assert.equal(G.allow(times, now + 5, 3, 60 * MINUTE).ok, false);
  assert.equal(G.allow(times, now + 60 * MINUTE, 3, 60 * MINUTE).ok, true, "an hour later");
  assert.deepEqual(G.timesFrom({ times: [1, "2", 3.5, 4] }), [1, 4]);
  assert.match(G.keyFor("g", now, "0123abcd-0000-4000-8000-000000000000"), /^g1790000000000_[0-9a-f]{12}$/);
  assert.equal(G.expired(now - 60 * DAY, now), true);
  assert.equal(G.expired(now - 60 * DAY + 1, now), false);
  assert.equal(G.KEEP_DAYS, 60);
});
