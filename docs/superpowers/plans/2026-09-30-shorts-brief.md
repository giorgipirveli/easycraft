# EasyCraft Shorts — the agent brief (owner #94; spec §5.12b)

You are building **EasyCraft Shorts** in EasyCraft (Godot 4.7.2, typed GDScript), a game for children: short learning
animations made and drawn by the game itself, swiped like TikTok, in the TV shows room. The owner (2026-09-30):
"implement short scrollings like tiktok where [we] create videos and animations which must be educational, like how to
build a rocket, lessons explanations, learning animations and etc. this should be presented at tv shows room". Work
autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§5.12b (your design)** and §5.12 (the Theater as built, owner #89),
   `docs/devlog/parts/tv-shows.md`, and `docs/design/` (fair fun: no rewards for watching, no endless feeds).
3. Study: `ui/theater/theater_panel.gd` (the panel, its channels as tabs, CLOSE/BACK/NEXT, the parent gate and the
   switch), `core/theater/*` (channels, rules, session, feed), `world/theater*` / `TheaterDirector` (the building, walking
   in); the School's pictures (`ui/school/school_picture*.gd`: `draw(self, data, r)` per kind, `problem(p)`), lessons
   (`data/school/g*/<subject>/<unit>.json`: `lesson: [{text, picture?, sound?}]`), `SchoolSound`, the read-aloud voice
   (`ui/progress/read_aloud.gd` and how the School reads a card), `RocketParts`/`RocketCheck`, `StarMap`, the
   characters' 2D pictures if any (Professor Hoot is drawn in the School), `PadFocus`/`GamepadRules` (controllers),
   `PlatformRules` (PC: mouse wheel and keys).

## Allocation
- New files: `core/shorts/*` (pure rules: the Short's data, its checks, the feed's order, likes and seen, making a Short
  from a lesson), `ui/shorts/*` (the player, the feed, the like and LEARN IT buttons), `data/shorts/*.json` (the
  hand-made Shorts), tests `tests/**/test_short*.gd`, a smoke `tools/shorts_smoke.gd`, notes
  `docs/devlog/parts/shorts.md`.
- Small additions: the Theater's panel (a SHORTS tab first, its portrait view), the profile (liked and seen Shorts, in
  `ProfileData` with its backup), LEARN IT's hooks (opening the School at a unit, the Mission Board, the Star Map).
  Another agent is improving **animations** (the world, the characters, the School's pictures: it may add an optional
  animated drawing to picture kinds) and another the **School's lessons' quality** (grades 3-6): don't edit lesson
  files or picture kinds' drawing; call the pictures as they are (if an animation API appears on lead-merge, use it).

## What to build
1. **The Short's format and player.** A Short = `{id, title, topic, link, grade?, scenes: [{seconds, background,
   caption, say, actors: [{kind, …, moves: [{at, to, …}]}], sound?}]}`: actors are words, a School picture (any kind,
   with its data), a block's icon, a rocket part, a planet or moon (StarMap's colours), a character; moves are
   time-based (appear, move, grow, spin, fade, pop, bounce, draw-on for lines/arrows) so the player can **seek** (tests
   and the feed's snapping play any moment exactly). Captions always on screen (big, high contrast), the `say` words read
   aloud, a quiet sound or note on cue. A checker like the School's content test: every actor kind known, every
   picture's data valid (`SchoolPicture.problem`), seconds 20-60, words short and kind (the no-guilt-words test), links
   that exist.
2. **The feed in the Theater.** A **SHORTS** tab first; its view: a 9:16 player in the middle, the title and the
   topic's colour, a heart (LIKED), LEARN IT, the position ("3 of 40"), and the feed's list beside it; swipe up/down
   (drag with snapping), the mouse wheel, ↑/↓ and the D-pad; each Short plays as it snaps in and loops; CLOSE/EXIT as
   the panel has them. The order teaches: new first, a topic's Shorts together, seen ones marked; filters: Hand-made,
   Lessons (by grade, then subject), Liked.
3. **The first hand-made Shorts** (at least 16, real and checked facts, sources in your notes): how to build a rocket
   (parts, stages, thrust against weight, fuel: the game's own RocketCheck numbers), a crew flight, the planets going
   round the Sun (the orrery's real years), the Moon's phases, gravity on every world (a jump's height on each),
   why Venus is the hottest planet, Saturn's rings are ice, ice to rocket fuel on the Moon (ISRU), a lever lifts, the
   water cycle, photosynthesis, fractions of a pizza, place value, a food chain, how a circuit lights a bulb, the Seven
   Wonders' map. Each 20-60 s, 3-6 scenes, one idea, a question to wonder about at the end.
4. **Lessons in a minute.** A Short made at run time from any written School unit's lesson (grades 3-7): its cards in
   turn, each card's picture popping in and its words as the caption and voice (long cards split), 30-60 s; LEARN IT
   opens that unit. Build them lazily (only the ones on screen and the next), so the feed can list hundreds.
5. **Safe and fair:** only our Shorts in this tab; no gold, points or streaks for watching; the grown-ups' Theater switch
   covers it; works offline; English only.
6. **Fast:** 2D only; the next Short built while one plays; swiping holds the budget (≥ 30 FPS, no frame over 100 ms;
   a per-frame cost test and a bench in your notes).

## Tests and checks (TDD)
Failing tests first (the format and its checker, seeking gives the same frame, the feed's order and filters, likes and
seen saved with the profile, lesson → Short, every hand-made Short valid, the panel's tab and swipe inputs, LEARN IT's
targets). `--import` and grep Parse Error after new class_name scripts; single tests with `tests/run_tests.sh -gtest=…`.
A smoke (a private XDG_DATA_HOME containing "smoke") opens the Theater's SHORTS, swipes through 10, likes one, opens
LEARN IT: 0 fails. Windowed pictures of a few Shorts at phone and PC sizes if you can open a window (say what you saw).
The FULL suite once at the end. Never open the editor or an emulator; never touch adb. Never merge or push. Never
start agents.

## Finish
Notes (rulings, each Short's facts with sources, what a child sees, the bench, what the lead must check on the emulator:
swiping by touch, the voice, the size on a phone); spec §5.12b "As built"; `docs/DEVELOPMENT.md` (how to write a Short,
the checker); commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch,
commits, what a child sees, the Shorts made, the smoke's and full suite's results, what the lead must look at.
