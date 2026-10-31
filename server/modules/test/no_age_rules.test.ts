// The owner (2026-09-29): "remove all such restrictions" (age limits and grown-up confirmations). The module ships
// with AccountRules.ageRules off: every claimed account plays online with the filtered chat, whatever its band, and a
// band may be raised. (The other tests switch the rules on: test/harness.ts.)
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { server } from "./harness.ts";

const A = server().AccountRules;

function off<T>(f: () => T): T {
  A.ageRules = false;
  try {
    return f();
  } finally {
    A.ageRules = true;
  }
}

test("with the age rules off an under_13 account plays online with the filtered chat", () => {
  off(() => {
    const kid = { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" };
    assert.equal(A.canPlayOnline(kid), true, "no grown-up's consent needed");
    assert.equal(A.chatLevel(kid), "filtered", "typed chat, the word filter stays");
    assert.equal(A.effectiveBand("under_13"), "13_plus");
    assert.equal(A.canPlayOnline({ age_band: "", consent: "none", online_allowed: false, chat: "off" }), false,
      "an account with no name yet is still not online");
  });
});

test("with the age rules off a new account gets the open defaults and a band may be raised", () => {
  off(() => {
    assert.deepEqual(A.defaults("under_13"), { age_band: "13_plus", consent: "none", online_allowed: true, chat: "filtered" });
    const kid = { age_band: "under_13", consent: "none", online_allowed: false, chat: "quick" };
    const r = A.applyParentSettings(kid, { age_band: "13_plus" });
    assert.equal(r.error, undefined, "not locked");
  });
});

test("the module ships with the age rules off", () => {
  const src = readFileSync(new URL("../src/rules/account_rules.ts", import.meta.url), "utf8");
  assert.match(src, /export let ageRules = false;/);
});
