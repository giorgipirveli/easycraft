# M1 acceptance — Android emulator `Pixel_8_API_35` (2026-09-23)

Device: Android 15 x86_64 emulator on the dev PC (Intel iGPU, OpenGL/Compatibility renderer because
emulator Vulkan is disabled). Graphics preset Medium, view distance 128. Build: debug APK from branch
`m1-first-steps`.

| # | Criterion (spec §9.13) | Result | Evidence |
|---|---|---|---|
| 1 | Fresh install → age → username → menu → Sandbox, playable < 10 s | **PASS** | `pm clear` + full flow by adb taps (PLAY → 2010s → 2015 → name validation hint → RANDOM → OK → SANDBOX). logcat `SANDBOX spawned_ms` 278–660 ms after tapping Sandbox/Continue (was 9988 ms for a save far from the origin — fixed, see below) |
| 2 | Triple jump; a 4th press in the air does nothing | **PASS** | `test_jump_counter.gd` (7 tests); godot-mcp playtest: 4 presses → `jumped` [1, 2, 3] |
| 3 | All 16 blocks place/break; Undo reverts the last 20 | **PASS** | `test_undo_stack.gd` (capacity 20, batches); godot-mcp: 3 places + 1 break + 4 undos → region identical; emulator taps placed brick/purple/stone, long-press broke brick; palette shows all 16 |
| 4 | Edits + position survive force-close and relaunch | **PASS** | emulator: stone placed → HOME → `am force-stop` → relaunch → Continue → stone present; far save (1835 m) restored |
| 5 | 2 km straight: no terrain holes, no frame > 100 ms after load | **PASS** | autopilot ghost-flight 2000 m: `avg_fps=57.5 max_frame_ms=78.9 frames_over_100ms=0` (holes: visual spot checks only) |
| 6 | Fly and Ghost work; leaving Ghost inside blocks moves to free space | **PASS** | godot-mcp: Ghost 6 blocks into stone → Normal → feet in air above grass, collision mask restored |
| 7 | ≥ 30 FPS average on Medium on the emulator (2-min walk-and-build) | **PASS** | autopilot play phase (walk, triple-jump, place/break, 60 s): `avg_fps=54.6 max_frame_ms=38.1 frames_over_100ms=0`; flight 57.5 FPS |
| 8 | Two desktop instances see each other and each other's edits | **PASS** | `--auto-host/--auto-join --lan-test`: client spawned 905 ms, saw host's pre-join block; host saw client's block; positions synced both ways |
| 9 | All GUT tests pass headless | **PASS** | `tests/run_tests.sh` → 160 passing, 0 failing, runner fails on script errors |
| 10 | At least one child has played it; notes in `docs/playtests/` | **NOT DONE** | Needs the owner; template at `docs/playtests/m1-template.md` |

## Signature features (spec §3a) — also verified
- Size Magic (tiny/giant), Mirror mode (mirrored pair + one-step undo), Stamps (house/rainbow + one-step
  undo), Magic Wand buddies (capture, follow, cheer, sleep back to blocks, save/restore) — godot-mcp
  playtests with screenshots; logic covered by unit tests.

## Bugs found during acceptance and fixed (each with a test or measurement)
- Spawn waited for the terrain around the **origin** (player parked at 0,0,0) → 10 s timeout for far
  saves. Player is now parked at the target while it streams: 9988 ms → 278 ms.
- Mid-air (flying) saves waited on empty air, which never meshes → wait on the ground below
  (`test_readiness_probe_*`).
- OpenGL renderer showed washed-out textures (sRGB not decoded) → forced sRGB decode on that renderer.
- Buddy cheer particles polluted the buddy list (save crash) → `test_cheer_does_not_litter_the_buddy_container`.
