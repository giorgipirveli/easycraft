# The world's wonders, third tour: the Seven Natural Wonders (world 41, spec §24)

The owner (#78): "we must have world wonders, all wonders in the game. so all things must be educational in the game,
close to real world". Brief: `docs/superpowers/plans/2026-09-29-world-wonders-brief.md` with TOUR = "the Seven Natural
Wonders of the World (the 1997 list: the Grand Canyon, the Great Barrier Reef, the Harbour of Rio de Janeiro, Mount
Everest, the Northern Lights, the Parícutin volcano, Victoria Falls)", world 41's third tour, in a region of its own
reached by a way that fits nature, each one's real geology and life taught, with safe, friendly adventures. Built by a
worker agent in its own worktree (branch `worktree-agent-a40189eb685979cfd`, reset to `lead-merge` 89ca0648), without the
editor, the emulator or adb (windowed runs of `tools/space_shots.gd` and `tools/wonders_draw_probe.gd` for pictures and
draws). Running beside it: the Reel Studio (Shorts' 3D and video) and the lessons' quality round 2; none of their files
touched.

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World | 41 (the same world, a third region) | its south: `WonderTour.NATURE_SQUARE` (165, 410), `NATURE_R` 230 | |
| Block ids, page 37 (`WondersBlocks.TILES_NATURE`, rows 1-3) | 642-655 (page 43, 736-751, if needed) | 642-655 | page 43 stays free |
| `BlockIds.COUNT`, `NEXT_PAGE_FIRST_ID` | 736 | 736 (unchanged) | |
| Atlas page 37 (`wonders4*.png`) | rows 1-7 | rows 1-3 | rows 4-7 |
| Secrets' numbers | `WondersSecretRules.FIRST_ATTEMPT` + 14…20 (114-120) | the first two tours keep 100-113 | |
| Item ids, animals, HUD spots, server | none | | |

## What a child sees

1. **Landing** (the same spot): "Welcome to the Wonders of the World! Follow the red arrow: the Seven Ancient Wonders are
   here, the New Seven along the Wonders Road, nature's seven along the Nature Trail." The explorer's card lists **three
   columns**, The Seven Ancient Wonders, The New Seven Wonders, **The Seven Natural Wonders** (short names so three fit
   a phone), its words: "… The New Seven Wonders wait along the Wonders Road to the west, the Seven Natural Wonders along
   the Nature Trail to the south. …".
2. **The Nature Trail.** A ninth signpost on the landing square, "The Seven Natural Wonders (Nature Trail)" (light
   green), and a **dirt trail** 3 wide running straight south-south-east between the Hanging Gardens' path and the Great
   Pyramid's, 425 blocks, level, no tree on it; from 198 blocks out a row of **speed pads** across it every 24 blocks
   (about 70 s at a walk, about 50 with the pads; in the Sandbox a child may fly).
   Past the first park it runs into the **snowy north** of the region (pines), then past Parícutin's cornfield to the
   **nature square** (paving, eight signposts, the plaque "The Seven Natural Wonders": "In 1997 a list was made …", a
   signpost back, "The Seven Ancient Wonders (Nature Trail)"). MY MAP marks it. Its paths to the wonders are dirt paths.
3. **Parícutin** (north of the square; Mexico). A dark **cinder cone** 26 high in a **cornfield** (rows of corn two tall,
   a farm track through it), a stair cut up its front to the **rim** (walk round it), and in the **crater** a pool of
   glowing lava **behind a ring of rock** (the game's own lava: it bounces a child out, never hurts; a stair leads down
   into the crater and out). Behind it to the north a **black lava field** with the **church tower of San Juan**
   (belfry, front wall, a doorway half filled with lava) rising out of it. "You reached Parícutin! This volcano was born
   in a farmer's cornfield in 1943." Its card says "Quiet since 1952: here its crater glows as it did while it grew".
   **Secret:** a cracked brick in the tower's south face over the lava: a small room with a chest: "…The lava flowed into
   the church of San Juan but left its main altar standing. People still bring it candles and flowers."
4. **The Northern Lights** (north-west; the far north). A **snowy valley** of pines with a **frozen lake** (slippery
   ice), a dirt path lit by **ice lanterns**, a **log cabin** and a **viewing deck** with benches by the lake. **At
   night** the sky over the valley's north glows with **curtains of green light, pink and violet at their tops**, slowly
   swaying and brightening (NatureSky; they cannot be seen by day, as the real ones). "You reached the land of the
   Northern Lights! Look up on a dark night: the sky glows green, pink and purple." **Secret:** a snow mound west of the
   lake; on its east face a wall of blue ice with a **snow door**: the **ice cave** (ice lanterns, a chest): "…The same
   lights shine round the South Pole, where they are called the southern lights, and Jupiter and Saturn have them too."
5. **Mount Everest** (south-west; Nepal and China). The **highest ground in world 41**: Everest's summit 88 over the park
   (y 120), **Lhotse** to its south (78), the **South Col** between them (62). From the path's end, **base camp** (seven
   colourful tents, a string of **prayer flags**), **stair 1** of packed snow straight up the route's shoulder to the
   col (62 steps) with **Camp IV**'s tents, then **stair 2** along the ridge to the **summit** (25 steps): prayer flags
   on posts, its rock a **sea fossil**. Snow on the tops, grey rock below, pines at its foot. "You reached Mount Everest!
   At 8,849 m it is the highest mountain on Earth." **Secret:** a golden chest on the summit: "You found a sea fossil on
   top of the world! The rock at Everest's top formed on the floor of an ancient sea: it holds fossils of sea animals
   called trilobites."
6. **Victoria Falls** (south; Zambia and Zimbabwe). A wide river flows north from a lake across the plateau and pours
   in a **curtain of water** 24 blocks down into a **narrow chasm of black basalt**, split by a rock buttress and
   **Livingstone Island** on the lip; a pool at the bottom, a **zigzag gorge** leading on; **spray** rising from the
   chasm over its lip (walk-through drops: "the smoke"), a **rainbow** arching over it by day; a dense **rainforest** on
   the far lip, watered by the spray, with a **path along the lip facing the falls** (a hedge with gaps) and a **stair
   down to the pool** (swim into the falling water!). "You reached Victoria Falls! Its Lozi name is Mosi-oa-Tunya: the
   smoke that thunders." **Secret:** a chest on Livingstone Island (swim across the calm river above the falls): "…From
   here in 1855 David Livingstone saw the falls and named them after Queen Victoria; local people had long known them."
7. **The Harbour of Rio de Janeiro** (south-east; Brazil). A round **bay** opening to the sea, two islands in it, a
   paved **promenade** on its north-west shore, a sandy beach round it; on its south side **Urca** and the **Sugarloaf**
   rising from the water (bare granite domes), joined by a rocky **ridge of steps** from the beach over Urca's top to the
   Sugarloaf's **lookout** (paved, a low white wall). "You reached the Harbour of Rio de Janeiro! Granite mountains like
   the Sugarloaf stand round its huge bay." **Secret:** a gap in the lookout's south wall, a step down, a little stone
   **climbers' ledge** with a chest: "…More than 270 climbing routes go up the Sugarloaf and the hills next to it."
8. **The Great Barrier Reef** (east, off the coast; Australia). A wooden **jetty** from the beach out to a sandy **coral
   cay** over a shallow **reef flat** covered in coral heads (brain coral, staghorn coral, sea fans), deeper blue sea
   round it; from a landing on the jetty a **glass tube** steps down into a **glass room on the reef** (look out at the
   corals and the fish); swim and dive anywhere (no drowning in the game). "You reached the Great Barrier Reef! It is the
   biggest thing on Earth built by living things: tiny corals." **Secret:** on the reef by the glass room lies **a ship's
   cannon** (coral growing on it) with a chest: "You found a ship's cannon! In 1770 James Cook's ship Endeavour ran onto
   the reef. Its crew threw six cannons into the sea to float free, and divers found them in 1969."
9. **The Grand Canyon** (north-east; Arizona). A **plateau** (12 over the park, pines on it) with the canyon cut into it,
   about 40 deep and 56 wide at its rim, its long way north-south, **its walls in layers** (the dark Vishnu schist at the
   bottom, the green-grey shale of the Tonto Platform, the Redwall's red-stained cliff, the Supai's red ledges, the cream
   Coconino cliff, the pale Kaibab rim, grass on top), the **Colorado River** in its bottom with sandy banks, three
   **buttes** standing in it; a **lookout** with a low wall on the west rim, a **glass walk** out over the canyon, and a
   **trail down a side gully**, a block a step, to the river's bank. "You reached the Grand Canyon! The Colorado River
   carved it, a little at a time, over millions of years." **Secret:** beside the trail, a little stone front with three
   doors in the cliff: the **granary** (a chest inside): "You found a hidden granary! About 900 years ago, Ancestral
   Puebloan people stored corn and seeds in little stone rooms high in the canyon's cliffs."
10. **Each wonder, once reached:** its fact (a toast, read aloud), a sparkle, then "Stamp! 16 of 21 wonders in your
    Wonders Passport. 2 of 7 of the Seven Natural Wonders of the World visited! Next: Mount Everest. Follow the arrow."
    The tour's last stamp: "… You visited all 7 of the Seven Natural Wonders of the World! The Seven Ancient Wonders wait
    along the Nature Trail. Follow the arrow." (the next tour not done, by its road; back to the landing square's tour by
    the road this one is at the end of).
