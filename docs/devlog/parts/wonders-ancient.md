# The world's wonders, first tour: the Seven Wonders of the Ancient World (world 41, spec §24)

The owner (#78): "we must have world wonders, all wonders in the game. so all things must be educational in the game,
close to real world". Brief: `docs/superpowers/plans/2026-09-29-world-wonders-brief.md` with TOUR = "the Seven Wonders of
the Ancient World". Built by a worker agent in its own worktree (branch `worktree-agent-a1d09625357d34c34`, reset to
`lead-merge` 6aa41cf4 first: controllers and prospecting merged), without the editor, the emulator or adb (two windowed
runs of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 41, "Wonders of the World", Earth's own range 41-60 (`EarthRules`) | 41 | 42-60 for Earth's next worlds |
| `UniverseRules.MAX_UNIVERSE` | 40 → 60 | | |
| Block ids, pages 33-34 (`WondersBlocks`) | 576-607 | 576-597 | 598-607 (for the next tours) |
| `BlockIds.COUNT`, `NEXT_PAGE_FIRST_ID` | 624 (unchanged: prospecting's page 35 is still the last) | | |
| Atlas pages | 33 (`wonders*.png`, 3 rows) and 34 (`wonders2*.png`, 2 rows) | | rows 3-7 and 2-7 |
| Item ids, animals, HUD spots | none (the Books got a WONDERS tab) | | |
| Server module | unchanged (0.2.17): no universe check there assumes 40 (the wallet's `MAX_UNIVERSE` 12 is the ladder's scaling, and Earth's worlds never scale; blocks up to 1023 already travel in gifts; the profile's `wonder` object is kept whole) | | |

## What a child sees

1. **Getting there.** Fly up above any world; on the Star Map, tap **Earth**: its card (its three facts) now says
   **"Wonders of the World: LAND"**. LAND takes the child down at once (a whoosh, no rocket landing: ruling 2).
2. **Landing.** "Welcome to the Wonders of the World! Follow the red arrow to the Seven Wonders." The child stands in the
   middle of a round square of pale paving; the golden portal home is built three steps in front; seven signposts round
   the square carry the wonders' names (floating names, the traders' look), and paved paths run out to each wonder. The
   explorer's card opens: **EXPLORE THE SEVEN WONDERS** — "Greek travellers wrote lists of them over 2,000 years ago. Only
   the Great Pyramid still stands; the other six are gone, built here as people believe they looked. Visit all seven:
   each one stamps your Wonders Passport. Follow the red arrow!" — with the seven listed, nearest first, and LET'S GO. The
   HUD's red arrow points to the nearest wonder not visited; MY MAP shows the landing spot and all seven.
3. **The world.** Earth: its gravity, its blue sky with clouds, its animals, day and night, weather (a rainbow now and
   then); peaceful (no monster comes by itself). A flat green park round the tour with oaks, silvery **olive trees** to the
   west (Greece), **palms** on the sand and toward Babylon, wild flowers; a sea to the north-east (the Mediterranean) with a
   sandy beach; Green Meadows' own hills and rivers far out. Tilly sells the wonders' blocks.
4. **The Great Pyramid of Giza** (south, on Giza's sand; still standing). 45 blocks wide, 29 courses of golden limestone at
   the real pyramid's slope (about 52°), a row of smooth white casing stones still at its north foot. A step leads up to the
   **entrance on the north face**; inside: the corridor (lamps), a passage west to the **Queen's Chamber** (a gabled room),
   stairs up the east side to the **Grand Gallery** (tall, its walls stepping in to a narrow roof, its floor climbing), the
   antechamber and the **King's Chamber** of pink granite (8 long, 5 wide, 5 high) with the king's stone box. The pyramid can
   be climbed outside step by step (some steps are two blocks: a double jump). At its foot: "You reached the Great Pyramid
   of Giza! It is the only one of the Seven Wonders still standing." **Secret:** in the Grand Gallery's east wall a
   limestone block with a faint crack knocks open onto a secret stair winding up to a **hidden room** over the gallery (a
   chest, two lamps): "You found a hidden room!" then "In 2017 scientists found a big hidden space inside the Great Pyramid,
   using tiny particles that fall from space. No one knows yet what it was for."
5. **The Hanging Gardens of Babylon** (south-east, by the river Euphrates; no one knows if they existed). Four terraces of
   yellow Babylon brick, each with a band of blue glazed bricks and a garden on top (grass, flowers, bushes, a date palm on
   every corner, plants trailing down the walls), stairs up the middle to a pool on the top; arches into a vaulted gallery
   under the first terrace; at the back a **water screw** rising from a pool to a channel that carries water over the
   terraces to the top pool. "You reached the Hanging Gardens of Babylon! Old writers described them, but no one knows for
   sure they were real." **Secret:** a brick with a crack at the back of the vaulted gallery opens onto a **cool room** (a
   pool, two lamps, a chest): "…An old writer said water was lifted up to the gardens by screws turned by people."
6. **The Temple of Artemis at Ephesus** (north-west; gone). A marble platform of three steps, two rows of columns all round
   with scrolled tops (89 columns; the real one had more than 100), a carved band with a key pattern, a red tiled roof
   with marble pediments, the hall with its door to the **west** (as the real temple faced). "You reached the Temple of
   Artemis! The ancient Greeks believed Artemis was the goddess of hunting and the Moon." **Secret:** the temple's treasury
   — walking into the hall finds it ("…People kept their gold safe in the Temple of Artemis: it worked like a bank."), and
   three plates on its floor, stepped on in the note's order, open a golden door to the chest.
7. **The Statue of Zeus at Olympia** (west, in its temple; gone). The temple has **6 columns across its ends and 13 along
   its sides**, as the real one; its great door faces east. Inside, a black floor with a marble rim (for the olive oil that
   kept the ivory from cracking), side galleries up stairs (visitors climbed to see Zeus closer), and **Zeus on his throne**
   at the back: a throne of black ebony trimmed with gold, a robe of gold over his lap and legs, skin of ivory, a gold beard
   and hair, an olive wreath, a small Victory on his right hand, a sceptre with an eagle in his left, **his head just under
   the roof**. "You reached the Statue of Zeus! The ancient Greeks believed Zeus was the king of their gods." **Secret:**
   **Phidias's workshop** west of the temple (a white stone house, its door a marble one that knocks open; his bench, clay
   moulds, bits of ivory and gold, a lantern, a chest): "…In the 1950s archaeologists found his real workshop at Olympia,
   with his tools and the clay moulds for Zeus's robe."
