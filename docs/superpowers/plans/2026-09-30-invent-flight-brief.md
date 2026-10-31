# Invent it: flight in history's order — the agent brief (owner #78; spec §21e)

You are building **"invent it"** in EasyCraft (Godot 4.7.2, typed GDScript), an educational game for children. The owner:
"so all things must be educational in the game, close to real world, like if you want to fly you have to invent
acordingly". Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§21e (your design)**, §25 (the core loop: gold, the Gold Shop, the
   rocket missions), §12 (Survivor: gold, crafting at the Workbench, `Recipes`, flying costs gold today:
   `core/economy/fly_cost.gd`), the player's physics modes (`PhysicsMode`, `Player.set_physics_mode`, the glider:
   `can_glide`), the School (a lesson card per invention can link to a School unit), `EarnRules`, `SpendRules`,
   the rocket missions (`MissionRules`, the Launch Site) and the planet guide (for a card's pattern).

## What to build (spec §21e)
- **An Inventions book** (a page of the Books or its own panel): the line of flight in history's order: the kite (China,
  over 2,000 years ago: wind and a string), the hot-air balloon (1783: hot air is lighter than cold air), the glider
  (the 1890s: wings lift), the plane with an engine (1903: the first powered flight lasted 12 seconds), the jet (1939:
  pushing air out fast pushes you forward), the rocket (1957 the first satellite, 1961 the first person in space, 1969
  people on the Moon). People of history only (never living people); each with one card of its story and its science,
  read aloud.
- **In Survivor, flight is invented step by step**: each invention is made at a Workbench from real materials (a kite:
  sticks, cloth, string; a balloon: cloth, a basket, a burner; a glider: wood and cloth wings; …), costs a little gold
  or a School unit mastered on its science (your ruling, one table), and opens what it can do: the kite a short lift
  on a windy hill, the balloon slow rises and falls, the glider the glide (already in the game: make it the invention's
  gift), the plane fast level flight, the jet the fastest, and **the rocket opens the Launch Site's missions** in
  Survivor (the missions are already there: gate them on the invention in Survivor only). Flying's gold cost in
  Survivor stays for the plane and the jet (the fuel), or is replaced by the inventions (your ruling, written).
- **Sandbox keeps free flying** (the owner's #54 and #75: jump taps fly); there the Inventions book is to read and try.
- A **"try it" moment** for each: a small challenge that shows its science (fly the kite into the wind; heat the
  balloon to rise; glide farther from higher; …), paying gold once (EarnRules).
- Controllers (`PadFocus.watch`), PC keys (the KEYS card), phones: every panel works everywhere.

## Allocation and rules
- New files: `core/inventions/*` (pure rules: the line, the recipes, the gates), `ui/inventions/*`, the models for the
  kite, the balloon, the plane and the jet (our own look, cheap to draw), tests `tests/**/test_invent*.gd`, a smoke
  `tools/inventions_smoke.gd`, notes `docs/devlog/parts/invent-flight.md`. Block ids only if the lead gives you a page.
  Small additions elsewhere (the player's modes, Survivor's gates, `Recipes`, the Books). Never touch other agents'
  files.
- TDD; `--import` and grep Parse Error; single tests; the FULL suite once at the end (a `test_nakama_account_key.gd`,
  `test_audio_credits.gd` or animation-timing failure can come from others loading the PC: rerun it alone). Never open
  the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
Notes (rulings, the facts with their sources, what a child sees and does, what the lead must check on the emulator);
spec §21e "As built"; `docs/DEVELOPMENT.md`. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees,
the smoke and full-suite results, what the lead must look at.
