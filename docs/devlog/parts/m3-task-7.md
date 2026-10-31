# M3 Task 7: smart blocks and Game Blocks (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `e5d3349`, after
M2 Task 17's HUD pass and M3 Task 5's universes), without the editor or the emulator. Spec §14.4, §3a (Game
Blocks: "an obstacle course or race in 60 seconds, no code"), §5.5, §16 (the signature moment "friends racing
your course"); plan Task 7. Allocation: block ids 192–207 on page 9 (`data/blocks/pages/smart*.png`), the race
clock top-centre below the wave/boss lines (a label, never a button). Reused, not re-added: `PRESSURE_PLATE`
33 (temple plates keep working; a plate a player placed powers too), `JUMP_PAD` 36 / `SPEED_PAD` 37
(`PadRules`), `DOOR` 25 / `DOOR_OPEN` 26 (untouched: power opens only powered doors).

## What was built

| Piece | Where | What it does |
|---|---|---|
| Blocks 192–207 | `data/blocks/block_ids.gd`, `data/blocks/smart_page.gd` (`SmartPage`, page 9, registered at the top of `BlockLibrary.build()`) | BUTTON / BUTTON_ON, LEVER / LEVER_ON, POWERED_DOOR / POWERED_DOOR_OPEN, LAMP / LAMP_ON, LIGHT_SWITCH / LIGHT_SWITCH_ON, TELEPORT_PAD, START, CHECKPOINT, FINISH, COIN, BOUNCE. On states glow (unshaded page material); an open powered door and a coin are kind `&"pass"` (cut out, no collision boxes **and** no mesh collision). None is in `PLACEABLE` (the BLOCKS grid keeps its size); `SmartPage.SMART_ROW` and `GAME_ROW` are the SMART tab's rows. |
| Pages' art | `tools/make_smart_page.gd` (pixel, original), `tools/make_smart_page.py` (realistic twin: the pixel designs smoothed up with CC0 ambientCG Metal034 and Plastic013A laid over; flat normals on glowing tiles) | `data/blocks/pages/smart.png`, `smart_albedo.png`, `smart_normal.png` |
| Power rules (pure) | `core/rules/power_rules.gd` (`PowerRules`) | Taps (`is_switch`, `tapped`), sources (`gives_power`: BUTTON_ON, LEVER_ON, LIGHT_SWITCH_ON, a plate someone stands on), consumers (powered doors, lamps), `is_powered` (6 faces), `door_stack` (≤ 3), `consumer_changes` (a doorway as one), `item_of` (an on state is its plain block), `matters`, `TapLimiter` (≤ 5 a second, or 20 for touches) |
| Teleport links (pure) | `core/rules/teleport_links.gd` (`TeleportLinks`) | The nearest free pad pairs; a broken pad's partner pairs again with the nearest free one; ≤ 64 pads; saved as `[x, y, z(, px, py, pz)]`, checked when loaded |
| Course rules (pure) | `core/rules/course_rules.gd` (`CourseRules`), `course_run.gd` (`CourseRun`), `course_book.gd` (`CourseBook`) | The block under the feet (`floor_block`, a foot on the edge counts), default goals (× 1.0 / 1.3 / 1.6, ≥ 1 s), `clean_goals`, `step_goal` (the order holds), `medal`, `fell` (> 12 below, water, out of the world), `format_time`; one runner's run (armed / running, checkpoint, coins once, finish, the way at 10 Hz); a world's courses (keyed by START; the FINISH of the first finished run; goals; best time and name; the best run for bots; ≤ 16 courses, ≤ 8 recordings) |
| Recorded runs (pure) | `core/rules/recorded_run.gd` (`RecordedRun`) | 10 Hz positions, ≤ 1800 (3 minutes), `sample_at` / `facing_at` between samples; saved as int16 decimetres from the START in base64 (3 minutes ≈ 14 KB), checked when loaded (base64 chars, whole samples, 2..1800) — M4's ghost races can reuse it |
| Save | `core/save/smart_state.gd` (`SmartState`), `world/world_meta.gd` (field `smart`) | `{"teleports", "courses", "power"}`, cleaned when loaded (never fails) |
| Host requests | `autoloads/session.gd`, section "M3 Task 7" | `request_smart_tap` / `host_smart_tap` (a switch there, reach, ≤ 5 toggles/s) → `smart_tap_requested`; `request_smart_touch` / `host_smart_touch` (the block is there, the body the host knows is within 3.5 blocks, ≤ 20/s) → `smart_touch_requested`; `power_set_blocks` (only off/on states of the same item; a closing doorway waits while someone — player, bot friend, monster — is in it; no undo step, no ledger); the goals panel's `request_course_info` / `request_course_goals`; `send_course_state` / `send_course_info` |
| Smart director | `world/smart_director.gd` (`SmartDirector`, node `Smart` on every peer) | Host: taps, power flushed at once (≤ 64 cells a tick), buttons pop up after 1 s, plates under players' and bot friends' feet looked at 10 times a second (memoised per quarter block), teleport trips (the arrival pad waits until they step off, 1 s cooldown), saved cells looked at again on load; every peer: clicks, door sounds, sparkles |
| Course director | `world/course_director.gd` (`CourseDirector`, node `Courses` on every peer) | Every peer: `watch()` on its own player (reads blocks only when the feet change cell or stand/leave), falls back to the checkpoint on its own game, the race clock's state; host: every runner's run on the host's clock, results, the finish toast for the others, samples every running runner at 10 Hz, stops a runner knocked out, gone, 256 blocks from START or 15 minutes on; `race_bot` |
| Bounce pad | `core/rules/pad_rules.gd`, `entities/fx/pad_fx.gd` | `BOUNCE` is a pad: 21 m/s up (jump pad 16), keeps the run, the same cooldown; a pink puff and a louder boing; players and animals |
| Bot races | `entities/bots/bot_friend.gd` (one hook line + section), `world/bot_director.gd` (section), `ui/menus/friends_panel.gd` (RACE ME! per row), `ui/menus/pause_menu.gd` (one line) | `race_ready` (by START, "Ready! Step on START and let's race!"), `race_go` when a runner starts that course, replays the best run at 0.9–1.1 × (no pathfinding, no physics), confetti and its time at the end; gives up after 60 s ("Let's race another time!") |
| HUD | `ui/hud/race_clock.gd` (`RaceClock`), `ui/hud/course_panel.gd` (`CoursePanel`), `ui/hud/hud.gd` (section "M3 Task 7: races"), `ui/hud/hud_layout.gd` (spot `race`, `TOAST_RACING_Y`) | The race clock (clock picture, time, star coins; at FINISH the medal's picture, the time, sparkles on a best; hides after 5 s); the toasts step down under it while it shows; the goals panel (medal pictures, times, big − and + buttons, the best time, a robot badge when a bot can race it) |
| Taps | `entities/player/block_interactor.gd` (one line + section) | A tap on a switch asks the host; a tap on START or FINISH shows its course (not while racing); whatever is in the hand; a creature in front takes the tap (like doors) |
| Palette | `ui/hud/block_palette.gd` | A SMART tab beside BLOCKS and ARMORY: a SMART row and a GAME row (grids, so the TOOLS row stays the second box row) |
| Shop | `core/economy/shop_rules.gd` | Tilly's HOME section sells every smart block, Game Block and the Lab's pads at fixed prices (× 2^(u−1) per universe); powered doors and teleport pads in pairs, coins in fours; never bought back |
| Survivor | `core/survival/gather_rules.gd` | On states break into (and an undo gives back) their plain block; a pressure plate breaks into a plate |
| Monsters | `core/rules/defense_rules.gd` (one condition) | Monsters never climb or hop over a closed powered door (like a door) |
| Sandbox | `scenes/sandbox.gd` (5 lines + section) | Directors on every peer; host start from `meta.smart` after the bot friends; this player's watcher and HUD; `meta.smart` saved; Back and the pause menu close the goals panel |
| Smoke run | `tools/smart_smoke.gd` (+ `_steps`) | Real terrain, library and physics (below) |

## Skills and patterns (godot-prompter)

- **multiplayer-basics:** host-authoritative requests. A tap is an `any_peer` RPC the host checks (block,
  reach, rate) and hands on as a host signal; a runner's own game reports what its feet touch (its body is
  simulated there, so a single frame on a block is never missed) and the host believes a touch only when the
  block is there in its world and the body it knows is within reach. The results come back by `authority`
  RPCs to that runner. Rejected: the host watching every runner's feet from its own copies at 10 Hz (a runner
  crossing a one-block FINISH at speed-pad speed moves 1.4 blocks a tick: finishes missed) and a
  `MultiplayerSynchronizer` for run state (a per-runner state only that runner needs).
