# Grade 7 maths, science and English: the last units written (owner #70, #73, #111; 2026-10-17)

The owner: "full school programs and syllabus content in the game" (#111), and earlier "start from grade 3 and finish
all grades accordingly" (#70). The research (`docs/design/school-curriculum-research.md` §6.7) merged Singapore
Secondary 1 (prime factorisation, significant figures, rate and speed, misleading charts, separating mixtures, light)
and England Year 8 / KS3 (acids and alkalis, the periodic table, the atmosphere) into grade 7, with Common Core's
reading, writing and speaking standards; 14 of those units still showed "Coming soon" on lead-merge a3a4e75d. This
agent wrote all 14 from the reusable brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 7,
SUBJECTS = maths, science, English), with grade 7's written units of those subjects and grades 3-6 as the spiral.
**After it, every unit of grade 7's maths (18), science (17) and English (18) is written.**

## What was written
| Unit | Cards | Hand-written exercises (levels 1/2/3) | Kinds | Generators (g7k) |
|---|---|---|---|---|
| maths `primes_estimation` | 8 | 22 (7/9/6) | number 12, choice 3, truefalse 3, match 2, sort, order | `estimate_calc`, `factorise`, `hcf_lcm`, `prime_pick`, `round_dp`, `round_sf` |
| maths `speed_rate` | 8 | 19 (6/7/6) | number 12, choice 2, truefalse 2, match, order, sort | `average_speed`, `dt_read`, `speed_calc`, `speed_convert` |
| maths `misleading_graphs` | 7 | 19 (5/8/6) | number 7, choice 6, match 2, truefalse 2, sort, order | `best_chart`, `cut_axis_look`, `picture_scale` |
| science `periodic_table` | 8 | 20 (7/7/6) | choice 6, truefalse 4, number 4, match 2, sort 2, order, label | `element_place`, `element_symbol`, `metal_sort` |
| science `mixtures_separating` | 8 | 19 (6/7/6) | choice 6, truefalse 4, match 2, sort 2, order 2, number 2, label | `chroma_read`, `mixture_words`, `separate_method` |
| science `acids_alkalis` | 7 | 19 (6/7/6) | choice 8, truefalse 3, number 2, sort 2, match 2, order 2 | `indicator_colour`, `ph_kind`, `salt_name` |
| science `light_colour` | 7 | 20 (6/7/7) | choice 9, truefalse 3, order 2, match 2, number 2, sort, label | `colour_seen`, `refraction_bend`, `spectrum_order` |
| science `air_carbon_cycle` | 7 | 20 (6/7/7) | choice 7, number 4, truefalse 3, sort 2, order 2, match, label | `air_share`, `burn_products`, `carbon_process` |
| English `strong_evidence` | 7 | 19 (6/7/6) | choice 8, truefalse 3, sort 3, match 3, order 2 | `evidence_pick`, `quote_or_paraphrase` |
| English `fiction_and_history` | 7 | 19 (6/7/6) | choice 9, sort 3, truefalse 3, match 2, order 2 | `fact_or_fiction`, `out_of_time` |
| English `speeches_media` | 7 | 19 (6/7/6), 4 to listen to | choice 8, truefalse 3, match 2, number 2, sort 2, order 2 | `appeal_kind`, `speech_trick` |
| English `write_argument` | 7 | 19 (6/7/6) | choice 9, truefalse 3, sort 3, match 2, order 2 | `reasoning_flaw`, `rebuttal_pick` |
| English `write_informative` | 7 | 19 (6/7/6) | choice 9, sort 3, truefalse 3, match 2, order 2 | `precise_term`, `signal_word` |
| English `write_narrative` | 8 | 19 (6/7/6) | choice 9, truefalse 3, match 3, sort 2, order 2 | `pov_name`, `sense_detail` |
| **All** | **103** | **272** | choice 99, number 47, true or false 42, sort 28, match 28, order 24, label 4 | 40 generators, every unit's at levels 1-3 |

- **Files:** `data/school/g7/<subject>/<unit>.json`, linked from `data/school/grade7.json` (only these 14 units gain a
  `file` line; titles, goals and every written unit unchanged).
