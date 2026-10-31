# Balance Altar, phase A (research and design) (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-18-game-balance-altar-brief.md`; the authority: `docs/design/future-lessons.md`
(the five tests, the four gated phases); the model of a good phase A: the leaf's (`docs/design/games/leaf-voyage.md` and
the lead's review at its end). Phase A only: research and the design, no game code. Done on 2026-10-18 by the game agent
on the worktree branch `worktree-agent-aeae51b3190e2f578`, cut from lead-merge at `bf953098` (the brief). No editor, no
emulator, no adb, no agents.

## What was delivered

- **The design:** `docs/design/games/balance-altar.md`: the research (what children of 10-14 get wrong in early algebra
  and what fixes it, with the numbers; the evidence for the balance model, concreteness fading, manipulatives, worked
  examples, gesture and perceptual learning; DragonBox's evidence, what it says and does not say, and 13 other games and
  apps; the curriculum strand: eleven units with their standards, ideas, exercises and generators), the fantasy, the core
  loop, the verb for every idea, the Entrance Hall and the Sky Room beat by beat with the altar's rules from the model,
  the ladder (four wings, grades 5-8, about 30 rooms with their transfer rooms, and the fade from pictures to runes),
  minute 1, 5 and 30 flat and in VR, every voice line of phase B (34 entries, 44 lines, each at most 12 words: checked by
  a script) and how the voice carries the symbols, the meanings of things, the five tests answered with the models'
  numbers, the evidence model into `SkillShown`, the look, the tech plan for phase B, phases and estimates, risks, 35
  rulings with their costs, nine open questions, an honesty table and 51 sources.
- **The owner's page:** `docs/design/games/balance-altar-owner.md` (one page, plain words, three pictures: 01, 03, 07).
- **Pictures:** `docs/design/games/balance-altar/01-…12-*.png` and their `.svg` sources, drawn by
  `docs/design/games/balance-altar/make_pictures.py` (`/usr/bin/python3 -I docs/design/games/balance-altar/make_pictures.py
  [name …]`, rendered with `rsvg-convert`; about 20 s, most of it picture 12 running the models). Picture 12 (the cheat
  test, two small multiples of bars: emphasis form, one hue for the players who know the rule, grey for the rest, one
  shared 0-100 % axis) is computed from the models each time.
- **The models:** `docs/design/games/balance-altar/model/`: `altar_rules.py` (the altar's state, the twin moves, the
  rule breaks, the shortest solution, the altar forms, the help policy, the evidence rule, and the players), and three
  runs, each `/usr/bin/python3 -I <file> 1000`: `hall_model.py` (the Entrance Hall, about 8 s), `sky_room_model.py` (the
  transfer room, about 8 s), `ladder_model.py` (crystals on both pans, breathing crystals, the leaning altar with the
  Mirror, and a search over the twin altars; about 35 s). They load `altar_rules.py` by its path, so they run with `-I`
  and leave no `__pycache__`.

## The headline

- **The verb:** keep the balance: take the same off both pans, put the same on both, share both into equal shares. The
  altar takes a move only when it is done to both pans; anything else rattles its chains and springs back. Free the
  crystal (alone on its pan) and the other pan shows its weight: solving an equation by equivalent transformations. Each
  wing adds its tool: balloons (negatives, the zero pair), recipe boxes (the distributive law), the breathing crystal (a
  variable; equivalence), the Mirror (negation; the inequality's flip), the swap seal and stacking (systems), crystal
  tiles (expanding and factorising).
- **The cheat test, measured** (1,000 visits per player, the hall's eight judged altars, the bar 7 of 8 as
  MasteryRules counts it): the rule 100 %; the rule with a 4 % slip rate 95.3 %; keeping the balance with no plan 0.2 %;
  guessing which move 0 %; "always take away" 0 %; "divide by the number" 0 %; random moves, random taps, one pan only,
  carrying across, weighing with the chained beam 0 %; weighing with a free-swinging beam (not built) 100 %.
- **The transfer test, measured** (the Sky Room, 1,000 visits, the bar 5 of 6): the rule 100 %; the hall's habit 0 % (it
  frees the two familiar altars, none of the four with balloons); guessing 0.2 %; everything else 0 %. The later wings
  (the ladder model): crystals on both pans, unwinding 0 % vs the rule 100 %; breathing crystals, the distributive slip,
  conjoining and one-size matching 0 % vs 100 %; the leaning altar, the equation habit and the forgotten flip 0 % vs
  100 %; twin altars: no fair move on one altar alone ever frees a crystal (1,576 states searched to depth 7).
- **The ladder:** wing 5 The Recipe Kitchen, wing 6 The Hall of Frozen Crystals (with the Sky Room), wing 7 The Mirror
  Halls, wing 8 The Twin Altars and the Star Floor; the fade: pictures, numbers, letters, runes alone.
