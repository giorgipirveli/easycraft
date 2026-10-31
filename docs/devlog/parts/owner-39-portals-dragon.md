# Owner feedback #39: universe portals you build, and the Dragon Realm (universe 5)

The owner (2026-09-24 20:35): "please add portals in the game, when you enter into portals you move to different
universes like in minecraft, like dragon universe and others". Brief `docs/superpowers/briefs/prompt-own39.md`; spec
§14.2a (written first, with §5.1's table), M3 plan Task 26 and the Allocations (page 11, the cores' ids on page 10).
Built by a lead agent in its own worktree (cut from `lead-merge` at `27306da`: Frostpeak, Candy, the audio pass, pets,
rideable buddies, gadgets, blasters, the treasure pack, Monster Wave, crafting, the Gold Farm, the shop) with three
helper agents in worktrees of their own, merged into the lead's branch: the Dragon Realm's world (page 11, terrain,
secrets and nests, the descriptor, the ladder, the void rescue), its two monsters, and the Sky Dragon. No editor, no
emulator.

## Part 1: universe crystals and universe portals (the lead)

| Piece | Where | What it does |
|---|---|---|
| Crystal rules (pure) | `core/rules/crystal_rules.gd` (`CrystalRules`) | One crystal per universe (items 480 Meadows … 484 Dragon; 485-489 kept for universes 6-10) and its portal core block (212 meadows, 213 desert, 214 frost, 215 candy, 222 dragon); `owed(unlocked, given, gifts)`: every universe reached above the highest one handed over, then gifts; `given_after`; `clean_gifts` (≤ 20); Tilly's copies `for_sale_in(u)` / `base_price` (50 × 2^(u−1), crystals of universes 1..u); `sandbox_crystals(unlocked)`; each universe's swirl colours `swirl_colors(u)` |
| Items and blocks | `data/items/item_ids.gd` (`CRYSTAL_*`, `CRYSTALS`, in `ALL`), `data/blocks/block_ids.gd` (`CORE_*`, `COUNT` 223) | Crystals are items (a name, an icon, a hotbar slot); cores are blocks, not in `PLACEABLE` |
| Placing and breaking | `entities/player/block_interactor.gd` (one line), `core/survival/gather_rules.gd` (`drop`, `cost`) | A crystal in the hand places its universe's core; Survivor pays the crystal from the bag, and breaking a core gives the crystal back (the ledger's usual path, undo included) |
| Frames | `core/rules/portal_rules.gd` (`is_core`) | A frame ring's core slot takes the linking Portal Core or a universe core (the same ring rules) |
| A world's universe portals | `core/rules/portal_gates.gd` (`PortalGates`), `world/world_meta.gd` (`gates`, `arrival_gate`) | Cores with their universe, frame and exit, in placing order (≤ 32); `gate_to(u)`; saved, never failing to load |
| The director | `world/portal_director.gd` (section "Owner feedback #39") | Follows block changes (a core placed, swapped or broken), rechecks frames, swirls working universe portals in their universe's colours (the host's list carries the universe: `[lo, size, axis, universe]`), and a walk-in asks `travel` (solo) or says "You are here!" / "Travel works when you play alone." / the travel's refusal |
| Swirl colours | `entities/portal/portal_swirl.gd` (`material_for(u)`) | One shared `ShaderMaterial` per universe with the same shader (no new compile; only the uniforms differ) |
| The portal back | `core/rules/return_gate.gd` (`ReturnGate`) | `arrival(gates, u)`: in front of the world's own portal to u; else `plan(feet, yaw, u)`: a whole 1 × 2 frame with u's core 3 blocks in front of the child, its doorway and a cell on each side cleared, never the child's own cells |
| Travel | `scenes/sandbox.gd` (section "Owner feedback #39") | `travel_through_gate(u)`: M3 Task 5's refusals, the Plus rule (`Session.shop_travel_refusal`), then Survivor: `_travel(u, true)` (the bag and hotbar come along) or Sandbox: `_travel_sandbox(u)` (universe u's own Sandbox world, `sandbox_<u>`, the hotbar comes along); the destination records `arrival_gate`; on arrival `_arrive_through_gate` puts the child in front of the world's portal back, or `_build_gate_back` builds one in front of them once they stand there (host edits: no undo step, nothing paid) |
| Crystals handed over | `scenes/sandbox.gd` (`_hand_over_crystals`), `core/save/profile_data.gd` (`crystals_given`, `crystal_gifts`), `core/save/profile_backup.gd` | In the child's own Survivor world (host or solo), once they stand there: the crystals of every universe reached (and gifts) into the bag, said once ("You got the Desert Crystal! Put it in a portal frame's bottom row."); the backup never hands one twice |
| A Sandbox world per universe | `core/rules/mode_rules.gd` (`slot`: `sandbox_<u>`, universe 1 keeps `sandbox_1`; `world_universe`), `core/rules/universe_rules.gd` (`scale_universe`: Sandbox never scales; `sandbox_arrival_meta`), `autoloads/game.gd` (every mode keeps its universe) | The sandbox reads `Game.universe` for terrain, sky, music, weather, gentle monsters of that universe; the monsters' and drops' scale is 1 in Sandbox |
| Menu | `ui/menus/menu.gd` (section "Owner feedback #39") | SANDBOX shows a picture card per Sandbox world once a portal made a second one ("Choose a Sandbox world"), each with CONTINUE / NEW WORLD ("Frostpeak Sandbox") |
| Palette | `ui/hud/block_palette.gd` (the SMART page's PORTALS row) | A Portal Frame and the crystal of every universe reached (Sandbox); Survivor's owned view shows crystals in the bag like everything |
| Tilly | `core/economy/shop_rules.gd` | HOME lists the crystals of universes 1..u at 50 × 2^(u−1); she never buys them |
| Icons, tiles | `ui/universe/crystal_icons.gd` (`CrystalIcons`, drawn in code), `data/blocks/portal_page.gd` (`CORE_TILES`), `tools/make_portal_page.gd` + `.py` | Page 10's tiles (0..7, 1) and (4, 3)/(5, 3), drawn last with their own seed: every earlier tile byte-identical in both styles (checked tile by tile) |

## Part 2: the pet dragon, dragon eggs, the baby dragon (the lead)

| Piece | Where | What it does |
|---|---|---|
| The kind | `core/rules/pet_rules.gd` (`DRAGON`, perk `GLIDE`, section "Owner feedback #39") | Given, never wild, never takes a pet place, favourite treat the fish snack; `glides(on_floor, owner_on_floor, owner_above)`, `glide_spot` (to the child's right, a little up and back), `glide_velocity` (≤ 14 m/s), `baby_dragon_record`, `give_baby_dragon` (once; a named one is never renamed) |
| The body | `core/rules/animal_rules.gd` (`dragon`: weight 0, `flies`), `entities/animal/blocky_animal.gd` (boxes: teal scales, a violet belly and wings that bob, little horns, a tail; a collar round the neck), `core/mind/species/animal_species.gd`, `core/rules/voice_rules.gd`, `autoloads/audio.gd` (`chirp`) | Chirps made by `tools/make_dragon_pet_sfx.py` (original) |
| Gliding | `entities/animal/animal.gd` (section "Owner feedback #39", one hook in `_physics_process`) | Host: a pet of a flying species takes off when its child is more than 1.5 blocks up in the air above it, flies beside them and lands when they land; "in the air" is read from the blocks under the child's feet (a guest's body is not simulated on the host) |
| Eggs | `entities/interactables/dragon_egg.gd` (`DragonEgg`, a secret thing), `world/dragon_nests.gd` (`DragonNests`, node "DragonNests"), `world/secret_director.gd` (spawns the egg of a nest whose egg has not hatched), `autoloads/session.gd` (section "Owner 39": `request_hatch`) | A tap within reach hatches the egg once per world (`SecretState.opened["egg_<secret>"]`): the crack and sparkle on every game, the tapper's pet dragon (id `dragon_<secret>`, saved with the world's pets), "A baby dragon hatched! … It flies with you!", the adventure board's tamed event |
| The baby dragon | `core/save/profile_data.gd` (`baby_dragon`), `world/pet_director.gd` (section "Owner feedback #39"), `autoloads/session.gd` (`pet_request_baby_dragon`, `boss_give_dragon`, `dragon_gift_apply`) | Lives in the profile like Pip, comes into every world (`babydragon_<peer>`), never saved with a world, goes home with a guest; beating the Sky Dragon gives every player a baby dragon (once) and a Dragon Crystal |

