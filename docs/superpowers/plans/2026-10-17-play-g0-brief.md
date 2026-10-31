# Play G0: every unit becomes a game — the agent brief (owner #122)

The owner (2026-10-17 18:49, #122): "all lessons should be game, part of game, mini games and etc but games, not
lectures and slides and classical lessons, this is why we are not school, we are something more … this must be future
of education". You build the first step in EasyCraft (Godot 4.7.2, typed GDScript; phones, the web, PC and VR on the
Meta Quest 3): **on the day this merges, no unit of the School is slides and a quiz any more; every written unit (790,
grades 3-8, twelve subjects) is played.** Work autonomously; do not ask questions (decide, and write each ruling down
with what it costs if wrong).

## Read first
- **`docs/design/learning-is-play.md`** (all of it: the evidence §2, **the seven rules §3**, the loop §4, **the generic
  mechanics §5.1**, where it lives §6, the `play` format §7, the rulings §9) and spec §22.0. This is the authority.
- The School as built: spec §22, `docs/DEVELOPMENT.md`'s School section; `ui/school/school_screen.gd` (the pages: map,
  unit, lesson, round, round end, grown-ups), `ui/school/exercise_panel.gd` and its answer widgets, `core/school/*`
  (`Curriculum`, `ExerciseCheck.is_right` / `answer_of` / `answer_text`, `MasteryRules.after_round`, `BuildCheck`,
  `SchoolGen`, the generators in `core/school/gen/*`), `ui/school/school_picture*.gd` (the pictures), the data
  `data/school/grade<N>.json` and `data/school/g<N>/<subject>/<unit>.json`.
- Life's framework, the model for learning by doing: `docs/devlog/parts/life-l1.md`, `tools-r4b.md`, `life-l3c.md`;
  `entities/life/life_room_host.gd`, `entities/tools/tool_room_host.gd`, `entities/life/life_ghost_hands.gd`,
  `core/life/life_check.gd` (steps, motions, the coach, ghost hands, tracks, VR hands).

## Build
1. **The play layer** (`core/play/*` pure rules, `entities/play/*` the places, `ui/play/*` the coach and the Book):
   a unit's **loop** (design §4): the hook (15 s, a problem appears in the place), the try (a level-1 challenge before
   any words), see why (the coach's one line after the try, from the unit's cards: one idea, at most 12 words, read
   aloud; after two misses the **ghost hands** do one step), play (rounds at levels 1-3 from the unit's exercises and
   generators), use it in the world (the unit's "Try it in the world" card as a quest card the child takes with them),
   come back (`MasteryRules`' reviews start the same game with new challenges). **`ExerciseCheck` stays the referee**
   and **`MasteryRules` the record**: a challenge solved in play is an exercise answered (first try counts as now),
   so stars, reviews, the gold once, the daily mission and the grown-ups' page keep working unchanged.
2. **The generic mechanics** (design §5.1), each a small place (a room or an arena) with its own pure rules and
   tests, flat and VR (VR: the hands do the move):
   - **Make it** (number): the quantity is made with things: blocks stacked, base-ten rods joined, fraction bars cut,
     coins paid, a number line jumped, a jug filled, a scale balanced (choose the maker from the exercise: whole
     numbers, money, fractions, decimals, measures; a ruling for the rest).
   - **Sort it** (sort), **Order it** (order: a bridge, a timeline path or a story strip that only works in order, the
     buddy walks it), **Connect it** (match: wires or pipes, the lamp lights or the water flows), **Fix it** (label).
   - **Build it** (build: the block board in the world, `BuildCheck`), **Code it** (robot), **Beat it** (rhythm),
     **Mix it** (mix), **Find it** (point): reuse what the School's widgets already do, placed in the world.
   - **Choose by doing** (choice, 5,755) and **Test it** (truefalse, 2,280): the options are things to act with (give
     the right thing to the buddy who needs it, take the path, set the switch), never buttons on a panel; a claim is
     tested where the game can show it, and otherwise the world shows what each choice leads to. This is the weakest
     bridge (design §5.1): make it as much play as you can, and say honestly in the notes what it still is.
   - The exercise's picture (any `SchoolPicture` kind) shows in the place on a board, a screen or a sign when the
     challenge needs it.
3. **DISCOVER** (design §6): the menu's SCHOOL button says DISCOVER for children; the map shows each subject's units as
   places to play (not a list of lessons); a unit's page offers PLAY first and **the Book** (today's cards, as they are,
   read aloud) as a small choice; children no longer reach the old lesson-then-round path (keep its code only where
   tests or the grown-ups need it, and say where). The grown-ups' page keeps the programme's words (grades, subjects,
   standards) and gains each unit's **play level** (P0 generic, P1 its own game: all P0 now).
4. **The `play` block** in a unit's file (design §7): optional fields (`hook`, `game` and its parameters, `coach`
   lines, `world_task`), read by `Curriculum`; absent means the generic mechanics by type; document the format in
   DEVELOPMENT.md so the content agents write play-first from now; one unit per subject with a hand-written `play`
   block as the example.
