# The practice rooms look like real places: the agent brief (the owner's standing goal: "create amazing and best visuals")

The lead's emulator check (2026-10-17 20:50) found Life's and Success's practice rooms work and run fast (Talk & Deal
60 FPS, Find Your Way 58-60 FPS, Water Safety 54-60 FPS, no frame over 50 ms on the Pixel 8 emulator) but look bare:
a white floor that runs to a plain blue background, flat colour boxes, signs and name tags that overlap ("ANA'S
APPLES" over Ana's own tag in Talk & Deal), and first views that cut things off (Water Safety's lifeguard's head above
the frame, the reach pole across the view). These rooms are where children learn by doing (22 Experiences on three
tracks, in flat and VR), and owner #122 (`docs/design/learning-is-play.md`) makes places like them the home of all
learning: they must look like somewhere a child wants to be. Work autonomously; do not ask questions (decide, and write
each ruling down with what it costs if wrong).

## Read first
- `docs/devlog/parts/life-l1.md`, `life-l2.md`, `life-l3a.md`, `life-l3b.md`, `life-l3c.md`, `success-s2.md`,
  `success-s3.md` (what each room is for, its views, its VR reach rules), `docs/design/life-skills.md` §4, §6, §10.
- The kit and the host: `entities/life/life_room_kit.gd` (its header: no assets loaded, shared materials by colour, no
  shadows from the rooms' own lights, only shaders the game already warms up, the background a plain colour: **these
  rules exist for the Quest's budget; keep their reason, improve within it**), `entities/life/life_room.gd` (`env`,
  views, targets, `glow`), `entities/life/life_room_host.gd`, every room in `entities/life/*_room.gd`,
  `entities/life/practice_house.gd`, `entities/success/*` rooms, `entities/tools/tool_room_host.gd`.
- The budgets: CLAUDE.md (≥ 30 FPS average and no frame over 100 ms on the emulator), DEVELOPMENT.md's performance
  section and its VR line (Quest: ≤ 100 draws a frame at 72 Hz on the floor preset, ≤ 750K triangles; `tools/vr_bench.gd`),
  the shader warm-up and its census (`ShaderWarmup`, `tools/shader_probe_steps.gd`: a new material must be one the game
  already warms up, or be added to the census with its test).
- `docs/devlog/parts/visuals.md` (the game's light, haze, colour decisions) so the rooms match the worlds' look.

## Build
1. **A shared look for every room** (in the kit, used by all rooms): a real floor for each kind of place (wood planks
   indoors, paving and kerbs in the street, sand and tiles at the pool, grass and paths outdoors) from the game's own
   block textures or simple patterns the warmed-up shaders already draw; walls with windows, skirting, a door, a few
   shelves or plants where a real room would have them; a soft sky or ceiling instead of the plain background (the
   menu world's sky look or a gradient); one warm key light and gentle ambient (no new shadows). A small set of
   decoration helpers (`LifeRoomKit.window`, `plant`, `shelf`, `rug`, `lamp`, `fence`, … your names) built as few meshes
   as possible (merge static decor into one mesh or a MultiMesh per material: draws matter more than triangles).
2. **Each room dressed as its place** (all of Life's and Success's rooms: the practice house, the kitchen, the street,
   the pool and beach, the poisons cupboard, the electricity room, the animals' farm, the medical room, the online city,
   find your way's market, school, metro and park, the home helper's home, earth and weather, calm corner, the first-aid
   room, Talk & Deal's stall, the Goal Board, the Connections Book, Success Stories, My Shop's bakery, the Market Square):
   what a child would expect to see there, calm and friendly (spec §3c), never cluttered around the steps.
3. **Fix what the emulator showed:** no sign over a name tag (a rule in the kit: tags and signs keep apart; a test), every
   room's first view frames its people and things whole (a test per room: the people's heads inside the first view's
   frustum, nothing within 0.5 m of the camera across the middle of the view), no text cut at the edges of the first view.
4. **Never change what a room teaches or how it is played:** every target, view, step, reach and VR stand stays where it
   is (the rooms' tests and the VR reach rules must pass unchanged: e.g. L3a's rescue branch at 1.06 m, the crouch under
   the table, L3c's tablet and watering can, S3's honey buns at 1.14 m). Decoration never sits on a path, a target or
   within a VR reach line. `LifeRoomKit`'s existing functions keep their signatures (Play G0 may be building on them);
   add new ones.
5. **Fast everywhere:** per room, count draws and triangles before and after (`tools/vr_bench.gd`'s pattern or the
   rooms' own counters); stay ≤ 100 draws a frame for the heaviest room in VR (the Quest floor preset) and keep the
   emulator's ≥ 30 FPS / no frame over 100 ms; if a room is over, merge more. Record a table in the notes.
6. **Look at it:** pictures of every room's first view in a real window under `nice`, one at a time (the patterns in
   `tools/look_shots.gd` / `tools/space_shots.gd`), before and after, both graphics styles where they differ; fix what
   looks cheap; put the before/after contact sheet's path in the notes.

## Allocation and rules
- Yours: `entities/life/life_room_kit.gd`, the decoration parts of `entities/life/*_room.gd`,
  `entities/life/practice_house.gd`, `entities/success/*` rooms' decoration, `entities/life/life_room.gd`'s `env` and
  background, new helper files `entities/life/life_room_decor*.gd`, tests `tests/**/test_room_look*.gd`, a tool
  `tools/room_shots.gd`, notes `docs/devlog/parts/rooms-look.md`, DEVELOPMENT.md's Life rooms section (the look rules).
- Running beside you: **Play G0** (`core/play/*`, `entities/play/*`, `ui/play/*`, `data/play/*`, `ui/school/*`'s flow,
  `core/school/curriculum.gd`, small marked hooks in Life's files), **the Glow Caves** (universe 6: `world/universes/glow*`,
  block page 45, ids 768-783, its monsters and boss). Don't touch theirs; if you must touch a line G0 might also touch
  (the kit's existing functions), don't.
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (3d-essentials, godot-optimization,
  shader-basics, xr-development); `--import` after new class_name scripts; logs `rooms_look_*` in the session
  scratchpad; the FULL suite once at the end (tests/run_tests.sh drops a plugin's python3 shim itself; ad hoc Python:
  /usr/bin/python3). Never open the editor or an emulator, never touch adb; never merge or push; no downloads; never
  start agents. CC0 or own assets only (the game's own textures are fine). Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way. Right before your final full suite, merge
  lead-merge and run the suite on that merged tree.

## Finish
Notes (the look rules, each room's before/after picture paths, the draws and triangles table, the rulings and their
costs, what the lead must check on the emulator and the Quest 3), DEVELOPMENT.md. Report: branch, commits, what changed
in each room, the budget table, the full suite's result.
