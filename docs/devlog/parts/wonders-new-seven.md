# The world's wonders, second tour: the New Seven Wonders (world 41, spec §24)

The owner (#78): "we must have world wonders, all wonders in the game. so all things must be educational in the game,
close to real world". Brief: `docs/superpowers/plans/2026-09-29-world-wonders-brief.md` with TOUR = "the New Seven
Wonders (chosen in 2007): the Great Wall of China, Petra, the Colosseum, Chichen Itza, Machu Picchu, the Taj Mahal,
Christ the Redeemer", in the same world as the first tour (`wonders-ancient.md`). Built by a worker agent in its own
worktree (branch `worktree-agent-ae5f6b15259d115e7`, reset to `lead-merge` 1d4ff0af), without the editor, the emulator
or adb (one windowed run of `tools/space_shots.gd` for pictures). Running beside it: Venus's cloud city (world 24, page
38, ids 656-671) and grade 6's computing, art and music; none of their files touched.

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World | 41 (the same world, a second region) | its west: `WonderTour.NEW_SQUARE` (−350, 0), `NEW_R` 180 | |
| Block ids, pages 36-37 (`WondersBlocks.TILES_NEW`, `TILES_NEW_MORE`) | 624-655 | 624-641 | 642-655 (the next tours) |
| `BlockIds.COUNT`, `NEXT_PAGE_FIRST_ID` | → 656 | 656 | |
| Atlas pages | 36 (`wonders3*.png`, 3 rows) and 37 (`wonders4*.png`, 1 row) | | rows 3-7 and 1-7 |
| Secrets' numbers | `WondersSecretRules.FIRST_ATTEMPT` + 7…13 (107-113) | the first tour's keep 100-106 | |
| Item ids, animals, HUD spots, server | none | | |

## What a child sees

1. **Landing** (the same spot, the ancient square): "Welcome to the Wonders of the World! Follow the red arrow: the Seven
   Ancient Wonders are here, the New Seven along the Wonders Road." The explorer's card is now **EXPLORE THE WONDERS OF
   THE WORLD**: "The Seven Wonders of the Ancient World stand round this square: only the Great Pyramid still stands, the
   rest are built as people believe they looked. The New Seven Wonders wait along the Wonders Road to the west. Each one
   stamps your Wonders Passport. Follow the red arrow!", then two columns, **The Seven Ancient Wonders** and **The New
   Seven Wonders**, each nearest first, "(found!)" on the ones reached. The red arrow points to the nearest wonder not
   reached (the ancient ones first, being nearer; once they are all reached, the New Seven).
2. **The Wonders Road.** An eighth signpost on the landing square, "The New Seven Wonders (Wonders Road)" (light blue),
   and a sandy road 3 wide running straight west between the Temple of Artemis and the Temple of Zeus, 330 blocks,
   level, no tree on it; past the first park (198 blocks out) a row of **speed pads** across it every 24 blocks (a whoosh
   along the way the child goes, either way). About 55 s at a walk, less with the pads; in the Sandbox a child may fly.
3. **The New Seven's square**: a round of paving, seven signposts with the names floating over them, the plaque "The
   New Seven Wonders" (its card: "In 2007 people all over the world voted on the internet and by phone for the New Seven
   Wonders", all seven still stand on four continents, the Great Pyramid's place of honour, a popular vote: many other
   amazing places were not on the list; and which the child has visited), a signpost back, "The Seven Ancient Wonders
   (Wonders Road)". MY MAP marks it ("The New Seven Wonders").
4. **The Great Wall of China** (north of the square; the real one: northern China). A long wall of grey **wall bricks**
   (113 blocks) along the crest of a green ridge, its walkway (4 wide) rising and falling with the hill a block at a time,
   a low parapet on its inner (south) side and **battlements facing north**, where raiders came from; **five
   watchtowers** the walkway passes through (arrow windows, a lamp inside, battlements on their roofs), a **beacon fire**
   on the east one; a stair from the path's end up the ridge into the middle tower. Walk the whole wall, tower to tower.
   "You reached the Great Wall of China! It runs for thousands of kilometres over mountains and deserts." **Secret:** a
   cracked brick at the foot of the tower east of the middle one (on the ridge's south slope) opens onto the tower's
   **store room** (a chest, a lamp): "…Guards on the Great Wall sent messages with smoke by day and fire by night."
5. **Petra** (south-east of the square; Jordan). A weathered cliff of **rose rock** (ribs of different heights, worn
   corners, banded rose, red, cream and plum) on Petra's sand. The **Siq**: a narrow gorge 3 wide, open to the sky,
   winding in; it opens onto a court (14 deep) before the **Treasury**, carved in the cliff: six rose columns before a porch, the
   entablature and a pediment, the upper storey's round **tholos** between two half-pediments, the **urn** on top; its
   door leads into a plain chamber (lit). "You reached Petra! The Nabataeans carved this city's buildings right into the
   rose-red rock." **Secret:** a stair cut in the rock from the court's east side climbs inside the cliff (a flight back,
   a landing, a flight forward) and out onto a **ledge along the facade by the urn** (a low wall on its edge): a golden
   chest: "You found treasure by the urn! People once thought treasure was hidden in the Treasury's stone urn, but it
   is solid rock."
