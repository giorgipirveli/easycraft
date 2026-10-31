# Fraction Bakery, phase A (research and design) (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-18-game-fraction-bakery-brief.md`; the authority: `docs/design/future-lessons.md`
(the five tests, the four gated phases); the models of a good phase A: Inside a Leaf's and Balance Altar's
(`docs/design/games/leaf-voyage.md`, `balance-altar.md`, each with the lead's review at its end). Phase A only: research and
the design, no game code. Done on 2026-10-18 by the game agent on the worktree branch `worktree-agent-aa69169ab842fa870`,
cut from lead-merge at `1771f0ba` (the brief). No editor, no emulator, no adb, no agents, no Godot runs.

## What was delivered

- **The design:** `docs/design/games/fraction-bakery.md`: the research (what children of 8-12 get wrong about fractions and
  what fixes it, with the numbers: whole-number bias, a fraction as two numbers, equal parts ignored, no felt size,
  "multiplying makes bigger", the wrong operation's rule, halving, decimals' longer- and shorter-is-larger, additive
  ratios, the swapped division, the forgotten whole; the evidence for the method: Siegler's integrated theory and the
  predictors study, the IES practice guide's five recommendations with their evidence levels, Fraction Face-Off, the
  number line against area models, the Rational Number Project, Moss & Case's percent-first curriculum, equal sharing,
  incorrect examples, embodiment; ten games and apps with what their evidence says and does not say; the curriculum
  strand: sixteen units with their standards, ideas, exercises and generators, and the units left to other games), the
  fantasy, the core loop, the verb for every idea, Opening Night and Midnight Leftovers beat by beat with the bakery's
  rules from the model, the Maths door (how a child of each grade finds the bakery or the temple), the ladder (four rungs,
  grades 3-6, about 24 rooms with their transfer rooms, and the fade from pictures to symbols), minute 1, 5 and 30 flat and
  in VR, every voice line of phase B (50 lines, each at most 12 words: checked by a script) and how the voice carries the
  numerals, the meanings of things, the music, the five tests answered with the models' numbers, the evidence model into
  `SkillShown`, the look, the tech plan for phase B, phases and estimates, risks, 38 rulings with their costs, eleven open
  questions, an honesty table and 36 new sources (and the standards).
- **The owner's page:** `docs/design/games/fraction-bakery-owner.md` (one page, plain words, three pictures: 01, 02, 07).
- **Pictures:** `docs/design/games/fraction-bakery/01-…12-*.png` and their `.svg` sources, drawn by
  `docs/design/games/fraction-bakery/make_pictures.py` (`/usr/bin/python3 -I docs/design/games/fraction-bakery/make_pictures.py
  [name …]`, rendered with `rsvg-convert`; about 12 s, most of it picture 12 running the models). Picture 12 (the cheat test,
  two small multiples of bars as the altar's) is computed from the models each time.
- **The models:** `docs/design/games/fraction-bakery/model/`: `bakery_rules.py` (the bench, the Fair Knife, the order forms,
  the Fair Line judge, the cut budget, the fewest-cut search, and the players), and three runs, each
  `/usr/bin/python3 -I <file> 1000 [--draft]`: `opening_night_model.py` (the phase B slice, about 4 s), `midnight_model.py`
  (the transfer room, about 7 s), `ladder_model.py` (eight later rooms, about 2 s). They load `bakery_rules.py` by its path,
  so they run with `-I` and leave no `__pycache__`. `--draft` prints the first drafts the models changed.

## The headline

- **The verb:** cut it fair. The Fair Knife cuts only equal pieces into a count the child sets (2-12; in VR a twist, one
  click a piece); the count is the bottom number, the pieces given the top. Every order is then handed over on the Fair
  Line (the counter's brass rail, one whole pie from post to post): it slides piece by piece to its amount and the buddy's
  flag shows where it should stop. Tables of buddies are fractions as sharing; boxes are a/b of a whole; each rung adds its
  tool: the leftover shelf, tins (common denominators), the cupcake tray, loaves along the rail, the Size Oven (scaling),
  scoops (division), the Hundred Tray (decimals and percents), the recipe book (ratios).
- **The cheat test, measured** (1,000 visits per player, Opening Night's eight judged orders, the bar 7 of 8): knows what a
  fraction is 100 %; slips on 4 % of decisions 88.0 %; whole-number bias 100 % (nothing compares two amounts there:
  Midnight is where it fails); cuts in twelfths and deals 2.6 % (it reads boxes right); always halves 0 %; one piece each
  0 %; turns n/p round 0 %; random 0 %; trial and error with our knife 0 %; trial and error with an undo (not built) 100 %.
- **The transfer test, measured** (Midnight Leftovers, 1,000 visits, the bar 5 of 6): the idea 100 % (slips 97.6 %);
  Opening Night's habit 0 %; whole-number bias 0 %; random 0 %; greedy-by-size and halving pass (both know sizes); the habit
  with a fresh pie (not built) fills every box order. The later rooms (the ladder model): each named misconception 0 %
  (the tins' "bigger bottom number" habit 0.8 %), the idea 100 %.
- **The ladder:** rung 3 The Pie Shop, rung 4 The Cake Kitchen, rung 5 The Big Oven, rung 6 The Recipe Book; the fade:
  pictures, pictures and numerals, numerals, symbols.
- **Sixteen units** become P1 when their rooms ship: `g3.maths.unit_fractions`, `fractions_number_line`,
  `equivalent_fractions`; `g4.maths.equal_fractions`, `add_fractions`, `fraction_times`, `decimals`;
  `g5.maths.unlike_fractions`, `fractions_as_division`, `multiply_fractions`, `scaling`, `divide_unit_fractions`,
  `percent_intro`; `g6.maths.divide_fractions`, `ratios`, `percent` (195 hand-written exercises, 77 of them reading debt).
- **Phase B:** Opening Night and Midnight Leftovers, flat and VR: 6 agent sessions (5 if the leaf's B2 registry hook has
  merged and the altar's B has proved the host pattern; 5-8 with surprises).

## What the models changed in the design

1. **Opening Night's tables and boxes.** The first draft used grade 3's own denominators (2, 3, 4, 6, 8) and tables of 2-6:
   a child who cuts every pie into twelfths and deals round-robin fed every table fairly and reached the bar on **100 %**
   of visits; a child who only halves on **12.3 %**. The night now seats tables of 5 and 8 (an odd number of pies at 8) and
   puts thirds, fifths and sixths in three boxes: **2.6 %** and **0 %** (ruling 9; open question 5 asks the lead about
   fifths in grade 3).
2. **Cuts are final, with no preview** (rulings 3, 4): with an undo, trial and error ends right every time (100 %); with the
   cut final, 0 %.
3. **The oven sleeps at midnight** (ruling 11): with one fresh pie per order, Opening Night's habit fills every box order.
4. **The slip model was corrected**, not the design: my first version counted a misdeal per pair of pieces, which dropped
   the slip player to 56 %; in the design pieces on the plates are in plain sight and moving them before the bell is free
   (ruling 6), so slips are the knife's click and an unnoticed count: 88 %.
5. **The Baguette Counter**: boxes drawn anywhere in (0, 2] let "a fraction is less than one" reach 11.7 %: four of six now
   go past post one (ruling 28).
6. **The Queue**: four random cards let "order by the top number" reach 2.9 %, and adding a same-top pair alone *raised* it
   to 12.5 % (that player happens to order same-top pairs right); every queue now holds a same-top pair and a small top
   worth more (1/2 against 3/8): 0 % (ruling 27).
7. **The Size Oven**: one cake an order let "multiplying always makes bigger" reach 29.4 % and "a fraction always shrinks"
   37.5 %: three cakes now go in at once, one shrinking and one growing: 0 % (ruling 26).
8. **The Hundred Tray**: decimal queues without a trap let "shorter is larger" reach 2.7 %: every queue now holds 0.4,
   0.405 and 0.45: 0 % (ruling 27).

## How the research was done (and what is uncertain)

Web reading (WebSearch and WebFetch); nothing was downloaded on purpose and nothing outside the docs was saved. **The fetch
tool saved one PDF by itself** (Siegler, Thompson & Schneider 2011, whose text it could not read); it was deleted at once,
unread. Most figures come from abstracts, publishers' pages, PubMed Central (Siegler & Pyke 2013 was read in full there),
the IES practice guide's page, a National Academies chapter (Moss 2005) and clearinghouse summaries; where a figure is
second-hand the source list says "as reported". Honest flags:
- **Self-reported or commissioned:** Slice Fractions' "+10.5 %" (the developer); Motion Math's +15 % (commissioned and
  co-funded by the maker, run by an independent researcher); Fraction Face-Off's trials (run by the developers; Blueprints
  says so); ST Math's positive report (the developer's) against the randomized trial's negligible effect.
- **Not fully verified:** the 0.64 effect for Fraction Face-Off's five-trial review (the summary page does not say which
  trial it covers); the NAEP 12/13 + 7/8 percentages (24 %, 28 %, 27 %: from Post 1981 as reproduced by the Lesson Study
  Alliance; sources disagree on the assessment's year); Siegler & Lortie-Forgues 2015 (design read, its percentages not,
  so none are quoted); Moss & Case 1999's results (the sample from the abstract, the outcome sentence from Moss's later
  chapter); Schneider et al.'s fractions-versus-whole-numbers split (as reported by a later paper); Pothier & Sawada's
  halving (as cited, the paper itself not read); the Fraction Ball journal's name (a 2022 APA record and an AERA abstract).
- **No figure found:** the prevalence of the swapped division (8 ÷ 3 = 3/8) and of the forgotten whole; both are in the
  table with "no prevalence figure found".
- The strand's counts were computed from the units' own files (`data/school/g3..g6/maths/*.json`, `gradeN.json`); the
  generators' denominators from `core/school/gen/g3_fractions_gen.gd` … `g5_fractions_gen.gd`.

**The voice lines** were checked by a script (`/usr/bin/python3 -I check_lines.py docs/design/games/fraction-bakery.md`,
kept in the session scratchpad, not the repo): 50 lines, the longest 12 words; the only questions are spoken ones answered
by picture buttons (H23, G1, G2), the pattern the altar's review accepted.

## What the lead should check

1. The design's open questions (§8): Midnight's events (NEW_SETTING for `unit_fractions`, or a first round for
   `equivalent_fractions`); the registry hook for a deep game with its own host; ratios (the bakery's recipes vs Ratio
   Kitchen); decimals (names here, algorithms in Market Change and Frog Jump); fifths in the grade 3 prologue; where the
   bakery stands in phase C; the Maths door's choice for grades 5-6; the child's own buddies as customers; when phase B
   starts; the food; the baker's journal on the grown-ups' page.
2. Show the owner `fraction-bakery-owner.md`.
3. Phase B's brief from §4 (6 agent sessions; one agent, three briefs of two sessions with the lead's checks between).

## Rulings of this run (the design's §7 has all 38 with their costs)

The most consequential: the cut is the core verb (1); every order is judged on the Fair Line (2); no preview and every cut
final (3, 4); the Fair Line moves only at the hand-over (5); any fair split counts (8); Opening Night's tables of 5 and 8
and its boxes never in halves (9); the oven sleeps at midnight (11); Midnight's events are NEW_SETTING for
`unit_fractions` (12); Hoot speaks every order at every stage (15); no money in the bakery (18); never timed, no opening
hours (20); the Maths door opens the game of the child's current unit (23); the Size Oven bakes three cakes at once (26);
the queues' traps (27); ratios stop at recipes, decimals are names (30, 31).
