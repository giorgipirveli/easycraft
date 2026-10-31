# Life L3b: Electricity, Animals, Medical Emergencies, Fire and Heat — the agent brief (owner #112, #117, #118)

The owner (2026-10-16 19:51, #118): "consider somethimes in real life teaching some staff is dangerous, we can use this
online environment to teach them safely, so think what such things we can implement into game". Life L3a is merged (`0ac3bc35`) (the **safe mistake** step kind, the per-try **time scale**, the **intensity** setting, the **debrief** card;
Water Safety, the Poisons Cupboard, Earth and Weather). You build the dangers wave's second part in EasyCraft (Godot 4.7.2,
typed GDScript; phones, the web, PC and VR on the Meta Quest 3). Work autonomously; do not ask questions (decide, and
write each ruling down with what it costs if wrong).

## Read first
- **`docs/design/life-skills.md` §14 "Dangerous things, learned safely"** (the rules for every dangerous Experience; the
  catalogue's rows 3, 6, 7, 8 and 10), and §3, §6, §10, §11, §13.
- Life as built: `docs/devlog/parts/life-l1.md`, `life-l2.md`, `tools-r4b.md`, **`life-l3a.md`** (the framework additions:
  use them, don't rebuild them); `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`; the tool engine
  `core/tools/*`, `entities/tools/*` (ToolRoomHost plays every Experience; the ten motions; the device model).

## Build
1. **Electricity** (row 7; Middle and Big; Little: the hazard hunt only): sockets and water (dry hands; the hair dryer far
   from the bath), a frayed cable (don't touch it, tell a grown-up, the plug out by its head), an overloaded socket, a
   fallen power line (stay far away, keep others away, call the region's number; **"not for a child to do"** said plainly),
   someone stuck to a current (the safe mistake: grabbing them: time freezes, the coach says why; then: don't touch,
   switch off at the fuse box only if it is safe and a grown-up's way, call), kites and climbing near lines, a substation's
   fence; the Tool Book's entries (the fuse box, the plug, the RCD test button).
2. **Animals** (row 8; all tracks): a dog's warning signs (stiff body, a stare, lips back, the tail held high) and **"be a
   tree"** (still, arms in, look at your feet) when a dog runs at you; ask the owner first, let it sniff the back of your
   hand; farm animals (never behind a horse, calm and slow near cows); bees and wasps (walk away slowly, no swatting; a
   sting: tell a grown-up, an allergy is an emergency); snakes (step back slowly, leave it alone); wild animals in the hills
   (Georgia's mountains: stay with the group, make noise on the path, never feed or follow); the safe mistakes: running
   from the dog, hugging a dog you don't know (the coach freezes it calmly: never a bite shown).
3. **Medical Emergencies** (row 10; Middle and Big): an allergic reaction (spot it: the swelling, the breathing; the
   **auto-injector practice pen**: a trainer, blue and orange, "blue to the sky, orange to the thigh", hold it, then call
   the region's number; it is a grown-up's or the child's own prescribed pen: said plainly), an asthma inhaler with a
   spacer (shake, breathe out, press, slow breaths), a seizure (time it, move hard things away, something soft under the
   head, never hold them down, nothing in the mouth, the recovery position after; call if over 5 minutes), a nosebleed
   (sit, lean forward, pinch the soft part 10 minutes; the safe mistake: tipping the head back), a bump on the head (tell
   a grown-up), heat stroke (shade, cool, water, call); Little: "tell a grown-up and call for help" with the play phone
   (Little Lifesaver's).
4. **Fire and heat, what L1 left** (row 3; all tracks): a pan fire in The Kitchen's room (heat off, lid on, leave it
   covered; the safe mistake: water on the pan: frozen before the flare, the coach's calm why), candles and matches (a
   grown-up's job: the child spots and tells), a campfire built in a ring, kept small, then put out (drown, stir, feel the
   ashes cool with the back of the hand), hot-water scalds (the tap's hot side, the kettle's cord; burns first aid: L1's
   cool water); choking (row 6, Little): small things away from babies and toddlers (an older sibling's tidy-up). Extend
   Fire Escape and The Kitchen through their data where you can; a new room only where needed.
5. **What L3a and Success S2 left for Life** (`docs/devlog/parts/life-l3a.md`, `success-s2.md`): Real Builder's
   saw-without-goggles becomes a true safe mistake (one line in `ToolRoomHost._safe_mistake` and a `try` field in its
   data); Safe Streets' unsafe crossing becomes a safe mistake (a small new rule: the wrong moment on the right target);
   the Tool Book's calendar and jar (S2's); L3a's new Tool Book entries get their own pictures where you can.
6. **Life Town's second row** (the plaza is full after L3a): your Experiences' places AND Success S2's four
   (`goal_board`, `talk_deal`, `connections`, `success_stories`: their ids in `core/success/*`; S2 left them out of Life
   Town and out of `test_life_town.gd`), keeping "walking up to one never opens another".
7. Each Experience with its place in Life Town (the second row), its units on the Life map (three tracks), its Tool Book entries, its review sheet (`tools/life_review_sheet.py`),
   and **every fact from its authority with its source** (the national Red Cross or Red Crescent and St John Ambulance first
   aid manuals; allergy and asthma bodies (e.g. the UK's NHS, Asthma + Lung UK, Anaphylaxis UK); epilepsy bodies (the
   Epilepsy Foundation, Epilepsy Action); electricity safety bodies (e.g. Electrical Safety First); vets' and kennel clubs'
   dog safety (e.g. the Blue Dog programme's guidance as text, not its material); the fire services). Mark each fact for
   the expert's review before it ships (§14).

## Allocation and rules
- Yours: `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`, `data/tools/tools.json` (new entries only), Life
  Town's spots, tests `tests/**/test_life_*.gd`, notes `docs/devlog/parts/life-l3b.md`, spec §27 "As built (L3b)",
  DEVELOPMENT.md. Running beside you: School agents (`data/school/g8/*`, `data/school/grade8.json`, `core/school/gen/*`) and
  Success (`core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*`): don't touch theirs.
- Calm, never scary (§6, §14): no injuries, no gore, no bites, no screaming, no sudden scares; no medicine doses; English
  only; nothing personal kept or sent; no microphone. Every Experience flat and in VR, on its tracks; steps name their
  motion, tool and device (§13).
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization, godot-ui,
  xr-development, audio-system); `--import` after new class_name scripts; logs `life3b_*` in the session scratchpad; extend
  `tools/life_smoke.gd`; the FULL suite once at the end (tests/run_tests.sh drops a plugin's python3 shim itself; ad hoc
  Python: /usr/bin/python3). Never open the editor or an emulator, never touch adb; never merge or push; no downloads;
  never start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Finish
Notes (what a child does in each Experience on each track, flat and in VR, every safe mistake and what the coach says,
the rulings and their costs, the sources, what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md,
spec. Report: branch, commits, the four Experiences (or extensions), the full suite's result.
