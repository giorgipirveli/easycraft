// Reports (spec §5.14, §17.3): stored on the server for a person to read in the Nakama console.
// Reasons are codes (no free text from children); a reporter can't flood the console.
import { test } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";

const R = server().ReportRules;
const NOW = 5_000_000;

test("reasons: the known codes, anything else is 'other'", () => {
  for (const reason of R.REASONS) {
    assert.equal(R.reason(reason), reason);
  }
  assert.ok(R.REASONS.includes("mean_words"));
  assert.ok(R.REASONS.includes("other"));
  assert.equal(R.reason("he said my address is ..."), "other");
  assert.equal(R.reason(undefined), "other");
});

test("a report is accepted and counted", () => {
  const r = R.accept(R.emptyWindow(), "bad-kid", NOW);
  assert.equal(r.error, undefined);
  assert.equal(r.store, true);
  assert.deepEqual(r.window.times, [NOW]);
  assert.equal(r.window.last["bad-kid"], NOW);
});

test("the same player again within 10 minutes is not stored twice", () => {
  const first = R.accept(R.emptyWindow(), "bad-kid", NOW);
  const again = R.accept(first.window, "bad-kid", NOW + R.SAME_USER_GAP_MS - 1);
  assert.equal(again.error, undefined, "the child is still told 'thanks'");
  assert.equal(again.store, false);
  assert.equal(R.accept(first.window, "bad-kid", NOW + R.SAME_USER_GAP_MS).store, true);
});

test("at most 10 reports an hour", () => {
  let w = R.emptyWindow();
  for (let i = 0; i < R.MAX_PER_HOUR; i++) {
    const r = R.accept(w, "kid" + i, NOW + i);
    assert.equal(r.store, true);
    w = r.window;
  }
  assert.equal(R.accept(w, "another", NOW + 100).error, "too_many");
  assert.equal(R.accept(w, "another", NOW + R.HOUR_MS).store, true, "an hour later");
});

test("windows read from storage are sanitised", () => {
  assert.deepEqual(R.windowFrom(undefined), R.emptyWindow());
  assert.deepEqual(R.windowFrom({ times: [1, "x"], last: { a: 2, b: "y" } }), { times: [1], last: { a: 2 } });
});
