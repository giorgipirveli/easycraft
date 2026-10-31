# The same game everywhere: the Android apps update their game from our server (owner #123)

The owner (2026-10-17 22:00-22:08, #123): "why phone and windows version of the game, using online play are different" …
"make windows and phone use same version always" … "i mean game version but of course mobile should be mobile". The
brief: `docs/superpowers/plans/2026-10-17-same-version-brief.md`. This agent works in the worktree branch
`worktree-agent-af739c04ed8ecefcd`, cut from `lead-merge` at `543e4607`, beside Play G0, the Glow Caves and the lead's
online version check. No editor, no emulator, no adb, no download, nothing sent to the live server. (Paused by the
owner's order at ~23:00 after the WIP commit `279b8ad3`, resumed later from there.)

**In short:** pattern (a), a patch pack loaded by the first autoload (`autoloads/updater.gd`), for every Android build
that has the updater (the phone APK, the Play AAB, the Quest APK). A day's change is a **1.2-2.6 MB download** (the whole
game: 147 MB). The manifest is RSA-signed, every file SHA-256-checked, HTTPS from our server only; two starts that never
reach the menu bring the app's own build back. Proven end to end on this PC with the real game (§6): a base pack with the
updater downloaded a newer game from a local folder in the server's place, started it next time (its commit, its version
1.0.7, a new class, a new input action), and fell back after two starts killed before the menu.

## 1. The spike: what a pack loaded at run time can change (evidence first)

