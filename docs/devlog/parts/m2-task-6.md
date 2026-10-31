# M2 Task 6: Tool tiers, shield, potions, spear and mace, rarity colours

Spec §12.6 (tiers, shield, potions), §13.1–13.2 (spear, mace, rarity colours; owner feedback #22),
plan Task 6 and its allocations. Built in an isolated worktree from `2430164`
(`m2-survive-the-night`), without the editor or the emulator.

## What was built

- **Tiers** (`core/rules/weapon_rules.gd`): `WeaponRules.TIERS` lists wood → stone → iron → crystal →
  cosmic for the sword, bow, pickaxe, axe, spear, mace and shield. The first (wood) item is the kind:
  `base_of(item)` gives it, `tier_of(item)` gives 0–4 (−1 for anything else). A tier item has its kind's
  stats with damage × 1 / 1.5 / 2 / 3 / 4.5 (`TIER_MULTIPLIERS`, rounded, cached read-only), and every
  M1b check like `== ItemIds.SWORD` now compares `base_of`, so tier items combo, draw, fell and swing
  like their kind. **Dig power** (`dig_power`, `power_cooldown`) makes a better axe or pickaxe use its
  block power faster (cooldown ÷ the tier's multiplier).
- **Spear** (SPEAR 118, SPEAR_STONE…COSMIC 161–164) and **mace** (MACE 119, MACE_STONE…COSMIC 166–169):

  | Weapon | Damage | Reach | Cooldown | Knockback | Arc | Max hits | Extra |
  |---|---|---|---|---|---|---|---|
  | Spear | 4 | 4.5 m | 0.55 s | 7 | 20° | 2 | thrust; throw ×1.5 damage |
  | Mace | 6 | 3.0 m | 0.9 s | 12 | 50° | 3 | ground shake, dust |

  - The **spear thrusts** (the held spear shoots forward along the hand's −Z and back). A tap on
    something beyond its reach (up to 20 m), or ATTACK held for 0.3 s and let go, **throws** it:
    `Session.request_spear_throw` → the host checks it like an attack (a spear, a sane aim, the shared
    cooldown) → `CombatDirector.spawn_spear` → a `ThrownSpear` (`entities/projectiles/thrown_spear.gd`)
    that every peer flies like an arrow (speed 17, gravity 13: about 22 m at most). The host checks
    what it hits (first thing only, ×1.5 damage), then it drops and **sticks where it lands**. Its
    thrower takes it back by walking within 1.6 m; after 20 s it flies back by itself ("Your spear
    flew back to you!"). One spear out per player; while it is out the hand is empty
    (`Player.spear_out`) and spear attacks are refused locally ("Walk to your spear to pick it up!")
    and on the host. The inventory never changes, so a spear is never lost.
  - The **mace** swings overhead (the hammer's smash) and every swing strikes the ground ahead
    (`WeaponRules.mace_impact`): dust and a thud for everyone, and a camera shake for players within
    8 m (0.35 at the impact, fading out), at most one every 0.34 s. The shake is behind one function,
    `CombatDirector.shake(player, strength)`: it calls an autoload named `Feel` with `shake(strength)`
    when there is one (Task 11), else wobbles the camera's h/v offsets for 0.2 s.
- **Shields** (SHIELD_WOOD…COSMIC 140–144; passive, ruling 5): `WeaponRules.shield_block(best_shield,
  hit_dir, facing)` blocks 30 / 40 / 55 / 70 / 85 % of a blow from the front (±60° on the ground plane;
  `hit_dir` is the way the blow travels). `Session.hurt_player` now asks `shielded_amount` first
  (three lines in the Task 1 section): the best shield in the Survivor inventory, or in Sandbox the
  best shield in the hotbar (`Player.carried_shield`, synced). The blocked part is kept exactly with a
  per-player carry (`shielded_damage`), so 1-point hits are blocked fairly on average. A block shows a
  small burst and a thud for everyone (`shield_blocked`). A selected shield is held in the hand.
- **Potions** (`core/survival/potion_rules.gd`): Moon Jump (jump height × 1.8, 60 s), Invisibility
  (30 s), Speed (walking and swimming × 1.5, 60 s). A tap on the potion's hotbar slot (or its number
  key) drinks it: `BlockInteractor.tap_slot` → `Session.request_drink` → the host refuses a potion that
  is still working, takes one from the inventory in Survivor (Sandbox is unlimited), and every game
  starts it on that player (`Player.drink`: bubbles and a ding). `Player.potions` (a
  `PotionRules.Effects`) counts down on every game with the physics frames. `Player.is_invisible()`,
  `Player.invisible_until` and `potions.visibility()` are for Task 5's stealth. An invisible player
  is see-through to everyone (one shared unshaded ghost material on the avatar and the held item).
- **Potion timers** on the HUD (`ui/hud/potion_timers.gd`): a chip per working potion with its icon and
  the whole seconds left, top-centre-left (anchor top-centre, x 240–540, y 100–148 of 1280 × 720), under
  the palette overlay, never taking a tap. The last 5 s turn orange (steady, no blinking).
- **Rarity colours** (`core/rules/item_rarity.gd`, §13.2): common grey, uncommon green, rare blue, epic
  purple, legendary gold, for tiers wood…cosmic. They show on icons (rim and pale metal), held models
  (one cached material per tier) and names (the palette's tier rows).
- **Item icon atlas** `data/items/item_icons.png` (8 × 8 tiles of 16 px) from `tools/make_item_icons.gd`
  (deterministic pixel art, no RNG), imported as an **Image** so its pixels can be read on every
  renderer. Row 0 holds one picture per kind (sword, bow, pickaxe, axe, spear, mace, shield) with its
  metal in pure greys; row 1 the three potions; rows 2–3 are still free (mine); rows 4–7 are empty
  (Task 16 row 4, Task 15 row 5). `BlockIcons.tier_image(kind, tier)` composes each tier icon once at
  32 px: the grey metal takes a pale rarity colour, a rim in the full rarity colour goes around, and
  **1–5 white pips** in the top-left corner count the tier. The M1b wood sword, bow, axe and pickaxe
  now show their tier icon too (grey rim, one pip).
- **Held models** (`WeaponModels`): the spear, mace and a round shield, one merged vertex-coloured mesh
  each. A tier item's mesh is its kind's plus **tier + 1 light bands** on the handle (studs under the
  boss of a shield), built once per item. Its colour comes from `WeaponModels.tier_material(tier)`: one
  cached copy of the M1b material per tier with a different albedo colour (the same shader, nothing
  new to compile). `HeldItem` holds weapons and shields, animates the spear's thrust (a forward push)
  and swaps to the ghost material while its holder is invisible.
- **Palette**: two pages on a `TabBar`, **BLOCKS** (the M1b blocks, MAGIC and TOOLS rows) and
  **ARMORY**: rows WOOD, STONE, IRON, CRYSTAL, COSMIC (names in their rarity colours), each with that
  tier's spear, mace, shield, sword, bow, pickaxe and axe (the WOOD row holds the spear, mace and
  shield; the wood sword, bow, pickaxe and axe stay in TOOLS so every item is listed once), then
  POTIONS. Buttons have a rim in their rarity colour. Sandbox shows every tier. The panel is sized to
  the bigger page (about 26–606 px of 720, clear of the hotbar at 642).

## Files

New: `core/rules/item_rarity.gd`, `core/survival/potion_rules.gd`, `entities/projectiles/thrown_spear.gd`,
`ui/hud/potion_timers.gd`, `tools/make_item_icons.gd`, `data/items/item_icons.png` (+ `.import`, Image).

Changed: `data/items/item_ids.gd` (ids, names, `ARMORY`, `ALL`), `core/rules/weapon_rules.gd` (spear and
mace rows, tier section at the end, `base_of` in the M1b checks, `arrow_step` gravity parameter),
`entities/weapons/weapon_models.gd`, `entities/player/held_item.gd`, `entities/player/weapon_user.gd`,
`entities/player/block_interactor.gd` (`tap_slot`), `entities/player/player.gd` (hooks + section at the
end), `entities/projectiles/arrow.gd` (`weapon`), `world/combat_director.gd` (section at the end, small
hooks), `autoloads/session.gd` (hook in `hurt_player`, section `# --- M2 Task 6` at the end),
`ui/hud/block_icons.gd`, `ui/hud/block_palette.gd`, `ui/hud/hotbar.gd`, `ui/hud/hud.gd` (two lines +
section), `assets/CREDITS.md`, `docs/DEVELOPMENT.md`.

## Tests (RED → GREEN)

Baseline 637 passing. New test files:

- `tests/unit/test_weapon_tiers.gd` (21): ids, five tiers per kind, `tier_of`/`base_of`, the M1b items
  are the wood tier with unchanged stats, damage per tier, tiers keep reach/speed/push/power, tier
  weapons combo and spin like their kind, dig power, spear reach and arc, mace speed and push, the
  ground shake's reach, tap-to-throw distances, throw flight and ×1.5 damage, pickup distance, shield
  shares per tier, the ±60° front (and no block from behind, straight above, unknown or zero
  direction), the best shield owned, fair blocking over 100 small hits, rarity per tier and colours.
  RED: parse errors for the missing ids and members; then one wrong expectation in my own test (a
  sword does hit the side target), fixed in the test. The zero-direction case was added later and
  failed (0.55 instead of 0) before the fix.
- `tests/unit/test_potion_rules.gd` (7): durations, effects, expiry, no stacking, refusals. RED:
  `PotionRules` not declared.
- `tests/unit/test_item_icons.gd` (8): the atlas size, rows 4–7 empty, a picture with tintable metal and
  an empty pip band per kind, potions, 1–5 pips per tier, rarity rims, tinted metal and untouched wood,
  every item's icon cached. RED: the API was missing, and the M1b `test_every_item_has_a_name_and_icon`
  failed for all 34 new items.
- `tests/integration/test_palette_armory.gd` (7): two pages, every tier and potion once, rows by tier
  with names in rarity colours, rarity rims, every page fits above the hotbar, big buttons, picking
  one. RED: the items were missing (the M1b palette test failed too).
- `tests/integration/test_weapon_tiers_in_world.gd` (7): spear/mace/shield meshes (one surface, vertex
  colours, faces outward, sizes), tier + 1 bands per tier item, one cached material per tier with the
  M1b shader flags, the held tier item and shield, swing names, the thrust push, the mace overhead.
  RED: `TIER_MARK` / `tier_material` missing.
- `tests/integration/test_spear_and_mace.gd` (10) and `tests/integration/test_player_potions.gd` (7):
  thrust reach, throw hit and drop, sticking, pickup by walking up, auto-return, one spear per player
  and an empty hand, the mace shake (near only, three per second at most), tier arrows; drinking,
  speed ×1.5, jump height ×1.8, the ghost look on and off (avatar and held item), the empty hand while
  the spear flies, `carried_shield` synced. These were written before `ThrownSpear` existed (they could
  not parse) but were first run after it was written.
- `tests/integration/test_session_task6.gd` (8): Sandbox potions unlimited and not wasted, Survivor
  takes one from the inventory and refuses at zero, non-potions ignored, spear throws checked like
  attacks, shields from the front in Sandbox (with the carry), never from behind, Survivor's best
  inventory shield, no shield. Written after the Session code; checked by a mutation (the
  `hurt_player` hook removed: 2 failures), then restored.
- `tests/integration/test_weapon_user_task6.gd` (8): a tap on a potion slot drinks, a block slot only
  selects, the palette never drinks, the hotbar button drinks, a held shield and the carried best one,
  quick ATTACK thrusts, held ATTACK throws, no spear attack while it is out. RED: `tap_slot` missing,
  shields not held, the spear hold not throwing.
- `tests/integration/test_potion_timers.gd` (3): placement clear of the other controls and under the
  palette, a chip per potion with its seconds, orange last seconds, no player. RED: `PotionTimers` not
  declared.

Changed M1b test: `test_item_ids.gd` `test_magic_and_tools_rows_cover_every_item_once` now covers
MAGIC + TOOLS + ARMORY (ALL grew). Every other M1b test passes unchanged.

Full suite (`tests/run_tests.sh`, exit 0, no script errors): 637 → **680** after part 1 (rules, icons,
palette) → **723** after part 2 (models, spear, mace, shields, potions, HUD, controls) → **725** with two
guest-side RPC tests → **731** after the review fixes (below). The thrust test first sampled its 0.1 s
peak with real-time waits and missed it once while the PC's load average was above 60; it (and the
mace-arm test) now step the tween by hand.

**Headless weapons smoke run** (`tools/weapons_smoke.gd`, the real sandbox, private user folders):
this branch passed 3 of 4 random worlds; the failing world (seed 2540073012: sword, arrow and
boomerang all miss the dummy) fails the same way on the base commit `2430164`, so it is an old,
terrain-dependent flake of the smoke tool: `_target_spot` picks a spot up to 2 blocks above or below
the player without checking line of sight, which melee has needed since review M10. The base passed
4 of 4 random worlds. (One earlier run here also failed "the dummy is saved with the world": the
hammer step dug under the dummy, which then popped; also terrain-dependent.) Suggested fix for the
lead: make `_target_spot` require `CombatDirector.in_sight` from the chest, or stand on the same level.

## Review (a fresh reviewer on the whole diff) and fixes

No critical issues. Fixed test-first (each new test failed before its fix):

- **Important: Survivor attacks did not check the weapon was owned.** With tiers a stranger weapon is
  much stronger (a cosmic mace hits 27 against the starter sword's 4), so a modified LAN client could
  farm monsters and gold. `Session.accept_attack` (and so spear throws) now asks `owns_weapon`: the
  inventory in Survivor, anything in Sandbox. Test `test_survivor_attacks_need_the_weapon_in_the_inventory`.
- **Important: a second drink could be lost on a LAN guest.** The guest's timer runs a little behind
  the host's, so the host could allow a new drink while the guest still refused it as "working". The
  host now sends the seconds left (`_rpc_potion(peer, potion, seconds)`) and the guest takes the host's
  word (`Player.sync_potion`, `Effects.set_left`). The same message now tells **late joiners** about
  potions already working (`Session.working_potions`, sent on `client_ready`). Tests
  `test_a_guest_follows_the_hosts_timer`, `test_the_host_tells_a_late_joiner_which_potions_are_working`,
  `test_the_time_left_can_be_set_by_the_host`.
- Minor: `ThrownSpear.drop_at` now clears `stuck` (a guest's copy could have stuck in a wall just before
  the host's word) — `test_a_dropped_spear_falls_even_if_it_had_stuck`; no "your spear came back"
  message to a thrower who left (an unknown-peer error) — `test_no_message_to_a_thrower_who_has_left`;
  `WeaponRules.tier_of`/`base_of` no longer allocate an empty array per call for untiered ids.
- Left as is: `Player.spear_out()` asks the `spears` group every frame, but only while a spear is held
  (the M1b boomerang does the same).

## Rulings (decided on the owner's behalf)

| Ruling | Cost if wrong |
|---|---|
| A tier changes **only damage and dig power**; reach, cooldown, knockback and arc stay the kind's. | Tiers feel alike except for numbers; one table to change. |
| **Dig power = how fast** a tool's block power works (cooldown ÷ multiplier). Which ores a pickaxe may mine is Task 3's (ruling 6), with `tier_of`/`base_of`. | If the owner meant bigger tunnels, `ToolPowers` changes; `power_cooldown` stays. |
| **Mace below the hammer** in speed and push (0.9 s, 12 vs 1.1 s, 14), so the M1b rule "the hammer is the slowest and pushes hardest" holds; the mace hits as hard (6) and shakes the ground. | If the mace should push hardest, change its row and that M1b test. |
| **Spear throw**: tap far or hold ATTACK 0.3 s; one out per player; the hand is empty until the thrower **walks within 1.6 m**; it **flies back after 20 s** by itself. The inventory never changes. | A child who throws it into a lake waits 20 s; nobody else can pick it up. |
| **Thrown spears hit the first thing** (×1.5) and drop; they never pierce. | Less powerful than a pierce; tuning only. |
| **Shields**: Sandbox counts the best shield **in the hotbar** (owner-reported, synced; Sandbox has no losses), Survivor the best **in the inventory** (host). Blows with no known source, from straight above or from right where the player stands are never blocked. | A modified LAN client could claim a shield in Sandbox. |
| **Blocked damage is exact on average** (a per-player carry of the fraction), so a wooden shield blocks 30 % of 1-point slime hits too; the first small hit is blocked completely. | Slightly surprising single hits; fair over a fight. |
| **Moon Jump: jump height × 1.8** (take-off speed × √1.8 ≈ 1.34), every jump including air jumps. | The owner may have meant speed × 1.8 (about 3.2 × height); one constant (`PotionRules.JUMP_HEIGHT`). |
| **Speed** is walking and swimming only, not flying (Survivor flying costs gold; Sandbox flying is already fast). | One multiplier in `_move_flying` if wanted. |
| **A potion still working is refused** ("still working! N s left"); no stacking or refreshing. A tap on its slot drinks at once (spec), also with the number keys; picking one from the palette never drinks. | An accidental first tap drinks it. |
| **Invisibility looks see-through for everyone** (friends included) with one shared unshaded alpha material; `GeometryInstance3D.transparency` was not used because its support outside Forward+ is not certain. | The first use may compile that shader once (a hitch to measure on the emulator); prewarm it if it shows. |
| **Tier icons are composed at run time** (32 px, once per item, cached) from one picture per kind: the 34 new icons do not fit the 32 tiles of rows 0–3, and one picture per kind keeps every tier consistent. Rows 2–3 stay free. | All 48 item icons take 19.2 ms once on this PC (load average 63 at the time), so roughly 60–100 ms on a phone, when the HUD is built during world load. |
| **Metal takes a pale rarity tint, the rim the full colour** (a full-colour blade merged with the rim). Held models take one tint over the whole model (one surface), so handles look slightly tinted. | Cosmetic. |
| **Palette pages** (BLOCKS / ARMORY on a `TabBar`) instead of one long panel: 34 more buttons do not fit 1280 × 720 above the hotbar. The WOOD row starts with the spear, mace and shield; the wood sword, bow, pickaxe and axe stay in TOOLS (every item listed once). | Children must find the ARMORY tab. |
| **Potion timers at top-centre-left** (x 240–540, y 100–148): under the hearts and stealth rows, left of the wave line and boss bar, above the chat history. A long toast (y 96–156, centred) can cover part of it for 2.5 s. | The lead may move it once Tasks 2, 5 and 9 are on screen. |
| The rarity class is **`ItemRarity`** (not `Rarity`), so a class Task 16 might add does not clash; chests should use it. | Two sources of rarity colours if Task 16 made its own. |
| **Survivor attacks need the weapon in the inventory** (host check; review fix). The M1b ruling (the host does not check the held item, whose sync may lag) still holds in Sandbox. | A weapon bought but not yet in the host's inventory (Tasks 3 and 7 must add bought tools to it) would be refused. |

### Accessibility rulings (the lead's child-psychology research, 2026-09-24)

| Ruling | Where |
|---|---|
| **Colour is never the only sign of a tier.** Tier icons carry 1–5 white pips with a dark edge; held models carry 1–5 light bands (studs on a shield). Tier rows in the palette are named (WOOD … COSMIC). | `BlockIcons.tier_image`, `WeaponModels.tier_marks`, `BlockPalette._armory_page`; tests `test_tier_icons_carry_one_to_five_pips`, `test_every_tier_item_is_a_cached_mesh_with_tier_plus_one_bands` |
| **Nothing flashes more than 3 times a second.** The mace's camera shake happens at most once every 0.34 s; potion timers never blink (the last 5 s turn orange and stay); drink and shield bursts are small one-shot particles. | `CombatDirector.ground_shake` (`SHAKE_GAP_MS`), `PotionTimers`; tests `test_a_mace_swing_shakes_the_ground_near_it_three_times_a_second_at_most`, `test_a_chip_per_working_potion_with_its_seconds` |

## What to check on the emulator (the lead)

1. Palette: the ARMORY tab is easy to hit; both pages fit above the hotbar on the phone's aspect;
   rarity rims and pips read at phone size; tier names in their colours.
2. Hotbar: tier icons (32 px) look crisp at 40 px, pips countable; potion icons.
3. Held models in both avatars: the spear points forward and the thrust pushes it; the mace swings
   overhead; the shield sits in the right hand facing forward; tier tints and bands visible.
4. Spear: hold ATTACK and let go (the crosshair shows while holding), tap a far dummy; the spear arcs,
   sticks, the hand is empty; walking up takes it back; after 20 s it comes back with a toast.
5. Mace: dust and a small, comfortable camera shake; nobody far away feels it.
6. Potions: a tap on the slot drinks (bubbles, ding), the timer chip appears top-centre-left; Moon Jump
   height with triple jump (ceilings in caves), Speed, the see-through look in BLOCKY and REALISTIC on
   the GL Compatibility renderer, and **the frame time of the first invisibility** (ghost shader
   compile).
7. Shield: with monsters (Task 4), a blow from the front shows the small burst and takes less.
8. LAN: others see your held shield and spear, your thrown spear, and your see-through look.
9. First palette open: the time to compose ~40 tier icons on the emulator.

## Integration notes (for the merge)

- **Task 3 (gathering):** gate ores with `WeaponRules.base_of(item) == ItemIds.PICKAXE and
  WeaponRules.tier_of(item) >= WeaponRules.TIER_IRON`. Potions are taken from the inventory in
  `Session._host_drink` (`inventory_of(peer).take`): if Task 3 sends counts to clients, notify there.
  The ARMORY page's buttons come from the same `_button(id, …)` as every other palette button.
- **Task 4 (monsters):** `WeaponRules.damage_to(MONSTER, weapon_id, combo, power)` already gives tier
  damage (a thrown spear passes `combo = WeaponRules.THROW`: ×1.5). Monsters hurting players must pass
  their position as `from` to `Session.hurt_player`, or shields cannot block (`Vector3.INF` = never).
- **Task 5 (stealth):** `Player.is_invisible()`, `Player.invisible_until`, `Player.potions.visibility()`.
- **Task 7 (trader):** tiers from `WeaponRules.TIERS` (index = tier), potions `ItemIds.POTIONS`,
  names `ItemIds.display_name`, colours `ItemRarity`. A bought weapon must go into the buyer's
  inventory on the host: Survivor attacks are only accepted with an owned weapon (`Session.owns_weapon`).
- **Task 11 (feel):** replace the body of `CombatDirector.shake(p, strength)`; it already calls an
  autoload `Feel` with `shake(strength)` when one exists.
- **Tasks 15 and 16:** item icon atlas rows 5 and 4. Add drawing calls to `tools/make_item_icons.gd`
  (no RNG, so order does not matter) and entries next to `KIND_TILES` / `POTION_TILES`. Task 16's chests
  can glow with `ItemRarity.color`.
- **Session:** hook in `hurt_player` (Task 1 section, 3 lines), `owns_weapon` in `accept_attack` (M1b
  weapons section, 2 lines) and `_shield_carry.clear()` in `survivor_reset`; new section at the end
  (signals `potion_started`, `spear_throw_requested`, `shield_blocked`; RPCs `_rpc_drink`,
  `_rpc_potion(peer, potion, seconds)`, `_rpc_spear_throw`, `_rpc_shield_fx`; `working_potions` is sent
  to players who join later).
- **Expect small textual conflicts** in `item_ids.gd` (`ALL`), `player.gd`, `hud.gd`,
  `block_palette.gd` (Task 3's Survivor filter), `combat_director.gd` (Task 4's monsters group),
  `session.gd` (sections at the end), `DEVELOPMENT.md`.