## Part 3: the Dragon Realm, its monsters and the Sky Dragon (three helper agents, merged here)

| Part | Branch and notes | What it is |
|---|---|---|
| The realm's world | `worktree-agent-a99c950600aa93273` (`e0b246e`); `docs/devlog/parts/owner-39-dragon-world.md` | Block page 11 (224-238, both styles), `DragonShape` / `DragonGenerator` (a home island round the spawn, floating islands over a starry void, clouds, crystal spires, glowing mushrooms, ores by depth; cheaper per chunk than Green Meadows), `DragonSecretRules` (five kinds on islands; dragon nests with an `egg` cell on a nest block), the treasure pack's DRAGON style, `world/universes/dragon.gd`, the ladder of five (candy → dragon → hub), arena palette 5, the void rescue (`DragonRules`, `Player.carry_back`, the host's `VoidWatch`), `tools/dragon_smoke.gd` |
| The realm's monsters | `worktree-agent-af5322484dbe433d0`; its notes file | Shadow bats and wisp spirits (`MonsterRules.DRAGON_KINDS`) |
| The Sky Dragon | `worktree-agent-aeb8e3d2df0e92608` (`abf91f0`); `docs/devlog/parts/owner-39-sky-dragon.md` | `SkyDragonRules`, `SkyDragon` (a `StoneGolem` to the BossDirector), `SkyDragonTower`, signalled dives along a line on the ground, crystal towers that heal it until broken, team scaling and honest help; Monster Wave's raid boss in universe 5, `/summon skydragon` |

The lead's wiring at the merges: `dragon.gd`'s `boss_kind` is the Sky Dragon and its `monster_kinds` the realm's two;
`BossDirector._earn_boss_items` gives every player a baby dragon (once) and a Dragon Crystal when the Sky Dragon is
beaten (`Session.boss_give_dragon`; `test_a_win_gives_a_baby_dragon_and_a_dragon_crystal`, mutation-checked); the
Dragon Realm smoke run also hatches the nearest nest's egg into the child's pet dragon on real terrain; `/universe`
knows universe 5 (and "დრაკონი"); the hub panel fits five universes (RED: 1288 px > 1280 with five cards, then
`test_the_hub_panel_fits_five_universes_on_a_1280_screen`). Merge conflicts: `voice_rules.gd` (main's own fix of the
pets' voices came in with the helpers' base, kept with the dragon's chirp), `block_ids.gd` (both sections, `COUNT`
240), `sandbox.gd` (both sections), `DEVELOPMENT.md` (both).

## Tests (RED → GREEN)

Suite before: **4500 of 4502** on the merged `lead-merge` (the two failures were already there: `test_voice_rules`
and `test_animal_voices` — M3 Task 11's fox, parrot and Pip had no hurt voice after the audio pass; fixed here in
`VoiceRules._HURT`).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_crystal_rules.gd` | 8 | run before the code: "Identifier CrystalRules not declared" |
| `tests/unit/test_portal_gates.gd` | 7 | written before `PortalGates` and `PortalRules.is_core`; first run with them: green |
| `tests/unit/test_return_gate.gd` | 4 | written before `ReturnGate`; first run: green; the smoke run then found the walled-in exit (a test case can't see a dune), so the plan clears both sides |
| `tests/integration/test_universe_gates.gd` | 8 | written before the director's section; first run: green (the old `test_portal_frames.gd` and `test_portal_rules.gd` stay green) |
| `tests/unit/test_portal_saves.gd` | 6 | written before the save fields; first run: green |
| `tests/integration/test_portal_crystals_ui.gd` | 4 | written before the PORTALS row and the menu's Sandbox cards; first run: green |
| `tests/unit/test_dragon_pet_rules.gd` | 5 | written before `PetRules.DRAGON`; first run: green |
| `tests/integration/test_pet_dragon.gd` | 9 | written before `DragonNests`, `DragonEgg`, `on_baby_dragon`, `dragon_gift_apply`; first run: green. Mutation-checked: with the glide hook in `Animal._physics_process` switched off, the take-off test fails (1 of 9), restored |
| Changed | | `test_universe_rules.gd` (a Sandbox world per universe; Sandbox never scales), `test_universe_world.gd` (the slot follows the universe in Sandbox too), `test_block_palette.gd`, `test_palette_smart.gd`, `test_counted_hotbar.gd` and `test_item_ids.gd` (the PORTALS row: the crystals of the universes reached), `test_voice_rules.gd` (the dragon is an animal now: `griffin` is the unknown one) |

**Suite: 4500 of 4502 before → 4708 of 4708 after** (everything merged: the portals, the pet dragon, the realm's world,
its monsters and the Sky Dragon; `tests/suite_slots.sh tests/run_tests.sh` on a snapshot of `08f4861`, exit 0; 485
scripts). On the way: 4672 of 4672 with the world and the Sky Dragon merged. Smoke runs on the final tree:
`tools/dragon_smoke.gd` 28 checks ok (the nest's egg hatched into the child's pet dragon), `tools/portals_smoke.gd` 19
checks ok.

First full suite of part 1 (load ~30): 4537 of 4540; `test_item_ids` and `test_counted_hotbar` counted the palette's
rows without the crystals (fixed above), and `test_visit_world`'s "the island's grass stays" read an unloaded cell
(0) — it passed alone (26 of 26 with the other two): load-dependent, not this task's code.

**Found and fixed:** `Game.start_world` forced every non-Survivor world to universe 1, so Monster Wave's arena cards
and NEXT UNIVERSE always opened universe 1's arena (`wave_1`), whatever universe was picked (its tests set
`Game.universe` directly, so none saw it). Every mode now keeps its universe (`ModeRules.world_universe`), which a
Sandbox world per universe needs too (`test_sandbox_never_scales_and_every_mode_keeps_its_universe`).

The runner: `tests/run_tests.sh -gtest=<files>` ran the **whole** suite (it always passed `-gdir`, and GUT runs both),
without the slot gate; now `-gtest` leaves the directories out, so it runs only the named files.

## Headless smoke run: `tools/portals_smoke.gd`

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/portals_smoke.gd`

2026-09-25 03:0x, load ~5: **all 19 checks ok, exit 0** (again after merging the Dragon Realm, 04:2x, load ~28). A new Sandbox world of Green Meadows: a frame built with the
host's edits and the Desert Crystal's core placed through `Session.request_set_block` make a universe portal that
swirls in the desert's colours; walking in opens `sandbox_2` (the desert's terrain, monsters at scale 1), where a portal
back to Green Meadows stands 3.0 blocks in front of the child with the Meadows Crystal's core; walking into it comes out
0.00 from the first portal's exit (not at the spawn). Then a new Survivor world: the two crystals of the universes
reached are in the bag (once), placing the desert's core uses the Desert Crystal, walking in travels to `survivor_u2`
with the bag (a cosmic sword), and its portal back stands there. (The first run failed one check: the portal back was
built facing into a dune and its exit was walled in — the plan now clears a cell on each side of the doorway.)

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Crystals are items, cores are blocks** (a crystal placed turns into its universe's core, the core breaks into the
   crystal): the hotbar shows a gem, the world a glowing core, and M3 Task 5's frame rules are reused whole. *Cost if
   wrong:* none known; a crystal could become a block later by changing `core_for_item`.
