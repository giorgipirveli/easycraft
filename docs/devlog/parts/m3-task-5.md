# M3 Task 5: the universe ladder and portals (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `ccb03fe`,
M3 Task 1's block pages), without the editor or the emulator. Spec §14.1 (first bullets), §14.2, §5.1,
§4.3; plan Task 5. M3 Task 2 (Sandstorm Desert, universe 2) ran in parallel and reads the descriptor
interface below. Commits: `17e9d5e` (ladder, slots, scaling), `89b48f9` (portal hub, travel, the Golem's
portal), `be2ce51` (portal frames and cores) and the last one (the new world's kit, these notes, DEVELOPMENT.md).

## The descriptor interface (for the universe tasks: desert, frost, candy)

A universe is a script at `world/universes/<name>.gd`, the ladder's name: `meadows.gd` (1, written here),
**`desert.gd` (2)**, **`frost.gd` (3)**, **`candy.gd` (4)**. `UniverseRegistry` (`world/universes/universe_registry.gd`)
loads it with `ResourceLoader.exists` + `load(path).new()`, once, and reads it through these names. A
universe whose file doesn't exist is "coming soon": the hub shows its card greyed, nobody can travel there,
the Golem's portal keeps M2's words. Missing or broken fields read as safe defaults.

```gdscript
extends RefCounted                     # not a Node: `name` is our own field
var name := &"desert"                  # the ladder's name
var display_name := "Sandstorm Desert" # hub cards, portal words, the menu title
var index := 2
var monster_kinds: Array[StringName] = [&"mummy", &"scorpion"]
var boss_kind := &"serpent"
var music := {"day": "res://assets/music/desert_day.ogg", "night": "…", "boss": "…"}   # tracks MusicRules.DAY/NIGHT/BOSS; missing = Meadows'
var sky := {"sky_top": Color(…), "sky_horizon": Color(…), "ground_bottom": Color(…), "ground_horizon": Color(…), "fog": Color(…)}   # the full-day colours
var trader_stock := {BlockIds.SANDSTONE: 1, …}   # id -> price in Green Meadows gold, per one; scaled × 2^(u−1)

func generator_shape(world_seed: int) -> MeadowsShape:   # a MeadowsShape or a subclass (extends MeadowsShape)
	return DesertShape.new(world_seed)

func generator(world_seed: int) -> VoxelGenerator:       # optional: Green Meadows' MeadowsGenerator without it
	var g := DesertGenerator.new()
	g.world_seed = world_seed
	return g
```

- **Why `generator_shape` must return a `MeadowsShape` (subclass):** every system types the shape that way
  (`WorldService.generator_shape()`, `AnimalDirector.shape`, `TraderRules.place_in`, `WaveRules.place_in`,
  `TheaterDirector.setup`, `SecretRules`, `HubRules.circle_for_world`). Override `height_at`, `is_river`,
  `tree_at`, `spawn_column`, `column_block`, `bedrock_top` as needed; `MeadowsShape.SEA_LEVEL` is still
  read as a constant by spawns and placement (keep dry land above 25 near the spawn). Anything else
  (`RefCounted` without `extends MeadowsShape`) falls back to Green Meadows' ground.
- **The generator** runs on Voxel Tools' threads like `MeadowsGenerator`; a LAN guest builds its own from
  the same seed and universe (`EditedGenerator` wraps it).
- **What reads what:** `WorldService.setup(dir, seed, is_client, universe)` → shape and generator;
  `sandbox._apply_universe_look()` → `SkyCycle.palette` (the day's sky colours, the night stays) and
  `Music.use_tracks(music)`; `ShopRules.catalog/price(…, universe)` → `trader_stock` at the end of the
  BLOCKS section. **Not wired here** (the universe tasks own them): `monster_kinds` (MonsterDirector's
  night mix) and `boss_kind` (BossDirector starts the Stone Golem; read `UniverseRegistry.boss_kind(Game.universe)`).
- **The boss of a later universe:** unlock with `Session.boss_unlock(UniverseRules.next_universe(Game.universe))`
  and open the portal through `BossDirector`'s portal (`_open_portal` / `restore`, which now carries
  `target`), or spawn a `DesertPortal` with `{"id", "pos", "yaw", "target": u + 1}` and connect its
  `entered(target)` to `sandbox.universe_hub.portal_entered`.
- **Developer run of another universe:** `-- --survivor --new-world --universe=2` (and `--auto-host
  --survivor --universe=2`), `scenes/main.gd`. `Game.universe` is the universe of the world being played.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Ladder rules (pure) | `core/rules/universe_rules.gd` (`UniverseRules`) | `valid`, `scale` 2^(u−1) (capped at u 20), `gold`/`monster_hp`/`monster_hit`/`price`, `slot` (`survivor_1` for u 1, `survivor_u<u>` after), `next_universe`, `unlocked_after_boss`, `portal_target`, `portal_words`, `hub_entries`, `shows_hub`, `wants_hub`, `travel_refusal`/`travel_message`, `sky_color`, `arrival_meta`, `carry` |
| Slots | `core/rules/mode_rules.gd` | `ModeRules.slot(mode, universe = 1)`; Sandbox is always `sandbox_1` |
| Registry | `world/universes/universe_registry.gd` (`UniverseRegistry`) | The ladder (meadows, desert, frost, candy) with names and card colours; descriptors from files; `available`, `exists`, `display_name`, `monster_kinds`, `boss_kind`, `music`, `sky`, `trader_stock`, `shape_for`, `generator_for`, `hub_entries`, `card_colors`; `use`/`reset` for tests |
| Green Meadows | `world/universes/meadows.gd` | Universe 1's descriptor (today's world) |
| Game | `autoloads/game.gd` | `Game.universe`, `start_world(mode, new, difficulty, universe = 1)`, `slot()` with the universe |
| World | `world/world_service.gd` | `setup(…, world_universe = 1)`: the descriptor's shape and generator; `world.universe` |
| Save | `world/world_meta.gd` (section at the end) | `universe` (broken → 1) and `portals` (PortalLinks) |
| LAN | `autoloads/session.gd` (one line in `_rpc_hello`, section at the end) | The host sends its universe just before `world_info` (`_rpc_m3_universe`); the guest's world, sky, music and scaling follow |
| Sky, music | `world/sky_cycle.gd`, `autoloads/music.gd` (sections at the end) | `SkyCycle.palette` tints the day toward the universe's colours; `Music.use_tracks(dict)` swaps loops (`play_menu` puts Meadows' back) |
| Scaling | `world/wave_director.gd`, `world/boss_director.gd`, `ui/hud/totem_panel.gd`, `core/economy/shop_rules.gd`, `ui/hud/shop_panel.gd`, `core/economy/fly_cost.gd`, `entities/player/player.gd`, `world/secret_director.gd`, `core/rules/monster_rules.gd`, `autoloads/session.gd` | Wave gold, the boss's 300 gold, Tilly's buy and sell prices (and her local stock), the fly charge and its message, treasure loot, all × 2^(u−1); monsters already scaled (`MonsterRules.universe_scale` now calls `UniverseRules.scale`); the sandbox sets `MonsterDirector.universe`; the boss of universe u unlocks u + 1 |
| Menu hub | `ui/menus/menu.gd` (section at the end + the Survivor flow), `ui/universe/universe_card.gd` (`UniverseCard`) | SURVIVOR lists every unlocked universe as a big picture card (sky, sun, ground drawn in code; "GO!", "You are here", "Coming soon!") once a second one is unlocked; a card opens that universe's CONTINUE / NEW WORLD (difficulty for a new one); BACK returns to the hub |
| Stone circle | `core/rules/hub_rules.gd` (`HubRules`), `entities/portal/hub_circle.gd` (`HubCircle`), `world/universes/universe_hub.gd` (`UniverseHub`), `ui/universe/hub_panel.gd` (`HubPanel`) | 8 standing stones round a swirling floor, 4–11 blocks from every Survivor world's spawn on dry, nearly level ground, clear of Tilly and the Totem, from the seed (every game of a LAN world agrees); walking in opens the hub panel, walking away closes it |
| Travel | `scenes/sandbox.gd` (section at the end: `travel_to`, `_travel`) | Solo only: saves the world, moves the child's bag and hotbar into the destination world (made the first time with this world's difficulty), arrives by its spawn, whoosh |
| The Golem's portal | `entities/portal/desert_portal.gd` (section), `world/boss_director.gd` | `target` (the next universe); words from `UniverseRules.portal_words`; walking into its doorway in Survivor emits `entered` → `BossDirector.portal_entered` → the hub travels; a window to anything but the desert is the swirl |
| Swirl | `shaders/portal_swirl.gdshader`, `entities/portal/portal_swirl.gd` (`PortalSwirl`) | One unshaded procedural shader, one shared material and one unit quad for every portal doorway, the circle's floor and later universe windows; prewarmed at spawn |
| Portal blocks | `data/blocks/block_ids.gd` (`PORTAL_FRAME` 130, `PORTAL_CORE` 135, `COUNT` 136), `data/blocks/portal_page.gd` (`PortalPage`), `data/blocks/pages/portals*.png`, `world/block_library.gd` (one line), `tools/make_portal_page.gd` + `.py` | Page 5 in both styles (frame: violet stone with a cyan rune; core: a glowing swirl gem), registered before every library is built, in the palette, sold by Tilly (frames 4 for 5 gold, a core 30) |
| Portal rules (pure) | `core/rules/portal_rules.gd` (`PortalRules`), `core/rules/portal_links.gd` (`PortalLinks`) | A portal = an upright ring of frames round a 1–3 × 2–3 doorway (corners optional), one core in its bottom row; `find`, `frame_ok`, `in_opening`, `exit_spot` (in front, room for a body, ground preferred, never a wall), `exit_yaw`; links in placing order, `works`, `active`, save/load (broken entries dropped, waiting cores pair up again), at most 32 cores per world |
| Portal director | `world/portal_director.gd` (`PortalDirector`, node `PortalFrames` on every peer), `scenes/sandbox.gd` (section) | Host: follows `block_changed`, rechecks dirty frames once a tick, looks where every player stands 10 times a second, sends them through (their own game moves them: `spawn_at`), says why not; every peer: swirls from the host's list; saved in `WorldMeta.portals` |
| Sounds | `tools/make_portal_sfx.py` → `assets/audio/sfx/portal_whoosh.wav`, `Audio` key `&"portal_whoosh"` | Original procedural whoosh with a gliding shimmer, credited |
| Smoke run | `tools/universe_smoke.gd` (+ `_steps`) | Headless on real terrain (below) |

