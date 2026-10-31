# Grade 8 history, geography and citizenship: every unit written (owner #70, #73, #111; 2026-10-17)

The owner (#111, 2026-10-16): "when all remaining tasks are done, you continue adding educational materials, as you know
we want to have full school programs and sylabusse content in the game". Grade 8 had only maths, science and English;
this agent wrote all 31 units of its history (10: the modern world, 1745 to today), geography (10: global issues) and
citizenship (11), following the reusable brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 8,
SUBJECTS = history, geography, citizenship) and the research (`docs/design/school-curriculum-research.md` §6.8), one step
up from grade 7's (`m8-grade7-humanities.md`) and building on grades 3-7. Branch `worktree-agent-ad29b051664985540`,
from `lead-merge` at 59be02e3 (Success S2), with lead-merge merged in again for grade 7's D&T, Health and Projects.

## What was written
| Subject | Units | Cards | Hand-written exercises | Generators used (g8h) |
|---|---|---|---|---|
| History | 10 | 80 | 154 | `modern_order`, `modern_years`, `rail_journey`, `town_growth`, `invention_sort`, `thinker_idea`, `powers_sort`, `triangle_trade`, `abolition_dates`, `independence_years`, `suffrage_years`, `electorate_share`, `ww1_sides`, `ww2_sides`, `ration_book`, `upstander_sort`, `udhr_rights`, `moore_doubling`, `space_firsts` |
| Geography | 10 | 80 | 151 | `co2_rise`, `climate_sort`, `mitigate_adapt`, `dev_indicator`, `pyramid_read`, `trade_balance`, `supply_chain`, `energy_sort`, `energy_mix`, `power_cost`, `virtual_water`, `farm_type`, `farm_scale`, `density`, `city_solutions`, `tourist_spend`, `tourism_effects`, `butler_stage`, `ocean_zone`, `plastic_years`, `mercator_stretch`, `projection_choice`, `overlay_count`, `gis_features` |
| Citizenship | 11 | 88 | 165 | `seat_maths`, `powers_sort`, `vote_tally`, `law_ages`, `rights_duties`, `equal_or_fair`, `upstander_sort`, `tax_maths`, `spend_share`, `monthly_budget`, `fixed_variable`, `loan_cost`, `credit_score_sort`, `rule_of_72`, `regular_investing`, `real_return`, `refund_rights`, `best_buy`, `goal_for_action`, `target_progress`, `for_or_against`, `personal_data`, `training_data` |
| **All** | **31** | **248** | **470** | 64 generators, every one used; every unit has at least one |

