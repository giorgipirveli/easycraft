# EasyCraft — developer guide

Everything needed to work on this project without the chat history. Keep it current: when a
command, path, convention or gotcha changes, update this file in the same commit.

## 1. What the game is

**EasyCraft** (the owner's name for the game; `config/name` in `project.godot`) is a 3D, landscape-only
mobile sandbox and survival game for children, in the spirit of Minecraft and Roblox. The player
chooses **Sandbox** (unlimited everything, build anything) or **Survivor** (earn gold, hide from or
fight monsters, climb a ladder of universes). Its own features are **living buddies** (the Magic Wand
brings builds to life), **Size Magic** (tiny/giant), **stamps** and **Mirror** building. Android is
built and tested on this PC; iOS will be built later on the owner's Mac. It will be public on the app
stores for all ages (with an age check), free at launch.

| What | Where |
|---|---|
| Full design spec (decisions, systems, roadmap M1–M5) | `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` |
| Implementation plans (M1 done, M1b done — 15 tasks) | `docs/superpowers/plans/` |
| Notes: Voxel Tools spike, M1 and M1b acceptance | `docs/superpowers/notes/` |
| Owner testing feedback, status and proof of every fix | `docs/playtests/owner-feedback.md` |
| Child playtest template | `docs/playtests/m1-template.md` |
| Dev log (chronological decisions, measurements, progress) | `docs/devlog/` |
| Asset credits (CC0 only) | `assets/CREDITS.md` |
| Third-party code and licences | `THIRD_PARTY_NOTICES.md` |
| Online backend (Nakama, M4; early spike done) | `server/`, see `server/README.md` and `docs/devlog/parts/m4-online-spike.md` |
| Play G0: the foundation every game stands on (DISCOVER, the play arena, the voice and rule 0, the demonstration, `SkillShown` to the record, the reading debt, the `play` block; owner #122, #133, #134, spec §22.0) | `core/play/`, `entities/play/`, `ui/play/`, `data/play/`; `docs/devlog/parts/play-g0.md`; tools `play_audit.py`, `play_debt.gd`, `play_smoke.gd`, `play_shots.gd` |
| Life: the Life tab, the Experiences and their practice rooms, the Passport, Life Town; safe mistakes (owner #112, #118, spec §27) | `core/life/`, `entities/life/`, `ui/life/`, `data/life/`; `docs/devlog/parts/life-l1.md`, `life-l2.md`, `life-l3a.md`, `life-l3b.md` |
| Tools: the ten motions, the device run, the Tool Book, Real Builder (owner #116, #117, spec §27.3) | `core/tools/`, `entities/tools/`, `ui/tools/`, `data/tools/`; `docs/devlog/parts/tools-r4b.md` |
| Success S2: the Goal Board and the habit garden, Talk & Deal, the Connections Book, Success Stories (owner #115, spec §27.4) | `core/success/`, `entities/success/`, `ui/success/`, `data/success/`; `docs/devlog/parts/success-s2.md` |
| Success S3: My Business's shop and the Market Square (MY SHOP, THE PRICE BOARD, the second plaza beside Life Town; owner #115, spec §27.8) | the same folders; `docs/devlog/parts/success-s3.md` |
| Play W1: learning inside the world (DISCOVER in MORE and the pause menu, Professor Hoot's invitation, the discovery crystals, the Discovery Academy; owner #132, #133, #134) | `core/discovery/`, `entities/discovery/`, `ui/discovery/`; `docs/devlog/parts/play-w1.md` |
| Friends apart: gifts, showcase visits, bottles, playdates (M4 Wave 3, agent I) | `core/gifts/`, `ui/gifts/`, `world/visit/`; `docs/devlog/parts/m4-i.md` |
| The online server on the internet (owner's VPS, M4 D) | `docs/hosting.md` (owner's guide), kit `server/deploy/` (`kit.sh`) |
| Agent guide | `CLAUDE.md` |

Branches: `main` (scaffold), `m1-first-steps` (M1, complete, **not merged**), `m1b-underground`
(M1b, current work, branched from `m1-first-steps`). There is no remote. Nothing is merged or pushed
until the owner says so.

## 2. Toolchain on this PC

The dev machine is Ubuntu 26.04 (KDE/Wayland) with an i9-12950HX (24 cores), 30 GB RAM and an Intel
iGPU only.

| Tool | Location / version |
|---|---|
| Godot 4.7.2 (editor + headless) | `~/.local/opt/godot/Godot_v4.7.2-stable_linux.x86_64`, symlink `~/.local/bin/godot` |
| Export templates | `~/.local/share/godot/export_templates/4.7.2.stable/` |
| Editor settings | `~/.config/godot/editor_settings-4.7.tres` (Android SDK, JDK and debug keystore paths are set there) |
| JDK 17 (Temurin) | `~/.local/jdk17` |
| Android SDK | `~/android-sdk` (`platform-tools/adb`, `emulator/emulator`, build-tools, NDK) |
| Debug keystore | `~/.local/share/godot/keystores/debug.keystore` (alias `androiddebugkey`, password `android`) |
| Emulator AVD | `Pixel_8_API_35` (Android 15, x86_64, Play image) |
| Screen mirroring of a real phone | `scrcpy` |
| Voxel engine | Voxel Tools 1.7 GDExtension (Zylann), `addons/zylann.voxel/` |
| Tests | GUT 9.7.1, `addons/gut/` |
| Online backend (M4) | Docker 29 + Compose v2: Nakama 3.41.0 + PostgreSQL 16.8, compose project `easycraft` (`server/`, see `server/README.md`); Node 24 / npm 12 for the TypeScript module |
| Nakama client | nakama-godot (Heroic Labs, Apache-2.0) at a pinned commit, `addons/com.heroiclabs.nakama/` (`tools/fetch_nakama_godot.sh`), no autoload |
| Editor bridge for Claude | godot-mcp `@satelliteoflove/godot-mcp@4.1.11` (pinned in `.mcp.json`); the addon in `addons/godot_mcp/` must be the same version; it listens on port 6550 |
| Claude skills | GodotPrompter plugin (`godot-prompter@skillsmith`), superpowers |

godot-mcp needs the editor open: `godot -e --path ~/Documents/game`. If Claude started first, the
bridge reconnects within about 10 s. Before driving the editor, check that godot-mcp `get_info` reports
the path `/home/giorgi/Documents/game/`, because another project may be open.

### Machine gotchas
- `cargo` is broken on this machine. Install Rust tools with `apt` or prebuilt binaries.
- Installers that self-elevate fail without a tty. `sudo` is passwordless and works directly.

## 3. Android emulator etiquette (another app is built in parallel)

Another app is developed on this PC at the same time. It uses AVD `Parkingi_API_35` (usually
`emulator-5556`) and a different adb (`/usr/lib/android-sdk`).

- On **every** adb call for this game, use a private adb server and our emulator:
  `ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554 ~/android-sdk/platform-tools/adb …`
  Two adb versions sharing the default server port kill each other's server; the private port avoids that.
- Never touch `emulator-5556`, `Parkingi_API_35` or that app's packages.
- `~/.android/advancedFeatures.ini` has `Vulkan = off`. With emulator Vulkan on, Godot's Vulkan output
  was a black screen on this Intel iGPU. With it off, Godot falls back to OpenGL (Compatibility), so
  the emulator shows Compatibility-renderer visuals, while real phones use Vulkan (Mobile renderer).
  **This file is global to all emulators on the PC**, including the other app's.
- Start: `~/android-sdk/emulator/emulator -avd Pixel_8_API_35 -no-boot-anim -no-snapshot -port 5554` (with
  `ANDROID_ADB_SERVER_PORT=5038`; from the Bash tool as a background task, not `nohup … &`, which the tool's shell
  takes down). Since 2026-09-28 loading the AVD's quick-boot snapshot makes qemu crash (SIGSEGV right after "Successfully
  loaded snapshot", even a snapshot saved by a clean `adb emu kill`): `-no-snapshot` cold-boots (about a minute) and saves
  none. Shut it down with `adb emu kill` when idle (it holds ~1.5 cores and 4.7 GB).
- A Godot app launched within seconds of a cold boot can die ("surface abandoned"). Relaunch it once
  the emulator has settled.
- Test on the emulator, not on the owner's phone (the owner's instruction).

## 4. Everyday commands

All commands run from the project root.

### Tests
```bash
tests/run_tests.sh
```
Runs every GUT test in `tests/unit` and `tests/integration` headless (`tests/run_tests.sh -gtest=res://tests/unit/a.gd,res://…/b.gd`
runs only those files: before owner #39 it ran the whole suite as well, without the slot gate). A full run waits for one of
3 PC-wide slots (`tests/suite_slots.sh`: flock on `/tmp/easycraft-suite-slots/slot1..3`). When the PC is overloaded
(2026-09-25 17:29: load 171 and 1 GB free, mostly the other app's native build), the lead lowers the cap for every
agent at once by holding slots itself: `flock /tmp/easycraft-suite-slots/slot2 flock /tmp/easycraft-suite-slots/slot3
sleep 3600` (in the background; `lsof -t /tmp/easycraft-suite-slots/slot*` shows the holders). GUT silently skips test
scripts that fail to parse and still exits 0, so the runner also **fails the run on any
`SCRIPT ERROR` or `Parse Error`** in the output. Save long output to a file and read the tail:
`tests/run_tests.sh > /tmp/…/t.log 2>&1; grep -E 'Passing Tests|Failing Tests' /tmp/…/t.log`.

### Every smoke run at once (the acceptance's end-to-end part)
```bash
tools/smoke_all.sh              # every tools/*_smoke.gd, one after another
tools/smoke_all.sh farm quest   # only these (names without _smoke.gd)
```
Each run gets a fresh folder under `/tmp/easycraft-smoke-all/<name>-smoke` (the path holds "smoke", as every smoke
run requires) with a copy of this PC's `profile.json`, a 600 s limit (`SMOKE_ALL_LIMIT`) and `nice`; the whole
batch holds one PC-wide suite slot. It prints `SMOKE <name> PASS|FAIL|TIMEOUT <seconds> [log]` and
`SMOKE_ALL passed=<n> failed=<m>`, and exits 0 when all passed; a run with `SCRIPT ERROR` / `Parse Error` counts as
failed. The logs stay in the folder (`SMOKE_ALL_DIR`). It clears that folder first: never run two at once with the
same folder (give an extra run its own `SMOKE_ALL_DIR=/tmp/easycraft-smoke-x`).

On a busy PC (load average around 35) the full suite took more than 10 minutes. Agents with a
command time limit should run it in the background and wait for it.

Integration tests that write files use **per-process `user://` folders**. Parallel suites (for
example agents in other git worktrees) share one user-data folder,
`~/.local/share/godot/app_userdata/EasyCraft`, and used to collide ("disk I/O error"). Keep new
file-writing tests per-process too.

A **new `class_name` script** is not known to headless runs until the global class cache is updated.
Rescan in the open editor (godot-mcp `godot_editor_edit rescan`), or run `godot --headless --path . --import`
while the editor is closed. Otherwise you get "Identifier not declared" or "Could not find type" errors.

### Block texture atlas
```bash
godot --headless --path . --script res://tools/make_atlas.gd
godot --headless --path . --import      # or rescan in the editor
```
This regenerates `data/blocks/atlas.png` (8×8 tiles of 16 px, RNG seed 20260923). **Append new tiles at
the end of `_init`.** The RNG sequence then stays the same for existing tiles, so they stay byte-identical.
Tile coordinates must match `TILES` in `world/block_library.gd` and item icons in `ui/hud/block_icons.gd`.
Import settings: lossless, mipmaps on, detect-3D off.
**Redrawing an existing tile** (owner #43's grass side and ores): leave its old drawing call where it is (the RNG
stays in step for every later tile) and draw over it at the end of `_init` with its own RNG (`_identity_pass`). A
page tool that draws a block's tiles with a shared RNG can skip the old draws instead (`make_portal_page.gd`'s
`_crafting_tiles` burns the old table's 560 draws so the planks after it stay the same). Check a regenerated page
tile by tile against the old file before committing.

### Brand pictures and the boot splash (owner feedback #43, spec §3c)
```bash
python3 tools/make_brand_art.py          # needs Pillow + numpy; our own drawing, no font file, no randomness
godot --headless --path . --import       # or rescan in the editor
```
It writes the launcher icon `icon.png` (the buddy mark on teal `#139e9b`, full bleed, the buddy inside the adaptive
icon's safe zone), the store icon `docs/store/graphics/next/icon-512.png` (a `.gdignore` folder: never in the APK),
the boot splash `assets/brand/splash.png` and the menu's wordmark `assets/brand/wordmark.png` (twice its shown
size). The splash is `application/boot_splash/image` in `project.godot` (teal `bg_color`, `stretch_mode` 0: drawn at
its own size) and is imported **"keep"** (`splash.png.import`): Godot packs the boot splash raw, so an imported copy
would only add size. `tests/unit/test_boot_splash.gd` checks it is ours, small, packed by every preset.
**Names**: no other block game's name, creature or place in the store drafts, release notes, public pages, game
strings or data (`tests/unit/test_identity_words.gd`; the words list lives only in that test).

### Item icon atlas (M2 Task 6)
```bash
godot --headless --path . --script res://tools/make_item_icons.gd
godot --headless --path . --import      # or rescan in the editor
```
This regenerates `data/items/item_icons.png` (8×8 tiles of 16 px, no RNG). It is **imported as an Image**
(`importer="image"` in `item_icons.png.import`), so `BlockIcons` can read its pixels on every renderer.
- Rows: 0–3 Task 6 (row 0: one picture per tiered kind — sword, bow, pickaxe, axe, spear, mace, shield;
  row 1: potions), 4 Task 16 (secrets), 5 Task 15 (bots), 6–7 free. Tile coordinates must match
  `KIND_TILES` / `POTION_TILES` in `ui/hud/block_icons.gd`.
- A kind's **metal is drawn in pure greys** (r = g = b): `BlockIcons.tier_image` tints exactly those pixels
  in the tier's rarity colour, adds a rarity rim and 1–5 white pips (top-left; keep the band x < 13, y < 3
  empty), at 32 px. Every other colour stays as drawn.
- The blasters' and their ammo's icons (M3 Task 14b) are not in this atlas: `BlasterIcons` draws them in code
  (16 px pictures as text rows) and frames them the same way (rarity rim, 32 px, 1–5 pips).

### Realistic textures, sky and sounds
```bash
python3 tools/make_realistic_atlas.py    # needs Pillow + numpy; downloads CC0 ambientCG materials
python3 tools/make_animal_sounds.py      # synthesises the fish's animal_blub.wav (the other voices are real recordings now)
python3 tools/make_water_sfx.py          # synthesises splash_*, swim_*, bubbles, step_wet_*.wav (original work)
python3 tools/make_photo_sfx.py          # synthesises assets/audio/sfx/shutter.wav (photo mode; original work)
python3 tools/make_monster_sounds.py     # monster_squish/growl/pop/poof.wav (M2 Task 4)
python3 tools/make_bot_skins.py          # bot friends' REALISTIC skins: the Kenney skins with dyed shirts (M2 Task 15)
python3 tools/make_avatar_masks.py [--preview <dir>]   # realistic avatar region masks (M3 Task 9)
python3 tools/make_boss_sounds.py        # golem_roar/slam/throw/stomp/crumble, rock_crash, portal_wind (M2 Task 10)
python3 tools/make_defense_sfx.py        # door_open, door_close, spikes.wav (M2 Task 8; original work)
python3 tools/make_portal_sfx.py         # portal_whoosh.wav (M3 Task 5; original work)
python3 tools/make_blaster_sfx.py        # foam_pop, paint_shot, bubble_shot/pop, rocket_whoosh, confetti_boom, party_horn, pinata_burst (M3 Task 14b)
```
- `make_avatar_masks.py` writes `assets/characters/avatar_masks/<skin>_regions.png` (per-pixel skin,
  hair, shirt and pants weights for the recolour shader) and prints the reference brightness values
  that go into `AvatarSkin.REFERENCES`. `--preview` writes recoloured textures to check by eye. Import
  settings: lossless, mipmaps on, detect-3D off and **`process/fix_alpha_border=false`** (alpha is data).
- `make_realistic_atlas.py` builds `data/blocks/realistic_albedo.png` and `realistic_normal.png`,
  2048² in the same 8×8 layout as the pixel atlas. Each 256 px tile is a 240 px texture plus an 8 px
  continuation border, so mipmaps never bleed. It also builds `water_waves.png`.
- The downloads are cached in `~/.cache/easycraft-textures`. The ambientCG site needs a browser
  User-Agent (the script uses curl with one).
- Import settings for these textures: VRAM-compressed, mipmaps on, normal maps flagged as normal
  maps. When the script adds tiles, keep them in the same coordinates as the pixel atlas.
- **How a realistic page is written (M5 Task 3, the APK size pass):** every page tool (`make_realistic_atlas.py`, the
  universes' `make_*_realistic.py`, `make_{paint,portal,smart,tiny}_page.py`) saves through
  `make_realistic_atlas.save_page`: the rows under the page's last drawn tile are cropped off (the desert's twin is
  2048 × 768), and a page with no see-through tile is written without alpha (paint, Tiny world: ETC2 RGB, half the
  size). `BlockLibrary.texture_rows` / `page_uv_scale` stretch the 8 × 8 page's UVs over the rows a texture keeps
  (`uv1_scale` on the page's shared materials): tile coordinates, meshes and the pixel pages stay 8 × 8. Every
  `*_normal.png.import` has `process/size_limit=1024` (the normal maps are imported at half size; the source keeps
  every pixel). A new tile in a later row grows its page by itself. `tests/unit/test_page_sizes.gd` checks the rows,
  the alpha, the uv scale and a 72 MB budget for all the pages' textures (71.5 MB with the Glow Caves' page 45, three
  rows with alpha, `glow-caves.md`; before it 70 MB; about 63.8 MB with the New Seven's pages 36-37,
  Venus's page 38, space's riches' page 39, Saturn's rings' page 40, Pluto's page 41 and Triton's page 42; 66.8 MB once
  the natural wonders' rows 1-3 made page 37 four rows with alpha, `wonders-nature.md`; 68.3 MB with Ganymede's page
  43, `cosmos-ganymede.md`; a page of three rows without alpha adds ~1.6 MB: room for one more; the budget was 40 MB
  until Mercury's, `docs/devlog/parts/cosmos-mercury.md`, 48 until the ancient wonders', `wonders-ancient.md`, 54 until
  the New Seven's and Venus's, `wonders-new-seven.md`, `cosmos-venus.md`, 60 until the rings', `cosmos-rings.md`, 64
  until Triton's, `cosmos-triton.md`).
- **Pictures of the pages** before and after a texture change, both styles, close and at phone distance (a window):
  `godot --path . --disable-vsync --resolution 960x432 --script res://tools/page_shots.gd -- --out=<dir> --tag=after`.
- The HDRI sky is `assets/sky/*.hdr` (Poly Haven, CC0, 1K). Credits are in `assets/CREDITS.md`.
- **In the browser these files come later** (the realistic pack, §5 "Realistic pictures that come later"): keep a new
  page's twins named `data/blocks/pages/<page>_albedo.png` / `_normal.png` and a realistic-only sky an `.hdr` in
  `assets/sky/`, and never use them in BLOCKY (`test_realistic_pack.gd` checks the patterns catch nothing else).

### Music and feel sounds (M2 Task 11)
```bash
python3 tools/make_music.py      # needs numpy + ffmpeg with libvorbis; downloads CC0 tracks (cynicmusic)
python3 tools/make_feel_sfx.py   # synthesises assets/audio/sfx/coin.wav (original work)
```
- `make_music.py` builds `assets/music/day.ogg`, `night.ogg` and `boss.ogg`. It cuts each source at a bar
  line (tempo and bar count are in its `TRACKS` table), mixes the reverb tail back onto the start, evens
  out the loudness and encodes stereo Vorbis. It prints the loop length, the size and a seam check for
  each track. The downloads are cached in `~/.cache/easycraft-music`.
- The music `.import` files have `loop=true`. Keep each track at 1.5 MB or less (`test_music.gd`).

### The audio pass: effects, animal voices, ambience and classical music (owner feedback #27, #31)
```bash
python3 tools/make_audio_pass_sfx.py [effects|animals|monsters|ambience|pack]   # needs numpy, scipy, ffmpeg (libvorbis); pack: owner #41
python3 tools/make_classical_music.py [piece ids]                         # needs numpy, ffmpeg (libvorbis)
godot --headless --path . --script res://tools/measure_audio.gd           # load times and folder sizes
```
- `make_audio_pass_sfx.py` writes mono Ogg Vorbis (32 kHz) into `assets/audio/sfx/` and the seamless
  ambience loops into `assets/audio/ambience/`: footsteps by block, the toggle click, the hotbar tick, the
  pickup pop, the gold clink and the jingles (Kenney packs, CC0), the **animal voices** (real CC0 recordings
  from freesound.org: the tool checks that each page still says CC0 before it downloads the page's HQ
  preview, then trims, cuts single calls out of longer takes and levels them), the monster voices and the
  wave horn (synthesised) and the wind loop (synthesised). Each part has its own RNG seed, so running one
  part alone gives the same files. Downloads are cached in `~/.cache/easycraft-sounds`.
- `make_classical_music.py` downloads each piece from Wikimedia Commons (public-domain or CC0 recordings;
  the table in the script names the file, the performer and the licence template read on its page), cuts a
  1.5–3 minute excerpt that ends at the quietest moment of its last third with a 3 s fade, evens out the
  loudness and encodes Ogg Vorbis at 32 kHz (mono for solo piano, stereo for orchestras). Eine kleine
  Nachtmusik is our own rendering of the public-domain Mutopia score (a small numpy synthesiser in the
  script: music box, marimbas, plucked bass, a soft room). Cached in `~/.cache/easycraft-music/classical`.
- **How many animal calls a child hears** (owner #50): `tools/animal_voices_measure.gd` starts a new
  Sandbox world by day and counts every `Audio` play by name for `--seconds`, with the idle calls' kinds,
  distances and levels, standing at the spawn, walking (`--walk`), at the busiest place of the world
  (`--busiest`, or `--busiest=chicken`) or after `/summon`s (`--summon=chicken:10`). Private user folder:
  `XDG_DATA_HOME=/tmp/…/voices-smoke-1 godot --headless --path . --script res://tools/animal_voices_measure.gd -- --seed=42 --busiest --seconds=150`
  (prints `VOICES` lines; the before/after numbers are in `docs/devlog/parts/owner-50-sounds.md`).
- **More animals' voices (owner #41):** `python3 tools/make_audio_pass_sfx.py pack` cuts the new kinds' calls, hurt
  and happy voices (and the fox's and parrot's real voices) out of CC0 freesound takes at the times written in
  `animal_pack()`; `freesound()` skips the licence check for files already in the cache, so after adding a source
  check its page once (the notes' method: grep the page for `creativecommons.org/publicdomain/zero/1.0`).
- **Every animal kind needs a chorus level** (`VoiceRules.CALL_GAIN_DB`, guarded by
  `test_every_animal_kind_joins_the_chorus_with_a_measured_level`): measure its takes through a phone speaker the #50
  way (`ffmpeg -stream_loop 6 -i take.ogg -af "highpass=f=500,highpass=f=500,ebur128=framelog=quiet" -f null -`, the
  mean of the takes' integrated LUFS) and bring it towards −17 LUFS, boosts capped at +3 dB.
- **New audio file = a credits line**: `tests/unit/test_audio_credits.gd` fails for any audio file under
  `assets/` that no backticked name or pattern in `assets/CREDITS.md` matches.
- The classical `.import` files have `loop=false` (a piece plays once); the ambience ones `loop=true`.
  After changing a piece's length, update `MusicPieces.PIECES` (`test_classical_music.gd` compares them).

### The polish pass: pictures, loudness, universe audio (M5 Task 2, spec §15.2)
```bash
XDG_DATA_HOME=/tmp/…/shots godot --path . --disable-vsync --script res://tools/polish_shots.gd   # windowed
python3 tools/measure_loudness.py [music|pieces|ambience|voices] [--json out.json]            # needs ffmpeg
python3 tools/make_audio_pass_sfx.py universes          # Frostpeak's and the Candy Kingdom's ambience loops
python3 tools/make_classical_music.py winter_largo snow_dancing minute_waltz
```
- `polish_shots.gd` pictures the menu with the title diorama at four moments of its loop, the Survivor hub's five
  universe cards, a universe's own screens (how brave, which game) and every universe's loading card, at 1600 × 720
  and 1334 × 750, into `user://polish_shots/` (a private `XDG_DATA_HOME`: a fresh profile, no shared save).
- `measure_loudness.py` measures every universe music loop, piece, ambience loop and monster idle voice the #50 way
  (EBU R128 integrated loudness full band and after two 500 Hz high-passes, true peak) and prints the tables.
  **When an audio file changes, copy its three numbers into `core/rules/loudness.gd`** (`Loudness.MUSIC`, `PIECES`,
  `AMBIENCE`, `VOICES`): the game's gains come from there, and `tests/unit/test_loudness.gd` checks every file a
  universe plays is measured and listed in the tool.
- A universe's own classical pieces carry `"own": true` in `MusicPieces.PIECES`: they play only where the universe
  names them (`classical` in its descriptor), never in the menu or elsewhere.

### Player avatars (blocky and realistic)
- Both bodies implement `AvatarModel` (`entities/player/avatar_model.gd`): `animate`, `play_jump`,
  `hand()` (held items attach there), `body_pivot()`, `set_pose(&"stand" | &"sleep" | &"swim")`, and
  `swim(horizontal, vertical, delta)`, called instead of `animate` while swimming (M2 Task 14).
  `Player.set_avatar_style(style)` swaps `$Avatar`; the sandbox calls it for every player on this device.
- The realistic person is Kenney "Animated Characters 3" (CC0) in `assets/characters/kenney_human/`.
  The clip files `idle.fbx`, `run.fbx` and `jump.fbx` are imported **as AnimationLibrary**
  (`importer="animation_library"` in their `.import`), with the clip's loop mode set under `_subresources`.
- The FBX faces +Z and carries a 100× unit scale on its `Root` node. `RealisticAvatar` turns it and
  scales it from the mesh AABB at runtime. Anything under a `BoneAttachment3D` inherits that scale,
  which is why `hand()` is a child node that cancels it.
- The Kenney pack has no swim clip. The realistic swim strokes come from `SwimStrokes`
  (`entities/player/swim_strokes.gd`), a `SkeletonModifier3D` on the skeleton that poses the arm and
  leg bones over the idle clip while swimming.
- **Looks (M3 Task 9):** `AvatarModel.apply_look(AvatarLook)` dresses either body; box parts
  (`AvatarParts`) hang on `head_anchor` / `face_anchor` / `back_anchor` / `hip_anchor` / `body_anchor`
  (on the realistic person: `BoneAttachment3D`s on Head, UpperChest and Hips at head scale 0.85 and back
  scale 0.7). The realistic skin is recoloured by `AvatarSkin` (one `ShaderMaterial` per look). Emotes:
  `play_emote` / `stop_emote` / `emote()`, poses from `EmotePoses` (the realistic one through an
  `EmotePoser` skeleton modifier). `Player.look_code` is synced; `Player.celebrate()` dances and throws
  confetti.
- To see every look in both styles (needs a display, not headless):
  `godot --path . --disable-vsync --script res://tools/avatar_gallery.gd -- --out=/tmp/g.png [--back] [--side] [--close] [--emote=wave]`.
- **Boy and girl looks (owner feedback #48, spec §14.6a):** `AvatarLook.base` (boy / girl / neutral) is the
  editor's first choice and stays on the phone (not in `to_code()` or the backup); `AvatarLook.start` and
  `AvatarLook.preset` keep the skin tone and dance wheel. The CLOTHES slot's cuts (`AvatarCatalog.CUTS`) are
  worn in the look's own colours: part boxes can name `"top"` and `"bottom"` (the look's shirt and pants) as
  well as `"shirt"` / `"pants"` (what the body wears). Part boxes can be round (`AvatarParts.BALL`, `CONE`,
  `TUBE`, per box or per part); a part `"<id>_real"` replaces `"<id>"` on the realistic person, whose new
  anchors are `body_anchor()` (the chest) and `waist_anchor()` (the hips; skirts, in metres). The realistic
  face's lashes and cheeks are uniforms of `avatar_skin.gdshader` at `AvatarSkin.FACE_SPOTS`. Bots wear
  `BotRules.avatar_look(i)` in their own colours (`AvatarModel._resolved`). Everything for boys and girls
  is free (`AvatarCatalog.GIRL_PARTS`; the shop tests scan it).
- **The default look (owner feedback #43, spec §3c):** `AvatarLook.new()` is EasyCraft's own default (peach skin, curly
  brown hair, the rosy smile, an orange tee, teal trousers): new players and JUST ME. `AvatarLook.classic()` is the old
  yellow-and-blue default: `ProfileData.from_json` fills a saved look's missing or unknown fields from it
  (`AvatarLook.from_dict(d, base)`), so every saved profile looks as before. The blocky head is three crossing boxes
  (`HEAD_ROUND`, edges cut round, the same 0.5 outer size) at `HEAD_SCALE` 1.08; every body wears the **buddy badge**
  (`BuddyBadge`, one shared mesh on the parts' material) on its `body_anchor()` unless a full outfit is worn.
- Pictures of the boy and girl looks, the editor and the first-launch look step (a window, a "shots" folder):
  `XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/girl_avatar_shots.gd`
  (PNGs in `$XDG_DATA_HOME/godot/app_userdata/EasyCraft/girl_avatar_shots/`, `GIRL_SHOT` lines).
- **The Storybook costume pack (owner feedback #36, spec §14.6b):** `CostumeRules` (`core/avatar/costume_rules.gd`)
  holds the 21 costumes (whole looks of catalogue parts), their sources and `ORDER`. A costume is the avatar item
  `"costume.<id>"` (`AvatarCatalog.COSTUME`, not a tab) with one earn way; its own new parts are items of kind
  `AvatarCatalog.IN_COSTUME` ("costume": its id). `AvatarUnlocks.is_owned` also asks `CostumeRules.gives`: an earned
  costume owns everything it wears (gold items in it too). Ways named `"<kind>/<detail>"` (`level/3`, `title/hunter`,
  `quest/tilly_pets`, `badge/big_builder`, `count/buddy_ridden/fly`, `secret/cove`) and `EARN_SECRET_PAGE` are read
  from the profile by `CostumeRules.met`; `CostumeRules.sync(profile)` gives what is due (idempotent). It runs in a
  world on `Progress.changed` (Session's owner-36 section, the profile's own progress only) and when the avatar editor
  opens. A boss's costume comes with its win (`AvatarCatalog.BOSS_EARNS`, `BossDirector._earn_boss_items`); the Cube
  Hero with a code (a cosmetic reward of `"costume.cube_hero"` in both code tables). Adding a costume: its parts
  (both styles), a `COSTUMES` line, an `ITEMS` line with its way, a `SOURCES` line, a place in `ORDER`; the costume
  tests check the rest (both bodies, fixed ways in the free game, never sold, the banned names).
- Hats sit lower on the realistic head than on the blocky one: a part's `"real_offset"` (`AvatarParts.REAL_HAT_DROP`)
  moves it there (`AvatarModel._attach`). Faces are painted on the realistic person, but a face with a `"face_<id>_real"`
  part (Pinocchio's nose, a beard) wears it there. Seen from the front the avatar's +X is the viewer's **left**: text
  and emblems built from boxes (the Nautilus' N, the Hatter's 10/6) are laid out mirrored in X.
- Pictures of every costume (front and back, blocky over realistic), faces close up and the COSTUME tab:
  `XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/costume_shots.gd`
  (PNGs in `$XDG_DATA_HOME/godot/app_userdata/EasyCraft/costume_shots/`, `COSTUME_SHOT` lines).

### Generator benchmark
```bash
godot --headless --path . --script res://tools/bench_generator.gd
```
This times `MeadowsGenerator._generate_block` per 16³ chunk over an 8×9×8-chunk region (seed 12345). It
prints one `BENCH <surface|underground|sky> chunks=… avg_ms=… worst_ms=…` line per chunk kind. It also
generates every chunk with the secrets off (M2 Task 16), in alternating order so a busy PC slows both alike:
`BENCH_SECRETS <kind> off_avg_ms=… on_avg_ms=…` compares them, and `BENCH_SECRET_AREAS` times placing a new
128 × 128 area's secrets (once per area, then cached). Numbers: `docs/devlog/parts/m2-task-16.md`.
With `-- --desert` (M3 Task 2) it compares `DesertGenerator` with `MeadowsGenerator` on the same chunks, the
two alternating chunk by chunk: `BENCH_DESERT <kind> meadows_avg_ms=… desert_avg_ms=…` and
`BENCH_DESERT_SECRET_AREAS` (numbers: `docs/devlog/parts/m3-task-2.md`). `-- --frost` (M3 Task 3) does the same for
`FrostGenerator`: `BENCH_FROST <kind> meadows_avg_ms=… frost_avg_ms=…` (numbers: `docs/devlog/parts/m3-task-3.md`). `-- --candy` (M3 Task 4)
the same for `CandyGenerator`: `BENCH_CANDY …` (numbers: `docs/devlog/parts/m3-task-4.md`). `-- --dragon` (owner 39) the
same for `DragonGenerator`: `BENCH_DRAGON …` (numbers: `docs/devlog/parts/owner-39-dragon-world.md`; its chunk stacks are
cached, so the second, timed round is cheaper than a cold world: the notes have a cold run too). `-- --biomes` (owner #45b) the wild
meadows (`MeadowsBiomeGenerator`, terrain version 2) against the old meadows, whole stacks of chunk columns (y −64…159) the
way a world streams them, three generators alternating chunk by chunk (the old meadows, the wild meadows, and the wild
meadows without their column cache, "cold"): `BENCH_BIOMES <kind> meadows_avg_ms=… biomes_avg_ms=… biomes_cold_avg_ms=…`,
`BENCH_BIOMES_SECRET_AREAS` and `BENCH_BIOMES_PLACE_REGIONS` (a new 256 × 256 region's places, once, then cached). Numbers:
`docs/devlog/parts/owner-45b-world.md`. `-- --space` (owner #55) every planet's `SpaceGenerator` against the meadows:
`BENCH_SPACE_<MOON|BOING|RAINBOW> …` (the second round, stacks cached) and `BENCH_SPACE_<P>_COLD …` (fresh generators, a
stack's chunks one after another as a world streams them). Numbers: `docs/devlog/parts/owner-55-space.md`.
`-- --space moon mars` benches only those planets; Mars adds `BENCH_MARS_<VOLCANO_FLANK|VOLCANO_TOP|CANYON|NORTH_CAP>`
(fresh generators over 4 × 4 whole chunk stacks there, against the meadows on the same chunks). Numbers:
`docs/devlog/parts/cosmos-mars.md`. Europa adds `BENCH_EUROPA_<WELL|CLIFFS|VENT>` the same way (numbers:
`docs/devlog/parts/cosmos-europa.md`), Io `BENCH_IO_<LAKE|MOUNTAIN|VOLCANO>` (`docs/devlog/parts/cosmos-io.md`), Titan
`BENCH_TITAN_<SEA|DUNES|MOUNTAIN>` (`docs/devlog/parts/cosmos-titan.md`), Mercury `BENCH_MERCURY_<CLIFF|CRATER|ICE>`
(`docs/devlog/parts/cosmos-mercury.md`), Venus `BENCH_VENUS_<LANDING|HOMES|GARDEN|ISLE|OPEN>`
(`docs/devlog/parts/cosmos-venus.md`), Saturn's rings `BENCH_RINGS_<LANDING|B_RING|C_RING|CASSINI|PAN|F_RING|OPEN>`
(`docs/devlog/parts/cosmos-rings.md`), Pluto `BENCH_PLUTO_<LANDING|PLAIN|HILLS|MOUNTAINS|DARK|BRIGHT>` and
`BENCH_PLUTO_SHAPE` (building a shape, one column; `docs/devlog/parts/cosmos-pluto.md`), Triton
`BENCH_TRITON_<LANDING|GEYSER|CAP|MELON|LAKE|CRATER>` and `BENCH_TRITON_SHAPE` (`docs/devlog/parts/cosmos-triton.md`),
Ganymede `BENCH_GANYMEDE_<LANDING|GROOVES|DARK|CRATER|FROST|DRILL>` and `BENCH_GANYMEDE_SHAPE`
(`docs/devlog/parts/cosmos-ganymede.md`).
`-- --deposits` (spec §26) the chunks round each terrain's nearest deposits with
deposits on and off: `BENCH_DEPOSITS <meadows|wild|desert|moon|mars> off_avg_ms=… on_avg_ms=…`, and
`BENCH_DEPOSIT_REGIONS` the one-time cost of placing a new 512 × 512 region's deposits (numbers:
`docs/devlog/parts/prospecting-earth.md`, the Moon's and Mars's `prospecting-space.md`).
(`docs/devlog/parts/cosmos-mercury.md`). The Moon and Mars add `BENCH_COLONY_<MOON|MARS>` (spec §21c: the colony's 6 × 6
chunk stacks with the colony, without it and the meadows') and `BENCH_COLONY_<P>_SHAPE` (a shape with its colony built;
numbers: `docs/devlog/parts/colony-domes.md`).
`-- --wonders` (owner #78) world 41's `WondersGenerator` against the meadows round the landing square (`BENCH_WONDERS …`)
and over each wonder of the three tours, fresh, against the old and the wild meadows (`BENCH_WONDERS_<ID> …`; numbers:
`docs/devlog/parts/wonders-ancient.md`, `wonders-new-seven.md`, `wonders-nature.md`).

### Space: the Moon and the planets (owner feedback #55, spec §21)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd   # pages 15-17: moon.png, boing.png, rainbow.png
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py [moon boing rainbow]   # their realistic twins (CC0 ambientCG)
python3 tools/copy_page_import.py dragon moon boing rainbow   # a new page's .import files take a page's settings; --import again
XDG_DATA_HOME=/tmp/easycraft-space-smoke godot --headless --path . --script res://tools/space_smoke.gd
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=16   # a new Survivor world on the Moon
```
- **Getting there:** fly up (Sandbox free, Survivor paid) above any world. From y 160 the sky turns to space (stars at noon),
  at y 180 "Keep flying up! Space is up there!", crossing **y 200** opens "Where shall we land?" (the Moon, Planet Boing,
  Rainbow Planet; from a space world HOME first; STAY HERE). Nothing reads the jump or fly input: the director looks at
  this game's player's height only.
- **The smoke run** (a fresh private folder whose path contains "smoke", with a copy of `profile.json`) flies up from a new
  Green Meadows Sandbox world, lands on the Moon (its slot `sandbox_16`, gravity 0.35, the space sky and the home planet,
  no night monsters, the landing pad under the feet, MY MAP's pad, the portal home, a slow fall, the Moon Base found and
  marked), flies up and takes HOME (back on the take-off column, on the ground), then flies a Survivor bag to Planet Boing
  (`survivor_u17`) and home through the portal by the pad. Prints `SPACE_SMOKE ok|FAIL …`; exits 0 when all passed.
- **A new block page:** draw it (`make_space_atlas.gd`), make its twin, `godot --headless --path . --import` (the new PNGs get
  Godot's defaults), `python3 tools/copy_page_import.py dragon <page>` (lossless with mipmaps, the normal map at half size:
  `test_page_sizes.gd` checks it), `--import` again. Run the realistic tool with `PYTHONDONTWRITEBYTECODE=1`: the tracked
  `tools/__pycache__/make_realistic_atlas.cpython-314.pyc` changes otherwise.

### Mars, world 19 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- mars   # only page 18 (mars.png); no args: every page
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py mars           # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon mars                                # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-mars-smoke godot --headless --path . --script res://tools/mars_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon mars
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=19   # a new Survivor world on Mars
```
- **What it is:** a space world like the Moon (`world/universes/mars.gd`, `UniverseRegistry.SPACE[19]`,
  `SpaceRules.WORLDS` has 19, so the Star Map says LAND on Mars). Terrain: `SpaceShape` with planet `MARS`, its regions in
  `MarsTerrain` (`world/generators/mars_terrain.gd`: the plains, craters, dry river valleys, the shield volcano, the
  canyon, the polar caps; `column()` packs height × 16 + region); `SpaceGenerator` writes a Mars column by its region
  (`_write_mars_column`, the shared rock in whole-chunk layer fills). Blocks: page 18, ids 336-349 (`MarsBlocks`).
  Secrets: `SpaceSecretRules` (Mars's palette, the rover `_mars_rover`). Sights: `world/space_sights.gd` (node "Sights",
  the sandbox's section "Cosmos: a space world's sights"); their words are the descriptor's `sights`.
- **New descriptor fields** (any universe may use them): `lifeless` (no animals: the sandbox switches the AnimalDirector
  off; `UniverseRegistry.animals` is empty), `sights` ({id: {name, words}}), a sky palette's `sunset` colour (the horizon's
  glow at sunrise and sunset: `SkyCycle._tint`), and in `sky_planet`: `lumpy`, `own_moons` (no moon disc at night) and
  `moons` (more small bodies: `SkyCycle.moons()`).
- **The smoke run** (a private folder whose path holds "smoke", with a copy of `profile.json`) flies up from a new Green
  Meadows Sandbox world, taps Mars on the Star Map (its card, LAND), lands on Mars (`sandbox_19`: gravity 0.38, the sky,
  Phobos and Deimos, peace, no animals, MY MAP's pad and four sights, the Space Book's mark, the portal home), falls
  slowly, climbs onto the rover, stands on the volcano's summit (its fact) and walks home through the portal (the
  take-off column). Prints `MARS_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Mars fact in the game (the finds' and the sights' words, the hints) is listed with its check in
  `docs/devlog/parts/cosmos-mars.md`; keep that list when changing one.

### Europa, world 20 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- europa   # only page 20 (europa.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py europa           # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon europa                                # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-europa-smoke godot --headless --path . --script res://tools/europa_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon europa
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=20 --sights   # pictures, the sights too (windowed)
```
- **What it is:** Jupiter's icy moon as a space world (`world/universes/europa.gd`, `UniverseRegistry.SPACE[20]`,
  `SpaceRules.WORLDS` has 20). Terrain: `SpaceShape` with planet `EUROPA`, its regions in `EuropaTerrain`
  (`world/generators/europa_terrain.gd`: the smooth crust, three families of reddish cracks with stained ridges, the ice
  cliffs' plateau, the geyser vents in salt mounds, the ocean well). The well is the one place a column is not solid up
  to its top: `column()` gives a WELL column's ice top (the layers are written as usual), `well_ground()` its real ground
  (the seafloor, the ramp), `well_block()` its blocks; `SpaceGenerator._carve_europa_well` cuts it into the chunks it
  reaches (under y 0 too), after the ores. Blocks: page 20, ids 368-380 (`EuropaBlocks`). Secrets: `SpaceSecretRules`
  (Europa's palette, the Ice Lander `_ice_lander`; `_fits` keeps secrets out of the well and off the vents). Sights: the
  ocean, the cliffs, the plume nearest the pad (MY MAP from the landing), a crack where found.
- **New shared pieces:** `SpaceGeysers` (`world/space_geysers.gd`, node "Geysers" in a world whose shape has vents: the
  plumes near the player erupt, each on its own beat), `PadRules`' geyser vent (a pad at `GEYSER_SPEED`, the jump pad's
  16 m/s: ~41 blocks up in Europa's gravity), a sky planet's `bands` and `spot` (`SkyCycle.planet_image`: Jupiter),
  `LabRules.step_velocity` (the auto-step hop keeps the Moon's height in lower gravity), `space_shots.gd --sights`.
- **The smoke run** flies up from a new Green Meadows Sandbox world, taps Europa on the Star Map (its card, LAND), lands
  (`sandbox_20`: gravity 0.13, the black sky with Jupiter, Io and Ganymede, peace, no animals, MY MAP's pad and three
  sights, the Space Book's mark, the plumes, the portal home), falls slowly, stands on the Ice Lander's deck, on a plume's
  mound, rides the plume up from its vent, climbs the ice cliffs, reaches the ocean on the shelf at the bottom of the
  well, and walks home through the portal. Prints `EUROPA_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Europa fact in the game is listed with its source in `docs/devlog/parts/cosmos-europa.md`; keep that
  list when changing one. No mission names (spec §21b.2): "a space telescope", "a spacecraft", "scientists".

### Io, world 21 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- io       # only page 21 (io.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py io               # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon io                                    # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-io-smoke godot --headless --path . --script res://tools/io_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon io
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=21 --sights   # pictures, the sights too (windowed)
```
- **What it is:** Jupiter's volcanic moon as a space world (`world/universes/io.gd`, `UniverseRegistry.SPACE[21]`,
  `SpaceRules.WORLDS` has 21). Terrain: `SpaceShape` with planet `IO`, its regions in `IoTerrain`
  (`world/generators/io_terrain.gd`: the sulphur plains and their patches, the volcanoes' cones, vents and red rings, the
  small lava lakes, the big lava lake's crust, moat, rim and causeways, the mountain). Every column is a plain column:
  `column()` packs its height and kind; `SpaceGenerator._write_io_column` writes it (the rock in layers of black lava
  filled chunk-wide by `_fill_io_layers`). Blocks: page 21, ids 384-398 (`IoBlocks`). Secrets: `SpaceSecretRules` (Io's
  palette, the Volcano Lander `_volcano_lander`; `_io_fits` keeps secrets out of the lava lake and off the volcanoes).
  Sights: the lava lake (its rim first), the mountain's top, the volcano nearest the pad (MY MAP from the landing), a red
  ring where found.
- **Hot lava** (`BlockIds.HOT_LAVA`) is a `PadRules` pad at `LAVA_SPEED` (8 m/s: ~7 blocks up on Io): it never hurts,
  it bounces a child up and out. Keep every band of it at most `IoTerrain.MOAT_W` (2) wide and never put it where a
  child cannot see it coming (the rules and the tests in `docs/devlog/parts/cosmos-io.md`, ruling 2). The volcano vent
  is a pad at `GEYSER_SPEED` like Europa's plumes. `SpaceGeysers` serves any planet whose shape has vents
  (`SpaceShape.vents_near`, `has_vents`; `plume_color`: Io's yellow sulphur, Europa's white vapour).
- **Block ids:** page 21 is the last block page under the items' ids (400-511: `BlockIds.RESERVED_FIRST`/`END`); Titan
  took page 29 (ids 512-527), Mercury page 30 (ids 528-543); the next pages are in "Block ids and pages" below
  (`BlockIds.NEXT_PAGE_FIRST_ID`).
  `tests/unit/test_block_pages.gd` registers its own test page 99.
- **The smoke run** flies up from a new Green Meadows Sandbox world, taps Io on the Star Map (its card, LAND), lands
  (`sandbox_21`: gravity 0.18, the black sky with Jupiter, Europa and Ganymede, peace, no animals, MY MAP's pad and three
  sights, the Space Book's mark, the volcanoes, the portal home), falls slowly, stands on the Volcano Lander's deck, on a
  volcano's cone, rides its plume up from the vent, reaches the lava lake's rim, steps into the moat's hot lava (a
  bounce up, hearts unchanged), climbs the mountain, and walks home through the portal. Prints `IO_SMOKE ok|FAIL …`;
  exits 0 when all passed.
- **Facts:** every Io fact in the game is listed with its source in `docs/devlog/parts/cosmos-io.md`; keep that list
  when changing one. No mission names (spec §21b.2): "a spacecraft", "scientists".

### Titan, world 22 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- titan    # only page 29 (titan.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py titan            # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon titan                                 # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-titan-smoke godot --headless --path . --script res://tools/titan_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon io titan
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=22 --sights   # pictures, the sights too (windowed)
```
- **What it is:** Saturn's hazy moon as a space world (`world/universes/titan.gd`, `UniverseRegistry.SPACE[22]`,
  `SpaceRules.WORLDS` has 22). Terrain: `SpaceShape` with planet `TITAN`, its regions in `TitanTerrain`
  (`world/generators/titan_terrain.gd`: the soil plains and their pebble patches, the methane sea to the north, small
  methane lakes, the dunes to the south, the icy mountains). Every column is a plain column (`column()` packs its height
  and kind); a column whose ground lies under `TitanTerrain.LIQUID_TOP` is filled with the game's WATER up to it
  (`SpaceShape.top_of`), and `SpaceShape.is_river` is true there, so every spawner's "dry land" keeps off it.
  `SpaceGenerator._write_titan_column` writes it. Blocks: page 29, ids 512-522 (`TitanBlocks`), the first page past the
  items' ids. Secrets: `SpaceSecretRules` (Titan's palette, the Landing Probe `_landing_probe`; `_titan_fits` keeps
  secrets off the methane and its shores). Sights: the sea (its beach on the way to the pad), the first dune south of the
  pad, the icy mountains' top (MY MAP from the landing), a lake where found.
- **The methane** is the game's water shown as liquid methane: the descriptor's `liquid` &"methane" (`TitanRules.METHANE`)
  sets the one water material's `methane` uniform (`BlockLibrary.set_liquid`, like the Candy Kingdom's chocolate) and
  `Ambience.methane` (the amber view under it: `TitanRules.methane_mood`). Very floaty: in `Player._swim`, JUMP at the
  surface of floaty methane leaps the swimmer out (`TitanRules.leaps`, `LEAP` 0.75 of a jump's speed, `LEAP_COAST`,
  `LEAP_COOLDOWN`); a bank in reach is climbed first. A game rule, not a fact (a real person would sink in it).
- **Gifts** carry blocks up to 1023, never the items' 400-511 (`BuildCodec.BLOCK_MAX`, `RESERVED_FIRST`/`RESERVED_END`,
  the same in the server's `BuildRules`, module 0.2.15: deploy the server with this client).
- **The smoke run** flies up from a new Green Meadows Sandbox world, taps Titan on the Star Map (its card, LAND), lands
  (`sandbox_22`: gravity 0.14, the orange haze with Saturn and its rings, the methane look, peace, no animals, MY MAP's pad
  and three sights, the Space Book's mark, the portal home), falls slowly, stands on the Landing Probe, on the sea's
  beach, swims in the sea and leaps out of it holding JUMP (hearts unchanged), stands on a dune, on the icy mountains' top
  and by a lake, and walks home through the portal (the water water again). Prints `TITAN_SMOKE ok|FAIL …`; exits 0 when
  all passed.
- **Facts:** every Titan fact in the game is listed with its source in `docs/devlog/parts/cosmos-titan.md`; keep that list
  when changing one. No mission names (spec §21b.2): "a probe", "scientists".

### Mercury, world 23 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- mercury   # only page 30 (mercury.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py mercury           # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon mercury                                # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-mercury-smoke godot --headless --path . --script res://tools/mercury_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon mercury
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=23 --sights   # pictures, the sights too (windowed)
```
- **What it is:** the planet closest to the Sun as a space world (`world/universes/mercury.gd`, `UniverseRegistry.SPACE[23]`,
  `SpaceRules.WORLDS` has 23). Terrain: `SpaceShape` with planet `MERCURY`, its regions in `MercuryTerrain`
  (`world/generators/mercury_terrain.gd`: grey dust plains with darker patches; small craters, the young ones with bright
  rays; big craters with a flat floor, a central peak and terraced walls; long cliffs (lobate scarps: arcs whose inside is
  a raised slab with a gentle back and a terraced face), the great one a walk from the pad; the ice crater far to the
  north, and ice on every big crater's floor near a pole). Every column is a plain column; the features are drawn cell by
  cell into caches (a mutex: the generator's threads share them) and dropped where they would touch a bigger one, so
  every column belongs to one of them: `column()` is the reference, `columns()` the generator's block of them.
  `SpaceGenerator._write_mercury_column` writes it. Blocks: page 30, ids 528-541 (`MercuryBlocks`). Secrets:
  `SpaceSecretRules` (Mercury's palette, the Sunshade Lander `_sunshade_lander` with its sunshade on `SUNNY`, the +z side
  where the Sun is at noon; `_fits` keeps secrets off the cliffs' faces and out of the big craters, `steep_near`). The
  explorers' thermometer is a feature `THERMOMETER_DISTANCE` from the pad (`SpaceShape.thermometer_column`, 7 tall: a
  plinth, the red bulb, the tube). Sights: the thermometer, the great cliff's face, the nearest big crater, the ice crater
  (all four on MY MAP from the landing).
- **The big Sun:** a descriptor's `sun_size` (`UniverseRegistry.sun_size`, 0.25-4, 1 without one) is `SkyCycle.sun_size`
  (the sandbox's `_space_local`): it scales the painted sky's sun (its disc and glow, `sun_angle_max`) by day, never the
  night's light, never the light's energy. Mercury's is 3; its `photo_sky` false keeps it in the realistic style too.
- **The smoke run** flies up from a new Green Meadows Sandbox world, taps Mercury on the Star Map (its card, LAND), lands
  (`sandbox_23`: gravity 0.38, space's black sky with the Sun three times as big, Venus, Earth and our Moon as tiny points,
  peace, no animals, MY MAP's pad and four sights, the Space Book's mark, the thermometer by the pad, the portal home),
  falls slowly, stands on the Sunshade Lander's deck, by the thermometer, on the long cliff's face, on a big crater's peak
  and on the ice crater's ice (hearts unchanged), and walks home through the portal (home's Sun again). Prints
  `MERCURY_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Mercury fact in the game is listed with its source in `docs/devlog/parts/cosmos-mercury.md`; keep that
  list when changing one. No mission names (spec §21b.2): "spacecraft", "scientists". Its heat is a fact, never a danger:
  no word says anything hurts (`test_the_heat_is_a_fact_never_a_danger`).

### Venus's cloud city, world 24 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- venus   # only page 38 (venus.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py venus           # its realistic twin (CC0 ambientCG)
SMOKE_ALL_DIR=<your folder> tools/smoke_all.sh venus                            # the smoke run (a private folder)
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon venus
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=24 --sights   # pictures, the sights too (windowed)
```
- **What it is:** a floating city about 50 km up in Venus's sky as a space world (`world/universes/venus.gd`,
  `UniverseRegistry.SPACE[24]`, `SpaceRules.WORLDS` has 24). Terrain: `SpaceShape` with planet `VENUS`, the city in
  `VenusTerrain` (`world/generators/venus_terrain.gd`): round platforms (`platforms()`: [role, x, z, radius]) all at
  `DECK_Y` 80 on float hulls, bridges between them (`bridges()`: [ax, az, bx, bz], 3 wide), isles per `ISLE_CELL` cell far
  out with bridges to their neighbours, the clouds everywhere below (`cloud_top`). A column is [kind, top, bottom, cloud]
  (`column()` the reference, `columns()` the generator's block of them); the platforms and bridges are looked up in 32-block
  buckets. The city's built parts (the cloud scope, the dock's mast, the garden's pond, the homes, the west telescope) are
  boxes (`built_at`, `write`); lamp posts, flowers and little trees are features (`feature_at`, `features()`). The clouds
  and the bridges are `is_river` (no spawner stands there); the aliens camp on the camp deck (`camp_spot`), the Theater on
  the show deck (`show_spot`). `SpaceGenerator._generate_venus` writes it (no ores: no rock). Blocks: page 38, ids 656-671
  (`VenusBlocks`). Secrets: `SpaceSecretRules` (Venus's palette; `secret_spot` draws them onto a platform, `holds` keeps
  them over decks with a hull under them; `_hull_room`, `_cloud_geode`; the Research Blimp `_research_blimp` at the dock).
- **The warm breeze:** a descriptor's `has_void` with `void_y` (a line of its own: `DragonRules.rescue_y`) and
  `void_words` (`DragonRules.carried_back_words`): the player's void step, the host's `VoidWatch` and the sandbox's words
  use them. Venus's line is `VenusTerrain.LIFT_Y` 56: far over the clouds (never over 42), 24 under the decks.
- **The Sun rises in the west:** a descriptor's `sun_rises_west` (`UniverseRegistry.sun_rises_west`) is
  `SkyCycle.sun_west` (the sandbox's `_space_local`): `DayCycle.backwards` mirrors the Sun's and the Moon's paths east-west.
  Every world: the Sun's disc is drawn in the painted sky only while its light is full (`sun.sky_mode`: no dark blot at dawn
  and dusk).
- **Lightning:** `VenusLightning` (node "Lightning", the sandbox's `_space_lightning`, this game's own): a silent bolt deep
  in the clouds 26-70 blocks away every 5-11 s, drawn with the stars' material settings.
- **The smoke run** (`tools/venus_smoke.gd`) flies up from a new Green Meadows Sandbox world, taps Venus on the Star Map
  (its card, LAND), lands (`sandbox_24`: gravity 0.9, its golden sky, the Sun rising in the west, Earth a tiny point, peace,
  no animals, MY MAP's pad and five sights, the Space Book's mark, the lightning, the robots and the camp, the portal home),
  steps off the landing deck (the breeze lifts it back), walks into the Research Blimp's gondola, stands at the five
  sights (hearts unchanged) and walks home through the portal. Prints `VENUS_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Venus fact in the game is listed with its source in `docs/devlog/parts/cosmos-venus.md`; keep that list
  when changing one. No mission names (spec §21b.2): "robot balloons", "spacecraft", "scientists". The acid clouds and the
  heat far below are facts, never a danger (`test_the_clouds_and_the_heat_are_facts_never_a_danger`).

### Saturn's rings, world 25 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- rings   # only page 40 (rings.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py rings           # its realistic twin (CC0 ambientCG)
SMOKE_ALL_DIR=<your folder> tools/smoke_all.sh rings                            # the smoke run (a private folder)
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon venus rings
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=25 --sights   # pictures, the sights too (windowed)
```
- **What it is:** a strip of Saturn's rings as a space world (`world/universes/rings.gd`, `UniverseRegistry.SPACE[25]`,
  `SpaceRules.WORLDS` has 25; the Star Map's Saturn card says "Saturn's rings: LAND", `StarMap` Saturn's `land`).
  Terrain: `SpaceShape` with planet `RINGS`, the rings in `RingsTerrain` (`world/generators/rings_terrain.gd`): bands
  by z (north, -z, is towards Saturn): the C ring (`C_IN`-`B_IN`, dusty), the B ring (`B_IN`-`B_OUT`, the landing), the
  Cassini Division (`B_OUT`-`A_IN`, lumps only), the A ring (`A_IN`-`A_OUT`) with the Encke Gap (Pan) and the Keeler Gap,
  the F ring (`F_MID`, two braided strands), endless along x. Big chunks one per `BIG` × `BIG` cell at most (inside
  their cell: `big_chunk`), lumps one per `SMALL` cell (`lump`, never near a big chunk or the fixed chunks), the F ring's
  lumps per `F_STEP` (`f_lump`), the fixed chunks round the spawn (`FIXED`: the landing, camp, show, explorer and edge
  chunks, the C and F rings' sight chunks; mirrored east-west by the seed: `flip`) and Pan. A column is [kind, top,
  bottom] (`column()` the reference, `columns()` the generator's block; every column holds one span at most); the big
  chunks' tops are flat (no step on a chunk: at 0.05 gravity a one-block step is a slow hop), their undersides round and
  rough. Open space is `VOID` (height `VOID_TOP`, the sea level: "no ground here", the Dragon Realm's rule); open space,
  lumps and Pan are `is_river` (spawners keep to the big chunks); no bedrock, nothing under the rings. The built parts
  (the Saturn scope, the Ring Station, the Saturn model, the beacons) are boxes (`built_at`, `write`); `tree_at` marks
  their ground (Tilly and the Totem keep off). `SpaceGenerator._generate_rings` writes it. Blocks: page 40, ids 688-703
  (`RingsBlocks`). Secrets: `SpaceSecretRules` (the rings' palette; `secret_spot` draws them onto a big chunk, `holds`
  keeps them on its ice; `_hull_room`, `_ring_geode`; the Ring Explorer `_ring_explorer` on its chunk).
- **Very low gravity:** the descriptor's `gravity` 0.05 (`UniverseRegistry.MIN_GRAVITY` is 0.05): a jump floats ~34
  blocks up for ~15 s. **The suit's jets:** `has_void`, `void_y` `RingsTerrain.LIFT_Y` 50 (under every chunk's top) and
  `void_words` (Venus's `DragonRules.rescue_y` / `carried_back_words`): a fall between the chunks is a ~5 s float, then back.
- **Its sky:** space's black (`space_sky` 1), the Sun `sun_size` 0.1 (`UniverseRegistry.MIN_SUN` went to 0.1 for it,
  then to 0.025 for Pluto); Saturn is the sky planet with `dir` (over the northern horizon), `ring_edge` (the rings
  edge-on: a line across its middle, their shadow on its clouds, its shadow on them) and `pixels` 192
  (`SkyCycle.planet_image`, ~20 ms at a world's load on the PC); Titan, Enceladus, Mimas, Prometheus and Pandora are its
  `moons`.
- **The smoke run** (`tools/rings_smoke.gd`) flies up from a new Green Meadows Sandbox world, taps Saturn on the Star Map
  ("Saturn's rings: LAND"), lands (`sandbox_25`: gravity 0.05, the black sky, the small Sun, huge Saturn, peace, no
  animals, MY MAP's pad and six sights, the Space Book's mark, the robots and the camp, the portal home), steps off the
  landing chunk (the suit's jets bring it back), walks into the Ring Explorer, stands at the six sights (hearts unchanged)
  and walks home through the portal. Prints `RINGS_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every rings fact in the game is listed with its source in `docs/devlog/parts/cosmos-rings.md`; keep that
  list when changing one. No mission names (spec §21b.2): "a spacecraft", "scientists"; the Cassini Division is a place
  named for the astronomer who saw it in 1675 (`test_robot_words` lets its name through). Falling is never a danger.

### Pluto, world 26 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- pluto   # only page 41 (pluto.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py pluto           # its realistic twin (CC0 ambientCG)
SMOKE_ALL_DIR=<your folder> tools/smoke_all.sh pluto                            # the smoke run (a private folder)
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon pluto
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=26 --sights   # pictures, the sights too (windowed)
```
- **What it is:** the dwarf planet as a space world (`world/universes/pluto.gd`, `UniverseRegistry.SPACE[26]`,
  `SpaceRules.WORLDS` has 26; the Star Map's Pluto card says LAND once reached, MISSION before). Terrain: `SpaceShape`
  with planet `PLUTO`, its regions in `PlutoTerrain` (`world/generators/pluto_terrain.gd`): the heart (`sd_heart`, Inigo
  Quilez's exact heart distance, `HEART_S` blocks a unit, its point to the south) ~70-95 blocks east of the world's
  middle: its west half the plain (`plain_sd`: flat nitrogen ice at `PLAIN_Y` in cells of `CELL` with darker edges,
  `_cell_kind`; floating hills of water ice on the cells' edges within `HILL_BAND` of its shore, `hills()`), a rim up to
  the uplands (`RIM_W`), its east half the bright side (methane snow); the ice mountains (jumbled flat-topped blocks of
  water ice, `BLOCK`, up to `PEAK_H`, snowy on top) along the plain's south-west side; the red-brown lands west of
  `dark_edge` (tholin dust over red ice, rolling hills with methane frost above `SNOW_LINE`, craters with frosty rims);
  peach-tan uplands elsewhere. The plain's cells and hills and the mountains' blocks are built in `_init` (read-only
  afterwards: the generator's threads share them without a lock); `column()` packs height and kind and skips noise
  nothing can need (`NOISE_MARGIN`); `columns()` is the generator's block of them. `SpaceGenerator._write_pluto_column`
  writes it (the layers in runs: the plain's nitrogen ice fills its basin `N2_DEPTH` deep, a floating hill's water ice
  reaches twice its height down into it). Blocks: page 41, ids 704-716 (`PlutoBlocks`; 717-719 free). The **Charon
  Lookout** is the shape's built part (`PlutoTerrain.place_lookout`, called once by `SpaceShape._init`: a frost-brick
  floor, a telescope on a truss looking west and up, a globe of Charon, a glowing heart) `LOOKOUT_DISTANCE` west of the
  pad; the generator writes it with the colonies' flag (`_place_colony`, `reference_block`), `tree_at` keeps its ground.
  Secrets: `SpaceSecretRules` (Pluto's palette; `_fits` keeps them off the mountains and the hills' band,
  `steep_near`; the Balloon Lander `_balloon_lander`: legs, a gold-foil body, a white deck with lamps and the chest, a
  power pack, a dish, its drag balloon spread out behind it). Sights: the lookout, the heart's shore on the way to it, the
  nearest floating hill, the peak, the first red-brown land west of the pad, the bright side (all six on MY MAP).
- **Low gravity:** the descriptor's `gravity` 0.063 (real): a jump floats ~27 blocks up for ~12 s; a one-block step is
  the Moon's hop (a ~4 s float at this gravity: the plain, its rim and the uplands step one block at most).
- **Its sky:** a thin nitrogen air: `space_sky` 0.55 (black and starry overhead by day), a blue haze palette at the
  horizon and over the far ground; the Sun `sun_size` 0.025 (`UniverseRegistry.MIN_SUN` is 0.025: a bright star) rising
  in the west (`sun_rises_west`: Pluto spins backwards, like Venus); Charon
  the sky planet low in the west (`dir`), grey with its red cap (a sky planet's `cap`: `SkyCycle.planet_image`), never
  moving; Nix and Hydra tiny `moons`.
- **The smoke run** (`tools/pluto_smoke.gd`) flies up from a new Green Meadows Sandbox world, taps Pluto on the Star Map
  (LAND), lands (`sandbox_26`: gravity 0.063, the black sky with its blue haze, the star-like Sun, Charon in the west,
  peace, no animals, MY MAP's pad and six sights, the Space Book's mark, Nixie and the camp, the lookout, the portal
  home), falls slowly, jumps ~27 blocks, stands on the Balloon Lander's deck and at the six sights (hearts unchanged) and
  walks home through the portal. Prints `PLUTO_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Pluto fact in the game is listed with its source in `docs/devlog/parts/cosmos-pluto.md`; keep that
  list when changing one. No mission names (spec §21b.2): "a spacecraft", "scientists"; the mountains are named for
  Tenzing Norgay and Edmund Hillary (people, not missions). It says kindly that Pluto is a dwarf planet since 2006, and
  why (`test_it_says_kindly_that_pluto_is_a_dwarf_planet_and_why`). The cold is a fact, never a danger.

### Triton, world 27 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- triton   # only page 42 (triton.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py triton           # its realistic twin (CC0 ambientCG)
SMOKE_ALL_DIR=<your folder> tools/smoke_all.sh triton                            # the smoke run (a private folder)
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon pluto triton
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=27 --sights   # pictures, the sights too (windowed)
```
- **What it is:** Neptune's big moon as a space world (`world/universes/triton.gd`, `UniverseRegistry.SPACE[27]`,
  `SpaceRules.WORLDS` has 27; the Star Map's Triton card says LAND once reached, MISSION before). Terrain: `SpaceShape`
  with planet `TRITON`, its regions in `TritonTerrain` (`world/generators/triton_terrain.gd`): the bright band of fresh
  nitrogen frost (`FROST`) round the pad; the pink south polar cap south of `cap_edge` (`CAP_Z`, wandering
  `CAP_WANDER`; `CAP_RISE` higher, `MOTTLE` patches), its geysers (`vent_in_cell`: at most one per `VENT_CELL`, deep in
  the cap; the first one `first_geyser()` south of the world's middle, alone within `FIRST_CLEAR`; a vent in a ring of
  dust flush with it, `HOLE_R`/`SPOT_R`) and their dark streaks (`_on_streak`: north-east ± `TURN`, `streak_length`,
  narrowing by `TAPER`, wandering `MEANDER`, breaking up past `FADE_FROM`; `streak_centre` is a streak's middle line);
  the cantaloupe terrain north-west of its line (`MELON_D`: dimples in cells of `MELON_CELL`, `_melon_e` the edge-ness,
  ridges where it is small; it fades back to the band by the cap's edge); a walled plain north-east (`lake_centre()`: a
  frozen lake of ice lava at `LAKE_Y`, terraced walls of `STEPS` one-block steps `STEP_W` wide, a flat rim, a blend); one
  of its few craters east (`crater_centre()`). What the rules look up is built in `_init` (read-only afterwards: the
  generator's threads share it without a lock); `column()` packs height and kind and skips noise nothing can need
  (`NOISE_MARGIN`); `columns()` is the generator's block of them. `SpaceGenerator._write_triton_column` writes it (frost
  over a crust of nitrogen ice over water ice; pink ice over nitrogen ice; the lake's ice lava in layers). Under the frost
  Triton uses Pluto's `NITROGEN_ICE` and `WATER_ICE` (page 41). Blocks: page 42, ids 720-733 (`TritonBlocks`; 734-735
  free). The **Neptune Lookout** is the shape's built part (`TritonTerrain.place_lookout`, called once by
  `SpaceShape._init` `NEPTUNE_LOOKOUT` east and north of the pad: a cap-brick floor, a telescope looking north-east and
  up, a globe of Neptune, a blue beacon); the generator writes it with the colonies' flag, `tree_at` keeps its ground.
  Secrets: `SpaceSecretRules` (Triton's palette; `_fits` keeps them off the lake, the crater and the geysers,
  `steep_near`; the Hopper Lander `_hopper_lander`: legs, a gold-foil body with a rocket nozzle under it, a white deck
  with lamps and the chest, a big white nitrogen tank, a scoop arm to a heap of frost, a power pack, a dish, the scorched
  rings of its last hops behind it). Sights: the lookout, the first geyser, a point on its streak, the cap south of the
  pad, the cantaloupe terrain north-west of it, the lake, the crater (all seven on MY MAP, `sight_spots`).
- **The geysers are a ride:** `BlockIds.NITROGEN_GEYSER` is a `PadRules` pad at `PUFF_SPEED` (11 m/s: ~32 blocks up at
  0.079, ~11 s in the air); it starts a drift (`drift_left`, `DRIFT_TIME`): Triton's thin wind carries the rider
  north-east (`WIND`) at `DRIFT_SPEED` (the child steers across it; landing ends it). `SpaceGeysers` puffs dark dust and a
  little frost from the vents near the child, drifting north-east (`plume_wind`, `DRIFT`); `PadFx` the same for the ride.
- **Low gravity:** the descriptor's `gravity` 0.079 (real): a jump floats ~21 blocks up for ~10 s; the band, the cap,
  the cantaloupe terrain and the lake step one block at most.
- **Its sky:** a very thin nitrogen air: `space_sky` 0.8, a faint cold haze at the horizon; the Sun `sun_size` 0.033;
  Neptune the sky planet big (`size` 100) and low over the north-east horizon (`dir`), deep blue with faint `bands` and
  its dark spot (`spot` with `spot_color`: `SkyCycle.planet_image` draws Jupiter's red `SPOT` without it), never moving;
  two small `moons`.
- **The mission:** `MissionRules`' Triton row has `skim` (not `air`): the check (`RocketCheck`) wants a heat shield to
  skim its thin air and never a parachute; the board says "A heat shield to skim its thin air".
- **The smoke run** (`tools/triton_smoke.gd`) flies up from a new Green Meadows Sandbox world, taps Triton on the Star
  Map (LAND), lands (`sandbox_27`: gravity 0.079, the black sky, the star-like Sun, Neptune in the north-east, peace, no
  animals, MY MAP's pad and seven sights, the Space Book's mark, Spout and the camp, the lookout, the geysers watched, the
  portal home), falls slowly, jumps ~21 blocks, stands on the Hopper Lander's deck and at the seven sights, rides the
  first geyser's puff up and north-east (hearts unchanged) and walks home through the portal. Prints
  `TRITON_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Triton fact in the game is listed with its source in `docs/devlog/parts/cosmos-triton.md`; keep that
  list when changing one. No mission names (spec §21b.2) and no names of its mapped places (they are long names from
  myths): "a spacecraft", "scientists", "the cantaloupe terrain". The cold is a fact, never a danger; the geysers are a
  ride (`test_the_cold_and_the_geysers_are_never_a_danger`).

### Ganymede, world 28 (cosmos, spec §21b.2)
```bash
godot --headless --path . --script res://tools/make_space_atlas.gd -- ganymede   # only page 43 (ganymede.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_space_realistic.py ganymede           # its realistic twin (CC0 ambientCG)
SMOKE_ALL_DIR=<your folder> tools/smoke_all.sh ganymede                            # the smoke run (a private folder)
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon triton ganymede
XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=28 --sights   # pictures, the sights and the auroras too (windowed)
```
- **What it is:** Jupiter's biggest moon (the biggest moon of all) as a space world (`world/universes/ganymede.gd`,
  `UniverseRegistry.SPACE[28]`, `SpaceRules.GANYMEDE` 28 in `WORLDS`; the Star Map's Ganymede card has `"world": 28` and
  says LAND once reached, MISSION before). Terrain: `SpaceShape` with planet `GANYMEDE`, its regions in `GanymedeTerrain`
  (`world/generators/ganymede_terrain.gd`): a smooth plain of bright ice round the world's middle (`PLAIN_R`, the pad);
  the bright grooved terrain everywhere else on the bright side, in lanes (`LANE_CELL`, Voronoi cells: `lane_at`) of long
  parallel ridges and grooves (`PERIOD`, at most `SLOPE` steep and `RIDGE_H` high), flat seams where lanes meet (`SEAM`);
  the old dark terrain west of `dark_edge` (`DARK_RISE` higher over `DARK_BLEND`; furrows: arcs `FURROW_SPACING` apart
  round `furrow_centre()`; old craters per `OLD_CELL`); a bright ray crater east (`crater_centre()`, a bowl with a pit,
  `PIT_R`, a low rim; rays: `_rays` built in `_init`, laid on the ground without changing its height, breaking up past
  `RAY_FADE`); frost north of `north_edge` and south of `south_edge` (patchy over `POLE_PATCH`). What the rules look up
  is built in `_init` and `place_parts` (read-only afterwards: the generator's threads share it without a lock);
  `column()` packs height and kind and skips noise nothing can need (`NOISE_MARGIN`); `columns()` is the generator's block
  of them. `SpaceGenerator._write_ganymede_column` writes it (a column's own layers `SUB_DEPTH` deep over the crust's
  water ice: Pluto's `WATER_ICE`). Blocks: page 43, ids 736-747 (`GanymedeBlocks`; 748-751 free). **Built parts**
  (`GanymedeTerrain.place_parts`, called once by `SpaceShape._init` after the pad; written with the colonies' flag,
  `built_at`, `on_part`; `tree_at` keeps their ground): the **Jupiter Lookout** `LOOKOUT_AT` from the pad (a floor of groove
  bricks, a telescope looking east and up, a Jupiter globe, an aurora lamp), the **Aurora Watch** `WATCH_IN` inside the
  north frost's line (a mast, a boom with the magnetometer at its tip), the **ocean drill** `DRILL_DIST` south-west (a
  shaft `SHAFT_DEPTH` deep lined with Europa's deep ice, glow ice at its bottom, a tower over it); the watch's and the
  drill's ground is calm (`PART_CALM`). Secrets: `SpaceSecretRules` (Ganymede's palette; `_fits` keeps them off the
  crater and the parts, `steep_near`; the Solar Wing Lander `_solar_wing_lander`: legs, a gold-foil body, a white deck with
  lamps and the chest, two giant solar wings (Mars's `SOLAR_PANEL`), a magnetometer on a boom, a dish). Sights: the lookout,
  the first grooves south of the pad, the dark terrain west of it, the crater (and its rays), the frost north of it, the
  watch, the drill (all seven on MY MAP, `sight_spots`; the parts' sights before the spawn's clearing: `part_sight`).
- **Its sky shows** (`world/ganymede_sky.gd`, `GanymedeSky`, node "GanymedeSky", the sandbox's `_space_ganymede_sky`):
  the auroras, two belts of curtains over the poles' frost (`BELT_IN`, `BELT_Y`) at night only (NatureSky's night amount),
  drawn by `belt_mesh` (NatureSky's look, ends that dissolve: `END_FADE`) with `NatureSky.star_material()` (no new
  shader), following the viewer east and west, at most `BELT_FAR` away (inside the camera's far plane), rocking `ROCK`
  every `ROCK_PERIOD`; Io and Europa (the descriptor's `sky_planet.moons`, Io first) swung past Jupiter along the circle
  through the east and the west (`swing`, `along_circle`: `IO_SWING`/`IO_PERIOD`, `EUROPA_SWING`/`EUROPA_PERIOD`), drawn
  `NEAR` in front of or behind it, hidden behind its disc (`BEHIND`). It moves `SkyCycle.moons()` from outside SkyCycle.
- **Low gravity:** the descriptor's `gravity` 0.146 (real): a jump floats ~11.6 blocks up for ~5 s; the plain steps one
  block at most, everything else two (`MAX_STEP`).
- **Its sky:** almost no air: `space_sky` 1.0, Europa's palette; the Sun `sun_size` 0.19; Jupiter the sky planet (`size`
  80, `bands`, `spot`) low in the east (`dir`), never moving.
- **The mission:** `MissionRules`' Ganymede row follows the real spacecraft on its way now (swinging past the Moon, Venus
  and Earth, then past Jupiter's moons): 9.4 + 3.5 + 2.1 + 2.5 = 17.5 km/s, almost 12 years (4,260 crew-days), no air;
  the flight's tables (`FlightPlan.REAL_TRIP`, `_JUPITER`; `FlightDials`; `FlightShots.RADIUS_KM`; `FlightLooks.SUN_SIZE`).
- **The smoke run** (`tools/ganymede_smoke.gd`) flies up from a new Green Meadows Sandbox world, taps Ganymede on the Star
  Map (LAND), lands (`sandbox_28`: gravity 0.146, the black sky, a small Sun, Jupiter in the east, Io and Europa, peace,
  no animals, MY MAP's pad and seven sights, the Space Book's mark, Compass and the camp, the lookout, the sky shows, the
  portal home), falls slowly, jumps ~11.6 blocks, stands on the Solar Wing Lander's deck and at the seven sights, turns
  the clock to midnight (the auroras glow over both poles, Io moves), drops into the ocean drill's shaft and jumps out
  (hearts unchanged) and walks home through the portal. Prints `GANYMEDE_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Facts:** every Ganymede fact in the game is listed with its source in `docs/devlog/parts/cosmos-ganymede.md`; keep that
  list when changing one. No mission names (spec §21b.2) and no names of its mapped places: "a spacecraft", "a space
  telescope", "scientists"; the astronomer Galileo Galilei only with his whole name (the spacecraft shares it). The cold
  is a fact, never a danger (`test_the_cold_is_never_a_danger`).

### Colonies under domes on the Moon and Mars (owner #77, spec §21c)
```bash
godot --headless --path . --script res://tools/make_colony_page.gd        # page 31's pixel page (colony.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_colony_realistic.py          # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py dragon colony                          # after --import; then --import again
tools/smoke_all.sh colony                                                # tools/colony_smoke.gd in a private folder
godot --headless --path . --script res://tools/bench_generator.gd -- --space moon mars   # BENCH_COLONY_<P> lines
XDG_DATA_HOME=/tmp/easycraft-colony-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=19 --colony             # pictures of the colony (windowed; 16: the Moon)
```
- **What it is:** terrain, like a planet's landmark: `ColonyLayout` (`world/colony/colony_layout.gd`, pure) is the colony
  as boxes (lo, hi, id; a later box wins) in the colony's own frame (`a` toward the landing pad, `b` across: `world()`,
  `local()`), indexed per 16³ chunk; `write(buffer, origin)` is the generator's fast path, `block_at` its reference.
  `SpaceShape` (the Moon's, Mars's) makes it after the landing pad (`colony`: `ColonyLayout.place`, the candidates and
  `_colony_calm`), flattens the ground under it (`_height_from`, `mars_columns`: `flatten`), grows nothing there
  (`tree_at`), gives Mars's plains there (`mars_kind`) and says its parts as sights (`sight_at`: `part_at`; `sights()`:
  the Great Dome, id `colony`; `is_part_sight`). `SpaceGenerator._place_colony` writes it over the terrain, ores and
  features, under the secrets (`colony_enabled` off: the bench's "plain"). `SpaceSecretRules` keeps the landmark and the
  secrets off its ground (`near_box`); `TheaterSite.pick_for` keeps the Shorts Theater off it (`on_colony`; a site saved
  before is picked again: `stands_on_colony`).
- **Rules:** `ColonyRules` (`world/colony/colony_rules.gd`): the worlds with one (`PLANETS`), the parts (sight ids), their
  names and real facts per planet (`WORDS`: the descriptors' `sights` take them with `with_sights`/`sights`), each planet's
  blocks in it (`PALETTE`), the dome's animals (`HERD`), Tilly's stock (`STOCK`, `with_stock`), the Gold Shop's
  decorations (`DECOR`, `register_shelf`: into the backpack).
- **Animals:** `ColonyAnimals` (the sandbox's node "ColonyAnimals", host and solo, `_start_colony_animals`) brings the herd
  on `ColonyLayout.animal_spots` when a child is within `NEAR` (one a tick, `MAX_SPAWNS_PER_TICK`), sends it away when every
  child is farther than `FAR` (never while no child stands), puts one that wandered out back on its spot, never touches a
  pet. Bees and butterflies: the sandbox's "ColonyInsects" (`MeadowInsects` over the dome's grass).
- **Blocks:** page 31 (ids 544-559, `ColonyBlocks`); the dome glass uses the page extra `{"culls": true}`
  (`BlockLibrary._page_models`: a cut-out that hides the faces between two of it).
- **The smoke run** (`tools/colony_smoke.gd`, a private folder whose path holds "smoke") flies up from a new Green Meadows
  Sandbox world, lands on Mars from the Star Map, finds the colony on MY MAP and the explorer's checklist, stands under the
  Great Dome (its glass, grass and garden in the real terrain, its animals all under the glass, bees and butterflies),
  walks into all twelve parts (each says its fact), times the frames under the dome and far away, taps the lab's bench
  (the Science Lab opens), then lands on the Moon and does the same. Prints `COLONY_SMOKE ok|FAIL …`; exits 0 when all
  passed.
- **Facts:** every fact of the colonies is listed with its source in `docs/devlog/parts/colony-domes.md`; keep that list
  when changing one. No real person's, company's or mission's name (`test_no_real_names_and_never_scary`).
- **Gotcha:** building an animal costs a frame 5-15 ms on this desktop (loaded); spawners near a child build one a tick.
  A player being spawned (`spawn_at`) is not "spawned" for a few frames: player lists (`_player_positions`) are empty
  then, so a rule "no child near: go away" must not fire on an empty list.

### Missions: the Launch Site, the Mission Board, rocket parts (spec §21d, §25.3)
```bash
godot --headless --path . --script res://tools/make_rocket_page.gd        # page 32's pixel page (rockets.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_rocket_realistic.py          # its realistic twin (CC0 ambientCG)
XDG_DATA_HOME=/tmp/easycraft-mission-smoke godot --headless --path . --script res://tools/mission_smoke.gd
tools/smoke_all.sh mission                                                # the same, in a private folder
godot --headless --path . --script res://tools/make_rocket_plans.gd       # owner #98: Mission Control's plans (~20 s)
godot --headless --path . --script res://tools/make_rocket_plans.gd -- --dry --prices 562=5   # try prices, write nothing
XDG_DATA_HOME=/tmp/easycraft-launch-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/launch_shots.gd                                    # pictures of the site and the board (windowed)
```
- **What it is:** every home world (not Monster Wave's arena, not a space world) has a Launch Site
  (`entities/launch/launch_director.gd`, the sandbox's node `LaunchSite`, section "Spec §21d" of `scenes/sandbox.gd`).
  `LaunchSite` (`core/rules/launch_site.gd`, pure) picks it like the Theater (the seed, clear of the Theater, `TIERS`:
  flat open ground, then steeper ground whose trees `clear_changes` removes), stamps the pad (`pad_changes`: the plaza's
  concrete, the pad's ring of stripes, a plinth down to the ground) only when `natural()` finds the world's own ground
  there, and says where the Mission Board is (`near_board`). `WorldMeta.launch_site` keeps `[x, y, z, facing, stamped]`.
  The tower, Mission Control and the board are one vertex-coloured mesh (`LaunchBuildings`). A LAN guest finds the site
  from the seed and never stamps.
- **The board** (`ui/missions/mission_board.gd`): hooks from the sandbox (`read_rocket` = `LaunchDirector.read_pad`,
  `owned`, `have`, `gold`, `buy` = `buy_rocket_part`, `launch` = `launch_rocket`, `route` = `mission_route`, `star_map`).
  `RocketCheck.check(cells, mission, crew, owned)` does the sums (`core/rules/rocket_check.gd`; numbers in
  `core/rules/rocket_parts.gd`, missions in `core/rules/mission_rules.gd`). LAUNCH calls `fly(rocket)` (the plain
  space trip via `mission_arrive` until the flight agent's `RocketFlight` is joined; see the notes' "For the lead").
- **Gold:** parts cost gold in every mode (`RocketParts.PRICES`). Survivor: `Session.gold_spend` and the bag (a guest
  buys in its own world). Sandbox: `Profile.data.survivor_gold` directly (like the School) and `Profile.data.missions`
  (`MissionData`: the parts owned, the missions flown; backed up by `ProfileBackup`).
- **The route:** `MissionRules.route(wonder, flown)`; `SpaceDirector.route` gives it to the Star Map
  (`StarMap.states(…, route)`: `MISSION` for a planet off it; no route = every built world lands, for tools). A tool that
  lands on a planet from the Star Map puts it on the route first (`Profile.data.missions.fly(…)`, the planet smokes do).
- **The smoke run** starts a new Green Meadows Sandbox world (seed 12345): the site and its stamped pad, the Star Map's
  MISSION for the Moon (and Boing's LAND; owner #98: its card and refusal point the arrow to the Launch Site, the
  sandbox's `_on_star_map_body`; MY MAP shows it),
  the board opened by walking up, BUILD IT FOR ME building Mission Control's Moon plan on the pad (it prints the build's
  frames and its slowest write), its check, BUY THE PARTS FOR THIS ROCKET and its card, LAUNCH, the Moon ("Mission
  complete!", the route, the Space Book), HOME (the rocket still on the pad, the Moon's LAND), then a Survivor world
  (the Gold Shop's parts in the bag, the board selling into it). Prints `MISSION_SMOKE ok|FAIL …`.
- **Mission Control's plans (owner #98):** `RocketPlan` (`core/rules/rocket_plan.gd`, pure) holds a table per mission
  and crew of 1-4 (stages from the bottom: engine, engines, tanks; the lander's parts follow from the rules) and lays a
  plan out as pad cells (`cells`, `layout`), says what BUILD IT FOR ME does with what stands on the pad (`diff`: keep,
  place, clear stray parts, blocked by a child's blocks), what a Survivor bag lacks (`bag_short`) and the words. The table
  is written between `# BEGIN PLANS` / `# END PLANS` by `tools/make_rocket_plans.gd` (search in
  `tools/rocket_plans_search.gd`: a Pareto search over the check's own sums, 2-8 stages; run in
  `tools/rocket_plans_maker.gd`, which keeps only what the REAL `RocketCheck` passes with every part bought, one piece,
  9 × 9, ≤ 24 layers, ≥ 0.05 km/s over the need). **Re-run it whenever `RocketParts` (masses, pushes, prices),
  `RocketCheck` or `MissionRules` change**; `tests/unit/test_rocket_plan.gd` fails until you do (it also lists the pairs
  with no plan: Mercury with 3-4 astronauts). After the run the Profile autoload may print SCRIPT ERROR lines about this
  PC's profile: harmless.
- **BUILD IT FOR ME (owner #98):** `MissionBoard.press_build` → the sandbox's `build_rocket_plan` (host only: near the
  board, the gate, no crew call or flight) → `LaunchDirector.build(plan, words, place)`: a job in `_build_step` (16
  cells a frame, a layer every 0.4 s, `say` per stage, waits while `bodies` stand in the build box or chunks load, gives
  up after 30 s). Writes go through the sandbox's `_write_rocket_cells` (Survivor: `Session.gather_ledger` pays per
  chunk; no XP, no undo step). WorldSync carries the blocks to friends.
- **Gotcha:** `MissionData.parts` is a total (owner #98, bug 3): purchases are counted per install (`by`, the key in
  `user://rocket_parts_device.json`) so two devices' parts add up like their gold; buy with `add_part`, never by
  assigning `parts` (a tool's shortcut is overwritten on the next purchase).
- Notes, rulings, the numbers table with sources: `docs/devlog/parts/missions.md`; owner #98's: `docs/devlog/parts/rocket-easier.md`.
### The rocket flight (owner #79, #86, #87; spec §25.3)
The child flies the rocket they built: `RocketFlight` (`entities/flight/rocket_flight.gd`) with its cockpit
(`ui/flight/flight_cockpit.gd`). Notes, rulings and measurements: `docs/devlog/parts/rocket-flight.md`.
- **The interface.** The missions' LAUNCH calls the sandbox's `fly_rocket(rocket)` (their `fly` Callable; the lead joins
  them): RocketStages' description `{"destination", "cells" {Vector3i: id, from the pad's corner}, "stages" [[Vector3i…]
  bottom first], "seats"}` plus an optional `"origin"` (the pad's corner in the world; else 7 blocks in front of the
  child). `RocketFlight.start(rocket, from_world)`, `land(destination, lander = {})` (the landing on its own: the Star
  Map's LAND, the sandbox's `land_on_space`, owner #87), `abort()` (QUIT), signals `landed(destination)` (the sandbox
  then `_travel_space`s) and `ended`. Unknown block ids (the missions' parts, page 32) are drawn in a stand-in look.
- **Pure rules, tested** (`tests/unit/test_flight_*.gd`): `FlightPlan` (the steps per destination, actions, words),
  `FlightRun` (plays them: waits for the child, the autopilot after 5 s), `FlightDials` (the real numbers),
  `FlightSteering` (aim, drift, the autopilot's kind corrections), `FlightShots` (what shows at every moment),
  `RocketStages` (the rocket's stages, seat, nozzles, lander, test rockets), `RocketMesh` (the blocks' mesh, a surface a
  material). Nodes: `RocketBody`, `FlightSet` (the flight's own space far over the world, `SET_OFFSET` y 60,000, its own
  visual layers: the world is not drawn there), `FlightMoments` (light speed, tunnels, asteroids, nebula), `FlightLooks`
  (materials and maps, `planet.gdshader`, `tunnel.gdshader`), `FlightSounds` (the engine's roar,
  `assets/flight/engine_roar.wav` from `tools/make_flight_sounds.py`),
  `FlightTicket` (the developer's test flight and the parked lander, small so the menu can name it).
- **Try it:** the developer menu's **FLY ROCKET** (to WORLD's space world, else the Moon), or on the desktop
  `godot --path . -- --fly-moon` / `--fly=19` / `--land=23` (the Sandbox world; with `--survivor [--universe=N]` the
  Survivor world). The rocket stands in front of the child.
- **Pictures and frame times:** `XDG_DATA_HOME=/tmp/easycraft-flight-shots godot --path . --resolution 1280x720 --script
  res://tools/flight_shots.gd -- --dest=16` (`--landing`, `--style=realistic`, `--no-shots`; headless measures the CPU
  side; `--rendering-method gl_compatibility` before `--path` for the phones' and the web's renderer). It starts a new
  Sandbox world, waits 6 s, flies a test rocket with a child who presses what is asked, writes JPEGs to
  `$XDG_DATA_HOME/flight_shots/` and prints `FLIGHT_FRAMES phase=… frames avg_ms worst_ms over33/50/100
  flight_tick_avg_ms flight_tick_worst_ms`. A copy of this PC's `profile.json` in the folder skips the first-run cards.
- **Smoke:** `tools/smoke_all.sh flight` (`tools/flight_smoke.gd`): the missions' fly, the pause menu, QUIT, a whole flight
  to the Moon (its child flies the descent: owner #106), the lander by the pad, the Star Map's landing on Mercury.
- **Pictures of the worlds:** `python3 tools/make_flight_textures.py [earth moon mars mercury dust noise cloud]`
  (`assets/flight/`; the Earth from `tools/data/earth_mask.png`, Natural Earth, public domain; re-make the mask with
  `--natural-earth <dir>`). Imported lossless with mipmaps (`detect_3d/compress_to=0`).
- **Shaders:** the flight draws two new ones (the planets, the tunnels) and the flame as instanced glow: they are in the
  warm-up's census under the phase `flight`. After the census is written by playing (§7), run
  `godot --headless --rendering-method gl_compatibility --path . --script res://tools/flight_census.gd` again. The flight
  also draws each of its looks once, one a frame, during the boarding's glide.
- **Frame budget rules it keeps:** its first frame loads no world descriptor (FlightLooks copies the air worlds' skies and
  Mercury's Sun; a descriptor load took 360 ms), the big maps load on worker threads (`FlightLooks.poll`/`need`), the
  flight's scripts compile on a worker as the world appears (`sandbox._flight_script`), the set, the moments and the
  cockpit's screens are built a piece a frame over the boarding, fog stays on in the flight's space (no new way of
  drawing at the landing), and the scene changes from the world to space under the clouds' white-out.
- **Gotcha:** on this Linux desktop `DisplayServer.tts_speak` blocks for 55-90 ms (speech-dispatcher): the countdown's
  spoken numbers make 60-100 ms frames here (Android's and the browser's speech are asynchronous).
- **Gotcha:** a `WorkerThreadPool` task whose callable is a GDScript lambda, still held by the pool at shutdown, aborted
  the game at exit (exit 134 after "RIDs of type CanvasItem were leaked"): the roar was made on a thread before; it is a
  file now. `SpaceRules.refusal` with `UniverseRegistry.space_available()` loads every space world's descriptor (290 ms):
  the flight checks only the destination's file.
- **Owner #106: the landing is the child's, a crash has fair costs** (spec §21d.11; notes, rulings and sources:
  `docs/devlog/parts/moon-landing.md`). Every trip ends with `FlightPlan.DESCENT` (action `DESCEND`): `FlightRun` gives
  the throttle to its `FlightDescent` (pure: 120 m at 8 m/s, the world's pull clamped to 1.0-3.71 m/s², the engine 2.5×
  it, fuel from the lander's tanks, safe touchdown ≤ 3 m/s, the zones' colours, words and beeps; the easy first try
  behind a hint card). **There is no autopilot on DESCEND** (`act()` never completes it): a test or tool that flies a
  whole trip must fly the descent too, with `run.test_throttle()` (full for lift-off and burns, `FlightDescent.test_pilot`
  in the descent; never used by the game). A crash replaces the steps after the DESCENT with `FlightPlan.crash_steps`
  (the way home: CRASH, ESCAPE, HOME_ENTRY, HOME_CHUTE in the world beside the pad, WRECK, HOME); `RocketFlight` calls
  its `wreck` hook when the falling rocket hits (the sandbox's `_flight_wreck`: `LaunchDirector.crash_damage(seed)` with
  `CrashRules`, `MissionData.lose_parts` in the Sandbox, `notice_crash` for the board), then sends `crashed(destination)`
  instead of `landed`, puts everything back and frees itself; the sandbox's `_on_flight_crashed`/`mission_crash` stand
  the child at the Mission Board with half the hearts (Survivor, host-decided for the whole crew). `land()` (the Star
  Map's LAND) is a practice (`FlightRun.practice`: a crash tries again, Mission Control lands after 3). In VR the way
  home is a fade cut (the flight jumps to WRECK under a held black). Tests: `tests/**/test_landing_*.gd`,
  `tests/**/test_crash_*.gd`; `tools/smoke_all.sh mission` crashes once, rebuilds and then lands.

### Crew flights: friends fly the rocket together (owner #78, #79; spec §21d.6 phase 2, §21d.9)
```bash
tools/net_test.sh --crew ; tools/net_test.sh --lan --crew ; tools/net_test.sh --crew --drop=close   # two headless games
tests/run_tests.sh -gtest=res://tests/integration/test_crew_flights.gd                                # the flow, a fake session
```
- **Where:** the rules are pure (`core/missions/`: `CrewFlightRules` the words and constants, `CrewCall` the pilot's call,
  `CrewBadges` the badges in `MissionData.crews`); the flow on every game is `CrewFlights` (`ui/missions/crew_flights.gd`,
  the sandbox's node "Crew", made in `_ready` so a guest following its host shows "Landing with your crew…" at once),
  with `CrewCallCard` and `CrewSeats`; the messages are Session's section "Crew flights" (`crew_call` … `crew_welcome`);
  the sandbox's section "Spec §21d.6 phase 2" joins them (`_crew_pilot_fly`, `_crew_fly`, `_lend_chat`, `_crew_credit`,
  `_close_or_move`, `_crew_follow`, `_crew_home`, `_crew_guest_home`). The names `Crew…` without "Flight" in them in
  `core/social/` are the friends' Crews of §25.7: another thing.
- **A crew member's flight** is a RocketFlight with `crew_follow` (set before `start`): it plays the pilot's
  (`follow_pilot(RocketFlight.crew_state())` a few times a second → `FlightRun.follow`), never its own; its `landed` only
  fades (the sandbox ignores it for travel).
- **Moving a hosted world:** `_travel_space`, `_travel_sandbox` and `_travel` call `_close_or_move(u, home)` where they
  called `Session.close()`: with friends coming along it is `Session.crew_move` (the host keeps its match or LAN server,
  holds hellos until `crew_world_ready`), then `Game.start_world(…)` followed by `Game.net_mode = &"host"`; the next
  sandbox sees `Session.crew_moving()` and does not host again. Any new code that changes a host's world with guests in
  it must go through `_close_or_move` (or close the session as before).
- **Gotcha:** a guest's link must not stay open through a world change: the host's next world spawns into a guest scene
  that is not there yet. Guests leave and join again (`Session.crew_follow_leave`, the ordinary join); the host waits for
  them to let go (`crew_guests_gone`) before it switches, or their bodies' last syncs reach its next world ("Node not
  found: Sandbox/Players/<id>/Sync").

### Prospecting on Earth: deposits, Gemma's quests, refining (owner #80, spec §26)
```bash
godot --headless --path . --script res://tools/make_prospect_page.gd      # page 35's pixel page (prospect.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_prospect_realistic.py        # its realistic twin (CC0 ambientCG)
tools/smoke_all.sh prospecting                                            # the smoke (a private folder)
XDG_DATA_HOME=/tmp/easycraft-prospecting-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/prospecting_shots.gd                               # pictures of the camp, deposits, board, well
godot --headless --path . --script res://tools/bench_generator.gd -- --deposits   # the deposits' cost
```
- **Deposits** (`core/prospecting/deposit_rules.gd`, pure, a small cache behind a mutex): each 512 × 512 region of Green
  Meadows (old and wild) holds at most one gold, iron and coal deposit, the Sandstorm Desert's copper, oil and salt
  (`DepositKinds`), sited from the seed and the terrain where real geology puts them, with their sign on top. The
  generators build one (`MeadowsGenerator.deposits()`, `DepositRules.for_world`: null for other terrains) and write its
  cells in `_place_secrets`, before the secrets: ore and signs only over the world's own ground (`GROUND`), AIR only over
  plants. `reference_block` = `deposit_over(x, y, z, _natural_ref(x, y, z))` in the meadows', wild meadows' and desert's
  generators. A deposit: `{id "kind:rx:rz", kind, anchor, spots, signs, lo, hi, cells (by chunk), count, depth_m, drums}`;
  `nearest(kind, from, skip, rings)` gives a quest its target. Never within 128 of the spawn, clear of secrets, mouse
  villages and places.
- **Quests** (`ProspectQuests`: 7 steps from the deposit, the camp and the seed's roll: MAP, CLUE, PROBLEM, QUIZ (School
  exercises), REACH, SIGN (walking), MARK; `SurveyRules`: the echo's depth, the detector's beeps, the map's frame, squares
  and choices). The world's state `ProspectState` in `WorldMeta.prospect` (the quests started, their step, the finds, the
  oil wells' drums); the child's `ProspectData` in `ProfileData.prospect` (backed up: quests done, finds, today's finding
  gold); `ProspectRewards` pays EarnRules' `PROSPECT_QUEST_GOLD` / `PROSPECT_FIND_GOLD`.
- **In the world** (`world/prospecting/`, section "Spec §26" of `scenes/sandbox.gd`, node `Prospecting`):
  `ProspectDirector` (Gemma's camp found on a worker, the walk-up board, the quest's walking steps, the compass's
  `guide`, MY MAP's marks, oil wells, the Metal Detector's beeps, DIG in MORE, the `prospect` action = J),
  `ProspectCamp` (her camp's spot and model), `OilWell`, `ProspectModels` (vertex-coloured boxes, the Theater's material).
  The board: `ui/prospecting/prospect_board.gd` (quests, a step with its ExercisePanel and `ProspectMap` inside the map
  step, walks, MARK IT, the find, MY FINDS); `ProspectPictures` draws the kinds on the board and on MY MAP (`deposit_<kind>`).
- **Refining** (`RefiningRules`: facts, sale prices, `ROCKET_FUEL` = Kerosene): ten recipes in `Recipes.LIST` (panning
  and drying salt by hand, smelting in the Clay Oven, a Refinery at a Workbench, kerosene and plastic at a Refinery:
  `Recipes.REFINERY`, found in reach like the oven by `CraftRules.stations(…, refineries)` and
  `Session.craft_stations_near`); `ShopRules.SELL_PRICES` has the refined five; `GatherRules.NEEDS_TIER` the ores'
  pickaxes. The Gold Shop's Metal Detector: `ProspectGear` (`prospect:detector` on SpendRules' GEAR shelf).
- Notes, rulings, facts with sources, what the lead checks: `docs/devlog/parts/prospecting-earth.md`.
### Prospecting on the Moon and Mars: living off the land (owner #80, spec §26.5)
```bash
godot --headless --path . --script res://tools/make_prospect_space_page.gd      # page 39's pixel page (prospect_space.png)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_prospect_space_realistic.py        # its realistic twin (CC0 ambientCG)
tools/smoke_all.sh prospecting_space                                            # the smoke (a private folder)
XDG_DATA_HOME=/tmp/easycraft-prospecting-space-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/prospecting_space_shots.gd                               # the space camps, deposits, board
godot --headless --path . --script res://tools/bench_generator.gd -- --deposits  # moon, mars with Earth's terrains
```
- **Kinds and places**: `DepositKinds` has the Moon's five (ice, ilmenite, helium-3, KREEP, meteorite) and Mars's five
  (ice, hematite, dark sand, salt, meteorite); `DepositKinds.told_in(u)` is what a board tells (Earth's six, a planet's
  five). `DepositRules.kinds_for(SpaceShape)` gives them; `SpaceDepositSites` sites them on the region's craters
  (`crater_in_cell`) or coarse samples, with a column cache made per placing (`SpaceDepositSites.Cols`: one thread's,
  never shared; DepositRules' region cache keeps its mutex). Never on the colony's ground (`ColonyLayout.near_box`). A
  deposit cell with a negative id stands on the ground (fills air only: a meteorite's lump). SpaceGenerator writes them
  in `_place_secrets` like Earth's; its `reference_block` applies `deposit_over`.
- **Quests**: `SpaceQuests` (the cards and the steps between the map and MARK IT; `ProspectQuests.steps` calls it).
  Gemma's space camp: `ProspectCamp.space_spot` (off the colony, clear of the Theater's building, the landmark, the
  airlock), `camp.space` (her spacesuit). The planet guide's compass asks `ProspectDirector.quest_target` first
  (`scenes/sandbox.gd` `_setup_planet_guide`). A planet's quest map: `ProspectMap.SPACE_SAMPLES` with its craters' cells
  drawn once (`Cols.crater_only`).
- **Living off the land**: three machines in `Recipes` (`MELTER` = the colony's Ice Melter, `OXYGEN_MAKER`, `SOLAR_OVEN`;
  `Recipes.MACHINES`, found in reach by `CraftRules.stations(…, machines)` and `Session.craft_stations_near`), eighteen
  recipes (ice → water → hydrogen fuel / oxygen; bricks, titanium, helium-3, rare earth powder, iron, oxygen in a Solar
  Oven; the rocket's parts stay bought with gold). `RefiningRules`: the facts, `SPACE_FUEL`, `CHAIN` (a find's card
  follows the ice to the fuel), `helps` (what is never sold is for). `ProspectGear`: the Ice Finder
  (`prospect:ice_finder`), the Metal Detector hears meteorites. Page 39: `ProspectSpacePage` (FOUND, MADE).
- Notes, rulings, facts with sources, numbers, what the lead checks: `docs/devlog/parts/prospecting-space.md`.
### Robots and aliens on the planets (owner #86, spec §21f)
```bash
tools/smoke_all.sh creatures                                              # the smoke run in a private folder
XDG_DATA_HOME=/tmp/easycraft-creature-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/creature_shots.gd -- --universe=19                 # pictures, both styles (17: a village)
```
- **What it is:** on every space world the sandbox adds `SpaceCreatures` (node "Creatures", section "Owner #86" of
  `scenes/sandbox.gd`, this game's own, never on a LAN guest): the helper robot by the pad (`HelperRobot`), the rover buddy
  (`RoverBuddy`), the scout drone (`ScoutDrone`), and the aliens' camp (`AlienCamp`, the real bodies) or village
  (`AlienVillage`, Boing and Rainbow). Pure rules in `core/creatures/`: `CreatureWords` (every word and fact: keep the notes'
  facts table when changing one), `RobotRules`, `AlienRules`, `EchoGame`, `CreatureData` (`ProfileData.creatures`).
- **Taps:** `BlockInteractor._tap_space_creature` asks `SpaceCreature.find` (a ray near a creature's middle, within its
  `reach`, never through a block) after the quest givers; the creature's `on_tap` is the director's (a card, a dig, a
  hop). The card is `CreatureCard` (a `QuestOverlay`). A new creature: a `SpaceCreature` with its `tap_height`,
  `tap_radius`, `on_tap`.
- **Hooks** the sandbox gives the director: `ground_y` (`world.find_standing_y`), the player's position and facing, the
  world's secrets' `found` (the quest keeps `creature:*` ids there), the sights, the profile and its save, the HUD's toast,
  MY MAP's `mark`, `gold_changed` (`Session.gold_changed`), `bring_buddy` (`buddy_magic.bring_minis`), `send_home` (frees
  an alien's mini), `avoid` (Tilly's stall, the world's own portal home, the thermometer), the landmark.
- **Alien buddies** are mini-buddies: `MiniRules.MINIS` has `alien_<id>` kinds (their look `AlienModels.mini_boxes` through
  `MagicPetModels`); `AlienRules.befriend` puts the record in `BuddyMagicData.minis`; `BuddyMagicDirector.bring_minis`
  brings only `CreatureData.buddy`'s (`AlienRules.comes_along`).
- **Cost rules it keeps:** a transform is set only when it moves (`SpaceCreature.ease_to`); the ground is read once per
  column a walker reaches; thinking 4 times a second; the robot and the aliens sleep beyond `SpaceCreature.WAKE_R` (64);
  one mesh per model with the animals' vertex-colour material (`CreatureLook`: nothing new to compile).
- **Gotcha:** a timing taken right after the child is moved (a teleport) measures the chunk streaming too (1.0-1.5 ms
  instead of 0.05 ms for the creatures): `tools/creatures_smoke.gd` waits 3 s and takes the best of 5 runs.
- Notes, the facts with their sources, the rulings, frame costs: `docs/devlog/parts/space-creatures.md`.
### Invent it: flight in history's order (owner #78, spec §21e)
```bash
tools/smoke_all.sh inventions                                             # the smoke run in a private folder
XDG_DATA_HOME=/tmp/easycraft-invention-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/invention_shots.gd                                 # pictures: the machines, the book, the banner
```
- **Pure rules** (`core/inventions/`): `InventionLine` (the one table: the story, the science, the people with their
  death years, what it opens, the try, the materials `needs` with `MATERIALS`' "any of these things", the gold, the
  School unit), `InventionRules` (MAKE IT's refusals and taking, the price or the unit, `take_off_craft`, `fly_refusal`,
  `air`, `fuel_factor`, `missions_open`), `InventionData` (`ProfileData.inventions`, merged by `ProfileBackup`),
  `FlightCrafts` (the machines' steps, the kite's lift, the wind), `InventionTry` (the try-its, the bottle rocket).
- **The Player** (section "Owner #78" at the end of `entities/player/player.gd`): `flight_craft` (synced: `FlightLook`
  shows it in every game, `Session.fly_tick` charges its fuel), `chosen_craft` (this game's pick), `wind`, `hold_kite`;
  `set_physics_mode(FLY)` goes through `_take_off_craft` (a kite lifts, never flies) and `_may_take_off`
  (`InventionRules.fly_refusal`, `can_pay_take_off`); `_move_flying` steps a machine with `FlightCrafts.step`;
  `has_glider` is true once the glider is invented.
- **In the world** (section "Owner #78" of `scenes/sandbox.gd`, node `Inventions`, never in the arena):
  `InventionsDirector` (`ui/inventions/`) owns the book (`InventionsPanel`, `InventionPicture`, `BottleRocket`) and the
  try's banner (`TryBanner`, under the HUD's game clock); the sandbox gives it the bag (the host's; a LAN guest invents
  at home), the Workbench in reach (`Session.craft_stations_near`), the wallet, the toast. `mission_gate()` is the
  Mission Board's `gate` and LAUNCH's first refusal. INVENT in MORE (`HudIcons` `invent`), the `inventions` action (I).
- **A new invention line**: its entries in a table like `InventionLine.LINE` (people of history only; the test holds
  their death years), its gates in the rules, its pictures in `InventionPicture`; keep the facts table in the notes.
- Notes, the facts with their sources, the rulings: `docs/devlog/parts/invent-flight.md`.

### Wonders of the World, world 41: the Seven Wonders of the Ancient World (owner #78, spec §24)
```bash
godot --headless --path . --script res://tools/make_wonders_page.gd   # pages 33-34: wonders.png, wonders2.png
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_realistic.py        # their realistic twins (CC0 ambientCG)
python3 tools/copy_page_import.py dragon wonders wonders2                 # after --import; then --import again
tools/smoke_all.sh wonders                                                # or XDG_DATA_HOME=/tmp/…-smoke godot … wonders_smoke.gd
godot --headless --path . --script res://tools/bench_generator.gd -- --wonders
XDG_DATA_HOME=/tmp/easycraft-wonders-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=41 --sights            # pictures of each wonder (windowed)
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=41   # a new Survivor world there
```
- **Earth's own worlds** are numbers 41-60 (`EarthRules`; `UniverseRules.MAX_UNIVERSE` 60; `UniverseRegistry.EARTH`,
  `is_earth`, `earth_available`, `trip_available`). Like a space world they are a trip away (`SpaceRules.is_away`: their
  own slots `sandbox_41` / `survivor_u41`, `WorldMeta.space_home`, the portal home by the landing spot, never scaled, never
  Plus); unlike one they have Earth's gravity, sky, animals and weather. The Star Map's Earth body is `world` 41 with
  `land` "Wonders of the World" (`StarMap.action_words_for`: "Wonders of the World: LAND"); `Sandbox.land_on_space` sends
  an Earth world down at once through `_travel_space` (no rocket landing); `EarthRules.way_there` is the hook for the plane
  (spec §21e).
- **World 41** (`world/universes/wonders.gd`): `WondersShape` (a flat park at `WonderTour.BASE_Y` 32 out to radius 190,
  Green Meadows' own land from 260; the sea north-east of the line x − z = 155 with a 12-block beach; the Lighthouse's
  island and causeway; Giza's sand; trees off the wonders and paths: olives west, palms on sand; `is_river` true on the
  wonders' footprints so every spawner keeps off them), `WondersGenerator` (no caves within 276; sand; flowers; the tour's
  boxes after the trees, before the secrets), `WondersSecretRules` (one secret per wonder with its own `words`; nothing else
  in the tour's areas −3…2). Where each wonder stands and faces: `WonderTour` (seed-free); its blocks: `WonderBuilds`
  (boxes in each wonder's own frame, front toward −z, turned into the world; bucketed per 16 × 16 chunk column once, behind
  a mutex; `block_at` is the reference). Keep a secret's boxes inside its own 128 × 128 area (`test_wonders_secrets`).
- **Blocks:** pages 33-34, ids 576-597 (`WondersBlocks`; 598-607 free for the next tours); the three fakes (limestone,
  marble, Babylon brick) knock open like `FAKE_WALL` and drop their stone.
- **The tour for the child** (the sandbox's section "Owner #78: the world's wonders"): `WondersDirector` (node "Wonders"):
  `WonderSights` (extends `SpaceSights`: a wonder's zone is its blocks' bounds + 3; found ids "sight:<id>" in the world's
  secrets), the passport's stamp (`WonderData.stamp`), MY MAP (the landing spot and seven wonders), the explorer's card
  (`PlanetGuideCard` with the tour's own words), the compass (`compass_target`), floating names (Label3D, the traders'
  look; 32 with the second tour), a plaque's tap (`BlockInteractor.plaque_tapped` → `WonderCard`: facts, QUIZ). The quiz (`WonderQuizView`,
  `WondersPassportRules.answer`) pays `EarnRules.FACT_QUIZ_GOLD` a question right the first time, once
  (`Sandbox._wonder_pay`: Survivor's wallet, the Sandbox's profile).
- **The Wonders Passport** is the Books' WONDERS tab (`WondersPassportPage`, `WonderStamp` draws each stamp);
  `WonderData.wonders` (stamps) and `quiz` (answers) are merged by the backup with OR.
- **Facts:** every word is `core/books/wonder_facts.gd`; each is listed with its sources in
  `docs/devlog/parts/wonders-ancient.md` (keep that list when changing one). Religion as what people believed; people of
  history only; the lost wonders "as people believe they looked"; the Hanging Gardens "no one knows for sure".
- **The smoke run** flies up from a new Green Meadows Sandbox world, taps Earth on the Star Map ("Wonders of the World:
  LAND"), lands (`sandbox_41`: Earth's gravity and sky, animals, peace, the paving under the feet, MY MAP's eight places, the
  director and its names, the explorer's card, the compass, the portal home), reaches the pyramid (its fact and stamp), the
  King's Chamber's granite, knocks open the hidden room (its banner), answers the pyramid's quiz (+10 gold), reaches the
  other six (their stamps), opens the lighthouse's golden chest, sees Earth "You are here!" and HOME on the Star Map, and
  walks home through the portal (the take-off column). Prints `WONDERS_SMOKE ok|FAIL …`; exits 0 when all passed.

### Wonders of the World, world 41: the second tour, the New Seven Wonders (owner #78, spec §24)
```bash
godot --headless --path . --script res://tools/make_wonders_new_page.gd   # pages 36-37: wonders3.png, wonders4.png
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_new_realistic.py        # their realistic twins (CC0 ambientCG)
python3 tools/copy_page_import.py wonders wonders3 wonders4                  # after --import; then --import again
SMOKE_ALL_DIR=<your worktree>/build/smoke-logs tools/smoke_all.sh wonders    # the smoke visits both tours
XDG_DATA_HOME=/tmp/easycraft-draw-smoke godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/wonders_draw_probe.gd                                 # the landing spot's draws a frame (windowed)
XDG_DATA_HOME=/tmp/easycraft-wonders-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=41 --close             # the New Seven up close (windowed)
```
- **Tours:** `WonderFacts.TOURS` / `TOUR_IDS` (`&"ancient"`, `&"new"`), `tour_ids(tour)`, `tour_of(id)`,
  `tour_info(tour)` (name, title, heading, the square's plaque id, the card's words); `ORDER` is every wonder, the first
  tour first (saved stamps, sights, the passport). A wonder's tour decides its square (`WonderTour.square_of`): its path
  and signpost start there. `WonderFacts.called(id)` says a name in a sentence ("the Great Wall of China", "Petra").
  A third tour: add its ids to `WonderFacts` (a `TOURS` entry), its places to `WonderTour.WONDERS`, its builds to
  `WonderBuilds._build`'s match, its secrets to `WondersSecretRules._wonder_secret`; the passport's headings, the guide's
  columns, MY MAP and the sights follow.
- **The region:** round `WonderTour.NEW_SQUARE` (−350, 0) out to `NEW_R` 180, blending into the meadows over `BLEND`
  70 (`WondersShape._column`: whichever designed ground is nearer; the first park's own blend is unchanged), at the end of
  the **Wonders Road** (`WonderTour.road()`: 3 wide along z = 0 from the landing square's edge, of `ROAD_BLOCK` sand, a
  block of the ground's own page so it adds no draw to the chunks it crosses; `road_pads()`: a row of speed pads every
  24 blocks from 198 out, beyond the landing spot's farthest view; a signpost on each square, "… (Wonders Road)").
  **Keep world 41's spawn view light** (the day's slowest world on the emulator): nothing new within 192 blocks of the
  landing spot but the sand road; the plaques' names hide past 60 m; the HUD compass's `compass_target` is a plain loop
  (the compass asks every frame). `tools/wonders_draw_probe.gd` counts the draws before and after a change. `NewSevenGround` is its ground (seed-free
  arithmetic: the Great Wall's ridge under `wall_walk`, Corcovado under Christ the Redeemer, Huayna Picchu behind Machu
  Picchu; `WALL_C`, `CORCOVADO_C`, `HUAYNA_C` are checked against `WonderTour`'s centres by `test_wonders_new_seven`).
  Petra's desert (`WonderTour.PETRA_SAND`), no caves within `WondersGenerator.NO_CAVES_NEW_R`, the secrets' areas
  `WondersSecretRules.NEW_TOUR_AREAS`.
- **Builds:** `WonderBuildsNew` (one static func per wonder on a `WonderBuilds.Frame`; `WonderTour.reach` is the rect a
  build covers past its footprint, e.g. Christ the Redeemer's stair). The walk tests use `tests/fakes/wonder_walker.gd`
  (a memoised child's walk over the builds, secrets and ground).
- **Blocks:** pages 36-37, ids 624-641 (`WondersBlocks.TILES_NEW`, `TILES_NEW_MORE`; 642-655 are the third tour's);
  five fakes (`FAKES_NEW`: wall brick, travertine, Maya stone, Inca stone, white stone). `BlockIds.COUNT` and
  `NEXT_PAGE_FIRST_ID` 656.
- **For the child:** the explorer's card lists both tours side by side (`PlanetGuideCard`'s `groups`); after a stamp,
  how many of its tour are visited and which is next, or where the other tour waits
  (`WondersPassportRules.tour_progress_words`); 32 floating names hidden past 140 m (`WondersDirector.LABEL_RANGE`);
  MY MAP gets the New Seven's square; the passport shows each tour under its heading with its count.
- Notes, the facts with their sources, the rulings, the bench: `docs/devlog/parts/wonders-new-seven.md`.

### Wonders of the World, world 41: the third tour, the Seven Natural Wonders (owner #78, spec §24)
```bash
godot --headless --path . --script res://tools/make_wonders_nature_page.gd   # page 37's rows 1-3 (after make_wonders_new_page.gd)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_nature_realistic.py        # their realistic twins (after make_wonders_new_realistic.py)
SMOKE_ALL_DIR=<a folder with "smoke" in it> tools/smoke_all.sh wonders          # the smoke visits the three tours
XDG_DATA_HOME=/tmp/easycraft-draw-smoke godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/wonders_draw_probe.gd -- --at=nature                     # draws at the nature square (or --at=everest, --night)
XDG_DATA_HOME=/tmp/easycraft-wonders-shots godot --path . --disable-vsync --resolution 1280x720 \
  --script res://tools/space_shots.gd -- --universe=41 --nature               # the seven as a child sees them, the aurora at night
```
- **The region:** round `WonderTour.NATURE_SQUARE` (165, 410) out to `NATURE_R` 230 (its nearest edge 212 out, past the
  landing spot's view), at the end of the **Nature Trail** (`WonderTour.trail()`: dirt, `TRAIL_BLOCK`, 3 wide, straight
  from the landing square at 68°; `trail_pads()` every 24 blocks from 198 out; `trail_signpost(end)`; the paths there are
  dirt too, `NATURE_PATH_BLOCK`). Between the first park and the region the two blends multiply (`WondersShape._column`),
  so the gap the trail crosses stays level.
- **The ground is the wonders:** `NatureGround.sample(x, z)` gives a column's height and kind (land, snow, beach, sea
  floor, canyon, plateau, cinder, lava, mountain, river, chasm, farm, reef, rock, frozen lake, basalt land); the
  generator writes each kind itself (`WondersGenerator._write_nature_column`: the canyon's strata by height from
  `NatureGround.STRATA`, water to the sea level, the river's and the pool's own water tops) and then the decorations
  (`_place_nature`: corn, coral heads in the water, the falls' spray). Its feature centres are copies of
  `WonderTour.WONDERS`' (checked by `test_wonders_nature_ground`). **Keep it cheap:** `WondersShape.nature_sample` keeps
  a chunk column's 256 samples (behind a mutex; the generator asks each column many times), a tree's hash roll comes
  before any ground (`NatureGround.TREES_MOST`), the region's trees look only at its own clearings and paths. Keep
  everything under y 128 (a view of 128 streams y 0-127 from the ground: Everest's top is y 120).
- **Builds:** `WonderBuildsNature` (one static func per wonder: paths, stairs, lookouts, camps, the falls' water
  curtain; `CLEAR`: frame rects where no tree grows). Secrets: `WondersSecretRules` (`NATURE_TOUR_AREAS`; keep a
  secret's boxes in its anchor's 128 × 128 area: tested).
- **Blocks:** page 37's rows 1-3, ids 642-655 (`WondersBlocks.TILES_NATURE`, registered with the New Seven's row by
  `page_37_tiles()`): the canyon's six rocks, the sea fossil, three corals (solid cubes: a see-through block in water
  shows the water's surface round it), cinders, corn (crossed), prayer flags and spray (walk-through, `culls`). Reused:
  Frostpeak's snow, ice and pines, Io's black lava and hot lava, the New Seven's wall brick. `BlockIds.COUNT` stays 736;
  page 43 is free.
- **The sky:** `NatureSky` (a child of the director): the northern lights at night near the valley and a rainbow over
  the falls by day, ribbons of vertex colours with the night sky's star material settings (no new shader); the sandbox
  gives the director `sky_time`.
- **Words:** `WonderFacts` nature entries have `formed` (how nature made them: `when_words`) and the status `NATURAL`
  ("A wonder of nature"; Parícutin's own `status_words`); `TOURS[t].road` and `way` give the clue and the next tour's
  road (`WondersPassportRules`).
- Notes, the facts with their sources, the rulings, the bench and the draws: `docs/devlog/parts/wonders-nature.md`.

### Age rules and grown-up gates: switched off (the owner, 2026-09-29, #69)
- `AgeBand.restrictions` (game) and `AccountRules.ageRules` (server module) are **false**: no age question, every player
  counts as 13+ (`AgeBand.effective`, `AgeBand.unknown`), `GrownUpGate` and the Theater's gate pass at once, the server
  lets every claimed account play online with the filtered chat. The rules' code stays behind them.
- The tests switch them on: GUT runs `tests/pre_run.gd` (`-gpre_run_script` in `tests/run_tests.sh`), the server tests'
  `test/harness.ts` sets `AccountRules.ageRules = true`. `tests/integration/test_no_age_restrictions.gd` and
  `server/modules/test/no_age_rules.test.ts` test the game as it ships. A new check on age belongs behind the switch
  (`AgeBand.effective(band)`, never a bare `== AgeBand.UNDER_13` or an `UNDER_13` default).

- **Block ids and pages:** a block page p holds ids 16 × (p + 3) … + 15. Pages 0-21 hold ids up to 399; ids 400-511 are
  the items' (`BlockIds.RESERVED_FIRST`, `RESERVED_END`: never blocks; `is_block_id`, `is_solid`, `is_valid` refuse
  them; the voxel library keeps empty models there), so block pages go on from 29: Titan's (ids 512-527), Mercury's 30
  (ids 528-543), the colony domes' 31 (ids 544-559), the rocket parts' 32, the wonders' 33-34, prospecting's 35, the New
  Seven Wonders' 36-37, Venus's 38 (ids 656-671), page 39 (ids 672-687) held for another agent's work (2026-09-30),
  Saturn's rings' 40 (ids 688-703), Pluto's 41 (ids 704-719), Triton's 42 (ids 720-735); the next is page 43 (ids
  736-751, `BlockIds.NEXT_PAGE_FIRST_ID`: move it on when a page is taken).
  Gifts carry blocks up to 1023 (`BuildCodec.BLOCK_MAX`, the server's `BuildRules` the same). `test_block_id_space.gd`,
  `test_titan_blocks.gd`, `test_mercury_blocks.gd`.

### School: content, tests and pictures (owner feedback #68, spec §22)
Owner #122, #133, #134 (G0, see "Play G0" below): children **play** a unit where enough of it plays without reading (the
play arena); every other unit keeps LESSON then PRACTICE until a deep game replaces it (docs/design/future-lessons.md
§6: the units are the curriculum map and the Book). What follows is how the School's content is written and checked.
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_school_content.gd      # every written unit and every generator
python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md   # the plan's outline, after a grade file changes
python3 tools/school_from_research.py 4 --all-new             # a grade's subjects from docs/design/school-curriculum-research.md §6
python3 tools/school_from_research.py 4 maths --merge         # add the research's new units, keep the written ones
XDG_DATA_HOME=/tmp/easycraft-school-shots godot --path . --disable-vsync --script res://tools/school_shots.gd -- --unit=g4.maths.angles --exercises
python3 tools/school_audit.py                 # owner #94: every written unit's quality, a table per grade, the weakest
python3 tools/school_audit.py --check         # sizes, letters, spelling and sums without Godot, after editing a unit
python3 tools/school_audit.py --json /tmp/before.json     # keep a baseline; later: --compare /tmp/before.json
python3 tools/school_audit.py --not-yet       # the bar's lists: NOT_YET (any rule) and NOT_YET_VARIED (only the 70% rule)
python3 tools/school_audit.py --flat          # units whose level 3 asks no more than level 1 (rough demand; audit only)
nice godot --headless --path . --script res://tools/school_check.gd -- g5.maths.volume g6.english.pronouns   # or no ids: every unit
```
- **Lesson quality** (owner #94; notes `docs/devlog/parts/lesson-quality.md`): `tools/school_audit.py` scores every
  written unit out of 100 against research §5.3 (cards, reading level, pictures, memory first, "Try it in the world" or
  "Next" last, kinds of exercise per level, hints and worked answers, duplicates, sounds, notes); `--unit`, `--units`,
  `--json`/`--compare` (before and after), `--not-yet`, `--flat`. Since round 3 (2026-10-01) the bar also holds every
  unit to at most 70% choice and true-or-false among its hand-written exercises (`MAX_CHOICE_SHARE`; the ratchet list
  `NOT_YET_VARIED` is empty), and the audit measures each level's demand (the worked answer's reader words, numbers and
  steps, the prompt's words and numbers, items beyond two) and flags a unit whose level 3 asks less than `STEP_UP`
  (1.1) × its level 1 (column "flat"; not a test). `tests/unit/test_school_quality.gd` holds every unit of grades
  3-6 and grade 7's twelve subjects (history, geography and citizenship since round 2; health and PE, D&T and projects
  since 2026-10-17) to the quality bar (its
  `NOT_YET` list only shrank, and has been empty since 2026-10-01: all 645 meet it), and every moving kind of
  `SchoolPictureMotion.KINDS` to a lesson card (an exercise's `"animate": true` only on a picture that moves). The
  audit counts a card's and a sentence's words as a reader reads them (`reader_words`: 1,000, 2.5, 1440s, C4 are one
  word each) and splits a sentence that ends inside brackets or quotes; the bar's hints and worked answers keep
  `words_of` (the test's count). A new unit meets the bar: "Quick memory: …?" first, "Try it in the world: … Next: …" last,
  4-8 cards, a picture (two in maths, science, geography, D&T, computing, art and music), three kinds of exercise, three
  hand-written or a generator at each level, hints of three words or more that never say the right choice, worked
  answers of four words or a worked sum, no body-shape words outside health. The exercise panel shows the worked answer
  after a right second try too, and shrinks the picture (to `MIN_PICTURE_H`) so a long worked answer fits.
  `tools/school_check.gd` (a `--script` shell that adds `tools/school_check_steps.gd` to the tree, so autoload classes
  resolve) runs in seconds what the content test runs in minutes for hand-written content: every unit's loader
  problems, card sizes, pictures, sounds, each exercise right by its own answer only, and every table cell measured with
  the game's font (`SchoolPicture.table_font_size` shrinks a long cell from 22 px to at least 13 px; the check names any
  cell under 17 px). It prints `SCHOOL_CHECK` lines and exits 1 on a problem. Picture kinds of the lesson-quality work
  live in `ui/school/school_picture_quality.gd` (`SchoolPictureQuality`: `inequality_line`, `word_blocks`,
  `sentence_parts`, `coordinate_plane`; samples in `tests/integration/test_school_quality_pictures.gd`).
- **The curriculum is data.** `data/school/grade<N>.json` (grades 3-8) is the outline: its subjects in the order of
  `Curriculum.SUBJECTS` (maths, science, english, history, geography, citizenship, computing, art, music, health_pe,
  design_tech, projects; always the first three; a tab shows once a subject has a written unit); each unit `{id: "g<N>.<subject>.<name>", title, standards, goals, file?}` (at most 18 units a
  subject, a title the stop card fits: `test_every_units_stop_fits_its_card_in_every_grade`). A unit is **written** when it
  names its `file` (under `data/school/`); otherwise the School shows it as "Coming soon" with its goals.
- **A unit file** (`data/school/g<N>/<subject>/<name>.json`): `{id, lesson: [{text, picture?}] (2-8 cards, 260 letters
  each), exercises: [...], generators: [{gen, level}], play?}` (owner #122: the `play` block, see "Play G0" below).
  **An exercise** is `ExerciseCheck`'s form: `type` (`choice`,
  `truefalse`, `number`, `order`, `build`), `prompt` (180 letters), `hint` (200), `explain` (260, the worked answer),
  `level` 1-3, `picture`, and per type: `choices` + `answer` (the index; a choice is text of 48 letters or `{picture}`),
  `answer` (bool), `answer` (a number as text: whole, decimal, fraction, negative; compared by value) + `accept` + `year`
  (true: the pad and the worked answer show `1850`, not `1,850`),
  `items` + `answer` (the indexes in the right order; never shown already in order), `board` + `goal` (`BuildCheck`:
  `count`, `array`, `rectangle`, `fraction`, `mirror`). Write your own words, British spelling (`test_school_content.gd`
  lists US forms), English letters and the font's symbols only (× ÷ − ° ² ³ ½ ¼ ¾ √ π ≤ ≥; no stars, arrows or ticks:
  draw them).
- **Hard history for grown-ups** (research §5.4): a unit in the outline may carry `"hard": "<60 letters>"` (what it
  names: "the Spanish conquest"); the School's grown-ups page lists those units under the subject ("Hard history, told
  with respect and never shown: …"). Grade 6's history marks 7 units; grades 7-8 mark theirs when written.
- **Exercise types** (`core/school/exercise_check.gd` header): choice, truefalse, number, order, build, point, and from
  the research (§5.3) **sort** (groups, items, each item's group), **match** (items, matches, each item's match; 32
  letters a side) and **robot** ("code the robot": `board` for `RobotCheck`, 3-8 squares a side, walls, gems, a flag;
  `max` commands; the answer is a program of F, L and R; the worked answer is a shortest program) and **rhythm** ("copy
  the rhythm": a `sound` of kind rhythm, at most 8 beat boxes; the child marks claps and rests; the pattern is checked,
  never the speed) and **mix** ("mix the colour": a `target` of `ColourMix.RECIPES`; drops of red, yellow, blue, white
  and black; right when their shares match the recipe) and **label** ("label the diagram": a `picture`, `spots` (2-5
  numbered pins, `[x, y]` fractions of `ExerciseCheck.LABEL_BOX` 520 × 250, at least 56 px apart), `labels` (as many,
  24 letters), `answer` (each label's spot, never already in order); `LabelAnswer` shows the picture with its pins on
  the answer side; look at the pins with `tools/school_shots.gd`). Any exercise or lesson card may carry a **sound** (`core/school/school_sound.gd`: a tune
  `{"kind": "notes", "notes": ["C4", "E4", "G4:2", "-"]}` (grade 5: "C4+E4+G4:2" is a chord, 2-4 notes together) or
  claps `{"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}`; grade 6: any sound's `volume` 0.1-1, the amplitude,
  and a tune's `tone`, `SchoolSound.TONES`: "plucked" (the default), "pure", "bright", "hollow"; grade 7: a tune's
  `parts`, 1-3 more tunes `{notes, volume?, tone?}` played together from its start (a melody over a quieter bass, a
  ground bass, a drone, a mix out of balance), and `"-:n"`, n beats of rest), made in code and played by LISTEN. `test_the_sums_in_the_lessons_are_right` computes every plain sum
  a lesson states.
- **Pictures** (`SchoolPicture`, `ui/school/school_picture.gd`): 15 kinds drawn from data (the header lists their fields).
  A new kind: a `KINDS` entry, its `problem()` check, its `_draw_*`, and a sample in `test_school_picture.gd`.
  Grade 3 computing, art and music add **swatches** (paint patches, "red + yellow = ?", patterns of coloured shapes),
  **notation** (crotchets, quavers, rests, bar lines), **melody** (a tune's shape), **robot** (a RobotCheck board drawn as
  RobotAnswer draws it, with a trail) and **marks** (kinds of line, hatching, stippling) in `ui/school/school_picture_arts.gd`
  (`SchoolPictureArts`, samples in `tests/integration/test_school_picture_arts.gd`).
  Grade 4 computing, art and music add 13 more kinds (stave, code, flowchart, network, colour_wheel, shading, face,
  landscape, pixel_art, relief, print, orchestra, glyphs) in `ui/school/school_picture_g4arts.gd` (`SchoolPictureG4Arts`).
  Grade 5 computing, art and music add 27 (pen, var_boxes, sim_frames, packets, search_page, shadow_photo, column_chart,
  sheet, chat, access_feature, perspective, greek_column, greek_vase, mosaic, building, still_life, abstract, dye, comic,
  keyboard, chord_stave, song_form, lifespans, beat_grid, beat_pattern, tracks, waveform) in
  `ui/school/school_picture_g5arts.gd` (`SchoolPictureG5Arts`).
- **A generator** is `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary` in a
  `core/school/gen/g<N>_<area>_gen.gd` whose prefix is a `SchoolGen.SOURCES` line; build exercises with `GenKit`, give each
  a hint, a worked answer and `data` (its inputs), and check its answers against arithmetic done in a test (as
  `test_g4_maths_gen.gd` and `test_g4_more_gen.gd` do; the latter also evaluates every generated "… = ?" equation).
  `test_school_content.gd` runs every generator 120 seeds × 3 levels and wants every one used by a written unit.
- **Grade 3 maths** (owner #70; notes `docs/devlog/parts/m8-grade3-maths.md`): 13 more picture kinds in
  `SchoolPictureG3` (`ui/school/school_picture_g3.gd`: pictogram, bar_graph, jug, dial_scale, ruler, cut_shape,
  unit_squares, side_lengths, fraction_plot, bar_model, digital_clock, times_grid, fraction_wall; samples in
  `tests/integration/test_school_picture_g3.gd`), generators `g3m` (units 1-8), `g3f` (9-12), `g3g` (13-18).
  `test_school_content_g3_maths.gd` also works out every "a op b = c" (and every written column sum) in grade 3's
  lessons, hints, worked answers and questions, hand-written and generated: run it after editing a unit.
- **Rules:** `MasteryRules` (stars, reviews, `UNIT_GOLD`), `RoundPlan` (6 exercises easy to harder), `SchoolData`
  (`ProfileData.school`; its `merge_from` is for the profile backup's merge), `SchoolSpeech` (maths read aloud).
- **UI tests** give the screen its own profile, save hook, day and seed (`SchoolScreen.profile`, `save_profile`, `today`,
  `next_seed`) and `Curriculum.put_content` for a unit's content; `Curriculum.clear_cache()` after.
- **Grade 3 science and English** (owner #70; notes `docs/devlog/parts/m8-grade3-science-english.md`): the research's
  18 + 18 units (§6.3), each checked by `test_school_content_g3_words.gd` (12+ hand-written exercises with a hint and a
  worked answer, levels 1-3, rounds that vary). Generators `g3s` (`G3ScienceGen`) and `g3e` (`G3WordsGen`: word banks
  spelled the same in UK and US English, hand-written wrong choices); `test_g3_science_gen.gd` and
  `test_g3_words_gen.gd` work every answer out again with their own facts and spelling rules. `SchoolSpeech` reads
  "°C" as "degrees Celsius".
- **Grade 3 health and PE, design and technology, projects** (owner #70, #73; notes `docs/devlog/parts/m8-grade3-life.md`):
  11 + 9 + 3 units, checked by `test_school_content_g3_life.gd` (also: memory question first, "in the world" last, no
  weight talk or puberty, the emergency numbers, sounds in dance and the heart unit, nets drawn, a build in every
  project). Picture kinds `net`, `plate`, `lever`, `frame`, `weave`, `stitch`, `pose` (stick figures) in
  `SchoolPictureLife` (`ui/school/school_picture_life.gd`, hooked like `SchoolPictureG5`; samples in
  `tests/integration/test_school_picture_life.gd`). `CubeNet` (`core/school/cube_net.gd`) folds a net by rolling a cube;
  BuildCheck's goal `cube_net {}` ("build a net of a cube", given squares kept). Generators `g3p` (`G3HealthGen`:
  pulse, sleep, claps by ear, food groups and sources, cube nets, a park's area and fence, recipes, map distances, a
  Stone Age camp's kit); `test_g3_health_gen.gd` works every answer out again (its own food tables and 3D cube fold).
- **Grade 4 computing, art and music** (owner #70, #73; notes `docs/devlog/parts/m8-grade4-arts.md`): 11 + 9 + 9
  units, checked by `test_school_content_g4_arts.gd` (also: memory question first, "in the world" last, listening in
  seven music units, colour facts by the wheel, stave answers by the notes' letters, beats by the notes, robot programs
  run, mixes by their recipes, no personal questions, the names' letters ç è é ü in the font). Picture kinds `stave`,
  `code`, `flowchart`, `network`, `colour_wheel`, `shading`, `face`, `landscape`, `pixel_art`, `relief`, `print`,
  `orchestra`, `glyphs` in `SchoolPictureG4Arts` (`ui/school/school_picture_g4arts.gd`, hooked after the grade 3 arts
  kinds; samples in `tests/integration/test_school_picture_g4arts.gd`); grade 3's `notation` gains semibreves, dotted
  minims and `time`, `ColourMix` the tertiary colours (2 : 1) and light and dark grey. Generators `g4a` (`G4ArtsGen`:
  events, IF, variables, robot routes, tables, the wheel, tones, pixels, prints, note values, bars heard, the stave,
  steps and leaps, rounds, ostinatos); `test_g4_arts_gen.gd` works every answer out again (its own interpreter for the
  code pictures, robot, wheel, recipes, stave and round tables).
- **Grade 4 health and PE, design and technology, projects** (owner #70, #73; notes `docs/devlog/parts/m8-grade4-life.md`):
  11 + 9 + 3 units (184 cards, 349 exercises), checked by `test_school_content_g4_life.gd` (also: the safety facts,
  kind health words with nothing about drugs, alcohol or gambling before grade 5, each unit's pictures, the show's tunes,
  a build in every project). Picture kinds `circuit`, `beach_flags`, `food_label`, `pitch` (layouts invasion, rounders,
  court), `site_plan` (orienteering and town plans), `chassis`, `hand` in `SchoolPictureG4Life`
  (`ui/school/school_picture_g4life.gd`, hooked like `SchoolPictureLife`; samples in
  `tests/integration/test_school_picture_g4life.gd`). Generators `g4w` (`G4HealthGen`: 21, from finding space to a
  tune's shape); `test_g4_health_gen.gd` works every answer out again with its own facts.
- **Grade 5 health and PE, D&T, projects** (owner #70, #73; notes `docs/devlog/parts/m8-grade5-life.md`): 11 + 9 + 3
  units (184 cards, 371 exercises), checked by `test_school_content_g5_life.gd` (also: the safety facts, kind health
  words, **tobacco, vaping, alcohol and other drugs only in "Medicines and harmful substances"**, factual, with no
  figures and nothing that invites use (research §5.4 rule 5), each unit's pictures, the dance's claps, the robot
  buggies, the Roman grid's points, a build in every project). Picture kinds `net_court`, `gears`, `pulleys`, `cam`,
  `bridge`, `views` (a block model, its plan, front and side views), `compass`, `food_web`, `lying` (the recovery
  position) in `SchoolPictureG5Life` (`ui/school/school_picture_g5life.gd`, hooked after `SchoolPictureG4Life`; the rules
  they draw by, `gear_turns`, `pulley_turns`, `cam_height`, `front_view`, `side_view`, are tested with the samples in
  `tests/integration/test_school_picture_g5life.gd`). Generators `g5w` (`G5HealthGen`: 35, from a net court's target
  to a fair's profit); `test_g5_health_gen.gd` works every answer out again with its own facts.
- **Grade 5 computing, art and music** (owner #70, #73; notes `docs/devlog/parts/m8-grade5-arts.md`): 11 + 9 + 9 units
  (232 cards, 428 exercises), checked by `test_school_content_g5_arts.gd` (also: listening in eight music units, chords
  and scales by semitones, major or minor by ear, stave letters and beats, marked lines run through loops and
  procedures, spreadsheet formulas, the composers' years, robot programs, no personal questions). `SchoolSound` plays
  chords ("C4+E4+G4:2"). Picture kinds in `SchoolPictureG5Arts` (`ui/school/school_picture_g5arts.gd`, hooked after the
  grade 4 life kinds; samples in `tests/integration/test_school_picture_g5arts.gd`): `pen` runs a program on squared
  paper (`trace`), `sheet` works out its formulas (`value`), `packets` splits a message (`packets_of`), and 24 more.
  Grade 4's `stave` gains quavers, dotted minims and `words`; its `code` gains DEFINE blocks and calls, and a pointer at
  the marked line. Generators `g5a` (`G5ArtsGen`: 25, from a game's variables to a music maker's tracks);
  `test_g5_arts_gen.gd` works every answer out again (its own interpreter, pen, spreadsheet and music facts).
- **Grade 5 maths, science and English: the research's new units** (owner #70, #73; notes
  `docs/devlog/parts/m8-grade5-core.md`): percentages, angles in triangles and quadrilaterals, friction and machines,
  electric systems, how living things reproduce, breathing and the heart, quote to prove it, many sources, opinion,
  explanation and story writing, speaking and presenting (12 units, 96 cards, 210 exercises), checked by
  `test_school_content_g5_core.gd` (also: hundred squares never give the answer, the angle facts' five figures, series
  and parallel circuits, the Lab's circuit words, listening, safety: plants' and animals' reproduction only, no drugs
  outside health and PE). Picture kinds `hundred_square`, `angle_facts`, `circuit_symbols` (with `power`, the ideal-cell
  rule), `force_arrows`, `life_cycle`, `flower_parts`, `lungs`, `blood_loop` in `SchoolPictureG5Core`
  (`ui/school/school_picture_g5core.gd`, hooked after `SchoolPictureG5Life`; samples and rules in
  `tests/integration/test_school_picture_g5core.gd`). Generators `g5c` (`G5CoreGen`: 32, from a hundred square to a
  talk's summary); `test_g5_core_gen.gd` works every answer out again with its own facts and a speech-mark rule checker.

### Play G0: the foundation every game stands on, and the `play` block (owner #122, #133, #134, spec §22.0)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_play_readless.gd,res://tests/unit/test_play_skill_shown.gd,res://tests/unit/test_play_mechanics.gd,res://tests/unit/test_play_block.gd,res://tests/unit/test_play_loop.gd,res://tests/unit/test_play_make.gd,res://tests/unit/test_play_placing.gd,res://tests/unit/test_play_choose.gd,res://tests/unit/test_play_quests.gd,res://tests/unit/test_play_audit.gd
tests/run_tests.sh -gtest=res://tests/integration/test_play_voice.gd,res://tests/integration/test_play_stations.gd,res://tests/integration/test_play_host.gd,res://tests/integration/test_play_screen.gd,res://tests/integration/test_play_budget.gd,res://tests/integration/test_play_vr_hud.gd,res://tests/integration/test_play_games.gd
/usr/bin/python3 tools/play_audit.py               # units by play level (P0/P1) and the reading debt of the hand-written challenges
/usr/bin/python3 tools/play_audit.py --check       # exits 1 when a unit has a type no mechanic knows (there must be none)
godot --headless --path . --script res://tools/play_debt.gd [-- --units]   # the reading debt by grade and subject, generators too
XDG_DATA_HOME=/tmp/easycraft-play-smoke godot --headless --path . --script res://tools/play_smoke.gd   # 102 runs, ~1 min
XDG_DATA_HOME=/tmp/easycraft-play-smoke godot --headless --path . --script res://tools/play_smoke.gd -- --only=types --modes=vr
XDG_DATA_HOME=/tmp/easycraft-play-shots godot --path . --disable-vsync --script res://tools/play_shots.gd -- --only=sort,make_coins
```
**The authority is `docs/design/future-lessons.md`** (owner #133, #134: a future lesson is a deep game a child chooses,
where the knowledge is the only way to win, nothing is read and learning is seen from play; its five tests: choice,
mute, cheat, transfer, wow), over `learning-is-play.md` §5 and §8. G0 is **the foundation** those games stand on, not
the games: the loop, the voice, the demonstration, the place (flat and VR), the bridge to the record, DISCOVER and the
audit. **Never dress a written question as a game, and never build a new unit as cards and a quiz.** Notes and rulings:
`docs/devlog/parts/play-g0.md`.

- **What a child meets:** DISCOVER (the menu's School button) → the map (a stop shows its game's picture, `PlayIcon`,
  only when the unit plays) → a unit's page. A unit **plays** (`PlayHost.plays(content)`: at least 3 of its hand-written
  challenges, or one generator, play without reading; 404 of 818 today): **PLAY** (PLAY: REVIEW) and **THE BOOK** (its
  cards, read aloud, on request) and MY QUESTS. Any other unit **stays in the School as it was** (LESSON, then PRACTICE
  or REVIEW; its Book ends in LET'S PRACTISE!), P0, its reading debt counted, until a deep game replaces it.
- **Rule 0, a child never has to read** (owner #133; `test_play_voice.gd`):
  - *Say:* the hook, every challenge's question, the coach's lines, the world's answer and the hint are spoken at once by
    themselves (`PlayVoice.say` → `ReadAloud.speak`, each cutting in); the big ear (`PlayHud.ear`, 96 px) says the line
    again; a thing says its card's words when lifted, a bin its name (`PlayStation.spoken_name`).
  - *On the screen while a challenge plays:* at most `PlayReadless.screen_words()` (7) words (`PlayHud.screen_words()`):
    the caption (`PlayVoice.caption`: the numbers themselves when they are the question, "300 + 40 + 7 = ?", else the
    mechanic's `say`, "Sort them!"), the count as dots, the buttons as pictures (`PlayGlyph`: eye = SHOW ME, two bars = I
    NEED A BREAK, a triangle = the test, LET'S PLAY and CARRY ON, an arrow = NEXT, a door = STOP; their words in the
    tooltip); every word on a thing in the place a short name (`PlayArena.label_words()`, at most 3 each); the 3D test
    button has no words.
  - *World answers:* no written "Correct!": the place reacts and the voice speaks.
  - *Show:* a new unit's (no stars) first challenge of each mechanic in a round is shown first, once the question has
    been heard (`PlayHost.DEMO_WAIT`): the ghost (finger flat, hands in VR) does one step (`PlayStation.DEMO_DO`: several
    things to place) or shows it over the right things (`DEMO_SHOW`), never where one act answers it (`DEMO_NONE`: Find
    it), then "Your turn!". It still counts. `PlayStation.demo_kind()` says which.
  - *Without a voice* (the device has none for English, or a grown-up turned Read to me off; on by default since
    `ff49983f`): every word shows, as for a reader (`PlayHud.set_voice(false)`).
- **What plays** (`PlayReadless`, limits in `data/play/mechanics.json`'s `"readless"`): a kept mechanic's action (make a
  quantity, sort, order, connect, put labels back, build, code, beat, mix, find), its things pictures, numbers or names of
  at most 3 words, its question at most 16 words. **Shelved:** Choose by doing (a written choice) and Test it (a claim):
  `"status": "shelved"` with its `why`; their stations stay in the code, the loop never routes to them. `why_not(ex)`
  names the reading a challenge needs; `debt(content)` counts a unit's; `content(c)` keeps what plays (plus what a built
  signature game expresses).
- **Layers:** `core/play/` pure rules (`PlayMechanics`, `PlayReadless`, `PlayBlock`, `PlayLoop`, `PlayMake`,
  `PlayPlacing`, `PlayChoose`, `PlayQuests`, `SkillShown`), `entities/play/` the place (`PlayArena`: a `LifeRoom` with
  Life's kit; `PlayStation` and its subclasses, made by `PlayStations.make`; `PlayBoard`; `PlayKit`; `PlayHost` flat and
  VR), `ui/play/` (`PlayHud`, `PlayVoice`, `PlayGlyph`, `PlayIcon`).
- **The referee stays `ExerciseCheck`** (a station turns what the child did into the exercise's own response); the
  record is `SkillShown` (below) → `MasteryRules`.

#### The foundation's API, for the game agents (owner #134)
- **`SkillShown`: what a game saw, into the School's record** (no quiz screens: future-lessons.md §3.5, ruling 3).
  ```gdscript
  var shown := SkillShown.begin()                                  # one per play session
  shown.add(unit_id, SkillShown.SOLVED)                            # each challenge the game judged, as it ends
  shown.add(unit_id, SkillShown.NEW_SETTING, "the bakery at night")   # solved with no help somewhere new: transfer
  shown.add(unit_id, SkillShown.HELPED)                            # after a hint, the ghost or SHOW ME: doesn't count
  shown.add(unit_id, SkillShown.SHOWN)                             # the game showed the answer: doesn't count
  var gold := SkillShown.pay_first_try(Profile.data, today)        # an answer right the first time: the School's gold, capped
  var results := shown.record(Profile.data, today, Profile.save)   # at the end: {unit id: result}, saved once
  ```
  `record` turns each unit's events into a round exactly as `MasteryRules.after_round` counts one (SOLVED and NEW_SETTING
  are "right the first time"): stars, the unit's gold once, the reviews, the grown-ups' page (it reads the same
  progress), a friend's reward (`InviteData`, then `InviteSender.send_soon()` after the save), a proud moment
  (`result.moment`, postcards) and learning together (`SocialSender`). A unit not mastered yet needs
  `MasteryRules.ROUND_SIZE` (6) events to change; fewer (a crystal's minute) count only as a review of a mastered unit
  (`result.recorded` false otherwise). The game decides what one challenge is (a level, a customer, a crystal freed) and
  what "no help" means; its notes say why its events show learning. The School's own rounds and the play arena record
  through `SkillShown.record_round` too.
- **`PlayHost`: a unit's play, anywhere** (the School, the world's Academy and crystals: Play W1):
  ```gdscript
  if PlayHost.plays(content):                              # enough plays without reading
      var host := PlayHost.new()
      host.setup(unit_id, content, seed, stars, Curriculum.unit(unit_id), 4)   # 4: a short round (0: a whole round)
      host.first_try_gold = func() -> int: return SkillShown.pay_first_try(Profile.data, today)
      host.finished.connect(func(o: Dictionary) -> void: (o.shown as SkillShown).record(Profile.data, today, Profile.save))
      host.stopped.connect(...)                            # STOP FOR NOW: nothing recorded (the answers' gold is kept)
      host.open(parent)                                    # the parent's CanvasLayer hides; the place's own camera
  ```
  Its outcome: `{right_first, total, world_task, shown}`. The place is far above the world (`ROOM_ORIGIN`), with its own
  sky; closing gives the camera back. In a world, the caller keeps the avatar still while it is open.
- **`PlayVoice`:** `on()`, `say(text)`, `caption(ex)`. Any game's lines go through `say` (spoken at once while the voice
  is on); its screen keeps to pictures, numbers and a few words (`PlayReadless.words`, `screen_words()`).
- **The demonstration:** a station's `demo_kind()` and `ghost()` (the next step as taps); `PlayHost` runs it. A deep
  game with its own host shows its first step the same way (watch one step, then do), the ghost hands in VR.
- **The place:** a `PlayStation` subclass is a place's moves (`build`, `tap`, `ghost`, `response`, `react`,
  `show_answer`, `spoken_name`, `demo_kind`); `PlayArena` holds one at a time (its targets for the finger, the hands and
  the laser; `glow`; flat views and VR stands).
- **A signature game (a deep game) plugs in** as a `PlayStation` subclass with `static func expresses(ex) -> bool`,
  registered by one entry in `data/play/mechanics.json`'s `"signature"` (`"fraction_bakery": {"name": "Fraction
  Bakery", "script": "res://entities/play/fraction_bakery_station.gd"}`); a unit whose `play.game` names it is P1
  (`PlayMechanics.level`, the audit, the grown-ups' page) and plays every exercise the game expresses (whatever its
  type: a deep game is designed to be played without reading), the rest through the kept mechanics.
  `tests/integration/test_play_games.gd` shows the contract with a stand-in game. A deep game may also be its own scene
  with its own host: then it reports through `SkillShown` and speaks through `PlayVoice`.
- **A deep game with its own host: the registry** (owner #133, #134; built once in the leaf's B2, for every deep game:
  Inside a Leaf first, Balance Altar and Fraction Bakery next; `docs/devlog/parts/game-leaf-b.md` B2.1 and B2.3):
  ```gdscript
  # data/play/mechanics.json: "signature": {"leaf_voyage": {"name": "...", "host": "res://entities/play/leaf/leaf_voyage_host.gd"}}
  var host := PlaySignature.make_host(content)   # the unit's deep game's own host, else G0's PlayHost (a warning for an
  host.setup(unit_id, content, seed, stars, outline, count)   # unknown game or a broken host: never a crash)
  host.first_try_gold = ...; host.finished.connect(...); host.stopped.connect(...); host.open(parent)
  var next := PlaySignature.then_of(outcome)     # the game asks to be opened again ({} none): show_play(unit, next)
  ```
  The host is a **`PlayHost` subclass** (the contract is `PlayHost`'s own face, so the School, DISCOVER's room,
  the world's hold and `menu.gd`'s Back treat it as a round): it reads its params from the unit's play block
  (`PlayBlock.params`), calls `first_try_gold` per challenge solved with no help, and ends with a round's outcome
  (`right_first`, `total`, `world_task`, `shown`, optional `then`). `SchoolScreen.show_play` and
  `DiscoveryDirector._open_place` (Hoot's pick, crystals, the Academy's doors) open it already; also `host_for`,
  `game_of`, `why_not`, `hosts()`, `any_open(tree)`, `with_params`. Tests: `tests/unit/test_play_signature.gd`,
  `tests/integration/test_play_signature_callers.gd` (a stand-in host, `play_signature_host.gd`: copy it for a game).
- **The counts:** `tools/play_audit.py` (play levels; the reading debt of the hand-written challenges; `--check`) and
  `tools/play_debt.gd` (the same by PlayReadless itself, generators included); `test_play_audit.gd` keeps them equal.
  On 2026-10-18: 818 units, all P0; 404 play; 2,402 of 13,559 hand-written challenges play without reading, 11,157
  need reading (written choices 5,922, claims 2,362, long questions 793, words on things 2,080); 777 of 3,387 generator
  entries play.
- **Budgets the tests hold:** every target in `PlayHud.FREE` from the flat view (a 16:9 canvas), carried things and
  their places within 1.1 m of the VR eye (the laser reaches the rest), only the warm-up's shaders (Life's kit; a
  board's face is a copy of the kit's see-through material with the picture as its texture), at most 100 draws at a
  station's heaviest (`test_play_budget.gd`), one light, no shadows, still pictures drawn once, the HUD's words 24 px or
  more on the VR panel, at most 7 words on the screen while a challenge plays. A new station or look runs
  `tools/play_shots.gd` (windowed) and the smoke.

#### The `play` block: how units are written from now (owner #122, design §7)
A unit file may carry a `play` object (`PlayBlock`; checked by `Curriculum.content_problems`, so by the content test):
```json
"play": {
	"hook": "The bakery's pie tins are cut into eighths, and the orders are waiting. Make each fraction with the pieces!",
	"game": "generic",
	"params": {"maker": "fraction", "costume": "give"},
	"coach": ["Same size parts: add the tops, keep the bottom.", "Taking away works the same way."],
	"world_task": "Build a wall 8 blocks long. Colour 3/8 of it red and 4/8 blue. How much is coloured?"
}
```
- `hook` (at most 160 letters): the problem that appears in the place, spoken (owner #133: never on the screen while the
  voice is on); a problem to solve, never a lesson.
- `game`: `"generic"` (the kept mechanics by exercise type: P0) or a deep game's id (P1 once it is listed under
  `signature` in `data/play/mechanics.json`; until then the kept mechanics play what plays without reading).
- `params.maker`: Make it's things for the unit's number answers (`tower`, `base_ten`, `coins`, `fraction`, `frog`,
  `jug`, `scale`, `dial`; used when it can make the answer, else the maker the answer needs). `params.costume`: Choose by
  doing's way (`give`, `path`): kept in the format, unused while Choose by doing is shelved (owner #134).
- `coach` (1-8 lines, each one idea of at most 12 words, from the unit's own checked facts): the first is the see-why
  card after the try; the next follow right answers. No block: one short idea from each card (never the "Quick memory"
  question or the world card), else the unit's first goal.
- `world_task` (at most 220 letters): a real task in the open world. No block: the "Try it in the world" card without
  its "Next:", else "Teach it: show a grown-up or a friend what you found out about …".
- The examples: one unit of every subject in grade 4 (`g4.maths.add_fractions`, `g4.science.circuits`,
  `g4.english.word_parts`, `g4.history.ancient_egypt`, `g4.geography.rivers`, `g4.citizenship.smart_spending`,
  `g4.computing.plan_programs`, `g4.art.colour_wheel`, `g4.music.note_values`, `g4.health_pe.food_labels`,
  `g4.design_tech.wheels_axles`, `g4.projects.river_town`); six of their units play (the other six stay in the School:
  too little of them plays without reading). Write exercises whose act is the concept (rule 1) and that play without
  reading (PlayReadless): a number made with things, a sort, an order, a match, a label, a build, a robot, a rhythm, a
  mix, a point, with pictures, numbers or names of at most 3 words and a question of at most 16 words. Choice and true
  or false are never played (owner #134): they are the reading debt the audit counts.

### Inside a Leaf (Size Magic Voyages, the first future lesson; owner #133, #134)
The design: `docs/design/games/leaf-voyage.md` (approved); the notes: `docs/devlog/parts/game-leaf-b.md` (the pattern,
the cheat bots' numbers, the pictures, the draws, the rulings, the findings). Phase B1 built the rules and the places;
B2 the voyage itself (`LeafVoyageHost`, opened through the registry: below and "The foundation's API"); B3 the desert's
dressing, sounds, music and juice. A unit plays it with `"play": {"game": "leaf_voyage", "params": {"voyage": "5.1"}}`
(`g5.science.plants_air_water`); `--leaf-voyage=5.1|5.T1` makes its PLAY open that voyage.
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_leaf_sim.gd,res://tests/unit/test_leaf_beats.gd,res://tests/unit/test_leaf_run.gd,res://tests/unit/test_leaf_journey.gd
tests/run_tests.sh -gtest=res://tests/unit/test_leaf_cheat_bots.gd        # the cheat test: 1,000 seeded runs a bot, ~3 min
tests/run_tests.sh -gtest=res://tests/integration/test_leaf_place.gd,res://tests/integration/test_leaf_budget.gd
tests/run_tests.sh -gtest=res://tests/integration/test_leaf_host.gd,res://tests/integration/test_leaf_host_vr.gd,res://tests/integration/test_leaf_voice.gd
XDG_DATA_HOME=<private dir> godot --headless --path . --script res://tools/leaf_smoke.gd [-- --modes=flat,vr]   # both voyages by the rule
XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/leaf_shots.gd -- [--only=inside_act1,host_end]
XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/leaf_bench.gd -- [--seconds=5]
godot --path . --script res://tools/leaf_voyage.gd -- --leaf-voyage=5.T1 [--vr-preview]   # play one at once
```
- **The voyage** (`entities/play/leaf/leaf_voyage_host.gd`, a `PlayHost` subclass): `LeafJourney` (`core/play/leaf/`,
  pure: `make(id, seed)`, `start`, `water`, `touch_leaf`, `step(dt)`, `take_cues()`, `stage`: HOOK, DIVE, UNDER, INSIDE,
  RETURN, ANSWER, END; inside it is `LeafRun`) shown in the places; flat: `tap_target(t)` (glide and act),
  `pick`/`screen_of`, `toggle_camera`, `busy`, `waiting_sugar`, keys and a controller (`_step_keys`); VR: `LeafVrHands`
  (`step`, `grapple_to`, `speed`, `hoot`); `stand_at(room, view, blink)`; the record: `_record` at the return (the run's
  events into `shown`, `LeafProgress.finish`), `end_choice(AGAIN|NEXT|BACK|voyage)` emits `finished` with `then`;
  `stop_for_now` keeps the bud. `LeafHud` (`ui/play/leaf/`, a `PlayHud`: `show_end`, `show_board`, `show_camera`;
  `LeafGlyph` its pictures). Its places build a step a frame in the garden (`LeafPlace`/`LeafDive` `staged`,
  `build_step`). The census holds everything it draws as FIRST (`tools/shader_probe_steps.gd`'s phase `leaf`, merged
  with `tools/census_merge.py ... menu`).
- **The rules** (`core/play/leaf/`, pure, seeded; data `data/play/leaf/voyages.json` and `lines.json`):
  `LeafVoyages` (`ids`, `voyage`, `unit`, `unlocked(id, done)`, `rungs`, `weather_kinds`, `lines`, `line`);
  `LeafSim.make(sim)` (`step(dt, weather)`, `toggle`, `set_door`, `open_count`, `standing`, `too_dry`, `waiting`, `take`,
  `deliver(n)`, `bud_full`, `work`; C3 for the sunflower, CAM for the cactus); `LeafWeather.for_voyage(id)` (`at(t)`:
  kind, heat, light, night, `open` (the rule's direction), voiced; `lengthen`, `add_turn`); `LeafBeats.for_voyage(id,
  weather)` (`observe(w, sim, dt)` returns the beats judged, `act1_done`, `help(kind)`, `finish`, `record(shown)`);
  `LeafRun.make(id, seed)` (one voyage inside the plant: `start`, `step(dt)`, `toggle`, `take`, `deliver("gold"|"blue")`,
  `show_me`, `take_cues()` ({say}, {ghost}, {beat}, {weather}, {phase}, {rescue}, {bud_full}), `record(shown)`);
  `LeafProgress.open_at()` (`user://leaf_voyage.json`: `finish`, `keep`, `plant`, `open_voyages`, the journal, `save`);
  `LeafSwimRules` (`step(velocity, pulls, dt)`, `glide`); `LeafSpace.make(setting, seed)` (the layout; `push_out`,
  `free_at`, `clear_line`).
- **The places** (`entities/play/leaf/`): `LeafKit` (the census's vertex-colour materials, the mesh builder, Hoot, the
  Sun: the rooms' `LifeRoomSun`, so the world's suns are put away while a leaf place shows),
  `LeafRoom` (a `LifeRoom` with `flat_views`, `flat_targets`, `hand_targets`, `stand_for`; under the rooms' look it keeps
  its own sky and filmic tone: the default dome hidden, `LeafKit.own_tone`), `LeafPlace(dressing)`
  (`show_sim(sim, weather, dt)`, `set_weather`, `pulse_drops`, `set_lift`, `show_all`; views WORK, UNDER, UP and a VR
  stand per target; targets `door_i`, `door_i_a`/`_b`, `sugar_k`, `gold_pipe`, `blue_pipe`), `CactusDressing`,
  `LeafGarden` (`show_stage`, `set_blocks`; targets `can`, `soil`, `leaf`), `SunflowerModel` (`set_pose(droop, bloom)`,
  `leaf_tip`), `LeafDive` (`pose(p)`, `camera_transform`). Only the census's materials (`test_leaf_place.gd` checks them
  with their instanced flag), one light, no shadows, no words; the draws in `test_leaf_budget.gd`.

### Balance Altar (the second future lesson: algebra; owner #133, #134)
The design: `docs/design/games/balance-altar.md` (approved); the notes: `docs/devlog/parts/game-altar-b.md` (the pattern,
the cheat bots' numbers, the pictures, the draws, the rulings, the findings). Phase B1 built the rules and the places;
B2 adds `AltarTempleHost` (input, camera, the ring's glide, VR, the HUD, the record), B3 sounds and juice.
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_altar_moves.gd,res://tests/unit/test_altar_run.gd,res://tests/unit/test_altar_beats.gd
tests/run_tests.sh -gtest=res://tests/unit/test_altar_cheat_bots.gd       # the cheat test: 1,000 seeded visits a bot, ~1 min
tests/run_tests.sh -gtest=res://tests/integration/test_altar_place.gd,res://tests/integration/test_altar_budget.gd
XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/altar_shots.gd -- [--only=hall,altar]
```
- **The rules** (`core/play/altar/`, pure, seeded; data `data/play/altar/halls.json` and `lines.json`):
  `AltarState.make(lc, lk, rc, rk, x)` (net amounts: negative gems are balloons, negative crystals crystal balloons;
  `holds`, `freed`, `crystal_pan`, `amount(pan, kind)`, `shown_weight`, `clutter`, `key`);
  `AltarMoves` (static: `take`, `add`, `share`, `legal`, `apply`, `legal_ops`, `name_of`; an instance is one altar played:
  `start(state, tools)`, `lift`, `handful`, `place`, `put_back`, `share_by`, `carry_across`, `tap_crystal`, `commit(op, by)`,
  each returning {ok, moved, broke, waiting}; the record `breaks`, `notes`, `ops`, `acts`, `helped`, `helps`, `freed_by`);
  `AltarSolver` (`shortest`, `next_step`, `min_ops`, `budget`); `AltarGen.make(form, rng)` (add, mul, two, sub, subtwo,
  twin; `_R` swaps the pans), `fixed`; `AltarHalls` (`ids`, `room`, `unit`, `tools`, `altars`, `altar_state`,
  `solved_kind`, `cues`, `wings`, `start_stage`, `lines`, `line`, `say(id, {n})`); `AltarRunes` (`tokens`, `line`,
  `say(state, stage)`, `answer_say`, `number_word`; stages PICTURES, NUMBERS, LETTERS, RUNES); `AltarBeats.for_room(id)`
  (`judge(altar, moves)`, `judged`, `right_first`, `masters`, `record(shown)`); `AltarRun.make(room, seed)` (one room:
  `start`, the acts above, `drag`, `show_me`, `hint_no_twin`, `remind_goal`, `next_altar`, `take_cues()` ({altar}, {read},
  {say}, {ghost, demo}, {moved}, {broke}, {freed}, {count}, {judged}, {room_done}), `record(shown)`); `AltarProgress.open_at()`
  (`user://balance_altar.json`: `begin_stage`, `note_altar`, `free_glimmer`, `finish`, the journal, `save`);
  `AltarTwinRules` (`pan_under`, `scoop`, `pair`, `release`, `trigger`).
- **The places** (`entities/play/altar/`): `AltarKit` (the census's four vertex-colour materials, the mesher whose
  triangles face along their normals, the sky dome, cloud puffs, `column`, `halo`, `facing`, Hoot: BlockyAnimal's owl
  in a cap), `AltarRoom` (a `LifeRoom`: `flat_views`, `flat_targets`, `hand_targets`, `stand_for`, `build_ring`,
  `set_active(i, glimmer)`, `set_freed`, `focus`, `show_altar(state, waiting, freed)`, `show_hoot`; its own sky and warm
  tone), `BalanceAltar` (`show_state`, `shown(pan)`, `lifted_count`, `chained`, `glimmer_awake`, `carved_line`,
  `targets()`: `gems_0`, `gems_1`, `balloons_0`, `balloons_1`, `crystal`, `bowls`, `seal`, `bag`, `pump`, `runes`),
  `GlimmerModel.mesh(kind, ASLEEP|AWAKE)`, `TempleHall` (`raise_great`, `set_lit`, `set_door_open`; views `altar`,
  `great`, `wide`, `up`), `SkyRoom` (views `altar`, `wide`), `TempleArrival` (`set_door_open`; views `foot`, `door`). Only
  the census's materials (`test_altar_place.gd` checks every draw with its instanced flag), one light (the place's own
  `LifeRoomSun`), no shadows, no labels (the rune line is carved geometry); the draws in `test_altar_budget.gd` (the
  hall at the chorus 17); every mesh in `test_mesh_winding.gd`.

### The Science Lab (spec §23, owner #74)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_lab_content.gd        # every experiment's data, facts and words
godot --headless --path . --script res://tools/make_lab_page.gd        # page 19 (lab.png): the lab bench
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_lab_page.py               # its realistic twin (CC0 ambientCG)
python3 tools/copy_page_import.py tiny lab                             # after --import; then --import again
XDG_DATA_HOME=/tmp/easycraft-lab-shots godot --path . --disable-vsync --script res://tools/lab_shots.gd [-- --wide]
XDG_DATA_HOME=/tmp/easycraft-lab-smoke godot --headless --path . --script res://tools/lab_smoke.gd   # with a copy of profile.json
```
- **The smoke run** (a new Survivor world): crafts the bench at a Workbench (3 planks, 1 glass, 1 iron), places it, taps
  it (the Lab over the HUD), does float or sink (without supplies the Lab says what it needs; with them the bag gives 1
  planks and 1 stone), checks the Lab Book's star and the book's LAB tab, Android Back, and profile.json. Prints
  `LAB_SMOKE ok|FAIL …`; exits 0 when all passed (`tools/smoke_all.sh lab`).
- **Experiments are data.** `data/lab/index.json` lists them in the Lab's order; `data/lab/<id>.json` is one: id, title
  (24 letters), card (44), units (School unit ids in the outline: TRY IT IN THE LAB on their pages, LEARN MORE), supplies
  (`{block name: count}`, 1-3 ordinary blocks: `LabExperiments.SUPPLY_BLOCKS`), predict (the School's `choice` form, or
  `{type: "sort", prompt, groups: [yes, no], by: "floats"|"magnetic"}` whose items and answer come from the scene's
  things; no hint: a guess is never marked), scene (a kind of `LabModels`: tank, magnet, heat, colours, plants, circuit;
  the header lists their fields), try (140), safety (optional, 140), result (200), why (1-4 cards of 230). Your own words,
  British spelling, the School's letters (the content test uses `test_school_content.gd`'s lists). A fact goes with a
  check in `test_lab_content.gd` (densities, magnetic metals, water's 0 and 100 °C, additive light, seeds, circuits) and a
  line in `docs/devlog/parts/science-lab.md`.
- **A new kind of scene:** a model in `core/lab/` (state, taps, `last`, `done`), its `LabModels.make`/`problem` entries, a
  view in `ui/lab/` (`LabView.make`; big buttons, taps only) and its card picture (`LabArt.card`); new things to draw go in
  `LabModels.THINGS` and `LabThings.draw`.
- **The Lab Book** is `ProfileData.lab` (`LabData`; `ProfileBackup.merge` keeps every star, guess and planting) and the
  book's LAB tab (`LabBookPage`). A plants run's planting (unix seconds) is kept there; a game day is `DayCycle.LENGTH`.
- **UI tests** give `LabScreen` its own `profile`, `save_profile`, `now` and `supplies` (see `test_lab_screen.gd`); every
  page must fit `SchoolUi.FRAME` with buttons of 64 px or more.
- **Grade 4 history, geography and citizenship** (owner #70, #73; notes `docs/devlog/parts/m8-grade4-humanities.md`):
  the research's 10 + 10 + 11 units (§6.4), checked by `test_school_content_g4_humanities.gd` (also: every lesson opens
  with "Quick memory:" and ends "Try it in the world: … Next: …"). Generators `g4h` (`G4HumanitiesGen`: years across BC
  and AD, dated events, Egyptian and Babylonian numbers, map scales, capitals, fieldwork data, gold with decimals, votes),
  checked by `test_g4_humanities_gen.gd` with its own facts. The picture kind **numerals** (`SchoolPictureHistory`,
  `ui/school/school_picture_history.gd`: Egyptian hieroglyph numbers to 9,999, Babylonian wedges in sixties to 3,599)
  has its samples in `tests/integration/test_school_picture_history.gd`.
- **Grade 4 maths, science and English: the research's new units** (owner #70, #73; notes
  `docs/devlog/parts/m8-grade4-core.md`): tables, line graphs and pie charts; circuits, heat and temperature, states of
  matter, sound, digestion and teeth; myths, accounts and evidence, writing an opinion, a report and a narrative (11
  units, 203 hand-written exercises), checked by `test_school_content_g4_core.gd` (also: grade 4's maths, science and
  English have every unit written, the Lab's circuit and melting experiments match their units' lessons, sound is
  listened to, the pictures each unit needs, safety words). Generators `g4d` (`G4DataGen`: tables, line graphs, pie
  charts) and `g4c` (`G4CoreGen`: circuits, conductors, thermometers, heat flow, states, sound waves, the food's path,
  myth phrases, accounts, linking words), each answer worked out again in `test_g4_data_gen.gd` and
  `test_g4_core_gen.gd`. Picture kinds `line_graph`, `pie_chart`, `circuit` (the Lab's bulb, battery and switch;
  `works()` is the complete-loop rule), `thermometer` (lying down on wide cards), `states`, `teeth`, `digestion` in
  `SchoolPictureG4Core` (`ui/school/school_picture_g4core.gd`, samples in `tests/integration/test_school_picture_g4core.gd`).
- **Grade 5 history, geography and citizenship** (owner #70, #73; notes `docs/devlog/parts/m8-grade5-humanities.md`):
  the research's 10 + 10 + 11 units (§6.5: the classical world, the world's grid and climates, democracy and money),
  checked by `test_school_content_g5_humanities.gd` (as grade 4's, and: the Maya and grid pictures drawn, money only in
  gold). Generators `g5h` (`G5HumanitiesGen`: Olympiads, classical years and events, Roman and Maya numbers, latitude
  and longitude, January time zones, 6.5 °C per 1,000 m, resources, an atlas index, trade by sea, elections, budgets,
  simple interest, loans, a class's rubbish), checked by `test_g5_humanities_gen.gd` with its own facts.
  `SchoolPictureHistory` also draws Maya numbers (`numerals` system `maya`: dots, bars and shells in places of twenties
  to 7,999) and the kind **latlong** (the world's grid: lines, places, night, hours from Greenwich, climate bands; no
  coastlines).
- **Grade 6 history, geography and citizenship** (owner #70, #73; notes `docs/devlog/parts/m8-grade6-humanities.md`):
  the research's 10 + 10 + 11 units (§6.6: the medieval world, people and places, maps, climates, rivers, Africa and
  Asia, how a country is run, rights, money and risk), checked by `test_school_content_g6_humanities.gd` (as grade 5's,
  and: each first card names the grade it recalls, a number asking "what/which year" says `"year": true`, the pictures
  each unit needs, no gruesome words or party names). Generators `g6h` (`G6HumanitiesGen`, 28: centuries, three fields,
  years and anniversaries, timelines, al-Khwarizmi's puzzles, caravans, quipus, the harvest after the Black Death,
  density, population change, city growth, job sectors, grid references, contours, map scales, climate graphs, rivers,
  Africa's and Asia's places, layers, government's jobs, seats, arguing well, take-home pay, compound interest,
  insurance, scams, footprints), checked by `test_g6_humanities_gen.gd` with its own facts (and places' names that
  never overlap). Picture kinds `event_timeline`, `quipu`, `feudal_pyramid`, `castle_type`, `dot_density`,
  `city_zones`, `os_map` (grid lines 1 km apart, tenth ticks, contours bunched on a steep side, symbols; `six_figure`,
  `four_figure`), `climograph` (rain bars and a temperature line on matching scales), `river_course` (long profile,
  plan, meander, waterfall), `layer_map` (overlay or stacked sheets), `savings_growth` (`compound`, `simple`) in
  `SchoolPictureG6Hum` (`ui/school/school_picture_g6hum.gd`, hooked after `SchoolPictureG5Arts`; samples in
  `tests/integration/test_school_picture_g6hum.gd`).
- **Grade 6 computing, art and music** (owner #70, #73; notes `docs/devlog/parts/m8-grade6-arts.md`): 11 + 9 + 9 units
  (232 cards, 487 exercises), checked by `test_school_content_g6_arts.gd` (also: memory first, the world and Next last,
  listening in seven music units, no personal questions, every label's line on its part (`SchoolPictureG6Arts.part_at`),
  and the facts by the test's own rules: binary, light, gates and truth tables, programs run by its interpreter (SET
  with expressions, REPEAT UNTIL, IF with AND, OR, NOT), spreadsheet cells, tessellation angles and rotation, major
  scales and key signatures, intervals said, heard or read, the blues scale and 12-bar pictures, the people's years,
  frequencies in hertz). 25 picture kinds in `SchoolPictureG6Arts` (`ui/school/school_picture_g6arts.gd`, hooked after
  `SchoolPictureG6Hum`; samples and facts in `tests/integration/test_school_picture_g6arts.gd`): `bit_cards`, `rgb_mix`,
  `logic_gate`, `computer_parts`, `phish_mail`, `privacy_panel`, `ai_examples`, `art_principle`, `illuminated`,
  `star_pattern`, `ink_landscape`, `tessellation`, `rotation_motif`, `two_point`, `feeling_art`, `print_layers`,
  `stroke_letters`, `letter_guides`, `land_art`, `masterwork`, `key_signature`, `twelve_bar`, `hand_keys`,
  `world_instrument`, `decibel_scale`. Grade 5's `sheet` works out `=AVERAGE(…)` and `=B2/C2` (16-letter cells).
  Generators `g6c` (`G6ArtsGen`: 31, from binary cards to thunder's distance); `test_g6_arts_gen.gd` works every answer
  out again with its own rules.
- **Grade 6 health and PE, D&T, projects** (owner #70, #73; notes `docs/devlog/parts/m8-grade6-health.md`): 11 + 9 + 3
  units (184 cards, 369 exercises), checked by `test_school_content_g6_health.gd` (also: memory first naming grade 3-5,
  the world and Next last, the facts each lesson teaches, kind health words, **smoking, vaping and alcohol only in their
  own unit**, factual, with only the lungs drawn, gold and nothing personal, each unit's pictures, every label's line on
  its part (`SchoolPictureG6Health.part_at`), the CPR beat heard at 100-120 a minute, a build in every project, and the
  pictures' rules worked out again: lever classes, linkages, food zones, a truss's triangles and bars). 18 picture kinds
  in `SchoolPictureG6Health` (`ui/school/school_picture_g6health.gd`, hooked after `SchoolPictureG6Arts`; samples and
  rules in `tests/integration/test_school_picture_g6health.gd`): `lever_class` (effort by `effort_up`, class by
  `lever_kind`, `names: false` for labelling), `linkage` (`linkage_output`), `truss` (`truss_counts`), `struct_force`,
  `biomimicry`, `material_swatch`, `design_style`, `sensor_system`, `threshold_graph` (`on_at`), `breath_box`,
  `control_rings`, `food_thermo` (`zone_of`: freezer −18 °C or colder, fridge 0-5 °C, danger above 5 and below 63 °C,
  hot 63 °C and above), `microbe_split`, `weather_kit`, `access_fm`, `talk_test`, `fast_signs`, `track_field`
  (`jump_length`). Generators `g6w` (`G6HealthGen`: 40, from a pulse to a decision matrix); `test_g6_health_gen.gd`
  works every answer out again with its own facts.
- **Grade 6 maths, science and English: the research's last units** (owner #70, #73; notes
  `docs/devlog/parts/m8-grade6-core.md`): the problem-solving toolkit; skeleton and muscles, nutrition and digestion,
  classifying life, light travels, energy changes, engineering design; read closely, write an argument, to inform and a
  narrative, research and sources, discuss and present (13 units, 104 cards, 234 exercises). Grade 6's maths (18),
  science (17) and English (18) now have every unit written. Checked by `test_school_content_g6_core.gd` (as grade 6's
  others, and: the facts each lesson teaches, each unit's pictures, every label's line on its part
  (`SchoolPictureG6Core.part_at`), the pictures' answers worked out again (a function machine undone, handshakes,
  towers, shadows, reflected angles, energy flows), listening to a speaker's pace and volume, kind body words and no
  substances). 18 picture kinds in `SchoolPictureG6Core` (`ui/school/school_picture_g6core.gd`, hooked after
  `SchoolPictureG6Health`; samples and rules in `tests/integration/test_school_picture_g6core.gd`): `skeleton`,
  `joint`, `muscle_pair`, `food_test` (`colour_word`), `enzyme_cut`, `key_tree` (`key_end`), `kingdoms`,
  `taxon_levels`, `shadow_rays` (`shadow_height`), `reflection` (`angle_of`), `light_device`, `energy_chain`, `sankey`
  (its parts must add up to the total; `efficiency`), `op_chain` (`run`, `undo`; both ends numbers must agree),
  `handshakes`, `argument_map`, `story_arc`, `info_page`. Generators `g6k` (`G6CoreGen`: 43, from working backwards to
  the right chart); `test_g6_core_gen.gd` works every answer out again with its own facts and rules.
- **Grade 7 computing, art and music** (owner #70, #73; notes `docs/devlog/parts/m8-grade7-arts.md`): 11 + 9 + 9 units
  (232 cards, 466 exercises), checked by `test_school_content_g7_arts.gd` (as grade 6's, and the facts by the test's
  own rules: every text program run, what a picture's output panel shows, the line a mistake stops on, lists, linear and
  binary search, bubble sort, the Caesar cipher, example-only IP addresses, copyright's 70 years, colour schemes, scale
  drawings, the rule of thirds, a woodcut's mirrored print, primary chords, cadences heard, ornaments, the bass clef,
  dots and ties, tempo sums, mixes, symphonies, the people's years). **Text code** is the School's own words for the
  kind of text language schools teach first (a Python-like subset, 4 spaces a step in; no language is named):
  `tests/fakes/text_code_runner.gd` is the tests' interpreter (print, =, +=, if/elif/else, for over range or a list,
  while, def with return, lists with append, len, max, min, sum; errors: syntax, name, index, zero, type), and the
  content was also run by real Python when it was written. 27 picture kinds in `SchoolPictureG7Arts`
  (`ui/school/school_picture_g7arts.gd`, hooked after `SchoolPictureG6Health`; samples and facts in
  `tests/integration/test_school_picture_g7arts.gd`): `text_code` (syntax colours, line numbers, a marked mistake, an
  output panel, or the same program as blocks), `list_boxes`, `func_machine`, `search_steps` (`search_checks`),
  `sort_bars` (`bubble_after`, `merge_rows`), `internet_trip` (routes through routers A-F, or a DNS lookup),
  `cipher_wheel` (`caesar`), `data_sheet`, `phone_feed`, `licence_tags`, `old_master`, `colour_scheme`
  (`scheme_colours`), `figure_study`, `world_art_piece`, `poster_layout`, `house_drawing` (`HOUSE`, one bungalow's plan,
  front and side), `thirds_frame` (`on_thirds`, `power_point`), `carved_block` (a block, or a print as it is:
  `print_rows` mirrors a block into its print), `gallery_wall`, `chord_chart` (`chord_name`, `chord_letters`),
  `ornament_signs` (`ornament_notes`), `symphony_plan`, `drum_kit`, `piano_roll`, `film_strip`, `mixer`, `clef_stave`
  (bass, treble or grand; dotted notes, semiquavers, ties; `clef_step`). Generators `g7c` (`G7ArtsGen`: 35, from what a
  program prints to a jig's bars); `test_g7_arts_gen.gd` works every answer out again (programs by the runner).
- **Grade 7 history, geography and citizenship** (owner #70, #73; notes `docs/devlog/parts/m8-grade7-humanities.md`):
  the research's 10 + 10 + 11 units (§6.7: the early modern world, plates, rocks, glaciers, coasts, ecosystems, water,
  the Middle East, Russia, fieldwork, hazards, laws, rights, active citizens, charities, media, the UN, careers, a small
  business, credit, investing, dilemmas; 248 cards, 466 exercises), checked by `test_school_content_g7_humanities.gd`
  (as grade 6's, and: memory of grades 3-6 first, no disputed places or names, gold only in lessons and generators,
  **hard history marked in the outline** (`"hard"`, 60 letters, read by the grown-ups' page) for exactly the five units
  that name it, every new picture kind drawn by a lesson). Generators `g7h` (`G7HumGen`, 43, a SOURCES line after `"g6w"`:
  dates, type, the Pole Star, reigns, Kepler, spices, shares, plates, magnitudes, rocks, glaciers, coasts, biomes,
  water, the Middle East, Russia's time zones, fieldwork averages, the three Ps, bills, speech, petitions, charities,
  facts, cut axes, the Global Goals, careers, profit, credit, portfolios, reasons; a shared `_sorter` builds the sort
  drills), checked by `test_g7_hum_gen.gd` with its own facts (and one test per generator). 17 picture kinds in
  `SchoolPictureG7Hum` (`ui/school/school_picture_g7hum.gd`, hooked after `SchoolPictureG6Health`; samples and rules in
  `tests/integration/test_school_picture_g7hum.gd`): `hand_press` (a press, or mirrored type: `type_order`),
  `voyage_map` (the world's grid or a `window` of it, routes that cross 180°, names placed where they are clear),
  `pole_star`, `columbian_exchange`, `dome_profile` (Ottoman, Mughal), `charbagh`, `sky_model` (Ptolemy, Copernicus,
  Galileo's Jupiter: `bodies`), `family_tree`, `plate_section`, `rock_cycle` (`rock_next`, `process_after`),
  `soil_profile`, `glacial_valley`, `coast_view`, `nutrient_cycle`, `step_chain`, `break_even` (`break_even_items`),
  `cut_axis_bars` (`bar_ratio`). Diagrams label their parts in bands above and below (`_label_parts`: `labels`, `mark`,
  `hide`).
- **Grade 7 health and PE, D&T and projects** (owner #70, #73, #111; notes `docs/devlog/parts/school-g7-dt-hpe-projects.md`):
  11 + 9 + 3 units (184 cards, 380 exercises; every one 100 on the audit), checked by `test_school_content_g7_life.gd`
  (as grade 6's, and: drugs only in "Drugs, risks and the law" with no street names, the dance heard, a build in every
  project, every label's line on its part, and **the Life links**: a unit whose topic is a Life Experience ends by naming
  it in the LIFE tab, each name checked against `data/life/experiences/*.json`, `data/tools/real_builder.json` and the
  Tool Book's tools). Generators `g7w` (`G7LifeGen`, 49, the last SOURCES line), checked by `test_g7_life_gen.gd` with
  its own rules and facts. 14 picture kinds in `SchoolPictureG7Life` (`ui/school/school_picture_g7life.gd`, hooked after
  `SchoolPictureG7Hum`; samples and rules in `tests/integration/test_school_picture_g7life.gd`): `hr_zones` (`zone_of`),
  `shot_paths`, `sleep_dial` (`sleep_hours`), `photo_edit`, `advert`, `influence_map`, `ref_signal`, `schematic` (UK
  symbols, `conducts`), `resistor` (`resistor_ohms`), `micro_board` (`led_at`), `exploded`, `cam_process`,
  `fabric_section`, `eco_home`; `part_at` places label pins on the six diagrams (`RATIOS`: each is drawn in a box of a
  fixed shape, so a pin's line can be worked out from the label box).
- **Grade 8 history, geography and citizenship** (owner #70, #73, #111; notes `docs/devlog/parts/m8-grade8-hum.md`): the
  research's 10 + 10 + 11 units (§6.8: the modern world from 1745 to the digital age, the slave trade and the Holocaust
  told truthfully; climate change, development, globalisation, energy, food, cities, tourism, oceans, map projections,
  GIS; democracies, young people's voice and the law, equality, taxes, budgets, credit, investing, consumer rights, a
  Global Goal in action, technology's big questions; 248 cards, 470 exercises, every unit 100 on the audit), checked by
  `test_school_content_g8_hum.gd` (as grade 7's, and: the quality bar of `test_school_quality.gd` applied to grade 8,
  memory of grades 3-7 first, **hard history marked** for seven units, "murdered" only in the Holocaust unit, no weapon
  detail, living people, brands or today's parties, and **the Life and Success links**: 15 last cards name an
  Experience by its own title in `data/life/experiences/` or `data/success/experiences/`). Generators `g8h`
  (`G8HumGen`, 64, a SOURCES line after `"g7w"`; `_sorter`, `_match` and `_dates` build the drills), checked by
  `test_g8_hum_gen.gd` with its own facts. 10 picture kinds in `SchoolPictureG8Hum` (`ui/school/school_picture_g8hum.gd`,
  hooked after `SchoolPictureG7Life`, reusing `SchoolPictureG7Hum`'s label bands; samples and rules in
  `tests/integration/test_school_picture_g8hum.gd`): `steam_engine`, `greenhouse`, `scatter_plot` (a trend `line`),
  `pop_pyramid`, `tourism_cycle` (`stage_after`), `ocean_zones` (`zone_at`), `projection` (globe, Mercator, Gall-Peters,
  Robinson, north-polar azimuthal, with Tissot's circles: `stretch`, `mercator_y`), `parliament_seats` (`majority`),
  `receipt` (`receipt_total`), `balance_scale` (`tilt`).
- **Grade 8 computing, art and music** (owner #70, #73, #111; notes `docs/devlog/parts/m8-grade8-arts.md`): 11 + 9 + 9
  units (232 cards, 472 exercises; every one 100 on the audit), checked by `test_school_content_g8_arts.gd` (as grade
  7's, and: **the quality bar** through `test_school_quality.gd`'s `bar` (its own scope is grades 3-7), 6 sounds in
  every music unit, the Life and Success links (`LIFE_LINKS`: The Connections Book, Success Stories, the Tool Book,
  Real Builder, Talk & Deal, Calm Corner, The Goal Board), and the facts by the test's own rules: programs run, the
  little machine, ASCII, circuits, queries, nearest votes, stops, the 42 people's years, mobiles, ranges, notes read and
  heard, scales, textures, swing, loops). Generators `g8c` (`G8ArtsGen`, 46, the last SOURCES line: programs of
  functions to chords that fit; helpers start with "_" so SchoolGen does not call them), checked by
  `test_g8_arts_gen.gd` with its own rules. 27 picture kinds in `SchoolPictureG8Arts`
  (`ui/school/school_picture_g8arts.gd`, hooked after `SchoolPictureG7Life`; samples and rules in
  `tests/integration/test_school_picture_g8arts.gd`): `structure_chart`, `step_growth` (`steps_for`), `state_machine`,
  `abstract_map` (`stops_between`), `cpu_cycle`, `sampled_wave`, `gate_circuit` (`circuit_out`), `db_table`,
  `scatter_learn` (`nearest`), `threat_card`, `app_screen`, `light_series`, `brushwork`, `movement_piece`,
  `camera_obscura`, `raster_vector`, `symbol_portrait`, `grid_enlarge`, `object_design`, `flip_frames` (`ball_at`),
  `mobile_balance` (`turning`; `still` draws it level), `gallery_plan`, `wall_label`, `jazz_band`, `instrument_ranges`
  (`range_of`, `pitch_of`), `opera_house`, `swing_beats`; `part_at` places label pins on six diagrams (`RATIOS`).
- **Grade 8 health and PE, D&T and projects** (owner #70, #73, #111; notes `docs/devlog/parts/m8-grade8-life.md`): the
  research's 11 + 9 + 3 units (§6.8: game strategy, fitness testing, active for life, mental health, bouncing back,
  respect online, chance and gambling, alcohol and peer pressure, CPR and defibrillators, a health campaign, digital
  balance; from brief to product, smart materials, a programmable product, mechanical advantage, big structures,
  nutrition, food production, circular design, future technology; an invention expo, a history documentary, a global
  goal campaign; 184 cards, 364 exercises, every unit 100 on the audit), checked by `test_school_content_g8_life.gd`
  (as grade 7's, and: the quality bar applied to grade 8, substances only in "Alcohol, drugs and peer pressure" and
  gambling only in "Chance, gambling and spending", no brands, every new picture kind on a lesson card, and **the Life
  and Success links**: 22 last cards name an Experience by its own title or the Tool Book's tools). Generators `g8l`
  (`G8LifeGen`, 60, a SOURCES line after `"g8h"`), checked by `test_g8_life_gen.gd` with its own facts and rules. 10
  picture kinds in `SchoolPictureG8Life` (`ui/school/school_picture_g8life.gd`, hooked after `SchoolPictureG8Hum`,
  reusing `SchoolPictureG7Life`'s helpers; samples and rules in `tests/integration/test_school_picture_g8life.gd`):
  `fitness_profile` (`weakest`), `feeling_curve` (`pressure_zone`), `chance_wheel` (`chance`, `expected_win`), `cpr_aed`,
  `making_plan` (`plan_end`), `smart_material`, `gear_train` (`train_ratio`, `train_turns`), `block_tackle`
  (`tackle_effort`), `tall_structure`, `circular_loop`. A label exercise's picture may say `"pins": true`: its diagram
  leaves room for the pins (bands on a wide one, side columns on a narrow one: `SIDE_PINS_RATIO`).
- **Grade 7 maths, science and English: the last units** (owner #70, #73, #111; notes `docs/devlog/parts/m8-grade7-core.md`):
  primes and estimates, speed, graphs that mislead; the periodic table, separating mixtures, acids and alkalis, light
  and colour, the air and the carbon cycle; strong evidence, fiction and history, speeches and media, arguments,
  information and narrative writing (14 units, 103 cards, 272 exercises; every one 100 on the audit). Grade 7's 136
  units are all written. Checked by `test_school_content_g7_core.gd` (the quality bar, memory first, the world and Next
  last, `MUST` facts, `DRAWS`, every label's line on its part, the Life and Success links, the pictures' answers worked
  out again, speeches heard, safety: never taste, a grown-up, never mix cleaners, never look at the Sun). Generators
  `g7k` (`G7CoreGen`, 40, the SOURCES line before `g8k`), checked by `test_g7_core_gen.gd` with its own rules and facts. 18
  picture kinds in `SchoolPictureG7Core` (`ui/school/school_picture_g7core.gd`, hooked after `SchoolPictureG8Arts`;
  samples and rules in `tests/integration/test_school_picture_g7core.gd`): `factor_tree` (`prime_factors`,
  `power_form`), `prime_venn` (`venn_parts`, `hcf`, `lcm`), `distance_time` (`leg_speed`), `speed_triangle`,
  `chart_kinds`, `odd_scale` (`drawn_height`), `big_icons` (`looks_times`), `periodic_grid` (`place_of`,
  `school_group`, `element_kind`, `family_of`), `ph_scale` (`ph_kind`, `strength`, `indicator_colour`), `separation`,
  `chromatogram` (`is_pure`, `shared`, `rf`), `light_rays` (`refracted_angle`: Snell's law), `seen_colour`
  (`seen_as`), `carbon_cycle` (`process_from`, `adds_carbon_dioxide`), `air_mix`, `marked_text`, `venn`, `pov_view`;
  `part_at` places label pins on four diagrams (`RATIOS`).
- **Grade 8 maths, science and English: the research's last 14 units** (owner #70, #73, #111; notes
  `docs/devlog/parts/m8-grade8-core.md`): expanding and factorising, sine, cosine and tangent; pressure, energy and
  bills, hot and cold reactions, current and voltage, transport in plants and animals, breeding and genes; the strongest
  evidence, old stories in new versions, arguing, explaining, a narrative, presenting with multimedia (112 cards, 225
  exercises, every unit 100 on `tools/school_audit.py --grades 8`), checked by `test_school_content_g8_core.gd` (the
  bar, the quality bar applied to grade 8, the facts each lesson teaches, nothing about puberty or human reproduction,
  gold and no brands, every new kind on a lesson card, every label on its part, nine Life links, the talk's sounds, and
  the pictures' rules worked out again: the true sine, cosine and tangent, Ohm's law in series and parallel, the
  counter's units, a parabola's crossings, an energy level diagram's change). Generators `g8k` (`G8CoreGen`, 37, the
  last SOURCES line), checked by `test_g8_core_gen.gd` with its own facts (13,320 answers worked out again); a ratio is
  given to 2 decimal places and the answer follows from it. 12 picture kinds in `SchoolPictureG8Core`
  (`ui/school/school_picture_g8core.gd`, hooked after `SchoolPictureG8Life`, reusing `SchoolPictureG7Life`'s helpers and
  label bands; samples and rules in `tests/integration/test_school_picture_g8core.gd`): `parabola` (`parabola_y`,
  `roots`, `vertex`, `equation`), `trig_triangle` (sides named from the marked angle, at the bottom left or the top; a
  ladder or a ramp), `fluid_pressure` (faces, spouts, dam, float), `energy_meter` (`meter_used`), `energy_profile`,
  `meter_circuit` (`reading`: a number on a meter must be its reading when every part has its resistance),
  `plant_transport`, `heart_chambers` (`parts`: the labels or pins it names), `air_sac`, `gene_transfer`,
  `slide_design` (clear or `busy`), `story_order` (`flashback`); `part_at` places label pins on seven diagrams. The
  spelling tests ban "meter" (the US "metre"), so a lesson says "electricity counter"; the kind keeps its name.

### Life: the Life tab, the Experiences, the practice rooms, Life Town (owner #112, #113, #115, #117, #118; spec §27)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_life_experience.gd,res://tests/integration/test_life_rooms.gd   # data + rooms
tests/run_tests.sh -gtest=res://tests/unit/test_life_safe_mistake.gd,res://tests/integration/test_life_room_host_l3a.gd   # #118
tests/run_tests.sh -gtest=res://tests/unit/test_life_l3b_rules.gd,res://tests/unit/test_life_l3b_data.gd,res://tests/integration/test_life_room_host_l3b.gd   # L3b
tests/run_tests.sh -gtest=res://tests/integration/test_life_rooms_l3b.gd,res://tests/integration/test_life_screen_l3b.gd,res://tests/integration/test_life_icons_l3b.gd
tests/run_tests.sh -gtest=res://tests/unit/test_life_l3c_data.gd,res://tests/unit/test_life_l3c_rules.gd,res://tests/integration/test_life_room_host_l3c.gd   # L3c
tests/run_tests.sh -gtest=res://tests/integration/test_life_rooms_l3c.gd,res://tests/integration/test_life_screen_l3c.gd,res://tests/integration/test_life_icons_l3c.gd
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd   # every Experience (L3c: 207 runs), ~18 min
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=electricity,animals,medical
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=online_city,find_way,home_helper   # 35 runs
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=water_safety --modes=mistake,mistake_vr
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=fire_escape.middle --modes=vr
XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=kitchen,calm_corner
XDG_DATA_HOME=/tmp/easycraft-life-town-smoke godot --headless --path . --script res://tools/life_town_smoke.gd   # a real world
/usr/bin/python3 tools/life_review_sheet.py            # the experts' review sheets from the data (life-l1- to -l3c-review.md)
/usr/bin/python3 tools/life_review_sheet.py --check    # exits 1 when a sheet is out of date (after editing an Experience)
```
The design `docs/design/life-skills.md` (Living well; §14 "Dangerous things, learned safely") and
`docs/design/success-skills.md` (Success); the notes and rulings `docs/devlog/parts/life-l1.md`, `life-l2.md` and
`life-l3a.md`, `life-l3b.md`, `life-l3c.md`; the review sheets `docs/devlog/parts/life-l1-review.md`, `life-l2-review.md`,
`life-l3a-review.md`, `life-l3b-review.md` and `life-l3c-review.md` (every source a checkbox: each fact marked for the
expert's review). The
smoke's `--only=` takes skills (`kitchen.big`) or Experiences (`kitchen`), comma-separated; `--modes=` any of flat,
expert, vr, mistake, mistake_vr (the mistake modes run only where a track has safe mistakes to try: each wrong way is
tried once, must freeze the room and cost no hint); a timeout prints the step's state (and the street's cars).
- **Where it shows:** the School's 13th tab, LIFE (`SchoolScreen.show_life`, a `LifeScreen` inside the School's frame), and
  LIFE on the School's grown-ups page (Life's grown-ups' page, past the gate). Life's progress is `ProfileData.life`
  (`LifeData`: the track and its lock, the region, the careful switches, Life units' progress with SchoolData's keys, each
  skill's Passport stamps, runs, before-and-after numbers, repeats and gold); it travels in the backup (its merge never
  loses a stamp) and is sent nowhere else. Step measurements are `user://life_measure.json` (`LifeMeasure`), device-only.
- **The map is data:** `data/life/life.json`: the ten areas (`strand` "living" or "success") and the units: Life's own
  (`life.<area>.<name>`, `file` under `data/life/units/` in the School's unit format, `experience`), the School's own
  (`school: true`, its School id: progress and reward stay the School's), or "coming soon" (`soon`: an Experience not
  built yet). `test_life_catalog.gd` holds Life's own units to the School's bar (a memory question first, "Try it" last,
  4-8 cards, 9+ exercises on three levels, hints, a round of 6).
- **An Experience is data:** `data/life/experiences/<id>.json` (`LifeExperience`'s header has the format): per track its
  steps (LifeCheck's 24 kinds: info, touch, hold, hands, taps, sequence, find, choose, count, action, go, point, rhythm,
  coins, basket, sweep, timelapse, and Life L2's look, cross, rub, pour, breathe, feel, steady; each with `say`, `done`,
  a `view`, `react` / `after` room events, `on_miss` (an event when a miss happens: a car stopping), `goes`, `low`,
  `stand`, `reach` (any / hand / head / trigger), `mode` normal / expert, `glow` false), the Expert try's `twist`, 3-5
  `check` questions, the `name_it` card with its `source`, `try_real`, `can_now` and `sources` (each with a URL). Tokens:
  the region's `{number}`, `{number_words}`, `{number_keys}`, the kerb drill's `{look_order}`, `{look_sides}`,
  `{first_side}`, the street sign's `{speed_limit}`, `{speed_unit}`, `{speed_lo}` / `{speed_hi}` / `{speed_top}`; the
  stall's values (`LifeMoney.stall_vars`); the kitchen's (`"vary": "kitchen"`: `LifeKitchen.vars`: `{recipe}`,
  `{recipe_from}`, `{cut_food}`, `{pour_what}`, `{pour_want}`, `{pour_words}`, `{weigh_what}`, `{weigh_g}`). Choices are
  written right-first; the game mixes them. Choice pictures are `LifeIcons` names (drawn in code: L1's in `LifeIcons`,
  L2's in `LifeIconsMore`, L3a's in `LifeIconsDanger`, L3b's in `LifeIconsHazards`, L3c's in `LifeIconsEveryday`; a new one
  is a `NAMES` entry and its drawing in one of them, never a `ToolIcons` name). Life L3b's token: `{wild_where}` (the
  region's wild animals out walking, `LifeRegion.wild_words`); Life L3c's: `{metro_where}` (the region's own metro:
  Tbilisi's two lines meeting at Station Square, `LifeRegion.metro_words`) and `{bins_where}` (the region's recycling
  bins, `LifeRegion.bins_words`). A pour step's `unit` "soil" says how damp a plant's soil is.
- **Real motions and devices (owner #117, design §13):** a hands-on step names its `motion` (one of `LifeCheck.MOTIONS`:
  strike, stroke, twist, squeeze, press, spread, measure, pour, aim, cut), its `tool` and its `device` (an entry of the
  Experience's `devices`: controls, shows, order, safety). Data only: the shared recogniser and device model (round 4b)
  will read them; Life's rules never do, so they take over without a rule changing. A new step that uses its hands names
  its motion (`test_every_hands_on_step_names_its_motion`).
- **A new Experience:** its JSON, a room (`LifeRoom` subclass in `entities/life/`, made by `LifeRooms.make`: targets,
  views with VR spots, `on_event`, `progress`, `step_done`), its id in `LifeExperience.IDS`, its units in `life.json`.
  The room tests then check that every target and view exists, that **everything to tap is in the screen's free band
  from its view** (the coach's bar and the bottom controls left out) and that **everything to touch is within a child's
  reach in VR**, and that every material and sign is a shader the warm-up already holds (`LifeRoomKit` only makes those:
  `AvatarParts.material`, the mirror wall's see-through settings, the animals' billboard tags). Add it to the smoke's
  runs (they follow `LifeExperience.IDS`) and regenerate the review sheet.
- **Flat and VR:** `LifeRoomHost` turns fingers (flat) or hands, the laser and the head (VR) into one `LifeCheck` sample a
  frame ("the hand is here and squeezing", never a button: VR round 4's shared grab can feed the same samples); the
  room sits at `LifeRoomHost.ROOM_ORIGIN` (1.5 km above the menu's world) with its own environment; the screen it came
  from hides while it shows. No editor scene files: rooms are built in code (`LifeRoomKit`).
- **The rooms' look (2026-10-18, `docs/devlog/parts/rooms-look.md`):** every practice room is a real place. A room
  builds its dressing through `decor()` (`LifeRoomDecor`: tiled floors and walls in the block pictures, windows,
  skirting, rugs, plants, shelves, lamps, pictures, fences, benches, trees, bushes, houses, a town square, the sky dome;
  drawn as one mesh per material, about four draws) and its static furniture with LifeRoomKit's usual calls under
  `scenery()` instead of `self` (merged after `build()`; whatever the room holds in a property, every target, scripted,
  hidden, see-through or glowing things stay nodes). Its own sun (`sun()`, the world's put away while it shows),
  `nightfall(on)` for a night, ACES tone. People and moving things in few meshes with `LifeRoomPeople`: `merge_person(b,
  rigid)` (rigid only if its pose never changes again), every face change through `LifeRoomPeople.feel(b, feeling)`
  (and `redraw(b)` after recolouring), `merge_dog(dog, still)`, `merge_parts(room, node)` (a moving thing's own boxes),
  `merge_whole(node)` (a thing that never comes apart: a bottle and its sign). Words draw within `LifeRoom.WORDS_SEEN`
  (25 m), a phone held up within 4 m. **The look test holds every room** (`tests/integration/test_room_look.gd`): a
  real floor under the child, signs never over name tags, heads whole under the HUD's bar, nothing within 0.5 m across
  the first view's middle, no words cut (or half under the bar unless a target's own), no dressing on a target, a view's
  line, a VR reach or where the child stands, and **at most 66 of the room's own draws from any VR stand, any of four
  ways** (the HUD and the hands take the rest of the Quest's 100). `ROOM_LOOK_ONLY=<id>,<id>` runs only those rooms,
  `ROOM_LOOK_DRAWS_LIST=1` lists the heaviest stand's draws. Pictures and draws per room: `tools/room_shots.gd` (its
  header: windowed, under `nice`, `--vr`, `--style=realistic`, `--only=`, `--play`). A new room is dressed the same way
  and joins the test by being in `LifeExperience.IDS`.
- **Tests** give `LifeScreen` its own profile, save hook, day, seed, locale and `LifeMeasure` path; the host is driven
  with `finger_down(host.screen_of(target))` or `Vr.simulate` and `Vr.sim_hand` / `sim_head` / `sim_input`. **Wait for
  the state, never a count of frames** (a busy PC flaked L1's host test): `_taken()` (the host sampled the input) and
  `_next_started(before)` (the next step began) in `test_life_room_host*.gd`, `wait_until` with a few seconds at most.
- **Life L2's rooms:** `StreetRoom` (its scripted traffic is `LifeTraffic`: the cars' own models and engine loop, the
  region's side, bunches with a real gap, `stop_for_child`, the button crossing, `turn_red`; `safe_now(step)` answers a
  cross step), `KitchenRoom`, `CalmRoom` (the buddies' `LifeBuddy.face(feeling)`). In VR a crossing and the practice
  car's pedals are the trigger itself (reach `trigger`): a laser straight ahead to a far target crosses the HUD's tray.
- **Life Town** (`LifeTown`, `LifeTownBuildings`, `LifeTownDirector` node "LifeTown" of the sandbox, `LifeTownPanel`):
  placed like the Launch Site (`WorldMeta.life_town`, the host's natural check and its places' trees cleared once), six
  places as models; walking up opens Life on the place's unit (`LifeScreen.town_experience`); while a room from it shows
  the avatar is held (`_life_take_over`) and kept safe. Android Back inside any practice room belongs to the room ("Leave
  the practice?": `LifeRoomHud.open_leave`; the menu asks `LifeRoomHost.any_open` first).
- **Safe mistakes (owner #118, Life L3a; design §14):** a step's `safe_mistake` {wrong, try, event, icon, why, right}
  lets the child try the wrong way: `try` is a room target, "action:stand" (VR: the head coming up after being low; flat:
  the HUD's STAND UP picture) or one of `LifeCheck.ACTIONS`, or on a picture step the choice marked `"mistake": true`
  (`LifeCheck.tries_mistake`; without a try it is only shaped, like Real Builder's). LifeCheck says `mistake` (never a
  miss; LifeRun counts a hint only on the Expert try), and `LifeRoomHost.freeze_for` freezes the room (`LifeRoom.freeze`:
  its process and tweens), softens the scene over `FREEZE_FADE` (flat: the HUD's veil; VR: `Vr.set_dim(MISTAKE_DIM)`), shows
  the room's still picture (`show_mistake` → the room's `on_mistake(event, on)` under `mistake_holder()`) and the HUD's card;
  GOT IT (`hud.mistake_ok` → `unfreeze`) goes on. **Never on the Little track** (`LifeExperience.problems`). A room must
  draw every event its steps' safe mistakes name (`test_life_rooms_l3a.gd` and `_l3b.gd` check each comes and goes).
  Life L3b: `try: "unsafe"` (`LifeCheck.UNSAFE`) is **the right target at the wrong moment**: the step's own target pressed
  while the sample's `safe` is false (a cross step: the room's `safe_now`; a tool step with `safety`: ToolRoomHost says so
  when the gear is off). Only on a cross step or a step with `safety` (LifeCheck.problem). And the body action `"tree"`
  (be a tree: flat the BE A TREE button; VR `LifeRoomHost._tree_pose`: the view looking down past `TREE_LOOK_DOWN`, both
  hands `TREE_HANDS_LOW` under the head and within `TREE_HANDS_IN` across, still); running from a dog is a place in the
  room (`run_away`), so the same `try` rule tries it.
- **Danger moments, `within`, `not`:** a step with `danger: true` runs the room's own time at `LifeRun.time_scale(runs,
  expert, more_real)` (0.5 on the first two tries, 0.75 later, 1.0 on Expert or "more real"); rooms move their simulation
  by `sim_delta(delta)`; `within` (s of the room's time, the sample's `room_dt`) and `late` make a slow action a kind miss;
  `not` {target: words} makes a harmless wrong tap a kind miss. `glow: false` hides the glow on any kind (SHOW ME still
  shows); an action's `button` and a basket's `label` / `unit` / `pay` are the HUD's words.
- **Intensity and the debrief:** `LifeData.intensity` (GENTLE / REAL, merged like the careful switches) reaches only the
  Big track (`intensity_for`), set on the grown-ups' SAFETY tab; rooms read `more_real()` and stay modest (stronger, never
  new or scary). An Experience with `"emergency": true` gets the DEBRIEF page before its name-it card (and its words on the
  calm page). `LifeScreen` passes the intensity and the skill's finished runs to `LifeRoomHost.setup`.
- **Life L3a's rooms:** `WaterRoom` (the pool, the beach with its rip, the winter pond), `PoisonsRoom` (the kitchen with the
  GHS's red diamonds and the child lock, the garage, the hall's CO alarm at night), `EarthRoom` (the practice room's strong
  table, the garden's open ground, the park's storms and heat, the flooded path, the woods, the bag shelf, the playground);
  their pictures in `LifeIconsDanger`.
- **Life L3b's rooms:** `ElectricRoom` (the practice house's bath corner, sockets, frayed lamp cable, toaster and window
  with the lines outside; Big's hall fuse box with its main switch and RCD; Middle's park with its poles, open field, tree
  and substation; Big's storm path with the fallen line, the safe place 10 m off and Mo), `AnimalsRoom` (the park with
  Biscuit and his owner, a sleeping dog and a loose one that runs up by the room's time and stops short; Middle's dog park
  with three dogs whose places vary with the seed, the warning one's four signs as targets of their own for one step; the
  farm's horse and cows; the picnic's bee and wasp; the hills with the snake, Big's group, bear, fox, flock and guard
  dogs), `LifeDog` (a blocky dog facing +X: moods relaxed, warning, play, sleep, sniff, uneasy; marks body, eyes, lips,
  tail, side, head, neck, nose), `MedicalRoom` (Middle's bench with Bobo's nosebleed, Kiki's chair and the trainer
  inhaler's table; Big's floor mat for the seizure with the hard things, the cushion, the spoon and the stopwatch; the
  playground; the picnic with Mo's allergy signs and the trainer pen's table and practice pad). The Kitchen and the
  practice house grew L3b's corners in their own data and rooms (the pan fire, the lid and the water jug; the play mat's
  small things; Bobo's scald; Gus for Little's matches; the campfire). Their pictures in `LifeIconsHazards`.
- **Life Town's second row (Life L3b):** the plaza runs to `PLAZA_MAX` (12, 14): the second row nearest the spawn
  (`SECOND_ROW_Z` 9, fronts and doors facing the spawn, 3.7 m apart): power, pets, firstaid, and Success S2's goals, talk,
  village, stage (`LifeTownBuildings._second_row`). Every Experience has its place (`test_life_town.gd`); 7 of 8 real
  meadows still get their town. A next wave: a third row or a second plaza (the search's radii shrink as the town grows).
- **Life L3c's rooms:** `OnlineRoom` (the practice living room, Gus, and the play tablet: one pretend page at a time, a
  step's `page` and the news step's `headline`; its chats' BLOCK and REPORT, the pop-ups' X), `FindWayRoom` (the market
  with the safe grown-ups and the man who says "come with me", standing where he is; the school's fire drill; the metro's
  map, gates, platform, train (by the room's time) and help point; the park's compass, map and flags), `HomeHelperRoom`
  (the laundry, the bedroom, the kitchen's bins, table and dishwasher, the plant, Biscuit, the hall's practice smoke
  alarm); their pictures in `LifeIconsEveryday`. **A device held in the hand** (`LifeRoom.held`, `holding`, `held_rest`,
  `hold_pose`, `is_held_target`, `rest_held`): once held, `LifeRoomHost._hold_device` keeps it in VR's off hand (the hand
  that doesn't point), its face to the eyes; that hand never presses its own buttons; flat (and when the headset comes
  off) it rests at `held_rest`. The smoke checks it stays in the hand every frame it is held, and that a run trying no
  wrong way never freezes.
- **Life Town's third row (Life L3c):** `PLAZA_MAX` (12, 18), `THIRD_ROW_Z` 15: online, wayfinder, helper in front of the
  second row (`LifeTownBuildings._third_row`), doors 5 m apart facing the spawn; the search also keeps the plaza's whole
  edge clear of the Theater (its empty corners). 6 of 8 real meadows get their town (one fewer than L3b's). A next wave: a
  second plaza (another row costs more meadows).
- **The second plaza (Success S3, owner #115):** the Market Square beside the town (`MarketPlaza`), placed by
  `LifeTown.pick` with its own layout and the town's site (the search, the natural check, the tree clearing, the doors and
  walking up all take a `layout`; the town's own default is unchanged), stood by the director's `MarketPlazaPlacer` and
  saved with the town (`WorldMeta.life_town`: four numbers, then four more). A further wave can be a third plaza the same
  way (a layout, beside the town, `TOWN_GAP` from it); see "Success S3" below.

### Tools: the ten motions, the device run, the Tool Book, Real Builder (owner #116, #117, #118; spec §27.3)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_tools_motion.gd,res://tests/unit/test_real_builder_data.gd   # rules + data
tests/run_tests.sh -gtest=res://tests/integration/test_real_builder_site.gd,res://tests/integration/test_real_builder_host.gd
XDG_DATA_HOME=/tmp/easycraft-real-builder-smoke godot --headless --path . --script res://tools/real_builder_smoke.gd   # 9 runs, seconds
XDG_DATA_HOME=/tmp/easycraft-real-builder-smoke godot --headless --path . --script res://tools/real_builder_smoke.gd -- --runs=big.vr
/usr/bin/python3 tools/real_builder_review_sheet.py           # the experts' review sheet (docs/devlog/parts/tools-r4b-review.md)
/usr/bin/python3 tools/real_builder_review_sheet.py --check   # exits 1 when it is out of date (run it after editing the data)
```
The design `docs/design/life-skills.md` §13 (one method for every real skill) and §14 (#118: safe mistakes); the notes and
rulings `docs/devlog/parts/tools-r4b.md` (with the lead's hooks into Life).
- **The engine is shared:** `ToolMotion` (the ten motions; `ToolMotion.ALL` is the one list, equal to `LifeCheck.MOTIONS`;
  `CHECKS` their numbers, `HOW` their words), `ToolSample` (a held tool's tip in VR or a finger's ray flat, as one sample in
  the work's frame: x along the work, y out of its surface), `ToolDevice` (Life L1's device data at run time: the order,
  what it shows, safety steps first), `ToolBook` (`data/tools/tools.json`), `ToolData` (`ProfileData.tools`: three stamps
  per tool, in the backup), `ToolRoomHost` (LifeRoomHost with the engine: every frame's LifeCheck sample goes through it).
- **A room opts in:** give a target a work frame (`has_work(target)`, `work_frame(target)` -> a global Transform3D) and a
  step on it naming `motion` (and `tool`) is done with the real motion; `has_device(id)` runs a step's `device`. Rooms
  without them (L1's) play exactly as before. Tools in a room are `ToolProp`s (a VrGrabbable of kind `&"tool"`; tips per
  motion, ToolModels' true sizes; register `tool_<id>` targets so the right one glows in VR).
- **A new tool:** an entry in `data/tools/tools.json` (name, for, hold, motions from the ten, safety, area, icon, checks
  per motion, `grown_up`, a device's run data); a model in `ToolModels.build` with its tips; a picture in `ToolIcons` (or,
  Life L3b, any `LifeIcons` name: ToolIcons draws it with Life's picture, as for the life jacket, the CO alarm, the fuse box).
  `test_tools_book.gd` holds the catalogue to the rules (every motion taught, every L1 tool and device present, devices
  run, kind British words).
- **Step fields the engine reads** (Life's format, LifeCheck's kinds unchanged): `motion`, `tool`, `checks` (the motion's
  numbers for this step), `gear` (safety gear a find step puts on), `safety` (gear that must be on before the tool),
  `device`, `glow: false` (no glowing places: the Expert try), `walk` (VR: a long tape carries the child to its end),
  `safe_mistake {wrong, event, why, right}` (#118: shaped; played as the coach's why and the room's gentle event, never a
  miss; never on Little). Life L3b made the saw's tryable: its `try: "unsafe"` (the saw before the goggles):
  `ToolRoomHost._safe_mistake` marks the frame's sample unsafe with the target pressed the first time, so Life's run counts
  the mistake and the host freezes time; once explained, a later try is the shaped way (the why, the goggles glow).
- **Real Builder:** `RealBuilder` (`data/tools/real_builder.json`, Life's format; `RealBuilder.problems()`), `BrickBond`
  (real brickwork as rules: 215 x 102.5 x 65 mm bricks, 440 x 100 x 215 mm blocks, 10 mm joints, stretcher bond with
  corners, openings, lintels with 150 mm bearing, `straight_joints` for the push test, `floating`), `RealBuilderSite`
  (the room per track), `BoxBatch` (laid bricks as one mesh per colour: a house in 70 meshes). Its three Life units are in
  `data/tools/units/` (the School's format) and in `data/life/life.json` as "coming soon" until the lead's hook.
- **Tests** tick the host themselves on a fixed clock (`host.set_process(false)`, `host._process(dt)`, `Vr.step(dt)`);
  `tools/real_builder_driver.gd` plays a whole try like a child who does every step right (flat: the tray and a finger
  through `hud.finger`; VR: fake hands with `Vr.sim_hand` / `sim_input`, tools in the right hand, bricks carried with the
  left). Set `Profile.data.settings.reduce_motion` so the camera moves at once.

### Success S2: the Goal Board, Talk & Deal, the Connections Book, Success Stories (owner #115; spec §27.4)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_success_data.gd,res://tests/unit/test_success_goals.gd,res://tests/unit/test_success_habits.gd
tests/run_tests.sh -gtest=res://tests/unit/test_success_people.gd,res://tests/unit/test_success_stories.gd,res://tests/unit/test_success_experiences.gd
tests/run_tests.sh -gtest=res://tests/integration/test_success_places.gd,res://tests/integration/test_success_rooms.gd,res://tests/integration/test_success_icons.gd
XDG_DATA_HOME=/tmp/easycraft-success-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=goal_board,talk_deal,connections,success_stories
/usr/bin/python3 tools/success_review_sheet.py            # the experts' sheet (docs/devlog/parts/success-s2-review.md)
/usr/bin/python3 tools/success_review_sheet.py --check    # exits 1 when it is out of date (run it after editing data/success)
```
The design `docs/design/success-skills.md`; the notes and rulings `docs/devlog/parts/success-s2.md`.
- **Four Life Experiences** (Life's framework, nothing forked): `goal_board` (GoalRoom), `talk_deal` (TalkSquare),
  `connections` (VillageSquare), `success_stories` (StoryStage). Their data is `data/success/experiences/<id>.json` in
  Life's format (LifeExperience's header); `SuccessExperiences` is the registry (IDS, the data path, the rooms,
  `vars` for `"vary": "success"`: Mo's complaint, the cake's, Lina's present, the Moon rocket's real gold). Owner #115's
  hooks (each marked): `LifeExperience.IDS`, its data path and `vars`; `LifeRooms.make`'s default; `LifeCatalog.problems`
  (Living well's 8 areas and Success's 2 or more); `LifeIcons.has` / `paint` (SuccessIcons); `LifeData.success`;
  `LifeScreen` (`SUCCESS`, `show_success_place`, the map's `SuccessPlaces.fit_grid`, the area's `SuccessPlaces.add_places`,
  `_on_room_finished`'s `SuccessPlaces.record_try`); `LifeGrownUpsPage.show_progress` (`SuccessPlaces.grown_ups`).
- **The map:** four Success areas in `data/life/life.json` (`goals`, `talk`, `connections`, `stories`; `"owner": "#115"`,
  a `"place"` for three of them), their twelve Life units in `data/success/units/` (the School's format; the file path
  is `../success/units/...` from `data/life/`) and the School's own lessons that fit. The Success row is one row of six
  smaller cards (`fit_grid`). Life Town's second row has the four Success places (Life L3b: the goal board, the talk
  tent, the village board, the story stage); walking up opens the Experience's unit on the child's track.
- **The places** (`ui/success/`, pages inside the Life screen, `SuccessPage`): MY GOAL BOARD (`GoalBoardPage`: the goal,
  its steps, the if-then and obstacle plans, the habit garden: `HabitPlant`), MY CONNECTIONS BOOK (`ConnectionsBookPage`),
  THE STORY SHELF (`StoryShelfPage`). Rules in `core/success/`: `SuccessData` (`ProfileData.life.success`: in the backup,
  merged without losing a day, a person or a story), `SuccessGoals` (`data/success/goals.json`: dreams, goals with their
  `measure`, steps, cues, actions, ready plans, obstacles, responses, habits), `SuccessHabits` (days kept in all, never in
  a row; nothing anywhere counts a streak: `test_no_streak_is_counted_anywhere`), `SuccessPeople`
  (`data/success/people.json`; warmth by kind acts, at most 2 a try, shown only in words), `SuccessStories`
  (`data/success/stories.json`: twenty, every fact with its source).
- **A step that fills the book:** `"book": {"meet": [ids]}` / `{"help": id}` / `{"promise": id}` / `{"intro": [a, b]}` /
  `{"mentor": id}` or a list of them; a step's `"story": id` ticks the story shelf. Only a finished try records
  (`SuccessPlaces.record_try`). A new person: an entry in `people.json` (a `look` that `SuccessCast.dress` knows, a
  skin tone in `SuccessIcons.SKINS`); a new story: an entry in `stories.json` (5-7 lines, a question whose answers have
  icons, two sources or more), a symbol in `SuccessIcons`; then regenerate the review sheet.

### Success S3: My Business's shop and the Market Square (owner #115; spec §27.8)
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_success_shop.gd,res://tests/unit/test_success_market.gd,res://tests/unit/test_success_s3_experiences.gd
tests/run_tests.sh -gtest=res://tests/integration/test_success_s3_rooms.gd,res://tests/integration/test_success_s3_places.gd
tests/run_tests.sh -gtest=res://tests/unit/test_success_s3_plaza.gd,res://tests/integration/test_success_s3_town.gd   # the second plaza
XDG_DATA_HOME=/tmp/easycraft-success-smoke godot --headless --path . --script res://tools/life_smoke.gd -- --only=my_shop,market_square
XDG_DATA_HOME=/tmp/easycraft-life-town-smoke godot --headless --path . --script res://tools/life_town_smoke.gd   # and the Market Square
/usr/bin/python3 tools/success_review_sheet.py            # both sheets (success-s2-review.md, success-s3-review.md)
```
The design `docs/design/success-skills.md` §2.1, §2.2; the notes and rulings `docs/devlog/parts/success-s3.md`; the
experts' sheet `docs/devlog/parts/success-s3-review.md` (every source a checkbox).
- **Two Life Experiences** (Life's framework, `vary: "success"`): `my_shop` (ShopRoom: Little's stand, Middle's bakery,
  Big's harder days) and `market_square` (MarketSquareRoom: Little's swap stall, Middle's Price Board and causes, Big's
  shed, baskets, storm and dice table). Their values come from `SuccessShop.vars` / `SuccessMarket.vars` through
  `SuccessExperiences.vars`. **Tokens are letters and underscores only** (LifeExperience.TOKEN): `{one_name}`, never
  `{c1_name}` (it is never filled). Both rooms' coin trays are `SuccessTill` (moves to where the child stands: Tomas's
  stall). Their units are in Money and business (`data/life/life.json`, owner "#115 (S3)"), beside My Money Stall.
- **The shop's day:** a step's `"shop"`: `{"sale": person, "in": coins, "review": kind}`, `{"out": coins}`,
  `{"fixed": person}`. `SuccessShop.day_from(steps, log)` counts only the steps done; `SuccessPlaces.after_try` (from
  LifeScreen's finished and stopped hooks) records the day (`SuccessData.shop`: the ledger, the reviews) and pays
  `SuccessShop.pay`: GOLD_PER_CUSTOMER (5) a customer served, at most DAY_CAP (50) a day, through `EarnRules.credit`.
  The result page shows it (`ShopGold`). A finished market try counts in `SuccessData.market`; its `chart` step marks the
  dice lesson seen.
- **The places** (cards among Money and business's units: `SuccessPlaces.AREA_PLACES`; two unit rows leave no room for a
  row of buttons): MY SHOP (`MyShopPage`: the sign picked from six, the reviews, `ShopWeekBars`, OPEN MY SHOP through the
  page's `try_it`) and THE PRICE BOARD (`PriceBoardPage`: `SuccessMarket.board(today)`, the season, the next season's
  change, TRY IT AT THE MARKET).
- **The Market Square in the world** (`MarketPlaza`: its LAYOUT and SPOTS "bakery" and "square"): found by
  `LifeTown.pick(..., layout, town)` (the rings' cells nearest the town first, every tier; off the town's plaza by CLEAR,
  TOWN_GAP 30 round from it, PLAZA_SIGHT_GAP 20 from the Theater and the Launch Site); `LifeTownDirector` makes
  `MarketPlazaPlacer` (node "MarketSquare") when the town stands: saved site at once, else the search, the host's
  natural check and tree clearing, `MarketPlazaBuildings`, `placed` → `site.market` and `site_placed` (WorldMeta keeps
  `[town x, y, z, facing, market x, y, z, facing]`: `LifeTown.to_save` / `from_save`). Walking up: `_follow_player`
  asks the placer after the town ("market/<id>").
- **Pictures:** `SuccessIconsMarket` (31; SuccessIcons asks it). **Tool Book:** `ledger`, `price_board` (owner
  "#115 (S3)"); the till and the scales were there.

### Play W1: learning inside the world (owner #132, #133; spec §22.0 "As built (W1)")
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_discovery_rules.gd,res://tests/integration/test_discovery_director.gd,res://tests/integration/test_discovery_pause.gd
tests/run_tests.sh -gtest=res://tests/unit/test_discovery_crystal_rules.gd,res://tests/unit/test_discovery_crystal_plays.gd,res://tests/integration/test_discovery_crystal.gd,res://tests/integration/test_discovery_grown_ups.gd
tests/run_tests.sh -gtest=res://tests/unit/test_discovery_academy.gd,res://tests/integration/test_discovery_academy_world.gd,res://tests/integration/test_discovery_hoot_flight.gd
tests/run_tests.sh -gtest=res://tests/integration/test_discovery_play_place.gd   # on Play G0's place
XDG_DATA_HOME=/tmp/easycraft-discovery-smoke godot --headless --path . --script res://tools/discovery_smoke.gd   # a real world
XDG_DATA_HOME=/tmp/easycraft-discovery-smoke nice godot --path . --resolution 1280x720 --script res://tools/discovery_smoke.gd -- --shots=/tmp/w1   # pictures
```
The notes and rulings: `docs/devlog/parts/play-w1.md`. Folders: `core/discovery/` (rules), `entities/discovery/` (the
director), `ui/discovery/` (screens), `data/discovery/`; hooks in `scenes/sandbox.gd` are marked "owner #132 (W1)".
- **DiscoveryDirector** (node "Discovery" of the sandbox; `_setup_discovery`): in every world but Monster Wave's arena
  (`DiscoveryRules.discover_here`). MORE's first picture is DISCOVER (`more_button()`: HudIcons' `discover`, a magnifying
  glass) and the pause menu has a DISCOVER picture beside RESUME (`PauseMenu.discover_on`, `discover_requested`); both
  call `open_discover(subject)`: **DiscoverPanel**, the School over the world (like `LifeTownPanel`); while it shows the
  avatar is held (`_life_take_over`) and kept safe; Android Back, Esc, Circle / B and the School's own BACK close it.
- **The switch for Play G0:** `DiscoverPanel.make_screen()` is the one call that makes the screen (today SchoolScreen
  through its public functions: `subject`, `show_life()`); G0's DISCOVER map goes there when G0 merges.
- **Professor Hoot's invitation** (`HootCard`, home worlds only: `hoot_here`): after `HOOT_AFTER` s standing in the
  world with nothing over it (`overlay_open`: the sandbox's `_discovery_covered`), on each world's first visit and in a
  world seen before at most once a day (`hoot_due`); his line spoken by itself (`ReadAloud.speak`), the card Hoot + one
  DISCOVER picture + a cross, top middle, fading after `HOOT_STAYS` s. In a headset his line goes on the toast strip
  (`hud.toast`). Opening DISCOVER first counts as his visit. His memory: `DiscoveryLog` (`user://discovery.json`, this
  device only, never sent, not in the backup).
- **No reading (owner #133):** a W1 screen shows pictures, numbers and at most `DiscoveryRules.MAX_SCREEN_WORDS` words
  (`word_count`: numbers and signs are not words); every line is spoken; DISCOVER's word is spoken when a pointer (a
  mouse, the headset's laser) or a controller's focus comes to it (`DiscoverButton`; MORE's TouchButton gets
  `MOUSE_FILTER_PASS` for it). A new W1 screen gets a test that it speaks its line and keeps the budget.
- **Discovery crystals (stage 2;** `tests/unit/test_discovery_crystal_rules.gd`, `test_discovery_crystal_plays.gd`,
  `tests/integration/test_discovery_crystal.gd`, `test_discovery_grown_ups.gd`**):** `DiscoveryCrystalRules` (where and
  when: home worlds, the grown-up's switch `settings.discovery_crystals` on the grown-ups' PLAY & PHOTOS page,
  `FIRST_SECONDS`/`EVERY_SECONDS` of free play, `WAIT_SECONDS` untouched, `spot_near`: dry, open, reachable ground a few
  metres off, a little to one side of the view), `DiscoveryPlays` (MAKE and ORDER sets, `UNIT_PLAYS` by standards,
  `pick`: a review due, else the next unit, else a grade challenge with the unit kept as play debt; **`play_for(unit)`
  is the lead's switch** as deep games and G0's mechanics merge), `DiscoveryChallenge` (the moves: TAKEN, MADE,
  BOUNCED, the hint after two misses, `first_try`), `DiscoveryCrystal` (the node under the sandbox: never replicated;
  one warmed unshaded material, billboard labels), `DiscoveryStrip` (the flat card). The sandbox gives the director
  `world_parent`, `block_at`, `player_feet`, `player_yaw`, `busy` (`_discovery_busy`: monsters within 18 m, a wave, a
  round, a race, riding, a car, flying, seated, hiding, asleep, knocked out, the tutorial) and `hand_points` (VR), and
  sets `BlockInteractor.discovery_tap` (before bags and blocks, in `place_at_screen` and `break_at_screen`): a tap on the
  crystal starts it, and during its play every tap is the play's. The smoke's crystal steps skip the minutes of play by
  setting the director's `_play`.
- **The Discovery Academy (stage 3;** `tests/unit/test_discovery_academy.gd`, `tests/integration/test_discovery_academy_world.gd`,
  `test_discovery_hoot_flight.gd`**):** `AcademyPlaza` (the layout: a tower and twelve doors on a ring, `DOORS`,
  `SPOTS` with subject, spoken name, picture, colour; `pick`/`pick_for`: `LifeTown.pick` with this layout, its own start
  angle (`SEED_SHIFT`) and **`avoid`** (a new `LifeTown.pick` parameter: [site, layout] pairs whose plazas and 20 degrees
  round are kept off: the town's and the Market Square's), else `island` over the spawn; `to_save`/`from_save`:
  `WorldMeta.academy`; **`opens(door)` is the lead's switch**: CRYSTAL, LIFE or SOON), `AcademyPlacer` (node "Academy"
  under "Discovery": the Market Square placer's way; it recomputes the Theater, the Launch Site, the town and the Market
  Square from the save or the seed on its worker), `AcademyBuildings` (merged lit and glowing parts, Hoot's body and head;
  pictures from `AcademyIcons`, rectangles shared with the cards), `AcademyCard` (a door's "coming soon"), `HootFlyer`
  (Hoot landing near the child with his invitation). The sandbox's `_setup_academy` (home worlds), `_mark_academy` (MY
  MAP's tower) and `_chain_discovery_compass` (deferred: the Academy before the world's own guide). Doors: the director's
  `_follow_doors` (a door opens again only after walking away).
- **The learning places' look (2026-10-18,** `tests/integration/test_academy_look.gd`, notes
  `docs/devlog/parts/academy-look.md`**):** `AcademyBuildings` is built with the rooms' kit (`LifeRoomDecor`): three drawn
  meshes (the world's block pictures, the lit pieces with the perched Hoot, the glowing pieces; none casts a shadow) and a
  `Shadow` proxy of plain boxes (`SHADOWS_ONLY`); `look_pieces` holds every piece's box (the look tests read them: the
  doors' ways kept clear, the paving on its ground, the places kept for the games: the bakery's plot, the Voyage
  Garden's bed, the Word Tower's scaffolding, the temple's island). Keep `TOWER_TOP` + `PEDESTAL` as Hoot's perch (his
  flight lands there). **Hoot is one model** (`HootModel`: the body with face and cap, two wings; facing -Z):
  `HootFlyer` beats the wings in flight and folds them on landing; a new Hoot anywhere uses it. The crystal: a cluster,
  a breathing `halo`, `stones`, `sparkles` on the first touch. Pictures and the draws in a real world:
  `tools/academy_shots.gd` (its header: `--vr`, `--style=realistic`, `--only=`; a private `XDG_DATA_HOME` with "shots").
- **On Play G0's foundation** (`tests/integration/test_discovery_play_place.gd`): a crystal opens G0's short round
  (`DiscoveryDirector._open_place(unit, CRYSTAL_ROUND, …)`: `PlayHost.setup(…, 4)` under `play_holder` in the HUD's
  layer, `SkillShown.pay_first_try` for the gold, `SkillShown.record` at the end) on `DiscoveryPlays.pick`'s unit (the
  child's own when `PlayHost.plays`, else the grade's, the debt kept); W1's own MAKE and ORDER only where nothing in the
  grade plays. A subject's Academy door: a whole round of `DiscoveryPlays.subject_unit` (else "coming soon"). The
  director's `unit_plays` ((unit id) -> bool, `DiscoveryPlays.g0_plays` by default) lets tests choose what plays.
  `DiscoverPanel.room_open()`/`close()` know the School's `play_host`. Every W1 line goes through `PlayVoice.say`.

### Earning, inviting and the Gold Shop (owner #79, #83, #85; spec §25.6)
Notes and rulings: `docs/devlog/parts/earn-invite.md`; the lawyer's note: `docs/store/refer-a-friend-note.md`.
- **EarnRules** (`core/economy/earn_rules.gd`): the one table of gold for learning (School answers right the first
  time, 5 each up to 150 a day in `profile.earn_today`; a unit's 100; a new Lab star's 25; the worlds' own LootRules;
  hooks for the first secret of each kind and fact quizzes; the server's invite rewards). `EarnRules.credit(profile, n)`
  pays account gold outside a world (the caller saves; the wallet sync reports it). The School pays through
  `ExercisePanel.first_try_gold` (the words under the praise, label `GoldLine`) and the round's end (`AnswerGold`,
  `DayFull`); the Lab in `LabScreen._what_happened`.
- **SpendRules** (`core/economy/spend_rules.gd`): every price the Gold Shop shows, by id: `lesson:<unit>` (a unit marked
  `"bonus": true` with a `"price"` in a grade outline: `lesson_open`, `bonus_units`; the School's unit page offers OPEN
  FOR N GOLD), `gear:<item>` (ShopRules in `universe_unlocked`; into `profile.backpack`, device-only, emptied into the
  next Survivor world by `Session.set_inventory`), `look:<avatar item>` (AvatarUnlocks), and what other parts hang on a
  shelf: **`SpendRules.register(SpendRules.ROCKET, {"id": "part:<id>", "name", "price", "picture"?}, grant)`** (the
  missions' rocket parts; `grant(profile, id)` gives the thing; `profile.bought` keeps the id). `GUIDE` suggests prices.
- **Invites** (`core/invite/`): `InviteRules` (codes typed any way: `canonical`, `shown`; the links; the share text;
  the ranks; the child's words; the server's numbers; the missions' hook `InviteRules.friend_landed("moon")`),
  `InviteData` (`profile.invite`: a code waiting for the server, used, the guide's name, the first unit learned, what the
  server has heard, the account's own code), `InviteSender.send_soon()`, and `QrCode` (the game's own QR encoder, level M,
  versions 1-10; `QrView` draws it). `OnlineService`'s section "Owner #79": `invite_info`, `use_invite` (keeps a code
  offline), `send_invite_events`, `refresh_invite_news`, `take_invite_news`, `invite_group`; signals
  `invite_news_arrived`, `invite_code_result`; the sign-in sends what waits (`_inv_signed_in`) and note 108 refreshes the
  news. `Session.online_autostart` also signs in a device whose `profile.invite` is not empty.
- **UI**: `InvitePage` (the main menu's INVITE; views SOON, CONNECTING, FAILED, CLAIM, MAIN, QR, CODE, GATE, GROWN_UPS),
  `InviteCodeBox` (the start's step after the name, SETTINGS → HELP's FRIEND'S CODE, the page's I HAVE A CODE),
  `InviteNewsCard` (the main menu's card), `GoldShop` (the main menu's GOLD SHOP). The main menu's second row is six
  buttons (SCHOOL, INVITE, FRIENDS, GOLD SHOP, AVATAR, SETTINGS) of `menu.gd`'s `EXTRA_BUTTON` (182 × 76, font
  `EXTRA_FONT` 26; owner #81/#85 added FRIENDS). The web page keeps `?invite=` as `window.easycraftInvite`
  (`web/shell.html`, also across its redirect to the server's copy); `WebGlue.invite_code()`, `can_share()`, `share()`.
- **Server** (module 0.2.16): `invite_info`, `invite_use`, `invite_progress`, `invite_group` (`server/README.md`).
  Checked on a private Nakama for a worktree: `EASYCRAFT_SERVER=http://127.0.0.1:7460 node --test
  test/integration/referrals.server.ts` (compose project `easycraft_<x>`, ports 7459-7461, the README's recipe).
- **Tests**: `test_earn_rules`, `test_spend_rules`, `test_invite_rules`, `test_qr_code` (whole matrices from Project
  Nayuki's qrcodegen, `pip install qrcodegen` in a scratch venv; `zbarimg` from `zbar-tools` read the game's pictures),
  `test_explorer_lessons`, `test_school_earn`, `test_invite_online`, `test_invite_page`, `test_invite_menu`,
  `test_gold_shop`; the fake server's section "Owner #79" (`tests/fakes/fake_online_server.gd`) answers like the module.

### The Daily Mission, postcards and friends (owner #81, #82, #85; spec §25.7)
Notes, rulings and the numbers: `docs/devlog/parts/daily-and-friends.md`; server module 0.2.18 (`server/README.md`).
```bash
tests/run_tests.sh -gtest=res://tests/unit/test_daily_mission.gd,res://tests/integration/test_daily_page.gd
XDG_DATA_HOME=/tmp/easycraft-daily-shots godot --path . --disable-vsync --script res://tools/daily_shots.gd [-- --wide]
EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/together.server.ts   # a real Nakama
```
- **The Daily Mission** (`core/daily/`): `DailyMission.plan(day, grade)`: 5 exercises (`LEVELS` easy to harder) from the
  grade's subjects (a seeded shuffle of the subjects with written units; a unit picked from the outline, never an
  Explorer lesson; its generators first, a unit with none gives one of its own exercises), seeded by the **UTC day**
  (`DailyMission.day_of`) and the grade: the same for every player of a grade on one version of the School. Only the five
  picked units are read. `DailyData` (`profile.daily`): each day's answers (`"10111"`) and grade, `total` mission days (never
  falls), `paid`; `week(today)` is mission days and rest days. `EarnRules.daily_gold` pays `DAILY_STAR_GOLD` (10) a star,
  once a day (the table's `daily` row). UI: `ui/daily/` (`DailyPage` in the School's page `DAILY` from the map's gold
  TODAY'S MISSION button; `DailyCard`, the result card; `DailyWeek`). Tests give the page `today`, `grade`, `copy_text`,
  `can_share`, `share`, `save_png` and `render`; the School has `daily_today`.
- **Pictures to keep and share** (`ui/social/card_picture.gd`): `CardPicture.render(host, control, px)` draws a card in a
  SubViewport (null headless), `save_png` puts it where photos go (Android's gallery, a desktop's `user://photos`, a
  browser's download), `share` uses a browser's share sheet (the words and the link) or Android's (the picture), where
  `PhotoRules.may_share` allows. Every shared thing carries only the words and the invite link (`InviteRules`).
- **Postcards** (`core/social/postcard_rules.gd`, `ui/social/postcard_*.gd`): a moment is `{kind, place, key, words}`
  (`PostcardRules.landed("moon")`, `mission`, `unit`, `grade`, `stamp`, `deposit`); `SocialData.postcards` remembers each
  offered (once, never nagging). The School offers MAKE A POSTCARD on a round's end when a unit (or the subject's last:
  the grade's moment) is mastered; `PostcardPage` shows `PostcardView` (a drawn picture in the School). In a world,
  **`PostcardOffer.offer(parent, moment)`** is the hook (a small card; POSTCARD takes the world's picture,
  `before_photo`/`after_photo` can hide the HUD; `close_if_open()` for Android Back): the lead wires it to
  `RocketFlight.landed` / `sandbox.mission_arrive` for a first landing, and the wonders and prospecting to theirs.
- **Friends** (`core/social/`: `FriendshipRules`, `FriendPresents`, `CrewRules`, `SocialData`, `SocialSender`; `ui/social/
  friends_page.gd`): FRIENDS on the main menu (tabs FRIENDS, PRESENTS, CREW; pickers CHEER, PICK_PRESENT, MAKE_CREW,
  PICK_CREWMATE). `SocialSender.learned(unit)` (a School round finished, the Daily Mission done) and `.moment(m)` keep what
  the server should hear in `profile.social` until a sign-in (`OnlineService.send_social_events`); `OnlineService`'s
  section "Owner #81, #82, #85" has `social_info`, `send_cheer`, `send_present`, `send_link_present`, `open_present` (it
  gives the thing: `FriendPresents.open`), `thank_present`, `study_buddy`, `crew_action`, and puts friends' news on the main
  menu's card (`invite_news` `{"what": "text"}`; note 109). The GDScript numbers and lists mirror
  `server/modules/src/rules/social_rules.ts` (tests read the .ts). The fake server's section "Owner #81, #82, #85"
  (`tests/fakes/fake_online_server.gd`, `soc_day`) answers like the module.
- **Tests**: `test_daily_mission`, `test_daily_data`, `test_postcard_rules`, `test_gift_presents`, `test_friendship_rules`,
  `test_crew_rules` (unit); `test_daily_page`, `test_postcard_page`, `test_friendship_online`, `test_friendship_page`,
  `test_crew_page` (integration); server `social_rules.test.ts`, `together_rpcs.test.ts`.

### The wild meadows: a bigger world (owner feedback #45b)
```bash
godot --headless --path . --script res://tools/make_meadows_page.gd   # data/blocks/pages/meadows.png (page 13)
python3 tools/make_meadows_realistic.py     # its realistic twin (CC0 ambientCG; helpers of make_realistic_atlas.py)
XDG_DATA_HOME=/tmp/easycraft-world-smoke godot --headless --path . --script res://tools/world_smoke.gd
XDG_DATA_HOME=/tmp/easycraft-world-shots godot --path . --disable-vsync --resolution 1280x720 --script res://tools/world_shots.gd
```
- **Only new worlds get it.** `WorldMeta.terrain`: 1 is the M1–M3 Green Meadows (every world saved before, forever; only
  edited chunks are saved, so a changed generator would change their untouched land), 2 the wild meadows
  (`MeadowsBiomeShape`, `MeadowsBiomeGenerator`, `MeadowsPlaces`). The meadows descriptor makes the version's terrain
  (`terrain_shape` / `terrain_generator`, through `UniverseRegistry.shape_for(u, seed, terrain)`); `WorldService.terrain_version`
  is set before `setup`; a guest gets the host's version before `world_info` (Session section "Owner 45b").
- The smoke run (a fresh private folder whose path contains "smoke", with a `profile.json`) starts a new Sandbox world
  of seed 12345: terrain 2, the nearest village in the generated terrain (well, plaza, a house's door), found by walking in
  (the toast, the save), its villagers, MAP and a tap setting the find arrow, a lighthouse's lamp and stair, birches and a
  snowy top in the real chunks. Prints `WORLD_SMOKE ok|FAIL …`; exits 0 when all passed.
- The screenshot tour needs a window and a folder containing "shots": every place kind, the biomes, a mushroom cave and
  the map, in both styles, as 640 × 360 JPEGs in `$XDG_DATA_HOME/world_shots/`.
- To find places in a world from godot-mcp exec: `sandbox.places_director.places.nearest(pos, &"village", 8)` (a
  Dictionary: `anchor`, `name`, `doors`, …); the world map shows only found ones.

### The Sandstorm Desert (universe 2, M3 Task 2)
```bash
godot --headless --path . --script res://tools/make_desert_atlas.gd   # data/blocks/pages/desert.png (page 1)
python3 tools/make_desert_realistic.py     # its realistic twin (CC0 ambientCG; helpers of make_realistic_atlas.py)
python3 tools/make_desert_music.py         # assets/music/desert_day.ogg, desert_night.ogg (CC0, OpenGameArt)
python3 tools/make_desert_sounds.py        # mummy, scorpion, serpent, trap and sandstorm sounds (original)
XDG_DATA_HOME=/tmp/easycraft-desert-smoke godot --headless --path . --script res://tools/desert_smoke.gd
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=2   # play a new desert world
```
- The smoke run starts a new Survivor world of universe 2 (Cozy) and checks, with the real systems: the
  desert's directors, night mummies and scorpions, a scorpion's spit hitting a player who stands still, a
  level 3 mummy unwrapping into two halves, a sandstorm (the player half as visible, the fog at half the
  view) coming and going, the Sand Serpent's phases and its defeat (the portal), the nearest pyramid's blocks
  and finding it; then a cost window with 20 desert monsters. Prints `DESERT_SMOKE ok|FAIL …` and `cost` lines;
  exits 0 when all passed. A fresh private folder whose path contains "smoke", with a `profile.json`;
  `-- --smoke-seed=<n>` repeats a world.
- `--universe=2` (with `--survivor`, M3 Task 5's argument) opens universe 2's own save slot (`survivor_u2`);
  in the game, the Stone Golem's portal leads there once universe 2 is unlocked.

### Frostpeak (universe 3, M3 Task 3)
```bash
godot --headless --path . --script res://tools/make_frost_atlas.gd   # data/blocks/pages/frost.png (page 2)
python3 tools/make_frost_realistic.py      # its realistic twin (CC0 ambientCG; helpers of make_realistic_atlas.py)
python3 tools/make_frost_music.py          # assets/music/frost_day.ogg, frost_night.ogg (CC0, OpenGameArt)
python3 tools/make_frost_sounds.py         # yeti, ice bat, Frost Giant, snowball, ice and snowstorm sounds (original)
XDG_DATA_HOME=/tmp/easycraft-frost-smoke godot --headless --path . --script res://tools/frost_smoke.gd
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=3   # play a new Frostpeak world
```
- The smoke run starts a new Survivor world of universe 3 (Cozy) and checks, with the real systems: Frostpeak's
  directors, night yetis and ice bats, a yeti's snowball and an ice bat's dive hitting a player who stands still
  (both signalled first), a snowstorm (the player half as visible, the fog white at half the view) coming and
  going, the Frost Giant's phases, its icy ground and its defeat (the portal to universe 4), a cost window with
  20 Frostpeak monsters, the nearest igloo with a secret room (a knock opens its fake floor and finds it), and a
  frozen lake's ice under the player's feet (slippery). Prints `FROST_SMOKE ok|FAIL …` and `cost` lines; exits 0
  when all passed. A private folder whose path contains "smoke", with a `profile.json`; `-- --smoke-seed=<n>`.
- Ice is slippery through one rule, `FrostRules.grip_at` (the block under the feet, or the Frost Giant's
  `IcyGround` rings): the player's ground acceleration, monsters' and animals' speeding up and slowing down are
  scaled by it. Snowstorms are the desert's `SandstormDirector` with `snow = true` (node "Snowstorm").

### The Candy Kingdom (universe 4, M3 Task 4)
```bash
godot --headless --path . --script res://tools/make_candy_atlas.gd   # data/blocks/pages/candy.png (page 8)
python3 tools/make_candy_realistic.py      # its realistic twin (CC0 ambientCG; helpers of make_realistic_atlas.py)
python3 tools/make_candy_music.py          # assets/music/candy_day.ogg, candy_night.ogg (an original waltz, synthesised)
python3 tools/make_candy_sounds.py         # gummy, sneaker, Cake Monster and fanfare sounds (original)
XDG_DATA_HOME=/tmp/easycraft-candy-smoke godot --headless --path . --script res://tools/candy_smoke.gd
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=4   # play a new kingdom world
```
- The smoke run starts a new Survivor world of universe 4 (Cozy) and checks, with the real systems: the kingdom's
  directors and chocolate water, night gummy bears and sneakers and the sprinkles, a gummy bear's nip, a sneaker
  dark at night (only its shimmer close by) that jingles and swings, the sprinkles stopping by day, swimming in a
  chocolate river, bouncing on a gumdrop hill, the Cake Monster (a layer falls, it is beaten: the hub portal, the
  cosmic outfit), the nearest gingerbread house; then a cost window with 20 candy monsters. Prints
  `CANDY_SMOKE ok|FAIL …` and `cost` lines; exits 0 when all passed. A fresh private folder whose path contains
  "smoke", with a `profile.json`; `-- --smoke-seed=<n>` repeats a world.

### The Dragon Realm (universe 5, owner feedback #39)
```bash
godot --headless --path . --script res://tools/make_dragon_atlas.gd   # data/blocks/pages/dragon.png (page 11)
python3 tools/make_dragon_realistic.py     # its realistic twin (CC0 ambientCG; helpers of make_realistic_atlas.py)
XDG_DATA_HOME=/tmp/easycraft-dragon-smoke godot --headless --path . --script res://tools/dragon_smoke.gd
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=5   # play a new Dragon Realm world
```
- The smoke run starts a new Survivor world of universe 5 (Cozy) and checks, with the real systems: the player on the
  home island's sky grass, the realm's secrets and the host's `VoidWatch`; a crystal spire and a giant mushroom near
  the spawn; the nearest dragon nest's egg cell (air on a nest block, inside its island's box); the player pushed off
  the island's edge falls under every island, the wind carries it back where it last stood with "Whoosh! The wind
  carried you back." (no knock-out); a monster in the void puffs away and a sheep comes back beside the player; the arena
  of universe 5 is flat sky grass. Prints `DRAGON_SMOKE ok|FAIL …` and a `cost` line; exits 0 when all passed. A fresh
  private folder whose path contains "smoke", with a copy of `profile.json`; `-- --smoke-seed=<n>` repeats a world.
- The void: a descriptor with `has_void = true` (`void` is a GDScript keyword) floats over one (`DragonRules`). Every
  player's own game remembers its last safe spot (solid ground under the feet, at most every 0.5 s) and below
  `DragonRules.RESCUE_Y` (4, under every island: `DragonShape.MIN_BOTTOM` 12) is carried back there (`Player.carry_back`:
  the spot; its column's ground when that block is gone; home when there is no island there). The host's `VoidWatch`
  (sandbox section "Owner 39") does the rest. Monster Wave's arena of the realm is flat ground: no void there.
- A void column's height is `DragonShape.VOID_HEIGHT` (the sea level): every spawner that wants dry land (> sea + 1)
  or water deep enough for fish (2 under the sea) finds none there. Secrets but the nests stand on islands whose rock
  reaches below them (`DragonSecretRules.grounded`); the treasure pack builds its DRAGON style (five kinds).

### The Glow Caves (universe 6; `docs/devlog/parts/glow-caves.md`)
```bash
godot --headless --path . --script res://tools/make_glow_atlas.gd   # data/blocks/pages/glow.png (page 45, the pixel style)
PYTHONDONTWRITEBYTECODE=1 python3 tools/make_glow_realistic.py      # its realistic twin (cached CC0 ambientCG only: it never downloads)
python3 tools/make_glow_sounds.py                                   # puffs, crawlers, the Spore Mother, echo, drip, fizz (original)
godot --headless --path . --script res://tools/bench_generator.gd -- --glow   # BENCH_GLOW lines: against the Dragon Realm's
XDG_DATA_HOME=/tmp/easycraft-glow-smoke godot --headless --path . --script res://tools/glow_smoke.gd
XDG_DATA_HOME=/tmp/easycraft-look-shots godot --path . --disable-vsync --resolution 1600x720 \
  --script res://tools/look_shots.gd -- --universe=6       # pictures in both styles (windowed): halls, wonders, monsters
XDG_DATA_HOME=/tmp/easycraft-vr-bench-smoke nice godot --display-driver x11 --disable-vsync --path . --resolution 1440x1584 \
  --rendering-method mobile --script res://tools/vr_bench.gd -- --world=6 --seconds=20 --turns=4
XDG_DATA_HOME=<private dir> godot --path . -- --survivor --new-world --universe=6   # play a new Glow Caves world
```
- **What it is:** the ladder's sixth universe (`world/universes/glow.gd`, `UniverseRegistry.LADDER[5]`), opened by the
  Sky Dragon. `GlowShape` (a `MeadowsShape`): every column is a cavern floor (`height_at`), a domed ceiling and a roof
  (`column(x, z)` = (floor, ceiling, roof); a wall's floor equals its ceiling and `height_at` is the sea level, like the
  Dragon Realm's void); halls from a warped cellular noise, passages through the walls, lakes under `LAKE_LEVEL`, the home
  hall round the spawn, daylight shafts with a spiral ramp (`shaft_near`, `ramp_height`), bedrock at `BED_BOTTOM` (−16);
  plants by hash bands (`plant_at`: giant and small glowshrooms, stalagmites, columns, selenite beams in crystal halls),
  stalactites (`hang_at`), flowers on the roof (`flower_on_roof`). `GlowGenerator` works each chunk stack's columns out
  once (runs, plants, stalactites, flowers) and fills runs; `reference_block` is the slow rule its tests compare with.
- **Its dark:** `GlowRules.CAVE_MOOD` (the descriptor's `cave_mood`) is applied by `Ambience` under any ceiling (a soft
  blue-violet fog and ambient, never black); `WorldService.sky_height` is the roof, so every cavern is underground for
  the ambience, the music and the stealth eye; `SkyCycle` leaves the ambient colour to the mood.
- **Monsters and boss:** `MonsterRules.SPORE_PUFF` (sneaks: hidden in the dark, comes to light; golden ones too) and
  `CRAWLER` (a blind chaser: hears noise only); `SporeMotherRules` and `SporeMother` (a `StoneGolem` to the
  `BossDirector`): spores on rings shown first, a rolling ring, a puff that hides her, open gills take double damage; her
  slow is each game's own (`Player.slow_down`).
- **The Cave Wonders (owner #122, learning is play):** `GlowWonderRules` (pure: the plays, hooks, facts, gold),
  `GlowWonders` (one per 128 × 128 area, its kind in turn: placed on level floor, built as boxes by the generator after
  the secrets; secrets and plants keep off them), `GlowWondersDirector` (node "GlowWonders", every game, its own child:
  hooks, tap spots `WonderThing`, looks `GlowWonderLooks`, the plays, the facts, fixed gold once, the Cave Book's page in
  `WonderData.caves`, the compass; world changes are the host's: `_rpc_change`). The Cave Book is the Secret Book's last
  page (`SecretBook.CAVE_TITLE`). Heard, not read (owner #133/#134): with `PlayVoice.on()` the director's lines are
  spoken (`voice_on` / `speak`) and the toast keeps a caption (the wonder's name, the cheer, two words).
- **The free peek:** a locked universe whose descriptor has `peek` lines (`UniverseRegistry.peek`) shows PEEK on its hub
  card and its Star Map card: `UniversePeek` (a moving picture, its lines, how it opens; closes by itself after 10 s).
- **The census:** `tools/shader_probe_steps.gd`'s `WORLDS` has `glow`; one world's census run merges into
  `data/shader_warmup.json` with `python3 tools/census_merge.py data/shader_warmup.json <run.json> data/shader_warmup.json
  glow` (`--list` first shows which draws are new).
- **The smoke run** starts a new Survivor world of universe 6 (Cozy): the home hall's floor and ceiling, the roof as the
  open sky's ground, the cave mood, the caves' secrets and wonders, a giant glowshroom, the nearest Rain Carver solved
  through the real taps (`SecretTaps`: its limestone door dissolved in the world, the wonder's gold once, the Cave Book's
  page), the nearest Drip Stone's rock, the flat arena, then two cost windows back at the spawn (with and without the
  wonders' director). Prints `GLOW_SMOKE ok|FAIL …`; exits 0 when all passed.
- **Six universe cards** fit the 1280 px screen: `UniverseCard.width_for(count)` (195 px for six).

### The Sky Dragon: sounds and cost bench (owner feedback #39)
```bash
python3 tools/make_sky_dragon_sounds.py                                # roar, wing beat, dive whoosh, crystal hum and shatter (original)
godot --headless --path . --script res://tools/sky_dragon_bench.gd     # its fight's cost next to the Cake Monster's
```
- The bench steps both bosses by hand at 60 Hz on the arena's ground (`ArenaShape`) with a child near the middle, in
  alternating 5 s blocks for 60 s each: the host step, the looks (pose, dive line, tower beams), the towers' own
  `_process`, and world reads a second (a real voxel read costs 15-35 µs here). Prints `SKY_BENCH` lines; writes
  nothing. `/summon skydragon` calls it in Sandbox.

### Autopilot (performance and acceptance run)
`tools/autopilot.gd` has two phases:
- **Play (60 s):** walk in a circle, triple-jump, place and break blocks.
- **Fly:** a 2 km ghost flight through terrain, streaming as it goes. A 10 s stall ends it with "stuck".

It prints `AUTOPILOT result phase=<play|fly> avg_fps=… max_frame_ms=… frames_over_100ms=… seconds=…`.
The same lines are kept in the static array `load("res://tools/autopilot.gd").results`, for tools that
can't read stdout, such as godot-mcp exec.

How to start it:
- **Desktop or editor run:** pass the user arg `--autopilot`, or from godot-mcp exec run
  `Game.autopilot = true; Game.start_sandbox(true)`.
- **Android (debug builds only):** triple-tap the version label in the main menu to open the developer
  menu, then press **AUTOPILOT BLOCKY** or **AUTOPILOT REALISTIC**. Each saves the style and
  continues the sandbox world. **AUTOPILOT 10 BUDDIES** first brings 10 house-sized buddies to life
  (owner feedback #9). Read the results with
  `adb logcat -d -s 'godot:*' | grep AUTOPILOT` (with the adb env vars above).
- Scripted on the emulator (2400×1080 landscape): the version label is only about 100 px wide, so
  triple-tap *on the text*: `input tap 50 1045` three times (x = 110 missed it once the label became
  "v0.2.0"). AUTOPILOT BLOCKY is at (918, 811), AUTOPILOT REALISTIC at (1482, 811), AUTOPILOT 10 BUDDIES at (1200, 961), AUTOPILOT TOUR at (1809, 961); the centred panel moves when a button is added, so re-measure from a screenshot (find the orange buttons) after any menu change.
- Measure only on a quiet PC: record the load average, and wait until the other app's native build
  (`clang++` from `parkingi`) is not running.

### Autopilot tour (on-device acceptance of the M1b features)
`tools/tour.gd` (`AcceptanceTour`) walks through the M1b features in a **new** Sandbox world, in the
current style, as the host and through the real systems (Session requests, WorldService, the sandbox's
hooks, the chat's `ChatCommandRunner`). Its checks are bedrock, cave, water, underwater, settings,
animals, bed, weapons, chat, avatar, buddies (skipped: measured with AUTOPILOT 10 BUDDIES) and peak.
Where to go is found from the world seed by `tools/tour_scout.gd` (`TourScout`, unit-tested).
- It prints `TOUR <check> PASS|FAIL <detail>` for each check and `TOUR done passed=<n> failed=<m>` at the end.
  Before a moment worth a screenshot it prints `TOUR_SHOT <name>` and holds still for 3 s.
  `TOUR_FPS <check> avg=… worst_ms=…` lines give the frame rate while each check ran.
- Each check has a time limit, so the tour never hangs. A check that runs out prints
  `FAIL timeout after <n> s at: <step>`.
- A wait inside a check (`wait_until_true`) gives up only after its seconds **and** 10 frames
  (`MIN_WAIT_FRAMES`): on a crowded emulator one frame can outlast a wait's whole budget, and a check
  must not fail having seen a single frame (M2 dev log 16:30).
- **Android (debug builds):** in the developer menu, press **AUTOPILOT TOUR**, which is right of
  AUTOPILOT 10 BUDDIES in the same row. Follow `adb logcat -s 'godot:*' | grep --line-buffered TOUR`
  and take `adb exec-out screencap -p > <name>.png` on each `TOUR_SHOT`. It replaces the Sandbox world
  on the device and returns to the menu when it is done.
- **Desktop:** `XDG_DATA_HOME=/tmp/easycraft-tour godot --path . --disable-vsync -- --tour [--tour-seed=<n>]
  [--tour-only=cave,water]`. Without a private `XDG_DATA_HOME` it refuses (exit 2). It exits 0 when
  every check passed. `--tour-seed` repeats a world (the `TOUR begin` line prints the seed of every run),
  and `--tour-only` runs a subset of the checks.
- Details, rulings and results: `docs/devlog/parts/tour.md`.

### Survivor tour (on-device acceptance of the M2 features)
`tools/tour_survivor.gd` (`SurvivorTour`, the same runner as the M1b tour) walks through M2 in a **new**
Survivor world (Normal), as the host and through the real systems: kit (starter kit, hearts, gold, no
LAB), gather (a break gives the drop, a place takes one), trader (Tilly's shop, a stone pickaxe for 30),
stealth (crouching halves visibility), night (monsters come, wild ones puff at sunrise), knockout (the
fade, getting up, the pickup bag gives the blocks back), wave (the Totem's wave 1 won, 10 gold), boss
(the Golem beaten, the portal, universe 2), friends (a bot friend joins with its badge), minds (animals
think), secrets (the nearest secret nobody found). Same lines as the M1b tour (`TOUR …`, `TOUR_SHOT …`).
- **Android (debug builds):** the developer menu's **SURVIVOR TOUR**, left of AUTOPILOT 10 BUDDIES
  (tap x ≈ 591, y 961 on the 2400 × 1080 emulator). It replaces the Survivor world.
- **Desktop:** `XDG_DATA_HOME=/tmp/easycraft-tour godot --path . --disable-vsync -- --tour --survivor
  [--tour-seed=<n>] [--tour-only=kit,wave]`.

### LAN test (two desktop instances)
Developer user args: `--auto-host`, `--auto-join=<ip>` and `--lan-test` (`tools/lan_test.gd`).
- The host places a purple block and walks along +X; the client places a red block. Both blocks
  are next to the world spawn column, within reach of both players.
- Both print `LANTEST <role> t=… players=… A=… B=… remote=… undo=…` and quit after 30 s. `undo` is
  the player's undo steps, which the host sends back (1 after its block is placed).
- Headless on this PC: give each instance its own `XDG_DATA_HOME` with a `profile.json`, start
  `godot --headless --path . -- --auto-host --lan-test`, then
  `godot --headless --path . -- --auto-join=127.0.0.1 --lan-test`.
- Default port is 24565, with up to 3 clients.
- When the host quits first, the client goes back to the main menu and keeps running there (its
  `--lan-test` quit is gone with the sandbox): run it under `timeout`.
- **Knock-out over LAN** (M2 Task 2): add `--ko` to both, and `--survivor` to the host. At t 16 the
  host gives the guest 5 dirt and knocks them out. The guest logs the fade and getting up, then asks
  for its bag. Look for `LANTEST host ko end guest_hp=20 bags=0 guest_dirt=5`.
- **Totem waves over LAN** (M2 Task 9): add `--wave` to both (and `--survivor --new-world` to the host;
  both then run 40 s). The guest walks to the Totem and asks for wave 1 at t 15; both log every wave
  state with their Totem's glow and line and the HUD's wave line (`LANTEST <role> wave state …`), the
  wave monsters replicated to them (`wave monsters here=5`), and the end (`wave end phase=0 next=2 …`,
  the guest's gold +10).
- **The Stone Golem over LAN** (M2 Task 10): add `--boss` to both (and `--survivor` to the host). At t 12
  the host calls `start_boss` next to itself, at t 18 it defeats the Golem. Both print
  `LANTEST <role> boss t=… golem=… phase=… hp=… bar=… fraction=… title=… music=… portals=… gold=… universe=…`
  every 2 s: the guest must see the Golem, the bar and the boss music, then the portal and (Survivor)
  its gold and universe 2.
- **Co-op games over LAN** (M4 Wave 3 H): add `--games` to both (both run 60 s). At t 18 the host starts
  hide-and-seek with the guest seeking (the guest logs `counting=true`), ends the counting at once, and the guest
  stands 2 blocks from the host and asks to find it; then Storm Run (the guest stands at a star), END GAME, and
  TEAM PHOTO, which the guest taps. Both log `LANTEST <role> games t=… kind=… phase=… counting=… line='…' stars=…
  score=… best=… stickers=… photo='…' ring=…` every 2 s (the host also its `sight` check of the guest).
- **Trading over LAN** (owner #37): add `--trade` to both, and `--survivor` (best with `--new-world`) to the host. At
  t 12 the host gives itself 10 Stone and the guest 3 Diamonds and asks the guest to trade; the guest says YES and
  offers 2 Diamonds, the host 5 Stone, both press READY. Both log `LANTEST <role> trade asked|state|note|ended|line …`
  and at t 16 `LANTEST host trade bag stone=5 diamond=2` / `LANTEST client trade bag stone=5 diamond=1`.

The in-game developer menu (debug builds only) also has HOST LAN / JOIN buttons.

### Safety in the world: the player card (spec §17.3, module 0.2.9)
A tap on another player's name tag opens `PlayerCard` (the TradeDirector makes it in every world: `open_card(peer)` sets
`can_trade`, `online`, `host`). REPORT and BLOCK use `Session.online_user_of(peer)` and the OnlineService; REMOVE is
`Session.host_remove_guest(peer)` (an RPC to the guest first, then online `OnlineService.remove_guest` → the server's
`remove_guest`, or on LAN `ENetMultiplayerPeer.disconnect_peer`). A removed guest's game ends through
`Session._leave_removed()` (never a rejoin); notification 107 (`OnlineRules.REMOVED`) reaches it too. Online the server
strikes them off the invite list; **on LAN** (M5 Task 6 review) the host remembers the address a removed player's game
connected from (`_lan_removed`) and, while it hosts, turns a new connection from there away the same way
(`_lan_turn_away`: the kind words, their hello and ready unheard, the link dropped 0.3 s later); the next `host_lan`
forgets (`test_m5_review_lan_remove.gd`, real ENet on this machine).

### Online test (Nakama relay, M4 early spike)
The game can host and join a Nakama **relayed match** instead of LAN (developer args only, no menu yet):
`--online-host` prints `ONLINE host match_id=<id>`, `--online-join=<id>` joins it, and
`--online-server=<[http[s]://]host[:port]>` picks the server (default: this build's own,
`OnlineConfig.default_server()`: `127.0.0.1:7350` on the desktop, `10.0.2.2:7350` in Android developer
builds, the release server in release builds; `--online-server=release` tries the release server from a
developer build). Everything else (handshake, RPCs, spawners, world sync) is the LAN code.
```bash
server/dev.sh up            # Nakama + PostgreSQL in Docker (compose project "easycraft"); server/README.md
tools/net_test.sh           # two headless instances over the relay check each other; exit 0 = PASS
tools/net_test.sh --lan     # the same check over LAN (ENet), for comparison
tools/net_test.sh --fly     # then the guest flies 150 m: what the world costs a moving guest
tools/net_test.sh --drop=close   # (online) the guest's link drops and it must rejoin within 30 s
tools/net_test.sh --drop=dead    # the same, but the old connection stays open on the server
tools/net_test.sh --drop=never   # the guest can't get back in: it gives up after 30 s and reaches the menu
tools/net_test.sh --no-smooth    # remote bodies not smoothed (to compare the host's "moved in N of M frames")
tools/net_test.sh --server=https://178-104-20-64.sslip.io --invite --delete-accounts   # the live server
tools/net_test.sh --lan --remove   # then the host removes the guest (spec §17.3): menu, the host's words, no rejoin
tools/net_test.sh --crew          # crew flights (spec §21d.9): a 2-seat rocket, LAUNCH, both fly, both on the Moon, HOME
tools/net_test.sh --lan --crew    # the same over LAN (the guest comes back with a new peer id: welcomed by its crew seat)
tools/net_test.sh --crew --drop=close   # the guest's link drops mid-flight: back on board, lands with the crew
tools/net_test.sh --move          # owner #99: one account moved with its 6-digit code (SKIP while the move is off)
tools/net_test.sh --login --delete-accounts   # owner #105: "b" logs in with the name and the password, "a" is logged out
server/dev.sh down          # stop it when done (the database volume is kept)
```
`--crew` (`--net-test-crew`) replaces the edit checks with a crew flight (spec §21d.9, notes
`docs/devlog/parts/crew-flights.md`): the host waits for its Launch Site's pad, builds `NetTest.crew_rocket()` (the Moon
rocket with a second capsule: 45 parts, 3 stages, 2 seats) on it, buys the parts and presses the board's LAUNCH; the
guest's call card appears and it takes its seat; the host flies like a child who presses what is asked and SKIPs to the
landing once in orbit, the guest's flight follows (its cockpit without controls, the chat lent over it; it WAVEs, the
host sees it; on LAN it says "Look!" and the host hears it); both stand in the host's Moon world, the guest's own profile
has the Moon flown and a crew badge; the host's HOME brings both home. The games get 400 s (`timeout`), NetTest 330 s.
It prints `CREW …` lines (the call, the launch, the move with its ms, "guests let go in N ms", "world ready: N hellos
answered", the follow, the welcome). About 90 s on this PC.
A real (production) server lets only **invited friends** into a match (M4 consent gates: a stranger gets
`not_invited`); a development server also lets an unclaimed developer in, which is how the plain run works there.
`--invite` makes it real: `tools/net_test_friends.gd` signs both folders in, claims two random names (`NtH…`, `NtG…`)
and makes them friends (the host asks, the guest says yes), the host game invites the guest as soon as its match
exists (`--net-test-invite`, "NETTEST host … invited <name> ok"), and only then does the guest join.
Each run makes two new accounts (fresh user folders, new device ids). Against the live server always pass
`--delete-accounts`: afterwards `tools/delete_test_account.gd` signs each folder in again and deletes its account
through the game's own data-rights path (`DELETE_ACCOUNT ok deleted <name>`; a failed delete fails the run).
`tools/net_test.gd` (`--net-test`, added by `main.gd` as `/root/NetTest` on both instances) checks: the
host's early edit reaches the guest, both placements seen by both, both undos, the host's walk, RPC
ping, a checksum of the blocks around the spawn, then 10 s of play (the host counts what it sends
the guest: `play streaming`), the flight with `--fly` (`flight streaming`) and the rejoin with
`--drop` (the guest is back at the place its player waited, and sees the block the host placed
meanwhile). The guest also prints its join (and rejoin) time broken down (`join ms since the sandbox
started: sign_in= socket= joined= world_info= world= player= standing=`), and the host how the
guest's body moved on its screen while the guest played (`moved in N of M frames, biggest step`).
It prints `NETTEST <role> ...` lines, the relay traffic per guest (`sent_to`, Godot
packets; `wire_bytes`, the JSON the socket took; `by_kind`, SceneMultiplayer's packet kinds) and the
world sync's counts. Both games run with `--max-fps 60` (`--fps=` changes it): a headless game
otherwise runs as fast as it can, and the traffic grows with the frame rate. Results:
`docs/devlog/parts/m4-online-spike.md` (before), `docs/devlog/parts/m4-a.md` (world sync by edits),
`docs/devlog/parts/m4-a2.md` (rejoin, smoothing, join time, LAN after pacing).

### LOG IN with a password, LOG OUT, one device at a time (owner #99, #104, #105, module 0.2.20)
Notes: `docs/devlog/parts/accounts-99.md`; spec §5.13 "As built (owner #99, #105)". **One player on a device** (the final
review's simple model: no kept player slots). Right after the online name the child makes a password
(`ui/online/password_page.gd`, no LATER; an account from before is asked once, with LATER).
- **LOG IN** (`ui/online/log_in_page.gd`, opened by `AccountsFlow`: the start screen's LOG IN beside PLAY, PLAY ONLINE's I
  HAVE AN ACCOUNT, a taken name's YES, the main menu's LOG IN, a logged-out device) sends the name and the password
  (`OnlineService.log_in` → `log_in_with_password`), or a grown-up's key (`sign_in_with_key`), on a second connection
  with this device's own asking credential `user://login_device.json` (`_ask_to_log_in`; remade once on a 404 or 403).
  The server links a new id of this device and logs every other device out. `OnlineService._become` then makes this
  device play as the account: the same account as before (known by its user id, `OnlinePrefs.account_id`; logged out
  elsewhere) keeps what was played here; any other starts from a fresh player (the account files forgotten, a new
  profile that takes the account's gold as the server has it: `_adopt_server_gold`), so nothing merges into it and gold
  can't double. The account's profile backup comes down. **Before that, the page asks** when this player's gold and
  progress would go (`OnlineService.progress_goes`, `DeviceMoveRules.has_progress` / `NOT_PROGRESS`; the pages' `goes`):
  "Pip's gold and progress on this device will go. Your worlds stay. Log in as Anna?" YES / NO (LOG IN and the key page).
- **LOG OUT** (`OnlineService.log_out`; the main menu's own button, SETTINGS, PLAY ONLINE; one tap and YES, never the
  parent gate): saved to the account first (offline: refused), and only when every coin is on the server (the phone's
  gold equals the wallet marker after the sync: over the hourly cap `GOLD_ON_ITS_WAY`, a gold piece or a backup the server
  refused `NOT_SAVED`; `save_for_log_out`); an account with no password makes one first
  (`LOG_OUT_NEEDS_PASSWORD` → "Make a password first, so you can log back in."); the server's `log_out` unlinks this
  device (a placeholder custom id first when it is the account's last one) and tombstones its id; then
  `forget_player()`: the account files (`forget_online`) and the player (`_fresh_profile`: the profile file goes,
  `Profile.reload()`) go; **the worlds stay** (they belong to the device). The start screen opens (`AccountsOverlay.to_menu`).
- **A logged-out device** (another device logged in, or the account was deleted): `sign_in` uses `create=false` once a
  device id file exists; the server refuses a tombstoned id with PERMISSION_DENIED `device_logged_out`, which the
  backend maps to `device_logged_out` and the service to `logged_out` ("This device was logged out. LOG IN to play
  here.", `ui/online/logged_out_card.gd`, layer 93, with LOG IN, NEW PLAYER (asks first) and LATER; LOG IN and NEW PLAYER on
  the main menu only, a world says "Go to the main menu to LOG IN."), whatever its prefs say. It
  never makes a new account by itself. A plain 404 with no kept name (a never-claimed account the clean-up removed)
  starts anew.
- **DELETE** asks for the password and calls `forget_player()` for the game's own player (worlds stay).
- **The move by code rests** (`DeviceMoveRules.enabled`, the server's `MoveRules.ENABLED`); its last step is
  `move_sign_in` (the main connection: the one-time key is the device's own account's).
```bash
npm --prefix server/modules test                       # passwords_rpcs (the two windows, log_out), account_lockout, keys
EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/passwords.server.ts   # + timing, LOG OUT
tests/run_tests.sh -gtest=res://tests/integration/test_log_out.gd,res://tests/integration/test_account_password.gd
tools/net_test.sh --login --delete-accounts   # two headless games: LOG IN with the password; the other is logged out
```
- **A word or a rule of passwords** lives in `core/net/password_rules.gd` (`PasswordRules`) and, for the rules, again in
  `server/modules/src/rules/password_rules.ts` (the same COMMON list, RUNS and RUN_LEN: `test_account_password_rules.gd`
  checks the game's side). The game's COMMON list is `core/net/common_passwords.gd` (never shown; the banned-name check
  of shipped strings in `test_costumes.gd` leaves it out). Never tell a child why a log-in failed beyond "That name and password don't match."
- **The brake is frozen** (the lead, after three reviews): the pair window and the name window only
  (`server/modules/src/server/passwords.ts`'s header). Do not add windows, growth or decay.
- **A coroutine of one session** that writes the profile, the account or the wallet after an await checks
  `OnlineService._stale(s)` with the `session` it started with (`forget_session` bumps it), and LOG IN and LOG OUT refuse
  while `OnlineService.busy()` (a sign-in, a wallet sync, a paid code, a gold report, the profile backup on its way).
- Testing on a private Nakama for a worktree (the README's recipe): an override file with
  `services: {postgres: {container_name: easycraft_acct99-postgres}, nakama: {container_name: easycraft_acct99-nakama}}`,
  `NAKAMA_GRPC_PORT=7499 NAKAMA_HTTP_PORT=7500 NAKAMA_CONSOLE_PORT=7501 docker compose -f server/docker-compose.yml -f
  <override> -p easycraft_acct99 up -d --wait`, then `--server=127.0.0.1:7500` / `EASYCRAFT_SERVER=http://127.0.0.1:7500`;
  `docker compose ... -p easycraft_acct99 down -v` afterwards.


### Hosting kit (the owner's server on the internet, M4 D)
`server/deploy/` runs the same server on a VPS: Nakama (a multi-stage image with the module built in),
PostgreSQL 16, Caddy with automatic HTTPS on 443 (WebSocket upgrade for `wss://`), a daily backup
service (7 kept) and `kit.sh` for everything (`keys`, `up`, `status`, `check`, `logs`, `access`,
`backup`, `restore`, `update`, `down`, `console`, `pack`). Secrets come from `server/deploy/.env` (git-ignored;
`kit.sh keys` makes it from `.env.example`); `nakama/start.sh` refuses empty or default secrets and
writes them to a config file in memory. The owner's step-by-step guide, sizing and cost estimates:
`docs/hosting.md`. Measurements and rulings: `docs/devlog/parts/m4-d.md`.
- **Game side:** release builds use `OnlineConfig.RELEASE_SERVER` (https only; empty until the owner
  has a server, then release builds offer no online play) with `RELEASE_SERVER_KEY`, which must equal
  `NAKAMA_SERVER_KEY` in `.env.example`; `OnlineConfig.key_for(server)` picks the key for a server.
- **Try it on this PC** without touching the development server (commands at the top of
  `server/deploy/local-try.yml`): compose project `easycraft_d`, Caddy on 127.0.0.1:8480/8443 with its
  local certificate, then `kit.sh check https://localhost:8443`. Remove it with
  `docker compose -p easycraft_d down -v`. Never `kit.sh update` on this PC (it pulls shared image tags).
- `tests/unit/test_hosting_kit.gd` keeps the kit in step with the game: the release key, the relay
  settings of `server/nakama/local.yml` (a change there must go into `server/deploy/nakama/production.yml`
  too), every secret checked, only 80/443 published, and (M4 G) the logs: every service's Docker log
  limited, Caddy's access log rolled every midnight and gone within 14 days, no addresses, tokens or
  headers where they must not be (`caddy validate` with the kit's image checks the Caddyfile itself).
The server module (M4 Wave 1, agent B) has its own tests, and its RPCs, hooks and switches are listed
in `server/README.md`:
```bash
npm --prefix server/modules test                  # the Node tests: rules and glue on a fake Nakama
EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server   # against a running server
```
Agent F's real-server checks (friend approvals, codes by hash, the profile backup, host wallets) are in
`server/modules/test/integration/parents.server.ts` and `nakama.server.ts`; the GUT test
`tests/integration/test_nakama_profile_backup.gd` takes `EASYCRAFT_TEST_SERVER=<host:port>` to run
against another server than 7350 (it prints `MEASURE` timings). Agent G's (M4 Task 8b: account
deletion, retention, report snapshots) are in `server/modules/test/integration/data_rights.server.ts`;
they also use the console (`EASYCRAFT_CONSOLE`, default the HTTP port + 1) and the runtime HTTP key
(`EASYCRAFT_HTTP_KEY`, default `defaulthttpkey`). Agent I's (M4 Wave 3: gifts, showcases, bottles, build
reports, and their deletion and retention SQL) are in `server/modules/test/integration/gifts.server.ts`.
Joining a match needs an invite from its host, except for developer accounts that never claimed a
username while `EASYCRAFT_DEV_OPEN_MATCHES=true` (`server/nakama/local.yml`), which is what the
developer args, `tools/net_test.sh` and the GUT relay tests use.

### Friends apart: smoke run and the build viewer (M4 Wave 3, agent I)
```bash
XDG_DATA_HOME=/tmp/easycraft-gifts-smoke godot --headless --path . --script res://tools/gifts_smoke.gd
godot --headless --path . --script res://tools/show_build.gd -- --file=<a build's text>   # or -- --build=<text>
EASYCRAFT_SERVER=http://127.0.0.1:<port> node --test server/modules/test/integration/gifts.server.ts
```
- The smoke run (a fresh private folder whose path contains "smoke", with a `profile.json`) plays two
  players on the game's fake server (`tests/fakes/`) in a NEW Sandbox world: SHARE in the MORE panel,
  a picked build sent and opened into a stamp, the showcase put up, a bottle floating up and opened, two
  buddies on a playdate, then the friend visits the showcase (the visit scene) and leaves a sticker.
  Prints `GIFTS_SMOKE ok|FAIL` and `MEASURE` lines; exits 0 when all passed.
- `show_build.gd` prints a build (a report's `build` text, or the whole report's JSON) layer by layer
  as letters with a legend: how a person reviewing a report sees a reported build (`docs/hosting.md`).

### Ghost races: smoke run and the two-game net test (M4)
```bash
XDG_DATA_HOME=/tmp/easycraft-ghosts-smoke godot --headless --path . --script res://tools/ghosts_smoke.gd
tools/ghost_net_test.sh --server=127.0.0.1:7350     # two headless games over a real server (module 0.2.6+)
EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test server/modules/test/integration/ghosts.server.ts
```
- The smoke run (a fresh private folder whose path contains "smoke", with a copy of `profile.json`) plays two
  players on the game's fake server: Hopper builds a course in a NEW Sandbox world and races it with his feet
  on the real blocks, puts his showcase up (his race goes with it), beats his time (it replaces his ghost),
  gifts Mia the whole course with his race; Mia visits and races his ghost, again offline, then stamps the
  gift in her own new world and races it there. Prints `GHOSTS_SMOKE ok|FAIL` and `MEASURE` lines; exit 0
  when all passed.
- The net test makes two throwaway 13+ accounts (friends), shares, visits, races in the real visit scene and
  deletes both accounts. It needs a server running module 0.2.6 or later (the lead's development server
  after the deploy, or a private one: an override file with other container names, `-p <project>` and
  other ports, as `server/README.md` says). Prints `GHOSTNET` lines and `GHOSTNET PASS`.

### Weapons smoke run (headless)
`tools/weapons_smoke.gd` starts a new Sandbox world and checks weapons end to end: sword in the hand,
dummy placed and hit, arrow, boomerang, axe fells a tree, hammer smash, pickaxe step, targets saved.
It overwrites the sandbox save slot, so give it a **private user folder** (every worktree and the real
game share `~/.local/share/godot/app_userdata/EasyCraft`); it refuses to run otherwise, and the
folder's path must contain "smoke". Use a **fresh folder for each run**: a folder an earlier run used
still holds the edited world, and the run then fails at "found a flat spot for a dummy".
```bash
XDG_DATA_HOME=/tmp/easycraft-smoke godot --headless --path . --script res://tools/weapons_smoke.gd
```
It prints `WEAPONS_SMOKE ok|FAIL …` lines and exits 0 when everything passed. Scripts run with
`--script` cannot use autoload names, so its steps live in `tools/weapons_smoke_steps.gd`, loaded at run time.

### Knock-out smoke run (headless, M2 Task 2)
`tools/knockout_smoke.gd` (steps in `tools/knockout_smoke_steps.gd`) starts a **new Survivor world**:
- It knocks the player out: the hearts, the fade, the message and tip, a bag with the starter
  blocks, tools kept, no more damage.
- The player gets up at the world spawn with full hearts and protection; the bag is in `world.json`.
- A real tap on the bag gives every block back.
- Under Sandbox rules, the player pops up on the spot keeping everything.

Same rules as the weapons run: a private, **fresh** user folder whose path contains "smoke".
```bash
XDG_DATA_HOME=/tmp/easycraft-ko-smoke-1 godot --headless --path . --script res://tools/knockout_smoke.gd
```
It prints `KO_SMOKE ok|FAIL …` lines and exits 0 when everything passed.

### Monster smoke run (headless, M2 Task 4)
`tools/monster_smoke.gd` starts a **new** Survivor world (or Sandbox with `-- --smoke-sandbox`) and checks
night monsters end to end on real terrain: spawns 18–40 blocks away on the surface, a summoned goblin
hurts the player, coins pay once (Survivor) or confetti only (Sandbox), MONSTERS: OFF, the sunrise puff.
It ends with a cost window (quiet, then 20 active monsters). Same rules as the weapons smoke run: a
fresh private user folder whose path contains "smoke" (copy a `profile.json` into it).
```bash
XDG_DATA_HOME=/tmp/easycraft-monster-smoke godot --headless --path . --script res://tools/monster_smoke.gd
```
It prints `MONSTER_SMOKE ok|FAIL …` and `MONSTER_SMOKE cost …` lines and exits 0 when everything passed.
Frame times from it are only meaningful on a quiet PC; for monster cost, time `Monster._physics_process`
per call (see `docs/devlog/parts/m2-task-4.md`). Since knock-outs (Task 2), the 20 summoned monsters
knock the player out in the cost window, and sometimes every monster is despawned during the respawn
("FAIL 20 monsters (0)", about 1 run in 4; `docs/devlog/parts/m2-task-5.md`, "Found").

### The Dragon Realm's monsters: sounds and cost bench (owner feedback #39)
```bash
python3 tools/make_dragon_monster_sounds.py                            # shadow bat and wisp sounds (original)
godot --headless --path . --script res://tools/dragon_monster_bench.gd # writes nothing
```
The bench rings a walking player with 20 ice bats, 20 shadow bats and 20 wisps on a flat stand-in world, the groups
taking turns in 2 s blocks, and prints `DRAGON_BENCH` lines: each group's physics step and looks (`_process`) per
frame, in this thread's CPU time. Numbers: `docs/devlog/parts/owner-39-dragon-monsters.md`.

### Bot friends smoke run (headless, M2 Task 15)
`tools/bots_smoke.gd` starts a new Sandbox world and checks bot friends on real terrain: three join
(a fourth is refused), they pop up next to the player after a 40-block jump, a builder builds next to the
player's block, a fighter hits a stand-in monster, a knocked-out friend is back after 10 s, the friends
are saved, one says bye. It also times the friends' own physics steps (decision steps and move steps
apart) against a control workload, and on a failed build it prints why no spot fitted.
```bash
XDG_DATA_HOME=/tmp/easycraft-botsmoke godot --headless --path . --script res://tools/bots_smoke.gd
```
Use a fresh private folder for each run (the path must contain "smoke"). Prints `BOTS_SMOKE ok|FAIL …`
lines and exits 0 when everything passed.

### Talking to bot friends: smoke run (headless, owner feedback #38)
`tools/bot_talk_smoke.gd` starts a new Sandbox world (a fresh profile: an under-13 child), adds a builder and
an explorer and talks to them through the HUD's chat bar and the host's path (`Session.request_bot_talk`):
they follow, build a house next to the child on real ground, the explorer tells where the world's nearest
secret is and leads the child there, and they answer the day clock, Tilly (no shop in Sandbox), a thank-you
and words they don't know. Prints every bot answer.
```bash
XDG_DATA_HOME=/tmp/easycraft-talksmoke godot --headless --path . --script res://tools/bot_talk_smoke.gd
```
Use a fresh private folder for each run (the path must contain "smoke"). Prints `BOT_TALK_SMOKE ok|FAIL …`
lines and exits 0 when everything passed.

### Secrets: smoke run, screenshots, pictures and sounds (M2 Task 16)
```bash
XDG_DATA_HOME=/tmp/easycraft-smoke-secrets godot --headless --path . --script res://tools/secrets_smoke.gd
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --resolution 1280x720 --script res://tools/secrets_shots.gd
godot --headless --path . --script res://tools/make_secret_pictures.gd   # data/secrets/pictures.png
python3 tools/make_secret_sfx.py                                         # assets/audio/sfx/sparkle.wav, …
```
- The smoke run starts a new Sandbox world of seed 12345 and goes through the nearest buried treasure,
  hidden room, puzzle temple and the Wanderer with the real systems; it prints `SECRETS_SMOKE ok|FAIL …` and
  exits 0 when all passed. Like the weapons smoke run it overwrites the sandbox slot: use a fresh folder
  whose path contains "smoke".
- The screenshot tour needs a window (headless draws nothing) and a folder containing "shots"; the PNGs go to
  `$XDG_DATA_HOME/secret_shots/`.
- In the game, the Sandbox cheat `/secret [treasure|room|temple|island|geode]` names the nearest secret nobody
  found yet, with a `/tp` next to it.

### Treasure pack: smoke run, screenshots, pictures and sounds (owner feedback #42)
```bash
XDG_DATA_HOME=/tmp/easycraft-smoke-treasure godot --headless --path . --script res://tools/treasure_smoke.gd
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --resolution 1280x720 --script res://tools/treasure_shots.gd
godot --headless --path . --script res://tools/make_treasure_pictures.gd   # data/secrets/treasure_pictures.png
python3 tools/make_treasure_sfx.py                                         # giggle.wav, coin_toss.wav, rainbow.wav
```
- The places (`world/generators/treasure_places.gd`, `TreasurePlaces`) are SecretRules secrets: SecretRules
  builds them after its own M2 kinds (`SecretRules.more`; `SecretRules.new(seed, shape, false)` is the world
  without them), so every generator writes them and M2 ids never move. Kind names have no `_` (ids are
  `<kind>_<ax>_<az>_<attempt>`). Their host logic is `TreasureDirector`, the SecretDirector's child `Treasures`;
  chests of the pack roll through `TreasureLoot` (LootRules.roll hands them over).
- The smoke run (38 checks) starts a new Sandbox world of seed 12345: the nearest camp, vault (real lever
  taps), haunted house, wishing well, `/secret rainbow` and the save. The screenshot tour needs a window and a
  folder containing "shots"; PNGs go to `$XDG_DATA_HOME/treasure_shots/`.
- `/secret shipwreck|sunken|mineshaft|vault|waterfall|hollowtree|well|cove|ruins|haunted|camp` finds the nearest
  one; `/secret rainbow` brings a rainbow now (Sandbox cheats). Weather: call `SecretDirector.treasures.rain_ended()`
  when rain stops (a rainbow by day).
- Pictures with ids 32+ are in the pack's own atlas (`Pictures` picks it); import it with
  `detect_3d/compress_to=0` like the M2 atlas (the lever signs use it in 3D: no VRAM compression).

### Pictures of the HUD (M2 Task 17)
```bash
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/hud_shots.gd
```
Needs a window (headless draws nothing). It builds the HUD over a plain background (a player standing in
empty air, no world, no save) on the emulator's 20:9 canvas (a 1600 × 720 window) and a 16:9 phone
(1334 × 750): awake with a sword, SLEEP and HELP UP (and M3 Task 22's game clock); MORE open; the Survivor palette's
CRAFT page; flying; asleep; plus a sheet of every
`HudIcons` picture. PNGs go to `$XDG_DATA_HOME/godot/app_userdata/EasyCraft/hud_shots/`; it prints
`HUD_SHOT` lines.

### Pictures of the chat (owner feedback #49)
```bash
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/chat_shots.gd
```
Windowed, like the HUD pictures. A 13+ player's crowded Survivor HUD (a game's round line and clock, the Brave
badge) over a bright sky, with friends' lines (a long one, an emoji, an emote, a bot's answer) and a dark
stand-in for a phone keyboard over the bottom 55 % of the screen: closed, open with the phrases, typing,
"/" commands, and the quick-chat wheel; at 1600 × 720 (the emulator's 20:9) and 1280 × 720. PNGs go
to `$XDG_DATA_HOME/godot/app_userdata/EasyCraft/chat_shots/`; it prints `CHAT_SHOT` lines.

### The look: fixed views, pictures and a bench (the visuals brief, 2026-10-01)
```bash
XDG_DATA_HOME=/tmp/easycraft-look-shots godot --path . --disable-vsync --resolution 1600x720 \
  [--rendering-method gl_compatibility] --script res://tools/look_shots.gd -- --universe=1 --tag=before
#   --universe=1: Green Meadows noon, morning, sunset, night, the ground, the sea's shore, a cave; 16 19 24 25 41 and
#   any other: noon, sunset, night over the landing; --menu the title screen; --style=blocky|realistic; --views=noon,...;
#   --frames=90; --no-shots; --env=tonemap_mode:3,tonemap_exposure:0.75,fog_begin:0.5 (try Environment settings);
#   --no-shadows, --no-lantern (the sun's shadows, the cave lantern off: one cost alone)
```
Windowed (a private folder whose path contains "shots", with a copy of `profile.json`; it starts a NEW Sandbox world of
seed 12345). JPEGs 1200 wide in `$XDG_DATA_HOME/look_shots/<tag>/<renderer>/` and a `LOOK_BENCH` line per view: the
frames' average and worst wall time, the **GPU time** (RenderingServer's measure: compare this between runs; the wall
time on this shared PC is other programs' too), the render CPU time, draw calls and primitives. Take the pictures on
**both renderers**: `gl_compatibility` is the web's, the emulator's and a phone without Vulkan; the default (`mobile`,
Vulkan) is a phone's. The window's size is the screen's shape (`--resolution 1280x720` for 16:9, `960x720` for 4:3).
What was measured, the before and after pictures and the rulings: `docs/devlog/parts/visuals.md`.

### The Google Play store pictures (docs/store/screenshots.md)
```bash
XDG_DATA_HOME=/tmp/easycraft-store-shots godot --path . --disable-vsync --resolution 1920x1080 \
  --script res://tools/store_shots.gd -- --touch [--only=wake,size,portal,dragon,dog,hide,race,book,feature]
```
Windowed, with the phone's touch HUD (`--touch`); the path must contain "shots" (it starts new Sandbox worlds and
writes a made-up player's profile there). The eight screenshots' moments and the feature graphic's photo, each in a
new world of its own, set up through the chat runner, Session's requests and the directors; 1920 × 1080 JPEG
candidates in `$XDG_DATA_HOME/store_shots/`, `STORE_SHOT` lines; about 15 minutes. Pick by eye, copy to
`docs/store/graphics/next/` (`.gdignore`). Set-up, picks and compromises: `docs/devlog/parts/store-shots.md`.

### Wave smoke run (headless, M2 Task 9)
`tools/wave_smoke.gd` (steps in `tools/wave_smoke_steps.gd`) starts a new Survivor world (or Sandbox with
`-- --smoke-sandbox`) and checks the Monster Totem on real terrain: it stands on the ground about 20 blocks
from the spawn and is saved; a real tap through the camera opens its panel; START counts down on the HUD
while it glows; wave 1's monsters appear on solid ground at the edge of the 25-block circle and walk to the
Totem; defeating them pays 10 gold (none in Sandbox) and `world.json` keeps wave 2; a knock-out ends wave 2
and the panel offers TRY AGAIN and an easier wave. It ends with a cost window: wave 9 (20 monsters, 8 in
Sandbox) around the player. Same rules as the other smoke runs (fresh private folder with "smoke" in its
path and a copy of `profile.json`).
```bash
XDG_DATA_HOME=/tmp/easycraft-wave-smoke godot --headless --path . --script res://tools/wave_smoke.gd
```
It prints `WAVE_SMOKE ok|FAIL …` and `WAVE_SMOKE cost …` lines and exits 0 when everything passed.

### Stone Golem smoke run (headless, M2 Task 10)
`tools/boss_smoke.gd` (steps in `tools/boss_smoke_steps.gd`) starts a **new** Survivor world (or Sandbox
with `-- --smoke-sandbox`) and checks the boss on real terrain: the Golem rises next to a stand-in Totem
(the sandbox's `start_boss`, or `summon_boss` in Sandbox) with the HUD bar and the boss music, its slam
hurts the player next to it and it is dazed after (double damage), a win pays 300 gold and unlocks
universe 2 (Survivor; nothing in Sandbox), opens the portal on the ground and saves the world, and a lost
fight shows "You got it to 50%!" and is saved as help. It prints frame times without the Golem, during
the fight and next to the portal.
```bash
XDG_DATA_HOME=/tmp/easycraft-boss-smoke godot --headless --path . --script res://tools/boss_smoke.gd
```
Same rules: a fresh private folder whose path contains "smoke", with a `profile.json` in it. It prints
the world's seed; `-- --smoke-seed=<n>` repeats a world.

### Universe ladder and portals: smoke run, developer arg, block page 5 (M3 Task 5)
```bash
XDG_DATA_HOME=/tmp/easycraft-universe-smoke godot --headless --path . --script res://tools/universe_smoke.gd
XDG_DATA_HOME=<private dir with profile.json> godot --headless --path . -- --survivor --new-world --universe=2
godot --headless --path . --script res://tools/make_portal_page.gd   # data/blocks/pages/portals.png (pixel)
python3 tools/make_portal_page.py                                     # portals_albedo.png, portals_normal.png
```
- The smoke run starts a new Survivor world (a fresh private folder whose path contains "smoke", with a
  `profile.json`): the stone circle and the hub panel, travel to universe 2 (a stand-in universe,
  `tests/fakes/fake_universe.gd`) with the bag, back again, the Golem's portal's words and walk-in, then two
  portal frames built with blocks link and carry the player. Prints `UNIVERSE_SMOKE ok|FAIL …`; exits 0 when
  all passed. It replaces the Survivor worlds of universes 1 and 2 in that folder.
- `--universe=<u>` (with `--survivor`, or `--auto-host --survivor`) plays universe u's world (`survivor_u<u>`).
- Page 5's import settings are the atlases': pixel lossless with mipmaps, realistic VRAM-compressed with
  mipmaps, the normal map flagged as a normal map, detect-3D off.

### Universe portals you build: smoke run (headless, owner feedback #39)
```bash
XDG_DATA_HOME=/tmp/easycraft-portals-smoke godot --headless --path . --script res://tools/portals_smoke.gd
python3 tools/make_dragon_pet_sfx.py    # the pet dragon's chirps and the egg's crack (original)
```
A fresh private folder whose path contains "smoke", with a copy of `profile.json`. A new Sandbox world: a frame with the
Desert Crystal's core (placed through Session) swirls in the desert's colours, walking in opens the desert's own Sandbox
world (`sandbox_2`) where a portal back stands in front of the child, and walking into it comes out in front of the
first portal; then a new Survivor world: the crystals of the universes reached are in the bag, a crystal placed in a
frame is paid from the bag, walking in travels with the bag to `survivor_u2`, and its portal back stands there. Prints
`PORTALS_SMOKE ok|FAIL …`; exits 0 when all passed. It replaces the Sandbox and Survivor worlds of universes 1 and 2.

### Survivor games, crafting and Monster Wave smoke run (headless, M3 Task 22)
`tools/survivor_games_smoke.gd` (steps in `tools/survivor_games_smoke_steps.gd`) starts a **new** Build to
Survive world, then a new Monster Wave arena, on real terrain: the quick-start kit and the night clock (3:00), no
Totem in Survivor; a plank hut built round the player through the host's edits is a shelter, an open door is a gap;
at night a goblin can't see the player inside; the sunrise counts a night; planks and a table by hand, a furnace at
the table, glass at the furnace, the CRAFT page's 28 cards; a knock-out at night brings the morning and ends the run;
`world.json` keeps the game and the scores. Then the arena: flat, the kit, the Totem in the middle, wave 1 by itself,
the kill bonus with the combo and no coins, the breather, no building or flying, a knock-out ends the run with gold
for the time and the wave, the result panel, the best saved, PLAY AGAIN.
```bash
XDG_DATA_HOME=/tmp/easycraft-games-smoke-1 godot --headless --path . --script res://tools/survivor_games_smoke.gd
```
A fresh private folder with "smoke" in its path and a copy of `profile.json`. Prints `GAMES_SMOKE ok|FAIL …`;
exits 0 when every check passed. Notes and rulings: `docs/devlog/parts/survivor-games-crafting.md`.

### Progress smoke run (headless, M3 Task 12)
```bash
XDG_DATA_HOME=/tmp/easycraft-progress-smoke godot --headless --path . --script res://tools/progress_smoke.gd
```
A fresh private folder whose path contains "smoke", with a copy of `profile.json` in
`godot/app_userdata/EasyCraft/`. It starts a new Survivor world and goes through the real systems: the world
counts and sets the name tag code; two planks placed; the wand wakes them; three goblins beaten next to the
player finish "Beat 3 goblins" and the host pays its 40 gold; a dog tamed with taps; the dog's present after
active play (the HUD's banner); the present opened on the pause menu's BOARD (the host gives 2 lanterns); a
new place; a secret found and a photo saved (the sandbox's wiring); the profile on disk. Prints `PROGRESS_SMOKE ok|FAIL …`; exits 0 when every check passed.

### Books and memories smoke run (headless, M3 Task 21b)
```bash
XDG_DATA_HOME=/tmp/easycraft-books-smoke godot --headless --path . --script res://tools/books_smoke.gd
```
A new Survivor world through the real systems: the `Books` director and this universe explored; the Hub Tree beside the
stone circle, on the ground, with one crown; a summoned cow met; a photo badge and a woken buddy kept as memories and a
photo saved soon after given to the newest (its small copy in `user://memories/`); a trophy shelf placed through the host's
edit path showing the badges; the first Secret Book page's last secret giving the Fairy Wings and the tree's star; a tap
on a bookshelf (the camera aimed from the eyes) opening the book on MEMORIES; the saving bar under the gold; `profile.json`
keeping the books. Prints `BOOKS_SMOKE ok|FAIL …`; exits 0 when all passed. A fresh private folder whose path contains
"smoke", with a copy of `profile.json`.

### Quests smoke run (headless, owner #45a)
```bash
XDG_DATA_HOME=/tmp/easycraft-quest-smoke godot --headless --path . --script res://tools/quest_smoke.gd
```
A fresh private folder whose path contains "smoke", with a copy of `profile.json` in
`godot/app_userdata/EasyCraft/`. It starts a new Survivor world in the Sandstorm Desert: Zara stands by the spawn
at her seed spot, on the ground, with a "!"; a real tap on her opens her card; LET'S GO starts "The golden
scarab"; the arrow points at the nearest buried treasure; an explorer bot asked to "follow the arrow" leads there;
the treasure found (the Secret Director's find path), the walk to the pyramid, the pyramid solved and the walk
back end the story (keepsake, title on the name tag, 200 gold from the host, a place); the quest book, the Secret
Book's keepsakes page and the profile on disk. Prints `QUEST_SMOKE ok|FAIL …`; exits 0 when every check passed.

### Shop and trading smoke run (headless, owner #37)
```bash
XDG_DATA_HOME=/tmp/easycraft-trade-smoke godot --headless --path . --script res://tools/trade_smoke.gd
```
A fresh private folder whose path contains "smoke", with a copy of `profile.json` in
`godot/app_userdata/EasyCraft/`. A new Survivor world in the Sandstorm Desert: the first-time tip and its arrow at
Tilly; MORE → SHOP's card with her distance; SHOW ME points the find arrow; standing by her opens her shop by itself;
Zara's stand beside her, a real tap opens "Zara's stand", a purchase through the host; the host's clock past a
sunrise into day 2 brings Nico's cart beside Tilly's stall with the banner, a real tap opens "Nico's Market", a
purchase at his fixed price; sunset takes the cart; the save keeps the day count. Prints `TRADE_SMOKE seed …` and
`TRADE_SMOKE ok|FAIL …`; exits 0 when every check passed. `TRADE_SMOKE_SEED=<seed>` makes that world again.

### Gold Farm smoke run (headless, M3 Task 10)
```bash
XDG_DATA_HOME=/tmp/easycraft-farm-smoke godot --headless --path . --script res://tools/farm_smoke.gd
```
A fresh private folder whose path contains "smoke", with a copy of `profile.json` in
`godot/app_userdata/EasyCraft/`. It starts a new Survivor world and goes through the real systems: Tilly sells one
farm; the FARM item placed on flat ground near her builds it; the barn's floor holds a player; a tap on the barn
opens its panel and FASTER buys a second worker; leaving inside is saved; SAVE & QUIT, the away record moved 3 hours
back on disk, CONTINUE: the welcome-back pays 90 gold once (banner, coin shower); a record in the future pays
nothing; MOVE and placing it again keep its level. Prints `FARM_SMOKE ok|FAIL …` and a `cost` line (the workers'
animation step); exits 0 when every check passed. It replaces the Survivor world of universe 1 in that folder;
`-- --smoke-seed=<n>` repeats a world (a failed search for flat ground prints its seed and why each spot said no).

### Smart blocks and Game Blocks: smoke run, block page 9 (M3 Task 7)
```bash
XDG_DATA_HOME=/tmp/easycraft-smart-smoke godot --headless --path . --script res://tools/smart_smoke.gd
godot --headless --path . --script res://tools/make_smart_page.gd   # data/blocks/pages/smart.png (pixel)
python3 tools/make_smart_page.py                                    # smart_albedo.png, smart_normal.png (after the pixel page)
```
- The smoke run starts a new Sandbox world (a fresh private folder whose path contains "smoke", with a
  `profile.json`), lays a floor next to the player and, with the real voxel library and physics: a lever
  lights a lamp, a button opens a powered doorway for a second (a physics ray goes through it while it is
  open), a plate opens it while the player stands on it, two teleport pads carry the player across (and not
  straight back), a course is run (START, a coin, a checkpoint and a fall back to it, FINISH: a gold medal on
  the race clock), a bot friend races the recorded best run, and the pads and the course are in `world.json`.
  Prints `SMART_SMOKE ok|FAIL …`; exits 0 when all passed. It replaces the Sandbox world in that folder.
- The realistic page is painted from the pixel page's designs: run `make_smart_page.gd` first. Import
  settings are the atlases' (pixel lossless with mipmaps; realistic VRAM-compressed, the normal map flagged).

### Action kit smoke run (headless, M3 Task 14b)
`tools/action_kit_smoke.gd` (steps in `tools/action_kit_smoke_steps.gd`) starts a new Survivor world (Cozy)
and checks the blasters, goblin archers and surprise drops on real terrain through the real systems: foam
darts defeat a summoned goblin and use up one dart a shot from the bag; a bubble traps a level 2 goblin
(everyone sees the bubble); a summoned archer backs off, draws its bow and its arrow hits the player standing
still; a Party Piñata floats down 8-30 blocks away, lands and bursts after 3 hits into supplies; a supply
balloon comes in a wave from 3, settles beside the Totem and pops into a potion and ammo; then a cost window
(foam darts at 8 monsters for 5 s, `ACTION_SMOKE cost …`).
```bash
XDG_DATA_HOME=/tmp/easycraft-action-smoke godot --headless --path . --script res://tools/action_kit_smoke.gd
```
A fresh private folder with "smoke" in its path and a copy of `profile.json`. Exits 0 when every check passed.

### Rideable buddies: smoke run, the saddle's tiles (M3 Task 20a)
```bash
XDG_DATA_HOME=/tmp/easycraft-ride-smoke godot --headless --path . --script res://tools/ride_smoke.gd [-- --smoke-seed=<n>]
godot --headless --path . --script res://tools/make_portal_page.gd   # page 10's pixel tiles, the saddle's too
python3 tools/make_portal_page.py                                    # their realistic twin (CC0 ambientCG Leather026)
```
- The smoke run starts a new Sandbox world (a fresh private folder whose path contains "smoke", with a
  `profile.json`), lays a stone pad at the spawn and, with the real systems: a dragon built sideways with a SADDLE
  (placed through the host's edit path) wakes with the wand ("Your dragon can fly!", turned a quarter to fly
  forwards, one collision shape), RIDE gets on, the wand can't put it to sleep while ridden, it flies 60 s ahead over
  the terrain about 14 blocks above the ground (never over 11 m/s), dives to land, HOP OFF puts the child beside it
  (never inside blocks); the saddle is saved; the same flight without a dragon (the player's free Fly, the other
  way) for comparison; then a car on its road climbs a 1-block step, bumps off a 2-block wall and JUMP gets off.
  It prints `RIDE_SMOKE ok|FAIL …` and `RIDE_SMOKE cost phase=<stand|fly|fly_plain|drive> …` lines (frames, the
  physics step, the ridden buddy's own step and the player's, timed by the run) and exits 0 when all passed.
  Numbers: `docs/devlog/parts/m3-task-20a.md`.
- The Python twin needs the `make_portal_page.gd` page first only for the layout; both keep the other owners'
  tiles byte-identical (new tiles are drawn after the old ones).

### Cars: smoke run and sounds (owner #109)
```bash
XDG_DATA_HOME=/tmp/easycraft-cars-smoke godot --headless --path . --script res://tools/cars_smoke.gd [-- --smoke-seed=<n>] [-- --kinds=race_car,sky_taxi]
python3 tools/make_car_sfx.py   # the horns, the vroom and the two loops (then --import; the loops' .import say loop_mode=2)
```
- A new Sandbox world (a fresh private folder whose path contains "smoke", with a `profile.json`), solo. A straight
  stone road 7 wide (4 blocks of air above it) runs from the spawn along -z at the spawn's height, laid ahead of the car
  where the world is loaded. For each kind in the garage's order, through the real systems: the garage's request brings
  the car in front of the child, the child gets in (the RIDE button says DRIVE for the first; a tap's request after),
  drives 300 m (the stick as Input actions, steered along the road) or flies 300 m (JUMP up to about 12 blocks over the
  ground ahead, then ahead; LAND through the HUD's FLY / LAND button), stops and hops off with the RIDE button. Every car
  starts where the last was left: 2.4 km of road in all, the race car at 14 m/s. Checks: each car's top speed (its
  kind's; never past 14 m/s), the flying cars' ceiling, HOP OFF never inside blocks nor in the car, the ground 24 m
  ahead ready (`WorldService.is_area_ready`) in at least 90 % of the samples while a car went faster than 8 m/s, the save
  keeping the child's 4 cars out. `CARS_SMOKE ok|FAIL …` lines and one `CARS_SMOKE cost kind=…` line per car (frames, the
  physics step, the car's own step timed by the run, distance, top speed, the ahead samples and misses); exits 0 when
  all passed (`tools/smoke_all.sh cars`). Numbers: `docs/devlog/parts/cars.md`.

### The music blocks: tones, page, smoke run (owner #110, VR round 4 ideas 7 and 8)
```bash
godot --headless --path . --script res://tools/make_instrument_tones.gd   # assets/audio/sfx/instrument_*.wav (our own)
godot --headless --path . --script res://tools/make_music_page.gd         # data/blocks/pages/music*.png (page 44)
godot --headless --path . --import; python3 tools/copy_page_import.py ganymede music; godot --headless --path . --import
tools/smoke_all.sh music                                                  # tools/music_smoke.gd in a new Sandbox world
```
- `make_instrument_tones.gd` renders the xylophone's eight bars (C5-C6: a struck wooden bar, its overtone a tuned twelfth),
  the bongos' two skins and their shell as mono 16-bit 32 kHz WAV, deterministic, each from silence to silence at one
  peak; Godot imports them as QOA (`compress/mode=2`, 141 KB in all). After changing a tone, measure it the Loudness way
  (EBU R128 over the file looped 7 times, full band and through two 500 Hz high-passes) and put the numbers in
  `MusicBlockRules.MEASURED` / `VOICE_DB`; `tests/unit/test_music_blocks_tones.gd` checks each bar's pitch (1.2 %), the
  click-free start and end, the peak, the decay and the credits line.
- `make_music_page.gd` draws the pixel page (8 × 8 tiles of 16 px; row 0 only) and its realistic twin itself (each
  pixel tile painted at 240 px with grain by kind, an 8 px continuation border, one row, no alpha) and its normal map
  from the painting's light: no download.
- The smoke run (a private `XDG_DATA_HOME` whose path holds "smoke"; `smoke_all.sh` makes it): a xylophone and bongos
  placed through the host, a tap from the eyes on the G bar, LOOP's count-in, take and playback, STOP, a simulated
  headset's mallets and a hit; `MUSIC_SMOKE ok|FAIL` lines, exits 0 when all passed (47 s on 2026-10-16).
- Tests: `tests/**/test_music_blocks_*.gd` (the rules, the tones, the page, the taps, LOOP, friends' notes) and
  `test_vr_r4_sound_*.gd` (the mallets and the cockpit with `Vr.simulate`). Notes: `docs/devlog/parts/vr-r4-sound.md`.

### Buddy magic smoke run (headless, M3 Task 20b)
```bash
XDG_DATA_HOME=/tmp/easycraft-magic-smoke godot --headless --path . --script res://tools/buddy_magic_smoke.gd [-- --smoke-seed=<n>]
```
- A new Sandbox world (a fresh private folder whose path contains "smoke", with a `profile.json`: the run writes the
  profile's buddy magic and `my_stamps_smoke.json` there): a snowman next to the spawn wakes as Frosty the Jolly
  Snowman (the secret shape's words, the Secret Book, the Buddy Album); a summoned level-1 slime is befriended (a pet
  friend that looks like a slime); a summoned Stone Golem is beaten (the Pebble Golem hops out of its spot and lives in
  the profile); four Bunny Hops by the snowman teach it the dance (it dances along the fourth time); a brick tower is
  saved with NEW STAMP and placed, and one undo takes it away; the saved world keeps the trick and the friend's kind,
  never the Pebble Golem. Prints `MAGIC_SMOKE ok|FAIL …`, exits 0 when all passed.

### The wonder pack: the Tiny world, waking more things, building sounds (M3 Task 21c)
```bash
XDG_DATA_HOME=/tmp/easycraft-tiny-smoke godot --headless --path . --script res://tools/tiny_smoke.gd
godot --headless --path . --script res://tools/tiny_bench.gd       # what placing mouse villages costs (writes nothing)
godot --headless --path . --script res://tools/make_tiny_page.gd   # data/blocks/pages/tiny.png (page 14)
python3 tools/make_tiny_page.py                                    # its realistic twin (after the pixel page)
python3 tools/make_tiny_sfx.py                                     # build notes, mouse squeaks, the mimic's hop (original)
```
- The smoke run (a fresh private folder whose path contains "smoke", with a copy of `profile.json`) starts a new Sandbox
  world of seed 12345 and, with the real terrain and physics: the nearest mouse village's door, lintel and pumpkin in the
  generated terrain (every cell of its boxes compared), a normal-size child walking at the door stays outside, a tiny child
  walks in (the Input Map's `move_forward`) and finds it, the mice and the tiny chest come, the cheese, the wand wakes the
  opened chest (it hops, gives a present, sleeps), growing in the room shows the child out, a pumpkin wakes as a pumpkin
  buddy, `/secret mice`, the save. Prints `TINY_SMOKE ok|FAIL|info|said …`; exits 0 when all passed.
- The bench prints `TINY_BENCH areas universe=… avg_ms worst_ms` (a new area's villages, its secrets worked out first)
  and `TINY_BENCH chunks … with_avg_ms without_avg_ms` (a village's chunks with and without villages). Numbers:
  `docs/devlog/parts/m3-task-21c.md`.

### Defense smoke run (headless, M2 Task 8)
`tools/defense_smoke.gd` (steps in `tools/defense_smoke_steps.gd`) starts a new Sandbox world and checks
doors, spike traps and lanterns on real terrain with the real voxel collision: a brick pen round the player
with a doorway of two doors, opened and closed through the host; monsters of every level kept after the
player never get in through the closed doors and come in once they are open; a goblin in a pit trap loses
2 HP a second; a weak slime walks 6 blocks away from a new lantern (from the lantern index) and a light
sits on the lantern. It ends with `DEFENSE_SMOKE cost …` lines (the host's defense tick with 20 monsters).
```bash
XDG_DATA_HOME=/tmp/easycraft-defense-smoke godot --headless --path . --script res://tools/defense_smoke.gd
```
A fresh private folder with "smoke" in its path and a copy of `profile.json`. Exits 0 when every check passed.

### Co-op games smoke run (headless, M4 Wave 3 H)
`tools/games_smoke.gd` (steps in `tools/games_smoke_steps.gd`) starts a **new** Sandbox world and plays the co-op
games through the real sandbox, Session and GamesDirector: two bot friends join, a barrel stands 10 blocks away;
hide-and-seek with the child seeking (the Totem and the night monsters wait, the counting holds the child still,
the bots hide — one in the barrel — a look into the barrel and a find end it, the sticker); Storm Run (stars in
the air inside the circle on real terrain, the push back in, a star for the team, END GAME, the best in
`world.json`); the team photo (TEAM PHOTO, the line-up, photo mode saves the picture). It prints `GAMES_SMOKE
ok|FAIL …`, frame and process times per part and the cost of searching one 16³ box for hiding spots.
```bash
XDG_DATA_HOME=/tmp/easycraft-games-smoke godot --headless --path . --script res://tools/games_smoke.gd
```
A fresh private folder whose path contains "smoke", with a `profile.json`. Exits 0 when every check passed.

### Building tools: smoke run, the paint page (M3 Task 8)
```bash
XDG_DATA_HOME=/tmp/easycraft-build-smoke godot --headless --path . --script res://tools/build_tools_smoke.gd
godot --headless --path . --script res://tools/make_paint_page.gd    # data/blocks/pages/paint.png
python3 tools/make_paint_page.py                                     # its realistic twin (CC0 Plaster001)
```
The smoke run's private folder's path must contain "smoke" and hold a copy of `profile.json` under
`godot/app_userdata/EasyCraft/` (it wears a built hat). A new Sandbox world, flying: paint and its undo, a LINE, a
4,096-block FILL written a little every frame and its one undo, COPY and a turned paste, Build Rewind (5,000 edits, the
time-lapse, saved with the world), Build-and-Wear through the wand's card; then measurements (the per-cell and bulk
edit costs, each `block_changed` listener, the library's bake, the Rewind preview against remeshing its box). Prints
`BUILD_SMOKE ok|FAIL|time|measure …`; exits 0 when all passed. The paint colours live in three places kept equal
by `test_the_pixel_tiles_are_the_tints`: `PaintRules.TINTS` and both page tools.

### Pets with perks: smoke run (headless, M3 Task 11)
```bash
XDG_DATA_HOME=/tmp/easycraft-pets-smoke godot --headless --path . --script res://tools/pets_smoke.gd
```
The private folder's path must contain "smoke" and hold a copy of `profile.json` under
`godot/app_userdata/EasyCraft/` (the run gives Pip to that profile). A new Sandbox world: taming a dog (pets), a
fox and a parrot (treats), Pip from the profile, a name and a collar, a treat's heart, the dog's bark at a slime,
a coin pulled to the child, the parrot's own-words bubble, pointing (when a secret is near), the one night light
on Pip, and what the world and the profile save. Prints `PETS_SMOKE ok|FAIL|skip …`; exits 0 when all passed.

### The tutorial with Pip: smoke run (headless, M3 Task 15)
```bash
XDG_DATA_HOME=/tmp/easycraft-tutorial-smoke godot --headless --path . --script res://tools/tutorial_smoke.gd
# -- --seed=<n> for another world (20260925, 12345, 777, 99 and 4242 pass)
```
The private folder's path must contain "smoke" and hold a copy of `profile.json` under
`godot/app_userdata/EasyCraft/` (the run resets that profile's tutorial, Pip, Pip's Cap and the shop tip, and
pays it). A new solo Survivor world (NORMAL, CLASSIC) on real terrain: the offer and the waiting shop tip, PLAY
WITH PIP, the playground recorded in the meta (and on disk) before it goes in, then every step with simulated input
(the stick and the camera's yaw, JUMP three times, the edit requests a tap sends for the bridge and the wall, C in
the bush, the bag's CRAFT page and the sticks' craft request, the walk to Tilly after the tip's arrow), and at the
end the 500 gold, Pip's Cap, Pip kept, every cell back as it was, never hurt, no practice slime left. Prints
`TUTORIAL_SMOKE ok|FAIL …` and the director's `TUTORIAL playground …` lines (the time to find it, the plan's time on
its worker thread, the slowest tick while it went in); exits 0 when all passed (about 30 s).

### More animals: the census and the 40-animal bench (owner feedback #41)
```bash
godot --headless --path . --script res://tools/animal_census.gd -- [--seed=12345] [--cells=32]   # herds per universe
godot --headless --path . --script res://tools/animals_bench.gd -- [--seconds=40]                # writes nothing
```
- The census prints `CENSUS u=<u> <species>=<herds>/<animals> ...`: what `AnimalRules.spawns_for_cell` grows with each
  universe's own animals over `cells`² areas of 32 × 32 round the origin (tune `AnimalHomes` weights with it).
- The bench steps 40 of the new kinds and 40 of M1b's farm animals by hand on a flat stand-in world (a pond, an ice
  patch, trees, a player walking among them, day then night) in alternating 2 s blocks and prints
  `ANIMALS_BENCH new|farm avg_ms=… p99_ms=… max_ms=… per_animal_us=…` and the chorus's cost. Numbers:
  `docs/devlog/parts/owner-41-animals.md`.

### Creature minds: smoke run, cost bench and thought pictures (M2 Task 18)
```bash
XDG_DATA_HOME=/tmp/easycraft-mindsmoke godot --headless --path . --script res://tools/minds_smoke.gd
godot --headless --path . --script res://tools/minds_bench.gd          # writes nothing
godot --headless --path . --script res://tools/make_thought_pictures.gd # data/minds/thoughts.png
```
- The smoke run starts a new Sandbox world (a fresh private folder whose path contains "smoke", with a
  `profile.json`): animals near the player have minds and act, a treat through the host's request makes one
  like the player and a heart shows over it, at night the herds lie down and in the morning they get up, and
  the world saves the species' table. Prints `MINDS_SMOKE ok|FAIL …`; exits 0 when all passed.
- The bench puts 24 animals (six herds, a tree each), three bot friends (their swings hurt nobody) and 20
  monsters (goblins and slimes, levels 1-3, chasing) around a walking, building player on a flat stand-in
  world and simulates them by hand for 40 s (day, then night). It prints `MINDS_BENCH` lines: one mind step
  per decision (an animal thinking, an animal keeping its action, a friend, a monster's tick and tactic
  steering, a tactic pick), the animals' cost per frame in alternating 2 s blocks with their minds on and off
  (a busy PC slows both alike), the friends' and monsters' cost, all minds per frame against the 0.3 ms
  budget, and the load average. Times are this thread's CPU time. Numbers: `docs/devlog/parts/m2-task-18.md`.
- `thoughts.png` is 8 × 1 tiles of 32 px (ids: `core/mind/thought.gd`); its import keeps it lossless in 3D
  (`detect_3d/compress_to=0`).

### Words and voices: English only, babble syllables (M3 Task 21a, owner #52)
```bash
python3 tools/make_babble_sfx.py      # assets/audio/sfx/babble_1..12.wav (original work; needs numpy)
```
- **The game is English only** (owner #52, 2026-09-25: "please dont build game in georgian, i didnt ask it.
  remove it from game and never include"). No translation file, no LANGUAGE setting or card, no Georgian command
  names or bot words; `tests/unit/test_english_only.gd` fails on any Georgian letter in the game's folders (the
  one exception is `ui/theme/ui_kit.gd`: owner #49's chat shows the letters players type with the phone's own
  font). Never add a language, a language picker or a translated store listing.
- `tr()` and `Lang.t()` stay where M3 Task 21a put them and give the English back (no translation is registered);
  English plural "s" and "a/an" go through `Lang.plural_s(n)` and `Lang.article(thing)`; a count of blocks through
  `Lang.blocks(n)` ("1 block"; `test_m3_review_plurals.gd` rejects a new `tr("… %d blocks")` line).

### Input map
`tools/setup_input_map.gd` writes the keyboard/mouse bindings into `project.godot`:
- Movement: WASD / arrows, jump (Space), fly up/down (E / Q, Shift). Two quick presses of Space (like two quick
  taps on the touch JUMP) take off flying in the Sandbox; tapping on opens the glider (owner #54, `JumpTaps`, spec §3b).
- Magic and modes: undo (Z), physics mode (F), Physics Lab (L, action `lab_mode`, Sandbox), camera (V),
  size (G), mirror (M).
- Weapons: attack (R; hold it to draw the bow). With a weapon or tool selected and the mouse captured,
  the left button attacks (hold = draw the bow) and both buttons use a tool's block power. Attack always
  attacks (owner feedback #29): the held weapon, else the best melee weapon in the hotbar, else fists.
- Hotbar 1–9; break with the left mouse button, place with the right.
- Chat: T or Enter opens it; "/" opens it with "/" typed (actions `chat`, `chat_command`).
- Photo mode: P opens and closes it (action `photo`, M3 Task 16). Inside it: drag orbits, right-drag
  pans, the wheel zooms, Esc leaves.
- Crouch: C toggles it (action `crouch`, M2 Task 5; the touch CROUCH button presses the same action).
  Held while swimming, it dives.
- Co-op (M4 E): hold H near a knocked-out teammate who waits for help (HELP UP); G gets up at once
  while waiting (GET UP). Physical keys read by `KnockoutDirector`, not Input Map actions.
- Prospecting (spec §26): J opens Gemma's journal (action `prospect`: the quest's step, or her quests; DIG in MORE on a
  phone).
- Inventions (owner #78, spec §21e): I opens and closes the Inventions book (action `inventions`; INVENT in MORE on a
  phone and with a controller). In Survivor, FLY (F, the taps) flies the machine the child invented.
- Cars (owner #109): physical keys read by `VehicleDirector` while in a car: H honks, E hops off (Y too, as for rides);
  the move keys drive (W forward, S back and brake, A / D turn); Space in a ground car honks, in a flying car takes off
  and climbs (C, Q or Shift dives; touching the ground diving lands). A pad (and the Quest's controllers): the left stick
  drives, A flies up (honks in a ground car), B dives, Triangle / Y (the physics switch's button) hops off. The driver
  hears its keys as a toast on getting in (`VehicleRules.drive_hint`).
- Rides (M3 Task 20a): Y gets on a saddled buddy next to you and off again (RIDE / HOP OFF), a physical key read
  by `RideDirector`. While riding: the move keys steer, Space (JUMP) or E climbs a flyer, C (CROUCH, held), Q or
  Shift dives; Space gets off anything but a flyer.

Touch controls drive the same actions.

**Game controllers (owner #90):** the same script writes a pad's events beside the keys, from
`GamepadRules.BINDINGS` (`core/platform/gamepad_rules.gd`, `device -1`: every pad): the left stick walks (`move_*`), the
right stick looks (`look_up/down/left/right`, pad only), Cross / A `jump`, R2 / RT `break`, L2 / LT `place` (their dead
zone is 0.5: a trigger presses half-way), L1 / R1 `hotbar_prev` / `hotbar_next`, Square / X `attack`, Triangle / Y
`physics_mode`, the D-pad up / down `fly_up` / `fly_down`, left `blocks` (the palette), right `more` (the MORE panel),
Circle / B `crouch`, R3 `camera_toggle`, L3 `size_mode`, Options / Menu `pause`, the touchpad and Create / View `map`,
and Cross / A in `ui_accept` (which keeps Enter and Space). The pad-only actions (`GamepadRules.PAD_ONLY`) have no keys.
Change a binding in `BINDINGS`, run the script, and `tests/integration/test_pad_input_map.gd` checks the map. The whole
table and its rulings: `docs/devlog/parts/controllers.md`; how menus take the pad: §5 "Game controllers".

### One game everywhere: the build label, the online version check, the release rule (owner #123, 2026-10-17)
The owner played the phone app (Google Play's 1.0.1) and the web game (deployed almost daily) together online and saw
different games; both said "v1.0.5". Now:
- **The build label.** `tools/write_build_info.py` writes `data/build_info.json` (git-ignored) before an export: the
  commit, the date and `net`, online play's fingerprint (a hash of every `@rpc` with the function it marks, every
  `rpc_config()` and `BlockIds.COUNT`: what two games must share to play together; School lessons, Life, pictures and
  words never change it). `BuildInfo` reads it; the menu shows "v1.0.6 (17 Oct, 90e976cc)". `tools/export_web.sh` (and
  so `export_web_vr.sh`) write it first and `--clean` it last; **for an Android export run
  `/usr/bin/python3 tools/write_build_info.py` before and `… --clean` after**. Tests: `test_build_info.gd`.
- **The online version check** (`NetVersionCheck`, driven by `NakamaLink`, acted on by `Session._on_version_verdict`):
  each game in a relayed match sends `{net, version, date}` on op code 9010 (outside Godot's remote calls, which line
  up only between identical builds; the relay's bridges ignore codes they don't know, old games too) every 2 s until it
  hears the other's. A different `net`: the guest goes back to the menu with "This world has a newer/older EasyCraft…"
  (`NetWords.NEWER_WORLD` / `OLDER_WORLD`, by the build's date, then the version's numbers) and the host hears
  `FRIEND_DIFFERENT`; a game that never answers within 12 s is older than the check: a gentle `MAYBE_DIFFERENT` only (the
  store's old phones can't update yet). A developer's run (no build file) has net "" and plays with anyone.
  `--net-version=<hex>` (debug builds) plays as another fingerprint: `tools/net_test.sh --versions=differ` (PASS: the
  guest leaves, the host is told) and `--versions=same`. Tests: `test_net_version_check.gd`, `test_net_words.gd`.
- **The release rule:** every deploy publishes the web, VR, the Quest APK, the phone APK and the Play bundle **from one
  commit with one version** (raise `test_release_version.gd`'s version and code with it); the Play upload still waits
  for the owner's yes. **Every deploy also publishes the Android apps' update packs** (phone and Quest) from that
  commit, and a new APK/AAB is needed only when a patch cannot carry the change: the next section.

### The Android apps follow the web: the updater, its packs, the release rule (owner #123)
An installed app with the updater (the phone APK, the Play AAB, the Quest APK) runs the web's game from its next start
after a deploy, as a **patch pack** for its own build (a day's change: 1.2-2.6 MB to download; the whole game is 147 MB).
Notes, the spike, the rulings and Google Play's policy: `docs/devlog/parts/same-version.md`.
- **The updater** (`autoloads/updater.gd`, the **first** autoload; idle off Android): at the start it loads the
  verified pack waiting for this build (`user://update/`), counts the try, and takes the pack's version and input map;
  after the menu (`Updater.menu_shown()`, in the line of `ui/menus/menu.gd` that makes the `UpdateNote`) it downloads the
  next one in the background (`UpdateFlow`, `UpdateFetch`: HTTPS from `/play/android/` or `/play/quest/` only, gzip, a
  signed `update.json`, SHA-256) and the note says "A new EasyCraft is ready: it starts next time" (no RESTART in an
  app). Two starts that never reach the menu bring back the app's own build. The updater and its three scripts
  (`core/platform/update_rules.gd`, `update_flow.gd`, `update_fetch.gd`) **name nothing else of the game** (they load
  before any pack: `test_updater.gd`), and a change to them reaches apps only in a new APK/AAB.
- **Every deploy, from the web's commit:** `tools/export_web.sh`, `tools/export_web_vr.sh`,
  **`tools/export_android_update.sh`** (the newest game's pack per kind, a patch per kept base, the check, the signed
  manifest in `build/android/update/<kind>/`; `--dry-run`), then `tools/deploy_web.sh`, `deploy_web_vr.sh`,
  `deploy_web_github.sh`, **`tools/deploy_android_update.sh`** (`--dry-run`, `--to <folder>`; packs first, `update.json`
  last, into the server's `play/android/` and `play/quest/`, which Caddy's `/play/*` block already serves;
  `deploy_web.sh`'s `--delete` leaves them alone).
- **A new APK/AAB (a new base) only when a patch cannot carry the change:** another engine, a native plugin or
  GDExtension, the Android manifest or a preset's options (permissions, SDK levels, the package), a setting the engine
  reads at the start (a new or changed autoload, rendering, physics, translations, the boot splash), or the updater's own
  four scripts. The version and the input map ride in the patch. `tools/export_android_update.sh` prints "NEEDS A NEW
  APK/AAB" and why, and that base gets no patch (online play's check tells it to update).
- **When an APK/AAB with the updater goes out** (exported after `tools/write_build_info.py`, before `--clean`): keep it
  as a base: `tools/export_android_update.sh base phone <the phone or debug APK>` and `… base quest <the Quest APK>`
  (`build/android/bases/<kind>/<commit>/`; the Play AAB's files are the phone APK's of the same commit). A build
  without `data/build_info.json` has no identity and keeps its own game.
- **The signing key:** `~/.config/easycraft/update-signing.pem` (RSA 3072, `chmod 600`, never in git; back it up),
  made once with `python3 tools/android_update.py keygen`, which prints the public key for `UpdateRules.PUBLIC_KEYS`.
  `python3 tools/android_update.py verify <update.json>` checks a manifest with the game's key.
- **On a PC** (no emulator): a kept base pack runs headless as the app would, its updater pointed at folders:
  `godot --headless --main-pack <base.pck> -- --update-dir=<folder> --update-source=<a folder laid out as play/>`
  (run it from a folder where `addons/zylann.voxel/bin/` is reachable). Tests: `test_update_rules.gd`,
  `test_updater.gd`, `test_update_flow.gd`, `test_update_note_app.gd`, `test_update_tools.gd`. The spike's scripts:
  `tools/android_update_spike.sh`, `tools/android_update_spike_http.sh`.

### Export APKs
Presets live in `export_presets.cfg`; package `com.giorgi.game`, which is a **placeholder** that must be
final before the first store upload, because it can't change afterwards.

| Preset | Build | ABIs | Output |
|---|---|---|---|
| `Android` | debug | arm64-v8a + x86_64 (emulator) | `build/android/game.apk` |
| `Android Phone` | release | arm64-v8a only | `build/android/EasyCraft-phone.apk` |
| `Android Spike` | spike feature tag (Voxel Tools check) | both | `build/android/spike.apk` |
| `Android Theater` | debug, **Gradle build**, feature tag `theater_live` (the Shorts Theater's player check, M3 Task 17) | both | `build/android/theater.apk` |

Both game presets exclude `spikes/*, tests/*, addons/gut/*`. The version is set in **both**
`project.godot` (`config/version`) and each preset (`version/name`, `version/code`). It is currently 1.0.0, code 10 (the release candidate, 2026-09-26). Raise the code by one for every APK the owner receives;
`tests/unit/test_release_version.gd` holds the release's version and checks every preset agrees.

```bash
# debug (emulator)
godot --headless --path . --export-debug "Android" build/android/game.apk
# release for phones, signed with the debug keystore for now
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/.local/share/godot/keystores/debug.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android \
godot --headless --path . --export-release "Android Phone" build/android/EasyCraft-phone.apk
```
The owner receives release APKs in `~/Downloads`; the latest delivered is `~/Downloads/EasyCraft-0.2.0.apk`
(before it: `RealmHoppers-0.1.1.apk`, the M1 build under the old working title).
A real release keystore is still to be created (before the store).

Install and launch on the emulator:
```bash
export ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554
~/android-sdk/platform-tools/adb install -r build/android/game.apk
~/android-sdk/platform-tools/adb shell am start -n com.giorgi.game/com.godot.game.GodotAppLauncher
~/android-sdk/platform-tools/adb shell am force-stop com.giorgi.game
```
For UI checks, drive the emulator with `adb shell input tap x y`. The HUD's buttons act on release and miss an
instant tap: press them with `adb shell "input motionevent DOWN x y; sleep 0.15; input motionevent UP x y"`.
- **Launch arguments don't reach the game on Android:** `am start … --esa command_line_params …` arrives as "Launch
  intent … with parameters []" (`GodotAppLauncher` drops the extras), in debug and release builds.
- **A test profile on the emulator (debug builds only, which are debuggable):** read and write the save with
  `run-as`, e.g. to unlock universes or own Plus for a check:
  `adb exec-out run-as com.giorgi.game cat files/profile.json > p.json`, edit it, then
  `cat p.json | adb shell "run-as com.giorgi.game sh -c 'cat > files/profile.json && cp files/profile.json files/profile.json.bak'"`
  (with the game stopped). Debug builds use the pretend store, so Plus universes are locked until `purchases` has "plus".
- **Installing a lower versionCode wipes the app's data on the emulator** (seen 2026-09-25: 8 → 7 made a fresh
  install): keep the working branch's version at or above the last release.

### The shop's Google Play backend (owner #35; off until the owner turns it on)
The shop works with the pretend store in debug builds ("Test store: nothing is charged"). Release builds
say "The shop isn't open" until all of these are done (details: `docs/devlog/parts/owner-35-shop.md`):
1. **Owner, Play Console:** a payments profile; one-time (non-consumable) products for each product on sale
   in `ShopCatalog.PRODUCTS` (the same US$ prices), active; licence testers for test purchases.
2. Put their ids in `ShopCatalog.PLAY_IDS` (`core/shop/shop_catalog.gd`).
3. Install the Godot Google Play Billing plugin **3.3.0** (MIT) into `addons/GodotGooglePlayBilling/`
   (AssetLib or the GitHub release), enable it in Project Settings → Plugins, and set
   `gradle_build/use_gradle_build=true` in the `Android Phone` preset (run
   `--install-android-build-template` once, as for the Theater). Update `THIRD_PARTY_NOTICES.md` (bundled).
4. Build an AAB, upload it to a Play testing track (billing only works for apps installed from Play), buy
   with a licence tester, reinstall and check RESTORE.
5. Re-answer the store forms (`docs/store/data-safety.md`: purchase history; `families-and-rating.md`:
   digital purchases, "Contains in-app purchases").

### Shorts Theater: the Android player plugin (M3 Task 17)
The Theater's video player is our own Godot v2 Android plugin, `EasyCraftWebView` (Kotlin, one
`WebView` placed over the panel's screen area). Notes, rulings and the plugin evaluation:
`docs/devlog/parts/m3-task-17.md`.

| What | Where |
|---|---|
| Kotlin source and Gradle project | `android/plugins/easycraft_webview/` (Godot skips it: `android/plugins/.gdignore`) |
| Built AARs (committed, about 12 KB each) | `addons/easycraft_webview/bin/{debug,release}/EasyCraftWebView-*.aar` |
| Export plugin that adds them to Gradle builds | `addons/easycraft_webview/plugin.gd` (enabled in `project.godot`) |
| Game side | `ui/theater/theater_webview.gd` (`TheaterWebView`, the singleton wrapper); the page it shows is `core/theater/theater_embed.gd` |

**Rebuild the AARs** after changing the Kotlin (JDK 17, Gradle 8.11.1 and AGP 8.6.1 / Kotlin 2.1.21, the
same versions as Godot 4.7.2's build template; the first run downloads them, about 9 minutes):
```bash
cd android/plugins/easycraft_webview
JAVA_HOME=$HOME/.local/jdk17 ANDROID_HOME=$HOME/android-sdk ./gradlew assemble --no-daemon
# copies EasyCraftWebView-{debug,release}.aar into addons/easycraft_webview/bin/
```
**Build the check APK.** Android v2 plugins only go into **Gradle** builds; Godot silently leaves them
out of the other presets, which keep exporting exactly as before (their Theater says "Coming soon").
The `Android Theater` preset uses Gradle (and the feature tag `theater_live`, which since owner #89 only
matters for the tests' sample list: the game plays the real `data/theater/channels.json` anyway). It has
the game's package name, so it replaces the debug game on the emulator (same debug signature, the profile
stays).
```bash
godot --headless --path . --install-android-build-template --export-debug "Android Theater" build/android/theater.apk
```
`--install-android-build-template` unpacks `android_source.zip` into `android/build/` (git-ignored,
about 220 MB) the first time. The first Gradle export downloads its tools too.

**Check on the emulator** (the lead; owner #89's version, `docs/devlog/parts/tv-shows.md`): install
`theater.apk`, start a Sandbox world, walk into the Theater (a cream building with a red THEATER sign
about 30 blocks from the spawn, its door facing the spawn), and check that:
- the eight picture tabs sit across the top, the title and CLOSE over the 16:9 player, BACK left and
  NEXT, EXIT right of it, the video cards under it, none of them over the player;
- walking in shows EasyCraft TV's first video **still** in YouTube's own player (its poster and play
  button; **"Error 153"** would mean the Referer is missing), a tap on YouTube's play button plays it,
  and the game's music stops while it is on the screen and comes back with CLOSE or EXIT;
- a tab, a card and NEXT load their video; at the end of one, NEXT lights up yellow and nothing starts;
  CLOSE stops it and leaves its poster (a tap on it plays again);
- the pause menu, the block palette, the chat and F1's KEYS card hide the player; EXIT, walking out and
  the Android Back button leave no video playing; logcat has no `EasyCraftWebView` exceptions
  (`adb logcat -d | grep -i -E "EasyCraftWebView|chromium"`).

Owner #89: the list is real (`data/theater/channels.json`), so every Gradle build with the plugin plays
it; **"Android Play" is one** (its AAB carries the plugin): see "EasyCraft TV" below before a Play
upload. The `Android` and `Android Phone` presets still export without Gradle and say "Coming soon";
switching `gradle_build/use_gradle_build=true` on there (and running the template install once) is all
they need.

### EasyCraft TV: the channel list, the browser's player, pictures (owner #89)
Notes, rulings, every video's source and the browser checks: `docs/devlog/parts/tv-shows.md`.

| What | Where |
|---|---|
| The list the game plays until it has read the server's (and the file the owner sends) | `data/theater/channels.json` (`"source": "bundled"`); `data/theater/sample_channels.json` is only the tests' placeholder list |
| Which list plays | `TheaterFeed` (`core/theater/theater_feed.gd`): the server's last one kept in `user://theater_channels.json`, else the bundled one; read when a world starts and the device is signed in (or signs in there) |
| The server's copy | module 0.2.17: storage `theater/channels` (the system user's, everyone reads), `theater_channels`, `theater_set_channels` (the owner only); `server/README.md` |
| The browser's player | `web/shell.html`'s block (`window.easycraftTv`), called only through `WebGlue.tv_*`; `TheaterWebPlayer`. Safari and Firefox: `server/deploy/site/tv/index.html`, served at `/tv/` by Caddy |

```bash
python3 tools/theater_list.py check          # every video on YouTube: embeddable, playable, made for kids; the shape
python3 tools/theater_list.py sources        # the same as a Markdown table (the notes' source list)
EASYCRAFT_HTTP_KEY=<the server's NAKAMA_RUNTIME_HTTP_KEY> python3 tools/theater_list.py push   # the server keeps it
EASYCRAFT_HTTP_KEY=... python3 tools/theater_list.py show | off | clear   # what it keeps; the kill-switch; none
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/theater_shots.gd   # pictures
```
To change the channels: edit `data/theater/channels.json`, `check` it, `push` it, commit it (the next build bundles
it). Games that are online play it from their next world. `--server http://127.0.0.1:7350` with
`EASYCRAFT_HTTP_KEY=defaulthttpkey` talks to this PC's `server/dev.sh` server.

- **The browser's player can't be a plain iframe:** the game's page is cross-origin isolated (COOP/COEP, for its
  threads) and YouTube sends no COEP, so a plain `<iframe>` is refused (`net::ERR_BLOCKED_BY_RESPONSE`). Chromium
  takes it as a `credentialless` iframe; Safari and Firefox have none, so the page shows WATCH, which opens `/tv/` in a
  tab (a BroadcastChannel tells the game when it closes). Keep `/tv/` out of `/play/` (its headers) and out of the
  service worker's scope.
- **The Play build plays the Theater** (Gradle, the plugin, a real list). The store drafts assumed it off
  (`docs/store/data-safety.md` "Later", `families-and-rating.md`, pre-launch checklist F2): re-answer them before a
  Play upload, or build that AAB with `"enabled": false` in `data/theater/channels.json`.

### EasyCraft Shorts: writing a Short, the checker, the reel studio (owner #94, #96; spec §5.12b)
Notes, rulings, every Short's facts and sources, the review and the bench: `docs/devlog/parts/shorts.md`. The Theater
opens on its SHORTS tab (`ShortsView`); a Short is data the game draws itself (2D, offline).

**Writing a Short.** Add `data/shorts/<id>.json` and its id to `data/shorts/shorts.json` (the list's order is the feed's
within a topic). The format (constants in `core/shorts/short_rules.gd`, the style in `core/shorts/short_style.gd`):

```json
{"id": "lever_lift", "title": "A lever lifts", "topic": "science", "link": {"unit": "g3.design_tech.levers_linkages"},
 "scenes": [{"seconds": 8, "background": "paper", "caption": "A lever is a strong bar that turns on a pivot.",
   "say": "A lever is a strong bar that turns on a pivot, like a seesaw.",
   "sounds": [{"at": 0.3, "effect": "pop"}],
   "actors": [{"kind": "words", "text": "PIVOT", "at": [180, 330], "size": 24, "color": "white", "box": "blue",
     "moves": [{"do": "pop", "at": 0.6}, {"do": "pulse", "at": 1.4}]}]}]}
```

- **The stage** is 360 × 640 (x right, y down). Actors stay inside `ShortStyle.SAFE` (8, 24, 344 × 608) and above the
  caption's band (y 440); `"bleed": true` lets decoration run off an edge. `at` is an actor's middle.
- **Topics:** rockets, space, science, nature, maths, history. **Links (LEARN IT):** `{"unit": "<written School
  unit>"}`, `{"board": true}` (the Mission Board), `{"star_map": true}`.
- **Scenes:** 3-6, each 2.5-16 s, a hand-made Short 20-60 s in all; `background` one of sky, space, paper, grass, sea,
  night, sunset, chalk, lab, tint (+ `"tint": "#rrggbb"`); optional `camera` `{"zoom": [1.0, 1.1], "focus": [x, y]}`
  (else a slow 1.04 push-in). `caption` ≤ 90 letters, `say` ≤ 240. Both are paced at no more than 2.5 words a second.
  The last caption asks a question to wonder about. `sounds`: `{at, effect}` (`ShortRules.EFFECTS`) or `{at, tune}` (a
  SchoolSound tune, ≤ 4 s).
- **Actors** (≤ 16 a scene, `size` 8-400, colours by name from `ShortRules.COLOURS` or `#rrggbb`):
  `words` {text, size ≥ 16, color, box?, on?, width?}; `picture` {picture: any School picture's data, w?};
  `block` {block: a BlockIds name or id}; `part` {part: a rocket part}; `planet` {body: a StarMap body}; `character`
  {who: hoot, robot, astronaut or an animal species}; `arrow` / `line` {from, to, width, bend?}; `shape` {shape:
  `ShortRules.SHAPES`, value? (a pizza's slices shaded, a phase, a bulb lit)}; `map` {lat, long, sea/seas/lands corners,
  points [{lat, long, label}]}; `count` {from, to, decimals?, prefix?, suffix?: a number that counts}.
- **Moves** (≤ 10 an actor, `{"do", "at", "dur"?, "ease"?}`): entrances pop, appear, slide {from}, drop {height}, draw
  (arrows and lines draw on); then move {to}, grow {to}, spin {turns}, bounce {height}, pulse {amount}, shake, orbit
  {around, period, squash?, dir?}, fade {to}, value {to} (counts, pizzas, phases), out. Eases: smooth, out, in, back,
  bounce, elastic (and linear, never for a move or a slide). Each move keeps its own ease unless it names one.
- **The style rules the checker enforces:** arrivals ease out in 12-18 frames (a pop 0.3-0.8 s, a slide 0.35-1.0 s, a
  drop 0.5-1.4 s), a move lasts at least 0.4 s, letters from `ShortStyle.LETTER_SIZES` (never under 16), words legible
  (WCAG contrast ≥ 4.5 on their sticker, else a dark outline with a sticker ≥ 2.0).
- **Every number must be the game's or checked:** add a test in `tests/unit/test_short_library.gd` that works it out
  again from the game's tables (RocketParts, StarMap, WonderFacts…) and put its source in the notes.

**Lessons in a minute** are made at run time from every written unit (`LessonShort.make`): nothing to write. A lesson
card's picture shows; a card without one borrows an exercise picture that asks nothing, else shows its headline. The
"Quick memory" review is left out whole (`LessonShort.teaching`: its lead-in line, question and answer, up to the
bracketed answer or to the lesson's own "Today" or "Now"), so write a memory card as "Quick memory: … ? (answer.)
Today: …".

**Checking and looking:**

```bash
tests/run_tests.sh -gtest=res://tests/unit/test_short_library.gd,res://tests/integration/test_short_quality.gd
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_preview.gd -- --short=lever_lift   # the studio
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_preview.gd -- --sheet --short=lever_lift,lesson:g4.science.circuits
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_preview.gd -- --sheet --all          # every hand-made Short
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/shorts_shots.gd -- --panel   # the Theater's tab
XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/shorts_shots.gd -- --bench   # frame times
XDG_DATA_HOME=/tmp/easycraft-shorts-smoke godot --headless --path . --script res://tools/shorts_smoke.gd          # the smoke
```

The studio (windowed) scrubs a Short on a timeline, lists its scenes and the checker's findings; keys: Space plays, ← /
→ a tenth of a second (Shift: a second), PageUp / PageDown the Short before or after, Home the start, R reduce motion.
A frame sheet is one PNG, a picture every half second (`user://reel_studio/`). **Review every new Short on its sheet
before it ships** and fix what looks cheap: things that pop at once without rhythm, words on words, a still scene,
labels off the frame.

**Adding an actor kind** (as the Reel Studio's `scene3d` and `video` were, next section): a check
`func(actor: Dictionary) -> String` registered in `ShortKinds._builtins()` (`core/shorts/short_kinds.gd`) and a
`ShortDrawer` subclass (`ui/shorts/short_drawer.gd`: `setup`, `draw`, `update(actor, state, t)`, which must show
exactly the frame at `t` so seeks match playing) registered in `ShortDrawers._builtins()` (`ui/shorts/short_drawers.gd`).
Add it to `ShortRules.ACTOR_KINDS` only if ShortCheck's own `_kind_problem` should know it.
`test_short_player.gd: test_a_new_actor_kind_plugs_in_with_its_check_and_its_drawer` is the model.

### The Reel Studio: 3D reels, rendering them to video, the reels pack (owner #96; spec §5.12b)
Notes, every reel's facts and sources, what the review changed, the sizes, the bench and the rulings:
`docs/devlog/parts/reel-studio.md`. A Short can show a **3D stage**: its whole picture (a cinematic reel: the Short's
own `"stage"`, on the Short's clock) or one actor (`{"kind": "scene3d", "at", "w", "h", "stage"}`, on its scene's
clock). A stage is data (`core/shorts/studio/studio_rules.gd` documents the format): a sky (a preset, colours, or keys
fading from day to space), a light preset (key, fill and rim, no shadows), models (a rocket of real parts that can be
built part by part and let its stages go, planets and moons with the flight's maps, the Sun, Saturn's rings and ring
chunks, orbit lines, the flight's ground and pad, block builds: the Launch Site, a world's own places from its
generator, cells; the blocky avatar with emotes, clouds), effects (flame, smoke, dust, billow, sparkles, steam, snow)
and camera keys (dolly, crane, push-in and orbit eased between keys; cut, follow, shake, roll). Any moment is a pure
function of the time (StudioMotion, StudioCamera, StudioParticles), so seeks, frame sheets and the Movie Maker all
show what playing shows. Write a reel in `data/shorts/cinematic/<id>.json` and list its id in `data/shorts/shorts.json`.

- **Live or video.** Live (the default) when the stage is light (a few thousand triangles, a few effects: bench it);
  else add `"video": "<id>"`: the feed plays `assets/reels/<id>.ogv` under the live captions, stickers, voice and
  sounds, and the studio's tools still draw the stage.
- **Frame it for a tall phone:** the bottom third is the caption's, the top band the stickers'; keep the subject
  between (look a little below it). A camera move lasts 0.4 s at least (a cut any time) and eases (Scene3DKind).
- **Look:** `tools/reel_preview.gd -- --sheet --short=<id>` (a frame every half second, the stage live; `--video`: the
  rendered video), and pictures at the video's size: `godot --path . --resolution 540x960 --script
  res://tools/reel_render.gd -- --short=<id> --frames=2,14.5,30 --full`. The studio lists ShortCheck's and ReelCheck's
  findings.
- **Render a video reel:** `tools/reel_render.sh <id> [--q=3] [--blur=0.4] [--keep] [--encode]` films the stage with
  the Movie Maker (a real window, `--fixed-fps 30`, 540 × 960; a temporary `override.cfg` opens the window at that size:
  the Movie Maker takes its picture's size from the project's window override, not `--resolution`), encodes Theora
  (silent; a keyframe every 2 s; quality 3 after a 0.4-pixel blur: the blocks' pixel art shimmers at a distance and that
  shimmer costs most of the bytes; a busy reel can take `--q=2 --blur=0.5`), writes its still (`assets/reels/<id>.jpg`),
  its frame sheet (`build/reel_render/<id>/<id>_video_sheet.png`: review it) and its numbers in `assets/reels/reels.json`
  (bytes, seconds, pixels, three frames' brightness). About 3 minutes a reel; one render at a time, under nice. Then
  `godot --headless --path . --import` (the still is imported) and `tests/run_tests.sh -gtest=res://tests/unit/test_reel_studio_library.gd`.
- **Delivery:** every video is in the Android and desktop builds (all together under `ReelPack.ANDROID_CAP`, 20 MiB;
  one under `VIDEO_CAP`, 8 MiB). The browser's games leave `assets/reels/*.ogv` out and `tools/export_web.sh` makes
  `reels.<hash>.pck` (preset "Web Reels") listed in `packs.json` after the music; an iPhone fetches it once the SHORTS
  have been opened (`ReelPack.wanted`); until it is in, a video reel shows its still and "This video is on its way…".
  `INCLUDE_REELS=1 tools/export_web.sh` keeps them in the main packs too.
- **Bench a live reel:** `godot --path . --script res://tools/reel_render.gd -- --bench [--short=<id>]` (its stage's
  GPU and CPU time, the pose's CPU time, draws and triangles at a phone's 288 × 512 and 432 × 768).
- **Tests:** `tests/unit/test_reel_studio_motion.gd`, `test_scene3d_kind.gd`, `test_reel_studio_rockets.gd`,
  `test_reel_studio_library.gd` (every reel, ReelCheck, the facts against the game's tables), `test_reel_studio_pack.gd`;
  `tests/integration/test_scene3d_view.gd`, `test_video_actor.gd`.

**Learning reels (round 2; notes, facts, sources, the reviews, the bench: `docs/devlog/parts/reels-2.md`).** Twelve
live 3D lessons (a volcano, the water cycle, seasons, day and night, the pyramids, levers and pulleys, the Moon's
phases, plants, mountains, volume, gold, floating) written with a generator and the stage's teaching rigs:
- **Write or tune one:** its script is `tools/learning_reels/<id>.py` (the kit: `reelkit.py`: scenes, stickers kept
  inside the frame and above the caption, arrows put on 3D points with `project()`, shapes, moves, cameras); then
  `python3 tools/make_learning_reels.py <id>` writes `data/shorts/cinematic/<id>.json` (never edit that JSON by hand:
  the next make overwrites it), list the id in `data/shorts/shorts.json`, and
  `godot --headless --path . --script res://tools/reel_check.gd -- --short=<id>` (or `--all`) prints ShortCheck's and
  ReelCheck's findings. Then the sheet (`--disable-vsync`: see Gotchas), review it, fix, make again.
- **The rigs** (StudioRules' header): a model rides on another (`on`), is stretched (`stretch`, `grow` with an `axis`),
  is a `mark` (nothing drawn) or a `rope` (between two models, `from_at`/`to_at` points); an avatar walks or pulls
  (`legs`: steps, arms swing/pull/push/up, lean); the camera keeps a model in the middle (`aim`); light and sun keys fade
  (a sunset), a `night` sky and light; a planet's darker night side (`night`); blocks from shapes (`fill`: box, disc,
  cylinder, cone, ball; AIR carves; StudioShapes); rain, a lava fountain, an effect's own `gravity` and `area`.
- **Cost:** a blocks model's shapes are filled row by row into a VoxelBuffer on a worker and meshed on the main thread
  a frame later (a live stage); the tools mesh at once (`Scene3DModels.sync_blocks`). Every learning reel builds in
  4-13 ms here and poses in 0.4-2.4 ms. Tests: `tests/unit/test_reel_studio_rigs.gd`, `test_reel_studio_learning.gd`
  (every fact), `tests/integration/test_reel_studio_rigs_view.gd`.

### MAKE MY SHORT: a child's own Shorts, on the device only (spec §5.12b "As built (My Shorts)")
Notes, rulings, the animals' facts and their sources, the bench and the emulator checks: `docs/devlog/parts/my-shorts.md`.
The SHORTS tab's MY SHORTS filter and MAKE A SHORT open the maker (`MyShortMakerView`, `ui/shorts/mine/`) over the view.

| What | Where |
|---|---|
| The rules: ids `mine:<n>`, the cap (20), templates, quick phrases, titles, endings, backdrops, music, blueprints, the words check, `clean_recipe`, the new kinds' checks | `core/shorts/mine/my_short_rules.gd` (MyShortRules) |
| "3 facts about…": planets, wonders, real animals (their two extra facts: `ANIMAL_FACTS`) | `core/shorts/mine/my_short_facts.gd` (MyShortFacts) |
| A recipe made into a Short (paced, laid out: always passes ShortCheck) | `core/shorts/mine/my_short_maker.gd` (MyShortMaker) |
| The profile's part (recipes, newest first, ids never reused) | `core/shorts/mine/my_shorts_data.gd` (MyShortsData, `ProfileData.my_shorts`) |
| Photo and stamp copies, the photo folder, tidying, pictures loaded on workers | `core/shorts/mine/my_short_album.gd` (MyShortAlbum, `user://my_shorts/photos`, `builds`) |
| The `photo`, `me`, `wonder`, `build` actors; IsoBuild (a build as cached per-layer meshes) | `ui/shorts/mine/my_short_drawers.gd` (MyShortDrawers) |

- **On the device only:** `my_shorts` is in `ProfileBackup.DEVICE_ONLY_FIELDS`, and `_leave_out_device_only` takes the
  `mine:` ids out of the backup's hearts and seen list; a merge keeps this device's. Keep any new My Shorts data there or
  in `user://my_shorts/`, never in a payload; `test_my_shorts_privacy.gd` scans `core/shorts/mine/` and
  `ui/shorts/mine/` for anything that talks to a network (add such code elsewhere and it fails, on purpose).
- **A recipe** (`clean_recipe` reads every one back): `{template, title, captions, ending, backdrop, music, voice}` and
  BUILT `photos` (album file names `p_<…>.jpg`), FACTS `subject {kind, id}` and `facts` (three indexes), STEPS `build`
  (`{kind: "blueprint", id}` or `{kind: "stamp", file: "b_<…>.txt", layers}`); `id` and `made` once kept.
- **A child's Short in ShortCheck:** an id `mine:<n>` means topic `mine`, LEARN IT optional, and only it may show a
  `photo`; `music` (a `MyShortRules.MUSIC` piece) and `voice` (bool) are checked for any Short, and ShortPlayer plays the
  music (worker-loaded, on the effects bus at `MyShortRules.MUSIC_DB`) and honours `voice: false`.
- **Adding:** a quick phrase or an ending: `MyShortRules` (a test checks every phrase passes the words check and every
  ending is a question); an animal fact: `MyShortFacts.ANIMAL_FACTS` (≤ 90 letters, ending in a stop; its source in the
  notes); a template: its words, a branch in `MyShortMaker._specs` / `_scene`, its PICK page in the maker, and its recipe
  keys in `clean_recipe` (`test_my_short_maker.gd` makes random recipes of each and runs ShortCheck on them).
- **Typing** turns the game's keys off while the field has the focus (as the chat does) and shows the phone's keyboard.
- **The photos:** `sandbox.gd` keeps a small copy of each photo photo mode takes (`MyShortAlbum.keep_photo`, a worker);
  the maker also lists the photo folder's (`PhotoFiles.folders`) and copies one when it is picked.

```bash
tests/run_tests.sh -gtest=res://tests/unit/test_my_short_maker.gd,res://tests/integration/test_my_short_maker_view.gd,res://tests/integration/test_my_shorts_privacy.gd
XDG_DATA_HOME=/tmp/easycraft-my-shorts godot --path . --disable-vsync --script res://tools/my_shorts_shots.gd -- --panel --sheets   # pictures, frame sheets
XDG_DATA_HOME=/tmp/easycraft-my-shorts godot --path . --disable-vsync --script res://tools/my_shorts_shots.gd -- --bench [--novoice]   # frame times
XDG_DATA_HOME=/tmp/easycraft-my-shorts-smoke godot --headless --path . --script res://tools/my_shorts_smoke.gd   # the smoke run (or tools/smoke_all.sh my_shorts)
```

### The game in the browser: build, test, deploy (M7, spec §20)
The same game exported a third way. The browser build of Voxel Tools is ours (its authors ship none); the game-code
side (touch, LAN, photos, saves) is `PlatformRules` in §5 "Web".
- **Toolchain (once):** emsdk **4.0.20** (the Emscripten of Godot 4.7.2's web templates; a different one will not
  load) in `~/src/emsdk`, SCons in a venv `~/src/sconsenv`, godot-cpp master of 2026-08-20 in `~/src/godot-cpp`, Voxel
  Tools tag `v1.7x` in `~/src/godot_voxel`, brotli (`apt`). Commands in `docs/devlog/2026-09-27-m7-web.md`.
- **Voxel Tools for the browser:** `tools/build_voxel_web.sh` (3 min on 12 cores) →
  `addons/zylann.voxel/bin/libvoxel.web.template_release.wasm32.threads.wasm` (committed, 6.5 MB). Rebuild only when
  the voxel version changes (then change the tag and the godot-cpp date in the script).
- **Export:** `tools/export_web.sh` (1 min): `index.pck` (the code and data, computer textures, S3TC) and
  `index.mobile.pck` (phone textures, ETC2; the page picks one by the GPU), the game's media as `assets.<hash>.pck` and
  `assets.mobile.<hash>.pck` (fetched by the page next to its main pack, §5 "The game's media in their own pack"), the
  background music as `music.<hash>.pck`, the Reel Studio's videos as `reels.<hash>.pck` (owner #96, the section
  above), the REALISTIC style's pictures as `realistic.<hash>.pck` (S3TC) and `realistic.mobile.<hash>.pck` (ETC2),
  these four listed in `packs.json`; every content pack cut down to its own
  files (`tools/pck_tool.py strip`: the exporter adds the autoload scripts, `project.binary` and the caches to each, and
  a code change then renamed them all); the service worker patched (takes over the first visit; the big files, the
  assets packs and `index.js` kept by content hash across versions), then `tools/web_finish.py`. `INCLUDE_MUSIC=1` /
  `INCLUDE_REALISTIC=1` / `INCLUDE_ASSETS=1 tools/export_web.sh` keeps the music / the realistic pictures / the media
  in the main packs too (the packs are still made). The presets: "Web", "Web Mobile" (scripts as plain binary tokens,
  `script_export_mode=1`: brotli packs the code to 2.6 MB instead of 4.7), "Web Assets" and "Web Assets Mobile" (the
  media in each format), "Web Music" (the music only; `export_filter="resources"`, no splash: `test_boot_splash.gd`),
  "Web Realistic" and "Web Realistic Mobile" (the realistic pictures in each format: `include_filter` = the patterns
  the two game presets exclude, §5 "Realistic pictures that come later"), "Web Spike" (the voxel spike: a block edit
  that must survive a reload). `python3 tools/pck_tool.py list <pack>` lists a pack's files.
- **Try it here:** `python3 tools/web_serve.py build/web 8060` (sends COOP/COEP; threads need them), then a **visible**
  browser: the Playwright browser, or Chrome on emulator-5554 after `adb reverse tcp:8060 tcp:8060` at
  http://localhost:8060/ (localhost is a secure context; 10.0.2.2 is not, so no threads there). A hidden tab stops the
  game's main loop (browsers pause `requestAnimationFrame`): the Claude-in-Chrome tab is usually hidden, so it looks
  frozen. `tools/cdp_eval.py` reads FPS, runs JavaScript and prints the console of the emulator's Chrome (DevTools
  protocol over `adb forward tcp:9223 localabstract:chrome_devtools_remote`). An installed or visited build is cached by
  its service worker: clear it (`navigator.serviceWorker` registrations and `caches`) before testing a new export.
- **Updates:** a returning visit's page and its service worker must be of one build. `tools/export_web.sh` writes
  one id (Godot's cache name) into `index.html` (`EC_BUILD` in `web/shell.html`) and the worker (it answers the message
  `ec-build` on a MessageChannel). A returning page asks for a newer worker (`reg.update()`, 3 s at most), waits for it
  to take over, and reloads once (a `sessionStorage` guard) when the worker's build differs. Check it by reading the
  page's `EC_BUILD`, asking the controller, and comparing `GODOT_CONFIG.fileSizes` with the delivered pack's
  `performance.getEntriesByType('resource')` size.
- **A child's first minute on the emulator:** `~/src/cdpenv/bin/python tools/web_emu_flow.py <label> <idle s> [s] [--keep]`
  (setup in its header: `web_serve.py` on 8060, `adb reverse`/`forward`, the emulator sideways) visits as a new player
  (or a returning one with `--keep`), taps into the first world like a child and prints every long frame with the
  game's console lines. The shader warm-up was judged with it (`docs/devlog/parts/m7-shader-warmup.md`).
- **A browser that cannot run the game** (no WebGL 2 or WebAssembly: a PlayStation's, an old TV's; owner #90) gets a
  kind page from `web/shell.html`'s first script (old-browser JavaScript, before the engine's script; the engine's
  script missing or unreadable says "a newer browser"). Check it in a real headless Chromium without an export:
  `PW_HOME=~/src/pwenv node tools/web_kind_page_check.mjs` (4 cases: everything there, `--disable-3d-apis`, no
  WebAssembly, no engine script; prints `KIND_PAGE PASS`). A game controller's button also presses the page's PLAY.
- **On many devices at once:** `PW_HOME=~/src/pwenv nice node tools/web_device_matrix.mjs <url> <out-folder>` runs the
  page in Chromium, Firefox and WebKit as a PC, a Mac, Android phones and a tablet, iPhones and an iPad (one after
  another, about 4 minutes): page ready, menu after PLAY, threads, page errors, and a picture per device after the
  game's PLAY. The latest run and the list of browser-vs-app differences: `docs/web/parity.md`.
- **As an iPhone (WebKit, Safari's engine):** `PW_HOME=~/src/pwenv node tools/web_iphone_check.mjs <url>` runs
  Playwright's WebKit with an iPhone 15's screen, touch and user agent: the GitHub link must send it on to our server,
  PLAY starts the game, the age pad (only with the age rules on, #69), the name box (the visible field at the top) and typing; screenshots
  `iphone-*.png` in the temp folder (or the folder given second; never the project: Godot would import them). Setup in the script's header (Playwright in `~/src/pwenv`, `npx playwright
  install webkit`, two apt libraries). It proves the page, threads and typing in WebKit, not that a real iPhone
  opens its keyboard.
- **Full screen:** the Web preset's `html/head_include` script goes full screen on the first tap/click and locks
  landscape; installed, the manifest opens it full screen. iPhone Safari cannot: a hint says "Add to Home Screen".
- **Deploy:** `tools/deploy_web.sh` (brotli + gzip, rsync to `~/easycraft/server/deploy/play/` on the server), served
  by Caddy at **https://178-104-20-64.sslip.io/play/** with COOP/COEP (`server/deploy/caddy/Caddyfile`); and
  `tools/deploy_web_github.sh` → **https://giorgipirveli.github.io/easycraft/** (web files only; iPhones are sent on to
  the server's copy: WebKit ignores the headers a service worker adds). The first visit downloads about 19 MB (brotli:
  `index.pck` 2.6 at `-q 11`, the assets pack 6.4, the engine 8.5, Voxel Tools 1.2); the music (19 MB), the reels' videos (19.6 MiB:
  Theora barely compresses) and then the realistic pictures (7.8 MB brotli, 35 MB raw; GitHub Pages gzips them itself)
  follow while the child plays. A
  refresh downloads nothing; **an update that changes only code about 2.8 MB** (the code pack, the page, its icons).
  Check a build with `~/src/cdpenv/bin/python tools/web_check.py <url> [seconds]` (headless Chrome: a first visit,
  PLAY, the packs, then a refresh and the MB it fetched; the live server: 0.00 MB, the menu in 4 s). Headless Chrome
  draws in software at a few frames a second and `HTTPRequest` takes one 256 KiB piece a frame: give it 200 s to see
  "the realistic pack is in" (a phone at 30 FPS takes 36 MB in about 5 s). **The update case:** copy an export's
  `build/web` aside (A), change something and export again (B), then `~/src/cdpenv/bin/python
  tools/web_update_check.py <A> <B> [port] [first-visit seconds] [--etc2]`: one kept Chrome profile visits A, then B at
  the same address, a refresh and B's Survivor world, and prints what the server sent in each (raw bytes; the service
  worker's own downloads included). A code-only change: `index.pck` and the small files, never the assets pack,
  `index.js`, the engine or the background packs.
- **Without the internet (owner #93):** after one full visit the page opens offline: the worker takes the page from
  the network when it can (an update reaches it at once) and else its own build's `index.html`, when every file of
  the game is kept (`ecOfflinePage` in `tools/export_web.sh`); a first visit cut short gets `web/offline.html` (the
  Web preset's offline page). Check it: `python3 tools/web_serve.py build/web 8068`, then `PW_HOME=~/src/pwenv nice
  node tools/web_offline_check.mjs http://localhost:8068/ <out-folder>` (online visit, network cut, reload, a new
  player, SANDBOX; screenshots of each step). The game's own "can't reach the game" cards add
  `OnlineRules.PLAY_ALONE` (`OnlineUi.play_alone`): what works alone, and that the gold waits on the device.
- **An update, then offline (owner #95):** a new version's worker downloads this device's whole game before it takes
  over (`ecKeepUpdate` in `tools/export_web.sh`: the kind of main pack the device kept, phone or computer), so an
  update that arrives while the child plays online still opens offline; if the download fails the old version stays.
  The page asks for an update when the browser is online again and a minute after the start (`checkForUpdate` in
  `web/shell.html`). Check it: two builds A and B (copy `build/web` aside, export again), a symlink the server serves,
  `python3 tools/web_serve.py <symlink> 8071`, then `PW_HOME=~/src/pwenv nice node tools/web_update_offline_check.mjs
  <A> <B> <symlink> 8071 <out>` (A online, the symlink turned to B, an update asked, the network cut, a reload: B's
  page and the game's menu, offline: PASS).
- **Signing in again by itself (owner #95):** `ReconnectWatch` (`net/reconnect_watch.gd`, made by
  `Session.online_autostart`) retries sign-in for a device that has been online before, 20 s to 10 min apart
  (`ReconnectRules`), at once when the browser's `navigator.onLine` turns true (`WebGlue.browser_online`); sign-in sends
  everything kept offline; `Session.back_online` → "Back online! …" on the menu and the HUD.
- **Shader compiles (the browser's freezes):** `~/src/cdpenv/bin/python tools/web_shader_probe.py build/web --continue`
  counts the WebGL programs each phase of play links, and the long frames they cause (§7 "Shader compiles in a
  browser"); `--no-warmup` measures the same build without the warm-up (§5 "The shader warm-up").

### VR on the Meta Quest: the Quest APK, the desktop preview, the tests (owner #101; the rig side)
**The owner's Quest session of 2026-10-17 (#124-#128):**
- **Held items point along the laser** (#124): a hand model follows the controller's **grip** pose (its -Z: the
  straightened index finger), the laser, taps and shots its **aim** pose, ~40° apart on the Quest; the item anchor turns
  by `Vr.aim_in_grip(side)` every frame, so a barrel or a blade points where the laser points. **Shots leave the weapon**:
  `Vr.muzzle(item)` (a blaster's barrel tip, the bow hand), sent just before the shot (`Session.request_shot_origin`,
  believed within `SHOT_ORIGIN_REACH` 1.6 m of the eye) and used by `BlasterDirector.spawn_blast` and
  `CombatDirector`'s arrows and boomerangs (`Session.shot_origin(p)`, else the eye). A drawn bow shoots straight along
  its arrow (`attack_towards(..., straight = true)`). **Tests must give a grip pose** (`Vr.sim_grip`): without one the
  grip is the aim, which hid all of this.
- **The hands in the rocket** (#126): the hands and what they hold draw on `VrRules.HANDS_LAYER` (1 << 15) besides the
  world's; `Vr.view_like` always adds it (the flight in space draws only its own layers).
- **The HUD on a raised forearm** (#127): while playing the HUD panel is HIDDEN; `VrPanelRules.shield_up` (the off hand
  ahead of and a little below the eyes, its line across the body; slack once up) shows it as `SHIELD`, 0.5 m wide just
  above that hand, facing the eyes; the wrist strips rest meanwhile; menus, the pause and loading stay at `EYE`; the
  `--vr-preview` keeps `TRAY`. Tests: `test_vr_shield_rules.gd`, `test_vr_ui_shield.gd`.
- **A held sword hits by swinging it** (#128): `VrRules.SWING` is now "vr_sword_swing", on by default, for a melee weapon
  in the hand only (never fists, a block, a bow or a wand). Tests: `test_vr_quest_fixes.gd`.

The plan `docs/superpowers/plans/2026-10-15-vr-quest.md`, the research `docs/devlog/parts/vr-research.md`, the rig's
notes and rulings `docs/devlog/parts/vr-rig.md` (the panels': `vr-ui.md`). Architecture: §5 "VR: the rig".
- **The Quest APK** (preset "Quest": Gradle, OpenXR, arm64, min SDK 32, target SDK 34, package
  `com.giorgi.easycraft.quest`, the Mobile renderer, feature tag `quest`; "Quest GL" is the Compatibility twin for the
  renderer A/B, the same package):
  ```bash
  JAVA_HOME=$HOME/.local/jdk17 ANDROID_HOME=$HOME/android-sdk nice godot --headless --path . \
    --install-android-build-template --export-debug "Quest" build/android/EasyCraft-quest.apk
  ```
  Godot's OpenXR export adds the Khronos loader `org.khronos.openxr:openxr_loader_for_android:1.1.54` (Maven Central;
  in this PC's Gradle cache since 2026-10-16, the owner's yes, #108). **The Meta vendor:** `addons/godotopenxrvendors/`
  is the Godot OpenXR Vendors plugin 5.1.0-stable (GitHub's `godotopenxrvendorsaddon.zip`, sha256 6a838dbd…e2911; MIT,
  the Meta part under the Oculus SDK licence); the Quest presets set `xr_features/enable_meta_plugin=true` and
  `meta_xr_features/quest_2_support`/`quest_3_support` (Pro off: Meta does not support it for under-13s). Every other
  preset that exports the whole game has `addons/godotopenxrvendors/*` in its exclude filter (the media-only packs never
  take it; `test_assets_pack.gd`), and the Theater's WebView library stays out of Quest builds
  (`addons/easycraft_webview/plugin.gd`). A debug APK is about 185 MB; check it with `aapt2 dump xmltree <apk> --file
  AndroidManifest.xml` (the VR category, `com.oculus.vr.focusaware`, `quest2|quest3|quest3s`, Horizon OS SDK 69) and
  `unzip -l` (`libopenxr_loader.so`, `libgodotopenxrvendors.so`).
- **OpenXR on this PC (Monado, before a headset run):** Monado 25.0.0 (`monado-service`, `libopenxr1-monado`, Ubuntu's
  universe; the active OpenXR runtime). It watches its stdin, so from the Bash tool give it a pipe:
  `sleep 3000 | SIMULATED_ENABLE=1 XRT_COMPOSITOR_NULL=1 nice monado-service` (a simulated headset, no window; it paces
  at 20 FPS). Then `XDG_DATA_HOME=<private> godot --path . --xr-mode on --rendering-method mobile --script <a SceneTree
  script that calls Vr.start(&"openxr") and changes to the main scene>`: on 2026-10-16 the menu and a Sandbox world ran
  in VR with no script errors (OpenXR 1.1.54, the Mobile renderer, multiview on the Intel iGPU); the game's VR_BENCH
  lines print (230 draws in the Sandbox then; P5 cut them, §7 "VR on the Quest"). `[xr]` in project.godot turns OpenXR and the
  multiview shaders on only for the `quest` feature (`openxr/enabled.quest`, `shaders/enabled.quest`); phones, the web
  and the desktop never start OpenXR. The action map: `openxr_action_map.tres`, written by
  `nice godot --headless --path . -s res://tools/vr_action_map.gd` (Touch, Touch Plus, generic and simple controllers).
- **Install on the owner's Quest** (the lead; the owner's one-time steps are in the plan): find its serial with
  `ANDROID_ADB_SERVER_PORT=5038 ~/android-sdk/platform-tools/adb devices -l` (model `Quest_2`, `Quest_3`...), then every
  call names it: `ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=<QUEST_SERIAL> ~/android-sdk/platform-tools/adb install -r
  build/android/EasyCraft-quest.apk`, `... shell am start -n com.giorgi.easycraft.quest/com.godot.game.GodotAppLauncher`,
  `... logcat -s godot:V | grep VR_BENCH` (a line every 10 s: fps, the worst frame, frames over 28 ms, draws, primitives,
  process, physics and GPU ms). Never `emulator-5554`'s packages from that serial, never `emulator-5556`. If the other
  app's adb grabs the headset (the connection flaps): Wi-Fi adb (`adb tcpip 5555`, `adb connect <ip>:5555`) or a private
  server, `ANDROID_ADB_SERVER_PORT=5039 adb start-server --one-device <QUEST_SERIAL>`.
- **The desktop preview** (no headset): `godot --path . -- --vr-preview` runs a session on fake trackers and shows the
  head's view flat in the window, the `vr` preset on. Click the world (the mouse is captured as usual): the mouse turns the
  head, Q and E snap-turn, the game's keys walk, the mouse buttons place and break along the fake right hand (it points
  where the head looks).
- **The bench:** `XDG_DATA_HOME=/tmp/easycraft-vr-bench-smoke nice godot --path . --resolution 1440x1584 --rendering-method
  mobile --script res://tools/vr_bench.gd -- --seconds=20 --turns=4` (Green Meadows NEW, seed 12345, through the preview;
  VR_BENCH lines a second and a summary; `--flat` without the rig). A window: keep it in front (a hidden window is drawn
  about once a second). The draws are one eye's (multiview draws both in one pass); the frame times are this PC's, never a
  Quest's. **P5's options** (`docs/devlog/parts/vr-perf.md`): `--world=<n>` any world (16-28 the cosmos, 41 the Wonders),
  `--at=launch` beside the Launch Site's board, `--cruise=<s>` then a FLY cruise (about 11 m/s), `--menu` the main menu,
  `--blame` where the draws come from (each viewport's 3D, shadow and 2D draws, then each part of the scene and of the VR
  canvas hidden in turn: what it saves), `--long` every frame over 28 ms with its main-thread CPU, the voxel queue, the
  terrain's statistics and tools/frame_blame.gd's breakdown, `--time=<0..1>` the time of day, `--desktop-ui` this PC's HUD
  (by default the preview plays the Quest APK's platform: no touch HUD, the phone's canvas). The summary splits the draws:
  `draws_3d` (the scene's, Meta's budget) and `draws_2d` (the canvases': the HUD's tray is drawn every frame). **On a
  locked or hidden screen** (an agent's run) use Xwayland and no V-Sync: `--display-driver x11 --disable-vsync` before
  `--path` (Wayland stops presenting and the frames come once a second). The summary's `cpu_ms` is the main thread's own CPU
  a frame (/proc), robust to this PC's other programs; `process_ms` (one sample a second) is not. A profile with a VR
  preset: put `"graphics": "vr_plus"` (and `"style": "realistic"`) in the private folder's `profile.json`. `--shot=<dir>`
  saves the VR canvas and the head's view as PNGs. P5's tests: `tests/**/test_vr_perf_*.gd` (the presets and the refresh
  rate, `CanvasBatch`, the HUD's one-draw paths, the settings row, the first start, labels, bursts); they set
  `GraphicsPreset.vr_session` (or `headset`) themselves and put it back in `after_each`.
- **Tests** (headless, with `Vr.simulate(true)`: a fake head and two hands on the XRServer; `Vr.sim_head`, `sim_hand`,
  `sim_input` move them; `Vr.step(delta)` / `Vr.step_physics()` run a frame or a tick): `tests/unit/test_vr_rig_rules.gd`,
  `test_vr_rig_platform.gd`, `tests/integration/test_vr_rig_session.gd`, `test_vr_rig_player.gd`, `test_vr_rig_input.gd`
  (the controllers: `Input.flush_buffered_events()` after `VrInput.step`, the game reads the actions then); P3's
  `tests/unit/test_vr_rig_p3_rules.gd`, `tests/integration/test_vr_rig_p3_player.gd` (teleport, vignette, knock-out,
  sleep, Size Magic, hiding, the guest's mount, seats), `test_vr_rig_rocket.gd` (the seated flight), `test_vr_rig_photo.gd`
  (the held camera); P4's `tests/unit/test_vr_rig_pose_rules.gd`, `tests/integration/test_vr_rig_p4.gd` (hands, the
  held item, the bow, swings, a remote VR body, the mirror, the teleport refusals), `test_vr_rig_link.gd` (VrPoseLink:
  two games in one process, each subtree with its own fake `MultiplayerAPIExtension` set by
  `get_tree().set_multiplayer(api, subtree.get_path())`, whose `_rpc` calls the same node path in the other game as
  from that peer; a path the other game lacks is an older build), `test_vr_rig_mirror.gd` (the reflection's sums:
  `Camera3D.unproject_position` works headless); owner #106/#108's `test_vr_rig_descent.gd` (the trip flown with the
  controllers only, a frame at a time in a frame's order: `Vr.sim_input`, `Vr.step(dt)`, `Input.flush_buffered_events()`,
  `cockpit._process(dt)`, `flight.tick(dt)`); the lead's contract `tests/unit/test_vr_contract.gd`. Every `after_each`
  ends the session (`Vr.simulate(false)`, `Vr.anchor(null)`). A lambda's locals are copies in GDScript: a test that
  gathers inside a callback keeps its findings in a Dictionary (`test_vr_rig_rocket.gd`). Logs of the VR-RIG agent:
  `vrrig_*`, `vrrig3_*` (round 3).
- **Two games, one in VR** (LAN, this PC): `tools/net_test.sh --vr=host` (or `guest`): that game runs the preview with
  `--vr-wave` (its head nods, its right hand waves) and the other must see its VR body; `--old=guest` (or `host`) makes
  that game an older build (`--vr-old-peer`: no VrPoseLink) that must play as before and never hear a pose. The four
  runs (`--vr=host`, `--vr=guest`, each with `--old=` the other) pass (2026-10-16).
### VR on the Meta Quest: the panels, ENTER VR and `/vr/` (owner #101, VR-UI)
The plan `docs/superpowers/plans/2026-10-15-vr-quest.md`, the research `docs/devlog/parts/vr-research.md`, this side's
notes `docs/devlog/parts/vr-ui.md` (the rig, the native Quest APK and its install with the Quest's own adb serial:
VR-RIG's notes `docs/devlog/parts/vr-rig.md`). Off VR every `Vr` call is a no-op and nothing below is made.
- **Where the UI goes in a headset:** the root's 2D canvas is not shown in VR, so every CanvasLayer goes through
  `UiLayers.route(layer, owner)` (off VR: `owner.add_child(layer)`) into one transparent 1280×720 canvas,
  `Vr.ui_viewport()` (`VrUi`), shown on a world-space quad (`VrPanel`): the **eye panel** (a panel with the pad, the pause
  menu, a loading world: 1.4 m ahead, world-fixed) or the **tray** (the HUD, low, lazily following the head). PadFocus
  lives in the canvas in VR; the headset's controllers (VR-RIG's virtual pad) push into it first, the root's keys and a
  connected pad's events are forwarded into it; the laser (`VrPointer`, its beam and the ring) is its only mouse and
  finger. Render priorities: the panel 127, the beam 126, the loading room 110-111, VR-RIG's fade 100. **New UI code:** route a new CanvasLayer through `UiLayers.route` (one made under a routed layer's
  control is in the canvas already); a HUD control that needs the world's camera uses `VrUi.world_camera(self)` (the
  canvas has none); nothing is pinned to the face; words shown in VR are 24 px or more (P2's readability pass).
- **The WebXR route** (the Quest's browser, no developer account): `tools/export_web_vr.sh` (about 1.5 min) exports the
  "Web VR" preset (preset.16, feature tag `webxr`: the menu's ENTER VR; `xr/shaders/enabled.webxr` the multiview shaders)
  with the flat web build's own pipeline (`tools/export_web.sh`, untouched; checked swaps) into `build/web_vr/`: one main
  pack with both texture formats, its own browser caches (`EasyCraft-vr-files`), the way home `/vr/`. Try it:
  `python3 tools/web_serve.py build/web_vr 8061` and `~/src/cdpenv/bin/python tools/web_check.py http://localhost:8061/ 70`
  (no headset there: ENTER VR stays hidden). Deploy: `tools/deploy_web_vr.sh` (rsync to the server's
  `~/easycraft/server/deploy/vr/`), served by Caddy at **https://178-104-20-64.sslip.io/vr/** with `/play/`'s thread
  headers (`server/deploy/caddy/Caddyfile`, the `./vr` mount in `docker-compose.yml`). **Live since 2026-10-16 09:20**
  (owner #108): `tools/deploy_web_vr.sh` first (it makes the server's `vr/` folder as the kit's user; a mount Docker makes
  itself is root's), then the kit with that Caddyfile and compose (`kit.sh update` recreates Caddy for the new mount: a few
  seconds), `kit.sh check`. A new Web VR build later needs only the two `tools/*web_vr.sh` steps. The owner opens it in the
  Quest's browser and presses ENTER VR.
- **A desktop look without a headset:** `XDG_DATA_HOME=<private> godot --path . -- --vr-preview` (the menu) or
  `-- --vr-preview=sandbox` (on into the Sandbox world): VR-RIG's preview (else a simulated session); the panel in front
  of the head, a free mouse is the laser (left button: the trigger; a click on the panel never captures the mouse), a
  click in the world captures the mouse (mouse look turns the "head"), Esc frees it; `VR_PREVIEW place=…` lines in the
  log. Headless: `timeout 75 godot --headless --path . --
  --vr-preview=sandbox`.
- **Tests:** `tests/**/test_vr_ui_*.gd` (the panel side, with `Vr.simulate` and stand-in heads, rays and triggers;
  never the shared profile file) and `test_vr_contract.gd` (the lead's contract). `tests/run_tests.sh
  -gtest=res://tests/integration/test_vr_ui_canvas.gd` runs one.
- **Settings:** the `vr_*` keys in `ProfileData.DEFAULT_SETTINGS` (VrRules' defaults, `vr_text_size` "big"), device-only
  in backups; SETTINGS' VR COMFORT page shows only in a headset (`VrComfortPage`: every vr_* key, `value_of` checks
  them); the break card after `vr_break_minutes` (`VrBreakCard`, `VrUi.worn`).
- **Readability in VR (P2):** `VrReadability` lifts every word in the canvas to 24 px while VR runs (put back after; a
  size set again later is lifted again) and outlines light words on buttons. A screen whose words no longer fit at 24 px
  gets a VR-only change in its own file (`if Vr.active()`: two lines and "…", a picture alone, a wrap); a picture's own
  words (a Short's stage) carry meta `VrReadability.PICTURE`. Check new screens with the audit
  (`tests/integration/test_vr_ui_audit.gd`: no word under 24 px, fits, nothing past the edge or cut off; add the screen to
  `tools/vr_ui_screens.gd`) and look at them: `XDG_DATA_HOME=/tmp/easycraft-vr-shots godot --path . --disable-vsync
  --script res://tools/vr_ui_shots.gd` (a window for about 20 s; PNGs of the canvas in `user://vr_ui_shots/`,
  `VR_UI_SHOT` lines with each screen's smallest word). `test_vr_ui_reach.gd` reaches every menu, SETTINGS, School,
  Mission Board, Gold Shop and pause screen by the sticks and by the laser.
- **Typing in VR:** `VrKeyboard` comes up for any focused `LineEdit` / `TextEdit` in the canvas and types by pushing key
  events into it (a box needs nothing); while it shows it has the pad (`PadFocus.keyboard`). A `secret` LineEdit (a
  password) shows as dots on the keyboard's own line and gets a SHOW / HIDE key (it calls the parent's `toggle()`, as
  `PasswordField` has, else flips `secret`); never put a box's text into a toast, a label or `ReadAloud`.
- **Overlays in VR:** a `CanvasLayer` added with `UiLayers.route(layer, host)` is drawn in the VR canvas in a headset
  (and added to `host` off VR): the account overlay, the logged-out card and the device-move card go this way. A card
  that must come to the eye calls `PadFocus.watch(control)` when `Vr.active()`.
- **The HUD in VR:** the tray (the whole canvas), the wrist strips and the toast strip (`VrWrist` from `Hud.vr_rects()`);
  in a flight the cockpit's dashboard band (`FlightCockpit.dashboard_mode`, `dashboard_rect`, the canvas's bottom
  `DASH_REGION_H` = 520 px) on a quad at `RocketFlight.vr_dashboard()`. Anything the cockpit shows in a flight (the
  descent's panel, the hint card) must sit in that band in dashboard mode. The dashboard is a display except for
  `FlightCockpit.laser_area()` (the hint card: PRESS A TO GO!, pressed by A or by the laser's trigger; `VrPointer.dash*`)
  and, owner #110 (VR round 4), the three poke buttons STAGE, LEGS and LIGHTS (`FlightCockpit.poke_buttons`, places from
  `CockpitTouchRules.button_rects`): pressed by a fingertip only (RocketFlight's `_vr_touch`), never by the laser.
  Every VR mesh is on `VrPanelRules.LAYERS` (the world's and the flight's space layer).
### VR round 4: hands that hold things, bricks, waves, the Build Table, MODEL VIEW (owner #110, #116, VR-HANDS)
The plan `docs/superpowers/plans/2026-10-16-vr-round4.md`, the notes and rulings `docs/devlog/parts/vr-r4-hands.md`.
Architecture: §5 "VR: hands that hold things".
- **Tests:** `tests/**/test_vr_r4_hands_*.gd` (fake hands with `Vr.simulate`: `Vr.sim_hand` poses are the play space's,
  before the world scale: under MODEL VIEW's 25 a world point is `(rig.global_transform.affine_inverse() * p) /
  Vr.world_scale()`). Integration tests that lay bricks or wake builds use an EditWorld with `Session.register_world`
  (the host's own edits); the Build Table's stamps a per-process `MyStampBook.use(book, "user://…_<pid>.json")`.
- **The draws bench:** `XDG_DATA_HOME=/tmp/easycraft-vr-hands-smoke nice godot --display-driver x11 --disable-vsync --path .
  --resolution 1440x1584 --rendering-method mobile --script res://tools/vr_hands_bench.gd -- --seconds=6` (a window; the
  preview on the Quest APK's platform; `VR_HANDS_BENCH phase=play|play_looking_down|table|brick|model draws=… most=…
  draws_3d=… draws_2d=…`). `--taps` asks a world tap a second through `BlockInteractor.in_space` and one the old way: with
  an `override.cfg` (`[physics]` `3d/run_on_separate_thread=true`, a scratch run only, never committed) only the old way
  logs "Space state is inaccessible".
- **VR_BENCH lines** (P5's follow-up b) print `vr_preset=vr|vr_plus` and `draws_3d=` / `draws_2d=` beside `draws=`.
### VR round 4: wonders to hold: the orrery, the lenses, the Lab bench (owner #110, VR-WONDER)
The plan's VR-WONDER row (`docs/superpowers/plans/2026-10-16-vr-round4.md`), the notes and rulings
`docs/devlog/parts/vr-r4-wonder.md`. Architecture: §5 "VR: wonders to hold".
- **Tests:** `tests/unit/test_vr_r4_wonder_*_rules.gd` (OrreryRules, LensRules, LabBenchRules, the lens items, each
  wonder's School units checked against the curriculum), `tests/integration/test_vr_r4_wonder_orrery.gd`, `_lens.gd`,
  `_bench.gd` (fake hands with `Vr.simulate` on a real Player: a test moves a hand to a world point with
  `Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * at / Vr.world_scale()))`; the
  orrery's and the bench's `step(delta)` are called by the test after `Vr.step`, the Lab panel's `vr_step()` too; the
  Lab runs on its own `ProfileData` and a no-op `save_profile`).
- **The draws bench:** `XDG_DATA_HOME=/tmp/easycraft-vr-wonder-smoke nice godot --display-driver x11 --disable-vsync --path .
  --resolution 1440x1584 --rendering-method mobile --script res://tools/vr_wonder_bench.gd -- --seconds=6` (a window; the
  preview on the Quest APK's platform; `VR_WONDER_BENCH phase=play|play_looking_down|orrery|orrery_true_size|
  orrery_planet_in_hand|telescope_8x|magnifier|lab_bench|play_after draws=… most=… draws_3d=… draws_2d=… lens=…`, `lens`
  being the lens's own viewport).
- **The lens items:** `ItemIds.TELESCOPE` 500, `MAGNIFIER` 501 (`LENSES`, `is_lens`), VR only: not in `ItemIds.ALL` (no
  palette row, chest or shop off VR), the VR palette's SMART page LOOK row and Survivor's owned view (free tools); icons
  drawn in code (`LensIcons`). A new way to place blocks must keep refusing a lens (`BlockInteractor.place_block`).

## 5. Architecture

- **Engine:** Godot 4.7.2, statically typed GDScript. Renderer is Mobile (Vulkan) on phones and
  Compatibility (OpenGL) on the emulator. Landscape only (orientation 4), viewport 1280×720, desktop
  window 960×540.
- **Autoloads:** `Profile` (profile.json), `Game` (scene flow, settings, dev flags), `Session`
  (multiplayer and all world edits), `Audio` (short sound effects), `Music`, `Feel`, `Progress` (the
  progress event bus, M3 Task 12), `MCPGameBridge` (godot-mcp).
  - `Music`: day, night and boss loops on the `Music` bus, with 2.5 s cross-fades (`MusicRules`,
    `MusicMix`). Calls: `play_menu()`, `follow_sky(sky)` and `play_boss(on)`. `settings.music_volume`
    sets the bus. The audio pass: `MusicPlan` picks the cue from the MUSIC style (`settings.music_style`:
    game / classical / mix) and the mood (menu, morning, day, night, boss, underground); classical pieces
    (`MusicPieces`) play once each on two piece players, loaded on the loader thread; a starting piece shows
    "Now playing: …" (`settings.song_names`). More calls: `set_underground(on)` (Ambience's
    `AmbienceSounds`), `use_favourites(ids)` (the universe's `classical` pieces).
  - `Audio`: every effect on the `Effects` bus (`settings.sfx_volume`, the SOUND EFFECTS slider); pools of 6
    flat and 12 positional players that never grow; the same sound at most 3 times in 80 ms, a flat sound
    once a frame, positional sounds beyond 40 m of the camera skipped. Every `BaseButton` clicks by itself
    (a toggle softer; meta `ui_sound` picks another sound or `&""` for none) and `TouchButton` calls
    `Audio.touch` (`UiSoundRules`: JUMP, ATTACK, CROUCH, UP, DOWN and UNDO stay quiet, the hotbar ticks).
    Gold going up clinks; blocks coming into this game's bag pop (host and solo; a LAN guest's snapshots are
    new bags, so no pop). `play(sound, at, volume_db, pitch_scale)`: animals pass their own voice pitch.
    Owner #50: a sound never plays the same take twice in a row (`last_take`), and the signal
    `sound_played(sound, at, volume_db)` reports every sound that plays (tools and tests count by name).
  - Voices and footsteps: `VoiceRules` (animal calls, hurt and happy voices, each animal's pitch, the kinds'
    call gains, monster idle and hurt voices), `FootstepRules` (the block under the feet), `AmbienceSoundRules`
    (the loop for the place and time; `world/ambience_sounds.gd` plays it under `Ambience`).
  - **Animal idle calls (owner #50):** animals never call on their own. One `AnimalChorus`
    (`world/animal_chorus.gd`, added by the sandbox on every peer) asks `AnimalChorusRules.next_call` when a
    call is due and plays the chosen animal's call: at most one every 6–10 s per device, a kind rests 20 s,
    the kind heard least lately and the nearest first, far ones rarer and quieter, within 20 blocks of this
    device's camera. Hurt and happy voices still play at once (`Animal.knockback`, `cheer`); the chorus
    hears them through `Audio.sound_played` and lets that kind rest. Every animal kind needs a measured line in
    `VoiceRules.CALL_GAIN_DB` (owner #41, tested; §4 "The audio pass"). A wild animal asleep (`sitting`, not a pet:
    an owl by day, the herds at night) never calls.
  - **Monster idle voices (M5 Task 2):** monsters never speak on their own timers either. One `MonsterChorus`
    (`world/monster_chorus.gd`, beside the animals' chorus) asks `MonsterChorusRules.next_call`: at most one idle
    voice every 4.5–7.5 s per device, a kind rests 12 s, the nearest first, nothing beyond 20 blocks of the camera,
    a bat asleep under a ceiling is quiet. Hurt cries and a monster's growl on spotting a child play at once
    (`Monster._sound`) and make the chorus wait. Volumes: `MonsterChorusRules.volume_db` + `VoiceRules.monster_gain_db`.
  - **The loudness balance (M5 Task 2):** `Loudness` (`core/rules/loudness.gd`) turns the measured loudness into
    gains: `Music` adds `Loudness.music_gain_db(path)` to a universe's day and night loops and `piece_gain_db(id)` to
    a piece; `AmbienceSoundRules.volume_db` adds `ambience_gain_db`; the monster chorus `voice_gain_db` (via
    `VoiceRules.monster_gain_db`). Green Meadows' loops, the boss loop, the sea and the caves are the references and
    stay as they were.
  - **Particles (M5 Task 2):** every `Fx` effect counts against `Fx.MAX_LIVE` (32; a new one ends the oldest), and
    a `Fx.burst` farther than `Fx.FAR` (48 m) from this device's camera is never made (a stand-in comes back, never
    drawn, freed at the frame's end: callers may still set it up). Named bursts: `Fx.wake` (gold stars),
    `Fx.portal` (rainbow-gold), `Fx.level_up` (gold stars rising round the child), `Fx.confetti` (one emitter for
    many colours); all on the one shared material, stars from `Fx.star_mesh()`.
  - **Monster and boss moves (M5 Task 2):** `CreatureMoves` (pure numbers) gives the jumpers' pounce crouch
    (`winding` synced, `Monster._pounce_due`), the recoil lean on every hit (`Monster._recoil_look`,
    `StoneGolem._recoil_lean`), the bosses' breath while they stand and their cheer when they win
    (`StoneGolem._sink` waits `CreatureMoves.WIN_TIME`; each boss's DOWN pose cheers first; `win_sound()` roars).
  - **Menus (M5 Task 2):** `UniverseArt` draws every universe's scene from its own block tiles (the cards'
    `UniversePicture`, `UniverseBackdrop` behind a universe's own menu screens, the loading card); `TitleDiorama`
    rides on the menu's camera (hidden with Reduce motion, which also holds the camera still); `LoadingCard.cover`
    (sandbox `_setup_local_player`) shows `LoadingHints` until the local player stands in the world.
  - `Feel`: `shake(m, s)` on the local `CameraRig`, `vibrate(ms)` (Android), a red edge `flash(alpha)`,
    `slam(distance)`. The local player being hurt plays all three. It follows the Vibration and Reduce
    motion settings (`FeelRules`: never more than 3 flashes a second). Anything that moves the view must
    check `Feel.motion_allowed()`.
- **`core/` holds pure rules with unit tests** (no scene tree):
  - `building/`: placement, grid ray, block hit, edit batch, mirror, undo.
  - `input/`: touch classifier.
  - `magic/`: capture, buddy traits and names, sleep rules, riding (M3 Task 20a), buddy magic (M3 Task 20b: secret
    shapes, pictures, the album data, befriending, mini-buddies, tricks).
  - `rules/`: jump counter, physics mode, size magic, step (`StepRules`: auto-step and unstuck scaled
    to the body's size and footprint), spawn, water, swimming (`SwimRules`: water state, buoyancy,
    look-direction swimming, climbing out, splash strength; `SwimEffects`: when splash, ripples,
    bubbles, drips and strokes happen, per body, from the synced `Player.water_state`), graphics
    preset, weapons
    (`WeaponRules`: the weapon table, melee cone and aim assist, host reach/cooldown checks, knockback,
    arrows, boomerang, bullseye) and tool powers (`ToolPowers`: axe fells a tree, pickaxe 1×2 step,
    hammer 3×3 smash, as EditBatch input), the Physics Lab (`LabRules`: the LAB modes, what each game
    mode allows, Moon gravity, slow-motion time, zero-G drift and push-off) and pads (`PadRules`: the
    pad under a body, jump pad launch, speed pad burst, the per-body cooldown).
  - `save/`: JsonStore, profile data, world saves.
  - `codes/`: secret codes (M3 Task 13). `CodeRules` ships only salted SHA-256 hashes → rewards, once
    per profile (`ProfileData.codes_redeemed` holds hashes), and `CodeTries` is the rate limit. To add
    a code, see `docs/devlog/parts/m3-task-13.md`. Never write a plain code into a shipped file.
  - `validation/`: username, age band, names, birth year, the parent gate (`ParentGate`, M3 Task 17; three wrong
    answers in a row rest every gate for a minute, one count for the app run: the M4 review's E. Tests that open a
    gate call `ParentGate.reset_tries()` in `before_each`, so one file's wrong answers can't rest another's gate).
  - `theater/`: the Shorts Theater (M3 Task 17; owner #89). `TheaterChannels` parses the curated list
    (`data/theater/channels.json` or the server's; fails closed, the kill-switch is its `enabled` flag),
    `TheaterFeed` which list plays (the server's kept one, else the bundled one), `TheaterRules` the
    made-for-kids rules and which screen shows, `TheaterSession` next / back / tabs / cards / the end card,
    `TheaterEmbed` the Android page with the official embedded player.
    `core/rules/theater_site.gd` (`TheaterSite`) picks where the building stands.
  - `economy/` (M2): `Wallet`, Tilly's prices and trades (`ShopRules`), the stall's spot and reach
    (`TraderRules`), the fly cost (`FlyCost`) and short gold numbers (`GoldFormat`, "1.2K").
- **Tilly the trader (M2 Task 7):** `entities/npcs/trader.gd`, spawned by the host's `TraderSpawner`
  in Survivor worlds from `WorldMeta.trader_*`; a tap (`BlockInteractor.trader_tapped`) opens the HUD's
  `ShopPanel`; every trade goes through `Session.request_trade` (host checks reach, gold, room). The
  host charges Survivor flyers in `Session.fly_tick`. Notes: `docs/devlog/parts/m2-task-7.md`.
- **World:**
  - `world/world_service.gd` wraps Voxel Tools (`VoxelTerrain`, `VoxelMesherBlocky`, `VoxelStreamSQLite`,
    `VoxelTool`). Y range −64…192. It offers `get_block`/`set_block` (emits `block_changed`), `raycast`
    (GridRay), `surface_height`, `spawn_column`, `find_standing_y`, `is_area_ready`, save, and
    `apply_graphics`.
  - Terrain rules are pure and live in `world/generators/`:
    - `MeadowsShape`: continents, oceans, hills, mountains, river channels, bedrock top, layers, trees
      and the spawn column.
    - `CaveShape`: tunnels, caverns, crusts, entrances, flooded deep caves (M1b Task 4).
    - `OreRules` (`core/rules/`): ores and glowing crystals by depth (M1b Task 5).
    - The universes' own shapes extend `MeadowsShape` (desert, frost, candy); `DragonShape` (owner 39) floats islands
      over a void (no bedrock, no water, its own ores by depth under an island's top) and caches nothing but its
      spawn; `DragonGenerator` caches each chunk stack's columns and plants (`COLUMN_CACHE`).
  - `MeadowsGenerator` (a `VoxelGeneratorScript`, runs on worker threads) writes them into voxel
    buffers. `reference_block()` is its slow one-block reference, which tests compare the fast path against.
  - Every rule is a function of world coordinates only, so chunks meet without seams.
- **Every edit goes through `Session`**, even in solo play (which uses an `OfflineMultiplayerPeer`).
  - The host validates each edit with `PlacementRules.validate_edit`: reach, valid id, never inside a
    player, and never touching an unbreakable cell (bedrock). The cell's current block
    (`world.get_block(pos)`) is a required argument, so a caller can't forget it.
  - Batches (stamps, mirror, undo) go through `EditBatch.sanitize` (max 1600 entries) with `BATCH_REACH` 32.
  - **Undo steps come from the host**, never from the request (a LAN client can't know what the host
    refuses or skips). After each edit the host sends the requester the cells it really changed
    (`Session.undo_step_received`, over `_rpc_undo_step` for clients). After an undo, it sends the
    cells it couldn't restore yet, which are kept for later. `BlockInteractor` records only these.
  - **Survivor pays for every edit (M2 Task 3):** the host asks a `GatherLedger` (`core/survival/`,
    rules in `GatherRules`) before it changes a cell. Placing takes one from the requester's inventory
    ("You have no Stone left!"), breaking gives the drop (grass → dirt; leaves, water, bedrock nothing),
    ores need the best pickaxe owned (coal/iron any, gold/diamond/crystal iron+). Batches of placements
    (stamps, mirror) are paid whole or not at all; an undo is the exact reverse of its edit and waits
    for later when the block is gone. Sandbox (`UNLIMITED_BLOCKS`) never counts.
  - **Inventories reach the HUD by themselves:** `Inventory` emits `changed`; Session sends that player
    one snapshot per frame (`_rpc_inventory`). The HUD reads `Session.my_inventory` and listens to
    `Session.inventory_changed` (hotbar counts, faded empty slots, the Survivor palette of owned things).
    Change inventories only through `add` / `take` / `set_inventory`, or the HUD won't hear it.
- **LAN multiplayer:**
  - ENet, with a `hello → world_info → client_ready` handshake.
  - `MultiplayerSpawner` / `MultiplayerSynchronizer` for players and buddies.
  - Each player body is simulated by its owning peer; buddies are simulated by the host.
- **Secrets and treasures (M2 Task 16):** `SecretRules` (`world/generators/secret_rules.gd`) places a few
  secrets per 128 × 128 area from the seed (buried treasure, hidden rooms, puzzle temples, sky islands,
  crystal geodes) as lists of boxes that stay inside their area; the generator writes them last in every
  chunk. `SecretDirector` (`world/secret_director.gd`, node `Secrets` on every peer) spawns their things near
  players (`entities/interactables/`: chests, riddle notes, plate pictures, the Wanderer; physics layer 512),
  notices finds, rings the secret chime, and decides chest / knock / answer requests (Session section "M2
  Task 16"). Dusks and nights bring the Wanderer and shooting stars (`SurpriseRules`); golden animals ride on
  the animal spawns. Loot: `LootRules`; per-world state: `SecretState` in `WorldMeta.secrets`; the
  account-wide Secret Book: `ProfileData.secret_book` and `treasures`. HUD: BOOK button, banners, the
  treasure map's compass, the riddle panel (`ui/hud/`); pictures for children who can't read: `Pictures`.
  Details and rulings: `docs/devlog/parts/m2-task-16.md`.
- **Online (M4 early spike):** the same game over a Nakama relayed match. `NakamaLink`
  (`net/nakama_link.gd`) signs in with `DeviceId` (`user://device_id.json`) and wraps the match in a
  `RelayBridge` (`net/relay_bridge.gd`, a `NakamaMultiplayerBridge` that sends packets over 32 KiB in
  `RelayPieces`), which is the `MultiplayerPeer`. `Session`'s section "M4 early: Nakama online peer"
  hosts (`host_online`) or joins (`join_online`); solo and LAN never load the Nakama client.
- **Online play with friends (M4 Wave 1, Agent C):** the main menu's PLAY ONLINE opens
  `PlayOnlineScreen` (`ui/online/`): the stay-safe card, the username claim, "Ask a grown-up" (the
  parent gate, then consent), HOME (HOST MY WORLD, FRIENDS). `OnlineService` (`net/online_service.gd`,
  made on first use by `Session.online_service()`, section "M4 C: online play") keeps the account,
  friends, invites and consent over an `OnlineBackend`: `NakamaOnlineBackend` (its own `NakamaLink`,
  loaded by path) or, in tests, the fake in `tests/fakes/`. Pure rules: `OnlineRules` (screens,
  consent gating, invites, plain words), `OnlinePrefs` (`user://online.json`: the card, mutes). The
  invite toast sits over every scene (Session's CanvasLayer 90); the host invites from the pause
  menu's INVITE FRIENDS row; the HUD shows a dot while online. Notes and rulings:
  `docs/devlog/parts/m4-c.md`. Timing the backend against a server:
  `godot --headless --path . --script res://tools/measure_online_backend.gd`.
- **Accounts, parents and the economy online (M4 Wave 2, agent F; spec §17.1, §17.2, §17.6):**
  - Profile backup: `ProfileSync` (`net/profile_sync.gd`, a child of `OnlineService`) keeps the
    profile in the player's private `profiles/profile` storage (`ProfileBackup`, `core/save/`: the
    profile's JSON minus graphics, view distance and FPS). Uploads 5 s after `Profile.saved` goes quiet
    (at most 30 s), at quit and in the background; at sign-in it merges (the newer by
    `ProfileData.updated_at` wins, a profile with no progress is restored, gold never goes backwards on
    the phone, codes / things owned / universe / Secret Book never lost). Claimed accounts only.
    **Owner #67 changed this** (next bullet): no gold in the backup, per-choice merge, writes by version.
  - **The account on every device (owner #67, module 0.2.12; spec §5.13, §17.1):**
    - *Sign-in key:* `OnlineService.make_account_key` / `account_key_state` / `sign_out_other_devices` (section "Owner
      #67" at the end) behind GROWN-UPS → ONLINE PLAY → OTHER DEVICES (`AccountKeyPage`, `ui/parents/`);
      `sign_in_with_key(name, key)` from PLAY ONLINE's name claim → I HAVE AN ACCOUNT → the parent gate →
      `KeySignInPage` (`ui/online/`): it makes a new `DeviceId`, the server's `sign_in_with_key` links it to the
      account, the service keeps it (`device_id.json`, `WebStorage.sync()` in a browser), signs out and in again, and
      `_f_signed_in` does the rest (the account's name into the profile, `ProfileSync.sync`, `sync_wallet`). Only
      while the device has no claimed name of its own (`already_claimed`).
    - *Backup layout 2* (`ProfileBackup.BACKUP_VERSION`): no `survivor_gold` (the wallet ledger), `DEVICE_ONLY_FIELDS`
      (gold, `hud_moves`, `farm_note_at`) and `DEVICE_ONLY_SETTINGS` (+ the install card, the farm note) stay on the
      device. `ProfileData.stamps`: per group of choices (`ProfileBackup.GROUPS`: look, settings, switches, pets) the
      unix time it last changed; `Profile.save` stamps groups whose travelling JSON changed (`stamp_changes`; a group
      that came with its own stamp from a merge keeps it); a profile from before has every group stamped with its
      `updated_at` (`from_json`). `merge`: earned things as before, choices per group (the newest), a new device takes
      all of the account's, device-only from the local copy, gold always the local one.
    - *Writes by version* (`ProfileSync`): `_version` from the last read or write; `write_storage(..., version)`
      (`"*"` when there is none); Nakama's "version check failed" is `version_clash` (`NakamaOnlineBackend.storage_error`)
      → read, merge, write again (`MAX_TRIES` 3). `bad_profile` / `not_allowed` / `too_big`: not again until the next
      change. The menu opening (`Session.online_autostart`, after a world) flushes at once.
    - *Wallet:* `WalletSync.plan/settle` end with the server's balance plus the device's unreported change (gold given
      on the server or earned elsewhere arrives; spent elsewhere is gone here); `account.gold` follows the sync's own
      report; no sync inside an online world (`in_online_world`, default `Session.is_online()`); `Session.gold_changed`
      tells the counter.
    - *Server:* `server/modules/src/rules/key_rules.ts`, `profile_rules.ts`, `src/server/keys.ts`, `guards.ts` (the
      write hook cleans the value in place). Tests: `npm --prefix server/modules test` (`key_rules`, `profile_rules`,
      `keys_rpcs`), `tests/unit/test_profile_backup.gd`, `test_profile_stamps.gd`, `test_wallet_sync.gd`,
      `tests/integration/test_profile_sync.gd`, `test_account_key.gd`, `test_account_key_pages.gd`,
      `test_online_wallets.gd` (fake server: `link_device`, `keys`, `O67_CALLS`); against a real server:
      `EASYCRAFT_SERVER=http://127.0.0.1:<port> node --test server/modules/test/integration/keys.server.ts` and
      `EASYCRAFT_TEST_SERVER=127.0.0.1:<port> tests/run_tests.sh -gtest=res://tests/integration/test_nakama_account_key.gd`
      (pending on a module older than 0.2.12). Notes and rulings: `docs/devlog/parts/owner-67-cloud-profile.md`.
  - Codes: signed in, `OnlineService.redeem_code` asks the server (`CodePanel` uses it); offline,
    `CodeRules` as before; codes used offline are recorded at sign-in (`redeem_code {"hashes"}`).
    *Module 0.2.19 (`docs/devlog/parts/gold-double.md`, "The two leftovers"):* gold the phone pays by its own check
    (offline, or the server's answer was lost) waits in `ProfileData.codes_unsettled` (device-only) for the server's
    word: the server remembers the gold codes it paid (`codes/redeemed`'s `paid`), answers `already_used` + `paid`
    and a record's `paid` list, and `OnlineService._f_code_settled` moves the marker for the ones it paid (the code is
    the account's once). A sync settles them first (`_f_settle_codes`) and never plans while one is unsettled.
  - Survivor gold online: the server keeps each player's balance. The online host starts a guest's
    wallet from the server (`OnlineWallets.starting_gold` → `get_gold_of`), reports every change of every
    player (`OnlineService.report_gold`, `WalletReport`: batched 5 s per player → `wallet_award` with
    `user_id` + `match_id`), and a guest's game adds each change to its own gold (`Session._rpc_gold_moved`).
    The server limits a guest's spends the host reports (module 0.2.10: `limits/wallet_spent`, `spend_limit`;
    the host drops a refused piece like its other refusals).
    `OnlineService.sync_wallet` (`WalletSync`, a per-account marker in `user://wallet_sync.json`) sends
    what changed off the server's watch when signed in. LAN keeps the M2 way (Session section "M4 F").
    *The gold-double bug (2026-10-01, `docs/devlog/parts/gold-double.md`):* a call that pays gold on the server and
    then on the phone (`redeem_code`, `farm_collect`) counts in `_f_paying` while on its way, and its gold on the phone
    goes through `_f_move_marker`; `sync_wallet` reads the wallet only when none is on its way and none crossed the
    read (`_f_read_wallet`). A new paying call must do both, or it can cross a sync and be counted twice. Fake-server
    seam for such orderings: `FakeOnlineBackend.answer_frames` (the server does the call at once; only the answer is late).
    *The host's last batch (module 0.2.19):* the host counts each guest's gold moves (`WalletReport.seq`), sends the
    count with each `_rpc_gold_moved` and with the last piece of a guest's batch (`wallet_award`'s `seq`; a net-zero
    batch as a 0 piece), and sends its batches at once when a guest leaves or it closes its world
    (`Session._f_flush_wallet_reports`); the server takes a seq batch even after the guest or the host left (the match
    it saw the guest in, its host, 24 h) and answers the last count in `get_account_state`'s `hosted`. A guest's sync
    after the world waits (`HOST_WAIT_MSEC` 15 s at most) until `hosted` has the count it was told
    (`Session.hosted_gold_seq` → `_f_host_wait`); a host's own last batch goes up before its sync reads. Older servers
    (no `paid`, no `hosted`) work as before. More seams: `FakeOnlineBackend.lose_answers` and `call_frames` (a call reaches the server late; lose: the server does the call,
    the answer never arrives), the fake server's `old_module` (answers as 0.2.18), `leave_match`. Real server:
    `EASYCRAFT_TEST_SERVER=127.0.0.1:<port> tests/run_tests.sh -gtest=res://tests/integration/test_nakama_wallet_exact.gd`
    (pending before 0.2.19).
  - Parent controls: `GrownUpsPanel` (`ui/online/`) behind the parent gate, from PLAY ONLINE and from
    SETTINGS' GROWN-UPS: ONLINE PLAY (consent state, switches), FRIEND REQUESTS (an under-13 player's
    requests wait for a grown-up: the server's AddFriends hook and `approve_friend`), PLAY & PHOTOS (PLAY TIME before
    M5 F1: `PlayClock`, `ui/parents/`, made by Session; `PlayTime` in `user://play_time.json`, device only; and the
    "Photo sharing" ON / OFF switch, `ProfileData.photo_share` through the service's profile, `PhotoRules.may_share`:
    off by default for under-13, on for 13+, saved at once, no online account needed),
    and PRIVACY in the title row (M5 Task 4: Play's User Data policy wants the privacy policy inside the app): the
    trust promise (`GrownUpsPanel.PROMISE`) and buttons that open `OnlineConfig.privacy_url()` /
    `delete_account_url()`, the release server's public pages (`server/deploy/site/`, made from `docs/store/` by
    `python3 tools/make_store_pages.py`; `test_grown_up_privacy.gd` holds the paths to the Caddyfile and the tool).
    Store work before production: `docs/store/pre-launch-checklist.md`.
  - Age signals: `AgeSignals.for_platform()` (`net/`): a no-op off Android; `AndroidAgeSignals` uses a
    plugin singleton `EasyCraftAgeSignals` when the APK has one (not built yet); `AgeSignalsRules` maps
    the store's range to our bands, only ever stricter. Notes and rulings: `docs/devlog/parts/m4-f.md`.
- **Data rights and retention (M4 Task 8b, agent G; spec §5.14, §17.2; `docs/store/`):**
  - DELETE MY ONLINE ACCOUNT: a button on the grown-up area's ONLINE PLAY page opens
    `DeleteAccountPage` (`ui/parents/`): what goes and what stays in adult words, a `HoldButton` held 3 s.
    `OnlineService.delete_account_start` / `delete_account` call the server's `delete_account` twice (a
    confirmation, then the deletion), then `forget_online` deletes the device's online files
    (`online_files()`: `device_id.json`, `online.json`, `wallet_sync.json`, each with `.bak`/`.tmp`) and
    the cached account. Worlds, the profile and play time stay. The grown-up area signs in by itself only
    when `has_online_link()` (a device id is kept), so it never makes a new account.
  - Server (module 0.2.3): `delete_account`, the retention clean-up (after every device sign-in, at most
    once a day; `retention_run` for the owner), the sign-in record (`activity/signed_in`), the reported
    message's snapshot (`report_user` with `message_id`; the after-ChannelMessageSend hook remembers
    messages for an hour). `server/README.md` has the details, `docs/hosting.md` the owner's steps.
  - Logs: Caddy's access log is its own file, rolled every midnight, none older than 14 days
    (`server/deploy/caddy/Caddyfile`, `./kit.sh access`); Docker's logs keep no addresses.
    `tests/unit/test_hosting_kit.gd` checks it. Notes and rulings: `docs/devlog/parts/m4-g.md`.
- **Friends apart (M4 Wave 3, agent I; spec §17.5, research T3, T4, D5):** module 0.2.4
  (`server/modules/src/server/gifts.ts`; `server/README.md`) and the game's side:
  - A build travels as one text (`BuildCodec`, `core/gifts/`: version, size, LEB128 runs; the server's
    `BuildRules` decodes and checks every one: 8³/512 for a present, 4³ for a bottle, 32³ and 48 KiB for
    a showcase). `BuildPicker` (`core/building/`) picks the connected non-natural build under a tap;
    `BuildOutline` (`ui/gifts/`) makes it glow with one shared material.
  - In a world: **SHARE** in the MORE panel (`SharePanel`, the sandbox's section "M4 I"; only in the
    child's own world, signed in with friends allowed): GIFT A BUILD (the next tap on the world picks:
    `BlockInteractor.tap_override`) and MY SHOWCASE (`ShowcaseArea`: 32³ around the child from 8 layers
    under the feet; the snapshot reads the area's copy on a worker thread).
  - PLAY ONLINE → FRIENDS: **GIFT** (`GiftSendPage`: a build from the shelf of the last 8 picked, or a
    bottle, `BottlePage`: a wheel phrase and maybe a tiny build) and **VISIT** on a friend's row;
    **PRESENTS** (`GiftsPage`: open into a stamp, delete, report) and **MY SHOWCASE** (`GuestbookPage`:
    stickers, delete, report, take it down) beside ADD. `OnlineService` section "M4 I" makes the calls
    (notes 104/105/106 nudge an open game; muted and blocked players' things are hidden).
  - Friends' builds are stamps on the device (`GiftStampBook`, `user://gifts.json`, not in the profile
    backup; item ids 460–479, placed by `Blueprints`; the palette's GIFTS tab). Deleting the online
    account forgets the file (`online_files`).
  - **The visit** (`world/visit/visit.tscn`, `VisitWorld`; `Session.start_visit` / `leave_visit`): an
    island of its own (`VisitGenerator`, `WorldService.setup_visit`) with the showcase in the middle, the
    friend's name on a sign, their buddy waving (`Buddy.visiting`), the visitor's player and the HUD with
    building hidden; the world never registers with Session, so nothing can change there; the bar
    (`VisitPanel`): STICKER, REPORT, LEAVE.
  - **Bottles** float up near this player when playing starts and when one arrives (`BottleShore`, node
    `Bottles`, this game only; `BottleSpot`: water, beach, ground); `GiftBottle` is a secret thing (tap
    layer 512; `SecretTaps.use` calls its `tapped()`); `BottleCard` says who and what.
  - **Buddy playdates** (`PlaydateDirector`, node `Playdates` on every game; `PlaydateRules`): the host
    decides at most 10 times a second (`Buddy.playdate_target`), the wave and the dance go to every game
    by one reliable RPC each.
  Notes, measurements and rulings: `docs/devlog/parts/m4-i.md`.
- **Ghost races on friends' courses (M4; spec §17.5, research T2):** module 0.2.6 (`share_ghost`,
  `list_ghosts`: `server/modules/src/rules/ghost_rules.ts`, `src/server/ghosts.ts`) and the game's side:
  - A ghost (`RaceGhost`, `core/ghosts/`) is the world owner's own best run on a course
    (`CourseBook.mine`, apart from anyone's best), sampled 5 times a second in decimetres from START's top,
    with the racer's look code; checked on this side exactly as the server checks it (START and FINISH where
    it says in the box that travels, from START to FINISH, inside the box and a margin, ≤ 40 m/s, jumps only
    onto a START, CHECKPOINT or TELEPORT_PAD). `GhostShare` finds the owner's courses in a showcase area or
    a picked build; `GhostRaceRules`: medals against the ghost's time (×1, ×1.3, ×1.6), names only for 13+
    or with verified consent, kind words.
  - Sharing: SHARE's SHOW IT takes the courses in the frame along, GIFT A BUILD of a whole course sends the
    race with the present (`SharePanel` section); a new own best on a course inside the child's showcase
    replaces its ghost (the sandbox's section "M4 ghost races"). `OnlineService` section "M4 ghost races".
  - Racing: `GhostRaces` (this game only, never over the network) links ghosts to STARTs and puts a
    `GhostRunner` (a blocky body in the friend's look, see-through by `GhostLook`'s material twins, no
    collision of any kind) on the START near the player; M3 Task 7's START and timing run the race and
    `CourseDirector.state_filter` gives the medal against the ghost. In a visit the friend's courses work (the
    visit is its own world: `CourseDirector.setup_own_world`; `Hud.push_top` puts the race clock under the
    visit's bar); in the child's own world a gift's race waits where its stamp was stamped
    (`BlockInteractor.stamped`, `GhostShare.stamped_start`).
  - Offline: `GhostBook` (`user://ghosts.json`, not in the profile backup) keeps friends' showcase ghosts with
    the showcase's build, gifts' ghosts by stamp slot and where they were stamped, the child's best against
    each; PLAY ONLINE's can't-connect page offers FRIENDS' RACES. Deleting the online account forgets it.
  Notes, measurements and rulings: `docs/devlog/parts/m4-ghosts.md`.

- **The shop and trading (owner #37, spec §14.23):** Survivor only; gold is never sold (owner #35's shop is the
  grown-ups'). Pure rules: `TradeRules` and `TradeTable` (`core/trade/`: offers of ≤ 8 kinds and gold ≤ 500 × 2^(u−1),
  never a universe crystal or the Gold Farm; the all-or-nothing swap, every give taken before anything is added; asks
  and open trades; the under-13 friends rule online), `MarketRules` (market day every 7th in-game day from day 2, the
  days counted at sunrise and saved in `WorldMeta.market`; Nico's fixed stock of village blocks and prices; the cart's
  spot beside Tilly's stall), `StandRules` (a stand beside each universe's helper with its `trader_stock`), `ShopGuide`
  (`core/economy/`). Session section `# --- Trading`: `player_trade_ask / answer / unask / offer / ready / cancel /
  friends` → the host's `host_trade_*` (both have a body, the age rule), `_pt_swap` (`swap_check`, the gold through
  `gold_spend` / `gold_add`, then `move_items`), offers held to the bags every 250 ms (`player_trade_tick`), `peer_left` /
  `peer_away` stop a trade, one RPC back (`_rpc_pt_to`: signals `player_trade_asked`, `_ask_gone`, `_changed`,
  `_ended`, `_note`); `host_trade` sells Nico's things only near a `market_traders` node. `TradeDirector`
  (`world/trade_director.gd`, node `Trading` on every game; the sandbox's section "Owner #37"): MORE → SHOP
  (`ShopMenu`: the nearest full shop's way and distance, SHOW ME = the /find arrow and the shop opens on arrival, Nico
  on market day, the other players with TRADE), the tip once per profile (`hints_seen` "shop_tip"), the host's day count
  and Nico's `MarketCart` (an RPC on change and to an arriving guest), the helper's `TraderStand` (`entities/npcs/`,
  every game from the helper's spot, a worker thread), a tap on another player's name tag (`BlockInteractor.name_tag_tap`
  → `PlayerCard`), the ask (`TradeAskCard`) and the `TradeWindow` (`ui/trade/`). The shop panel opens a stall's own
  things (`ShopPanel.stall_stock`, `title_text()`). Notes and rulings: `docs/devlog/parts/owner-37-trade.md`.
- **The honest shop (owner #35, spec §18):** parents pay for clear value; code in `core/shop/` and
  `ui/shop/`. `ShopCatalog` is **the one table** (products, fixed US$ reference prices, `FREE_UNIVERSES`,
  `FREE_FOREVER`, `PLAY_IDS`): EasyCraft Plus = every ladder universe not in `FREE_UNIVERSES` (meadows,
  desert) — a universe added to `UniverseRegistry.LADDER` is Plus by that rule — plus the Plus set; packs'
  items are avatar items of kind `AvatarCatalog.PACK` naming their product (`"pack": "pack_sky"`), so they
  exist only in their pack and gold never buys them. `Entitlements` (what a purchase opens; the profile's
  `purchases`; `grant` also gives the pack's items to `cosmetics`), `WishList` (the profile's `wishes`: pack
  items and products; the grown-up's rows), `ShopWords` (the child's calm words vs the grown-up's).
  `Billing` is the store adapter (base = no store), `FakeBilling` (tests; debug builds keep a pretend
  history in `user://fake_store.json`), `PlayBilling` (the Godot Google Play Billing plugin's singleton;
  off without it or without `PLAY_IDS`). `ShopService` (made by `Session.shop()`, section "Owner 35: shop";
  restores at start) buys only while the grown-up area's SHOP page shows (`enter_grown_up_area`), records,
  acknowledges, restores (only ever adds), and has the receipt hook `verify_receipt`. UI: `ShopPage`
  (`ui/shop/`, the grown-up area's SHOP tab: PLUS, PACKS, WISH LIST, ALWAYS FREE, RESTORE, a confirm page
  with the price before PAY), the avatar editor's WISH (a heart) on pack items, `UniverseCard.plus_locked`
  ("EasyCraft Plus"), the once-line in `HubPanel` / the SURVIVOR hub, and `Session.shop_travel_refusal(u)`
  in `sandbox.travel_to`. Guard tests: `test_shop_catalog`, `test_entitlements`, `test_wish_list`,
  `test_shop_service`, `test_play_billing`, `test_shop_grown_up`, `test_shop_child_side` (no child screen
  can buy or show a price). Notes and rulings: `docs/devlog/parts/owner-35-shop.md`.
- **World sync by edits (M4 Wave 1 A, spec §17.0; LAN and online):** a guest generates the terrain from
  the seed (`EditedGenerator`: the host's generator, then the host's edits from an `EditOverlay`) and
  gets only what differs from it. `WorldSync` (`net/world_sync.gd`, node `WorldSync` of every
  `WorldService`, `world.sync`) replaces Voxel Tools' `VoxelTerrainMultiplayerSynchronizer`:
  - Host: the VoxelViewer it streams around each guest's player (network peer id, block notifications)
    makes `SyncedTerrain` (`world/synced_terrain.gd`) say when a 16³ chunk comes into that guest's view;
    the guest is then owed the chunk's edit list (`EditLog`, `core/net/`: cells that differ from the
    generator, per chunk, with the generated id for undo; a chunk it doesn't know, e.g. loaded from the
    save, is compared with the generator on worker threads, `ChunkDiffer` (M4 Wave 2 A2): the copy and
    the generation run in `WorkerThreadPool` tasks, at most 2, changes made meanwhile are replayed over
    the result, and its list waits without holding back the others); every later `block_changed` goes
    as a single change. The chunks that came into each guest's view are remembered (also before its
    `client_ready`, and while it is away), because Voxel Tools says so only once per viewer.
    `GuestSync` keeps the order (changes first, lists nearest first, a list made when it is sent),
    `SyncPacer` the pace (a byte budget per guest per frame, nothing while the relay link has a
    backlog), `EditCodec` the packets (deflated when big). Session sends them (`_rpc_world_edits`) and
    the guest's view distance comes back (`_rpc_view_distance`).
  - Guest: `WorldSync.receive` puts edits into the overlay and the loaded chunks (`WorldService.put_block`,
    no `block_changed`); a chunk that was generating meanwhile is checked on `block_loaded`. A chunk the
    guest's terrain has had unloaded (`block_unloaded`) for `WorldSync.FORGET_AFTER_MS` (10 s) leaves the
    overlay (`EditOverlay.forget`), and the host sends its list again when Voxel Tools says the chunk came
    into the guest's view again (`GuestSync.forget`; the M4 review's I). The wait covers the host's copy of
    the guest's player lagging: a chunk out of the guest's view for a moment may never leave the host's.
- **Relay link (M4 Wave 1 A):** `RelayBridge` queues every message (`RelayQueue`) and hands the WebSocket
  only what fits, checking each send (a refused one waits, nothing is lost or reordered); packets of one
  frame for the same target go as one `RelayBatch` message; a packet for the only other player goes
  without its presence (the M4 review's H: a join first names the players every waiting "everyone else" message was
  made for, `RelayQueue.retarget_everyone`, since the addon greets the newcomer outside the queue). `SyncPace` (applied by Session to every `MultiplayerSynchronizer` entering the
  tree): players sync 20 times a second, everything else 10, and in a networked game creatures sync only
  what changed. A guest whose link drops (socket closed, or nothing from the host for 8 s) rejoins the
  same match within 30 s (`RejoinRules`, Session section "M4 A"): its scene reloads under "The internet
  went away. Trying again…" (`NetOverlay`, `ui/net/`), `RelayBridge` gives it back its peer id, and
  the host kept its player meanwhile (`Session.peer_away` / `peer_back`, then `peer_left`). Every network
  problem reaches the player as a `NetWords` code with kind words. Notes: `docs/devlog/parts/m4-a.md`.
  Before a rejoin reloads the scene, the old world stops streaming (`WorldService.stop_viewers`, then
  `drain`: freeing a streaming world waited 6-13 s for Voxel Tools' queue), and no try starts before the
  new scene is there (M4 Wave 2 A2, `docs/devlog/parts/m4-a2.md`).
- **Online chat and co-op (M4 Wave 2, Agent E):** friends' DMs and a team room per online match on
  Nakama channels (`OnlineBackend.join_chat` / `send_chat` / `chat_history`, `OnlineService` section
  "M4 E": `open_dm`, `open_team`, `send_text` / `send_phrase` / `send_emote`, `report_message`), pure rules
  in `OnlineChatRules` (the wheel's phrases, chat level, careful reading, 13+ history for 30 days). The
  quick-chat wheel (`QuickChatWheel`, pictures by `ChatPictures`) is the only way under-13 players chat;
  the in-game `ChatPanel` talks in the team room in an online match (`use_team_chat`, from the
  sandbox's `_setup_team_chat` with `Session.online_match_id()`), keeps the host's relay chat on LAN,
  and opens MUTE / REPORT from a line; TALK on a friend's row opens `DmPanel`. The M4 review's B (module 0.2.11):
  online, no relay stand-in for the team room: when it can't open, the chat rests ("Chat is resting for now. Quick
  phrases still work!", `OnlineChatRules` `chat_resting`), typed words wait, the wheel's phrases go through the host,
  and the room is tried again when the chat opens (`_open_room`, `_retry_room`); an online host registers each guest
  from the server's `match_players` (`MatchRoster`, Session section "M4 Task 10 review B": under 13 and unnamed until
  it answers, "Player" when it can't say), its relay passes quick phrases only and nothing to or from a player whose
  grown-up switched chat off (`_chat_levels`). Owner #49 (section "Owner
  49" of `ChatPanel`): the open chat is the HUD's last child, the history shows the newest lines that fit
  above the phone keyboard (`keyboard_height`, a Callable tests set) or left of the wheel, each on a dark
  backing; `UiKit.add_script_fallbacks` gives the default font the device's Georgian font. The server keeps history
  only for a DM between two 13+ players at the text level (module 0.2.1). Co-op: `ReviveRules` +
  `KnockoutDirector` section "M4 E" (wait for help with a teammate near, HELP UP held 3 s helps them up
  on the spot, GET UP; HUD's `help_button` / `get_up_button` / `ReviveRing`), waves sized by the team
  (`WaveRules.size(n, gentle, team)`, `WaveDirector.team_size`), bot friends in the seats players leave
  online (`BotRules.seats_for_bots`, `BotDirector.seats` / `fit_seats`). Notes and rulings:
  `docs/devlog/parts/m4-e.md`. Timing the chat against a server:
  `godot --headless --path . --script res://tools/measure_online_chat.gd -- --online-server=<address>`.
- **Smooth remote bodies (M4 Wave 2 A2):** Session's `RemoteSmoother` (`net/remote_smoother.gd`) follows
  every `MultiplayerSynchronizer` that syncs its body's `position` (players, animals, monsters, the
  Golem, buddies, bot friends). On the game that receives a sync (`synchronized` / `delta_synchronized`
  fire only there), the synced place and turn go into the body's `MotionBuffer` (`core/net/`, a fixed
  ring of 8) and the body is put back where it is shown; every frame it is shown one sync interval and
  50 ms behind its newest sync (`SyncPace.smoothing_delay`: 100 ms players, 150 ms creatures), between
  two syncs. Only the vertical turn is smoothed (a player's is its `Avatar`'s). A jump over 8 m snaps;
  code on that game moving the body itself wins. The game that simulates a body never receives its
  syncs, so nothing changes there. The host sees its guests' players up to 100 ms late too.
- **Weapons (M1b Task 11):** `Session.request_attack` → the host checks the weapon, the aim and the
  cooldown per player → `CombatDirector` (`world/combat_director.gd`, node `Combat` in the sandbox on
  every peer) resolves it with the host's own positions: melee hits within reach, host-checked arrows
  and boomerangs (every peer flies them from the same spawn data). Practice dummies, monsters (M2) and
  animals (owner feedback #26: `Animal.take_hit`, health by kind in `AnimalRules.HEALTH`; pets and golden
  animals are only pushed; a defeated one puffs away through `CombatDirector._rpc_animal_puff`, drops into
  the defeater's bag in Survivor, and `animal_defeated` tells the `AnimalDirector`, which refills its spot
  after `AnimalRules.REFILL_TIME`) take damage; players get a knockback RPC to their own game, buddies cheer.
  `apply_hit`'s last argument is the attacker's peer. With no weapon the attack is `WeaponRules.FISTS` (−1,
  not an item; `WeaponUser.ready_weapon`, owner feedback #29). Tool powers
  are plain block batches (`Session.request_set_blocks`). Practice targets are spawned by the host and
  saved in `WorldMeta.targets`. The held item hangs under the avatar's `hand()` (`Player.held_item` is synced).
- **HUD layout (M2 Task 17):** every HUD spot is in one table, `HudLayout.SPOTS` (`ui/hud/hud_layout.gd`:
  anchor, offset and size in the 1280 × 720 design space). Buttons are `TouchButton`s with a `symbol` (a picture drawn in code by
  `HudIcons`, no textures or materials) and their word under it: JUMP 225, ATTACK 200, every other
  button ≥ 135 (the hotbar's 62 px slots excepted). What a child uses now and then lives in the MORE
  panel (`MorePanel`: EMOTE, PHOTO, CAM, SIZE, MIRROR, UNDO, LAB; the sandbox adds SHARE (M4 I), MAP (owner #45b, in
  worlds with places), QUESTS (owner #45a) and SHOP (owner #37, Survivor)); add such a button with
  `hud.more.add(button)`, never as a new always-visible button. The guard is
  `tests/integration/test_hud_layout.gd` (2400 × 1080 and a 16:9 phone, both modes, awake and asleep:
  sizes, pictures, no overlaps). Pictures of the HUD without the emulator: `tools/hud_shots.gd` (§4).
  Notes and rulings: `docs/devlog/parts/m2-task-17-hud.md`.
- **Accessibility (M5 Task 1, spec §15.1a):** the table is shown through `HudLayout.configure_from(profile, screen)`
  (static state): BUTTON SIZE NORMAL / BIG ×1.1 / BIGGER ×1.2 grows the thumb controls and uses `BIG_SPOTS` /
  `BIGGER_SPOTS` / `_MIDDLE`; LEFT HAND mirrors every spot; moved JUMP / ATTACK / CROUCH / stick
  (`ProfileData.hud_moves`, per size, the right hand's frame) stay only where `HudLayout.fits` (nothing that may show
  with them, `APART`, is covered; inside the screen and the safe area). Place HUD controls with `HudLayout.place` and
  read spots with `HudLayout.rect` / `spot` (not `SPOTS[...]`), so every size and hand is right; a placed control keeps
  its spot in meta and `Hud.relayout()` places it again when the settings change. `HudLayout.clashes(screen)` lists
  overlaps (`test_hud_layout_config.gd` wants none at every size × hand × screen); a new spot goes into all three
  sizes' checks. MOVE BUTTONS is `HudEditor`; SETTINGS' third page BUTTONS & TEXT. **TEXT SIZE:** give a word a
  child reads while playing `TextSize.mark(label, normal_px)` instead of a font-size override, and check its box still
  fits at BIG (the tutorial's step card sets its picture and dots aside at BIG: `TutorialCard.fit_text_size`). **Sound captions:**
  add a sound to `CaptionRules.SOUNDS` (its kind's words and picture in `KINDS`). **Reduce motion:** particle bursts
  go through `Fx.burst` / `Fx.calm` (pooled ones call `calm` before each restart). Notes:
  `docs/devlog/parts/m5-task-1.md`.
- **Physics Lab (M3 Task 6):** the HUD's LAB button (Sandbox, touch; L on desktop; in the MORE panel since M2 Task 17) cycles
  `Player.lab_mode` (`LabRules`: Normal, Moon, Zero-G, Fly, Ghost, Slow motion). A lab mode sits on top
  of `physics_mode` (Moon and Slow walk, Zero-G floats as FLY), and the WALK/FLY/GHOST switch sets the
  plain lab mode back (`_follow_physics_mode` at the end of `set_physics_mode`). The player's physics
  step runs on the body's own time (`LabRules.body_delta`; slow motion scales the velocity around
  `move_and_slide`), so the world's time is never slowed. `lab_mode` is synced like `physics_mode` and
  saved in `WorldMeta.lab_mode`. Jump and speed pads (`PadRules`, one per body) fire under players (their
  own game) and animals (the host); the boing and puff go to the other games by an RPC on the body
  (`_rpc_pad_fx`). Notes and rulings: `docs/devlog/parts/m3-task-6.md`.
- **Photo mode (M3 Task 16):** `PhotoMode` (`ui/photo/`) sits in the sandbox's CanvasLayer between the
  HUD and the pause menu, `PROCESS_MODE_ALWAYS`. The HUD's PHOTO button (in MORE) or P opens it: the HUD hides,
  its own `Camera3D` becomes current and follows `PhotoOrbit` (`core/photo/`, pure: orbit/zoom/pan
  limits, never through or inside a block). Filters are one `canvas_item` screen-texture shader on one
  material (`PhotoFilters`); frames are UI draw calls (`PhotoFrames`). Photos go to `Pictures/EasyCraft`
  on Android (MediaStore via Godot's FileAccess) or `user://photos` (`PhotoFiles`); SHARE uses
  `JavaClassWrapper` + Godot's FileProvider (`PhotoShare`) and shows only where the grown-up's photo sharing switch
  allows it (M5 F1: `PhotoMode.share_allowed`, read at every open; tests set it and `sharer`, so no test opens a real
  share sheet or folder). Solo pauses the world while it is open;
  LAN never does. Notes and rulings: `docs/devlog/parts/m3-task-16.md`.
- **Tiers, spear, mace, shields, potions (M2 Task 6):** a tier item is its kind's (`WeaponRules.base_of`)
  with damage and dig power × 1/1.5/2/3/4.5 (`tier_of`); every `== ItemIds.SWORD`-style check uses
  `base_of`. Held models: one cached mesh per item (the kind's plus 1–5 bands) and one cached material per
  tier (`WeaponModels.tier_material`, rarity tint, same shader). The spear's throw is a `ThrownSpear`
  projectile (host-checked like arrows; its thrower walks up to take it back). Shields are passive:
  `Session.hurt_player` asks `shielded_amount` first. Potions: a tap on the hotbar slot →
  `Session.request_drink` → every game runs `Player.potions` (`PotionRules.Effects`); stealth reads
  `Player.is_invisible()`. Rarity colours: `ItemRarity`.
- **Bot friends (M2 Task 15):** up to 3 host-simulated companions (`entities/bots/bot_friend.gd`,
  rules in `core/rules/bot_rules.gd`), added and removed in the pause menu's FRIENDS row
  (`ui/menus/friends_panel.gd`) through the host's `BotDirector` (`world/bot_director.gd`), replicated by
  the sandbox's `BotSpawner` like animals and saved in `WorldMeta.bots`. They are not players: groups
  `bots` (up, monsters target them: `hurt(n, from)`) and `bot_friends` (all, for team size). Their swings
  go through `CombatDirector.bot_melee` (monsters only), their builds through `Session.bot_set_blocks`
  (empty cells only, no undo step), their lines through `Session.bot_say` (chat kind `&"bot"`,
  "Pip (bot)"). Contract for monsters, the boss and secrets: `docs/devlog/parts/m2-task-15.md`.
- **Talking to bot friends (owner feedback #38, spec §12.14a):** pure code in `core/bots/`: `BotIntents`
  (the child's words → an intent, English only (owner #52): cleaning, a word list with
  typo fixing, names, a scored matcher; its phrase table is `tests/unit/test_bot_intents.gd`), `BotAnswers`
  (every answer, in English, and answers from the game: directions from where the child looks, hearts, the
  day clock), `BotTalk` (who hears: only the speaker's own friends — `BotFriend.leader_peer` — near, named or
  called; who answers; who acts), `BotAsks` (requests remembered, saved in the friend's mind as `a`). The chat
  bar and the quick-chat wheel (`ChatPanel` section "Owner 38"; the wheel's BOTS page, `BotTalkWheel`) call
  `Session.request_bot_talk` (section "Owner 38: bot chat": the host's rate limit and chat filter) →
  `BotDirector.hear` (section "Owner 38") → the friends' orders (`BotFriend` section "Owner 38": the talk
  behaviours `STAY`, `GUIDE`, `HIDE`, `DANCE` of `BotRules`, closer following, a wider guard circle, requested
  builds placed 5 blocks at a time) and `talk_reply` (never held back by the 20 s gap). Add a word: a row in
  `BotIntents.EN_WORDS` / `KA_WORDS` and a sentence in the test's `TABLE`. Notes and rulings:
  `docs/devlog/parts/owner-38-bot-chat.md`.
- **Avatar looks, emotes, celebrations (M3 Task 9):** pure rules in `core/avatar/`: `AvatarCatalog`
  (every item: free, a fixed Survivor-gold price, or earned by `EARN_*` events and codes; never random),
  `AvatarLook` (the look, synced as `Player.look_code`), `AvatarUnlocks` (the one price/ownership rule),
  `EmotePoses`. The profile keeps `avatar` and `cosmetics` (owned ids). The editor (`ui/avatar/`,
  main menu and pause menu) buys through `AvatarUnlocks.buy` outside a world or in Sandbox, and through
  `Session.request_cosmetic_buy` (host `gold_spend`) in a Survivor world. Emotes: the HUD's emote wheel
  → `Player.play_emote` → `Session.request_emote` (host cooldown) → every other game
  (`Session.emote_played`). `Session.celebrate_all()` (host) makes every body in every game celebrate.
  Notes and rulings: `docs/devlog/parts/m3-task-9.md`.
- **Shorts Theater (M3 Task 17):** `TheaterDirector` (`entities/theater/`, node `Theater` in the
  sandbox) stands the `TheaterBuilding` (a node, not voxels: one shared mesh, one static body) on its
  site, about 30 blocks from the spawn (saved in `WorldMeta.theater`; a LAN guest works it out from
  the seed), and opens `TheaterPanel` (`ui/theater/`) while the local player is in the room. The
  panel is per device and nothing about it goes over the network. On Android the player is the
  `EasyCraftWebView` plugin (§4), in a browser the page's own block (`TheaterWebPlayer`, owner #89);
  elsewhere `TheaterStill` draws a placeholder. The panel holds the game's sound (the master bus) while a
  video is on the screen. No rewards for watching.
- **Creature minds (M2 Task 18, owner feedback #24, spec §12.17):** pure code in `core/mind/`. A `Mind`
  (senses → the species' `TinyNet`, 16 → 12 → actions → plus a personality offset from the id → a gentle
  softmax pick among the actions possible now; drives, a `MindMemory` of ≤ 8 players by name and ≤ 8 places;
  rewards teach the net's last layer only, clamped) sits in every animal (not fish or golden ones) and bot
  friend, host only. Species tables: `core/mind/species/` (`AnimalSpecies`, `BotSpecies` + `BotStyle`).
  Wild animals share one net per species per world (`MindBook.current`, saved in `WorldMeta.minds`, ≤ 2 KB: owner #41, the monsters' tables first, then the ones that learned most);
  pets and friends save their minds in `WorldMeta.pets` / `bots` (`mind`). Thought bubbles
  (`entities/mind/`: one shared quad, one cached material per picture) follow a synced `thought` property.
  A tap holding grass or leaves feeds an animal (`Session.mind_request_treat`, section "M2 Task 18").
  `Animal.time_source` is the sky's clock. **Monsters (part 2):** while a monster chases what it sees, its
  `mind` (`MonsterSpecies`, one table per kind per world in `MindBook`, capped by the universe) picks a fair,
  signalled tactic — straight, zigzag, go round, wait by cover, back off when hurt, call a friend — that only
  steers (speed, sight, hits and hearts stay §12.4/§12.5's); its stealth state is `awareness` (it was `mind`
  before). `MonsterMinds.current` holds the guards (Cozy: no learning and plain tactics; Sandbox: 0.3 ×
  learning; a child's knock-outs ease them off, fading in minutes) and the one-time hints (toasts, saved in
  `WorldMeta.mind_hints`). Golden slimes never think. Details: `docs/devlog/parts/m2-task-18.md`.
- **The Sandstorm Desert (universe 2, M3 Task 2):** its descriptor `world/universes/desert.gd` (M3 Task 5's
  universe interface: name, display_name, index, generator_shape, generator, monster_kinds, boss_kind, music,
  sky, trader_stock; plus secret_rules, secret_words, weather, traps), found by `UniverseRegistry`.
  `WorldService.setup(..., universe)` and `WorldService.descriptor()` give the world
  `DesertShape` / `DesertGenerator` (dunes, mesas, oases, plants) and `DesertSecretRules` (buried treasure,
  mesa rooms behind fake sandstone, pyramids with arrow slits, a sand pit and the plate puzzle, floating
  mesas, geodes). The sandbox's section "M3 Task 2" hands the directors the universe's monsters
  (`MonsterDirector.kinds`, `WaveDirector.kinds`: mummies and scorpions), its boss
  (`BossDirector.boss_kind`: the `SandSerpent`, a `StoneGolem` to the director, rules in `SerpentRules`), its
  secrets and their words, and adds `SandstormDirector` (node `Sandstorm`: the host's storm clock;
  `StealthDirector.weather` halves the light outdoors; `Ambience.storm` closes the fog in to half and tints
  the screen) and `DesertTraps` (node `DesertTraps`: cacti push, arrow slits click then shoot). Mummies are
  tanks that unwrap into two halves (`Monster.half`); scorpions spit a glob that leads a runner a little
  (`SpitGlob`, `MonsterRules.spit_*`). Details and rulings: `docs/devlog/parts/m3-task-2.md`.
- **The Candy Kingdom (universe 4, M3 Task 4):** `world/universes/candy.gd` (the desert's fields plus `weather`
  `&"sprinkles"`, `liquid` `&"chocolate"`, `classical`), `CandyShape` / `CandyGenerator` (frosting plains,
  chocolate rivers, gumdrop hills, tiered cake mountains, candy-cane forests; a chunk's hills and cakes looked up once:
  `features_in` + `column_among`), `CandySecretRules` (sprinkle X, rooms in cakes behind fake chocolate,
  gingerbread houses, floating cakes, geodes), blocks 176-191 on page 8 (`CandyBlocks`, `BlockIds.CANDY_GROUND`).
  Monsters (`MonsterRules.CANDY_KINDS`): the gummy bear (a jumper that bounces off walls, `MonsterRules.wall_bounce`)
  and the candy sneaker (the host measures its light: `MonsterDirector.light_at` = `StealthDirector.light_at`;
  `Monster.dark` synced; every screen shows only a shimmer within 6 blocks, and always a shimmer and a jingle while it
  winds up). Boss: the `CakeMonster` (a `StoneGolem` to the director; rules in `CakeRules`: tiers fall off at 2/3 and
  1/3, each tier its own attack). Universe 4 is the last: its boss portal leads to the hub
  (`UniverseRules.HUB`, `boss_portal_target`), the win is a grand celebration, and Survivor earns the cosmic outfit
  (`Session.boss_earn`). Its water is chocolate (`BlockLibrary.set_liquid`, one uniform on the shared water shader;
  `Ambience.chocolate`), gumdrops bounce a landing player (`CandyRules.gumdrop_bounce`, `Player._gumdrop_bounce`),
  sprinkles fall at night (`CandySprinkles`, node `Sprinkles`, one CPUParticles3D per screen). Details and rulings:
  `docs/devlog/parts/m3-task-4.md`.
- **Building tools (M3 Task 8, spec §14.5):** the palette's BUILD tab (tab 6: TOOLS row LINE, FILL, COPY, REWIND; 16
  paint buckets; Survivor shows the paints and REWIND). Pure rules in `core/building/`: `PaintRules` (tints, the painted
  blocks 240–255 on page 12, which blocks are paintable, Survivor's precious blocks), `PowerTools` (LINE ≤ 64 as a
  face-to-face staircase, FILL ≤ 4,096, COPY ≤ 16 a side, copies in stamp coordinates that turn with the child, TURN),
  `RewindLog` (≤ 5,000 edits within 32 blocks, 5 bytes each, deflated in `WorldMeta.rewind`, replay ≤ 20 s), and
  `core/avatar/wear_rules.gd` (`WearRules`: ≤ 5 × 5 × 5 builds as BuildCodec text in `AvatarLook.builds`; look code ≤ 2,048).
  In the hand: `BuildToolUser` (`entities/player/`, the BlockInteractor's `tools`, like `gadgets`): taps, the block held
  last (`material`), the first corner's glow (M4 I's `BuildOutline`), the copy, Rewind's recorder (the host's undo steps
  and the undos asked for; `BlockInteractor.undoing`), the wand's `offer_wear`. The host: `Session.request_build_tool(kind,
  changes)` (section "M3 Task 8": PAINT in both modes, LINE/FILL/PASTE in Sandbox, UNDO through the host's per-player
  tool log of 20 steps; one undo step each, `tool_undo_step_received`, pushed with `via: &"tool"`). The host writes a
  request `TOOL_CHUNK` (16) cells at a time, each physics frame until `TOOL_FRAME_MS` (8 ms) have gone (`_tool_tick`: at
  least one chunk; an edit of at most `TOOL_AT_ONCE` (64) cells at once), checking each LINE / FILL / PASTE cell as its
  chunk is written (air or water, no body, within 48 blocks) and each paint or undo cell against what it held (a cell
  someone changed meanwhile stays); the child's game sends every cell and the host skips the taken ones. `WorldService.blocks_at` / `set_blocks` read and write a box with one copy / one copy and
  one paste (every changed cell still emits `block_changed`). Screens (`ui/building/`, the sandbox's section "M3 Task
  8"): `BuildToolBar` (top centre, only with LINE, FILL or COPY in the hand), `RewindView` + `RewindPreview` (its own
  World3D in a SubViewport, one MultiMesh per block id with `WearMesh.cube`, the camera on `PhotoOrbit`; pauses solo,
  stops drawing the game's 3D and hides the HUD while open; `export_video()` is M5's hook), `WearCard` (WAKE UP, HAT, BACKPACK, WINGS).
  `WearMesh` bakes a wearable into one cached mesh in its blocks' own library materials; `AvatarModel._dress_builds`
  wears it (a hat on the head, a backpack and wings on the back). Chat: `/fill`, `/copy`. Notes and rulings:
  `docs/devlog/parts/m3-task-8.md`.
- **The Sky Dragon (owner feedback #39, the Dragon Realm's boss, spec §14.2a):** `BossRules.SKY_DRAGON`
  (`&"sky_dragon"`; `/summon skydragon` through `ChatCommands.BOSS_KINDS`), rules in `SkyDragonRules` (pure: health,
  the schedule RISE → CIRCLE → DIVE_WARN → DIVE → GLIDE → CLIMB, or LAND → REST → TAKE_OFF after every second dive;
  the dive line, height, hits and push; `keep_in` the arena circle; `column_floor` / `floor_under_body` /
  `smooth_floors` for the ground under it; towers by thirds, their spots, heal and hits). `SkyDragon`
  (`entities/monsters/`) is a `StoneGolem` to the BossDirector (which passes it the Totem as `center`); the host moves
  it (no physics but a tap box), reads the ground ten times a second through a 10 s cell memory (`_read`), and the
  ground along a dive's line two samples a step during the wind-up. Synced on change: `phase`, `hp`, `dive_from`,
  `dive_to`, `tower_spots`, `tower_hits`; every screen draws the dive line and builds and breaks the towers from them
  (`_rpc_towers` only for the line and the hum). `SkyDragonTower` (its children, top_level `StaticBody3D`s in the
  group "monsters": every weapon hits them; the host's dragon counts hits). Looks: `SkyDragonModels` (shared meshes,
  the animals' material and the Golem's glow material). The bar's face (`BossBar._draw_dragon_face`), the win's bits
  and sound (`BossDirector._win_look`); `_rpc_won` carries whether a portal opened (Monster Wave's raid boss: none, so
  its words promise none). Notes and rulings: `docs/devlog/parts/owner-39-sky-dragon.md`.
- **More animals (owner feedback #41, spec §14.19):** each universe's descriptor names its animals (`animals`;
  `UniverseRegistry.animals(u)`, Green Meadows' when none) and `AnimalDirector.kinds` passes them to
  `AnimalRules.spawns_for_cell(shape, cell, kinds)`. Where a kind lives: `AnimalHomes` (biomes, weights; Green
  Meadows' new kinds take half the herds through `pack_at`, a seeded roll of its own; other universes `pick_at`). Food:
  `AnimalFood`. Special moves are `AnimalRules` row keys read by `Animal` (`swims`, `climb`, `shy`, `curls`, `slides`,
  `trees`, `nocturnal`, `lays`, `walk_hop`). Box models: `AnimalBoxes` (+ `BlockyAnimal.dressed_mesh_for`: a saddle or
  packs baked in). Riding a saddled horse or camel: M3 Task 20a's RIDE and `RideDirector` (section "owner #41"),
  `AnimalRideRules`, RideRules kinds GALLOP and TREK, `Player.riding_animal`; the host moves it (`Animal._ride_step`).
  The donkey's chest: `DonkeyChest` (9 × 99, flat), the pet card's CHEST page, PetDirector `on_chest_put/take`. Turtle
  eggs: `AnimalDirector._turtle_tick` (host), `Animal.egg_at` (synced). Bees and butterflies: `MeadowInsects` (descriptor
  field `insects`). **Add an animal kind:** an `AnimalRules.SPECIES` row (+ `HEALTH`, `DROPS`), an `AnimalHomes.HOMES`
  row, an `AnimalFood.FOOD` row, `AnimalSpecies.TRAITS`, boxes in `AnimalBoxes` (and its name in BlockyAnimal's match),
  voices (`Audio.SOUNDS`, `VoiceRules._HURT`, a measured `CALL_GAIN_DB` line), its universe's `animals` list;
  `test_animal_pack.gd` lists what is missing. Notes: `docs/devlog/parts/owner-41-animals.md`.
- **Pets with perks (M3 Task 11, spec §14.7):** pure rules in `core/rules/`: `PetRules` (the kinds table `KINDS`
  — dog, cat, fox, parrot, Pip: how each becomes a pet, perks, favourite treat; the happiness heart; names: a list
  for everyone, a typed name through `UsernameRules` for 13+ only; 8 collars; `give_pip(profile)`), `PetPerks`
  (a perk works only for a tamed pet within 16 blocks of its child: glow, coins, bark, point) and `PetEcho` (the
  parrot's words: only this device's own player's lines, never sent). Treats are items 430–434 (the palette's PETS
  tab, Tilly's POTIONS shelf). `PetDirector` (`world/pet_director.gd`, node `Pets` on every game): the host decides
  treats, pats, names, collars (Session section "M3 Task 11"), the dog's bark (an RPC on the animal: sound and the
  monsters' "!") and coins (it sets a coin's `collector`), the parrot's pointing (an RPC), the heart falling while
  the child plays, and each child's Pip; every game has **one** shared light (`PetGlow`) on the glowing pet nearest
  its player in the dark, the parrot's bubble and the profile's Pip record. The animal syncs `collar` and
  `happiness` (1/20 steps) on change. A tap on your own pet pats it and opens its card (`ui/pets/PetPanel`: SIT,
  NAME, COLLAR). **Pip lives in the profile** (`ProfileData.pip`), comes into every world, is never saved in
  `WorldMeta.pets`. Add a pet kind: a `PetRules.KINDS` row, an `AnimalRules.SPECIES` body, `BlockyAnimal` boxes and
  `COLLAR`, `AnimalSpecies.TRAITS`. Notes and rulings: `docs/devlog/parts/m3-task-11.md`.
- **The tutorial with Pip (M3 Task 15, spec §14.9):** pure rules in `core/tutorial/`: `TutorialRules` (the steps in
  order with their line ids, pictures and words in `LINES`; where it plays: a solo Survivor CLASSIC world of universes
  1–4; the offer, SKIP never again, stop and go on, SETTINGS' replay, the reward once), `TutorialData`
  (`ProfileData.tutorial`, merged by the backup), `TutorialCourse` ("Pip's playground": a 24 × 5 pad near the spawn —
  the hole to jump, the hole to bridge, the wall, two bushes, Pip's Workbench — its site from the terrain rules, zones
  for the jump), `TutorialProps` (the cells it changes, recorded as [x, y, z, held, placed]; putting them back and the
  child's blocks back to the bag; the natural-ground check; `touches` the child), `TutorialChecks` (each step's check).
  `TutorialDirector` (`world/tutorial_director.gd`, node `Tutorial`, this game only; the sandbox's section "M3 Task
  15"): the offer (`ui/tutorial/TutorialOffer`), the site, the natural check and the plan on a worker thread (over one
  `WorldService.box_reader` copy of the course's box), the playground into the world 16 cells a tick (the record in
  `WorldMeta.tutorial_props`, the meta saved first; putting back the same way; a crash's record goes back at the next
  start of the world), a visiting Pip (`PetDirector.on_pip`), the step card (`TutorialCard`: picture, words, dots, speaker, X),
  one `BuildOutline` on the step's cells, the practice slime (`Monster.practice`: never hurts, never beaten, no
  mind), the checks at 10 Hz, the reward (`Session.gold_add` 500, `AvatarUnlocks.earn(EARN_TUTORIAL)`,
  `PetRules.give_pip`). It holds owner #37's first-time tip (`TradeDirector.hold_tip`) and shows it for the Tilly
  step (`TradeDirector.show_tip`). SETTINGS → HELP → PIP'S LESSONS sets `ProfileData.tutorial.replay`. **A new step**
  is a `TutorialRules.STEPS` row + a `LINES` line, a check in `TutorialDirector._check` (pure in `TutorialChecks`),
  and, if it needs a place, cells in `TutorialCourse`/`TutorialProps`. Notes and rulings: `docs/devlog/parts/m3-task-15.md`.
- **Levels, the adventure board, badges, presents (M3 Task 12, spec §14.11):** one entry point,
  `Progress.event(kind, amount := 1)` (autoload `autoloads/progress.gd`): kinds are `LevelRules` families
  (`monster_defeated`, `secret_found`, `block_placed`, `wave_won`, `boss_beaten`, `buddy_woken`,
  `animal_tamed`, `photo_taken`, `race_finished`, `friend_played`, `area_explored`) or `family/detail`
  (`animal_tamed/dog`). It counts **only while a world is played** (`Progress.begin/end`, called by the
  sandbox's `ProgressDirector`, `world/progress_director.gd`), into the profile's `ProgressData`
  (`core/progress/`, pure: `LevelRules` XP/curve/titles, `BoardRules` the three picture goals,
  `AchievementRules` 24 badges, `PresentRules` the pet's presents; no dates anywhere). Host-decided events
  go to the player's own game with `Session.progress_tell(peer, kind)` / `progress_near(pos, kind)` /
  `progress_everyone(kind)` (Session section "M3 Task 12"; blocks placed are counted from the host's undo
  steps); Survivor gold for a goal and a present's gift go through the host (`progress_host_goal_gold`,
  `progress_host_present`). Other players wear a `NameTag` (name + "Lv 5 Master Builder" from the synced
  `Player.progress_tag`). UI: the pause menu's BOARD (`ui/progress/`: `AdventureBoard`, `TrophyRoom`,
  pictures in `ProgressPictures`). **A new feature that should count** calls `Progress.event` on the
  player's own game (or `Session.progress_tell` on the host). Notes and rulings:
  `docs/devlog/parts/m3-task-12.md`.
- **Words and voices (M3 Task 21a, spec §14.20):** notes and rulings `docs/devlog/parts/m3-task-21a.md`.
  - Words: English only (owner #52). `Lang` (`core/words/lang.gd`: `apply` sets English, `t`, `plural_s`,
    `article`); no translation is registered and `settings.language` is dropped when a profile loads.
  - Read-aloud: `ReadAloud` (`ui/progress/read_aloud.gd`: `speak` for a speaker button, `auto` for "Read to me",
    `with_speaker(title, panel)` puts a speaker beside a title, `words_of(panel)` reads what shows, a `Voice` that
    tests replace) with `SpeechQueue` (`core/words/`: one at a time, never twice in a row or late, other players'
    names read as "a friend"). The chat never calls it. Hooks: `Hud.toast`, `SurpriseBanner`, `PictureHint`,
    `RiddlePanel`, the menu's `_show` (a screen's title), the stay-safe card.
  - Babble: `BabbleRules` (`core/rules/`: pitch by kind, size and name, syllables by length, the budget) and
    `BabbleVoices` (`world/`, node `Babble` in the sandbox on every game; `BabbleVoices.say(node, kind, size,
    text, answer, who)`; a bot friend's `Session.chat_received` line babbles by itself). Audio's `&"babble"` takes;
    `AnimalChorus` rests while it plays.
  - Simple controls: `SimpleControls` (`core/rules/`: `auto_jump` (steps, and gaps in Simple), `follow_yaw`,
    `show_attack`, `show_crouch`); `Player.simple_controls()`, `Player._simple_follow`, `CameraRig.since_look`,
    the HUD's `_simple_tick` (monsters within 16 blocks, 4 times a second).
  - SETTINGS: two pages (`SettingsPanel.show_page(GAME / WORDS)`, the second is HELP; `saver` for tests);
    `WelcomeCards` (the controls card, once: `WelcomeCards.due`), routed by the menu's `_welcome`.
- **Quests (owner #45a, spec §14.17):** more families (`item_crafted/<recipe>` from `Session.host_craft`,
  `pet_fed/<species>` from `PetDirector.on_treat`, `buddy_ridden/<fly|drive|sail|walk>` from `RideDirector.host_ride`,
  `race_finished/<medal>`, `boss_beaten/<the world's boss>`, `wave_won/arena`, `quest_step`, `quest_done/<chain>`);
  `Progress.event` also counts per universe (`Progress.universe`, `ProgressData.u_counts`, `count_in(kind, u)`)
  and emits `Progress.counted(kind, amount)`. Board goals may say `modes`, `universe` and `species` (listed only
  once that animal exists). The stories: `QuestRules` (pure: the givers, 9 chains of DO / REACH / GO steps, the
  rewards, a helper's spot from the seed) and `QuestData` (`ProgressData.quests`: the story followed, the
  waiting ones, the ones done, places). `QuestDirector` (`world/quest_director.gd`, node `Quests` on every peer)
  places the universe's giver (`QuestGiver`, `entities/npcs/`; Tilly's Survivor self is her stall), moves the
  story on (events, walking to places and back, a tap on the giver), points the HUD's arrow (a `FindArrow`;
  places are looked up on a worker thread, a guest asks the host), pays Survivor gold through the host once, and
  shares the host's story in co-op (guests' matching events, helpers rewarded). UI: `ui/progress/` `QuestBook`
  (MORE → QUESTS), `QuestCard` (a giver's card), both `QuestOverlay`s (they take touches before the HUD), pictures
  in `QuestPictures`, `ReadAloud` (the system's text-to-speech; `audio/general/text_to_speech` is on). Bot friends
  lead to the story's place first (`BotDirector.quest_near`). **A new story** is a `QuestRules.CHAINS` row (steps
  of kinds something really raises; pictures from `ProgressPictures`). Notes: `docs/devlog/parts/owner-45a-quests.md`.
- **Books and memories (M3 Task 21b, spec §14.24):** the HUD's BOOK opens the Secret Book with a column of tabs
  (`SecretBook` section at the end; pages in `ui/books/`): SECRETS, ANIMALS (`AnimalBookPage`, pictures drawn from each
  kind's own boxes by `AnimalPortrait`), MEMORIES (`MemoryBookPage`), IDEAS (`IdeaCardsPage`), SAVING (`SavingPage`).
  Pure rules in `core/books/`: `WonderData` (`ProfileData.wonder`: Animal Book marks, the saving list, pages rewarded,
  universes explored; kept by the backup merge), `AnimalBookRules` (reads `AnimalRules.SPECIES`: **a new animal kind needs
  no line** — a fact in `FACTS` is welcome), `MemoryRules` + `MemoryBook` (the device's `user://memories/memory_book.json`
  and small photo copies; never in the profile), `IdeaCards`, `SavingRules` (SAVE UP: gold things; owner #35's `WishList`
  stays the grown-up's pack items), `BookPages` (a done page's avatar item, sticker, Hub Tree star, once), `HubTreeRules`,
  `TrophyRules`, `BlockIndex` (a chunk index for any block ids). `BooksDirector` (`world/books_director.gd`, node `Books`
  on every game, the sandbox's section "M3 Task 21b") fills them from `Progress.counted`, level-ups, badges, animals near
  the player (1 Hz), `BlockInteractor.animal_fed` and photos (`PhotoMode.last_png`, a thumbnail on a worker thread); the
  world owner's showcase (badges, tree) goes host → guests (Session section "M3 Task 21b"). In the world: `TrophyShelves`
  (block 217, one cached mesh per shelf content) and `HubTree` (`entities/books/`, beside the stone circle, one cached mesh
  per state). SAVE UP at Tilly's and in the avatar editor; the bar under the gold (`Hud.setup_books`). A new moment is a
  `MemoryRules.MOMENTS` row (an event kind and a ProgressPictures picture). Notes: `docs/devlog/parts/m3-task-21b.md`.
- **Co-op games (M4 Wave 3 H; spec §17.5 "Co-op games"):** hide-and-seek, Storm Run and the team photo after a
  boss, in the host's world (LAN and online alike). Pure rules in `core/games/`: `GameRules` (kinds, keys "p<peer>"
  / "b<bot name>", when a round may start, the stickers), `HideSeekRound` (counting 30 s, seeking 3 min, found joins
  the seekers, hints after 2 min, `can_see`: the monsters' sight within 3 blocks, `in_spot`, the 40-block play
  area), `StormRun` (radius 40 → 8 over 3 min, drifting centre, stars, the gentle push, the best), `TeamPhoto`
  (20 s offer, the line-up and the camera), `BotGamePlans` (bots hide, seek fairly, fetch stars), `GameWords`.
  `GamesDirector` (`world/games/`, node `Games` in the sandbox on every peer, group `games_director`): the host checks
  every request (Session section "M4 H": `games_request_start` / `_stop` / `_find` / `_spot` / `_star` /
  `_photo`), runs the round, steers bot friends through `BotFriend.game_brain` (their `game_pose` is synced:
  crouching or inside a barrel or closet), keeps night monsters away (`monsters_allowed`) and the Totem waiting
  (`WaveDirector.game_on`), gives the sticker (`ProfileData.stickers`) and keeps Storm Run's best
  (`WorldMeta.storm_best`); every game keeps a copy of the round (RPCs on change and every 5 s), shows the ring
  (`GameRing`, `shaders/game_ring.gdshader`) and the stars (`StarPool`, a pool of 10 meshes,
  `shaders/game_star.gdshader`), and moves only its own player (the counting seeker held still, the push back in,
  a seeker's look for hiders from its camera, touching stars, the photo line-up). UI: the GAMES page
  (`ui/games/games_panel.gd`) from the pause menu's FRIENDS panel (host), the HUD's round line (`GameLine`, spot
  `game_line`) and TEAM PHOTO (spot `team_photo`, 20 s after a won boss), the counting screen and end card
  (`GameOverlay`, under the HUD's buttons). A seeker's tap on a barrel, closet or bush looks inside (`GameTaps`,
  `BlockInteractor`). The team photo uses `PhotoMode.take_team_photo(view)`. Notes and rulings:
  `docs/devlog/parts/m4-h.md`.
- **School (owner #68, spec §22; notes `docs/devlog/parts/owner-68-school.md`):** the main menu's SCHOOL (`menu.gd`
  section "Owner #68: School", the script loaded on press) shows `SchoolScreen` (`ui/school/`) in the menu's panel: the
  grade (the child's, or fixed by a grown-up), the map of a subject's units (`UnitStop`), a unit, its lesson cards
  (`SchoolPicture`), a round of 6 (`RoundPlan`, `ExercisePanel` with `ChoiceAnswer`, `NumberAnswerPad`, `OrderAnswer`,
  `BuildBoard`), the round's end (`MasteryRules.after_round`: stars, reviews, 100 Survivor gold once per unit mastered) and
  the grown-ups' page behind the parent gate (`SchoolGrownUpsPage`). Pure rules and generators in `core/school/`, the
  curriculum in `data/school/` (§4 "School"). Progress: `ProfileData.school` (`SchoolData`).
- **Animations (owner #94; notes, rulings and measurements `docs/devlog/parts/animations.md`):**
  - **Moving School pictures:** `SchoolPicture.time` (seconds a moving kind draws; a set redraws once) and `playing`
    (advances it, redrawing at `SchoolPicture.FPS` = 30 while shown). Time 0 is every kind's still picture; a still kind
    never ticks. `SchoolPicture.animates(d)`, `should_play(d, question)` (the School's rule: lesson cards play,
    exercises only with `"animate": true`, never with Reduce motion), `time_of(canvas_item)` (what a kind's drawing
    reads). `SchoolPictureMotion` (`ui/school/school_picture_motion.gd`) says which kinds move (`moves`), holds their
    rules (`gear_spin`, `pulley_spin`, `cam_turn`, `lever_tilt`, `wave_phase`, `circuit_way`, `moon_month`,
    `pendulum_period`, `rocket_state`...), the shared `flow_dots`, and draws the kinds made for motion (`water_cycle`,
    `moon_phases`, `orbit`, `pendulum`, `rocket_stages`). A new moving kind: its motion in its own drawing (read
    `SchoolPicture.time_of(ci)`, time 0 = its still picture), a line in `SchoolPictureMotion.moves`, a sample in
    `test_anim_school_picture.gd` (its draw is measured there; it fails over 2.5 ms).
  - **UI motion:** `UiMotion` (`ui/fx/ui_motion.gd`) is the one helper: `pop_in(control)` for every card and panel
    that shows, `squash_on_press(button)` (every `UiKit.big_button` has it), `fly(host, from, target, count,
    UiFlyers.COIN | STAR)` for gold and stars going to their counter, `burst(host, at, count)`, `glow(control)`,
    `bounce(control)`, `bump(control)`. Tweens only (they run over a paused game); the flying pieces are one pooled
    `UiFlyers` per screen, asleep when nothing flies. Reduce motion calms all of it (`UiMotion.calm()`). **A test that
    measures a panel right after it opens** (its buttons' global rects) calls `UiMotion.settle(panel)` first: mid-pop
    it is drawn smaller.
  - **Characters:** poses in `EmotePoses` have a `head` (nod, turn, tilt; both bodies turn it); `AnimIdle`
    (`entities/player/anim_idle.gd`) is a standing body's idle life (`Player._idle_tick`, every game for every body,
    never sent) and what a child cheers for (`Player.react_happy`: `hooray`, sent like any emote); `AnimGreet`
    (`entities/npcs/anim_greet.gd`) is a helper's hop hello and jump for joy; `AnimLife`
    (`entities/animal/anim_life.gd`) an animal's hop, shake or sniff now and then.
  - **The world's ambient life** (`world/life/`, `LifeRules` holds the rules and the budget): `AmbientLife` (the
    sandbox's `_meadow_local`, where the universe has `insects`) with `Fireflies` (14, one CPUParticles3D) and `Birds`
    (6, one multimesh); `LifeRules.flutter` (leaves and petals from `Fx.break_block`); `Blinker` and `WavingFlag` (the
    Launch Site). Budget: pooled (one system each), shared materials (Fx's, the golem's glow, the Launch Site's: list a
    new maker in `test_shader_warmup_sources.gd`), LOW halves (`Fx.scaled`), off when nobody would see it, nothing
    sent; its cost: `tools/life_bench.gd` (§7).
- **Saves:**
  - `user://profile.json`, plus `user://worlds/<slot>/` holding `world.json` (WorldMeta) and `voxels.sqlite`.
  - `JsonStore.write_atomic`: write a tmp file, read it back to verify, rotate `.bak`, rename. Reads fall
    back to `.bak`.
  - The game saves on pause, close and focus-out, and when the pause menu opens.
- **Physics:** Jolt Physics (`physics/3d/physics_engine="Jolt Physics"`) since owner feedback #9. Godot's
  default engine spent up to 220 ms/frame on big bodies overlapping the voxel terrain mesh.
  `tests/unit/test_project_settings.gd` guards the setting. Buddy collision boxes are capped at a
  1.8-block footprint (`Buddy.MAX_FOOTPRINT`).
  Physics layers (value): 1 world, 2 players, 4 buddies, 8 animals and monsters, 16 practice targets
  and pickup bags (static, mask 0, only tap rays look for them), 64 bot friends (M2 Task 15; mask 1,
  nothing looks for them), 512 secret things (chests, riddle notes, the Wanderer; static, mask 0, tap
  rays only; M2 Task 16). Surprise drops (the Party Piñata, supply balloons; M3 Task 14b) are static bodies
  on 8 with mask 0, so taps aim at them like at monsters.
- **Knock-outs and pickup bags (M2 Task 2):** `KnockoutDirector` (node `Knockout` in the sandbox on
  every peer, with its own bag spawner) acts when the host's own `Health` reaches 0.
  - Survivor (not Cozy): the carried blocks drop into a `PickupBag` (`KnockoutRules`: blocks only;
    the owner's for 5 minutes, then anyone's; bags merge, never lose a block).
  - After 1.6 s the host revives the player, whose own game moves them: home (bed or world spawn) in
    Survivor, on the spot in Sandbox. Protection holds until they say they have arrived, then lasts 3 s.
  - A tap or hold on a bag asks the host (`Session.request_take_bag`: reach, owner, not while down).
  - Bags are saved in `WorldMeta.bags`.
  - The HUD's hearts row (`HeartsBar`) and the fade (`KnockoutOverlay`) follow `Session.player_hurt`.
    The FPS label sits bottom-right.
- **Monsters (M2 Task 4):** `MonsterRules` (pure: stats, spawns, coins, sight), `Monster`
  (`entities/monsters/`: group `monsters`, `take_hit(damage, from, knockback)`, `perceive()` is the
  sight seam), `MonsterDirector` (node `Monsters` on every peer: spawners and effects; the host ticks
  night spawns, the sunrise puff, defeats, coins and `/summon`), `Coin` (`entities/pickups/`). Monsters
  follow the animals' cost rules and never change blocks. Sandbox monsters are gentle (8, levels 1–2,
  no coins) and switch off with MONSTERS: ON / OFF (`WorldMeta.monsters_on`, pause menu, host).
- **The Dragon Realm's monsters (owner feedback #39, spec §14.2a):** `MonsterRules.DRAGON_KINDS` = the shadow bat
  (`SHADOW_BAT`, `&"shadow_bat"`, `/summon shadowbat`: `ChatCommands.MONSTER_WORDS`) and the wisp spirit (`WISP`,
  `/summon wisp`), both `FLYER`s (the ice bat's flight; section "Owner #39" at the end of `monster_rules.gd`,
  `monster.gd` and `monster_models.gd`). The shadow bat swoops after a 1 s signal (wings flare, eyes brighten, a
  squeak), then flies up and away to rest (`shadow_rest_spot`, `SHADOW_REST`). The wisp keeps `WISP_KEEP` from a
  child, signals 1.2 s (it lights up, chimes, its ring grows) and throws a slow straight spark (`spark_*`: 5 m/s, no
  lead) that the host flies step by step (a wall stops it, one built while it flies too) and every game shows as a
  straight `SpitGlob`. Their minds' tactics only move where they fly (`Monster._dragon_aim`). Every flyer over the
  void (nothing within `BAT_LOOK_DOWN` below: `MonsterRules.over_void`) keeps its height, turns at an island's edge
  and flies back to the last ground (`_home`); below `VOID_Y` over nothing it is `lost` and the MonsterDirector puffs
  it away. Notes: `docs/devlog/parts/owner-39-dragon-monsters.md`.
- **Monster Totem and waves (M2 Task 9):** `WaveRules` (`core/rules/`, pure: wave sizes and levels, the
  outcome, rewards, try again / easier, the boss offer, the Totem's spot and taps), `Totem`
  (`entities/interactables/`: three shared meshes, one shared glow material, group `totems`), `WaveDirector`
  (node `Waves` on every peer, with the TotemSpawner and the state/effect RPCs; the host places the Totem
  from `WorldMeta.totem_*`, checks `Session.wave_request_start`, brings wave monsters through the
  MonsterDirector and pays through `Session.gold_add`). Wave monsters carry `Monster.wave` and `goal` (the
  Totem): not wild, never sent away for distance, a split slime's small ones join the wave. HUD:
  `WaveLine` (top-centre above the toasts) and `TotemPanel` (centred), both following
  `WaveDirector.state_changed`. Boss hook for Task 10: `boss_offered`, `boss_requested`,
  `set_boss_running` (`sandbox.waves()`). Notes: `docs/devlog/parts/m2-task-9.md`.
- **Stealth (M2 Task 5):** `StealthRules` (`core/rules/`, pure: visibility = light × crouch, 0 when
  hidden or invisible; sight 16 × visibility in a 120° view with a grid ray; noise radii; the monster's
  `Mind`: wander → ? → ! → search 6 s; hiding spots; the HUD's eye and bars; the danger arrow).
  `Monster` perceives players **and** bot friends at every look (`perceive()`, `visibility_of`,
  `noise_of`), keeps its `mind`, attacks only what it sees, and syncs `alert` (? / !) and `alert_peer`
  on change; the marks are shared box meshes (`AlertMarks`, BlockyAnimal's material). The
  `StealthDirector` (node `Stealth` on every peer, `world/stealth_director.gd`) measures the light
  around bodies five times a second (`Player.stealth_light`, a bot's `stealth_light` meta), keeps the
  host's noise log (landings, broken blocks, attacks: `StealthDirector.add_noise`/`heard_at`), and
  checks hiding requests (`Session.stealth_request_hide/unhide`, section `# --- M2 Task 5: stealth`).
  `Player`: `crouching` (synced), `hidden_in`, `set_hidden`, `stealth_visibility()`, `stealth_eye()`;
  the `CameraRig` has `height_factor` (crouch) and `peek_from` (inside a hiding spot). HUD:
  `StealthMeter` (eye and noise bars under the hearts), `HideOverlay`, `DangerArrows`, CROUCH where
  DOWN sits. Notes and rulings: `docs/devlog/parts/m2-task-5.md`.
- **The Stone Golem and the portal (M2 Task 10):** `BossRules` (pure: health by team size, the
  slam/rock/charge schedule and wind-ups, who each attack hits, dazed double damage, the gold split,
  honest help, `stand_y`), `StoneGolem` (`entities/monsters/`: group `monsters`, `take_hit`/`hit_center`/
  `hit_radius`, phases synced as an int, looks from `GolemModels`), `GolemRock` (every peer flies the same
  arc; the host decides the hit), `BossDirector` (node `Boss` on every peer: Golem and portal spawners,
  the HUD's `BossBar`, win/loss RPCs; the host starts fights, pays, opens the portal, keeps the help) and
  `DesertPortal` (`entities/portal/`: one shared scrolling shader, `shaders/desert_window.gdshader`).
  Hooks: the sandbox's `start_boss(totem_pos)` (Task 9's Totem) and `summon_boss(near)` (`/summon golem`,
  Sandbox); `BossDirector.fight_started(tired)` / `fight_ended(won, percent)`. Beating it in Survivor
  raises every player's `Profile.data.universe_unlocked` through `Session.boss_unlock`. Saved per world:
  `WorldMeta.boss_help`, `portal_pos`. The Golem never changes blocks (tested). Notes:
  `docs/devlog/parts/m2-task-10.md`.
- **Universe ladder and portals (M3 Task 5):** `UniverseRules` (`core/rules/`, pure: slots, scaling
  × 2^(u−1), unlock order, the hub's list, travel, the bag carried through) and `UniverseRegistry`
  (`world/universes/`): the ladder meadows / desert / frost / candy, each universe a **descriptor script**
  `world/universes/<name>.gd` (interface in `universe_registry.gd` and `docs/devlog/parts/m3-task-5.md`;
  a missing file is "coming soon"). `Game.universe` is the universe of the world being played: its slot
  (`ModeRules.slot(mode, universe)`: `survivor_1`, `survivor_u2`, …), terrain (`WorldService.setup(…,
  universe)`), sky (`SkyCycle.palette`), music (`Music.use_tracks`) and scaling (waves, the boss, Tilly,
  flying, treasure; monsters already had it). A LAN guest gets the host's universe before `world_info`.
  The portal hub: the SURVIVOR menu's picture cards (`UniverseCard`) once a second universe is unlocked,
  and a stone circle by every Survivor world's spawn (`HubRules`, `HubCircle`, `UniverseHub`, `HubPanel`);
  travel (`sandbox.travel_to`, solo only) moves the child's bag and hotbar (`UniverseRules.carry`). The
  Golem's portal (`DesertPortal.target`) leads to the next universe. Portal frames and cores (blocks 130
  and 135, page 5, any world): `PortalRules` / `PortalLinks` (pure), `PortalDirector` (node `PortalFrames`
  on every peer; the host decides every trip from its own positions; saved in `WorldMeta.portals`); one
  shared swirl (`PortalSwirl`, `shaders/portal_swirl.gdshader`). Notes and rulings:
  `docs/devlog/parts/m3-task-5.md`.
- **Space: the Moon and the planets (owner feedback #55, spec §21):** worlds **16** The Moon, **17** Planet Boing, **18**
  Rainbow Planet (19-20 kept) are universe descriptors (`world/universes/moon.gd`, `boing.gd`, `rainbow.gd`) found by
  `UniverseRegistry` through its `SPACE` table beside the `LADDER` (`is_space`, `space_available`, `path_for`; `available()`
  and `size()` stay the ladder's, so the menus, the hub, Monster Wave and Plus never list them). Their extra descriptor
  fields: `gravity` (`UniverseRegistry.gravity`; the world scene sets `LabRules.world_gravity`, which every lab mode's
  gravity is × by), `peaceful` (`_start_space_host`: no night monsters), `space_sky` and `sky_planet` (`SkyCycle.space`,
  `show_planet`), `landing_words`. Pure rules: `SpaceRules` (`core/rules/`: the line and the climb, `may_launch`, the
  picker's `cards`, `refusal`, `arrival_meta`, `take_off`, `landing_spot`, `space_look`, `scaling`: never scaled, never Plus
  in `UniverseRules.scale`, `ShopCatalog.needs_plus` and the loot scales). This game only: `SpaceDirector` (`world/`, node
  "Space": the player's height → the sky's climb (`SkyCycle.set_space_climb`, in steps), the hint, the picker) and
  `SpacePanel` (`ui/space/`: `UniverseCard`s over stars and the planet below, HOME via `UniverseCard.as_home`, STAY HERE;
  holds a solo game still, `close(false)` when the pause menu takes over). The sandbox's section "Owner #55: space":
  `travel_to_space` → `_travel_space` (`SpaceTrip.arrival` writes the space world's save first: its home and the owner #39
  arrival gate; the bag in Survivor; then this world with `SpaceRules.take_off`: the take-off column, walking),
  `go_home_from_space` (= `travel_through_gate(home)`), `_arrive_from_space` (home lands on the take-off column,
  `WorldMeta.space_return`), `_space_landed` (the words, a whoosh, dust), `_space_map` (MY MAP: the pad, the landmark once
  found). Saves per mode like a universe (`sandbox_16`, `survivor_u17`, …); `WorldMeta.space_home`, `space_return`.
  Terrain: `SpaceShape` (one class, `planet`: MOON / BOING / RAINBOW; `ground_at` vs `height_at` = a Boing pool's jelly
  top; the landing pad at the spawn; features = "trees": moon crystals, spring mushrooms, prism spires) and
  `SpaceGenerator` (per chunk-stack cache of grounds and features; `grounds()` bit-identical to `ground_at`, the crater sums
  in the same order; `reference_block` is the test's rule), `SpaceSecretRules` (the M2 kinds through `PALETTES`, the
  landmark as the ISLAND secret: Moon Base, Boing Tower, Rainbow Arch; no treasure pack or mouse villages). Blocks: pages
  15-17 (`MoonBlocks`, `BoingBlocks` with `BOUNCY` → `CandyRules.is_gumdrop`, `RainbowBlocks` with `STRIPES`),
  `BlockIds.SPACE_GROUND` in the natural-block lists. Animals: `moon_bunny` (new, `AnimalHomes.SPACE`); planets reuse frogs,
  goats, candy birds and horses (`AnimalHomes._fits_space`). Notes and rulings: `docs/devlog/parts/owner-55-space.md`.
- **Universe portals you build (owner feedback #39, spec §14.2a):** universe crystals (items 480-484, `ItemIds.CRYSTALS`;
  rules in `CrystalRules`): every universe a profile reached gives its crystal once into the bag of the child's own
  Survivor world (`sandbox._hand_over_crystals`, `ProfileData.crystals_given` / `crystal_gifts`), Tilly's HOME sells
  copies (50 × 2^(u−1), universes 1..u), the Sandbox palette's SMART page has a PORTALS row. A crystal in the hand
  places its universe's **core** (blocks 212-215, 222; `GatherRules` pays and gives back the crystal) — a frame ring
  (`PortalRules`, `is_core`) round it is a **universe portal** (`PortalGates`, `WorldMeta.gates`, the
  `PortalDirector`'s section "Owner feedback #39"): no partner, its universe's swirl (`PortalSwirl.material_for(u)`,
  one material per universe, one shader), and a walk-in calls `sandbox.travel_through_gate(u)` (solo; the Plus rule):
  Survivor → that universe's Survivor world with the bag (`_travel(u, true)`), Sandbox → that universe's **Sandbox world**
  (`sandbox_<u>`, `ModeRules.slot`; `sandbox_1` is M1's; never scaled: `UniverseRules.scale_universe`). The arrival is
  in front of the destination's portal back (`WorldMeta.arrival_gate`, `ReturnGate.arrival`), built by the host when
  there is none (`ReturnGate.plan`). The SANDBOX menu shows a card per Sandbox world once there are two. **The pet
  dragon** (`PetRules.DRAGON`, perk `GLIDE`): a dragon egg in a Dragon Realm nest (`DragonEgg`, host `DragonNests`, node
  "DragonNests"; `Session.request_hatch`) hatches into the tapper's pet (saved with the world's pets); the Sky Dragon
  gives every player a baby dragon that lives in the profile like Pip (`ProfileData.baby_dragon`,
  `PetDirector.on_baby_dragon`, `Session.boss_give_dragon`) and a Dragon Crystal. A flying pet takes off when its child
  is up in the air and flies beside them (`Animal` section "Owner feedback #39"). Notes and rulings:
  `docs/devlog/parts/owner-39-portals-dragon.md`.
- **Survivor games and crafting (M3 Task 22, owner feedback #33, #34, spec §12.18–§12.19):** a new Survivor
  world picks a game after COZY / NORMAL / BRAVE (`menu.gd` `_choose_game` → `Game.start_world(…, game)`), saved in
  `WorldMeta.game` (old worlds CLASSIC) with each player's `WorldMeta.game_scores` (`GameScores`); `Game.survivor_game`
  is the game being played (a guest gets the host's before `world_info`, Session section "Survivor games and
  crafting"). Pure rules in `core/survival/`: `SurvivorGames` (kits, clock speed, night tuning), `BuildRules` (Build
  to Survive's clock: first night 3:00, days 4×, nights 2×; `SkyCycle.game` runs it), `ShelterRules` (a roof within 4
  above the head, walls by an exact flood at head and feet level within 6). (Monster Hunter became Monster Wave, #44.)
  `SurvivorGameDirector` (`world/`, node `SurvivorGame` on every peer): the host's shelters (`Player.sheltered` →
  visibility 0, so monsters never see them), nights counted at sunrise, knock-outs (all down at night → morning),
  beds only in a shelter (`SleepDirector.may_sleep`), fiercer nights (`MonsterDirector.per_player_cap`,
  `level_bonus`); every game's HUD `GameClock` (`HudLayout.SPOTS.game_clock`, a label). Build to Survive's building
  blocks at Tilly (`ShopRules.amount(…, game)`).
  Crafting: `Recipes` (`core/crafting/`, one validated table of 28), `CraftRules` (stations within 4 of the eyes,
  fuel, one tool of each), `Session.request_craft` → the host checks against the requester's body (one bulk copy
  around it, `craft_stations_near`) → `craft_done`; the palette's CRAFT tab (`CraftBook`, `RecipeCard`; Survivor
  only). Notes and 26 rulings: `docs/devlog/parts/survivor-games-crafting.md`.
- **A bigger world: the wild meadows (owner feedback #45b, spec §14.18):** Green Meadows' terrain version 2, for new
  worlds only (`WorldMeta.terrain`, the section above in §4). `MeadowsBiomeShape` (`world/generators/`, a MeadowsShape):
  `column(x, z)` = (height, biome, flags) — the old continents, hills and mountains (taller, snowy over 90, rock over 80)
  with biomes blended in (meadow, flower field, birch and dark forest, swamp with pools and lily pads, beach, mountain,
  sea, river, island), rivers as two families of warped lines that never close into loops and so reach the sea
  (`river_line_a/b`, wider at the coast), trees by biome (`tree_kind`), cave regions (`cave_region`: mushroom caves,
  lake caves), `chunk_columns` (a chunk column's heights, biomes and trees once for its whole stack of chunks, cached).
  `MeadowsBiomeGenerator` writes them (reference_block is its slow rule) plus the old caves and ores, a mushroom region's
  mud floors, glowing caps and giant mushrooms, a lake region's flooding (below y −22), then `MeadowsPlaces` and the
  secrets. `MeadowsPlaces` (pure): windmills, villages, lookout towers, lighthouses, ships at a pier, castle ruins,
  towns — one per 256 × 256 region at most, rarer farther from the spawn (`RARITY`, `chance_at`), 60 blocks clear of
  the spawn, clear of every secret, on dry gentle ground (pads), each with an id, a name, an anchor, doors, stairs,
  villagers. `PlacesDirector` (`world/`, node `Places` on every game; the sandbox's section "Owner 45b"): the host finds
  places near players (twice a second) and keeps `WorldMeta.places_found`; villagers (`entities/npcs/villager.gd`, a
  `Trader`: Tilly's shop in Survivor, a wave in the Sandbox) stand in villages near players; `found_places()` and
  `mark()` feed the world map (`ui/map/world_map_panel.gd`, MORE → MAP, the /find arrow through
  `ChatCommandRunner.point_at`). Hooks for the quests (§14.17): `place_found`, `places.nearest`, `village_centre`,
  `mark`. Notes and rulings: `docs/devlog/parts/owner-45b-world.md`.
- **Monster Wave (M3 Task 22, owner feedback #44, spec §12.20):** a third main mode, `ModeRules.WAVE` (hearts and the
  Totem; no `BUILDING` — Session refuses every edit and bot build —, no `FLYING`, real gold), one arena world per
  universe (`wave_<u>`, `WorldMeta.arena` keeps each player's best). The arena is flat (`ArenaShape`, `ArenaGenerator`;
  `WorldService.setup(…, arena = true)` on the host and its guests), with the Totem in the middle; the sandbox skips
  secrets, animals, weather, traps and the Theater there and stops the sky at noon. `ArenaDirector` (`world/`, node
  `Arena` on every peer) runs it on the host: waves by themselves through the WaveDirector (`taps_start`, `rewards`,
  `knockouts_end_waves` off), the raid boss at wave 10 through the BossDirector (`opens_portal` off, `end_fight`), the
  run's end when everyone is down at once (`ArenaRules.run_gold` for the time and the waves), the kill bonus
  (`MonsterDirector.defeat_payer`, no coins), bests, and the choice NEXT UNIVERSE / STAY (`sandbox.travel_to_arena`,
  solo). HUD: the `GameClock` (`show_arena`) and the `ArenaPanel`. Menu: MONSTER WAVE between SURVIVOR and PLAY ONLINE
  (`_show_wave`: a card per universe with its best). **Survivor has no Totem waves or boss any more** (`ModeRules.TOTEM`:
  Sandbox and Monster Wave). Notes and rulings: `docs/devlog/parts/survivor-games-crafting.md` ("Monster Wave").
- **Smart blocks and Game Blocks (M3 Task 7, spec §14.4):** blocks 192–207 on page 9 (`SmartPage`,
  registered at the top of `BlockLibrary.build()`; the palette's SMART tab, Tilly's HOME section). Pure rules:
  `PowerRules` (one step: a pressed button for 1 s, a lever or light switch that is on, a plate someone
  stands on powers the blocks touching its 6 faces; a powered doorway of up to 3 opens as one, a lamp lights;
  nothing powered passes power on; the on states are the same item as their plain block; `TapLimiter`, at
  most 5 toggles a second), `TeleportLinks` (the two nearest free pads pair), `CourseRules` / `CourseRun` /
  `CourseBook` (START arms, stepping off starts the clock; checkpoints; coins count for the course only; FINISH
  and the medal by the builder's goals, the first run × 1.0 / 1.3 / 1.6; best times), `RecordedRun` (10 Hz,
  ≤ 3 minutes, int16 decimetres in base64). Session section "M3 Task 7": `request_smart_tap` /
  `request_smart_touch` (the host checks the block, reach and a rate cap, then emits `smart_tap_requested` /
  `smart_touch_requested`), `power_set_blocks` (only a block's off and on states; never closes a doorway on
  someone; no undo step, no Survivor ledger), course state and goals panel RPCs. `SmartDirector` (node `Smart`
  on every peer; host: power, plates looked at 10 times a second, buttons popping up, teleport trips) and
  `CourseDirector` (node `Courses`; every peer watches its own player's feet — blocks read only when the feet
  change cell — and reports touches; falls go back to the checkpoint on the runner's own game; the host
  times every runner, records the best run, and a bot friend races it: `race_bot`, the FRIENDS page's RACE
  ME!). HUD: `RaceClock` (spot `race`, under the wave and boss lines; the toasts step down while it shows) and
  `CoursePanel` (a tap on FINISH or START). Saved in `WorldMeta.smart` (`SmartState`). Notes and rulings:
  `docs/devlog/parts/m3-task-7.md`.
- **The action kit's gadgets (M3 Task 14a, spec §13.3):** pure rules in `GadgetRules` (glider, hook, zipline
  ride, orbs, dance times, quick builds, Tilly's prices) and `ZiplineLinks`. The player's own game moves its
  body: `Player` section "M3 Task 14a" (`gadget_move` and `glider_look` synced; `_gadget_step` before the
  walk/fly dispatch: glide, the hook's pull, the zipline ride; JUMP after the last air jump or the HUD's GLIDE
  context button opens the glider, a launch pad (block 211, a `PadRules` pad) opens it at the top). Every use
  but gliding is a host request (Session section "M3 Task 14a": ownership, pace, reach, a grid ray for the hook,
  empty cells and the batch path for quick builds). `GadgetUser` (a child of the BlockInteractor) turns taps and
  ATTACK (the hook or an orb in the hand) into requests; a tap on a zipline post rides it. `GadgetDirector`
  (node `Gadgets`): orb flights and bursts (Boing pushes monsters and bounces players, Dance makes monsters
  `dance(seconds)`; bosses 2 s once in 20 s) and every game's effects; `ZiplineDirector` (node `Ziplines`):
  links from block changes (the nearest player owns a new post), rides, cables and poles, `WorldMeta.ziplines`.
  Models: `GadgetModels` (cached, WeaponModels' material), `GadgetLooks` on a player. Palette: the ARMORY page's
  GADGETS column; Tilly: GADGETS. Notes and rulings: `docs/devlog/parts/m3-task-14a.md`.
- **Rideable buddies (M3 Task 20a, spec §14.16):** a buddy built with a SADDLE (block 216, page 10) can be
  ridden. Pure rules in `core/magic/ride_rules.gd` (`RideRules`): the kind from the shape (wings sticking out
  left and right in the upper half, ≥ 2 each side: FLY; four bottom corners with a gap between front and back:
  DRIVE; else WALK; any non-flyer on water: SAIL), `normalise` (a build whose wings or wheels are along the other
  axis turns a quarter, keeping its look), speeds and caps (`SPEED`, never above `Player.FLY_SPEED`), `step`,
  `bump`, `climb_height`, `dismount_spot` (never inside blocks), Survivor's `ride_over` (a flight ends at landing).
  `RideDirector` (`world/ride_director.gd`, node `Rides` in the sandbox on every game): the RIDE context button
  (`HudLayout` spot `ride`, `Hud.show_ride_button`, HOP OFF while riding; Y on a keyboard) and every host
  decision (`host_ride`, `host_ride_off`, `host_ride_input`, `host_check` 10 times a second). Session section
  "M3 Task 20a": `request_ride`, `request_ride_off`, `ride_input` (unreliable, ≤ 20 a second), `send_ride_off`.
  The host moves the buddy (`Buddy` section "M3 Task 20a": `ride_kind`, synced `rider_peer` and `ride_mode`,
  `start_ride` / `end_ride` / `set_ride_input`, `_ride_step`, `_ride_decide` at 10 Hz, one collision box as
  before); every game puts the rider on the saddle (`Player.riding`, placed in `_process`; the sit pose) and a
  flyer's wings (meshes of their own on two hinges) beat. Tilly sells the saddle (HOME, 60 gold × 2^(u−1)); the
  Sandbox palette has it in the MAGIC row (`BlockPalette.MAGIC_BLOCKS`). Notes and rulings:
  `docs/devlog/parts/m3-task-20a.md`.
- **Cars (owner #109, spec §3b "Cars"):** eight ready-made kinds. Data: `core/rules/car_kinds.gd` (`CarKinds`: each
  kind's speed, reverse, acceleration, turn, climb (1-3 blocks), seats (where each rider's feet go, the driver's first),
  size, its compact collision box (≤ `MAX_BOX`), wheels, four colours, price, camera distance, horn, its card's line and
  checked facts). Pure rules: `core/rules/vehicle_rules.gd` (`VehicleRules`: `drive_step` (throttle and steer, no
  sideways slide, an empty car brakes at once), `fly_step`, `ceiling_y` / `held_under` (`FLY_CEILING` 150, a hover car
  24 over the ground), `wants_hop` / `hop_velocity`, `push_aside`, `can_board`, the seats, `place_spot` (in front,
  beside or behind, always within `BOARD_REACH`, never in a body or a parked car), `goes_home` (`PER_PLAYER` 4,
  `MAX_CARS` 12), the profile's ownership (`owned_kinds`: `"car:<kind>"` in `ProfileData.bought`), `clean_save`, the
  pickup's bed (`cargo_add`, `tip_cells`), `chase_yaw`, `drive_hint`). `Vehicle` (`entities/vehicles/vehicle.gd`,
  CharacterBody3D on layer 1 like the world, mask world + players + buddies + animals and monsters + bot friends): synced
  `seats`, `flying`, `colour`, `cargo` (position and rotation as every body, smoothed by RemoteSmoother); the host moves
  it (`host_step`: `_host_decide` at 10 Hz for water, steps, the safe spot, a fall out of the world, a parked car's
  ground); a parked car sleeps (no physics) until someone gets in or its loaded ground goes; the driver's stick comes by
  the car's own RPC (`send_input` / `_heard_input`: only the driver's); `host_fx` plays the horn, bumps, bounces on
  every game; every game links its riders (`Player.riding_vehicle`, `Player.in_car()`: `is_riding()` is true, so VR's
  vignette and the guest's mount filter, SLEEP and the teleport rules hold), spins the wheels and the sky taxi's rotors,
  bobs a hover car, bounces a monster truck, plays the engine loop (`VehicleSounds`). Looks: `CarModels` (one cached
  vertex-coloured mesh per kind and colour with `WeaponModels.material()`; one wheel mesh per kind; the rotor).
  `VehicleDirector` (`world/vehicle_director.gd`, node `Vehicles` in the sandbox on every game; its `Cars` filled by the
  `CarSpawner`): the requests (`request_car`, `request_buy`, `request_put_away`, `request_get_in`, `request_horn`,
  `request_fly`, `request_load`, `request_unload`; HOP OFF is Session's ride-off request) as RPCs on this node, never on
  Session; the host's `host_car`, `host_buy` (`Session.gold_spend`; a guest's game is told it owns the car: `_rpc_bought`;
  a guest says what it owns on arriving: `_rpc_owned`), `host_get_in`, `host_get_out` (`RideRules.dismount_spot`,
  `Session.send_ride_off`), `host_check` at 10 Hz, `to_save` / `restore` (`WorldMeta.cars`). Locally: MORE → CARS opens
  `GaragePanel` (`ui/vehicles/`: `CarPicture` drawn from the model's boxes, `CarCard` read aloud), the HUD's HORN and
  FLY / LAND (`Hud.add_car_controls`, `HudLayout` spots `horn` and `car_fly`, symbols `car` and `horn`), `RideDirector`
  asks `nearest_car` so its RIDE button says DRIVE or GET IN (`Hud.show_ride_button(on, riding, word, symbol)`),
  `BlockInteractor.vehicle_tap` (a tap on a car), the camera behind a moving car, the car out of its spring arm, VR's
  blink and facing. Notes and rulings: `docs/devlog/parts/cars.md`.
- **Buddy magic (M3 Task 20b, spec §14.21):** pure rules in `core/magic/`: `BuddyRecipes` (8 secret shapes: cells of
  block classes, matched turned four ways and mirrored with one spare block; traits, the thing each does, the Secret
  Book's silhouette and riddle), `BuddyPicture` (a build's front as a small picture code), `BuddyMagicData`
  (`ProfileData.buddy_magic`: shapes found, the Buddy Album (newest 40, the rest a count), the bosses' minis, the
  profile pets' tricks; merged by `ProfileBackup`), `BefriendRules` (the wand on a calm level 1-2 monster; never a
  boss, a wave's, the golden slime; not in Monster Wave; the pet cap), `MiniRules` (a tiny version of each boss but the
  Sky Dragon), `TrickRules` (three emotes near your own buddy or pet teach it; the move it does). A special buddy is
  worked out from its blocks on every game (`Buddy` section "M3 Task 20b": `recipe`, its act now and then, `grown`,
  `do_trick`, tricks saved in `WorldMeta.buddies`). Befriended monsters and minis are pets: species `monster_friend`
  and `mini_boss` with the monster or boss kind as the animal's `variant` (sent with the spawn, saved in
  `WorldMeta.pets`), looks from `MagicPetModels` (one shared mesh per kind, the animals' material); minis live in the
  profile like Pip (`MiniRules.animal_id` "mini_<kind>_<peer>", `PetDirector.is_profile_pet`). `BuddyMagicDirector`
  (`world/`, node `BuddyMagic` on every game; the sandbox's section "M3 Task 20b"): the host's album entries and
  secret-shape reveals from `_on_spark`, befriending (`Session.request_befriend`), minis from `BossDirector.boss_won`
  (every player's game told through `Session.buddy_magic_tell`; `request_mini` brings them), lessons from
  `Session.emote_played` (the move on every game by one reliable RPC). UI: the Secret Book's BUDDY RECIPES and BUDDY
  ALBUM pages (`BuildPicture` draws cells with the blocks' icons), My Stamps: `MyStampBook` (`core/building/`,
  `user://my_stamps.json`, item ids 495-499, ≤ 16 a side and ≤ `EditBatch.MAX_BATCH` blocks), the palette's STAMPS
  tab and `MyStampBar` (`ui/building/`: NEW STAMP → the next tap picks a build with `BuildPicker`). Notes and rulings:
  `docs/devlog/parts/m3-task-20b.md`.
- **The wonder pack (M3 Task 21c, spec §14.22):** **the Tiny world**: `MouseVillages` (`world/generators/`, pure) places a
  mouse village per 128-block area at most (a 1-block-high door at a hill's foot or in a knoll's tree roots, a tunnel,
  a 5 x 5 room with the mice's houses, lamps, the tiny chest; a marker by the door) from the seed and the terrain; it is
  `SecretRules.tiny` (`tiny_in_area`, `tiny_near`; **never in `secrets_in_area`**, so no secret and no place moves; villages
  keep `GAP` from the area's secrets and the wild meadows' places instead). `SecretRules.block_at` and every generator's
  `_place_secrets` write them; their cache is shared by every `MouseVillages` of a world (static, keyed by seed, terrain
  and rules), so the host's SecretDirector finds what the generator's threads worked out. `TinyDirector` (node
  `Secrets/Tiny` on every peer, the SecretDirector's child): a TINY child's feet in a room find it (the director's
  banner and book), the `MouseFamily` near players, every game's own big child in a room is shown out to the door; the
  chest mimic (`Session.request_wake_chest`, section "M3 Task 21c"; `SecretTaps`: the wand on an opened chest): a
  `ChestMimic` hops after its waker (`WakeKinds.mimic_hop`, ten times a second from the plate tick), gives
  `WakeKinds.mimic_present` (never gold), sleeps; once per chest (`SecretState.solved["mimic:<id>"]`). The tiny chest's
  loot is `MouseVillages.loot` (the cheese, block 275, treasure only). Pictures drawn in code: `TinyPictures` (ids 64+,
  through `Pictures`). **Waking more things**: `WakeKinds.kind_of` (cactus, pumpkin, snowman; names and words;
  `Buddy` section "M3 Task 21c": flower, orange glow, roll, snow puffs). **Building sounds**: `BuildNotes` (pure: the
  pentatonic notes, the row's rising melody, the budget: one note every 70 ms, 8 a second) and `BuildMelody` (the
  BlockInteractor's child `melody`: a pool of 4 players that never grows; one note per tap or tool step);
  `settings.build_notes` (SETTINGS → HELP → "Block music", beside Reduce motion). Block page 14: `TinyPage` (`data/blocks/tiny_page.gd`). Notes and
  rulings: `docs/devlog/parts/m3-task-21c.md`.
- **The Gold Farm (M3 Task 10, spec §5.6, §14.8):** pure rules in `core/economy/`: `FarmRules` (150 gold from
  Tilly × 2^(u−1); 20-50 gold an hour × 2^(u−1) for the time away, capped at 12-24 h, only when the owner left inside
  it; FASTER / BIGGER upgrades at fixed prices; the same sum as the server's `farm_collect`; a backwards clock pays
  nothing), `FarmSite` (placed like a stamp: the tapped cell is the front row's middle, the door faces the child; a
  9 × 7 footprint on flat, open ground; "inside" = over the footprint), `FarmNotifyRules` (the opt-in "Your farm is
  full!": never 20:00-08:00, once a day). `FarmDirector` (`world/farm_director.gd`, node `Farm` in the sandbox on
  every peer): the host places, upgrades and moves the owner's farm (Session section "M3 Task 10": `request_farm_*`,
  `farm_buy_refusal` for Tilly, `farm_pay_collected`), writes the away record at every world save (`for_save`) and
  pays the welcome-back once (the server's `farm_collect` when signed in and the server's clock was started, else
  the device clock), saved at once; every peer builds `FarmBuilding` (`entities/farm/`: one shared mesh, one static
  body) with 1-3 `FarmWorker`s (shared meshes, animated only within 48 blocks of this game's player). The item
  `ItemIds.FARM` (491, not in `ALL`). HUD: `FarmPanel` (a tap on the barn; FASTER, BIGGER, MOVE for the owner),
  `Hud.farm_welcome` (banner + `Fx.coin_shower`). The note: `FarmNotifier` / `AndroidFarmNotifier` (`net/`), a
  no-op until an Android plugin exists (M5); the switch "Farm note" in SETTINGS (off; under-13 behind the parent
  gate). Saved in `WorldMeta.farm` and the profile's `farm_note_at`. Notes and rulings: `docs/devlog/parts/m3-task-10.md`.
- **Defenses (M2 Task 8):** `DefenseRules` (pure: door stacks, doors in a monster's way, traps under the
  feet and their 2-a-second timing, lantern fear). A tap on a door (`BlockInteractor`) →
  `Session.request_door` → the host toggles the whole stack of doors (at most 3) like an edit (reach,
  never closing on a player, a bot friend or a monster; Survivor ledger; one undo step) and every game
  plays the door sound (`Session.door_toggled`). `DefenseDirector` (node `Defenses` on every peer): the
  host stabs monsters on spike traps (`take_hit(2, …)`, `Fx.spikes`) and tells weak monsters (level ≤ 2,
  `Monster.lanterns`) the lanterns within 8 blocks from a **lantern index** of 16-block chunks (each copied
  once when loaded, kept up to date from `block_changed`; a guest looks again every 2 s); every game puts
  2 shared warm lights on the lanterns nearest the camera (none on Low). Monsters never step up onto or hop
  over a closed door. Tilly sells doors in pairs. Notes and rulings: `docs/devlog/parts/m2-task-8.md`.
- **Blasters, surprise drops and goblin archers (M3 Task 14b, spec §13.4, §13.5, §13.7):** cartoon toy
  blasters, never real guns. Items 415–424 (`ItemIds.BLASTERS`, `AMMO`; 425–429 free), pure rules in
  `BlasterRules` (one blaster per rarity with its own ammo; damage, rate, magazine and reload in a
  `BlasterRules.Magazine`; the bubble's level cap, paint's slow and mark, the rocket's 4-block push; Tilly's
  prices and packs). Looks: `BlasterModels` (toy colours, an orange tip, rarity + 1 bands, the shared weapon
  material; shots; the bubble and paint marks) and `BlasterIcons` (drawn in code: no atlas tiles). Controls:
  `BlasterUser` (`entities/player/`, a child of the `WeaponUser`, which asks it first: the first line of
  `attack_pressed` / `attack_released`, `use_at_screen`, `handle_input`): ATTACK fires and keeps firing
  while held, a tap fires where it points. `Session.request_blast` → the host's `accept_blast` (a blaster,
  a sane aim; Survivor: owned, one ammo from the bag, "Out of Foam Darts!" once; rate and reload with slack)
  → `blast_requested` → `BlasterDirector` (node `Blasters` on every peer): the shot starts at the host's copy
  of the shooter's eyes and goes to everyone (`_rpc_shot`); every game flies it in the fixed `ShotPool`
  (`entities/projectiles/shot_pool.gd`, 40 mesh slots, nothing made per shot); the host checks what it
  meets (monsters take damage and push, `Monster.blast_bubble` / `blast_paint` / `blast_slow`; animals only
  pushed; dummies and the bullseye; never players, bot friends or buddies) and ends it everywhere
  (`_rpc_end`). Bursts and marks come from small pools. **Goblin archers** (`MonsterRules.ARCHER`, rules in
  `ArcherRules`; Monster section "M3 Task 14b"): keep 10–20 blocks, score a couple of spots a decision
  (cover, a peek beside it, high ground), wait in cover, step out, draw the bow for 1 s (`winding`, a glowing
  arrow), and shoot a slow arrow in the same pool (`Monster.shoot_arrow` = `BlasterDirector.monster_arrow`);
  a wall always stops it. They come at night instead of some goblins of level ≥ 2 and in waves from wave 4
  (`ArcherRules.night_kind`, `wave_roster`); `/summon archer`. **Surprise drops**: `DropDirector` (node
  `Drops` on every peer, rules in `DropRules`): a Party Piñata (`PartyPinata`, `entities/interactables/`,
  in the group `monsters` so every weapon hits it) floats down near a player after ≥ 10 minutes of play (never
  two at once; the clock is `WorldMeta.drops`); 3 hits burst it into supplies for every player near it
  (Survivor: blocks, a potion, ammo; never gold); Survivor waves from wave 3 bring one supply balloon over the
  Totem. Smoke run: §4. Notes and rulings: `docs/devlog/parts/m3-task-14b.md`.

### Web: one platform rule and what differs in a browser (M7, spec §20.3)

The web build is the same code as Android and the desktop. Every platform difference goes through **`PlatformRules`**
(`core/platform/platform_rules.gd`): pure static rules over a features dictionary, so tests can be a phone browser, a
desktop browser, Android or the desktop. `PlatformRules.current()` reads this device once: the engine's feature tags
(`web`, `web_android`, `web_ios`, `web_macos`, `web_windows`, `web_linuxbsd`, `mobile`, `android`), `touch_screen`
(web only: the browser's main pointer is a finger, `matchMedia('(pointer: coarse)')`, which also catches iPads whose
Safari says "Macintosh") and `touch_arg` (the `--touch` user arg). In a browser `mobile` and `android` are false.
**Tests pretend** with `PlatformRules.simulated = {...}` and reset it to `{}` in `after_each`.

| Rule | Android | Desktop | Browser |
|---|---|---|---|
| `touch_ui` (touch HUD: Sandbox, visits) | yes | only with `--touch` | phones and tablets (`web_android`, `web_ios`, a finger pointer) |
| `captures_mouse` (a click captures it; panels free it) | no | yes | desktop browsers only |
| `lan_available` (home Wi-Fi, ENet) | yes | yes | **no**: `Session.host_lan/join_lan` return `ERR_UNAVAILABLE`; the developer menu hides HOST LAN, JOIN and the address |
| `can_quit` (Back on the main screen quits) | yes | yes | **no** (the browser closes the tab); there is no QUIT button anywhere (SAVE & QUIT goes to the menu) |
| `photo_save` | `gallery` (SHARE) | `folder` (FOLDER) | `download`: the shutter keeps the photo in the game (no file), the chip is **DOWNLOAD** (`JavaScriptBridge.download_buffer`), behind the grown-up photo switch like SHARE |
| `starts_low_graphics` (a new profile's default only) | no (memory and cores decide) | no | phones and tablets |
| `can_vibrate` | yes | no | Chrome on Android (`navigator.vibrate`); never iPhone |
| `reads_safe_area` (HUD clear of the notch) | yes | no | no (the page keeps its canvas inside the safe area) |
| `syncs_storage` (`WebStorage`) | no | no | yes |
| `autosave_seconds(f, 60)` | 60 | 60 | 20 (`WEB_AUTOSAVE_SECONDS`: a tab can close any moment) |
| `shows_stand_ins` (the Theater's placeholder player) | no | yes | no |
| `fetches_packs` (`WebContent`: content that comes after the start) | no | no | yes: the music and the realistic pictures |

Not routed, on purpose: Android-only native parts that are simply off in a browser (`ShopService`'s Play Billing,
`FarmNotifier`, `AgeSignals`) and the developer-arg guards in `scenes/main.gd`.

- **`WebGlue`** (`core/platform/web_glue.gd`) is the only place that calls `JavaScriptBridge`; each call checks
  `OS.has_feature("web")` and is a quiet no-op elsewhere: `coarse_pointer()`, `page_host()`, `download()`,
  `ask_persistent_storage()` (`navigator.storage.persist()` when not persisted yet; logs
  `EasyCraft: storage persisted = true|false` to the browser console). Chrome says false for a site that is not installed or
  bookmarked (the data is then "best effort": kept unless the phone runs short of space). **Safari on iPhone (and
  every iPhone browser, all WebKit) may delete a site's storage, saved worlds and downloaded files included, after 7
  days without a visit; a Home Screen web app is exempt** (WebKit's storage policy). That is one more reason for the
  iPhone reminder to add the game to the Home Screen (`InstallOffer`); a child who plays only in a Safari tab and
  stays away a week can lose their worlds.
- **Saves that survive a reload (`WebStorage`, `core/platform/web_storage.gd`).** In a browser `user://` is
  `/userfs/godot/app_userdata/EasyCraft` in IndexedDB. Godot copies the whole folder there after a `FileAccess` write is
  closed (so JSON saves, the profile and world meta, sync themselves), but `VoxelStreamSQLite` writes the blocks with
  its own file I/O, which does not. `WorldService.save()` hands its save tracker to `WebStorage.sync_when_written`
  (a static coroutine: it finishes even when the world is freed) and `save_and_wait()` calls `WebStorage.sync()` after
  its wait: both write `user://web_sync.txt` (a timestamp), which carries the database with the copy. Off the web
  nothing is written. `scenes/main.gd` calls `WebStorage.ask_persistent()` once at boot.
- **"Add EasyCraft to this device" in the game (owner 2026-09-28).** The page's loading screen offers it; many
  players tap PLAY first, so the game offers it too, through the page's `window.easycraftApp` (`web/shell.html`):
  `WebGlue.install_state()` → `{can_install, needs_guide, installed}` (all false off the web or on a page without it;
  `parse_install_state` keeps only real `true`s) and `WebGlue.request_install()` (the browser's install prompt, or
  on Safari the page's picture guide over the game; call it right from the button's `pressed`: browsers allow the
  prompt only just after a tap). **`InstallOffer`** (`core/platform/install_offer.gd`, pure) decides: `can_offer`
  (a browser, `can_install`, not `installed`) for SETTINGS' **ADD TO THIS DEVICE** (the last row, hidden elsewhere;
  it hides again once the page has nothing more to add), and `card_due` for the main menu's **`InstallCard`**
  (`ui/menus/install_card.gd`: the buddy `res://icon.png` first, "Add EasyCraft to this device" with the speaker,
  one line, ADD / NOT NOW): only after play (`Game.worlds_left > 0`, counted by `Game.quit_to_menu`, or the
  profile's progress not empty), at most once a run (`InstallOffer.shown_this_run`), 3 days after an answer (ADD or
  NOT NOW: `settings.install_asked_at`), never after 3 NOT NOWs (`settings.install_not_now`). The menu shows it in
  `_route()` after the first-launch questions and welcome cards (`_show_home`), never during them. Tests pretend
  with the menu's `install_state` / `request_install` / `save_profile` and the settings panel's `install_state` /
  `request_install`; `Game.change_scene` records `quit_to_menu`'s scene change. Notes and the browser checklist:
  `docs/devlog/parts/m7-install-offer.md`.
- **Online:** a web release build uses `OnlineConfig.RELEASE_SERVER` like the phones (the page is served from that
  host's `/play/`, so no CORS); a developer (debug) web export signs in to the server on the host that served the page
  (`WebGlue.page_host()`: 127.0.0.1 in this PC's Chrome, 10.0.2.2 in the emulator's).
- **Music that comes later (`WebContent`, owner 2026-09-28: a small first download).** The web export leaves the
  background music out of `index.pck` (all of `res://assets/music/` except `day.ogg`, `night.ogg`, `boss.ogg`: the 17
  classical pieces and the 6 universe loops, about 20 MB) and puts it in a resource pack, listed in `packs.json` next
  to `index.html`: `{"version": 1, "packs": [{"name": "music", "file": "music.<hash>.pck", "size": <bytes>}]}`.
  `scenes/main.gd` (`start_packs`) adds a `WebContent` node (`core/platform/web_content.gd`) under the root in a browser
  only (`PlatformRules.fetches_packs`). `START_DELAY` (5 s) after boot, never while a world loads (a `LoadingCard` is in
  the group `world_loading`), it reads `packs.json` (from `WebGlue.page_url()`'s folder); for each pack a whole copy in
  `user://packs/` (right size) is loaded at once, otherwise it is downloaded to `<file>.part` (`WebContentIo`: one
  `HTTPRequest`, `accept_gzip` off in a browser; the body comes into memory and `WebContentIo` writes the file, because
  `HTTPRequest` deletes its own `download_file` in a browser), renamed when it has the right size, older copies of that pack deleted,
  `ProjectSettings.load_resource_pack(path, false)`, and `pack_loaded(name)` goes to `Music.on_pack_loaded`. Offline
  (no `packs.json`) the copies already here load. Retries wait 5, 15, 30, 60, then 120 s (`MAX_TRIES` 12 a run); a
  download with no byte for 60 s starts again; a hidden tab's long first frame counts 0.25 s. The downloaded file
  stays in the browser's storage (the download's close and `WebStorage.sync()` after renames and deletions).
  **Before the pack:** `MusicPieces.present(id)` / `file_present(path)` (`ResourceLoader.exists`, always true on
  Android and the desktop) decide; `MusicPlan` picks only pieces that are in, the mood's own core loop stands in where a
  piece would play (no silence, no "Now playing") and tries a piece again after `MIX_LOOP_TIME`; `Music.use_tracks`
  gives a missing universe loop Green Meadows'; `Music.on_pack_loaded("music")` loads each universe loop on the loader
  thread and swaps it in at its next start (never cut). The settings show "More music is on its way…" beside Song names while `Music.more_music_coming()`,
  and `/music next` says the same. Tests pretend with `MusicPieces.exists_check = func(path) -> bool` (reset to
  `Callable()` in `after_each`). Browser log lines start `EasyCraft:` ("downloading the music pack", "the music pack is
  in"). Notes, the pack's file list and the browser checklist: `docs/devlog/parts/m7-web-packs.md`.
- **Realistic pictures that come later (`RealisticPack`, owner 2026-09-28: "load any unnessesary data later").** The
  REALISTIC style's own files, every block page's realistic twin (`data/blocks/realistic_{albedo,normal}.png`,
  `data/blocks/pages/<page>_{albedo,normal}.png`) and the HDRI sky (`assets/sky/*.hdr`), were 36 of the browser's 47 MB
  main pack; BLOCKY (the default) never loads them. "Web" and "Web Mobile" exclude the patterns
  `data/blocks/*_albedo.png, data/blocks/*_normal.png, assets/sky/*.hdr` (a page added later with the same naming comes
  along; no pixel page matches: `tests/unit/test_realistic_pack.gd` walks the project), and "Web Realistic" /
  "Web Realistic Mobile" export exactly them in the game preset's texture format. `packs.json` lists them after the
  music with `"gpu": "s3tc"` / `"etc2"`: an entry with `gpu` is only for that texture format, the one the page chose
  (`web/shell.html`'s `pickPack` sets `window.easycraftGpu`; `WebGlue.texture_format()`, S3TC when unknown;
  `WebContent.gpu`), an entry without it is for every GPU. `WebContent.first` names a pack to fetch before the others,
  asked before each pack starts (never cutting a download): `scenes/main.gd` names `realistic` while the saved style
  is REALISTIC. **iPhones and iPads** (`PlatformRules.holds_big_packs`: `web_ios`, or `web_macos` with a finger pointer)
  fetch it only for a child who plays REALISTIC: `WebContent.later` (pack name → true while it waits; a whole copy
  already here still loads; looked at every `LATER_CHECK` = 2 s) holds `realistic` while the saved style is not
  REALISTIC (the lead's ruling, 2026-09-28: every start copies all of user:// into the tab's memory, ~57 MB more with
  both packs, and Safari reloads a tab that uses too much; cost if wrong: an iPhone child who picks REALISTIC waits
  for ~8 MB to download, with the "on their way" note). **Before the pack:** `RealisticPack.present()` (its `files()`: `BlockLibrary.realistic_files()` and
  `WorldService.REALISTIC_SKY`; `ResourceLoader.exists`, always true on Android and the desktop) decides:
  `BlockLibrary.set_style("realistic")` keeps the pixel pictures (`BlockLibrary.style` says what the blocks show:
  BLOCKY, so the painted sky, no glow, blocky water and Pip; a page whose twin is missing keeps its pixel page), the
  saved choice stays, the person (the realistic avatar is in the first download) follows the choice at once. SETTINGS
  shows "The realistic pictures are on their way…" beside the style buttons while REALISTIC is chosen (it goes when
  they land), and `/style realistic` says the same. **When it lands** `WebContent.pack_loaded` →
  `RealisticPack.on_pack_loaded` calls the group `realistic_pictures` (`realistic_pictures_arrived()`): every
  `WorldService` that was asked for REALISTIC (`apply_style` remembers it) applies it again (the shared materials: no
  remesh), a BLOCKY one changes nothing; the menu's backdrop follows a style picked in its SETTINGS at once (every
  platform). Tests pretend with `RealisticPack.exists_check = func(path) -> bool` (reset to `Callable()`). Browser
  log line: `EasyCraft: the realistic pictures are here (the blocks show realistic; 107 ms)`. A new realistic-only
  file elsewhere needs its pattern in the three presets, `RealisticPack.files()` and the test's `PATTERNS`. Notes,
  the pack's file list, sizes, rulings and the browser proof: `docs/devlog/parts/m7-realistic-pack.md`.
- **The game's media in their own pack (`AssetsPack`, owner 2026-09-28: "after refresh i dont need to redownload the
  data").** Every deploy changes `index.pck`; its media changed rarely. "Web" and "Web Mobile" exclude
  `assets/audio/*.ogg, assets/audio/*.wav, assets/characters/*.png, assets/characters/*.fbx` and the three core loops
  (`assets/music/day.ogg, night.ogg, boss.ogg`), and "Web Assets" / "Web Assets Mobile" export exactly them
  (`assets.<hash>.pck`, `assets.mobile.<hash>.pck`, 7.6 MB, 6.4 brotli; byte-identical today: no VRAM texture among
  them). Not moved: the brand pictures (the boot splash), `icon.png`, and the pictures our tools make in `data/` and
  `ui/` (they change with blocks and items). The page (`web/shell.html`) preloads its GPU's one to **`/assets.pck`**
  next to its main pack, **before the engine starts** (the progress bar counts it; `tools/export_web.sh` fills
  `EC_ASSETS` and `fileSizes`); the service worker keeps it by content (`EC_HASHES`), so an update that changes only
  code downloads only `index.pck`. **`AssetsPack` (`autoloads/assets_pack.gd`) is the first autoload:** in a browser
  its `_init` loads `/assets.pck` (`load_resource_pack(path, false)`: the main pack's files win; logs `EasyCraft: the
  assets pack is in (16 ms)`, an error when the page brought none); off the web nothing. The engine loads and makes
  the autoloads one by one, so every later autoload's `preload` (Music's loops) finds its file; for that the loader
  names nothing of the game (no preload, no path, no class). Keep it first and keep it bare. A new kind of media file
  under `assets/audio` or `assets/characters` needs its pattern in the four presets and the test's `PATTERNS`;
  nothing may name a moved file by uid (the main pack's uid cache only knows its own files). Notes, file lists, sizes
  before and after, the update measurement and the rulings: `docs/devlog/parts/m7-assets-pack.md`.
- **The shader warm-up (`ShaderWarmup`, `world/shader_warmup.gd`; the browser's freezes).** WebGL compiles a material's
  shader the first time it is drawn, and the page waits for it on the main thread (the lead's profile of a first world
  load: `getProgramParameter` 49 %); Godot compiles 4 variants of every new material shader at once, then one per way
  it is lit (a sun, a lantern, fog, glow, particles): about a second a shader on a phone. `ShaderWarmup` draws what
  the game will draw once, hidden, **in two parts** (the rework, 2026-09-28: all of it before the menu held the
  emulator's page 44 s). `Menu._warm_then_announce` → `ShaderWarmup.start(menu, backdrop world)` where
  `ShaderWarmup.wanted` (the OpenGL renderer, `PlatformRules.warms_shaders`: every browser, an Android phone or desktop
  that fell back to OpenGL; `PlatformRules.shader_warmup` is the switch; not with the developer arg
  `--no-shader-warmup`), once a run; the node lives under the tree's root. **The first part** (the census's `tier`
  FIRST: what the menu shows) is drawn before the menu says `MENU ready` (`first_done`); meanwhile the game view draws
  no 3D (`quiet_main_view`, from `start`) and the progress goes to the page's bar (`WebGlue.warmup_progress` →
  `window.easycraftWarmup` in `web/shell.html`: "Getting your world ready… N %", the engine's start is the first
  10 %). **The world part** (WORLD: what a first world shows near the spawn, the player's feedback on blocks, the
  blocks by a lantern) comes first after it; while it is not drawn the warm-up is in `LoadingCard.HOLD_GROUP`, so a
  world's `LoadingCard` stays after the spawn until it is (at most `LoadingCard.HOLD_MAX`, 30 s), and the game view
  draws no 3D under the card (log line `WARMUP world blocky: …`). **The rest** (SOON: what the first minutes of play
  show or the first world holds hidden; then lanterns; LATER: monsters, bosses, the Moon, other universes, the other
  style) follows. After the menu it draws only where `later_may_run` lets it: on the main menu
  (`ShaderWarmup.AT_MENU`) when nobody touched anything for 1.5 s, or behind a world's `LoadingCard`; never in play;
  after a frame that drew, as long again without (`rest_after`, at most 2 s; not while the card only waits for it).
  **Every world's card waits for that world's own draws** (the frame spikes, 2026-09-30): a new `LoadingCard` makes
  `ShaderWarmup.world_part(card.universe())` put what the census saw on screen at that world's landing
  (`in_world_part`: the blocks and the child's own look, also by a lantern, `player_look_keys`; FIRST; the player's
  feedback; the world's census phase, `world_phases`; Green Meadows' first world: WORLD) first and hold the card for
  it; another world's draws go back to the rest (log line `WARMUP world blocky (moon): …`). Before, the Moon from the
  developer menu, a rocket's landing or a space world CONTINUEd met its own draws compiling in play.
  Every frame draws as many as `BUDGET_MS` (150 ms) allows at the last draws' cost (`next_count`, measured to
  `RenderingServer.frame_post_draw`), at least one, at most 8. It draws in a SubViewport with a world of its own (nothing shows in the game's), a copy of
  the backdrop's environment and sun, the game view's 3D scale and MSAA (they decide the variants), an omni light for
  the lantern variants. What: every block page's materials in the style (`BlockLibrary.warmup_materials`: keeper twins,
  so both styles' shaders stay compiled: a shader nobody uses is freed), and the census (`data/shader_warmup.json`,
  §7): materials by what makes their shader (`ShaderWarmup.describe`/`build`), instanced or not, casting a shadow or
  not, skinned characters on their own scene, Label3D and Sprite3D settings; one draw per shader. Styles: BLOCKY; a
  REALISTIC child REALISTIC first, BLOCKY in the rest; a child who picks REALISTIC later gets it first in the rest
  (`watch_style`, `add_style`). **The Sandbox's spawn prewarms** (a tiny draw in front of the camera: Fx, the break
  ring, thought bubbles, portals, the game ring, the blasters; made for Vulkan) go through `ShaderWarmup.at_spawn`,
  which skips them where a warm-up ran (`covers_prewarms`): on WebGL they were 41 of a new world's 71 programs, all at
  the spawn. Every built material stays (`ShaderWarmup.kept()`). Log lines: `WARMUP first blocky: <draws> draws in <ms>
  ms` (the menu shows) and `WARMUP blocky: <draws> draws in <ms> ms (<ms> ms of frames drawing; the worst after the
  menu <ms> ms)`. Measurements, what compiles where, the rulings: `docs/devlog/parts/m7-shader-warmup.md`. Tests:
  `tests/unit/test_shader_warmup.gd`, `test_shader_warmup_sources.gd` (the census and the list of every script that
  makes a material), `tests/integration/test_shader_warmup_stage.gd`, `test_shader_warmup_spread.gd` (the parts, the
  order, the budget, the progress), `test_shader_warmup_menu.gd` (the menu, the gate, the styles).
- Tests: `tests/unit/test_platform_rules.gd`, `test_web_glue.gd`, `test_web_storage.gd`, `test_install_offer.gd`,
  `tests/integration/test_web_world_saves.gd`, `test_web_lan.gd`, `test_web_photo.gd`, `test_web_routing.gd`,
  `test_install_offer_menu.gd`, and the web cases in `test_visit_world.gd`, `test_online_config.gd`,
  `test_low_preset.gd`, `test_profile_data.gd`; the music pack: `tests/unit/test_web_content.gd` (a fake network and
  files, `tests/fakes/fake_web_content_io.gd`), `test_music_before_the_pack.gd`, `tests/integration/test_web_content_io.gd`
  (real files and a real `.pck`), `test_music_pack.gd`; the realistic pack: `tests/unit/test_realistic_pack.gd` (its
  files and the export presets' patterns), `tests/integration/test_realistic_before_the_pack.gd` (blocks, worlds, the
  menu, SETTINGS); the assets pack: `tests/unit/test_assets_pack.gd` (the loader, the patterns, what the engine reads
  before the autoloads, the presets), `tests/integration/test_assets_pack_load.gd` (a real pack, `tools/pck_tool.py
  strip`). Notes and rulings: `docs/devlog/parts/m7-web-code.md`, `m7-install-offer.md`, `m7-web-packs.md`,
  `m7-realistic-pack.md`, `m7-assets-pack.md`.

### Game controllers (owner #90, spec §20.3)

A PlayStation, Xbox or any pad plays the whole game on every platform (Godot's joypads; the browser's Gamepad API).
The table, the rulings and what the lead checks with a real pad: `docs/devlog/parts/controllers.md`.
- **`GamepadRules`** (`core/platform/gamepad_rules.gd`, pure; `PadRules` is the jump pads'): `BINDINGS` (the input map's
  pad events, §4 "Input map"), `world_actions()` (set aside while a menu has the pad), `family(joy_name)` (PLAYSTATION,
  XBOX, else GENERIC with the Xbox letters) and the words (`button_word`, `line_words`, `CARD_LINES`), `look_step`
  (the right stick: `LOOK_SPEED` rad/s, the profile's `pad_look` SLOW / NORMAL / FAST), `device_of(event)` (PAD, OTHER
  or nothing: the mouse moving never counts), and the focus rules (`first_focus`, `next_focus`, `reading_order`,
  `reachable`, `stick_direction`, `Repeat`, `is_back_word`).
- **`PadFocus`** (`ui/help/pad_focus.gd`; one under the root, `PadFocus.install` in `main.gd`; tests make their own in a
  SubViewport; with none every static call is a no-op): **every menu and panel takes the pad through it.**
  `PadFocus.watch(panel)` where a panel is made (it has the pad whenever it is `visible`; the newest shown wins; closed,
  the one under it gets the focus back where it was) or `PadFocus.take(card, first)` when a card opens. New content in a
  panel gets the focus by itself. Circle / B: the nearest `pad_back() -> bool` from the focus up, else the panel's
  BACK / CLOSE / X / CANCEL / NOT NOW (or meta `pad_back`), else the game's Back (`NOTIFICATION_WM_GO_BACK_REQUEST`
  round the tree, `PadFocus.back_from_pad` true meanwhile). Metas: `pad_first`, `pad_skip`, `pad_back`; a drawn control:
  `pad_move(dir) -> bool`, `pad_press() -> bool` (TouchButton, the School's grid and build board). FOCUS_NONE buttons
  take the pad's focus and are put back when the mouse, a finger or a key comes. While a panel has the pad the world's
  pad events are out of the input map (restored on close and exit). The triggers' repeated moves are cut to one press and
  one release. The ring: `PadFocus.PadRing` on layer 126 with `UiKit.focus_ring()`; the theme's focus stays empty.
  Statics for game code: `pad_active()`, `menu_has_pad()`, `playing_with_pad()` (the sandbox's crosshair and hidden
  arrow), `current_family()`, the `device_changed(pad)` signal (the HUD's `set_pad`: the touch buttons hide on a phone,
  MORE's picture buttons show on a PC; the KEYS / CONTROLLER card follows).
- **Never watch a panel that shows while the child plays** (a HUD strip, a hint): it sets the pad's walking aside. The
  Theater's screen is watched on purpose (inside the building it is the Theater; EXIT is its back: the sandbox's
  `pad_theater`), and the Mission Board too (it opens when the child walks up; X, then walk away). Something done while
  playing that is only a touch button needs an action with a pad event in `BINDINGS`.
- **Tests:** `tests/unit/test_pad_gamepad_rules.gd`, `tests/integration/test_pad_input_map.gd`, `test_pad_focus.gd` (the
  mechanics in a SubViewport: push joypad events with `view.push_input`, wait with `get_tree().process_frame`, not
  GUT's `wait_frames`, which counts physics steps that can run several to a drawn frame), `test_pad_screens.gd` (every
  screen reachable: `GamepadRules.reachable` over `PadFocus.candidates`), `test_pad_menu.gd`, `test_pad_player.gd`,
  `test_pad_card.gd`, `test_pad_web_page.gd`.

### VR: the rig (owner #101; `docs/devlog/parts/vr-rig.md`)
- **`Vr`** (autoload, `PROCESS_MODE_ALWAYS`, the lead's frozen contract): off VR every call is a no-op and nothing is
  made. A session (`start(&"openxr")`: by itself at launch in a `quest` build; `start(&"webxr")`: from a tap in the
  browser; `simulate(true)`: tests; `preview(true)`: the desktop) makes the **`VrRig`** (`entities/vr/vr_rig.gd`, an
  XROrigin3D: the head `XRCamera3D`, two `XRController3D`, the `VrComfort` sphere), `VrInput`, `VrHand` and (not in
  tests) `VrBench`, children of the autoload, so they live across scene changes. The head is always the view in VR.
- **The anchor:** `Vr.anchor(node, &"feet" | &"seat" | &"menu")`; the local Player anchors its feet in `_ready`. The
  origin puts the tracked head at the anchor's eye (feet + the avatar's eye height, "game height"; a seat or a menu spot:
  the node), recorded each physics tick after the player's (`process_physics_priority` 100) and interpolated each frame.
  It turns only round the head (`Vr.turn`, `Vr.face`); a jump of more than 2 m in a tick blinks (black, then 0.25 s in).
- **Gameplay keeps reading `rig.yaw` / `rig.pitch`:** CameraRig's VR mode (`CameraRig.vr_mode()`) sets them from the head,
  turns the origin when the game writes a yaw, has no spring arm, shake, look or CAM, and `snap_to_target` blinks. The
  player's own camera stands where the head is (it is not drawn). **Every world tap goes through
  `Player.aim_ray(screen_pos)`** ([origin, direction]: the camera's ray off VR, the pointing hand's in VR): a new world
  tap must use it, never `project_ray_*`.
- **Never a camera move the child did not make:** no shake (Feel, CameraRig), no knockback on the VR body, no pad, mouse
  or finger look, `Feel.motion_allowed()` false in VR (take its calm way), every jump in place behind `Vr.blink()` /
  `fade_out` + `fade_in`. Room scale: `Player._vr_room_scale` walks the body after a head that stepped; a head in a block
  is black.
- **The controllers** play as pad device `VrInput.DEVICE` through `GamepadRules.QUEST_BUTTONS` (the table in the notes);
  the turning stick snap-turns, the pointing trigger is TAP/HOLD (TouchClassifier) on the laser's target.
- **Graphics:** a real session sets `GraphicsPreset.vr_session`: every phone preset reads as the headset's VR preset (P5:
  `GraphicsPreset.vr_preset`, `vr` or on a Quest 3 / 3S `vr_plus`; a child's VR or VR PLUS stays itself), and so do
  `style_in_use`, `mesh_block_size`, `sky_interval`, the refresh rate (`Vr._tune`), `Fx.max_live`;
  `PlatformRules.vr_build` (feature `quest` or `webxr`): no touch HUD, no pointer lock, no phone buzz. The OpenXR and WebXR classes are reached by name (`xr.call`, `xr.get`): each exists only in its
  own builds, so a typed reference would not parse in the others.
- **P3 (comfort for everything that moves):** the turning stick pushed away aims a teleport (`VrTeleport`,
  `TeleportRules`: 1-6 m, a block up at most, room, in sight, no hiding spot, `Player.vr_teleport_refuse` for a game's
  no), behind a blink. The vignette reads the origin's speed and acceleration and is stronger for motion the child did
  not make (`Player.vr_passive_motion`). A seat (`Vr.sit(node)` / `release(node)`; kind `&"seat"`) carries the origin's
  whole transform every frame (the rocket's `VrSeat` with `VrCapsule`, turned at most 15°/s; `Vr.view_like(camera)`
  draws a flight camera's layers and sky); a game that moves a seat in `_process` calls `Vr.follow_now()` after it. Size
  Magic is `Vr.set_world_scale(size)`; a hiding spot is `VrRig.eye_override`; sleep `Vr.freeze` + fades; a knock-out
  `Vr.set_dim`. PHOTO in VR is `VrPhotoCamera` in the hand (`PhotoMode._vr_open`). Anything new that moves the child
  goes behind `Vr.blink()` / a fade, or turns at most `VrRules.SEAT_TURN_DEGREES` a second.
- **P4 (hands and friends):** the child's own hands are `VrHandModel`s in the avatar's colours on the controllers' grips
  (`Vr.hand_grip(side)`; the grip makes a fist, the trigger curls the index finger); the held item hangs on the pointing
  hand (`Vr.item_anchor(item)`; a bow in the other hand, drawn with two: `VrRules.bow_grabs` / `bow_power`); swings
  attack only with VR COMFORT's `vr_swing` on (off by default). The child's own avatar shows only through
  `Vr.show_self(on, who)` (its meshes on `VrPhotoCamera.SELF_LAYER`, never drawn by the head: the photo's selfie, the
  mirror `Vr.set_mirror` / `toggle_mirror`). A game that must refuse a teleport joins the group `Player.TELEPORT_RULES`
  with `refuses_teleport(player, at) -> bool` (CourseDirector while racing, GamesDirector while a round runs).
- **A VR player's pose for the others:** `Player.vr_pose` (`VrPoseRules`: 21 bytes, the head and both hands in the
  body's space, VERSION 1; empty off VR) goes by RPC on the Player's child **`VrPoseLink`** (`entities/vr/vr_pose_link.gd`):
  a game that shows the player asks its owner once (`_listen`, reliable); the owner sends to those who asked, 20 a second
  while it changes and a keepalive each second (`_pose`, unreliable ordered), "no pose" as one 0 byte (an empty
  PackedByteArray arrives as no argument at all). Other games show it as `VrBody` (the head turned, the hands floating,
  the arms folded; `VrBodyModifier` for the realistic skeleton) and `NameTag.vr_marked` ("  [VR]"). **Never add a
  property to the Player's SceneReplicationConfig for something new:** a game with one more synced property than an
  older build breaks every packet the older one sends it ("Invalid packet received. Size too small"; the net test's
  `--old` run found it). New per-player data goes by RPC on a child node, as VrPoseLink does.
- **The rocket in VR (owner #106/#108):** seated, the right trigger is the throttle lever (`FlightCockpit.analog_throttle`,
  set by RocketFlight in VR: as far as it is squeezed, at once; let go, it falls back at the lever's spring); A is the
  action and GO on the first try's card. The descent is the child's (no autopilot in VR either); its crash never tips the
  seated child (`FlightShots.vr_pose` zeroes `tilt` with the shake), the bumps are buzzes (`VrRules.HAPTIC_TOUCHDOWN`,
  `HAPTIC_CRASH`, `HAPTIC_WRECK`). **Every cut of a flight is under the headset's black** (`RocketFlight._vr_black`,
  held with `Vr.hold_fade`, let go with `Vr.fade_in()`): the clouds' thickest (the world and the space set change places)
  dips to black; a practice's next try dips; after a crash the way home is fade cuts, never black for more than about
  3 s: the crash dims to black, the capsule heading home and its re-entry are seen from the seat (each fades in and dips
  at its end), then the parachute, the rocket's fall and HOME are watched from a still spot on the ground by the pad
  (`_vr_spot`: the flat still shot's place, an eye's height up, level, facing the pad; the capsule's round room not
  drawn there, `VrCapsule.show_shell(false)`). A new flight step that cuts (the rocket turned at once, a scene change)
  gets a dip there too.
- **Round 4, VR-SOUND (owner #110; `docs/devlog/parts/vr-r4-sound.md`):** the music blocks (`BlockIds.XYLOPHONE`,
  `DRUM`; `MusicPage`) are played by `MusicDirector` (node "Music" in the sandbox, every peer): a tap through
  `BlockInteractor.vehicle_tap` (chained before the cars' own: BlockInteractor was VR-HANDS' in round 4), in VR two
  `MusicDirector.Mallet`s (each a `VrGrabbable` of kind `&"tool"`: VR-HANDS' grabber sets `holder` and emits the
  signals; a held mallet follows `Vr.hand_grip(side) * hold_offset`, its head striking what it comes into), LOOP and STOP
  on the HUD (the HORN and FLY spots), friends' notes as events through the host (`host_note`, only to games that said
  `_rpc_listen`). The rules: `MusicBlockRules` (and its `Loop`). In the capsule RocketFlight pokes the dashboard's STAGE,
  LEGS and LIGHTS with both hands' index fingertips (`CockpitTouchRules`: VrHandModel's geometry, a press in through the
  face, the hand's picture stopped at the panel), toggles the cabin lights (VrCapsule's `shell` and `rim` parameters),
  and every buzz goes through `_vr_buzz(pulse, sides)` with `Vr.haptic`'s frequency (the burn's pulsed rumble, the
  stage's thump, the countdown's ticks, the pokes' clicks), logged in `vr_haptic_log` for tests.

### VR: hands that hold things (owner #110, #116; `docs/devlog/parts/vr-r4-hands.md`)
- **Something a hand can take** gets a `VrGrabbable` child (the lead's frozen contract: `kind`, `throwable`, `far_pull`,
  `hold_offset`, the signals `hovered`, `grabbed`, `released(side, velocity)`, `used(side, amount)`, `held_by()`; its
  body's plain fields `radius` (its size round the node), `follows_hand` (false: its own script moves it), `enabled`,
  `stretch`). Listen to the signals; a RigidBody3D parent is frozen while held and thrown on release; a node with
  `vr_into_bag(side) -> bool` takes the over-the-shoulder drop. Never move a host-owned thing on one game alone
  (`follows_hand = false`, ask the host on `grabbed`: the pickup bags' way).
- **`VrGrabber`** (`Vr.grabber`) drives every grabbable on `VrGrabRules`: near (NEAR_REACH from its surface), far by the
  pointing hand's laser (lock, then a flick or PULL_HOLD), throws (THROW_WINDOW × THROW_SCALE, capped). **The grip's
  order (R1):** a grabbable near, one under the laser, then `claimers` (objects with `grip_claim(side) -> bool`,
  `grip_release(side)`, optional `grip_cancel(side)`: the Build Table's rim, `VrBricks`, MODEL VIEW's twist), else the
  hotbar's step as before (VrInput `_grip_to_hands`). `Vr.hand_busy(side)`: holding, building or at the table: that
  hand's laser is off (VrHand's beam, VrPointer's ray) and its trigger is the thing's (the table's place and break).
- **Hand building in the world (#116):** `VrBricks` + `VrBrickRules`: a brick from the bag (over the shoulder), the wrist
  hotbar's slot, or out of a wall (`BlockInteractor.break_block`); the ghost's cell; let go: `BlockInteractor.place_block`
  (the tap's own place: one undo, Survivor's bag, the host). A new way to place or break a block must use those two.
- **Gestures:** `VrGestures` (waves, the buddy's paw, high-fives with friends on the VR pose's spare byte:
  `VrGestureRules.with_claps`, appended by `Vr.pose_bytes` only after a clap), `Buddy.look_target` (INF off VR),
  `VrBody._bubble` and `Player.vr_bubbled()` (R8). **Never add an RPC to VrPoseLink:** Godot numbers a node's RPCs by their
  sorted names, so a new one shifts the ids an older build uses; extra data rides after the pose's 21 bytes.
- **The Build Table** (`Vr.build_table`, `VrBuildTable`, `BuildTableRules`: x right, y up, z towards the child, the far row
  z = 0) and **MODEL VIEW** (`Vr.model_view`, `VrModelView`, `ModelViewRules`; `Vr.body_waits()` while it holds the body
  still: VrInput sends no walking and no buttons but the menu and MORE, `Player._vr_room_scale` walks nothing). A School
  `BuildBoard` coming into the VR canvas opens the table on it (`Vr._on_node_added`). The VR panel, tray and wrist strips
  scale with `Vr.world_scale()` (`VrPanel.scaled_round_head`).
- **Physics queries from a tap** (VR P5's follow-up a): through `BlockInteractor.space_ray(query)` and `in_space(tap,
  done)`, never `direct_space_state` from `_process` / `_input`: with `physics/3d/run_on_separate_thread` on (the Quest
  APK's lever) the space can be read only in the physics step. The VR hands' own checks use the voxels (`GridRay`,
  `WorldService.get_block`), never physics.

### VR: wonders to hold (owner #110; `docs/devlog/parts/vr-r4-wonder.md`)
- **The orrery** (`VrOrrery`, `OrreryRules`): `SpacePanel` makes it under `Vr` when it opens in a headset (`vr_orrery`;
  `Vr.add_child`: it goes on while a game played alone holds still for the map, and goes with the map and the session)
  and then hides the flat map's 17 solar bodies and draws its stars as one `CanvasBatch` (the far worlds, the card and the
  buttons stay). Each body is a node whose scale is its radius, with a `VrGrabbable` (`&"two_hand"`); the 16 spheres are
  one MultiMesh drawn at those nodes every frame (per-instance colour and custom data: the second colour and the bands).
  A held body is `top_level` (the hand's); let go it glides home. `body_taken` → the card (`select`, read aloud);
  `dropped_in_ring` → `SpacePanel.vr_land` (the card button's LAND / HOME, else why not). TRUE SIZE:
  `SpacePanel.true_size_button` → `VrOrrery.set_true_size`.
- **The lenses** (`VrLens`, `LensRules`, `VrLensCloseups`): VR-HANDS' grabber steps `VrLens.keep_in_hand` every frame
  (VR-WONDER's addition): the local player's selected hotbar item is a lens → a `VrLens` (a `VrGrabbable` of kind
  `&"tool"`) under the grabber, given to the pointing hand (`VrGrabber.give`; `take_back` when another item is chosen).
  The zoom is only inside the lens (R7): a SubViewport over the same world with its own camera, its field of view the
  disc's cover from the eyes over the zoom; its meshes on `VrLens.LENS_LAYER` (1 << 16), which that camera never draws.
  The magnifier's close-ups: `LensRules.CLOSEUPS` (block id → picture, name, fact; facts are content: keep them short,
  plain and true, with a check in the rules' test).
- **The Lab bench** (`VrLabBench`, `LabBenchRules`): `LabPanel.vr_step()` (every frame) keeps one under `Vr` while the
  Lab shows float-or-sink or magnets (`LabBenchRules.by_hand`) on its PREDICT, TRY or WHY page, hides that page's 2D
  copies (the sort cards, the 2D scene) and adds a line for the bench. The bench never decides an outcome: a guess is
  `LabPredict.tap`, a drop or the magnet's catch presses the thing's button in the Lab's own `LabThingsView`, so
  `LabTank` / `LabMagnet` (and `test_lab_content.gd`) stay the truth. A new hand-done experiment: its kind in
  `by_hand`, its layout in `LabBenchRules`, its steps through the Lab's own view.
- **A grabbable thing of a panel that closes** is disabled at once (`enabled = false`): a closed thing stays in the tree
  until the frame ends, and a hand could take it in that frame.

### The look: light, sky, haze, water, leaves (the visuals brief, 2026-10-01)

Everything here costs nothing per frame unless it says so; notes, pictures, bench and rulings:
`docs/devlog/parts/visuals.md`.
- **Colours are decoded once, on every renderer.** Godot 4.7's OpenGL decodes a colour picture (`source_color`, every
  material's albedo) itself; never set `albedo_texture_force_srgb` or `to_linear` a sampled colour
  (`tests/unit/test_look_colours.gd` fails on any `force_srgb` in the game).
- **Tonemapping:** ACES at `tonemap_exposure` 0.75 (`world/world.tscn`, every world's and the menu's environment): the
  painted colours at noon (at 1.0 the noon light drew them about twice as bright). The moon's light is 0.55 of the sun's
  (`DayCycle.MOON`) to keep the night moonlit under it.
- **The horizon:** `DayCycle.sky_meets_fog` (every look SkyCycle shows, a world's own palette and space's too): the
  haze and the sky under the horizon take the sky's horizon colour, so the fogged far land melts into the sky with no
  band and no line. A universe's palette `fog` is therefore not the haze any more; its `sky_horizon` is.
- **The haze:** the depth fog starts at `WorldService.FOG_BEGIN` (0.45) of the view and is full at its end (the chunk
  edge hides in it); the day's horizon and haze are a light blue (0.6, 0.78, 0.98).
- **The light:** a low sun is golden (`DayCycle.golden`: under a height of 0.5 its light turns toward 1.0, 0.8, 0.56),
  the twilight orange on the horizon as before.
- **The photo sky (REALISTIC)** takes the fog's colour at dusk and at night: `DayCycle.look().photo_fog` (0.45 at
  sunset, 0.65 at night, 0 by day) goes into `Environment.fog_sky_affect` (SkyCycle; 0 for the painted sky).
- **Water (blocky):** deeper blue at a glancing angle, the sun's glint (roughness 0.35) and a texel-sized shimmer on its
  top (`shaders/water.gdshader`; the shimmer is off with LOW's simpler water).
- **Leaves and plants sway on HIGH** (`world/look/sway.gdshader`, one shader for every page and both styles): page 0's
  leaves and bush, and any page block with extras `"sway": true` (leaves: move whole) or `"cross": true` (plants: the top
  moves, the feet stay). Only HIGH (`GraphicsPreset.sways`, never with Reduce motion): on Vulkan's Mobile renderer any
  custom cut-out shader drew leaves about twice as dear as StandardMaterial3D's cut-out (a cave under a forest: +9-10 ms
  of this PC's GPU; the sway's own vertex work was nothing; OpenGL showed no such cost), so MEDIUM and LOW keep the plain
  cut-out. The choice is made when a library is built: `BlockLibrary.set_sway` (from `WorldService.apply_graphics`)
  returns true on a change and the cached `WorldService.library()` is dropped, so the next world meshed shows it.
  `BlockLibrary.block_material` picks a page block's material; the warm-up draws the sway shader with the blocks
  (FIRST) only while it is on. A new leaf block: give it `"sway": true` (and keep its kind `&"cutout"`).
- **A world's own sunlight:** a descriptor's `sun_light` (`UniverseRegistry.sun_light`, 0.3-1.5, 1 without one; Mars
  0.7, Venus 0.8) scales its day's light (`SkyCycle.sun_light`), never the moon's.
- **The title diorama** stands left of the wordmark, sized for the screen's shape (`TitleDioramaRules.place`).

### Block ids (`data/blocks/block_ids.gd`) and atlas tiles (`world/block_library.gd`)

| id | block | atlas tile(s) [top, side, bottom] | notes |
|---|---|---|---|
| 0 | AIR | — | empty model |
| 1 | GRASS | (0,0) top, (1,0) side, (2,0) bottom | |
| 2 | DIRT | (2,0) | |
| 3 | STONE | (3,0) | y ≥ 0 |
| 4 | SAND | (4,0) | beaches, river banks, sea floor |
| 5 | LOG | (6,0) top/bottom, (5,0) side | |
| 6 | PLANKS | (7,0) | |
| 7 | LEAVES | (0,1) | cutout, transparency 1 |
| 8 | GLASS | (1,1) | cutout, transparency 2 |
| 9 | BRICK | (2,1) | |
| 10 | LIGHT | (3,1) | unshaded "glow" |
| 11 | WATER | (4,1) | alpha, no collision, not solid |
| 12–16 | RED, YELLOW, GREEN, BLUE, PURPLE | (5,1), (6,1), (7,1), (0,2), (1,2) | toy blocks |
| 17 | DEEPSTONE | (2,2) | y < 0 |
| 18 | BEDROCK | (3,2) | world floor −64…−61 (noisy); **not placeable, not breakable** |
| 19 | COAL | (4,2) | ore |
| 20 | IRON | (5,2) | ore |
| 21 | GOLD | (6,2) | ore |
| 22 | DIAMOND | (7,2) | ore |
| 23 | CRYSTAL | (6,3) | glows (unshaded); the wand can bring it alive |
| 24 | BED | (0,4) top, (1,4) side, (2,4) bottom | half height (0.5625, collision too); pillow at the +Z end; sleeping in it makes it your home (M1b Task 10) |
| 25–28 | M2 defenses (Task 8) | placeholders | see `BlockLibrary.TILES` |
| 29 | BUSH | (1,6) top, (0,6) side | cutout, no collision; crouch in it to hide (M2 Task 5) |
| 30 | BARREL | (3,6) top/bottom, (2,6) side | tap within 4 blocks to hide inside (M2 Task 5) |
| 31 | CLOSET | (5,6) top/bottom, (4,6) side | tap within 4 blocks to hide inside (M2 Task 5) |
| 32 | FAKE_WALL | (6,6) | looks like stone (a faint crack); a tap knocks and opens it (M2 Task 16); not in the palette |
| 33 | PRESSURE_PLATE | (7,6) top, (0,7) side, (3,0) bottom | 1/8 high; temple plates, pressed by stepping on them |
| 34 | TROPHY | (2,7) top, (1,7) side | golden trophy: treasure and golden animals only, never in the palette or `/give` |
| 35 | GOLD_LAMP | (3,7) | glows (unshaded): treasure only |
| 36 | JUMP_PAD | (7,1) top, (1,2) side, (3,0) bottom | glows; throws a body up (`PadRules`, M3 Task 6); placeholder tiles until M3 Task 1's pages (then 128–135) |
| 37 | SPEED_PAD | (6,1) top, (0,2) side, (3,0) bottom | glows; a 1.5 s burst of speed the way you were going (`PadRules`); placeholder tiles, as above |
| 80–91 | Frostpeak's blocks (M3 Task 3) | page 2, `FrostBlocks.TILES` | snow, snowy grass, packed snow, ice and blue ice (slippery: `FrostRules`), pine wood and needles (leaves), frozen ore (an ore), snow brick, ice lantern (glows), frosted glass; built only by Frostpeak's secrets: fake packed snow (an igloo's hidden floor, knocks open); none in the Sandbox palette; 92–95 free |
| 64–78 | the desert's blocks (M3 Task 2) | page 1, `DesertBlocks.TILES` | sandstone (plain, cut, carved), red sand, red sandstone, cactus (pushes), dry bush (walk-through), desert glass, palm wood and leaves, pyramid gold (glows), desert lamp (glows); built only by the desert's secrets: arrow slit, trap sand (walk-through, looks like sand), fake sandstone (knocks open); none in the Sandbox palette |
| 176–191 | the Candy Kingdom's blocks (M3 Task 4) | page 8, `CandyBlocks.TILES` | frosting, cake, chocolate, candy cane, lollipop, green and red gumdrops (bouncy to land on), cream, jam, sugar glass, gingerbread, candy lamp (glows), cotton candy (walk-through), sprinkles; built only by its secrets: golden candy (glows), fake chocolate (knocks open); none in the Sandbox palette |
| 224–238 | the Dragon Realm's blocks (owner 39) | page 11, `DragonBlocks.TILES` | sky grass (floatstone under it when broken), floatstone, deep floatstone, crystal spire (glows), mushroom stem and glow cap (glows; the axe fells a giant mushroom), dragon and ember scales, starglass (cutout, transparency index 6), moon lamp (glows), cloud (cutout, walk-through, `NON_SOLID`), dragon nest (twigs: a nest's egg lies on one), floatstone brick; built only by its secrets: dragon gold (glows), fake floatstone (knocks open); none in the Sandbox palette; 239 free |
| 130 | PORTAL_FRAME | page 5: (1,0) top/bottom, (0,0) side | frames a portal's doorway (M3 Task 5, `PortalRules`); Tilly sells 4 for 5 gold |
| 135 | PORTAL_CORE | page 5: (3,0) top/bottom, (2,0) side | glows; one in a frame's bottom row; two whole frames with cores link (`PortalLinks`); Tilly: 30 gold |
| 220 | CRAFTING_TABLE | page 10: (0,6) top, (1,6) side, (2,6) bottom | the **Workbench** (owner #43's name and look); most recipes are made within 4 blocks of one (M3 Task 22, `CraftRules`); 4 planks by hand |
| 221 | FURNACE | page 10: (3,6) top/bottom, (4,6) side | the **Clay Oven** (owner #43); glass, bricks, charcoal; burns coal or a log (M3 Task 22); 8 stone at a table |
| 25 | DOOR | (7,0) top/bottom (planks), (3,4) side | a tap opens the whole stack of doors (a doorway is two); monsters never open, climb or hop over it (M2 Task 8) |
| 26 | DOOR_OPEN | (5,4) | a cut-out frame; walk-through: no `collision_aabbs` **and no mesh collision** (the terrain's physics); made only by opening a door |
| 27 | SPIKE_TRAP | (6,4) top/bottom, (7,4) side | hurts monsters on it or in it 2 a second, never players, bot friends or animals |
| 28 | LANTERN | (4,4) top/bottom, (7,3) side | glows (unshaded); monsters of level ≤ 2 keep 6 blocks away; no night spawns within 8 |
| 192, 193 | BUTTON, BUTTON_ON | page 9: (1,0) / (3,0) top, (0,0) / (2,0) side, (1,3) bottom | a tap presses it: it powers what it touches for 1 s (M3 Task 7); pressed glows |
| 194, 195 | LEVER, LEVER_ON | page 9: (5,0) / (7,0) top, (4,0) / (6,0) side | a tap switches it; on glows |
| 196, 197 | POWERED_DOOR, POWERED_DOOR_OPEN | page 9: (0,1) side; open (1,1) cut out | opens while powered (its doorway of ≤ 3 as one); open: walk-through (kind `pass`: no collision boxes, no mesh collision); monsters never climb a closed one |
| 198, 199 | LAMP, LAMP_ON | page 9: (2,1) / (3,1) | lights while powered (lit glows); `LIGHT` 10 stays always on |
| 200, 201 | LIGHT_SWITCH, LIGHT_SWITCH_ON | page 9: (4,1) / (5,1) side | a lever with a light switch's look |
| 202 | TELEPORT_PAD | page 9: (6,1) top, (7,1) side | glows; the two nearest free pads pair (`TeleportLinks`) |
| 203–205 | START, CHECKPOINT, FINISH | page 9: (0,2)/(1,2), (2,2)/(3,2), (4,2)/(5,2) | Game Blocks (`CourseRules`) |
| 206 | COIN | page 9: (6,2) cut out | walked through (kind `pass`); course score, never gold |
| 207 | BOUNCE | page 9: (7,2) top, (0,3) side | a trampoline: `PadRules.BOUNCE_SPEED` 21 m/s, keeps the run |
| 212–215, 222, 223 | CORE_MEADOWS, CORE_DESERT, CORE_FROST, CORE_CANDY, CORE_DRAGON, CORE_GLOW | page 10: side (0,1)/(2,1)/(4,1)/(6,1)/(4,3)/(7,3) (the Glow Caves': top (6,3)), top the tile after | glow; a universe crystal (items 480-484) placed in a portal frame's core slot: a universe portal (owner #39, `CrystalRules`); breaks into its crystal; not in PLACEABLE |
| 216 | SADDLE | page 10: (0,2) top, (1,2) side and bottom | built into a buddy it makes the buddy rideable (`RideRules`, M3 Task 20a); the palette's MAGIC row, Tilly's HOME (60 gold) |
| 217 | TROPHY_SHELF | page 10: (3,2) top/bottom, (2,2) side (cut out: two see-through openings) | shows the world owner's badges as little trophies (`TrophyRules`, `TrophyShelves`; M3 Task 21b); the palette's SMART page (HOME row), Tilly's HOME (15) |
| 218 | BOOKSHELF | page 10: (5,2) top/bottom, (4,2) side | a tap opens the books on MEMORIES (`BlockInteractor.bookshelf_tapped`); the palette's SMART page (HOME row), Tilly's HOME (10) |
| 256–271 | the wild meadows' blocks (owner #45b) | page 13, `MeadowsBlocks.TILES` | birch wood and leaves, dark wood and leaves (leaves drop nothing), flowers and wheat (two crossed pictures, walk-through: `{"cross": true}`), lily pad (a 1/16-high pad you stand on: `{"height": …}`), mud, stone bricks, mossy bricks, white plaster, roof tiles, hay, sail cloth, glow mushroom (glows), dirt path; built by the wild meadows' generator and places; not in the Sandbox palette's BLOCKS grid (`/give` has them); ids past 255: blocks may use 256–399 (the voxel type channel is 16-bit; `BuildCodec.BLOCK_MAX` and the server's are 399, module 0.2.5) |
| 272–275 | PUMPKIN, JACK_O_LANTERN, SNOWMAN_HEAD, CHEESE (M3 Task 21c) | page 14, `TinyPage.TILES` | the wand wakes a pumpkin (a jack-o-lantern glows) and a snowman's head on snow blocks (`WakeKinds`); the palette's MAGIC row and Tilly's HOME; the cheese is the mouse villages' treasure only (`LootRules.TREASURE_ONLY`); 276–287 free |
| 288–298 | the Moon's blocks (owner #55) | page 15, `MoonBlocks.TILES` | moon dust (the ground, 2 deep), moon rock, deep moon rock (under y 0), moon crystal (glows), moon cheese (the hidden rooms' walls), base panel, porthole (glows), landing pad (glows; the spawn's pad, Tilly sells it), base light (glows); built only by the secrets: star gold (glows; every planet's temples and treasure), fake moon rock (knocks open); none in the Sandbox palette; 299–303 free |
| 304–312 | Planet Boing's blocks (owner #55) | page 16, `BoingBlocks.TILES` | boing moss (bouncy; breaks into soil), boing soil, boing rock, jelly (bouncy: the pools), spring stem and spring cap (bouncy), glow bulb (glows), boing brick; built only by the secrets: fake boing rock; 313–319 free |
| 320–330 | Rainbow Planet's blocks (owner #55) | page 17, `RainbowBlocks.TILES` | prism grass, the six stripes (red, orange, yellow, green, blue, violet: `RainbowBlocks.STRIPES`, 2 high each by height), prism crystal (glows), prism brick, prism lamp (glows); built only by the secrets: fake rainbow (looks and drops like the blue stripe); 331–335 free |
| 336–349 | Mars's blocks (cosmos, spec §21b.2) | page 18, `MarsBlocks.TILES` | Mars dust (red: iron oxide), regolith, basalt, deep basalt (under y 0), layered rock (the river beds, the rock's pale layers), polar ice (the caps, with dust layers inside), dry ice (the south cap's top, frost), gypsum crystal (glows), rover panel, rover wheel, solar panel, gold foil (the old lander), rover light (glows); built only by the secrets: fake basalt (knocks open, drops basalt); 350–351 free |
| 352 | LAB_BENCH (spec §23, the Science Lab) | page 19, `LabPage.TILES`: (0,0) top, (1,0) side, (2,0) bottom | a tap opens the Science Lab (`BlockInteractor.lab_bench_tapped`, `Sandbox.open_lab`); the palette's SMART page (HOME row); crafted at a Workbench (3 planks, 1 glass, 1 iron); some village houses; never painted (`PaintRules.JOBS`); `BlockIds.COUNT` 353; 353–367 free for the Lab |
| 368–380 | Europa's blocks (cosmos, spec §21b.2) | page 20, `EuropaBlocks.TILES` | Europa ice (the white crust), reddish ice (the cracks), stained ice (their ridges), deep ice (blue, white bands every 6: the cliffs, the well), seafloor rock (under y 0; ores), glow ice (glows: the well's rings, the melt hole), sea salt (glows: crystals in the cracks, the plumes' mounds, geodes), geyser vent (glows; a `PadRules` pad: the plume throws a child up), lander panel, melt probe, lander light (glows), ice brick; built only by the secrets: fake deep ice (knocks open, drops deep ice); 381–383 free (352–367, page 19, are the Science Lab's) |
| 512–522 | Titan's blocks (cosmos, spec §21b.2) | page 29, `TitanBlocks.TILES` | Titan soil (orange-brown: the plains), ice pebbles (pale patches), dune grains (dark: the dunes), wet shore (the basins' beaches and beds), icy rock (water ice as hard as stone; ores), shore crystal (glows: the beaches, geodes, the treasure's X), probe shell, parachute (orange and white stripes), probe lamp (glows), station brick; built only by the secrets: fake icy rock (knocks open, drops icy rock); 523–527 free; the first page past the items' 400–511 (`BlockIds.COUNT` 528). Its lakes are WATER shown as methane |
| 544–559 | kept for the colony domes (spec §21c) | page 31 | no block owns them yet: empty models in the voxel library, never placed |
| 656–671 | Venus's cloud city's blocks (cosmos, spec §21b.2) | page 38, `VenusBlocks.TILES` | yellow cloud (the tops far below), deep cloud (under them and under y 0), cloud deck (cream panels, teal rivets), float hull (silvery balloon cloth), sky turf (a garden's), sky bridge (honey planks), cloud lamp (glows), sky frame (white metal: rims, posts, the mast, keels), home panel (peach), blimp skin, blimp stripe (teal, an orange line), gondola (a round window), solar film, cloud crystal (glows: the treasure's X, geodes), telescope (brass); built only by the secrets: fake float hull (knocks open, drops a float hull); the clouds, decks, hulls and turf are the world's ground (`SPACE_GROUND`); `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 672 |
| 704–716 | Pluto's blocks (cosmos, spec §21b.2) | page 41, `PlutoBlocks.TILES` | nitrogen ice (the heart's plain), cell edge ice (its cells' darker edges), water ice (as hard as rock: the bedrock, the mountains, the floating hills), Pluto frost (the uplands' peach-tan frost), tholin dust (the red-brown lands), red ice (water ice stained red: under them, craters), methane snow (the bright side, snowy tops), frost crystal (glows: the treasure's X, geodes, rooms' lights, the bright side), drag balloon (the Balloon Lander's), Charon globe (grey, its red cap), heart beacon (glows pink), frost brick (the lookout's floor, the explorers' station); built only by the secrets: fake water ice (knocks open, drops water ice); the ices, frost, dust and snow are the world's ground (`SPACE_GROUND`); 717–719 free; `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 720 |
| 720–733 | Triton's blocks (cosmos, spec §21b.2) | page 42, `TritonBlocks.TILES` | Triton frost (the bright band's fresh nitrogen frost), pink ice (the south polar cap), mottled ice (its darker patches), geyser dust (the vents' rings and the dark streaks), nitrogen geyser (glows; a `PadRules` pad: a gentle puff up, then the wind's drift north-east), cantaloupe ice (the dimples), ridge ice (the ridges between them), ice lava (the frozen lake's floor and terraces), nitrogen crystal (glows: the treasure's X, geodes, rooms' lights, the cap), nitrogen tank (the Hopper Lander's), Neptune globe (deep blue, its dark spot), blue beacon (glows), cap brick (the lookout's floor, the explorers' station); built only by the secrets: fake pink ice (knocks open, drops pink ice); the frost, ices and dust are the world's ground (`SPACE_GROUND`); under the frost Triton uses Pluto's nitrogen ice and water ice; 734–735 free; `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 736 |
| 688–703 | Saturn's rings' blocks (cosmos, spec §21b.2) | page 40, `RingsBlocks.TILES` | ring ice (clean water ice: the chunks' body), ring frost (their frosty tops), dusty ice (the C ring's and the Cassini Division's), ring rock (rock lumps), moonlet ice (Pan), ridge dust (Pan's ridge), ring crystal (glows: the treasure's X, geodes), station panel (white, a teal trim), station window (round), station lamp (glows), radio dish, power pack (glows: electricity from heat), truss (dark struts), ring beacon (glows teal: the sights), Saturn band (its gold and tan bands: the Saturn model); built only by the secrets: fake ring ice (knocks open, drops ring ice); the ice, frost, dusty ice, rock, moonlet ice and ridge dust are the world's ground (`SPACE_GROUND`); page 39 (672–687) held for another agent's work; `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 704 |
| 576–597 | the world's wonders (owner #78, spec §24) | pages 33–34, `WondersBlocks.TILES`, `TILES_MORE` | limestone (the pyramid's core), casing stone (its white casing), granite (the King's Chamber), marble, marble column (fluted), column top (scrolls), frieze (a key pattern), bronze (the Colossus), ivory and gold leaf (Zeus), ebony (his throne), Babylon brick, glazed brick (blue with a flower), beacon fire (glows), white stone (the Lighthouse, the Mausoleum's podium), paving (the tour's paths), wonder plaque (a tap: the wonder's card and quiz), water screw, olive leaves (cut out); built only by the wonders' secrets: fake limestone, fake marble, fake Babylon brick (knock open, drop their stone); Tilly sells the rest in world 41; 598–607 free for the next tours |
| 608–623 | prospecting's riches (spec §26) | page 35, `ProspectPage.TILES` | found in the ground (DepositRules writes them): gold quartz, gold gravel, copper ore, malachite, banded iron, rusty rock, fern shale, oil seep, rock salt, salt crust (the world's own ground: `CaptureRules.GROUND`, `BotRules.NATURAL`); refined: copper, table salt, crude oil, kerosene (`RefiningRules.ROCKET_FUEL`), plastic; the Refinery (a crafting station: `Recipes.REFINERY`); never painted (`PaintRules.JOB_PAGES`); not in the Sandbox palette (`/give` has them); `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 624 |
| 544–559 | the colony's blocks (spec §21c, owner #77) | page 31, `ColonyBlocks.TILES` | Dome Glass (a clear cut-out with a thin frame; transparency index 7, `{"culls": true}`: no faces between two panes), Colony Panel, Colony Floor, Greenhouse Soil, Grow Lamp (glows pink), Colony Light (glows), Fruit Leaves (cut out, oranges), Water Tank, Ice Melter, Oxygen Maker, Control Screen, Colony Map (these five glow), Airlock Frame, Rocket Hull, Printed Regolith, Colony Table (cut out: its legs); built by the space generator in the Moon's and Mars's colonies (`ColonyLayout`); Tilly sells them all there; the Gold Shop's DECORATIONS shelf sells some into the backpack; not in the Sandbox palette (`/give` has them) |
| 560–573 | the rocket parts and the launch pad (spec §21d) | page 32, `RocketPage.TILES` | Rocket Engine, Space Engine (cut out: bells), Fuel Tank, Nose Cone (cut out), Crew Capsule (cut out: a cone with a window), Service Module, Heat Shield, Landing Legs and Rocket Fins (cut out), Stage Separator, Solar Array, Parachute Pack; Pad Concrete and Pad Stripe (the Launch Site's pad); their numbers and prices in `RocketParts`; the Sandbox palette's SMART page has them as its SPACE row; never painted (`PaintRules.JOB_PAGES`); the wand never wakes the pad; 574–575 free; `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` 576 |
| 384–398 | Io's blocks (cosmos, spec §21b.2) | page 21, `IoBlocks.TILES` | sulphur (yellow: the plains), orange sulphur, sulphur frost (white: frozen sulphur dioxide), red sulphur (the rings round a volcano), Io rock (the rock, with black lava layers every 6; ores), black lava rock (the lakes' shores, the cones, boulders), lava crust (glows: black with glowing cracks, safe ground), hot lava (glows; a `PadRules` pad: a warm bounce, never hurts), volcano vent (glows; a pad: the plume throws a child up), sulphur crystal (glows), heat tile, lander leg, heat camera (glows), sulphur brick; built only by the secrets: fake Io rock (knocks open, drops Io rock); `BlockIds.COUNT` 400 (the items' ids start there); 399 free |
| 33 | PRESSURE_PLATE | (page 0) | since M3 Task 7 also a smart block (the SMART tab, Tilly): powers while stood on; breaks into a plate |
| 210 | ZIPLINE_POST | page 10: (5,0) top/bottom, (4,0) side | M3 Task 14a: the nearest waiting post of the same player (3–48 blocks, a clear line) links (`ZiplineLinks`); a tap rides the line; a pole and wheel are drawn over it; not in PLACEABLE (the ARMORY page's GADGETS column), Tilly: 2 for 15 |
| 211 | LAUNCH_PAD | page 10: (6,0) top, (7,0) side/bottom | M3 Task 14a: glows; a `PadRules` pad at 30 m/s (about 19 blocks); a glider opens by itself at the top; Tilly: 10 |
| 240–255 | PAINTED_WHITE … PAINTED_PINK | page 12: tint t at (t % 8, t / 8), one tile on every face | M3 Task 8: what paint turns a plain block into (`PaintRules`: 16 tints); one shared material for all 16; drops as itself; not in PLACEABLE (the BUILD tab's paints make them) |

- Row 3 holds item icons: wand (0,3), house (1,3), tower (2,3), bridge (3,3), big tree (4,3), rainbow (5,3).
- Row 4 holds the bed: (0,4)–(2,4). A half-height block's side faces show only the bottom 9 rows
  of its side tile.
- Row 5 holds weapon, tool and target icons (M1b Task 11): sword (0,5), bow (1,5), boomerang (2,5),
  hammer (3,5), axe (4,5), pickaxe (5,5), practice dummy (6,5), bullseye (7,5). They are drawn without
  the RNG.
- **Block atlas pages (M3 Task 1):** the atlas above is page 0 (every id below 64). Each later range of 16
  ids gets its own 8 × 8 page (desert 64–79, frost 80–95, candy 176–191, smart and game blocks 192–207,
  portals/pads/lab 208–223, building tools 224–239 (unused so far), paint 240–255), registered by its owner with
  `BlockLibrary.register_page(page, [pixel png, realistic albedo, realistic normal], {id: [top, side,
  bottom, kind?, extras?]})` (kind: `&"opaque"` by default, `&"cutout"` or `&"glow"`; extras (M3 Task 2):
  `{"walk_through": true}`, `{"transparency": n}`). Page 1 (the desert) is registered by `DesertBlocks` and page
  2 (Frostpeak) by `FrostBlocks` and page 8 (the Candy Kingdom, ids 176–191, moved there because 96–111 hold items;
  M3 Task 4) by `CandyBlocks`, page 11 (the Dragon Realm, ids 224–239; owner 39) by `DragonBlocks` and page 13 (the wild
  meadows, ids 256–271; owner #45b) by `MeadowsBlocks` and page 14 (M3 Task 21c, ids 272–287) by `TinyPage` and pages 15-17 (owner #55: the Moon, Planet Boing, Rainbow Planet, ids 288–335) by `MoonBlocks`, `BoingBlocks`, `RainbowBlocks` from `BlockLibrary._static_init`, so they exist before any library is
  built. Blocks may use 256–399 (pages 13–21; the voxel type channel is 16-bit); tests register their own page as page 21
  (ids 384–399, kept for `test_block_pages.gd`: unregistering a real page there would take it from every later test).
  Each page has its own shared
  materials (`BlockLibrary.page_material(page, kind)`, restyled by `set_style` with the rest); icons and
  break particles read the block's page (`tiles_of`, `pixel_atlas_of`). Put a page's files in
  `data/blocks/pages/<name>.png`, `<name>_albedo.png`, `<name>_normal.png` (128² pixel, 2048² realistic,
  the same layout), drawn by the page's own tool like `tools/make_atlas.gd`. The Physics Lab's pads stay
  at ids 36–37 on page 0 (no save migration). Page 5 (portals) is registered by `PortalPage`
  (`data/blocks/portal_page.gd`) at the top of `BlockLibrary.build()`, so every world has it; page 9 (smart
  blocks and Game Blocks, M3 Task 7) likewise by `SmartPage` (`data/blocks/smart_page.gd`); page 12 (the 16 painted
  blocks, M3 Task 8) by `PaintPage` (`data/blocks/paint_page.gd`) both ways. A fourth kind,
  `&"pass"`, is a cut-out block you walk through (no collision boxes and no mesh collision: M2 Task 8's lesson).
- **Block ids and item ids share one int space** (hotbars, bags, `Session` edits, `/give`), and item ids run
  100–172 (tiers at 121–169): a block at an item's id would turn into that item when broken. The page
  ranges of the M3 plan overlap items from 100 on (candy 100–111, so the candy blocks took 176–191; smart blocks 112–127, building tools
  136–143; page 5 has only 130 and 135 free, which the portals use). `test_no_block_takes_an_item_id`
  (`tests/unit/test_portal_blocks.gd`) fails when a block takes an item id. `BlockIds.COUNT` is 331 (owner #55's pages 15-17: 288–330; before, 276 with M3 Task 21c's page 14: 272–275): the universe cores
  212–215 and 222 on page 10 and the Dragon Realm's page 11 (ids 224–238, owner 39), the paint on page 12 (240–255, M3
  Task 8), the wild meadows on page 13 (256–271, owner #45b). **Block ids go past 255:** anything that packs a block id
  must use 16 bits (Build Rewind's `RewindLog` does since 2026-09-25; `BuildCodec.BLOCK_MAX` and the server's
  `BuildRules.BLOCK_MAX` are 399), and a native search of a copied box's bytes must match the id's low byte **and**
  check the next byte is its high byte (`MonsterDirector.find_blocks`, `BotRules.find_in_buffer` since M3 Task 19: a
  village roof, 266 = 0x0A 0x01, was found as a LIGHT block, 10).
- **Page 10's tiles** (ids 208–223, several owners): two tiles per id, tile index 2 × (id − 208) — the portal
  frame (0,0)/(1,0), the core (2,0)/(3,0), the saddle 216 (0,2)/(1,2), the trophy shelf 217 (2,2)/(3,2) and the bookshelf
  218 (4,2)/(5,2) (M3 Task 21b, `PortalPage.BOOK_TILES`). Each owner extends `PortalPage.TILES` and
  draws its tiles after the others' in `tools/make_portal_page.gd` and `.py` (the RNG stays in step, the old
  tiles stay byte-identical). The PNGs are binary: after merging two owners, run both tools again.
- Row 6 (0..5, 6) holds the hiding spots (M2 Task 5), drawn with their own RNG in both styles.
- Row 6–7 (M2 Task 16's tiles): fake wall (6,6), pressure plate top (7,6) and side (0,7), trophy side (1,7) and
  top (2,7), golden lamp (3,7), treasure map icon (4,7). They use their own RNG in both atlas tools.
- Free tiles: (7,3), (3,4)–(7,4) (allocated to Task 8) and (5..7,7).
- Row 4 also holds the defenses (M2 Task 8): door (3,4), lantern top (4,4), open door (5,4), spike trap
  top (6,4) and side (7,4); the lantern's side is (7,3).
- Free tiles: rows 6–7 (allocated: Task 5 (0..5, 6), Task 16 (6..7, 6) and row 7).
- The cars (owner #109) take no block and no item id: item ids 500-511 stay free; a car's ownership is `"car:<kind>"` in
  `ProfileData.bought`, its kind a `CarKinds` name.
- **752–753: XYLOPHONE, DRUM (owner #110, VR round 4)** on page 44, `MusicPage.TILES` (row 0: the xylophone's top (0,0)
  and side (1,0), both blocks' plank bottom (2,0), the bongos' top (3,0) and side (4,0)); solid opaque cubes; a tap plays
  them (`MusicDirector`); the palette's SMART page (HOME row), a Workbench recipe each, never painted
  (`PaintRules.JOBS`); 754–767 kept for more instruments on page 44; `BlockIds.COUNT` 754, `NEXT_PAGE_FIRST_ID` **768**
  (the next page is 45).
- **768–783: the Glow Caves' blocks (universe 6)** on page 45, `GlowBlocks.TILES` (three rows, alpha): cave stone,
  glow moss (glows), shroom stem, blue and rose glowshroom caps (glow), glow-worms (a glowing ceiling), selenite crystal
  (glow: beams, geodes), flowstone, stalactite and stalagmite (crossed pictures that never sway, walked through; the
  stalactite's hang from the cell's top), cave lake stone, fungus planks, spore lamp (glows; a light for the stealth
  eye), cave pearls (glow), cave gold; built only by the secrets: fake cave stone (knocks open, drops cave stone). The
  stone, moss, lake stone and flowstone are the world's ground (`BlockIds.GLOW_GROUND`). Its portal core is **223**
  (`CORE_GLOW`, page 10). `BlockIds.COUNT` 784, `NEXT_PAGE_FIRST_ID` **784** (the next page is 46).
- The Gold Farm (M3 Task 10): item id **491** `ItemIds.FARM` (492–494 kept for the farm); not in `ItemIds.ALL`
  (no palette row, no `/give`), `is_item` knows it; bought from Tilly, placed by `FarmDirector`.
- Gift stamps (M4 Wave 3, agent I): item ids **460–479**, one per slot of the device's `GiftStampBook`
  (`ItemIds.GIFT_STAMP_FIRST`, `is_gift_stamp`); not in `ItemIds.ALL` (never given, sold or listed in
  MAGIC); a hotbar holds them; `Blueprints.local` reads the book; every one shows a gift box.
- Item ids start at 100 (`data/items/item_ids.gd`): WAND 100, stamps 101–105, SWORD 110, BOW 111,
  BOOMERANG 112, HAMMER 113, AXE 114, PICKAXE 115, DUMMY 116, BULLSEYE 117, SPEAR 118, MACE 119 (M2).
  Tiers (M2 Task 6; `WeaponRules.TIERS`, wood → stone → iron → crystal → cosmic): the M1b sword, bow,
  pickaxe and axe and the spear and mace are the wood tier; SWORD_* 121–124, BOW_* 126–129,
  PICKAXE_* 131–134, AXE_* 136–139, SHIELD_WOOD…COSMIC 140–144, SPEAR_* 161–164, MACE_* 166–169.
  Potions 150–152. Their icons come from the item icon atlas (above), not the block atlas.
  STICK 451 (M3 Task 22, crafted only: `ItemIds.CRAFTED`, no palette row, its picture drawn by `CraftIcons`;
  452–459 and 490–499 are free for crafted things; 460–479 are M4 I's gift stamps, 480–489 universe crystals: 480-484
  made (owner #39, `ItemIds.CRYSTALS`, icons drawn by `CrystalIcons`), 485-489 kept for universes 6-10).
  Gadgets 400–407 (M3 Task 14a, `ItemIds.GADGETS`: Glider, Grappling Hook, Quick Wall/Floor/Ramp/Fort,
  Boing Orb, Dance Orb; icons drawn in code by `GadgetIcons`); blasters 415–429 (Task 14b). M3 Task 8: the
  building tools 408–411 (`ItemIds.BUILD_TOOLS`: LINE_TOOL, FILL_TOOL, COPY_TOOL, REWIND; 412–414 stay free) and the 16
  paints 435–450 (`ItemIds.PAINTS`); their icons are drawn in code by `BuildToolIcons`.
  TREASURE_MAP 170 (M2 Task 16, treasure only: in `ItemIds.TREASURES`, no palette row; 171–172 stay
  unused, the decorations are blocks 34–35).
- The secrets' pictures (riddles, plates, the Secret Book) are a separate atlas,
  `data/secrets/pictures.png` (8 × 4 tiles of 16 px, ids in `core/rules/riddles.gd`).

## 6. Conventions

- **Typed GDScript.** Match the surrounding code; comment density is low, and doc comments use `##`.
- **TDD for every rule:** write the test, watch it fail for the right reason (RED), implement, watch it
  pass (GREEN), then run the whole suite. Engine glue is checked through godot-mcp and on the emulator.
- **Owner feedback:** log it in `docs/playtests/owner-feedback.md` as soon as it arrives. Fix it
  test-first, then mark it fixed with the test name or measurement as proof.
- **Documentation lives in the project, not in chat:**
  - Spec: the design.
  - Plan: the tasks.
  - `docs/devlog/`: what happened, the measurements, and every ruling.
  - This file: how to work.
- **Plan rulings:** decisions that deviate from the plan are written down with "cost if wrong", both in
  the git-ignored ledger `.superpowers/sdd/<plan>/progress.md` and in the dev log.
- **Commits:**
  - One logical change per commit.
  - Messages like `feat(world): …`, `fix(buddy): …`, `docs: …`.
  - End with the attribution line `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- **Never merge or push** without the owner saying so. There is no remote.
- **Assets:** CC0 only (Kenney, ambientCG, Poly Haven), each credited in `assets/CREDITS.md`.
  Generated art is made by scripts in `tools/`.
- **Package name** `com.giorgi.game` is a placeholder (see §4).

## 7. Performance budget and how to measure

- **Budget on the emulator** (the acceptance device): ≥ 30 FPS average and no frame over 100 ms,
  during the 60 s play phase and the 2 km flight. M1b adds that this must hold in both graphics styles
  and with animals around.
- **Levers:** view distance, Low/Medium/High presets (Low has no shadows), threaded meshing, one
  texture atlas, no heavy post-processing, capped counts (10 buddies per world; about 20 monsters
  or animals).
- **LOW (M5 Task 3, spec §15.3):** view ≤ 64 blocks (`GraphicsPreset.view_distance`: use it, never
  `settings.view_distance` directly), no shadows, 75 % 3D resolution, half the particles (`Fx.particle_scale`; a new
  particle effect takes its amount through `Fx.scaled`), simpler water (`BlockLibrary.set_simple_water`: realistic
  without wave normals, blocky without its shimmer), no swaying leaves (only HIGH sways: `GraphicsPreset.sways`, the
  visuals brief),
  at most 6 night monsters and 12 animals near each child (`MonsterDirector` / `AnimalDirector.apply_preset`, the host
  phone's preset); the monster cap holds for `/summon` and the MOBS tab too (`MonsterDirector._crowded_on_low`, M5 Task 6
  review; animal summons keep `AnimalRules.SUMMON_CAP`). A phone with under 3.5 GiB of memory or ≤ 4 cores starts on LOW (`GraphicsPreset.for_device`, at
  the first start only). **The emulator counts as weak:** `Pixel_8_API_35` has 4 cores, so a fresh install (or one
  after a data wipe) starts on LOW (no shadows); pick MEDIUM in SETTINGS for measurements that compare with earlier
  ones.
- **Worker tasks a child waits for are high priority** (M5 Task 3): a 4-core phone's pool has one low-priority slot,
  shared with Godot's threaded resource loads and the world's other searches; the tutorial's site search waited 20 s
  there on the emulator. `WorkerThreadPool.add_task(job, true, …)` for them (`TutorialDirector._pick`).
- **Everything at once on the host (M5 Task 3):** `tools/host_bench.gd` starts a new Survivor world of a universe
  (in the wild meadows: at the nearest village, among its villagers), measures a quiet window, then adds 20 of the
  universe's monsters, two pets, a saddled horse ridden in a circle, the Gold Farm and a race, and measures a busy
  window; the monsters and animals are stepped by hand there so their own cost is printed too. A private folder whose
  path contains "smoke" (with a copy of `profile.json`):
  `XDG_DATA_HOME=/tmp/easycraft-bench-smoke godot --headless --max-fps 60 --path . --script res://tools/host_bench.gd -- --universe=2`
  (`--preset=low`, `--without=ride,monsters,farm,pets,race`, `--off=…`: the tool's header; `HOST_BENCH`
  lines). **Compare the main thread's CPU per frame** (`main_thread_cpu_ms_per_frame`, from /proc): on this shared PC
  the frame and physics times are wall times and grow several-fold while the main thread waits for Jolt's and the
  voxel threads, which other programs starve (the per-second line shows it: slow seconds with the same CPU).
- **Shader compiles in a browser (M7; `docs/devlog/parts/m7-shader-warmup.md`):** `tools/web_shader_probe.py` serves
  a web export on a free port (the thread headers), opens it in headless Chrome (its own profile and DevTools port) and,
  before the page's scripts, wraps WebGL2's `compileShader` / `linkProgram` / `getProgramParameter` /
  `getShaderParameter` / `getParameter` and `requestAnimationFrame`. The game plays the phases itself (the developer arg
  `--shader-probe=<phases>`, `tools/shader_probe_steps.gd`, added by `scenes/main.gd`: `new`, `continue`, `play`,
  `creatures`, `features`, `universes`, `moon`, `realistic`; `PROBE phase=<name>` lines mark them), and the tool prints
  per phase the programs linked, the time waited for them, the frames, the long frames (over 100 ms) and the shaders'
  share of those, then each phase's programs by signature (Godot's shader kind, its `#define`s, the material's
  uniforms). `~/src/cdpenv/bin/python tools/web_shader_probe.py build/web --phases new,play,creatures,moon,realistic
  --continue [--no-warmup] [--style realistic] [--json out.json]` (`--continue` reloads and CONTINUEs the saved world;
  `--no-warmup` gives the game `--no-shader-warmup`: the same build without its warm-up, a before; `--style realistic`
  starts as a REALISTIC child; `--warmup` gives `--shader-warmup`: the warm-up where `PlatformRules.shader_warmup` is
  off; `--warmup-log` gives `--shader-warmup-log`: one draw a frame, each printed, so programs can be told apart by
  draw; `--menu-seconds 2` a child who taps at once, 12 by default). It also prints what the loading page said after
  PLAY (its label and bar, with times) and the `WARMUP` lines. Headless Chrome draws with SwiftShader: compare the COUNT
  of programs per phase, not the times (a phone links a program in 100-500 ms, SwiftShader in 5-15; the emulator's
  Chrome ~200). A run takes 15-20 min. **GUT gotcha:** never `wait_for_signal` on a `ShaderWarmup` (the signal watcher
  records every `node_drawn` with its node; a test file hung after such a test): poll `RUNNING` instead
  (`test_shader_warmup_menu.gd`'s `_until_finished`).
- **The warm-up's census (`data/shader_warmup.json`):** every way the game draws something besides the blocks,
  written by playing a session on the desktop with the browser's renderer settings (a new world replaces the Sandbox
  slot: a private folder with a copy of `profile.json`): `XDG_DATA_HOME=/tmp/easycraft-census godot --headless
  --rendering-method gl_compatibility --path . -- --shader-probe=new,play,creatures,features,survivor,universes,moon,mars,europa,io,titan,mercury,venus,rings,pluto,triton,boing,rainbow,wonders,newseven,continue,realistic
  --shader-census=res://data/shader_warmup.json --shader-warmup` (about 25 minutes; it quits when done;
  `--shader-warmup` so the session skips the spawn prewarms as a browser does), **then** `godot --headless
  --rendering-method gl_compatibility --path . --script res://tools/flight_census.gd` (the rocket flight's draws,
  phase `flight`). Each draw has `phases` (where it was in the tree), `shown` (where a node drawing it was visible
  within `ShaderWarmup.SHOWN_RADIUS`, 48 m, of the camera, or under the sky's bodies, `ShaderWarmup.SKY`, however far;
  sampled every 0.5 s) and `at`; the world's prewarms are drawn once in a phase of their own, `prewarm`, so what only
  they draw (the desert portal's window) stays in the census. **Every world's landing has a phase named after the
  world** (`ShaderWarmup.world_phases`: `desert` … `dragon`, `moon`, `mars` … `venus`, `rings`, `pluto`, `triton`, `boing`, `rainbow`, `wonders`;
  a new Sandbox and a new Survivor world of it, standing, then once round the landing at 30 m; `newseven` is world 41's
  second square); the way between worlds (the world left behind, the loading, the rocket flight) is the phase `travel`.
  `ShaderWarmup.tier` reads it: FIRST (shown in `menu`), WORLD (shown in `new`, `continue` or `survivor`, the player's
  feedback on blocks, and for the REALISTIC pass what `realistic` showed), SOON (shown in `play`, or there hidden in
  the first world), LATER; `ShaderWarmup.world_part` reads a world's own phase when its loading card comes up (§5).
  **Run it again after adding anything that draws with a new kind
  of material** (a new shader, other material settings, a new Label3D/Sprite3D setting, particles):
  `test_shader_warmup_sources.gd` fails for a new script that makes one until it is listed there, and its known makers
  must be in the census.
- **Long frames, one by one (M7, the browser's freezes; `docs/devlog/parts/m7-freezes.md`):** `tools/frame_probe.gd`
  plays a session headless — the menu, a NEW WORLD, 60 s walking, cruising over new land, flying up to space, the Moon
  trip, SAVE AND QUIT and CONTINUE, a Survivor NEW WORLD — and prints every frame over `--over=<ms>` with what it spent
  its time on (`tools/frame_blame.gd`: each processing node gets its own priority and a marker after it, so a frame is
  split into physics scripts, the physics engine, process scripts per node and the rest; the frame's start into
  coroutines and deferred calls; what was built in it, per panel), then a summary per phase (frames, worst, how many
  over 16/33/50/100/200 ms). Private folder with a copy of `profile.json` (restore it between runs: a run changes it):
  `XDG_DATA_HOME=/tmp/easycraft-freeze-smoke godot --headless --path . --script res://tools/frame_probe.gd -- --over=10 --voxel-threads=2`
  (`--phases=new,walk,cruise,fly,trip,continue,survivor`, `--no-blame`, `--menu-seconds=`; `--max-fps 60` before
  `--path` for runs that compare with the 60 FPS cap). **The autopilot's worlds** (the frame spikes, 2026-09-30,
  `docs/devlog/parts/frame-spikes.md`): `--phases=moon-pilot` (also `mars-pilot`, `venus-pilot`, `wonders-pilot`) plays
  what the lead's developer menu does (WORLD, AUTOPILOT BLOCKY: a new Survivor world there, `tools/autopilot.gd`'s 60 s
  play and 2 km flight) with each long frame's autopilot t and distance flown; `wonders-road` walks world 41's Wonders
  Road and flies round the New Seven. `--cpu` adds each long frame's main-thread CPU and run-queue time
  (`/proc/thread-self/schedstat`: on this shared PC a long wall time with little CPU is other programs, not the game).
  `--sights` (`tools/first_sights.gd`) prints every draw the camera sees for the first time with its census tier and
  whether a quick child's warm-up had it ready (a summary per phase; run it with `--rendering-method gl_compatibility`
  before `--path`, as the census). The blame also lists the nodes that left the tree in a long frame (`gone`). **Always pass `--voxel-threads=2`** (a phone's browser gets a
  quarter of its cores; 4 is an 8-core phone's app): with this PC's default 12, the main thread's calls into engine
  methods slow down 10-50x while the terrain generates, which no phone sees. Leave out `--max-fps` to see frames of
  10-16 ms (a 60 FPS cap sleeps them up to 16.6). Phones run this logic 3-5x slower than this desktop, a browser slower
  still; the browser's multi-second stalls when something is first drawn are shader compiles, which a headless run
  cannot see (the lead's CPU profile, `docs/devlog/2026-09-27-m7-web.md` 06:00-06:35).
  `tools/frame_trip.gd` (the lead's first tool, the Moon trip only) still works.
- **Heavy one-time work never goes in a world switch's frame (M7):** a hidden panel builds its content the first time
  it opens (`build_later`, like the HUD's `BlockPalette` and `SecretBook`: `_ready` sets up the root, `_build()` runs
  once from `open`/`show_page`/whatever reads the content; built alone, as in the tests, it builds at once), a search
  over the terrain's rules runs on a worker (`TheaterDirector.search_later`) or a few areas a tick
  (`AnimalDirector.NEW_AREAS_PER_TICK`), and files a later moment will need load in the background
  (`UniverseRegistry.warm_space`, `ResourceLoader.load_threaded_request`, claimed with `load_threaded_get`).
- **The ambient life's cost (owner #94, `docs/devlog/parts/animations.md` §4):** `tools/life_bench.gd` starts a new
  Sandbox world in Green Meadows and measures four windows, the life on and off by turns, by day (birds) and at night
  (fireflies): `XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --max-fps 60 --path . --script
  res://tools/life_bench.gd -- --voxel-threads=2` (a private folder with a copy of `profile.json`; `--window=`,
  `--smoke-seed=`), `LIFE_BENCH` lines with the main thread's CPU per frame. 2026-09-30: 0.0-0.15 ms a frame here. The
  developer arg `--no-ambient-life` leaves the life out of a world (a before for any other tool).
- **Startup (M5 Task 3):** the menu prints `MENU ready_ms=<ms since the engine started>` once per run (logcat on the
  emulator); `godot --headless --path . -- --startup-probe` also prints the first frame and quits. Most of the start
  is GDScript compiling the ~400 scripts (about 80,000 lines) the autoloads and the menu reach: see the notes before
  adding anything heavy to an autoload's `_ready` or a `const ... = preload(...)` in a class the autoloads name.
- **APK size (M5 Task 3):** `python3 tools/apk_size.py build/android/EasyCraft-phone.apk` breaks an APK or a bundle
  down; with `--bundletool=<bundletool-all.jar>` a bundle also gets Play's download size and the size its APKs take
  on a phone. Numbers of every release: `docs/devlog/parts/m5-task-3.md`.
- **Measuring live in the editor:**
  1. Run the game with godot-mcp.
  2. Attach a probe `Node` under the exec `holder`. Its script records per-frame delta and the max/average
     of `Performance.TIME_PROCESS` and `TIME_PHYSICS_PROCESS`, plus node count and draw calls.
  3. Let the game run in real time (thawed), then read the probe back with exec.

  FPS numbers taken while game time is frozen or stepped are meaningless.
- **Measured so far:**

  | Run | Result |
  |---|---|
  | M1, emulator | Play 54.6 FPS (worst 38 ms); flight 57.5 FPS (worst 78.9 ms); spawn 0.3–0.8 s |
  | M1b on Jolt, desktop editor autopilot | Play 59.6 FPS (worst 30.6 ms); flight 59.8 FPS (worst 51.4 ms); 0 frames > 100 ms |

  | M1b preview, emulator, blocky, calm host (load about 5) | Play 59.9 FPS (worst 32.9 ms, 0 over 100 ms); flight 59.6 FPS (3 frames over 100 ms, to re-check) |

  Owner feedback #9 numbers are in the dev log.
- **This PC is shared.** The other app's Gradle builds, bots, emulators and agents all run here.
  Record `uptime` (the load average) with every measurement, and never leave a desktop game running
  while measuring the emulator. One contaminated run showed 28 FPS where a calm run showed 60.
- **Streaming:** the player's VoxelViewer streams a box that starts 24 blocks below the feet and
  reaches upwards (`GraphicsPreset.vertical_range`), so caves far below a surface player are never
  generated. While a spawn is pending, the viewer is anchored at the ground the spawn waits for.
- **Phones are 3–5× slower than this desktop CPU.** Anything that costs more than a few ms per frame
  here must be measured again on the emulator or a real device.
- **VR on the Quest (P5, `docs/devlog/parts/vr-perf.md`).** The budget (Quest 2, the floor, 72 Hz): ≤ 100 draws a frame
  (≤ 150 at the heaviest landings, logged), ≤ 750K triangles, GPU ≤ 11 ms, main thread ≤ 9 ms, no frame over 28 ms after
  the spawn fade; a Quest 3 with `vr_plus` at 90 Hz: < 200 draws, 1.5M triangles. **Measure with `tools/vr_bench.gd`**
  (§4 "The bench"; every world: `--world=<n>`, 20 s with four snap turns, `--blame` for where the draws come from,
  `--long --voxel-threads=4` for the long frames, `--walk=40`, `--cruise=60`), and on the headset from logcat:
  `adb logcat -s godot:V | grep VR_BENCH` (the device line names the model, the preset and the refresh rate; a line every
  10 s). **Count draws, not this PC's times:** the draws and primitives are the renderer's own; frame times here are a
  shared i9 and an Intel iGPU (record `uptime`), and a long frame counts as the game's only with ≥ 28 ms of main-thread CPU
  (`--long` prints it beside the run-queue wait). **What the draws are in a headset:** the scene's (`draws_3d`) and the HUD's
  canvas (`draws_2d`: the tray's texture is drawn every frame; every polygon, circle and line drawn in code is a draw of its
  own, so a HUD picture must draw through `CanvasBatch` in a session, as the hearts, the buttons' symbols, the hotbar's
  frames, the coin, the stealth eye and the read-aloud speaker do). **Measured 2026-10-16** (the desktop preview, the
  `vr` preset, draws a frame before → after P5, the most in brackets): Green Meadows 165 → 103 (105); Desert 158 → 89
  (101); Frostpeak 160 → 98 (126); Candy 157 → 86 (107); Dragon 162 → 90 (107); Moon 173 → 82 (92); Boing 155 → 69
  (106); Rainbow 157 → 71 (85); Mars 172 → 75 (94); Europa 170 → 74 (85); Io 171 → 87 (97); Titan 168 → 77 (83); Mercury
  168 → 72 (77); Venus 174 → 86 (105); Rings 175 → 80 (89); Pluto 168 → 77 (86); Triton 169 → 72 (79); Ganymede 169 → 71
  (80); world 41 179 → 89 (93); the Launch Site 163 → 100 (115); a FLY cruise 139 → 38 (69). `vr_plus` (REALISTIC, the
  Quest's 2048 shadow map): Green Meadows 173 (188), the Moon 115 (142), world 41 135 (138). Long frames standing: none of
  the game's own; walking 40 s: a few of 32-38 ms (the voxel engine applying 16-cube blocks).

## 8. Known gotchas (learned the hard way)

- **Box meshes built by hand must wind clockwise seen from outside (2026-10-18):** Godot's front faces are clockwise;
  BlockyAnimal wound its faces the other way, so every animal, golem and the hub tree's stones were lit from inside
  for weeks (the outline looked right, the light did not). `tests/unit/test_mesh_winding.gd` compares a mesh's
  triangles with Godot's own `BoxMesh`; add every new hand-built mesh to it.
- **A headless renderer keeps no MultiMesh data (2026-10-18, Balance Altar B1):** tests cannot read instance
  transforms or colours back from a `MultiMesh` under `--headless`; test the data you put in (your own arrays) instead.
- **A `python3` that refuses to run (2026-10-16):** a Claude Code plugin (modern-python) can put a `python3` shim first on
  the agent shell's PATH that prints "Use `uv run python3 ...` instead" and exits. `tools/export_web.sh`,
  `tools/export_web_vr.sh`, `tools/deploy_web*.sh` and `tools/reel_render.sh` call `python3` directly and fail with it
  (the export then says "no web export"). Run them with the shim left out:
  `PATH=$(echo "$PATH" | tr ':' '\n' | grep -v modern-python/hooks/shims | paste -sd: -) tools/export_web.sh`; or call
  `/usr/bin/python3` in ad hoc commands. `tests/run_tests.sh` drops any `/hooks/shims` entry from its own PATH (some
  tests run `python3 tools/...`, e.g. `test_assets_pack_load.gd`, which failed through the shim).

**Godot and rendering**

| Gotcha | What to do |
|---|---|
| Godot 4.7's OpenGL/Compatibility renderer decodes a colour picture (`source_color`, every material's albedo) itself, like Vulkan; the M1b fix that forced a second decode there (`albedo_texture_force_srgb`, a `to_linear` in a shader) made every colour on the web, the emulator and an OpenGL phone darker and louder (neon grass, near-black leaves, a dark REALISTIC world; measured: the grass's red/green 0.23-0.27 there, 0.43 on Vulkan, the tile's own 0.47) | Never force the decode; `tests/unit/test_look_colours.gd` fails on any `force_srgb` in the game (the visuals brief, `docs/devlog/parts/visuals.md`) |
| In a browser the first sight of a material froze the game for seconds (a new world 5-12 s on the emulator, the first animal, lantern light or effect later): WebGL links the shader on the main thread, Godot compiles 4 variants of each new material shader at once plus one per way it is lit, and the official web templates link synchronously | `ShaderWarmup` draws everything once before `MENU ready` (§5 "The shader warm-up"); after adding content that draws with a new kind of material, run the census again (§7) |
| A `StandardMaterial3D`'s shader is freed when no material with its settings is left: after a REALISTIC visit every BLOCKY block shader compiled again | Keep a material with those settings alive (`BlockLibrary.warmup_materials` returns keeper twins in both styles; `ShaderWarmup.kept()`) |
| A `MultiMeshInstance3D` added for a single frame drew nothing (culled: the MultiMesh's box is only worked out as it is drawn), so its instanced shader never compiled | Give it a `custom_aabb` (`ShaderWarmup._node_for`) |
| GUT hung between tests when a test awaited the `finished` signal of two nodes that `queue_free` themselves as they emit it | Emit, then free a couple of frames later (`ShaderWarmup.LINGER_FRAMES`) |
| `set_anchors_preset` left HUD controls at size 0 | Use `set_anchors_and_offsets_preset` |
| Godot 4's canvas renderer batches only rects and text of one texture: every `draw_colored_polygon`, `draw_circle`, `draw_polyline` / `draw_arc` (an antialiased line is a polygon with a feather) is a draw call of its own. In VR the HUD's canvas is a texture drawn every frame: the hearts row alone was 60 of the Sandbox's 165 draws (P5) | A picture drawn in code that a headset shows every frame goes through `CanvasBatch` in a session (`GraphicsPreset.vr_session`): one `canvas_item_add_triangle_array` (`docs/devlog/parts/vr-perf.md`) |
| VoxelTerrain's 32-cube mesh blocks have a third of the draws, but each block's collision shape is built on the main thread in one go (Jolt's triangle-mesh tree): a 30-50 ms frame on this desktop for every block streaming in, more on a Quest; `voxel/threads/main/time_budget_ms` does not split one task | Keep Voxel Tools' 16 (P5's ruling 1); a physics server on its own thread moves the builds off the main thread but refuses `direct_space_state` outside `_physics_process` ("Space state is inaccessible right now": the taps' rays) |
| A window on a locked or hidden Wayland screen is drawn about once a second (agents' benches: frame times and the first seconds' draws meaningless) | `--display-driver x11 --disable-vsync` before `--path` (Xwayland presents; no V-Sync wait) |
| The desktop's directional shadow map is 4096 with a soft filter; an Android (the Quest APK) gets Godot's `.mobile` 2048 and hard edges: a desktop bench of shadows costs 10 ms more GPU than the headset's setting | The VR bench sets the `.mobile` values when it plays the Quest's platform (`tools/vr_bench_steps.gd`) |
| A GDScript lambda that assigns to a local of the function around it changes only its own copy (owner #99's net test waited for a code that never arrived) | Share state through a Dictionary or an Array (`got.code = ...`), or a member variable |
| A `func _set(...)` of your own in a Control script fails to parse ("The function signature doesn't match the parent": it is `Object._set(property, value)`) | Name it something else (`_set_page`) |
| Two scripts with the same `class_name` (Success S3's first `ShopPage`; the grown-ups' SHOP page has it): the global name goes to either script by the class cache's order, so a run may pass and the next fail with "Too many arguments for "new()" call. Expected at most 0", "Cannot find member ... in base" and the profile autoload failing to compile, and nothing names the real cause | Check a new name first (`grep -rhoE "^class_name [A-Za-z0-9_]+" --include='*.gd' --exclude-dir=.godot --exclude-dir=addons . \| sort \| uniq -d`); `test_no_class_name_is_used_twice` (test_success_s3_experiences.gd) fails on any duplicate |
| A script loaded by the profile's chain (ProfileData, LifeData, SuccessData...) that calls rules or screens, or a `const` made from another class's constant (`const X := EarnRules.ANSWER_GOLD`), can fail to compile in the autoloads' cyclic order | Keep saved data a leaf (S3: SuccessData holds the shop's limits, SuccessShop reads them); write a constant as its number and test the equality |
| A test awaited GUT's `wait_frames(3)` and a node's `_process` had not run once (owner #90: `Engine.get_process_frames()` was still 1): `wait_frames` counts physics steps, and several run inside one drawn frame at the start | Await `get_tree().process_frame` (or GUT's `wait_process_frames`) when a node's `_process` must have run |
| A Godot 4.7 project's `ui_accept` and `ui_cancel` have no joypad buttons (only keys); the D-pad and the left stick are in `ui_up/down/left/right` | Cross / A is added to `ui_accept` by `tools/setup_input_map.gd`; Circle / B is PadFocus's own (§5 "Game controllers") |
| `DisplayServer.is_touchscreen_available()` is true on desktop, and in every desktop browser too (`input_devices/pointing/emulate_touch_from_mouse` is on) | Use `PlatformRules.touch_ui(PlatformRules.current())` (M7: the phone game, phone browsers, a browser's finger pointer, or `--touch`) |
| In a browser, a world's block edits were gone after a reload: `VoxelStreamSQLite` writes `user://` without the `FileAccess` close that makes Godot copy it to IndexedDB (the lead's check, 2026-09-27) | World saves go through `WorldService.save` / `save_and_wait`, which write the `WebStorage` stamp once the blocks are written (M7 Task 5) |
| A touch also emits an emulated mouse click, so the palette opened and closed at once | Open on release; the palette is a full-screen overlay that eats taps |
| Script members named `_set` or `_get` collide with Object virtuals | Rename them (e.g. `_store`, `_block_at`) |
| A static func named like a `Script` method (`is_tool`) is shadowed when called on the class: `ShopRules.is_tool(id)` ran `Script.is_tool()` ("Expected 0 arguments"); `BlasterRules.reload(id)` ran `Script.reload()` and quietly returned 0 (M3 Task 14b) | Pick another name (`is_tool_item`, `reload_time`) |
| `PackedStringArray` has no `any` or `filter` | Wrap it in `Array(...)` |
| A local `const X := OtherClass.CONST` is "not a constant expression" | Use a local `var` or the class constant directly |
| The editor may rewrite `project.godot` on restart (sections reordered) | Re-read it with `git diff` after a restart; run godot-mcp `check_stale` after disk edits and restart for autoload or input-map changes |
| `Input.is_action_pressed` ignores GUI focus: typing W into a LineEdit still walks the player | `ChatPanel` takes every non-`ui_*` action's events out of the Input Map while the chat bar is open and puts them back on close |
| HUD pieces added after the chat panel (`move_child(x, palette.get_index())`) were drawn over the open chat bar: on phones the typed words vanished under a game's round line and the Brave badge (owner #49) | While open, `ChatPanel` moves itself to the end of the HUD and back between its neighbours on close (`_raise`); a label that must stay under the closed lines goes to `chat.get_index()` (the hearts, the eye, the game clock) |
| Android's keyboard does not resize or pan the game (edge-to-edge, `IME_FLAG_NO_EXTRACT_UI`): it covers about the bottom half of a landscape screen | Read `DisplayServer.virtual_keyboard_get_height()` (screen pixels; scale by canvas height / window height) and keep what the child needs above it (`ChatPanel.keyboard_top`). Guard it with `DisplayServer.has_feature(FEATURE_VIRTUAL_KEYBOARD)`: elsewhere (headless, desktop) it logs "Virtual keyboard not supported" every call |
| The engine's built-in font (Open Sans) has no Georgian; letters then depend on the automatic system-font lookup, which on Android 4.7.2 reads only `/system/etc/fonts.xml` (deprecated in Android 15) | `UiKit.add_script_fallbacks` (run by `UiKit.theme()`) adds the device's own font (found through `OS.get_system_font_path_for_text`, else Android's file names) to `ThemeDB.fallback_font.fallbacks`; never bundle a font (CC0 only) |
| An autowrap `Label`'s height depends on its width, so a container only knows it a frame later | To measure before showing, set the label's `size.x` and read `get_minimum_size().y` (`ChatPanel._fitting`) |
| Paused nodes never hear a finger lifted during the pause menu, so touch actions stay pressed after RESUME | Let go on `NOTIFICATION_PAUSED` (`TouchButton`, `LookBuildArea`, `Hud`). `VirtualJoystick` has no reset method: send it `NOTIFICATION_RESIZED` |
| Testing touch controls headless | Put the HUD in its own `SubViewport` and `push_input` screen touches into it (`test_touch_pause.gd`) |
| A `SkeletonModifier3D`'s poses are restored after each skeleton update, so `get_bone_pose*()` reads the clip's pose, not the modifier's | Measure a modifier through a `BoneAttachment3D` (the avatar's `hand()`), which follows the modified pose |
| Godot 4.7's `TabContainer` wraps its tab bar in an internal `HBoxContainer`, and `find_children` also finds internal nodes, so tests that count a panel's rows broke | The palette uses a plain `TabBar` and shows/hides its pages itself (M2 Task 6) |
| Reading a texture's pixels at run time (`Texture2D.get_image`) downloads it from the GPU and is not reliable on every renderer | Import the PNG as an **Image** (`importer="image"`): `preload` returns an `Image` (the item icon atlas) |
| Packed arrays are values: `(d.v as PackedVector3Array).append(x)` (or a packed array passed to a function) appends to a copy; an `ArrayMesh` built that way came out empty | Gather into plain `Array`s and convert once (`PackedVector3Array(arr)`) (`AvatarParts.part_mesh`) |
| An imported PNG whose alpha channel is data (a mask) had the colour of every alpha-0 pixel rewritten | Import with `process/fix_alpha_border=false` (the avatar region masks) |
| A synced float the host lowers a little every tick (a pet's heart) either sends a change every tick or, once quantised, never moves at all (the small step rounds back) (M3 Task 11) | Keep the exact value on the host and sync only its step (`Animal._heart` → `happiness`, `PetRules.synced`) |
| Setting `size` on a Control whose anchors are full-rect after `_ready` is an engine error ("Unexpected Errors" in GUT) (M3 Task 11) | Leave the size to the anchors; compute a panel's place for a given screen from its constants (`PetPanel.card_rect`) |
| `x == true` is a runtime error when `x` is a String or a number ("Invalid operands 'String' and 'bool' in operator '=='"): a hand-edited save broke the parse (M3 Task 12) | Check the type first: `v is bool and v` (`ProgressData._bool`) |
| `JSON.parse_string` logs an engine error for bad input, which fails a GUT test | Parse untrusted text with `JSON.new().parse()` (`AvatarLook.from_code`, `ProfileData.from_json`) |
| A subclass calling `apply_look` in its `_ready` before `super()` dressed the blocky body before its boxes existed ("Invalid access to property or key 'Head'") (owner #48, bots) | Set `_look` and `_look_applied` before `super()`; the base `_ready` dresses it |
| A fit test that checks only the editor's rect passed while its `PanelContainer` (29 px padding each side) ran off a 720 px screen (owner #48) | Check the parent panel's rect, with a margin (`test_the_editor_still_fits_the_phone_screen_after_girl`) || `Viewport.push_input(event)` treats positions as window coordinates and converts them by the stretch transform | Tests with viewport coordinates call `push_input(event, true)` |
| Nodes a test removed with `queue_free()` count as GUT orphans until the frame ends | Free plain nodes nothing refers to at once (`free()`): avatar parts, trails, editor tiles |
| The Kenney head is deeper than a blocky head and its eyes sit lower under the hair | Realistic face pieces use their own `face_anchor`; helmets fit bigger (`RealisticAvatar._fit_cover`); check with `tools/avatar_gallery.gd` |
| Hats built on the blocky head float above the realistic one; box letters read backwards from the front (owner #36) | Give the hat `"real_offset": REAL_HAT_DROP`; lay text out mirrored in X (the avatar faces -Z, so its +X is the viewer's left); check with `tools/costume_shots.gd` |
| `LookBuildArea` reads touches in `_input`, before any GUI control: a tap on a new overlay's button also placed a block | Register the overlay's controls in `hud.look_area.blockers` (the Theater panel's `blockers()`) |
| `TouchButton`s read touches in `_input` too, so a GUI panel over a HUD button does not stop it: a tap on the panel presses both (on a 16:9 phone the Theater's side columns reached BOOK and WALK, M2 Task 17) | Keep HUD buttons out from under overlays (`test_hud_layout.gd`) or hide them while the overlay shows (`Hud.set_theater_open`; since M5 Task 1 it also hides any thumb button under the panel's buttons at BIG, BIGGER and for the left hand); a touch overlay that must win sits after the buttons in the tree and takes presses in `_input` (`MorePanel`, `EmoteWheel`). Check a new overlay at every button size and both hands |
| An overlay opened on a button's touch-down then hears that finger's lift: the emote wheel closed the moment the finger left the glass (M2 Task 17) | Ignore, and leave unhandled, the lift of a finger the overlay did not see go down (`EmoteWheel`); `MorePanel` only takes presses |
| A 2400 × 1080 window does not fit a 1920 × 1080 monitor: a windowed tool got 1920 × 1080 (a 16:9 canvas) | For the emulator's 20:9 canvas use a 1600 × 720 window (`tools/hud_shots.gd`); headless tests can set 2400 × 1080 (`test_hud_layout.gd`) |
| Android's Back reaches the game as `NOTIFICATION_WM_GO_BACK_REQUEST`, sent to every node (root first, then children in order), not as `ui_cancel` (Escape only here): MOVE BUTTONS (its own CanvasLayer) never heard it, and the sandbox's Back chain closed the pause menu under it (M5 Task 6) | An overlay on its own layer handles the notification itself **and** the owners' Back handlers ask it first (`HudEditor.close_open()` at the top of `Sandbox.go_back` and `Menu._notification`); close such an overlay when the panel that opened it leaves the tree |
| The pause menu is on the world's CanvasLayer (layer 1): an overlay on a higher layer that takes touches (the loading card, 88) hid it, and a paused game never ends a load, so Back during a load looked stuck (M5 Task 6) | A high overlay steps aside while the tree is paused (`NOTIFICATION_PAUSED` / `UNPAUSED`: `LoadingCard`) |
| A native Android view (the Theater's WebView) draws over the whole Godot surface, menus included | Hide it whenever a menu covers the middle (`TheaterPanel.set_covered`, polled by `TheaterDirector`) |
| Screen pixels for a native view | `get_viewport().get_final_transform() * control.get_global_transform_with_canvas()`; `get_screen_transform()` adds the window's position on the monitor |
| Android v2 plugins (`_get_android_libraries`) are silently left out of non-Gradle exports | Only the `Android Theater` preset uses Gradle so far (§4); the game's Gradle template only picks up `*.aar` at the top of `addons/`, so plugin AARs in subfolders are only added through the export plugin |
| A non-Gradle Android export stores every `.ctex` raw (Godot's no-compress list) and a phone keeps an APK as it is: a texture's empty half costs its full VRAM size. The realistic pages' empty rows were 80 of the phone APK's 193 MB; the Play bundle deflates them (so its download hid it), but Play installs them raw again (M5 Task 3) | Keep a texture to what it draws (`make_realistic_atlas.save_page` crops a page's empty rows); check an APK with `tools/apk_size.py` |
| Every picture outside a `.gdignore` folder is imported, and `all_resources` exports it: the dev log's and the store's JPEGs were 16 MB of every APK (M5 Task 3) | `docs/` is a `.gdignore` folder (`test_export_size.gd`); pictures that are not the game's go there |

**Voxel Tools**

| Gotcha | What to do |
|---|---|
| Only edited chunks are saved (`VoxelStreamSQLite` keeps no generator output): a changed generator changes the untouched land of every saved world, and its edited chunks then meet new land at a seam (owner #45b) | Never change a shipped generator's output; give the new terrain a version (`WorldMeta.terrain`) that only new worlds get |
| `WorldService.terrain()` is a method (the `VoxelTerrain`): a field named `terrain` on it fails to parse, and every script using `WorldService` fails after it (owner #45b) | The terrain version is `WorldService.terrain_version` |
| Knowing when a chunk comes into another player's view (M4 A) | A script extending `VoxelTerrain` gets `_on_data_block_entered(info)` when `block_enter_notification_enabled` is on and a `VoxelViewer` has `requires_data_block_notifications` and a network peer id; `info.are_voxels_edited()` is true for chunks edited this session or loaded from the save. `block_loaded(position)` fires for generated chunks too. **A viewer taken out and put back in the same frame is not notified again** (the net test's rejoin got no edits, M4 A2): remember what came into view (`WorldSync._seen`) |
| `VoxelGenerator.generate_block` of one surface chunk on the main thread: 6–9 ms on this PC at load 30 (phones 3–5× more) | Keep it off the main thread: the host's diffs run in `WorkerThreadPool` tasks (`ChunkDiffer`, M4 A2); `VoxelTool.copy` from a worker thread is fine (Voxel Tools locks its data) |
| Freeing a `VoxelTerrain` while it streams blocks until Voxel Tools has picked every queued task: 6–13 s on this PC with 4,700 generation tasks queued (view distance 128), "Waiting for all tasks to be picked is taking a long time" (M4 A2) | Take its viewers away first and wait about 150 ms: the queue is dropped, then the world goes in ~3 ms (`WorldService.stop_viewers(scene)`, `await WorldService.drain(tree, s)`). Rejoin and the guest's goodbye do it; `Game.quit_to_menu` does not yet |
| Queued voxel work | `VoxelEngine.get_stats()`: `thread_pools.general.tasks` (queued), `tasks.generation` / `meshing` (`WorldService.voxel_tasks()`) |
| The GDScript generator on 12 worker threads under load 20: ~40 ms a chunk per thread (~290 chunks/s), the spawn area ~0.8 s; a guest that started generating before its player arrived starved its main thread (the host's spawn of its player arrived 1.3–1.8 s late instead of 0.2 s) (M4 A2) | Don't start a world streaming before its first player is there; the readiness box size doesn't matter (a 1×2×1 box around the feet was meshed at the same moment as the 16³ box) |
| `VoxelViewer.set_network_peer_id()` is a method, not a property | Call the method |
| Hundreds of `set_block` calls around a standing player (a smoke run laying a floor): while the chunk was re-meshed the player fell through the ground, 28 blocks, in 3 of 4 runs (M3 Task 7) | Stand the player again after big edits and wait a moment (`tools/smart_smoke_steps.gd` step 1), or fly |
| `VoxelMesherBlocky.build_mesh` uses 1 voxel of padding (mesh coords = buffer coords − 1) | Size the buffer +2 and offset by 1 |
| `VoxelBuffer.fill_area` max is exclusive | |
| `VoxelStreamSQLite` needs a global path | |
| `collision_aabbs = []` leaves a block solid to the terrain's physics: they only serve Voxel Tools' own box queries; the physics is built from mesh surfaces with collision on (`collision_enabled_0`). Monsters pressed on an open door in the defense smoke run; a physics ray probe also stopped at water | For a walk-through block also call `set_mesh_collision_enabled(0, false)` (`BlockLibrary.build`: DOOR_OPEN, BUSH); test it with a physics ray across real terrain, not with test boxes (`test_door_saves.gd`) |
| `VoxelTool.copy` (`copy_box`) waits on the voxel threads while terrain around streams: a 17³ copy took 19 ms on average and 202 ms at worst in a benchmark on a still-streaming world, against 0.02 ms once settled (M2 Task 8) | Never copy boxes per monster or per frame; index what you look for per 16-block chunk, copied once when loaded, a few a tick (`DefenseDirector.lanterns_near`) |
| Searching a box cell by cell through a Callable (`box_reader`) costs about 4-8 µs per cell: an explorer friend's 13 × 9 × 13 look took 2-4.5 ms on the desktop (M2 Task 15) | To find a few block ids, copy the box once (`WorldService.copy_box`) and search its bytes natively (`BotRules.find_in_buffer`: `decompress_channel`, `get_channel_as_byte_array`, `PackedByteArray.find`; 16-bit little-endian, index = y + sy·(x + sx·z)): 0.02 ms |
| Terrain collision (a concave shape per 16³ chunk, built for Jolt) is built on the main thread inside `VoxelEngineUpdater`, and `voxel/threads/main/time_budget_ms` does not cap it (2 ms changed nothing): flying 30 s over new land had 214 frames of 8-91 ms there, 18 of at most 10 with the terrain's collision off (M7, headless, 2 voxel threads) | Ask for collision only where something walks (`Player.COLLISION_DISTANCE`; the menu's backdrop asks for none); every chunk inside a collision viewer's box costs this, caves below included |
| `VoxelTerrain`'s `mesher`, `generator` and `stream` setters take ~10.5 ms each (it waits), ~32 ms of every world made (M7) | Set each once |

**Tests, tooling and machine**

| Gotcha | What to do |
|---|---|
| GUT silently skips test scripts that don't parse | `tests/run_tests.sh` greps for `SCRIPT ERROR` / `Parse Error` |
| The headless window in tests is square: a test of where a 3D thing lands on the screen (`Camera3D.unproject_position`) gave numbers no phone shows (Life L1: a side table "off the screen" at 16:9 was on it) | Measure in a `SubViewport` of the canvas's size with the camera inside it (`test_life_rooms.gd`) |
| JSON numbers are floats: `[1.0].has(1)` is false, so a step's coins from a file never matched a pressed coin (Life L1) | Compare as whole numbers (`LifeCheck._values`) |
| A test helper that waits a fixed number of frames flakes on a busy PC: a tap came before the room had left the step before (Life L1's host test in the lead's full suite) | Wait for the state the next action needs (`wait_until(... , 3.0)`: the input taken, the next step started) |
| In VR the laser to a far target straight ahead (the street's far kerb) passes through the HUD's tray, and `Vr.ui_wants_pointer()` takes it: nothing is pressed (Life L2's smoke) | Use the trigger itself for a step whose skill is the timing (reach `trigger`), or put the target off the tray's line |
| A held finger that goes down while the flat camera still glides to the step's view lands on another thing (Life L2's smoke: the scales' weigh) | Press again on the thing when the finger isn't on it (`tools/life_smoke_steps.gd`) |
| `a == ["x"] as Array[String]` parses as `(a == ["x"]) as Array[String]` (a cast of a bool) | Parenthesise the cast: `a == (["x"] as Array[String])` |
| A match pattern can't be split over two lines with a backslash (Parse Error: Expected expression for match pattern) | Put the patterns on one line, or two `match` branches |
| GUT runs every test of a file on one instance: a member variable a test changed (`var feet := …`) stays changed for the next test (VR-SOUND's loop test stopped its loop for "walking off" in the next one) | Set every member a test may change again in `before_each` |
| `const K := SomeClassName` is not a constant expression in GDScript 4.7 (the test did not parse) | Write the class's name, or `const K := preload("res://…")` |
| GUT's `wait_until` asks its predicate in `_physics_process` (60 a second): a state that lives a few milliseconds between two frames' `_process` (a chunk's comparison on a worker, `WorldSync.diffing()`) was missed about 1 run in 4 (the frame spikes agent, 2026-09-30) | Poll at the start of every frame (`await get_tree().process_frame` in a loop: `test_world_sync.gd`'s `_until_each_frame`); that test keeps the physics rate at 4 during the wait so a physics-rate check would miss it every time |
| Two probe or census runs at once in one private `XDG_DATA_HOME` wiped and reused each other's worlds (they start by deleting the slots they play) | One folder per run |
| The first suite run after a fresh `--import` in a new worktree stopped mid-run with exit 0 (M2 Task 3; the rerun was complete) | Check the log for "All tests passed" and the script count, not only the exit code |
| `pkill -f gut_cmdln.gd` kills every agent's test run on this PC (and its own shell) | Stop your own background run by its task id; never `pkill -f` a shared tool name |
| Agents started by one lead session share that session's scratchpad folder: two agents' `full.log` overwrote each other (2026-09-30, the daily-and-friends agent read another worktree's run) | Give logs and scripts in the scratchpad a folder or name of your own (`scratchpad/<agent>/…`); check the log names your own new test files |
| New `class_name` scripts are unknown to headless runs | Editor rescan or `--import` first |
| Two adb versions on one server port kill each other | Private server `ANDROID_ADB_SERVER_PORT=5038` |
| The emulator vanished mid-session (2026-09-25 ~17:30): `earlyoom` (a system service) stops `qemu-system-x86`, `godot`, `java` and `node` first when free memory falls under about 6 % | Keep full suites to their slots and the agents to 3; start the emulator when more than ~6 GB is free, and stop it (`adb emu kill`) after a check |
| `ls` in this PC's shell is an alias of another tool (`ls -t` does not sort by time): a deploy picked an older server kit (2026-09-25) | Name the kit file (`kit.sh pack` prints it), or use `command ls -t` |
| The phone APK ("Android Phone", arm64-v8a only) on the x86_64 emulator runs under ARM translation: the menu took ~20 s against ~7 s for the dev APK of the same code (2026-09-26, the 1.0.0 RC) | Measure performance on the emulator with the dev APK ("Android", with x86_64); use the phone APK there only to check that it installs and runs |
| After the emulator restarts, our private adb server (5038) may list no device although the emulator booted | Restart only our server: `ANDROID_ADB_SERVER_PORT=5038 adb kill-server && … adb start-server` (never touch the other app's server on 5037) |
| `test_no_guilt_words` reads every string literal in `autoloads/`, `core/`, `entities/`, `scenes/`, `ui/`, `world/` (only `core/validation/` is exempt): a word list that must understand a child saying "hurry" or "don't go" can't hold those words (owner 38) | Understand them through other words ("come on", "wait"), or keep such a list in `core/validation/` |
| Emulator Vulkan gave a black screen | `Vulkan = off` (global, see §3) |
| An app launched right after a cold boot dies | Relaunch after the emulator settles |
| A Python/sed edit silently didn't apply because the anchor text had changed | Assert the anchor exists, then grep the result |
| `cargo` is broken on this PC | Install tools with apt or prebuilt binaries |
| A GDScript lambda captures locals by value: `got = x` inside a signal lambda never reaches the test | Collect into an Array (`got.append(x)`) |
| Headless on this PC, the voxel generator's 12 threads (a GDScript generator) slow the main thread's calls into engine methods 10-50x while the terrain generates: 200 `height_at` calls took 0.7 ms idle and 35-120 ms then; plain GDScript maths was unchanged. The first Moon-trip measurement's "burst a few seconds after arriving" (animals 300-560 ms, secrets 110-430 ms, the player's physics) was mostly this (M7) | Measure long frames with `--voxel-threads=2` (`tools/frame_probe.gd`; a phone's browser gets a quarter of its cores, an 8-core phone's app 4) |
| A panel built on first open (`build_later`) has no children before it opens: `find_children` in a test finds nothing (M7) | Open it first, or read it through its methods (they build it) |
| A monster (or animal) stepped by a test rests unless a player stands within 32 blocks (`MonsterRules.is_active`), and the players list is refreshed only when the physics frame changes | Put a player within 32 blocks for the whole run (a fleeing monster walks out of range: put the player on its side), and `await get_tree().physics_frame` once after adding them |
| The first RPC to a peer also sends Godot's node-path cache packets: a fake peer sees three packets for one call | Assert that every packet went to the right peer, not how many |
| A sound still playing when a headless test run quits shows as "ObjectDB instances were leaked at exit" | Stop the `Audio` players in the test file's `after_all` (`Audio.stop_all()`) |
| Every `BaseButton` now has Audio's click connected to `pressed` (the audio pass), after the button's own connections if it entered the tree after them: `pressed.get_connections().back()` may be Audio's | Skip connections whose callable's object is `Audio` (`test_universe_menu.gd`'s `_bound`) |
| `Audio.play` drops the same sound after 3 plays in 80 ms and a flat sound played twice in one frame; a positional sound 40 m from the current camera is not played | Tests that count plays use distinct sounds, or count `Audio.played + Audio.dropped`; `Audio.stop_all()` clears the counters' windows |
| The 80 ms window above is real time: a test that steps ten minutes of a chorus in a moment sees most of its calls dropped (M5 Task 2: 0.3 "grunts a minute") | Count the chorus's own `called` signal, not `Audio.sound_played` |
| A window run of the menu (`tools/polish_shots.gd`) needs a few seconds before the backdrop world is drawn; the title diorama rides on the camera, so it shows at once | Wait ~3 s before the first picture |
| Loading a 1 MB Vorbis piece takes 5–20 ms on this PC (more on a phone) | `Music` loads pieces with `ResourceLoader.load_threaded_request`; a test waits a few frames (`_until_playing` in `test_classical_music.gd`) |
| A headless test run under a heavy load (35–40) sat in "Waiting for all tasks to be completed is taking a long time" when a menu with a voxel world was freed (`test_universe_menu.gd`, the audio pass) | Rerun it on its own; it passed on the rerun and in a batch |
| A GUT `func should_skip_script() -> Variant:` parsed alone but failed in a full run ("signature doesn't match the parent") | Leave it untyped, like GUT's own; tests that need the Nakama server skip through `tests/integration/nakama_probe.gd` |
| npm 12 refuses git and URL dependencies by default (`EALLOWGIT`, `EALLOWREMOTE`) | Registry packages only; nakama-common's `index.d.ts` is vendored in `server/modules/vendor/` |
| `MultiplayerPeer.close()` on a `NakamaMultiplayerPeer` is an engine error in Godot 4.7 (it has no `_close`) | `Session._online_close` swaps in an `OfflineMultiplayerPeer` first, then leaves the match |
| Nakama closed the host's session as a guest joined ("websocket: read limit exceeded"): the voxel sync sent one 537 KB packet | `RelayBridge` sends packets over 32 KiB in pieces; `socket.max_message_size_bytes` 65536 in `server/nakama/local.yml` |
| A compose `${VAR:?message}` whose message has ": " in it is a YAML error ("mapping values are not allowed") | No colon-space in those messages (`server/deploy/docker-compose.yml`) |
| Docker's published ports go past `ufw` | Publish only what may be public (the kit: 80/443; the console on 127.0.0.1) and add the provider's firewall (`docs/hosting.md` step 2) |
| Let's Encrypt's certificates for bare IP addresses (since January 2026: 6-day `shortlived` profile, Caddy 2.11.4+ with `default_sni`) are untested with the game's TLS check | The kit's server has a name: a domain or a free DuckDNS name (`docs/hosting.md` step 3) |
| Godot only trusts its CA bundle, so a desktop game refuses Caddy's local certificate (mbedTLS -0x2700) | For a local TLS check, a temporary `override.cfg` in the project root with `[network] tls/certificate_bundle_override="<Caddy's root.crt>"`; delete it right after (every run in that folder reads it) |
| Over `wss://` Godot writes a WebSocket frame's header and payload as two TLS records, and Nagle holds the second until a delayed ACK (40 ms): relay round trip 55 ms instead of 14 ms. `WebSocketPeer.set_no_delay(true)` before connecting does nothing for TLS | Call `set_no_delay(true)` once the socket is open (measured: 13.9 ms; `docs/devlog/parts/m4-d.md`) |
| Nakama reads several `--config` files and merges them (the later one wins, key by key) | The kit keeps secrets out of git that way: `production.yml` + a file `start.sh` writes into a tmpfs |
| Nakama refused to start: "js ... function key could not be extracted" | It reads `InitModule`'s own source: write every `initializer.register*(...)` call inside `InitModule`, never in a helper |
| A realtime before-hook that returns nothing counts as a disabled resource in Nakama's pipeline (its source closes the session for it) | Refuse by throwing `{message: "<code>", code}` (`Server.refuse`): the game gets the code and the session stays (the integration script sends again after a refusal) |
| After `claim_username` the session token (and match presences, chat) still show the random name Nakama gave | Sign in again (or refresh the session) after claiming |
| Nakama keeps storage values as JSONB: what you read back has other key order and spacing than what you wrote (M4 F) | Compare parsed JSON, never the text (`ProfileSync._same`) |
| An RPC payload is at most 4 KiB in the module (`Util.MAX_PAYLOAD`): 256 code hashes are ~17 KB (M4 F) | Send lists in chunks (`CodeRules.RECORD_CHUNK`, 50) |
| A notification sent with `persistent = false` reaches only an open socket and never shows in `GET /v2/notification` (M4 F: the first approval note was missed by the integration test) | Send what the game must not miss as persistent |
| The runtime's `nk.friendsAdd` / `friendsDelete` do not run the before-AddFriends hook | The hook can hold a child's request for a grown-up and `approve_friend` still adds it (M4 F) |
| Nakama's JS runtime gives storage objects' `createTime` / `updateTime` in unix **seconds** (the console shows text; checked on 3.41, M4 G) | Read times through `RetentionRules.timeMs` (seconds, milliseconds or text) |
| Deleting a Nakama account (`nk.accountDeleteId`, the console's Delete) cascades in PostgreSQL to devices, storage, wallet ledger, friend edges, notifications **to** the player and messages it **sent**, but not notifications it sent (invites, Nakama's own friend notes, which carry it as sender) nor the other side of its DMs (checked in the database, M4 G) | `Deletion.run` removes those first; the retention clean-up removes what a console deletion leaves behind |
| An RPC called without a session (the runtime HTTP key `?http_key=…&unwrap`, or the console's API Explorer with an empty User ID) runs with `ctx.userId` ""; with a User ID the explorer runs it as that player ("User id not found." for none) | "" means the owner (`Server.rpcOrAdmin`); a game can never call without a session |
| Docker's `json-file` log driver limits size only (`max-size`, `max-file`): nothing ages out of a quiet server's log | Keep internet addresses out of Docker's logs; logs that must age go to their own files (Caddy's access log) |
| Caddy's `roll_interval` rolls a log only at the next write after the interval, and old rolled files are deleted only when a new file is made | `roll_at 00:00` (a timer: rolls with no requests) and `roll_keep_for 288h`: no access-log line older than 14 days (M4 G) |
| A GDScript function with an `await` in one branch still runs to the end at once when that branch is not taken | `CodePanel.submit` stays instant offline (its tests call it without `await`) and waits only for the server |
| A `godot --script` main loop can't name autoloads, or classes that use them (compile errors cascade and poison the script cache) | Keep the SceneTree script bare and `load()` a driver Node in `_initialize` (`root.add_child.call_deferred(...)`) |
| A frame longer than about 140 ms reaches `_process` as a clamped `delta` (the physics step cap): a timer summing `delta` lost 7 s during a rejoin's frozen frames, and `worst_frame_ms` never shows more than ~150 (M4 A2) | Measure times with `Time.get_ticks_msec()` (the net test's drop and join times do) |
| `.gitignore` ignores every folder named `build/`: M3 Task 8's `ui/build/` never reached git (its first suite run failed on "Could not find type") | Don't name a source folder `build` (it is `ui/building/`); check new folders with `git check-ignore -v` |
| `HTTPRequest.download_file` in a browser: the request ends `RESULT_SUCCESS` with every byte, and the file is gone (fetch() gives no body length, and Godot 4.7.2 deletes a download that did not match a length or end a chunked body; the music pack, 2026-09-28) | Take the body into memory and write it yourself (`WebContentIo`, test `test_the_download_is_written_by_us_not_by_http_request`) |
| The Movie Maker (`--write-movie`) wrote 960 × 540 frames for a 540 × 960 `--resolution` window: its picture's size comes from the project's window override at start, and the frames were a corner of the picture (the Reel Studio, 2026-10-01) | `tools/reel_render.sh` writes a temporary `override.cfg` with the video's size (never committed; removed after) |
| A render script stopped after filming 1,500 frames with no error: `first=$(ls dir | head -1)` under `set -o pipefail` (`ls` dies of SIGPIPE once its output outgrows the pipe) | A glob array (`shot=(dir/frame*.png)`), never `ls` into `head` in a pipefail script |
| `get_meta(&"view", null)` printed "does not have any 'meta' values" on every Short's pause (a null default counts as no default) | `has_meta` first |
| Seeking a Theora video decodes from its last keyframe: a feed neighbour seeking its poster cost 60 ms | Keyframes every 2 s (`-g 60`); a video reel's neighbour shows its still and opens the video only when it plays (VideoView) |
| A frame sheet took 8 minutes and the reel bench never finished (10 min, no output): their windows wait on `frame_post_draw`, which vsync throttles to a crawl when the window is behind others (learning reels, 2026-10-01) | Run `tools/reel_preview.gd` sheets and `tools/reel_render.gd -- --bench` with `--disable-vsync` (a sheet in 20 s) |
| `ShortCheck.block_id(name)` reads BlockIds' whole constant map every call (0.3 ms): a volcano's shapes took 50 ms in it | Keep names resolved (`StudioShapes.block` keeps them, behind a mutex: workers use it) |
| An ArrayMesh made on a WorkerThreadPool task lost its RIDs in the headless renderer ("Parameter m is null" in `mesh_set_blend_shape_*`) | Fill the VoxelBuffer on the worker; build the mesh on the main thread (`Scene3DModels.BlocksBuilt`) |
| One VoxelTool read or write takes the voxel data's lock: while chunks mesh around the player (after a big edit) a cell cost up to 40 µs, and a 4,096-block fill read and written cell by cell took 1.5–5 s (M3 Task 8) | Read and write a box at once (`WorldService.blocks_at`, `set_blocks`: one copy, one paste) and write big edits a little every frame (`Session.TOOL_CHUNK`, `TOOL_FRAME_MS`) |
| Every `block_changed` has about ten listeners (world sync, water, stealth, bots, smart blocks, portals, defenses, ziplines, sleep, animals' news): together 13–20 µs an edit on this PC once the world is settled, up to 0.9 ms while it streams (they read neighbours through the VoxelTool; and a loaded PC starves the main thread: plain GDScript ran 10–40× slower in the smoke run's first seconds) | A tool that changes thousands of cells writes them a little every frame against a time budget (`Session.TOOL_FRAME_MS`), and checks cells as it writes them, never thousands in one frame (M3 Task 8) |
| Headless game runs share `user://` (saves, profile) with every worktree and the desktop game | Run them with `XDG_DATA_HOME=<scratch dir>` for a private user dir (put a `profile.json` there if needed) |
| A scene that leaves by `Game.quit_to_menu` / `change_scene_to_file` replaces GUT's own scene when a test presses its button (M4 I: the visit's LEAVE) | Give the scene an injectable way out (`VisitWorld.leave_to`); tests set it |
| `OnlineUi.button` never makes a button under 64 px tall or 135 px wide: asking for less still takes that much (a page that must fit the menu's 534 px panel went over by 8 px, M4 I) | Do the height sums with the real minimums; `tests/integration/test_gift_pages.gd` measures every page |
| The module's RPC payload cap is its own (`Util.MAX_PAYLOAD`, 4 KiB); Nakama's HTTP body limit is far larger (256 KiB) | An RPC that needs more parses with its own cap (`Gifts.rpc`, publish_showcase: 56 KiB; measured 33 KB through the real server) |
| Reading a 32³ area cell by cell with `VoxelBuffer.get_voxel` took 85-128 ms on this PC (M4 I) | Read the copy's bytes (`get_channel_as_byte_array` after `decompress_channel`; index y + sy·(x + sx·z)) on a `WorkerThreadPool` task (`ShowcaseArea.snapshot_async`) |
| Changing a setting in the settings panel calls `Profile.save()`, which writes the shared `user://profile.json` | Tests only read the panel (`test_settings_panel.gd`) and put `Profile.data` back in `after_each` |
| `HudLayout`'s button size, hand and moves are static state (the Hud configures it from the profile): a test that changes them left every later test's HUD bigger or mirrored (M5 Task 1) | Call `HudLayout.reset()` in `after_each`; put the profile's `button_size`, `left_handed` and `hud_moves` back |
| `ProfileData.from_json` coerces every settings key by its default's type, and anything not a number or bool becomes a String: a Dictionary in `DEFAULT_SETTINGS` would come back as text (and a const default's nested Dictionary is read-only) (M5 Task 1) | Keep structured data at the profile's top level with its own sanitiser (`ProfileData.hud_moves`, `HudLayout.sanitize_moves`) |
| `CPUParticles3D` has no `amount_ratio` in Godot 4.7 | Set `amount` (a pooled burst keeps its own in meta and `Fx.calm` puts it back) and slow it with `speed_scale` |
| The settings panel had grown to 725 px on the 720 px screen | It is 711 px now, guarded by `test_settings_fit_on_the_screen`. Since M3 Task 21a it has two pages (GAME, HELP; `test_settings_words_page.gd` measures both): put a new setting on the page with room |
| A static function can't call `tr()` (it is an Object method): "Cannot call non-static function" (M3 Task 21a) | Use `Lang.t("…")` in static code |
| Words drawn with `draw_string` are never translated by themselves (only a Control's `text` is) (M3 Task 21a) | Draw `atr(text)` |
| A Label translates any text that happens to be a key: a player named "Stone" showed as a translated word (M3 Task 21a; no translation is registered since owner #52) | Labels with players' words or names keep `auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED` (the chat's lines, the username, `NameTag`) |
| A windowed game started from an agent's shell ran at 2–4 FPS on KDE Wayland with vsync on, and at 50–110 FPS with `--disable-vsync` under the same host load (cause not confirmed; probably the compositor not pacing a window that isn't shown) | Add `--disable-vsync` for desktop tool runs such as the tour; FPS measured that way is not the game's |
| Headless runs draw nothing: `RenderingServer.frame_post_draw` never fires and `ViewportTexture.get_image()` returns null (with an engine error) | Await `process_frame` and use a blank image of the viewport's size when `DisplayServer.get_name() == "headless"` (`PhotoMode.capture`) |
| A `Label` given its `size` before `autowrap_mode` keeps the width of its whole unwrapped line (its minimum size then): its text runs on past its box (MAKE MY SHORT's kind cards) | Set `autowrap_mode` first, then the text and the size (`MyShortMakerView._words_label`) |
| `CanvasItem.draw_polygon` per face: the canvas renderer draws each polygon on its own (polygons are not batched), so a build of a few hundred blocks drawn face by face was ~400 draws a frame, and making it again for each actor cost 22 ms | Gather the faces into an `ArrayMesh` (2D vertices, UVs, colours) once and `draw_mesh` it (MyShortDrawers.IsoBuild: two meshes a layer, kept) |
| GUT fails a test on any engine `ERROR:` it caused, even an expected one (e.g. `DirAccess` failing on purpose) | In that test, take `get_errors()` and set `handled = true` on each (`test_photo_store.gd`) |
| A fresh worktree has no `.godot/` folder (no class cache, nothing imported): every script fails to parse | Run `godot --headless --path . --import` once before the first test run |
| Parallel agents of one session share its scratchpad folder: an agent read another agent's `one.log` test output as its own (M2 Task 16) | Give scratch files a task-specific subfolder or name (e.g. `scratchpad/t16/`) |
| `global_position` set on a node that is not in the tree yet fails (spawn functions build nodes before adding them) | Set `position` (with `top_level = true` it is a world position) |
| GUT's `wait_physics_frames(1)` resumes two physics frames later (owner #54: a "0.25 s" tap rhythm was really 0.5 s) | When the timing of taps or frames matters, `await get_tree().physics_frame` once per frame (`test_jump_taps_player.gd` `_frames`) |
| Animals look players up once per physics frame (`Animal._players_now`), so a test that moves a player sees the old place in the same frame | `await wait_physics_frames(1)` after moving the player |
| Bot friends cache players' spots and monsters once per physics frame too: a test stepping a friend by hand after teleporting the player 12 blocks saw it "rest" (the cached spot was more than 32 blocks away), and a monster added in the same frame was never fought (M2 Task 18) | `await get_tree().physics_frame` after moving a player or adding or freeing a monster |
| A small matrix product written as GDScript loops (16 × 12 + 12 × 8 multiply-adds) cost 18 µs on the desktop (M2 Task 18) | Keep the weights in `PackedFloat32Array` but run the product on native 4 × 4 blocks: `Projection * Vector4` (0.75 µs; `TinyNet`) |
| A GDScript lambda copies the local variables it uses: flipping a local `bool` after making the lambda never reaches it | Keep such a flag in a member variable (or an Array/Dictionary) |
| A behaviour test on a seeded creature passed with the behaviour removed: its seeded wander happened to go the right way (M2 Task 9, the wave monsters' walk to the Totem) | Mutation-check behaviour tests (remove the line, run, restore); mirror the setup (same seed, opposite sides) so luck can't pass both |
| The full suite takes 5-10 min; editing files while it runs in the same folder tests a mix of versions (M2 Task 5) | Stage the commit, export the index (`git checkout-index -a --prefix=<scratch>/snap/`), copy `.godot` in, `--import`, and run `tests/run_tests.sh` there; keep editing meanwhile and commit the index when it passes |
| A test that steps a node by hand (`_physics_process(dt)`) was flaky on a busy PC: the engine ran the node too, between the test's awaits | Turn its engine processing off in the test (`set_physics_process(false)`) |
| `test_monster_defenses.gd` `test_no_monster_passes_a_closed_doorway_of_two_doors` fails when run alone (always 5.126 > 5.0: a monster's centre 0.13 into the wall's outer face; the room starts at x = 6) but passes in the full suite (seen 2026-09-25 on trees from before #53 too, so it is old) | An order dependency not found yet (the combat tests before it are not it); judge it by the full suite, M5's flaky list with `test_visit_world` |
| A `CharacterBody3D` stepped by hand outside a physics frame (a test loop) moves by the *process* delta in `move_and_slide`: in a busy headless run that was 0.1 s+, so its speed looked right but it went ~8× as far, and a ridden horse passed over the water it should stop at (owner #41) | When distances matter, step it inside physics frames (`await get_tree().physics_frame`, then `_physics_process(get_physics_process_delta_time())`: `test_animal_ride.gd`'s `_run`) |
| `godot -s addons/gut/gut_cmdln.gd -gdir=… -gtest=res://x.gd` runs every script in the dirs, not just x (owner #41: an agent's "one test" ran the whole suite outside the slot gate) | For one or a few scripts pass only `-gtest=res://a.gd,res://b.gd` (comma-separated), no `-gdir` |
| `var a: Array[int] = X if c else Y` with typed-array constants or literals, and `var order: Array[int] = [...] if c else [...]`, fail at run time ("Trying to assign an array of type "Array" to a variable of type "Array[int]"", M3 Task 10): the ternary's value is an untyped Array | Use if/else, or index each constant inside the branches (`RATE_PRICES[i] if c else CAP_PRICES[i]`) |
| `var me := weakref(self)` fails to parse (warnings are errors: `weakref()` returns a Variant) | Type it: `var me: WeakRef = weakref(self)` |
| Every `MultiplayerSynchronizer` sends once per frame by default, and a headless game runs as fast as it can: a host sent a guest 234 kbit/s of positions at 60 FPS, more uncapped (M4 A) | `SyncPace` (Session) sets every synchronizer's intervals; net tests run with `--max-fps 60` |
| Godot frees every node a peer spawned when that peer disconnects (or when `multiplayer_peer` is replaced): a guest that drops its link loses its own player at once | A rejoining guest reloads its scene; the sandbox's quit on "own player left" checks `Session.a_rejoining()` |
| Godot's `WebSocketPeer.send` writes to the OS socket at once (on this PC the kernel takes megabytes, so `get_current_outbound_buffered_amount()` stays 0); only what the OS refuses waits in its buffer, and a message that does not fit is refused with an `ERROR` line, which the Nakama client ignored | `RelayBridge` sends match data itself (`_adapter.send`), checks the result and keeps a refused message first in line |
| Every Nakama message carries about 300 bytes of JSON (match id, op code, the target's presence) around base64 data: 60 small packets a second cost far more envelope than data | `RelayBridge` batches a frame's packets per target (`RelayBatch`) and leaves the presence out when the target is the only other player |

**Gameplay**

| Gotcha | What to do |
|---|---|
| Every boss after the Golem has its own phase enum (`P`: `SerpentRules.Phase`, `FrostGiantRules.Phase`, `CakeRules.Phase`, `SkyDragonRules.Phase`): `BossRules.Phase.DOWN` set on the Frost Giant is its breath warning (M5 Task 6) | Read the boss's own `P` (`script.get_script_constant_map().get("P", BossRules.Phase)`) |
| A look every screen plays from synced state guarded by a host-only flag (`StoneGolem._defeated`, set in the host's `take_hit`) is not guarded on a guest's copy (M5 Task 6: the win roar) | Guard it with synced state (`hp > 0`) |
| Particles parented into the Buddies container crashed the save loop | Parent effects to `get_tree().root`; `_buddy_nodes()` filters `is Buddy` |
| The camera squeezed into the avatar's head | Hide the avatar when the spring-arm hit length < 0.8 × size |
| Spawn waited on terrain at the origin (10 s for far saves) | Park the hidden player at the target while it streams; mid-air saves wait on the ground below |
| Autopilot got stuck flying into mountains | Use Ghost mode plus stall detection |
| Big bodies sliding over the voxel terrain mesh are expensive (cost grows with the collision footprint) | Keep collision footprints small; use Jolt (owner feedback #9) |
| Block ids 100 and up collide with item ids (one int space for hotbars and bags): a Portal Frame at 128 would break into a Crystal Bow (M3 Task 5) | Only give blocks ids no item uses; `test_no_block_takes_an_item_id` guards it |
| Walkers keeping apart in a crowd slid sideways along a wall into a doorway and hopped onto the closed door there: the door check looked only along the way each one wanted to go (found when M3 Task 3's yeti made six walking kinds in `test_monster_defenses`) | A walker pressed against a wall never hops when a closed door is in that wall or beside where it presses (`Monster._door_at_wall`) |
| A boss (or any body) stepped by a test without a floor falls with gravity, so its height-checked attacks miss (the Frost Giant's stomp and breath "never landed") | Give such tests a StaticBody3D ground (`test_frost_giant.gd`) |
| A flying body that read the ground under its feet ten times a second grazed cover with its side between two looks (the Sky Dragon gliding past a ring of cover, owner #39) | Read under its whole body and as far round as it moves before it looks again (`SkyDragonRules.floor_under_body`, reach = footprint + speed × 0.1 s); a fast straight path: read the ground along it beforehand, a few samples a step (`SkyDragon._read_line`); test with cover round the target (`test_sky_dragon.gd`) |
| A headless smoke run that quits while a music loop plays prints "resources still in use at exit" | `Music.reset()` and quit a moment later (`tools/universe_smoke_steps.gd`) |
| A material made per effect (one per particle burst) frees its generated shader with the last effect, so the next one compiles it again: a 100+ ms frame on the emulator's GL renderer | Share one long-lived material (`Fx`); prewarm it on `spawned`, with the camera in place (a prewarm during loading is not drawn) |
| Terrain collision for every chunk out to the view distance is built on the main thread: 108–145 ms frames while flying | Collision only within `Player.COLLISION_DISTANCE` (48) through a collision-only `VoxelViewer`; the view streams visuals only |
| ~20 animals simulated in full every physics step: 15–77 ms frames, then a physics-step spiral | `AnimalRules.is_active` (rest beyond 32 blocks), decisions every 0.1 s, idle animals skip `move_and_slide`, ≤ 3 spawns per tick |
| Reading many cells with `VoxelTool.get_voxel` (one lock each) | `WorldService.box_reader` copies a box once |
| Looking for a few block ids in a big box (lanterns near a monster spawn) | Copy the box once and search `VoxelBuffer.get_channel_as_byte_array` natively (`MonsterDirector.find_blocks`): search the id's low byte and check the high byte after it (ids go past 255; M3 Task 19) |
| 20 chasing monsters cost 3.4 ms a physics step on the desktop (grid-ray sight every decision, all pushing into the player) | Look every 0.3 s, stop a step short and stand, keep apart without group queries: 0.9 ms (M2 Task 4) |
| A LAN client's own player is freed by the host's spawner when the host quits, frames before the disconnect | The sandbox stops processing when its player leaves; per-frame users check `is_instance_valid` |
| A node the host frees in the same frame as its last change (the Golem's killing hit) never shows that change on a guest, and the guest's copy can outlive a reliable RPC sent at the same time (M2 Task 10: the guest's boss bar went back to full health after "You beat the Stone Golem!") | Send the outcome by RPC and let the guest's HUD keep it (`BossBar` ignores health updates while it shows a result) |
| A swim test with the view level passed while children could not get out of rivers: every generated river bank is 1 block high over water only 2 deep, and a push with the view tilted down (pitch < −0.5) dives to the river bed against the bank, below where the climb starts (owner feedback #30) | Test swimming with the view tilted down too, and on the real terrain (`test_swim_climb_out.gd`); a push into a bank never dives (`SwimRules.BANK_DEPTH`) |
| A tool that moved a player to "2 blocks from the host" put it inside a slope: it fell through the terrain (the voxel collision is one-sided mesh faces) to y −57 and the LAN games check failed (M4 H) | Put a moved body on `find_standing_y(x, z)` (or `BossRules.stand_y` near a height), never at another body's height |
| A guest's end card of the last round (its timer started when the host's end arrived, later than the host's) wiped the host's next round's state that came meanwhile (M4 H, the LAN games check) | A state of a running round ends any end display (`GamesDirector.receive_state`); test the order (`test_a_guests_copy_of_the_round_shows_the_same`) |
| Finding which frame broke the budget | The autopilot prints `AUTOPILOT slow phase=… t=… ms=…` and `AUTOPILOT act …`; for script vs engine time, the temporary per-script timer patch (dev log "Acceptance run 1") |
| Merging two branches that each add a function ending in the same line (`return true`): git counts that last line as shared, so after "keep both" the first function lost its `return` ("Not all code paths return a value", 76 failing tests) | After resolving conflicts, run `godot --headless --path . --import` and grep for `Parse Error` before the suite; read both sides' last lines around each resolved hunk |
| The lead's development Nakama (`easycraft-nakama`) mounts the **main checkout's** `server/modules/build`, so a module merged in `lead-merge` is not what the server runs (GUT tests against the server then test the old module) | In `lead-merge`: `npm --prefix server/modules run build`, copy `server/modules/build/index.js` into the main checkout's same (git-ignored) folder, `docker restart easycraft-nakama`, and check the log says `module <version> loaded` |
| A `get_tree().create_timer(0.1)` made at the end of a long frame (a test that had just built ten bosses) fired at the next frame, 2 ms of real time later: a timer counts frame deltas, and that frame's delta held the work done before it was made (M5 Task 6) | For a real-time wait (Audio's 80 ms same-sound window) loop on `Time.get_ticks_msec()` with `await get_tree().process_frame` |
| A GUT test that counts sounds passed with nothing heard: the bodies stood farther than `Audio.HEARING` from a camera, or in Audio's same-sound window, so every play was dropped (M5 Task 6) | Count tries (`Audio.played + Audio.dropped`), and add a control that must be heard |
| A `godot --script` run instantiates the autoloads before its `_initialize` (root already has them), so a script's `load()` timed there measures nothing: the autoloads compiled it (M5 Task 3) | Time the start with the menu's `--startup-probe` and `--verbose` time stamps, or `--check-only --script <file>` (compiles a script and what it needs, then quits) |
| A generator's fast path summed each column's craters in another order than its per-block reference: floats added in another order can round a height differently at .5 (owner #55) | Keep the fast path's sums in the reference's order (`SpaceShape._craters_near` lists cells in the order `crater_depth` visits them) and compare every block of whole chunks (`test_space_generator.gd`) |
| A generator that works out a column's height per chunk pays it 16 times per stack, and a Dictionary per crater cell per column made the Moon 3× slower than the meadows (owner #55) | Cache a chunk stack's columns and features (`SpaceGenerator._stack`, like `DragonGenerator`), keep per-column loops on packed arrays; bench cold and warm (`bench_generator.gd -- --space`) |
| A test that saves through `ModeRules.slot` writes the real save slot of this PC's own game (`sandbox_16`, …): the desktop user folder is shared with the developer and other worktrees | Pass the slot in (`SpaceTrip.arrival(…, slot, …)`) and use per-process slot names in tests (`test_space_trip.gd`) |
| `x == [a, b] as Array[String]` parses as `(x == [a, b]) as Array[String]` (a Parse Error in a `--script` smoke run, which then hangs until its time limit) | Put the cast in brackets: `x == ([a, b] as Array[String])` |
| Once a device had a wallet marker, `WalletSync` never gave it the server's balance: gold granted on the server (the owner's 100,000 for sasa192974, #67) or earned on another device never reached it, and a stale `account.gold` from before the sync's own report made the next `sync_wallet(false)` think the server had nothing (owner #67) | A sync ends with the server's balance plus the device's unreported change; `account.gold` is set from the sync's own result; no sync inside an online world (the host's reports are 5 s behind) |
| Nakama 3.41's `nk.sessionLogout(userId)` did not stop a session token already handed out: the old token still answered HTTP calls, and open sockets stayed (owner #67, checked on a real server) | Unlink the devices (they can't sign in again), `sessionLogout` (no refresh), and close every socket on the user's notifications stream (`streamUserList({mode: 0, subject})` → `sessionDisconnect`); a token lives at most `token_expiry_sec` (2 h) |
| A before-WriteStorageObjects hook may change what gets written: assigning a new JSON text to `data.objects[i].value` and returning `data` stores the cleaned value (Nakama 3.41, owner #67) | `beforeWriteStorageObjects` cleans the profile in place (`ProfileRules.clean`); a refusal is still `Server.refuse` |
| Nakama answers a storage write whose version doesn't match (or `"*"` over an existing object) with HTTP 400 "Storage write rejected - version check failed." | `NakamaOnlineBackend.storage_error` turns it into `version_clash`; `ProfileSync` reads, merges and writes again |
| `OnlineService._ready` loads `OnlinePrefs` from `prefs_path`, so a test's `s.prefs.safe_card_seen = now` set before `add_child` is lost and PLAY ONLINE shows the stay-safe card (owner #67's page tests) | Set prefs after adding the service to the tree |
| With `physics/3d/run_on_separate_thread` on, `direct_space_state` is null outside the physics step: a ray from `_process` or `_input` logs "Space state is inaccessible right now" and the tap does nothing (VR P5, measured; owner #110's follow-up a) | Taps' rays through `BlockInteractor.space_ray` / `in_space` (they wait for `_physics_process` then); a new query from a frame goes there too, or uses the voxels (`GridRay`) |
| A new RPC method on an existing node (VrPoseLink) shifts its other RPCs' ids for older builds: Godot numbers a node's RPCs by their sorted names (owner #110) | New data rides on what the node already sends (the VR pose's spare bytes), or on a new child node only peers that know it are sent to |
| A container's children have no rects until it sorts them (a frame later): a test reading a Hotbar's slot rects right after `setup` gets them all at the first slot (owner #110's wrist test) | `container.notification(Container.NOTIFICATION_SORT_CHILDREN)` first, or wait a frame |
| A queued-for-deletion node is still in its groups until the frame ends: a closed MODEL VIEW's figure was still grabbable by the next test's hand (owner #110) | Check `is_queued_for_deletion()` (`VrGrabbable.takeable`), and disable what a closing thing offers at once |

## 9. Deferred minors (known, not yet fixed)

From the M1 final review, still open:
- There is no network rate limiting for block edits yet (M4). Chat has its own limit.

From the M1b final review (Task 15), still open: none.

From the M3 whole-branch review (Task 19), still open (file:line and proposed fixes in
`docs/devlog/parts/m3-task-19-review.md`): guests' Survivor gold claims for quests, board goals and presents are
trusted (the trusted-LAN ruling); Survivor night records and arena
bests keep the first 16 players at load (a ruling: kept); the team chat's awaits touch a freed panel (debug error); buddies look the players group up
every physics frame. Fixed by the lead after the review: the building tools' job queue has a per-player cap
(`Session.TOOL_JOBS_PER_PLAYER` = 2, "Still building! Wait a moment."), the last "1 blocks" lines (`Lang.blocks`), and
the panels' "where is my player" callbacks ask `Player.position_or_none` (INF out of the tree: the host-quit error line).

From the M4 whole-branch review (Task 10), still open (where, why and the proposed fixes in
`docs/devlog/parts/m4-task-10-review.md`, "Not fixed"):
- E's second half: friend approvals and chat switches through the consent provider's parent dashboard once a
  provider exists (the phone's gate is the check until then).
- D's second half: farm payouts are not counted in the wallet's hourly window (farms are capped at 20 per player,
  each paying at most 1,000 × 2^(u−1) an hour for 24 h).
- C's limit uses the universe the host reports (at most 12): a modified host claiming universe 12 may still spend
  up to 20,000 × 2,048 of a guest's gold an hour. The server knows no player's universe.

Fixed in the review's follow-up (module 0.2.10, `docs/devlog/parts/m4-review-leftovers.md`), each test-first:
C (a guest's spends a host reports: `spend_limit`), D (at most 20 farm clocks: `too_many_farms`), E (three wrong
answers rest every parent gate for a minute), F (report windows go an hour after the last report), G (a blocked
player's sticker note), I (a guest forgets the edits of chunks it left; the host sends them again). A came with
module 0.2.9 (`remove_guest`). B (module 0.2.11, `match_players`: an online host names and bands its guests by the
server; no relay-chat stand-in for the team room) and H (reproduced in `test_relay_bridge_targets.gd`: a join names
the players of every waiting "everyone" message) were fixed in the safety leftovers
(`docs/devlog/parts/safety-leftovers.md`), with M5 Task 4's F1 (the photo sharing switch).

From the M5 whole-game review (Task 6, 2026-09-26), still open (where, why and the proposed fixes in
`docs/devlog/parts/m5-task-6-review.md`, "Not fixed"):
- Online REMOVE when the server's `remove_guest` fails at that moment: the guest's game leaves, but the server never
  struck them off the invite list (the host can BLOCK them from FRIENDS; a retry queue would fix it).
- LAN turn-away is by the address a game connected from (LAN has no accounts): another device can join.
- LOW's animal cap (12 near a child) does not hold for animal summons (`AnimalRules.SUMMON_CAP` 30): a ruling, animals
  cost far less than monsters.
Fixed in that review, each test-first: a removed LAN player turned away while the host hosts, Pip's step card at TEXT
SIZE BIG, the tutorial's blocks given back twice after a close mid-clearing, LOW's monster cap for summons (MOBS), a
defeated boss's win roar on a guest's copy, Android Back over MOVE BUTTONS, Back during a load.

Fixed during M1b, each test-first:
- A cancelled touch counted as a tap.
- There was no feedback when a placement was refused. The host now says why (bedrock, too far,
  someone standing there).
- `set_block` on unloaded areas emitted `block_changed`.
- The Android presets lacked network permissions, which LAN needs.
- `WorldMeta.from_json` crashed on bad value types (every saved number must now be finite).
- M1b review: a LAN NaN could corrupt the save (I1), a peak hid the valley and sea (I2), `/summon`
  had no cap and put fish on land (I3), the axe felled log cabins, commands left sleepers lying,
  waking under a low ceiling, style re-apply rebuilt the sky, chat age bands untested across peers,
  and the spec's collars / idle animations / looking at players were missing.
- M1b review M8 (part) and M12 (`docs/devlog/parts/review-minors-animals.md`): `Ambience` wrote the
  light and fog every frame (now only on a change), animal sync sent owner/name/sitting every frame
  (now on change), and a guest's pets froze when the guest left and stayed stuck if they fell out of
  the world (now they sit and wait, and come back up next to the world spawn).
- A LAN client crashed when the host quit (found by the M1 minors agent: signal 11 in
  `world/ambience.gd`, 2 of 3 headless LAN runs). The host's spawner frees the client's own player,
  often frames before the disconnect arrives. The sandbox now stops processing the moment its own
  player leaves and goes back to the menu; Ambience, SleepDirector, the HUD and the look area also
  check `is_instance_valid`. 4 of 4 LAN runs clean afterwards.
- The boomerang flew level whatever the aim, so it flew over a dummy one block below the thrower
  (the weapons smoke run's failing step). It follows the aim up or down now, never steeper than
  `WeaponRules.BOOMERANG_MAX_PITCH`.
- M1b review M8 (rest): animals queried the `players` group every physics frame; the animal
  simulation rework (`20774a0`, found as the emulator frame spikes) shares one lookup per frame.
- M1b review minors (`docs/devlog/parts/review-minors-host.md`):
  - M1: the bedrock check could fail open. `PlacementRules.validate_edit` / `refusal` now require the
    cell's current block (`current_id`, right after `id`), and `tests/integration/test_host_edits.gd`
    checks bedrock through `Session` for a tap, a batch, a stamp and a mirror copy.
  - M6: a player who joined during the sleep-skip countdown cancelled it silently. The host now
    counts the joiner at `client_ready` (its body is added after the director hears it) and tells
    the sleepers "Zzz... N of M asleep"; a countdown that can't finish also tells them.
  - M9: the chat filter missed non-ASCII digits and accented swears. `ChatRules.normalize` (tables:
    every Unicode decimal digit, fullwidth ASCII, accented and look-alike letters, other spaces and
    dashes) makes the copy every check reads; the delivered message keeps its accents.
  - M10: melee hit through walls. `CombatDirector.in_sight` casts a grid ray over the voxel data
    from the chest to the target (water and air don't block), and things out of sight are left out
    before the swing picks its targets.
- M1 minors (`docs/devlog/parts/m1-minors.md`): touch releases were lost while paused (a joystick or
  button stayed held after RESUME); pausing now lets go of every touch. The name filter blocked
  "Peacock" and "Scrappy"; a blocked stem inside a known innocent word
  (`UsernameRules.INNOCENT_WORDS`) no longer counts. Giants didn't auto-step and unstuck checked
  only the centre column; both now scale to the body (`StepRules`). LAN client undo had gaps; undo
  steps now come from the host (only what it really changed; cells an undo couldn't restore yet are
  kept for later).
