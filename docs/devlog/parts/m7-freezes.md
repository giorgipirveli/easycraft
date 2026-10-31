# M7: "from time to time when playing it freezes" (the browser on phones)

The owner (2026-09-28), playing the browser version on phones. The lead measured it on the emulator's Chrome (a Moon
trip, every frame over 60 ms): 4700 ms at the trip's start, 2567 ms while the new world loads, 150 ms at the spawn,
2083 ms about 7 s into play; headless (`tools/frame_trip.gd`) the same shape without drawing. A worker agent took the
game-logic side (branch `worktree-agent-aa2c55a71414706c8`, from `lead-merge` 63d3c64; lead-merge 77e1c64 and 5f49f37
merged in later), without the editor, the emulator or a browser: everything below is measured headless on this PC, so
it is **the game logic's share** of those frames.

The lead's CPU profile of the emulator's first world load (`docs/devlog/2026-09-27-m7-web.md`, 06:00-06:35) later
showed that the browser's multi-second stalls are WebGL compiling shaders the first time something is drawn
(`getProgramParameter` 49 % of the profile, the game's wasm a few %); a second load of the same world had no frame over
60 ms. So the numbers here are not those freezes: the Moon trip's switch was 229 ms of logic here against the
emulator's 4700 ms frame. They still add up on phones (the app runs this logic 3-5x slower than this desktop, a
browser slower still), and they are what is left once the shaders are warmed up (a separate task).

## The tool: `tools/frame_probe.gd` (with `tools/frame_blame.gd`)

A session played headless, phase by phase: the menu, Sandbox NEW WORLD (seed 12345), 60 s walking, 30 s cruising
(FLY over new land), flying up to "Where shall we land?", the Moon, SAVE AND QUIT + CONTINUE, SAVE AND QUIT + Survivor
NEW WORLD. Every frame over `--over=` is printed with what it spent its time on, then a summary per phase. How to run
it: DEVELOPMENT.md §7 ("Long frames, one by one").

How the blame works, without touching the game: every node that processes (or physics-processes) gets its own priority
in tree order (the game sets none, so its order stays the same) and a marker node right after it that notes the time;
a node's cost is the time between the marker before it and its own. A frame (between two `process_frame` signals) is
split into physics scripts (per node), the physics engine, process scripts (per node; Timer nodes name their timeout's
target) and the rest (the scene change, SceneTree timers, tweens, freeing). The frame's start is split again into
coroutines resumed by `process_frame`, deferred calls queued before the frame and those queued meanwhile (a deferred
call queued from a one-shot listener connected at the end of the previous frame marks the boundary). Nodes added in a
long frame are listed by the panel they belong to, with the time from the previous panel's last node ("built").

Two traps found while building it (both in the tool now): a marker class with both `_process` and `_physics_process`
gets both turned on at ready (its time stamps then came from the wrong half of the frame), and the report of a long
frame is itself counted in the next frame's start ("this tool"; checking thousands of nodes once a second made it
look like 60-130 ms of mystery deferred work).

## What the long frames were

### The headless numbers were inflated by the generator's 12 threads (measure with `--voxel-threads=2`)

With this PC's default (12 voxel threads, a GDScript generator), the main thread's calls into engine methods slow down
10-50x while the terrain generates: a canary in the animal director's tick, 200 `height_at` calls, took 35-120 ms while
generating and 0.7 ms idle; 20,000 lines of plain GDScript maths took 2 ms either way; 2,000 calls of a *fresh*
`FastNoiseLite.get_noise_2d` took 7-35 ms (so it is not the shared shape: every call into the engine contends with the
12 threads doing the same). The first Moon-trip measurement's "burst a few seconds after arriving" was mostly this:
the animal director 300-560 ms, the secret director 110-430 ms, the player's physics 10-60 ms a frame. A phone's browser
has a quarter of its cores for voxel threads (`threads/count/ratio_over_max.web=0.25`: 1 on the emulator, 2 on an
8-core phone) and an 8-core phone's app 4; with 2 or 4 threads those frames are gone (new world, 10 s standing, 4
threads: worst 25 ms). All numbers below use 2 threads.

### The frames, and what each was (2 voxel threads, uncapped, 2026-09-28 05:00-07:00, load 2-20)

