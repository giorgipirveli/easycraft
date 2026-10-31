// M4 ghost races (docs/design T2 "my friend races my ghost and gets bronze; I have gold"; spec §17.5):
// the pure rules of a shared ghost. A ghost is a player's best run on a course they built (M3 Task 7's
// recorded run), sampled 5 times a second and kept small; the server checks that it belongs to the
// course it is shared with (its START and FINISH are there) and that a child could really have run it:
// it starts on START, ends on FINISH, never moves faster than the game's fastest way to move, and only
// "jumps" onto a START, CHECKPOINT or TELEPORT_PAD (a fall brings a runner back to the checkpoint; a
// teleport pad moves them). The path format is the game's (core/ghosts/race_ghost.gd, RaceGhost): three
// little-endian int16 decimetres per sample, from the top of the START block, in base64.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const S = server();
const H = S.GhostRules;
const START = 203;
const CHECKPOINT = 204;
const FINISH = 205;
const TELEPORT_PAD = 202;
const STONE = 1;

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

// A 12 x 4 x 12 course: a stone floor, START at (1, 0, 1), FINISH at (9, 0, 9), a CHECKPOINT at (5, 0, 5)
// and a TELEPORT_PAD at (1, 0, 9).
const SIZE = [12, 4, 12];
const CELLS = cellsOf(SIZE, (x, y, z) => {
  if (y !== 0) {
    return 0;
  }
  if (x === 1 && z === 1) {
    return START;
  }
  if (x === 9 && z === 9) {
    return FINISH;
  }
  if (x === 5 && z === 5) {
    return CHECKPOINT;
  }
  if (x === 1 && z === 9) {
    return TELEPORT_PAD;
  }
  return STONE;
});

// Samples (decimetres from START's top) along straight lines through `corners`, `ms` long.
function walk(corners: number[][], ms: number): number[][] {
  const n = H.sampleCount(ms);
  const legs: number[] = [];
  let total = 0;
  for (let i = 0; i + 1 < corners.length; i++) {
    const d = Math.hypot(corners[i + 1][0] - corners[i][0], corners[i + 1][1] - corners[i][1], corners[i + 1][2] - corners[i][2]);
    legs.push(d);
    total += d;
  }
  const out: number[][] = [];
  for (let k = 0; k < n; k++) {
    let along = total * k / (n - 1);
    let i = 0;
    while (i < legs.length - 1 && along > legs[i]) {
      along -= legs[i];
      i++;
    }
    const f = legs[i] > 0 ? Math.min(1, along / legs[i]) : 0;
    out.push([0, 1, 2].map((a) => Math.round(corners[i][a] + (corners[i + 1][a] - corners[i][a]) * f)));
  }
  return out;
}

// START's top is the origin; FINISH's top is (8, 0, 8) blocks away: (80, 0, 80) decimetres.
const TO_FINISH = [80, 0, 80];

function ghost(points: number[][], ms: number, extra: object = {}): object {
  return { start: [1, 0, 1], finish: [9, 0, 9], ms: ms, path: H.encodePath(points), look: "", ...extra };
}

function check(g: unknown): any {
  return H.check(g, SIZE, CELLS);
}

test("GhostRules: the limits follow from the samples (5 a second, at most 3 minutes)", () => {
  assert.equal(H.SAMPLE_MS, 200);
  assert.equal(H.MIN_MS, 1000, "CourseRules.MIN_GOAL_MS");
  assert.equal(H.MAX_MS, 180000, "RecordedRun: 3 minutes");
  assert.equal(H.MAX_SAMPLES, H.MAX_MS / H.SAMPLE_MS + 1);
  assert.equal(H.MAX_PATH_TEXT, Math.ceil(H.MAX_SAMPLES * 6 / 3) * 4, "the base64 of the longest path");
  assert.equal(H.MAX_LOOK, 2048, "AvatarLook.MAX_CODE_LENGTH");
  assert.ok(H.PAYLOAD >= H.MAX_PATH_TEXT + H.MAX_LOOK + 2800 + 512, "a gift's build and its ghost fit one call");
  assert.equal(H.sampleCount(1000), 6);
  assert.equal(H.sampleCount(1650), 9);
  assert.equal(H.sampleCount(180000), H.MAX_SAMPLES);
});

test("GhostRules: the path's bytes both ways (int16 little-endian triplets, base64), and anything else refused", () => {
  const points = [[0, 0, 0], [-1, 2, -3], [32767, -32768, 12], [80, 0, 80]];
  const text = H.encodePath(points);
  assert.equal(text, Buffer.from(Int16Array.from(points.flat()).buffer).toString("base64"), "the game's bytes");
  assert.deepEqual(H.decodePath(text), points);
  assert.equal(H.decodePath("abc"), null, "not base64");
  assert.equal(H.decodePath(5), null);
  assert.equal(H.decodePath(Buffer.from([1, 2, 3, 4, 5, 6, 7]).toString("base64")), null, "not whole samples");
  assert.equal(H.decodePath(H.encodePath([[0, 0, 0]])), null, "at least two samples");
  const long = new Array(H.MAX_SAMPLES + 1).fill([0, 0, 0]);
  assert.equal(H.decodePath(H.encodePath(long)), null, "at most MAX_SAMPLES");
  assert.equal(H.decodePath(H.encodePath(long.slice(1))).length, H.MAX_SAMPLES);
});