11. **The plaques**: each card says how nature made it in place of when it was built ("Michoacán, Mexico · born in 1943 ·
    Quiet since 1952: …", "Nepal and China · pushed up over millions of years · A wonder of nature"), five or six real
    facts, QUIZ once stamped (three questions, +10 gold each right the first time, once).
12. **The Wonders Passport**: a third heading, "The Seven Natural Wonders · 0 of 7", over seven new stamps drawn in code
    (the canyon's layers over its river, the reef's corals and a fish, the Sugarloaf over the bay, Everest's snowy peak
    with a flag, the northern lights over a pine, Parícutin's glowing cone in its corn, the falls with a rainbow); 21
    stamps in all; a stamp not had yet says "… follow the Nature Trail south to the Seven Natural Wonders and walk to …".
13. **Loading hints** (world 41): "Take the Nature Trail south to the Seven Natural Wonders!", "The canyon's bottom rocks
    are about 2 billion years old.", "Tiny coral animals built the Great Barrier Reef.", "On dark nights, look up for the
    northern lights!", "Parícutin, a volcano, was born in a cornfield in 1943."
14. **Tilly** sells nature's blocks too (the canyon's six rocks, the sea fossil, the three corals, cinders, corn, prayer
    flags, waterfall spray).

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **The same world, a region of its own to the south, at the end of the Nature Trail** (a dirt trail: "a way that fits
   nature"), not a river path: a river would need its own water level all the way and crossings for the first park's
   paths. The region (radius 230 round (165, 410)) starts 212 blocks out, past the landing spot's farthest view (192);
   every natural wonder stands 240 blocks or more from it. *Cost:* a 425-block walk (speed pads from 198 out: about 50 s
   with them); moving `NATURE_SQUARE` moves every centre in `WonderTour` and `NatureGround` (a test checks they match).
2. **The trail's direction**: straight from the landing square toward the nature square, 68° (south-south-east), between
   the Hanging Gardens' path (43°) and the Great Pyramid's (96°): it keeps off every first-tour wonder and leaves the
   square at least 18° from any of their paths (tested). It crosses a corner of Giza's sand (dirt over it). *Cost:* none
   seen.
3. **The gap between the first park (flat to 190) and the region (from 212 along the trail)**: where the two blend rings
   overlap the blends multiply (`WondersShape._column`), so the gap stays level for the trail; everywhere else only the
   nearest region's blend counts, as before (the first two tours' ground is unchanged; tested by their tests). *Cost:* a
   few columns between the park and the region are flatter than before in old saves (a seam where saved chunks meet).
4. **Existing world-41 saves** get the region: its ground replaces the meadows there (the first tour shipped
   2026-09-30). A child who built far south before this update may see seams. *Cost:* a seam in a rare save.
5. **The wonders are the ground** (`NatureGround`: heights and kinds per column, the same in every world), what people
   built there are boxes (`WonderBuildsNature`), as the New Seven's hills were. A wonder's zone (its stamp) is its builds'
   bounds: the canyon's from its rim lookout, the reef's from the jetty, Rio's from the promenade, Everest's from base
   camp, the valley's from its deck, Parícutin's from its farm track, the falls' from the rainforest path. *Cost:* a child
   who reaches a wonder another way (flying over Everest's far side) gets its stamp only near its builds.
6. **Game scale, real numbers in the words**: the canyon about 40 deep (1,857 m), Everest 88 over the park (its summit at
   y 120, inside the streamed height from its foot: a view of 128 streams y 0-127), Lhotse 78, the col 62, the Sugarloaf
   36 over the sea (396 m), the falls 24 high (108 m), Parícutin's cone 26 (424 m), the reef 24 across. *Cost:* numbers
   in `NatureGround`.
7. **One sea for the reef and the harbour**: a round sea in the region's south-east (its shore a beach and a shelf); the
   bay of Rio opens into it and the reef lies off its coast 30 blocks east. No world-map order (as the New Seven's ruling
   6). *Cost:* none claimed.
8. **Directions kept where they are part of the story**: the northern lights in the valley's north sky; the falls' river
   flows into the chasm and the rainforest faces the falls on the far lip (as the real one, though here the river flows
   north); the lava field behind Parícutin to the north (the real flows spread round it); Everest's base camp east of
   it on the Nepal side, the South Col between Everest and Lhotse to its south (as the real one); the canyon's long way
   north-south (the real one runs mostly east-west: not claimed). *Cost:* turning a wonder.
9. **The northern lights only at night**: NatureSky shows them when the sky is dark (`DayCycle.look`'s stars) and the
   child is within 300 blocks of the valley (never from the landing spot); by day the sight's words say to look up on a
   dark night (a child may sleep or wait, or a Sandbox child types /time night). They are a few ribbons of vertex colours
   drawn with the night sky's star material settings (no new shader; the warm-up's sources test lists the script as
   "shares"). *Cost:* a child who only comes by day sees a snowy valley; the lead may want a day-time "aurora hut".
10. **Safe adventures, as the brief asks**: Parícutin's lava is the game's own (`HOT_LAVA`, Io's: a warm bounce, never
    hurts) deep in the crater behind a ring of rock, with a stair down and out (a child who jumps in climbs out); the
    glass walk and the underwater room are glass (break a pane and the sea flows in a little: the game's own water rule,
    no drowning); the falls' pool is reached by a stair and the curtain can be swum up; no fall damage anywhere (the
    lookout and the glass walk have low walls anyway). *Cost:* none.
11. **The real lava has stopped**: Parícutin has been quiet since 1952, so its card says "Quiet since 1952: here its
    crater glows as it did while it grew" (WonderFacts' own `status_words`). *Cost:* words.
12. **Religion as culture and belief** (spec §22.4): "Climbers hang prayer flags in five colours: Buddhists believe the
    wind carries their prayers"; the church of San Juan: "the lava … left its main altar standing. People still bring it
    candles and flowers" (no miracle claimed). No cross drawn on the tower. *Cost:* words.
13. **People of history only**: Dionisio Pulido (the farmer, 1943), Tenzing Norgay (1914-1986) and Edmund Hillary
    (1919-2008), James Cook (1728-1779), David Livingstone (1813-1873), Queen Victoria, Galileo; peoples named with
    respect (the Ancestral Puebloans, the Hualapai, the Havasupai, Aboriginal and Torres Strait Islander peoples, the
    Sherpa people, the Lozi, the Tupi). The 1997 list's maker (a TV news channel, CNN) is never named in the game (no
    brands). *Cost:* none.
