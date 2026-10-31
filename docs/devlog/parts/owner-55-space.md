# Owner feedback #55: space — the Moon and the planets

The owner (2026-09-28): "when i fly up to sky, i should be able to lend on moon and other planets where there is
different and new worlds". Spec §21, plan `docs/superpowers/plans/2026-09-28-space.md`. Built by a worker agent in its
own worktree (branch `worktree-agent-a5302402758eb8b7b`, fast-forwarded to `lead-merge` 6535ebf before starting), without
the editor, the emulator or a browser. Another agent changed the JUMP/fly input on the player (owner #54) at the same
time: nothing here reads that input or edits `entities/player/player.gd` — the space line watches the player's position.

## Allocations (nobody else added blocks meanwhile)

| What | Allocated | Used | Free |
|---|---|---|---|
| World numbers | 16-20 (`SpaceRules.FIRST..LAST`) | 16 The Moon, 17 Planet Boing, 18 Rainbow Planet | 19-20 (more planets) |
| Block ids, page 15 (the Moon, `MoonBlocks`) | 288-303 | 288-298 | 299-303 |
| Block ids, page 16 (Planet Boing, `BoingBlocks`) | 304-319 | 304-312 | 313-319 |
| Block ids, page 17 (Rainbow Planet, `RainbowBlocks`) | 320-335 | 320-330 | 331-335 |
| `BlockIds.COUNT` | 276 → 331 | | |
| Atlas pages | 15, 16, 17 (`data/blocks/pages/moon*.png`, `boing*.png`, `rainbow*.png`) | rows 0-1 of each | rows 2-7 |
| Item ids | none | | |
| Animal kinds | `moon_bunny` | | |
| HUD spots | none (the picker is a full-screen panel under the pause menu) | | |

## What a child experiences

1. **Fly up** anywhere flying works (Sandbox free; Survivor pays its usual fly gold). Above y 160 the sky darkens and the
   stars come out even at noon; at y 180 "Keep flying up! Space is up there!".
2. **Space:** crossing y 200 the game holds still (played alone) and "Where shall we land?" shows three big picture cards
   over a starry sky with their own planet round and big below: **The Moon**, **Planet Boing**, **Rainbow Planet**, and
   **STAY HERE** (back under the line, flying on).
3. **Landing:** a card flies there — a whoosh, a puff of dust, the words ("You landed on the Moon! Jump: you float!") — on
   the world's **landing pad** (a teal disc with a golden star at its spawn), with a golden **portal home** (owner #39's
   universe portal, the home universe's swirl) built three steps in front. MY MAP shows the pad.
4. **Exploring:** each world is endless, with its own ground, sky, gravity, light, music, sounds, animals, secrets (the
   Secret Book counts them) and a landmark a short walk from the pad (MY MAP marks it once found).
5. **Home:** walk into the portal, or fly up again and tap **HOME** (the first card from a space world). Home lands the
   child on the ground where they took off, walking: "Welcome home!". From one planet a child can also hop to another; the
   way home stays the first home's.

## The new worlds

| # | World | Ground, sky, light | Gravity | Landmark and secrets | Animals | Music, sounds |
|---|---|---|---|---|---|---|
| 16 | **The Moon** | silvery moon dust (2 deep) over moon rock; gentle swells and round craters with raised rims; glowing pale-blue moon crystals mostly in the craters; a black starry sky all day with the blue-green home planet hanging in it; the sun as bright as ever | 0.35: a jump goes ~4.8 blocks (1.7 at home) and floats down | **the Moon Base**: a silver dome with round portholes, a ceiling light and an antenna, its door toward the pad, a golden chest inside (walk in: "You found the Moon Base!"); buried treasure under an X of crystals, hidden **cheese** rooms behind fake moon rock ("the Moon IS made of cheese"), a silver star temple with star gold on top, moon-crystal geodes | **moon bunnies** (new: silver-white, long pale-blue ears, big floaty hops; they love moon cheese and crystals) | Moonlight Sonata, Gymnopédie; wind chimes |
| 17 | **Planet Boing** | rolling lime **boing moss** hills over teal soil and purple rock; flat pink **jelly** pools in the dips; spring mushrooms (white stalk, wide orange cap); a violet sky with a golden **ringed planet** | 0.6 | **the Boing Tower**: four bouncy spring-cap pads spiralling up a stalk to a brick platform with glowing bulbs and a golden chest (reach the top: "You reached the top of the Boing Tower!"); the book's kinds in its blocks (a spring-cap X, a lilac temple, glowing geodes) | frogs (by the pools) and goats (on the hills) | Eine kleine Nachtmusik, Spring; a babbling brook |
| 18 | **Rainbow Planet** | terraced hills (flat steps, one block each) of rock striped red, orange, yellow, green, blue and violet by height, pastel prism grass on top; clear prism crystal spires with rainbow edges; a lilac sky with a pink planet | 0.8 | **the Rainbow Arch**: six rainbow rings on the terraces facing the pad, a flight of prism-brick steps up to the golden chest on its top; rooms behind a fake blue stripe, a white prism temple, prism geodes | candy birds (by the spires) and horses | Waltz of the Flowers, Morning Mood; wind chimes |

- **Bouncy:** boing moss, jelly and spring caps throw a landing child back up (the Candy Kingdom's gumdrop rule, 75 % of the
  landing speed, lower each time; `CandyRules.is_gumdrop` ← `BoingBlocks.BOUNCY`).
- **Peaceful:** no monster comes by itself in space (the Sandbox Totem and `/summon` still work).
- **Tilly** (Survivor) sells each world's own blocks and the landing pad, never star gold; prices as at home.
- Every world has its own picture card (`UniverseArt` 16-18: the Moon Base on dust under the home planet, a spring
  mushroom and the tower's pads over a jelly pool under a ringed planet, the rainbow arch on striped terraces) and loading
  hints ("On the Moon you jump high and float down!", "Jump on the moss and jelly. Boing!", "Climb the steps up the
  Rainbow Arch!", …).

## How it plugs in (no parallel system)

A space world is a universe descriptor (`world/universes/moon.gd`, `boing.gd`, `rainbow.gd`) that `UniverseRegistry`
finds through its `SPACE` table beside the `LADDER`; `available()` and `size()` stay the ladder's, so the SURVIVOR hub,
Monster Wave, the Sandbox world cards, `/universe` and Plus never list them. Everything else is the universe machinery:
`Game.universe`, `ModeRules.slot` (`sandbox_16`, `survivor_u17`), `WorldService.setup(…, u)` (the descriptor's shape and
generator), the sky palette and music, the animals, the secrets and their words, `LoadingCard`, the portal home (owner
#39's `arrival_gate` / `ReturnGate`), `travel_through_gate` for the way home, MY MAP's `PlacesDirector.mark`, the Secret
Book's per-universe page. Details: `docs/DEVELOPMENT.md` §4 "Space" and §5 "Space: the Moon and the planets".

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The space line is y 200** (8 above the highest block; ~18 s of real flying from the meadows' ground at 11 m/s), the
   sky turns from y 160, the hint at 180, re-armed under 190; STAY HERE puts the flyer at 186. *Cost:* constants in
   `SpaceRules`.
2. **Survivor reaches space the same way (paid flying)** — no rocket, no Dragon Realm gate: the owner said "when i fly
   up"; flying already costs gold in Survivor, and a gate behind universe 5 would put space behind EasyCraft Plus. *Cost:*
   one check in `SpaceRules.may_launch`.
3. **Space worlds are free and never scaled** (gold, prices, flying, loot as in Green Meadows: `SpaceRules.scaling` in
   `UniverseRules.scale`, `LootRules`, `TreasureRules`, `TreasureLoot`; `ShopCatalog.needs_plus` false). *Cost:* one line
   each.
4. **Numbers 16-18**, off the ladder (6-15 stay §5.1's Glow Caves, Neon City, Lava Core and the remixes). *Cost:* a
   renumbering needs a save migration (worlds are saved per number).
5. **Peaceful:** no night monsters in space. *Cost:* the descriptors' `peaceful`.
6. **Home lands on the take-off column** (`WorldMeta.space_return`, walking); the portal home stands by the pad (built at
   the first landing, owner #39's way). *Cost:* none known.
7. **The menus list only the ladder's worlds**; a space world is reached by flying (Save & Quit on the Moon keeps it;
   SANDBOX in the menu opens home, landing on the take-off column; flying up again finds the Moon as it was). *Cost:* a
   SANDBOX/SURVIVOR card for space worlds later.
8. **Gravity is the world's** (`LabRules.world_gravity`, set by the world scene, × the lab's own: the lab's Moon on the
   Moon is 0.35 × 0.35): the player's jumps, falls and glides; animals and monsters keep their own hops (the moon bunny's
   `walk_hop` is extra floaty instead). *Cost:* animals' gravity if they should float too.
9. **The space moment holds a solo game still** (the tree pauses while the picker shows, so a flyer does not keep
   climbing or paying); with friends it goes on and a card says "Space trips work when you play alone." (like universe
   travel). *Cost:* none.
10. **One class for all three planets** (`SpaceShape`, `SpaceGenerator` with `planet`), not three shapes: the pad, the
    features, the stack cache and the tests are shared. *Cost:* a fourth planet adds a `match` arm per method.
11. **The landmark is the world's one ISLAND secret** (like the Dragon Realm's nests), 44-56 blocks from the pad, the
    Secret Book counting it; no sky islands, no treasure pack, no mouse villages in space (their Meadows look would
    clash). *Cost:* two flags in `SpaceSecretRules._init`.
12. **No caves, no water in space**; ores (coal to diamond, OreRules' bands) only in the planet's rock (Rainbow: the
    stripes). *Cost:* caves later cost a generator pass (bench it).
13. **The moon bunny squeaks with the rabbits' recordings** at the rabbits' measured level (−2 dB); frogs, goats, candy
    birds and horses visit the planets with their own voices. *Cost:* a recording of its own if it sounds too plain.
14. **Tilly's crystals on a planet:** her HOME section sells the universe crystals up to the world's number (16 ≥ 5: all
    five); travelling through one still checks the unlock and Plus. *Cost:* one line in `CrystalRules.for_sale_in` if only
    the home's should show.
15. **A tracked `.pyc`:** `tools/__pycache__/make_realistic_atlas.cpython-314.pyc` is in git; the space tool is run with
    `PYTHONDONTWRITEBYTECODE=1` so it stays unchanged. *Cost:* none.

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_space_rules.gd` | 18 | `SpaceRules` not declared |
| `tests/unit/test_space_registry.gd` | 8 | `SpaceRules` / `UniverseRegistry.is_space` missing |
| `tests/integration/test_space_sky.gd` | 5 | `SkyCycle.set_space_climb` missing |
| `tests/integration/test_space_panel.gd` | 8 | `SpacePanel` not declared; then the HOME card of a Plus universe was locked (→ `UniverseCard.as_home`) |
| `tests/integration/test_space_director.gd` | 11 | `SpaceDirector` not declared |
| `tests/integration/test_space_trip.gd` | 3 | written with `SpaceTrip` (the sandbox's saves); step b moved it from a stand-in Moon to the real one |
| `tests/unit/test_moon_blocks.gd` | 8 | `MoonBlocks` not declared |
| `tests/unit/test_space_shape.gd` | 12 | `SpaceShape` not declared; Boing/Rainbow: `SpaceShape.BOING` missing |
| `tests/unit/test_space_generator.gd` | 6 | `SpaceGenerator` not declared (then all three planets bit-identical to the reference) |
| `tests/unit/test_space_secrets.gd` | 5 | `SpaceSecretRules` not declared |
| `tests/unit/test_moon_universe.gd` | 6 | no `moon.gd`, no moon bunny |
| `tests/integration/test_moon_world.gd` | 3 | written with `moon.gd` |
| `tests/unit/test_planet_blocks.gd` | 6 | `BoingBlocks` / `RainbowBlocks` not declared |
| `tests/unit/test_planet_universes.gd` | 6 | no `boing.gd` / `rainbow.gd` |
| Changed | `test_loading_hints` (a hint over ten words, shortened), every animal-table test (the moon bunny passes them) | |

Full suite (`tests/run_tests.sh`, 2026-09-28 ~03:00, load ~15-20): **6206 tests, 6203 passing, 1 failing, 2 risky** (the two that never assert), 679 scripts, no script errors. The one failure is not this work's: `test_boot_splash.gd` `test_every_android_preset_carries_the_splash` wants every preset's `export_filter` to be `all_resources`, and M7's "Web Music" preset (`preset.8`, `5b90641`) exports `resources` (the lead's call: skip the Web Music pack in that test, or keep the splash in it).

Smoke run (`tools/space_smoke.gd`, seed 12345): **34 checks, 0 fails** — see "The lead's checklist" for what it covers.

## Measurements

Generator (`bench_generator.gd -- --space`, 640 chunks per planet, alternating with Green Meadows, load ~10 on 24 cores):

| chunks | Meadows avg ms | Moon | Boing | Rainbow |
|---|---|---|---|---|
| surface, warm (stacks cached) | 1.51-1.53 | 1.01 | 1.03 | 1.33 |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.63-1.71 | 1.50 | 1.14 | 1.48 |
| underground | 1.09-1.21 | 0.24 | 0.23 | 0.24 |
| sky (y 80+) | 0.76-0.81 | 0.01 | 0.01 | 0.01 |
| all, cold | 1.34-1.42 | 0.85 | 0.66 | 0.84 |
| a new area's secrets (once, then cached) | — | 0.53 (worst 1.19) | 0.20 | 0.23 |

Every planet is cheaper than Green Meadows on average. The first version of the Moon was 3× slower (4.90 ms per surface
chunk): each column summed its 9 neighbouring crater cells through a Dictionary per cell, and sky chunks worked out every
column's height. Now a chunk stack's grounds and features are worked out once (`SpaceGenerator._stack`, 1024 stacks) with
the stack's craters listed once (`SpaceShape._craters_near`), summed in the reference's order so the heights stay
bit-identical (`test_chunks_match_the_reference_block_rule`, all three planets). Worst single chunks: the Moon 12-15 ms
(the chunk with the Moon Base's boxes, on a worker thread), Meadows 5-10 ms.

FPS on the emulator: not measured here (no emulator for agents). What costs frame time on the main thread: the sky's
climb re-lights the sky in 0.05 steps (≤ 20 refreshes on the way up; the sky already refreshes once a second), the
picker is a 2D panel (`_draw` of 140 stars and a circle) shown once, the planet in a space world's sky is one billboard
quad with a 96 px texture made once.

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up (FLY or the new double-tap from owner #54). From y 160 the sky darkens, the stars show at
   noon; "Keep flying up!" at 180; at 200 the picker shows and the world stops. Do the cards fit (three 236 px cards)? Is
   the planet at the bottom pleasant in BLOCKY and REALISTIC? STAY HERE: the flyer is put back at 186 and flies on.
2. Tap THE MOON: the loading card shows the Moon's scene; landing on the teal pad with the star, the words, a puff; the
   portal home three steps ahead (golden, the meadows' swirl). The black sky with the blue-green planet by day, the stars;
   the REALISTIC photo sky is dimmed to near black (`SPACE_SKY_ENERGY`): acceptable?
3. Jump on the Moon: big floaty jumps (double jump high!). Walk to the Moon Base (MY MAP shows the pad; the base appears
   there once found). Moon bunnies hop around; feed one a moon crystal.
4. Fly up on the Moon: HOME first. Home lands where you took off, on the ground, "Welcome home!".
5. Planet Boing: bounce on the moss (every landing from a fall bounces: fun or annoying?), jelly pools, spring
   mushrooms, the Boing Tower's pads up to the chest. Rainbow Planet: the striped terraces, prism spires, climb the arch.
6. Survivor: flying up costs gold as always; the bag goes to the planet and comes home (portal or HOME).
7. Performance: the autopilot's flight over a planet (`--survivor --new-world --universe=16/17/18`), ≥ 30 FPS and no frame
   over 100 ms; the first frames on a planet compile three new page materials (like any new universe).
8. With a LAN guest: the guest's picker says "Space trips work when you play alone."

## Merge notes (for the lead)

- New: `core/rules/space_rules.gd`, `world/space_director.gd`, `world/space_trip.gd`, `ui/space/space_panel.gd`,
  `world/generators/space_shape.gd`, `space_generator.gd`, `space_secret_rules.gd`, `world/universes/moon.gd`, `boing.gd`,
  `rainbow.gd`, `moon_blocks.gd`, `boing_blocks.gd`, `rainbow_blocks.gd`, `data/blocks/pages/{moon,boing,rainbow}*.png`
  (+ imports), `tools/make_space_atlas.gd`, `make_space_realistic.py`, `copy_page_import.py`, `space_smoke.gd` (+ steps),
  14 test files.
- Shared, small and additive: `data/blocks/block_ids.gd` (ids, `COUNT` 331, `SPACE_GROUND`, names),
  `world/block_library.gd` (three register lines), `world/universes/universe_registry.gd` (`SPACE` table, `path_for`,
  `display_name`, `card_colors`, a section at the end), `world/world_meta.gd` (`space_home`, `space_return`),
  `world/sky_cycle.gd` (two lines in `refresh`, a section at the end), `core/rules/lab_rules.gd` (`world_gravity`),
  `core/rules/universe_rules.gd`, `loot_rules.gd`, `treasure_rules.gd`, `treasure_loot.gd` (`SpaceRules.scaling`),
  `core/shop/shop_catalog.gd` (`needs_plus`), `core/rules/candy_rules.gd` (`is_gumdrop`), the natural-block lists
  (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`), `world/generators/secret_rules.gd`
  (`is_fake_wall`), the animal tables (`animal_rules`, `animal_homes`, `animal_food`, `animal_species`, `voice_rules`,
  `animal_book_rules`, `animal_boxes`, `blocky_animal`), `ui/universe/universe_art.gd`, `universe_card.gd` (`as_home`),
  `core/rules/loading_hints.gd`, `tools/bench_generator.gd` (`--space`), `scenes/sandbox.gd` (four call lines:
  `_arrive_from_space`, `_space_local`, `_start_space_host`, the Back chain; a section at the end), `assets/CREDITS.md`,
  `docs/DEVELOPMENT.md`, the spec (§21), the plan, `docs/playtests/owner-feedback.md`.
- Not touched: `entities/player/player.gd`, the HUD's JUMP/WALK/FLY (owner #54's agent), `ui/menus/menu.gd`,
  `settings_panel.gd`, `core/save/profile_data.gd`, `autoloads/music.gd`.
