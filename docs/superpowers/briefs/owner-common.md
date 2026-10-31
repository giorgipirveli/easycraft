You are building part of **EasyCraft**, a Godot 4.7.2 (typed GDScript, Jolt, Voxel Tools 1.7) 3D block game for children (Minecraft/Roblox-like), Android landscape. You are in your own git worktree on a branch cut from `m2-survive-the-night` (M2 complete; M3 and M4 in progress). Up to 6 agents work in parallel; the lead merges.

**Read first:** `CLAUDE.md`, `docs/DEVELOPMENT.md` (§8 gotchas), the spec `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` (§6 fair fun, §16 research, and the sections named below), `docs/playtests/owner-feedback.md` (your row: the owner's words and the lead's ruling), and the notes of the tasks you build on (`docs/devlog/parts/`).

## House rules
- New features go into the spec and the plan before they're built (CLAUDE.md rule 3): add a short spec section and a plan line.
- TDD: write the test, watch it fail for the right reason, implement, watch it pass, then run the **full suite** `tests/run_tests.sh`; **commit only if it exits 0**. New `class_name` → `godot --headless --path . --import` first. Redirect long output to a file and read its tail.
- Children's game: plain, kind words (the no-guilt word test stays green), icons first, big buttons; the HUD layout table `ui/hud/hud_layout.gd` (no new always-visible buttons; rare actions in MORE).
- Blocks and items share one id space: items own 100–175 and 400+, block pages 64–95 and 176–255 — use only the ids your brief allocates.
- Never use adb/the emulator; never call godot-mcp tools. CC0 assets only (credited in `assets/CREDITS.md`); third-party code only with a permissive licence (listed in `THIRD_PARTY_NOTICES.md`). Never merge or push. Commit messages end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Keep edits to shared files small and in your own section (Session: a section at the end of `autoloads/session.gd`).
- Before implementing, invoke the matching `godot-prompter:*` skills and note the chosen/rejected patterns in your notes.
- The PC is shared: up to 6 agents; tests run under `nice`; run the full suite before commits, not in a loop. If an API limit stops you and you are resumed, check `git status`/`git log` first and continue.
- Notes in `docs/devlog/parts/<your-file>.md`: what you built, tests RED→GREEN, rulings with their cost if wrong, what the lead should check on the emulator; mark your row in `docs/playtests/owner-feedback.md` fixed with the test names when done.

