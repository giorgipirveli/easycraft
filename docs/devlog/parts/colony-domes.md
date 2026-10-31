# Colonies under domes on the Moon and Mars (owner #77, spec §21c)

The owner (#77): "On the planets like moon, create domes for living creatures, something like [a famous rocket builder]
is dreaming, find it. same on the mars". Brief: `docs/superpowers/plans/2026-09-29-colony-domes-brief.md`. Built by a
worker agent in its own worktree (branch `worktree-agent-aa10bf2c1f528fc23`, reset to `lead-merge` 745ddf2e first: the
rocket flight with a controller), without the editor, the emulator or adb (three windowed runs of `tools/space_shots.gd`
for pictures). No real person's, company's or mission's name anywhere in the game (spec §21b.2): "a rover", "rocket
builders", "space agencies"; the names below are only in these notes, as sources.

## Allocations (used; nothing else touched)

| What | Allocated | Used |
|---|---|---|
| Block ids, page 31 (`ColonyBlocks`) | 544-559 | all 16 |
| `BlockIds.COUNT`, `NEXT_PAGE_FIRST_ID` | 576 on the base (pages 32 rockets, 33-34 wonders, 35 prospecting) | unchanged |
| Atlas page | 31 (`data/blocks/pages/colony*.png`) | rows 0-3 |
| New files | `world/colony/*`, the page, `tests/**/test_colony*.gd`, `tools/colony_smoke*.gd`, `tools/make_colony_*` | |
| Item ids, HUD spots, server module | none | |

Shared files with small additions: `data/blocks/block_ids.gd` (the ids, names), `world/block_library.gd` (the page; a
cut-out that culls like glass), `world/generators/space_shape.gd` (the colony, the flat ground, no features on it, Mars's
plains under it, its sights), `space_generator.gd` (writes it; `colony_enabled` for the bench), `space_secret_rules.gd`
(the landmark and the secrets keep off it), `world/universes/mars.gd`, `moon.gd` (the sights' words, Tilly's stock),
`world/space_sights.gd` (parts are never marked by themselves), `core/space/planet_guide_rules.gd` ("1 place"),
`scenes/sandbox.gd` (the dome's animals and insects; the checklist's progress toast only for big sights),
`ui/shop/gold_shop.gd` (the DECORATIONS shelf), `core/rules/theater_site.gd` and `entities/theater/theater_director.gd`
(the Shorts Theater never stands on a colony), `tools/bench_generator.gd`, `tools/space_shots*.gd`, the tests of other
parts that knew page 31 was empty or the Moon had no sights (`test_rocket_blocks.gd`, `test_mars_shape.gd`,
`test_mars_universe.gd`, `test_mars_sights.gd`, `test_gold_shop.gd`). Nothing in `entities/robot`, `entities/alien`,
`core/creatures`, `core/daily`, `core/social`, the School, the missions or other worlds; the animals' own files untouched.

## The real idea (found, checked against the agencies' own pages)

- **The Moon:** space agencies plan a base camp near the Moon's **south pole**, on a well-lit crater rim (near continuous
  sunlight for power) next to craters whose floors never see the Sun and hold **water ice** (drinking water, oxygen and
  rocket fuel); the habitat and solar panels stand at least half a mile from the landing zone. Robots could **3D-print a
  shell of Moon dust** over an inflatable dome: a shield from radiation and tiny meteorites.
- **Mars:** rocket builders dream of a city on Mars for many people; agencies map **ice buried just under the dust** in
  the mid-latitudes (drinking water and rocket fuel) to choose where astronauts land; a thick shell of Mars soil **or ice**
  over a home keeps out radiation (one design lets the light in through ice); **oxygen can be made from Mars's carbon
  dioxide air** (a real instrument on a rover did it 16 times, 2021-2023); water split by electricity gives oxygen (as on
  the space station); Mars gets less than half of Earth's sunlight and dust settles on solar panels; **a big reusable
  rocket** lands on its legs and flies again (one Moon lander is as tall as a 15-storey building).