2. **Core ids 212-215 and 222 on page 10** (the free ids after 210-211, 216, 217-219 and 220-221; 223 left free); the
   dragon's core at 222 because 212-215 fill the four before it. Tiles by the page's rule, two per id at 2 × (id − 208).
3. **Earning:** every universe the profile opened (`universe_unlocked`, raised by bosses in Monster Wave and by the old
   Survivor bosses) gives its crystal once, into the bag of the child's own Survivor world (host or solo, not a guest's
   visit: a guest's bag is the host's world's). Green Meadows' crystal comes to every child. Tilly sells copies of the
   crystals of universes 1..u at 50 × 2^(u−1) in universe u (never bought back: no gold loop). *Cost if wrong:* a
   child who plays only Sandbox never has a Survivor crystal (Sandbox's palette has them free).
4. **A universe portal needs no partner** and leads to its core's universe; a portal to the universe you are in says
   "You are here!". In Sandbox it leads to **that universe's Sandbox world** (`sandbox_<u>`; `sandbox_1` stays M1's, so
   old saves keep working); the Plus rule of §18.3 applies there too (a Plus universe is a place to explore, whatever
   the mode). *Cost if wrong:* if the owner wants Sandbox universes free, drop one call in `travel_through_gate`.
5. **Sandbox worlds never scale** (`UniverseRules.scale_universe`): monsters there are the universe's own kinds, gentle
   and at scale 1; Survivor and Monster Wave scale as before.
