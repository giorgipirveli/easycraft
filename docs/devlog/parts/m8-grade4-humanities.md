# Grade 4 history, geography and citizenship: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.4) lists grade 4's
History (10: the first civilisations), Geography (10) and Citizenship (11) units; this agent wrote all 31, following
the reusable brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 4, SUBJECTS = history,
geography, citizenship) and building on grade 3's humanities (`m8-grade3-humanities.md`). Branch
`worktree-agent-a8f5ff3c1798f8a99`, from `lead-merge` at e74c9cd.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used |
|---|---|---|---|---|
| History | 10 | 80 | 148 | `g4h.event_order` (The first cities), `g4h.egypt_number`, `g4h.sixties` (How ancient people counted), `g4h.years_apart`, `g4h.event_order` (Comparing civilisations) |
| Geography | 10 | 80 | 141 | `g4h.world_capital`, `g4h.europe_capital`, `g4h.americas_capital`, `g4h.map_scale`, `g4h.survey_count` and `g4h.weather_table` (Fieldwork) |
| Citizenship | 11 | 88 | 154 | `g4h.town_budget`, `g4h.vote_count`, `g4h.best_value`, `g4h.deal_check`, `g4h.change_due` |
| **All** | **31** | **248** | **443** | 15 generators, each at levels 1-3 |

- **Files:** `data/school/g4/<subject>/<unit>.json`, linked from `data/school/grade4.json` (only these 31 units' `file`
  fields changed; titles and goals kept).
- **Every unit:** a lesson of 8 cards that opens with "Quick memory:" and a question from an earlier unit or grade 3
  (its answer in brackets), teaches one idea a card with a worked example, and ends "Try it in the world: …" with
  "Next: …" (research §5.3 rules 1, 7 and 8; the test enforces all three); 14-16 hand-written exercises, at least 4 at
  level 1 and 5 at levels 2 and 3 (so no round repeats one), of 4-6 kinds: choice (225), true or false (87), number
  (54), match (30), sort (26) and order (21). Every exercise has a hint (a strategy, never the answer) and an explain
  (the worked answer). No unit asks the same question twice.