6. **The Colosseum** (west-north-west; Rome). An oval of cream **travertine**, 58 × 48 blocks, its long way east-west
   as the real one: three storeys of arches and a solid top storey on the north side; **on the south side only two
   storeys, broken off**, as today. In at any of the four entrances on its axes (the path arrives at the east one), a
   **sand arena**, tiers rising all round it a block at a time up to a walk behind the top tier (13 up; a railing where
   the outer wall broke off), a corridor under the tiers, a stair up the tiers on the north and south sides. "You reached
   the Colosseum! About 50,000 Romans sat here to watch shows, almost 2,000 years ago." **Secret:** a cracked block low in
   the arena's wall at its west end: steps down to the **tunnels under the arena** (a wooden lift's floor, a post, lamps,
   a chest): "…Lifts once raised scenery and animals up through trapdoors into the arena."
7. **Chichen Itza** (west; Mexico). **El Castillo**: nine terraces of pale **Maya stone** (39 wide, 18 up), a stair up
   each of its four sides (18 steps here, 91 on the real one: its fact says so) between balustrades, the **feathered
   serpent's heads** at the foot of the **north** stair (as the real one), the temple on top with its carved band, its
   roof crest, a wide north door with two serpent heads before it and a door on each other side. "You reached Chichen
   Itza! The Maya built this pyramid for Kukulcan, the feathered serpent they believed was a god." **Secret:** a cracked
   stone low in the north stair's west balustrade: a tunnel under the stair and a stair up inside to **the pyramid inside
   the pyramid**: a room with the **red jaguar throne** (red with jade spots), lamps, a chest: "…In the 1930s explorers
   found an older temple inside, with a red jaguar throne."
8. **Machu Picchu** (south-west; Peru). Six terraces of fitted grey **Inca stone** with grass on them, a stair up the
   middle to the plaza (12 up); east of the plaza six stone houses with **thatched gabled roofs**; west, the **Temple of
   the Sun** (a curved tower on its rock, two small windows), the **Temple of the Three Windows**, the **Intihuatana**
   stone on its knoll; **Huayna Picchu**, a steep green sugarloaf peak, rises behind (44 up). "You reached Machu Picchu!
   The Inca built this town high in the Andes mountains, 2,430 m above the sea." **Secret:** a cracked Inca stone in the
   walled east face of the Temple of the Sun's rock: **the cave under it** (a stepped altar, a lamp, a chest): "…People
   call it the Royal Tomb, but no one knows for sure what it was for."
9. **The Taj Mahal** (north-east; India). Through the great **gate** of red sandstone (its arch framed in inlaid marble,
   small white domes with golden tips along its top) into the **garden**: the long water channel and the paved walk, the
   cross walk, a raised marble pool in the middle, rows of dark **cypresses**; up three steps onto the marble **plinth**;
   the **tomb** (eight-sided, a great arch on each side framed in **inlaid marble** with coloured stone flowers), inside the
   hall **Mumtaz Mahal's tomb in the middle and Shah Jahan's beside it** under a hanging lamp; the **onion dome** bulging
   wider than its drum, its **golden top** (35 up), four small domed kiosks round it; **four minarets** at the plinth's
   corners (three balconies, a kiosk on top); the **river** behind it to the **north**, as the real one's Yamuna.
   "You reached the Taj Mahal! Emperor Shah Jahan built it of white marble in memory of his wife, Mumtaz Mahal."
   **Secret:** one minaret (the back one on the west side) has a door facing the tomb and a **spiral stair** inside up to
   its top balcony: a golden chest: "…The four minarets lean a little outward, so an earthquake would topple them away
   from the tomb."
