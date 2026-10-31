# Owner feedback #37: the shop and trading (notes)

Owner, 2026-09-24: "we should have a shop in the game, where you can trade". Tilly's shop (M2 Task 7) is the game's shop
and the owner found it (20:19); the brief (`docs/superpowers/briefs/prompt-own37.md`) asks for the follow-ups: find
Tilly from MORE, Tilly in more places with a market day, and trading between players (LAN and online). Spec **§14.23**
(new; §14.19 went to #41 and §14.20 to M3 Task 21a at the merges), M3 plan **Task 28** (Task 27 went to #36). Built by a background agent in its own worktree after
`git merge lead-merge` (`f40eb97`: #39, #45b), merged again mid-task (`a46b97f`: #41 more animals, Nell the Dragon
Realm's helper, fixes), without the editor or the emulator. No block or item ids, no always-visible HUD button.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Trading rules | `core/trade/trade_rules.gd` (`TradeRules`) | what may be traded (the bag's things but universe crystals and the Gold Farm), an offer (≤ 8 kinds, gold ≤ 500 × 2^(u−1)) cleaned from anything a game sends, held to what its owner still has (`covered`), the all-or-nothing `swap_check` (each still owns their offer, each bag and purse has room) and `move_items` (every give taken before anything is added), the under-13 friends rule, the chat line, kind words |
| The host's table | `core/trade/trade_table.gd` (`TradeTable`) | asks (one out and one waiting per child, asking again waits 3 s, no expiry) and open trades (one per child); every change of an offer makes both not ready; a child who leaves takes their ask and trade along; each side's view (`state_for`) |
| Market day | `core/economy/market_rules.gd` (`MarketRules`) | a day begins at sunrise (`sunrises`), market day every 7th day from day 2, open sunrise to sunset; Nico's fixed stock (13 village blocks of page 13, which no shop sells and nobody buys back) at fixed prices × 2^(u−1); `buy`; the cart's spot beside Tilly's stall (level, dry, no trunk, 4 blocks clear of the Totem, the hub circle, the Theater and the helper); the saved count |
| The helpers' stands | `core/economy/stand_rules.gd` (`StandRules`) | a stand in every universe with a helper of its own (Zara, Bram, Mimi, Nell), its universe's `trader_stock` at Tilly's prices, its spot beside the helper on their level |
| Finding Tilly | `core/economy/shop_guide.gd` (`ShopGuide`) | the nearest full shop (Tilly or a villager who trades), the way and the distance, "there" (the tap's reach), the tip once per profile |
| Save | `world/world_meta.gd` (section "Owner #37") | `WorldMeta.market` = `{"day": n}` (old and broken saves: day 1) |
| The host's checks | `autoloads/session.gd` section `# --- Trading` (+ hooks in `_ready`, `survivor_reset`, `_physics_process`, one branch in M2 Task 7's `host_trade`) | `player_trade_ask / answer / unask / offer / ready / cancel / friends` → the host's `host_trade_*` (Survivor, both have a body, not yourself, the age rule), `_pt_swap` (the check, the gold through `gold_spend` / `gold_add` — the online ledger hears it —, then the things), `player_trade_tick` (offers held to the bags every 250 ms), a child leaving or dropping their link stops their trade, one reliable RPC back (`_rpc_pt_to`); Nico's things sold only near a `market_traders` node (`_pt_market_sells` / `_pt_market_buy`) |
| Entities | `entities/npcs/trader_stand.gd` (`TraderStand`), `entities/npcs/market_cart.gd` (`MarketCart`) | `Trader`s: a table with crates and an awning in the universe's colours and its sign (one shared mesh per universe, one small static body); Nico's cart on two wheels with a green and yellow awning and Nico, who waves (three shared meshes); `shop_stock` / `shop_title` / `market` for the shop panel |
| The director | `world/trade_director.gd` (`TradeDirector`, node `Trading` on every game; the sandbox's section "Owner #37" + 5 one-liners) | SHOP in MORE and its card, the guide (the /find arrow; the shop opens on arrival), the tip; the host's day count and cart (RPC on change and to a guest who arrives, the banner); the stand beside the helper (a worker thread finds its spot); the name tag tap; the ask card, the trade window and the notes on Session's signals; this game's friends to the host |
| UI | `ui/trade/` `ShopMenu`, `PlayerCard`, `TradeAskCard` (QuestOverlay pages), `TradeWindow`, `TradeSlot`; `ui/hud/shop_panel.gd` (section "Owner #37": a stall's own things under its own title, Nico's prices); `ui/hud/hud_icons.gd` (picture `shop`) | see below |
| Taps | `entities/player/block_interactor.gd` (section "Owner #37", one line after the quest givers) | `name_tag_tap`: another player's name tag opens their card, whatever is in the hand |
| Tools | `tools/trade_smoke.gd` (+ steps), `tools/lan_test.gd` `--trade` | a real desert world end to end; two LAN instances trading |

### The screens

- **MORE → SHOP** (Survivor): a picture card — Tilly (or the nearest villager who trades, whichever is nearer) with
  the metres and a little dial arrow the way to go, SHOW ME (the HUD's find arrow; the shop opens by itself when the
  child is within the tap's reach) or, close by, OPEN; on market day Nico's row too; then "Trade with a friend": each
  other player in this world with TRADE; CLOSE.
- **The first-time tip:** the first time a child plays a Survivor world after this lands, the picture hint "Tilly's
  shop is near! MORE, then SHOP shows the way." with the coin, and the arrow points at her (it does not open the shop).
- **A player's card:** a tap on another player's name tag (≤ 8 blocks, not through blocks): their name, TRADE, CLOSE.
- **The ask:** "Bob would like to trade." with YES and NO THANKS as equal buttons; a tap outside is NO THANKS; it goes
  away by itself when Bob takes it back or leaves.
- **The trade window** (1180 × 686 in the 1280 × 720 design space, measured): YOU GIVE and BOB GIVES (8 squares each,
  gold, "READY!"), YOUR BAG (tap: ×1 / ×10 / ALL; a crystal never shows), gold chips +1 +10 +100 and 0, READY / NOT READY,
  X; a tap on one of your own squares takes it back; the host's notes on its message line ("Waiting for Bob...",
  "Bob has no room for that many Stone."). Only X (or Android Back) stops it; a stray tap outside does nothing.
- **A stand / Nico's cart:** the shop panel opens on that trader's own things under its title ("Zara's stand",
  "Nico's Market"), no sections; SELL works as at Tilly's.

## Skills and patterns (godot-prompter)

- **multiplayer-basics:** chosen — host-authoritative requests (`any_peer` RPCs checked on the host with the sender
  id), one `authority` RPC back with a kind (`_rpc_pt_to`), sends only to connected peers (tests and solo play send
  nothing), `peer_left` / `peer_away` clean-up. The cart is not a `MultiplayerSpawner` node: its spot is decided by the
  host and one reliable RPC (on change and to an arriving guest) lets every game build its own copy, like the quest
  givers are built from the seed. Rejected: a `MultiplayerSynchronizer` for the trade (a state RPC on each change is
  smaller and ordered with the requests).
- **inventory-system:** kept the game's `Inventory` (id → count, `add` returns what fitted) instead of slot/Resource
  items; offers are `{id: count}` dictionaries; the swap is all or nothing (the skill's "leftover" return is not
  wanted in a trade); the UI never polls — it follows `Session.inventory_changed` and the host's states. Rejected:
  drag-and-drop between grids (a tap is easier for a child and for touch).
- **godot-ui:** containers only, one theme (`UiKit.theme()`), the QuestOverlay base for pages that take touches before
  the HUD, fixed-size windows measured against 720 px (a test), `FOCUS_NONE` touch buttons ≥ 64 px.

## Tests (RED → GREEN)

| File | Tests | RED |
|---|---|---|
| `tests/unit/test_market_rules.gd` | 10 | missing `MarketRules` |
| `tests/unit/test_trade_rules.gd` | 12 | missing `TradeRules` |
| `tests/unit/test_trade_table.gd` | 8 | missing `TradeTable` |
| `tests/unit/test_shop_guide.gd` | 6 | missing `ShopGuide` / `StandRules`; then my own test's "wet" ground was backwards (fixed the test) |
| `tests/unit/test_world_meta_market.gd` | 3 | `WorldMeta.market` missing |
| `tests/integration/test_player_trade_session.gd` | 21 | Session's functions missing; then the guest's chat line went by RPC to a peer the test doesn't have (`_pt_line` now sends only to a game that is there) |
| `tests/integration/test_trade_entities.gd` | 4 | Trader's constants redeclared (parse error); the test's player was hidden until spawned |
| `tests/integration/test_shop_panel_stalls.gd` | 5 | the panel showed Tilly's catalog at a stand; then a typed-array ternary (DEVELOPMENT §8) and `bool(null)` |
| `tests/integration/test_trade_window.gd` | 9 | written after the window: the window measured 704 px and ran 1 px off a 720 px screen (tightened) |
| `tests/integration/test_trade_director.gd` | 17 | written after the director: the banner needs the HUD's secret controls; the test's own name tag was a second one (every other player already wears `NameTag`) |

**Mutation check** (the window, the director and the Session glue were written before some of their tests): five
breaks at once — the shop not opening on arrival, an offer change not un-readying the other side, `move_items` adding
before taking, the swap skipping `swap_check`, a tap outside the ask card not answering — failed exactly the seven
matching tests (`test_arriving_opens_her_shop_and_the_arrow_stops`, both `test_every_change_makes_both_not_ready`,
`test_a_swap_never_copies_anything`, `test_a_full_bag_stops_the_swap_and_says_why`,
`test_a_last_moment_check_makes_copies_impossible`, `test_no_thanks_and_a_tap_outside_both_say_no`); all restored.

**Full suite** (`tests/run_tests.sh`): on the first finished tree (`7605ce0`, base `a46b97f`) 536 scripts, 5185 tests,
5182 passing — the 3 failures were the base's (#41's dragon checks and the keepsakes page at 704 px) and `lead-merge`
fixed them; after merging `lead-merge` with M3 Task 21a (`58ae8f1`): **556 scripts, 5328 tests, 5326 passing, 2 pending,
exit 0**; the final tree (the babble fix, merged with `lead-merge` `a39c2ec`: #36's costumes): **560 scripts, 5367 tests,
5365 passing, 2 pending (the Nakama-server tests), exit 0**.

### The smoke run (the real game, headless)

`XDG_DATA_HOME=<private "smoke" folder with profile.json> godot --headless --path . --script res://tools/trade_smoke.gd`:
a new Survivor world in the Sandstorm Desert, **20 of 20 checks pass**, no script errors: the director and SHOP in
MORE; the first-time tip and its arrow at Tilly; the card's distance ("12 m"); SHOW ME points the find arrow; standing
by her opens "Tilly's Shop" by itself; Zara's stand 2.8 blocks beside her on the ground; a real tap through the
interactor opens "Zara's stand"; buying Sandstone there through the host; a sunrise into day 2 brings Nico's cart
3.6 blocks beside Tilly's stall with the banner; a real tap opens "Nico's Market"; roof tiles for 4 gold (2 × 2^(2−1));
sunset takes the cart; the save keeps `{"day": 2}`. After the last merges it passed again on two more worlds, one of
them (seed 3026685144) with Zara on a mesa's edge: the run now stands the player on the trader's own level
(`_beside`) and `TRADE_SMOKE_SEED=<seed>` replays a world (it prints `TRADE_SMOKE seed …`).

### LAN (two headless instances)

`godot --headless --path . -- --auto-host --survivor --new-world --lan-test --trade` and
`godot --headless --path . -- --auto-join=127.0.0.1 --lan-test --trade` (each with its own `XDG_DATA_HOME`): the host
asks, the guest hears "asked by=1", says YES; both offers travel, the host readies, the guest sees `their_ready=true`
and readies; both log `ended done=true text='Traded!'` and their own chat line ("You traded with Player2: you gave 5
Stone; you got 2 Diamond."); the bags at t 16: host `stone=5 diamond=2`, guest `stone=5 diamond=1` (10 Stone and 3
Diamonds before). Online play uses the same Session code over the relay (not run here: it needs the server and two
accounts; the lead's check below).

### Georgian (M3 Task 21a merged mid-task)

Every line of this work is translated before it is filled in (`Lang.t` in static code, `tr()` in nodes), sentences
are built whole ("%s and %s", no English plural "s"), and 44 Georgian lines are appended to `i18n/ka.po` under their own
heading — **native check needed** like the rest of the file (e.g. "ვაჭრობა" TRADE, "დახლი: %s" a stand, "ნიკოს ბაზარი",
"%s ვაჭრობას გთავაზობს."). "Nico" joins the other names in `i18n/not_words.txt` (a name is the same in every language).
`tools/i18n/words.gd -- --missing`: MISSING 0. The trade's chat line is a game line, built on the host in the host's
language (Task 21a's ruling 9); players' own chat is never translated.

### A fix outside this part

- **`world/babble_voices.gd`** (M3 Task 21a): a speaker freed while its babble line played (Nico's cart leaving at
  sunset right after "Hello! What would you like?") made `_play_due` cast a freed object every frame for the rest of
  the session ("Trying to cast a freed object", found by the smoke run). The line now goes with its speaker (validity
  checked before the cast); `test_babble_voices.gd::test_a_speaker_that_goes_while_it_talks_just_stops` (RED on the
  script error, then GREEN).
- **Seen, not fixed (the lead's):** a LAN guest logs `Invalid access to property or key 'seed' on a base object of type
  'Nil'` in `sandbox.gd` `gh_world_key` from `_gh_setup_local` (M4 ghost races): a guest has no `meta`.

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **Survivor only.** No SHOP entry, no name tag card and no trades in the Sandbox (everything is free there) or the
   Monster Wave arenas (no shop there). *Cost:* Sandbox children can't swap things (they have them all anyway).
2. **"Tilly in more places" = a stand beside each universe's helper**, not the helper keeping a shop: a tap on the
   helper still opens their quest card (the quest code is untouched), a tap on the stand opens the universe's own
   things. Tilly's stall already stands in every Survivor universe and #45b's villagers trade in the wild meadows'
   villages; what was missing was the universe's own things, hidden at the end of Tilly's BLOCKS (they stay there
   too). Nell (the Dragon Realm, merged mid-task) keeps one as well; Green Meadows' stand is Tilly's stall. *Cost:* in
   universes 2–5 two shops stand near the spawn; a stand farther out (by a secret place) would need a new spot rule.
3. **One MORE entry, SHOP,** holds both finding Tilly and trading with players (the brief's "friends list": the
   players in this world, from `Session.chat_names` with a body; the pause menu's FRIENDS page stays the bot friends').
   *Cost:* trading is two taps away (MORE, SHOP) besides the name tag.
4. **SHOP points at the nearest full shop** (Tilly's stall or a villager who trades), never at a stand or the cart
   (they sell only their own things; the cart has its own row). The shop opens by itself on arrival only after SHOW
   ME, not after the tip's arrow. The arrow is the /find arrow (the quest arrow steps aside while it shows).
5. **The tip once per profile** (`ProfileData.hints_seen` "shop_tip"), in the first Survivor world played after this
   lands — also for children who already know Tilly. *Cost:* one extra tip for them.
6. **Market day every 7th in-game day from day 2**: a day is 20 minutes, so the first market comes about 17 minutes into
   a new world and then about every 2 h 20 min of play (sleeping skips nights and counts). The host counts sunrises
   from the sky's clock once a second; worlds saved before start at day 1. *Cost:* children with short sessions see it
   rarely; `MarketRules.FIRST_MARKET` / `MARKET_EVERY` are the knobs.
7. **Nico brings the same things every time** (no rotation, nothing "only today", no countdown on screen; §6 and
   §18.1's no-rotation rule applied to gold too): the village blocks of page 13 at fixed prices × 2^(u−1), buy only,
   never bought back (no loop can mint gold). *Cost:* content only (`MarketRules.STOCK`).
8. **The cart stands beside Tilly's stall** (3.5–6 blocks to her side, level and dry, no trunk next to it, 4 blocks
   clear of the Totem, the hub circle, the Theater and the helper's spot), found on a worker thread when the world
   starts. *Cost:* on odd terrain the fallback spot may be uneven.
9. **Offers are proposals: nothing leaves a bag before the swap** (no escrow). The host holds each offer to what its
   owner still has every 250 ms and checks everything again at the swap, so a stopped trade, a crash or a child who
   placed the offered blocks never loses or copies anything. *Cost:* an offer shrinks when its blocks are used, and both
   press READY again (a note says why).
10. **Tradable:** the bag's blocks and items except universe crystals (a key you earn by reaching its universe) and the
    Gold Farm (one per world, its owner's); Survivor gold at most 500 × 2^(u−1) a trade (under the online server's
    2,000 × 2^(u−1) award limit; its hourly limit of 20,000 × 2^(u−1) still applies to a receiver's awards). **Not in the
    bag, so never tradable:** pets and tamed animals (#41's horses, camels and donkeys with their chest too), Pip and
    the baby dragon, looks and cosmetics, stickers, keepsakes, titles, anything a grown-up bought. *Cost:* a bigger gift of
    gold takes several trades.
11. **A present one way is allowed** (one side may be empty; both empty is refused). *Cost:* a child could be talked into
    giving things away — nothing moves without their own READY after seeing both sides, and online an under-13 child
    trades only with their friends.
12. **No distance rule:** both in the same world is enough (the name tag needs a tap within 8 blocks; SHOP's list works
    anywhere in the world); leaving, or a dropped link, stops the trade. *Cost:* two children far apart can trade.
13. **The age rule:** online, a player under 13 trades only with players on their own friends list — each game tells
    the host its friends' user ids (`player_trade_friends`), the host maps peers to user ids through the relay. LAN
    players are together at home and trade freely (like LAN chat). Bands are the chat's registered ones. *Cost:* a
    modified game could lie about its own friends, which only weakens its own child's protection; LAN trusts the home.
14. **Asks:** one out and one waiting per child, asking again waits 3 s, no expiry timer; a tap outside the ask card,
    or opening the pause menu (quest pages close on pause), is NO THANKS. *Cost:* a child who never answers keeps the
    asker waiting (the asker can ask someone else); a child who pauses has to be asked again.
15. **The trade window never closes by a stray tap;** X or Android Back stops the trade; the pause menu leaves it open.
16. **The chat line goes to the two traders only** (privacy), not to everyone in the world.
17. **Bots can't be traded with:** they are not players (no card from their name, not in SHOP's list, and the host
    refuses any peer without a player body).
18. **A stand has no figure of its own** (the helper stands beside it) and no sections in its shop; SELL works there as
    at Tilly's (the host accepts trades near any trader).

## Out of scope (said so on purpose)

Trading pets or tamed animals (the brief), trading across worlds (a friend who is not in your world: M4 I's presents
already carry builds), real money (owner #35's shop is the grown-ups'; gold is never sold), the pause menu's FRIENDS
page (bot friends), Monster Wave's gold.

## What the lead should check on the emulator

1. **New Survivor world (Green Meadows):** the picture tip "Tilly's shop is near!" once, the find arrow at top right
   pointing to her; a second new world: no tip.
2. **MORE → SHOP:** the card fits 2400 × 1080; Tilly's row with metres and the dial arrow turning as the child turns;
   SHOW ME → the arrow; walking to her opens her shop by itself; close by the row says OPEN. With QUESTS, MAP and
   SHARE (signed in) the MORE panel's four rows fit (tested headless on both screens).
3. **Desert, Frostpeak, Candy, Dragon Realm Survivor:** a stand beside Zara / Bram / Mimi / Nell in the universe's
   colours with its sign; a tap → "Zara's stand" with the local blocks; buy one. Both styles.
4. **Market day:** from a new world sleep through a night (a bed) until day 2's sunrise: the banner, Nico's cart beside
   Tilly's stall, Nico waving; a tap → "Nico's Market"; buy roof tiles; the cart leaves at sunset and comes back on day 9.
5. **LAN (emulator + desktop):** a tap on the other player's name tag → their card → TRADE; the other sees "… would
   like to trade." YES / NO THANKS; the trade window on both, ×1 / ×10 / ALL, the gold chips; READY on both → the
   things swap, "Traded!", the chat line on both; X stops it; the other leaving stops it.
6. **Online** (two accounts, one under 13): trading with a friend works; with a guest who is not that child's friend,
   "You can trade with … once you are friends."; the gold moved shows on the server's ledger after 5 s.
7. **Performance:** nothing runs per frame but the SHOP card's refresh while it is open and the guide's check four
   times a second while guiding; the stand and the cart are shared meshes with one small static body each.

## Merge notes

Shared files touched with one-line hooks and a section at the end: `autoloads/session.gd` (section `# --- Trading`,
hooks in `_ready`, `survivor_reset`, `_physics_process` and one `elif` in `host_trade`), `scenes/sandbox.gd` (section
"Owner #37", 6 one-liners), `world/world_meta.gd` (the `market` field, 2 lines), `entities/player/block_interactor.gd`
(one line and a section), `ui/hud/shop_panel.gd` (5 small edits and a section), `ui/hud/hud_icons.gd` (`shop`),
`tools/lan_test.gd` (`--trade`). The spec section is §14.23 (§14.19 is #41's, §14.20 M3 Task 21a's).
