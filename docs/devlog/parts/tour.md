# M1b Task 14 helper: the AUTOPILOT TOUR (on-device acceptance run)

The lead has to prove on the emulator that each M1b feature works in the real game
(`docs/superpowers/notes/m1b-acceptance.md`, rows 3–13 and 15). The autopilot only measures FPS.
The tour walks through the features one check after another and prints a PASS or FAIL line for
each, so the lead can read the results from logcat and grab screenshots at the right moments.
Built in an agent worktree (branch cut from `m1b-underground` at the 0.2.0 bump); no editor or
emulator use.

## What was built

- **`tools/tour.gd`** (`AcceptanceTour`), started by the sandbox like the autopilot when
  `Game.autopilot_tour` is set. It waits for the player to spawn, then 3 s, then runs 12 checks in
  order: `bedrock`, `cave`, `water`, `underwater`, `settings`, `animals`, `bed`, `weapons`, `chat`,
  `avatar`, `buddies` (skipped: measured separately), `peak`.
- **Output** (`print`, so logcat tag `godot` on Android):
  - `TOUR begin seed=<n> style=<s> renderer=<r> version=<v>`;
  - one `TOUR <name> PASS <detail>` or `TOUR <name> FAIL <detail>` per check (`SKIP` for buddies);
  - `TOUR_SHOT <name>` before each moment worth a screenshot (cave, water, underwater, animals,
    weapons, avatar, peak), then the tour holds still for 3 s;
  - `TOUR_FPS <name> avg=… worst_ms=… seconds=…` after each check (not part of the result lines);
  - `TOUR done passed=<n> failed=<m>` at the end.
  The result and shot lines are also kept in the static `AcceptanceTour.results` (for godot-mcp exec).
- **Never hangs.** Each check has a time limit (5–180 s, `CHECKS` in the script). The runner polls
  the running check every frame. When the limit passes, it prints `FAIL timeout after <n> s at: <step>`,
  naming the last step the check announced with `note()`, and starts the next check. Every wait inside a check
  goes through `frame`, `wait_seconds` or `wait_until_true`. These return false as soon as their check
  has been abandoned, so a timed-out check stops at its next wait and its late result is ignored. A
  check that dies on a script error also ends as a FAIL (`bad result`). After each check the runner
  releases the movement keys, closes a settings panel it opened, leaves first person and wakes the player.
- **`tools/tour_scout.gd`** (`TourScout`) holds pure helpers that work from the world seed alone (no
  loaded terrain needed):
  - `peak`: the highest column near the spawn;
  - `water`: the nearest water (any, sea/lake or river, of a given depth);
  - `shore`: a beach block at the waterline beside water;
  - `flat`: level, dry ground with no tree whose leaves reach over it;
  - `cave`: a dry cave spot with room for the player under a solid ceiling.

  They are unit-tested against `MeadowsShape` and `MeadowsGenerator.reference_block`.
- **`Game.autopilot_tour`** and **`Game.new_world_seed`** are both reset in `quit_to_menu`. The sandbox
  uses `new_world_seed` for a new world when it is not 0, so a run can be repeated.
- **Desktop user args:** `--tour` skips the menu, starts a new Sandbox world with the tour and quits
  with exit code 0 (all passed) or 1. `--tour-seed=<n>` fixes the world and `--tour-only=a,b` runs a
  subset of the checks. On a desktop it refuses to run without `XDG_DATA_HOME` (exit 2).
- **Developer menu:** an **AUTOPILOT TOUR** button (see "Button position").

## What each check does (all as the host, through the real systems)

"Level ground" is `TourScout.flat(spawn, 64)`: a 5×5 square at one height, dry, with no tree within
4 blocks.