Two reproducible scripts, both local only:
- `tools/android_update_spike.sh <work folder>` builds a tiny project twice (A, "the installed app", and B, "the newer
  game"), exports A's whole pack and B's patch against it (`--export-patch "Linux" b_patch.pck --patches a.pck`), then
  starts A's pack headless the way an installed app starts (`--main-pack a.pck`) without and with the patch, which its
  **first autoload** loads in `_init` with `ProjectSettings.load_resource_pack(path, true)`; and B's whole pack as the
  main pack, for comparison. Log of the run: `samever_spike1.log` (session scratchpad).
- `tools/android_update_spike_http.sh <pack> <work folder>` serves a pack from 127.0.0.1 the way Caddy's
  `precompressed gzip` sends `/play/` files and downloads it with `HTTPRequest` (`use_threads`, `download_file`,
  `accept_gzip`), then hashes it.

What A + B's patch did (Godot 4.7.2, every line from the run):

| B changed | With B's patch loaded by A's first autoload | B's whole pack as `--main-pack` |
|---|---|---|
| a script with a `class_name` (`Foo`) | **B's** (`Foo B`) | B's |
| a **new** `class_name` script (`Bar`), used by another new script | **works**: the global class list is `[Bar, Foo]` right after the load (Godot re-reads the pack's `.godot/global_script_class_cache.cfg`), `bar_user.gd` compiles and `Bar.who()` answers | works |
| the second autoload's script | **B's** (`second.gd … version B`): the first autoload's `_init` runs before the engine has even loaded the second one's script (`second.gd loaded yet = false`) | B's |
| a scene (`sub.tscn`, 1 → 3 children), JSON data, a texture (16 → 32 px) | **B's** (3, `data B`, 32) | B's |
| a new file found only by its uid | **loads** (the pack's `uid_cache.bin`) | loads |
| a file B deleted | **gone** (`still there = false`: a 4.7 patch carries a 0-byte "deleted" entry) | gone |
| the version, a new input action (project.binary) | **not** in `ProjectSettings` (still 1.0.0, no action): the engine read project.binary before any script ran. But `res://project.binary` *as a file* is now B's, and decoding it (`bytes_to_var_with_objects` per setting) then `ProjectSettings.set_setting` + `InputMap.load_from_project_settings()` gives the new action (`J`) at once | in |
| a new autoload (`Third`) | **not made** (the autoload list is project.binary's, fixed at start) | made |
| the first autoload's own script | A's (it is already running) | B's |

- `load_resource_pack` of the patch: 0.18 ms (tiny pack). In the real game, the load is at start, before anything else.
- **The download (part 2):** the server sent `game.pck.gz` (2,436,775 bytes) for `Accept-Encoding: gzip, deflate`
  (Godot sends that by itself), `HTTPRequest` wrote the **un-compressed** 4,466,892 bytes to `download_file`, and their
  SHA-256 equals the original's. 47 ms on 127.0.0.1 over 7 frames (a thread). Hashing the 4.5 MB file: 23 ms on this PC
  (a phone 3-5× slower: ~0.1 s), so a patch can be checked at every start; a whole pack (147 MB) would take ~0.75 s here and
  2-4 s on a phone. HTTPRequest has no brotli: the deploy sends `.gz` beside each pack.

The real game, "Android Phone" preset (ETC2, `android`), on this PC:
- the whole phone pack of `543e4607`: **147.4 MB**, exported in 17-23 s; it runs headless here with `--main-pack` (the
  voxel library reachable beside it) to `MENU ready_ms=7977`.
- **determinism:** a second export of the same tree against the first is "No files or changes to export" (exit 1), so a
  patch has only real changes. The "Android" (debug) and "Android Phone" (release) presets export **identical** files
  (5090, same sizes and MD5s), and a debug APK of the same commit holds every one of them under `assets/` with the same
  MD5 (5090 of 5090; the APK adds `assets/_cl_` and `assets/assets.sparsepck`). Godot 4.7 also takes the APK itself as the
  patch base (`--patches game.apk`: "No files or changes" against its own commit). So **a base = the whole pack exported
  from the commit and preset of an APK/AAB** (kept in `build/android/bases/`), for the debug APK, the phone APK and the
  Play AAB alike.
- **a typical day's change**, measured on lead-merge's real history:

| From → to | What changed | Patch (raw) | Download (gzip -9) | Files |
|---|---|---|---|---|
| `cf01cb83` (10-16 23:01) → `543e4607` (10-17 22:12), **one day** | grade 7-8 School, Life L3a-c, Success S2-S3 (135 commits) | 4.47 MB | **2.44 MB** | 357 |
| `8a891642` (10-17 09:16, a deploy) → `90e976cc` (17:43, the next deploy) | Life L3b, L3c, grade 8 subjects (53 commits) | 2.52 MB | **1.25 MB** | 169 |
| the Quest ("Quest" preset): `cf01cb83` → `9c1fc378` (this branch, 145 commits) | the same day, the updater | 4.66 MB | **2.60 MB** | 377 |
| the proof's change (§6): a menu line, a new class, the version, an input action | | 0.38 MB | **0.09 MB** | 7 |
| the whole phone game (for comparison) | | 147.4 MB | | 5090 |

  The biggest files of the day's patch: the global class cache (215 KB), `scenes/sandbox.gdc` (120 KB), the School's
  generated grade 7-8 files (60-110 KB each), the uid cache (96 KB).
- **How often a patch cannot carry a day's change** (project.godot since the Play build 1.0.1, 2026-09-26): 4 version
  bumps, 5 input-map changes (the rocket's keys, game controllers, the prospecting J, the Inventions), 1 new autoload (`Vr`,
  10-15, which came with the brand-new Quest app anyway), and settings for the web (`.web`, `.webxr`) or the Quest (`.quest`)
  only. With the version and the input map taken from the pack's project.binary, **every Android-relevant change of those
  three weeks but one (the new autoload) fits in a patch.**

### The pattern: (a), a patch pack loaded by the first autoload. Rejected: (b) and (c)

**Picked: (a).** `autoloads/updater.gd` is the first autoload; in its `_init` it loads a downloaded, verified patch for
this app's own base with `load_resource_pack(path, true)`, then sets the version and the input map from the pack's
project.binary. Why:
- it carries everything a day's deploy changes (the table above: scripts, new classes, autoload scripts, scenes, data,
  pictures, deletions, the version, the input map), as **1-2.5 MB downloads instead of 147 MB**, so it can run on mobile data;
- it needs no Java and no change to the APK/AAB beyond the game's own scripts, the same for the phone APK, the Play AAB
  and the Quest APK ("Android Phone" stays a non-Gradle export), and the PC can prove it headless (the spike, and the
  end-to-end check in §6);
- the fall-back is in GDScript and simple: don't load the pack.

**Rejected: (b) a whole main pack started by the Android side** (`--main-pack` from `GodotApp.getCommandLine()`): it
would add new autoloads and start-time settings, but it means 147 MB (phone) (the Quest APK: ~185 MB) downloads, Wi-Fi only,
2-4 s of hashing at a phone's start, a Java change in the Gradle template (which is not in git: the export installs it,
`android/build/`), "Android Phone" moved to Gradle, and none of it can be checked on this PC under this brief's rules (no
emulator). Its one gain happened once in three weeks. **(c) both** is (b)'s cost for that one case. Instead, the deploy
script finds the changes a patch cannot carry (a new or changed autoload, a start-time setting, a GDExtension, a native
file, another engine) and says **"needs a new APK/AAB"**; those bases keep their own build, online play's version check
(the lead's) tells such a device to update from the store, and the release rule (§5) makes that new base. Cost if wrong:
a release that adds an autoload reaches phones only through the store (days); if that becomes frequent, (b) can be added
later on top of (a) without changing the manifest's format (a `whole` entry).

## 2. What a child sees

- **Nothing new at the start.** The app opens as fast as before: the updater checks the waiting pack's SHA-256 (a day's
  patch: ~25 ms on this PC, ~0.1 s on a phone) and loads it in well under a millisecond; nobody waits for a download.
- **On the menu, after an update has downloaded in the background** (it starts 15 s after the menu shows): the lead's
  note at the bottom, *"A new EasyCraft is ready: it starts next time"*, calm, no button, no timer. On the web the same
  note says "A new EasyCraft is ready!" with RESTART (the page reloads); an installed app cannot restart itself (Godot's
  restart-on-exit is the desktop's), so it has no RESTART (ruling 5).
- **The next time the app starts** (Android ends a game in the background within hours, a phone restarts, or the child
  swipes it away): the newer game, with its own label on the menu, e.g. "v1.0.7 (18 Oct, b0b0b0b0)", the same as the web.
- **If a new game ever fails to start twice:** the app's own build comes back by itself, silently; that game is never
  downloaded again on this device, and the next deploy's game is tried as usual.
- **An app too old for the newest game** (one whose build needs a new APK/AAB): it keeps its own game; online play's
  version check says the worlds differ and to update.

## 3. The pieces

| File | What it does |
|---|---|
| `autoloads/updater.gd` | The **first** autoload (no `class_name`; it and its three scripts name nothing else of the game: `test_updater.gd`). `_init`: on Android, this app's own build (`kind`: phone or quest by the `quest` feature; `commit`: the APK's own `data/build_info.json`, read before any pack; `version`; `engine`), `UpdateRules.start_plan`, the SHA-256 check, the try saved, `load_resource_pack(user://update/<file>, true)`, then the pack's version and input map (`apply_changes`). `menu_shown()` (the menu's note line) clears the tries and starts the background check; `has_ready()`, `status`, `running`, `fell_back`; the `update_ready` signal. Again on `NOTIFICATION_APPLICATION_RESUMED` after 3 hours. Off Android idle, unless `--update-dir=<folder>` (a developer's run on a PC; `--update-kind=`, `--update-source=<folder>`). |
| `core/platform/update_rules.gd` (`UpdateRules`) | The pure rules: the envelope and its signature, the manifest's shape, the URLs (only `https://178-104-20-64.sslip.io/play/android/` and `/play/quest/`), `plan_download` (and why nothing: up to date, already waiting, failed here, too old, no patch for this build, another engine, another app, an older manifest, waits for Wi-Fi), `may_download` (the Wi-Fi rule), `keep_ready`, `start_plan`, `drop_active`, `menu_reached`, `read_project_binary`, `project_changes`, the public key, the menu's words. |
| `core/platform/update_flow.gd` (`UpdateFlow`) | The background check: manifest → plan → download to `<file>.part` → size and SHA-256 → renamed in place → `keep_ready`. `sha256_of`. |
| `core/platform/update_fetch.gd` (`UpdateFetch`) | The downloads: HTTPRequest (its own thread, gzip, 30 s for the manifest, 30 min for a pack, a body limit), only our URLs; or a local folder laid out as the server's `play/` folder; `metered()` (Android's ConnectivityManager through `JavaClassWrapper`; unknown counts as metered). |
| `ui/menus/update_note.gd` (the lead's) + one line in `ui/menus/menu.gd` | `UpdateNote.new(Updater.has_ready, Callable()) if Updater.menu_shown() else UpdateNote.new()`: in an installed app the updater feeds the note (and learns the menu showed); with no `restart` the note says "it starts next time" and hides RESTART. |
| `tools/android_update.py` | `keygen`, `base` (keep a build: an APK or a pack, its identity from its own files), `bases`, `check` (what a patch cannot carry), `manifest` (signs with openssl; refuses to write one the game's own key would not open), `verify`. |
| `tools/export_android_update.sh` | Every deploy: the newest game's pack per kind, a patch per kept base, the check, the signed manifest (`build/android/update/<kind>/`). `base <kind> [<APK>]` keeps a build as a base (`build/android/bases/<kind>/<commit>/`). `--dry-run`. |
| `tools/deploy_android_update.sh` | Verifies each manifest with the game's key, gzips the packs, puts them on the server (packs first, `update.json` last, then old files go) into `play/android/` and `play/quest/`; `--dry-run`, `--to <folder>`. `tools/deploy_web.sh` now leaves those two folders alone (`--exclude`): its `--delete` would have removed them. |
| `tools/android_update_spike.sh`, `tools/android_update_spike_http.sh` | The spike (§1). |

The manifest (the signed text inside `update.json`'s envelope `{"key": "k1", "signed": "...", "signature": "<base64>"}`):
`{"format": 1, "kind": "phone", "serial": <the deploy's Unix time>, "engine": "4.7.2.stable", "game": {"commit",
"date", "version", "net"}, "min_base": "1.0.6", "bases": {"<a build's commit>": {"file":
"phone-<base8>-<game8>.pck", "size", "sha256"}}}`. The app's state (`user://update/state.json`): `base`, `serial` (the
newest manifest it accepted), `active` (the pack in use, with `tries`), `ready` (the next one), `bad` (games that failed
here), `big_on_mobile`.

## 4. The safety rules

1. **HTTPS from our server only:** every URL is built from `UpdateRules.SERVER` + the kind's folder and checked by
   `is_our_url` (no plain HTTP, no other host, no `..`, only plain `*.pck` names and `update.json`); Godot's TLS checks
   the certificate (Caddy's Let's Encrypt). A developer's local folder exists only off Android (launch arguments never
   reach an Android app).
2. **A signed manifest:** RSA (a 3072-bit key) over SHA-256, the private key in `~/.config/easycraft/update-signing.pem`
   on this PC (made 2026-10-17 by this agent, `chmod 600`, never in the repository: `test_update_rules.gd` checks the
   game holds only public keys), the public key in `UpdateRules.PUBLIC_KEYS["k1"]`. The deploy refuses to write a
   manifest the game's key would not open. **Back the key up** (the owner's password manager or an encrypted USB): if it
   is lost, apps in the wild can only be updated by a new APK/AAB with a new key.