- **Files:** `data/school/g8/<subject>/<unit>.json`, linked from `data/school/grade8.json` (only these 31 units' `file`
  lines and seven history units' `hard` lines; titles and goals kept).
- **Every unit:** 8 cards: "Quick memory: …?" first, naming the grade 3-7 unit it builds on, one idea a card, worked
  examples, 2-3 pictures (3-5 in geography), and "Try it in the world: … Next: …" last; 15 or 16 hand-written exercises
  (4-5 at level 1, 6 at level 2, 5 at level 3) of 6 kinds (choice, true or false, number, order, sort, match), at most
  60% choice and true-or-false, each with a hint (a strategy, never the answer) and a worked answer. Every unit scores
  100 on `tools/school_audit.py` (no long cards or sentences, reading level about grade 5, every level harder than the
  last) and meets `test_school_quality.gd`'s bar.
- **History** (`g8.history.*`): `industrial_revolution` (the domestic system, the flying shuttle 1733, the spinning
  jenny about 1764, Newcomen 1712, Watt's separate condenser 1769, Cromford Mill 1771, the Bridgewater Canal 1761, the
  first public steam railway 1825, Liverpool and Manchester 1830 and the Rocket, Manchester about 70,000 → 300,000,
  cholera, the Factory Act 1833, towns over country by 1851); `ideas_of_liberty` (the Enlightenment, Locke 1689,
  Montesquieu 1748, Rousseau, Voltaire, Wollstonecraft, no taxation without representation, the Boston Tea Party 1773,
  4 July 1776, slavery for almost 90 more years, the Bastille, the Rights of Man, Olympe de Gouges 1791, the Terror,
  Napoleon 1799-1815, the Haitian Revolution 1791-1804, Toussaint Louverture, Bolivar); `slavery_abolition` (12.5
  million forced onto ships, 10.7 million arrived, the triangle and the Middle Passage, plantations, resistance, Nanny
  of the Maroons, Samuel Sharpe 1831, Equiano's book 1789, Clarkson, Wilberforce, petitions, the sugar boycott, 1807,
  1834, the enslavers paid and not the enslaved, Haiti 1804, the USA 1865, Brazil 1888, 23 August, forced labour
  today); `empires_independence` (empires, the scramble for Africa, 90% of Africa by 1914, a quarter of the world's
  land, the Bengal famine 1943, the Raj 1858, the Salt March, Quit India 1942, 15 August 1947, partition and 15 million
  people moved, Nkrumah and Ghana 1957, the Year of Africa 1960, Jamaica 1962, Kenya 1963, the Commonwealth's 56, the
  Windrush generation); `votes_for_all` (Old Sarum, the Great Reform Act 1832, the Chartists, 1867, 1884, the secret
  ballot 1872, Fawcett 1897, Pankhurst 1903, 1918 and 8.4 million women, 1928, 18 in 1969, New Zealand 1893, Finland
  1906, the USA 1920, France 1944, Japan 1945, India 1950, Switzerland 1971, the Voting Rights Act 1965, votes at 16);
  `first_world_war` (MAIN, Sarajevo 28 June 1914, the two sides, 1.5 million soldiers from India, the trenches, the
  Somme, the home front, rationing 1918, conscription 1916, the Armistice, about 9 million soldiers died, poppies, two
  minutes' silence); `second_world_war` (Versailles, the slump, Mussolini and Hitler, appeasement, Poland 1939,
  evacuation, the Blitz, rationing, Dig for Victory, Bletchley Park, Pearl Harbor, the Soviet Union from 1941, 2.5
  million from India, D-Day, VE Day, Hiroshima and Nagasaki, about 70 million died, mostly civilians);
  `holocaust_remembrance` (Jewish life before the war, antisemitism, 1933, the Nuremberg Laws, Kristallnacht, the
  Kindertransport, ghettos and camps, six million Jews murdered, 1.5 million children, Roma, Sinti, disabled people
  and others, Anne Frank, Irena Sendler, Chiune Sugihara, over 28,000 Righteous Among the Nations, 27 January, how
  hatred grows, upstanders); `building_peace` (the UN 1945, the UDHR 10 December 1948 and its 30 articles, Eleanor
  Roosevelt, Cassin, Chang, Hansa Mehta, Rosa Parks 1955, the March on Washington 1963, the laws of 1964-65, Windrush,
  the Bristol bus boycott 1963 and Paul Stephenson, the Race Relations Act 1965, apartheid 1948-1994, Mandela's 27 years
  and 1994); `space_digital_age` (the Cold War, Sputnik 1957, Gagarin 1961, the first woman 1963, Katherine Johnson,
  Apollo 11 and twelve moonwalkers, Colossus 1944, the transistor 1947, the microchip, the 1971 microprocessor and its
  2,300 transistors, doubling every two years, ARPANET 1969, the Web 1989 at CERN, smartphones 2007, daily life).
- **Geography** (`g8.geography.*`): `climate_change` (weather and climate, the greenhouse effect and −18 °C without
  it, the enhanced effect, 280 ppm, Mauna Loa's 317 → 414, 800,000 years of ice, about 1.2 °C warmer, 2024 the warmest
  year, 20 cm of sea since 1900, effects, the poorest hit hardest, mitigation, adaptation, Paris 2015);
  `development` (income per person, life expectancy, years at school, the HDI, the scatter of income and life,
  population pyramids from a wide base to a column, physical and human reasons, colonial history, aid, fair trade,
  small loans, girls' education, debt relief, extreme poverty more than halved since 1990); `connected_world`
  (globalisation, exports and imports, surplus and deficit, supply chains, 80% of goods by sea, the container 1956,
  20,000-container ships, Suez and Panama, undersea cables, winners and losers, fair trade); `energy_for_the_world`
  (sunlight behind almost all energy, fossil fuels about 80% of the world's energy in 2023, renewables about a third
  of electricity in 2024, storage, nuclear and its waste, uneven resources, Iceland's geothermal heat, Norway's rivers,
  kWh, LEDs about a sixth of the power); `feeding_the_world` (farm systems, arable, pastoral, mixed, subsistence and
  commercial, intensive and extensive, the Green Revolution and hybrid rice, virtual water: beef 15,400, chicken
  4,300, rice 2,500, bread 1,600, potatoes 290 litres a kg, food miles, 8.2 billion people, about 670 million hungry in
  2024, a third of food lost or wasted, food security); `future_cities` (20 → 45 in 100 in cities, 33 megacities,
  density, transport: Curitiba 1974, Copenhagen, Medellin's cable cars; informal settlements and upgrading; green
  space and the urban heat island, Seoul's stream 2005; smart and sustainable cities planned with their people);
  `tourism` (25 million trips in 1950 to 1.4 billion in 2024, jobs, the multiplier, leakage, harms, the tourism area
  life cycle, sustainable tourism and ecotourism, Costa Rica's quarter of protected land, the Galapagos guides);
  `oceans` (71% of the surface, five oceans, 97% of the water, gyres, the Gulf Stream, the deep conveyor, the five
  zones to nearly 11,000 m, phytoplankton and half our oxygen, reefs under 1% of the floor with a quarter of sea
  species, 11 million tonnes of plastic a year, microplastics, ghost nets, solutions, protected areas);
  `map_projections` (the globe, the orange peel, Mercator 1569 and its stretch: 2 at 60°, areas 4 times; Africa about
  14 times Greenland; web maps; Gall-Peters; Robinson 1963; azimuthal and the UN emblem; choosing a map);
  `gis_investigation` (layers of points, lines and areas, data sources, John Snow 1854, overlays and buffers, the
  enquiry steps of grade 7, choosing a park's site).
- **Citizenship** (`g8.citizenship.*`): `democracies_compared` (direct and representative, parliamentary and
  presidential, 650 seats and 326 for a majority, the Electoral College's 538, constitutional monarchies and
  republics, first past the post and proportional representation, Germany's two votes, Australia's compulsory and
  ranked voting, India's nearly a billion voters); `your_voice` (Article 12, school councils, youth councils, the UK
  Youth Parliament, consultations, a campaign's steps, being heard online, kindly); `young_people_law` (England's ages
  10, 13, 16, 17 and 18, Scotland's 12 and votes at 16, other countries' driving, criminal responsibility and voting
  ages, the UNCRC 1989, an appropriate adult, youth courts, rights and responsibilities); `fairness_for_all` (equality
  and equity, stereotypes, prejudice and discrimination, the Equality Act 2010's nine characteristics, direct and
  indirect discrimination, the Bristol bus boycott, the Dagenham strike 1968 and the Equal Pay Act 1970, the 1995
  disability law, challenging prejudice safely); `public_services` (taxes and services, income tax, VAT, company and
  council tax, a worked example in gold, spending shares roughly like the UK's, choices with no single right answer,
  deficits, the national debt, taxes that change behaviour); `life_budget` (gross and net pay, fixed and variable
  costs, a budget spreadsheet, 50/30/20, pay yourself first, an emergency fund, tracking, a budget that does not
  balance, getting help); `credit_debt` (kinds of credit, simple interest worked, compound debt snowballing, good and
  bad debt, credit scores, warning signs and free advice, loan sharks); `investing_risk` (savings, bonds and shares,
  risk and return, diversifying and funds, the rule of 72, inflation and real returns, investing is not gambling,
  guaranteed returns as a scam sign); `consumer_rights` (the Consumer Rights Act 2015, 30 days to reject faulty goods,
  repair or replace, 14 days online, no legal right for a change of mind in a shop, proof of purchase, a good
  complaint, smart buying, consumers' responsibilities); `global_goals_action` (17 goals and 169 targets, choosing a
  local goal, SMART targets, plans and if-then plans, measuring progress, an honest review); `technology_ethics`
  (stakeholders and reasons, AI and its patterns, bias in training data, personal data, the GDPR and 13 in the UK,
  weighing reasons, automation and who decides).

## Learn by doing: the Life and Success links (owner #112, #115, #117)
Fifteen units keep their lesson and exercises and point their last card ("Try it in the world") to an Experience by
its own title, checked by the content test against `data/life/experiences/*.json` and `data/success/experiences/*.json`:
- **Success Stories** (on the Story Shelf): `first_world_war` (Marie Curie's X-ray cars), `second_world_war` (Alexander
  Fleming's penicillin, made for everyone in the war), `building_peace` (Henry Dunant and the Red Cross),
  `space_digital_age` (Katherine Johnson), `development` (Fazle Hasan Abed and BRAC), `feeding_the_world` (the rice
  scientist's story: Yuan Longping, named by his story not by his name, see ruling 9), `future_cities` (Hassan Fathy's
  mud-brick homes).
- **Earth and Weather** (Life L3a, being built now): `climate_change` (floods and heatwaves).
- **Talk & Deal**: `your_voice` (a clear pitch), `consumer_rights` (a polite complaint).
- **The Connections Book**: `fairness_for_all` (help someone different from you first).
- **My Money Stall**: `life_budget` (plan the stall's budget), `credit_debt` (the bank's interest), `investing_risk`
  (the money tree).
- **The Goal Board**: `global_goals_action` (the goal, its steps and an if-then plan).

## Generators (`core/school/gen/g8_hum_gen.gd`, `G8HumGen`, SchoolGen source "g8h", the last SOURCES line)
64, seeded, levels 1-3, each with a hint, a worked answer and `data`. Sort drills share `_sorter` (as grade 7's: level 1
one item's group as a choice, level 2 four items, level 3 six or fewer when the worked answer would not fit), match
drills `_match` (never side by side), dated facts `_dates` (which came first, years apart, four in order). History: the
modern world's 30 dated events in order and apart, anniversaries to 2025 (years); a stagecoach against a train; towns
from 1801 to 1851; inventions; thinkers and ideas; the three powers; the triangle's goods; abolition, independence and
votes for women by year; "1 in N" and electorate shares; the two wars' sides; a family's ration book; upstanders;
the UDHR's freedoms and decent life; chips doubling (2,300 in 1971); the space race's firsts. Geography: CO2 rises
(Mauna Loa's decades) and percentage rises from 280; climate causes, effects and responses; mitigation and adaptation;
three countries' measures in a table; population pyramids (the biggest band, the share aged 0-14, what the shape
says; the bands always add to 100); trade balances; supply chains in order; energy sources; an electricity mix as a
bar graph (renewables, TWh, low-carbon); kWh and their cost, an LED's saving; virtual water; farms by kind and scale;
density, the denser city, a district's people; city problems and fixes; tourists' spending, leakage and each
resident's share; tourism's effects; the tourism cycle (from a picture, a description, what comes next); ocean zones,
pressure and a dive's minutes; litter's years (a year up to 2625); Mercator's stretch (1, 1.5, 2, 2.5, 3, 4), areas and
true areas; projections for jobs; a GIS overlay of houses and a flood zone (count, at risk, percentage); points, lines
and areas. Citizenship: a first-past-the-post winner, proportional seats, the gap; a school vote (winner, percentage,
votes short of a majority); England's ages in law; rights and responsibilities; equality and equity; VAT and income tax
in bands (in gold, "in this example"); a budget's shares; a monthly budget (what is left, 50/30/20, months to save);
fixed and variable costs; simple-interest loans (interest, monthly payment, the cheaper of two); credit scores; the rule
of 72; investing 120 gold a month (units, average cost); real returns (below 0 too); UK refund rights; best buys; a
Global Goal for an action (never a goal it also serves); a target's progress; reasons for and against four proposals;
personal data; an AI's training data and accuracy.

## Pictures (`ui/school/school_picture_g8hum.gd`, `SchoolPictureG8Hum`, 10 kinds, hooked after `SchoolPictureG7Life`)
`steam_engine` (a beam engine with Watt's separate condenser in its cold tub, labelled with grade 7's `_label_parts`),
`greenhouse` (sunlight in, heat out, some kept in; `more`: a thicker blanket), `scatter_plot` (two axes from data, a
least-squares `line`, labelled points), `pop_pyramid` (age bands out from the middle), `tourism_cycle` (the life
cycle's S-curve with its stages shaded and the two `paths` after stagnation; `stage_after`), `ocean_zones` (five bands,
depths, creatures; `zone_at`), `projection` (the globe, Mercator, Gall-Peters, Robinson from its table, a north-polar
azimuthal map, with the same 7°-radius circles on the globe drawn as each map draws them: Tissot's circles;
`stretch`, `mercator_y`), `parliament_seats` (a hemicycle of dots, each row's seats in proportion to its length, the
majority's seat marked; `majority`), `receipt` (a till slip with a total or "?"; `receipt_total`), `balance_scale`
(reasons stacked on two pans, the heavier side down; `tilt`). Samples, broken data and the rules in
`tests/integration/test_school_picture_g8hum.gd` (10/10).
- **Looked at in a real window** (a scratch render script in a SubViewport, no editor): all 34 samples at 580 × 250 and
  248 × 126, every lesson picture of the 31 units (80 renders), and `tools/school_shots.gd` for
  `g8.geography.map_projections` with its exercises and the grown-ups' page for grade 8 history (the seven hard lines
  fit in three lines). Fixed on sight: the greenhouse gases' dots fell in a diagonal line (now an R2 sequence) and the
  kept-in heat waves crossed; sea creatures too small; seats overlapping at 100 (the dot now fits the tightest row); a
  one-line receipt in huge letters and a six-line one running off its slip; the balance's boxes overlapping on a small
  card (pans now sit on the beam, boxes sized to the room); a table header and a chain step squeezed.

## Rulings (decide and write down; cost if wrong)
1. **Memory first naming grades 3-7; "Try it in the world: … Next: …" last** (the test enforces both). *Cost:* none.
2. **Hard history is named truthfully, never shown, and marked in the outline for seven units** (research §5.4 rule
   3, ruling 9): `ideas_of_liberty` ("the Terror and the revolutionary wars"), `slavery_abolition` ("the
   transatlantic slave trade and enslavement"), `empires_independence` ("empire, the Bengal famine and the violence of
   partition"), `first_world_war`, `second_world_war` ("the Second World War, the Blitz, Hiroshima and Nagasaki"),
   `holocaust_remembrance` ("the Holocaust: persecution and murder of Europe's Jews"), `building_peace`
   ("segregation, apartheid and the struggle for civil rights"). The lead said to touch only the units' `file` fields;
   the brief and the research require hard history to be listed for grown-ups, so these seven `hard` lines (in my own
   units' entries only) were added too. *Cost:* the lead may drop a line (the test lists the seven).
3. **"Murdered" for the Holocaust, and only there.** Holocaust education (the outline's goal says "persecution and
   murder") uses the true word; every other unit and every generator avoids "murder" and "killed" ("died", "lost their
   lives", "put to death"); the test bans gruesome words and weapon detail everywhere (no "rifle", "bullet", "gas
   chamber"…). Numbers of the dead are given where they are the history's scale (the slave trade's crossing, the world
   wars, six million), never as drills: no generator counts deaths. *Cost:* none.
4. **The slave trade told with care:** "enslaved people" (an exercise explains why), resistance and abolitionists given
   as much room as the trade, the compensation paid to enslavers named plainly, forced labour today mentioned, 23
   August for remembrance. *Cost:* none.
5. **No living people, no parties, no brands.** Unnamed: the Web's inventor ("a British scientist at CERN"), the second
   moonwalker, the first woman in space ("in 1963 the first woman flew"), the geographer of the tourism cycle, the
   car company at Dagenham; the Indian independence movement is told through Gandhi and Nehru, not party names. The test
   bans today's parties (and "Indian National Congress", "Muslim League", "ANC") and a list of living people and brands.
   *Cost:* some names a teacher would use are missing.
6. **Politics in general terms:** systems compared (no party, no living politician), "Group A/B/C" in the seats picture,
   proportional representation's points "often given" for and against, public spending "roughly like the UK's" with
   "no single right answer", votes at 16 as a fact of some places, not an argument. *Cost:* none.
7. **UK law as the worked example, said to be England's or the UK's:** ages (10, 13, 16, 17, 18; Scotland's 12 and
   votes at 16), the Equality Act's nine characteristics (five named: age, disability, race, religion or belief, sex),
   the Consumer Rights Act (30 days, repair or replace, 14 days online), UK digital consent at 13, an appropriate adult.
   *Cost:* other countries' consumer and equality law only in general terms.
8. **Money is gold** and tax is "in this example" (12,000 gold tax-free, 20% to 50,000, 40% above); simple interest
   where the prompt says so; real returns may be below 0 (the pad takes "-3"). *Cost:* none.
9. **Words the content test bans as currencies stay out even as names:** "Yuan Longping" is named "a Chinese
   scientist" and "the rice scientist" (his story is on the Story Shelf); "Pearl Harbor" keeps its name's spelling
   (the British-spelling test does not list "harbor"). *Cost:* his name only in Success Stories.
10. **Letters the font has:** "Simon Bolivar", "Medellin", "Galapagos" without accents; René Cassin keeps the font's
    é. *Cost:* none. (The first woman in space is alive, so ruling 5 leaves her unnamed.)
11. **Numbers as the sources give them, rounded for children:** Manchester about 70,000 → about 300,000 (70,409 and
    303,382); towns' 1801 and 1851 people to the nearest 10,000; electorate "about 1 in 5 men" in 1832 (sources give
    18-20%) and the graph's "of every 10" (2, 3, 6, 10); the sugar boycott's "about 300,000 families" (Clarkson's
    figure); about 1.2 °C warmer (2015-2024); renewables "about a third" of electricity (32% in 2024); hunger "about
    670 million"; litter's years are scientists' estimates. *Cost:* none.
12. **Maps have no coastlines** (grade 5's ruling), so routes and places sit on the grid; projections show their
    stretch with Tissot's circles instead of countries. *Cost:* coastline outlines later.
13. **The units are written by a scratch builder** (kit, history, geography, citizenship) that checks every limit, the
    banned words, British spelling, sums, the audit's long cards and sentences, and the 60% choice share before it
    writes; the unit files are the source of truth.
14. **TDD order:** the content test (`test_school_content_g8_hum.gd`) and the picture samples were written first and
    watched failing (31 units "is written"; the picture class missing); the generator source was written before its
    test (a deviation from the brief), then the test caught two real bugs (non-whole percentages for 200 voters, a
    pyramid shape rule) before the first commit. *Cost:* none known.
15. **An outline title is cut off on the grown-ups' list** ("From the space race to the digital age"): left as it is,
    because the instruction was to touch only `file` fields. *Cost:* the lead may shorten it.

## Facts checked (with sources)
- Manchester 70,409 (1801) and 303,382 (1851) (Manchester City Council, "Manchester population 1086-2016"). The Factory
  Act 1833: no children under 9 in textile mills, 9-13s at most 48 hours a week, four inspectors (UK Parliament; EBSCO;
  Lumen). Watt's patent 1769; Newcomen 1712; Cromford Mill 1771; Stockton and Darlington 1825; Liverpool and Manchester
  1830 (Britannica).
- The electorate: 1832 about 18% of adult men; 1867 about 1 in 3; 1884 about 60%; 1918 over 21 million, all men over
  21 and women over 30 with property, about 8.4 million women; 1928 equal votes at 21; 1969 votes at 18 (UK Parliament;
  Wikipedia "Parliamentary franchise in the United Kingdom 1885-1918"). Old Sarum's 7 voters and 2 MPs; Manchester's
  none before 1832.
- The slave trade: about 12.5 million embarked, 10.7 million landed, about 1.8 million died on the crossing
  (SlaveVoyages / the Trans-Atlantic Slave Trade Database). The 1833 compensation of 20 million, about 40% of the
  government's spending (HM Treasury FOI 2018; Full Fact). The sugar boycott: about 300,000 families (Clarkson; Drescher
  calls it "not an unreasonable guess"). Equiano's Narrative 1789; Samuel Sharpe's rising 1831-32; 23 August (UNESCO).
- About 1.5 million South Asians in the Indian Army in the First World War (1914-1918-online); about 2.5 million in
  the Second; Dunkirk about 338,000; evacuation about 1.5 million in the first days (several histories; others give
  1.25-3 million); rationing January 1940 to July 1954.
- The Righteous Among the Nations: 28,707 from 51 countries on 1 January 2024 (USHMM; Yad Vashem); the Kindertransport
  about 10,000 children; six million Jews, about two-thirds of Europe's Jews, 1.5 million children (USHMM).
- The UDHR 10 December 1948, 30 articles, Hansa Mehta's "all human beings" (UN). The Bristol bus boycott 1963 and the
  Race Relations Act 1965; the Equal Pay Act 1970 after the Dagenham strike of 1968; the Disability Discrimination Act
  1995; the Equality Act 2010's nine protected characteristics (UK government).
- Mauna Loa annual means: 316.91 (1960), 325.68 (1970), 338.76 (1980), 354.45 (1990), 369.71 (2000), 390.10 (2010),
  414.21 (2020), 424.61 (2024) ppm (NOAA GML, co2_annmean_mlo.txt). 2024 about 1.55 °C above 1850-1900, the warmest
  year (WMO). Sea level about 20 cm since 1901 (IPCC AR6).
- Fossil fuels 81.5% of primary energy in 2023 (Energy Institute, Statistical Review 2024). Wind 8.1%, solar 6.9%,
  hydro 14.3% of electricity in 2024, low-carbon 40.9% (Ember, Global Electricity Review 2025).
- Hunger: 673 million in 2024 (SOFI 2025); 8.2 billion people (UN World Population Prospects 2024). Water footprints:
  beef 15,415, cheese 5,060, chicken 4,325, rice 2,497, bread 1,608, apples 822, potatoes 287, tomatoes 214 litres a kg
  (Water Footprint Network, rounded).
- Cities: 45% of people in cities, 20% in 1950, 33 megacities (UN World Urbanization Prospects 2025).
- Tourism: about 25 million international arrivals in 1950, 1.46 billion in 2019, about 1.4 billion in 2024 (UN
  Tourism, World Tourism Barometer).
- Plastic: about 11 million tonnes into the ocean a year (Pew, "Breaking the Plastic Wave", 2020). Litter's years:
  NOAA's marine debris estimates.
- The Bundestag's 630 seats since 2025 (the Federal Returning Officer); the House of Commons 650; the Electoral College
  538; India about 968 million voters in 2024.
- Known dates as the standard record (Britannica): Locke 1689, Montesquieu 1748, the Boston Tea Party 1773, the
  Bastille 14 July 1789, the Rights of Man August 1789, Olympe de Gouges 1791, Haiti 1804, Waterloo 1815; the scramble
  for Africa and 1914; the Raj 1858; the Salt March 1930; Quit India 1942; 15 August 1947; Ghana 1957; 1960's 17 African
  countries; Jamaica 1962; Kenya 1963; the Commonwealth's 56; Sarajevo 28 June 1914; the Somme 1 July-18 November 1916;
  the Armistice 11 November 1918; Poland 1 September 1939; the Blitz September 1940-May 1941; Pearl Harbor 7 December
  1941; D-Day 6 June 1944; VE Day 8 May 1945; Hiroshima and Nagasaki 6 and 9 August 1945; the Nuremberg Laws 1935;
  Kristallnacht 9-10 November 1938; Anne Frank 1929-1945, in hiding from 6 July 1942; 27 January 1945; Montgomery
  1955-56 (381 days); 1963; the Civil Rights Act 1964 and Voting Rights Act 1965; apartheid 1948-1994; Sputnik 4
  October 1957; Gagarin 12 April 1961; Apollo 11 20 July 1969; Colossus 1944; the transistor 1947; the 1971
  microprocessor's 2,300 transistors; ARPANET 1969; the Web 1989; Mercator 1569; Robinson 1963; John Snow 1854; the
  container 1956; Curitiba 1974; Seoul's Cheonggyecheon 2005; the Paris Agreement 2015; the SDGs' 169 targets.

## Tests
- `tests/unit/test_school_content_g8_hum.gd` (written first; it failed with "g8.history.industrial_revolution is
  written" and 153 more): the outline's 10 + 10 + 11 units; every unit written with no problems, 4-8 cards, 12+
  exercises at levels 1-3 of 2+ kinds, rounds that fill, vary and never repeat; the quality bar (test_school_quality's
  `bar`); hints are strategies; memory of grades 3-7 first, the world and Next last; the 15 Life and Success links and
  their titles; no question twice; only g8h generators, all used; each unit's pictures and every new kind drawn; a year
  is a year; gold only; no gruesome words, weapon detail, parties, disputed places, living people or brands; "murder"
  only in the Holocaust unit; hard history marked for exactly seven units: 16/16 (470 exercises).
- `tests/unit/test_g8_hum_gen.gd`: one test per generator (64) plus the registration test, 60 seeds × 3 levels, every
  answer worked out again from `data` with this file's own facts: 65/65.
- `tests/integration/test_school_picture_g8hum.gd`: 34 samples valid and drawn at four sizes, 36 broken pictures, and
  the rules (Mercator's stretch, a majority, the zones, the cycle, a receipt's total, the balance's tilt): 10/10.
- `tools/school_check.gd` on every unit of the School: 738 units, 0 problems. `tools/school_audit.py --grades 8`: all 31
  units at 100 once these notes name them.

## The full suite (2026-10-17, this branch at 10ee9d4f: lead-merge at b585e78b merged in)
`tests/run_tests.sh`: **11,253 tests in 1,215 scripts: 11,248 passing, 2 failing, 3 risky**, no script or parse errors,
70 minutes. The two failures were tests pinned to the state before these units, both fixed and passing on their own:
- `test_daily_mission.gd`'s `test_a_grade_with_three_subjects_still_gets_five_questions` used grade 8 as the grade of
  three subjects ("grade 8 so far"); it now makes its own three-subject grade 8 from the real outline with
  `Curriculum.put_grade` and clears the cache after (8/8). The later grade 8 agents would have hit it too.
- `test_g7_life_gen.gd` asserted "g7w is the last SOURCES line"; the brief adds every new source at the end, so it now
  asks that g7w is a line after grade 7's other sources (1/1).

## For the lead when merging
- Expect conflicts in `core/school/school_gen.gd` (one SOURCES line `"g8h"` after `"g7w"`: keep both; the grade 8
  computing/arts and life agents will add `"g8c"` and `"g8l"` beside it), `ui/school/school_picture.gd` (a header
  paragraph and a `problem` and a `draw` hook after `SchoolPictureG7Life`'s; each draw hook keeps its own `return`),
  `docs/DEVELOPMENT.md` (one bullet after grade 7 health's), and `data/school/grade8.json` (only these 31 units' `file`
  lines and seven `hard` lines). Kind names checked against lead-merge of 2026-10-17 (unique: test 2/2 expected). Run
  `godot --headless --path . --import` after the merge (new classes `G8HumGen`, `SchoolPictureG8Hum`).
- Not done here (to avoid conflicts): `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md`,
  the spec's §22.4 line for grade 8, RESUME-HERE, the owner-feedback row.
- When Life L3a lands, check its Experience's title is "Earth and Weather" (the test allows it as pending until then).
- Worth a look in the School's frame: `g8.history.slavery_abolition` (the triangle on a coastless map),
  `g8.geography.connected_world` (the shipping routes on the whole world's grid), `g8.citizenship.fairness_for_all` (the
  balance's small boxes at card size).