| Check | How | PASS when |
|---|---|---|
| `bedrock` | Ghost mode in a shaft at spawn + (6, 0). It digs every block down with `Session.request_set_block(cell, AIR)` (the host's reach and bedrock rules), up to 4 blocks per frame, waiting for the terrain below to stream in. Then it tries to break the bedrock the same way. Finally it flies up and puts the top block back, so no later walk falls down the shaft. | Blocks were dug, the bedrock break was refused (the host's message is quoted) and the cell is still BEDROCK. |
| `cave` | `TourScout.cave` finds dry cave air (feet and head) with a ceiling, preferably at y −38…−22 where crystals grow, within 128 blocks. The player goes there the way `/tp` does (ghost). It counts ores and crystals within 10 blocks in the loaded world and turns the camera to the nearest. `TOUR_SHOT cave`. | Air is there in the loaded world, `Ambience.underground` reaches 1, sun and ambient light are below half the open-air values, the lantern is on, and at least one ore or crystal is near. |
| `water` | It reports the nearest river and sea/lake, and finds a beach block beside water (`TourScout.shore`). It hovers a block inland and digs an open hole from the top of the bank down to the waterline through `Session`. `TOUR_SHOT water`. | The loaded world has water beside the bank, and the hole fills with water (host-side `WaterFlow`) within 10 s. |
| `underwater` | It goes to the nearest water at least 3 deep (ghost, first person, so the camera is in the water too). It places STONE in the water beside the player (`TOUR_SHOT underwater`, with the stone in view) and digs it out again through `Session`. | `Ambience.underwater` reaches 1, the blue tint is on, the fog is the water fog, and both edits applied. |
| `settings` | It opens the real `SettingsPanel` and presses TRIPLE, DOUBLE, REALISTIC, BLOCKY, then the original values. | Each takes effect in the same frame (the player's max jumps; `BlockLibrary.style` and the avatar type) and is in `user://profile.json` read back from disk; the originals are restored. |
| `animals` | On level ground it waits up to 20 s for animals within 72 blocks. It calls a dog at the player's feet (`sandbox.summon_animal`, the `/summon` hook), pets it three times (`Session.request_pet` plus `cheer`, like three taps), walks 1.6 s away, waits for it, then pets it once more. `TOUR_SHOT animals`. | Animals appeared, the dog is the player's pet with a name and a collar, it came within 4.3 blocks, and the tap made it sit. |
| `bed` | On level ground it places a BED 2 blocks away with 3 free rows above it (`Session`), sets midnight with the sandbox's `set_time_of_day` hook, and asks to sleep (`Session.request_bed_sleep`, the SLEEP button's request). Then it goes 24 blocks away and drops the player to y = −70, below the world. | The player slept, the bed became home, everyone woke at sunrise, and the fall brought the player back onto the bed. |
| `weapons` | On level ground it places a practice dummy 2 blocks away and a bullseye 4–6 blocks away, at least a quarter turn from the dummy, with a clear line of flight, both facing the player (`Session.request_place_target`). It swings the sword and shoots the bow with `WeaponUser.attack_towards` (the tap path after aiming). `TOUR_SHOT weapons`. Then it fells the nearest natural tree with the axe's edits (`ToolPowers` plus `BlockInteractor.apply_edits`, as a tap with the axe does). | The dummy took a hit, the arrow scored on the bullseye, and every block of the tree is gone. |
| `chat` | It runs `/time night`, `/tp ~ ~20 ~`, `/give diamond`, `/summon dog` and `/time day` through the sandbox's `ChatCommandRunner.run` (what the chat bar calls). | Night came, the player landed 20 blocks up, a diamond is in the hand, one more dog exists, and day came back (so the later pictures are lit). |
| `avatar` | On level ground it switches to REALISTIC (as the settings do) and gives the sword. It walks 1.5 s, counting which clip plays in each frame, then turns the camera to the face. `TOUR_SHOT avatar`. The style is restored afterwards. | The avatar is a `RealisticAvatar`, the sword model is in its hand, the player moved more than 2 blocks, and walk/run played in at least 70% of the frames on the ground. Hops up 1-block steps rightly play the air pose. |
| `buddies` | Skipped: the lead measures ten big buddies with AUTOPILOT 10 BUDDIES. | — |
| `peak` | `TourScout.peak` finds the highest column within 300 blocks of the spawn. The player stands on it (`spawn_on_surface`), then the check waits for 16 cells at sea level, 40 and 60 blocks away in 8 directions. It looks down towards the lowest side. `TOUR_SHOT peak`. | All 16 cells are meshed within 60 s (review I2: the valley and the sea stay loaded). |

## How to run it

