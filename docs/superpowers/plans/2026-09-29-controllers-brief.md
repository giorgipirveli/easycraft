# Game controllers everywhere (PlayStation, Xbox, any gamepad) — the agent brief (owner #90, #84)

You are adding **game controller** play to EasyCraft (Godot 4.7.2, typed GDScript; the browser, Android, the desktop).
The owner: "make sure game can be played on playstation browser as well". The lead checked: the PS5's browser is hidden
and has no WebGL or controller input, and the PS4's is too old for WebGL 2, so the game cannot run there (a console
version needs Sony's programme: the owner's business step). What we build: a **PlayStation (DualSense, DualShock) or
Xbox controller** plays the whole game in a PC or phone or TV browser and on Android (Godot's joypad input; the
browser's Gamepad API). Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, the input map in `project.godot`, `core/platform/platform_rules.gd`
   (`keyboard_first`, the PC mode of owner #84), `core/platform/keys_rules.gd` and `ui/help/keys_card.gd` (the KEYS
   card), the player's movement and look (`entities/player/player.gd`, the camera rig), the HUD (`ui/hud/*`), the
   menus (`ui/menus/*`), the School's screens (`ui/school/*`).

## What to build
- **Playing**: the left stick walks, the right stick looks (smooth, a sensitivity in SETTINGS), Cross/A jumps (quick
  presses fly up, as JUMP does), R2/RT breaks, L2/LT places, L1/R1 pick the hotbar's block, Square/X attacks, Triangle/Y
  flies up or down with the D-pad, Options/Menu pauses, the touchpad/View button opens the map (your ruling for each,
  written in one table); every action through the input map (joypad events added to the actions).
- **Menus and the School with a controller**: focus moves with the D-pad or the left stick, Cross/A presses, Circle/B
  goes back; every screen a child meets (the menu, SETTINGS, the School's map, units and exercises, the Star Map, the
  shop, the pause menu) is reachable; a visible focus ring.
- **Hints show the controller** when one is used last (the KEYS card becomes a CONTROLLER card with the buttons' names
  for PlayStation or Xbox by the pad's name), and the touch HUD hides while a controller plays on a phone.
- **A browser that cannot run the game** (no WebGL 2 or WebAssembly) gets a kind page instead of a blank one: "This
  browser can't run EasyCraft yet. Try Chrome, Edge, Firefox or Safari on a computer, tablet or phone." (in
  `web/shell.html`, tested by a headless check if you can).

## Allocation and rules
- New files: `core/platform/pad_rules.gd` (pure: the table, which pad, which glyph words), `ui/help/*` additions, tests
  `tests/**/test_pad*.gd`, notes `docs/devlog/parts/controllers.md`. Small additions: `project.godot`'s input map (joypad
  events only), the player's look, the HUD's hide, the menus' focus. Never touch the core loop's agents' files, the
  School's units, the worlds.
- TDD (the table, focus order on each screen, the look's maths, the card's words); `--import` and grep Parse Error;
  single tests; the FULL suite once at the end. Never open the editor or an emulator; never touch adb. Never merge or
  push. Never run more agents.

## Finish
Notes (rulings, the button table, what the lead must check with a real controller on the PC and the emulator); spec
§20.3 (the platforms) "As built"; `docs/DEVELOPMENT.md`. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child can do with
a controller, the tests' results, what the lead must look at.