14. **Honest words where it is not certain**: the bay was named River of January (not "they thought it was a river": the
    sources disagree); "Everest is still rising" is told as "India is still pushing" (the rate differs between sources:
    about 1 mm a year at Everest, more elsewhere); the reef "has more than 2,900 reefs" (not a count of fish species of
    our own). *Cost:* none.
15. **No new page**: the fourteen blocks fit page 37's free ids (642-655) and rows 1-3; page 43 stays free for the next
    tour. Page 37 now has see-through tiles (corn, prayer flags, spray), so its realistic page keeps alpha (about +2.5 MB
    of VRAM textures: the realistic pages 66.8 MB of the 70 MB budget, `test_page_sizes.gd`; room for about one more
    page before the budget needs a ruling). *Cost:* ~2.5 MB of APK.
16. **Reused blocks** (no new page material where one already exists in world 41's other tours or the game): Frostpeak's
    snow, snowy grass, packed snow, ice, blue ice, pines, ice lanterns and the fake snow door; Io's black lava rock (the
    lava field, the falls' basalt chasm) and hot lava; the New Seven's wall brick (the church tower) and its fake; the
    ancient tour's paving, white stone and plaque; page 0's grass, dirt, sand, stone, deep stone (the cannon), water,
    glass, leaves, logs, planks and colours (the tents). *Cost:* a chunk holding Io's or Frostpeak's blocks draws their
    page too (only in those wonders' chunks, never in the landing view).
17. **Corals are solid cubes** (brain coral, staghorn coral, a sea fan), not crossed pictures: a see-through block in
    water would show the water's surface round it. *Cost:* blockier corals.
18. **The falls' spray** is a walk-through block placed by the generator (a cloud of drops over the chasm and over the
    pool, fewer higher up), not particles: one more draw only in the falls' chunks, nothing to tick. *Cost:* a still
    cloud (it does not drift).
19. **Not built yet**: the Grand Canyon's North Rim and the Skywalk's horseshoe shape, the reef's turtles (the game's
    turtles live on land), Rio's cable car (told in a fact), Everest's Khumbu Icefall and the Hillary Step, reindeer in
    the valley, Parícutin's second buried village, the Victoria Falls Bridge, a moonbow at full moon. *Cost:* later
    content (the game never ends).
