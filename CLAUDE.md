# EasyCraft — agent guide

This is a 3D landscape mobile sandbox and survival game for children (Minecraft/Roblox-like, with its
own magic: living buddies, Size Magic, stamps, Mirror). It is built with Godot 4.7.2 (typed GDScript)
and Voxel Tools 1.7. Android is built and tested on this PC; iOS comes later on the owner's Mac.

**Read `docs/DEVELOPMENT.md` first.** It covers the toolchain, commands, architecture, conventions,
performance budget and known gotchas.

## Where things are

| What | Where |
|---|---|
| **Resume here: current state, running agents, queue, next steps** | `docs/superpowers/plans/2026-09-24-RESUME-HERE.md` |
| Design spec (the authority) | `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` |
| Plans (**M2 complete, APK 0.3.0 delivered 2026-09-24**; current: **M3 "Worlds of Wonder"** and **M4 "Better Together"** in parallel; then M5 — all specced) | `docs/superpowers/plans/2026-09-24-m2-survive-the-night.md`, `…-m3-worlds-of-wonder.md`, `…-m4-better-together.md`, `…-m5-launch.md` |
| Engagement and child-psychology research (fair-fun rules, signature moments) | `docs/design/` |
| Owner feedback: every report, its status and proof | `docs/playtests/owner-feedback.md` |
| Dev log: what happened, measurements, rulings | `docs/devlog/` |
| Store and privacy drafts (listing, Data safety, Families/IARC, privacy policy, retention; for the owner's lawyer) | `docs/store/` |
| Notes: Voxel Tools spike, M1 and M1b acceptance | `docs/superpowers/notes/` |
| Plan ledger (git-ignored scratch) | `.superpowers/sdd/<plan>/progress.md` |

Current branch: `m2-survive-the-night` (cut from `m1b-underground`, which was cut from `m1-first-steps`;
nothing is merged until the owner says so). The owner's standing order (2026-09-24): build the whole
roadmap M2 → M5 (everything except the iOS build) without stopping between milestones.
Parallel work: independent tasks can run as background agents in git worktrees (`.claude/worktrees/`,
git-ignored), **at most 3 at once** (owner 2026-09-25 17:44: "dont run more then 3 agents same time"; before: up to 8 while more than 6 GB was free, owner 2026-09-24 19:54: "run multy agents fo the tasks that can be done in parallel, i dont care about tokens"; earlier the cap was 3 after the owner noticed the PC overloaded;
`tests/run_tests.sh` runs Godot under `nice` and waits for one of **3 PC-wide suite slots** (`tests/suite_slots.sh`, `EASYCRAFT_SUITE_SLOTS`): on 2026-09-24 at 22:14, nine full suites at once pushed the load to 63 on 24 cores, and **another app with its own emulator is built on this PC at the same time** (the owner, 22:14). Give each agent fixed allocations (block/item ids, atlas tiles, HUD spots), no editor or
emulator use, and a notes file in `docs/devlog/parts/`. The lead merges, fixes the integration and
verifies in the editor and on the emulator. See the dev log's merge entry for what usually conflicts.

## On the owner's Mac (the iPhone build, M6)
The Android roadmap (M2–M5) is complete: release 1.0.1. The next milestone, **M6 "iPhone"**, runs on the owner's Mac:
start with `docs/IOS-START-HERE.md` (setup, what differs on the Mac) and the plan
`docs/superpowers/plans/2026-09-27-m6-iphone.md` (spec §19). On the Mac, the Android rules below (adb ports, the
emulators, the PC-wide suite slots) do not apply; everything else does.

## The game never ends (the owner, 2026-09-29, #71)
"this game never ends, we have alwys to work here and develop new content … we never stop developing new worlds, new
universes, new lessons, new contents". The roadmap has no last milestone: `docs/superpowers/plans/2026-09-29-forever-roadmap.md`
(the School's every subject and grade, the cosmos, universes, visuals). Never call an area "done"; say exactly what
exists and what comes next (#70).

## Learning is play, not lessons (the owner, 2026-10-17, #122)
"all lessons should be game, part of game, mini games … not lectures and slides and classical lessons, this is why we
are not school, we are something more". Every unit is played in the world: the concept is the game's mechanic, play
comes before words, the cards are only a Book on request. The design (the authority for every learning feature):
`docs/design/learning-is-play.md`; spec §22.0. Never build a new lesson as cards and a quiz.

## One game everywhere (the owner, 2026-10-17, #123)
"make windows and phone use same version always … i mean game version but of course mobile should be mobile". Every
deploy publishes the web, VR and the Android apps' update packs (`tools/export_android_update.sh`,
`tools/deploy_android_update.sh`) from **one commit**; installed apps take that game at their next start
(`autoloads/updater.gd`). A new APK/AAB only when a patch cannot carry the change (the engine, a native plugin, the
Android manifest, a start-time setting such as a new autoload, the updater itself); keep each one released as a base
(`tools/export_android_update.sh base …`). Details: `docs/DEVELOPMENT.md` "The Android apps follow the web".

## Working rules (from the owner)

1. **Don't ask questions; just build.** The owner said "start work and dont ask me questions. give me
   game". When something is unclear, decide from the spec, write the decision down as a ruling (with
   what it costs if wrong) in the ledger and the dev log, and keep going.
2. **Every owner feedback gets fixed.** Log it in `docs/playtests/owner-feedback.md` the moment it
   arrives. Plan it, or fix it test-first, then mark it fixed with the test name or measurement.
3. **Document everything in the project, not only in chat.** After every task, update the dev log
   (`docs/devlog/`). If a command, path or convention changes, update `docs/DEVELOPMENT.md`. New
   features go into spec §3b and the plan before they are built.
4. **TDD.** Write a failing test, watch it fail for the right reason, implement, then run the full suite.
   Engine glue is verified with godot-mcp and on the emulator.
5. **Test on the Android emulator on this PC** (AVD `Pixel_8_API_35`), not on the owner's phone.
6. **Another app is built on this PC in parallel.**
   - For every adb call, use `ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554`.
   - Never touch `emulator-5556` / `Parkingi_API_35` or its packages.
   - Before driving the editor, check that godot-mcp `get_info` shows `/home/giorgi/Documents/game/`.
7. **Never merge or push** without the owner saying so. There is no remote.
8. **Only CC0 assets**, credited in `assets/CREDITS.md`.
9. **Commits** end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.

## Test command

```bash
tests/run_tests.sh          # GUT, headless; fails on any SCRIPT ERROR / Parse Error
```
After adding a new `class_name` script, rescan in the open editor (godot-mcp) or run
`godot --headless --path . --import` first.

## Performance budget

On the emulator: ≥ 30 FPS average and no frame over 100 ms. That holds for the autopilot's 60 s play
phase and its 2 km flight, in both graphics styles. Phones are 3–5× slower than this desktop CPU. The
physics engine is Jolt (owner feedback #9); keep collision footprints small.
