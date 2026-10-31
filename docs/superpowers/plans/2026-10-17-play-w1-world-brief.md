# Play W1: learning inside the world — the agent brief (owner #122, #132)

The owner (2026-10-17 23:30, watching a child play, #132): "ok, now i am watching a play and i dont understand where is
educational content? nowhere in the game". Two hours earlier (#122): "all lessons should be game, part of game, mini
games and etc but games, not lectures and slides". Today the School (818 units, grades 3-8, twelve subjects) and Life
(22 Experiences) open only from the main menu's SCHOOL button; inside a world only Life Town (if the child walks to it)
and the Lab block teach. A child can play an hour and meet no learning. **W1 puts learning into the world, where the
child plays.** Play G0 (running beside you) turns every unit into a game; W1 is how a child meets those games while
playing. Work autonomously; do not ask questions (decide, and write each ruling down with what it costs if wrong).

## Read first
- `docs/design/learning-is-play.md` (the seven rules, the loop, §6 where it lives) and spec §22.0; Play G0's brief
  (`docs/superpowers/plans/2026-10-17-play-g0-brief.md`) and, once merged, its notes (`docs/devlog/parts/play-g0.md`).
- How Life Town and the Market Square stand by a home world's spawn: `core/life/life_town.gd` (the search: rings
  round the spawn, dry near-level ground, never on the Theater or the Launch Site; models, nothing stamped; the save),
  `entities/life/life_town_director.gd`, `core/success/market_plaza.gd`, `entities/success/market_plaza_placer.gd`
  (a second plaza by the same search), `docs/devlog/parts/life-l3c.md` (Life Town is full: 6 of 8 real meadows) and
  `success-s3.md` (the plaza's placement, measured on the real meadows); MY MAP's marks (`scenes/sandbox.gd`
  `_mark_life_town`, `_mark_market_square`); the HUD's MORE menu and the pause menu; `LifeTownPanel` (how a walk-up
  opens a screen inside the world, in the HUD's layer) and `Session`/host rules for what is local.
- The School as built: `ui/school/school_screen.gd` (how it opens, a unit's page), `core/school/curriculum.gd`,
  `MasteryRules` (`review_due`, the next unit), `EarnRules` (answer gold and its daily cap), `SchoolData` (the grade),
  the Daily Mission (`DailyData`).

## Build
1. **The Discovery Academy** by every home world's spawn (not Monster Wave's arena, not a space world): a landmark seen
   from the spawn (a tall, friendly tower with Professor Hoot on top; glowing at night; calm, the worlds' own blocky or
   realistic look), placed by the same search as Life Town and the Market Square (a third plaza; measure on the real
   meadows that it lands, that Life Town keeps its 6 of 8 and the Market Square its 6, and how far each is; a world
   with no room: the Academy floats as a small island above the spawn, a ruling with its cost). Its doors, one per
   subject family (the Maths Workshop, the Science Lab, the Word Tower, the History Museum, the Map Room, the Art Studio,
   the Music Hall, the Code Lab, the Health Gym, the Makers' Shed, the Citizens' Hall; Life's door opens Life): walking
   up to a door opens that subject's games for the child's grade inside the world (the School screen's subject page, or
   G0's DISCOVER map once merged: one call the lead can switch); the child is back in the world after. MY MAP marks it;
   the HUD's compass points to it until the child has been in once. The save keeps its site (like Life Town's).
2. **Discovery crystals**: while the child plays a home world (not in a fight, not in a race or a round, not riding,
   not in a menu), every DISCOVERY_MINUTES (a ruling: about 5) a glowing "?" crystal rises a few metres from the child,
   on the ground the child can reach, never in water or a wall, with a soft sound. Touching it (a tap; in VR the hand)
   starts a short play challenge (about a minute: 3-5 challenges) from the child's own learning: a review due today
   first (`MasteryRules`), else the next unit of the grade, else today's Daily Mission; through G0's play when merged,
   else the School's round for that unit. Right answers pay the School's answer gold within its daily cap
   (`EarnRules`); nothing pays for time. Never forced: an untouched crystal fades after CRYSTAL_MINUTES and nothing is
   lost; at most one at a time; a setting for grown-ups turns them off. Local to each player (not synced: each child
   their own), never in Monster Wave or space unless a ruling says so.
3. **Professor Hoot comes to the child**: the first time in a world (and once a day after, at most), Hoot flies in,
   lands near the child and says one line ("Want to discover something? The Academy is right there!" or the crystal's
   "Touch the crystal to play!"), read aloud; then flies to the Academy. Calm, short, skippable, never blocking play.
4. **DISCOVER inside the world**: the HUD's MORE menu and the pause menu gain DISCOVER, which opens the School/G0
   screens inside the world (as Life Town opens Life) and returns to the world.
5. **VR**: the Academy's doors walked through, the crystal touched by the hand (VrGrabber's or the hand's own reach),
   Hoot's line on the toast strip; the budget (≤ 100 draws a frame on the Quest floor preset; models merged per
   material like the rooms' look).
6. **Fast and safe**: the phones' budget (≥ 30 FPS average, no frame over 100 ms on the emulator); the Academy's
   models and the crystal's draws counted; calm, kind, never scary; no pressure (no countdowns, no streak guilt, the
   crystal waits quietly and fades); English only; nothing personal kept or sent.

## Allocation and rules
- Yours: `core/discovery/*`, `entities/discovery/*`, `ui/discovery/*`, `data/discovery/*` (new), marked hooks
  ("owner #132 (W1)") in `scenes/sandbox.gd` (setup, MY MAP, the compass), the HUD's MORE menu and the pause menu (one
  entry each), `core/life/life_town.gd` (a third layout for the search, if you reuse it), tests
  `tests/**/test_discovery_*.gd`, a smoke `tools/discovery_smoke.gd`, notes `docs/devlog/parts/play-w1.md`, spec §22.0
  "As built (W1)", DEVELOPMENT.md. Running beside you: **Play G0** (`core/play/*`, `entities/play/*`, `ui/play/*`,
  `data/play/*`, `ui/school/school_screen.gd`, `ui/school/school_grown_ups.gd`, `core/school/curriculum.gd`, the main
  menu's School button) and **the Glow Caves** (`world/universes/glow*`, block page 45). Don't touch theirs: open the
  School through its existing public functions, and leave one clearly marked call for the lead to switch to G0's play.
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization,
  procedural-generation, 3d-essentials, godot-ui, xr-development, tween-animation); `--import` after new class_name
  scripts; logs `playw1_*` in the session scratchpad; look at the Academy and a crystal in a real window under `nice`
  (pictures in the notes); the FULL suite once at the end, right after merging lead-merge. Never open the editor or an
  emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents; no server changes.
  Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (what a child sees and does in the first five minutes of a new world, flat and VR; the Academy's placement
measured; the crystal's rules; the rulings and their costs; pictures; what the lead must check on the emulator and the
Quest 3), DEVELOPMENT.md, spec §22.0 "As built (W1)". Report: branch, commits, the full suite's result.
