# M2 Task 7: Tilly the trader, the economy, the gold counter, flying costs

Spec §12.7 (and §12.1, §12.11), plan Task 7. Built in an isolated worktree cut from
`m2-survive-the-night` at `2430164` (Task 1 foundation). No editor, no emulator.
The lead added four child-psychology notes during the task (2026-09-24, from `docs/design/`): short
gold numbers everywhere, a have/need bar under prices the player can't afford yet, icon-first buttons
with a small word under each, and a one-time hint arrow over Tilly's stall. All four are built and
recorded as rulings 13–16 below.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Price table and trades | `core/economy/shop_rules.gd` (`ShopRules`) | §12.7 prices, Buy sections, Sell list, `buy` / `sell` against a `Wallet` + `Inventory` (all or nothing), refusal keys and friendly messages, `done_message` |
| Fly cost | `core/economy/fly_cost.gd` (`FlyCost`) | 10 gold a minute: 1 gold per 6 s of flight, the first 6 s paid at take-off, landing never restarts the clock; `can_take_off` |
| Stall placement and reach | `core/economy/trader_rules.gd` (`TraderRules`) | Level, dry spot 12 blocks from the world spawn, deterministic from the seed and the generator's shape; `place_in(meta, mode, …)` (Survivor only, placed once), `spawn_data`, reach and tap ray |
| Short numbers | `core/economy/gold_format.gd` (`GoldFormat`) | "1.2K", "3.4M", never rounded up; "+12" / "-1"; "340 / 1.2K" |
| Tilly | `entities/npcs/trader.gd` (`Trader`) | A blocky shopkeeper (purple dress, apron, straw hat) behind the counter of a stall with a red and white awning and a gold-coin sign; three shared meshes with `WeaponModels.material()`, one static body on the world layer; turns to and waves at players within 8 blocks; hops on a trade; the hint arrow + "SHOP" label; `Trader.find` for taps |
| Host checks | `autoloads/session.gd`, section "M2 Task 7" | `request_shop`, `request_trade(buying, id, count)`, `host_trade`, signals `trade_done`, `trade_inventory_received`; `fly_tick` charges Survivor flyers, `_send_fly_land` |
| Player | `entities/player/player.gd` (one line in `set_physics_mode`, one in `_move_normal`, section at the end) | FLY refused without gold (Sandbox free); `land_gently()` + soft fall at most 4 m/s |
| Tap | `entities/player/block_interactor.gd` (one line in `place_at_screen`, section at the end) | A tap on Tilly within reach (not through blocks) emits `trader_tapped`, whatever is in the hand |
| Gold counter | `ui/hud/gold_counter.gd`, `ui/hud/coin_icon.gd` | Coin + short number, ∞ in Sandbox; on `Session.gold_changed` a bounce and a floating "+12" / "-1" |
| Shop panel | `ui/hud/shop_panel.gd`, `ui/hud/shop_card.gd` | Centred overlay: BUY / SELL tabs, TOOLS / POTIONS / HOME / BLOCKS sections, picture cards (icon, coin + short price, "×4" or "×7" badge, have/need bar, green check on owned tools), footer with the selected thing and one big action button, the host's answer line, the player's gold, X; closes on a tap outside, Back / Esc, or walking away |
| HUD | `ui/hud/hud.gd` (one line in `_ready`, one in `setup`, section at the end) | `gold_counter` top-right under the username (x 930–1150, y 62–110 on 1280 × 720, left of the WALK/SIZE column); `shop` under the palette overlay; `open_shop(trader)` |
| World | `scenes/sandbox.gd` (one line each in `_ready`, `_start_host_or_solo`, `_setup_local_player`, the Back handler; section at the end) | `TraderSpawner` on every peer; host places / restores Tilly; the first shop visit hides the hint and sets `meta.trader_visited` |
| Save | `world/world_meta.gd` | `trader_pos`, `trader_yaw`, `trader_visited` (JSON `"trader": {pos, yaw, visited}`), validated |

No new assets: the coin, the potion bottles, Tilly and the stall are drawn in code (nothing to credit).

## Tests (RED → GREEN)

All RED first for the right reason (missing class, method or signal), except `test_trader.gd`, whose
implementation I wrote before running it; I then mutation-checked it (removing the `traders` group and
the mesh cache made 3 of its 6 tests fail) and restored the file.

