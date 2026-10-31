# Life L3a: safe mistakes, then Water, Poisons, Earth and Weather — the agent brief (owner #112, #117, #118)

The owner (2026-10-16 19:51, #118): "consider somethimes in real life teaching some staff is dangerous, we can use this
online environment to teach them safely, so think what such things we can implement into game". Life L1 and L2 are
merged (seven Experiences with Real Builder, the Passport, the Tool Book, Life Town). You build the dangerous-skills
wave's first part in EasyCraft (Godot 4.7.2, typed GDScript; phones, the web, PC and VR on the Meta Quest 3). Work
autonomously; do not ask questions (decide, and write each ruling down with what it costs if wrong).

## Read first
- **`docs/design/life-skills.md` §14 "Dangerous things, learned safely"** (why: the WHO/UNICEF ranking; **safe mistakes**:
  the wrong way tried, time frozen, the coach's calm why, then the right way; time slowed at danger moments, real time
  for Expert; prevention first; "not for a child to do" said plainly; the intensity setting; the debrief; never weapons,
  recipes, drugs or stunts; the catalogue's rows 2, 5 and 9), and §3, §6, §10, §11, §13.
- Life as built: `docs/devlog/parts/life-l1.md`, `life-l2.md`, `tools-r4b.md`; `core/life/*`, `entities/life/*`,
  `ui/life/*`, `data/life/*`; the tool engine `core/tools/*`, `entities/tools/*` (ToolRoomHost plays every Experience).

## Build
1. **The framework additions** (Life's own, test-first): (a) a **safe mistake** step kind: the child may do the wrong
   thing (a target or action marked as the mistake); time freezes (the room's simulation stops, the scene softens and
   stills, never sudden), the coach shows calmly what would happen and why (words and a gentle picture, never injury or
   gore), then the step goes on and the child does it right; Little track: the coach guides before, no mistake shown;
   (b) **time scale** per try (slower at the step's danger moment on the first tries, real time on Expert); (c) the
   **intensity** setting on the grown-ups' Life page (gentle by default; "more real" allowed on the Big track by a
   grown-up: what it changes, kept modest); (d) the **debrief** card after every emergency Experience ("You did it. In
   real life, grown-ups help too.") and the way out at any moment, as now.
2. **Water Safety** (row 2): how drowning really looks (quiet, not waving: spot it at a pool), a rip current (swim along
   the shore, then in; the safe mistake: swimming straight back against it), thin ice (stay off; if you fall in: arms out,
   kick, roll, crawl; the safe mistake: standing up on the ice), reach or throw, don't go (the safe mistake: jumping in
   after someone), a life jacket's fit; three tracks; flat and VR.
3. **The Poisons Cupboard** (row 5): find the dangerous bottles in a kitchen and a garage (the hazard symbols), the child
   lock, never mix cleaners (the safe mistake: two bottles poured together: the coach freezes it and says why), medicines
   only from a grown-up, button batteries (swallowed: an emergency, call the region's number), wild mushrooms and berries
   (never eat them), carbon monoxide (the alarm: get everyone out, call from outside); three tracks.
4. **Earth and Weather** (row 9): earthquake: Drop, Cover, Hold On (under a table, away from windows; the safe mistake:
   running outside during the shaking), then out to open ground; lightning (get inside; never under a lone tree), floods
   (never walk or ride in moving water), heat (shade, water, rest), cold (layers, dry), lost in the woods (stay put, hug a
   tree, be seen and heard); Georgia's mountains make the earthquake row matter: the region's own guidance where it
   exists; three tracks.
5. Each with its place in Life Town (new spots on the plaza or a second plaza row: keep "walking up to one never opens
   another"), its units on the Life map, its Tool Book entries (a life jacket, a whistle, a child lock, a CO alarm...),
   its review sheet (`tools/life_review_sheet.py`), every fact from its authority with its source (the WHO, national water
   safety and lifesaving bodies, poison centres, earthquake and civil protection agencies, the national weather service).

## Allocation and rules
- Yours: `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`, `data/tools/tools.json` (new entries only),
  Life Town's spots, tests `tests/**/test_life_*.gd`, notes `docs/devlog/parts/life-l3a.md`, spec §27 "As built (L3a)",
  DEVELOPMENT.md. Running beside you: the School agent (`data/school/g7/*`, `data/school/grade7.json`, `core/school/gen/*`)
  and Success S2 (`core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*`): don't touch theirs.
- Calm, never scary (§6, §14): no injuries, no gore, no screaming, no sudden scares; English only; nothing personal kept or
  sent; no microphone. Every Experience flat and in VR, on all three tracks; steps name their motion, tool and device
  (§13).
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization, godot-ui,
  xr-development, audio-system); `--import` after new class_name scripts; logs `life3a_*` in the session scratchpad; extend
  `tools/life_smoke.gd`; the FULL suite once at the end (tests/run_tests.sh drops a plugin's python3 shim itself; ad hoc
  Python: /usr/bin/python3). Never open the editor or an emulator, never touch adb; never merge or push; no downloads;
  never start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Finish
Notes (what a child does in each Experience on each track, flat and in VR, every safe mistake and what the coach says,
the rulings and their costs, the sources, what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md,
spec. Report: branch, commits, the framework additions, the three Experiences, the full suite's result.
