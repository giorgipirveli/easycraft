# Frame spikes in the new worlds (2026-09-30, the frame spikes agent)

The brief: `docs/superpowers/plans/2026-09-30-frame-spikes-brief.md`. The lead's emulator runs (dev log
`docs/devlog/2026-09-27-m7-web.md`, 10:12 and 13:13): the Moon (16), blocky, one 142.8 ms frame 4.3 s into the
autopilot's play and one 129.3 ms 10.5 s into its flight (another run: 120.3 ms at 25 s of the flight); Wonders of the
World (41), blocky, one 109 ms frame 24.8 s into play and 27 frames over 100 ms 700-900 m into the flight (the PC's
load 6 → 15 then). Branch `worktree-agent-a7c40dd031b517770`, from `lead-merge` `3ac8775` (crew flights merged). No
editor, emulator or adb: everything below is measured headless on this shared PC (load 4-22 while other agents' suites
ran); the lead re-measures on the emulator.

The emulator's Android app draws with OpenGL (`gl_compatibility`: the emulator has no Vulkan), so the game's shader
warm-up runs there (`PlatformRules.warms_shaders`), and a material drawn for the first time compiles on the main thread
(~0.1-0.2 s on the emulator, ~1 s in a phone's browser). A headless run cannot time that, so each spike was looked at
two ways: what the main thread spends (the frame probe, now with each long frame's CPU time) and what the camera sees
for the first time and whether the warm-up had it ready (the new first-sights tool, against the census).

## The tools (all new or extended here)

- **`tools/frame_probe_steps.gd`**, phases `moon-pilot`, `mars-pilot`, `venus-pilot`, `wonders-pilot`: what the lead's
  developer menu does (WORLD, AUTOPILOT BLOCKY: `Game.start_world(SURVIVOR, true, NORMAL, u)` with `Game.autopilot`),
  so `tools/autopilot.gd` itself plays (its 3 s wait, 60 s play, 2 km ghost flight); each long frame says the pilot's
  t, the distance flown and where. `wonders-road`: world 41, down the Wonders Road on foot (its speed pads), then a
  flight at 20 m over the ground to each of the New Seven and back to their square. `--cpu`: each long frame's
  main-thread CPU and run-queue time (`/proc/thread-self/schedstat`): on this PC a 45 ms frame was often 11 ms of work
  and 34 ms of waiting for a core. `--sights`: `tools/first_sights.gd`.
- **`tools/first_sights.gd`**: every 0.25 s, what the game's camera sees (visible in the tree, in the frustum and the
  far plane, within its visibility range; lit or not by an OmniLight3D in range): each draw's census key the first
  time it is seen, its tier (FIRST, WORLD, SOON, LATER, NEW = not in the census), and whether a child who went straight
  from the menu to this world had it warm: before this work (the first world's part: FIRST and WORLD, never a lantern
  variant) and now (`ShaderWarmup.in_world_part` of the world). A summary per phase at the end. Tests:
  `tests/unit/test_first_sights.gd` (3).
- **`tools/frame_blame.gd`**: also the nodes that left the tree in a long frame (`gone`), like those built.
- **`tools/shader_probe_steps.gd`** (the census): every world's landing in a phase named after the world (§ "The
  census"), `survivor` (a new Survivor world of Green Meadows), `newseven`, and the phase `travel` between worlds.
- **`tools/flight_census_steps.gd`**: builds the flight's set and moments before it describes them (they are built
  over the boarding's frames since the flight's own fix; the census had lost the wormhole's tunnel).

Commands (a private folder whose path contains "smoke", with a copy of `profile.json`):
`XDG_DATA_HOME=<folder> nice godot --headless --rendering-method gl_compatibility --path . --script
res://tools/frame_probe.gd -- --phases=moon-pilot,wonders-pilot --over=12 --voxel-threads=2 --cpu` (add `--sights
--no-blame` for the first sights; `wonders-road`). About 4 minutes a pilot phase (it flies the whole 2 km).

## What each spike was

### The Moon: the play's single slow frame (t = 4.3 s) — a first sight the warm-up had not reached

Main thread (`moon-pilot`, 3 runs, load 12-17): play worst 25 ms wall, but 3.2 ms of CPU (17 ms waiting for a core);
the worst CPU in play 14.8 ms (`VoxelEngineUpdater` 11.5 ms: Voxel Tools applying meshes and building collision). No
game-logic spike: 15 ms here is ~45-75 ms on a phone.

First sights in the Moon's play, with the census as it was (a child from the developer menu: the warm-up's world part
drawn, its rest waiting for an idle menu or a card, "never in play"): **+2.6 s the Moon Base's chest shine (SOON)**,
+5.7 s a thought bubble (SOON), **+7.2 s the portal circle's swirl by a Survivor spawn (LATER)**, +9.2 s **the Earth
hanging in the Moon's sky (SOON; the census never counted a sky body as on screen: it hangs hundreds of metres away)**.
Each is a new shader the emulator compiles in that frame (~0.1-0.2 s): the 142.8 ms frame at t = 4.3 s is one of the
first two (the lead's circle turns at a slightly different rate). The census also had never seen a Survivor world (the
autopilot plays Survivor): its spawn's portal circle (swirl and stones) was LATER.