| File | Tests | Covers |
|---|---|---|
| `tests/unit/test_shop_rules.gd` | 19 | Every §12.7 price; spear/mace by name once Task 6 merges; no id buys cheaper than it sells; catalog only lists ownable things; buy/sell: not enough gold, full stack, tool already owned, not for sale, not sellable, negative counts; messages |
| `tests/unit/test_fly_cost.gd` | 6 | 10 gold/min, take-off charge, short hops don't fly free, can't pay → land, Sandbox free, bad time steps |
| `tests/unit/test_trader_rules.gd` | 12 | Survivor only, 12 blocks from spawn facing it, deterministic, level 3 × 3, dry, clear of trees, fallback, real seeds (1, 42, 777, 20260924) level and dry, placed once and kept, spawn data hint, reach, tap ray |
| `tests/unit/test_gold_format.gd` | 5 | Short numbers, never rounded up, signed changes, have/need |
| `tests/unit/test_world_meta_trader.gd` | 4 | Round trip, none saved without a trader, broken entries |
| `tests/integration/test_trader_session.gd` | 13 | Host: buy, sell, too far, no Tilly, not enough gold, selling what you don't have, Sandbox, shop inventory, a guest without a body; fly charged every 6 s, lands gently when broke, FLY refused without gold, Sandbox flies free |
| `tests/integration/test_trader.gd` | 6 | Placement, shared meshes / one material, static body on the world layer, stall size, hint arrow, `Trader.find` (reach, direction, walls) |
| `tests/integration/test_trader_tap.gd` | 3 | A tap on Tilly emits `trader_tapped` (also with a sword); not from far away |
| `tests/integration/test_gold_counter.gd` | 4 | ∞ in Sandbox (and the font has the glyph), follows `gold_changed` with "+12" / "-1" and short numbers, bounce settles, HUD spot clear of the buttons |
| `tests/integration/test_shop_panel.gd` | 13 | Opens on BUY / TOOLS with the gold, centred and on screen, short prices with badges, have/need bar updates with the gold, buying and selling through the host, owned tool marked and refused, BUY waits for gold, icon-first buttons, every card has a picture, closing, the HUD opens it on a tap (palette closed, look-area blocker), walking away closes it |

Full suite: see the final commit message (count at the time of the last run).

Headless developer runs (private `XDG_DATA_HOME` with a copy of `profile.json`):
- `-- --survivor --new-world`: `TRADER at (28.5, 34.0, 2.5)`, spawned in 0.9 s, no errors; `world.json` holds
  `"trader": {"pos": [28.5, 34.0, 2.5], "visited": false, "yaw": 1.4056}`.
- `-- --survivor` again: the same spot (restored from the save).
- LAN, `--survivor --auto-host --lan-test` + `--auto-join=127.0.0.1 --lan-test`: the guest receives
  Tilly at the same spot through the `TraderSpawner`; both logs clean.
- Careful: parallel agents run their own LAN tests on the default port 24565 at the same time (Task 2's
  `--ko` run started right after mine). Two hosts on one port collide; pick a moment when none runs.

Desktop render check (a windowed `godot --disable-vsync --script` driver that builds the stall, the
counter and the panel and saves screenshots; not committed, desktop Forward+ look, not the emulator's):
the stall, Tilly's face and hat, the awning and the coin sign read well from 7 blocks; the panel's
cards, bars ("3 / 20" on every card above 3 gold), the grey BUY and "You need more gold!" are clear.
Two fixes came out of it: the spinning arrow's flat head looked like a sliver edge-on (now two crossed
heads), and the panel was 4 % see-through, so the stall and the SHOP label showed behind the cards (now
opaque). Door, spike trap, barrel, closet and bush cards still show Task 1's placeholder tiles until
Tasks 5 and 8 draw them.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Hammer and boomerang cost 30 (like a stone tool); practice dummy and bullseye 5.** They have no
   tiers but are better than a wooden tool. *Cost:* one table line each.
2. **The wand and stamps are not sold.** Stamps would place dozens of blocks for free in a world where
   blocks are counted; the wand is Sandbox magic in M2. *Cost:* Survivor players can't bring buddies to
   life until a later ruling adds them.
3. **"Building blocks" = every placeable block except ores, water and the bed** (grass, dirt, stone,
   sand, wood, planks, leaves, glass, brick, light, the five toy colours, deep stone), 4 for 1 gold. Ores
   are never bought (buying diamonds at 4 for 1 and selling at 20 would mint gold; a test guards that
   nothing buys cheaper than it sells). Water flows, so it is not sold. *Cost:* a line in the table.
4. **One of each tool or shield.** The shop refuses a second ("You already have one!") so a child can't
   waste 1200 gold on a duplicate. Potions and blocks stack. *Cost:* a player who wants a spare can't.
5. **All or nothing.** A purchase that would not fit under the 999 cap is refused whole; selling
   takes exactly what was asked.
