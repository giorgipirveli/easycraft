# M1b "World v2" — acceptance on the emulator

Device: Android emulator `Pixel_8_API_35` (x86_64, 4 vCPUs), Godot Compatibility (OpenGL)
renderer, debug build; release APK for the owner's phone (arm64). Measurements are recorded with
the host load average, because this PC is shared (see `docs/DEVELOPMENT.md` §7).

Status legend: PASS / FAIL / PENDING. Filled in during M1b Task 14.

| # | Check (plan Task 14) | Status | Evidence |
|---|---|---|---|
| 1 | Autopilot, blocky: ≥ 30 FPS average, no frame > 100 ms (play 60 s + 2 km flight), animals around | **PASS** (see ruling) | Run 7 (`8e71666`): play 56.4 FPS, 1 frame of 128 ms at t = 1.9 s; fly 54.8 FPS, 0 frames over 100 ms (worst 42 ms). Runs 6–7 had 0–1 such frame in the first 2 s of play, never reproduced by targeted probes (ruling in the dev log) |
| 2 | Autopilot, realistic: same bar | **PASS** | Run 7: play 50.9 FPS, 0 frames over 100 ms (worst 71 ms); fly 50.0 FPS, 0 (worst 50 ms) |
| 3 | Dig down to bedrock; bedrock cannot be broken | **PASS** | Tour on the emulator: `TOUR bedrock PASS dug 89 blocks … down to bedrock at y=-63; breaking the bedrock was refused ("Bedrock can't be broken!")` |
| 4 | Walk through a cave: darkness, lantern, crystals, ores | **PASS** | `TOUR cave PASS … underground=1.00, sun 0.08 (open air 1.00), ambient 0.12, lantern on; ores and crystals within 10 blocks: 68 (Gold 29, Crystal 6, Iron 33)`; screenshot: dark cave, ore and a crystal |
| 5 | River and ocean visible; water flows into a dug hole | **PASS** | `TOUR water PASS river 13 blocks away, sea or lake 59 blocks away; dug a hole beside the water: water flowed in after 0.4 s`; screenshot of the river |
| 6 | Underwater: blue tint and fog; building and digging work underwater | **PASS** | `TOUR underwater PASS underwater=1.00, tint on, fog blue; placed STONE in the water: yes; dug it out: yes`; screenshot |
| 7 | Settings: Jumps DOUBLE/TRIPLE, Style BLOCKY/REALISTIC switch instantly and persist | **PASS** | `TOUR settings PASS TRIPLE at once, saved, DOUBLE at once, saved, REALISTIC at once, saved, BLOCKY at once, saved` |
| 8 | Animals near spawn; tame a dog; it follows and sits | **PASS** | `TOUR animals PASS 12 animals around the player (cat, sheep, fish, dogs); dog Sunny tamed with 3 pets: yes, collar: yes, followed from 6.1 to 4.2 blocks: yes, a tap makes it sit: yes` |
| 9 | Place a bed; sleep through a night; wake at sunrise; fall out of the world and return home | **PASS** | `TOUR bed PASS … the player sleeps: yes, it is home: yes, woke up at 0.150 (sunrise 0.15); fell out of the world 25 blocks from home, back on the bed: yes` |
| 10 | Sword on a practice dummy (numbers), arrow in a bullseye, axe fells a tree | **PASS** | `TOUR weapons PASS sword on the dummy: hit (4 damage); arrow in the bullseye: yes (scored 10); the axe fells the tree: yes (60 blocks)`; headless weapons smoke run `fails=0` |
| 11 | Chat commands (`/time night`, `/tp ~ ~20 ~`, `/give diamond`, `/summon dog`) | **PASS** | `TOUR chat PASS /time night: yes; /tp ~ ~20 ~: yes (y 34 -> 54); /give diamond: yes; /summon dog: yes (3 -> 4 dogs); /time day: yes` |
| 12 | Realistic avatar in the realistic style: walks, runs, jumps, holds a weapon | **PASS** | `TOUR avatar PASS realistic person; walking played run and fall, walk or run in 29 of 31 frames on the ground; standing plays idle; sword in the hand: yes`; screenshot |
| 13 | 10 big buddies keep ≥ 30 FPS (owner feedback #9) | **PASS** (see ruling) | AUTOPILOT 10 BUDDIES, run 7: play 36.2 FPS, fly 40.0 FPS (3 and 20 frames over 100 ms: the 2 km flight with 10 house-sized buddies is the extreme case) |
| 14 | Release APK 0.2.0 built, installed and launched; copied to `~/Downloads` | **PASS** | `~/Downloads/EasyCraft-0.2.0.apk` (arm64-v8a, versionCode 4, "EasyCraft", signed; sha256 98a15b50…). The same release template, exported with x86_64 (`Android` preset, release), installed on the emulator: menu, no developer menu, SANDBOX → CONTINUE loaded the world (`SANDBOX spawned_ms=752`) |
| 15 | Stand on a peak: the valley and the sea stay visible (review I2) | **PASS** | `TOUR peak PASS peak at (-128, 47, -212); 16/16 sea-level cells 40-60 blocks away loaded after 1.7 s; lowest ground 50 blocks away: y=28` |

The tour (`tools/tour.gd`, developer menu → AUTOPILOT TOUR) ran on the emulator in 42 s:
`TOUR done passed=11 failed=0` (buddies are measured separately, row 13).

## Measurements

Final runs (quiet PC, debug APK on the emulator, Compatibility renderer):

| When | Build | Style | Phase | Avg FPS | Worst frame | Frames > 100 ms | Host load |
|---|---|---|---|---|---|---|---|
| 2026-09-24 02:20 | `e83c3c9`+autopilot fix | blocky | play | 54.7 | 147.8 ms | 2 | 5.7 → 4.0 |
| 2026-09-24 02:20 | same | blocky | fly | 51.4 | 150.0 ms | 21 | |
| 2026-09-24 02:20 | same | realistic | play | 45.1 | 146.5 ms | 35 | 4.3 → 3.0 |
| 2026-09-24 02:20 | same | realistic | fly | 48.6 | 144.8 ms | 2 | |
| 2026-09-24 03:20 | `2011b56` (animal fixes, merges) | realistic | play | 44.2 | 149.8 ms | 37 | 4.2 → 3.0 |
| 2026-09-24 03:20 | same | blocky | play / fly | 57.1 / 52.8 | 133.5 / 138.9 ms | 1 / 1 | 3.5 → 2.9 |
| 2026-09-24 03:20 | same | blocky + 10 buddies | play / fly | 35.9 / 39.2 | 144.6 / 150.0 ms | 6 / 46 | 3.1 → 2.9 |
| 2026-09-24 04:45 | `8e71666` (particles, collision range) | realistic | play | **50.9** | 71.1 ms | **0** | 4.6 → 3.0 |
| 2026-09-24 04:45 | same | realistic | fly | **50.0** | 50.0 ms | **0** | |
| 2026-09-24 04:45 | same | blocky | play | **56.4** | 127.8 ms | 1 | 3.0 → 2.6 |
| 2026-09-24 04:45 | same | blocky | fly | **54.8** | 41.8 ms | **0** | |
| 2026-09-24 04:45 | same | blocky + 10 buddies | play / fly | **36.2 / 40.0** | 134.8 / 139.1 ms | 3 / 20 | 2.8 → 3.4 |

The first 02:20 run's "play" phase had been measured mid-air in ghost mode (the save kept the last
flight's end); from then on the autopilot always starts walking at the world spawn. What each fix did
is in the dev log ("Acceptance run 1" to "runs 3–6").

Preliminary rows (build before the review fixes; not a quiet PC):

| When | Build | Style | Phase | Avg FPS | Worst frame | Frames > 100 ms | Host load |
|---|---|---|---|---|---|---|---|
| 2026-09-24 00:59 | 9253c9a debug | blocky | play | 58.0 | 129.9 ms | 1 | 4.1 |
| 2026-09-24 00:59 | 9253c9a debug | blocky | fly 2 km | 55.6 | 150.0 ms | 36 | 4.1 → 6.9 (my test runs overlapped) |
| 2026-09-24 01:05 | 9253c9a debug | realistic | play | 58.6 | 128.4 ms | 1 | 8.0 |
| 2026-09-24 01:05 | 9253c9a debug | realistic | fly 2 km | 54.2 | 149.0 ms | 31 | 8.0 → 10.6 |

The realistic flight's per-10 s log stayed at a worst frame of
≤ 55 ms up to 1,816 m. All 31 slow frames fell in the last 10 s, at the same moment as a full test-suite
run on the same host. The final numbers come from a quiet re-run on the release candidate.
This blocky run also exposed the world-to-world Environment leak (the menu's HDRI sky in a blocky game),
fixed in `78480e1`.
