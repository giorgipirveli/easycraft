# Success S2: Goals & Habits, Talk & Deal, the Connections Book, Success Stories — the agent brief (owner #115)

The owner (2026-10-16 11:49, #115): "in life skills we need more, we need skills school dont deliver, skills releted to
real life, how to be successfull, business, trading, money, comunications, connections, everything to be sucsessfull".
Success S1 (My Money Stall, inside Life L1) is merged. You build the Success strand's second step in EasyCraft (Godot
4.7.2, typed GDScript; phones, the web, PC and VR on the Meta Quest 3). Work autonomously; do not ask questions (decide,
and write each ruling down with what it costs if wrong).

## Read first
- **`docs/design/success-skills.md`** (all of it: success means value for yourself and for others; the eleven families on
  three tracks; the evidence: lessons barely change behaviour, so doing; self-control, social skills and cross-group
  friendships predict adult success; if-then plans; the seven systems §2; the guardrails §3; parents §4; the plan §5:
  your step is S2) and `docs/design/life-skills.md` §3 (the Experience loop), §10 (easy means obvious), §11 (parents).
- Life as built (`docs/devlog/parts/life-l1.md`, `life-l2.md`; `core/life/*`, `ui/life/*`): reuse its Experience framework,
  the Passport, the coach, the stamps, the grown-ups' page, the Life map's Success strand; the buddies and the worlds'
  characters (NPCs) you can talk to.

## Build (success-skills.md §2, systems 3, 4, 6, 7)
1. **Goals & Habits** (S8): the **Goal Board** (a dream → a goal → steps → if-then plans: "When I finish a lesson, I put
   10 gold in my rocket jar"; the Big track writes its own plan from parts), tied to the child's real goals in the game
   (the rocket, a universe, a build); the **habit garden** (one small good habit chosen; a plant grows on each day it is
   kept; a missed day never kills it: gentle, never guilt; no streak pressure); the parents' page shows the goal and the
   habit's days.
2. **Talk & Deal** (S4, S6): practice conversations with the worlds' characters, the child choosing what to say (pictures
   on Little, phrases later; no typing, no voice): a customer's complaint (listen, say sorry, fix it), a deal with the
   farmer (find what both want: win-win), a pitch to friendly investors (the problem, the idea, why you, what you need;
   in VR standing in front of them), instructions to a buddy who does EXACTLY what you said (clear words matter);
   kind feedback about what the child said; three tracks.
3. **The Connections Book** (S5, S10): the worlds' people with names, jobs, wishes and needs (the baker needs flour, the
   farmer needs tools, the engineer needs a buyer); meet them, remember them in the book, help first, keep promises
   (deliver on time), introduce two people who can help each other; their warmth grows (never a public score); new chances
   open; mentors teach a skill when asked politely; people different from you (Chetty: cross-group connections).
4. **Success Stories** (S11, S10, S8): twenty short read-aloud stories of real people who built things (inventors, nurses,
   teachers, farmers, engineers, founders; many countries; started small, failed, tried again, helped others), every fact
   checked with its source; no living-people politics, no brands' marketing; "Which skill did they use?" questions.
5. Each a Life Experience or a Life-map place in the Success strand, with units on three tracks, the Passport's stamps,
   before-and-after checks, and Try it for real cards ("Set one small goal with a grown-up and plan its first step").

## Guardrails (success-skills.md §3)
Never gambling; no real money or advice; no pressure tricks (no timers, no fear of missing out, no streak guilt); honesty
rewarded; success means many things; trading only with approved friends (not in S2). English only; nothing personal kept
or sent; no typing of personal things; no microphone.

## Allocation and rules
- Yours: `core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*` (new), the Success units in
  `data/life/life.json` (the Success strand's areas; new entries only), small hooks in `core/life/*` / `ui/life/*` marked
  "owner #115" (Life L3a edits those now: keep your hooks minimal and say where), tests `tests/**/test_success_*.gd`, notes
  `docs/devlog/parts/success-s2.md`, spec §27 "As built (S2)", DEVELOPMENT.md. Running beside you: Life L3a (`core/life/*`,
  `entities/life/*`, `ui/life/*`, `data/life/*` except your entries) and the School agent (`data/school/g7/*`).
- TDD; the matching godot-prompter skills first (dialogue-system, godot-ui, save-load); `--import` after new class_name
  scripts; logs `success2_*` in the session scratchpad; the FULL suite once at the end (tests/run_tests.sh drops a plugin's
  python3 shim itself; ad hoc Python: /usr/bin/python3). Never open the editor or an emulator, never touch adb; never
  merge or push; no downloads; never start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Finish
Notes (what a child does in each system on each track, flat and in VR; every ruling and its cost; the stories' sources;
what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md, spec. Report: branch, commits, the four
systems, the full suite's result.
