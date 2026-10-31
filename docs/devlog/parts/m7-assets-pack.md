# M7: the game's media in their own pack, so an update downloads only the code (notes, 2026-09-28)

The owner (2026-09-28): "make sure it loads fast … after refresh i dont need to redownload the data, this is
important". A refresh already fetched nothing, but **every deploy changed `index.pck`** (12.8 MB raw, 11.2 MB brotli),
so every returning visit after an update downloaded ~11 MB again, and 7.5 MB of that pack were media that rarely
change: 6.2 MB OGG (sound effects, ambience, the day/night/boss loops), 0.76 MB WAV samples, 0.59 MB the characters'
skins and models. (MB here are MiB, as the export prints them; the tables give bytes.) The engine files were already kept by their content (the service worker's `EasyCraft-files`).

Done by a background agent in its own worktree (`worktree-agent-ae47ea66ab4bf95a0`, from `lead-merge` at `40a573f`).
No editor, emulator, adb, server or deploy. Every rule test-first (RED seen for the reason named, then GREEN). How it
works now: `docs/DEVELOPMENT.md` §5 "Web", the bullet "The game's media in their own pack", and §4 "The game in the
browser".

## How it works

- **Two new presets, "Web Assets" (S3TC) and "Web Assets Mobile" (ETC2)**, `export_filter="resources"`, no
  `export_files`, `include_filter` = the media patterns; "Web" and "Web Mobile" exclude the same patterns (after the
  music's and the realistic pictures'):
  `assets/audio/*.ogg, assets/audio/*.wav, assets/characters/*.png, assets/characters/*.fbx, assets/music/day.ogg,
  assets/music/night.ogg, assets/music/boss.ogg`. By extension, so an `.import` or `License.txt` never goes along as a
  raw file (an include filter adds every file it matches).
- **The page** (`web/shell.html`) downloads its GPU's assets pack next to its main pack **before the engine starts**
  (`engine.preloadFile(assets, '/assets.pck')`, the progress bar counts it: its size is in `GODOT_CONFIG.fileSizes`).
  `tools/export_web.sh` writes the names into `const EC_ASSETS = '@EC_ASSETS@'` (`{"s3tc": "assets.<h>.pck", "etc2":
  "assets.mobile.<h>.pck"}`); an unpatched page (a bare Godot export) brings none.
- **The first autoload, `AssetsPack`** (`autoloads/assets_pack.gd`), in a browser loads `/assets.pck` in `_init` with
  `ProjectSettings.load_resource_pack(path, false)` (a file the main pack has wins) and logs
  `EasyCraft: the assets pack is in (16 ms)`, or an error when the page brought none. Off the web it does nothing.
  **Why it works:** the engine loads and instantiates the autoloads one by one in `project.godot`'s order
  (`ResourceLoader.load(script)` then `set_script`, which runs `_init`), so `Profile`, … `Music` are loaded after the
  pack is in, and `Music`'s `preload("res://assets/music/day.ogg")` (not in `index.pck` any more) finds its file.
  For that the loader names nothing of the game: no preload, no path, no class (a class would be compiled first, with
  its preloads). Proved in the browser: the log line comes before `MENU ready`, the menu and a Survivor world run, no
  error (a missing preload in an autoload fails to compile `Music`, and the menu's `Music.play_menu()` would error).
- **Content packs keep only their own files** (`tools/pck_tool.py strip`). Godot's exporter adds the autoload scripts
  (`autoloads/*.gdc`, the MCP bridge), `project.binary`, the uid and class caches, `icon.png` and the boot splash to
  every pack it exports, also a pack of chosen files (≈0.3 MB). The packs are named by the hash of their bytes, so a
  change to an autoload or to `project.godot` renamed the music, realistic and assets packs, and every returning
  device downloaded them again. `strip` keeps the files the preset chose, their `.import`/`.remap` and the imported
  data those name; it refuses a pack with nothing or with code in it; the same input gives the same bytes. Applied to
  all five content packs.
- **The service worker** keeps both assets packs by content (`EC_HASHES`), like `index.pck`. A new version's worker
  used to download every file of Godot's `CACHED_FILES` again, `index.js` (3 MB raw) too, which the content cache
  already keeps: now those in `EC_HASHES` come from there (`ecKeep`, once from the network the first time; that also
  puts `index.js` in the content cache on the first visit). The offline check (`fullCache`) is unchanged: it never
  counted files in `EC_HASHES`.
- **The web code as plain binary tokens** (`script_export_mode=1` in "Web" and "Web Mobile"; Android keeps 2). After
  the split, `index.pck` is 85 % compiled scripts, each compressed on its own (zstd, mode 2), and brotli could take
  nothing off (5.1 MB raw, 4.7 MB brotli). As plain tokens it is 15.9 MB raw but brotli packs it across all scripts:
  3.4 MB at `-q 9`, **2.6 MB at `-q 11`** (`tools/deploy_web.sh` gives `index*.pck` `-q 11`, ~50 s each).
  GitHub Pages gzips every file itself (checked: `content-encoding: gzip` for `index.pck`, the 35 MB realistic pack and
  the 41 MB engine): 4.8 MB there, as in mode 2 (4.8).

### What stays in `index.pck` and why

| Stays | Why |
|---|---|
| Every script, scene, shader, `project.binary`, the caches, `voxel.gdextension` | code: an update is meant to bring it |
| `assets/brand/*` (the boot splash, the wordmark; 28 KB) | the engine shows the splash before any autoload |
| `icon.png` | the project icon (read at boot) and the install card's picture |
| The generated pictures in `data/` and `ui/` (block pages, item icons, `water_waves.png`, pictures; 0.33 MB) | remade by our tools when blocks or items change (a code change): they would rename the assets pack |

**Read before the first autoload** (`test_nothing_the_engine_opens_before_the_autoloads_moves` walks every path in the
project settings and every `.gdextension`): `res://scenes/main.tscn`, `default_bus_layout.tres`,
`openxr_action_map.tres`, `assets/brand/splash.png`, `icon.png`, `script_templates`, the autoload scripts, the MCP
bridge, `addons/zylann.voxel/voxel.gdextension`; none is caught by the patterns. `project.binary` and the `.godot`
caches are written by the exporter, never a source file.

### The assets pack's files (327 media files, 7,873,920 bytes imported; 654 entries with their `.import`)

| Folder | Files | Imported bytes |
|---|---|---|
| `assets/audio/sfx` (OGG and WAV) | 301 | 2,773,529 |
| `assets/audio/ambience` | 9 | 2,544,559 |
| `assets/music/day.ogg`, `night.ogg`, `boss.ogg` (`Music.STREAMS`) | 3 | 1,939,842 |
| `assets/characters/bot_skins` | 6 | 432,156 |
| `assets/characters/kenney_human` (the model, 3 animations, 2 skins) | 6 | 176,562 |
| `assets/characters/avatar_masks` | 2 | 7,272 |

No VRAM-compressed texture is among them, so today both formats' packs are **byte-identical** (`assets.c6d086f1e6.pck`
and `assets.mobile.c6d086f1e6.pck`). Nothing names a moved file by uid (`test_nothing_names_a_moved_file_by_its_uid`):
the main pack's uid cache only knows its own files.

## Sizes (bytes; brotli `-q 9` unless noted, the deploy's)

"Before" is `lead-merge` at `40a573f` exported as it was; "after" is this branch.

| File | Before (raw / brotli) | After (raw / brotli) |
|---|---|---|
| `index.pck` (computers) | 13,366,568 / 11,717,358 | 16,629,948 / **2,772,449** (`-q 11`; `-q 9` 3,592,155; gzip 5,081,422) |
| `index.mobile.pck` (phones) | 13,517,104 / 11,735,264 | 16,780,484 / **2,801,592** (`-q 11`; `-q 9` 3,613,836) |
| `assets.<h>.pck` / `assets.mobile.<h>.pck` | — | 8,002,172 / 6,728,831 each (gzip 6,892,919) |
| `music.<h>.pck` | 21,431,876 / 20,194,626 | 21,135,936 / 19,917,312 (stripped) |
| `realistic.<h>.pck` | 36,488,260 / 8,632,688 | 36,192,624 / 8,172,770 (stripped) |
| `realistic.mobile.<h>.pck` | 36,488,260 / 8,536,246 | 36,192,624 / 8,066,942 (stripped) |
| `index.html` / `index.service.worker.js` | 35,246 / 10,914 · 8,111 / 2,705 | 36,010 / 11,165 · 8,636 / 2,802 |
| the engine (unchanged) | `index.side.wasm` 43,275,872 / 8,093,915; `index.wasm` 1,601,069 / 536,283; `index.js` 2,958,897 / 303,323; Voxel Tools 6,521,204 / 1,297,319 | the same |

With the split alone (scripts still mode 2), `index.pck` was 5,353,964 raw / 4,979,240 brotli (`-q 11` 4,905,508).

- **First visit** (before PLAY, brotli, MB = MiB): before ~21.1 (`index.pck` 11.2 + the engine 8.5 + Voxel Tools 1.2
  + small); after **~19.0** (`index.pck` 2.6 + assets 6.4 + the same engine and Voxel Tools). The music (19.0) and the
  realistic pictures (7.8) follow in the background as before.
- **An update that changes only code: ~11.6 → ~2.8 MB brotli** (measured below, raw on the test server).

## The update, measured (headless Chrome, `tools/web_update_check.py`)

A persistent Chrome profile visits build A (PLAY, the menu, 150 s: the music and realistic packs land in `user://`),
then build B is served at the same address (a code-only change: one unused constant added to
`core/platform/web_glue.gd`, not committed), visited, refreshed, and B opens the Survivor world. The server counts
what it sends (the service worker's own downloads included; a page's own count misses those). Raw bytes (the test
server sends no brotli).

**Before** (`lead-merge`, A0 → B0), the update:

```
=== update to B: the server sent 15.79 MB ===
     13366616  /index.pck
      2958897  /index.js          (the new worker's CACHED_FILES)
        76979  /index.icon.png … (html, icons, worklets, offline page, worker: 0.19 MB)
```

**After** (this branch, A1 → B1):

```
   9.6 EasyCraft: the assets pack is in (15 ms)
  13.2 MENU ready_ms=4932 main_cpu_ms=-1
  21.2 EasyCraft: the music pack is in (music.f8becd3ef7.pck)
  21.3 EasyCraft: the realistic pack is in (realistic.06332826e9.pck)
=== update to B: the server sent 16.08 MB ===
     16630060  /index.pck
        76979  /index.icon.png … (html, icons, worklets, offline page, worker: 0.22 MB)
=== refresh B: the server sent 0.00 MB ===
  27.4 SANDBOX spawned_ms=12723          (B again with --survivor: the world, its sounds from the assets pack)
=== world B: the server sent 0.00 MB ===
```

In what a phone downloads (brotli): before ≈ 11.2 (`index.pck`) + 0.29 (`index.js`) + 0.15 ≈ **11.6 MB**; after ≈
2.6 (`index.pck`, `-q 11`) + 0.2 ≈ **2.8 MB**. The assets pack, `index.js`, the engine, the music and the realistic
packs: nothing.

A second run with the committed `tools/web_update_check.py` gave the same numbers (update 16.08 MB raw, refresh and
world 0.00 MB). No error in any run; the one warning, in the Survivor world, is the game's own ("Theater: no flat, dry
ground near the spawn", seen with that world's seed, not about files).

**A media change** (`animal_blub.wav` normalized, re-imported, not committed; A1 → C1): the update brought
`assets.f1121e5399.pck` (7.6 MB raw, 6.4 brotli) and `index.pck` (below: every export changes it), and the content
cache then held only the new assets pack (the old one removed on `activate`). A refresh: 0.00 MB.

**A phone's GPU** (S3TC hidden from WebGL, `--etc2`): the page took `index.mobile.pck` and
`assets.mobile.c6d086f1e6.pck` (`window.easycraftGpu` = `etc2`), the game `realistic.mobile.d53b4522ad.pck`; the
menu and the Survivor world ran.

**As an iPhone** (`tools/web_iphone_check.mjs`, Playwright's WebKit with an iPhone 15's screen and touch, the same
build served locally): threads allowed, `EasyCraft: the assets pack is in (31 ms)`, `MENU ready`, the age pad and
the name box work (the screenshot shows the menu's world, the buddy and the dog, "Bear" typed).

**The lead's `tools/web_check.py`** (fresh profile, 200 s): `EasyCraft: the assets pack is in (19 ms)` before
`MENU ready`, the music pack and the realistic pack came and landed, and after the refresh **0.00 MB** over the network.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The media come before the start, not in the background.** Music preloads its loops, the world plays sounds at
   once and the avatar needs its model: the pack is part of the first download (the progress bar counts it) and the
   first autoload loads it. *Cost:* none in size (the same bytes as before, now in two files); a page that cannot get
   the pack does not start ("Paused… it will continue by itself", as for `index.pck`).
2. **Patterns by extension under `assets/audio` and `assets/characters`, plus the three core loops by name.** A new
   sound or skin comes along; a new kind of file there (`.mp3`, `.glb`) fails
   `test_the_patterns_catch_the_media_and_nothing_else` until it has a pattern (in the three presets and the test).
   *Cost:* none seen.
3. **The generated pictures (`data/`, `ui/`, 0.33 MB) and the brand pictures stay with the code.** Our tools remake the
   block pages and icons when blocks or items change; in the assets pack every such change would rename it (8 MB).
   *Cost:* 0.33 MB in every update.
4. **One pack per texture format, although today both are the same bytes.** A VRAM-compressed texture added under
   `assets/` later then goes in its GPU's format (like `index.pck`). *Cost:* the deploy uploads 8 MB more (and its
   `.br`/`.gz`); a device downloads only its own.
5. **Every content pack is stripped to its own files**, so this deploy renames the music and realistic packs once
   (`music.a29511ee1e` → `music.f8becd3ef7`, …): every returning device downloads them once more in the background
   (music 19.0 MB, its realistic pack ~7.8 MB brotli). After that a code change never renames them. *Cost:* that one
   background download; nothing at run time (the main pack's copies of the dropped files always won).
6. **The web code as plain binary tokens (mode 1).** The code pack 4.7 → 2.6 MB brotli on our server (every update
   and the first visit), GitHub Pages the same (4.8 MB gzip either way). *Cost:* the pack sits in the engine's
   in-memory file system for the whole run: `index.pck` + `assets` = 23.5 MB of JavaScript memory instead of 12.7 MB
   (+10.7 MB). If an iPhone tab is reloaded by Safari for memory, set `script_export_mode=2` in "Web" and "Web Mobile"
   (and the test `test_the_browsers_code_is_left_for_brotli_to_pack`): updates then cost ~4.9 MB.
7. **`tools/deploy_web.sh` gives `index*.pck` brotli `-q 11`** (16 MB each, ~50 s, 2.6 MB instead of 3.4; the other
   files keep `-q 9`).
   *Cost:* ~1.5 minutes more per deploy.
8. **The new worker takes `index.js` from the content cache.** *Cost:* none seen; if `ecKeep`'s one download fails,
   the worker's install fails and the old worker stays (as when `addAll` failed before).

## Left open

- **`index.pck` changes at every export, even without a change:** Godot 4.7 writes random `node_ids` into each
  `.tscn` it converts to binary (7 scenes: main, menu, world, sandbox, visit, player, status_panel). A media-only or
  a repeated deploy therefore also brings the code pack (2.6 MB). Stable ids need those scenes saved again in the
  editor (or the conversion off); not done here (the scenes belong to other work).
- The manifest's icons and the page's PNGs (0.14 MB) are downloaded again at every update (Godot's versioned cache);
  they could join `EC_HASHES`.
- More could leave the code pack: `tools/` (0.67 of the 4.3 MB of mode-2 scripts: the autopilot, tours, benches)
  and the MCP bridge (0.21 MB, an editor tool) ship in the web build.
- Not checked on a real phone or iPhone (headless Chrome only; no emulator in this task): the update on the emulator's
  Chrome and on an iPhone (the memory of ruling 6).

## Tests

New: `tests/unit/test_assets_pack.gd` (14: the loader is the first autoload and names nothing, its path, off the web
and without a pack it loads nothing, the page puts the pack where the game reads it, the patterns catch the media and
nothing else, leave the other packs' files and the brand alone, nothing read before the autoloads is caught, nothing
names a moved file by uid, "Web"/"Web Mobile" exclude them, the two pack presets take exactly them in their format,
the web code is mode 1 and Android's mode 2, Android keeps the media), `tests/integration/test_assets_pack_load.gd`
(5: a real pack joins `res://`, the game's own files win, `pck_tool.py strip` keeps only its files and the engine
loads what it wrote, the same bytes twice, an empty result refused), and `test_boot_splash.gd`'s content-pack list
(+2 presets). RED seen for each: the loader missing / not first, the presets and patterns missing, the page without
`EC_ASSETS`, mode 2 in the web presets, `tools/pck_tool.py` missing.

**Full suite** (`tests/run_tests.sh`, 2026-09-28, 1119 s, on the final code): **6347 of 6349 pass**, none fails, no
script error; the 2 risky ones are the known never-asserting generator tests (`test_the_column_cache_changes_nothing`,
`test_chunks_meet_without_seams`). The 19 new tests (14 + 5) come on top of `lead-merge`'s 6330.