10. **Christ the Redeemer** (south; Brazil). **Corcovado**, a green mountain 40 up, a stair of **40 white steps** with a
    low wall each side from the path's end to the **summit's terrace** (a low wall round it), the pedestal, and the statue
    of pale **soapstone** tiles (25 tall), its **arms spread wide** (25 across), **facing the square**; seen from all over
    the region (its head 102 up). "You reached Christ the Redeemer! It is a statue of Jesus, whom Christians believe is
    the Son of God." **Secret:** a cracked white stone at the back of the pedestal: the **room inside it** (a lamp, a
    chest): "…Workers climb stairs inside the statue and come out of small hatches on its arms and head to fix it."
11. **Each wonder, once reached:** its fact (a toast, read aloud), a sparkle, then "Stamp! 9 of 14 wonders in your
    Wonders Passport. 2 of 7 of the New Seven Wonders visited! Next: Petra. Follow the arrow." The tour's last stamp:
    "Stamp! You have all 7 stamps of the New Seven Wonders! … You visited all 7 of the New Seven Wonders! The Seven
    Ancient Wonders wait along the Wonders Road. Follow the arrow." All fourteen: "Your Wonders Passport is full…".
12. **The plaques** by each wonder's gate: its card (the stamp, "Rome, Italy · built from AD 70 to 80 · Still standing",
    five or six real facts, QUIZ once stamped: three questions, +10 gold each right the first time, once).
13. **The Wonders Passport** (the Books' WONDERS tab): two headings, "The Seven Ancient Wonders · 3 of 7" and "The New
    Seven Wonders · 1 of 7", each over its seven stamps (the New Seven's drawn in code: the Wall over its hills with a
    tower, Petra's rose facade and urn, the Colosseum's arches broken on one side, El Castillo's steps and temple, Machu
    Picchu's terraces under its peak, the Taj Mahal's dome between minarets, the statue's open arms on its mountain);
    "14 stamps" in all; a stamp not yet had says how to get there ("… follow the Wonders Road west to the New Seven
    Wonders and walk to Petra.").
14. **Loading hints** (world 41): "Take the Wonders Road west to the New Seven Wonders!", "Walk along the top of the Great
    Wall.", "Walk through Petra's narrow gorge to the Treasury.", "Machu Picchu's stones fit together without any mortar."
15. **Tilly** sells the New Seven's blocks too (wall brick, rose rock, rose stone and column, travertine, Maya stone and
    carving, the serpent's head, the jaguar throne, Inca stone, soapstone, inlaid marble, the gate's red stone).

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **The same world, a region of its own at the end of a road** (not squeezed into the first park): the first park is
   flat with its sea to the north-east, and the New Seven need hills (the Wall's ridge, Corcovado, Huayna Picchu) and
   room (the Colosseum alone is 58 × 48). The region is round its own square with its own signposts, 350 blocks west.
   *Cost:* a long road (hence the speed pads); the region's constants in `WonderTour` and `NewSevenGround`.
2. **West, along z = 0**: the widest gap between the first tour's paths (Artemis's and Zeus's are 33-41° either side);
   the road passes between their temples and stays clear of both paths. *Cost:* moving `NEW_SQUARE` moves every new
   centre and `NewSevenGround`'s three hill centres (a test checks they match).
3. **Existing world-41 saves** get the new region: its ground replaces the meadows there (the first tour shipped the same
   day). A child who built out west before this update may see a seam where saved chunks meet the new ground. *Cost:* a
   seam in a rare save.
4. **Game scale, real numbers in the words** (as the first tour): the Colosseum 58 × 48 × 16 (1:3.2 of 189 × 156 × 48 m),
   El Castillo 9 terraces and 18 steps a side (the fact gives 91), the Great Wall 113 long with 5 towers, the Taj Mahal's
   golden top 35 up (73 m), Christ the Redeemer 25 tall on a 6-high pedestal on a 40-high Corcovado (30 m, 8 m, 710 m),
   Petra's Treasury about 28 high (39 m), Machu Picchu's six terraces. *Cost:* numbers in `WonderBuildsNew`.
5. **Directions kept true where they are part of the story**: the Great Wall's battlements face north; the Taj Mahal's
   gate and garden to the south, its river to the north; El Castillo's serpent stair to the north; the Colosseum's long
   way east-west, its broken outer ring on the south. **Not kept**: Christ the Redeemer faces the square (north; the real
   statue faces east) so a child climbing the stair meets his face; Huayna Picchu stands south of the citadel here (the
   real one is north of it) so a child arriving from the square sees the postcard view, the town with the peak behind;
   Petra's Treasury faces west (toward the square). No word claims a direction for these. *Cost:* turning a wonder.
6. **No world-map order** round the square (the Great Wall is north because of its battlements, the rest where they fit):
   not claimed anywhere. *Cost:* none.
7. **Religion as culture and belief** (spec §22.4): Christ the Redeemer "is a statue of Jesus, whom Christians believe is
   the Son of God"; Kukulcan, "the feathered serpent they believed was a god"; the Taj Mahal's "verses from the Quran,
   the holy book of Islam". Left out: the chapel in the statue's base (consecrated 2006: the pedestal room is the
   workers'), any holy script drawn on a block (the Taj Mahal's calligraphy is told, not drawn), the mosque beside the
   Taj Mahal (not built yet). The two tombs in the Taj Mahal are plain inlaid blocks. *Cost:* words.
8. **Hard history named with respect, never shown**: the Great Wall's forced labour ("Soldiers, farmers and prisoners
   were made to build it. The work was hard, and many died."), the Colosseum's gladiators and builders ("Many of them, and
   many of its builders, were enslaved people."), the conquest ("Spanish conquerors took their empire but never found
   it."). No fight, hunt or sacrifice is built or told (Chichen Itza's sacred cenote is not built; its ball game is told as
   a game). *Cost:* words.