3. **SHA-256 on every file, before use:** at download (with the size) and at every start before loading; a file that
   changed on the device is dropped (and downloaded again). A download goes to `.part` and is renamed only when whole.
4. **The fall-back:** the try is counted and saved before the pack loads (a crash while loading counts); the menu clears
   it; two starts that never reached the menu drop the pack and mark its game bad for this build; a pack that does not
   load is dropped the same way.
5. **Only this build's pack:** a manifest for another kind or engine is ignored, a patch is made for one base commit,
   and a new app from the store drops the packs of the old one at its first start.
6. **No replay:** a manifest with a lower serial than one already accepted is refused (an old, validly signed manifest
   sent again cannot roll a device back).
7. **The lowest supported base:** the manifest names `min_base` (the lowest version that has a patch); an older build
   gets nothing and keeps its own game ("too_old": online play's check then tells it to update from the store).
8. **No native code, ever:** the deploy's check refuses a patch with `.so`, `.dex`, `.jar`, `.aar`, `.dylib`, `.dll`,
   `.gdextension`, `addons/*/bin/*` or a changed `.godot/extension_list.cfg` (and a GDExtension could not load from a
   patch anyway).
9. **The updater cannot break itself:** its four scripts load before any pack and are the APK's own for the whole run;
   a patch that changes them takes effect only in a new APK/AAB (the deploy warns). Their API used by the game
   (`menu_shown`, `has_ready`, `enabled`, `status`) stays stable.

## 5. The release rule (also in DEVELOPMENT.md and CLAUDE.md)

- **Every deploy, from one commit:** `tools/export_web.sh`, `tools/export_web_vr.sh` and
  **`tools/export_android_update.sh`** (phone and Quest), then `tools/deploy_web.sh`, `deploy_web_vr.sh`,
  `deploy_web_github.sh` and **`tools/deploy_android_update.sh`**. Every installed app with the updater then runs that
  commit's game from its next start.
- **A new APK/AAB (a new base) only when a patch cannot carry the change:** another engine version, a native plugin or
  GDExtension, the Android manifest or the preset's options (permissions, SDK levels, the package), a project setting
  read at start (a new or changed autoload, rendering, physics, translations, the boot splash; the version and the input
  map ride in the patch), or the updater's own four scripts. `tools/export_android_update.sh` says "NEEDS A NEW APK/AAB"
  and why. The Play AAB carries the updater, so a new install updates itself at its first start.
- **When a new APK/AAB goes out** (exported after `tools/write_build_info.py`, before its `--clean`):
  `tools/export_android_update.sh base phone <the phone APK>` and `… base quest <the Quest APK>` keep it as a base, so
  the next deploys make its patch. The Play AAB's files are the phone APK's of the same commit (§1); the debug "Android"
  APK's too.

## 6. The proof on this PC (the real game, headless, a local folder in the server's place)

1. **A, the installed app:** this branch at `9c1fc378` (with the updater): `EASYCRAFT_UPDATE_BASES=build/samever/bases
   tools/export_android_update.sh base phone` → `BASE phone 9c1fc378 v1.0.6 (4.7.2.stable, code 16)`.
2. **B, the newer game:** the same tree plus a menu line printing a new `class_name` script's words, the label and a new
   input action; the version 1.0.7; build_info commit `b0b0b0b0`. Its pack, its patch against A (380,272 bytes, gzip
   87,509: 7 files, among them `project.binary`, the class and uid caches, `menu.gdc`), `android_update.py check` (OK),
   `manifest` (signed with the real key: `VERIFY … OK`), `deploy_android_update.sh --to build/samever/play`.
3. **A started headless** (`godot --headless --main-pack base.pck -- --update-dir=… --update-source=build/samever/play`,
   the logs `samever_e2e_runs.log` and `samever_e2e_runs2.log` in the session scratchpad):
   - run 1 (A's own build): `MENU ready` → 15 s → `EasyCraft: update check: ready (metered false)`; the pack kept.
   - run 2: `EasyCraft: the game of 2026-10-17 (b0b0b0b0, v1.0.7) on this app's own build 9c1fc378 (try 1)`, then the
     newer menu's own line: `SAMEVER_PROOF menu of the newer game: a class only the newer game has; v1.0.7 (17 Oct,
     b0b0b0b0); input samever_probe=true`; the check: `up_to_date`; the tries back to 0.
   - runs 3 and 4 killed 3 s in (before the menu, as crashes): tries 1, then 2.
   - run 5: `EasyCraft: the update never reached the menu twice: this app's own build again`, the menu, the check:
     `failed_here_before`; the pack deleted, `bad: [b0b0b0b0]`.

What this PC cannot show (the lead's checks, §9): Android's file system and `user://`, HTTPS from the live server
through Caddy, `isActiveNetworkMetered()`, the Quest's VR menu.

## 7. Rulings (and what each costs if wrong)

1. **Pattern (a), not (b)/(c)** (§1). Cost: a change a patch cannot carry (a new autoload: once in three weeks) waits
   for a store update on those devices.
2. **Two tries** before a pack is dropped. Cost: a broken pack crashes twice before the fall-back; a child who kills
   the app twice while it loads loses that day's update until the next deploy.
3. **The menu is the "it started" signal**, from the note's line in `menu.gd` (tested). Cost: if a later menu lost that
   line, every pack would be dropped after two starts (the test fails first).
4. **The Wi-Fi rule:** patches up to 32 MB on any network (a day is 1-2.6 MB), bigger only unmetered; a network Android
   cannot describe counts as metered; `big_on_mobile` in the state, **no settings row yet** (the settings are not this
   brief's files). Cost: a family on mobile data only waits for Wi-Fi for a big update (rare: a big media change).
5. **No RESTART in an installed app** (unverified on Android: Godot documents `set_restart_on_exit` for desktops). Cost:
   the new game waits for the next start; if the lead finds a restart that works on the emulator and the Quest, the
   note's RESTART can return there.
6. **The check starts 15 s after the menu** and again after 3 h in the background. Cost: a deploy made while a child
   plays reaches that device at its next start after the next check.
7. **A base is identified by its build_info commit** (not the version code): exports are deterministic, and the debug,
   release and Play builds of a commit hold the same files (§1). The version code goes into base.json for people.
   Cost: an APK exported from a dirty tree gets the clean commit's patch (write_build_info says so; never ship one).
8. **The version and the input map come from the pack's project.binary;** a built-in `ui_` action the pack stops
   overriding keeps its current value. Cost: such a revert waits for a new base (harmless).
9. **The update files live in the web's `play/` folder** (`play/android/`, `play/quest/`): served by Caddy's existing
   `/play/*` block, so no Caddy or server change. `deploy_web.sh`'s `--delete` now excludes them.
10. **No download resume:** a failed download starts again at the next check (patches are small).

## 8. Google Play's policy on code loaded at run time (for the owner)

Google Play's Developer Program Policy, *Device and Network Abuse* (as it read in 2025-26; check the current text before
the next upload): an app from Google Play may not modify, replace or update itself by any method other than Google
Play's update mechanism, and may not download executable code (such as dex, JAR or .so files) from a source other
than Google Play; **this restriction does not apply to code that runs in a virtual machine or an interpreter where
either provides indirect access to Android APIs** (such as JavaScript in a webview), and interpreted code loaded at run
time must not allow violations of Google Play's policies.

How this fits: the APK/AAB from Play, with its engine and every native library, never changes; only Google Play
updates it. What comes from our server is game content and GDScript, which runs in Godot's own interpreter inside the
app and reaches Android only through the engine (the "interpreted code" exemption, the same one Lua and JavaScript games
use). No dex, JAR or .so is ever downloaded: the deploy refuses a patch with native code, and Godot could not load one
from a patch anyway. The conditions to keep: every update follows every Play policy, above all the **Families policy**
(the same game as the web, made for children, no ads, no new data collection); the store listing and the content rating
stay true (an update that adds something the IARC questionnaire asks about, e.g. open chat or purchases, means updating
those answers first); and the **Data safety** form: each installed app now asks our server for `update.json` at every
start (an HTTPS request with no account, name or device id; Caddy's access log keeps the address 14 days, as for every
visit), so `docs/store/data-safety.md` should say the app connects to our server for content updates. The owner's
lawyer may want to read this section.

## 9. What the lead must do and check (the first live deploy)

**Before it:** merge this branch; back up `~/.config/easycraft/update-signing.pem`; the web's next deploys must use the
new `tools/deploy_web.sh` (its `--exclude` keeps `play/android/` and `play/quest/`).

**The first base** (a new APK/AAB with the updater; raise the version and code as usual):
1. `/usr/bin/python3 tools/write_build_info.py`; export the debug "Android" APK (emulator), the "Android Phone" APK,
   the "Android Play" AAB and the "Quest" APK from that commit; then `tools/export_android_update.sh base phone
   build/android/game.apk` (or the phone APK: the same files) and `… base quest build/android/EasyCraft-quest.apk`;
   then `… --clean`.
2. **On the emulator** (`ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554`): install the debug APK, start it,
   `adb logcat -s godot:V | grep EasyCraft`: no "updates off" line; after the menu `EasyCraft: update check: …` (before
   any deploy: `offline`, the manifest is not there yet; that is right).

**The first deploy** (the next commit, with the web):
3. `tools/export_android_update.sh --dry-run`, then `tools/export_android_update.sh`: `phone-<base>-<game>.pck` and
   `quest-…` with their sizes (expect 1-5 MB), no "NEEDS A NEW APK/AAB"; `tools/deploy_android_update.sh --dry-run`
   (VERIFY OK), then `tools/deploy_android_update.sh` after the web's deploy.
4. **From this PC:** `curl -sS https://178-104-20-64.sslip.io/play/android/update.json | head -c 300` (the envelope),
   `python3 tools/android_update.py verify <a downloaded copy>` (OK), `curl -sSI -H 'Accept-Encoding: gzip'
   https://178-104-20-64.sslip.io/play/android/<file>.pck` (200, `Content-Encoding: gzip`); the same for `/play/quest/`.
5. **On the emulator:** start the app: after the menu, logcat `EasyCraft: update check: ready (metered …)` and the
   menu's note "A new EasyCraft is ready: it starts next time" (no RESTART); `adb shell am force-stop com.giorgi.game`,
   start again: logcat `EasyCraft: the game of … (<game>, v…) on this app's own build <base> (try 1)`, and the menu's
   label shows the web's commit; play a world; join the web game online: the version check stays quiet (the same
   `net`). Note what `metered` says on the emulator's network.
6. **The fall-back on the emulator (once):** force-stop the app twice within 3 s of starting it, then start it:
   `the update never reached the menu twice: this app's own build again`; the next deploy's game downloads again.
7. **On the Quest 3** (the owner's, by its serial): the same as 5 with the Quest APK (`com.giorgi.easycraft.quest`,
   `/play/quest/`): the note on the VR menu's panel, then after the app starts again the new game in VR (the label).
8. **Optional:** try `OS.set_restart_on_exit(true)` + `get_tree().quit()` on the emulator; if the app comes back by
   itself, the note's RESTART can return for installed apps (ruling 5).

## 10. Tests

`tests/unit/test_update_rules.gd` (20), `tests/unit/test_updater.gd` (4), `tests/integration/test_update_flow.gd` (8:
a real pack made with PCKPacker, a local folder, a failing network, the start, the fall-back, the whole way; a start
that loads a pack runs in a Godot of its own, `tests/integration/update_start_child.gd`, as a phone's next start is a
new process: a loaded pack stays for the whole process, and DirAccess then lists res://'s hidden folders too),
`tests/integration/test_update_note_app.gd` (4), `tests/unit/test_update_tools.gd` (6: the Python tool's base, check,
manifest with openssl, the export script's dry run, the deploy into a local folder read by the flow);
`tests/unit/test_assets_pack.gd`'s first-autoload test now expects the updater first and AssetsPack second. Two
mutations (the start's SHA-256 check removed; every setting patchable) each turned a test red.

**The full suite** on this branch with lead-merge merged in (`801ea084`, 2026-10-18): **1268 scripts, 11,778 tests,
11,775 passing, 0 failing**, 3 risky/pending that are not this work's (two tests that assert nothing:
`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`; one pending: the move by code is off on this
server), 87 minutes (`samever_full2.log`). An earlier run (on `95a94d3f`) was stopped by me after 1 failure that was
mine: `test_success_s3_experiences.gd`'s `test_no_class_name_is_used_twice` walks every folder, and found the game's
classes a second time in this spike's measurement copies of older commits under `build/samever/tree_*` (deleted;
measure in a folder outside the project, or give such a copy no `.gd` files). It was not cut off by the memory guard.
