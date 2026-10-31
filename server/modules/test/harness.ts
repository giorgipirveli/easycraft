// Loads the built module (build/index.js, the one script Nakama runs) into this Node process, the
// way Nakama's runtime does: as a plain script whose top-level declarations become globals. Tests
// then call the pure rules and the RPC/hook functions directly; `npm test` builds first.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const BUILD = fileURLToPath(new URL("../build/index.js", import.meta.url));
let loaded = false;

// The module's globals (namespaces such as UsernameRules, the rpc* and hook functions, InitModule).
export function server(): any {
  if (!loaded) {
    vm.runInThisContext(readFileSync(BUILD, "utf8"), { filename: BUILD });
    // The age rules on for the tests written for them; the module ships with them off (the owner, 2026-09-29;
    // test/no_age_rules.test.ts tests the module as it ships).
    (globalThis as any).AccountRules.ageRules = true;
    loaded = true;
  }
  return globalThis as any;
}