6. **The portal back:** the arrival is in front of the destination's own portal to where the child came from (the
   first working one), else the host builds one 3 blocks in front of the child (frames and the core, its doorway and a
   cell on each side cleared) — no undo step and nothing paid, so a child can always go home. Survivor's stone-circle
   travel keeps M3 Task 5's arrival by the spawn. *Cost if wrong:* a built portal back cuts a small hole in a hill.
7. **Solo only**, as M3 Task 5: a guest or a host with guests hears "Travel works when you play alone.".
8. **The SANDBOX menu** keeps its old screen until a second Sandbox world exists, then shows a card per world.
9. **The pet dragon is given, never wild** (an egg or the Sky Dragon), never takes one of the three pet places, never
   fights (no perk hurts anyone); it glides beside its child when they are more than 1.5 blocks up in the air, at most
   14 m/s. A hatched dragon belongs to its world (saved with the world's pets); the Sky Dragon's baby dragon to the
   profile (like Pip, it comes into every world). *Cost if wrong:* the egg's dragon could move into the profile too.
10. **An egg hatches once per world** (`SecretState.opened`), for whoever taps it within reach.
11. **The Sky Dragon's gifts** go to every player's own profile when it is beaten in Monster Wave (Survivor has no
    boss since #44; Sandbox's `/summon skydragon` gives nothing, like every Sandbox boss): a baby dragon once, a Dragon
    Crystal every win (handed into the bag in the child's own Survivor world). *Cost if wrong:* one line in
    `BossDirector._earn_boss_items`.
12. **Left as it is:** after the Dragon Realm's raid boss (the last universe), Monster Wave's panel still offers STAY
    with "The next universe is coming soon!" (the ArenaDirector's words, as after the Candy Kingdom before). The
    helpers' own rulings are in their notes (the world's 6, the monsters' 8, the Sky Dragon's 7).

## What the lead should check on the emulator

1. **Crystals:** a Survivor world of a profile with `universe_unlocked` 2+: "You got … crystals!" once; the crystals in
   the palette's owned view with their gem icons; Tilly's HOME sells them (50, 100 … gold); the Sandbox palette's SMART
   page has the PORTALS row (a frame and the crystals of the universes reached).
2. **A universe portal:** a 1 × 2 frame of Portal Frames with a crystal placed in its bottom-middle: the core glows in
   the universe's colours (both styles), the doorway swirls in them (not the purple of a linked pair); walking in
   travels with a whoosh (Sandbox: "Sandstorm Desert Sandbox" world; Survivor: the desert's world, bag and all).
3. **The portal back:** it stands 3 blocks in front of the arriving child (it cuts a small hole in a hill or a dune if
   it must), with the crystal core of where they came from; walking in brings them out in front of the first portal.
   A portal to "here" says "You are here!"; with a LAN guest, "Travel works when you play alone.".
4. **SANDBOX menu** after a trip: "Choose a Sandbox world" with a card per world; each card's CONTINUE / NEW WORLD
   ("Frostpeak Sandbox").
5. **Plus:** with the pretend store on (debug), a Frostpeak/Candy/Dragon crystal portal says the EasyCraft Plus line once.
6. **The pet dragon:** in the Dragon Realm, a nest's egg rocks and glows; a tap within reach cracks it (sound and
   sparkles) and a little teal dragon follows; when the child flies or glides (or jumps off a high edge) it flies
   beside them, wings bobbing, and lands when they land; the pet card (tap it): name, collar, SIT. After beating the
   Sky Dragon in Monster Wave: "You got a baby dragon and a Dragon Crystal!", and the baby dragon comes into every
   world next to the child.
7. **The five-universe screens:** the stone circle's hub panel, the SURVIVOR hub and MONSTER WAVE cards fit a 16:9
   phone and the 20:9 emulator.
8. **Performance:** a world with a few universe portals (one swirl material per universe, no new shader compile at
   the first sight of a coloured swirl: the swirl shader is prewarmed); a gliding dragon over the void.