8. **The Mausoleum at Halicarnassus** (north; gone). A white podium with stairs up its front, **36 columns** round the tomb
   hall (as the real one), the carved band, a **stepped pyramid roof**, and **four horses pulling a chariot** on top. "You
   reached the Mausoleum! It was a giant tomb for Mausolus, a ruler of Caria, finished by his wife Artemisia." **Secret:** a
   marble block with a crack at the back of the podium opens onto a stair down to the **hidden tomb room** underground (a
   stone coffin, lamps, a chest): "…The real one lay under the Mausoleum: knights found it in 1522, when they took its
   stones."
9. **The Colossus of Rhodes** (north-east, by the harbour shore; gone). A white marble base with steps up to its feet and a
   bronze figure standing **with its legs together** (not over the harbour), a cloak falling to the base, a crown of golden
   sun rays and a torch held high (glowing): 34 blocks to the flame. "You reached the Colossus of Rhodes! It was a giant
   bronze statue of Helios, whom the people of Rhodes believed was the god of the Sun." **Secret:** buried treasure under an
   X of sand in the grass toward the sea: "…The people of Rhodes paid for the Colossus by selling the weapons an army left
   behind."
10. **The Lighthouse of Alexandria** (east, on its island in the sea at the end of a raised paved **causeway** with low
    walls; gone). Three tiers of white stone: square (windows, stairs round a pillar inside up to a terrace with a parapet),
    eight-sided, round; a spiral stair in a shaft through the upper two to the **lantern**, where the **fire** burns under a
    bronze roof. "You reached the Lighthouse of Alexandria! It stood on the island of Pharos, joined to the city by a long
    causeway." **Secret:** a golden chest by the fire: "You found treasure at the top! The lighthouse's fire could be seen
    by sailors far out at sea."
