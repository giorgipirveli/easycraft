# M7: a small first download, the music afterwards (notes, 2026-09-28)

The owner (2026-09-28): "is it possible to make first download small, then after starting a game download continues
in background to full game, do we need everything at the start of the game? it requires a lot time to wait". A first
visit downloaded about 53 MB, 21 MB of it music. The lead exports the web build as two packs: `index.pck` without the
background music, and a **music pack** (a Godot resource pack) listed in `packs.json` next to `index.html`. This part
is the game side: fetch the pack in the background after the start, load it, and make the music work before and after.

Done by a background agent in its own worktree (`worktree-agent-a8ee5623a5ef15a3c`, from `lead-merge` at `0a80da8`).
No editor, emulator, adb, browser or export; `export_presets.cfg`, `web/shell.html`, `tools/*web*`, `addons/*` and
the server untouched. Every change test-first (RED seen for the reason named, then GREEN); the loader's and the IO's
tests were also mutation-checked (each deliberate break of a rule made a test fail; two tests were tightened and two
added until all did). How it works now: `docs/DEVELOPMENT.md` §5, "Web", the bullet "Music that comes later".

## The contract with the export (the lead's side)

- `packs.json` next to the page (`location.href` without its last part):
  `{"version": 1, "packs": [{"name": "music", "file": "music.<shorthash>.pck", "size": <bytes>}]}`.
  `version` must be the JSON number 1 and `packs` an array (otherwise the whole file counts as missing: tried again
  later); `file` must be a plain file name `"<name>.<anything>.pck"` and `size` a number above 0 (an entry that isn't is
  skipped); `size` is the **uncompressed** `.pck`'s size in bytes, exactly (the download is checked against it; Caddy
  may send `.br`/`.gz`, the browser un-compresses before the game sees a byte). A new file name whenever the content
  changes. The lead's export (2026-09-28: every `res://assets/music/**/*.ogg` except `day`/`night`/`boss` into
  `music.<hash>.pck`) matches this.
- In a browser the files in the pack are not in `index.pck`; the game loads the pack with
  `ProjectSettings.load_resource_pack(path, false)`: files `index.pck` already has (e.g. a `project.binary` or
  `uid_cache.bin` an export adds to every pack) stay as they are.
- The pack's name `music` is `Music.PACK` (the Music autoload listens for it).

### The music pack's files (23 files, 20,299,597 bytes of `.ogg`)

Everything under `res://assets/music/` **except** `day.ogg`, `night.ogg`, `boss.ogg` (1,867,222 bytes; `preload`ed by
`autoloads/music.gd`, they stay in `index.pck`). With each file its `.ogg.import` and imported data go too (an export
filter on the source path does that); a stray `.import` left in `index.pck` would make `ResourceLoader.exists` say yes
and the piece would fail to load (silence for that piece), so check the main pack has neither.

| File | Bytes |
|---|---|
| `res://assets/music/classical/air.ogg` | 1,274,625 |
| `res://assets/music/classical/bumblebee.ogg` | 603,398 |
| `res://assets/music/classical/figaro.ogg` | 1,252,908 |
| `res://assets/music/classical/fur_elise.ogg` | 902,853 |
| `res://assets/music/classical/goldberg_aria.ogg` | 938,136 |
| `res://assets/music/classical/gymnopedie.ogg` | 1,148,868 |
| `res://assets/music/classical/minute_waltz.ogg` | 702,501 |
| `res://assets/music/classical/moonlight.ogg` | 921,554 |
| `res://assets/music/classical/morning_mood.ogg` | 1,184,841 |
| `res://assets/music/classical/mountain_king.ogg` | 1,209,170 |
| `res://assets/music/classical/nachtmusik.ogg` | 816,660 |
| `res://assets/music/classical/ode_to_joy.ogg` | 1,033,073 |
| `res://assets/music/classical/snow_dancing.ogg` | 814,384 |
| `res://assets/music/classical/spring.ogg` | 1,051,378 |
| `res://assets/music/classical/symphony_40.ogg` | 876,188 |
| `res://assets/music/classical/waltz_flowers.ogg` | 1,250,465 |
| `res://assets/music/classical/winter_largo.ogg` | 1,173,951 |
| `res://assets/music/candy_day.ogg` | 255,769 |
| `res://assets/music/candy_night.ogg` | 127,561 |
| `res://assets/music/desert_day.ogg` | 696,247 |
| `res://assets/music/desert_night.ogg` | 705,301 |
| `res://assets/music/frost_day.ogg` | 979,459 |
| `res://assets/music/frost_night.ogg` | 380,307 |