### The Moon: the flight's single slow frames (t = 10.5 s, 25 s)

Main thread (`moon-pilot` fly): worst CPU 16.8 ms (`VoxelEngineUpdater` 14.3 ms); 45 ms wall at 83 m was 11 ms of CPU.
First sights in the flight (my runs flew east): a moon bunny at 122-134 m (WORLD: warm). The flight goes 12 m over the
landing's ground in a straight line through whatever is there (ghost mode); where it enters a hill or a crater's rim the
player's cave lantern lights the avatar, and **the avatar's lantern variants were in the warm-up's rest** (seen in world
41's flight at 1,100 m, "WORLD lit"). With the lead's direction unknown, the flight's frames are one of: the avatar by
its lantern (now in every world's part), a sight past the landing (SOON/LATER), or `VoxelEngineUpdater` (14 ms here,
~40-70 ms on the emulator) on a busy PC.

### World 41: the play's frame (t = 24.8 s) and the spawn

First sights in play: +7.8 s the portal circle's swirl and +8.0 s its stones (a Survivor spawn: LATER). Main thread:
play worst CPU 14-16.6 ms (`VoxelEngineUpdater`). **The spawn's first 0.1 s: 22-46 ms frames, the secret director's
first tick 18.6-24.1 ms** (3 runs): it worked out every secret and mouse village within 40 m on the main thread (the
mouse villages' search alone 10 ms at world 41's landing, 6 ms in Green Meadows; a bench,
`SecretRules.tiny_near`). Not in the autopilot's measured play (its 3 s wait), but a child's first second.

### World 41: the flight's run of slow frames (700-900 m)