11. **Each wonder, once reached:** its fact (a toast, read aloud), a sparkle, then "Stamp! 3 of 7 wonders in your Wonders
    Passport. 3 of 7 wonders visited! Next: the Colossus of Rhodes. Follow the arrow." After the seventh: "Your Wonders
    Passport is full…" and the arrow rests.
12. **The plaques.** By each wonder's gate a stone with a bronze plaque (its name floating over it). A tap opens its card:
    the stamp, the name (read aloud), "Giza, Egypt · built about 4,500 years ago · Still standing" (or "Gone: built here as
    people believe it looked", or "No one knows for sure it existed"), its five or six real facts, and **QUIZ** once the
    wonder is stamped. The quiz: two or three questions, three big answers each; right the first time pays **+10 gold**
    ("Right! +10 gold!"), a wrong first answer says the right one and never pays, a question answered before never pays
    again (a child may still try again to learn it). The landing square's own plaque tells the tour itself.
13. **The Wonders Passport** (the Books' new **WONDERS** tab, a pyramid on it): a stamp for each wonder (a round stamp in
    its own ink with its shape drawn: our own art), "???" until visited, "quiz: 1 of 3" under each; a tap opens its card
    (facts, QUIZ, or how to get there).
14. **Going home:** the portal home by the square, or fly up and take HOME on the Star Map (where Earth now says "You are
    here!"). Home lands the child on the column they took off from.

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **Earth's own worlds are a trip away, like space's** (`SpaceRules.is_away`: space 16-40 or Earth 41-60): world 41
   remembers its home, gets the portal home, is never scaled and never Plus, has its own saves (`sandbox_41`,
   `survivor_u41`), and the Star Map's HOME works from it. *Cost:* `is_away` in six places (scaling, home_for, refusal,
   take_off, landing_spot, needs_plus) plus the Star Map's HOME and the panel's button.
2. **LAND on Earth is the old whoosh, no rocket landing** (`Sandbox.land_on_space`): a rocket coming down among the wonders
   would be odd, and the brief keeps "by plane" for later. The hook is `EarthRules.way_there(u, plane)` (spec §21e: once the
   plane is invented, a mission with a plane from the Launch Site). *Cost:* one branch.
3. **The tour is the same in every world** (seed-free: `WonderTour`), on a **flat park** to radius 190 that blends into Green
   Meadows' own land by 260 (the seed's hills, rivers and seas out there). Flat keeps every wonder level and seen from far.
   *Cost:* `WonderTour` constants; hills in the park would need the flattening the plan first had (per-column blends).
4. **Game scale, real numbers in the words.** Each wonder is built at a size a child walks round in about half a minute
   (the pyramid 45 wide and 29 high, the lighthouse 41 high, the Colossus 34 to its torch), its shape and proportions true where blocks
   allow (the pyramid's slope, the Temple of Zeus's 6 × 13 columns, the Mausoleum's 36 columns, the King's Chamber 8 × 5 × 5
   like 10.5 × 5.2 × 5.8 m); the facts give the real sizes. *Cost:* numbers in `WonderBuilds`.
5. **The pyramid's real slope makes some of its outside steps two blocks high** (a double jump), and the fact says visitors
   may not climb the real one. Inside, every step is one block with room over the head (tested). *Cost:* a step block per
   pair of courses up one face if the emulator shows children stuck.
