# Survivor games, crafting and Monster Wave (owner feedback #33, #34, #44) — M3 Task 22

**Since 21:08 (owner feedback #44, the lead):** Monster Hunter was folded into a new main mode, **MONSTER WAVE**
(spec §12.20), and Survivor lost its Totem waves and its boss. The section "Monster Wave" below has its build, its
rulings, its tests and its checklist; the Monster Hunter rulings (10–12) are kept below, marked as replaced.

Spec: §12.18 (Survivor games) and §12.19 (crafting). Plan: M3 Task 22. Agent worktree branch cut from
`m2-survive-the-night` at `13b77f4` (before M3 Tasks 7 and 12 were merged there).

The owner (2026-09-24): "in survivor mode we need different modes, one should something like you must build
a house to be able to hide from monsters, if you dont hurry and build house you diy. also anothe mode can be
like killing mosnters and as much monsters you kill you get more money" (#33) and "also we need ctafting
options, we should be able to create different things like crafting and minecraft" (#34).

## What was built

| Piece | Where |
|---|---|
| The game of a Survivor world: CLASSIC / BUILD TO SURVIVE (MONSTER HUNTER until #44), labels, kits, clock speed, night tuning | `core/survival/survivor_games.gd` (`SurvivorGames`) |
| Build to Survive's clock and words (first night 3:00, days 4×, nights 2×) | `core/survival/build_rules.gd` (`BuildRules`) |
| The shelter rule (roof within 4, walls: an exact flood at head and feet level within 6) | `core/survival/shelter_rules.gd` (`ShelterRules`) |
| *(Removed with #44: Monster Hunter's packs and pay, `HunterRules`; the combo moved to `ArenaRules.Combo`)* | — |
| Scores per player name: nights in a row and best (the hunt went with #44) | `core/survival/game_scores.gd` (`GameScores`) |
| The recipe table (28 recipes, validated: ids, counts, no loops) | `core/crafting/recipes.gd` (`Recipes`) |
| Crafting rules: stations within 4, fuel, one tool of each, all or nothing, the book's order | `core/crafting/craft_rules.gd` (`CraftRules`) |
| The host's side of both games (shelters, nights, knock-outs, packs, pay) and every peer's clock | `world/survivor_game_director.gd` (`SurvivorGameDirector`, node `SurvivorGame`) |
| The HUD's game clock (a label) | `ui/hud/game_clock.gd` (`GameClock`), `HudLayout.SPOTS.game_clock` |
| The palette's CRAFT tab: the picture recipe book | `ui/hud/craft_book.gd` (`CraftBook`), `ui/hud/recipe_card.gd` (`RecipeCard`) |
| The stick's picture (drawn in code) | `ui/hud/craft_icons.gd` (`CraftIcons`) |
| Blocks 220 CRAFTING_TABLE, 221 FURNACE (page 10, row 6, both styles); item 451 STICK | `data/blocks/block_ids.gd`, `data/blocks/portal_page.gd` (`CRAFT_TILES`), `data/items/item_ids.gd`, `tools/make_portal_page.gd` / `.py` |
| Session section `# --- Survivor games and crafting` | `request_craft`, `host_craft`, `craft_stations_near`, `craft_done`; the game to guests before `world_info`; `hunt_paid`, `game_score_received` |
| Menu: "Which game?" after COZY / NORMAL / BRAVE | `ui/menus/menu.gd` (`_choose_game`), `Game.start_world(…, game)`, `Game.new_world_game`, `Game.survivor_game` |
| Saved | `WorldMeta.game` (old worlds CLASSIC), `WorldMeta.game_scores` |
| Small hooks in shared files | `MonsterDirector` (`per_player_cap`, `level_bonus`, `defeat_payer`), `Player.sheltered` (visibility 0), `SkyCycle.game` (clock speed), `SleepDirector.may_sleep`, `ShopRules` (game prices), `ShopPanel`, `Hud.add_game_clock` / `setup_crafting`, `BlockPalette` (CRAFT tab), `BlockLibrary._static_init` (registers page 10), `scenes/sandbox.gd` (section at the end + 8 one-line hooks) |
| End-to-end smoke run on real terrain | `tools/survivor_games_smoke.gd` (+ `_steps.gd`) |

## Rulings (cost if wrong)

1. **"You die" is a knock-out.** Children's game (§6, §12.3): the owner's "if you dont hurry and build house
   you diy" becomes: outside at night the monsters are fiercer and a knock-out ends your run of nights; you
   wake at home. *Cost if wrong:* none expected; permanent death is excluded by the spec.
2. **The Build to Survive clock:** a new world starts at t = 0.25 (morning) and the first sunset comes 3:00
   later; days run 4× (3:30 sunrise to sunset), nights 2× (3:00). Constants `BuildRules.START_TIME`,
   `DAY_SPEED`, `NIGHT_SPEED`. *Cost if wrong:* if 3 minutes are too short for young children to build, raise
   the numbers (one line each; the tests read the constants for the 3:00 check only through `START_TIME`).
3. **The night clock is game time, not a pressure countdown.** The research (`docs/design/`, §7) rejects
   countdowns in shops and events that press children to spend or come back. This one is gameplay (like the
   wave's 3-minute bar): it stops when the game pauses, never counts real days, sells nothing, and its words
   are kind ("Night in 1:20", never "hurry"; the no-guilt word test scans them). *Cost if wrong:* show only the
   moon/sun picture filling up, no numbers (`GameClock.show_build`).
4. **The shelter rule is an exact flood, not 16 rays.** The brief said "every horizontal ray from the head
   reaches a solid block within 6". A fixed set of 16 rays misses a one-block window between two rays (a room
   4 wide: a window 27° off +X), and a monster walks round a bend no straight ray takes. So walls are checked
   by a flood through open cells (four sides at a time, so a crack where two blocks only touch at an edge
   stays closed) that must never get 6 or more blocks away (along x or z), **at the head's level and at the
   feet's** (a one-block hole at the feet lets a slime in). The roof is a solid block 1..4 above the head.
   Solid = `BlockIds.is_solid` (closed doors, glass and leaves are; open doors, water and bushes are not).
   *Cost if wrong:* a long L-shaped hall whose arm reaches 6 blocks away counts as open; relax `WALL_REACH`.
5. **Sheltered = invisible (visibility 0)**, like a hiding spot: monsters never see, chase or hit a sheltered
   player (`Player.stealth_visibility`), and monsters never change blocks. A monster that walked in before the
   door shut can't see them either. The host's answer (its copy of every body) is what monsters obey; each
   game works out its own player's shelter for the label and the stealth eye. *Cost if wrong:* if a child
   builds a "cage" round a monster to hide next to it, that's fine for a children's game.
6. **Fiercer nights outside:** up to 14 night monsters per player (20 in all, as before) and one level higher
   (at most 5) in Build to Survive. *Cost if wrong:* tune `SurvivorGames.BUILD_PER_PLAYER` / `BUILD_LEVEL_BONUS`.
7. **Knocked out in Build to Survive** wakes you at home as in Classic; when every player present has been
   knocked out this night (solo: at once) the clock jumps to sunrise ("Good morning! You're home."). With a
   friend still up, the night goes on. *Cost if wrong:* LAN friends who are down wait for the morning at home.
8. **Beds need a shelter in Build to Survive** ("Build walls and a roof around your bed first!"), so a bed in a
   field is no shortcut through the night. Classic and Hunter beds as before.
9. **The score:** nights survived in a row without a knock-out, and the best, per world and per player name
   (`WorldMeta.game_scores`). A knock-out starts the run again; the best stays. This is a score inside one
   world, like a wave number — nothing is ever lost by being away or playing something else, so it is not a
   §6 "streak that punishes missed days". *Cost if wrong:* if the owner finds the reset harsh, show the total
   nights instead (`GameScores` has room for a `total` key).
10. *(Replaced by Monster Wave, #44: packs, pay-at-once and cheaper weapons were removed; the combo lives on as
    Monster Wave's kill bonus.)* **Monster Hunter packs:** pack n = min(2 + n, 8) monsters, level 1 + ⌊(n − 1)/2⌋ (from pack 3 the last one a
    level up), 12–24 blocks away on the surface, day and night, 3 spawned a tick (the animals' lesson). They are
    not wild (the sun never puffs them) and walk to where the hunter stood when they came (the Totem waves'
    `goal`). The next pack comes 8 s after the last of a pack is gone (defeated or walked 64 blocks away). No wild
    night spawns in this game. *Cost if wrong:* tune `HunterRules`.
11. **Gold per defeat is paid at once, not as coins**, to the player nearest to where the last hit came from
    (a bot friend's defeat pays the nearest child, as bots never take gold), × the combo: defeats within 5 s of
    each other count up, × 2 for the second, × 3 from the third (never more). Combos count per player. A
    knock-out ends the combo, takes no gold, and the next pack is one easier (honest help, §16). Gold is
    §12.4's by kind and level, × 2^(u−1). *Cost if wrong:* combos could be per team instead.
12. **Tilly per game:** Monster Hunter's weapons (the sword, bow, spear, mace and shield lines, the hammer and
    the boomerang — not pickaxes or axes) cost 3/4, rounded up; Build to Survive's building blocks come 8 a gold
    instead of 4, **except logs** (charcoal from 3 logs + a log to burn must never sell for more than the logs
    cost: 4 logs = 1 gold = 1 coal). Tilly buys no tools, so no loop can make gold (tested for every game).
13. **Crafting — no ingots:** ores are used directly (iron ore → iron tools). One step fewer for young
    children and no new items. The tiers map: wood ← planks, stone ← stone, iron ← iron, **crystal ← diamond**
    (the owner's "diamond tools"), **cosmic ← gold + crystal** (the owner's "gold"). Swords and pickaxes in all
    five tiers, axes in three, a wooden shield. *Cost if wrong:* add ingots as crafted items 452–459 (or 490–499) and a furnace
    recipe each.
14. **The recipe book is a picture list, not a grid** (child-first: nothing to remember). Cards that can be made
    now shine (a gold rim) and come first; a tap on another says what is missing. 28 recipes (spec lists them).
15. **Furnace fuel:** one coal, else one log, per furnace craft; never the recipe's own result (charcoal burns a
    log, not coal) and never what its ingredients need. *Cost if wrong:* none (the rule is simple to change).
16. **Stations within 4 blocks of the eyes** (to the block's nearest point); the host allows 5 (a guest's body
    lags on the host), so a card that shines on the child's screen is always accepted.
17. **One of each tool** (like Tilly): crafting a sword you have says "You already have one!".
18. **Sandbox has no CRAFT tab** (everything is free there); the crafting table and furnace are in its block
    palette as decoration.
19. **The crafting table and furnace look:** tiles in row 6 of page 10, drawn by both page tools with their own
    seeds, so every older tile stays byte-identical (checked). Page 10 is now registered in
    `BlockLibrary._static_init` too (it was only registered by `build()`), so their icons exist before a world.
20. **The stick** is item 451 (crafted-only: `ItemIds.CRAFTED`, in no palette row), its picture drawn in code
    (`CraftIcons`), so no other task's item atlas changes. Held and tapped, it is refused like other items.
21. **A new crafted thing goes into the first hotbar slot whose thing the player has none of** (and is
    selected), unless it is on the hotbar already.
22. **The game carries on:** a new universe world reached by portal plays the same game.
23. **Scores are kept by player name** (like inventories); a LAN guest without a chat name keeps a session
    record ("#peer").
24. **The game clock's spot:** top, left of the middle, under the potion chips (1280-wide: x 300–600, y 164–224),
    clear of the Secret Book and of M3 Task 7's race clock (checked against `m2-survive-the-night`'s table).
    Toasts and the picture hint can pass over it for a moment.
25. **Build to Survive's hotbar** holds the doorway and the lantern (the last two slots, instead of glass and
    bricks), so a child can build the hut at once (`SurvivorGames.starter_hotbar`).
26. **Recipes only for things that exist:** the brief's ladders, chests and stone bricks have no block yet, and the
    allocation gave me only the table and the furnace; bricks come from stone at the furnace, "torches" are the
    glowing LIGHT block (coal + a stick). *Cost if wrong:* when a task adds a ladder, a chest or stone bricks, one
    line each in `Recipes.LIST` (the validator and the no-gold test check them).

## Patterns from the godot-prompter skills

- **inventory-system:** chosen — keep the game's counted `Inventory` (id → count, `changed` once per call) and
  plain int ids in one table, since blocks and items share one id space and bags hold both; a craft takes its
  ingredients and gives its result as one all-or-nothing step, and the HUD hears one snapshot a frame (Session).
  Rejected — `ItemData` Resources in `.tres` and slot arrays (ids are ints across saves, network and hotbars;
  a Resource per recipe would make the validator and the no-loop test harder).
- **state-machine:** chosen — enum-like states read from the clock, not stored (day or night from `DayCycle`,
  a pack's `n`/`left`/`wait_until`), because the host's tick recomputes them and a save needs nothing. Rejected —
  node-based state machines (fewer than five states, no enter/exit animation).
- **save-load:** chosen — JSON in `WorldMeta` with defensive parsing and defaults (an unknown game is CLASSIC,
  broken scores are dropped, counts clamped), no version bump (new keys only). Rejected — Resource saves.
- **godot-ui:** chosen — containers (`GridContainer` of cards in a `ScrollContainer`, `HBox`/`VBox` inside each
  card), `StyleBoxFlat` rims for "shines", `custom_minimum_size` for big touch targets, labels that ignore the
  mouse so the card takes the tap; the clock is a `Control` that draws its picture with `HudIcons` and never
  takes input. Rejected — a `TabContainer` (the palette already uses a plain `TabBar`: the M2 gotcha).

## Tests (RED first, then GREEN)

(Counts as first built; after #44: `test_survivor_games.gd` 11, `test_game_scores.gd` 7,
`test_survivor_game_director.gd` 10, `test_hunter_rules.gd` removed.)
Unit: `test_survivor_games.gd` (12), `test_build_rules.gd` (7), `test_shelter_rules.gd` (16), `test_hunter_rules.gd`
(9), `test_game_scores.gd` (8), `test_recipes.gd` (11), `test_craft_rules.gd` (16), `test_world_meta_games.gd` (4).
Integration: `test_craft_session.gd` (8: hand, table and furnace reach on the host, one bulk copy, a guest's craft
checked against the guest's body and bag, Sandbox refused), `test_survivor_game_director.gd` (16: shelters make a
player invisible, a monster beside a sheltered player never sees them, nights at sunrise, knock-outs and the solo
morning, friends, fiercer nights, beds, packs by day, pay with combos and no coins, the combo window, the breather,
knock-out easing, Classic unchanged), `test_game_clock.gd` (6), `test_craft_book.gd` (6), `test_craft_hud.gd` (3),
`test_survivor_games_session.gd` (4: Tilly's game prices through the host, a guest takes the host's game);
additions to `test_main_menu_modes.gd`, `test_universe_menu.gd`, `test_sky_cycle.gd`, `test_hud_layout.gd`.
RED reasons: the classes/members did not exist ("Identifier not declared", "Invalid access to property 'game'",
"Nonexistent function 'setup_crafting'"). `test_survivor_game_director.gd` passed at its first run (it was written
before the director, but only run after), so it was **mutation-checked**: removing the shelter's visibility 0, the
combo, the knock-out-tonight rule and the pay-instead-of-coins each failed its tests (5 failures), then restored.
Existing tests adapted to the new rules: the palette's three tabs (`test_palette_armory.gd`), ARMORY hidden but
CRAFT shown in Survivor (`test_counted_hotbar.gd`), counts that leave out crafted-only things
(`test_block_palette.gd`, `test_counted_hotbar.gd`, `test_item_ids.gd`), 35 placeable blocks (`test_block_ids.gd`),
page 10's tiles (`test_portal_blocks.gd`).

## What the lead should check on the emulator

1. SURVIVOR → NEW WORLD → COZY/NORMAL/BRAVE → "Which game?": three big cards with pictures and a short line each,
   BACK returns to how brave.
2. BUILD TO SURVIVE: the clock under the potion chips says "Night in 3:00" and counts down; 48 planks, 2 doors,
   a lantern in the palette; build a hut round the player (a roof and a doorway): from a minute before the night
   the clock says "Add a roof!", "Close the gap!" and "Safe inside!" with a house; at night goblins come but
   never see the child inside (no "!" over them); the morning toast "You made it through night 1! A new best!".
   Open the door at night: the clock says "Close the gap!" and monsters can see in.
3. A knock-out at night (outside): the child wakes at home and it is morning; "Nights 0 · Best 1".
4. Sleeping in a bed outside a shelter: "Build walls and a roof around your bed first!".
5. *(Replaced by #44: Monster Hunter is gone; see "Monster Wave" below.)* A new Survivor world's game choice shows
   CLASSIC and BUILD TO SURVIVE only; no Monster Totem stands in any Survivor world.
6. Crafting in any Survivor world: the palette's CRAFT tab; planks and sticks by hand; place a crafting table
   (4 planks) and the sword/pickaxe cards shine next to it; a furnace (8 stone) and glass from sand with coal.
   Both styles: the table (a gridded work top, planks with a saw and a hammer) and the furnace (cobbles with a
   glowing mouth) look right.
7. Performance: the host's shelter check reads one 13 × 6 × 13 box per player every 0.5 s in Build to Survive
   (a flood of at most ~2 × 169 cells); measure a night with 14 monsters per player on the emulator.

## Smoke run (desktop, headless)

```bash
mkdir -p /tmp/easycraft-games-smoke-1/godot/app_userdata/EasyCraft
cp ~/.local/share/godot/app_userdata/EasyCraft/profile.json /tmp/easycraft-games-smoke-1/godot/app_userdata/EasyCraft/
XDG_DATA_HOME=/tmp/easycraft-games-smoke-1 godot --headless --path . --script res://tools/survivor_games_smoke.gd
```
Prints `GAMES_SMOKE ok|FAIL …` lines and exits 0 when every check passed.

**Result (21:05, load average 41):** 30 of 30 checks ok, exit 0, no engine errors: the kit (48 planks, 2 doors,
a lantern; the doorway and the lantern on the hotbar), the first night in 178.6 s at the first check, the hut
built through the host is `safe`, the open door a `gap`, "Safe inside!" at night, no monster sees the player in
the hut, "You made it through night 1! A new best!", the knock-out at night wakes the player at t 0.155 (sunrise)
with the run at 0 and the best at 1, `world.json` keeps both; a pack of 3 by day, +12 gold for three goblins/slimes
with the combo and no coins, the clock "Pack 2 · 3" (the first pack cleared), planks, a table, a furnace and glass
crafted through the host, 28 cards on the CRAFT page. (The first run failed one check: my smoke expected "Pack 1",
but the whole first pack had been defeated, so the clock rightly showed the next pack.)

Pictures (windowed `tools/hud_shots.gd`, which now also shows the game clock and the CRAFT page): the clock sits
under the potion chips clear of every button on 1600 × 720 and 1334 × 750; the CRAFT page shows shining cards
first, have/need in orange when short, and the crafting table's picture on table recipes; the "Which game?"
screen's three cards fit their words.

## Merge notes for the lead

- `BlockIds.COUNT` (222 here) and `test_block_ids.gd`'s placeable count (35 here): other page-10 tasks change the
  same lines — take the largest id + 1 and add the counts.
- Page 10's PNGs are binary: after merging `tools/make_portal_page.gd` / `.py` (texts), rerun both tools
  (`godot --headless --path . --script res://tools/make_portal_page.gd`, `python3 tools/make_portal_page.py`) and
  `--import`. Each task's tiles use their own seed, so the order of the sections doesn't matter.
- `PortalPage.TILES` stays the portals'; other tasks' tiles can be merged in `all_tiles()` like `CRAFT_TILES`.
- The palette's tabs: any other task adding a tab must follow `CRAFT_PAGE := 2`.
- Session and sandbox: my sections are at the ends of the files, plus one-line hooks (marked "spec §12.18").


## Monster Wave (owner feedback #44, spec §12.20)

The owner (21:07): "i want to wave part and the monster part should be separated by a new gamemode ,,monster wave"
and that gamemode only is a flat world and ur goal is to stay as long as possible alive. And more time you are alive
the more gold u get when u die. But if u have managed to stay alive till the final raid boss at wave 10 u get
teleported into a another universe where u get 2xgold 2xhard and 2xharder to find secret but dosent count in
sandbox. But the player has a choise. But on the other hand in normal survival there is no longer a wave part."

### What was built

| Piece | Where |
|---|---|
| A third mode: `ModeRules.WAVE` (DAMAGE, TOTEM; no BUILDING, no FLYING, real gold), slots `wave_<u>` | `core/rules/mode_rules.gd` (new rules `BUILDING`, `FLYING`, `TOTEM`) |
| Run gold, the kill bonus (Monster Hunter's combo), lines, bests, the kit per universe | `core/arena/arena_rules.gd` (`ArenaRules`) |
| The flat arena per universe (grass / sand / snow, cover on a grid, the Totem in the middle) | `world/generators/arena_shape.gd` (`ArenaShape`), `arena_generator.gd` (`ArenaGenerator`); `WorldService.setup(…, arena)` |
| The run on the host (waves by themselves, breathers, the raid boss at 10, knock-outs, pay, bests, the choice) and every peer's clock | `world/arena_director.gd` (`ArenaDirector`, node `Arena`) |
| The result panel (PLAY AGAIN / LEAVE, or NEXT UNIVERSE / STAY) | `ui/hud/arena_panel.gd` (`ArenaPanel`), `Hud.add_arena_panel` |
| The menu: MONSTER WAVE between SURVIVOR and PLAY ONLINE; a card per universe with its best | `ui/menus/menu.gd` (`_show_wave`, `_start_arena`, `MAIN_BUTTON`) |
| Hooks in shared files | `WaveDirector` (`taps_start`, `rewards`, `knockouts_end_waves`), `WaveRules.REFUSALS.auto`, `BossDirector` (`opens_portal`, `end_fight`), `Session` (no edits without `BUILDING`, bots too), `Player._may_take_off` (no `FLYING`), `WorldMeta.arena`, `scenes/sandbox.gd` (section at the end, gates for secrets, animals, Theater, weather, the fresh tip, the Totem, the sky) |
| Survivor loses its waves | `sandbox._start_waves` returns without `TOTEM`; the Survivor tour's `wave`/`boss` checks left its list; the wave smoke run uses a Sandbox world |

### Rulings (cost if wrong)

M1. **A mode, not a Survivor game:** MONSTER WAVE is `ModeRules.WAVE` with its own arena per universe (the lead's
    brief). *Cost if wrong:* none expected.
M2. **The arena:** flat at y 32 with the universe's ground (Green Meadows grass, the Desert's sand, Frostpeak's snow;
    later universes grass until they add a palette in `ArenaShape.PALETTES`), cover in two of three 12-block cells
    (2 × 2 pillars of stone, 3-long walls of wood, 2 high) never within 12 blocks of the middle; the Totem in the
    middle, the start 6 blocks away; always noon (the sky's clock stopped). *Cost if wrong:* tune the constants.
M3. **Nothing is built or broken in the arena, and nobody flies:** a child who could wall themselves in (monsters
    never break blocks) would survive forever; flying would do the same. Refused with kind words; the WALK/FLY
    button is hidden. Bot friends build nothing either. *Cost if wrong:* allow a few blocks per run.
M4. **A fixed kit per universe** (sword, bow, spear, mace and shield of the universe's tier: stone, iron, crystal,
    cosmic; 2 Speed and 2 Moon Jump potions), refreshed every visit: everyone starts equal, nothing is carried in or
    bought (§6: no pay-to-win). *Cost if wrong:* let children bring their Survivor tools.
M5. **The waves:** §12.8's rosters (3 + 2N, team-sized, the universe's kinds and × 2^(u−1)); wave 1 comes 8 s after
    the run starts, each next 8 s after the last is cleared; a wave whose 3 minutes run out counts as cleared (the
    child survived it); Totem taps start nothing ("Here the waves come by themselves!"); a won wave pays nothing
    itself (the run pays at its end). *Cost if wrong:* `ArenaRules.FIRST_DELAY`, `BREATHER`.
M6. **Wave 10 is the raid boss** through the shared BossDirector (the universe's boss), which opens no portal in the
    arena (the choice replaces it) and still pays its 300 × 2^(u−1) split and unlocks the next universe.
M7. **The run ends when every player is down at once** (solo: the first knock-out; with friends a player who is down
    pops up on the spot — the Sandbox way, no bag — and fights on; M4 E's help-up works). The WaveDirector's own
    "everyone knocked out" end is switched off in the arena so the two rules never disagree. *Cost if wrong:* end
    at the first knock-out of anyone.
M8. **Run gold:** ⌊seconds / 10⌋ + 5 × waves cleared, × 2^(u−1), to every player in the arena, once, through
    `Session.gold_add` (their own Survivor gold). 3:24 and 5 waves = 45 gold in Green Meadows. *Cost if wrong:*
    `ArenaRules.SECONDS_PER_GOLD`, `GOLD_PER_WAVE`.
M9. **The kill bonus** keeps Monster Hunter's combo alive (the lead's suggestion): 1 gold × 1/2/3 × 2^(u−1) to the
    defeater at once, no coins in the arena. Small on purpose: the owner's gold is for time survived.
M10. **Bests** per player name per arena (`WorldMeta.arena`: best time and best wave, never lowered); "A new best!"
    on the panel; the menu's cards show them. Never a streak: a run is a run.
M11. **The choice after the raid boss:** NEXT UNIVERSE (solo: saves and opens universe u+1's arena, made the first
    time) or STAY (a new run here); when u+1 has no world yet, STAY only with "The next universe is coming soon!".
    With friends, everyone stays (the host can start the next arena from the menu). The profile's unlock also lets
    the child visit that universe's Survivor world from the hub (its secrets are the ×2 harder ones).
M12. **Survivor loses its Totem waves and its boss** (`ModeRules.TOTEM` only in Sandbox and Monster Wave); a Survivor
    world's saved wave number, boss help and old portal stay in its save (an old portal still stands and leads on).
    Sandbox keeps its gentle Totem waves (the owner spoke of Survivor only).
M13. **Monster Wave has no difficulty choice** (NORMAL): one fair arena for everyone. *Cost if wrong:* the COZY /
    NORMAL / BRAVE screen before the first run of an arena.

### Tests (RED first, then GREEN)

Unit: `test_arena_rules.gd` (7), `test_arena_shape.gd` (5), additions to `test_mode_rules.gd` (4). Integration:
`test_arena_director.gd` (14: the run starts by itself, breathers, the raid boss at 10, taps refused, waves pay
nothing, solo knock-out ends and pays, friends, kill bonus combo and no coins, PLAY AGAIN, bests, NEXT UNIVERSE /
STAY / coming soon, losing to the boss, the boss put to sleep), `test_arena_world.gd` (5), `test_arena_session.gd` (4:
no edits, no bot builds, no flying, Sandbox unchanged), `test_arena_panel.gd` (4), additions to
`test_main_menu_modes.gd` (3) and `test_game_clock.gd`. `test_arena_director.gd` passed at its first run, so it was
mutation-checked (the all-down rule, the refused taps and the no-coins pay each broke tests; restored).
Removed with Monster Hunter: `test_hunter_rules.gd` and the hunter tests of the director, the scores and the clock.

### What the lead should check on the emulator

1. The main menu's four buttons in one row (SANDBOX / SURVIVOR / MONSTER WAVE / PLAY ONLINE) on 20:9 and 16:9.
2. MONSTER WAVE → a card per universe with "Your first run!" or the best → the arena: flat grass with pillars and
   short walls, the Totem in the middle, the clock under the potion chips ("0:12 · Wave 1"), no WALK/FLY button.
3. Wave 1 comes by itself; defeats pop "+1", "+2 × 2!", "+3 × 3!"; "Wave 1 cleared! Next wave coming."; a tap on the
   Totem says the waves come by themselves; placing a block says "No building in Monster Wave. Stay alive!".
4. Getting knocked out: the panel "What a run!", the time, the waves, the gold, "A new best!", PLAY AGAIN / LEAVE.
5. Wave 10: the raid boss (the Golem in Green Meadows, the Sand Serpent in the Desert, the Frost Giant in Frostpeak),
   the boss bar; beating it: "You beat the raid boss!", NEXT UNIVERSE → the Desert's arena (sand, iron kit).
6. A Survivor world has no Totem any more; Tilly, night monsters, secrets and crafting stay; the hub lists the
   universes unlocked in Monster Wave.
7. Performance: a wave of 20 monsters in the arena (flat ground is cheap to mesh); the boss fight.

### Smoke run

`tools/survivor_games_smoke.gd` now runs Build to Survive (with crafting) and then a Monster Wave run. Result (22:00,
load average ~40): **47 of 47 checks ok, exit 0**: no Totem in Survivor; the arena is flat, the player stands on
y 32.05, the stone kit, the Totem in the middle, wave 1 by itself (5 monsters), the kill bonus +12 for five defeats
(1 + 2 + 3 + 3 + 3), no coins, the breather, no building, no flying, the knock-out ends the run with +6 gold for
18.2 s and one wave, the panel "You lasted 0:18 and cleared 1 wave! +6 gold", the best saved, PLAY AGAIN.

### Merge notes

- `WaveDirector` and `BossDirector` got small public hooks (defaults keep every other world as before).
- The main menu's buttons are 282 wide now (four in a row); any other main button must fit the same row.
- Found while merging `m2-survive-the-night` (21:10): `test_bot_minds.gd`
  `test_a_fighter_guards_the_side_monsters_come_from` failed twice at load average ~40 and then passed alone 3 of 3
  on the same tree (it passes on the main branch too): load-dependent, not this task's code.
