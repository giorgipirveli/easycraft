// A build as it travels between the game and the server (M4 Wave 3, agent I): blueprint gifts,
// showcases, the tiny builds in bottles, a buddy waving in a showcase. One base64 text in the game's
// format (core/gifts/build_codec.gd, BuildCodec): a version byte (1), the box's size (three bytes,
// 1-255), then runs of (count, block id) as unsigned LEB128 until every cell of the box is covered;
// cells x fastest, then z, then y. The server decodes every build it keeps: the size, the number of
// blocks and every id are its own check, never the game's word.
//
// Block ids share one int space with items (docs/DEVELOPMENT.md §5): blocks are 1-99, 176-399 and 512-1023
// (cosmos: block pages go on past the items; Titan's page 29 is 512-527), items 100-175 and 400-511. A build never
// holds an item (a block at an item's id turns into that item
// when broken) and never bedrock (it can't be broken). tests/unit/test_build_codec.gd keeps the
// game's list and these numbers in step.

namespace BuildRules {
  export const VERSION = 1;
  export const BEDROCK = 18;
  export const ITEM_FIRST = 100;
  export const ITEM_LAST = 175;
  export const RESERVED_FIRST = 400; // cosmos: 400-511 stay the items' forever (the game's BlockIds.RESERVED_FIRST) ...
  export const RESERVED_END = 512; // ... (the first id past them)
  export const BLOCK_MAX = 1023; // owner #45b: 256-399; cosmos: block pages go on past the items (Titan's 512-527)
  const MAX_VARINT_BYTES = 3; // values below 2^21: a run never covers more than 32^3 cells
  const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  export interface Limits {
    maxDim: number; // each side of the box
    maxCount: number; // blocks that are not air
    maxText: number; // characters of base64
  }

  export interface Decoded {
    size: number[];
    count: number;
    cells: number[]; // the id of every cell, in the format's order
  }

  export function isBlockId(id: unknown): boolean {
    return (
      Util.isInt(id) &&
      id >= 0 &&
      id <= BLOCK_MAX &&
      id !== BEDROCK &&
      !(id >= ITEM_FIRST && id <= ITEM_LAST) &&
      !(id >= RESERVED_FIRST && id < RESERVED_END)
    );
  }

  export function base64Encode(bytes: number[]): string {
    let out = "";
    for (let i = 0; i < bytes.length; i += 3) {
      const a = bytes[i];
      const b = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const c = i + 2 < bytes.length ? bytes[i + 2] : 0;
      out += CHARS.charAt(a >> 2) + CHARS.charAt(((a & 3) << 4) | (b >> 4));
      out += i + 1 < bytes.length ? CHARS.charAt(((b & 15) << 2) | (c >> 6)) : "=";
      out += i + 2 < bytes.length ? CHARS.charAt(c & 63) : "=";
    }
    return out;
  }

  // Standard base64 with padding; null for anything else.
  export function base64Decode(text: unknown): number[] | null {
    if (typeof text !== "string" || text.length % 4 !== 0) {
      return null;
    }
    let pad = 0;
    while (pad < 2 && pad < text.length && text.charAt(text.length - 1 - pad) === "=") {
      pad++;
    }
    const out: number[] = [];
    let bits = 0;
    let value = 0;
    for (let i = 0; i < text.length - pad; i++) {
      const v = CHARS.indexOf(text.charAt(i));
      if (v < 0) {
        return null;
      }
      value = (value << 6) | v;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.push((value >> bits) & 255);
        value &= (1 << bits) - 1;
      }
    }
    // The bits left over must be the zero fill of the last character.
    return value === 0 ? out : null;
  }

  function readVarint(bytes: number[], at: number): { value: number; next: number } | null {
    let value = 0;
    for (let k = 0; k < MAX_VARINT_BYTES; k++) {
      if (at + k >= bytes.length) {
        return null;
      }
      const b = bytes[at + k];
      value += (b & 127) * Math.pow(128, k);
      if ((b & 128) === 0) {
        return { value: value, next: at + k + 1 };
      }
    }
    return null;
  }

  function pushVarint(out: number[], value: number): void {
    let v = value;
    while (v >= 128) {
      out.push((v & 127) | 128);
      v = Math.floor(v / 128);
    }
    out.push(v);
  }

  // The build of a text, checked against `limits`: {build} or {error: "bad_build" | "too_big" |
  // "empty_build"}.
  export function decode(raw: unknown, limits: Limits): { build?: Decoded; error?: string } {
    if (typeof raw !== "string" || raw === "") {
      return { error: "bad_build" };
    }
    if (raw.length > limits.maxText) {
      return { error: "too_big" };
    }
    const bytes = base64Decode(raw);
    if (bytes === null || bytes.length < 4 || bytes[0] !== VERSION) {
      return { error: "bad_build" };
    }
    const size = [bytes[1], bytes[2], bytes[3]];
    if (size[0] === 0 || size[1] === 0 || size[2] === 0) {
      return { error: "bad_build" };
    }
    if (size[0] > limits.maxDim || size[1] > limits.maxDim || size[2] > limits.maxDim) {
      return { error: "too_big" };
    }
    const total = size[0] * size[1] * size[2];
    const cells: number[] = [];
    let count = 0;
    let at = 4;
    while (cells.length < total) {
      const n = readVarint(bytes, at);
      if (n === null || n.value === 0 || cells.length + n.value > total) {
        return { error: "bad_build" };
      }
      const id = readVarint(bytes, n.next);
      if (id === null || !isBlockId(id.value)) {
        return { error: "bad_build" };
      }
      for (let i = 0; i < n.value; i++) {
        cells.push(id.value);
      }
      if (id.value !== 0) {
        count += n.value;
        if (count > limits.maxCount) {
          return { error: "too_big" };
        }
      }
      at = id.next;
    }
    if (at !== bytes.length) {
      return { error: "bad_build" };
    }
    if (count === 0) {
      return { error: "empty_build" };
    }
    return { build: { size: size, count: count, cells: cells } };
  }

  // The text of a box of `size` with these cells (the format's order). The game makes builds; the
  // server uses this in tests.
  export function encode(size: number[], cells: number[]): string {
    const out: number[] = [VERSION, size[0], size[1], size[2]];
    let i = 0;
    while (i < cells.length) {
      let j = i + 1;
      while (j < cells.length && cells[j] === cells[i]) {
        j++;
      }
      pushVarint(out, j - i);
      pushVarint(out, cells[i]);
      i = j;
    }
    return base64Encode(out);
  }
}