**Emulator (debug build):** triple-tap the version label in the main menu, then tap **AUTOPILOT
TOUR**. Follow the log:
```bash
export ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554
~/android-sdk/platform-tools/adb logcat -c
~/android-sdk/platform-tools/adb logcat -s 'godot:*' | grep --line-buffered TOUR
# on each "TOUR_SHOT <name>" (a 3 s hold):
~/android-sdk/platform-tools/adb exec-out screencap -p > tour_<name>.png
```
The tour starts a **new** Sandbox world in the current style (it replaces the saved Sandbox world on
the device) and returns to the main menu at the end. To run it in the realistic style, pick
REALISTIC in the settings first. The avatar check switches to REALISTIC by itself either way.

**Desktop:**
```bash
XDG_DATA_HOME=/tmp/easycraft-tour godot --path . --disable-vsync -- --tour                  # random world
XDG_DATA_HOME=/tmp/easycraft-tour godot --path . --disable-vsync -- --tour --tour-seed=12345
XDG_DATA_HOME=/tmp/easycraft-tour godot --headless --path . -- --tour --tour-only=cave,peak
```
Without `XDG_DATA_HOME` it refuses (`TOUR refused: …`, exit 2), because the shared user folder holds
every worktree's and the developer's own Sandbox world. Exit code 0 means every check passed.

## Button position

The developer panel has no room for another row. Measured headless on a 2400×1080 window
(logical 1600×720): the panel runs from y 207 to 1066, and AUTOPILOT 10 BUDDIES is at y 904–1024. A
row below it would recentre the panel and move every button the lead taps. So **AUTOPILOT TOUR sits
right of AUTOPILOT 10 BUDDIES, in the same row**. An empty twin on its left keeps 10 BUDDIES and every
row centred. The row keeps its height, so no button moves. `tests/integration/test_dev_menu.gd` proves
this: it hides the tour button and its twin, and every other button keeps its exact screen rectangle.

- Headless layout at 2400×1080: BLOCKY centre (918, 814), REALISTIC (1482, 814),
  10 BUDDIES (1200, 964.5), **AUTOPILOT TOUR (1809, 964.5)**, size 540×120 px.