| Where | Frame here | What it was |
|---|---|---|
| Every world switch (the Moon trip, CONTINUE, a new Survivor world) | 186-252 ms (median; 390 with 12 threads) | The whole world UI built in one frame. The HUD's hidden panels: the block palette (~330 nodes, 24-88 ms) and the Secret Book with its tabs (~500 nodes, 48-154 ms: the Animal and Memory Books, idea cards, the saving list). The world's setup 35-80 ms: `VoxelTerrain`'s `mesher`, `generator` and `stream` setters wait ~10.5 ms each; the first world also builds the block library (25 ms), its shape (17 ms) and generator (62 ms). A new Meadows world's Theater site search 60-120 ms (TheaterSite.pick: up to 111 ms over 80 worlds). The rest small (the HUD itself 12-26 ms, the Brave badge 7.5, the wave HUD 6-50 the first time, the space line 8.5, the sky 4-7, the player 4-7). |
| "Where shall we land?" opens | 103-115 ms | Loading the three space worlds' descriptor scripts (the Moon 44 ms, Boing 21, Rainbow 21: with their generators and shapes) the first time a card asked for a name and colours. |
| The first second after the child stands | 17 ms | The animal director's first tick worked out every area in reach (~16 herds from the terrain's rules). |
| About 0.5 s after the child stands | 9-12 ms | The secret director's first tick (every secret area in reach). Left as it is. |
| Walking (60 s) | 176 frames of 10-33 ms | `VoxelEngineUpdater`: building terrain collision for the chunks coming into the collision viewer's box. |
| Cruising (30 s of FLY over new land) | 214 frames of 8-91 ms (33 over 33 ms, 8 over 50) | The same, faster: with the terrain's collision switched off (a scratch run) 18 frames of at most 10 ms. |
| The menu | 10-20 ms frames while its backdrop streams | The backdrop's viewer asked for collision out to 96 blocks (nothing on the menu stands on the ground). |
| SAVE AND QUIT | 40-130 ms | Freeing the world and building the menu (its world's setup again, its first draw). Left as it is. |
| A new world from the menu (first time in a run) | 2-3 s | Loading `sandbox.tscn` and compiling its ~400 scripts from source; an export loads tokenized scripts (the lead saw "Sandbox world in 2.1 s" in the browser). Not measured further. |

## The fixes (each test-first; before/after from the probe, medians of 3 runs made alternately, `--voxel-threads=2`)

| Fix | Test | Before → after |
|---|---|---|
| The HUD's block palette and Secret Book are built the first time they open (`build_later`; `open`, `show_page`, a tab, the slots build them; built alone, as in the tests, they build at once) (`7dc6be4`) | `test_lazy_panels.gd` (6); `test_books_tabs.gd` opens the book first now | The Moon trip's switch 229 → 126 ms, CONTINUE 186 → 96, Survivor NEW WORLD 252 → 176 |
| The space worlds' files load in the background from the start of the climb (y 160): `UniverseRegistry.warm_space` asks `ResourceLoader` threads, `descriptor()` claims them (`e59831f`) | `test_the_climb_warms_the_space_worlds_once`, `test_monster_wave_warms_nothing`, `test_warming_loads_the_space_worlds_files_in_the_background`, `test_warming_skips_a_world_a_test_stands_in_for` | The fly phase's worst frame (the picker) 115 → 22 ms |
| The animal director works out 3 new areas a tick, the nearest first, and none once no animal can come this tick (`b3483f1`) | `test_director_works_out_a_few_new_areas_per_tick_nearest_first` | The first tick near a child (bench, seeds 12345, 777, 99): 7.0-7.9 → 0.1-2.7 ms (17 ms in-game before) |
| The menu's backdrop world builds no collision (`1d7ccd9`) | `test_menu_backdrop.gd` | Frames over 16 ms in 15 s of menu: 13/4/2 → 1/1/1 (the menu's own first frame) |
| A new world's Theater site is searched on a worker (`TheaterDirector.search_later`, high priority like Pip's playground search); the Theater stands when it ends and the world's save gets it (`site_placed`) | `test_a_new_worlds_theater_is_searched_on_a_worker`, `test_a_saved_theater_stands_at_once_even_when_searching_later`; a headless check: the new world's Theater stood at `[-25, 34, 19, 1]`, where `pick_for` puts it, and the save kept it (`1419e9b`) | Survivor NEW WORLD's switch 307 → 148 ms |

## The whole session before and after (all fixes at once)

