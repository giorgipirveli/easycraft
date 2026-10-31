# Success S3: My Business's shop and the Market Square — the agent brief (owner #115)

The owner (2026-10-16 11:49, #115): "in life skills we need more, we need skills school dont deliver, skills releted to
real life, how to be successfull, business, trading, money, comunications, connections, everything to be sucsessfull".
Success S1 (My Money Stall, inside Life L1) and S2 (the Goal Board and habit garden, Talk & Deal, the Connections Book,
Success Stories) are merged. You build the Success strand's third step in EasyCraft (Godot 4.7.2, typed GDScript; phones,
the web, PC and VR on the Meta Quest 3). Work autonomously; do not ask questions (decide, and write each ruling down with
what it costs if wrong).

## Read first
- **`docs/design/success-skills.md`** (all of it; your step is §5's S3: systems 1 **My Business** (its Middle track: the
  shop) and 2 **the Market Square**; the guardrails §3; parents §4) and `docs/design/life-skills.md` §3, §10, §11, §13.
- Success and Life as built: `docs/devlog/parts/success-s2.md`, `life-l1.md` (My Money Stall: the stand you grow from),
  `life-l3b.md`, `life-l3c.md` (if merged); `core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*`,
  `core/life/*`, `ui/life/*`; the Connections Book's people (your customers and merchants are them); the worlds' farm.
- How gold is earned and capped now: the client's wallet award path and the server's `server/modules/src/rules/
  wallet_rules.ts` (reasons, per-award and per-hour caps). **No server change** (server changes need the owner's go):
  use the existing path and caps.

## Build
1. **My Business: the shop** (Middle; Little keeps the stand; Big gets the shop's harder days): the child builds or
   chooses a shop in Life Town's Success corner (or the child's world: a ruling); customers (the Connections Book's
   people) with their own wishes, budgets and moods; ask what they want; make it (from the farm's wheat, crafts);
   price it (what it cost + a profit; too high: nobody buys; too low: no money for more flour); a sign; stars and
   reviews (honest, kind); a complaint listened to and fixed (Talk & Deal's way); **the ledger** in pictures (money in,
   money out, profit; a week's bars); a buddy helper paid a wage; a rival shop that wins customers back only with
   better quality or service (**never tricks**: no fake reviews, no lies: the coach says why). The shop pays **real gold
   only while the child plays it** (customers come while you are there; never left running to farm gold), within the
   existing caps and through the existing award path, like learning's gold (a ruling on how much, with its cost).
2. **The Market Square** (Middle and Big; Little: a swap stall, swapping fairly): stalls of buddy merchants; goods'
   prices move by **supply and demand with causes you can see**, told on the **Price Board** (a dry season: wheat goes
   up; a festival: cakes go up; many sellers: the price falls); buy, sell, specialise (bake only bread, trade for the
   rest: both richer), haggle politely (Talk & Deal's phrases); Big: buy low and sell high honestly, keep a stock,
   spread across goods (a storm hits one), and **a lesson with dice that shows why gambling loses over time** (pretend
   counters only, never gold, never a bet: averages over many throws drawn as a chart). Seasons pass in game days.
3. Each with units on three tracks in the Life map's Success strand, the Passport's stamps, before-and-after checks,
   Try it for real cards ("Help a grown-up compare two prices in a shop"), the Tool Book's entries (the till, the scales,
   the ledger, the Price Board), its place (Life Town is full: L3c's third row cost one real meadow its town, 6 of 8 now, and
   L3c measured that a fourth row, a side wing or a wider search do no better (`docs/devlog/parts/life-l3c.md`): so the
   shop and the Market Square are **a second plaza, the Market Square itself**, placed near Life Town by the same
   search; keep "walking up to one never opens another"; measure that the real meadows get it and that Life Town keeps
   its 6 of 8; a world without room still opens both from the LIFE tab), and its review sheet; every fact (economics,
   consumer rights) with its source (e.g. the Bank of England's and central banks' education pages, the OECD's
   financial literacy framework, consumer bodies), marked for the expert's review.
4. Flat and VR: in VR the till's coins in the hand, the scales, the goods on the shelves, the Price Board to read.

## Guardrails (success-skills.md §3)
Never gambling (no bets, no chance boxes, no paid randomness); no real money or advice; no pressure tricks (no timers
that hurry, no fear of missing out, no streak guilt); honesty rewarded; success means many things; trading with real
friends online is S4's (not now). English only; nothing personal kept or sent; no typing of personal things; no
microphone.

## Allocation and rules
- Yours: `core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*`, the Success units in
  `data/life/life.json` (new entries only), small hooks in `core/life/*` / `ui/life/*` / Life Town marked "owner #115
  (S3)" (list each in the notes), tests `tests/**/test_success_*.gd`, notes `docs/devlog/parts/success-s3.md`, spec §27
  "As built (S3)", DEVELOPMENT.md. Running beside you: School agents (`data/school/*`, `core/school/gen/*`,
  `ui/school/*`) and possibly Life (`core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`): don't touch theirs.
- TDD; the matching godot-prompter skills first (inventory-system, dialogue-system, godot-ui, save-load, xr-development);
  `--import` after new class_name scripts; logs `success3_*` in the session scratchpad; the FULL suite once at the end
  (tests/run_tests.sh drops a plugin's python3 shim itself; ad hoc Python: /usr/bin/python3). Never open the editor or
  an emulator, never touch adb; never merge or push; no downloads; never start agents; no server changes. Commits end
  with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (what a child does in the shop and the market on each track, flat and in VR; how much gold the shop pays and why;
every ruling and its cost; the sources; what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md, spec.
Report: branch, commits, the two systems, the full suite's result.
