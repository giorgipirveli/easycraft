# Prospecting on Earth: gold, copper, iron, coal, oil and salt (owner #80; spec §26)

Brief: `docs/superpowers/plans/2026-09-29-prospecting-brief.md`, PART = "Earth: gold, copper, iron, coal, oil and salt in
Green Meadows and the Sandstorm Desert", IDS = block atlas page 35, ids 608-623. Branch
`worktree-agent-a635a0044ddcd9bef`, cut from `lead-merge` at `0f042304` ("docs: owner-feedback statuses for #78, #79, #83,
#85"). No editor, no emulator, no adb. Built test-first (every test below was red for its reason first).

The owner (#80): "we should have minnings on planets and on eath, where we find preious metals, petrols and other things
like a real world has. to find such places you need find them with quests which include solving problems, quizes, maps,
advantures, findings and other exciting things".

## What a child sees and does

**Gemma the geologist** stands at her camp 21-26 blocks from the spawn of every Green Meadows and Sandstorm Desert world
(Sandbox and Survivor; never Monster Wave's arena): an orange vest with the brand's teal band, a yellow hard hat, a hand
lens, a teal-and-orange tent, a table with her map and rock samples, a crate with a pick. A "!" floats over her while a
quest of this world waits. Walking up to her opens her board (after X it stays closed until the child walks away and
back); DIG in MORE, and J on a PC, open it anywhere (on the quest's step, or on her quests). The board's six cards are the
six quests, this world's three first (the other world's say "Told in the Sandstorm Desert" / "in Green Meadows"):
START, GO ON (Step 3 of 7), FIND ANOTHER. MY FINDS lists the deposits found in this world and how each is worked.

Every quest is 7 steps. It starts at the camp with **the map**: a real map of this world drawn from the ground round the
camp and the X (sea and rivers blue, land green by height, the desert's sand and red mesas), a grid of squares with
letters across and numbers down, north up, a scale bar (100 m a square, or 200 / 500 m for a far target), the camp's tent
and a red X. Its question is about this world (the answer is where the deposit really is). Then **walks** (LET'S GO:
the HUD's compass points there; "It is about 240 m away"), **the sign** found up close (walking within 3.5 blocks of it:
"You found it! …" and a real fact), a **problem** or a **clue** on the board (it opens by itself when the sign is found),
**Gemma's quiz** (2-3 School exercises), and **MARK IT**: the deposit goes on MY MAP (its own picture: a nugget, a
derrick, salt cubes, …), the gold is paid, and the find's card says how it is dug out and refined and what it sells for.
Every exercise is a School exercise (ExercisePanel): a miss says "Not yet" with a hint and another try, a second miss
shows how; right the first time pays the School's answer gold (+5, inside the School's cap of 150 a day).

| Quest (world) | Map | Walk and find | Problem / clue | Quiz |
|---|---|---|---|---|
| **Gold in the hills** (Green Meadows) | which way is the X (N, NE, … in words) | the river by the X → the gold flakes in its gravel (GOLD_GRAVEL, at the water's edge) → "follow the gold uphill": the white quartz stripe in the hillside (GOLD_QUARTZ) | pans upstream: 2, 4, 8 flakes … the next? (16) | "Gold rusts when it gets wet" (false); why gold stays in the pan (it is very heavy) |
| **The green rocks** (the desert) | which square is the X in (C4 …) | the mesa → the green stains on its face (MALACHITE) | clue: why is the rock green (copper turned green in the air); problem: 1% copper, how much in 500 kg (5 kg) | what copper is for (electric wires); one of the first metals (true) |
| **The needle that points wrong** (Green Meadows) | about how far is the X (m, by the scale) | the red hill → the rusty rock on its top (RUSTY_ROCK) | clue (a compass picture): the needle points at the rock (magnetic iron ore); problem: the detector's beeps (1 at 40 m, 2 at 20, 4 at 10 … at 5 m? 8) | steel is mostly iron (true); 6 Banded Iron in the Clay Oven (12 Iron); how the old seas' iron rusted into stripes (oxygen from tiny living things) |
| **The black stripe** (Green Meadows) | which way | the hillside → the coal seam with fern shale over it (COAL, FERN_SHALE) | clue (a rock-layers picture with a fern fossil): a swamp forest; problem: 10 m of plants make 1 m of coal, a 3 m seam (30 m) | put in order: how a swamp forest becomes coal; burning coal warms the planet (true) |
| **The echo under the sand** (the desert) | which way | the dunes → the dark, sticky sand (OIL_SEEP) → the dome's top to drill | the echo survey: sound goes 2,000 m a second, the echo came back after t s (1-3 s): how deep is the dome (1,000-3,000 m) | why the oil stays under the dome (tight cap rock); the rockets' fuel (kerosene); burning oil warms the planet (true: cars and rockets are learning cleaner fuels) |
| **The dried-up lake** (the desert) | which square | the flat ground → the white crust (SALT_CRUST) | problem: 35 g of salt a litre, a pan of 2 / 4 / 10 litres (70 / 140 / 350 g); clue: a lake dried up and left it | salt's crystals (little cubes); salt keeps roads free of ice (true) |

The gold quest pays **100 gold the first time** (each quest once per child, like a School unit); the same quest again
leads to the next deposit farther on (FIND ANOTHER) and pays **20 gold** (up to 100 a day). An oil quest stands an **oil
well** on the dome: a 10 m steel derrick and a teal **pump jack** beside it, nodding (its horse head over its own
wellhead), a sign "Oil well, 1,500 m deep". Walking up to the pump jack in Survivor puts a **drum of crude oil** in the bag
(40 in a well; "+1 Crude Oil! 39 drums left …"); in the Sandbox it says how it works. With the Gold Shop's **Metal
Detector** (150 gold, WEAPONS & TOOLS), metal near the child (the gold, copper and iron deposits' signs within 48 m)
beeps faster as they come closer, and the compass points to it when no quest step is being followed.

**In Survivor**, the finds are mined (the pickaxe tier of their plain ore: gold quartz needs iron, the rest wood or a
hand) and refined in the Craft Book, each step saying a real fact: pan 4 Gold Gravel → 1 Gold (by hand); the Clay Oven
(burning coal or wood) smelts 4 Gold Quartz → 1 Gold, 2 Copper Ore → 1 Copper, 2 Malachite → 1 Copper, 1 Banded Iron →
2 Iron, 2 Rock Salt → 1 Table Salt; 3 Salt Crust → 1 Table Salt by hand; a **Refinery** (a Workbench: 4 Iron, 2 Glass,
2 Bricks; Tilly: 40 gold) turns 1 Crude Oil → 1 Kerosene and 2 Crude Oil → 3 Plastic. Tilly buys table salt (1),
crude oil (2), plastic (3), copper (5) and kerosene (6), × 2 in the desert; she never sells them. The Iron goes into the
rocket's parts (nose cone, fins, legs, separators); **kerosene is the rocket's fuel hook** (`RefiningRules.ROCKET_FUEL`).

## Where the deposits are (DepositRules; measured, 5 seeds × 3 terrains)
Each 512 × 512 region holds at most one deposit of each of its world's kinds, sited from the seed and the terrain (the
generator writes them with the secrets; `nearest` finds the next one for a quest). Never within 128 blocks of the spawn,
4 blocks clear of every secret, mouse village and wild-meadows place, 64 apart.

| Kind | Where (real geology) | Its sign on top | Its body |
|---|---|---|---|
| Gold | water (a river, a lake's or the sea's shore) below a hill ≥ 10 over the sea | gold gravel on the bed and the low bank at the water's edge (a placer) | a quartz vein 3 wide, 4 tall, 11 long running level into the hillside where it rises 6 over the sea (a lode): 132 blocks |
| Iron | a hilltop ≥ 14 over the sea, the highest of its neighbours | rusty rock (a gossan) 2 deep on the top | a lens of banded iron under it (radii 4, 2, 4): ~125 |
| Coal | a hillside rising 8 over 16 blocks | the seam's black stripe where the slope cuts it, fern shale over it | a seam 2 thick under 1 of shale, 7 wide, 13 into the hill: 182 |
| Copper | a mesa's edge by the open desert | malachite on the cliff face and the top by the edge | a body of copper ore in the mesa (radii 4, 3, 4): ~125 |
| Oil | open desert with low dunes, no mesa or oasis near | a patch of oil seep 7 blocks from the dome's top | none in blocks: 1,000-3,000 m down (the echo survey), 40 drums a well |
| Salt | level desert floor (no dune) | a white salt crust over an oval ~20 across | rock salt 2 deep under it: ~425 |

| Seed | Old meadows: gold / iron / coal | Wild meadows | Desert: copper / oil / salt |
|---|---|---|---|
| 12345 | 194 / 249 / 343 m | 371 / 250 / 219 | 240 / 283 (2,000 m down) / 303 |
| 777 | 168 / 335 / 430 | 255 / 350 / 204 | 240 / 136 (1,000) / 244 |
| 20260925 | 473 / 313 / 159 | 348 / 262 / 434 | 214 / 195 (3,000) / 272 |
| 99 | 316 / 173 / 218 | 235 / 279 / 211 | 401 / 232 (1,500) / 297 |
| 4242 | 272 / 260 / 140 | 189 / 258 / 258 | 139 / 208 (2,500) / 268 |

A deposit refined and sold in Survivor is worth about 180-620 gold (coal ~180, oil ~240, salt ~270, copper ~440 with its
malachite, gold ~340 with its gravel, iron ~750 less the coal it burns): a day or two of learning (EarnRules: a day ≈ 275),
and real work (mining a hundred blocks or more, then a tap a smelt). `test_a_deposit_is_worth_about_a_day_of_learning`.

## Rulings (the owner's rule: decide and write down; cost if wrong)
1. **Deposits are written by the terrain generator** (in `MeadowsGenerator._place_secrets`, before the secrets), in every
   world of those terrains, the old meadows too: a child finds a green stain before any quest, and a LAN guest's terrain
   has them without a message. *Cost:* in a world made before this, a deposit may meet a chunk the child edited (saved
   chunks keep their old ground: a cut at the seam; deposits are ≥ 128 blocks from the spawn, so rare). Turning them off
   for old worlds is one flag (`deposits_enabled`) from `WorldMeta.terrain`.
2. **One deposit of each kind per 512-block region**, sited on a coarse look at the ground (27 × 27 samples) then worked
   out exactly; the quest leads to the nearest one this world has not found (rings 1-3 round the camp, on a worker).
   *Cost:* the numbers are constants in DepositRules.
3. **Gold wants water below a hill** (a river, or a lake's or the sea's shore: black-sand beaches hold placer gold too).
   The wild meadows' rivers are ~1 km apart, so gold is 190-470 m out. *Cost:* in a dry corner of a world the nearest
   gold is farther (rings 2-3).
4. **Oil is not dug**: it lies 1-3 km down (as real oil does); the quest's dome gets an oil well whose pump jack fills
   drums (40 a well; the next quest finds more). *Cost:* none known; a "tunnel to the oil" is not possible at the world's
   depth.
5. **A quest belongs to its world** (it leads to that world's deposit; the step it waits at is saved in
   `WorldMeta.prospect`); **the child's reward belongs to the profile** (`ProfileData.prospect`: the quests done once,
   the finds, today's finding gold). *Cost:* a child who starts a quest in another world starts it there anew.
6. **Gold**: EarnRules' new lines, 100 the first time a quest is finished (once per quest), 20 for each later find (100 a
   day at most); the quests' exercises pay the School's answer gold inside its cap. Survivor pays through the host's
   wallet (the HUD and the online ledger hear it), the Sandbox into the profile like the School. *Cost:* three constants.
7. **Mining, refining and selling are Survivor's** (crafting is: `CraftRules`), the Sandbox's quests still pay, and its
   oil well shows how it works. *Cost:* none.
8. **A LAN guest looks but prospects in its own world** (the board says so; the camp and the wells stand on its screen
   from the seed). *Cost:* co-op prospecting later (the host sharing the quest like the quest book's PLAY TOGETHER).
9. **Refining makes the game's own Gold and Iron** (the rocket parts' recipes use Iron) and new Copper, Table Salt, Crude
   Oil, Kerosene and Plastic blocks; they are "stuff" in the words ("You made 1 Kerosene!"). *Cost:* none.
10. **Panning is by hand, anywhere** (not only at water). *Cost:* a water check needs a new kind of station.
11. **The Refinery is a crafting station** (`Recipes.REFINERY`, found in reach like the Clay Oven; it burns nothing).
    *Cost:* two tests counted the stations (updated).
12. **Prices** (`RefiningRules.SELL`, in `ShopRules.SELL_PRICES`): refining always pays more than the raw find, a drum is
    worth most as kerosene, and Tilly never sells any of them (no loop). The raw finds are not bought. *Cost:* one table.
13. **Kerosene is the rocket's fuel hook** (`RefiningRules.ROCKET_FUEL`); the missions are unchanged. *Cost:* none.
14. **The Metal Detector is gear on the Gold Shop's shelf** (`prospect:detector`, 150 gold, the profile's for good); no
    quest needs it (the compass points the way for everyone). *Cost:* none.
15. **Gemma is a new character** with her own camp (not Tilly, not the Launch Site: the missions' files are untouched),
    placed from the seed 21-26 blocks out, clear of Tilly's stall, the Totem, the hub circle, the Theater, the universe's
    helper and the Launch Site's pad (their places, and the straight ways to them). *Cost:* none.
16. **MY MAP's marks are put back every game** from the world's found list (PlacesDirector's marks are not saved).
17. **J** (input action `prospect`, in `project.godot` and `tools/setup_input_map.gd`; the KEYS card lists it) and **DIG**
    in MORE (HudIcons `dig`). *Cost:* the controllers agent may also touch the input map: a two-line merge.
18. **The finds are the world's ground** (`CaptureRules.GROUND`: the wand never wakes them; `BotRules.NATURAL`) and are
    never painted (`PaintRules.JOB_PAGES` has page 35).
19. **No palette row**: the riches come from the ground (`/give` has them). *Cost:* a palette row later (tests count its
    buttons).
20. **The models** (Gemma, her camp, the well) are vertex-coloured boxes with the Theater's shared material (its shaders
    are warmed; `test_shader_warmup_sources` lists the two files).

## The facts and their sources
- Gold is about 19 times as heavy as water (density 19.3 g/cm³) and never rusts; placer gold is washed from lode veins
  (quartz) and gathers in river gravel; panning separates it by weight. USGS, *Gold* (General Interest Publication) and
  *Prospecting for Gold in the United States* (pubs.usgs.gov/gip/prospect1).
- Copper turns green in air and water (malachite on rocks, a patina on roofs and statues): the Statue of Liberty's copper
  skin turned green within about 30 years. National Park Service, *Statue of Liberty: Frequently Asked Questions*.
- Big copper deposits (porphyry copper) are in dry mountains (Chile's Atacama, Arizona) and hold often less than 1% copper,
  so mines are huge open pits. USGS, *Porphyry Copper Deposit Model* (Scientific Investigations Report 2010-5070-B).
- Most copper goes into wires, motors and electronics; only silver conducts electricity better. USGS *Mineral Commodity
  Summaries: Copper*; Copper Development Association.
- People smelted copper more than 7,000 years ago, from malachite. Radivojević et al. (2010), "On the origins of extractive
  metallurgy", *Journal of Archaeological Science* 37 (Belovode, Serbia, ~5000 BCE). Copper melts at 1,085 °C (CRC
  Handbook).
- Banded iron formations were laid down about 2.5-1.8 billion years ago when oxygen made by tiny sea life rusted the iron
  in the sea. USGS; Cloud (1973), *Economic Geology* 68.
- Magnetite is the most magnetic mineral on Earth (a lodestone is magnetite). USGS; Geology.com, *Magnetite*.
- Almost all iron ore (about 98%) is made into steel; steel is iron with a little carbon; in a furnace the carbon of coal
  (coke) takes the oxygen out of the ore. USGS *Mineral Commodity Summaries: Iron Ore*; World Steel Association.
- Most coal formed in the Carboniferous (~359-299 million years ago) from swamp forests of tree ferns and club mosses;
  the grey shale over a seam holds their fossils. Britannica, *Carboniferous Period*.
- About 10 feet of squashed plant matter make 1 foot of coal (estimates vary). Kentucky Geological Survey, *How is coal
  formed?*
- Oil formed from tiny sea creatures (plankton) buried in mud and cooked by the Earth's heat; it rises until a dome of
  tight rock (a cap rock over an anticline) traps it. U.S. EIA, *Oil and petroleum products explained*; USGS.
- Seismic surveys send sound down and time its echoes: depth = speed × time ÷ 2; sound crosses sedimentary rock at about
  2,000-4,000 m a second. SEG Wiki, *Seismic velocity*; USGS.
- Oil seeps were used thousands of years ago (bitumen in Mesopotamia). Wikipedia, *Petroleum seep*.
- A pump jack ("nodding donkey") lifts oil up a well with a rod rocked by a walking beam. Wikipedia, *Pumpjack*.
- A refinery heats crude oil and sorts its parts in a distillation tower by the heat each boils at; kerosene (jet fuel)
  condenses part way up; many rockets burn a refined kerosene (RP-1); a few percent of oil goes into plastics. U.S. EIA,
  *Refining crude oil* and *How much oil is used to make plastic?*; NASA / Wikipedia, *RP-1*.
- Burning coal and oil adds carbon dioxide to the air, which warms the planet. IPCC AR6; NASA *Climate*.
- Sea water is about 3.5% salt (35 g a litre). NOAA, *Why is the ocean salty?*
- A salt flat is a dried-up lake (the Bonneville Salt Flats are Lake Bonneville's bed; Salar de Uyuni is over 10,000 km²);
  salt has been made by drying sea water in shallow pans for thousands of years. USGS; BLM *Bonneville Salt Flats*;
  Wikipedia, *Salt evaporation pond*.
- Rock salt (halite) grows as cubes; salt melts road ice at a lower temperature (road de-icing is its biggest use in the
  US). Mindat, *Halite*; USGS *Mineral Commodity Summaries: Salt*.

## Numbers measured (this PC)
- **Generator bench** (`tools/bench_generator.gd -- --deposits`, seed 12345, 270 chunks over each terrain's nearest
  deposits, on and off alternating, every chunk made once before it is timed): meadows 1.42 → 1.42 ms, wild meadows
  1.06 → 1.07, desert 1.07 → 1.08 (off → on: writing deposits costs 0.00-0.01 ms a chunk). Placing a new region's
  deposits, once per 512 × 512 region on a generator thread: meadows 13 ms (worst 26), wild meadows 25 (61), desert 20
  (33). The default bench's first chunk of a region pays it (its worst chunk).
- **Board**: opens with the map step's picture drawn from 48 × 48 samples of the ground (a few ms).

## The full suite, the smoke and the pictures
- **The full suite** (`tests/run_tests.sh`, 2026-09-30, a busy PC, 41 min): 869 scripts, 7,954 tests, **7,951 passing**,
  2 risky as before (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`: they assert only on a
  difference), 1 failing: `test_avatar_models.gd`'s `test_air_jumps_flip_and_come_back_upright` (an animation's timing
  under load: "flips forward" -0.14 < -0.3), which **passed alone** right after (15 of 15). Nothing of this work touches
  the avatar.
- `tools/prospecting_smoke.gd` (`tools/smoke_all.sh prospecting`): **PASS, 0 fails (43 checks), 40 s** on the final tree. A new Green Meadows Sandbox
  world at seed 12345: Gemma's camp 23 blocks out; walking up opens her board; the gold quest (gold:0:0, 371 m out) runs
  through the real board and world: the map answered, LET'S GO, the compass on the gravel, GOLD_GRAVEL in the generated
  river bed, found up close (its fact on the screen), the problem, GOLD_QUARTZ in the hill, the quiz, MARK IT (+100
  gold), MY MAP's mark, the world's save; then a desert Survivor world: the oil quest's well (2,000 m down), a drum from
  the pump jack into the bag, a Refinery placed beside it makes kerosene (its fact), Tilly buys it for 12.
- `tools/prospecting_shots.gd` (windowed, 1280 × 720): the camp in both worlds and styles, the gold gravel at the river's
  edge, the quartz vein (in a birch wood: trees hide it from the camera), the rusty hilltop, the coal seam with its shale,
  the board's quests, a map step and a find's card; the copper mesa's malachite (very plain to see), the oil seep, the
  salt flat, the oil well. Fixed after looking: the quest cards' words wrap; a cactus no longer grows on an oil seep;
  the find's card from the shots opens the board first.

## Files
- **New:** `core/prospecting/` (DepositKinds, DepositRules, SurveyRules, ProspectQuests, ProspectState, ProspectData,
  ProspectRewards, RefiningRules, ProspectGear), `world/prospecting/` (ProspectDirector, ProspectCamp, ProspectModels,
  OilWell), `ui/prospecting/` (ProspectBoard, ProspectMap, ProspectPictures), `data/blocks/prospect_page.gd`,
  `data/blocks/pages/prospect.png` (+ `_albedo`, `_normal`, their `.import`), `tools/make_prospect_page.gd`,
  `tools/make_prospect_realistic.py`, `tools/prospecting_smoke.gd` (+ `_steps`), `tools/prospecting_shots.gd`
  (+ `_steps`); tests `tests/unit/test_prospect_blocks.gd`, `test_deposit_rules.gd`, `test_deposit_generator.gd`,
  `test_prospect_survey.gd`, `test_prospect_quests.gd`, `test_prospect_state.gd`, `test_refining.gd`,
  `test_prospect_gear.gd`, `tests/integration/test_prospect_board.gd`, `test_prospect_director.gd`.
- **Shared, small:** `data/blocks/block_ids.gd` (ids 608-623, names, `COUNT` and `NEXT_PAGE_FIRST_ID` 624),
  `world/block_library.gd` (one register line), `world/generators/meadows_generator.gd` (the deposits with the secrets,
  `deposit_over` in the reference), `desert_generator.gd` and `meadows_biome_generator.gd` (their references),
  `core/crafting/recipes.gd` (ten recipes, the REFINERY station), `core/crafting/craft_rules.gd` (the station, the
  facts, "1 Kerosene"), `autoloads/session.gd` (refineries near), `core/economy/shop_rules.gd` (sell prices, the Refinery
  at 40), `core/economy/earn_rules.gd` (two lines), `core/survival/gather_rules.gd` (pickaxe tiers),
  `core/save/profile_data.gd`, `profile_backup.gd`, `world/world_meta.gd` (`prospect`), `core/building/paint_rules.gd`,
  `core/magic/capture_rules.gd`, `core/rules/bot_rules.gd`, `ui/map/world_map_panel.gd` (the deposits' pictures),
  `ui/hud/hud_icons.gd` (`dig`), `ui/shop/gold_shop.gd` (the detector's shelf), `core/platform/keys_rules.gd`,
  `project.godot` and `tools/setup_input_map.gd` (J), `scenes/sandbox.gd` (its section "Spec §26"),
  `tools/bench_generator.gd` (`--deposits`), `assets/CREDITS.md`; tests counting ids, pages, recipes and stations
  (`test_rocket_blocks`, `test_block_id_space`, `test_block_pages`, `test_realistic_pack`, `test_recipes`,
  `test_craft_rules`, `test_craft_session`, `test_shader_warmup_sources`).

## For the lead
- **Merging:** the files other agents touch too are `block_ids.gd` (ids after 573; pages 33-34 are held), `sandbox.gd`
  (one call in `_setup_local_player`, one line in `go_back`, one section before the KEYS card), `project.godot`'s input
  map (the `prospect` action) and `keys_rules.gd` (one line), `recipes.gd` and `craft_rules.gd`, `earn_rules.gd`,
  `shop_rules.gd`, `profile_data.gd`, `world_meta.gd`. The PNGs are new files.
- **lead-merge moved on** while this was built (the rocket flight, the TV shows, grade 6's grown-ups page): a trial merge
  (merge-tree against `698c85ae`) is clean once the `prospect` action sits before `photo` in the input map (the flight's
  keys follow `crouch`). The KEYS card then has 23 lines (the flight's four and J): run `test_keys_card.gd`'s "fits a
  PC screen" after the merge.
- **The rocket's fuel:** a Fuel Tank could be filled from kerosene drums: `RefiningRules.ROCKET_FUEL` is the block.
- **Later parts** (the brief's order): the Moon's and Mars's ice and metals are new rows in `DepositKinds.DATA` and a
  site function in `DepositRules` for their shapes (`kinds_for`), their quests in `ProspectQuests.QUESTS`, and an ice
  drill on the GEAR shelf (`ProspectGear`). Hooks not used yet: "an old prospector's map" in a treasure chest could call
  `ProspectDirector.start(kind)`; the adventure board could count `deposit_found/<kind>`.

## What the lead must check on the emulator
1. A new Green Meadows world and a new desert world (Sandbox and Survivor): Gemma's camp in both styles, where it stands
   (next to Tilly's stall, the Launch Site, the Theater, the helper), her "!" and her wave.
2. Walking up to Gemma; the board at the phone's size: the quest cards' words, the map step (is the map readable, the X
   and the grid?), the number pad of a problem, the quiz, LET'S GO, MARK IT, the find's card; X, Android Back, the
   speaker; J and DIG.
3. A quest's walk: the compass pointing, the toasts' facts, the board opening by itself on the problem after the sign.
4. The deposits in both styles: the gold gravel under shallow river water (can a child see it?), the quartz vein, the
   rusty hilltop, the coal seam, the malachite on a mesa, the oil seep, the salt flat; and the oil well's pump jack
   nodding.
5. The frame time when the child walks into a new 512-block region (its deposits placed on a generator thread, 13-60 ms on
   this PC: 3-5 × on a phone): no hitch on the main thread?
6. Survivor: mining the new ores (gold quartz needs an iron pickaxe), the Craft Book's refining cards (Clay Oven, the
   Refinery), a drum from the pump jack, Tilly's Sell tab (table salt, crude oil, plastic, copper, kerosene).
7. The Gold Shop's Metal Detector: buying it, the beeps near metal, the compass pointing to it.
8. MY MAP's deposit pictures.

## Tests
| Test | Tests | Red first |
|---|---|---|
| `tests/unit/test_prospect_blocks.gd` | 7 | ProspectPage not declared; the normal map's half size; the found blocks as ground |
| `tests/unit/test_deposit_rules.gd` | 8 | DepositRules not declared; the oil's dome spot without a sign |
| `tests/unit/test_deposit_generator.gd` | 4 | no `deposits()` on the generators |
| `tests/unit/test_prospect_survey.gd` | 7 | SurveyRules not declared; a far target off the map (the scales) |
| `tests/unit/test_prospect_quests.gd` | 9 | ProspectQuests not declared; "die" in the coal quest |
| `tests/unit/test_prospect_state.gd` | 6 | ProspectState, ProspectData, ProspectRewards, EarnRules' lines not declared |
| `tests/unit/test_refining.gd` | 5 | RefiningRules and the recipes not declared; "a Gold" |
| `tests/unit/test_prospect_gear.gd` | 2 | ProspectGear not declared |
| `tests/integration/test_prospect_board.gd` | 7 | ProspectBoard not declared |
| `tests/integration/test_prospect_director.gd` | 9 | ProspectDirector not declared; a typed array in its cards |