- **Eleven units** become P1 when their wings ship: `g5.maths.expressions`, `g6.maths.exponents_expressions`,
  `g6.maths.equivalent_expressions`, `g6.maths.equations`, `g6.maths.variables`, `g7.maths.expressions`,
  `g7.maths.equations`, `g7.maths.inequalities`, `g8.maths.linear_equations`, `g8.maths.systems`,
  `g8.maths.expand_factorise` (124 hand-written exercises).
- **Phase B:** the Entrance Hall and the Sky Room, flat and VR: 6 agent sessions (5 if the leaf's B2 registry hook has
  merged; 5-8 with surprises).

## What the models changed in the design

1. **The beam is chained.** A free-swinging beam lets a child find the crystal by weighing it (lift things off until it
   looks level): the weighing player won 100 % of visits. With the frozen crystal's chains holding the beam level (a
   refused move rattles, the beam never shows which pan is heavier) it wins 0 % (ruling 3).
2. **The move budget.** With "one move more than the shortest" on every altar, the no-plan player freed about half the
   one-move altars (detours like "add two gems, then take five" fitted) and reached the bar in 2 % of visits; with "a
   one-move altar in one move" it frees about a third and reaches the bar in 0.2 % (ruling 5).
3. **The Sky Room's Great Altar.** With six one-step altars the guesser reached the transfer bar in 1.0 % of visits; a
   two-step balloon altar at the room's end (mirroring the hall) brought it to 0.2 %.
4. **No preview for the bowls** (ruling 6): a free preview would let trying every bowl count solve the share altars.
5. A correction while drawing picture 11: the leaning altar's tilts were first drawn the wrong way round (−2x > 6 means the
   left pan is the heavier one until the Mirror flips it), and the breathing rows' differences were recomputed
   (3(x + 4) against 7 crystals is 12 − 4x: level at size 3 only, a nice "one solution" case now named in the picture).

## How the research was done

Web reading (WebSearch and WebFetch). The fetch tool cached two papers' PDFs by itself (Knuth et al. 2006 and Küchemann
1978); they were read for their figures (the grade-by-grade equal-sign and strategy numbers; the CSMS item rates) and
then deleted; nothing downloaded is kept, and nothing was saved in the repo. The strongest sources: Knuth, Stephens,
McNeil & Alibali 2006 (177 students: relational definitions 32/43/31 % in grades 6-8; none of 47 sixth graders used the
algebraic method; relational understanding predicts equation solving controlling for ability), Küchemann 1978 (3,000
13-15-year-olds: 2n or n + 2 6 %, n + 20 for 4(n + 5) 31 %, 8 cabbages and 6 turnips 52 %), Vlassis 2001-2002 (the
balance helps with the unknown on both sides, breaks with negatives), Herscovics & Linchevski 1994 and Filloy & Rojano
1989 (the cognitive gap), Otten et al. 2019 (the balance model review, and 65 fifth graders with a hanging mobile), Fyfe
et al. 2014 and Kaminski et al. 2008 (concreteness fading; abstract symbols transfer), Cook, Mitchell & Goldin-Meadow 2008
(the two-hand equalizer gesture: 85 % of gains kept against 33 %), and on DragonBox the Washington challenge's
self-reported 92.9 %, Long & Aleven 2017 (190 students: more problems and more fun with DragonBox, more learning on paper
with the tutor), Decker-Woodrow et al. 2023 (3,600 seventh graders: DragonBox 12+ and From Here to There beat the active
control) and Bernier et al. 2026 (play alone may not build the knowledge). The Common Core pages gave the standards'
wording; the units' own files gave their ideas, exercises and generators.

## What the lead should check

1. The design's open questions (§8): the registry hook for a deep game with its own host (the leaf's B2 builds it; wait
   or do it now); SkillShown's kind for "freed, but not the first time" (HELPED with a note, or a fifth kind); P1 in phase
   C; where the temple stands in the world; the fade's adaptivity; the Great Altar's two-step counted for the one-step
   unit; when phase B starts; the Glimmers outside the temple; the keeper's journal on the grown-ups' page.
2. Show the owner `balance-altar-owner.md`.
3. Phase B's brief from §4 (6 agent sessions; one agent, three briefs of two sessions with the lead's checks between).

## Rulings of this run (the design's §7 has all 35 with their costs)

The most consequential: the twin move is the core verb (1); a move is a batch that waits for its twin (2); the frozen
crystal's chains hold the beam level so it cannot be weighed (3); a one-move altar in one move (5); no preview for the
bowls (6); negatives are balloons (8); the crystal is never "c", its rune becomes x late (10); the fade moves with play
(11); a freed altar with a refused move or over budget is HELPED (15); phase B ships the hall and the Sky Room (17);
Glimmers are freed, never caught or bought, and seen before (19); never timed, never lost (20); in VR the twin move is two
hands at once (23); the Mirror is negation (25).