- Everywhere: **greenhouses** under lamps (astronauts have grown lettuce, cabbage, kale and zinnias in space, under a
  magenta glow: plants use red and blue light the most), **airlocks** with two doors, **rovers**.

## What a child sees

**On Mars** (seed 12345, the smoke run's world): landing on the pad, the colony stands **40 blocks north** (Mars's colony
is always north of the pad, or south if the north is not calm: its ice mine then faces an ice cap), on flat red ground
from the pad to past the colony (the ground blends back into the plains over 12 blocks). Seen from the pad: a glass
dome, smaller domes round it, a silver rocket 30 blocks tall behind them and a white garage; a floor path leads from the
pad toward the colony's **airlock** (two teal-and-white striped doors in a row, both open, a light between them: "a real
one has two doors, and one always stays shut"). Through it, **the Great Dome** (21 across, a white base ring, glass up to
10 high, warm lights under its top and round its base): green grass, **a greenhouse garden** at the back (three rows of
dark soil with wheat, berry bushes, pumpkins and flowers under bars of pink grow lamps on white posts, a floor path down
the middle), **a pond** 7 across and 4 deep with **fish** in it, **two orange trees**, flowers, and **bunnies, chickens
and ducks** walking about (the only animals on Mars; they never leave the glass), bees and butterflies over the grass.
The sky shows through the glass (butterscotch by day, stars at night). Glass tunnels (3 wide, 3 tall, white ribs) lead
left to **the homes** (a dome under a shell of printed regolith with five windows: three beds, a table, a bookshelf,
lights), right to **the lab** (two Lab Benches: a tap opens the Science Lab; a screen; a basalt sample and a gypsum
crystal on tables) and back to **the control room** (a big map of six screens on desks, two desks with screens), from
which tunnels lead to **the water plant** (ice melters with Mars's ice on top, tanks of water) and **the oxygen maker**
(makers with bubbling tubes, fed by tanks). Outside: **four rows of solar panels** on posts (lanes to walk between),
**the big rocket** on its own round pad (concrete, a yellow-and-black ring): four legs, four fins, five engines, a round
silver body with two teal bands and the crew's windows, a nose with a light on its tip; **the rover garage** (open toward
the pad, a rover inside facing out); **the ice mine** behind the colony (toward the north cap): a round pit in terraces
one block each, white ice in its floor and walls, a rim of dug-out soil with four ways in, a white drill tower with an
arm and a drill hanging into the pit, ice blocks waiting at the rim. Walking into each part says its fact once (the
toast, a sparkle); MY MAP shows "Mars Colony" from the landing; the explorer's card lists it as one place with Mars's
four sights. Tilly sells every colony block; the Gold Shop's DECORATIONS shelf sells dome decorations.

**On the Moon**: the same colony, **on the side away from the Moon Base** (the landmark), with the Moon's own things:
silver dust round it, the homes' printed regolith, the lab's moon rock and moon crystal, **the ice crater** (the same pit
with a rim of moon rock, shadow ice in it, a glowing ice crystal) and the Moon's facts. Under the black starry sky with
the home planet hanging in it, the dome's grass, trees and animals (moon bunnies hop outside as before). The explorer's
card now opens on the Moon too: "Explore 1 place: Moon Colony".

## The facts and their sources

Every part's words are in `world/colony/colony_rules.gd` (`WORDS`); `test_colony_rules.gd` holds the key numbers.

