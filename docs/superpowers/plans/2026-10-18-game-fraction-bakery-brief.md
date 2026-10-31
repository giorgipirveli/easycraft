# Fraction Bakery — phase A (research and design) — the agent brief (owner #133, #134)

The owner (2026-10-17): "noone will start reading and learning the lessons when playing game, so each game needs a lot
time power and thinking to create and implement … we need future lessons, not just texts with visuals like slides".
**Read `docs/design/future-lessons.md` first: it is the authority** (the five tests: choice, mute, cheat, transfer,
wow; the four gated phases). This is the third wave-1 game, one game, in depth; this run is **phase A only: research
and design, no game code**. Two phase A's have passed the lead's review and are the model of what a good one looks like:
`docs/design/games/leaf-voyage.md` and `docs/design/games/balance-altar.md` (each with the lead's review at its end),
their owner pages (`*-owner.md`), their pictures and their small simulation models (`model/`: the cheat and transfer
tests run as numbers before a line of game code; Balance Altar's models changed its design three times, which is the
point of them). Work autonomously; do not ask questions (decide, and write each ruling down with its cost).

## The game (the seed, `future-lessons.md` §5)
Fractions, grades 3-6: the topic children fail most. A bakery where the buddies order shares. A knife that cuts only
equal pieces (the denominator is the cut); slices that fit a tin only when they are the same size (common denominators
as the move); a crowd fed fairly (fractions as division). Grow it into the game: what the child bakes, who orders, what
the tins, trays, scales and ovens do, and where the ladder goes (equivalence, comparing, the number line, adding with
unlike pieces, a fraction of a number, multiplying and dividing fractions, decimals and percents as other names for the
same share, ratios as recipes).

## What to produce (`docs/design/games/fraction-bakery.md`, plus pictures)
1. **Research** (cite each source; reading the web is fine, nothing downloaded, and if a fetch saves a file by itself,
   delete it and say so): what children of 8-12 get wrong about fractions (whole-number bias: 1/8 > 1/4 because 8 > 4;
   adding tops and bottoms; "equal pieces" ignored; a fraction as two numbers, not one number on the line; the
   magnitude of a fraction; division making smaller) and what fixes them (Siegler's integrated theory and the number
   line; the measurement view; equal sharing as the entry, Empson; the evidence on area models, bars and number lines);
   the best existing games and apps for fractions and what the evidence says and does not say (e.g. Slice Fractions,
   Motion Math, DragonBox Numbers' cousins, Refraction, the Fraction Face-Off intervention: name what is self-reported);
   the curriculum strand from our units (`data/school/g3..g6/maths/*`: `unit_fractions`, `equivalent_fractions`,
   `fractions_number_line`, `add_fractions`, `equal_fractions`, `fraction_times`, `decimals`, `unlike_fractions`,
   `fractions_as_division`, `multiply_fractions`, `divide_unit_fractions`, `decimal_*`, `percent_intro`,
   `divide_fractions`, `percent`, `ratios`, `convert_ratios`) with each unit's standards.
2. **The design document**, concretely (as the leaf's and the altar's): the fantasy and purpose; the core loop; **the
   verb that is the concept** for each idea; **the five tests** answered, with **small simulation models** that show
   guessing cannot win (random cuts, the whole-number-bias player who picks the bigger denominator, the add-tops-and-
   bottoms player, the always-halve player, greedy moves) and the rule does, and a transfer test in a new setting; **the
   ladder** grades 3-6 (from pictures to numerals to symbols; levels, transfer levels); **minute 1, 5 and 30**, flat and
   VR; **show, say, do** with every voice line (≤ 12 words, never a question that needs reading; reading the numerals is
   part of the skill at the top of the ladder, so say how the voice supports it); **what the game records** through G0's
   `SkillShown`; **the look** (the bakery, the knife, the tins, the buddies who order, the shop at night: sketched as
   pictures you make); **the tech plan for phase B** (on G0's foundation: a host of its own through the registry hook
   that Inside a Leaf's phase B2 builds, `PlayVoice`, the demonstrations, `SkillShown`; DISCOVER and W1's Academy maths
   door, `AcademyPlaza.opens()`; where it lives in the world; VR: cutting and carrying with the hands); risks and
   rulings; an honesty table (what is real maths, what is simplified).
3. **A one-page plain-words summary for the owner** (`docs/design/games/fraction-bakery-owner.md`) with three pictures.

## Rules
- Read also: `docs/design/learning-is-play.md`, spec §22.0, G0's notes (`docs/devlog/parts/play-g0.md`) and
  DEVELOPMENT.md's "The foundation's API, for the game agents", W1's notes (`docs/devlog/parts/play-w1.md`), Balance
  Altar's notes (`docs/devlog/parts/game-altar-a.md`). Balance Altar and Fraction Bakery both sit behind the Academy's
  maths door: say how a child of each grade finds the right one.
- Write only under `docs/design/games/` and your notes `docs/devlog/parts/game-bakery-a.md`. Never open the editor or
  an emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents; no Godot runs (no
  suites: this phase has no game code). Python for the models (`/usr/bin/python3`, the standard library and what is
  installed). Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. The owner is "they".
- Report: branch, commits, the design's headline (the verb, the five tests with the models' numbers, the ladder), what
  the models changed in the design, the open questions the lead must decide, and phase B's estimate in agent sessions.