9. **People of history only**: Vespasian, Titus, Pachacuti, Shah Jahan, Mumtaz Mahal, Heitor da Silva Costa (1873-1947),
   Paul Landowski (1875-1961); the Ming dynasty, the Nabataeans, the Maya, the Inca. Petra's 1812 traveller (Johann Ludwig
   Burckhardt) and the 2007 vote's organiser (living) are not named. *Cost:* none.
10. **One secret per wonder** (five rooms behind fake stones, two golden chests up high), each with its fact; the first
    tour's secret ids are unchanged (the new ones take attempt numbers 107-113). *Cost:* none.
11. **Speed pads across the road** (`PadRules`: 14 m/s for 1.5 s along the way the body goes; animals too), only past
    the first park, from 198 blocks out: out of the landing spot's view (`GraphicsPreset.MAX_VIEW_DISTANCE` 192), since a
    pad's glowing material is one more draw in each chunk that holds one. *Cost:* the first 190 blocks are walked (~32
    s); a row of pads back to sand if children find them odd.
12. **The explorer's card lists both tours side by side** (`PlanetGuideCard` got an optional `groups`: a small additive
    change in the space card). *Cost:* none measured; check it fits a phone.
13. **The floating names hide with distance** (Label3D's `visibility_range_end`): a square's signposts' names past 140 m
    (`WondersDirector.LABEL_RANGE`), a wonder's plaque's name past 60 m (`PLAQUE_LABEL_RANGE`), the first tour's too. 32
    names now, but from the landing spot only the square's own 9 show (all 15 did before). *Cost:* a plaque's name appears
    as you come near its wonder.
14. **A railing on the Colosseum's top walk where the outer wall broke off** (the game has no fall damage, but a
    13-block drop off the broken side). *Cost:* none.
15. **The realistic pages' budget: 54 → 60 MB** (`test_page_sizes.gd`): the colonies' page 31 (merged into lead-merge)
    and these two brought them to 55.4 MB (pages 36-37 about 2.1 MB: a 3-row page ~1.6, a 1-row page ~0.5). 60 leaves room
    for Venus's page 38 and about two more. *Cost:* up to ~6 MB more APK.
16. **`test_prospect_blocks.gd`'s "held page" test failed on lead-merge** (it held page 31 empty for the domes; the
    colonies own it now): it checks page 31 is the colonies' instead. *Cost:* none (the lead may prefer its own wording).
17. **Names in sentences**: `WonderFacts.called` ("the Great Wall of China", but "Petra", "Chichen Itza", "Machu Picchu",
    "Christ the Redeemer"), used by the progress words and the clue. *Cost:* none.
18. **The tours are data** (`WonderFacts.TOURS`, `tour_ids`, `tour_of`; `WonderTour.SQUARES`): a third tour is an entry
    there plus its places, builds and secrets; the passport's headings, the guide's columns, MY MAP and the sights follow.
19. **The first tour's words where "Seven Wonders" became ambiguous**: the pyramid's sight now says "the only one of the
    Seven Ancient Wonders still standing", its loading hint "Of the ancient seven, only the Great Pyramid still stands!",
    and the landing square's plaque adds that the New Seven wait along the Wonders Road. *Cost:* none.
20. **Not built yet**: the Taj Mahal's mosque and its twin (red sandstone, beside the plinth), llamas at Machu Picchu
    (the game has no llama), Chichen Itza's ball court and cenote, the Siq's old arch, the other three minarets' stairs.
    *Cost:* later content (the game never ends).
21. **The Colosseum's underground is a secret room**, not the open grid of walls visible today (a child falling into a
    3-deep maze in the arena). *Cost:* the arena floor is whole.