6. **The lost wonders are built as people believe they looked**, and their words say so (the Colossus's torch "as many
   people imagine it", the gardens "as people imagine them", the status line "Gone: built here as people believe it
   looked"); the Hanging Gardens say that no one knows for sure they existed (spec §24). *Cost:* none.
7. **Religion as culture and belief** (spec §22.4): "the ancient Greeks believed Artemis was…", "…believed Zeus was the king
   of their gods", "Helios, whom the people of Rhodes believed was the god of the Sun". No cult statue of Artemis is built
   (the famous one is a sensitive image); Zeus is built because the statue is the wonder. People named are of history only
   (Khufu, Nebuchadnezzar II, Croesus, Phidias, Mausolus, Artemisia, Chares of Lindos). *Cost:* words.
8. **One secret per wonder, each with its own words** (a secret's `words`: the SecretDirector's banner shows the find, up to
   its first "!", and a toast the fact after it, `SecretDirector.split_words`; a new RPC `_rpc_found_words`, the old one kept).
   Round the tour only these (no random secrets, treasure-pack places or mouse villages would land on a wonder); out past it
   Green Meadows' own. *Cost:* the small change in `secret_director.gd`; the kinds already existed.
9. **The fact quiz pays through EarnRules' `fact_quiz` row** (10 gold a question right the first time; now `by: game`, so the
   Gold Shop's "How to earn" lists it — its list's spacing went from 8 to 6 to fit the frame): Survivor into the host's
   wallet (`Session.gold_add`, reason "wonder_quiz"), Sandbox into the profile like the School's (`Sandbox._wonder_pay`).
   The quiz opens once the wonder is stamped (it is a quiz *at* a wonder). *Cost:* one number; the planets' quizzes may use
   the same row later.
