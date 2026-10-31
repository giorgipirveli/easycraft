# M7: the REALISTIC style's pictures come later (notes, 2026-09-28)

The owner (2026-09-28): "make sure it loads fast, load any unnessesary data later and make sure it is saved in iphone
and in adnroid browser so after refresh i dont need to redonwload the data, this is important" and "while playing
download full data needed for full game run in background". After the music moved to a background pack the first
download was ~29 MB brotli, and 36 of `index.pck`'s 47 MB raw were the REALISTIC style's pictures, which a child on
BLOCKY (the default, `core/save/profile_data.gd`) never loads. They now come in their own pack, one per texture
format, fetched after the music (first for a child who plays REALISTIC), kept in the browser's storage like the music.

Done by a background agent in its own worktree (`worktree-agent-acef79c1dacad726f`, from `lead-merge` at `a6fa11e`,
then `lead-merge` merged in at `2c937cb` (the Space universes, owner #55) and `563f0ca` (the page's update check)).
No editor, emulator, adb, server or deploy. Every rule test-first (RED seen for the reason named, then GREEN). How it works now: `docs/DEVELOPMENT.md` §5 "Web",
the bullet "Realistic pictures that come later", and §4 "The game in the browser".

## What was checked before moving anything

- The realistic twins are only ever loaded by `BlockLibrary.set_style` / `_style_page` (`load(files[1])`,
  `load(files[2])`, `load(REALISTIC_ALBEDO/NORMAL)`) and the HDRI sky only by `WorldService.apply_style`
  (`load(REALISTIC_SKY)`). No `preload`, no `.tscn`/`.tres` ext_resource and no uid reference names any of them (grep
  of every `.gd`, `.tscn`, `.tres`, `.cfg` for the paths and for each file's `uid://`). Icons and break particles use
  the pixel page (`pixel_atlas_of`, `average_color`: `files[0]`). The tools that ship in the pack (`tools/*shots*`,
  `tools/tour.gd`, `tools/autopilot.gd`) only call `set_style`/`apply_style` at run time (a desktop run).
- After the merge of owner #55: the Moon, Planet Boing and Rainbow Planet pages are registered like the others
  (`world/universes/{moon,boing,rainbow}_blocks.gd`, twins `data/blocks/pages/{moon,boing,rainbow}_{albedo,normal}.png`);
  none of the space code (`world/space_*`, `world/universes/{moon,boing,rainbow}.gd`, `ui/space/`,
  `ui/universe/universe_art.gd`, `world/generators/space_*`) loads an HDR or a realistic twin (grep for `.hdr`,
  `_albedo`, `_normal`, `FILES[`, `preload`): the space skies are built in code.
- The Android presets are untouched (`test_phones_and_computers_keep_every_realistic_picture`).

## The export (`export_presets.cfg`, `tools/export_web.sh`, `tools/deploy_web.sh`)

- "Web" and "Web Mobile" `exclude_filter` gain `data/blocks/*_albedo.png, data/blocks/*_normal.png, assets/sky/*.hdr`
  (after the music's patterns). Godot's `*` crosses `/`, so `data/blocks/*_albedo.png` catches `data/blocks/pages/…`
  too: a page added later with the same naming comes along. The test walks the whole project: nothing but
  `RealisticPack.files()` matches (no pixel page, no `water_waves.png`, no other file).
- New presets **"Web Realistic"** (`vram_texture_compression/for_desktop=true, for_mobile=false`, as "Web") and
  **"Web Realistic Mobile"** (`false`/`true`, as "Web Mobile"): `export_filter="resources"`, no `export_files`,
  `include_filter` = the same three patterns. Like "Web Music" the exporter adds the autoload scripts, `icon.png`, the
  splash and `project.binary` (≈0.3 MB); `load_resource_pack(path, false)` keeps `index.pck`'s own.
- `tools/export_web.sh` exports both with `--export-pack` into `build/web-realistic{,-mobile}/`, names them by content
  (`realistic.<sha256:10>.pck`, `realistic.mobile.<sha256:10>.pck`) and writes `packs.json`:
  `{"version": 1, "packs": [{"name": "music", …}, {"name": "realistic", "file": "realistic.<h>.pck", "size": …,
  "gpu": "s3tc"}, {"name": "realistic", "file": "realistic.mobile.<h>.pck", "size": …, "gpu": "etc2"}]}` (the music
  entry unchanged, `version` still 1: an older game ignores `gpu` and would take the first realistic entry, S3TC).
  `INCLUDE_REALISTIC=1` keeps the pictures in the main packs too (like `INCLUDE_MUSIC=1`, which now strips only its
  own patterns). `tools/deploy_web.sh` brotli/gzips `realistic.*.pck` (the music stays raw: it is OGG).
- `tests/unit/test_boot_splash.gd`'s `CONTENT_PACK_PRESETS` names the two new presets (no splash in a pack).

### The realistic pack's files (27, the same in both formats)

| Source file | S3TC / ETC2 bytes |
|---|---|
| `res://data/blocks/realistic_albedo.png` | 5,592,484 |
| `res://data/blocks/realistic_normal.png` | 1,398,180 |
| `res://data/blocks/pages/portals_albedo.png` | 4,893,476 |
| `res://data/blocks/pages/portals_normal.png` | 1,223,460 |
| `res://data/blocks/pages/smart_albedo.png` | 2,796,292 |
| `res://data/blocks/pages/smart_normal.png` | 699,140 |
| `res://data/blocks/pages/candy_albedo.png` | 2,097,284 |
| `res://data/blocks/pages/candy_normal.png` | 524,420 |
| `res://data/blocks/pages/desert_albedo.png` | 2,097,284 |
| `res://data/blocks/pages/desert_normal.png` | 524,420 |
| `res://data/blocks/pages/dragon_albedo.png` | 2,097,284 |
| `res://data/blocks/pages/dragon_normal.png` | 524,420 |
| `res://data/blocks/pages/meadows_albedo.png` | 2,097,284 |
| `res://data/blocks/pages/meadows_normal.png` | 524,420 |
| `res://data/blocks/pages/frost_albedo.png` | 1,398,212 |
| `res://data/blocks/pages/frost_normal.png` | 349,636 |
| `res://data/blocks/pages/paint_albedo.png` | 699,132 |
| `res://data/blocks/pages/paint_normal.png` | 349,636 |
| `res://data/blocks/pages/tiny_albedo.png` | 699,132 |
| `res://data/blocks/pages/tiny_normal.png` | 349,636 |
| `res://data/blocks/pages/moon_albedo.png` | 699,132 |
| `res://data/blocks/pages/moon_normal.png` | 349,636 |
| `res://data/blocks/pages/boing_albedo.png` | 699,132 |
| `res://data/blocks/pages/boing_normal.png` | 349,636 |
| `res://data/blocks/pages/rainbow_albedo.png` | 699,132 |
| `res://data/blocks/pages/rainbow_normal.png` | 349,636 |
| `res://assets/sky/kloofendal_48d_partly_cloudy_puresky_1k.hdr` | 2,097,204 (the same file in both) |
| **27 imported files** | **36,178,740** |

Each with its `.import` (only that format's remap); `index.pck` and `index.mobile.pck` keep none of them (no stray
`.import`: `ResourceLoader.exists` would say yes and the load would fail) and keep every pixel page, `atlas.png` and
`water_waves.png` (checked by listing the packs).

## Sizes (after the merge of owner #55; brotli `-q 9`, the deploy's)

| File | Before (raw / brotli) | After (raw / brotli) |
|---|---|---|
| `index.pck` (computers, S3TC) | 49,554,968 (47.3 MB) / 19,912,136 (19.0 MB) | 13,361,756 (12.7 MB) / 11,712,324 (11.2 MB) |
| `index.mobile.pck` (phones, ETC2) | 49,705,504 (47.4 MB) / 19,921,441 (19.0 MB) | 13,512,292 (12.9 MB) / 11,729,430 (11.2 MB) |
| `realistic.<h>.pck` (S3TC) | — | 36,488,260 (34.8 MB) / 8,632,688 (8.2 MB) |
| `realistic.mobile.<h>.pck` (ETC2) | — | 36,488,260 (34.8 MB) / 8,536,246 (8.1 MB) |

"Before" is this branch exported with `INCLUDE_REALISTIC=1` (= `lead-merge` at `2c937cb`: the lead measured 47.3 MB).
The first visit goes from ~29 MB to **~21 MB brotli** (`index.pck` 11.2, the engine 8.1, Voxel Tools 1.3, the rest
0.5); the realistic pictures (8.2 MB brotli) follow the music (20.4 MB) in the background. GitHub Pages sends no `.br`:
there the pack is 34.8 MB (in the background). Before the merge (without the space pages) the same split gave
`index.pck` 46.3 → 13.2 MB raw, 19.0 → 11.6 MB brotli and a 33.3 MB (7.8 MB brotli) pack.

## The game (`core/platform/realistic_pack.gd`, `world/block_library.gd`, `world/world_service.gd`, …)

| Part | What | Tests (RED: why it failed first) |
|---|---|---|
| `WebContent` (`gpu`, `DEFAULT_GPU`, `parse_manifest(text, for_gpu)`) | An entry with `gpu` is only for that texture format; without it for every GPU; a `gpu` that is not a string leaves the entry out. | `test_web_content.gd` +4 (RED: `parse_manifest` took 1 argument, `DEFAULT_GPU` missing). |
| `WebContent.first` | `() -> String`: the pack to fetch next, asked before each pack starts; a download going on is never cut. | `test_web_content.gd` +3 (RED: no `first`). |
| `WebGlue.texture_format()`, `parse_texture_format`, `TEXTURE_FORMAT_JS`; `web/shell.html` | `pickPack` sets `window.easycraftGpu` (`etc2` when it took `index.mobile.pck`, else `s3tc`); the game reads it (S3TC off the web or when the page says nothing else); `WebContent.begin` sets `gpu` from it. | `test_web_glue.gd` +2 (RED: members missing). |
| `RealisticPack` (new) | `PACK = "realistic"`, `GROUP`, `files()` (every registered page's twins + the sky: `BlockLibrary.realistic_files()`), `file_present`/`present()` (`exists_check` for tests), `on_pack_loaded(name)` → the group's `realistic_pictures_arrived()` and the log line. | `tests/unit/test_realistic_pack.gd` (4 + the 4 export tests below; RED: class missing). |
| `BlockLibrary.set_style` / `_style_page` | REALISTIC without its pictures keeps the pixel pictures (`style` = what the blocks show); a page whose twin is missing keeps its pixel page (no null texture: the old code would crash in `page_uv_scale`). | `test_realistic_before_the_pack.gd` (RED: `style` was "realistic" with the pictures missing; the missing page crashed on `get_height` of null). |
| `WorldService.apply_style` / `realistic_pictures_arrived` | Remembers the asked style and joins the group; when the pack lands a world that wants REALISTIC applies it again (the shared materials, the photo sky, glow; no remesh); a BLOCKY world changes nothing. | same file (RED: the painted sky replaced by a PanoramaSkyMaterial pointing at a missing HDR). |
| Menu backdrop (`ui/menus/menu.gd`) | Re-applies the style on `Game.settings_applied` (every platform): a style picked in the menu's SETTINGS shows at once, REALISTIC when its pictures land. Found in headless Chrome: the pack landed while the child waited in the menu and "the blocks show blocky". | same file +2 (RED: `BlockLibrary.style` stayed blocky). |
| SETTINGS | "The realistic pictures are on their way…" (`SettingsPanel.REALISTIC_COMING`) beside the style buttons while REALISTIC is chosen and the pictures are not in; hidden again on BLOCKY and when they land. Still fits 1280 × 720. | same file (RED: no `RealisticNote`). |
| Chat | `/style realistic` before the pack says the same instead of "The world looks realistic now." (the choice is saved). | `test_chat_commands_run.gd` +1 (RED: the old reply). |
| Boot (`scenes/main.gd` `start_packs`) | `pack_loaded` → `RealisticPack.on_pack_loaded` too; `first` = `realistic` while the saved style is REALISTIC. | `test_web_content.gd` +1 (RED: not connected, `first` empty). |
| Export presets | The patterns (above) in "Web"/"Web Mobile", the two pack presets in their game's format, Android keeps every picture, nothing else matches. | `test_realistic_pack.gd` (RED: the patterns and presets missing). |

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Patterns, not a file list, move the pictures** (`data/blocks/*_albedo.png`, `data/blocks/*_normal.png`,
   `assets/sky/*.hdr`), so pages added later come along (the space pages did). *Cost:* a future file with that naming
   that BLOCKY needs would leave the first download; `test_the_patterns_catch_every_realistic_picture_and_nothing_else`
   fails then (it must be in `RealisticPack.files()`), and `test_the_pack_is_every_realistic_twin_and_the_sky` counts
   the pages (a new page must be added to its `PAGE_FILES`).
2. **Only the block twins and the HDRI sky move.** The realistic person (Kenney, `assets/characters/kenney_human/`),
   the bot skins and Pip's shiny look stay in `index.pck` (small; the avatar editor shows both bodies). *Cost:* none
   seen: `index.pck` is now scripts, sounds and small pictures (its biggest file is `boss.ogg`, 1.1 MB).
3. **Before the pack, REALISTIC looks BLOCKY but the person follows the choice at once** (the realistic body is in
   the first download; blocks, sky, glow, water and Pip wait). *Cost:* a real-looking person in a blocky world for the
   minute or two until the pack lands; making the person wait too is one line in `Sandbox._apply_settings`
   (`_style_avatars(BlockLibrary.style)`) plus the same re-apply on arrival.
4. **Every browser downloads the realistic pack, also a BLOCKY child's** (the owner: "while playing download full
   data needed for full game"), after the music; a REALISTIC child's (saved, or picked while the music downloads) comes
   next, never cutting a download. *Cost:* 8.2 MB more network and 34.8 MB more in the browser's storage for a child
   who never picks REALISTIC. Fetching it only once REALISTIC is chosen is a `first`-like filter in `WebContent`.
5. **Memory.** While it downloads, the body (36 MB) sits in the WebAssembly heap (which never shrinks) and is written
   into the in-memory `user://` (36 MB of JavaScript memory), then copied to IndexedDB; Godot copies all of `user://`
   from IndexedDB into memory at every boot, so a device with both packs keeps ~57 MB more JavaScript memory from the
   start (music 20.4 + realistic 34.8). On REALISTIC the 26 textures are ~34 MB of GPU memory (they stay compressed, as
   on Android today). *Cost:* an iPhone tab near its memory limit could be reloaded by Safari; the other way (no copy
   in `user://`, the HTTP cache instead) is ruling 1 of `m7-web-packs.md`.
6. **The switch happens in one frame when the pack lands** (26 textures and the sky on the main thread; WebGL uploads
   there anyway). Measured in headless Chrome (software WebGL): **107-109 ms**; a phone is likely a few hundred ms,
   once per run for a REALISTIC child. *Cost:* one pause; loading the files on the loader thread first
   (`ResourceLoader.load_threaded_request`, then restyle) would take the file reads out of the frame, not the upload.
7. **A returning REALISTIC child sees BLOCKY for the first few seconds** (`START_DELAY` 5 s, then `packs.json`, then
   the copy on the device loads and the menu turns realistic). *Cost:* a short blocky start every time; loading the
   device's copy of the `first` pack at boot, before `packs.json`, needs a version check (ruling 5 of
   `m7-web-packs.md`).
8. **A page that does not say its GPU gets S3TC** (the page's own default main pack is `index.pck`), and the game
   follows the page's choice rather than asking the GPU itself, so the pictures always match the main pack's format.
   *Cost:* none seen (the page and the packs come from one export); a wrong answer would load pictures the GPU cannot
   read directly: Godot decompresses them on the CPU (slower, still correct).
9. **The menu's backdrop follows a style picked in its SETTINGS** (all platforms). *Cost:* on a phone, picking
   REALISTIC in the menu loads the textures there (a short pause) instead of at the next world.

## The browser proof (headless Chrome, `python3 tools/web_serve.py build/web 8071`)

A copy of `tools/web_check.py` in the scratch folder (its own free DevTools port, like the lead's fixed script):
four phases in one fresh Chrome profile. Headless Chrome draws in software (a few frames a second), so a pack takes
40-130 s to come in (`HTTPRequest` reads one 256 KiB piece a frame).

**1. A first visit, BLOCKY (the default).** The music, then the realistic pack; it lands and nothing changes; both
are kept in IndexedDB (`/userfs/godot/app_userdata/EasyCraft/packs/`):

```
  11.8 MENU ready_ms=5214 main_cpu_ms=-1
  20.7 NET 200 packs.json sw=True
  21.5 EasyCraft: downloading the music pack (music.a29511ee1e.pck, 21431876 bytes)
  49.2 EasyCraft: the music pack is in (music.a29511ee1e.pck)
  49.4 EasyCraft: downloading the realistic pack (realistic.a24a7f14f5.pck, 36488260 bytes)
  94.2 EasyCraft: the realistic pack is in (realistic.a24a7f14f5.pck)
  94.2 EasyCraft: the realistic pictures are here (the blocks show blocky; 0 ms)
gpu: s3tc
kept in IndexedDB: {'music.a29511ee1e.pck': 21431876, 'realistic.a24a7f14f5.pck': 36488260}
```

**2. A BLOCKY child picks REALISTIC in SETTINGS before the pack lands** (the pack's copy deleted from IndexedDB, an
onboarded BLOCKY profile written there, on a page of the site where no game runs; then SETTINGS, REALISTIC by
clicks). No error; the note "The realistic pictures are on their way…" beside the buttons, the pixel pictures behind;
when the pack lands the menu's world turns realistic by itself and the note goes (screenshots checked):

```
 136.1 NET 200 packs.json sw=True
 137.3 EasyCraft: the music pack is in (music.a29511ee1e.pck)
 137.3 EasyCraft: downloading the realistic pack (realistic.a24a7f14f5.pck, 36488260 bytes)
 210.2 EasyCraft: the realistic pack is in (realistic.a24a7f14f5.pck)
 210.3 EasyCraft: the realistic pictures are here (the blocks show realistic; 115 ms)
```

**3. A REALISTIC child without the pack on the device**: the menu starts with the pixel pictures (no error), the
realistic pack comes **before** the music (the music's copy on the device loads after it), then the menu is
realistic:

```
 237.6 MENU ready_ms=3945 main_cpu_ms=-1
 255.3 NET 200 packs.json sw=True
 257.2 EasyCraft: downloading the realistic pack (realistic.a24a7f14f5.pck, 36488260 bytes)
 367.2 EasyCraft: the realistic pack is in (realistic.a24a7f14f5.pck)
 367.4 EasyCraft: the realistic pictures are here (the blocks show realistic; 112 ms)
 370.1 EasyCraft: the music pack is in (music.a29511ee1e.pck)
```

**4. A refresh:** both packs from the device, realistic at once, nothing over the network:

```
 464.0 MENU ready_ms=4056 main_cpu_ms=-1
 480.7 NET 200 packs.json sw=True
 482.6 EasyCraft: the realistic pack is in (realistic.a24a7f14f5.pck)
 482.7 EasyCraft: the realistic pictures are here (the blocks show realistic; 112 ms)
 482.8 EasyCraft: the music pack is in (music.a29511ee1e.pck)
=== after the refresh: 0.00 MB over the network ===
```

**A phone's GPU (ETC2 only):** the same Chrome with S3TC hidden from WebGL (a script before the page; its WebGL then
offers `WEBGL_compressed_texture_astc WEBGL_compressed_texture_etc WEBGL_compressed_texture_etc1`): the page took
`index.mobile.pck` (`window.easycraftGpu` = `etc2`), the game fetched `realistic.mobile.943caf1fcb.pck` and never the
S3TC one, and a REALISTIC profile shows the ETC2 pictures (the photo sky and blocks in the screenshot):

```
   0.3 NET 200 index.mobile.pck sw=True
  45.1 EasyCraft: downloading the realistic pack (realistic.mobile.943caf1fcb.pck, 36488260 bytes)
  94.1 EasyCraft: the realistic pack is in (realistic.mobile.943caf1fcb.pck)
 229.7 EasyCraft: the realistic pictures are here (the blocks show realistic; 131 ms)
```

(Its second visit downloaded the pack again: the page was left right after "is in", before the browser had copied
the 36 MB into IndexedDB. A tab closed in that moment costs one more download at the next visit; a `.part` or a
missing file is never loaded.)

**`tools/web_check.py` (the lead's, on the final build after merging `lead-merge` at `563f0ca`), 200 s:** "the music
pack is in", "the realistic pack is in", and after the refresh both from the device, **0.00 MB** over the network.
With 90 s headless Chrome is too slow for the second pack (it lands ~85-90 s after PLAY there).

## For the lead: check on a real device

- [ ] Chrome on this PC (visible): first visit, the Network tab shows `realistic.<h>.pck` after `music.<h>.pck`,
      once; Application → IndexedDB → `/userfs` has both under `packs/`.
- [ ] The emulator's Chrome (ETC2 only): the page takes `index.mobile.pck`, the game `realistic.mobile.<h>.pck`
      (`window.easycraftGpu` is `etc2`); SETTINGS → REALISTIC shows the realistic blocks and sky.
- [ ] SETTINGS → REALISTIC right after the start (before the pack): the note beside the buttons, the pixel pictures;
      in a world, the world turns realistic by itself when "the realistic pack is in"; FPS counter: the one pause.
- [ ] A refresh: 0 MB over the network, "the realistic pack is in" and "the realistic pictures are here" from the
      device.
- [ ] An iPhone (the server's copy): the same, and that Safari does not reload the tab (memory, ruling 5).

## Tests and the full suite

New: `tests/unit/test_realistic_pack.gd` (8), `tests/integration/test_realistic_before_the_pack.gd` (12), and in
`test_web_content.gd` (+8), `test_web_glue.gd` (+2), `test_chat_commands_run.gd` (+1): 31. **Full suite** (`tests/run_tests.sh`,
2026-09-28, 1165 s, on `a8c42d1`, after merging `lead-merge` at `563f0ca`): **6324 of 6326 pass**, none fails; the 2 risky
ones are the known never-asserting generator tests (`test_the_column_cache_changes_nothing`,
`test_chunks_meet_without_seams`).