Main thread (`wonders-pilot`, GL, load 7-14): `VoxelEngineUpdater` 15-23 ms of CPU in 15-49 frames of the 2 km (the
Meadows land past the parks: trees and hills, more collision triangles than the Moon's dust), the animal director's
ticks 8-9 ms (a tick worked out up to 3 new areas' herds, 3-6 ms each in world 41's shape, and built up to 3 animals,
3-5 ms each, in one frame), and in the same frames the herds left behind being freed (`gone: Animals … 7-21 nodes`).
Together 20-30 ms here: 60-150 ms on the emulator, more with the load at 15 (the emulator's cores are this PC's).
First sights: the chest shine at 389 m (SOON), a mouse family at 396-705 m (LATER), a levers vault at 766 m (SOON), the
avatar by its lantern at 1,100 m. One frame of 25-30 ms CPU at 386 m in "post" (deferred work, nothing built or freed)
was not seen again in 4 more runs.

### Mars, Venus, the New Seven

Mars and Venus: the lead's runs are in budget; their landings are in the census now (their sky's planet is their only
draw beyond the first world's). The Wonders Road on foot and the flight round the New Seven: nothing over 23 ms, no
first sight that was not already warm.

## The fixes (each test-first)

| Fix | Test | Before → after (this PC, headless) |
|---|---|---|
| **A world's loading card waits for that world's own draws** (`ShaderWarmup.world_part`, from a new `LoadingCard`'s `universe()`): the blocks and the child's own look (also by a lantern), FIRST, the player's feedback, and what the census saw on screen at that world's landing (`world_phases`: its name; Green Meadows: `new`, `continue`, `survivor`); another world's draws go back to the rest (`b1705ce0`) | `test_shader_warmup.gd` `test_a_world_s_census_phase_is_its_name`, `test_a_world_s_part_is_what_the_census_saw_on_screen_at_its_landing`; `test_shader_warmup_spread.gd` `test_a_world_s_loading_card_waits_for_what_that_world_shows` | First sights in play that compile for a child straight from the menu: see "First sights, before and after" |
| **The sky's bodies count as on screen** (`ShaderWarmup.SKY`, SkyCycle's NightSky) (`b1705ce0`) | `test_the_census_counts_the_sky_s_bodies_as_shown_however_far`, `test_the_sky_cycle_s_bodies_are_the_sky_s` | The Earth in the Moon's sky (and every space world's planet) is in its world's part |
| **A new Survivor world is a first world** (`WORLD_PHASES` + `survivor`): its spawn's portal circle | `test_a_first_survivor_world_is_a_first_world` | The portal swirl and stones LATER → WORLD |
| **The child's own look by the player's lantern** is in every world's part (`player_look_keys`: AvatarParts' materials, skinned bodies) (`2d1897a3`) | `test_the_avatar_by_its_own_lantern_is_in_every_world_s_part`, `test_first_sights.gd` | The avatar lit in world 41's flight: compiled → warm |
| **The census again** (`79e483b4`): every world's landing, Sandbox and Survivor; `travel` between worlds; the flight census builds the flight's set first | the census tests (`test_shader_warmup_sources.gd`) | 38 → 40 draws (§ "The census") |
| **A waiting spawn's secrets on a worker** (`SecretDirector.warm_pending`, `b8231a6d`): while a player's spawn waits for its terrain, a worker works out the secrets and mouse villages within 40 m (the rules' caches are locked: the generator threads fill them too); once per spawn; the director waits for it when it leaves | `tests/integration/test_secrets_warm.gd` (2) | World 41's spawn: the secret director 18.6-24.1 ms → under 0.5 ms; the spawn's worst frame 22-46 ms (CPU 21-34) → 12-13 ms (CPU 11.7-12.8) |
| **The animals' tick work one piece a frame** (`AnimalDirector.one_a_frame`, on in the sandbox, `b8231a6d`): the tick only queues its new areas and animals; each frame does one (`step`: the next animal, else the next area) | `test_animal.gd` `test_in_a_world_the_tick_s_work_comes_one_piece_a_frame` | Bench, a 3-minute flight over world 41 at 11 m/s, 60 frames a second: the director's worst frame 7.4-7.7 → 3.4-3.7 ms, frames over 4 ms 8-10 → 0 (2 runs each, load 22) |

### First sights, before and after

`--sights`, `moon-pilot,wonders-pilot` (the same seed and runs; "compiling" = a child from the menu straight into the
world meets it compiling in play: before with the census and code of `lead-merge`, now with this branch's):

| Phase | First sights | Compiling before (`lead-merge`) | Compiling now | Which (before) |
|---|---:|---:|---:|---|
| Moon, the load (behind the card) | 6 | 2 | **0** | the stars (SOON), the colony's butterflies (LATER) |
| Moon, the autopilot's play | 7 | **4** | **0** | +2.6 s the Moon Base's chest shine (SOON), +5.9 s a thought bubble (SOON), +7.4 s the portal circle's swirl (LATER), +9.2 s the Earth in the sky (SOON) |
| Moon, the 2 km flight | 1 | 0 | 0 | (a moon bunny: warm) |
| World 41, the play (run alone, the old census) | 5 | 2 | **0** | +7.8 s the portal circle's swirl, +8.0 s its stones (LATER) |
| World 41, the flight | 2-5 | 1-4 | 1 | a mouse family at 391-723 m (LATER: past the landing, ruling 4); before also the chest shine (389 m), a levers vault (766 m), the avatar by its lantern (1,100 m) |
| Back on the menu | 3 | 3 | 2 | the title diorama by its lamp (the menu draws its own: the lead's `menu_first` ruling) |

(One run of each with both worlds in one session, so world 41's rows there count only what the Moon had not shown; its
play row is from `sights-wonders`, world 41 alone with the old census, and the after run's world 41 play had no first
sight that was not warm.)

## The census

`data/shader_warmup.json`, written again (DEVELOPMENT.md §7 has the command; ~25 minutes). 38 → 40 draws:
- **New:** the rocket's two stage materials (the atlas with vertex colours, lit and unshaded; seen in the Moon trip and
  on the Moon's pad): LATER, and in the Moon's part.
- **Tiers:** the portal swirl LATER → WORLD and the portal circle's stones (instanced vertex colours) LATER → WORLD (a
  Survivor spawn); the thought bubble SOON → WORLD and the chest's shine SOON → WORLD (both on screen at a new Survivor
  world's spawn); a bot friend's badge LATER → WORLD (a CONTINUEd world whose bots came back).
- **Each world's landing beyond the first world's part:** the Moon 4 (the rocket's stages, the planet billboard, the
  stars), Mercury, Io and Europa 2, Mars, Venus, Titan, Boing and Rainbow 1 (their sky's planet), the ladder's worlds,
  world 41 and its New Seven 0. So a space world's card waits for 1-4 draws more than the first world's (one program
  each for a shader already compiled, ~5 for a new one: at most a second or two on a phone, ~0.5 s on the emulator).
- `ShaderWarmup.tier` puts what a world shows at its spawn in the WORLD tier only for Green Meadows' first world (a new
  Sandbox or Survivor world, CONTINUE); every other world's spawn is its own part now (`world_part`), drawn when its
  card comes up, so the first world's card does not wait for the Moon's or Mars's draws.

## The race in `test_world_sync.gd` (the crew-flights agent's lead)

`test_a_change_while_a_saved_chunk_is_compared_off_the_main_thread_reaches_the_guest` failed 2 of 8 runs alone here, as
the crew-flights agent saw ("a saved chunk is being compared" timed out, then `diffing()[0]` on an empty array). **The
race was in the test, not in the game:** GUT's `wait_until` asks its predicate in `_physics_process` (60 Hz), while a
comparison (`ChunkDiffer`) lives from one frame's `WorldSync._process` (started) to a later one's (collected), a few
ms at this PC's uncapped frame rate; the few saved chunks' windows were all missed about 1 run in 4. Shown: with the
physics rate at 4 the old wait failed 2 of 3 runs. The test now asks at the start of every frame (a job started in the
last frame is still in `_jobs` then: collection is in `_process`), with the physics rate at 4 during that wait: 8 of 8
(`b3749b72`). **Shared state in the off-main-thread chunk work:** `ChunkDiffer._run` writes only its own job's fields;
the main thread appends to `job.changes` and reads the rest only after `is_task_completed`; the copy goes through a
`VoxelTool` whose `copy` locks the voxel data; the generator's caches are locked (`SecretRules._mutex`,
`MouseVillages._mutex`, `MeadowsBiomeShape._mutex`, `SpaceGenerator._stack_mutex`, …) and the rest it reads is built
before the threads start (`SpaceSecretRules._landmark`, `ColonyLayout._index`, `WondersSecretRules._wonder_secrets`).
Nothing unlocked found.

**The lead's native crash (Mars, 1 start in 14: SIGSEGV, a null function pointer called from GDScript on a Voxel Tools
worker, 2 s into the world's start):** not reproduced (no emulator here) and nothing in the generators' shared state
explains it. What fits a call to address 0 from the GDScript VM on a generation thread 2 s into a world's start, while
the main thread still loads and compiles that world's scripts: a GDScript function or class used by the generator for
the first time on the worker while the main thread compiles it (Godot's GDScript cache fills a script's functions as it
compiles it). Unverified; not changed (the brief: only with a test that shows it). If it comes back: `adb shell ps -T
<pid>` for the thread names, the tombstone's backtrace, and a debug template with symbols; a cheap experiment is to
generate one chunk on the main thread in `WorldService.setup` before the terrain enters the tree (every script the
generator's common path uses is then compiled before a worker runs it).

## Rulings (what each costs if wrong)

1. **Per-world parts instead of more before the menu.** A world's card waits for its own landing's draws (1-4 beyond the
   first world's) when a warm-up is still running. Cost if wrong: a child going straight to a space world waits
   ~0.5 s longer on its card on the emulator (a phone's browser a second or two); `world_part` can be switched off by
   not calling it in `_watch_cards`.
2. **The Survivor spawn is a first world** (`survivor` in `WORLD_PHASES`): +5 draws in the first world's part (the
   portal swirl, its stones, the thought bubble, the chest's shine, a bot's badge). Cost if wrong: a first card ~1 s
   longer on the emulator, several on a phone's browser; in exchange no compile in a Survivor child's first seconds.
3. **The avatar's lantern variants everywhere** (2 draws, one program each). Cost if wrong: ~0.4 s on a phone's first
   card.
4. **The census's landings are Sandbox and Survivor worlds, standing 10 s then once round at 30 m.** A world's sights
   farther than ~80 m from its pad (a secret's chest, a mouse village) stay SOON/LATER and compile on first sight until
   the rest reaches them. Cost if wrong: one ~0.1-0.2 s frame on the emulator per such sight.
5. **`VoxelEngineUpdater` (Voxel Tools' main-thread budget, 8 ms) left as it is.** Measured: a budget of 4 ms cut world
   41's flight frames over 16 ms of CPU from 49 to 4 and its worst from 22.7 to 18.7 ms (one long task: a block's
   collision). On a phone a single task is already over 4 ms, so a lower budget saves at most ~4 ms a frame there while
   halving how fast new terrain appears when the queue is full. The lead can try `voxel/threads/main/time_budget_ms=4`
   in `project.godot` on the emulator (the flight's "no holes" check).
6. **The spawn's secrets on a worker, not on the main thread in slices.** Cost if wrong: in a slow browser the first
   tick may come before the worker is done (it then works them out itself, as before; the caches are locked, so the
   two only duplicate work).
7. **The animals: a tick's work one piece a frame.** The first animals come a tick (1 s) later than before (their areas
   are worked out in the frames after the tick that found them). Cost if wrong: a child who lands sees the nearest herd
   a second later.
8. **No web export measured.** The headless first sights give, per phase, which draws compile and whether the warm-up
   had them; `tools/web_shader_probe.py` (15-20 min of SwiftShader a run, a before and an after export) was left for the
   lead's emulator run, which is the judge anyway. Cost if wrong: no browser program counts per phase for the new worlds.

## What the lead runs on the emulator

A debug APK of the merge (DEVELOPMENT.md "Export APKs"), MEDIUM graphics as in the 13:13 runs, a quiet PC (load under
6; `uptime` with every run). Every adb call with `ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554`.
1. **The case the fix is for: straight from the menu.** `adb shell am force-stop com.giorgi.easycraft`, start the app
   (the warm-up runs once a run), and at once: triple-tap the version label (`input tap 50 1045` ×3), WORLD until THE
   MOON, AUTOPILOT BLOCKY. Then `adb logcat -d -s 'godot:*' | grep -E 'AUTOPILOT|WARMUP'`: a line
   `WARMUP world blocky (moon): <draws> draws in <ms> ms` before the play begins (the Moon's own draws behind its card;
   none when the rest had drawn them already), `AUTOPILOT result phase=play … frames_over_100ms=` and `phase=fly`.
   Expected: the play's 142.8 ms frame gone (it was a first sight: the Moon Base's chest shine or a thought bubble); the
   flight's frame gone if it was the avatar by its lantern or a sight near the landing.
2. The same for WONDERS OF THE WORLD (world 41): the play's frame (the portal circle, a first sight at ~8 s) gone; the
   flight's run at 700-900 m: fewer (the animals' tick one piece a frame, the avatar's lantern variants warm; the terrain's
   collision, `VoxelEngineUpdater`, is left: ruling 5), and a quiet PC tells how many were the load.
3. The same two after 40 s on the idle menu (the rest drawn further: the old behaviour's best case).
4. Optional, world 41's flight: `voxel/threads/main/time_budget_ms=4` under `[voxel]` in `project.godot` (ruling 5):
   fewer slow frames, and does new land still appear in time (no holes)?
5. The spawn of world 41 (the secret director's first tick, 18-24 ms here before): no hitch as the child stands.

## Tests

New: `tests/unit/test_first_sights.gd` (3), `tests/integration/test_secrets_warm.gd` (2); added to
`tests/unit/test_shader_warmup.gd` (6), `tests/integration/test_shader_warmup_spread.gd` (1),
`tests/integration/test_animal.gd` (1); `tests/integration/test_world_sync.gd`'s race case polls every frame.
The full suite (`tests/run_tests.sh`, once at the end, 2026-09-30 15:55-16:45, the PC's load 5-22): **961 scripts, 8,731
tests, 8,729 passing, 0 failing, 2 risky/pending as always**, no script error.