- **Every unit** opens with "Quick memory:" and a question from what it builds on (an earlier grade, named, or the unit
  before it), teaches one idea a card with a worked example and pictures, and ends "Try it in the world: … Next: …"
  (research §5.3 rules 1, 7 and 8). Every unit scores 100 on `tools/school_audit.py` and meets
  `test_school_quality.gd`'s bar: at most 63% choice and true-or-false, five to seven kinds of exercise, level 3 asking
  more than level 1 (the audit's demand), reading level (Flesch-Kincaid) 1.6 to 5.4 for grade 7's 8.
- **Generators** `g7k` (`G7CoreGen`, `core/school/gen/g7_core_gen.gd`, the last SOURCES line): 40, each at levels 1-3,
  checked by `tests/unit/test_g7_core_gen.gd` (every answer worked out again from `data` with the test's own arithmetic,
  periodic table, pH values, colour rules and word banks; one test a topic).
- **Pictures:** 18 new kinds in `SchoolPictureG7Core` (`ui/school/school_picture_g7core.gd`, hooked after
  `SchoolPictureG8Arts`; samples and rules in `tests/integration/test_school_picture_g7core.gd`): `factor_tree`,
  `prime_venn`, `distance_time`, `speed_triangle`, `chart_kinds`, `odd_scale`, `big_icons`, `periodic_grid`,
  `ph_scale`, `separation`, `chromatogram`, `light_rays`, `seen_colour`, `carbon_cycle`, `air_mix`, `marked_text`,
  `venn`, `pov_view`. Earlier kinds reused: `cut_axis_bars` (grade 7 citizenship), `greenhouse` (grade 8 geography),
  `rgb_mix` (grade 6 computing), `reflection` and `argument_map` (grade 6 core), `step_chain` (grade 7 humanities),
  `table`, `number_line`. `part_at` places label pins on four diagrams (`RATIOS`: separation, light_rays,
  carbon_cycle, periodic_grid); every label's line ends on its part (the content test).
- **Tests:** `tests/unit/test_school_content_g7_core.gd` (written first; it failed 11 of 16 before the units existed):
  every unit written and linked, grade 7's maths, science and English complete, the quality bar, memory first and
  the world with Next last, the facts each lesson teaches (`MUST`), the pictures each unit draws (`DRAWS`), every new
  kind on a lesson card, label lines on their parts, the Life and Success links, the pictures' answers worked out
  again (a factor tree's hidden prime, HCF and LCM, a leg's speed, how tall a bar looks on a cut axis and on a fair one,
  a scaled picture's area or volume, a chromatogram's dyes), speeches heard, and safety (no puberty, drugs, alcohol,
  smoking or gambling, no currencies, no brands, no personal questions; "never taste", "with a grown-up", "never mix",
  "never look straight at the Sun").

## The Life and Success links (owner #112, #115, #117)
Ten units whose topic is an Experience end by naming it in the LIFE tab (`LIFE_LINKS` in the content test, each title
read through `LifeExperience.data`):

| Unit | Experience | Why |
|---|---|---|
| maths `primes_estimation` | My Money Stall | estimate a basket's total before paying (its budget and change) |
| maths `speed_rate` | Safe Streets | the Big track's speed limit; a fast car's stopping distance |
| maths `misleading_graphs` | Success Stories | the Middle track's Florence Nightingale, who "used numbers to show the truth" |
| science `periodic_table` | Electricity Safety | metals conduct, so "only plugs" go in a socket, never a fork |
| science `acids_alkalis` | The Poisons Cupboard | corrosive cleaners; "never mix cleaners" (the Middle and Big tracks) |
| science `light_colour` | Safe Streets | the Middle track's "be seen at night": bright and reflective clothes |
| science `air_carbon_cycle` | Fire Escape, The Poisons Cupboard | fires need oxygen, so close doors; burning with too little air makes carbon monoxide (the CO alarm) |
| English `fiction_and_history` | Success Stories | true stories of real people acted out |
| English `speeches_media` | Talk & Deal | the Big track's pitch |
| English `write_argument` | Talk & Deal | ask what the other person needs: answering the other side |

## Facts and their sources
- **Primes, HCF, LCM, rounding, estimating** (Singapore Secondary 1 "numbers and their operations"; England KS3
  number): every whole number above 1 has one prime factorisation (the fundamental theorem of arithmetic); HCF = the
  product of the shared primes, LCM = the product of all of them once; HCF × LCM = a × b (checked by Euclid's method in
  the picture test); rounding half up at the next digit; significant figures from the first non-zero digit. Every sum
  checked by script; 48.7 × 21.3 = 1,037.31; 297.6 ÷ 0.51 = 583.5 (to 1 decimal place).
- **Speed** (Singapore S1 rate and speed): speed = distance ÷ time; 1 km/h = 1,000 m ÷ 3,600 s, so ÷ 3.6. The Highway
  Code's typical stopping distances (rule 126): at 30 mph (48 km/h, about 13 m/s), 9 m thinking and 14 m braking, 23 m
  in all; given here in km/h and metres. Sound in air about 340 m/s (343 m/s at 20 °C). Light about 300,000 km/s
  (299,792 km/s); sunlight takes about 500 s (499 s) to cross 150 million km (1 au = 149.6 million km). A cheetah's
  measured sprint, about 25-29 m/s (Wilson et al., Nature 2013: 25.9 m/s; the content says "about 25 m/s").
- **Graphs that mislead** (Singapore S1 data handling; England KS3 statistics): an axis that does not start at 0, uneven
  steps, pictures scaled in two directions (area k²) or three (volume k³), cherry-picked months. Florence Nightingale's
  1858 diagrams (her "Notes on Matters Affecting the Health, Efficiency and Hospital Administration of the British
  Army") showed that most deaths in the army's hospitals in the Crimean War came from preventable diseases; sanitary
  reform followed (Royal Commission, 1857-58). Told calmly, with no detail of war.
- **The periodic table** (England KS3): 118 elements (IUPAC); atomic number = protons; Dmitri Mendeleev's table of 1869
  with gaps and predictions; gallium found in 1875 (Lecoq de Boisbaudran) and germanium in 1886 (Winkler), his
  eka-aluminium and eka-silicon. Groups and periods; the alkali metals react with water, more vigorously down the
  group; the halogens; chlorine compounds disinfect pools; the noble gases hardly react; helium is unreactive and
  hydrogen flammable. Mercury, a metal, melts at −38.8 °C. Metals left of the staircase, metalloids along it (B, Si,
  Ge, As, Sb, Te, At: the common school list). Latin symbols: Na natrium, K kalium, Fe ferrum, Cu cuprum, Ag
  argentum, Sn stannum, Au aurum, Hg hydrargyrum, Pb plumbum. The game's Survivor has iron, gold and coal blocks.
- **Mixtures and separating** (England KS3 pure and impure substances; Singapore S1): solute, solvent, solution,
  soluble, insoluble; filtering (residue, filtrate), evaporating, distilling (a condenser with cold water in at its
  low end), paper chromatography (a pencil start line, as pencil does not dissolve; Rf = the substance's distance ÷ the
  solvent's). Thermal desalination (distilling sea water) supplies drinking water in some dry countries (multi-stage
  flash plants in the Gulf).
- **Acids and alkalis** (England KS3): the pH scale 0-14, 7 neutral; each pH step is 10 times the hydrogen-ion
  concentration; litmus red in acid and blue in alkali; universal indicator from red through green (7) to purple;
  acid + alkali make a salt + water, the salt named from the alkali's metal and the acid (chloride, sulfate, nitrate);
  a base neutralises an acid, an alkali is a base that dissolves in water; indigestion tablets (calcium carbonate,
  magnesium hydroxide) and agricultural lime are bases. Typical pH: stomach acid 1-2, lemon juice 2, vinegar about 3,
  tomato juice about 4, black coffee about 5, pure water 7, baking soda in water about 8, soap 9-10, household ammonia
  11-12, bleach 12-13, oven cleaner about 13, drain cleaner (sodium hydroxide) 14. Bleach mixed with an acid cleaner
  gives off chlorine gas (NHS and UK poison-centre advice: never mix cleaners). Red cabbage juice (anthocyanins) is pink
  in acid, purple when neutral and blue-green to green in alkali.
- **Light and colour** (England KS3 light waves; Singapore S1 light): the law of reflection; specular and diffuse
  reflection; refraction towards the normal into a denser material (Snell's law; glass n ≈ 1.5, about 200,000 km/s;
  water n ≈ 1.33, about 225,000 km/s); Newton's prism (1666; Opticks, 1704): red refracted least, violet most; colour
  by reflection and absorption; filters pass their own colour; light adds (red + green = yellow; all three white), as
  the Science Lab's "Mixing colours" bench shows (it already listed this unit). Never look straight at the Sun.
- **The air and the carbon cycle** (England KS3 Earth and atmosphere): dry air 78.08% nitrogen, 20.95% oxygen, 0.93%
  argon, about 0.042% carbon dioxide (NOAA, Mauna Loa: about 424 parts per million in 2024; about 280 before 1800);
  breathed-out air about 16% oxygen and 4% carbon dioxide; photosynthesis, respiration, feeding, death and waste,
  decay, fossilisation and combustion; fossil fuels from buried plants and sea creatures; the natural greenhouse effect
  keeps the Earth's average near 15 °C instead of about −18 °C (33 °C; NASA, Met Office); burning with too little
  oxygen makes carbon monoxide (hence CO alarms).
- **English** (Common Core): `strong_evidence` RL.7.1, RI.7.1 (several pieces of evidence; point, evidence, explain,
  the UK schools' paragraph); `fiction_and_history` RL.7.9 (a story and a history of the same time: William Caxton's
  press at Westminster, 1476, Chaucer's Canterbury Tales, his prologues, his death about 1492, as grade 7 history
  teaches; potatoes reached Europe from South America only after Columbus, the telescope dates from 1608, electric
  light from the 1870s); `speeches_media` SL.7.3 and RL.7.7 (Aristotle's ethos, pathos and logos from his Rhetoric;
  pace and pauses heard as claps, as grade 6's discussions did); `write_argument` W.7.1a-b (counterclaims, logical
  reasoning, credible sources); `write_informative` W.7.2a, d (compare and contrast, cause and effect, precise words;
  frogs' smooth skin and clumped spawn, toads' dry skin and strings of spawn; deforestation and soil erosion);
  `write_narrative` W.7.3a, b, d (point of view, pacing, sensory language).

## Rulings (decided; what each costs if wrong)
1. **"Strongly acidic", "weakly alkaline"** for a pH's place on the scale, never "a strong acid" (in chemistry "strong"
   is about how an acid splits up in water, a later topic). *Cost:* textbooks that say "pH 1 is a strong acid" read a
   little differently; one word change in `SchoolPictureG7Core.strength`.
2. **Universal indicator's bands:** red 0-3, orange 4-5, yellow 6, green 7, blue 8-10, purple 11-14 (charts differ by
   a step); exercises ask only at pH 1-2, 7, 9 and 12-14, where every chart agrees. *Cost:* none in the exercises.
