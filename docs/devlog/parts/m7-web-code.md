# M7 Tasks 4 and 5: web-safe game code and saves that survive a reload (notes, 2026-09-27)

Plan `docs/superpowers/plans/2026-09-27-m7-web.md`, spec §20.3. Done by a background agent in its own worktree
(`worktree-agent-a3c7b043badab222e`, from `lead-merge` at `cfe263a`). No editor, emulator, adb, godot-mcp or web
export; `export_presets.cfg`, `addons/zylann.voxel/*`, `tools/build_voxel_web.sh`, `tools/web_serve.py` and the
`[voxel]` section of `project.godot` untouched. Every change test-first (RED seen for the reason named, then GREEN).
How it works now: `docs/DEVELOPMENT.md` §5, "Web: one platform rule and what differs in a browser".

## What was built

| Part | What | Tests (RED: why it failed first) |
|---|---|---|
| `PlatformRules` (`core/platform/platform_rules.gd`) | One rule for Android, the desktop and the browser: `touch_device`, `touch_ui`, `captures_mouse`, `lan_available`, `can_quit`, `photo_save`, `starts_low_graphics`, `can_vibrate`, `reads_safe_area`, `syncs_storage`, `autosave_seconds`, `shows_stand_ins`, over a features dictionary; `current()` reads this device once; tests set `simulated`. | `tests/unit/test_platform_rules.gd` (14; RED: class not declared). |
| `WebGlue` (`core/platform/web_glue.gd`) | Every `JavaScriptBridge` call, each behind `OS.has_feature("web")`: the finger-pointer probe, the page's host, the photo download, `navigator.storage.persist()`. | `tests/unit/test_web_glue.gd` (2; RED: class not declared). |
| `WebStorage` (`core/platform/web_storage.gd`) | `sync()` writes `user://web_sync.txt` in a browser; `sync_when_written(tracker)` waits (a static coroutine, at most 10 s) for a Voxel save tracker, then syncs; `ask_persistent()` once per run. | `tests/unit/test_web_storage.gd` (9; RED: class not declared). |
| World saves (`WorldService.save`, `save_and_wait`) | Both push the world to the browser's storage once the blocks are written. Every save point (60 s autosave, now 20 s in a browser; the pause menu; SAVE & QUIT; focus out; the sleep and portal saves) goes through them. | `tests/integration/test_web_world_saves.gd` (3, the real VoxelTerrain and SQLite stream; RED: no stamp after `save_and_wait` or `save`). |
| LOW on web phones | `ProfileData.first_start(ram, cores, low)`; the Profile autoload passes `starts_low_graphics`. Only a new profile's default. | `test_low_preset.gd` (+1; RED: too many arguments). |
| Online server | `OnlineConfig.server_for_build(..., page_host)`: a web release build keeps `RELEASE_SERVER` (tested now); a developer web build the host that served the page. | `test_online_config.gd` (+2; RED: too many arguments). |
| No LAN, no quit in a browser | `Session.host_lan/join_lan` return `ERR_UNAVAILABLE` and stay solo; the developer menu hides HOST LAN, JOIN and the address field and says "No home Wi-Fi play in the browser: use PLAY ONLINE."; Back on the main screen never quits (`menu.quit_game`, a seam for tests); the grown-ups' delete page no longer promises home Wi-Fi play there (`DeleteAccountPage.stays_words`). | `tests/integration/test_web_lan.gd` (8; RED: `stays_words` missing; then OK instead of ERR_UNAVAILABLE, HOST LAN / JOIN / the field still there, no PLAY ONLINE line; the quit test's RED was the real `quit()` ending the run). |
| Photos in a browser | `save_way` `download`: the shutter writes no file and keeps the photo (the Memory Book still reads `last_png()`); `last_path` is the download's name `EasyCraft_<timestamp>.png`; the words say "Photo taken! Tap DOWNLOAD to keep it." (or "Photo taken!"); the chip reads DOWNLOAD and shows only where `PhotoRules.may_share` allows; `PhotoShare.share(..., way)` offers the file (`WebGlue.download`); "Your photo is downloading!"; the finger hint on phone browsers. | `tests/integration/test_web_photo.gd` (6; RED: no `button_label` / 3-argument `share`; then a file written, the full path, the desktop hint, no DOWNLOAD chip). The existing photo tests (44) pass unchanged. |
| Routing | Touch HUD (`sandbox.gd`, `visit_world.gd`), the click that captures the mouse (`sandbox.gd`), the panels that free it (hub, totem, shop, farm), the safe area (`hud.gd`), vibration (`Feel.buzz_ms`), the Theater's stand-in (`theater_panel.gd`), the web autosave, the boot-time storage request (`scenes/main.gd`). | `tests/integration/test_web_routing.gd` (4; RED: no `Feel.buzz_ms`, the Theater's `is_mobile` false in a browser) and `test_visit_world.gd` (+2; RED: no thumb stick in a phone browser). |