| Part | Mars | Moon | Sources |
|---|---|---|---|
| Great Dome | Mars's air is too thin to breathe (so the dome keeps air in) | The Moon has no air to breathe | NASA Mars facts (thin, 95 % CO₂: science.nasa.gov/mars/facts; the Mars fact sheet, nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html); NASA "The Moon's Atmosphere" (an exosphere, not breathable: science.nasa.gov/moon/lunar-atmosphere) |
| Greenhouse | Astronauts have grown lettuce, cabbage, kale and even flowers in space | Plants in space grow under pink lamps: they use red and blue light the most | NASA "Growing Plants in Space" (three lettuces, Chinese cabbage, mizuna, red Russian kale, zinnias; "plants reflect a lot of green light and use more red and blue wavelengths, the Veggie chamber typically glows magenta pink": nasa.gov/exploration-research-and-technology/growing-plants-in-space) |
| Airlock | A real one has two doors, and one always stays shut, so the air never gets out | the same | NASA "Quest Airlock" and "Commercial Airlock" (an entry door, a vestibule, an exit door; one hatch stays sealed while the other opens: nasa.gov/international-space-station/quest-airlock) |
| Homes | A thick shell of Mars soil or ice keeps out the Sun's harmful rays | Robots could print a shell of Moon dust over them: a shield from the Sun's rays | NASA Langley "A New Home on Mars" (Mars Ice Home: a shell of water ice against radiation that lets light in); NASA NTRS "Martian regolith as space radiation shielding" (19910048753); ESA "Building a lunar base with 3D printing" (a printed regolith shell against micrometeoroids and radiation: esa.int/Enabling_Support/Space_Engineering_Technology/Building_a_lunar_base_with_3D_printing) |
| Lab | A rover on Mars seals rock samples in tubes, so scientists can study them one day | Astronauts brought 382 kilograms of Moon rock home, and scientists still study it | NASA "Perseverance collects first Mars rock sample" (sealed in an airtight tube for a future return: jpl.nasa.gov/news/nasas-perseverance-rover-collects-first-mars-rock-sample); NASA curation (Apollo: 2,196 samples, 842 lb / 382 kg, studied for generations: curator.jsc.nasa.gov/lunar) |
| Water plant | Ice hides just under the dust in many places on Mars: melted, it is water to drink | Craters near the Moon's south pole stay in shadow and hold ice | NASA/JPL SWIM map ("buried ice … drinking water and a key ingredient for rocket fuel", ice within the upper metre, equator to 60° N: jpl.nasa.gov/news/nasa-is-locating-ice-on-mars-with-this-new-map); NASA "Artemis Base Camp … Will Need Light, Water, Elevation" (deep craters in near constant darkness hold frozen water) |
| Oxygen maker | A rover's machine made oxygen from Mars's air: what a small dog breathes in 10 hours | On the space station, electricity splits water into oxygen to breathe | JPL "MOXIE Completes Mars Mission" (122 g in 16 runs, 2021-2023, "about what a small dog breathes in 10 hours", made from CO₂: jpl.nasa.gov/news/nasas-oxygen-generating-experiment-moxie-completes-mars-mission); NASA Oxygen Generation System (electrolysis of water into oxygen and hydrogen: nasa.gov/stem-content/oxygen-generator-system) |
| Control room | A radio message from Mars takes 3 to 22 minutes to reach Earth | A radio message from the Moon reaches Earth in about 1.3 seconds | NASA "Mars Communications Disruption and Delay" (just over 3 minutes at the closest, over 20 at the farthest, up to 44 minutes round trip) and NASA TM-20250003885 (the Moon: about 1.3 s one way) |
| Solar panels | Mars gets less than half of Earth's sunshine, and dust must be cleaned off them | Near the Moon's south pole, some high places get sunshine almost all the time | NASA "Mars surface power generation" (at most 45 % of Earth's solar flux); JPL InSight (dust on its panels); NASA Artemis Base Camp (near continuous sunlight on crater rims) |
| Big rocket | Rockets that land on their legs can fly again. Earth to Mars takes about 7 months | Some new Moon landers land on their legs and stand as tall as a 15-storey building | NASA "Human Landing Systems" (a fully reusable launch and landing system; "about the same height as a 15-story building": nasa.gov/reference/human-landing-systems); NASA Mars trip about seven months (the missions' `MissionRules`, `docs/devlog/parts/missions.md`) |
| Rover garage | A rover on Mars drove more than a marathon: over 45 kilometres | Astronauts drove an electric car on the Moon in 1971 and 1972 | NASA Opportunity (28.06 mi / 45.16 km in all; a marathon in 2015: science.nasa.gov/mission/mer-opportunity); NASA "50 Years Ago, First Apollo Astronauts to Drive on the Moon" (electric Lunar Roving Vehicles on three missions, July 1971 to December 1972) |
| Ice mine / crater | Ice can be split into hydrogen and oxygen: rocket fuel for the trip home | Space agencies plan a base near the Moon's south pole, where dark craters hold ice | JPL SWIM ("a key ingredient for rocket fuel"); NASA "The Lunar South Pole Region" (water ice in permanently shadowed regions "can be used as fuel or oxygen") and NASA Artemis Base Camp |

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **The colony is terrain**, written by the space generator from `ColonyLayout`'s boxes like the planets' landmarks
   (never block edits stamped once, like the home worlds' Launch Site): the same for the host and every guest, nothing to
   save, no stamping frame. Worlds saved before get it too; a chunk a child already changed there keeps the child's
   blocks (a seam at worst). *Cost:* a space terrain version (a `WorldMeta.terrain` value for space worlds) to keep old
   Moon and Mars worlds colony-free.
2. **Where:** the Great Dome's middle 40 blocks from the pad, the airlock's door 24-25 from it, toward the pad. The Moon's
   on the side away from its landmark's first try (the Moon Base keeps its place unless it would touch the colony's
   ground: then it turns further round the pad, as it already does when its area is too narrow); Mars's due north,
   else due south (its mine then faces an ice cap), else the other sixteenth-turns, the first whose ground is Mars's plains
   (or a dry river bed) everywhere within 64 blocks. *Cost:* `ColonyLayout.DISTANCE`, `candidates`.
3. **Flat ground** at the landing pad's own height within 44 blocks of the middle (the pad is inside it), blended back
   over 12 (`R_FLAT`, `BLEND`); no crystal, boulder or gypsum grows on it, Mars's ground there is its plains' dust (a river
   bed under it is flattened away), no secret is built and no landmark stands within its blend, the Shorts Theater picks
   another place (a site saved before is picked again). *Cost:* two constants; the Theater check in `TheaterSite`.
4. **Sizes:** the Great Dome radius 10 (21 across, the brief's "about 21"), the smaller domes radius 5, the tunnels and
   the airlock 3 wide and 3 tall inside, every step one block (the Moon's and Mars's jumps reach 4). *Cost:* constants.
5. **Glass** is a cut-out (alpha scissor, like every glass in the game: no blended transparency to sort) with its own
   transparency index 7 and a new page extra `"culls": true` so the faces between two panes are hidden (the other pages'
   glass still draws them); a thin frame on two edges, so two panes side by side draw one line (a light lattice, like a
   real dome's frame). *Cost:* the tile and one extra.
6. **The homes under printed regolith** (the real shield), the other smaller domes glass (daylight inside); every dome has
   warm glowing lights; no dynamic light (on the phones' renderer every light is another pass over the nearby terrain).
   "Never dark": the night under the dome is the game's night (blue, the lights glowing; pictures). *Cost:* OmniLights.
7. **The airlock is open** (two striped frames in a row, no doors: pretend, the brief's rule); its fact says a real one
   keeps one shut.
8. **Sights:** the Great Dome is the colony's big sight (id `colony`: MY MAP "Mars Colony"/"Moon Colony" from the landing
   at the dome's middle, one line of the explorer's checklist, found by walking into the dome); its other eleven parts are
   small sights, each saying its fact when walked into, never marked on MY MAP by themselves, and no "2 of 5 found" toast
   after them. *Cost:* marking them is one line in `SpaceSights`.
9. **The Space Book** is not given a new mark; the colony is noted in the planet's card (the explorer's checklist line).
   A new bit in `WonderData.bodies` would be dropped by older app versions reading the backup (they refuse marks above 3).
   *Cost:* a `COLONY` bit (the merge keeps bits) and a line on the book's card once the old apps are gone.
10. **The dome's animals** are the game's own (2 rabbits, 3 chickens, 2 ducks, 3 fish: 10, the LOW preset's cap is 12),
    `ColonyAnimals` (host and solo): they come when a child is within 72 blocks of the dome's middle, **one every half
    second** (building an animal took 5-45 ms a tick for three on this desktop, loaded: see below), go when every child is
    farther than 110 (Mars has no AnimalDirector to send them home), stay while no child stands (a respawn, a teleport:
    the first version freed and rebuilt the herd every time the child moved), are put back on their spot when they wander
    out through a doorway, never touch a pet (a tamed bunny follows its child; its spot stays taken) and come back after
    `AnimalRules.REFILL_TIME` when defeated. The Moon's AnimalDirector counts them in its per-child budget (fewer moon
    bunnies spawn near the dome). *Cost:* `ColonyRules.HERD`, `ColonyAnimals` constants.
11. **The pond** is 7 across and 4 deep, **without lily pads**: in the first pond (5 across, 2 deep, two lily pads) the
    fish bumped its walls and pads every step; a bigger, deeper pond measured like no fish at all. *Cost:* constants.
12. **Bees and butterflies** are the meadows' particles (`MeadowInsects`) over the Great Dome's grass only, day and night
    (the lamps). *Cost:* one node.
13. **Build your own:** Tilly sells all sixteen colony blocks on the Moon and Mars (1-6 gold, never scaled); the Gold
    Shop's DECORATIONS shelf sells ten dome decorations (dome glass ×20, grow lamps ×4, greenhouse soil ×10, a fruit tree,
    lights ×4, tables ×2, water tanks ×2, an oxygen maker, screens ×2, a colony map; 40-80 gold, again and again) into
    the backpack for the next Survivor world, like the weapons. *Cost:* the tables in `ColonyRules`.
14. **The big rocket** is our own design in rocket steel with the missions' engine blocks and pad (page 32): a model,
    never a rocket the Mission Board checks or flies (the colony is in space; missions start at home). *Cost:* none.
15. **The ice:** Mars's mine uses its polar ice (the fact says ice hides under the dust far from the poles too), the
    Moon's crater Mercury's shadow ice (its name fits); the Moon's crater is lit like everything (the game is never dark),
    its fact says the real ones stay in shadow. *Cost:* `ColonyRules.PALETTE`.
16. **No people** in the colony (spec §21c.4: figures later, with the owner's word); the robots agent's helper robots
    and friendly aliens may move in later.
17. **The lab's two Lab Benches** open the Science Lab like any bench (supplies as there: the Sandbox's endless).

## Measurements (this desktop, 24 cores, shared: load 10-25 during the runs)

- **Generator bench** (`godot --headless --path . --script res://tools/bench_generator.gd -- --space moon mars`), the
  colony's 6 × 6 chunk stacks, fresh generators, alternating:

  | | meadows avg / worst | the planet without the colony | with the colony |
  |---|---|---|---|
  | Moon surface | 1.68 / 5.19 ms | 1.63 / 6.21 ms | **1.61 / 5.26 ms** |
  | Moon underground | 1.34 / 4.88 | 0.34 / 2.08 | 0.33 / 1.68 |
  | Mars surface | 1.45 / 4.32 | 1.55 / 7.98 | **1.60 / 6.93** |
  | Mars underground | 1.35 / 3.38 | 0.30 / 1.90 | 0.30 / 1.85 |

  The colony costs no more than the planet's own chunks (and less than the meadows'). The Moon's usual region:
  BENCH_SPACE_MOON surface 1.29 ms (meadows 1.55), cold 1.95 (1.71); Mars 1.03 (1.60), cold 1.48 (1.79).
  Building a shape with its colony (`BENCH_COLONY_<P>_SHAPE`): the Moon 5.6 ms avg (8.7 worst), Mars 8.6 (12.6: its calm
  look over 64 blocks), a few per world load; the colony is 1,446 boxes, indexed per 16³ chunk.
- **The smoke run's frames** (headless: the CPU side only; the herd about), 3 s each after 4 s of settling: under the
  Great Dome 6.9-11.3 ms average, far on the plains 7.3-10.7 ms (the differences are this busy PC's noise; one run's first
  window after a teleport averaged 122 ms and the next 10 ms: a busy moment of the PC, not repeated). Before the fixes:
  building three animals a tick cost 17-45 ms that tick, and the first pond's three fish added up to 16 ms a physics step
  (two deep, bumping its walls); after them the herd is one animal a tick and the fish cost nothing measurable.
- **Pictures** (`XDG_DATA_HOME=/tmp/easycraft-colony-shots godot --path . --disable-vsync --resolution 1280x720 --script
  res://tools/space_shots.gd -- --universe=19 --colony`, and `--universe=16`): from the pad, from above, under the dome by
  day and by night, the homes, the control room, the rocket, the mine, both styles. First pictures found the Moon's
  Shorts Theater standing in the colony (fixed: ruling 3) and the homes' ceiling looking like wood (greyer now, its layers
  seen from inside).

## Tests

- `tests/unit/test_colony_blocks.gd` (page 31, kinds, the glass sheet, both styles, the look, names, gifts),
  `test_colony_rules.gd` (worlds, parts, the facts and their numbers, no real names, friendly words, Tilly, the Gold
  Shop's shelf, the herd), `test_colony_layout.gd` (placement a short walk from the pad, seen from it, flat ground and a
  climbable blend, the round glass dome 21 across, the garden, pond, trees and flowers, every smaller dome's things, the
  airlock, **a child walks from the airlock into every part**, the outside parts, Mars digging toward a cap, parts where a
  child stands, the animals' spots inside, the writer equal to the reference), `test_colony_generator.gd` (the colony's
  chunks equal the reference, the rocket in the sky chunks, nothing grows or hides on its ground, the landmark clear of
  it, the Theater off it, the Moon Base opposite, Mars's dust under it).
- `tests/integration/test_colony_sights.gd` (MY MAP, every part's fact once on both worlds, saved worlds remember, the
  checklist's one line, "1 place"), `test_colony_animals.gd` (one a tick, only inside, back inside, away and back, a
  pet, a defeated one, nobody goes while the child is between two places), `test_colony_world.gd` (the real terrain on
  both worlds, the glass's collision, **a child's changes save and load**).
- `tools/colony_smoke.gd` (`tools/smoke_all.sh colony`): Mars from the Star Map, the colony on MY MAP and the checklist,
  the dome in the real terrain, its animals (all under the glass), bees and butterflies, every part's fact, the frames,
  the lab's bench opening the Science Lab, then the Moon the same. 62 checks, 0 fails.

## For the lead: check on the emulator

1. Land on Mars and on the Moon (both styles): the colony seen from the pad; walk the path through the airlock; the dome's
   glass (the lattice's look at a distance and from inside, no flicker between panes), the grass, garden, pond, trees.
2. **Frames** under the Great Dome with the herd about (budget: ≥ 30 FPS, no frame over 100 ms) and while the herd
   comes (one animal every half second); the glass domes' overdraw on the phones' renderer (alpha scissor, many layers
   when looking through two domes).
3. The animals stay inside and never get stuck in a doorway; the fish swim; the ducks paddle.
4. The explorer's card on the Moon now opens ("Explore 1 place: Moon Colony"); the KEYS card and the planet card don't
   hide each other.
5. An old Moon world (saved before this) gets the colony without a broken seam where the child built, and its Shorts
   Theater moves off the colony if it stood there.
6. Tilly's BLOCKS on the Moon and Mars list the colony's blocks; the Gold Shop's DECORATIONS shelf buys into the backpack.

## Next (the game never ends)

Colonies on more worlds (§21c.5: Titan by its sea, Europa under the ice); people in the colony (with the owner's word);
the robots' helper robots and friendly aliens moving into the domes (#86); a line in the Space Book's card; the
greenhouse's crops a child can pick; a working airlock game (one door at a time); the water plant's melt shown moving;
the colony's own fact quiz (EarnRules' hook).
