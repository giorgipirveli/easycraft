# Cosmos: Mars (world 19) — the agent's brief (spec §21b.2)

You are building **Mars**, the first real planet of EasyCraft's cosmos (world 19), for a Godot 4.7.2 (typed GDScript) + Voxel Tools game for children. The owner wants "the universes closer to real worlds so the player starts learning real things" (#74) and "cosmos, stars and planets where each planet is a different universe" (#72). Work autonomously; do not ask questions (decide, and note rulings with their cost if wrong in your notes file).

## Start
1. Your worktree was created from some commit; first run `git reset --hard lead-cosmos` (the lead's cosmos branch: it has the Star Map, commit 5eda55e, and `SpaceRules.MARS = 19`). Check `git log --oneline -3`. Then `nice godot --headless --path . --import` once (a fresh worktree needs its import).
2. Read `CLAUDE.md` (working rules), `docs/DEVELOPMENT.md` (conventions, gotchas), spec §21 (space, the Moon, Planet Boing, Rainbow Planet: how a space world is built) and §21b (the cosmos: the Star Map and the real planets; Mars's row) in `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md`, and `docs/devlog/parts/owner-55-space.md` (how the three space worlds were built, measured and tested).
3. Study the Moon end to end, then copy its pattern: `world/universes/moon.gd`, `moon_blocks.gd`, `universe_registry.gd` (SPACE table), `core/rules/space_rules.gd` (WORLDS), `world/generators/space_shape.gd`, `space_generator.gd`, `space_secret_rules.gd`, `data/blocks/block_ids.gd`, `world/block_library.gd` (pages, IDS_PER_PAGE), `tools/make_space_atlas.gd` (the pixel pages) and `tools/make_space_realistic.py` (the realistic twins from CC0 ambientCG textures; `assets/CREDITS.md`), `core/rules/star_map.gd` (Mars's card and facts), the tests `tests/**/test_space*`, `tests/**/test_moon*`, `tests/**/test_star_map.gd`, the smoke `tools/space_smoke.gd`, the bench `tools/bench_generator.gd -- --space`.

## Your allocation (fixed; nothing else)
- World **19**, `SpaceRules.MARS`; add it to `SpaceRules.WORLDS` (the Star Map then says LAND on Mars) and to `UniverseRegistry.SPACE` (19: name &"mars", display "Mars", its card colours).
- Block atlas **page 18** (check it is free in BlockLibrary and every *_page.gd), block ids **336-351** (`BlockIds`; COUNT goes to 352; keep 331-335 for Rainbow Planet).
- New files: `world/universes/mars.gd`, `world/universes/mars_blocks.gd`, `data/blocks/pages/mars.png` (+ `_albedo`, `_normal`), your shape as a new planet kind in `SpaceShape` (or a `MarsShape` if cleaner), secrets in `SpaceSecretRules` (or a Mars variant), tests `tests/unit/test_mars*.gd` / `tests/integration/test_mars*.gd`, notes `docs/devlog/parts/cosmos-mars.md`.
- Never touch the School (`data/school`, `core/school`, `ui/school`), the Star Map UI (`ui/space/*`), or other universes' files, except the few registry lines above.

## Mars (real, friendly, bright; spec §21b.2)
- **Gravity 0.38** (real). A butterscotch-pink daytime sky, a blue-tinted sunset glow at the horizon, a dusty haze; the two small moons Phobos and Deimos in the sky (SkyCycle.show_planet takes one body today; show Phobos at least, or extend it for two small ones).
- **Ground (blocks):** red Mars dust (iron oxide) over rusty regolith, dark basalt rock, deep rock, pale layered sediment (dry river beds), white polar ice (water ice) and dry ice (a frosty blue-white), a glowing Mars crystal/mineral for the geodes (keep it plausible: e.g. glowing hematite "blueberries" or a gypsum crystal), rover panels/wheels (for the rover landmark: generic, never a brand or mission name), a landing pad and base light if needed (reuse the Moon's LANDING_PAD if the spec's pad works for every space world), a fake rock for the hidden room.
- **Terrain:** wide dusty plains with craters (raised rims), dry river valleys, a giant **shield volcano** landmark (wide, gentle slopes, a caldera on top; far taller than anything around but within the world's height limit), a long **canyon** (like Valles Marineris), and a **polar ice cap** region; no water, no caves needed (keep the generator no slower than the Moon's: run the bench and record it).
- **Secrets** (the Secret Book counts them): buried treasure, a hidden room, a temple-like "old lander" or ruins stay friendly and fictional, the **rover** as the landmark (ISLAND secret, on MY MAP), geodes. Each find's banner is a real Mars fact where it fits ("You found the ice cap! Mars's poles hold frozen water and frozen carbon dioxide.").
- **Peaceful** (no monsters by themselves), no animals (Mars has no life we know of; say so in its words), ambience a soft dusty wind; classical music already in the game that fits (MusicPieces; Holst's "Mars" is NOT in the game — do not add audio files unless CC0/public-domain recordings are already there).
- **Landing words:** "You landed on Mars! Jump: you are lighter here!"; Tilly's trader stock like the Moon's.
- Real facts must be correct (check them). British spelling, kind words, English only, CC0 textures only (credit them in `assets/CREDITS.md`).

## Tests and checks (TDD)
- Write failing tests first: the descriptor's fields (gravity 0.38, peaceful, sky, words), the shape (the volcano, craters, canyon, ice cap exist where the shape says, heights in range), blocks registered in both styles, secrets placed and counted, `SpaceRules.WORLDS` includes 19, `StarMap.states` says LAND for Mars when its file exists.
- `nice godot --headless --path . --import 2>&1 | grep -iE "parse error|script error"` prints nothing after adding class_name scripts.
- Single tests: `tests/run_tests.sh -gtest=res://tests/...` (niced; waits for one of 3 PC-wide slots). GDScript gotchas: no `match` inside lambdas; typed vars from untyped array indexing need explicit types.
- The generator bench (`tools/bench_generator.gd`, see its header) for Mars vs the Moon and Green Meadows: record the numbers in your notes.
- Extend `tools/space_smoke.gd` / its steps (or a `tools/mars_smoke.gd`) so a headless run lands on Mars from the Star Map (tap Mars, LAND), checks its gravity and the portal home, and comes home; it must print 0 fails (run it with a private XDG_DATA_HOME containing "smoke", as its header says).
- At the end run the FULL suite once: `tests/run_tests.sh > /tmp/<yourname>-suite.log 2>&1; tail -30`, fix anything you broke.
- Never open the Godot editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes in `docs/devlog/parts/cosmos-mars.md` (what you built, rulings, measurements, test names, the suite's result), and a short row for Mars in spec §21b.2's "As built" if you add one.
- Commit on your branch, each message ending with the line:
Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
- Report: branch name, commits, what a child sees on Mars, the bench numbers, the smoke and full-suite results, and anything the lead must check on the emulator.
