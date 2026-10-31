# The Science Lab (spec §23, owner #74)

The owner (#74, 2026-09-29): "make the universies closer to real worlds so player start learning real things, real
crafts, real allsubjects, we need more labs, more eduction, more secrets, more excitments". Brief:
`docs/superpowers/plans/2026-09-29-science-lab-brief.md`. Built by a worker agent in its own worktree (branch
`worktree-agent-aeb3c2612ae04e1e3`, reset to `lead-merge` ee5cc309 first: spec §23 and Mars's page 18 are there),
without the editor, the emulator or adb.

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| Block ids, page 19 (`LabPage`) | 352-367 (the lead: Mars has 336-351) | 352 `LAB_BENCH` | 353-367 |
| `BlockIds.COUNT` | 352 → 353 | | |
| Atlas page | 19 (`data/blocks/pages/lab*.png`) | row 0: tiles (0,0) top, (1,0) side, (2,0) bottom | the rest |
| Files | `core/lab/`, `ui/lab/`, `data/lab/`, `tests/*/test_lab*.gd` | all new code lives there | |
| Item ids, animals, HUD spots | none | none (the Lab opens over the HUD, like the shop) | |

## What a child sees

1. **A lab bench** (a white bench: a shelf with a glass flask of green liquid and a tiny burner with a blue flame above a
   dark worktop, a white cabinet with our teal knobs; the flask and burner seen from above on top). The Sandbox has it in
   the palette's SMART page, HOME row (beside the trophy shelf and the bookshelf); Survivor crafts it at a Workbench
   (3 planks, 1 glass, 1 iron) or finds one in some village houses (13 of 31 villages and towns of seed 12345: against the
   back wall, under the window). `/give lab bench` works.
2. **A tap on the bench** (whatever is in the hand; a hold still breaks it) opens **the Science Lab** over the world: six
   big picture cards (a tank with a floating block and a sunk stone, a horseshoe magnet with a nail and a clip, a beaker
   on a burner with a thermometer, three overlapping lights, three pots, a battery and a lit bulb), a gold star on each
   one done, "growing" on the plants while they grow; LAB BOOK; "Predict, try it, then find out why."
3. **1 PREDICT:** "What do you think will happen? Any guess is a good start." Big choice buttons (a tap picks one, teal;
   another tap changes it; nothing is ever greyed out), or for float or sink and the magnets a card per thing with its
   picture: a tap puts it in "Floats" / "Sinks" (blue, orange), and round again. TRY IT! once a guess is made.
4. **2 TRY IT** (the small scene, every step a big button, a line of words after each tap):
   - **Float or sink:** tap each of 8 things (wood, stone, ice, an iron nail, a leaf, a gold ring, a dry sponge, a glass
     marble) to drop it into the tank: floaters bob at the surface, sinkers rest on the bottom (a splash).
   - **Magnetic or not:** tap each of 8 things (a wooden block, an iron nail, a glass marble, a paper clip, a gold ring,
     copper wire, a food tin, a pebble): the iron nail, the paper clip and the food tin jump up and hang from the magnet's
     poles; the rest go into the "Did not stick" tray.
   - **Melting and freezing:** WARM (the burner's blue flame) and COOL (the beaker stands in an ice bath); a big
     thermometer from −20 to 110 °C, the temperature in big numbers, "Solid ice at −20 °C". The ice warms to 0 °C and
     stays at 0 °C for two taps while it melts ("The thermometer stays at 0 °C"), the water warms to 100 °C and boils
     (bubbles, steam) and stays at 100 °C; cooled it freezes again at 0 °C. "melts" and "boils" appear on the scale once
     seen. Safety words: "In a real lab, only a grown-up lights the burner. Never play with fire at home."
   - **Mixing colours:** PAINT: red, yellow and blue pots drop paint into a bowl (the School's RYB mixing), CLEAN; LIGHT:
     red, green and blue torches shine on a dark wall and add where they overlap (yellow, cyan, magenta, white). Dots for
     orange, green, brown and yellow, white fill in (with a drawn tick) as each is made.
   - **What do plants need?** Three pots: light and water (a sun, a watering can), in the dark (an open dark cupboard),
     no water (a dry cloud). Tap each pot to plant its seed; "Every seed is planted! Come back after 2 game days to see
     what grew." Day 1: a green sprout, a pale sprout, a seed; day 2: a green plant with leaves, a tall thin pale yellow
     shoot, still a seed. "Day 1 of 2", LOOK AGAIN. The pots keep growing while the child plays anywhere or is away.
   - **A simple circuit:** a wooden board: a battery, copper wires round one loop, a bulb, a knife switch. Tap the switch:
     the loop closes, dots of electricity flow from + round to −, the bulb glows. Tap a wire: it lies beside a dashed gap
     and the light goes out. ADD A BULB: both glow, more dimly. Safety words about small batteries and wall sockets.
   WHAT HAPPENED? opens once the child has seen what the experiment shows (all dropped / all tried / melted, boiled and
   frozen / orange, green, brown, yellow and white made / two game days / lit, a gap, two bulbs lit).
5. **3 WHY:** "You guessed: …", then either "Your guess matched what happened. Well predicted!" (gold) or "Scientists
   guess wrong all the time; that is how they learn!" (warm yellow, never red, never a cross); "What happened: …" (the
   result); the first time, a gold star: "A star for your Lab Book!" (a jingle). Three why cards on paper, PREVIOUS / NEXT,
   read aloud by the speaker (and by "Read to me"). LEARN MORE (the School's unit of the child's grade, or the nearest
   below), DO IT AGAIN (a new guess), LAB BOOK.
6. **The Lab Book** (the book's new **LAB** tab, the bench's icon, and the Lab's LAB BOOK): a tile per experiment with its
   picture and a star once done ("Done!", "Done 3 times", "Growing: come back soon", "Not tried yet"), "4 of 6 experiments
   done"; a tap opens its card: the guess, what happened, the kind line, how many times.
7. **From the School:** a unit an experiment lists (e.g. Grade 3 Magnets, Grade 4 Electric circuits, even "Coming soon"
   ones) shows **TRY IT IN THE LAB** under PRACTICE; it opens the Lab on that experiment inside the School's frame (from
   the main menu, no world needed); BACK comes back to the unit; LEARN MORE opens the unit's page.

## How it plugs in

- **Data** (`data/lab/`): `index.json` (the Lab's order) and one file per experiment: id, title, card, units, supplies,
  predict ({type choice: prompt, choices, answer} or {type sort: prompt, groups, by}: the School's `ExerciseCheck` forms,
  with no hint: a guess is never marked), scene (by kind, `LabModels` header), try, safety, result, why (1-4 cards).
- **Rules** (`core/lab/`, no nodes): `LabExperiments` (loading, checks, `predict_of`: a sort's items and answer from the
  scene's things, `matched`, `predict_words`, `for_unit`, `learn_unit`, `supplies`), `LabModels` (factory, scene checks,
  the drawable things), a model per kind (`LabTank`, `LabMagnet`, `LabHeat`, `LabColours`, `LabPlants`, `LabCircuit`,
  base `LabModel`: state, taps, `last` words, `done`), `LabData` (`ProfileData.lab`), `LabSupplies`.
- **UI** (`ui/lab/`): `LabScreen` (the pages), `LabView` and its views (`LabThingsView` for the tank and the magnet,
  `LabHeatView`, `LabColoursView`, `LabPlantsView`, `LabCircuitView`), `LabPredict`, `LabBookPage`, `LabPanel` (over the
  world), `LabArt` and `LabThings` (every drawing, in code: no art files).
- **Hooks (small, marked "spec §23"):** `BlockIds.LAB_BENCH`/`COUNT`, `BlockLibrary._static_init` (`LabPage.register`),
  `PaintRules.JOBS`, `BlockPalette.HOME_BLOCKS`, `Recipes.LIST` (`lab_bench`), `MeadowsPlaces._house`/`_village` (a
  bench in some houses), `BlockInteractor._tap_lab_bench`/`lab_bench_tapped`, `Sandbox.open_lab` and `go_back`,
  `SecretBook.LAB_TAB`/`lab_page`, `ProgressPictures` (`&"lab"`: the tab's picture), `SchoolScreen` (TRY IT IN THE LAB,
  `LAB` page, `lab_link`, `home_unit`), `ProfileData.lab`, `ProfileBackup` (`is_new`, `merge`). Tests changed for them:
  `test_recipes.gd` (29 recipes), `test_mars_blocks.gd` (COUNT ≥ 352), `test_books_tabs.gd` (seven tabs),
  `test_realistic_pack.gd` (the Lab's realistic twin goes in the browser's later "realistic" pack like every page's).
- **The server** needs nothing: a new top-level profile field (`lab`) passes `ProfileRules.clean` within its limits.

## Rulings (decided here; cost if wrong)

1. **The Lab Book is its own profile field (`ProfileData.lab`, `LabData`), not inside `WonderData`.** It is the Lab's, it
   merges on its own rules (most runs, this copy's guess, the earlier planting). *Cost:* moving it is a from_dict
   migration of one key.
2. **The book gets a seventh tab, LAB,** after SPACE (seven 76 px tabs and gaps: 568 px, the page panel 628 ≤ 700).
   *Cost:* one entry in `SecretBook.TABS`.
3. **TRY IT IN THE LAB opens the Lab directly inside the School** (the brief's "simplest"), from the menu without a world
   or a bench; there the supplies are free (no bag). *Cost:* a `supplies` Callable on `SchoolScreen.show_lab`.
4. **A game day for the plants is `DayCycle.LENGTH` (20 minutes) on the device's clock**, counted from the moment every
   seed is in, whether the child plays in a world, in the menu, or is away (seeds grow while you are away; no countdown is
   shown, only "Day 1 of 2"). *Cost:* one function (`LabPlants.days`) if days must be counted in a world's own sky.
5. **Survivor's supplies (1-3 ordinary blocks an experiment, `data/lab/*.json` "supplies") are taken from the bag when
   TRY IT! is pressed, by the game that holds the bag (the host: solo play).** In a guest's game the bag is the host's
   and there is no request for it yet, so a guest's bench is free. *Cost:* a `request_lab_supplies` / `host_…` pair in
   `Session` (like `request_drink`) to charge guests too.
6. **A prediction is a School exercise form without a hint, checked by `LabExperiments`, not `ExerciseCheck.problem`**
   (a sort of 8 things is more than the School's 6, and a guess has no hint). The child's guess is compared with
   `ExerciseCheck.is_right`. *Cost:* none.
7. **The first unit an experiment lists is the School's link for TRY IT IN THE LAB; LEARN MORE picks the child's grade or
   the nearest below.** *Cost:* data.
8. **The bench is placeable in the Sandbox from the palette's HOME row, not the BLOCKS grid** (the grid keeps its size),
   like the shelves; Tilly does not sell it (the spec: crafted and found). *Cost:* one `ShopRules` line.
9. **Every experiment's scene is one of six kinds drawn in code.** More experiments of these kinds are data only; a new
   kind is a model, a view and a card picture. *Cost:* as said.
10. **The magnet's things are ones a fridge magnet really pulls or does not** (no spoons: many stainless steel spoons do
    not stick; the why card says so). **Float or sink's "leaf" and "wood" are a fresh leaf and ordinary wood** (the why
    card says "most wood"). *Cost:* data.

## Facts, and how each is checked

| Fact (where) | Check |
|---|---|
| Wood, ice, a leaf and a dry sponge float; stone, iron, gold and glass sink (float or sink) | `test_lab_content.gd` `test_floating_follows_density`: densities held in the test (pine/oak 0.4-0.75, ice 0.917, a leaf's air spaces, a sponge mostly air, granite 2.7, iron 7.87, gold 19.3, glass 2.5 g/cm³) against water's 1.0 |
| A steel ship floats by its hollow hull; pumice can float (why) | Archimedes' principle; pumice's sealed bubbles (a common school fact) |
| Iron and steel stick; wood, glass, gold, copper and ordinary stone do not; food tins are steel with a thin coat of tin; recycling uses magnets to sort steel from aluminium; some stainless steel spoons do not stick; nickel and cobalt are magnetic too (in the notes, not the cards); lodestone (magnetite) is a natural magnet; a magnet pulls through paper, water, a hand | `test_only_iron_and_steel_stick` (a table held in the test); tinplate and magnetic separation are standard; austenitic stainless steel is not ferromagnetic |
| Ice melts at 0 °C, water boils at 100 °C at sea level, the temperature stays still while the state changes; an ice bath with salt is colder than 0 °C (the model's low is −20 °C) | `test_water_melts_at_0_and_boils_at_100_degrees`; the models' test holds the thermometer still while melting and boiling |
| Paint: red + yellow = orange, blue + yellow = green, all three = brown | the School's `ColourMix` recipes, `test_light_adds_and_paint_mixes_as_the_school_teaches` |
| Light: red + green = yellow, red + blue = magenta, green + blue = cyan, all three = white; screens are made of red, green and blue lights | additive RGB worked out in the test; `LabColours.light_colour` sums channels |
| Seeds need water to sprout; in the dark a seed sprouts on its own food and grows pale and thin (etiolation); green plants need light to make food; real seeds take days or weeks | `test_seeds_need_water_to_sprout_and_light_to_grow_green` (the model's stages) |
| A bulb lights only in a complete loop; a switch is a gap you open and close; two bulbs in one loop share the battery's push and glow more dimly (each a quarter of the power: P = V²/(n²R)); copper wires | `test_a_bulb_lights_only_in_a_closed_loop`, `test_the_circuit_lights_in_a_closed_loop_and_two_bulbs_share_it` (brightness 0.25) |

## Tests (all new, all pass)

- `tests/unit/test_lab_content.gd` (19): the files and index, every problem check, units in the School's outline, LEARN
  MORE's unit, predictions (the sort's answer is what the scene does), the facts above, supplies, safety words, and the
  words (the School's own lists: kind, no other game's names, British spelling, the font's letters only).
- `tests/unit/test_lab_models.gd` (8), `tests/unit/test_lab_data.gd` (5), `tests/unit/test_lab_bench_block.gd` (3),
  `tests/unit/test_lab_villages.gd` (1).
- `tests/integration/test_lab_screen.gd` (11): every experiment predict → try → why by taps only; a guess never marked;
  choices change freely; the why cards turn; the plants across two game days and leaving; Survivor's supplies; LEARN
  MORE; the Lab Book; every page fits 1180 × 636, every visible button ≥ 64 × 64 px, a speaker on every page, no Timer.
- `tests/integration/test_lab_links.gd` (6): TRY IT IN THE LAB (and not on other units; the page still fits), the Lab
  inside the School and back, the book's LAB tab (fits 700 px), a tap on a bench (three things in the hand) and a hold,
  `LabPanel` open/close/Android Back, `LabSupplies`.

## The full suite (2026-09-29, 28 minutes on a shared PC)

7046 tests in 765 scripts: 7043 passing, 2 pending (as before), 1 failing: `test_realistic_pack.gd` counts every page's
realistic twin and the Lab's page is new; it now lists `LabPage.FILES` (passes). No script errors. After it, the Lab's,
the profile's, the book's, the School screen's and the pack's tests again: 145 passing.

## Smoke run (the real sandbox)

`XDG_DATA_HOME=/tmp/easycraft-lab-smoke godot --headless --path . --script res://tools/lab_smoke.gd` (a copy of
profile.json in the folder): a new Survivor world; the bench crafted at a Workbench through `Session.host_craft`
(3 planks, 1 glass, 1 iron gone from the bag), placed through the host's edit path, tapped through the camera's ray (the
Lab over the HUD, a look blocker), float or sink without supplies ("The bench needs 1 Planks and 1 Stone from your bag
for this one.") and with them (the bag gives them), done by taps, the star, Android Back, the book's LAB tab, and
profile.json. 2026-09-29: 20 checks ok, exit 0 (the tap through the camera, no fallback).

## Pictures

`XDG_DATA_HOME=/tmp/easycraft-lab-shots godot --path . --disable-vsync --script res://tools/lab_shots.gd` (windowed):
36 PNGs of every page, every experiment's steps (a guess made; the scene at the start, halfway and seen; the why), the
Lab Book and a card, LEARN (the School inside the Lab), the School's unit with TRY IT IN THE LAB and the Lab inside the
School. Looked at: fixed the burner's flame reaching into the beaker, the paint pots' names (dark on dark) and the bowl
overlapping the third pot, the torches' lights not overlapping (now they mix), an invisible seed, a white goal's dot
(a drawn tick now), the magnet's things hanging in a row.

## For the lead to check on the emulator

1. The bench's look in both styles (BLOCKY and REALISTIC) in a world: its side's flask and burner, the top.
2. The Sandbox palette's SMART page: HOME row has the lab bench; placing it; a tap opens the Lab over the world (the menu
   panel's look), BACK on the list closes it, Android Back closes it, nothing is built behind a tap on the Lab.
3. The Lab at 1280 × 720 and on a 20:9 screen: every page fits; the torches' additive blend in the Compatibility
   renderer (the emulator) shows yellow, cyan, magenta and white where they overlap.
4. Survivor: the Workbench's recipe book shows the lab bench (3 planks, 1 glass, 1 iron); TRY IT! with and without the
   supplies in the bag (the words "The bench needs 1 Planks and 1 Stone from your bag for this one.").
5. A village house with a bench (seed 12345 has 13 such villages and towns).
6. The book's LAB tab (seven tabs fit the 720 px screen), a Lab Book card.
7. SCHOOL → Grade 3 → SCIENCE → Magnets: TRY IT IN THE LAB; the Lab inside the School; BACK to the unit.
8. "Read to me" reads the why cards; the speaker reads each page.

## What comes next (the Lab never ends: roadmap §6)

More experiments as data on the six kinds (e.g. sound travels through materials, which materials conduct in the circuit,
insulators on the heat bench), then the crafts (pottery in a kiln, smelting, dyes from plants, bread from wheat, paper
from wood, weaving, glass from sand), light and shadows, rocks and soils, a weather station; an in-world lab room; the
guest's supplies request (ruling 5); owner #74's status line can cite `test_lab_*.gd`.
