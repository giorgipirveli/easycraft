# M3 Task 10: the Gold Farm (notes)

Built by a background agent in its own worktree (a branch cut from `m2-survive-the-night`, with the lead's
`lead-merge` merged in first: main plus owner #38, M4 I and M3 Task 4), without the editor or the emulator. Spec
§5.6, §14.8 (refined below), §6, §17.6; plan Task 10. Other M3/M4 agents ran in parallel.

## What was built

| Piece | Where | What it does |
|---|---|---|
| The rules (pure) | `core/economy/farm_rules.gd` (`FarmRules`) | Survivor only. Tilly sells a farm for 150 gold × 2^(u−1). It makes `RATES[rate]` (20, 30, 40, 50 an hour) × 2^(u−1) for the time away, capped at `CAP_HOURS[cap]` (12, 16, 20, 24 h), **only when the owner was inside it when they left**: `floor(rate × 2^(u−1) × min(away, cap) / 1 h)`, the same sum as the server's `farm_collect`. Upgrades: FASTER (rate) 200/400/800 and BIGGER (cap) 150/300/600 gold × 2^(u−1); workers 1/2/3/3 by rate level. `welcome` pays nothing without an away record or when the clock went backwards, and never takes gold. `packed` / `placed_again`: a farm picked up to move keeps its levels. `buy_refusal`, `upgrade_refusal`, messages, `server_start` (the farm_collect "start" payload), `to_save` / `clean` (a broken save is no farm or a safe one). |
| Where it stands (pure) | `core/economy/farm_site.gd` (`FarmSite`) | Placed like a stamp: the tapped cell is the middle of the farm's front row, the farm reaches away from the child and its barn door faces them (`facing_for_forward`, `center_for`). A 9 × 7 footprint (`HALF_W` 4, `HALF_D` 3): the barn (5 × 5) on the left, a yard in front of its door, the field (4 × 7) on the right. `refusal`: solid ground under every column (one block lower is filled by the plinth; never water) and open room over it (6 cells over the barn, 2 over the rest; air or walk-through plants). `is_inside`: anywhere over the footprint, 1 below to 7 above the floor. `in_barn` (nobody is trapped when it is placed), `box` (the one box the check copies). |
| The note's rules (pure) | `core/economy/farm_notify_rules.gd` (`FarmNotifyRules`) | "Your farm is full!" / "The barn holds all the gold it can.": off unless the setting `farm_note` is a real `true`; rings when the barn is full, but never 20:00–08:00 on the phone's clock (it waits for 08:00) and at most once a day (`last_rang_day`). |
| The notifier | `net/farm_notifier.gd` (`FarmNotifier`), `net/android_farm_notifier.gd` (`AndroidFarmNotifier`) | An interface like M4 F's `AgeSignals`: the base is a no-op that remembers what it was asked (desktop, tests, an APK without the plugin); the Android adapter calls the plugin singleton `EasyCraftNotes` (`scheduleNote(id, at_unix, title, text)`, `cancelNote(id)`) when the APK has one. **No plugin yet** (ruling 10). |
| The FARM item | `data/items/item_ids.gd` (section at the end, one line in `is_item`, one in `display_name`), `ui/hud/block_icons.gd` (section, one line in `icon`), `core/economy/shop_rules.gd` (HOME price, `one_only`, messages), `ui/hud/shop_panel.gd` (one word) | `ItemIds.FARM` **491** ("Gold Farm"; 492–494 kept for the farm). Not in `ItemIds.ALL`: no palette row in Sandbox and no `/give`; `is_item` knows it, so a Survivor bag holds it and the owned-things palette lists it. A red barn with a gold coin drawn in code. Tilly's HOME section sells one at a time (`one_only`, the owned check mark). |
| The building | `entities/farm/farm_building.gd` (`FarmBuilding`) | A small red barn with white trim, open doors, a gable coin and a hay door, a stone plinth, a yard with a coin sign, a field of wheat, carrots and pumpkins: **one shared mesh** (WeaponModels' vertex-colour material, one draw call), gold piles in the barn from a mesh cached per cap level (a bigger barn holds more), and one static body on the world layer (walls round a 2-block doorway, a flat roof, a hay bale). `find` / `ray_hit` for taps (within 8 blocks of the eye, not through blocks). |
| The workers | `entities/farm/farm_worker.gd` (`FarmWorker`) | 1–3 little farmers (straw hat, overalls, a hoe): walk the lanes between the rows, hoe 2–4 s, and after three rows carry the harvest to the barn door (a small gold sparkle through `Fx.burst`). A body mesh per shirt colour and one arm-and-hoe mesh, shared by every farm; a few sines a frame; drawn only within 72 blocks (`visibility_range_end`); they move only while this game's player is within 48 blocks (looked at 4 times a second); they decide where next only on arriving or finishing (every few seconds). Pure looks, seeded by index: not synced. |
| The director | `world/farm_director.gd` (`FarmDirector`, node `Farm` in the sandbox on every peer) | Host: places (`host_place`), upgrades (`host_upgrade`), moves (`host_move`), and at every world save `for_save(owner's feet)` writes the away record (and, signed in, starts the server's clock at most every 30 s); the welcome-back (`welcome_back`, at the world's start and on coming back from the background after 5 minutes) pays once, by the server's `farm_collect` when the record says the server was started and the phone is signed in, else by the device clock, then saves the world at once; the opt-in note is asked for on leaving inside and taken back on return. Every peer: the building from the host's state (`_rpc_state`, sent to a guest on `client_ready`, without the away record), the cheer (`_rpc_cheer`: a coin sound and a gold burst), the workers near this game's player. |
| Session | `autoloads/session.gd`, section `# --- M3 Task 10` (and one `elif` in `host_trade`) | `request_farm_place(anchor, facing)`, `request_farm_upgrade(kind)`, `request_farm_move()` (any peer → the host's signals `farm_place_requested`, `farm_upgrade_requested`, `farm_move_requested`); `farm_buy_refusal(peer, id)` (Tilly: only the owner, one per world, `farm_built`); `farm_pay_collected(gold)`: gold the server already paid into its wallet reaches the phone without being reported again, and the wallet marker moves with it. |
| Online service | `net/online_service.gd` (one function in agent F's farm section) | `farm_paid_on_phone(amount)` moves this device's wallet marker (`WalletSync`), so the wallet sync never sends farm gold the server paid a second time. |
| The panel | `ui/hud/farm_panel.gd` (`FarmPanel`) | A tap on the barn (whatever is in the hand): the farm as pictures and short words ("20 an hour", "Holds 12 hours", a little farmer per worker), the rule in one line, FASTER and BIGGER (fixed price; greyed with "have / need" while the gold is short; BEST! at the top) and MOVE for the owner, none for a guest ("This is the world owner's farm..."). The host's answer shows inside the panel. Closes with X, a tap outside, Back or walking 16 blocks away. |
| HUD | `ui/hud/hud.gd`, section `# --- M3 Task 10` | `add_farm_controls(director)` (Survivor worlds: the panel under the palette, a look-area blocker, the barn's tap), `open_farm` (closes the other overlays), `farm_welcome(gold)`: the banner "Your farm made 240 gold!" (the exact amount), the coin shower, the coin and fanfare sounds. No new HUD button. |
| The coin shower | `entities/fx/fx.gd`, section at the end | `Fx.coin_shower(parent, feet, gold)`: 12–48 coins (more gold, more coins) falling and spinning around the player; one cached coin mesh (a standing disc) with Fx's one shared material, so nothing compiles. |
| Taps | `entities/player/block_interactor.gd` (two lines in `place_at_screen`, section at the end) | The FARM item in the hand asks the host to place the farm (`_place_farm`); a tap on the barn emits `farm_tapped` (something standing in front of it takes the tap, like doors). |
| World | `scenes/sandbox.gd` (one line each in `_ready`, `_start_host_or_solo`, `_setup_local_player`, `save_world`, the Back handler; section at the end) | `_add_farm` (every peer), `_start_farm` (host: the save slot as the server's key, `save_world` for the welcome, the requests, `client_ready`, the welcome-back 1 s after the player stands in the world), `_setup_farm_local` (the workers follow this player; Survivor: the panel and the welcome). |
| Save | `world/world_meta.gd` (one line each in `from_json` and `to_json`, the field) | `WorldMeta.farm` (`{}` none; the farm with its away record; or `{packed, rate, cap}`), JSON key `farm`. |
| Profile | `core/save/profile_data.gd` | The setting `farm_note` (false) in `DEFAULT_SETTINGS`; `farm_note_at` (the last note asked for; one a day). |
| Settings | `ui/menus/settings_panel.gd` (one line in the toggles row, section at the end) | "Farm note" in the Show FPS / Vibration / Reduce motion row (the panel still fits 720 px). An under-13 child's tap opens the parent gate (`GrownUpGate`) first; the switch stays off until a grown-up passes it. |
| Fake server | `tests/fakes/fake_online_server.gd` | `farm_collect` now honours the universe and the cap and clamps like the real module. |
| Smoke run | `tools/farm_smoke.gd`, `tools/farm_smoke_steps.gd` | Below. |

No new assets: the barn, the workers, the coin, the icons and the farmer picture are drawn in code; the sounds
(`coin`, `fanfare`) already exist. Nothing to credit.

## Skills and patterns (godot-prompter)

- **save-load:** the farm is **JSON in `WorldMeta`** with a defensive `clean` (the project's way: a broken entry is
  no farm, levels clamped, a broken away record pays nothing) and the device-only note time in the profile.
  Rejected: a `Resource` (`.tres` saves run code) and a separate farm file (one more file to keep in step with
  the world's).
- **multiplayer-basics:** **host-authoritative requests** (`any_peer` RPCs on Session → the host's checks → the
  host's signals, like smart blocks) and the building from **one small reliable `call_local` state RPC** (sent
  again to a guest on `client_ready`). Rejected: a `MultiplayerSpawner` for the building (an upgrade or a move
  would mean despawning and spawning again) and syncing the workers (pure looks).
- **animation-system:** **code-driven procedural animation** (a few sines on shared meshes, like the blocky
  animals), running only near a player. Rejected: an `AnimationPlayer` per worker (a node and a process step each,
  always) and skeletal models.
- **particles-vfx:** **CPUParticles3D one-shot** with a cached mesh and **Fx's one long-lived material** (the
  emulator's GL renderer compiles a new material's shader in a 100+ ms frame; DEVELOPMENT.md §8). Rejected:
  `GPUParticles3D` with its own process material (a first-use compile) and a coin texture.
- **godot-ui:** a **Control overlay with containers and UiKit's theme** like the Totem panel (picture rows, big
  equal buttons, the answer inside). Rejected: toasts for the host's answers (hidden behind the panel; M2 Task 7's
  lesson) and a new always-visible HUD button (the brief).
- **mobile-development:** local notifications need an **Android plugin** (a manifest receiver, the
  POST_NOTIFICATIONS permission, a Gradle build): built as an **interface with a no-op and the plugin's
  contract**, like agent F's `AgeSignals`. Rejected: `JavaClassWrapper` + `AlarmManager` (nothing in the APK to
  post the note when the alarm fires with the game closed) and a half plugin.

## Tests (RED → GREEN)

Suite: **3561 → 3605** (the rules, the item, the save) **→ 3651** (the world, the HUD, taps, settings) **→ 3658**
(MOVE; a Sandbox HUD makes no farm panel),
`tests/run_tests.sh` through the PC's suite slots, exit 0, on a snapshot of each staged commit.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_farm_rules.gd` | 19 | `Identifier "FarmRules" not declared`; the move tests: `Static function "packed()" not found` |
| `tests/unit/test_farm_site.gd` | 9 | written before `FarmSite`, not run RED; mutation-checked (inside) |
| `tests/unit/test_farm_notify.gd` | 9 | written before the classes; the first run's one failure was the test's (it cancelled before reading) |
| `tests/unit/test_world_meta_farm.gd` | 5 | `Invalid access to property or key 'farm'` |
| `tests/unit/test_farm_item.gd` | 5 | `Cannot find member "FARM" in base "ItemIds"` |
| `tests/integration/test_farm_director.gd` | 23 | written before the director; its first run found three real bugs: the director started from the save's form (arrays, not a `Vector3i`), a guest's copy kept the away record, and a typed-array ternary in the building failed at run time |
| `tests/integration/test_farm_building.gd` | 7 | written before the building; the ternary above |
| `tests/integration/test_farm_panel.gd` | 8 | written before the panel; the move button: `farm_move_requested` missing |
| `tests/integration/test_farm_taps.gd` | 7 | the HUD opened the panel with the director's copy (none in the test) and closed it at once: now the tapped barn's farm; a Sandbox HUD made an unused panel that Android Back would stop at (visible before it was in the tree): now made in Survivor only, hidden from the start |
| `tests/integration/test_farm_settings.gd` | 5 | written with the switch |

**Found, not mine:** one full run (load about 25) failed M4 I's `test_visit_world.gd`
(`test_the_showcase_stands_on_the_island_with_the_friends_name_on_a_sign`: "where the showcase has air at the
bottom, the island's grass stays", after its 20 s wait); it passed alone (6/6) and in the next full run. A timing
flake under load, for the lead's list.

**Mutation checks** (each broken rule made its test fail, then was put back): the backwards-clock guard; a record
from before this session overwritten by the first save; the record not cleared after paying (paid twice); a
bigger "inside"; server-paid gold not moving the wallet marker; server-paid gold paid the reporting way; a
guest's panel with buttons; the barn's tap removed; a body in the barn not refusing the placement.

## Headless smoke run

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/farm_smoke.gd`

39 checks, all `ok` (`FARM_SMOKE done failed=0`, 2026-09-24, load 30–44; seeds 3524353366, 1630260915 and 2139949127): a new
Survivor world has its director
and Tilly; she sells a farm ("You got a Gold Farm!", 150 gold) and refuses a second ("You already have one!"); a
flat, open spot is found near her (the search waits up to 40 s for the ground to stream in: one run first looked
while only the spawn was loaded, 479 of 528 spots "not loaded", and found one a second later; `-- --smoke-seed=<n>`
repeats a world) and the FARM item placed there builds the barn with one worker ("Your Gold Farm
is ready! Stand on it..."); a player put in the barn stays on its floor (y 26.00, floor 26.05) and is inside;
the workers work; a tap on the barn finds it and opens its panel (20 an hour, Holds 12 hours); FASTER takes 200
gold and brings a second worker; leaving in the field is saved in `world.json`; after SAVE & QUIT and the away
record moved 3 hours back on disk, CONTINUE pays 90 gold ("Your farm made 90 gold!", one coin shower), saved at
once, the farm back with its two workers; a record 5 hours in the future pays nothing and takes nothing; MOVE
puts the farm back in the bag as `{packed, rate 1}`, the barn goes, and placing it again elsewhere keeps its
level and two workers. **Cost:** three workers' animation step 93–170 µs a frame at load 30–44 on this PC
(`FARM_SMOKE cost`), and only within 48 blocks of the farm; the building is one draw call plus the gold piles,
one static body.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The farm is a node, not voxels** (one shared mesh + one static body, like Tilly's stall and the Theater).
   Nobody can mine it for blocks (no block farm), break it or stamp over it, and "inside" is its footprint.
   *Cost:* it looks the same in both styles (vertex colours, like the stall); digging under it leaves it
   floating; blocks placed in the barn stay.
2. **Bought from Tilly as an item and placed like a stamp** (FARM 491 in her HOME section, 150 × 2^(u−1)); one per
   world (Tilly refuses a second while one stands or is picked up); only the world's owner buys, places, moves
   and upgrades it. *Cost:* a child must find flat, open ground (the refusal says so kindly).
3. **MOVE** (added beyond the brief): the owner can pick the farm up; the FARM item goes back into the bag and the
   farm keeps its levels; nothing is owed for that stay. A child who put it somewhere silly loses nothing (§6).
   *Cost:* a third button in the panel.
4. **Numbers:** 20 gold an hour, 12 h (the brief's 240 a night); FASTER 20 → 30 → 40 → 50 an hour for 200, 400,
   800; BIGGER 12 → 16 → 20 → 24 h for 150, 300, 600; all × 2^(u−1); workers 1, 2, 3, 3. The best farm makes
   1,200 a day in Green Meadows, as much as a cosmic tool. *Cost:* balance; the tables in `FarmRules`.
5. **"Inside" is anywhere over the 9 × 7 footprint** (barn, yard or field), from 1 below to 7 above the floor.
   *Cost:* standing next to it is outside.
6. **"Leaving" is every world save** with the owner's player inside (the minute's autosave, the pause menu, going
   to the background, closing, SAVE & QUIT); the record is the last save's time, so a force-closed game still
   pays from its last autosave. A record found when the world starts waits for the welcome-back and is never
   overwritten first. *Cost:* up to a minute of play counts as time away (the child's favour).
7. **The welcome-back comes at the world's start** (1 s after the player stands in the world) **and when the app
   comes back from the background after at least 5 minutes** (Android keeps apps alive for hours). *Cost:* a
   desktop window unfocused for 5+ minutes pays too (fair: the player was away).
8. **Online (signed in):** each save while inside also starts the server's clock (`farm_collect` "start", at most
   every 30 s; the reply marks the record `server` and saves the world's meta). On return, signed in and the
   record marked → `farm_collect` "collect" pays by the server's clock into its wallet, and the phone adds the same
   gold without reporting it (`Session.farm_pay_collected`, the wallet marker moved). Not signed in, the network
   failing or the server not knowing the stay → the device clock. The welcome waits up to 8 s for a sign-in in
   progress. *Cost:* offline returns use the phone's clock (accepted before launch by §5.6; a changed clock pays
   at most one full barn); if a collect's answer is lost, the device clock may pay the phone again later (rare).
9. **LAN and online guests:** the world's farm pays and grows for the world's owner only; guests see it, walk in
   it, see its panel without buttons. Each child's own farm lives in their own worlds. *Cost:* a guest earns
   nothing in a friend's world.
10. **The note is an interface, not a plugin (M5):** a note that rings with the game closed needs a manifest
    receiver (or a WorkManager worker), POST_NOTIFICATIONS (Android 13+) asked when the switch goes on, and a
    Gradle build, which the game's presets are not. `AndroidFarmNotifier` holds the plugin's contract. The switch
    ("Farm note") is in SETTINGS, off by default; an under-13 child needs the parent gate; the rules (never at night,
    once a day) are tested. *Cost:* until M5 builds the plugin, the switch does nothing on a phone (the lead may
    prefer to hide it until then: one line, `FarmNotifier.for_platform().is_available()`).
11. **The universe is the world's** (`Game.universe` = `WorldMeta.universe`, M3 Task 5): each universe's world has
    its own farm with its own levels and prices. *Cost:* upgrades don't carry between universes.
12. **Workers are looks, not synced:** every game animates its own from the same seed. *Cost:* two players may
    see a worker in different places.
13. **The FARM item is not in `ItemIds.ALL`** (no Sandbox palette row, no `/give`; `is_item` knows it).
    *Cost:* code that lists items from `ALL` won't see it (the Survivor palette lists what the bag holds).

## What to check on the emulator (lead)

1. New Survivor world (BLOCKY and REALISTIC): Tilly's HOME tab shows the Gold Farm card (barn icon, 150); buy it
   (a second is refused); the FARM item is in the owned palette; put it in a slot.
2. With FARM in the hand, tap flat ground in front of you: the barn, yard and field appear reaching away, the door
   facing you, one farmer hoeing; on a hill the refusal is kind ("Find flat, dry ground..."). Walk in through the
   door; the roof and walls hold; the camera inside is fine.
3. Tap the barn: the panel is centred, readable at 2400 × 1080, FASTER / BIGGER / MOVE / X big enough; FASTER with
   too little gold shows "have / need"; buying adds a farmer. MOVE puts it back in the bag; place it again.
4. Stand in the field, press the pause menu's SAVE & QUIT; change the emulator's clock forward 3 hours (or wait),
   CONTINUE: "Your farm made … gold!" with the coin shower, the counter bounces "+…", once. Background the app
   inside the farm for 5+ minutes: the welcome on return.
5. Frame time next to the farm with three workers (≥ 30 FPS, no frame over 100 ms), and the first coin shower
   compiles nothing (no 100+ ms frame).
6. LAN: a guest sees the farm and its workers, walks in, and gets a panel without buttons.
7. SETTINGS: "Farm note" fits the row; with an under-13 profile it asks for a grown-up first.

## Merge notes

Shared files touched with one-line hooks plus a section at the end: `autoloads/session.gd` (and one `elif` in
`host_trade`), `scenes/sandbox.gd`, `ui/hud/hud.gd`, `entities/player/block_interactor.gd`, `entities/fx/fx.gd`,
`world/world_meta.gd`, `core/save/profile_data.gd` (the settings default, one field, one parse line, one JSON
key), `ui/menus/settings_panel.gd`, `data/items/item_ids.gd`, `ui/hud/block_icons.gd`, `core/economy/shop_rules.gd`,
`ui/hud/shop_panel.gd` (`is_tool_item` → `one_only` on the owned mark), `net/online_service.gd` (one function),
`tests/fakes/fake_online_server.gd` (the farm). Item ids **491–494** are the farm's (491 used).