10. **The passport lives in `WonderData`** (the Books' part of the profile: `wonders` stamps, `quiz` answers), merged by the
    backup with OR (never loses a stamp; a right answer stays right). *Cost:* none (additive fields).
11. **The Books get an eighth tab, WONDERS** (between SPACE and LAB); the tabs still fit the 700 px book (tested). *Cost:*
    one tab.
12. **The realistic pages' budget: 48 → 54 MB.** The rocket parts', the riches' and the wonders' pages brought the pages to
    49.8 MB (the wonders' two: 3.3 MB, measured: page 33 1.05 + 0.52, page 34 1.40 + 0.35 — it keeps alpha for the olive leaves). 54 leaves room for the colony domes'
    page and two more. *Cost:* up to ~4 MB more APK; the lead may lower it by moving the olive leaves to an opaque tile.
13. **Names float as Label3D in the traders' look** (billboard, one material the warm-up knows): 15 labels in the world.
    *Cost:* none measured; check the frame on the emulator.
14. **No caves under the tour** (inside radius 276): no hole opens under a wonder or the sea, and the tour's chunks are
    cheaper. *Cost:* children dig their own; the ores are still there.
15. **`UniverseRegistry.warm_space` warms world 41's file too** (the Star Map reads `trip_available`, which loads it): the
    M7 browser freeze rule. *Cost:* one list.
16. **The Shorts Theater and Tilly's stall stand where the game puts them near every spawn** (on the park by the square);
    the stone circle, stall, Totem and animals keep off the wonders (`WondersShape.is_river` is true on their footprints and
    the river, like Titan's methane). *Cost:* none.
17. **The Colossus stands inland by the shore** (the beach is 12 blocks wide there), the treasure in the grass toward the
    sea; the Lighthouse's causeway has low walls both sides (no fall into the sea). *Cost:* positions in `WonderTour`.
18. **`WonderData.MAX_UNIVERSES` (20) and `ProgressData.MAX_UNIVERSES` (8) stay**: world 41 grows no Hub Tree crown and counts
    no quest, like space worlds past 20. *Cost:* raise them when Earth's worlds should count.

## The facts and their sources

Every line a child reads or hears (`core/books/wonder_facts.gd`: the sights, the cards' facts, the quizzes, the secrets;
the tour's words; the loading hints) was checked against these (web searches of 2026-09-30 for the numbers):
- The list: Britannica, "Seven Wonders of the World" (https://www.britannica.com/topic/Seven-Wonders-of-the-World); World
  History Encyclopedia (https://www.worldhistory.org). All seven standing together for only about 50 years (280-226 BC) is
  why the tour's card says the pyramid was ~2,000 years old when the others were built (c. 2560 BC against 600-280 BC).
- **Great Pyramid:** built for Khufu of the 4th dynasty, about 4,500 years ago; 146.6 m originally (138.5 m now); about
  2.3 million blocks; the tallest human-made structure for over 3,800 years; sides aligned to the compass points; the white
  Tura limestone casing, mostly taken away (for Cairo after the 1303 earthquake), a few casing stones at the base; the
  King's Chamber of Aswan granite, 10.5 × 5.2 × 5.8 m with its empty granite sarcophagus; the workers' town (Heit el-Ghurab,
  its bakeries) — Britannica "Pyramids of Giza" (https://www.britannica.com/topic/Pyramids-of-Giza), Wikipedia "Great
  Pyramid of Giza". The big void: Morishima et al., "Discovery of a big void in Khufu's Pyramid by observation of
  cosmic-ray muons", *Nature* 552, 386-390 (2017) (https://www.nature.com/articles/nature24647): at least 30 m long, over the
  Grand Gallery; its purpose unknown. Climbing the pyramids is forbidden (Egyptian law; UNESCO "Memphis and its Necropolis
  – the Pyramid Fields from Giza to Dahshur", https://whc.unesco.org/en/list/86).
- **Hanging Gardens:** described by Greek and Roman writers (Berossus via Josephus, Diodorus, Strabo, Philo); the story of
  Nebuchadnezzar II and his wife Amytis; no Babylonian inscription mentions them and no remains were found; Stephanie
  Dalley's case for Nineveh and Sennacherib (*The Mystery of the Hanging Garden of Babylon*, Oxford 2013); Strabo's screws
  (*Geography* 16.1.5) — Britannica "Hanging Gardens of Babylon"; National Geographic, "Were the Hanging Gardens of Babylon
  actually in Babylon?"; HISTORY, "Hanging Gardens Existed—But Not in Babylon"; Babylon on the Euphrates (UNESCO "Babylon",
  https://whc.unesco.org/en/list/278).
- **Temple of Artemis:** Croesus's funding c. 550 BC; 127 columns 60 ft (18 m) tall (Pliny, *Natural History* 36.95); burned
  in 356 BC by a man seeking fame (Herostratus), rebuilt grander; sacked by the Goths in AD 262; one column re-erected today;
  a treasury where people deposited money (Dio Chrysostom, *Oration* 31.54); the temple faced west — Britannica "Temple of
  Artemis" (https://www.britannica.com/topic/Temple-of-Artemis-temple-Ephesus-Turkey); World History Encyclopedia "Temple of
  Artemis at Ephesus"; UNESCO "Ephesus" (https://whc.unesco.org/en/list/1018).
- **Statue of Zeus:** by Phidias, c. 430 BC, about 12 m tall, seated, ivory and gold over a wooden frame (chryselephantine);
  "if he stood up he would unroof the temple" (Strabo 8.3.30); olive oil to keep the ivory from harm (Pausanias 5.11.10);
  the wreath of olive shoots; Victory in his right hand, a sceptre with an eagle in his left (Pausanias 5.11.1); the temple
  6 × 13 Doric columns; lost probably in a 5th-century fire; Phidias's workshop excavated in the 1950s with tools and the
  terracotta moulds for the robe; winners' olive crowns (kotinos) — World History Encyclopedia "Statue of Zeus at Olympia"
  (https://www.worldhistory.org/Statue_of_Zeus_at_Olympia/); Livius "Olympia, Phidias' statue of Zeus"; UNESCO "Archaeological
  Site of Olympia" (https://whc.unesco.org/en/list/517). The cup inscribed "I belong to Phidias" is left out: some call it a
  forgery.
- **Mausoleum:** tomb of Mausolus (satrap of Caria), finished by Artemisia c. 350 BC; about 45 m tall; 36 columns; a pyramid
  roof of 24 steps with a four-horse chariot (Pliny 36.30-31); the word mausoleum; earthquakes, then the Knights of St John
  took its stones for Bodrum Castle (1494-1522) and found the burial chamber in 1522; sculptures in the British Museum —
  Britannica "Mausoleum of Halicarnassus"; British Museum, "Mausoleum of Halikarnassos"
  (https://www.britishmuseum.org/collection/galleries/mausoleum-halikarnassos).
- **Colossus:** Helios; by Chares of Lindos; about 33 m (70 cubits) on a white marble base; 12 years to build, finished c.
  280 BC; paid for with the siege equipment Demetrius's army left in 305-304 BC; toppled by the earthquake of 226 BC (about
  54 years later); its thumb too thick for most to embrace (Pliny 34.41); it did not straddle the harbour — Britannica "Chares
  of Lindos" (https://www.britannica.com/biography/Chares-of-Lindos), "Colossus of Rhodes".
- **Lighthouse:** on the island of Pharos, joined by the Heptastadion causeway; built by Sostratus of Cnidus, finished c. 280
  BC under Ptolemy II; estimates about 100-110 m (to 150); three stages (square, octagonal, cylindrical) with a fire at the
  top; "pharos" gave French *phare*, Italian and Spanish *faro*; earthquakes ruined it; Qaitbay's fort (1480) on its site;
  Jean-Yves Empereur's divers found its blocks in the harbour in 1994 — Britannica "Lighthouse of Alexandria"
  (https://www.britannica.com/topic/lighthouse-of-Alexandria); Wikipedia "Lighthouse of Alexandria".

## Built (files)

- Numbers and the trip: `core/rules/earth_rules.gd` (new), `SpaceRules.is_away` and its uses, `UniverseRules.MAX_UNIVERSE`
  60, `UniverseRegistry.EARTH` (`is_earth`, `earth_available`, `trip_available`, paths, names, cards, warming,
  autopilot), `ShopCatalog.needs_plus`, the Star Map's Earth card (`world` 41, `land`, `StarMap.action_words_for`), the
  SpacePanel's HOME and button words, `SpaceDirector.available`, `Sandbox.land_on_space` / `go_home_from_space`.
- The world: `world/universes/wonders.gd` (descriptor), `world/universes/wonders_blocks.gd` (pages 33-34),
  `world/wonders/wonder_tour.gd` (where), `world/wonders/wonder_builds.gd` (what: boxes, bucketed per chunk column),
  `world/generators/wonders_shape.gd`, `wonders_generator.gd`, `wonders_secret_rules.gd`.
- The tour for the child: `world/wonder_sights.gd` (extends SpaceSights), `world/wonders/wonders_director.gd` (node
  "Wonders"), the sandbox's section "Owner #78: the world's wonders" (`_wonders_local`, `_wonder_pay`), the plaque's tap
  (`BlockInteractor.plaque_tapped`), `PlanetGuideCard`'s own words.
- The passport and the quiz: `core/books/wonder_facts.gd` (every word), `core/books/wonders_passport_rules.gd`,
  `WonderData.wonders` / `quiz`, `ui/books/wonders_passport_page.gd`, `wonder_quiz_view.gd`, `wonder_card.gd`,
  `wonder_stamp.gd`, the Books' WONDERS tab (`secret_book.gd`), `EarnRules` `fact_quiz` row `by: game`.
- Blocks: `BlockIds` 576-597, fakes in `SecretRules.is_fake_wall`, `GatherRules.DROPS`, `ChatCommands.NEVER_GIVEN`,
  `CaptureRules.GROUND`; pictures `data/blocks/pages/wonders*.png` by `tools/make_wonders_page.gd` and
  `tools/make_wonders_realistic.py` (CC0 ambientCG, already cached and credited: Rock030, Plaster001, Metal034, Wood095,
  Plastic013A, Grass001).
- Loading hints (6) and the universe picture (the pyramid on sand by a column: `UniverseArt` 41).
- Tools: `tools/wonders_smoke.gd` (+ steps), `tools/bench_generator.gd -- --wonders`, `tools/space_shots.gd -- --universe=41
  --sights` (each wonder; the explorer's and KEYS cards kept out of the pictures).

## Tests

New: `tests/unit/test_wonders_numbers.gd` (the range, slots, trip rules, registry, the plane hook),
`test_wonders_blocks.gd` (pages, names, fakes, both pictures, looks), `test_wonders_tour.gd` (places, level ground, paths,
signposts, facing, the sea, island, causeway, sand, trees, spawners, Green Meadows far out), `test_wonders_builds.gd`
(every wonder's shape and a child's walk: into both of the pyramid's chambers, up its steps, up the gardens and into their
gallery, into both temples and up Zeus's galleries, into the Mausoleum's hall, up to the Colossus's feet, along the
causeway and up to the lighthouse's fire; the paths), `test_wonders_secrets.gd`, `test_wonders_universe.gd`,
`test_wonders_passport.gd` (stamps, save and merge, the quiz's pay rules, honest words, lengths);
`tests/integration/test_wonders_director.gd` (MY MAP, sights, stamps, the guide and compass, the labels, the plaque's
card and quiz, the tour's plaque, the passport page), `test_wonders_world.gd` (the generator writes the wonders and secrets
exactly, no caves, sand, sea, island, flowers and olive trees; the trip's save). Changed: `test_star_map.gd` (Earth lands at
41), `test_space_registry.gd` (warming 41), `test_books_tabs.gd` (eight tabs), `test_gold_shop.gd` (the quiz row shows),
`test_prospect_blocks.gd` / `test_block_pages.gd` / `test_block_id_space.gd` (33-34 are the wonders'),
`test_realistic_pack.gd` (the two pages), `test_page_sizes.gd` (the budget).

## Measurements

- **Generator bench** (`tools/bench_generator.gd -- --wonders`, this PC at load 17 on 24 cores, 2026-09-30): round the
  landing square (8 × 8 chunk columns, second round) Green Meadows (old) 1.52 ms a surface chunk against the wonders' 1.16,
  underground 1.11 against 0.31, sky 0.78 against 0.58: **all 1.28 against 0.76**. Over each wonder (fresh generators, 4 × 4
  whole stacks y −64…159; old meadows / wild meadows / wonders, surface then underground):
  pyramid 1.21 / 0.71 / 0.77 and 1.95 / 2.05 / 0.33; gardens 1.04 / 0.74 / 0.74 and 1.26 / 1.50 / 0.33; Artemis 1.09 / 0.83 /
  0.77 and 1.24 / 1.54 / 0.32; Zeus 1.22 / 0.91 / 0.74 and 1.36 / 1.54 / 0.31; Mausoleum 1.07 / 0.67 / 0.80 and 1.53 / 1.73 /
  0.31; Colossus 1.15 / 0.76 / 0.80 and 1.35 / 1.37 / 0.31; lighthouse 0.88 / 0.56 / 0.79 and 1.27 / 1.24 / 0.32 (ms a chunk;
  worst wonders' chunk 2.97 ms). A whole stack of the tour costs less than Green Meadows' (the wild meadows' surface chunks
  are a little cheaper by the lighthouse, their underground ones 4-6 times dearer). Placing the tour's areas' secrets:
  0.36 ms an area. `WonderBuilds` works the tour out once (1,118 boxes, ~6 ms), the biggest chunk column holds 82.
- **Pictures** (`tools/space_shots.gd -- --universe=41 --sights`, windowed, both styles): the square's four views, sunset,
  night, and each wonder from 55 blocks toward the square; the pyramid's north face is in shade in the morning light (the
  Sun is in the south).
- **Smoke** (`tools/smoke_all.sh wonders`): 61 checks, **0 fails**, 44 s.

## What the lead must check on the emulator

1. The Star Map's Earth card: "Wonders of the World: LAND" fits the card's button on a phone; LAND takes you down.
2. The frame rate walking the tour in both styles (≥ 30 FPS, no frame over 100 ms), especially looking over the park from
   the lighthouse's lantern and at the Temple of Artemis (89 columns) and the gardens (many palms and leaves); the 15
   floating names.
3. Walking in: the pyramid's corridor and chambers (the lamps are enough in the dark?), the lighthouse's stairs and spiral
   (the auto-step in a one-block-wide spiral; the hatch onto the terrace), the gardens' stairs, Zeus's galleries.
4. Climbing the pyramid's outside (the two-block steps need a double jump: fine for a child?).
5. The hidden room's knock in the Grand Gallery (the banner, then the fact's toast), the temple's plates.
6. A plaque's tap and the quiz card with touch and with a controller (PadFocus), the card's size; the passport's WONDERS tab.
7. Survivor: a trip there with a bag, the stone circle, Tilly's wonder blocks, the quiz gold into the wallet.

## Next (the game never ends)

The New Seven Wonders (the Great Wall, Petra, the Colosseum, Chichen Itza, Machu Picchu, the Taj Mahal, Christ the
Redeemer), nature's wonders, the wonders people built later — each a tour of its own (ids 598-607 are free for the next
one; more pages from the lead); the plane from the Launch Site (§21e) instead of the Star Map; the School's history and
geography units linking "Visit it in the game"; the planets' fact quizzes on the same EarnRules row; a Wonders Passport
page per tour.
