# The same game everywhere: the Android apps update their game from our server (owner #123) — the agent brief

The owner (2026-10-17 22:00-22:08, #123): "why phone and windows version of the game, using online play are
different" … "make windows and phone use same version always" … "i mean game version but of course mobile should be
mobile". Today the web game (Windows, Mac, phones' browsers: https://178-104-20-64.sslip.io/play/ and GitHub Pages) is
deployed from the newest code almost every day, while an installed Android app changes only when a new APK is
installed: Google Play has 1.0.1 (27 Sept; every later upload waits for the owner's drag and yes, then review). So a
phone and a PC run different games, online too. **The goal: every install of EasyCraft runs the same game version as
the web, always, within a day of a deploy, without a store update**; each platform keeps its own form (the phone's
touch controls and mobile graphics, the Quest's VR, the web's). Work autonomously; do not ask questions (decide, and
write each ruling down with what it costs if wrong).

## What exists (read first)
- `docs/DEVELOPMENT.md`: the Android exports (presets "Android" debug, "Android Phone" release APK `com.giorgi.game`,
  "Android Play" AAB `com.giorgi.easycraft` with the Gradle build, "Quest" `com.giorgi.easycraft.quest` with the
  Gradle build), the web exports (`tools/export_web.sh`, `tools/export_web_vr.sh`) and deploys
  (`tools/deploy_web.sh`, `deploy_web_vr.sh`, `deploy_web_github.sh`: static files to the server's
  `~/easycraft/server/deploy/play/` and `vr/`, served by Caddy at `/play/` and `/vr/`), the web's runtime packs
  (`AssetsPack`, `packs.json`, `realistic.*.pck`: the game already loads packs at run time on the web).
- `core/platform/build_info.gd` and `tools/write_build_info.py` (the lead, #123, today): every export writes
  `data/build_info.json` (commit, date, `net`: online play's fingerprint); the menu shows "v1.0.6 (17 Oct, 90e976cc)".
- The lead is building beside you **online play's version check** (`net/nakama_link.gd`, `autoloads/session.gd`,
  `core/net/net_version_check.gd`): when two games' `net` differ, the guest is told to update or restart. Don't touch
  those files; your updater makes that message rare.
- Godot 4.7.2: `ProjectSettings.load_resource_pack(path, replace_files)`, PCK patch export (`--export-patch <preset>
  <path>` with `--patches <base packs>`, Godot 4.4+), `--main-pack`, `Crypto` (RSA sign and verify), `HTTPRequest`.

## Build
1. **Spike first (report it before building, in the notes' first section and your first commit):** on this PC, with a
   tiny headless project or the game itself, find out what a pack loaded at run time can change: a changed script, a
   new `class_name` script (Godot reads `.godot/global_script_class_cache.cfg` at start-up: does a pack's newer cache
   take effect?), a changed autoload script, a new autoload or input action (project.binary), a scene, JSON data, a
   texture; and whether the first autoload can load the pack before the others' scripts load. Then pick the pattern:
   (a) **a patch pack loaded by the first autoload** (small downloads: only the files changed since the installed
   APK's own build), (b) **a whole main pack** the Android side starts with (`--main-pack`, through our Gradle build's
   activity: the Gradle template is ours for "Android Play" and "Quest"; "Android Phone" can switch to Gradle), or (c)
   both (a patch normally, the whole pack when a release changes what a patch can't). Report the pattern picked, the
   one rejected, and why, with the spike's evidence.
2. **The updater** (`autoloads/updater.gd` as the **first** autoload, kept free of class_name dependencies; pure rules
   in `core/platform/update_rules.gd` with their tests): at start, if a downloaded, verified pack for **this app's own
   base** (its version code and engine version) is waiting, it is used; then, in the background once the menu shows,
   it asks the server's manifest for the newest game, downloads what this base needs, verifies it and keeps it for the
   next start. A child never waits on a download; a calm line on the menu says "A new EasyCraft is ready: it starts next
   time" (and a RESTART button only where restarting works). Mobile data: download on any network but small (a patch);
   a whole pack only on Wi-Fi unless the grown-ups' settings say otherwise (a ruling).
3. **Safety:** HTTPS from our server only; the manifest **signed** (RSA with `Crypto`; the private key in
   `~/.config/easycraft/update-signing.pem`, created by you, chmod 600, never committed; the public key in the game);
   each file's SHA-256 checked before use; a pack that fails to start the game (a crash before the menu, counted at
   start) is dropped and the app falls back to its own build; a manifest names the lowest base it supports, so an app
   too old to take a pack keeps its own build (and online play's check then says to update from the store).
4. **The deploy makes it** (`tools/export_android_update.sh` + `tools/deploy_android_update.sh`, or added to the
   existing scripts): from the same commit as the web: for each supported base (the APKs in the wild that have the
   updater: their own base packs kept in `build/android/bases/`), the patch (or the whole pack) for phone and for Quest
   (texture formats and feature tags must be each app's: ETC2, `android`, the Quest's `xr`), the signed manifest, copied
   to the server's deploy folder (e.g. `~/easycraft/server/deploy/play/android/` and `…/quest/`: static files in the
   folders Caddy already serves: **no Caddy or server config change**; if you find one is needed, stop at that point and
   say so in the report: it needs the owner's go). Not run against the live server by you: write the scripts, test them
   with `--dry-run` and a local folder; the lead runs the first live deploy.
5. **The release rule** in DEVELOPMENT.md and CLAUDE.md: every deploy publishes the web, VR, the Android update packs
   (phone and Quest) from one commit; a new APK/AAB (a new base) only when the engine, a native plugin, the Android
   manifest or project.binary-only changes require it; the store's AAB carries the updater so a new install updates
   itself on first start.
6. Tests: the rules (manifest parsing and signature, choosing what to download for a base, falling back after a bad
   start, the Wi-Fi rule), the updater's flow with a fake downloader and a local folder; the scripts' dry runs. On this
   PC: export a base APK pack and a patch from two commits, load the patch the way the app will (headless), and show the
   newer game starts (its `build_info` commit) — the lead checks it on the emulator and the Quest.

## Allocation and rules
- Yours: `autoloads/updater.gd` (and its line first in project.godot's autoloads), `core/platform/update_rules.gd`,
  `core/platform/update_*.gd`, `ui/menus/update_note.gd` (or a small marked hook in `ui/menus/menu.gd`), the Android
  build template's activity if you pick (b) (`android/build/...`, marked "owner #123"), tools `tools/*android_update*`,
  tests `tests/**/test_update*.gd`, notes `docs/devlog/parts/same-version.md`, DEVELOPMENT.md's release section,
  CLAUDE.md's release line. Not yours: `net/*`, `autoloads/session.gd` (the lead's version check), anything of **Play
  G0** (`core/play/*`, `entities/play/*`, `ui/play/*`, `ui/school/*`'s flow, `core/school/curriculum.gd`) or **the Glow
  Caves** (`world/universes/glow*`, block page 45, ids 768-783).
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (export-pipeline,
  mobile-development, save-load, godot-debugging); `--import` after new class_name scripts; logs `samever_*` in the
  session scratchpad; the FULL suite once at the end, right after merging lead-merge. Never open the editor or an
  emulator, never touch adb; never merge into lead-merge or push; no downloads (Godot's export templates for 4.7.2 are
  already on this PC); never start agents; never deploy to the live server; no Caddy/server changes. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (the spike's evidence; the pattern; what a child sees; the download sizes measured for a typical day's change;
the safety rules; the rulings and their costs; Google Play's policy on code loaded at run time and why this fits it
(Device and Network Abuse: interpreted code exemption), for the owner; what the lead must check on the emulator, the
Quest 3 and the live server). Report: branch, commits, the pattern, sizes, the full suite's result.
