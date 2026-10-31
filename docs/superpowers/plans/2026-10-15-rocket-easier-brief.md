# The rocket easier to build — the agent brief (owner #98; spec §21d, §25)

The owner (2026-10-14): "its getting way way to out of hands. so do fix that to make the rocket to build easier. so lets
check the 'buy the parts you don't have' quest". You are making the rocket a child can actually build and fly
(Godot 4.7.2, typed GDScript, Voxel Tools), keeping it real and educational. Work autonomously; do not ask questions
(decide, and note rulings with what they cost if wrong in your notes).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3` (Ganymede, world 28, is merged: its mission counts too);
   `nice godot --headless --path . --import`.
2. Read `docs/devlog/parts/rocket-easier.md` **whole** (the understanding phase: the child's flow step by step, 20
   frictions, 6 bugs with repros, the cheapest passing rocket per mission and crew and the planner's pitfalls, how to place
   a plan on the pad and its risks). Then `core/rules/rocket_check.gd`, `rocket_parts.gd`, `mission_rules.gd`,
   `mission_data.gd`, `ui/missions/mission_board.gd`, `entities/launch/launch_director.gd`, `scenes/sandbox.gd` (the board's
   hooks, `buy_rocket_part`, `launch_rocket`), `core/economy/spend_rules.gd` (GUIDE), `earn_rules.gd`, the inventions'
   rocket and jet (`core/inventions/invention_line.gd`), and their tests. The scratch planners of the understanding phase
   are in `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/rocket98/` (Python;
   read them, don't depend on them).

## The design (decided by the lead; rulings)
1. **Supplies (the strongest lever):** a service module keeps **one astronaut for the whole trip**, however long (it
   recycles air and water as the space station does and grows a little food): the supplies line needs one service module
   per astronaut. The cards still say the real trip length. *Cost if wrong:* less real about food on 12-year trips; one
   constant to change back.
2. **Prices halved** (multiples of 5, at least 5), then tuned with the plans so: **the Moon's plan about 400-550 gold** (one
   good day of learning: 150 for answers + 100 per unit mastered), Mars ≤ 900, the far worlds mostly ≤ 2,000, Mercury the
   hardest (its speed). Update `SpendRules.GUIDE`, the comments and tests that state prices. *Cost if wrong:* the economy
   too easy; one table.
3. **Mission Control's plan per mission and crew 1-4** (`core/rules/rocket_plan.gd`, `class_name RocketPlan`, pure): a
   stored table (stages from the bottom: engines, tanks, the lander's parts) made by a generator (`tools/make_rocket_plans.gd`,
   run headless, using the REAL RocketCheck) and guarded by a GUT test: every mission in `MissionRules.MISSIONS` × crew
   1-4 passes `RocketCheck.check(plan, mission, crew, RocketParts.count(plan)).ok`, is one piece on y 0, fits 9 × 9 and
   **≤ 24 layers**, clears the speed by ≥ 0.05 km/s. Shaped like a rocket a child recognises (centred stages narrowing
   upward, engines at each stage's bottom, the separator under the next stage, legs round the lander's engine, capsules
   with a nose cone on top). If a mission × crew still has no plan, the board says so plainly (and the test lists the
   exceptions; aim for none).
4. **BUILD IT FOR ME** (MY ROCKET page, and on the empty-pad line): the host builds the plan on its pad **layer by layer**
   (`LaunchDirector`; ≤ 16 cells a frame, a layer about every 0.4 s, one caption and spoken line per stage: "Stage 1: 8
   rocket engines and 10 fuel tanks lift everything."), for the crew present (1 + friends, up to 4). It keeps cells that
   already match, removes stray rocket parts that would join the rocket (Sandbox: gone; Survivor: back into the bag),
   **never breaks a child's other blocks** (it says how many to move first), refuses until the pad is stamped, during a
   crew call or a flight, and pauses while someone stands in the build box ("Step off the pad: Mission Control is
   building!"); writes through a host path gated by `near_board` (no reach limit for tall plans), no XP for its blocks, not
   in the child's 20-step undo. A friend at a friend's pad gets the same words as LAUNCH's ("This pad is your friend's…").
   Survivor: it takes the parts from the bag; what is missing is offered first (BUY THE MISSING PARTS: n gold, into the bag).
5. **Buying in one place:** the "Buy the parts you don't have yet" line gets **its own button on MY ROCKET**: "BUY THE PARTS
   FOR THIS ROCKET: n gold", then a confirmation card ("Buy 33 parts for 470 gold?" YES / NO); too little gold says
   exactly: "You have 120 gold: 350 more to go. A School unit mastered gives 100 gold." Lists with plurals ("8 rocket
   engines, 10 fuel tanks"). The board reopens on MY ROCKET when the pad has parts; a grey LAUNCH says why ("Not yet: 2
   lines to fix"). The mission card says the plan's size and price ("Mission Control's plan: 33 parts, 470 gold").
6. **Survivor's way:** keep the inventions (owner #78), but **no other universe may be needed for the rocket**: the
   kerosene for the jet and the rocket can be bought for gold where the child already buys (decide the place; the
   Desert's oil stays the free way). Rocket parts bought in the Gold Shop reach the Survivor bag (bug 1).
7. **Fix the six bugs** in the notes (each with a failing test first): the Gold Shop's parts and a friend's present never
   reach a Survivor bag; two devices' parts merged by the larger count while gold spends add up; a friend's bulk buy that
   does not pay for the owner's launch; every BUY scrolling the page to the top; a stale bulk price charged with no
   confirmation.
8. **Finding the Launch Site:** on MY MAP from the start, `/find launch`, and a hint when a child asks for the Moon.

## Allocation and rules
- Yours: the files above, `ui/missions/*`, `entities/launch/*`, the board's hooks in `scenes/sandbox.gd` (small, marked
  "owner #98"), tests `tests/**/test_rocket_plan*.gd`, `test_mission_board*.gd`, `test_launch*.gd`, `test_rocket*.gd`, the
  missions smoke, notes: append "As built" to `docs/devlog/parts/rocket-easier.md`.
- **Two VR agents work at the same time** (the player, camera, input, HUD, menus for VR): don't touch the player, the
  camera, the input map, `ui/hud/*` or `ui/menus/*` beyond a line you can't avoid (mark it).
- The rocket Short (`data/shorts`) teaches a dearer Moon rocket: leave it (the reels agent aligns it later); say so in the notes.
- TDD (failing test first, for the right reason). `--import` and grep Parse Error after new class_name scripts. Single tests
  with `tests/run_tests.sh -gtest=…`; the missions smoke (`tools/smoke_all.sh mission` or the mission smoke) 0 fails; the
  FULL suite once at the end. Never open the editor or an emulator; never touch adb; never merge or push; never start agents.

## Finish
Notes ("As built": the plans table per mission and crew with parts and gold, the prices, every ruling with its cost if
wrong, what the lead must check on the emulator: BUILD IT FOR ME's frame times, the board on a phone); `DEVELOPMENT.md`
(the plans generator command); spec §21d "As built (owner #98)". Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child does now
(the steps from the Star Map to LAUNCH), the plans table, the full suite's result, what the lead must look at.