test("GhostRules: a run a child could make is kept, as it came", () => {
  // 11.3 blocks at 6 m/s (a walk): about 1.9 s.
  const ms = 1900;
  const r = check(ghost(walk([[0, 0, 0], TO_FINISH], ms), ms, { look: "{\"hat\":\"cap\"}" }));
  assert.equal(r.error, undefined, JSON.stringify(r));
  assert.deepEqual(r.ghost.start, [1, 0, 1]);
  assert.deepEqual(r.ghost.finish, [9, 0, 9]);
  assert.equal(r.ghost.ms, ms);
  assert.equal(r.ghost.look, "{\"hat\":\"cap\"}");
  assert.equal(typeof r.ghost.path, "string");
  assert.equal(Object.keys(r.ghost).sort().join(","), "finish,look,ms,path,start", "nothing else is kept");
  // A jump up and over, and a slow wander: fine too.
  const slow = 20000;
  assert.equal(check(ghost(walk([[0, 0, 0], [0, 30, 40], [60, 0, 60], TO_FINISH], slow), slow)).error, undefined);
});

test("GhostRules: the shape must be whole (else bad_ghost)", () => {
  const ms = 1900;
  const good = ghost(walk([[0, 0, 0], TO_FINISH], ms), ms) as any;
  for (const bad of [null, 5, "x", [], {}]) {
    assert.equal(check(bad).error, "bad_ghost", JSON.stringify(bad));
  }
  for (const [key, value] of [["start", [1, 0]], ["start", [1, 0, 1.5]], ["start", [12, 0, 1]], ["start", [-1, 0, 1]],
    ["finish", "9,0,9"], ["finish", [9, 4, 9]], ["ms", "1900"], ["ms", 1900.5], ["ms", 999], ["ms", 180001],
    ["path", 7], ["path", "!!!!"], ["look", 7], ["look", "not json"], ["look", "[1,2]"], ["look", "x".repeat(2049)]] as [string, unknown][]) {
    assert.equal(check({ ...good, [key]: value }).error, "bad_ghost", key + " " + JSON.stringify(value).slice(0, 40));
  }
  assert.equal(check({ ...good, look: undefined }).error, undefined, "no look: the default avatar");
  // The samples must match the time: 5 a second.
  assert.equal(check({ ...good, ms: 4000 }).error, "bad_ghost", "too few samples for 4 s");
  assert.equal(check({ ...good, path: H.encodePath(walk([[0, 0, 0], TO_FINISH], 1000)) }).error, "bad_ghost", "too few for 1.9 s");
});

test("GhostRules: START and FINISH must be where the ghost says (else not_on_course)", () => {
  const ms = 1900;
  const points = walk([[0, 0, 0], TO_FINISH], ms);
  assert.equal(check(ghost(points, ms, { start: [2, 0, 1] })).error, "not_on_course", "stone, not START");
  assert.equal(check(ghost(points, ms, { finish: [5, 0, 5] })).error, "not_on_course", "a checkpoint, not FINISH");
  assert.equal(check(ghost(points, ms, { start: [9, 0, 9], finish: [1, 0, 1] })).error, "not_on_course", "the wrong way round");
});


test("GhostRules: it starts on START and ends on FINISH (else impossible_run)", () => {
  const ms = 3000;
  assert.equal(check(ghost(walk([[0, 0, 0], TO_FINISH], ms), ms)).error, undefined);
  assert.equal(check(ghost(walk([[35, 0, 0], TO_FINISH], ms), ms)).error, "impossible_run", "3.5 blocks off START");
  assert.equal(check(ghost(walk([[25, 0, 0], TO_FINISH], ms), ms)).error, undefined, "just stepped off it");
  assert.equal(check(ghost(walk([[0, 0, 0], [80, 0, 60]], ms), ms)).error, "impossible_run", "2 blocks short of FINISH");
});

// The points after `from` up to `to` (included), in `steps` equal steps.
function line(from: number[], to: number[], steps: number): number[][] {
  const out: number[][] = [];
  for (let k = 1; k <= steps; k++) {
    out.push([0, 1, 2].map((a) => Math.round(from[a] + (to[a] - from[a]) * k / steps)));
  }
  return out;
}