6. **Task 6 merge.** The shop lists only what `Inventory` can hold, so tier and potion items appear the
   moment Task 6 adds them to `ItemIds.ALL`. The spear and mace lines are looked up by name
   (`ItemIds` constant map), so they are priced as soon as their constants exist, with no code change and
   no parse error before. Icons: `BlockIcons.icon(id)` first; else a potion bottle drawn here, or the
   line's wood-tier icon tinted by tier. *Cost:* if Task 6 uses a different icon API, cards show the
   tinted fallback until one line in `ShopCard.icon_for` points at it.
7. **Reach:** a tap opens the shop within 6 blocks (eye to Tilly's chest, not through blocks); the host
   accepts trades within 8 (lag); the panel closes itself beyond 8. *Cost:* numbers to tune.
8. **Flying:** take-off pays the first 6 s (1 gold) at once and landing never restarts the clock, so
   hops don't fly free. FLY is refused on the player's own game with less than 1 gold (message); the host
   lands a broke flyer (resent at most every 2 s to a guest whose mode has not synced yet). The soft fall
   caps the fall at 4 m/s until ground or water. *Cost:* a modified LAN client could ignore the landing
   (LAN trust until M4, like gold).
9. **The stall is a node, not voxel blocks** (merged meshes + one static body on the world layer):
   it can't be mined, broken or stamped over by accident. Blocks can still be placed inside it (placement
   only protects player bodies), and digging under it leaves it floating. *Cost:* odd sights if a child
   digs under it; M3 could protect the cells.
10. **Where:** a 3 × 3 level patch of dry land (not beach, river, sea or a cave mouth) with no tree trunk
    within 3 columns, on the 12-block ring first (48 angles from a seed-derived start), then rings 11,
    13, 10, 14, 9, 15, 8, 16; with none, the first 12-ring spot anyway. The counter faces the spawn.
11. **Old Survivor worlds** (made before this task) get Tilly on their next load, placed and saved the
    same way.
12. **Two taps to buy** (tap a card, then BUY) so nothing expensive is bought by accident; the answer
    shows inside the panel (a toast would be hidden behind it), with a ding or a thud (Task 11 may give
    coins their own sound).
13. **Short gold numbers everywhere** (lead's note): counter, prices, bars, popups; rounded down, never
    up (1199 shows 1.1K, not 1.2K, so a 1.2K sword never looks affordable).
14. **Have/need bar** (lead's note) under every Buy price the player can't afford yet: a gold bar filling
    towards the price and "340 / 1.2K". Not on owned tools or in the Sell tab.
15. **Icon-first buttons with a small word under** (lead's note): BUY (coin), SELL (diamond), TOOLS
    (sword), POTIONS (bottle), HOME (bed), BLOCKS (planks), and the BUY / SELL 1 / SELL ALL actions
    (coin). The close button is a plain red X.
16. **The hint arrow** (lead's note): a bobbing, spinning gold arrow and a "SHOP" label (drawn over hills)
    above the stall in a new Survivor world, until the player first opens the shop; saved per world
    (`WorldMeta.trader_visited`, the host's player). A LAN guest sees it until their own first visit in
    the session. *Cost:* a guest who already knows Tilly sees it again next session.
17. **The "+12" floats down** from the counter (up would cover the username).
18. **Trades are refused in Sandbox** even if a trader existed ("Tilly trades in Survivor worlds."):
    Sandbox gold is ∞ and nothing is counted.

## What to check on the emulator (lead)

1. New Survivor world: the gold arrow and "SHOP" over the stall are visible from the spawn; walk to
   Tilly: she turns and waves. Stall looks right in BLOCKY and REALISTIC.
2. Tap her (with the sword selected too): the shop opens centred; the arrow is gone (also after a
   restart). Tabs, sections, cards and the footer are readable on 2400 × 1080; the grid scrolls in TOOLS
   once Task 6's tiers are listed.
3. Buy a lantern (25 → 20 gold): the counter bounces with "-5", Tilly hops, "You got a Lantern!".
   With 3 gold, the bed card shows the bar "3 / 20" and BUY is grey.
4. Sell ores after Task 3 merges (they come from mining): "+40".
5. FLY with gold: "-1" on take-off and every 6 s. At 0 gold: gentle landing and the message; FLY
   refused with the message. Sandbox: ∞, flying free, no Tilly.
6. Walk away with the shop open: it closes. Android Back closes it.
7. Frame time near the stall: 3 extra draw calls, one static body.

## Merge notes

Shared files touched only with one-line hooks plus a section at the end: `autoloads/session.gd`,
`entities/player/player.gd`, `entities/player/block_interactor.gd`, `ui/hud/hud.gd`,
`scenes/sandbox.gd`, `world/world_meta.gd`. The tap check in `place_at_screen` must stay first (before
weapons). Task 6: after the merge, run `test_shop_rules` (spear/mace pricing test switches from "not
merged" to real checks) and `test_shop_panel::test_every_card_has_a_picture`.