22. **The spawn view no heavier** (the lead, 2026-09-30: world 41 was the day's slowest world, 39 FPS blocky on the
    emulator at load 11, one 100.7 ms frame after spawn). The New Seven stand 224 blocks or more from the landing spot,
    past the farthest view distance (192): none of their chunks is ever drawn from there. Near the spawn only the road is
    new, and it is **sand** (a block of the ground's own page: paving would add a material, so a draw, to every chunk it
    crosses); the pads start out of view (ruling 11); the plaques' names hide (ruling 13); the HUD's compass, which asks
    the director every frame (`TreasureCompass.guided`), now gets a plain loop over the fourteen places (nothing built or
    sorted: it used to build and sort the whole checklist every frame). The wonders are voxel blocks: each chunk draws one
    surface per block page it holds, so a wonder costs a few shared page materials, never its own mesh or material (the
    New Seven use pages 36-37, the first tour's 33-34 and page 0). *Cost:* a sand road where a paved one would match the
    paths; the lead re-measures on the emulator.

## The facts and their sources

Every line a child reads or hears (`core/books/wonder_facts.gd`: the sights, the cards' facts, the quizzes, the
secrets, the tours' words; the loading hints) was checked against these (web searches and pages read on 2026-09-30):
- **The vote:** Wikipedia "New 7 Wonders of the World" (https://en.wikipedia.org/wiki/New_7_Wonders_of_the_World):
  announced 7 July 2007 in Lisbon; web and telephone voting; the Giza pyramids given honorary status; UNESCO distanced
  itself (a popular vote, not its list). The four continents are counted from the seven places.
- **Great Wall:** UNESCO "The Great Wall" (https://whc.unesco.org/en/list/438/): walls joined about 220 BC, built on up to
  the Ming dynasty (1368-1644), beacon towers, signals of smoke and fire; Wikipedia "Great Wall of China"
  (https://en.wikipedia.org/wiki/Great_Wall_of_China) and Britannica "Great Wall of China"
  (https://www.britannica.com/topic/Great-Wall-of-China): the first walls in the 7th century BC, the Ming wall 8,850 km
  (2009 survey), all its walls 21,196 km (2012 survey), Ming brick and stone, battlements, the wall built by soldiers,
  peasants and convicts; NASA "Great Wall" (https://www.nasa.gov/image-article/great-wall): not visible from the Moon;
  the sticky rice in the lime mortar: the 2010 Zhejiang University study (Yang Fuwei, Zhang Bingjian et al.), National
  Geographic "Sticky Rice Holds Ancient Chinese Buildings Together"
  (https://www.nationalgeographic.com/history/article/100608-sticky-rice-mortar-china-science). "Smoke by day and fire by
  night" is how the beacon signals are commonly described (UNESCO: smoke and fire).
- **Petra:** Wikipedia "Petra" (https://en.wikipedia.org/wiki/Petra): the Nabataeans (Arab), settled in the 4th century
  BC and their capital from the 2nd, dams, cisterns and conduits, the earthquake of 363, Burckhardt in 1812, the "Rose
  City"; UNESCO "Petra" (https://whc.unesco.org/en/list/326/); the Siq about 1.2 km long, 3 m wide in places (Wikipedia
  "Siq", https://en.wikipedia.org/wiki/Siq; Visit Petra, https://www.visitpetra.jo/en/Location/25); Wikipedia
  "Al-Khazneh" (https://en.wikipedia.org/wiki/Al-Khazneh): 39.1 m tall, 25.3 m wide, early 1st century AD, a plain
  chamber inside, the urn believed to hold treasure (shot at: its bullet marks).
- **Colosseum:** Wikipedia "Colosseum" (https://en.wikipedia.org/wiki/Colosseum): begun by Vespasian about AD 70-72,
  opened by Titus in AD 80, 189 × 156 m, 48 m tall, about 50,000-65,000 spectators (Britannica: about 50,000), travertine
  held by iron clamps, the velarium (a canvas awning), the hypogeum's tunnels, lifts and trapdoors, gladiators, built by
  enslaved people and prisoners of war with Roman builders, the 1349 earthquake and the fallen south side, its stone
  taken for other buildings; Titus's 100 days of games (Cassius Dio, *Roman History* 66.25).
- **Chichen Itza:** Wikipedia "El Castillo, Chichen Itza" (https://en.wikipedia.org/wiki/El_Castillo,_Chichen_Itza): 8th-12th
  centuries, 24 m and a 6 m temple, a 55.3 m base, four stairs of about 91 steps (with the top platform 365), the
  equinox shadow on the north balustrade, the serpent heads at its base, the inner temple with the Red Jaguar Throne
  (1935-36, jade inlays), the chirped echo like a quetzal's call; Wikipedia "Chichen Itza"
  (https://en.wikipedia.org/wiki/Chichen_Itza): a Maya city, a focus from about 600 to 1100, the Great Ball Court 168 × 70
  m (players hit a rubber ball with their hips: Wikipedia "Mesoamerican ballgame"); UNESCO "Pre-Hispanic City of
  Chichen-Itza" (https://whc.unesco.org/en/list/483/); Maya peoples and languages today: Wikipedia "Maya peoples".
- **Machu Picchu:** Wikipedia "Machu Picchu" (https://en.wikipedia.org/wiki/Machu_Picchu): built about 1450 for the Inca
  emperor Pachacuti, 2,430 m, left about a century later, never found by the Spanish, local farmers working its terraces,
  Hiram Bingham in 1911, ashlar walls without mortar, terraces for farming and against the slope sliding, the Temple of
  the Sun and the carved cave under it ("the Royal Tomb"), the Intihuatana, Huayna Picchu, the name ("old peak" in
  Quechua); UNESCO "Historic Sanctuary of Machu Picchu" (https://whc.unesco.org/en/list/274/).
- **Taj Mahal:** Wikipedia "Taj Mahal" (https://en.wikipedia.org/wiki/Taj_Mahal): built by Shah Jahan for Mumtaz Mahal
  (died 17 June 1631), 1632-1653 (the tomb by 1648), more than 20,000 workers, Makrana marble, 28 kinds of stones in the
  inlay, 73 m, the minarets over 40 m tilted outward to fall away from the tomb, the cenotaphs over the crypt, the
  charbagh garden and pool, the Yamuna on its northern side, the Quran's verses round the arches, the marble's colours
  through the day; UNESCO "Taj Mahal" (https://whc.unesco.org/en/list/252/).
- **Christ the Redeemer:** Wikipedia "Christ the Redeemer (statue)"
  (https://en.wikipedia.org/wiki/Christ_the_Redeemer_(statue)): 1922-1931, 30 m on an 8 m pedestal, arms 28 m, reinforced
  concrete covered in soapstone, designed by Heitor da Silva Costa, sculpted by Paul Landowski, faces east, lightning in
  2008 and a chipped finger in 2014; its hollow inside with stairs up to hatches on the arms and head, for workers only
  (e.g. https://riodejaneirobycariocas.com/how-to-get-to-the-head-of-christ-the-redeemer-statue/); Corcovado 710 m and
  the rack railway opened in 1884 (Wikipedia "Corcovado Rack Railway",
  https://en.wikipedia.org/wiki/Corcovado_Rack_Railway).

## Built (files)

- Where: `world/wonders/wonder_tour.gd` (the New Seven's entries, `NEW_SQUARE`, `NEW_R`, `BLEND`, `SQUARES`,
  `square_of`, `road`, `road_pads`, `road_signpost`, `to_frame`, `reach`, `tour_plaque(tour)`, `PETRA_SAND`).
- Ground: `world/wonders/new_seven_ground.gd` (new: the ridge, Corcovado, Huayna Picchu, `wall_walk`),
  `world/generators/wonders_shape.gd` (the region, the blend, trees, sand, spawners), `wonders_generator.gd` (no caves,
  flowers there).
- What: `world/wonders/wonder_builds_new.gd` (new: the seven builds), `world/wonders/wonder_builds.gd` (the match, the
  new square, the road and its pads, the signposts).
- Secrets: `world/generators/wonders_secret_rules.gd` (`NEW_TOUR_AREAS`, the seven secrets), the fakes in
  `SecretRules.is_fake_wall`, `GatherRules.DROPS`, `ChatCommands.NEVER_GIVEN`, `CaptureRules.GROUND`.
- Words: `core/books/wonder_facts.gd` (`TOURS`, `TOUR_IDS`, `ANCIENT`, `NEW`, `ORDER` of 14, the New Seven, `tour_of`,
  `tour_ids`, `tour_info`, `tour_of_plaque`, `called`), `core/books/wonders_passport_rules.gd` (`tour_stamped`,
  `stamp_words(w, id)`, `tour_progress_words`, the clue), `core/rules/loading_hints.gd`.
- The child's: `world/wonders/wonders_director.gd` (the guide's two columns, the new square on MY MAP, the road's and the
  tours' names, the label range), `ui/space/planet_guide_card.gd` (`groups`), `ui/books/wonder_card.gd` (tour cards),
  `ui/books/wonders_passport_page.gd` (headings), `ui/books/wonder_stamp.gd` (seven emblems), `world/universes/wonders.gd`
  (landing words, Tilly's stock).
- Blocks: `data/blocks/block_ids.gd` (624-641, `COUNT` 656), `world/universes/wonders_blocks.gd` (pages 36-37);
  pictures `data/blocks/pages/wonders3*.png`, `wonders4*.png` by `tools/make_wonders_new_page.gd` and
  `tools/make_wonders_new_realistic.py`; credits in `assets/CREDITS.md`.
- Tools: `tools/wonders_smoke_steps.gd` (both tours), `tools/space_shots_steps.gd` (each wonder from its own square;
  `--close`: the New Seven up close), `tools/wonders_draw_probe.gd` (new: the landing spot's draws a frame).

## Tests

New: `tests/unit/test_wonders_new_blocks.gd` (pages, names, fakes, both pictures, looks), `test_wonders_new_seven.gd` (the
tour's list, the road and its pads, the square, the places apart, level ground, the ridge, Corcovado, Huayna Picchu,
level paths, the meadows far out and the blend, Petra's sand, the trees, honest words, the passport for both tours),
`test_wonders_new_builds.gd` (each wonder's shape and a child's walk: along the Great Wall tower to tower, through the Siq
into the Treasury and up to the urn, into the Colosseum's arena and up its tiers, up El Castillo into its temple, up to
Machu Picchu's plaza, through the Taj Mahal's gate into its hall and up the minaret, up Corcovado's stair),
`test_wonders_new_secrets.gd` (a secret each, shut until the knock, into each room, up to each chest, the jaguar throne,
the tunnels under the arena), `tests/integration/test_wonders_new_world.gd` (the generator writes them and their secrets
exactly, no caves, the road, the square, Petra's sand, Corcovado's grass); `tests/fakes/wonder_walker.gd` (the walk).
Changed: `test_wonders_tour.gd`, `test_wonders_passport.gd`, `test_wonders_universe.gd`, `test_wonders_secrets.gd`,
`test_wonders_blocks.gd`, `tests/integration/test_wonders_director.gd` (14 wonders, 32 names, the two-column card, the
passport's headings), `test_block_id_space.gd`, `test_block_pages.gd`, `test_prospect_blocks.gd` (656, pages 36-38; the
held page is the colonies'), `test_realistic_pack.gd` (the two pages), `test_page_sizes.gd` (60 MB).

## Measurements

- **The landing spot's view** (`tools/wonders_draw_probe.gd`, new: windowed, a new Sandbox world in universe 41, seed
  12345, the default MEDIUM settings and view 128, noon, the HUD hidden; 120 frames each way, this PC while another suite
  ran): **before** (lead-merge 1d4ff0af, extracted and imported beside) north / east / south / west draws 179 / 225 / 248 /
  246, all 225 a frame, 149,119 primitives; **after** 147 / 216 / 246 / 245, all **214** a frame, **140,989** primitives
  (the plaques' names hidden; the road adds nothing). Frame times were noisy (the other suite): 12.4 ms before, 11.3 after.
- **Working the builds out** (once a game, at world 41's load: the director's zones and the generator's first chunk
  need them): before 7 wonders, 1,618 boxes, 6.5 ms; after 14 wonders, 4,297 boxes, 14.4 ms (a `Frame` now looks its
  wonder's place up once, not per box); the biggest chunk column's boxes 82 → 223 (the Colosseum's). `WondersShape.new`
  0.1 → 0.2 ms; `WondersSecretRules.new` 0.5 → 0.8 ms.

- **Generator bench** (`tools/bench_generator.gd -- --wonders`, this PC at load 5-8 on 24 cores, 2026-09-30; ms a chunk,
  fresh generators over 4 × 4 whole stacks; old meadows / wild meadows / wonders, surface then underground): Great Wall
  1.15 / 0.78 / 1.24 and 1.42 / 1.61 / 0.40; Petra 1.20 / 0.75 / 0.85 and 1.27 / 1.54 / 0.33; Colosseum 1.16 / 0.72 /
  0.91 and 1.19 / 1.30 / 0.35; Chichen Itza 1.02 / 0.65 / 0.85 and 1.51 / 1.88 / 0.32; Machu Picchu 1.20 / 0.63 / 0.86
  and 1.12 / 1.32 / 0.32; Taj Mahal 1.17 / 0.71 / 0.87 and 1.15 / 1.23 / 0.33; Christ the Redeemer 1.06 / 0.69 / 1.20 and
  1.34 / 1.58 / 0.34 (worst wonders' chunk 2.8 ms). A whole stack of every New Seven costs less than Green Meadows' (the
  Wall's and Corcovado's surface chunks a little more, their hills having more surface chunks; the wild meadows' surface
  chunks are cheaper, their underground 4-5 times dearer). The first version of `NewSevenGround` looked the wonders' centres
  up per column and cost 1.45-1.82 ms a surface chunk: the centres are constants now (checked by a test). Round the landing
  square unchanged: meadows 1.31, wonders 0.79 (all). `WonderBuilds` works out both tours once: about 4,300 boxes (the
  New Seven ~2,100: the Colosseum 711, the Taj Mahal 381, the Great Wall 286, Christ the Redeemer 271, Chichen Itza 245,
  Machu Picchu 108, Petra ~110; the extras 1,052), 18 ms; the biggest chunk column holds 223 boxes.
- **Pictures** (`tools/space_shots.gd -- --universe=41 --sights`, windowed, both styles, `build/wonders-shots/` in the
  worktree, not committed): each of the fourteen from 55 blocks toward its square. The New Seven read as themselves in
  both styles (the Great Wall on its ridge with towers, the Colosseum's arches and tiers with its broken side, El
  Castillo's stairs, Machu Picchu's terraces and thatch under Huayna Picchu, the Taj Mahal's dome, minarets, pool and
  cypresses behind its red gate, Christ the Redeemer's open arms high on Corcovado). Petra's cliff first looked like a
  plain pink box from outside: it got ribs of different heights and worn corners. `-- --universe=41 --close` (new) shows
  them as a child does: the Great Wall's walkway to a tower, the Treasury from its court (its court was deepened to 14 so
  the facade fits a child's view; the rose rock's bands were made to meet across blocks), the Colosseum's arena and tiers,
  El Castillo's north stair with the serpent heads, Machu Picchu's plaza under Huayna Picchu, the Taj Mahal's pool and
  cypresses before the tomb, the statue from Corcovado's summit.
- **Smoke** (`tools/smoke_all.sh wonders`, logs in the worktree's `build/smoke-logs/`): 95 checks, **0 fails**, 53-56 s.
- **Full suite** (`tests/run_tests.sh`, on the last commit): **8,498 passing, 0 failing** (2 pending). An earlier full
  run under load had `test_world_sync.gd` fail twice (a save compared off the main thread); it passes alone (the
  brief's known load flakes).
- **The realistic pages**: 55.4 MB of 60 (`test_page_sizes.gd`).

## What the lead must check on the emulator

1. World 41's autopilot at the landing spot as before (the spawn view: 214 draws a frame here against 225 before), the
   one-off building of the wonders at the load (14 ms here, 6.5 before: a phone's 3-5×); then a walk down the Wonders
   Road (the sand, the speed pads' whoosh both ways past the first park; animals on the pads?), the frame rate along it,
   the road signposts' names.
2. The frame rate at the New Seven in both styles (≥ 30 FPS, no frame over 100 ms): inside the Colosseum (711 boxes of
   travertine, many arches), at the Taj Mahal (the dome, the garden's water and cypresses), looking up at Christ the
   Redeemer from the square (the statue 102 up is seen from the whole region), along the Great Wall.
3. The explorer's card with two columns fits a phone's screen; the passport's two sections scroll; the new tour card.
4. Climbing: the Great Wall's stair and walkway (steps up and down a block at a time), Christ the Redeemer's 40 steps, the
   Taj Mahal minaret's spiral (1 wide, like the lighthouse's), Petra's rock-cut stair (dark inside the rock: enough
   light?), El Castillo's stairs, Machu Picchu's stair, the Colosseum's tier stairs.
5. Knocks: the Great Wall tower's cracked brick (on the ridge's slope), the Colosseum's in the arena's wall, El Castillo's
   in the north stair's balustrade, the Temple of the Sun's rock, the pedestal's back; the banners and facts.
6. Does the Treasury read as the Treasury from the court (columns, pediment, tholos, urn)? Does Machu Picchu read from the
   path (the peak behind)?
7. Survivor: the trip, the quiz gold into the wallet, Tilly's new blocks.
8. MY MAP with 16 places (14 wonders, the landing spot, the New Seven's square) and the arrow's choice after the first
   tour.

## Next (the game never ends)

Nature's wonders (the third tour; ids 642-655 are free on these pages, more pages from the lead), the Taj Mahal's mosque
and its twin, Chichen Itza's ball court and sacred cenote (told with care), llamas at Machu Picchu, the Siq's old arch,
the beacon towers lit at night, the School's history and geography units linking "Visit it in the game", the plane from
the Launch Site (§21e).