20. **The generator stays cheap**: nature's columns are worked out once per chunk column and kept (`WondersShape`'s
    `nature_sample`, behind a mutex, forgotten past 1,024 chunk columns: the generator asks a column for every chunk of
    its stack, its write, the trees and flowers round it), a tree's roll is checked before any ground is looked at (no
    ground grows more than 60 in a thousand: the rainforest, thinned from 90 when the falls' probe counted 332,000
    primitives), the nature region's trees look only at its own clearings and paths, a
    pine's chunk test skips the stack's other chunks. *Cost:* about 1 MB of kept samples while the region streams.

## The facts and their sources

Every line a child reads or hears (`core/books/wonder_facts.gd`: the sights, the cards' facts, the quizzes, the secrets,
the tour's words; the loading hints) was checked against these (web searches and pages read on 2026-10-01):
- **The list:** Wikipedia "Wonders of the World", section Seven Natural Wonders of the World
  (https://en.wikipedia.org/wiki/Wonders_of_the_World): compiled in 1997 (by CNN; not named in the game): the aurora,
  the Grand Canyon, the Great Barrier Reef, the Harbor of Rio de Janeiro, Mount Everest, the Parícutin volcano,
  Victoria Falls. Five continents counted from the seven (the aurora round the poles).
- **Grand Canyon:** Wikipedia "Grand Canyon" (https://en.wikipedia.org/wiki/Grand_Canyon): 446 km long, 6.4-29 km wide,
  1,857 m deep; the two-billion-year-old Vishnu Schist at the bottom, the 270-million-year-old Kaibab Limestone at the
  rim; the Colorado River's course 5 to 6 million years ago; Ancestral Puebloans the first people known there, the
  Nankoweap granaries; the Hualapai, Havasupai, Southern Paiutes, Navajo and Hopi; Wikipedia "Geology of the Grand
  Canyon area" (https://en.wikipedia.org/wiki/Geology_of_the_Grand_Canyon) and "Coconino Sandstone": the Redwall stained
  red from the Supai and Hermit above, the Coconino's old dunes; NPS "Fossils"
  (https://www.nps.gov/grca/learn/nature/fossils.htm): the Kaibab's marine fossils (brachiopods, crinoids, sponges) of a
  warm shallow sea; NPS "Condor Reintroduction and Recovery"
  (https://www.nps.gov/grca/learn/nature/condor-reintroduction-and-recovery.htm): condors back since 1996 (wings about
  3 m: Wikipedia "California condor"); the Nankoweap granaries built about 1100 by Ancestral Puebloans to store corn
  and seeds (Atlas Obscura, https://www.atlasobscura.com/places/nankoweap-granaries; river guides). The Skywalk (a glass
  walkway of the Hualapai, 2007) is the model of the glass walk but not named.
- **Great Barrier Reef:** Wikipedia "Great Barrier Reef" (https://en.wikipedia.org/wiki/Great_Barrier_Reef): over 2,900
  reefs and 900 islands over 2,300 km, seen from space, the biggest structure made by living things, built by coral
  polyps, more than 1,500 fish species, six of the seven sea turtle species, a World Heritage Site (1981) and a marine
  park (1975), long known to and used by Aboriginal Australian and Torres Strait Islander peoples; NOAA "The Coral and
  the Algae" (https://oceantoday.noaa.gov/fullmoon-coralandalgae/welcome.html) and NOAA "Are corals animals or plants?"
  (https://oceanservice.noaa.gov/facts/coral.html): corals are animals related to jellyfish, building limestone
  skeletons; algae inside them feed them and give their colour; too-warm seas make them bleach; Wikipedia "HMS
  Endeavour" (https://en.wikipedia.org/wiki/HMS_Endeavour): aground on the reef on 11 June 1770, six cannons thrown
  overboard, found in 1969.
- **Harbour of Rio de Janeiro:** Wikipedia "Guanabara Bay" (https://en.wikipedia.org/wiki/Guanabara_Bay): 31 by 28 km,
  more than 130 islands, Portuguese explorers on 1 January 1502 naming it River of January (whether they thought it a
  river is disputed: not claimed), Guanabara from the Tupi language; Wikipedia "Sugarloaf Mountain"
  (https://en.wikipedia.org/wiki/Sugarloaf_Mountain): 396 m at the bay's mouth, granite and quartz, named after the
  cone-shaped moulds of refined sugar on Portuguese ships, its cable car since 1912 (Morro da Urca, 220 m, between),
  more than 270 climbing routes; Corcovado and Christ the Redeemer: `wonders-new-seven.md`.
- **Mount Everest:** Wikipedia "Mount Everest" (https://en.wikipedia.org/wiki/Mount_Everest): 8,848.86 m (the 2020
  survey: "8,849 m"), between Nepal and China, Sagarmatha (Nepali), Chomolungma (Tibetan), formed by the Indian plate's
  collision with Asia, its summit's Qomolangma Formation limestone with marine fossils (trilobites, crinoids), Tenzing
  Norgay and Edmund Hillary first on 29 May 1953; National Geographic "Why Mount Everest keeps changing its height"
  (https://www.nationalgeographic.com/science/article/why-mount-everest-can-grow-and-shrink-plate-tectonics): the
  collision continues, India still pushing; Wikipedia "South Col" (7,906 m, Camp IV) and "Everest base camps" (South
  Base Camp 5,364 m); Wikipedia "Sherpa people" (https://en.wikipedia.org/wiki/Sherpa_people): Khumbu, many work as
  mountaineering guides; Wikipedia "Prayer flag" (https://en.wikipedia.org/wiki/Prayer_flag): five colours, the belief
  that the wind spreads the prayers.
- **Northern Lights:** Wikipedia "Aurora" (https://en.wikipedia.org/wiki/Aurora): charged particles from the Sun (the
  solar wind) hitting the upper atmosphere guided by Earth's magnetic field to the auroral zones round both poles,
  oxygen green and red, nitrogen blue, most of it about 100 km up, the aurora australis, Galileo's name of 1619 (Aurora,
  the Roman goddess of dawn; Boreas, the north wind), auroras on Jupiter and Saturn; University of Alaska Fairbanks
  Geophysical Institute "Aurora Forecast" (https://www.gi.alaska.edu/monitors/aurora-forecast) and Space.com
  (https://www.space.com/15139-northern-lights-auroras-earth-facts-sdcmp.html): seen only when the sky is dark, best on
  long winter nights in the far north (Norway, Iceland, Finland, Canada, Alaska).
- **Parícutin:** Wikipedia "Parícutin" (https://en.wikipedia.org/wiki/Par%C3%ADcutin): born on 20 February 1943 in
  Dionisio Pulido's cornfield, 50 m in a day, erupted until 1952 to 424 m, burying Parícutin and San Juan
  Parangaricutiro (the church's top still out of the lava), the first time science documented such a volcano's whole
  life, a cinder cone in the Michoacán-Guanajuato volcanic field of about 1,400 vents; Wikipedia "San Juan
  Parangaricutiro" (the new town, 1944); Lonely Planet "Volcán Paricutín"
  (https://www.lonelyplanet.com/mexico/western-central-highlands/angahuan/attractions/volcan-paricutin/a/poi-sig/1467715/361675):
  the lava went through the church but left the main altar standing, with offerings of candles and flowers.
- **Victoria Falls:** Wikipedia "Victoria Falls" (https://en.wikipedia.org/wiki/Victoria_Falls): 1,708 m wide, 108 m
  high, the largest sheet of falling water, the Lozi name Mosi-oa-Tunya ("the smoke that thunders"), the Zambezi between
  Zambia and Zimbabwe, spray over 400 m seen up to 50 km away, rainbows and moonbows, David Livingstone on 16 November
  1855 from Livingstone Island naming them after Queen Victoria, the zigzag gorges in the basalt showing the falls' past
  positions, a World Heritage Site (1989); the rainforest on the facing cliff watered by the spray every day (Wikipedia
  and visitor guides).

## Built (files)

- Where: `world/wonders/wonder_tour.gd` (the seven entries, `NATURE_SQUARE`, `NATURE_R`, `SQUARES`, `trail`,
  `trail_pads`, `trail_signpost`, `line_cells`, `nature_distance`, `in_nature_region`, `TRAIL_BLOCK`,
  `NATURE_PATH_BLOCK`).
- Ground: `world/wonders/nature_ground.gd` (new: the region's heights and kinds, the canyon's strata and buttes, the
  cone, the valley, the massif and its stairs, the falls, the bay and the Sugarloaf, the reef, the sea, the snow, the
  trees, corn, corals and spray), `world/generators/wonders_shape.gd` (the region, the blend, `nature_sample`'s cache,
  the trees, flowers, sand), `wonders_generator.gd` (`_write_nature_column`, `_place_nature`, `_write_pine`, no caves).
- What: `world/wonders/wonder_builds_nature.gd` (new: the seven builds and their tree clearings),
  `world/wonders/wonder_builds.gd` (the match, the trail and its pads, dirt paths, the trail's signposts).
- Secrets: `world/generators/wonders_secret_rules.gd` (`NATURE_TOUR_AREAS`, the seven secrets).
- Words: `core/books/wonder_facts.gd` (`NATURAL`, `NATURE`, `NATURE_TOUR*`, the seven, `TOURS[...].road/way`,
  `when_words`, `status_words` overrides), `core/books/wonders_passport_rules.gd` (the clue's way, the next tour's road),
  `core/rules/loading_hints.gd`.
- The child's: `world/wonders/wonders_director.gd` (MY MAP's nature square, the trail's signs, short names in the
  three-column card, `sky_time`, NatureSky), `world/wonders/nature_sky.gd` (new: the aurora and the rainbow),
  `ui/books/wonder_card.gd` and `ui/books/wonders_passport_page.gd` ("formed" words), `ui/books/wonder_stamp.gd` (seven
  emblems), `world/universes/wonders.gd` (landing words, Tilly's stock), `scenes/sandbox.gd` (the sky's time to the
  director: one line).
- Blocks: `data/blocks/block_ids.gd` (642-655, three walk-through), `world/universes/wonders_blocks.gd`
  (`TILES_NATURE`, `page_37_tiles`); pictures by `tools/make_wonders_nature_page.gd` and
  `tools/make_wonders_nature_realistic.py` into page 37's rows 1-3 (the New Seven's tools say to run these after them);
  credits in `assets/CREDITS.md`.
- Tools: `tools/wonders_smoke_steps.gd` (the third tour's visits, its square's plaque, the ice cave, the aurora by night
  and day), `tools/space_shots_steps.gd` (`--nature`), `tools/wonders_draw_probe*.gd` (`--at=nature|<wonder>`,
  `--night`), `tools/frame_probe_steps.gd` (`--phases=nature-trail`: down the trail on foot, a flight round the seven).
- The warm-up's sources test lists `world/wonders/nature_sky.gd` as "shares" (the star material's settings).

## Tests

New: `tests/unit/test_wonders_nature.gd` (the tour's list, the region out of the landing view and apart from the New
Seven's, the trail and its pads, the trail's signs and the square, the places apart and out of view, level dirt paths,
the meadows far out and the blend, honest words, the passport for three tours, the stamps' inks),
`test_wonders_nature_ground.gd` (the ground's copies of the places, the canyon's layers in order, its buttes and river,
the trail a block a step, the cone, crater, farm and lava field, the valley, Everest over Lhotse and the col with both
stairs, the falls, the bay and the Sugarloaf's steps, the reef, the sea, the snow, the trees never on a build),
`test_wonders_nature_builds.gd` (each build and a child's walk: down the canyon's trail, onto the glass walk, into the
granary; along the jetty and down into the glass room; round the bay up to the Sugarloaf's lookout; base camp to the col
and the summit; into the cabin and onto the deck; up Parícutin's rim, round it, into the crater and out; to the falls'
lip and down to the pool), `test_wonders_nature_secrets.gd` (a secret each, inside its own area, the ice cave and the
tower room shut until the knock, the chests reached on foot, the reef's by the cannon, the island's),
`test_wonders_nature_blocks.gd` (page 37, names, walk-through, models and materials, both pictures, looks),
`tests/integration/test_wonders_nature_world.gd` (the generator writes the builds and secrets exactly, the canyon's
layers and river, the falls, spray and pool, corals under water, corn, the frozen lake, Everest's snow, no caves, the
trail). Changed: `test_wonders_tour.gd`, `test_wonders_new_seven.gd`, `test_wonders_passport.gd`,
`test_wonders_universe.gd`, `test_wonders_secrets.gd`, `test_wonders_builds.gd`, `test_wonders_new_blocks.gd` (21
wonders; nature's trees and dirt paths; page 37's rows), `tests/integration/test_wonders_director.gd` (three columns, 49
names, the third square on MY MAP, nature's stamps and cards, the northern lights by night and the rainbow by day),
`tests/integration/test_wonders_world.gd`, `test_shader_warmup_sources.gd`.

## Measurements

On this desktop (24 cores, Intel iGPU; another app's builds and two other agents ran at the same time, load 6-17), so
the milliseconds are noisy and the draw counts are what to compare.

**Draws** (`tools/wonders_draw_probe.gd`, a real window at 1280 x 720, the blocky style, 120 frames looking each way;
the average of the four):

| Where | Draws | Primitives | Frame ms (worst) |
|---|---|---|---|
| The landing spot, lead-merge | 220 | 145,978 | |
| The landing spot, this branch | 215 | 141,255 | (the region is past the landing's view: nothing new drawn) |
| The nature square | 248 | 221,426 | 7.0 (22) |
| The Grand Canyon's gate | 236 | 190,440 | 5.8 (14) |
| The reef's gate | 223 | 179,075 | 5.0 (16) |
| Rio's gate | 246 | 228,826 | 5.4 (17) |
| Everest's base camp | 244 | 290,985 | 7.6 (17) |
| The valley by day | 233 | 253,923 | 8.5 (28) |
| The valley at night (the aurora's 3 ribbons) | 216 | 237,523 | 8.7 (38) |
| Parícutin's gate | 222 | 201,444 | 6.7 (23) |
| The falls' gate, first | 252 | 331,541 | 9.4 (14) |
| The falls' gate, the rainforest and spray thinned | 251 | 302,481 | 9.6 (19) |

A natural wonder in view costs at most 37 draws more than the landing spot; the valley at night, its aurora's three
ribbons included, draws 17 fewer than by day (the probe's two runs; why fewer was not looked into). The most primitives are at the falls (the rainforest's
leaves, the spray's cut-out cubes) and on Everest (a big mountain in view); both stay in the draws of the rest.

**The generator** (`tools/bench_generator.gd -- --wonders`, the two generators alternating chunk by chunk, after the
optimizations; milliseconds a 16³ chunk, average and worst):

| Over | Meadows | Wild meadows | World 41 | World 41 worst |
|---|---|---|---|---|
| The landing (all kinds) | 1.82 | | 1.24 | |
| Grand Canyon, surface | 1.29 | 0.87 | 1.37 | 6.71 |
| Barrier Reef, surface | 1.22 | 0.72 | 1.14 | 4.41 |
| Rio, surface | 1.49 | 1.09 | 1.53 | 8.28 |
| Everest, surface | 1.47 | 1.05 | 1.91 | 7.77 |
| Northern Lights, surface | 1.13 | 0.63 | 1.17 | 3.79 |
| Parícutin, surface | 1.62 | 1.12 | 1.95 | 6.17 |
| Victoria Falls, surface | 1.26 | 0.88 | 1.39 | 4.75 |
| The seven, underground | 1.17-1.88 | | 0.37-0.58 (no caves) | 2.62 |

Before the optimizations (ruling 20) the same chunks took up to 4.03 ms at Everest and 3.75 at the valley (about
1.6 times the meadows); now at most 1.3 times the meadows, and the worst chunk (8.3 ms, Rio's bay and the Sugarloaf)
is under the meadows' own worst underground (up to 23.7 ms). The builds' boxes (5,936 for the 21 wonders and the
squares, roads and trail; the New Seven's notes: 4,297 in 14.4 ms) are made once at world 41's load in 17-35 ms (three
runs); `WondersShape.new` (the clearings) 0.3-0.7 ms.

**Frames down the trail** (`tools/frame_probe.gd -- --phases=nature-trail --over=50 --no-blame --voxel-threads=2`,
headless: the game's logic, not the drawing): a new Survivor world 41, 68 s walking the Nature Trail from the landing to
the nature square (its speed pads), then 205 s flying 20 m over the ground round the seven and back:

| Phase | Frames | Average ms | Worst ms | Over 16 ms | Over 33 ms |
|---|---|---|---|---|---|
| Standing | 725 | 6.9 | 17 | 1 | 0 |
| The walk | 9,892 | 6.9 | 14 | 0 | 0 |
| The flight | 29,768 | 6.9 | 22 | 11 | 0 |
| Hovering at the end | 726 | 6.9 | 10 | 0 | 0 |

(The load's one long frame, 8.2 s, is a fresh process loading every script and scene behind the loading screen; any
world's first load in a cold process does it.)

**The realistic pages** (`tests/unit/test_page_sizes.gd`): 66.8 MB of the 70 MB budget (page 37's rows 1-3 added
about 2.5 MB: it keeps alpha for the corn, flags and spray; ruling 15).

**The smoke** (`tools/smoke_all.sh wonders`, a real window; the three tours' visits, the nature square's plaque, the
ice cave's knock, the aurora by night and not by day): **130 checks, 0 fails**, 65 s on the final code (74 s before the
last optimizations).

**The full suite** (`tests/run_tests.sh`, once at the end, 57 min at a load up to 20): 1,034 scripts, 9,490 tests,
9,484 passing, 4 failing. Two were this branch's: `test_block_library`'s every-block-is-a-cube test did not know a
page block may be crossed (corn: it now reads the page's `cross` extra, as with page 0's flowers and wheat), and
`test_wonders_universe` still expected the old landing words. Both are fixed, and those two files were rerun: 33 passing. The
other two (`test_lesson_short.gd`: the first card's words, a card's next sentence's headline) are lead-merge's at this
branch's base 89ca0648 (the lessons' quality round rewrote the lessons) and are fixed on lead-merge by 4c9ef554; this
branch touches no lesson. No SCRIPT ERROR. A test merge with today's lead-merge (47f35a8b: the Reel Studio, the
visuals) is clean (`git merge-tree`); the visuals' change to `SkyCycle._night_material` (no forced colour decode) reaches
NatureSky's material by itself, since NatureSky calls that function.

**Pictures** (`tools/space_shots.gd -- --universe=41 --nature`, both styles, 32 views): the canyon's coloured layers
and its three buttes from the rim, the glass walk over the gorge, the jetty and the glass room among the corals, the
bay's promenade and the Sugarloaf's lookout, base camp and the summit's flags, the frozen lake by day and the aurora's
green-to-violet ribbons over it at night, Parícutin's black cone over the cornfield and its glowing crater, the falls'
spray cloud and rainbow over the chasm from the rainforest path, the pool from below, the region from above. Looked at
and judged; nothing broken in either style.

## What the lead must check on the emulator

1. World 41's landing view as before (215 draws a frame here against 220 on lead-merge), then the Nature Trail on foot
   (its dirt, the speed pads' whoosh, the snow beginning past the park; the new frame probe phase `nature-trail` walks it
   and flies round the seven).
2. The frame rate at each natural wonder in both styles (≥ 30 FPS, no frame over 100 ms): the canyon from its rim (a
   deep view, many strata faces), the reef's glass room (glass all round, water, corals), the falls (the spray cloud's
   cut-out faces, the water curtain, the rainforest's trees), Everest from base camp and from its summit (a big
   mountain in view), the snowy valley at night (the aurora's see-through ribbons over the screen), Parícutin's crater.
3. The northern lights at night on a phone: their brightness, their slow sway, that they are not drawn by day nor from
   the landing spot; the rainbow by day at the falls.
4. The explorer's card's three columns on a phone's screen; the passport's three sections scroll; the new stamps.
5. Walks: the canyon's trail down the gully (a block a step, 27 steps), the glass walk, Everest's 62 + 25 steps (long:
   is it fun or tiring?), the Sugarloaf's steps, Parícutin's stair and the crater's stair, the falls' stair to the pool;
   swimming up the falls' water; diving to the cannon (the chest underwater opens?).
6. Knocks: the ice cave's snow door, the church tower's brick; the banners and facts.
7. Survivor: the trip, the quiz gold, Tilly's new blocks; the corn, flags and spray placed by a child.
8. MY MAP with 24 places (21 wonders, the landing spot, the two squares) and the arrow's choice after the first two tours.

## Next (the game never ends)

More of nature's wonders (the Amazon, the Sahara, Ha Long Bay, the Northern Lights' southern twin), the wonders people
built later (Stonehenge, the Eiffel Tower, the Sydney Opera House, the Panama Canal), a day-time "aurora hut" if the
lead wants one, the reef's sea turtles in the water, Rio's cable car to ride, Everest's Khumbu Icefall, the Victoria
Falls Bridge, a moonbow at full moon, the School's geography units linking "Visit it in the game".