5. **The lead's audit:** `tools/school_audit.py` (or a new `tools/play_audit.py`) counts units by play level and lists
   any unit that can't be played (a type with no mechanic: there must be none at the end).
6. Flat and VR, the phones' budget (≥ 30 FPS average and no frame over 100 ms on the emulator; places as small as
   Life's rooms), read aloud everywhere, the grown-ups' gate unchanged.

## Allocation and rules
- Yours: `core/play/*`, `entities/play/*`, `ui/play/*`, `data/play/*` (new), `ui/school/school_screen.gd` and
  `ui/school/school_grown_ups.gd` (the flow and the page), the menu's School button (`ui/menus/menu.gd`, one line and
  its tests), `core/school/curriculum.gd` (reading `play`), small marked hooks in `core/life/*` / `entities/life/*` /
  `entities/tools/*` if you reuse Life's rooms or ghost hands ("owner #122 (G0)"), tests `tests/**/test_play_*.gd` and
  the School tests your flow change makes wrong (fix them to the new flow; never delete what they protect), notes
  `docs/devlog/parts/play-g0.md`, spec §22.0's "As built (G0)", DEVELOPMENT.md. Running beside you: two School content
  agents (`data/school/g7/*`, `data/school/g8/*`, `core/school/gen/*`, `ui/school/school_picture*.gd`) and Success S3
  (`core/success/*`, `entities/success/*`, `ui/success/*`, `data/success/*`): don't touch theirs.
- Report before you build (in the notes' first section and your first commit message): the pattern you picked for the
  places (Life's rooms, a new arena, or both), the alternative you rejected, and why.
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization,
  component-system, godot-ui, xr-development, tween-animation, 3d-essentials); `--import` after new class_name scripts;
  logs `play0_*` in the session scratchpad; a smoke tool `tools/play_smoke.gd` that plays one unit of every exercise
  type through its mechanic (and, sampled, a unit of every subject and grade); the FULL suite once at the end
  (tests/run_tests.sh drops a plugin's python3 shim itself; ad hoc Python: /usr/bin/python3). Never open the editor or
  an emulator, never touch adb; never merge or push; no downloads; never start agents. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Calm, kind, never scary; never gambling; no pressure tricks; English only; nothing personal kept or sent; no
  microphone; CC0 or own assets only.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way. Right before your final full suite, merge
  lead-merge and run the suite on that merged tree.

## Finish
Notes (what a child does in each mechanic, flat and in VR, with a unit of each type as the example; the loop; the
pattern picked and rejected; the rulings and their costs; the play levels counted; what the lead must check on the
emulator and the Quest 3), DEVELOPMENT.md (the `play` format for the content agents), spec §22.0 "As built (G0)".
Report: branch, commits, the mechanics, the share of units playable (it must be all), the full suite's result.