- **save-load:** JSON in `world.json` (the world's own save), one `smart` dictionary with a cleaning parser
  (`SmartState.clean`: never fails, broken parts read as nothing), recordings as compact base64. Rejected:
  Resources (`.tres`) for courses (the same security warning as the skill gives, and they are world data) and
  a separate file per course (more files to keep in step on a crash).
- **hud-system:** the race clock is a `PanelContainer` under the HUD's CanvasLayer with `MOUSE_FILTER_IGNORE`
  everywhere (never takes a touch), placed from the one layout table; pictures drawn in code like `HudIcons`
  (no textures). Rejected: a `TextureProgressBar`-style bar or a Label3D over the course (the time is for the
  runner; top-centre is where M2 put the wave line and boss bar).

## Tests (RED → GREEN)

Suite (`tests/run_tests.sh`, exit 0, "All tests passed", run on a snapshot of the staged index as DEVELOPMENT.md
§8 says): **282 scripts / 2742 tests before → 294 scripts / 2853 tests** at the first commit (`031e1bb`); **2854**
with the second commit's added teleport test.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_smart_blocks.gd` | 10 | written first; first run after the blocks: 1 failure — "Open Powered Door has a picture" sampled two transparent pixels of the cut-out frame; the test now counts drawn pixels |
| `tests/unit/test_power_rules.gd` | 11 | "Assigned value for constant "B" isn't a constant expression" (the test's own alias; removed), then green |
| `tests/unit/test_teleport_links.gd` | 8 | written first, green on the first run; the nearest-first rule survived a mutation (every scenario had one free pad: live, at most one pad ever waits), so `test_free_pads_in_a_save_pair_nearest_first` was added and kills it |
| `tests/unit/test_course_rules.gd` | 17 | written first; one expectation of mine was wrong (36 s against goals 30/35/45 is bronze, not silver) and was fixed to 34 s |
| `tests/unit/test_recorded_run.gd` | 6 | written first, green on the first run (then mutation-checked through `test_courses`: a run over 3 minutes kept → fails) |
| `tests/unit/test_world_meta_smart.gd` | 3 | written first, green on the first run |
| `tests/integration/test_smart_power.gd` | 16 | "Could not find type SmartDirector" (not built yet); then 2 test-setup failures (a fake guest peer must be connected to peer 1 before an RPC, as `test_doors` does) |
| `tests/integration/test_teleport_pads.gd` | 8 | "Could not find type SmartDirector"; then green |
| `tests/integration/test_courses.gd` | 17 | "Could not find type CourseDirector"; then one setup failure (the goals panel test's player was out of reach of FINISH) |
| `tests/integration/test_bot_race.gd` | 7 | "CourseDirector not declared", "Could not resolve external class member race_with"; then one test step too short (a 10 s run at 0.9 × takes 11.1 s) |
| `tests/integration/test_palette_smart.gd` | 3 | written with the tab (not seen red); mutation: a SMART tab without the GAME row → 3 failures |
| `tests/integration/test_race_hud.gd` | 5 | "Could not resolve external class member race_clock" (HUD section not there), "RaceClock not declared" |
| Changed | `test_gather_rules` (a plate breaks into a plate), `test_block_palette` and `test_counted_hotbar` (the SMART page's buttons counted), `test_palette_armory` (three tabs), `test_hud_layout` (the race clock showing, one more label that must be clear of every button and label, wave and boss included), `test_hud_overlays` (+1: the goals panel above every button) | |

The pure rule files (phase A) were written before their classes, but their first run was after I had written
the classes too, so for those the RED was not watched separately (the parse errors on the missing classes are
what it would have been). Every director, HUD and bot-race test was seen failing first.

**Mutation checks** (each rule broken, its tests run, the rule put back; every one failed tests): a lit lamp
passing power on (chains) — 2; no rate cap on taps — 1; a doorway closing on someone — 1; no reach check on
touches — 2; the arrival pad sending straight back — 1; pads pairing with the first free pad — 1 (after the
added test); coins paying gold — 1; a finish without START counting — 1; a recording over 3 minutes kept — 1;
the SMART tab without its GAME row — 3; the race clock at y 40 (over the wave line) — 2; the toasts not
stepping down — 1; the bounce pad as strong as a jump pad — 1.

## Headless smoke run

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/smart_smoke.gd`

30 checks. **The first runs found a real engine behaviour**: after laying a floor (about 1,000 `set_block`
calls around the standing player) the player fell through the ground 28 blocks in 3 of 4 runs while the chunk
was re-meshed, so every tap was "too far away". Not a bug of this task (a smoke run's bulk edit), but written
down in DEVELOPMENT.md §8; the run now stands the player on the new floor again first. After that, **4 of 4 runs
passed** (`SMART_SMOKE result fails=0`, load 16–30): the lever lights its lamp, the button opens the doorway
(a physics ray goes through the open doorway: kind `pass` has no mesh collision) and it closes a second later,
the plate opens it while stood on, the teleport pad carries the player to the other pad and not back, a course
run arms on START, runs off it, counts the coin, takes the checkpoint, brings a 14-block fall back to it, and
FINISH gives a gold medal on the race clock (about 4.3 s), the best run is recorded, a bot friend joins, RACE
ME! makes it wait by START, it starts when the child steps off START and finishes at FINISH ("Tinker (bot)
finished: 0:04.3!"), and `world.json` keeps the teleport pair, the course, its best time and its recording.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **16 ids, one per state:** BUTTON/BUTTON_ON, LEVER/LEVER_ON, POWERED_DOOR/…_OPEN, LAMP/LAMP_ON,
   LIGHT_SWITCH/…_ON, TELEPORT_PAD, START, CHECKPOINT, FINISH, COIN, BOUNCE fill 192–207 exactly. *Cost:* a
   later smart block (a timer, a repeater) needs another page.
2. **LAMP is new; `LIGHT` 10 stays always on** (every build made before looks the same). A lamp lights only its
   look (the unshaded page material; no light node) and does not stop night spawns (LIGHT and LANTERN do).
   *Cost:* two light-looking blocks; a child may expect a lamp to keep monsters away.
3. **LIGHT_SWITCH is a lever with a light switch's look** (the same rule). *Cost:* a redundant block, kept
   because "a switch for my lamp" is what a child looks for.
4. **Power is one step and a doorway is one consumer:** a source powers the blocks touching its 6 faces; a
   powered door powers its whole stack (≤ 3, like M2's doorways), so a lever beside the bottom door opens the
   doorway; nothing powered passes power on. *Cost:* a child can't open half a doorway.
5. **Power opens only powered doors, never M2's hand doors** (a tap on a hand door still toggles it; a tap on a
   powered door does nothing special — it is a block to build against). *Cost:* a button beside a hand door
   does nothing (their pictures differ: a steel door with a lightning bolt).
6. **Plates are pressed by players and bot friends** (up, not in Ghost), looked at 10 times a second — not by
   animals or monsters (a monster must never open a child's door, §6). Temple plates (M2 Task 16) keep their
   own puzzle; they would power a smart block placed next to them. *Cost:* an animal pen with a plate door
   won't open for animals.
7. **On states are the same item; a plate breaks into a plate.** Breaking a lever that is on gives a lever, an
   undo gives it back (`GatherRules.cost` → `PowerRules.item_of`). M2 Task 16 made plates break into stone
   ("secrets are stone"); a plate is now something children buy and place, so it gives a plate (temple plates
   too: Tilly never buys plates, so no gold is made). *Cost:* a temple's plates can be taken home.
8. **Power changes are host edits without an undo step or the Survivor ledger**, and `power_set_blocks` only
   ever flips a block between its off and on states (the same item), so no request can make or remove a block
   through power. They sync to guests like every edit.
9. **A closing powered doorway waits while anyone is in it** (player, bot friend that is up, monster — never
   half of it), tried again every tick; opening never waits. *Cost:* a monster standing in a doorway keeps it
   open until it moves (it can't open it).
10. **Taps:** the building reach, at most 5 toggles a second per player; extra taps silently do nothing (a
    toast per drummed tap would be noise). *Cost:* a child drumming a lever sees it stop answering for a moment.
11. **Touches are reported by the runner's own game** (START, stepping off START, CHECKPOINT, FINISH and coins
    while racing, teleport pads) and believed by the host only when the block is there in its world and its copy
    of the body is within 3.5 blocks (≤ 20 a second). That is "host-checked: passed START and within reach".
    *Cost:* a guest with more than ~0.5 s of lag at speed-pad speed may have a FINISH refused; stepping on it
    again counts.
12. **The clock starts when the runner steps off START** (0:00.0 while standing on it; touching START again
    starts over). *Cost:* none known; it is the fairest start for a child who waits on START.
13. **A course is its START;** the FINISH of its first finished run belongs to it (a tap on that FINISH, or on
    the START, opens its panel); any FINISH ends a run. *Cost:* two courses sharing one FINISH show the first
    course's panel.
14. **Goals:** the first finished run sets them (× 1.0 / 1.3 / 1.6, so the first runner gets gold); anyone in
    reach changes them (− and +, a second a tap, the order kept). No medal is still "FINISHED" with a star (no
    shame words). *Cost:* a LAN friend can change the host's goals (cosmetic; reach checked).
15. **Coins stay:** a coin block counts once per run for each runner (everyone can collect it), course score
    only, never gold — no code path of the courses touches a wallet (mutation-checked). *Cost:* a child may
    expect the coin to vanish.
16. **Falls** (> 12 blocks below the last checkpoint or START, swimming or diving — wading doesn't count — or
    out of the world) bring the runner back on their own game; the clock keeps running. A knock-out, leaving,
    256 blocks from START or 15 minutes stop the run (the clock hides).
17. **The best run of anyone** (not only the builder's) is recorded, by the host at 10 Hz on its clock, ending
    on FINISH; over 3 minutes it is not kept (the time still counts); at most 16 courses and 8 recordings per
    world (the least lately raced give way). *Cost:* `world.json` grows up to ~115 KB with 8 three-minute runs.
18. **Bot races:** RACE ME! on each friend's row of the FRIENDS page (host only; the menu closes). The friend
    races the best run of the course nearest its player (≤ 64 blocks) as its own, at 0.9–1.1 × speed (a
    different time each race: it may win or lose), starting when anyone starts that course, and waits ≤ 60 s.
    While racing it follows the recording without physics or pathfinding. *Cost:* it passes through a door
    closed since the recording, and dives where the recorded child fell.
19. **Finish news:** the other players get a toast ("Kid finished: 0:42.3  GOLD!"), a bot's finish too ("Pip
    (bot) finished: 0:41.2!", always labelled as a bot). The runner gets the race clock's result, a toast and
    confetti.
20. **Teleport pads:** a new pad links with the pad waiting (the nearest free one; a save with several free
    pads pairs them nearest first); out on top of the partner (two cells of room, else "The other teleport pad
    is blocked!"); the arrival pad waits until the player steps off it; 1 s cooldown; players only (bot friends
    catch up as after any long jump). *Cost:* children can't choose pairs.
21. **BOUNCE** is a pad (`PadRules`): 21 m/s up (about 9 blocks; a jump pad 16), keeps the run, the same 0.5 s
    rest, players and animals. *Cost:* tuning.
22. **The race clock** sits at (−95, 90) from the top middle, 250 × 58 (under the wave line and the boss bar,
    right of the potion chips, left of the FPS on a 16:9 phone); while it shows, the toasts step down to y 156.
    It is a label (mouse ignored), never a button. *Cost:* numbers in the table.
23. **Where they are:** the palette's SMART tab (Sandbox), not the BLOCKS grid; Survivor's palette shows what the
    child owns as before; Tilly's HOME section sells them at fixed prices (button, lever, plate, light switch 3,
    lamp 4, START and FINISH 5, CHECKPOINT 3, powered doors 10 a pair, teleport pads 25 a pair, coins 2 for 4,
    bounce 8, and the Lab's jump and speed pads 6 — Task 6 had left them unsold), × 2^(u−1) per universe, never
    bought back.
24. **Monsters never climb or hop over a closed powered door** (one condition in `DefenseRules.door_in_way`).
25. **The race clock runs on locally** between the host's messages; the finish shows the host's time. *Cost:* a
    laggy guest's clock may jump a little at the finish.

## What to check on the emulator (the lead)

1. **Palette:** Sandbox → the hotbar's + → the SMART tab (right of ARMORY): a SMART row (button, lever, plate,
   powered door, lamp, light switch, teleport pad) and a GAME row (START, CHECKPOINT, FINISH, coin, bounce),
   pictures readable in both styles; BLOCKS and ARMORY unchanged; the panel still above the hotbar.
2. **Power:** a lever beside a lamp: tap → a click, the lever glows green, the lamp lights; tap again → off. A
   doorway of two powered doors with a button beside the bottom one: tap → both open (door sound), a second later
   they close. A plate beside it: stand on it → open, step off → closed; stand in the doorway and switch off →
   it stays open until you step out.
3. **Teleport pads:** two pads 20 blocks apart: step on one → sparkle and whoosh, you stand on the other; stay →
   nothing; step off and back → back again. A block over the far pad → "The other teleport pad is blocked!".
4. **A course:** START → the clock under the wave line reads 0:00.0; step off → it runs; walk through a coin →
   ding and "1"; a checkpoint → sparkle; fall off → "Back to your checkpoint!"; FINISH → the medal picture, the
   time, a toast and confetti; tap FINISH → the goals panel (medals, − / +, the best time, the robot badge);
   − / + change the times. With a toast during a race, the toast sits under the clock.
5. **Bounce pad:** a big pink boing, about 9 blocks up, the run kept.
6. **Bot race:** pause → FRIENDS → + BUILDER → RACE ME! → the menu closes, "Ready! Step on START…", the bot
   waits beside START; step off START → it runs the recorded route; its finish toast; with no course yet the
   FRIENDS page says "Finish a course first…".
7. **Survivor:** Tilly's HOME list (it scrolls) has them; buy and place a lever; break it while on → a lever.
8. **LAN:** a guest taps a lever (the host flips it), races (the guest's clock; the host's time at FINISH and
   the others' toast), steps on a teleport pad (moved on its own game).
9. **Performance:** nothing new runs per frame except the feet watcher (a cell compare; block reads only when
   the feet change cell) and the host's 10 Hz plate look (memoised); check the autopilot near a course in both
   styles.

## Merge notes (what will conflict)

- `data/blocks/block_ids.gd` (ids 192–207, names, `NON_SOLID`), `world/block_library.gd` (one line in
  `build()`, the `pass` kind in `_page_models`): other pages add theirs beside.
- `autoloads/session.gd`: a section at the end. `scenes/sandbox.gd`: one line in `_ready`, one after
  `_start_bots()`, one in `_setup_local_player`, one in `save_world`, one in the Back chain, a section at the end.
  `world/world_meta.gd`: a field, one line in `from_json`, one in `to_json`.
- `ui/hud/hud.gd` (one line in `_ready`, a section), `ui/hud/hud_layout.gd` (spot `race`, `TOAST_RACING_Y`),
  `ui/hud/block_palette.gd` (a tab, a page), `entities/player/block_interactor.gd` (one line, a section),
  `entities/bots/bot_friend.gd` (one hook line, a section), `world/bot_director.gd` (a section),
  `ui/menus/friends_panel.gd` (a signal, one line in `_row`, a section), `ui/menus/pause_menu.gd` (one line).
- `core/economy/shop_rules.gd` (HOME prices, PACKS), `core/survival/gather_rules.gd` (drops, `cost`),
  `core/rules/pad_rules.gd` (BOUNCE), `entities/fx/pad_fx.gd`, `core/rules/defense_rules.gd` (one condition).
- Tests changed: `test_gather_rules`, `test_block_palette`, `test_counted_hotbar`, `test_palette_armory`,
  `test_hud_layout`, `test_hud_overlays` (counts of the palette grow with any other task's SMART-like page).
- Not touched (the lead updates them at merge): the spec §14.4, the plan's Task 7 line, the M3 dev log.
