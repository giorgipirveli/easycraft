# Owner feedback #35: the honest, parent-facing shop (2026-09-24)

The owner asked for "psychological tricks and methods to motivate players to spend money". The lead
ruled (row #35, 19:52): **no manipulation aimed at children**; parents pay, for clear value. This agent
built that ruling: spec §18 "Monetization" (and a line in §2 and §6), plan M5 Task 4b. Built in a
worktree from `8cdcde7`, no editor or emulator (the lead checks on the emulator: below).

## What was built

| Part | Where |
|---|---|
| **The one table** the owner changes: products (EasyCraft Plus, Sky Pack, Ocean Pack; slots Storybook Pack and Glider Looks, not for sale), one kind only (`ONE_TIME`), fixed US$ reference prices, `FREE_UNIVERSES` (meadows, desert), `FREE_FOREVER`, `PLUS_LATER` (server extras, never shown before they work), `PLAY_IDS` (empty: the Play store is off) | `core/shop/shop_catalog.gd` (`ShopCatalog`) |
| **What a purchase opens**: Plus opens every ladder universe not in `FREE_UNIVERSES` (Frostpeak, the Candy Kingdom, and any universe added to `UniverseRegistry.LADDER` later: one table line), a pack gives its items (granted into `cosmetics`, so the editor, the look sync and the backup work unchanged); recorded once in the profile's new `purchases` | `core/shop/entitlements.gd` (`Entitlements`), `ProfileData.purchases` |
| **Pack items** (our own designs, both styles): Plus set — Frost Ranger (outfit: fur hood, scarf), Explorer Hat, Aurora Cape, Snowflakes trail; Sky Pack — Phoenix Wings, Cloud Cape, Feathers trail, Aviator Cap; Ocean Pack — Deep Diver (outfit: brass diving helmet, weight belt), Wave Cape, Little Fish trail, Captain's Cap. A new avatar kind `PACK` (`"pack": <product>`): never for gold, never earned, rarity at most rare | `AvatarCatalog` (items, 2 outfits, `PACK`), `AvatarParts` (9 box recipes), `AvatarTrail` (3 trail looks), `AvatarUnlocks.lock_reason` ("Part of the Sky Pack.") |
| **The wish list**: WISH (a heart) in the avatar editor on a pack item, in BUY's place; a heart on the tile; kept in the profile's new `wishes`; the grown-up area lists it with the product and price and GIVE AS A GIFT; a gift that arrives leaves the list | `core/shop/wish_list.gd` (`WishList`), `AvatarEditor` section "Owner 35", `AvatarTile.wished` |
| **Words**: the child's (calm, no price, no buy word, the Plus line with "ask a grown-up" said **once** per profile, `hints_seen` "shop_plus_universe") and the grown-up's (plain, the price before paying, results, refusals) | `core/shop/shop_words.gd` (`ShopWords`) |
| **Billing adapter**: `Billing` (base = no store: nothing available), `FakeBilling` (tests; debug builds keep a pretend purchase history in `user://fake_store.json`, labelled "Test store: nothing is charged"), `PlayBilling` (the Godot Google Play Billing plugin's `GodotGooglePlayBilling` singleton, 3.x API; **off** without the singleton or without `PLAY_IDS`) | `core/shop/billing.gd`, `fake_billing.gd`, `play_billing.gd` |
| **The flow**: buy only while the grown-up area's SHOP page shows; record + acknowledge on PAID; PENDING opens when paid (whatever screen is open); CANCELLED / FAILED change nothing; already owned → a restore; restore at every start and on RESTORE (only ever adds); `verify_receipt` hook for the owner's server (may be a coroutine); the store's own prices when it answers | `core/shop/shop_service.gd` (`ShopService`), Session section "Owner 35: shop" (`shop()`, `use_shop()`, `shop_travel_refusal(u)`) |
| **The grown-up area's SHOP tab** (behind the parent gate): PLUS (price, its universes, its set with pictures), PACKS (each pack's price and exact items), WISH LIST (n), ALWAYS FREE (the free-forever list and the trust line), RESTORE; BUY → a confirm page (what, price, "paid once", every item) → PAY → the store's sheet; results in plain words; "The shop isn't open" without a store | `ui/shop/shop_page.gd` (`ShopPage`), `GrownUpsPanel.PAGE_SHOP` (section "Owner 35") |
| **Locked universes**: a card for a Plus universe unlocked by its boss says "EasyCraft Plus" (a veil and a star, can't be pressed); the line "With EasyCraft Plus — ask a grown-up to look in the grown-up area." under the cards (menu SURVIVOR hub, stone-circle hub) or on a portal the **first** time only; after that "This universe comes with EasyCraft Plus." on a portal, nothing under the cards | `UniverseCard.plus_locked`, `HubPanel.open`, `menu.gd _show_hub`, `sandbox.travel_to` (one call) |
| Backup merge: purchases and wishes are joined, never lost; a profile with a purchase is not "new" | `ProfileBackup.merge` / `is_new` |
| Store drafts: Data safety (purchase history, only product ids; Google Play takes payments), Families/IARC (digital purchases: yes, parent-gated, once the shop is on), listing, privacy policy, the children's notice, README facts, the trust promise's line 2 (still true, with the proof) — each marks what **the owner** must do in Play Console | `docs/store/*` |

## Patterns (GodotPrompter skills `mobile-development` + its IAP reference, `save-load`, `godot-ui`)

- **Chosen:** the skill's "put every store call behind a service abstraction so the platform plugin is
  swappable" — `Billing` with a no-store base, a fake and the Play adapter; the skill's Play rules:
  query product details before `purchase` (the adapter queries at connection and refuses a purchase before
  it), never award PENDING, acknowledge one-time purchases (Play refunds unacknowledged ones after three
  days), `query_purchases` for restore; JSON profile fields added with defaults (no version bump: each
  field falls back on its own, as the profile already does); containers built in code with `UiKit` /
  `OnlineUi` like every menu, one row of big toggle buttons for the views (agent F's grown-up area
  pattern), `AvatarTile` pictures reused so the grown-up sees the same pictures the child does.
- **Rejected:** the plugin's own `BillingClient.gd` class (it only exists once the addon is installed: a
  class name the game can't parse without it); a half-installed plugin (the plugin is an Android v2
  plugin that only Gradle builds include — agent F's Age Signals ruling); `TabContainer` (Godot 4.7's
  internal tab bar node, M2 Task 6's gotcha); a `ScrollContainer` for the shop page (views sized to fit
  instead, checked by the fit test); `.tres` resources for the catalog (a table of consts the owner edits
  in one place; tests read it); consumables or a currency (never, by the ruling).

## Tests (RED → GREEN)

New: `tests/unit/test_shop_catalog.gd` (12), `test_entitlements.gd` (10), `test_wish_list.gd` (6),
`test_shop_service.gd` (15), `test_play_billing.gd` (9); `tests/integration/test_shop_grown_up.gd` (14),
`test_shop_child_side.gd` (9). 75 tests.

- **Rules** (catalog, entitlements, wish list, service, Play adapter): the tests were written first, but
  the API stopped this agent mid-task before they were run, and the code was finished before the first
  run; so, like agent F, the key lines were **mutation-checked**: with the parent-gate check removed from
  `ShopService.refusal`, a pending payment recorded, and `Entitlements.universe_open` always true, the
  tests failed (`[started] expected [needs_gate]`, "the store was never asked", "not while the payment
  waits", "universe 3 waits for Plus", "a pack is not Plus"), then passed with the lines back. First runs
  also found real faults: `Billing.OK` shadowed the engine's `OK` inside `FakeBilling` ("Invalid operands
  Error and StringName") — renamed `Billing.PAID`; a test's hand-written JSON was invalid.
- **UI and glue** (proper RED): `test_shop_grown_up` and `test_shop_child_side` were run before the UI
  existed and failed for the right reasons: `Could not find type "ShopPage"`, `Cannot find member
  "PAGE_SHOP"`, `Invalid access to property 'wish_button'` / `'plus_locked'`, `Nonexistent function
  'shop_travel_refusal'`, the hub's hint `""` instead of the Plus line, the menu without the Plus card.
  GREEN after `ShopPage` and the hooks; then the fit test caught two views too tall for the 534 px
  panel (the confirm page 626 px, ALWAYS FREE 579 px), fixed by moving the trust and "paid once through
  …" lines into the page's note line.
- A review after the first commit found that a stray "already owned" or error answer from Play with no
  purchase in flight reached the grown-up as a result with no product: two tests first
  (`test_a_stray_answer_without_a_purchase_in_flight_names_no_product`: `[{"product": "", "status":
  owned_already}] != []`; `test_an_answer_about_something_that_is_not_ours_is_ignored`: two results and a
  restore for nothing), then the guards in `PlayBilling` and `ShopService`.
- The child side over the code: no script under `ui/avatar`, `ui/universe`, `ui/menus`, `ui/hud`,
  `ui/progress`, `ui/photo`, `world`, `scenes`, `entities` makes a `ShopPage`, shows a price
  (`reference_price`, `price_words`, "US$") or calls a store's `buy`; every script that makes a
  `GrownUpsPanel` makes a `GrownUpGate` and waits for `passed`.
- Full suite: see the commit message (run through `tests/suite_slots.sh`).

## Rulings (decisions made on the owner's behalf; each is one table line or constant to change)

1. **Free forever:** Sandbox, Survivor in Green Meadows and the Sandstorm Desert (with their bosses), bot
   friends, LAN, **online play with friends**, the free avatar set and everything earned, the profile
   backup. Online play stays free: the owner made it part of the game's identity (#25). *Cost if wrong:*
   one list (`FREE_FOREVER`) and one gate to add.
2. **EasyCraft Plus = every universe after the first two** (by ladder name: `FREE_UNIVERSES`), the Plus
   set, and later the server extras (worlds saved on the server, visiting friends' worlds while they are
   away) **only once they work** (`PLUS_LATER.ready`; never promised on the page before). The universes
   still unlock by beating bosses; Plus lets the child travel there. *Cost if wrong:* `FREE_UNIVERSES`
   (e.g. add `&"frost"`), one line.
3. **Prices:** Plus US$4.99, packs US$1.99 each (reference; the owner sets the same in Play Console, and
   the grown-up sees Play's own price in their currency). *Cost if wrong:* `price_cents`.
4. **Nothing earnable is sold; nothing sold can be earned:** packs hold new items of kind `PACK`, never
   gold items (no "pay to skip"); gold never buys a pack item. Pack items are at most **rare**, never
   outranking what is earned. *Cost if wrong:* none known.
5. **Only one product kind, one-time.** No consumables, no gold for money, no subscriptions. *Cost if
   wrong:* a subscription would need `purchase_subscription` and its own rules.
6. **The wish list holds only what a grown-up can give** (pack items, products on sale). Gold items stay
   the child's own goals (M3 Task 21b's have/need bar can add them in its own list). WISH shows in BUY's
   place, only on pack items. At most 24 wishes. *Cost if wrong:* `WishList.can_wish`.
7. **The Plus line with "ask a grown-up" is said once per profile** (a hint), on the first Plus card or
   portal; afterwards the card says "EasyCraft Plus" and a portal "This universe comes with EasyCraft
   Plus." — no repeats, no timers, no badges, no notifications. *Cost if wrong:* none (the brief's words).
8. **The parent gate in front of every purchase:** the grown-up area (already behind `ParentGate`) has
   the SHOP tab; `ShopService.buy` refuses unless that page is showing; a confirm page with the exact
   items and price comes before PAY; then Google Play's own sheet (its own authentication). *Cost if
   wrong:* a second gate before PAY is one `GrownUpGate` in `_confirm`.
9. **Restore only adds; refunds are not taken back on the device.** A restore (every start and RESTORE)
   adds what the store account owns; a failed or shorter answer takes nothing away. A refunded purchase
   stays open until the owner's server checks receipts (`verify_receipt`) and a revoke rule is added.
   *Cost if wrong:* refund abuse; one branch in `ShopService._on_restore_finished`.
10. **No grandfathering:** a profile that reached universe 3 before this version keeps
    `universe_unlocked` but needs Plus to travel there (the game has no public players yet; only the
    owner's test builds). *Cost if wrong:* one flag granting Plus's universes to old profiles at load.
11. **Play Billing: an adapter to the plugin's singleton, not the plugin.** Godot Google Play Billing
    3.3.0 (MIT, Play Billing Library 9.1.0, Godot 4.2+) is an Android v2 plugin: only Gradle builds add
    it, and the game's presets don't use Gradle. `PlayBilling` talks to the `GodotGooglePlayBilling`
    singleton with the plugin's documented calls and signals (checked against its 3.3.0 source:
    `BillingClient.gd`, `Utils.kt`), is tested against a stand-in singleton, and is off until the
    plugin is installed and `PLAY_IDS` are set. *Cost if wrong:* a device test may find a mismatch in
    the plugin's dictionaries (one function each: `read_purchase`, `price_of`).
12. **Debug builds use the pretend store** (so the lead can buy on the emulator, clearly labelled "Test
    store: nothing is charged"); release builds without Play say "The shop isn't open in this version
    yet." *Cost if wrong:* none (no real money moves in a debug build).
13. **Nothing about payments is kept:** the profile records only owned product ids (and the wish list);
    no prices paid, order ids or tokens (they go only to the receipt hook). *Cost if wrong:* none.
14. **Storybook costumes (#36) and glider looks** have catalog slots (`pack_storybook`, `pack_gliders`,
    `ready: false`); the #36 agent decides whether its costumes are earned or sold (its brief says
    earned by playing unless the owner sells a pack). *Cost if wrong:* none.

## For the lead

**Merge notes.** Shared files, each a marked section or a few lines: `autoloads/session.gd` (section
"Owner 35: shop" at the end, one call in `_ready`), `core/save/profile_data.gd` (`purchases`, `wishes`),
`core/save/profile_backup.gd` (merge, `is_new`), `core/avatar/avatar_catalog.gd` (kind `PACK`, 12 items at
the end of `ITEMS`, 2 `OUTFITS`, rarity), `core/avatar/avatar_unlocks.gd` (lock reason), `entities/player/
avatar_parts.gd` (9 recipes at the end), `avatar_trail.gd` (3 looks), `ui/avatar/avatar_editor.gd` (WISH;
section at the end), `avatar_tile.gd` (`wished`), `ui/online/grown_ups_panel.gd` (`PAGE_SHOP`, the tab,
`_shop_view`), `ui/universe/universe_card.gd`, `hub_panel.gd`, `ui/menus/menu.gd` (`_show_hub`),
`scenes/sandbox.gd` (`travel_to`). Other agents adding avatar items (#36 costumes) or universes (#39 Dragon
Realm) append to the same tables: keep both sides. **The Monster Wave agent (#44)**: its "go to the next
universe" choice should ask `Session.shop_travel_refusal(u)` like `travel_to` (a universe after the
free ones comes with Plus). Optional follow-up: the Sand Serpent's portal still says "Walk in:
Frostpeak!" and then gives the calm Plus line; `UniverseRules.portal_words` could say it first.

**Check on the emulator** (a debug APK: the pretend store):
1. SETTINGS → GROWN-UPS → the gate → SHOP: the note says "Test store: nothing is charged"; PLUS shows
   US$4.99, Frostpeak and the Candy Kingdom, four pictures; everything fits the screen (20:9 and 16:9).
2. BUY → the confirm page (price, "paid once", the looks) → PAY → "Thank you! …"; BUY is gone ("Owned ✓").
   Back in the avatar editor the Frost Ranger, Explorer Hat, Aurora Cape and Snowflakes are owned, and
   they look right in BLOCKY and REAL (hood and helmet fit, cape and wings sway, trails fall/float).
3. A profile at universe 3 without Plus (delete `user://fake_store.json` and the profile's `purchases`):
   the SURVIVOR hub's Frostpeak card says "EasyCraft Plus" and the line under the cards shows once; it is
   gone the next time. Walking into the Serpent's portal: the calm line.
4. Avatar editor, WINGS → Phoenix Wings: no price, no BUY, WISH (a heart); WISH → "It's on your wish
   list." and a heart on the tile; the grown-up area's WISH LIST (1) shows it with "in the Sky Pack,
   US$1.99" and GIVE AS A GIFT → confirm → PAY → the wish is gone and the wings are owned.
5. Delete the profile (keep `user://fake_store.json`): a new profile gets Plus and the packs back at
   start (the restore) — RESTORE says "All your purchases are here."
6. A **release** APK: SHOP says "The shop isn't open in this version yet." and there is no BUY anywhere.
