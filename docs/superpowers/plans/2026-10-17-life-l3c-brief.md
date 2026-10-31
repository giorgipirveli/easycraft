# Life L3c: Online City, Find Your Way, Home Helper — the agent brief (owner #112, #113, #117, #118)

The owner (2026-10-16, #112): life skills school doesn't teach; (#117) every skill with its real tools and devices;
(#118) dangerous things taught safely. Life L3a and L3b are merged (`1b26c38f`: the safe mistake, the wrong moment
(`try: "unsafe"`), the time scale, the intensity, the debrief; seventeen Experiences, each with its place in Life Town's
two rows). You build Life's third wave's last part in EasyCraft (Godot 4.7.2, typed GDScript; phones, the web, PC and VR on
the Meta Quest 3). Work autonomously; do not ask questions (decide, and write each ruling down with what it costs if wrong).

## Read first
- **`docs/design/life-skills.md`**: §5's catalogue rows 7 (Online City), 10 (Find Your Way), 11 (Home Helper); §14's row
  14 (people and places: lost in a crowd, Online City, an emergency at school: follow the teacher; **no lockdown
  simulations for children**, a ruling) and §14's rules; §3, **§6 (careful topics, safety and the law)**, §10, §11, §13.
- Life as built: `docs/devlog/parts/life-l1.md`, `life-l2.md`, `tools-r4b.md`, `life-l3a.md`, **`life-l3b.md`** (the
  framework as it is now: use it, don't rebuild it); `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`; the
  tool engine `core/tools/*`, `entities/tools/*` (ToolRoomHost plays every Experience; the ten motions; the device model).
- Owner #105's log-in rules (`docs/playtests/owner-feedback.md` row 105): the game's own password rules are Online City's
  password lesson.

## Build
1. **Online City** (row 7; all tracks): a calm town of pretend websites, chats and games on a play tablet (flat: the
   screen; VR: the tablet held in the hand, the device model; the catalogue said "flat first": both, a ruling). A stranger
   in a game chat asks for a photo or where you live (the safe mistake on Middle: answering; the coach freezes it: no,
   block, tell a grown-up), a mean comment (don't reply, keep it to show, block, report, tell), a password (the game's own
   #105 rules: long, not your name, never shared, even with a friend), "free gold, just give your password" (a scam:
   the safe mistake on Big: clicking), a pop-up that wants you to download something (close it, ask a grown-up), a news
   story (who made it, when, does anyone else say so; a picture can be changed), being kind online, time online (a
   break; never guilt), what to share and what stays private (the name of your school, your address, photos of you:
   private). Little: "tell a grown-up if something online feels wrong" with a picture of a sad screen and the buddies.
   Everything in it is pretend: **no real sites, apps, brands or people; nothing the child types or says is kept or sent;
   no typing of anything personal; no microphone**.
2. **Find Your Way** (rows 10 and 14; all tracks): your address and a grown-up's number **said aloud to a grown-up, never
   typed or kept** (a Try it for real card: "Say your address to your grown-up now"; the game never asks for it), lost at
   the market (stay where you are; find a safe grown-up: a shop worker with a name badge, a parent with children, a police
   officer; the safe mistake on Middle: walking off with someone who says "come with me" — frozen calmly, never scary),
   an emergency at school: follow the teacher calmly (a fire drill's line, the meeting point; **no lockdown simulation**),
   a metro map with two lines and a change, a ticket and the gates, where to stand (behind the line), a map's symbols and
   grid squares, a compass (north, the eight points; Big: walk on a bearing to a flag), landmarks to remember the way;
   Georgia's own: Tbilisi's metro has two lines (check the source) — the game's metro is the game's own, named plainly.
3. **Home Helper** (row 11; all tracks): sort the washing (colours, whites, the label's symbols on Big), fold a T-shirt,
   pair the socks, tidy a room (everything has a home), sort the recycling (paper, plastic and cans, glass, food waste:
   the region's bins as a ruling, with the sources), water the plants (how much, how often), care for a pet (food, fresh
   water, a walk, a clean bed; a vet when it is ill), **test the smoke alarm with a grown-up** (§5 #11; the button; once a
   month), set the table, load the dishwasher's knives point down (Big). Hands folding, pouring and sorting in VR.
4. **Little tracks** for all three; Middle and Big as the catalogue says; each Experience with its safe mistakes where a
   wrong way is a real danger (Online City and Find Your Way), never in Home Helper's chores (no "mistake" for folding).
5. **Life Town:** the three new places in a **third row** (or the second row's free spots, if any are left), keeping
   "walking up to one never opens another"; measure that the real meadows still get their town (`test_life_town.gd`).
6. **Small hooks outside Life, each marked "owner #118 (L3c)" and listed in the notes** (no Success or School agent edits
   these files now): Success's Goal Board steps name S2's **calendar** and **jar** (`data/success/experiences/
   goal_board.json`) so their Tool Book stamps can be earned; the School's grade 8 computing unit **Cyber security**
   (`data/school/g8/computing/cyber_security.json`) ends by naming Online City instead of the Connections Book (one card
   line); add Online City to the Life map's School links in `data/life/life.json` where grade 6-8 online-safety units are
   listed (if the map has such links; otherwise skip and say so).
7. Each Experience with its place, its units on the Life map (three tracks), its Tool Book entries (the play tablet, the
   compass, the metro ticket, the smoke alarm's test button, the washing label), its debrief, its review sheet
   (`tools/life_review_sheet.py`), and **every fact from its authority with its source** (online safety: the UK Safer
   Internet Centre, Childnet's SMART rules, the NSPCC, UNICEF; being lost: the police's and child-safety charities'
   advice; the fire services for the smoke alarm and school drills; recycling: the region's own or the EU's; pets: the
   RSPCA or national vets' bodies). Mark each fact for the expert's review before it ships (§14).

## Allocation and rules
- Yours: `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`, `data/tools/tools.json` (new entries only), Life
  Town's spots, tests `tests/**/test_life_*.gd`, notes `docs/devlog/parts/life-l3c.md`, spec §27 "As built (L3c)",
  DEVELOPMENT.md; the three marked hooks in item 6. Running beside you: School agents (`data/school/g7/*`,
  `data/school/g8/*` except the one card, `data/school/grade7.json`, `data/school/grade8.json`, `core/school/gen/*`,
  `ui/school/*`): don't touch theirs.
- Calm, never scary (§6, §14): no stranger is ever shown grabbing or following; no bullying words worse than "you're
  bad at this game"; no lockdowns; English only; nothing personal kept or sent; no typing of personal things; no
  microphone. Every Experience flat and in VR, on its tracks; steps name their motion, tool and device (§13).
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization, godot-ui,
  xr-development, dialogue-system); `--import` after new class_name scripts; logs `life3c_*` in the session scratchpad;
  extend `tools/life_smoke.gd`; the FULL suite once at the end (tests/run_tests.sh drops a plugin's python3 shim itself;
  ad hoc Python: /usr/bin/python3). Never open the editor or an emulator, never touch adb; never merge or push; no
  downloads; never start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (what a child does in each Experience on each track, flat and in VR, every safe mistake and what the coach says,
the rulings and their costs, the sources, what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md,
spec. Report: branch, commits, the three Experiences, the hooks outside Life, the full suite's result.
