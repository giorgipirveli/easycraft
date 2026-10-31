// Ghost races on friends' courses (M4; spec §17.5, docs/design T2: "my friend races my ghost and gets
// bronze; I have gold"). A ghost is a player's best run on a course they built (M3 Task 7's recorded
// run), shared on their showcase or with a blueprint gift, for friends to race. Guards (spec §17.2): it is
// small (5 samples a second, at most 3 minutes, a size cap), it belongs to its course (the START and
// FINISH it names are in the course's build), and a child could really have run it: it starts on START,
// ends on FINISH, stays around the course, never moves faster than the game's fastest way to move, and it
// "jumps" only onto a START, CHECKPOINT or TELEPORT_PAD (a fall brings a runner back to the checkpoint, a
// teleport pad moves them). Pure: no Nakama calls.
//
// The format is the game's (core/ghosts/race_ghost.gd, RaceGhost):
//   {"start": [x, y, z], "finish": [x, y, z]   cells in the course's box (the showcase area or the gift)
//    "ms": the run's time                       1,000-180,000
//    "path": base64 of int16 little-endian (x, y, z) decimetres from the top of the START block (its
//            middle, one block up), sampleCount(ms) of them, evenly spread over the run
//    "look": the racer's avatar look code       AvatarLook.to_code(): a JSON object text, or ""}

namespace GhostRules {
  export const TELEPORT_PAD = 202; // BlockIds (data/blocks/block_ids.gd)
  export const START = 203;
  export const CHECKPOINT = 204;
  export const FINISH = 205;
  export const SAMPLE_MS = 200; // 5 samples a second
  export const MIN_MS = 1000; // CourseRules.MIN_GOAL_MS
  export const MAX_MS = 180000; // RecordedRun: 3 minutes
  export const MAX_SAMPLES = MAX_MS / SAMPLE_MS + 1;
  export const MAX_PATH_TEXT = Math.ceil(MAX_SAMPLES * 6 / 3) * 4;
  export const MAX_LOOK = 2048; // AvatarLook.MAX_CODE_LENGTH
  // The game's fastest ways to move are a launch pad (PadRules.LAUNCH_PAD_SPEED, 30 m/s) and a grappling
  // hook's pull (22); a fall caught at 12 blocks is 24 m/s. tests/unit/test_ghost_race_rules.gd keeps
  // this above every speed the game has.
  export const MAX_SPEED = 40; // m/s
  export const STEP_SLACK_DM = 10; // a block of slack on every step
  export const FIRST_REACH_DM = 30; // the first sample: within 3 blocks of START's top (just stepped off it)
  export const LAST_REACH_DM = 10; // the last: FINISH's top (the recording ends there)
  export const LAND_REACH_DM = 30; // a jump lands within 3 blocks of a START, CHECKPOINT or TELEPORT_PAD's top
  export const MAX_JUMPS = 64;
  export const MARGIN = 4; // blocks around the course's box the path may use
  export const UP_MARGIN = 24; // above it (a launch pad throws a runner 19 blocks up)
  export const DOWN_MARGIN = 16; // under it (a fall is caught 12 blocks under the checkpoint)
  export const PER_SHOWCASE = 3; // ghosts on one showcase (one per course)
  export const SHARES_PER_HOUR = 12;
  // share_ghost's payload: a gift's build (GiftRules.GIFT, 2,800), the path and the look fit.
  export const PAYLOAD = 16 * 1024;

  export interface Ghost {
    start: number[];
    finish: number[];
    ms: number;
    path: string;
    look: string;
  }

  // Samples for a run of `ms`: one every SAMPLE_MS and both ends.
  export function sampleCount(ms: number): number {
    return Math.round(ms / SAMPLE_MS) + 1;
  }

  export function encodePath(points: number[][]): string {
    const bytes: number[] = [];
    for (let i = 0; i < points.length; i++) {
      for (let a = 0; a < 3; a++) {
        const v = Math.max(-32768, Math.min(32767, Math.round(points[i][a]))) & 0xffff;
        bytes.push(v & 255, v >> 8);
      }
    }
    return BuildRules.base64Encode(bytes);
  }

  // The samples of a path text (decimetres), or null: not base64, not whole samples, fewer than 2 or
  // more than MAX_SAMPLES.
  export function decodePath(text: unknown): number[][] | null {
    if (typeof text !== "string" || text.length > MAX_PATH_TEXT) {
      return null;
    }
    const bytes = BuildRules.base64Decode(text);
    if (bytes === null || bytes.length % 6 !== 0 || bytes.length < 12 || bytes.length > MAX_SAMPLES * 6) {
      return null;
    }
    const out: number[][] = [];
    for (let i = 0; i < bytes.length; i += 6) {
      const p: number[] = [];
      for (let a = 0; a < 3; a++) {
        const v = bytes[i + a * 2] | (bytes[i + a * 2 + 1] << 8);
        p.push(v >= 32768 ? v - 65536 : v);
      }
      out.push(p);
    }
    return out;
  }