## Skills and patterns (godot-prompter)

- **resource-pattern:** descriptors are **plain scripts found by path** (`world/universes/<name>.gd`,
  `extends RefCounted`), read by duck typing with defaults. Rejected: a `Resource` subclass with `.tres`
  files (a shared `class_name` base would have to exist in both parallel branches before either merges,
  and a `.tres` can't carry the shape and generator factories anyway) and an autoload registry (global
  state for what is a static list).
- **save-load:** per-universe **slots** (`survivor_u<u>`) with the M2 slot kept for universe 1 (no
  migration); the bag moves by writing the destination's `world.json` **first**, then the source's
  (a crash in between can copy a bag, never lose it). Rejected: one save holding every universe (M2 saves
  would need a migration and one broken file would lose them all).
- **godot-ui:** the hub is **Control + containers + UiKit's theme** (like the Totem panel), picture cards
  as `Button`s with a custom-drawn child (`_draw`), no image files; the panel sits between the HUD and the
  pause menu and blocks the look area. Rejected: a `TabContainer` or `ItemList` (small text, not a
  child's big picture buttons).
- **shader-basics:** **one spatial shader, unshaded, procedural, animated by TIME**, one shared
  `ShaderMaterial` on a shared unit `QuadMesh` scaled per doorway, prewarmed at spawn. Rejected: a stencil
  "real view" portal (Godot 4.5+ stencil, a second camera: far too costly on a phone) and a
  `StandardMaterial3D` with a scrolling texture (a per-frame CPU write and a texture asset).
- **multiplayer-basics:** **host-authoritative detection**: the host looks at its own copy of every
  player's position at 10 Hz and decides; the player's own game moves itself (`authority` RPC
  `_rpc_arrive`, like the knock-out respawn); reliable `call_local` RPCs for the whoosh and the list of
  swirling doorways (sent to a joining guest on `client_ready`). Rejected: a client "I walked in" request
  (`any_peer`, needs the same checks plus spam limits) and a `MultiplayerSpawner` per swirl (they are
  pure looks derived from a small list).

## Tests (RED → GREEN)

Suite: **2402 → 2450** (ladder) **→ 2477** (hub) **→ 2515** (portal blocks; M2's one "risky" test,
`test_an_unowned_id_is_not_placeable`, now has gaps to check) **→ 2516** (the new world's kit),
`tests/run_tests.sh` exit 0 before each commit (run on a snapshot of the staged index, DEVELOPMENT.md §8).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_universe_rules.gd` | 16 | `Too many arguments for "slot()"`, `UniverseRules` not declared |
| `tests/unit/test_universe_registry.gd` | 11 | written with the registry, not run first; checked by mutation (a missing file counted as existing: 4 fail) |
| `tests/integration/test_universe_world.gd` | 9 | `Too many arguments for "setup()"` (no universe), then `Game.universe`, `SkyCycle.palette`, `Music.use_tracks`, `_rpc_m3_universe`, `WorldMeta.universe` missing |
| `tests/unit/test_shop_universe.gd` | 5 | `Too many arguments for "price()"`; one test first "did not assert" (no local item Tilly also buys) and was fixed to check a sold local item |
| `tests/integration/test_universe_scaling.gd` | 7 | `can_take_off` / `refused_message` missing; then 4 behaviour failures: wave gold 20 not 40, boss 300 not 600 and universe 2 not 3, Tilly 5 not 10 and 45 not 60, flying 9 not 8 |
| `tests/unit/test_universe_travel.gd` | 7 | `arrival_meta()` / `carry()` not found; later `Too many arguments for "arrival_meta()"` (the new world's kit) |
| `tests/unit/test_hub_rules.gd` | 6 | `HubRules` not declared; then seed 1's real world got a circle on the beach (25): the rings now go out to 11 and allow a block of slope under the stones |
| `tests/integration/test_universe_menu.gd` | 4 | written with the menu code; M2's `test_main_menu_modes.gd` still passes (one universe: no hub) |
| `tests/integration/test_universe_hub.gd` | 11 | `UniverseHub`, `PortalSwirl`, `DesertPortal.entered` / `target`, `BossDirector.portal_entered` missing; mutation-checked (below) |
| `tests/unit/test_portal_rules.gd` | 18 | written before `PortalRules`/`PortalLinks`; mutation-checked (below) |
| `tests/unit/test_portal_blocks.gd` | 7 | written with the ids; includes **no block takes an item's id** |
| `tests/integration/test_portal_frames.gd` | 12 | `PortalDirector` not declared; mutation-checked (below) |
| Changed | `test_block_ids.gd` (33 placeable; COUNT ≥ 38), `test_boss_director.gd` (pins the desert as missing: M2's portal words) | |

**Mutation checks** (each broken rule made the tests fail, then was put back): the hub never closing when
the child walks away; a portal leading somewhere while its universe is coming soon; a missing descriptor
file counted as existing; no cooldown after a trip (a guest's late position sent them back); no re-arm
while standing in a doorway; the exit ignoring walls; a blocked doorway counted as a portal; travelling
without checking the partner's frame; a waiting core never cleared (pairs overwritten). One mutation
survived at first (removing "the arrival counts as standing in the other doorway"): that line was
redundant with the cooldown and the exit lying outside the doorway, so it was removed and a test for late
positions added instead.

## Headless smoke run

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/universe_smoke.gd`

27 checks, all `ok` (`UNIVERSE_SMOKE result fails=0`, 2026-09-24, load ~15): a new Survivor world of universe 1
plays in `survivor_1`, has its circle 7.1 blocks from the spawn; walking in opens the hub (one card and
"Beat the boss to open a new universe!"), walking away closes it; with universe 2 unlocked (a stand-in:
`tests/fakes/fake_universe.gd`, flat stone at y 40) GO! travels to `survivor_u2` with its own ground,
carrying a cosmic sword and 40 planks (plus a new world's kit), nothing left behind; its circle says "You are here" and takes the
child back with the sword; the Golem's portal (restored as after a win) says "Walk in: Test Land!" and
walking in travels to universe 2; there two frames built with `set_block` link and swirl, walking into
one comes out 1.0 block from the other doorway, not in a wall, and the link is saved. (First runs quit
with "2 resources still in use": the stand-in's music loop still playing at quit; the run now stops the
music and quits a moment later.)

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Portal block ids are 130 (frame) and 135 (core), not 128–131.** Item ids share the same int space
   (hotbars, bags, `Session` edits) and 128, 129 and 131 are the Crystal Bow, Cosmic Bow and Stone
   Pickaxe: a portal frame at 128 would be broken into a Crystal Bow (400 gold, minted). 130 and 135 are
   the only ids of page 5 no item uses. **Lead: the M3 allocations collide the same way for candy 100–111
   (the wand, stamps, sword, bow), smart blocks 112–127 and building tools 136–143** (tiers, shields):
   those tasks need other ranges (or items moved above 1000 with a save migration) before they add blocks;
   `test_no_block_takes_an_item_id` (`test_portal_blocks.gd`) fails the moment a block takes an item id.
   *Cost if wrong:* if items move, two constants change (no saves hold portals yet).
2. **`BlockIds.COUNT` is 136** (the library needs a model per id up to the last block); gaps stay empty
   models and are refused by the host (`is_valid` needs a name). `/give` now lists blocks by `is_valid`
   and items by `is_item`, so paged block ids and item ids don't list twice. *Cost:* merges with the
   desert/other pages take the highest COUNT.
3. **A portal = an upright ring of frames round a 1–3 wide, 2–3 tall doorway, corners optional, one core
   in the bottom row** (the Minecraft-like shape children know, but forgiving). Cores link in pairs in the
   order they were placed; a broken core's partner waits for the next. *Cost:* children who want to choose
   pairs (colours, names) need a pairing tool later.
4. **The swirl shows only on working pairs** (both frames whole), so a child sees at once which portal is
   ready. Walking into a lone or broken one says why ("Build a second portal to link with this one!",
   "The other portal's frame is broken!", "The other portal is blocked!"), once per walk-in.
5. **The exit is the cell in front of the other doorway's middle**, on the side with room for a body and
   ground under it, else the side with room; walled in on both sides refuses. The traveller faces away
   from the doorway; 1 s cooldown per player. *Cost:* a child who builds a portal against a cliff comes
   out on the other side of it.
6. **A far end that isn't loaded is trusted as saved** (frames can only change where blocks are loaded,
   and the host sees every change); a loaded far end is checked again before each trip. *Cost:* none known.
7. **Portals never carry animals, monsters, buddies or items**; bot friends follow as after any long jump.
8. **Travel between universes is solo only** ("Travel works when you play alone."): a LAN/online host
   with guests, or a guest, can't travel (taking friends along means moving a whole match: M4 follow-up).
   A LAN host nobody joined can. *Cost:* friends play one universe per session.
9. **The bag comes along through a portal or the stone circle** (everything counted, and the hotbar), so
   "tools keep their tiers": a cosmic sword stays a cosmic sword. It is added to what waits in the
   destination world; what doesn't fit (999 each) stays behind — nothing copied, nothing lost. From the
   **main menu** nothing moves: each world keeps the bag last left in it. *Cost:* a child who goes back to
   universe 1 from the menu finds their tools in universe 2 (they are there, not lost).
10. **The destination world is made on the first trip with the difficulty of the world travelled from**
    and M2's starter kit (§12.1: every new Survivor world has it) on top of the carried bag; from the menu
    a new universe world asks COZY / NORMAL / BRAVE as in M2. Arrivals are by the new world's spawn (and
    its circle), never where the child last stood there. *Cost:* a second wooden sword and pickaxe in the
    bag of a child who already had them.
11. **The SURVIVOR menu shows the hub only once a second universe is unlocked** (M2 behaviour and tests
    otherwise); a universe unlocked but not built yet (desert before its merge) shows "Coming soon!".
12. **The stone circle stands in every Survivor world, universe 1 too** (with one universe it tells how
    to open the next); it is not blocks (no world change, no save), placed from the seed 4–11 blocks from
    the spawn. Walking in opens the panel; it opens again only after walking 3.2 blocks away.
13. **Scaling covers:** monster health, hits and coins (already there), wave gold, the boss's 300 gold,
    treasure loot, Tilly's buy and sell prices (so buying never costs less than selling pays), the fly
    charge. **Not done: the "+" levels of tier items in later universes** (spec §14.1 "tier shop items gain
    '+' levels there"): tools keep their tiers and damage. *Cost:* universes 3–4 (monsters × 4 and × 8)
    are hard with universe-1 tools; a `+` level (damage × 2^(u−1) for tools bought there) is a later task.
14. **The Golem's portal in a later universe leads to u + 1**; its window is the desert view for target 2
    and the swirl otherwise. In Sandbox it stays a peek ("… waits in Survivor!").
15. **Local trader stock prices are per one item** and sit at the end of the BLOCKS section.
16. **The circle and the hub panel are per device** (every game builds the circle from the seed; nothing
    about it is sent).

## What to check on the emulator (the lead)

1. **M2 saves:** an existing Survivor world (universe 1) continues from SURVIVOR exactly as before
   (slot `survivor_1`), Sandbox too.
2. **Stone circle:** in a Survivor world, eight grey stones with blue runes round a swirling purple floor,
   a few steps from the spawn (both styles, day and night); walk in → "Where to?" with Green Meadows
   "You are here" and "Beat the boss to open a new universe!"; walk out → it closes.
3. **Hub:** set `universe_unlocked` to 2 in `profile.json` → SURVIVOR shows two picture cards; before the
   desert's merge the second says "Coming soon!"; after it, GO! (circle) or the card (menu) opens the
   desert world, the bag comes along, the music and sky are the desert's.
4. **The Golem's portal** after a win: "Walk in: Sandstorm Desert!" (after the desert's merge) and walking
   through travels; before it, M2's words.
5. **Portal blocks:** Sandbox palette has Portal Frame and Portal Core (their page-5 icons); build two
   doorway frames with a core in the bottom row → both swirl; walk in → out by the other one with a whoosh
   and sparkles; break a frame block → the swirl stops on both, walking in says the other is broken;
   Survivor: Tilly sells frames (4 for 5) and cores (30).
6. **First-contact frames:** no spike when the first portal swirls or the circle appears (the swirl is
   prewarmed at spawn).
7. **LAN:** a guest sees the swirls and goes through portals (the host decides); the guest's hub says
   "Travel works when you play alone."
8. **Performance:** a circle is 2 draw calls (one MultiMesh of stones, the floor), a working doorway 1; check
   the autopilot near the spawn in both styles.

## Merge notes (what will conflict)

- `data/blocks/block_ids.gd`: `COUNT` (take the highest), the M3 Task 5 constants, `PLACEABLE`, `_NAMES`.
- `world/block_library.gd`: one line in `build()` (`PortalPage.register()`); other pages add theirs.
- `autoloads/session.gd`: one line in `_rpc_hello`, the section at the end. `scenes/sandbox.gd`: lines in
  `_ready`, `_start_host_or_solo` (universe), `_on_world_info`, `_add_sky`, `_setup_local_player`,
  `_start_monsters`, `save_world`, the section at the end. `world/world_meta.gd`: two lines + section.
- `scenes/main.gd` (`--universe=`): the desert agent may add the same arg; keep one.
- `core/economy/shop_rules.gd` (universe parameters, portal prices), `ui/hud/shop_panel.gd`,
  `world/boss_director.gd` (`portal_entered`, `target`, scaled pay, next universe),
  `entities/portal/desert_portal.gd`, `world/secret_director.gd` (4 × `Game.universe`),
  `core/economy/fly_cost.gd`, `entities/player/player.gd` (the fly refusal line), `ui/menus/menu.gd`.
- `tests/unit/test_block_ids.gd`: the placeable count (33 here, + the other pages' blocks).
- Not touched (the lead updates them at merge): the spec, the plan's Task 5 line, the M3 dev log.

## Lead's merge note (18:20)
The portal blocks moved to **208 (frame) and 209 (core)** on page 10 at the merge: blocks and items share
one id space, and the lead re-allocated every new block page to 176–255 (M3 dev log 18:20, ruling 7).
`PortalPage.PAGE` is 10; the atlas tiles are page-local and did not change.