**Full suite** (`tests/run_tests.sh`, 2026-09-27 23:55, 981 s): **6067 of 6069 pass**, the 2 risky ones the known
never-asserting generator tests (before: 6016 of 6018; 51 tests are new). Three wording-only edits after it (a doc
comment, a wrapped signature, a JS string split over lines) re-ran their files: 74 of 74.

## Found on the way

- **`DisplayServer.is_touchscreen_available()` can't tell a phone browser from a desktop one.** The project has
  `input_devices/pointing/emulate_touch_from_mouse=true`, and the engine then answers yes on a desktop: probed headless
  on this PC (`touch=true emulating=true`). The web display server's answer is the page's `'ontouchstart' in window`
  (seen in the 4.7.2 template's `godot.js`) or, as far as the engine source goes, that same emulation, so a desktop
  browser would say yes too. A browser's touch screen is therefore its main pointer being a finger
  (`matchMedia('(pointer: coarse)')`), asked through `WebGlue.coarse_pointer()`.
- **Godot's IndexedDB copy starts from the main loop** (engine source, matching the lead's browser check): a closed
  `FileAccess` write under `/userfs` sets a flag, and the next main-loop iteration syncs the whole `user://`
  (`godot_js_os_fs_sync`, one at a time, again if more writes came meanwhile). The 4.7.2 template mounts IDBFS without
  Emscripten's `autoPersist` (`FS.mount(IDBFS, {}, path)` in `godot.js`), so nothing else copies files.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A browser's DOWNLOAD sits behind the grown-up photo switch, and the shutter keeps the photo in the game with no
   file** (the lead's reading of §20.3: "offered as a download, still behind the switch"). A browser's `user://` is
   hidden in its storage, and photos there (1-3 MB each) would crowd the IndexedDB the worlds live in, where a full
   quota could stop world saves. *Cost if wrong:* a child whose switch is off keeps no photo outside the game in a
   browser; if the owner wants every photo downloaded at the shutter (as Android's gallery), it is one call in
   `PhotoMode._save` (`PhotoShare.share(png, path, save_way)` after the save) and one test.
2. **A browser's touch screen is a coarse main pointer** (plus `web_android` / `web_ios`), not "any touch screen".
   *Cost:* a Windows laptop with a touch screen gets keyboard and mouse (its trackpad is the main pointer), which suits
   it; a touch-only Windows tablet reports a coarse pointer and gets the touch HUD.
3. **Web phones and tablets start on LOW; a desktop browser is judged like any device** (`for_device`, from
   `hardwareConcurrency`; a browser reports no memory). *Cost:* a strong phone starts lower than it could; the child
   can raise it and the choice stays (Task 8 tunes the defaults).
4. **A browser saves its world at least every 20 s** (`WEB_AUTOSAVE_SECONDS`, the rest keep 60 s): a tab can be closed
   or reloaded without a pause notification. *Cost:* each save copies the changed files (the world database whole) to
   IndexedDB; on a big world on a slow phone that may show as a hitch every 20 s (Task 3/8 measure it).
5. **No stamp after profile saves.** The profile is written with `FileAccess` (`JsonStore.write_atomic`: a temp file
   closed, then renamed in the same frame), which already makes Godot copy all of `user://` on the next frame. *Cost:*
   none seen; adding `WebStorage.sync()` to `Profile.save` would be one line.
6. **The safe area stays the phone game's.** A page keeps its canvas inside the browser's safe area unless its shell
   sets `viewport-fit=cover`. *Cost:* if the page shell (Task 6) uses `viewport-fit=cover`, the HUD needs the CSS
   `env(safe-area-inset-*)` insets through `WebGlue`.
7. **A developer web build signs in to the host that served the page** (a release build to `RELEASE_SERVER`).
   *Cost:* none for players; a debug export served from another machine than the Nakama server finds no server.
8. **The Theater treats a browser as a phone without a webview** ("coming soon"; the Theater is off everywhere until
   the owner turns it on). *Cost:* none until the Theater opens; then a web player needs its own player (later).
9. **Not routed:** Play Billing (`ShopService`), local notifications (`FarmNotifier`), Play Age Signals (`AgeSignals`)
   stay Android-only by `OS.has_feature("android")` / `OS.get_name()`, which is right in a browser (the shop is off
   everywhere anyway); `scenes/main.gd`'s developer-arg guards; `OnlineConfig`'s emulator host for Android debug
   builds.

## For the lead: check in a real browser

- [ ] **A reload keeps a block edit** (Chrome on this PC and on the emulator): build, open the pause menu (it saves) or
      wait 20 s, reload: the block is there. Also: build, reload at once, no pause: the edit may be lost if the 20 s
      autosave had not run (expected; say if it should be tighter).
- [ ] The console at boot says `EasyCraft: storage persisted = true|false` (Chrome: true once installed or engaged;
      Firefox shows its permission bar once).
- [ ] **Touch HUD on a phone browser** (the emulator's Chrome; the owner's iPhone Safari later): thumb stick, jump,
      buttons; a tap never asks for pointer lock. An iPad (Safari says "Macintosh") also gets it.
- [ ] **Desktop browser: keyboard and mouse**: a click captures the mouse (pointer lock), panels (hub, totem, shop,
      farm) free it; no thumb stick.
- [ ] **No LAN anywhere in the browser**: the developer menu (a debug export; triple-tap the version) has no HOST LAN /
      JOIN / address, and shows the PLAY ONLINE line; online play (PLAY ONLINE) signs in (release build: the release
      server over wss; debug: `page_host`'s port 7350, where Nakama must answer CORS since the page's port differs).
- [ ] **Photo download**: with the grown-up switch ON (PLAY & PHOTOS), photo mode shows DOWNLOAD beside the shutter; a
      shot says "Photo taken! Tap DOWNLOAD to keep it."; DOWNLOAD saves `EasyCraft_<date>_<time>.png`. Switch OFF: no
      chip, "Photo taken!".
- [ ] **A new profile on a phone browser starts on LOW** (SETTINGS shows LOW; raising it stays after a reload).
- [ ] Vibration on Chrome for Android (a hit, a knock-out) with Vibration on; nothing on an iPhone.
- [ ] Back gestures and the browser's Back button never leave a dead canvas (there is no QUIT; SAVE & QUIT goes to the
      menu).
- [ ] Risk to watch: **a hidden tab doesn't run the main loop** (requestAnimationFrame stops), so a sync that a write
      queued just before the tab hid starts only when it is shown again. Switching away and killing the tab from the
      phone's app list may lose the last seconds. If that shows, a `visibilitychange` hook in the page shell that
      calls `FS.syncfs` directly would close it.
- [ ] Risk to watch: a sync that starts (after the world meta's JSON write) while the voxel threads are still writing
      the SQLite file copies a half-written database; the stamp's sync right after the blocks are done copies it again
      whole. Only a tab killed between the two would keep the torn copy.
