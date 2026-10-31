# Frame spikes in the new worlds — the agent brief (performance budget; the lead's emulator runs 2026-09-30)

You are chasing **single slow frames** in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children
that must stay smooth on phones and in browsers. The budget (CLAUDE.md): on the emulator ≥ 30 FPS average and **no
frame over 100 ms**, for the autopilot's 60 s play and its 2 km flight, in both styles; phones are 3-5× slower than this
PC. Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes).

## What the lead measured (dev log `docs/devlog/2026-09-27-m7-web.md`, 10:12 and 13:13 entries)
- **The Moon (16), blocky, load 6:** play 56.4 FPS but one 142.8 ms frame at t = 4.3 s; flight 57.2 FPS but one
  129.3 ms frame at t = 10.5 s. Another run: one 120.3 ms frame at t = 25 s of the flight. The shader warm-up's world
  part had finished before play began. The Moon has the colony domes (spec §21c) near the spawn, the moon bunnies,
  robots and aliens (space creatures), a trader.
- **Wonders of the World (41), blocky:** play 57.0 FPS with one 109 ms frame at t = 24.8 s; the flight had 27 frames
  over 100 ms between 700 and 900 m out (the PC's load rose from 6 to 15 then, so part of it is load). Realistic (an
  earlier build, load 8-11): 2 frames over 100 ms at t = 2.6 and 4.5 s after the spawn, one at t = 6 s of the flight.
- Mars realistic is in budget (0 slow frames). Earlier today: Europa, Io and Mars realistic had 1-2 slow frames each.

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` §5 "The shader warm-up", §7 (performance: "Long frames, one by one",
   `tools/frame_probe.gd` + `tools/frame_blame.gd`, "Shader compiles in a browser" `tools/web_shader_probe.py`, the
   census `data/shader_warmup.json` and how to run it again), `docs/devlog/parts/m7-freezes.md`,
   `docs/devlog/parts/m7-shader-warmup.md`, and the autopilot (`tools/autopilot.gd`: its play and fly phases, what
   it does at each t).

## What to do
1. **Find each spike's cause on the desktop**, not by guessing: extend `tools/frame_probe.gd` (or its steps) with the
   Moon's spawn + the autopilot's actions + a flight, and world 41's spawn + the Wonders Road + a flight over the New
   Seven's region; blame every frame over a threshold (scripts per node, the physics engine, meshing, the rest). Also
   count first-seen materials per phase (the census; `tools/web_shader_probe.py --phases …` in headless Chrome for the
   WebGL programs linked) — **the census was last written with the rocket flight, before the colonies, the space
   creatures, the wonders, Venus**: write it again with phases that visit the space and Earth worlds (the Moon, Mars,
   Venus 24, world 41 and its New Seven square), and check `ShaderWarmup.tier` puts what a world shows at its spawn in
   the WORLD tier.
2. **Fix what you find**, smallest change first: work spread over frames (a node's setup done in slices), a
   material shared instead of made per instance, a first-seen material drawn by the warm-up, a Label3D/particles setup
   moved into the loading, a lazily built cache built before the world shows, a generator hot spot. Keep every fix
   behind a test (the census's tier test, a per-frame cost test like `test_every_frame_is_cheap`, a bench).
3. **Measure before and after** on the desktop (frame_probe's worst frames per phase, programs per phase) and write
   both in your notes. The lead re-measures on the emulator.

## Allocation and rules
- New tools and tests are yours; small fixes anywhere they are needed (say which files in your notes). Other agents
  are working now on crew flights (the sandbox's launch, Session, the flight), mining on the Moon and Mars (the Moon's
  and Mars's generators and prospecting), and the School: keep your changes in those areas small and say so.
- No editor, no emulator, no adb. Never merge or push. Never start agents. Keep the PC light: one full suite at the
  end (tests/run_tests.sh waits for a PC-wide slot); headless probes under `nice`.
- Notes `docs/devlog/parts/frame-spikes.md` (each spike: its cause, the fix, before/after; rulings); `DEVELOPMENT.md`
  if a tool or command changes; commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Report: branch, commits, each spike's cause and fix with numbers, the census's changes, the full suite's result, and
  exactly what the lead should run on the emulator to confirm.