3. **"Sulfur"**, the IUPAC spelling England's curriculum uses, not "sulphur". *Cost:* none.
4. **Life links only where the topic is an Experience** (ten units); mixtures, strong evidence, information writing and
   narrative writing name none. *Cost:* the lead may want more links later; one line each.
5. **Elements 109-118 are drawn grey ("unknown")**, as only a few atoms have been made, and the lanthanides and
   actinides (with lutetium and lawrencium) are left out of the main table, group 3's gap marked "*". *Cost:* some
   tables shade 109-118 as predicted metals or put Lu and Lr in group 3.
6. **"Fiction and history" builds on Caxton** (grade 7 history's printing press), not the Great Fire of London, which
   the game's history does not teach. *Cost:* none.
7. **Nightingale's charts are not marked hard history** (one calm sentence about deaths from disease in army hospitals,
   no war detail). *Cost:* a grown-up might want it listed; one `"hard"` line in the outline.
8. **"Tom feels left out"**, not "Tom is lonely": "lonely" is on the School's guilt-words list (`UNKIND`). *Cost:* none.
9. **Stopping distances in km/h and metres** (the Highway Code's 30 mph row converted), as the School is metric.
   *Cost:* none.
10. **One generator source for the 14 units** (`g7k`, 40 generators), as grade 6's core units did (`g6k`). *Cost:* none.
11. **The full periodic table's box is 2.4 : 1** (`RATIOS`), so 18 groups fill the card; label pins are worked out by
    `part_at` from the same box. *Cost:* none.

## Checks run
- `tests/run_tests.sh -gtest=…`: `test_school_content_g7_core.gd` 16/16, `test_g7_core_gen.gd` 20/20,
  `test_school_picture_g7core.gd` 15/15, `test_school_quality.gd` (0 of 682 units under the bar),
  `test_school_content.gd` (every exercise right by its own answer, every generator 120 seeds × 3 levels, words, sums).
- `python3 tools/school_audit.py --grades 7`: the 14 units score 100; `--check`: no problems.
- `tools/school_check.gd` on the 14 units: 0 problems (table cells at 17 px or more).
- **The full suite** on this branch merged with lead-merge 71e6322c (the merges kept both sides of SOURCES, the picture
  hooks and DEVELOPMENT.md): 1,244 scripts, 11,559 tests, **11,556 passing, 0 failing**, 3 risky or pending (none of
  this branch's: `test_device_move_nakama.gd`'s move by code is off on the server, and two terrain tests that do not
  assert), 4,773 s. An earlier run on the tree merged with d4c74bfb was stopped by the owner's pause at 1,125 scripts
  with no failure.
- Pictures looked at: every sample and every picture of the 14 units drawn into contact sheets with a windowed Godot
  (a scratch copy of the earlier agents' sheet renderer), at 520 × 230; fixes made from them (the full table's size, the
  filter and the evaporating basin drawn larger, the condenser's water in at its low end, a ball for "a blue cup").