`tools/frame_probe.gd`, every phase, `--voxel-threads=2`, no FPS cap, 3 runs of each made alternately (lead-merge's code
vs this branch's, the same tool; load 3.6-14 before, 6.6-8.2 after). The worst frame per phase, median of 3, and in
brackets the frames over 16 ms of work (median):

| Phase | Before | After |
|---|---|---|
| The Moon trip's switch (trip-load) | 508 ms (2) | 126 ms (1) |
| Sandbox CONTINUE (continue-load) | 356 ms (5) | 97 ms (1) |
| Survivor NEW WORLD (survivor-load) | 284 ms (2) | 125 ms (2) |
| Flying up to "Where shall we land?" (fly) | 25 ms (1); 126 ms in the run where the picker opened | 14 ms (0) |
| The menu, 3 s (menu; its first frame is the scene's load) | 626 ms (5) | 587 ms (1) |
| SAVE AND QUIT and the menu (menu-2) | 76 ms (7) | 51 ms (1) |
| Walking 60 s (walk) | 44 ms (79) | 44 ms (64) |
| Standing after a new world, CONTINUE, Survivor, the Moon | 24-37 ms | 11-24 ms |

(In two of the three "before" runs the fly phase never reached the picker, so their trip phases are missing: the medians
of trip-load come from one run before and three after; the earlier per-fix A/B runs above are the cleaner comparison.
The walk's path depends on frame times, so its runs differ in where they go. In these runs the cruise after the walk
started in a hollow and never moved, so it is left out; the tool now turns and lifts a boxed-in flyer, and ruling 6's
cruise numbers come from runs of `new,cruise`.)

## Tests

New: `test_lazy_panels.gd` (6), `test_menu_backdrop.gd` (1); added to `test_space_director.gd` (2),
`test_space_registry.gd` (2), `test_animal.gd` (1), `test_theater.gd` (2); `test_books_tabs.gd` opens the book before
it looks at its pages. Full suite after merging lead-merge 5f49f37 (`--import` clean, no Parse Error): **693 scripts,
6363/6365 pass** (the two never-asserting, as before), 0 failures, 0 script errors.

## Rulings (with what each costs if wrong)

1. **The palette and the book are built on their first open, not spread over idle frames.** Cost if wrong: the first
   tap on the palette or BOOK in a world takes the build (here 25-90 and 50-150 ms; several times that on a phone),
   once per world. Building them in slices while the child plays would move that into play, which is what
   the owner reported; a tap that answers a little late is the smaller evil.
2. **The space worlds' files load on `ResourceLoader`'s threads when the climb starts.** Cost if wrong: if threaded
   script loading misbehaves in a browser, the picker's frame waits for the load as before (`load_threaded_get` waits);
   the lead checks the picker on the emulator.
3. **Animals: 3 new areas a tick, nearest first.** Cost if wrong: where the nearest three areas have no herd, the first
   animals come a second later (seed 777); the herds nearest the child now come first, which they did not before.
4. **The menu's backdrop builds no collision.** Cost if wrong: something added to the menu later that walks on the
   ground would fall through it.
5. **The Theater's site search runs on a worker.** Cost if wrong: in a slow browser the search could end after the child
   stands (the Theater appears a moment later), and Pip's playground (whose own search runs at the spawn) could then miss
   keeping clear of it.
6. **Terrain collision while moving is left as it is** (the biggest cost left in play). It is Voxel Tools' own
   main-thread work, and every way to shrink it changes where things can stand. Measured (one 30 s cruise each, load
   17-20; the collision viewer's box is `Player.COLLISION_DISTANCE` = 48 around the player, as high as it is wide):
   as it is 3,909 ms in 214 frames over 8 ms (worst 91); the box half as high (±24) 2,716 ms, worst 35; 32 blocks
   instead of 48: 2,202 ms, worst 42; no terrain collision: 92 ms. Animals and bot friends are simulated within 32
   blocks *sideways* of a player at any height, so a flatter or smaller box would drop some of them through the
   ground on hills: the lead decides, on the emulator.

## Left open

- Terrain collision while walking and flying (ruling 6).
- A world switch still costs ~100-180 ms here (~1-1.8 s in a phone's browser): the three `VoxelTerrain` setter waits
  (~32 ms: waiting, not work), the HUD, the sky, the player, the space line.
- SAVE AND QUIT (40-130 ms: freeing the world, the menu's world setup and first draw; 250 ms more only when the menu
  was never shown in that run, which a child's game never does), the secret director's first tick (9-12 ms).
- CONTINUE: while a saved world's chunks come in (behind the loading card and just after the child stands),
  `VoxelEngineUpdater` builds their collision at 35-56 ms a frame for about a second (ruling 6 again).
- Freeing a world while it streams waits for Voxel Tools' queue (the M4 gotcha; `Game.quit_to_menu` and the space
  trip do not stop the viewers first). Not hit here: the probe found 0 queued tasks before every trip and SAVE AND
  QUIT, even 3 s after cruising (2 threads) and with 1 thread; left as it is.
- What headless cannot show: shader compiles when something is first drawn (WebGL compiles on first use). The
  emulator's "2083 ms about 7 s after arriving" may be partly that (the Moon's bunnies, crystals, the portal appear
  then); the game already prewarms its particles and the portal swirl (`Fx.prewarm`, `PortalSwirl.prewarm`).
