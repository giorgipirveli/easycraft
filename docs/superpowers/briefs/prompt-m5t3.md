# M5 Task 3 — the performance pass (spec §15.3; the lead measures on the emulator)
(House rules: `docs/superpowers/briefs/owner-common.md`. Start from main after the night's merges.)
Read spec §15.3, CLAUDE.md's performance budget (≥ 30 FPS average, no frame over 100 ms on the emulator, in the
autopilot's 60 s play phase and 2 km flight, both styles), `docs/DEVELOPMENT.md` §8 (the hard-won gotchas), the
generator benchmark, the autopilot (`tools/autopilot.gd`: NIGHT, WORLD/UNIVERSE toggles), and every smoke run's
cost lines (defense, games, pets, rides, farm, action kit).
Do (headless measurements and code; the lead runs the emulator):
1. A **low-end preset** (graphics "low": shorter view distance, fewer particles, no shadows, simpler water,
   capped monster count within 32 blocks) chosen automatically on weak devices (RAM/CPU class at first start;
   the child can change it) — tests for the choice and the caps.
2. **Startup time:** measure menu-ready time headless and find the biggest costs (autoload `_ready`s, resource
   preloads, the classical music list); make heavy things lazy. Report before/after.
3. **APK/AAB size:** list the biggest assets (the audio pass added ~16 MB; classical pieces 13.8 MB): recompress
   music to a sensible Vorbis quality (mono where fine), check textures (VRAM compression settings, mipmaps),
   drop unused files. Report the size of `EasyCraft-phone.apk` and the Play bundle's download size before/after.
   **The lead's measurement (2026-09-25 08:50, dev APK of `5ae37e2`, 181 MB; 0.3.3 was 133 MB):** 144 MB of it is
   `assets/.godot/imported`, and nearly all of that is the **realistic block pages: every page is two 2048² ETC2
   textures with mipmaps, 5.6 MB each** (albedo + normal; realistic, smart, portals, paint, meadows, desert, frost,
   candy, dragon …, about a dozen pairs). `libgodot_android.so` is 71 MB, Voxel Tools 7 MB, `classes.dex` 5 MB. Ideas
   to measure (keep both styles looking the same on the emulator): normal maps at 1024² (half the size, little visible
   loss at phone distance); pages that use only a few of their 64 tiles packed together or at a smaller size; the paint
   page's 16 realistic tints made in the shader from one plaster tile instead of 16 tiles; the editor-only addons
   (`addons/godot_mcp`) left out of exports; and (owner #43's agent) the store graphics and the dev log's JPGs outside
   `.gdignore` folders are imported and probably go into every APK (about 2 MB): a `.gdignore` for `docs/`. Children's phones are often small: the aim is an installed size well
   under 150 MB.
4. **Hot paths:** profile the host tick with 20 monsters + pets + a ridden dragon + a farm + a race in each
   universe (headless cost lines); fix anything over budget (≤ 10 Hz decisions, no per-frame allocations).
5. Hand the lead an emulator checklist: autopilot in every universe (1–4, plus the Dragon Realm if merged) in
   both styles, a small-phone AVD and a tablet AVD layout check.
Notes: `docs/devlog/parts/m5-task-3.md` with every number. Suites through the slot gate.
