# M5 Task 3 — performance: APK size, the LOW preset, startup, hot paths (2026-09-25)

Brief: `docs/superpowers/briefs/prompt-m5t3.md` (spec §15.3). Cut from `m2-survive-the-night`, merged `lead-merge`
first (release 0.4.0, then `15bfae0`'s boot-splash fix) and again before the final suite (`247e2ea`: owner #52 English
only, #53 weapon numbers). All measurements are headless on this PC (i9-12950HX, 24 threads) while other agents, an
LLM server and another app's builds ran: the load average is given with each number.

## 1. APK and Play bundle size

### Measured
The lead's 181 MB was the dev APK; the release phone APK of `lead-merge` measured here (`15bfae0`, 0.4.0, the "Android
Phone" preset, debug keystore) is **193,474,218 bytes**. `python3 tools/apk_size.py <apk>` (new) breaks it down:

| Part of the phone APK | Before (MB in the APK) | After (MB) |
|---|---|---|
| Realistic block pages (20 textures, stored raw) | 111.85 | **30.94** |
| Native libraries (`libgodot_android.so` 71.1 raw, Voxel Tools 7.3 raw, libc++) | 31.78 (79.79 raw) | 31.78 |
| Audio (329 files) | 23.22 | 23.22 |
| JPEG pictures from `docs/` (the dev log's and the store's, imported) | 16.09 | **0** |
| Scripts (792 `.gdc`) | 4.20 | 4.20 |
| Other textures (sky HDR 2.1, atlases, icons) | 3.04 | 2.95 |
| `classes.dex` | 1.79 | 1.79 |
| **Whole APK** | **193.5 MB** | **96.4 MB** (96,383,896 B) |

**Why the pages were so big:** a non-Gradle Godot APK stores every `.ctex` raw (Android's no-compress list), and a
phone keeps an APK as it is. Every realistic page was two 2048² textures with mipmaps (albedo ETC2 RGBA8 and normal
ETC2 RG11: 5,592,484 B each), but most pages draw two or three of their eight rows: the rest was transparent black,
still 8 bits a pixel. The Play bundle deflates it (so its download hid it), but Play installs its APKs with the assets
raw again.

**On the phone:** the phone APK has `extractNativeLibs=true`, so Android also unpacks the 79.8 MB of native libraries
at install: about 273 MB taken before, about **176 MB** after.

**The Play bundle** ("Android Play" preset, Gradle, signed with the *debug* keystore: size only, never uploaded; the
upload key was not needed). bundletool 1.18.1 (`bundletool-all`, GitHub), an arm64 phone on Android 15 (420 dpi):

| | Before | After |
|---|---|---|
| `.aab` file | 89.9 MB | 67.7 MB |
| **Play download** | **88.8 MB** | **66.7 MB** |
| APKs Play installs on the phone | 246.5 MB | 149.2 MB |

(0.3.3's bundle was 69.8 MB: fewer pages and no store pictures then.)

### What changed
1. **Each realistic page keeps only the rows it draws** (`tools/make_realistic_atlas.save_page`, used by all ten page
   tools): the rows under the last drawn tile are cropped (the desert's twin is 2048 × 768), and a page with no
   see-through tile has no alpha (paint and the Tiny world: ETC2 RGB, 4 bits a pixel). `BlockLibrary.texture_rows` /
   `page_uv_scale` set the page materials' `uv1_scale` to (1, 8 / rows) in the realistic style: tile coordinates,
   meshes, icons and the pixel pages stay 8 × 8, and no shader or material is added. Every page tool was re-run: its
   output equals the old page cropped, **every drawn tile byte-identical** (checked pixel by pixel, RGB, alpha and
   normals; 0 drawn pixels lost), and page 0 (all 8 rows, see-through leaves and glass) is unchanged.
2. **Normal maps imported at half size** (`process/size_limit=1024` in every `*_normal.png.import`; the source PNGs keep
   every pixel).
3. **`docs/` is a `.gdignore` folder** (and its 16 `.import` files are gone): no dev-log or store picture is imported,
   so none is exported.

| Page | Rows kept | Alpha | Albedo (MB) | Normal (MB) | Before (MB) |
|---|---|---|---|---|---|
| 0 (the first atlas) | 8 | yes | 5.59 | 1.40 | 11.18 |
| 1 desert, 8 candy, 11 dragon, 13 wild meadows | 3 | yes | 2.10 | 0.52 | 11.18 each |
| 2 frost | 2 | yes | 1.40 | 0.35 | 11.18 |
| 9 smart | 4 | yes | 2.80 | 0.70 | 11.18 |
| 10 portals (row 6: the crafting table, the furnace) | 7 | yes | 4.89 | 1.22 | 11.18 |
| 12 paint, 14 Tiny world | 2 | **no** | 0.70 | 0.35 | 11.18 each |
| **All pages** | | | | | **111.8 → 30.9** |

### Both styles look the same
`tools/page_shots.gd` (new; a window) renders a wall of three blocks of every page on the emulator's 2400 × 1080 screen
at phone distance (4 m) and close (1.6 m, a block a child is about to break), in both styles, before and after:

| Style, shot | Mean \|difference\| (of 255) | Pixels changed by more than 8 | PSNR |
|---|---|---|---|
| Blocky, phone distance | 0.006 (max 3) | 0 % | 69.8 dB |
| Blocky, close ×3 | 0 | 0 % | identical |
| Realistic, phone distance | 1.1 | 3.2 % | 36.9 dB |
| Realistic, close left / middle / right | 1.6 / 3.5 / 4.8 | 4.5 / 12.2 / 16.2 % | 36.9 / 29.6 / 27.8 dB |

The realistic differences are the normal maps' finer grain (half size); the albedo is untouched. Before | after,
phone distance above and close below: `m5-task-3/m5-task-3-pages-realistic.jpg`,
`m5-task-3/m5-task-3-pages-blocky.jpg`.

### Measured and left (rulings)
- **Music:** already at a sensible Vorbis level (classical 50–63 kbps at 32 kHz, q1–q2, mono for solo piano; the loops
  q2–q3). The orchestral pieces in mono would save about 37 % each (Air 1.27 → 0.80 MB), about 3.9 MB for the ten;
  boss.ogg at 32 kHz instead of 44.1 kHz 0.12 MB. **Kept** (the audio pass chose stereo for orchestras). *Cost if
  wrong:* ~4 MB of APK and download; the switch is `"channels": 1` in `tools/make_classical_music.py`.
- **`addons/godot_mcp`** is 0.22 MB of the APK, and its autoload's scripts cost about 0.19 s of the desktop's start
  (they do nothing in a release build). **Kept:** its autoload path is what the lead's editor plugin expects; leaving
  the folder out of the export would log an autoload error at every start. *Cost if wrong:* 0.22 MB and about 0.2 s
  (desktop) of startup.
- **`libgodot_android.so` (71 MB raw, 24 MB in the APK)** needs a custom export template (scons, unused modules off) to
  shrink: out of this task's scope. *Cost:* the biggest single item left.
- **The portal page keeps its 7 rows** (the crafting table and the furnace are in row 6, outside the page's two-tiles-per-
  id rows 0–3). *Cost if wrong:* 1.75 MB.

Tests: `test_page_sizes.gd` (the rows each page draws, no empty row at the bottom, the normal maps at half size with the
same rows, no alpha on a page without see-through blocks, the uv scale per style, all pages ≤ 40 MB: 31 now),
`test_export_size.gd` (docs/ is ignored, nothing under it imported; RED with the `.gdignore` moved away and an
`.import` put back). The nine page tests check widths now (their `2048 × 2048` asserts). RED first:
`texture_rows()` missing, then every page 8 rows / 2048 wide, the desert's uv scale 1.

## 2. The LOW preset (spec §15.3)

| | LOW | MEDIUM / HIGH |
|---|---|---|
| View | ≤ 64 blocks (`GraphicsPreset.view_distance`), whatever the slider | the slider (64–192) |
| Shadows, 3D scale | none, 75 % | as before |
| Particles | half (`Fx.particle_scale` 0.5: bursts, coin showers, butterflies and bees, candy sprinkles) | all |
| Water (realistic) | no wave normals (`BlockLibrary.set_simple_water`: one uniform of the shared water material) | waves |
| Night monsters near a child | at most 6 (so never more than 6 within the 32 blocks where they are simulated) | the game's caps |
| Animals around a child | at most 12 | the game's 20 |

- **Chosen at the first start:** a phone with less than 3.5 GiB of memory or 4 cores or fewer starts on LOW, any other
  on MEDIUM (`GraphicsPreset.for_device`, `ProfileData.first_start`, called by `Profile.load_profile` when there is no
  profile yet). The child changes it in SETTINGS (LOW / MEDIUM / HIGH, as before) and that choice stays; a restored
  backup keeps this phone's own setting (M4 F).
- The host phone's preset caps its world's monsters and animals (the sandbox's `_apply_settings` calls
  `MonsterDirector` / `AnimalDirector.apply_preset`).
- No new on-screen words (owner #52: English only; nothing to translate).
- Tests: `test_low_preset.gd` (the preset table, the view cap, the device rule, a new profile and a saved choice, half
  the particles and never none, the settings setting them, the water uniform, the monster cap under Build to Survive's
  bigger one, the animal cap). The device choice was first written with MEDIUM's caps equal to the game's (10 monsters):
  the Build to Survive case failed (4 instead of 8), so MEDIUM and HIGH have no caps of their own (0).

Rulings (cost if wrong):
- 3.5 GiB / 4 cores: a "4 GB" phone with a slow chip starts on MEDIUM, a 6 GB phone with 4 big cores on LOW; the child
  can switch either way. **The emulator counts as weak:** `Pixel_8_API_35` has 4 cores (`hw.cpu.ncore=4`, 4 GB), so a
  fresh install there (or one after its data was wiped) starts on LOW; a profile already on it keeps its setting.
- LOW caps the view silently: the slider keeps the child's number (it comes back on MEDIUM). A child on LOW may wonder
  why far land doesn't show.
- The ambient particles take the scale when a world starts (a change mid-game shows in the next world).
- The host's preset decides the monster and animal caps for everyone in its world (LAN, online).

## 3. Startup

**Measured** (headless, desktop, load 13–25; the menu's new `MENU ready_ms=… main_cpu_ms=…` line, and `--verbose`
time-stamped for the parts): the menu is ready 4.5–5.9 s after the engine starts (±1.5 s between runs on this PC).

| Part (one run, load ~18) | ms |
|---|---|
| Engine start (to the first autoload) | ~300 |
| **Compiling the GDScript the autoloads reach** (`profile.gd` 1,874; `game.gd` 2,464; the MCP bridge 189) | **~4,500** |
| `main.gd` | 54 |
| `menu.gd` and what it adds | 455 |
| Autoloads' `_ready`s | 78 (Audio's sounds 53–56 of them) |
| The backdrop world, the UI, the route | 96 + 13 + 1 |

Most of the start is compiling scripts: the autoloads name the rules classes, which name each other, so starting the
game compiles about 400 scripts, 80,000 lines (a static walk: `ProfileData` alone reaches 147 scripts and 27,800 lines;
`Game` 302 / 59,700; `Session` 352 / 72,900; the menu 369 / 70,400). An exported build loads tokenised scripts, but the
parsing and analysing remain. `godot --check-only --script res://core/save/profile_data.gd` alone takes 1.6 s.

**Changed:** Audio no longer loads all ~330 takes in its `_ready` (55–75 ms; a phone reads them from the APK): a
sound's takes load the first time it plays (`Audio._takes`): Audio's `_ready` 53–56 ms → 0.1 ms. The wall-clock A/B of
the whole start (6 alternating runs each) can't show 55 ms under this PC's ±1.5 s noise. The menu prints
`MENU ready_ms=<ms since the engine started> main_cpu_ms=<the main thread's CPU so far>` once per run (logcat on the
emulator; /proc works on Android too), and `-- --startup-probe` quits after the first frame.

Ruling: **no structural change** (splitting the autoloads from the rules classes, a lazily loaded Session) this close
to release: every task's code would move. *Cost if wrong:* the start stays compile-bound; if the emulator shows more
than the spec's 5 s, that split is the lever (`docs/DEVELOPMENT.md` §7, Startup).

## 4. Hot paths with everything merged

**`tools/host_bench.gd`** (new): a new Survivor world per universe (in the wild meadows the player first goes to the
nearest village: Berrymeadow, 6 villagers), a 20 s quiet window, then 20 of the universe's monsters on a ring (levels
1–5), a dog and a cat as pets, a tamed and saddled horse ridden round a wide circle, the Gold Farm on flat ground and a
race running, 5 s to settle, then a 20 s busy window. `--max-fps 60` (a phone's rate). The reliable number is the
**main thread's own CPU per frame** (from /proc): the frame and physics wall times grow several-fold on this PC
(seconds with the same CPU but 30–60 ms frames: the main thread waits for Jolt's and the voxel threads, which the PC's
other programs starve; its own run-queue wait stayed small).

| Universe (MEDIUM) | Quiet CPU ms/frame | Busy CPU ms/frame | Monsters (hand-stepped) ms/tick | Animals ms/tick | Load |
|---|---|---|---|---|---|
| 1 wild meadows, at a village | 3.04 | 6.68 | 0.73 | 0.94 | 14–15 |
| 2 Sandstorm Desert | 2.18 | 4.76 | 1.16 | 0.57 | 17–22 |
| 3 Frostpeak | 2.06 / 2.26 / 2.08 | 9.33 / 6.57 / 4.80 | 2.33 / 0.91 / 1.21 | 1.31 / 0.89 / 0.56 | 19–27 |
| 4 Candy Kingdom | 2.07 | 6.53 | 0.29 | 1.43 | 23–25 |
| 5 Dragon Realm | 1.51 | 3.19 | 0.57 | 0.49 | 25–26 |
| 3 Frostpeak, **LOW** (6 monsters, its caps) | 1.94 | **4.22** | 0.39 | 0.68 | 20 |

The runs differ with where the ride carries the child (monsters left behind rest). Parts, desert: nothing added
1.9–2.1 ms; 20 monsters alone 4.7–5.6 (their own steps 1.8–2.7 ms a tick, their world reads 775 a second at 3 µs).

**Budget (ruling):** the host's main-thread CPU ≤ 10 ms a frame on this desktop with the whole scene, so the emulator
(this CPU) keeps ≥ 23 ms of a 30 FPS frame to draw: every universe is within it (worst 9.3 ms, Frostpeak). A real phone
is 3–5 times slower: this worst case is over budget there on MEDIUM, and LOW's caps halve it. *Cost if wrong:* a weak
phone on MEDIUM with 20 monsters round a riding child drops under 30 FPS; the lead's emulator runs are the check.

**Fixed** (an audit of every per-frame path merged tonight; `test_hot_paths.gd`, RED: each cell read twice):
- `DefenseRules.door_in_way` (a monster pressed against a wall looks for a door every tick): each cell read once (it
  read twice when not a door) and no array made per step.
- `AnimalRules.NO_SPECIES`: a shared read-only default instead of a new `{}` in every species lookup, two of them every
  physics tick per animal (the slide and glide checks).
- `CourseDirector.tick`: no player look-up (a group query) per frame per runner while no sample is due (one per 100 ms);
  a knocked-out or gone runner still stops (checked 10 times a second).
- `Hud._process`: the crosshair is set once a frame (it was hidden and shown again every frame of a bow draw).

**Measured and left:** the buddies' owner look-up (the M3 review's item, `buddy.gd` `_find_owner`): 0.62 µs a call, so
10 buddies cost 0.006 ms a frame: unchanged (0805d2b's waiting ownerless buddy kept). Fish and floating swimmers read
2–8 cells a tick (moving it to the decisions changes how they swim); flyers' per-frame looks and far animals' idle
animation (a few transform writes); a glob in flight copies its list (rare); the glide button reads up to 3 cells a
frame only while airborne with a glider.

## 5. The tutorial's first site search (the lead's emulator run, 19:35)

The lead measured the first search for Pip's playground at **20.1 s** on the emulator ("Hi! I'm Pip!" came 20 s after
the world opened; 217 ms when replayed). Here, with the game pinned to the emulator's 4 cores (`taskset -c 0-3`, a
4-thread worker pool: "4 threads, 1 max low-priority") the whole tutorial smoke passes (24 checks) and the search took
123–497 ms (on 2 cores 96 ms, on 1 core 30 ms of search), so the 20 s did not reproduce on this CPU. What differs on a
4-core phone: the pool has **one** low-priority slot, and the search was a low-priority task, so it queues behind
whatever holds that slot (Godot's threaded resource loads, e.g. the music; the world's other searches: Tilly's cart
and stand, the quest givers), each of them slowed by the chunk generation that fills the CPU while a new world streams
in. **Changed:** the search and the plan are **high-priority** tasks (any worker takes them first; the frame cost is
unchanged: planning stays on a worker, cells go in 16 a tick). The log line now says where the time went:
`TUTORIAL playground at … (497.7 ms to find, 61.7 ms of it waiting for a worker)`.
Test: `test_tutorial_pick_priority.gd` fills every low-priority slot with tasks that wait and asks for the site: RED
before (nothing found in 3 s), GREEN after. *Ruling, cost if wrong:* if the next emulator run still shows seconds, the
line tells which: waiting for a worker (the pool is full of high-priority work) or searching (the CPU starved by the
voxel threads; then the search should read fewer columns, or start once the first ring of chunks is in).

## 6. The buddies' owner look-up (the M3 review's item)

`Buddy._find_owner` looks the players group up every host physics frame: measured 0.62 µs a call (4 players, 50 other
grouped nodes), so 10 buddies cost **0.006 ms a frame**: left as it is (0805d2b's waiting ownerless buddy unchanged).

## 7. The flaky visit test

`test_visit_world.gd`'s "the island's grass stays" read air now and then under a load of 28–35: the test waited for the
visitor to stand (its own column meshed) and read the showcase's corner 12+ blocks away. A probe: at the moment the
visitor stood, the showcase was **not loaded in 3 of 6 visits** even on a calm PC. `_visit()` now waits until every
corner of the showcase's box is loaded (`WorldService.is_editable`), up to 90 s (a condition, not a time).

**Found, not mine:** `test_monster_defenses.gd`'s `test_no_monster_passes_a_closed_doorway_of_two_doors` fails when the
file runs alone (5.126 > 5.0, the same number every run, also on this branch's first commit, before any behaviour
change) and passes in the full suite: an order-dependent test, for the lead's list.

## Suites
| Commit(s) | Scripts | Tests | Result |
|---|---|---|---|
| `7c4bb88` size, `4331526` visit test | 600 | 5,663 | 5,661 passing, 2 pending, exit 0 |
| `c158d29` LOW, `541b90a` startup | 602 | 5,675 | 5,673 passing, 2 pending, exit 0 |
| hot paths, host bench, docs (after merging `lead-merge` `247e2ea`) | 610 | 5,698 | 5,696 passing, 2 pending, 0 failing, exit 0 |
| merged `lead-merge` `1f545b3` (the tutorial) | 619 | 5,790 | 5,788 passing, 2 pending, exit 0 |
| the tutorial's search, after merging `lead-merge` `cbd134c` | 621 | 5,801 | 5,799 passing, 2 pending, exit 0 |

## Commits
`7c4bb88` perf(size) pages, normal maps, docs/ · `4331526` test(visit) · `c158d29` feat(perf) LOW · `541b90a`
perf(startup) · `7b6e380` merge lead-merge (owner #52, #53) · `9b5955e` perf(hot paths) · `b45a513` tools(perf) host
bench · `36774cc` docs · `5dd9d22`, `297c5a9` merges of lead-merge (`1f545b3`, `cbd134c`) · then perf(tutorial): the
site search and plan high priority, and these notes.

## For the lead on the emulator
1. **Size:** install `build/android/EasyCraft-phone.apk` (96.4 MB); Settings → Apps → EasyCraft: about 176 MB (the APK
   and its unpacked libraries).
2. **Realistic style, every page:** a desert, a Frostpeak, a candy, a Dragon Realm and a wild-meadows world, a portal
   frame and core, a crafting table and a furnace (portal row 6), smart blocks and Game Blocks, painted blocks, a pumpkin
   and a jack-o-lantern and the cheese: every block shows its own texture (a wrong row shows another block's), close and
   at a few metres; blocky unchanged.
3. **Startup:** `adb logcat -d -s godot:* | grep MENU`: `ready_ms` under 5,000 (spec §15.3); note `main_cpu_ms`.
4. **LOW:** SETTINGS → LOW: no shadows, the view stops at 64 blocks, half the break particles, flat shiny water in the
   realistic style; a night in Survivor brings at most 6 monsters near. **A fresh install on `Pixel_8_API_35` (4 cores)
   starts on LOW**: pick MEDIUM in SETTINGS for measurements that compare with earlier ones.
5. **The autopilot** (developer menu) in every universe (1–5, the WORLD toggle) in both styles, on MEDIUM and on LOW,
   with NIGHT RUN: ≥ 30 FPS, no frame over 100 ms.
6. **Layouts:** a small-phone AVD (e.g. 1280 × 720, 5") and a tablet AVD (e.g. 2560 × 1600, 10"): the main menu, the
   HUD, SETTINGS (both pages), the palette and the shop fit, nothing under another.
7. A Play upload of the next bundle (~66.7 MB download).
8. **The tutorial:** a fresh profile, a new solo Survivor world: "Hi! I'm Pip!" within a few seconds; logcat
   `TUTORIAL playground at … (… ms to find, … ms of it waiting for a worker)` says where any delay went.