  function cellIn(v: unknown, size: number[]): v is number[] {
    return v instanceof Array && v.length === 3 && Util.isInt(v[0]) && Util.isInt(v[1]) && Util.isInt(v[2]) &&
      v[0] >= 0 && v[1] >= 0 && v[2] >= 0 && v[0] < size[0] && v[1] < size[1] && v[2] < size[2];
  }

  function cellAt(cells: number[], size: number[], c: number[]): number {
    return cells[c[0] + size[0] * (c[2] + size[2] * c[1])];
  }

  // "" (the default look) or a JSON object's text within MAX_LOOK.
  export function isLook(v: unknown): boolean {
    if (v === "") {
      return true;
    }
    if (typeof v !== "string" || v.length > MAX_LOOK) {
      return false;
    }
    try {
      return Util.isObject(JSON.parse(v));
    } catch (_e) {
      return false;
    }
  }

  function dist(a: number[], b: number[]): number {
    const dx = a[0] - b[0];
    const dy = a[1] - b[1];
    const dz = a[2] - b[2];
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  // The tops of the cells a jump may land on (START, CHECKPOINT, TELEPORT_PAD), in decimetres from START's top.
  function landings(size: number[], cells: number[], start: number[]): number[][] {
    const out: number[][] = [];
    for (let y = 0; y < size[1]; y++) {
      for (let z = 0; z < size[2]; z++) {
        for (let x = 0; x < size[0]; x++) {
          const id = cells[x + size[0] * (z + size[2] * y)];
          if (id === START || id === CHECKPOINT || id === TELEPORT_PAD) {
            out.push([(x - start[0]) * 10, (y - start[1]) * 10, (z - start[2]) * 10]);
          }
        }
      }
    }
    return out;
  }

  // A ghost shared with a course whose box is `size` with `cells` (BuildRules' order: x fastest, then z,
  // then y): {ghost} (only the fields it keeps), or {error}: "bad_ghost" (its shape), "not_on_course" (no
  // START or FINISH where it says), "impossible_run" (a run nobody could make).
  export function check(g: unknown, size: number[], cells: number[]): { ghost?: Ghost; error?: string } {
    if (!Util.isObject(g) || !cellIn(g.start, size) || !cellIn(g.finish, size) || !Util.isInt(g.ms) ||
        g.ms < MIN_MS || g.ms > MAX_MS) {
      return { error: "bad_ghost" };
    }
    const look = g.look === undefined || g.look === null ? "" : g.look;
    if (!isLook(look)) {
      return { error: "bad_ghost" };
    }
    const points = decodePath(g.path);
    if (points === null || Math.abs((points.length - 1) * SAMPLE_MS - g.ms) > SAMPLE_MS) {
      return { error: "bad_ghost" };
    }
    if (cellAt(cells, size, g.start) !== START || cellAt(cells, size, g.finish) !== FINISH) {
      return { error: "not_on_course" };
    }
    const start: number[] = g.start;
    const finish: number[] = g.finish;
    const toFinish = [(finish[0] - start[0]) * 10, (finish[1] - start[1]) * 10, (finish[2] - start[2]) * 10];
    if (dist(points[0], [0, 0, 0]) > FIRST_REACH_DM || dist(points[points.length - 1], toFinish) > LAST_REACH_DM) {
      return { error: "impossible_run" };
    }
    // The box and its margins, in decimetres from START's top (its middle, one block up).
    const lo = [(-MARGIN - start[0] - 0.5) * 10, (-DOWN_MARGIN - start[1] - 1) * 10, (-MARGIN - start[2] - 0.5) * 10];
    const hi = [(size[0] + MARGIN - start[0] - 0.5) * 10, (size[1] + UP_MARGIN - start[1] - 1) * 10,
      (size[2] + MARGIN - start[2] - 0.5) * 10];
    const step = MAX_SPEED * (g.ms / (points.length - 1)) / 100 + STEP_SLACK_DM; // decimetres a step
    let lands: number[][] | null = null;
    let jumps = 0;
    for (let i = 0; i < points.length; i++) {
      const p = points[i];
      for (let a = 0; a < 3; a++) {
        if (p[a] < lo[a] || p[a] > hi[a]) {
          return { error: "impossible_run" };
        }
      }
      if (i === 0 || dist(points[i - 1], p) <= step) {
        continue;
      }
      if (lands === null) {
        lands = landings(size, cells, start);
      }
      let landed = false;
      for (let k = 0; k < lands.length && !landed; k++) {
        landed = dist(lands[k], p) <= LAND_REACH_DM;
      }
      jumps++;
      if (!landed || jumps > MAX_JUMPS) {
        return { error: "impossible_run" };
      }
    }
    return { ghost: { start: [start[0], start[1], start[2]], finish: [finish[0], finish[1], finish[2]], ms: g.ms,
      path: g.path, look: look } };
  }
}
