# More animations — the agent brief (owner #94: "also make more animations")

You are making EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children, **more alive with animation**:
the characters, the creatures, the world, the menus and the School's pictures. The owner (2026-09-30): "continue game
improvement … also make more animations". Everything must stay inside the performance budget (the emulator: ≥ 30 FPS,
no frame over 100 ms; phones are 3-5× slower than this PC). Work autonomously; do not ask questions (decide, and note
rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the avatar and animal animation code, the shader warm-up §5 and the census
   rule, performance §7), `docs/design/` (fair fun, the signature moments), and look through what moves today: the
   avatar (`entities/player/*`, avatar parts, jumps and flips), animals (`entities/animals/*`, `AnimalDirector`), buddies,
   robots and aliens (`entities/robot/*`), the Theater, the menu's diorama, the rocket flight, the School's pictures
   (`ui/school/school_picture*.gd`), the HUD's toasts and cards (`UiKit`).

## What to build (pick the ones that give a child the most delight per millisecond; measure each)
1. **Characters:** idle variety for the avatar (look around, stretch, wave when a friend is near), happy reactions
   (a little jump and spin when a lesson star, a stamp, a secret or a landing is won), emotes a child can play from MORE
   (wave, dance, cheer, think), a sleepy yawn at night; the helpers (Professor Hoot, Gemma, Tilly, the robots, the
   aliens) greet the child when it walks up (a wave, a bounce, a blink) and react when a quest or a mission is done.
2. **Creatures and the world:** animals' small idle life (graze, sniff, tail wag, ear flick, hop), birds or butterflies
   over meadows by day and fireflies at night (a few, pooled, far ones hidden), fish in water, leaves and petals when a
   tree or flower block breaks, the Launch Site's tower lights blinking, flags waving at the landmarks, the wonders'
   water features moving. Pooled and budgeted: no per-frame allocation, far things off (`VisibleOnScreenNotifier3D`,
   distance), shared materials.
3. **The UI:** cards and panels slide and pop in with easing (one shared helper in `UiKit`, so every panel feels the
   same), buttons squash when pressed, gold and stars fly to their counter when earned, the School's right answer
   bursts a few stars, a level-up of a lesson glows.
4. **Animated School pictures** (the Shorts agent and the School both use them): an optional `animate` for the picture
   kinds that teach motion best (the water cycle's arrows flowing, a lever tipping, gears turning, the Moon's phases,
   orbits, a circuit's current, a food chain's arrows, a rocket's stages separating, a pendulum, sound waves): a time
   parameter the drawing reads (`SchoolPicture` gets `time` and a `playing` flag; static pictures stay as they are, a
   test proves a static kind draws the same with or without time). Say in the notes which kinds animate and how.
5. **Warm-up:** every new material or particle system goes into the shader warm-up's census (`data/shader_warmup.json`
   via `tools/shader_probe_steps.gd`; `test_shader_warmup_sources.gd` fails for a new material maker until it is listed).

## Allocation and rules
- Yours: new files `entities/**/anim_*.gd`, `world/life/*` (ambient life), `ui/fx/*` (UI motion helpers), animated
  drawing added inside the School's picture files for the kinds you animate, tests `tests/**/test_anim*.gd`,
  `test_ambient*.gd`, `test_ui_motion*.gd`, notes `docs/devlog/parts/animations.md`. Small hooks elsewhere (say which).
- Other agents now: **EasyCraft Shorts** (`core/shorts`, `ui/shorts`, the Theater's panel: it may call your picture
  animation API if it's on lead-merge when it looks; tell the lead its shape early in your notes), **lesson quality**
  (edits lesson JSON files; you don't). Don't touch their files.
- TDD; per-frame cost tests (like `test_every_frame_is_cheap`); a bench before/after for the world's life (frame time
  with birds/fireflies on vs off) in your notes. Never open the editor or an emulator; never touch adb; never merge or
  push; never start agents. One full suite at the end (tests/run_tests.sh waits for a PC-wide slot); windowed shots if
  you can open a window (say what you saw).

## Finish
Notes (what animates now, where, its cost, rulings, what the lead must check on the emulator: frame rate in a meadow at
dusk with birds and fireflies, a phone's feel); `DEVELOPMENT.md` (the motion helper, the picture animation API, the
ambient life's budget); commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
Report: branch, commits, what a child sees now, the bench, the full suite's result, what the lead must look at.