- **History, the first civilisations:** the first cities by rivers (irrigation, surplus, granaries, what makes a
  civilisation; Uruk and Stonehenge on one timeline), Sumer (city-states, ziggurats of mud brick, writing from about
  3200 BC, cuneiform with a reed, the tablet house, Gilgamesh, the wheel; Hammurabi's laws in stone), Ancient Egypt (the
  Nile flowing north, Kemet, Akhet-Peret-Shemu, the shaduf, pharaohs and Hatshepsut, the Great Pyramid about 2560 BC
  and its paid builders, beliefs about the afterlife, hieroglyphs, the Rosetta Stone and Champollion in 1822), the Indus
  Valley (about 2600-1900 BC, Harappa and Mohenjo-daro, grid streets, same-shaped bricks, covered drains, the Great
  Bath, seals and the unread script, the mysteries), Shang China (about 1600-1046 BC, dynasties, bronze casting in
  piece-moulds, the 830 kg pot, oracle bones cracked then carved, the oldest Chinese writing, 1899's "dragon bones", Fu
  Hao), Kush and Nubia (Kerma by about 2500 BC, "the land of the bow", Kush ruling Egypt in the 700s BC, over 200 steep
  pyramids, Meroe's iron, gold, ivory, ebony and incense, the Kandake queens, Meroitic writing), farming, trade and the
  first money (surplus, trade for timber, copper and lapis lazuli, Indus weights, the shekel, cowries, Lydia's electrum
  coins), how ancient people counted (Egyptian and Babylonian numbers, why 60, our minutes, degrees and 24 hours),
  how archaeologists work (chance finds such as the Terracotta Army in 1974, layers, recording, dating by layers, coins,
  pottery, tree rings and radiocarbon, caring for finds, what finds cannot tell) and comparing civilisations (two
  tables, leaders, what each is famous for, what they share, and the no-year-0 timeline trick).
- **Geography:** countries and capitals (about 195 countries, Russia and Vatican City, capitals that are not the
  biggest city, Africa's 54, finding Kenya), Europe (the Urals line, seas, the Alps and Mont Blanc, the Pyrenees, the
  Volga and the Danube's 10 countries, capitals and their rivers, peninsulas, the midnight Sun, Iceland), North and
  South America (Canada to Argentina, Brazil and Portuguese, the Rockies and the Andes, the Amazon, the Panama Canal
  1914, the Atacama, Angel Falls), rivers (source, courses, meanders, floodplain, estuary and delta; a map with a
  tributary), mountains (fold, volcanic and block; Everest 8,849 m and a heights table; 6.5 °C colder per 1,000 m;
  terraces, yaks and llamas), volcanoes and earthquakes (Earth's layers, three kinds of plate edges on a map picture,
  magma to lava, active, dormant and extinct, Vesuvius in AD 79, faults and epicentres, getting ready), water on the
  move (the water cycle as a table, 97 salty cups of 100 as a bar graph, aquifers and reservoirs), scale and distance
  (words, a scale bar picture, ratios such as 1 : 25,000, string for winding roads), two regions compared (the Lake
  District and the rainforest around Manaus) and fieldwork (a question, tallies, a traffic bar graph, weather tools,
  a worked conclusion, evaluating).
- **Citizenship:** rights and responsibilities (the UDHR 1948 and the UNCRC 1989, 54 articles, five articles in a
  table, rights against wants), who runs a town (councils, councillors, mayors, taxes, shared costs, choosing), deciding
  together (one person, voting, a secret vote, majority, consensus, turns, a draw), keep going ("yet", practice, when
  stuck, goals in steps, the Wright brothers in 1903), empathy (clues, feeling words in a table, listening, including
  newcomers), bullying (what it is and is not, the kinds, telling, online steps, upstanders, the game's REPORT and
  BLOCK), smart spending (prices with decimals, the price for one, value, costs and benefits, opportunity cost, waiting
  a day), adverts (tricks, 9.99, paid posts, friends and fitting in, questions to ask), ways to pay (cash, balances,
  debit and credit cards, phones, a card account worked example, PINs and asking a grown-up), helping your community
  (needs, a plan, a worked litter pick, measuring change, Japan's class cleaning, the 17 Global Goals) and a big
  question (dilemmas, a kind and honest answer, surprises and unsafe secrets, a rule broken to help, reasons, changing
  your mind).

## Generators (`core/school/gen/g4_humanities_gen.gd`, `G4HumanitiesGen`, SchoolGen source "g4h")
Seeded, levels 1-3, each with a hint, a worked answer and `data`:
- `years_apart`: whole hundreds BC (1), two of the first civilisations' dated events (2), BC to AD exactly: "there is
  no year 0" (3: a + b − 1).
- `event_order`: three events far apart (1), four BC events (2), four events across BC and AD (3), each with its date.
  The events and dates are the lessons' own (`EVENTS`).
- `egypt_number`: read hieroglyph numbers to 999 (1) and 9,999 (2) from the numerals picture; how many signs, or how
  many of one sign, a scribe draws (3: a 0 needs none).
- `sixties`: minutes in hours or seconds in minutes (1); a Babylonian tablet with its places labelled (2), unlabelled
  and bigger, or minutes as hours and minutes (3).
- `map_scale`: 1 cm for 2, 5 or 10 km with a scale bar (1); back to the map, or a town map in metres (2); a route of 2-3
  legs, or a ratio scale (3).
- `world_capital` (famous capitals; a capital's country or a country's continent; capitals that are not the biggest
  city, the biggest city always a wrong choice), `europe_capital` (capitals; more capitals; a capital's river or
  country), `americas_capital` (capitals; more capitals; a capital's country, or North or South America).
- `survey_count` (a 10-minute traffic bar graph: how many, the most, how many more, altogether, in an hour),
  `weather_table` (a week's °C and mm: the warmest day, a day's rain, how much warmer, the week's rain, the range across
  0 °C).
- `best_value` (the same thing at two stalls; which pack is better value, whole then decimal prices for one; the price
  for one), `change_due` (change from whole gold; counting on with decimals; a bank account after card and phone
  payments), `deal_check` ("was, now"; "buy 2, get 1 free"; a deal against another stall for the number you need),
  `town_budget` (two costs; what is left; a cost shared by families; a budget after two services), `vote_count` (the
  winner on a bar graph; how many more, how many voted; a majority true or false, both ways, or how many a majority
  needs).

## The numerals picture (`ui/school/school_picture_history.gd`, `SchoolPictureHistory`)
`{"kind": "numerals", "system": "egypt" | "babylon", "value": n, "labels"?: true}`: Egyptian strokes, heel bones, coils
of rope and lotus flowers, biggest first, rows of up to 4 (else two rows), labels with each group's worth; Babylonian
corner and upright wedges on a clay tablet, the sixties' place on the left, a gap between places, labels "sixties" and
"ones". SchoolPicture calls its `problem` and `draw` (two small dispatch blocks). Looked at in a real window: a scratch
render of the samples, and `school_shots.gd --unit=g4.history.ancient_numbers --exercises` (lesson cards 2-5 and a
round's Babylonian number exercise draw clearly); also `g4.geography.rivers`, `g4.geography.volcanoes_earthquakes` and
`g4.citizenship.smart_spending` (map pictures with a key, tables).

## Rulings (decide and write down; cost if wrong)
1. **Every lesson opens with "Quick memory:" and ends with "Try it in the world: … Next: …"**, and the test enforces it
   (research §5.3 rules 1, 7 and 8: memory, spiral, world). *Cost:* none.
2. **Dates are given as the lessons give them, rounded, with "about"** (3500, 3200, 3100, 2560, 2500, 1600, 1046 BC;
   the exact ones exact: 196 BC, AD 394, 1822, 1899, 1922, 1974, 1976); ranges and mysteries are said to be so ("may
   have", "perhaps", "nobody knows"). The generators' `EVENTS` hold the same dates. *Cost:* none.
3. **The no-year-0 rule is taught in grade 4** (grade 3's ruling 3 left it for later): Comparing civilisations' timeline
   card and `years_apart` level 3 want the exact count (a + b − 1). *Cost:* one `accept` line if the owner prefers
   "about" answers.
4. **Kush starts at Kerma, about 2500 BC** in the comparison table (Kerma was Kush's first kingdom); Kush ruling Egypt is
   "in the 700s BC, for about 90 years" (the 25th dynasty, about 744-656 BC). *Cost:* a table cell.
5. **Beliefs are beliefs** (research §5.4 rule 1): "where they believed their god lived", "who the Shang believed could
   help", "Egyptians believed in a life after death"; mummies are described with respect, and the game's monster
   "mummy" picture is not used. *Cost:* none.
6. **Capitals are widely recognised ones only** (§5.4 rule 2): countries whose capital or borders are disputed, or
   whose capital is unclear, are left out of the drills (for example Israel, Bolivia, Switzerland, South Africa,
   Tanzania, Ivory Coast, and Indonesia while its capital moves), and so are Russia and Ukraine; Russia appears only as
   the biggest country, across Europe and Asia. Turkey and New Zealand get capital questions but never "which
   continent?". Names are written in plain English letters (Brasilia, Bogota, Asuncion, San Jose, Reykjavik, Sao Paulo,
   Meroe; Champollion by his surname). *Cost:* an `ALLOWED` letter for each accent the owner wants.
7. **The two regions are the Lake District (Europe) and the rainforest around Manaus (South America)**: opposite land,
   weather and towns with a surprising likeness (both very rainy). Grade 5 has the Alps and the Andes and rainforest
   layers, so grade 4 avoids both. *Cost:* one unit's text for another pair.
8. **Money has hundredths from grade 4** (research §5.5 ruling 6): 0.50, 2.40, 9.99 gold; number answers are compared
   by value ("1.5" = "1.50"). *Cost:* none.
9. **Online safety names the game's own tools** (the player card's REPORT and BLOCK) and a trusted grown-up; no
   helpline numbers, since players are worldwide. *Cost:* a line per country's helpline.
10. **Government is described in general terms** ("in many places a mayor leads"), with no parties or named countries'
    systems; the UNCRC is "promised by nearly every country". *Cost:* none.
11. **The numerals picture is its own class** with two dispatch blocks in SchoolPicture, keeping `ui/school` changes
    small; Egyptian to 9,999 (bigger signs only in words) and Babylonian to 3,599 without an empty ones place (the
    Babylonians left a gap there, later a placeholder sign). *Cost:* fingers and tadpoles for bigger numbers.
12. **Oracle bones: cracked first, then carved** (the question was put during the divination; the question and answer
    were carved afterwards as a record), so the lesson and the order exercise say so. *Cost:* none.
13. **"Try it in the world" uses only what the game has** (signs, furnaces, blocks, chests, farms, the Meadows, the
    player card). *Cost:* none.
14. **The unit files are the source of truth**; the Python that wrote them (with its own limits, letters, kind-word,
    US-spelling and sums checks) stayed in the agent's scratchpad.

## Tests
- `tests/unit/test_school_content_g4_humanities.gd` (written first; it failed with "g4.history.first_cities is
  written" and the other 30): the outline has the research's 10 + 10 + 11 units; every unit is written with no
  problems, 3+ cards, 12+ hand-written exercises at levels 1-3 of 2+ kinds, rounds that fill and vary (12+ different
  exercises) and never a hand-written one twice in a round; hints are strategies and every exercise has a worked answer;
  every lesson starts with memory and ends in the world with what comes next; no unit asks a question twice; the units
  use only g4h generators and every g4h generator is used. It passes (6/6; 443 hand-written exercises).
- `tests/unit/test_g4_humanities_gen.gd` (written first; it failed with "g4h.… makes an exercise"): 16 tests, 80
  seeds × 3 levels, each answer worked out again from `data` (years with and without a year 0; items' dates parsed and
  checked in order; hieroglyph and wedge counts; minutes; map centimetres, legs and ratios; capitals, continents,
  rivers and biggest cities from the test's own table of facts; bar graphs and tables read back; prices for one; change
  and balances in hundredths; deals; shared costs and budgets; winners and majorities, which come up both true and
  false).
- `tests/integration/test_school_picture_history.gd` (written first; it failed to parse before `SchoolPictureHistory`
  existed): samples valid and drawn at three sizes, broken data are problems, the signs of a number.
- The shared `tests/unit/test_school_content.gd` passes with the 31 new units (4,258 hand-written exercises in all
  written units), and the School's other tests (curriculum, speech, pictures, menu, screen, exercise panel, round plan)
  pass.
- The full suite: see the end of this file.

## For the lead when merging
- `data/school/grade4.json`: only the 31 history, geography and citizenship units gain a `file` line; other grade 4
  agents add theirs to other units of the same file (a textual merge, no overlap).
- `core/school/school_gen.gd`: one SOURCES line `"g4h"` (after `"g3g"`, then the last); other agents may add theirs.
- `ui/school/school_picture.gd`: two header lines and two dispatch blocks (in `problem` and `_draw`) for
  `SchoolPictureHistory`, next to the grade 3 ones; the new class needs `godot --headless --path . --import` after the
  merge (also for `G4HumanitiesGen`).
- `docs/DEVELOPMENT.md`: one bullet at the end of the School section.
- Not done here (to avoid conflicts with the other grade 4 agents): `python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`, the spec's §22.4c "as built", RESUME-HERE and the owner-feedback row.

## The full suite (2026-09-29, this branch at db021dd)
`tests/run_tests.sh`: **7,023 tests in 761 scripts: 7,021 passing, 0 failing, 2 risky** (the two world tests that never
assert, as before), no script errors, exit 0. Two table cells were then shortened ("Tigris-Euphrates", "oracle bones":
the screenshots showed "oracle bone signs" overflowing a three-column cell), and the humanities' own tests,
`test_school_content.gd`, `test_g4_humanities_gen.gd` and `test_school_picture_history.gd` were run again on the final
state: 44/44 passing.