// A 210 x 2 x 3 straight course: START at x 0, a CHECKPOINT at x 100, FINISH at x 200 (all at z 1).
const LONG = [210, 2, 3];
const LONG_CELLS = cellsOf(LONG, (x, y, z) => {
  if (y !== 0) {
    return 0;
  }
  if (z === 1 && x === 0) {
    return START;
  }
  if (z === 1 && x === 100) {
    return CHECKPOINT;
  }
  if (z === 1 && x === 200) {
    return FINISH;
  }
  return STONE;
});

function long(points: number[][]): any {
  const ms = (points.length - 1) * H.SAMPLE_MS;
  return H.check({ start: [0, 0, 1], finish: [200, 0, 1], ms: ms, path: H.encodePath(points), look: "" }, LONG, LONG_CELLS);
}

test("GhostRules: never faster than the game's fastest move, and no teleports (else impossible_run)", () => {
  // 11.3 blocks in 1 s is 11 m/s: fine. The same in a single step is a teleport.
  const ms = 1000;
  assert.equal(check(ghost(walk([[0, 0, 0], TO_FINISH], ms), ms)).error, undefined);
  const hop = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], TO_FINISH];
  assert.equal(check(ghost(hop, ms)).error, "impossible_run", "straight onto FINISH");
  // 200 blocks: 40 m/s (8 blocks a step, a block of slack) is the limit; 9.1 blocks a step is not.
  assert.equal(long([[0, 0, 0]].concat(line([0, 0, 0], [2000, 0, 0], 25))).error, undefined, "40 m/s");
  assert.equal(long([[0, 0, 0]].concat(line([0, 0, 0], [2000, 0, 0], 22))).error, "impossible_run", "45 m/s");
});

test("GhostRules: a fall back to a checkpoint and a teleport pad's trip are the only jumps", () => {
  // Walk 7 blocks towards +z, fall 13 blocks, come back on the CHECKPOINT (40, 0, 40), walk to FINISH.
  const fall = [[0, 0, 0]].concat(line([0, 0, 0], [0, 0, 70], 10), line([0, 0, 70], [0, -130, 70], 5));
  const good = fall.concat([[40, 0, 40]], line([40, 0, 40], TO_FINISH, 14));
  const ms = (good.length - 1) * H.SAMPLE_MS;
  assert.equal(check(ghost(good, ms)).error, undefined, "back on the checkpoint");
  const nowhere = fall.concat([[90, 0, 10]], line([90, 0, 10], TO_FINISH, 14));
  assert.equal(check(ghost(nowhere, ms)).error, "impossible_run", "a jump to nowhere");
  const deep = [[0, 0, 0]].concat(line([0, 0, 0], [0, 0, 70], 10), line([0, 0, 70], [0, -210, 70], 5), [[40, 0, 40]],
    line([40, 0, 40], TO_FINISH, 14));
  assert.equal(check(ghost(deep, ms)).error, "impossible_run", "21 blocks under the course: a fall is caught at 12");
  // Onto a teleport pad's top (0, 0, 80) from 8 blocks along +x.
  const pad = [[0, 0, 0]].concat(line([0, 0, 0], [80, 0, 0], 10), [[0, 0, 80]], line([0, 0, 80], TO_FINISH, 10));
  assert.equal(check(ghost(pad, (pad.length - 1) * H.SAMPLE_MS)).error, undefined, "a teleport pad's trip");
  // At most MAX_JUMPS of them: START, CHECKPOINT, START, ... (100 blocks apart), then on to FINISH.
  const jumps = (count: number): number[][] => {
    const out = [[0, 0, 0]];
    for (let j = 1; j <= count; j++) {
      out.push(j % 2 === 1 ? [1000, 0, 0] : [0, 0, 0]);
    }
    const last = out[out.length - 1];
    return out.concat(line(last, [2000, 0, 0], last[0] === 0 ? 25 : 13));
  };
  assert.equal(long(jumps(H.MAX_JUMPS)).error, undefined, "MAX_JUMPS jumps");
  assert.equal(long(jumps(H.MAX_JUMPS + 1)).error, "impossible_run", "one more");
});

test("GhostRules: the run stays around its course (the box and a margin; higher for launch pads, lower for falls)", () => {
  const ms = 30000;
  const out = walk([[0, 0, 0], [-50, 0, 0], [0, 0, 0], TO_FINISH], ms);
  assert.equal(check(ghost(out, ms)).error, undefined, "5 blocks out of the box's side: within the margin (4 + a block)");
  const far = walk([[0, 0, 0], [-80, 0, 0], [0, 0, 0], TO_FINISH], ms);
  assert.equal(check(ghost(far, ms)).error, "impossible_run", "8 blocks out");
  const high = walk([[0, 0, 0], [0, 250, 0], [0, 0, 0], TO_FINISH], ms);
  assert.equal(check(ghost(high, ms)).error, undefined, "25 blocks up (a launch pad)");
  const sky = walk([[0, 0, 0], [0, 320, 0], [0, 0, 0], TO_FINISH], ms);
  assert.equal(check(ghost(sky, ms)).error, "impossible_run", "32 blocks up");
});
