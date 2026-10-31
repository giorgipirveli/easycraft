You are building part of **EasyCraft**, a Godot 4.7.2 (typed GDScript, Jolt, Voxel Tools 1.7) 3D block game for children (Minecraft/Roblox-like), Android landscape. You are in your own git worktree on a branch cut from `m2-survive-the-night`. Other agents build other M2 tasks in parallel; the lead merges.

**Read first:** `CLAUDE.md`, `docs/DEVELOPMENT.md` (§8 gotchas are hard-won: per-event materials cause 100+ ms frames; simulate things near players only, decide at 10 Hz; collision exists only within 48 blocks of players), the spec `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` §12 (M2 detailed spec), the plan `docs/superpowers/plans/2026-09-24-m2-survive-the-night.md` (your task, **Allocations**, Task 1 **Produces**), and the notes of the merged tasks you build on (`docs/devlog/parts/m2-task-*.md`, especially **m2-task-4.md for the Monster API**, m2-task-2 knock-outs, m2-task-3 inventories, m2-task-15 bots (group `bots`), m2-task-11 `Feel`/music). Developer run: `XDG_DATA_HOME=<private dir with a copy of ~/.local/share/godot/app_userdata/EasyCraft/profile.json under godot/app_userdata/EasyCraft/> godot --headless --path . -- --survivor --new-world`.

## House rules
- No per-event materials or meshes (use `Fx` and cached meshes/materials); ≤ 10 Hz decisions; per-frame code cheap; `is_instance_valid` for players that can vanish.
- Keep edits to shared files small and self-contained; Session signals/RPCs in a new section at the end of `autoloads/session.gd` titled `# --- M2 Task <n>: …`.
- TDD: write the test, watch it fail for the right reason, implement, watch it pass, then run the **full suite** `tests/run_tests.sh` and **commit only if it exits 0** (check the exit code). New `class_name` → `godot --headless --path . --import` first. Redirect long output to a file and read its tail.
- Never use adb/the emulator; never call godot-mcp tools. CC0 assets only (credited in `assets/CREDITS.md`).
- Match the code style (typed GDScript, tabs, short `##` doc comments, child-friendly on-screen text).
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Never merge or push.
- Document in `docs/devlog/parts/m2-task-<n>.md`: what you built, tests RED→GREEN, every decision with its cost if wrong. Final report: commits, suite count before/after, rulings, what the lead should check on the emulator.
