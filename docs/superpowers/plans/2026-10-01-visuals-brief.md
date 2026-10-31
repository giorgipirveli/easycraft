# The best visuals — the agent brief (the owner's goal: "create amazing and best visuals"; #94 "game improvement")

You are making EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools; the Mobile renderer on phones, GL Compatibility on
the web and the emulator) **look amazing** in both styles (BLOCKY and REALISTIC), inside the performance budget (the
emulator: ≥ 30 FPS, no frame over 100 ms; phones are 3-5× slower than this PC). Work autonomously; do not ask questions
(decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the styles, the sky and day cycle, `GraphicsPreset`, the shader warm-up and
   its census rule, performance §7, the page sizes' budget), `docs/devlog/parts/frame-spikes.md`, the look of each
   world (`world/universes/*.gd`: skies, fog, suns), the menu's diorama (the first thing a child sees).
3. **Take pictures first** (a real window, not the editor): the menu, Green Meadows at noon, sunset and night, a cave, water,
   the Moon, Mars, Venus, Saturn's rings, world 41, in both styles (tools like `tools/space_shots.gd`,
   `tools/page_shots.gd`; write your own `tools/look_shots.gd` for a fixed set of views). Keep them as the "before".

## What to improve (the biggest wins per millisecond first; measure each)
- **Light and sky:** the sun's warmth at morning and evening, a sunset glow on the horizon, gentle ambient that keeps
  shadows readable, night that is dark but friendly (moonlight blue, stars), per-world skies true to each planet.
- **Air and distance:** fog and aerial perspective that make far hills soft and bluish (and each planet's own haze),
  hiding the chunk edge beautifully.
- **Water:** colour by depth, a soft shoreline, gentle waves and a sparkle in the sun (both styles; cheap).
- **The blocks:** crisp blocky textures (no blur, no seams), a subtle vertex ambient occlusion look in corners if the
  mesher gives it, a touch of colour variation so big fields don't look flat; REALISTIC's materials balanced (not too
  dark, not too shiny).
- **Life in the scenery:** grass and flowers that sway a little, leaves that move in the wind (a vertex shader, cheap).
- **The first impression:** the menu's diorama, the wordmark's shine, the loading card's look.
- Everything behind `GraphicsPreset` levels where it costs (LOW stays fast; phones default to what the budget allows).

## Allocation and rules
- Yours: shaders and materials of the world, sky, water and blocks; `GraphicsPreset`; the menu's diorama look; new files
  `world/look/*`, `tools/look_shots.gd`, tests `tests/**/test_look*.gd`, notes `docs/devlog/parts/visuals.md`.
- Other agents now: **EasyCraft Shorts** (the Theater, `core/shorts`, `ui/shorts`), **lesson quality** (lesson JSON files).
  Don't touch their files. The animations agent's work is merged (`UiMotion`, the world's life `world/life/*`, moving
  School pictures): keep it working.
- Every new material, shader variant or particle system goes into the shader warm-up's census (the sources test guards
  it; the lead re-runs the census after merging). The realistic pages' texture budget (`test_page_sizes.gd`) holds.
- TDD for code (shader parameters per preset, the look per world, costs); a bench before/after (the desktop frame time
  in the fixed views, both styles) in your notes. Never open the editor or an emulator; never touch adb; never merge or
  push; never start agents. One full suite at the end (tests/run_tests.sh waits for a PC-wide slot).

## Finish
Notes (before/after pictures' paths and what you saw, each change's cost, rulings, what the lead must check on the
emulator: FPS in both styles at noon, sunset and night; a phone's look); `DEVELOPMENT.md`; commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what looks better and
where, the bench, the full suite's result, what the lead must look at.
