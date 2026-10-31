# M3 Task 15: the tutorial with Pip (notes)

Brief `docs/superpowers/briefs/prompt-m3t15.md` (+ the lead's update: the game as it is now — #43's Workbench, #37's
shop tip, #45a quests, T21a read-aloud and Simple controls, #48's look step, the first-launch flow, Pip from
`PetRules.give_pip`); spec **§14.9** ("As built" added), §5.10; plan M3 Task 15. Built by a background agent in its own
worktree after `git merge lead-merge` (release 0.4.0), merged again mid-task (`8445d17`, owner #52: **English only** —
no Georgian lines were added, no `i18n/` recreated, the tests measure English only) and before the final suite
(`33c8356`: owner #53's weapon numbers — blasters 3/9/12/22/50, spear 5, mace 8, boomerang 21, rocket magazine 3 —
nothing of the tutorial uses them), without the editor or the emulator. **No block or item ids, no HUD button, no
Session changes.**

## What was built

| Piece | Where | What it does |
|---|---|---|
| The rules (pure) | `core/tutorial/tutorial_rules.gd` (`TutorialRules`) | The steps in order — move and look, jump the hole, build a bridge, break the wall, hide from the practice slime, craft sticks, visit Tilly (the Totem is gone: owner #44) — each a row with its **line id**, picture and very short words; every line the tutorial says is in `LINES` by id. Where it plays (`plays_here`: Survivor, solo, not online, CLASSIC, universes 1–4). The offer (`wants_offer`), SETTINGS' replay (`starts_now`), the held shop tip (`holds_tip`), `begin` (a stopped tutorial goes on at its step; a replay starts at 0 and never makes it offered again), `advance`, `skip` (never asked again), `finish` (true only the first time: the reward once per profile). |
| The record (pure) | `core/tutorial/tutorial_data.gd` (`TutorialData`) | `ProfileData.tutorial`: state (new / started / skipped / done), the step to go on from, rewarded, replay. Parsed defensively; the backup merge keeps the furthest state, a paid reward and a skip (`ProfileBackup.merge`). |
| Pip's playground (pure) | `core/tutorial/tutorial_course.gd` (`TutorialCourse`) | A straight course on a level 24 × 5 pad: the start (a −1..1), the hole to jump (a 2..7: 6 wide, 2 deep), the landing, the hole to bridge (a 11..13), the wall (a 16, 2 high), two bushes (a 18–19, s 2), Pip's Workbench (a 20, s −2), where the practice slime comes from (a 22). Its site from the terrain rules (`pick` / `pick_for`): dry ground (no sea, river or cave mouth in or beside it), no trunk on it, the whole course inside the treasure pack's 60-block spawn circle, clear of the spawn and the landmarks (`avoid`), the most level first (the pad fills and cuts ±1, then ±2, ±3, ±4), nearest the spawn first, the way running away from the spawn first; `accept` turns a site down. Cells, spots, each step's place (`station`) and glowing cells (`outline`), the jump's zones. |
| Its cells (pure) | `core/tutorial/tutorial_props.gd` (`TutorialProps`) | `plan`: every cell the course changes over the world as it is, as [x, y, z, held, placed]; `clear`: every cell back to what it held, and the child's own blocks the clearing takes (a bridge) back to their bag — a cell still holding what it held or what the course put there is nobody's (so a stop half way through laying it out gives nothing away); `natural` (only ground, plants and air may be built over); `touches` (a cell inside or under the child); `clean` (a record from a save); `box`. Every read stays inside `TutorialCourse.box(site)` (1,320 cells): one bulk copy serves them all. |
| The checks (pure) | `core/tutorial/tutorial_checks.gd` (`TutorialChecks`) | `LookWatch` (walked 3, turned 90° either way; a teleport is no walk), `JumpWatch` (on the ground this side of the hole — or its lip, or higher ground behind the pad — then next on the ground past it; a landing in the hole: `fell`; beside the playground starts over), `HideWatch` (hidden 1.5 s while the slime is near and can't see), `bridge_done`, `wall_open`, `crafted_stick`, `at_tilly`. |
| The director | `world/tutorial_director.gd` (`TutorialDirector`, node **`Tutorial`**, this game only) | The offer, the site on a worker thread (`WorkerThreadPool`, like the trading's cart), the playground into the world when that part is loaded and not where the child stands (every 0.5 s; "Step off so Pip can build the playground!"): one bulk copy of the course's box (`WorldService.box_reader`), the natural check and the plan on a worker thread, the record saved in the world's meta **before** the first cell, then 16 cells a tick (`write_batch`; the steps wait until it is all in); putting back the same way (the meta keeps the record until the last cell), a crash's record put back at the next start (host or solo, wherever the tutorial plays or not), a visiting Pip, the card, the glow (one `BuildOutline`), the arrow at the step's place when the child is 12+ blocks off, the practice slime, the checks ten times a second, praise toasts, Pip's cheer and babble, the reward and the end, the X. The bag opens on CRAFT during the craft step; 3 dirt for a child with fewer than 3 blocks at the bridge. |
| The screens | `ui/tutorial/tutorial_card.gd` (`TutorialCard`), `tutorial_offer.gd` (`TutorialOffer`, a `QuestOverlay`), `tutorial_picture.gd` (`TutorialPicture`) | The step card under the toasts (390 × ≤ 150 at y 176): picture (a HUD picture or a block/item icon), words (a Label: English), the steps as dots, a speaker, a small X; only the two buttons take a touch. The offer ("Hi! I'm Pip!", Pip drawn from his boxes by `AnimalPortrait`, PLAY WITH PIP, SKIP; a tap outside is "later"); the end ("You did it! You know it all!", +500 gold, Pip's Cap, "Pip is your pet now!"; a replay: "Well done! You know it all!"). |
| The practice slime | `entities/monsters/monster.gd` (a section at the end + 4 one-line guards) | `Monster.practice` (data `"practice": true`, slimes only): it sees, chases and loses a hidden child like any slime, but `_attack` never starts, a hit only pushes (damage 0: no coins, no defeat), and it has no creature mind. |
| The held shop tip | `world/trade_director.gd` | `hold_tip` (the tutorial's `holds_tip`) holds `maybe_tip`; `show_tip()` is the tip itself (the picture hint and the arrow at Tilly, marked seen), used by `maybe_tip` and by the Tilly step. |
| SETTINGS | `ui/menus/settings_panel.gd` (a section at the end + one line) | HELP page: **PIP'S LESSONS** beside SIMPLE / CLASSIC; a tap sets the replay flag and saves; the button says "PIP IS COMING!". |
| Saves | `core/save/profile_data.gd`, `core/save/profile_backup.gd`, `world/world_meta.gd` | `ProfileData.tutorial`; the backup merge; `WorldMeta.tutorial_props` (cleaned on load). |
| Sandbox | `scenes/sandbox.gd` (a section at the end + one line each in `_ready` and `_setup_local_player`) | `_add_tutorial`, `_setup_tutorial_local` (where it plays, the world and the meta, the pets, the monsters, Session's gold and bag, the trading's tip and arrow, the cards under the pause menu), `_tutorial_avoid` (Tilly 9, the Totem 5, the portal 5, the Theater 9 from its middle, the stone circle 6, the quest givers 5, the helper's stand 5). |
| Smoke run | `tools/tutorial_smoke.gd`, `tools/tutorial_smoke_steps.gd` | Below. |

### The flow

1. First launch: age → name → look → controls → menu (owner #52: no language card). SURVIVOR → a new world (any
   difficulty, CLASSIC). When the player stands in the world the director asks the site on a worker thread (0.4–2 s
   while the world loads) and the offer comes; owner #37's shop tip waits.
2. PLAY WITH PIP: Pip rolls up (a visitor unless the profile has him); the playground goes in; the card shows step 1
   and the arrow points at "Pip's playground". Each step done: a praise toast, Pip's cheer, the next card.
3. The Tilly step shows #37's picture tip and its arrow; within the tap's reach of Tilly the tutorial ends: 500 gold,
   Pip's Cap, Pip is the child's pet (`give_pip`; the same Pip keeps rolling), everything put back, the reward card.
4. The X (or the game closing) at any step: the playground goes (or goes at the next start), the visitor Pip goes
   home; the next solo Survivor start asks "Shall we go on where we stopped?".

## Skills and patterns (godot-prompter)

- **state-machine:** chose the enum-style step index over one table (`TutorialRules.STEPS`, `_enter` / `_check` /
  `_leave` in the director): seven linear steps with no nesting. Rejected a node-based FSM (a node per step for seven
  rows of data) and a resource-based one (nothing to edit in the Inspector).
- **godot-ui:** containers built in code, the `QuestOverlay` base for the cards that take touches before the HUD, the
  step card anchored top-centre with fixed width and measured against every HUD button at 16:9 and 20:9 (like the pet
  card). Rejected a `Window`/popup (touch and focus trouble on phones), a `TabContainer`, a Theme resource.
- **multithreading** (the trading's pattern): the site search runs in a `WorkerThreadPool` task over the terrain rules
  only (thread-safe; the real-world check stays on the main thread), polled each tick, waited for in `_exit_tree`.
- **godot-testing:** GUT, pure rules unit-tested, the director with stand-in callables and a cell-dictionary
  `WorldService`, a real `Player` (physics off) moved by the test, and a real headless smoke run.

## Tests (RED → GREEN)

| File | Tests | RED |
|---|---|---|
| `tests/unit/test_tutorial_rules.gd` | 15 | `Identifier "TutorialRules" not declared` |
| `tests/unit/test_tutorial_course.gd` | 12 | `TutorialCourse` not declared; then the water test's own lambda (it said "dry" where it meant "wet"); then real worlds: 1 of 12 had no site with a tree margin of 2 (a trunk-free 28 × 9 is 2.8 % of meadow ground) → trunks only kept off the pad, tolerance up to ±4 |
| `tests/unit/test_tutorial_props.gd` | 11 | `TutorialProps` not declared; `touches` missing; `TutorialCourse.box()` missing; "a cell still holding what it held is nobody's block" (a half-laid playground gave its unwritten cells to the child) |
| `tests/unit/test_tutorial_checks.gd` | 14 | `TutorialChecks` not declared. The last two (higher ground behind the pad, the hole's lip) came from the smoke run (below) and were written with their fix |
| `tests/integration/test_practice_slime.gd` | 5 | "Invalid access to property or key 'practice'"; the real slime hurt the child (12 of 20 hearts), a hit beat it, it had a mind |
| `tests/integration/test_tutorial_ui.gd` | 9 | written first, first run after the classes (all green) |
| `tests/integration/test_tutorial_director.gd` | 19 | `TutorialDirector.new()` on a script that didn't compile (`sees` untyped); then "the hole must be jumped" (the test teleported across in one tick — now it walks round the side) and "the playground is back for it" (the child stood on the playground: placing waits for them — now it places unless a cell `touches` them); photo mode: the card and the glow stayed on (`hud.visibility_changed` now hides them); "Invalid assignment of property 'write_batch'" (a batch a tick) |
| `tests/integration/test_tutorial_settings.gd` | 2 | `Cannot find member "PIP_COMING"` |
| `tests/integration/test_trade_director.gd` | +2 | "Invalid assignment of property 'hold_tip'", "Nonexistent function 'show_tip'" |

## Smoke run (headless, real terrain)

`XDG_DATA_HOME=<private dir with "smoke" and a copy of profile.json> godot --headless --path . --script res://tools/tutorial_smoke.gd`
(`-- --seed=<n>`). A new solo Survivor world (NORMAL, CLASSIC), 24 checks. **Seeds 20260925, 12345, 777, 99 and 4242
pass** (each about 25–35 s, every step with simulated input: the stick, the camera's yaw, JUMP ×3, the edit requests,
C in the bush, the CRAFT page and the craft request, the walk to Tilly). Sites 12–16 blocks from the spawn,
167–211 cells. The first runs found three real things, all fixed test-first:
1. A child who ran down onto the pad from higher ground and jumped never touched the start on the pad → the ground
   behind the pad counts as this side.
2. A child standing on the hole's lip has their middle over its first column → the lip counts as this side.
3. A full triple jump carries ~12 blocks and landed in the bridge's hole ("fell in") → past the jump's hole is past it,
   the bridge's hole too.
(And the smoke's own walker learnt to round the stone circle's stones and to stand back from the bridge's cells.)

## Measurements (desktop, other agents' suites running: load 7–28 on 24 cores)

- The site search (worker thread): 240 worlds (universes 1–4 × terrains 1 and 2 × 30 seeds): **239 have a playground**
  (the Candy Kingdom missed one); average 6–28 ms, worst 88 ms alone; in the game 0.4–2.1 s of wall time after the
  spawn (the pool is busy while the world loads), so the offer comes a moment after the world shows. No frame waits.
- **Laying it out, first version (all on one frame): 193 ms, then 255 ms** — copy 0.1, natural check 32, plan 106,
  meta save 1.7, `set_blocks` of 211 cells 115. Now: the copy on the main thread (0.1 ms), the check and the plan on a
  worker thread (116–421 ms of wall time), the record saved (1.7 ms), then **16 cells a tick: the slowest tick 12–35 ms**
  over five worlds (a 32-cell batch right after a world loads took 9–44 ms; clearing later took 0.7 ms a batch — the
  cost is the busy first seconds of a new world, not the listeners). 98–211 cells: in within ~1.5 s.
- Per tick (10 Hz): one step's check (a few cell reads, one zone, one distance); the placement try every 0.5 s only
  until it is in. Nothing per frame but the card's visibility.
- No per-event materials: the glow is `BuildOutline`'s one shared material; the practice slime is a level-1 slime's
  shared mesh.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Where it plays:** a solo Survivor world, the CLASSIC game, universes 1–4. Never LAN (host or guest), online,
   Sandbox, Monster Wave; not Build to Survive (its night comes fast: "no timers") and not the Dragon Realm (islands over
   a void). *Cost:* a child whose first Survivor world is Build to Survive meets Pip in their first Classic world (or
   from SETTINGS).
2. **SKIP gives nothing and is never offered again, but finishing later (SETTINGS → HELP → PIP'S LESSONS) pays the
   reward** — the first finish of the profile, whenever it comes. *Cost:* if the owner meant a skip to forfeit Pip for
   good, one line in `TutorialRules.finish`.
3. **A tap outside the offer (or the pause menu) decides nothing:** it is asked again at the next start; the shop tip
   comes meanwhile. *Cost:* a child who closed it by mistake sees it once more.
4. **The steps are the brief's, minus the Totem** (owner #44). **"Craft a stick at a crafting table":** sticks are a
   hand recipe (spec §12.19), so sticks crafted anywhere count; Pip's Workbench stands on the playground, the card says
   "by the Workbench", and the bag opens on CRAFT during the step. *Cost:* none known.
5. **The playground** (24 × 5, in one straight line; the holes span the pad's width so it can't be walked round on the
   pad) is laid out **inside** the treasure pack's 60-block spawn circle — no treasure place ever stands there, so it
   never overlaps one — clear of Tilly, the Totem, the portal, the stone circle, the Theater, the quest giver, the
   helper's stand and the spawn. The pad cuts or fills at most 4 blocks. *Cost:* in the rare world with no such site
   (1 in 240 measured) the tutorial is not offered there ("TUTORIAL no playground here"); it waits for another world.
6. **Trunks never stand on the pad; a tree beside it keeps its trunk** (leaves over the pad below 5 blocks go while it
   stands and come back). A margin of 2 like the Theater's left too few sites. *Cost:* some leaves overhang the course.
7. **Nothing is kept:** the playground is real blocks while it stands (the child's real actions: placing, breaking,
   crouching in a real bush); every cell is recorded in `WorldMeta.tutorial_props` and saved before the world changes,
   put back at the end or the X, and after a crash at the next start of that world (host or solo). *Cost:* a record
   whose part of the world isn't loaded at the next start (the child spawns far away) is put back when they come near.
8. **Never built over a child's build** (a non-natural block in the volume: another site) **or under the child**
   (it waits: "Step off so Pip can build the playground!"). *Cost:* a child standing on the spot waits a moment.
9. **Blocks:** blocks the child built into the playground's cells (the bridge) go back to their bag when it goes; what
   breaking gives them (the wall's dirt, a Workbench they break) they keep, as anywhere in Survivor; a child with fewer
   than 3 blocks gets 3 dirt at the bridge. *Cost:* breaking Pip's Workbench gives one Workbench (4 planks' worth) per
   run; replays could farm that slowly.
10. **The practice slime is a real slime** (`Monster.practice`): it sees and chases, so hiding is the real lesson, but
    never hurts, is never beaten (a hit pushes it: no coins) and has no mind. Hiding = crouching in the bush (M2 Task 5)
    while it's within 16 blocks and doesn't see the child, 1.5 s. It comes from the course's far end and puffs when the
    step is done. *Cost:* a child who fights it can't win (the card says hide).
11. **The jump:** from this side (the start, the hole's lip or higher ground behind the pad) to the next floor contact
    past the hole (the bridge's hole counts: a triple jump carries ~12 blocks). A landing in the hole says "Jump out and
    try again!"; walking round the side doesn't count. The hole is 6 wide: one jump carries ~4.5 m, so it takes a double
    or triple jump; a child whose setting is double jump can do it. *Cost:* a child who bridges the jump's hole and walks
    across passes too.
12. **The bridge:** any row of three solid blocks across the second hole at the pad's level (the middle row glows).
    **The wall:** a way through (both blocks of one column).
13. **Move and look:** walk 3 blocks and turn the camera 90° in all, and be within 3 blocks of the start (the arrow,
    "Pip's playground"). *Cost:* turning once toward the arrow may already be "looking around".
14. **Tilly reuses owner #37's tip** (`TradeDirector.show_tip`: the same picture hint and the find arrow, marked seen);
    the step ends within the tap's reach of her (6 blocks). The first-time tip waits while the tutorial is offered or
    playing and comes after SKIP, the X or "later". No Tilly: the step passes. *Cost:* none known.
15. **Pip:** a visiting Pip (the profile's own when there is one) while it plays; he goes home at the X; the first
    finish makes him the child's (`give_pip`) and the same Pip stays. A Pip in a hole is lifted out beside the child.
16. **The card** sits under the toasts (390 wide, at most 150 high), between the top-left buttons (and RIDE) and the find
    arrow, above the crosshair; only its speaker and small X (52 px) take touches; it steps aside while a picture hint
    shows (the Tilly tip). Not a HUD button and not in `HudLayout`. *Cost:* 52 px is under the 135 px of HUD buttons —
    the brief asked for a small X.
17. **Voice:** every line has an id (`TutorialRules.LINES`); a step's words are read aloud with "Read to me" and
    babbled by Pip; the speaker reads them any time; praise and retry lines are toasts (read with "Read to me").
    **English only** (owner #52).
18. **No timers:** nothing counts down; the only hold is the 1.5 s hidden in the bush.
19. **SETTINGS → HELP → PIP'S LESSONS** sets the replay flag: a solo Survivor game starts it within a second (from the
    pause menu: as soon as the game goes on); from the main menu, the next solo Survivor game. *Cost:* tapped in
    Sandbox, it waits for Survivor.
20. **The pause menu closes the offer** (QuestOverlay pauses close it): "later". *Cost:* as ruling 3.
21. **The playground builds up over about a second** (16 cells a tick; the steps and the glow wait until it is all in)
    instead of in one frame (193 ms on the desktop, far more on a phone). *Cost:* the child sees it appear in a moment;
    the lead should check the tick cost on the emulator right after a new world loads (the worst time).
22. **Photo mode hides the card and the glow** with the HUD (it pauses solo play, so nothing else moves).

## Hooks in shared files (for the lead)

| File | What |
|---|---|
| `scenes/sandbox.gd` | `_add_tutorial()` after `_add_trading()`; `_setup_tutorial_local()` after `_setup_trading_local()`; section at the end |
| `entities/monsters/monster.gd` | `practice` read in `setup`; guards in `take_hit`, `_attack`, `_mind_ready`; section at the end |
| `world/trade_director.gd` | `maybe_tip` split into `hold_tip` + `show_tip` |
| `ui/menus/settings_panel.gd` | one line in `_add_words_page` (the controls row); section at the end |
| `core/save/profile_data.gd`, `profile_backup.gd`, `world/world_meta.gd` | the fields, each marked "M3 Task 15" |

## What the lead should check on the emulator

1. **First Survivor start** (clear the app's data): age → name → look → controls → menu → SURVIVOR → NORMAL →
   CLASSIC: "Hi! I'm Pip!" with PLAY WITH PIP / SKIP once the world shows; no shop tip yet.
2. **PLAY:** Pip rolls up; the arrow says "Pip's playground" (and "You found Pip's playground!" there); the playground
   near the spawn (a level pad, two holes across it, a dirt wall, two bushes, a Workbench) in both styles; the glow on
   the step's cells.
3. **By hand:** triple jump the first hole (fall in once: "Jump out and try again!"); 3 blocks across the second hole;
   the pickaxe through the wall; the practice slime comes ("!"), crouch in the bush ("?"), it never hurts; + opens on
   CRAFT, sticks; follow the arrow to Tilly (#37's tip shows, the card steps aside).
4. **The end:** +500 gold on the counter, Pip's Cap in AVATAR, Pip follows into the next world; the playground gone and
   the ground as it was; the bridge's planks back in the bag.
5. **The X** mid-way: all gone, Pip goes home; SAVE & QUIT and back: "Shall we go on where we stopped?" → same step.
6. **A crash** (swipe the app away mid-tutorial), relaunch, CONTINUE: no playground left in the world.
7. **SETTINGS → HELP → PIP'S LESSONS** in the pause menu → RESUME: it starts again; the end says "Well done!" and no
   second 500 gold.
8. **The card** on 2400 × 1080: under the toasts, clear of CHAT, BOOK, RIDE and the find arrow; X and the speaker work;
   "Read to me" on: each step is spoken.
9. **Performance:** the frames while the playground goes in (16 cells a tick for about a second, right after a new
   world loads: the logcat line `TUTORIAL playground in: … the slowest batch … ms`) and the steps (10 Hz).
10. **Never** in a LAN game (host or guest), online, Sandbox, Monster Wave or Build to Survive.

## Suite and commits

- Before: lead-merge `8445d17` (English only) — this branch's first full suite with the feature: **607 scripts, 5,735
  tests, 5,733 passing**, 2 risky/pending (the existing "did not assert"), exit 0 → commit `e94ae1f` (the feature).
- `79834ea`: merge of lead-merge `33c8356` (#53 weapon strength, the resume doc); no conflicts.
- Then the frame cost: one bulk copy, the plan on a worker thread, 16 cells a tick, the clearing rule for unwritten
  cells, photo mode hiding the card (tests first: `test_the_plan_and_the_checks_read_only_inside_the_courses_box`,
  `test_cells_not_written_yet_give_nothing_back`, `test_the_playground_goes_in_and_out_a_batch_a_tick`,
  `test_photo_mode_hides_the_card_and_the_glow_with_the_hud`); the smoke run passes seeds 20260925, 777, 12345, 99, 4242.
- **Final full suite (after the merge): 608 scripts, 5,747 tests, 5,745 passing**, 2 risky/pending, exit 0.
  This branch's own tests: 87 in 8 new files + 2 in `test_trade_director.gd`.