As export filters: exclude `assets/music/classical/*, assets/music/candy_*, assets/music/desert_*,
assets/music/frost_*` from the main Web preset (plus any `assets/music/dragon_*` if the Dragon Realm ever gets its own
loops; it has none today), and export exactly those as the pack. Checked: nothing `preload`s a moved file (the only
music `preload`s are the three core loops in `autoloads/music.gd`); the universe loops are path strings
(`world/universes/{candy,desert,frost}.gd`), the pieces `MusicPieces.path(id)`; no `.tscn`/`.tres` refers to any music
file. `tools/measure_audio.gd` `load`s the pieces, a desktop tool only.

## What was built

| Part | What | Tests (RED: why it failed first) |
|---|---|---|
| `MusicPieces.present(id)`, `file_present(path)`, `all_present()`, `exists_check` | Whether a music file is in the game now (`ResourceLoader.exists`; tests pretend with `exists_check`). | `tests/unit/test_music_before_the_pack.gd` (9; RED: members missing, then the plan picking absent pieces). |
| `MusicPlan` | Picks only pieces that are in; where a piece would play and none of the mood's is in, the mood's core loop stands in (MENU/MORNING/DAY: day, NIGHT/UNDERGROUND: night, BOSS: boss) in every style: no silence, no "Now playing". A loop standing in tries a piece again after `MIX_LOOP_TIME` (150 s), and a mood change does at once in CLASSICAL; the loop playing is never cut. `/music next` has nothing to skip to. | same file (the RED list: the menu, each mood, 20 minutes with no gap, skip, the next turn after the pack, only present pieces chosen). |
| `Music` | `use_tracks` gives a universe loop that is not in Green Meadows' (at Green Meadows' level); `on_pack_loaded("music")` loads each missing universe loop on the loader thread (never in a frame: a 1 MB loop takes 5-20 ms here, more on a phone) and gives it to its track from its next start (a silent player as soon as it is loaded, a playing one when it has faded out), and emits `more_music_arrived`; `more_music_coming()`; `use_tracks` and `reset` take and drop loads still going. `PACK := "music"`. | `tests/integration/test_music_pack.gd` (7; RED: `more_music_coming`/`on_pack_loaded`/`PACK` missing, the Candy Kingdom's day loop loaded though "missing"; then the silent loop loaded on the main thread at once). |
| `WebContent` (`core/platform/web_content.gd`) | The loader (above; DEVELOPMENT.md §5): `begin(root, f)` null off the web; `base_of(href)`, `parse_manifest(text)` (null when not a version 1 packs.json), `retry_wait(tries)`, `pack_name_of(file)`; a state machine driven by `tick(delta)` (MANIFEST → PACKS → DONE). | `tests/unit/test_web_content.gd` (28; RED: class not declared; mutation-checked). |
| `WebContentIo` (`core/platform/web_content_io.gd`) | The hands: one `HTTPRequest` (`accept_gzip` off in a browser, `download_chunk_size` 256 KiB: `HTTPRequest` reads at most one chunk a frame), file sizes, listing, rename, delete, `load_resource_pack`, `WebStorage.sync()`. | `tests/integration/test_web_content_io.gd` (5, real files and a real `.pck` made with `PCKPacker`; written after the class, then mutation-checked: 3 of 4 breaks caught, the 4th showed a redundant check, removed). |
| Boot | `scenes/main.gd` `start_packs(root)`: `WebContent.begin` + `pack_loaded` → `Music.on_pack_loaded`. `PlatformRules.fetches_packs` (web). `WebGlue.page_url()` (`window.location.href`). `LoadingCard.GROUP` (`world_loading`). | `test_web_content.gd` (RED: `start_packs` missing). |
| Settings | "More music is on its way…" beside Song names while `Music.more_music_coming()`; hides on `more_music_arrived`. The panel still fits 1280 × 720. | `test_music_pack.gd` (+2; RED: `MORE_MUSIC` missing). |
| Chat | `/music next` says "More music is on its way…" instead of "Try /music classical!" while the pack is coming. | `test_chat_commands_run.gd` (+1; RED: `NEXT_COMING` missing). |

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The downloaded pack is kept in `user://packs/`** (the lead's plan), so later visits and offline starts have the
   music without the network. *Cost:* Godot copies all of `user://` from IndexedDB into memory before the engine
   starts, so every later boot reads ~20 MB more from the browser's storage (likely a few hundred ms on a phone), and
   the browser's storage holds 20 MB more (a full quota would fail the copy: the next visit downloads again). The
   other way (no copy; the browser's HTTP cache with a long `Cache-Control` on the hashed name) is a small change in
   `WebContent._next_pack` if the boot time shows it.
2. **Downloaded to `<file>.part`, renamed only when it has `size` bytes.** A tab killed mid-download, or a sync that
   copies a half file, never leaves a whole-looking pack; offline only whole `.pck` names load. *Cost:* none seen (the
   rename happens in the same frame as the download's close, before Godot's copy to IndexedDB).
3. **Starts 5 s of running time after boot and never while a world loads; a download already going continues during a
   world load.** The browser does the network work; the game copies at most 256 KiB a frame into the file. *Cost:* if
   the phone's world load shows a hitch while a download runs, `busy` can also hold the download (cancel and resume
   after); not seen headless.
4. **The core loops stand in; nothing is cut when the pack arrives.** In MIX the menu keeps the day loop until its
   150 s turn is over (the first piece may come only in the world); CLASSICAL tries at the next mood change or after
   150 s. *Cost:* a child who chose CLASSICAL hears game loops for up to 2.5 minutes after the pack is in.
5. **One version of a pack per run.** A pack loaded from the device while offline is not replaced when `packs.json`
   later names a newer file; the next start downloads it. *Cost:* one visit plays the older music.
6. **At most 12 tries per step per run (waits 5, 15, 30, 60, then 120 s), then it waits for the next start.** A
   download with no byte for 60 s of running time (the clock stops in a hidden tab) is cancelled and tried again.
   *Cost:* a very bad connection may need a reload to try again after ~20 minutes of failures.
7. **No download progress on screen.** Only the settings' line and `/music next` say more is coming; the game plays on
   meanwhile. *Cost:* none for play; a progress bar would need `WebContent` to expose `io.downloaded_bytes()` / size.
8. **The pack's name is part of the contract** (`Music.PACK` = `"music"`); any other pack name is loaded and told, and
   nothing listens (ready for a later "more worlds" pack).

## For the lead: check in a real browser

Export side first: the Web preset without the 23 files (and their `.import`s), the pack with exactly them,
`packs.json` with the pack's uncompressed size. Caddy already sends `Cache-Control: no-cache` for everything under
`/play/` (`server/deploy/caddy/Caddyfile`), so `packs.json`, the one file whose content changes under the same name, is
revalidated on every visit; `tools/deploy_web.sh` compresses `*.json` and `*.pck` already.

- [ ] **First visit** (Chrome on this PC, cleared site data): the menu comes as before, with the day loop; about 5 s
      later the console shows `EasyCraft: downloading the music pack (music.<hash>.pck, <size> bytes)` and then
      `EasyCraft: the music pack is in (music.<hash>.pck)`; the Network tab shows `packs.json` and the `.pck` once
      each (200). No `SCRIPT ERROR`, no `Music: cannot load` warning, before or after.
- [ ] **Before it is in:** SETTINGS shows "More music is on its way…" beside Song names (gone after the "is in" line,
      also with the panel open); CLASSICAL and MIX play the day loop in the menu, no "Now playing"; `/music next` in a
      world says "More music is on its way…".
- [ ] **After it is in:** entering a world (MIX), a classical piece comes after the day loop's turn with "Now
      playing: …"; SETTINGS → CLASSICAL then a dusk plays a night piece. In the Candy Kingdom / Sandstorm Desert /
      Frostpeak (Survivor), after the next dusk or dawn its own loop plays (before the pack: Green Meadows' loops).
- [ ] **Second visit (reload):** no `.pck` request in the Network tab (only `packs.json`); the console says the pack
      is in within ~5 s; music as above. Application → IndexedDB → `/userfs` has `…/packs/music.<hash>.pck`, no
      `.part`.
- [ ] **Offline** (DevTools → Network → Offline, reload the installed app): the game starts (service worker), then
      `EasyCraft: no packs.json yet …` and `EasyCraft: offline: the music pack on this device is in`.
- [ ] **A new pack version** (re-export with a changed piece → a new hash): the next visit downloads the new file and
      IndexedDB keeps only the new `music.*.pck`.
- [ ] **Cut off:** throttle to "Slow 3G", reload, and switch Offline for ~10 s while the `.pck` downloads: the console
      shows the failed download and a new try 5 s after going back online; the pack comes in, the game never stops.
- [ ] **Hidden tab:** start the download on the emulator's Chrome, switch apps for a minute, come back: it goes on or
      starts again (no stuck state; `EasyCraft: a download stopped moving` at most once).
- [ ] **World load:** press PLAY within the first 5 s: the download starts only after the loading card is gone.
- [ ] Measure: the first download's size (should drop by ~20 MB) and the time to the menu; the time until "the music
      pack is in" on this PC and on the emulator; any hitch while it downloads (FPS counter).

## Tests and the full suite

New: `tests/unit/test_web_content.gd` (28), `tests/unit/test_music_before_the_pack.gd` (9),
`tests/integration/test_web_content_io.gd` (5), `tests/integration/test_music_pack.gd` (7), and one more in
`test_chat_commands_run.gd`: 50. **Full suite** (`tests/run_tests.sh`, 2026-09-28, 973 s, on the final code
`5fa3442`): **6120 of 6122 pass**. The 2 risky ones are the known never-asserting generator tests
(`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`). Before this work `lead-merge` had 6072
(6069 in the M7 notes plus `test_web_http_gzip.gd`'s 3).