- The lead taps BLOCKY and REALISTIC at y 891 on the emulator, while this headless layout has them at
  y 814 (the lead's x values fall inside the same buttons here). So the emulator's panel sits about 77 px lower. There the tour button
  is at **x 1809, the same height as 10 BUDDIES** (about y 1041 if the offset holds). Please confirm
  with one screenshot of the developer menu.

## Tests (TDD; RED first each time)

- `tests/unit/test_tour_scout.gd` (13): peak (the brute-force maximum in a small area, within the
  radius, at least every coarse sample), water (depth, rivers only, none on the dry spawn column),
  shore (4-neighbours, solid block at the waterline, water beside it, checked with `reference_block`),
  flat (level, dry, no tree within 4 blocks; found for several seeds; never in deep sea), cave (dry
  air at feet and head, in range, a ceiling; none above the ground).
  RED: `Identifier "TourScout" not declared`, then "Cannot infer the type" (`flat` missing), then
  `no tree at -1,4` (leaves reaching over the level ground).
- `tests/integration/test_acceptance_tour.gd` (7), the runner with fake checks:
  - one line per check, then the summary; a SKIP is not counted;
  - a check that never ends times out and the next one runs;
  - the timeout names the last step;
  - an abandoned check's waits return false at once and its late PASS is ignored;
  - `wait_until_true` reports the condition;
  - a shot prints `TOUR_SHOT` and holds for `shot_hold`.

  RED: `Identifier "AcceptanceTour" not declared`.
- `tests/integration/test_dev_menu.gd` (5), at 2400×1080:
  - the tour button moves no other button;
  - the lead's x taps are still inside BLOCKY and REALISTIC;
  - the tour button is on screen, right of 10 BUDDIES in its row, and covers nothing;
  - it is wired.

  RED: `AUTOPILOT TOUR button` null.

Full suite: 513 before, **538 after**, all passing (`tests/run_tests.sh`).

## Desktop results

Seed 12345, blocky, windowed with `--disable-vsync`, host load 8–13:
```
TOUR begin seed=12345 style=blocky renderer=mobile version=0.2.0
TOUR bedrock PASS dug 89 blocks at x=36 z=12 from y=27 down to bedrock at y=-62 in 0.9 s; breaking the bedrock was refused ("Bedrock can't be broken!"), it is Bedrock; shaft closed again: yes
TOUR cave PASS cave at (32, -28, 20), 8 blocks from the spawn (air): underground=1.00, sun 0.08 (open air 1.00), ambient 0.12 (open air 0.65), lantern on; ores and crystals within 10 blocks: 47 { "Gold": 28, "Crystal": 4, "Iron": 9, "Diamond": 6 }
TOUR water PASS river 8 blocks away at (30, 4), sea or lake 119 blocks away at (-54, 96); dug a hole at (30, 23, 5) beside the water at (30, 23, 4) (river): water flowed in after 0.1 s
TOUR underwater PASS 3 deep at (26, 21, 0): underwater=1.00, tint on, fog blue (ends at 22); placed STONE in the water at (25, 21, 0): yes; dug it out: yes (water flowed back: yes)
TOUR settings PASS TRIPLE at once, saved, DOUBLE at once, saved, REALISTIC at once, saved, BLOCKY at once, saved; restored 3 jumps and blocky style: yes
TOUR animals PASS 12 animals around the player { "fish": 6, "cow": 3, "pig": 3 }; dog Sunny tamed with 3 pets: yes ("Sunny is your pet now! Tap Sunny to make it sit."), collar: yes, followed from 5.5 to 4.3 blocks: yes, a tap makes it sit: yes
TOUR bed PASS bed at (48, 40, 38); at night (0.00) the player sleeps: yes, it is home: yes, woke up: yes at 0.150 (sunrise 0.15): yes; fell out of the world 26 blocks from home, back on the bed: yes (at (48.5, 41.0, 38.5))
TOUR weapons PASS sword on the dummy: hit (4 damage); arrow in the bullseye: yes (scored 10); the axe fells the tree at (44, 41, 45): yes (55 blocks)
TOUR chat PASS /time night: yes (0.930); /tp ~ ~20 ~: yes (y 40.0 -> 60.0); /give diamond: yes; /summon dog: yes (1 -> 2 dogs); /time day: yes
TOUR avatar PASS realistic person (skin 0); walking 8.6 blocks played { "run": 114 }, walk or run in 114 of 114 frames on the ground; standing plays "idle"; sword in the hand: yes (held_item 110, hand holds ["Node3D(item 110, visible true)"])
TOUR buddies SKIP measured separately (developer menu: AUTOPILOT 10 BUDDIES)
TOUR peak PASS peak at (190, 52, 144), 207 blocks from the spawn; standing at y=52.0; 16/16 sea-level cells 40-60 blocks away loaded after 3.7 s; lowest ground 50 blocks away: y=40
TOUR done passed=11 failed=0
```
(The `TOUR_SHOT` and `TOUR_FPS` lines are left out here.) Per-check average FPS in that run was 45–111,
not counting the two checks that last 0.1 s.

Other worlds, after the fixes below: seeds 1, 5, 7, 42, 64, 99, 123, 777, 1000, 2026, 4242, 31337
and 90210 headless, and seed 777 windowed in the REALISTIC style (profile restored to realistic and
2 jumps afterwards). All of them ended with `passed=11 failed=0`.

## What the runs found and what changed

| Run | Found | Change |
|---|---|---|
| First windowed run | 2–4 FPS for the whole run (for example 23 s to dig what took 1.4 s headless), at host load 16–19 | `--disable-vsync` for desktop runs (DEVELOPMENT.md §8), and `TOUR_FPS` lines so slow frames explain timeouts on the emulator too |
| Seed 12345 | The animals walk fell into the bedrock shaft 3 blocks from the spawn; bed, weapons and avatar then ran 88 blocks down | The shaft moved to spawn + 6, and the check closes it again after testing the bedrock |
| Seed 12345 | Reading the sword model 0.3 s after the style switch: the switch makes one long frame, and `Player._process` runs before its child `WeaponUser` sets `held_item` | Wait for the condition (up to 2 s), not a fixed time |
| Seed 12345 | Walking over uneven ground plays the air pose while the player is off the ground (auto-step hops, small drops) | Judge only the frames on the ground (walk/run in at least 70%) |
| Seed 12345 | A summoned dog vanished before it could be tamed | Animals, bed, weapons and avatar run on level ground (`TourScout.flat`) |
| Seeds 1, 42, 777 | The bullseye's fixed spot 5 blocks away was on a slope | Search 16 directions and 4–6 blocks with a clear line of flight, away from the dummy and the bed |
| Seed 777 | After falling out of the world the player came back 3 blocks above the bed | Level ground keeps trees' leaves 2 blocks away; the bed spot needs 3 free rows above |
| Seed 99 | Fog colour read at underwater 0.99, not quite the water fog | Wait for 1.0 and compare the colour with a 0.03 tolerance |

## Game issues found (not fixed here; for the lead)

1. **A `/summon`ed animal can fall through the world on uneven ground.** `sandbox.summon_animal` puts
   it within ±1.5 blocks of the player, half a block above the player's feet, without looking at the
   ground there. The likely result: beside a 1-block rise it starts inside the block and falls through
   the terrain, and a wild animal is removed below y −64, so it just disappears (a pet would teleport
   back). It happened in 2 of the windowed runs on seed 12345, before the tour moved to level ground:
   the dog could not be tamed (out of reach at once) and was then freed. In one of them the dog was
   called at the player's feet, exactly as `/summon dog` does. A fix would place it on the standing
   spot of its column (`world.find_standing_y`), test-first in `AnimalRules` or the sandbox hook.
2. **Going home to a bed under a low ceiling puts the player on top of the ceiling.** When leaves (or
   a roof) are two blocks above the bed, `Player.go_home` spawns at `BedRules.home_position(bed)`
   (bed + 1) and `_unstuck` lifts the player above the canopy, 3 blocks up (seed 777, bed at
   (−9, 41, 35) under an oak). Waking already handles this (`BedRules.wake_position`); going home
   could use the same rule.

## Rulings (decisions made on the owner's behalf, with the cost if wrong)

1. **One TOUR button, not one per style.** The tour runs in the current style, and the avatar check
   switches to REALISTIC itself and restores the style. Cost if wrong: a run fully in REALISTIC needs
   the style picked in the settings first (one extra tap), or a second button later (a few lines).
2. **The tour starts a new world** (the task asked for it). That replaces the emulator's saved Sandbox
   world each time. Cost: the emulator's test world is lost; any world to keep must be copied first.
3. **The button sits right of 10 BUDDIES, not below it.** There is no room below without moving the
   buttons the lead taps (see "Button position"). Cost: the lead has to look one button to the right;
   if the emulator's layout is lower than the desktop's, the button's lower edge may be cut off by the
   screen, but its centre stays tappable at the height of 10 BUDDIES.
4. **Host requests instead of simulated screen taps.** The checks call the same requests a tap ends in
   (`Session.request_set_block`, `request_pet`, `request_bed_sleep`, `request_place_target`,
   `WeaponUser.attack_towards`, `ChatCommandRunner.run`). The touch-picking step (ray from the screen
   point) is not exercised. Cost: a bug only in touch picking would not show in the tour; the
   `BlockInteractor` tests and the lead's own taps cover it.
5. **Teleports, not long walks.** The tour moves the way `/tp` and `/spawn` do (`spawn_at` and
   `spawn_on_surface`), in ghost mode for caves and water, and walks only for the pet and the avatar.
   Cost: walking into a cave or down to a river is not part of the proof.
6. **Water passes when any water near the spawn takes the flow.** Rivers and sea/lake distances are
   reported, but an ocean within 400 blocks is not required (continents can be wider than that).
   Cost: "ocean visible" must be judged from the detail line or a screenshot on a world that has one.
7. **The peak check samples 16 cells at sea level, 40 and 60 blocks away in 8 directions**, all of which
   must be meshed within 60 s. Cost: a hole in the view beyond 60 blocks would not be caught.
8. **Level ground is found from the generator rules** (5×5 at one height, no tree within 4 blocks,
   within 64 blocks of the spawn; the spawn itself if there is none). Cost: a player's edits or
   animals there are not considered (a fresh world has no edits).
9. **The buddies check prints SKIP and is not counted** in `passed`/`failed`, as the task allows.
10. **Desktop `--tour` refuses without `XDG_DATA_HOME`,** like the weapons smoke run. Cost: one more
    variable to type; editor or godot-mcp runs (`Game.autopilot_tour = true; Game.start_sandbox(true)`)
    are not guarded.
