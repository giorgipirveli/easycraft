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

# Your task: M2 Task 9 — the Monster Totem and waves (spec §12.8; plan Task 9; research G6 "easier or again?")

Build, test-first:
- `core/rules/wave_rules.gd` (pure): wave N = 3 + 2N monsters (≤ 20), levels ⌈N/2⌉ … ⌈N/2⌉+1 (max 5), spawned from the edge of a 25-block circle around the Totem; ends when all are defeated or after 3 minutes; every player who was **not knocked out during the wave** gets 10 × N gold (`Session.gold_add`, host; Sandbox has ∞ gold so nothing is paid there); a won wave raises N (saved per world); waves start day or night; after wave 5 is won the Totem offers the boss (Task 10 builds the boss — expose a signal/hook `boss_offered` and a way for Task 10 to start it; agree names in your notes).
- **The Totem** (`entities/interactables/totem.gd`): stands 20 blocks from the world spawn on flat ground, placed once from the seed when the world is made (like Tilly's stall — read how Task 7 did `TraderRules.place_in` and the `MultiplayerSpawner`, and do the same), saved in `WorldMeta`. Survivor worlds always; Sandbox worlds too (spec §12.15: gentle monsters; waves there are capped at level 2 and ≤ 8 monsters, no gold). Tap it: a small picture panel "Wave N" with START; "Wave N starts in 5…" countdown; glows while a wave runs (shared material, no per-event materials).
- Monsters through `MonsterDirector.spawn_monster({kind, level, id, pos, yaw, wild: false, universe})` and `monster_defeated(kind, level, pos)` (see `docs/devlog/parts/m2-task-4.md`). Bot friends fight wave monsters on their own (Task 15) and are never paid.
- HUD: top-centre above the toasts "Wave N — k left" (icon + number; short words).
- After a lost wave (time out or everyone knocked out) the Totem offers **Try again** or **Try an easier wave** (N−1, same gold per monster; words never shame) — research G6.
- LAN: the host decides everything; guests see the Totem, the countdown, the glow and the wave line (RPCs/sync).
Tests: wave sizes and levels for N=1..12, caps, end conditions (all defeated, 3 min), rewards only to players not knocked out during the wave (use Task 2's knock-out signal), N rises on a win only, boss offered after wave 5, Totem placement on flat ground and saved, Sandbox caps, the easier-wave choice.
Notes: `docs/devlog/parts/m2-task-9.md`. Session section `# --- M2 Task 9: waves` (names prefixed `wave_`).

Your worktree is cut from `m2-survive-the-night` at `c86fd0f` (Tasks 1, 2, 3, 4, 6, 7, 11, 14, 15 and M3 Tasks 13, 16 merged; Task 16 secrets is merging now and is not in your base — don't depend on it). Other agents build Tasks 5, 8, 9, 10 and 18 (creature minds) in parallel; keep your edits to shared files small and self-contained.

**Skills:** before implementing each Godot system, invoke the matching `godot-prompter:*` skill (e.g. `ai-navigation`/`state-machine` for monster AI, `hud-system`/`godot-ui` for HUD, `physics-system`, `multiplayer-sync`, `godot-optimization`) and write in your notes which pattern you chose and which you rejected, and why. Check `git log -1` in your worktree first: it must be `c86fd0f` or later on the M2 line.
