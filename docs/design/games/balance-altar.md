# Balance Altar — the design (phase A)

The second future lesson (owner #133, #134; `docs/design/future-lessons.md` §5, wave 1). This is **phase A**: the
research and the design, reviewed by the lead (and shown to the owner as `balance-altar-owner.md`) before any code. The
brief: `docs/superpowers/plans/2026-10-18-game-balance-altar-brief.md`. Pictures: `docs/design/games/balance-altar/`
(drawn by `make_pictures.py`). The models: `docs/design/games/balance-altar/model/`. Notes on how this was made:
`docs/devlog/parts/game-altar-a.md`. Written 2026-10-18 on the worktree branch `worktree-agent-aeae51b3190e2f578` (cut
from lead-merge at `bf953098`).

The owner, 2026-10-17, after watching their child play for half an hour and meet no learning: "noone will start reading
and learning the lessons when playing game … we need future lessons, not just texts with visuals like slides". Algebra
is the hardest case for that bar: it *is* symbols. So the question this design answers is not "how do we put equations
in a game" but "what would a child of 10 to 14 do with their hands, by choice, that is algebra, and that only algebra
can win".

---

## 0. In one page

**The fantasy.** Above the child's world floats the **Sky Temple**. Its light went out long ago: its crystals are frozen
on great golden balance altars, and inside each crystal a tiny crystal creature, a **Glimmer**, is asleep. The temple's
old magic, the balance spell, lets a crystal go only one way: when it stands alone on its pan and every move that got it
there was fair. The child is the temple's new Keeper. Free a crystal and its Glimmer wakes, sings one note and flies up
to light the hall's chandelier; free a hall and the Glimmers sing their tune together, the chandelier blazes and the
great door opens onto the next room. Every school year a new wing opens.

**The verb that is the concept.** *Keep the balance*: take the same off both pans, put the same on both, share both
pans into equal shares. The altar takes a move only when it is done to both pans; anything else rattles its chains and
springs back, changing nothing. Free the crystal (alone on its pan) and the other pan shows what it weighs: **that is
solving an equation by equivalent transformations**, the method most middle-school students never use (in one study of
177 students, none of the 47 sixth graders and one of 72 seventh graders did, §2.1). Each wing adds the tool its idea
needs: balloons (negatives: a gem and a balloon cancel), recipe boxes (the distributive law), a crystal that breathes
(a variable: equivalent expressions are pans that stay level at every size), the Mirror (negation: it turns gems into
balloons and flips which pan is heavier, the reason an inequality's sign turns), two crystal kinds on twin altars
(systems: the swap seal is substitution), crystal tiles (expanding and factorising as rectangles).

**The five tests** (the model's numbers: 1,000 seeded visits per player, §3.9).

| Test | This game's answer | Checked in phase B by |
|---|---|---|
| Choice | A puzzle temple to light up, room by room; creatures freed (never bought, never random) that sing; short altars (20-60 s), halls of 6 minutes; in VR both hands on two giant pans; later, an altar of your own for a friend | The owner's child: do they start the Sky Room unasked, and come back another day? |
| Mute | Nothing to read: the pans, the gems in rows of five, the chains, the glows; one short spoken line at a time; the rune line (the equation) is the only text, it changes with every move, Hoot reads it aloud and every rune says its name when touched | A test that the screen shows no words but the rune line while an altar plays; the owner's child plays with text hidden |
| Cheat | Guessing, button-mashing, working on one pan, carrying things across, weighing the crystal and half-knowledge all fail: the Entrance Hall's bar (7 of 8 altars freed fairly, with no help) is reached by **100 %** of visits that know the rule (95.3 % with a 4 % slip rate) and by **0-0.2 %** of every player without it | Bots in the tests (the model's players, thresholds as tests) |
| Transfer | Every wing has rooms where the old habit fails and the rule wins. Phase B ships **the Sky Room**: balloons beside the crystal; the hall's habit ("take it away") frees **0 %** of them, the rule ("the same on both pans; a gem undoes a balloon") **100 %**. Later: crystals on both pans (the step where arithmetic habits break: the habit 0 %, the rule 100 %), the fog altar (the symbols alone), a market scale, hanging mobiles, the rocket's scale | Phase B: the habit bot never wins the Sky Room, the rule bot always; a child solves it unhelped |
| Wow | The temple at sunset; the first crystal cracking open and its Glimmer yawning awake; the chandelier filling with light; the Great Altar's chorus and the door; in VR, lifting a gem off each giant pan with your two hands | The owner's verdict; whether the child shows it to someone |

**The ladder (grades 5-8)**: wing 5 *The Recipe Kitchen* (recipe boxes: brackets and order as structure), wing 6
*The Hall of Frozen Crystals* (take, share, balloons, the leaning altar, breathing crystals, the rule altar), wing 7
*The Mirror Halls* (two moves, negatives, the Mirror, inequalities, expanding and factorising with balloons), wing 8
*The Twin Altars and the Star Floor* (crystals on both pans; one, none or infinitely many; systems; crystal tiles).
The same altar fades from pictures (count the gems) to numbers to letters to runes alone (concreteness fading). It
covers the strand's eleven units (§2.4) and makes each P1 when its wing ships.

**Minute 1:** a floating temple, Hoot's welcome, a frozen crystal with a creature asleep inside; the ghost lifts a gem off
each pan; your turn. **Minute 5:** the hall nearly lit; three crystals shared into three bowls; the Great Altar rising.
**Minute 30:** the Entrance Hall lit, the Sky Room's balloons solved (the hall's habit failed there and the rule won),
the leaning altar's see-saw, and the first breathing crystal.

**Phase B** (the vertical slice): the Entrance Hall and the Sky Room, flat and VR, complete and beautiful. Estimate:
**6 agent sessions** (5 if the leaf's phase B2 has landed the registry hook for deep games, §4.7). The open questions for
the lead are in §8.

---

## 1. The bar this game must clear

From `future-lessons.md` §2 (the authority): a future lesson is a game a child chooses to play, where the knowledge is
the only way to win, nothing has to be read, and the game knows what the child learned from how they play. Five tests
(choice, mute, cheat, transfer, wow), four gated phases. From `learning-is-play.md` §3: the concept is the mechanic,
play first and words after, the world answers, shown when stuck, short and again, in the world and for the world, words
as tools. Rule 0 (owner #133): a child never has to read. EasyCraft's own rules apply too: calm, kind, never scary, no
gambling, no pressure tricks (no FOMO, no streaks, no character made sad to make a child play), English only, nothing
personal kept or sent, flat and VR, the phones' budget.

One thing is special about algebra: **its symbols are the subject**. A future lesson cannot leave them out (the child
must end able to solve 3x + 5 = 20 on paper and in the School's Book), and it cannot start with them (a page of symbols
is exactly the reading wall #133 forbids). The design's answer is the fade (§3.6, picture 10): the symbols grow out of
the play, read aloud, until the child plays with the symbols themselves.

---

## 2. Research

### 2.1 What children of 10-14 get wrong in early algebra, and what fixes it

| What children think or do | Who, how often | Why it sticks | What fixes it (the research) | How this game fixes it |
|---|---|---|---|---|
| **The equals sign means "the answer comes next"** (operational): 8 + 4 = □ + 5 answered 12 or 17 | Grades 1-6 [A3]; in middle school only **32 %** (grade 6), **43 %** (7), **31 %** (8) of 177 students define "=" as "the same as" [A1]; "There is no equal sign with a number after it" (a 12-13-year-old) [A1, quoting A2] | Years of a + b = □: the sign always announces a result | A relational view predicts solving 4m + 10 = 70 **even controlling for mathematics ability**; 8th graders with it used the algebraic method far more often [A1][A4]; non-standard forms (things on both sides) and the balance [A3][B1] | **The altar is the equals sign**: its beam rests on a crown of two gold bars (picture 02). From the first altar there are things on *both* pans; the crystal stands on the right as often as on the left; open equations (gems on both pans, 8 + 4 = x + 5) are ordinary altars |
| **Only arithmetic undoing ("unwind") and guess-and-test, never the same to both sides** | Grade 6: **0 %** used the algebraic method on 4m + 10 = 70, 51 % gave an answer only; grade 7: 1 %; grade 8: 33 % [A1] | Unwinding works for one-sided equations, so nothing pushes a child past it | The algebraic method grows from understanding equality [A1]; the balance model is used for exactly this "do the same to both sides" [B1][B2] | **The only verb is the twin move**: the same off both pans, on both, shared out of both. The altar refuses anything else |
| **The cognitive gap: the unknown on both sides** (the didactic cut) | 7th graders before instruction could not operate on the unknown spontaneously [A5]; equations like ax + b = cx + d mark the cut from arithmetic to algebra [A6] | Unwinding (and arithmetic) has no move for "take x from both sides" | The balance model supports this step in particular [B2] | **Crystals on both pans** (wing 8, and phase C's transfer): take a crystal off both. The model: the unwinding habit frees **0 %**, the rule **100 %** (§3.9) |
| **Negatives and the minus sign**: x − 3, −2x, flipping | 13-14-year-olds' difficulties come **less from the unknown on both sides than from negatives** (a cut of its own) [A7]; the balance has no negative weights [B2] | A pan cannot hold "minus three" | Extend the model: negatives as things that pull up (balloons in the Algebra Balance app [G9]; helium in the hot-air-balloon integer model [G10]); zero pairs | **Balloons** (a balloon pulls its pan up; a gem and a balloon cancel and float off together), **crystal balloons** (−x), **floaty crystals** (a negative answer), **the Mirror** (× −1). Introduced in the Sky Room (grade 6) as the transfer test |
| **Letters as labels or objects** ("fruit-salad algebra"): 8c + 6t read as "8 cabbages and 6 turnips" | 3,000 English 13-15-year-olds (the figures here are the 14-year-olds'): **52 %** read 8c + 6t as 8 cabbages and 6 turnips; blue and red pencils (5b + 6r = 90) **11 %** right, 17 % wrote b + r = 90 [A8]; students and professors: 37 % of engineering freshmen wrong, 68 % of them reversing it (6S = P) [A9]; most students up to 15 can't read letters as numbers [A10] | Letters are taught as initials; algebra then looks like shorthand | Letters stand for numbers, not things [A8][A10]; never "a for apples" | **A crystal is a weight, not a name**: we never write "c for crystal". Its rune becomes *x* only when the child has freed dozens of crystals (picture 10), and Hoot says "x" as a number ("the crystal weighs x gems") |
| **A letter as one hidden number, never a varying one** | "Which is larger, 2n or n + 2?": **6 %** right at 14 (71 % said 2n) [A8]; "f = 3g + 1: what happens to f if g grows by 2?" 7 % vs 92 % for "g + 5 = 8" [A8] | Equations show letters frozen at one value | Let the letter vary and watch the relationship between the expressions change (Küchemann's "second-order relationship") [A8] | **The breathing crystal** (wing 6): a crystal that grows and shrinks; Küchemann's 2n vs n + 2 is an altar that tips one way, levels at 2, then tips the other way |
| **Lack of closure and conjoining**: "add 4 onto 3n" gives 7n | **31 %** wrote 7n (36 % right); e + f = 8, e + f + g = ? **26 %** answered 12 [A8] | An "answer" must be one number | Accept expressions as answers [A8] | Crystals and gems never merge (a gem cannot fuse into a crystal): "3 crystals and 4 gems" is a perfectly good pan |
| **The distributive law half done**: 4(n + 5) = 4n + 5 or n + 20 | "Multiply n + 5 by 4": **17 %** right, **31 %** wrote n + 20 [A8]; distributive errors are the most common in grade 7 [A11] | The bracket's meaning (everything inside) is invisible | Area models, equal groups [A11]; test equivalence by values | **Recipe boxes**: k equal compartments, each holding the same; the breathing test (sizes 2, 5, 8) catches 4n + 5 at once (§3.9 (b)) |
| **Inequalities treated as equations; the flip forgotten or misapplied** | The most common source of errors is a false analogy between equations and inequalities [A12][A13] | A rule ("flip when you divide by a negative") with no reason | Meaning before rules: test values, number lines [A12] | **The leaning altar stays tipped** (an inequality is never level); **the Mirror flips the tip you can see**; the floor's number line lights the answer, the boundary stone dark for >, lit for ≥ |
| **"Move it across and change its sign"** used as a magic rule | Common; an app automates it (Algebra Touch: drag a term across and its sign changes; "a hit for procedural understanding, but it doesn't teach concepts") [G7] | It works, so it is never questioned | Equivalence as the reason for every step [A1][B1] | **Carrying a gem across is refused**: lifting it changes one pan, dropping it changes the other; the see-why says why |

**The progressions underneath.** Küchemann's six ways of reading a letter (evaluated, ignored, as an object, as a
specific unknown, as a generalised number, as a variable) [A8] are the ladder's spine for letters: wing 6's frozen
crystal is the *specific unknown*, its breathing crystal the *generalised number* and the *variable*, and the rune *x*
arrives only when both are familiar. Knuth's results [A1] are its spine for equality: the altar (relational equality)
comes first, the method (the same to both sides) is the only verb, unwinding is allowed to fail (crystals on both
pans).

**What we take from this:** (1) equality must be seen as a balance from the first second, with things on both sides;
(2) the only way to move must be the algebraic one, and the habits that work only for easy equations (unwinding,
guessing, "move it across") must meet altars where they fail; (3) negatives need their own physical meaning, or the
balance model breaks exactly where children struggle most [A7][B2]; (4) letters must stand for numbers, and must vary;
(5) every rule must have a visible reason (the flip, the distributive law, the zero pair).

### 2.2 What makes it stick: the evidence for the method

| Finding | Source | What we take |
|---|---|---|
| The balance model is a widely used aid for linear equations; a review of **34** studies found that its reasons (the meaning of equality; the same on both sides), forms (physical, pictorial, virtual, hanging mobiles) and situations vary, with no clear overall pattern in what works, and that it is a more intricate teaching tool than it looks | Otten, van den Heuvel-Panhuizen & Veldhuis 2019 [B1] | The balance is necessary, not sufficient: the design (what moves are allowed, how negatives work, how symbols arrive) decides whether it teaches |
| The balance helps with the unknown on both sides and hinders with negatives | Vlassis 2002 [B2], 2001 [A7] | Balloons and the Mirror extend it where it breaks |
| **65 fifth graders**, six lessons with a hanging mobile, no algebra before: they used isolation, restructuring and substitution, and applied them to linear equations in new contexts | Otten et al. 2019 [B3] | Primary-age children can do this with a physical model; mobiles as a transfer setting (wing 7) |
| Virtual and physical algebra balances both produced gains in grade 3; the virtual one linked pictures and symbols and checked itself | Suh & Moyer 2007 [B4] | Link the pans and the symbols (the rune line changes with every move) |
| **Concreteness fading**: begin concrete, then explicitly and gradually fade to the abstract; it combines the advantages of both | Fyfe, McNeil, Son & Goldstone 2014 [C1] | The fade: pictures → numerals → letters → runes alone (picture 10) |
| Generic symbols transferred better than concrete examples: **76 %** vs **44-51 %** (80 undergraduates, one artificial concept) | Kaminski, Sloutsky & Heckler 2008 [C2] | Concrete gems alone could trap the knowledge in the game: the fade is not optional |
| Manipulatives beat abstract-only teaching (55 studies, about 7,200 students): small-to-moderate effects, moderate-to-large on retention, small on transfer; it depends on guidance | Carbonneau, Marley & Selig 2013 [C3] | The ghost shows each new move once; transfer altars, not just more of the same |
| The worked-example effect was discovered in algebra; in AlgebraByExample (over 6,000 students, randomized) students who usually struggle gained 10 percentage points in conceptual knowledge; correct and incorrect worked examples are both studied as aids against misconceptions | Sweller & Cooper 1985 [C5]; Booth et al. 2013, AlgebraByExample [C6] | The ghost's demonstrations; at wing 7+ Hoot sometimes makes a wrong move on purpose and the altar refuses it (an incorrect example the child sees fail) |
| Children taught the "equalizer" strategy with a **two-hand gesture** (one hand under the left side, then the other under the right) kept **85 %** of their gains four weeks later, against **33 %** for speech alone (84 third and fourth graders) | Cook, Mitchell & Goldin-Meadow 2008 [C7] | In VR the twin move is two hands, one per pan, at the same time (§4.4) |
| Perceptual learning of algebraic transformations changes how equations are seen, most for the less proficient; notation that moves under the hand (From Here to There!) builds the same seeing | Kellman et al. 2010 [C8]; Bufford et al. 2014 [C9]; Ottmar et al. 2015 [C4] | Many short altars where the structure (what is beside the crystal) is the cue; the rune line moves in step with the pans |
| Students respond to the visual pattern of the notation more than to the rules' meaning | Kirshner & Awtry 2004 [C10] | Wrong transformations must *look* wrong: in the temple they rattle the chains and change nothing |

### 2.3 Games and apps that teach algebra: what works, what fails, and why

| Game or study | What it is | Worked? | Why | What we take |
|---|---|---|---|---|
| **DragonBox Algebra** (5+, 12+) [G1]-[G5] | Isolate a box among creature cards; cards are added to both trays; night cards cancel day cards; pictures fade into numbers and letters; up to three stars per level (isolated, few moves, simplified) | **Mixed.** Self-reported: in the Washington State Algebra Challenge (2013), 92.9 % of the 4,192 children who played at least 1.5 hours reached its in-game mastery, no control group [G2]. Independent: **190** 7th-8th graders randomized for five lessons: DragonBox players solved many more problems and enjoyed it more, but the tutor's group scored significantly higher on a paper test [G3]; the designers: "too much scaffolding" (the game prompts the twin move itself) and "it never asks players to write equations" [G4]. In a randomized trial of **3,600** 7th graders (analytic N = 1,850, nine sessions), DragonBox 12+ and From Here to There both beat an active control [G5]. A design study: play "may not surface or develop algebraic knowledge to the extent desired" without wraparound activities [G6] | The rules of the game are the rules of algebra (the best-evidenced idea in the field); the fade; delight. Weak where the game makes the move for you and never asks for symbols | The DragonBox route, with three fixes: (1) **the child chooses the move** (no prompt; the chains refuse, they don't steer); (2) **the symbols are played** (the rune line from the first altar, read aloud; fog altars at the end of each wing); (3) **transfer altars where habits fail** |
| **From Here to There! / Graspable Math** [G5][G8] | Drag and transform expressions into a target form (perceptual learning, dynamic notation) | Beat the active control in the 2023 randomized trial [G5] | The notation itself becomes a thing to handle | Wing 7-8's rune altars: the same twin moves made on the runes |
| **Algebra Touch** [G7] | Drag terms across "=" (their signs change), tap to simplify; refuses illegal moves with a buzz | "A hit for procedural understanding, but it doesn't teach concepts" | The app does the transformation; the shortcut is the interface | No move-across shortcut: carrying across is refused, and why is shown |
| **Hands-On Equations** [G11] | Pawns (x) and number cubes on a drawn balance; legal moves; white pawns for −x | Developer-reported: 111 fifth graders, 44.8 % → 85.3 %; no independent randomized study found | Physical legal moves on a balance | The crystal balloon (−x) is the white pawn's idea |
| **Algebra tiles** [G12] | x², x and 1 as tiles; products and factors as rectangles | Small quasi-experiments report gains (e.g. 120 Form Four students, Malaysia, 2025) | The area model makes the distributive law and factoring visible | Wing 8's crystal tiles (the Mosaic Floor) |
| **Algebra Balance** (Ventura) [G9] | An iPad balance: blocks positive, balloons negative | No study found | Negatives as balloons | Balloons |
| **SolveMe Mobiles** (EDC) [G13] | Hanging-mobile puzzles: shapes whose weights must balance | Research "limited": classroom observations of children writing and solving systems from a mobile | Mobiles hold several equations at once | Wing 7's transfer room (the Wind Garden) |
| **Cognitive Tutor Algebra I** [G14] | An intelligent tutor (each step judged, hints) | 147 schools, randomized: no effect in year 1, **+8 percentile points** in year 2 (high school) | Step-level feedback, practice | The evidence model judges each altar's moves; hints and the ghost |
| **DimensionM** [G15][G16] | A 3D action game with algebra missions | 437 8th graders (quasi-experiment): algebra gains, motivation kept [G15]; an earlier study of modern maths games (193 students): achievement up, motivation not [G16] | Algebra *beside* an action game | Motivation is not automatic; the concept must be the play |
| **Lure of the Labyrinth** (MIT) [G17] | Pre-algebra puzzle game inside a story | Districts that followed the intended use did better | Puzzles that are the maths; implementation matters | — |
| **Wuzzit Trouble** [G18] | Free creatures by turning gears (number sense) | 59 third graders, quasi-experiment: number-sense gains; "several constraints at once", "try, check, revise" | Puzzles with constraints, freeing creatures | The Glimmers: free a creature by the maths |
| **Zombie Division** [`learning-is-play.md` G3] | Divide to defeat skeletons | Chosen **7×** longer than the same maths as a quiz | The maths is the attack | The twin move is the play |
| **The Witness** [G19] | 650 wordless puzzles; each panel series teaches a rule with no text, then varies it | Acclaimed; players learn complex rule systems with no words | "One concept and its permutations" (the Nintendo school), epiphanies again and again | The hall's sequence teaches the twin rule and the bowls without a word; the trap altar; transfer altars as the "gotcha" panels |
| **Prisms VR** (WestEd) [G20] | Algebra 1 in VR with game elements | 514 students, 21 teachers: outperformed regular teaching (VR and game confounded) | Embodied models linked to symbols | VR is worth building, measured honestly |

**Why algebra games usually fail:** the algebra is beside the game (quizzes between levels), or the game makes the moves
for the child (and the knowledge stays in the game), or the symbols never come. **Why the good ones work:** the rules of
the game are the rules of algebra, the child chooses every move, the symbols grow out of the play, and some levels are
built so that the habit fails and only the idea wins.

### 2.4 The curriculum strand: the units this game replaces

The strand of our maths units for grades 5-8 (the Common Core standards [S1]-[S4] and the Singapore and UK references in
each unit), with each unit's goals (from `data/school/gradeN.json`) and the ideas of its cards, and which wing teaches
each idea. **P1** marks a unit the game replaces for children once phase C ships its wing; the cards stay as the Book.

| Unit | Standards | Its ideas (from the cards; exercises and generators) | Taught by | After phase C |
|---|---|---|---|---|
| `g5.maths.expressions` | 5.OA.1, 5.OA.2 | brackets first; × and ÷ before + and −; words into expressions (2 × (8 + 7)); compare without working out (3 × (18,932 + 921) is 3 times as large) (12 hand-written exercises; 18 generator levels: `g5n.brackets`, `order_of_operations`, `words_to_expression`, `bracket_place`, `compare_expression`, `expression_story`) | wing 5, the Recipe Kitchen | **P1** |
| `g6.maths.exponents_expressions` | 6.EE.1, 6.EE.2 | an exponent repeats a multiplication (3² is a square of 3 × 3); order with exponents; a letter stands for a number: 3x + 4 when x = 5; words to expressions (11; `g6a.power_value`, `evaluate`, `write_expression`) | wing 6: the Square Stones, the glass crystal | **P1** |
| `g6.maths.equivalent_expressions` | 6.EE.3, 6.EE.4 | equivalent = the same value for every number; 3(x + 4) = 3x + 12 (the area model); factoring 6x + 9 = 3(2x + 3); like terms (12; `g6a.distribute`, `like_terms`, `equivalent_tf`) | wing 6: the breathing crystals | **P1** |
| `g6.maths.equations` | 6.EE.5-8 | a solution makes it true; keep it balanced, do the same to both sides; undo + with −, × with ÷; x > 5 has many solutions, shown on a number line (11; `g6a.solve_one_step`, `inequality`) | wing 6: **the Entrance Hall and the Sky Room (phase B)**, the leaning altar | **P1** |
| `g6.maths.variables` | 6.EE.9 | amounts that change together; independent and dependent; b = 5h; a table, a graph's line; find the rule (y = 3x + 1) (11; `g6a.table_rule`) | wing 6: the rule altar | **P1** |
| `g7.maths.expressions` | 7.EE.1, 7.EE.2 | expand 3(2x − 4) = 6x − 12; collect like terms; factor out the greatest common factor; rewriting shows meaning (p + 0.2p = 1.2p) (12; `g7n.expand_simplify`) | wing 7: recipe boxes with balloons, packing, shards | **P1** |
| `g7.maths.equations` | 7.EE.3, 7.EE.4a | two moves: 3x + 5 = 20; undo in reverse order; check by putting it back; p(x + q) = r; negatives, decimals (11; `g7n.two_step`) | wing 7: two moves, boxes, crystal balloons, the Mirror, number gems | **P1** |
| `g7.maths.inequalities` | 7.EE.4b | solve like an equation; dividing by a negative flips the sign; open and filled circles (11; `g7n.solve_inequality`) | wing 7: the leaning altars and the Mirror | **P1** |
| `g8.maths.linear_equations` | 8.EE.7 | x on both sides; one, none or infinitely many solutions (8; `g8n.both_sides`) | wing 8: twin crystals, the breathing pairs | **P1** |
| `g8.maths.systems` | 8.EE.8 | two equations together; the crossing point; substitution; parallel lines never cross (8; `g8n.system`) | wing 8: twin altars, the swap seal, stacking, the Star Floor | **P1** |
| `g8.maths.expand_factorise` | SG S2, UK KS3 | (x + 3)(x + 2) as a rectangle; (a + b)² and (a + b)(a − b); factorising x² + 7x + 12; x² − 81; y = x² (17; `g8k.expand_brackets`, `factorise_quadratic`, `parabola_point`) | wing 8: the Mosaic Floor (crystal tiles) and the square crystal (a breathing x² tile whose weight leaves a U-shaped trail on the wall; x² − 9 levels at two sizes, 3 and a floaty −3) | **P1** |
| `g6.maths.negatives`, `g7.maths.integers_add`, `g7.maths.integers_multiply` | 6.NS.5-7, 7.NS.1-2 | negatives, opposites, adding and multiplying integers | used by balloons and the Mirror (review events only when mastered) | stay as they are (Frog Jump later) |
| `g6.maths.gcf_lcm` (6.NS.4's distributive factoring), `g8.maths.roots` (x² = p), `g6.maths.problem_solving_toolkit` (work backwards, guess and check) | various | — | touched (packing a box; an Expert altar for x² = 49; working backwards is unwinding) | stay as they are |

Eleven units become P1: their 124 hand-written exercises stop being what a child meets; the altars are the evidence
instead (§3.10). The altars' numbers come from the same ranges as the units' generators (`G6AlgebraGen.solve_one_step`,
`G7NumberGen.two_step`, `G8AlgebraGen.both_sides` and `system`), so what a child frees in the temple and what the Book
shows agree.

### 2.5 What the five tests need from the design (the research's verdict)

Choice comes from autonomy, competence and relatedness (`engagement-and-child-psychology.md` §1.1), from flow, curiosity
and epiphanies (The Witness's "miniature epiphanies over and over again" [G19]), from creatures to care about (Wuzzit
Trouble [G18], DragonBox's hatching dragons [G1]), and from making. Mute comes from wordless level design [G19] and a
world that answers. Cheat comes from rules that are the algebra and from refusing to do the move for the child (the
lesson of DragonBox's prompts [G4]). Transfer comes from the fade [C1][C2] and from altars where habits fail [A1][A5].
Wow must be the concept itself, never decoration (the seductive-detail rule, `learning-is-play.md` G8).

---

## 3. The game

### 3.1 The fantasy and the purpose

**You are the temple's new Keeper.** The Sky Temple floats above the child's world on a bank of clouds, white stone and
gold under a sunset sky (picture 01). Its crystals were frozen by the balance spell, an old magic that keeps each crystal
on its altar until someone frees it fairly. Inside every frozen crystal a Glimmer sleeps: a small crystal creature (a
fox, a bunny, a bird, a turtle…), blocky and glowing, its silhouette curled up behind the ice. Freeing a crystal wakes
it; it yawns, sings one note and flies up into the hall's chandelier, where its light stays. A hall whose crystals are all
free sings: every Glimmer's note together makes the hall's tune (the opening phrase of *Ode to Joy* for the first hall),
the chandelier blazes and the great door opens onto the next room.

**Why it matters to the child:** the temple grows lighter and larger because of them (their wings, their chandeliers,
their Glimmers, each one known by sight before it is freed: never a random reward); the Glimmers are theirs, and in
phase D they can follow the child into their own world as little lights (owner's call, §8). The long purpose ties into
EasyCraft's core loop (learn → gold → build a rocket → fly): every freed altar records through `SkillShown`, so stars
and the School's gold come from the temple, and wing 7's transfer room is the launch site's own scale (fuel and cargo
balanced for lift-off).

**The guide** is Professor Hoot, DISCOVER's owl, who perches on the altars' crowns. He speaks; the Glimmers only chirp.

**The tone:** a calm, beautiful puzzle temple, like Monument Valley or The Witness made friendly: soft light, Bach's
*Goldberg Aria* in the hall, the clink of gems, the creak of the beam, a chime for every fair move. Funny in small ways
(a Glimmer that yawns too long and topples off the pan; Hoot fluffing up when the chandelier lights). Never scary: no
traps, no falling, nothing breaks for good; a refused move only rattles the chains softly.

### 3.2 Where it lives

- **Phase B:** the temple is a place of its own far above the world (like Life's rooms and G0's play arena), with its own
  sky. It opens from DISCOVER (the unit `g6.maths.equations` shows the temple's picture, a balance with a crystal, on the
  maths map, and its PLAY opens the Entrance Hall), from the Discovery Academy's Maths Workshop door when the child's
  unit is in the strand (`AcademyPlaza.opens()`, W1's switch), and by a developer argument (`--altar-hall=entrance`).
- **Phase C:** the temple appears in every home world as a small floating island above the Discovery Academy, with a
  stair of clouds down to the courtyard (local to each child, like the crystals, never synced); walking up the stair
  starts the child's wing; the temple's map (each wing a room you can see lit or dark) picks a room. A discovery
  crystal (W1) can be a frozen crystal: for a child whose unit is in the strand, it opens a short visit (four altars).
- **Phase D:** the world's puzzle temples (spec §12.16: small stone temples whose vault opens to three pressure plates)
  gain a balance altar as their lock; friends visit each other's temples, and a child's own altar (§3.6, room 8.7) can be
  placed in their world for a friend to free.

### 3.3 The core loop

| Every | The child | The world answers | Example (the Entrance Hall) |
|---|---|---|---|
| **10 seconds** | one fair move with the hands: a gem off each pan, a gem from the bag onto each pan, two bowls set and sealed | at once, in sound and sight | the two gems float up with a two-note chime; the chains glow green |
| **minute** | one altar: the crystal freed | the chains snap, the Glimmer wakes and sings, the other pan's gems count themselves aloud, the rune line shows the answer | "Free! It weighs four gems!"; a fox Glimmer flies up; the chandelier's third crystal lights |
| **10 minutes** | one hall | the chandelier blazes, the Glimmers sing the hall's tune, the great door opens | the door swings open onto a cloud bridge to the Sky Room |
| **days and weeks** | the wings | a wing a grade; the temple's map lights room by room; in phase D, your own altar for a friend | next: the leaning altar, the breathing crystals, the Mirror Halls |

Picture 06. The rhythm inside a hall alternates: a new tool shown once by the ghost, three or four altars where the child
uses it, a mixed run where the child must choose which move undoes what, then the hall's Great Altar.

### 3.4 The verbs are the concepts

Every idea has the verb that *is* it, and a world that makes guessing lose.

| Idea | Verb | What the world does | Why guessing loses |
|---|---|---|---|
| An equation is a balance: both sides weigh the same | **look**: the beam rests on the equals sign; free crystals show the other pan's weight | the altar is level from the start; a freed crystal's pan is exactly the other pan's weight | — |
| Equality is kept by doing the same to both sides | **take** the same off both pans (a gem off each, a handful off each) | a lift waits (amber) for its twin on the other pan; the twin makes both float off with a chime | anything else (one pan only, a different kind, a share while waiting) rattles the chains and springs back: nothing changes, the altar's star is lost |
| Adding to both sides keeps equality too (and undoes a subtraction) | **put** the same on both pans from the gem bag (and, from the Sky Room on, balloons from the balloon pump) | a gem on one pan waits for its twin | on a one-step altar a pointless add costs the move budget; on a balloon altar it is the only way |
| Dividing both sides by the same number | **share** both pans into equal shares, keep one (the sharing bowls) | the pans sort into the bowls; one share stays, the rest float off | a share that doesn't divide evenly (3 crystals into 2 bowls) is refused; the bowls are set and sealed with no preview, so trying every count costs the star |
| Multiplying both sides (undoing a division) | **echo** both pans n times (the echo bell; wing 7) | shards (a third of a crystal) join into whole crystals | sharing a shard is refused |
| Inverse operations, undone in reverse order | **choose** which move undoes what is beside the crystal | gems beside it: take; several crystals: share; a balloon: a gem; a box: open it or share by its count | the mixed altars and the Great Altar: guessing take-or-share frees about a third of the take altars and one share altar in fifteen (§3.9) |
| A negative number; a + (−a) = 0 | **balloons**: each lifts a gem's weight; a gem and a balloon on the same pan cancel and float off together | a balloon beside the crystal is undone by a gem on both pans | "take the balloon away" finds no balloon on the other pan: stuck (the hall's habit, §3.9) |
| The unknown on both sides | **take crystals** off both pans | the crystals gather on one pan | unwinding (take the gems, share by the count) never divides the other pan's crystals: refused |
| A letter can be any number; equivalent expressions | **let the crystal breathe**: build the pan that stays level at every size | the beam is locked until the lever is pulled; then the crystal grows and shrinks through three sizes | matching one size, the distributive slip (3x + 4), conjoining (7x): the beam tips at some size |
| The distributive law; factoring | **open** a recipe box (its k compartments pour out k of everything) or **pack** loose things into one | the box's weight never changes (opening is allowed on one pan) | opening it "half" (3x + 4) is shown tipping by the breathing test |
| An inequality; its sign turns when both sides are negated | **the leaning altar** stays tipped; **the Mirror** turns every gem into a balloon and back | the tip flips under the Mirror; the floor's number line lights the solution, the boundary stone lit for ≥ and dark for > | treating it as an equation lights one stone; keeping the old direction lights the wrong side |
| Substitution; elimination; the solution of a system | **the swap seal** (swap a crystal for what a level twin altar shows it weighs); **stack** one altar onto the other | the other kind's crystals gather; both kinds freed one after the other | no move on one altar alone frees either crystal (an exhaustive search, §3.9 (d)) |
| Products and factors as rectangles | **tile** a rectangle from crystal tiles (x², x, 1) | the tiles snap only into a whole rectangle; its sides are the factors | random arrangements almost never close a rectangle |
| Reading the symbols | **the rune line**: the equation carved under the pans, changing with every move | each rune speaks when touched; Hoot reads the line | in the fog altars the pans are hidden: only someone who reads the runes can act |

### 3.5 The Entrance Hall, beat by beat (the phase B slice)

Pictures: `balance-altar/01-the-temple.png`, `02-one-altar.png`, `03-the-twin-move.png`, `04-the-hall.png`.

**The place** (the Sky Temple's first hall): a round hall of white stone under a dome with an oculus; ten altars in a
ring, each with a frozen crystal glowing pale blue, a sleeping Glimmer inside, around a round seal in the floor where the
eleventh, the Great Altar, will rise; a dark chandelier of eleven crystal sockets hanging from the dome; the great door at
the far side, closed; the child at the hall's entrance with Hoot. The active altar is always in front of the child: the
ring turns (a 1 s glide) to bring the next one; in VR the child stands still and the altar comes to them.

1. **The arrival (0:00).** A stair of clouds up to the temple at sunset; the door opens by itself for a new Keeper. Hoot:
   "Welcome to the Sky Temple! Its crystals are frozen." Inside: "A Glimmer sleeps in each crystal. Let's wake them!"
2. **Altar 1, taught (0:20): a crystal and two gems | five gems.** The ghost hands lift a gem off the left pan (it rises,
   amber; the right pan's gems glow, waiting) and one off the right (both float up with a two-note chime). Hoot: "Watch:
   the same off both pans." … "Your turn!" The child takes the second pair. Alone, the crystal cracks open; the gems on
   the other pan count themselves ("One, two, three!"); Hoot: "Free! It weighs three gems!"; the fox Glimmer yawns,
   sings and flies up: the chandelier's first light.
3. **Altar 2, taught: the trap (0:55): a crystal and three gems | seven gems.** No ghost. If the child takes from the
   crystal's pan only and then does anything else (taps the crystal, takes another kind, shares), the chains rattle,
   the gem springs back, nothing changes; Hoot: "Whoa! The altar wants fair moves." then "The same on both pans!" (play
   first, words after: the rule is met by trying). Done right: "Fair and square!"
4. **Altars 3 and 4, judged (1:20, 1:45):** x + a = b, then b = x + a (the crystal on the right). Silent; Hoot praises
   after ("Same on both pans. Perfect!").
5. **Altar 5, taught (2:10): two crystals | six gems.** The bowl rack at the altar's side glows. The ghost pulls out two
   bowls and presses the seal on the fulcrum: each pan's things sort into two bowls; one share stays, the other floats
   off. Hoot: "Share both pans fairly. Keep one share." then the see-why: "Two crystals weighed six. So one weighs three!"
6. **Altars 6-10, judged (2:40-4:20):** c x = b, then a mixed run (x + a = b, b = c x, b = x + a, c x = b) where the child
   must choose: take or share? Silent; strategy praise ("You shared it out. Clever!", "Straight to the answer!").
7. **Altar 11, judged: the Great Altar (4:50): 2x + 1 = 7.** The hall's centre opens and a great altar twice the size
   rises under the chandelier, its crystal holding the hall's biggest Glimmer. Hoot: "The Great Altar! Free its crystal
   to light the hall." Two moves: take the loose gem off both pans, then share by two. (A child who shares first is
   refused: one gem won't split; the reverse order is the idea.)
8. **The hall sings (5:30).** The last Glimmer flies up; all eleven sing their notes together (the first phrase of *Ode
   to Joy*), the chandelier blazes, light pours from the oculus; Hoot: "The hall is lit! Listen to them sing!" The see-why
   of the whole hall: "Whatever you do to one pan, do to the other." Then: "Grown-ups call this an equation. You just
   solved eleven!"
9. **The door (5:40).** The great door swings open onto a cloud bridge; beyond it, the Sky Room's balloons bob in the sky.
   Hoot: "The great door is open. The Sky Room awaits!" The end card (pictures only): the lit hall, the Glimmers, the
   unit's stars, the gold, three picture buttons (↻ again, ▶ the Sky Room, a door: back).

A child who knows the rule takes about 5-6 minutes; a slower one 7-8. Nothing is ever timed. After two refused moves on
an altar the ghost does one step (that altar counts as helped); SHOW ME (the eye) does one step any time (helped); idle
for 10 s, everything that can be touched glows for 3 s (never only the right thing: no help).

**The altar's rules for phase B** (the starting rules for `AltarState` and `AltarMoves`, from the phase A model,
`balance-altar/model/altar_rules.py`):

| Rule | Value |
|---|---|
| What a pan holds | crystals (each weighs x), gems (+1), balloons (−1; the Sky Room); net amounts: when a move commits, a gem and a balloon on one pan cancel and float off together |
| The crystal's weight | a whole number 1-8 in the hall (new every visit), at most 12-15 gems on a pan; the forms and ranges of `G6AlgebraGen.solve_one_step` (level 3's halves become half-gems in phase C) |
| A twin move | a lift (or a placement from the gem bag) waits for its twin on the other pan; more of the same on the same pan grows the batch; the batch commits when the other pan has given the same; a long press takes a handful (all of that kind), the twin long press takes the same number |
| A share | set the bowls (2-6), press the seal; legal only if every amount on both pans divides; no preview |
| A rule break | while a lift waits, any other act (another kind, the other verb, a share, tapping the crystal); carrying an item across; an uneven share. The items spring back; nothing changes. Putting a waiting item back is free |
| Freed | the crystal alone on its pan (one crystal, nothing else), nothing waiting, no crystal on the other pan |
| SOLVED (first time right) | freed with no rule break, no help, and within the move budget: a one-move altar in one move (a handful or pair by pair is one move), a longer altar with at most one move more than its shortest solution |
| Help | the ghost does the next step of a shortest solution after every second rule break; SHOW ME any time; the ghost finishes an altar the child has not freed after 40 acts (SHOWN) |
| The hall's record | 8 judged altars → 8 `SkillShown` events for `g6.maths.equations`; MasteryRules' bar: 7 of 8 |

### 3.5b The Sky Room, beat by beat (the phase B transfer room)

It opens through the great door, or from the end card. Picture `balance-altar/05-the-sky-room.png`.

1. **The hook (0:00).** A round platform floating among clouds, bright blue sky, *Spring* playing; red balloons bob on
   strings; the altars stand on cloud plinths, each with a gem bag and a balloon pump at its foot. Hoot: "The Sky Room!
   Up here, balloons pull pans up." Then the frame (teaching, not help): "Balloons pull pans up. Gems pull them down."
2. **The first balloon altar (0:15), judged: a crystal and three balloons | five gems** (x − 3 = 5). The child who
   carries the hall's habit lifts a balloon to take it off both pans: no balloon glows on the other pan; they put it back
   (free) or try something else (refused). If nothing happens for 15 s, once: "Make the crystal alone. Fair moves only."
   (it restates the goal, never the move: not help). The child puts a gem on the crystal's pan: it hangs under a balloon
   (waiting); a gem on the other pan: the twin; the gem and the balloon float off together with a soft pop. Three times,
   or a handful of three. The crystal stands alone; the other pan holds eight: "Free! It weighs eight gems!" The
   see-why, the first time: "A gem and a balloon cancel out. Pop!"
3. **Altars 2-5, judged:** x − a = b, x + a = b (familiar), b = x − a (the crystal on the right), c x = b (familiar).
4. **Altar 6, judged: the Sky Room's Great Altar: 2x − 2 = 6** (put two gems on both pans, then share by two).
5. **The end (about 4:00).** The Sky Room's Glimmers (sky birds) fly up and the clouds part: far across the sky, the
   Mirror Halls glint (next year's wing). The rule in words, after the child has used it: "To undo a balloon, add a gem to
   both pans." End card; "You found the Sky Room's secret, like a real Keeper!"

**Its six altars** are `SkillShown.NEW_SETTING` events for `g6.maths.equations` when freed with no rule break, no help,
within the budget (HELPED or SHOWN otherwise): a full round, its transfer kept apart. The model of this room
(`balance-altar/model/sky_room_model.py`): the hall's habit frees the two familiar altars and none of the four balloon
altars (**0 %** of visits reach 5 of 6); the rule frees all six (**100 %**).

### 3.6 The ladder across grades 5-8

Each wing is a part of the temple, its tools and its rooms (each room a short run of altars, 4-8 minutes). The grade
(DISCOVER's) picks the child's wing after the prologue (the Entrance Hall, everyone's first room); every wing stays open
to everyone. Inside a wing the rooms open one after another; transfer rooms (T) come after their idea. Picture
`balance-altar/07-the-ladder.png`; the later wings: `11-later-wings.png`.

**Two more kinds of altar** join the frozen crystal's (whose crystal is freed by twin moves):
- **The weighing altar** (a pan to fill): the beam is locked until the child pulls the altar's lever; then it is released
  once and tips truly, level or not (G0's Make it rule: never while building, so it cannot be used to search). First
  time level is first time right.
- **The breathing altar**: its crystal grows and shrinks (a variable). After the lever, the crystal breathes through
  three sizes; the altar must stay level at every one.

**Wing 5, The Recipe Kitchen** (grade 5). Unit: `g5.maths.expressions`. The temple's kitchen, where the Glimmers' gem
recipes are kept in **recipe boxes**: wooden boxes of k equal compartments (whatever is in one compartment is in all),
which can nest. Weighing altars.
- *5.1 Weigh the Box:* a ×2 box of [3 gems + 5 gems] on the left: fill the right pan, pull the lever. Then a loose 3
  beside a ×2 box of [5]: 13, not 16. See why: "What's in one compartment is in all of them."
- *5.2 Boxes from the Runes:* the rune line says 3 + 5 × 2, or (3 + 5) × 2; build the boxes that match (choose the
  compartments, fill them) and pull the lever against the altar's hidden pan. See why: "Times holds tighter than plus.
  Brackets hold tightest."
- *5.3 Pack a Recipe:* a picture on the wall (three baskets of four apples, two more apples: no words); pack the recipe
  that weighs the same (a ×3 box of 4, two loose): writing an expression.
- *5.4 The Giant Box:* a ×3 box of [18,932 + 921] in number gems against copies of the pile [18,932 + 921]: how many
  copies balance it? (three, without working anything out).
- *5.T1 The Market Scale* (Life Town's Market Square): a buddy's order as a recipe on a fruit scale.
- Harder: counted gems → number gems; one box → nested boxes; then the runes alone.

**Wing 6, The Hall of Frozen Crystals** (grade 6). Units: `g6.maths.equations`, `g6.maths.equivalent_expressions`,
`g6.maths.exponents_expressions`, `g6.maths.variables`.
- *6.1 The Entrance Hall* (phase B, §3.5): take and share (6.EE.5-7).
- *6.T1 The Sky Room* (phase B, §3.5b): balloons, the zero pair.
- *6.2 The Leaning Altar* (6.EE.8): a see-saw altar that stays tipped; "this crystal is heavier than five gems": the
  crystal breathes and the floor's number line lights every size where the beam tips the crystal's way; the child lights
  the solution (walks to the boundary stone and picks the side; the stone lit only when level counts, "at least"). From
  a situation: a boat-pan that sinks past six Glimmers (at most six).
- *6.3 The Breathing Crystals* (6.EE.3-4): build the pan that stays level at every size: recipe boxes ↔ loose things
  (3 × [crystal + 4] and 3 crystals + 12 gems), like terms (crystal + crystal + crystal), and Küchemann's question as an
  altar: 2 crystals against 1 crystal + 2 gems tips one way, levels at size 2, then tips the other way ("It depends on
  the size!").
- *6.4 The Square Stones* (6.EE.1-2): powers as squares and cubes of gems (3² a 3 × 3 square stone, 2³ a cube); a glass
  crystal whose weight is shown (x = 5) inside a recipe: weigh 3x + 4 (a letter stands for a number).
- *6.5 The Rule Altar* (6.EE.9): the crystal breathes 1, 2, 3 and the gems that balance it at each size are shown (a
  table fills the wall; the points on the floor line up); set the recipe box's two dials (× and +) so the altar stays
  level at new sizes (5, 8): the rule y = 2x + 1.
- *6.T2 The Fog Altar:* the pans in mist; only the rune line (the crystal icon and numerals) to act on.
- *6.T3 Open Equations:* gems on both pans and the crystal on the right (8 + 4 = x + 5), the equals sign's own test.
- Harder: voiced to silent; counted gems → number gems; one move → the mixed run → two moves.

**Wing 7, The Mirror Halls** (grade 7). Units: `g7.maths.equations`, `g7.maths.expressions`, `g7.maths.inequalities`
(reviews for `g7.maths.integers_add`, `g7.maths.integers_multiply`).
- *7.1 Two Moves* (7.EE.4a): px + q = r with gems and balloons; a negative answer is a **floaty crystal** (freed, it
  drifts up; the other pan holds balloons).
- *7.2 Number Gems:* gems carry their numbers, half-gems and decimal gems; the **echo bell** copies both pans (x ÷ 3 +
  2 = 7: one shard of a crystal broken in three; echo ×3 and the shards join).
- *7.3 Boxes with Balloons* (7.EE.1-2): open 3 × [crystal + 4 balloons]; pack the biggest box (8x + 12 = 4 × [2x + 3]);
  a crystal and a fifth-shard is 1.2 crystals (p + 0.2p = 1.2p).
- *7.4 The Mirror:* crystal balloons (−x): −3x + 4 = 19: take four gems off both; the Mirror turns every gem into a
  balloon and every crystal balloon into a crystal: 3x = −15; share: a floaty crystal, −5.
- *7.5 The Leaning Altars* (7.EE.4b): px + q > r; the Mirror flips the tip (picture 11, middle); light the floor's line.
- *7.T1 The Wind Garden:* hanging mobiles (several beams in one mobile; two crystal kinds at the deepest arm, a preview
  of wing 8).
- *7.T2 The Rocket Scale* (the launch site): cargo against fuel cells: how many cells lift it? (EasyCraft's rocket loop).
- *7.T3 The Fog Altars:* standard notation, the runes alone.
- Expert: Hoot makes a wrong move on purpose (he carries a gem across) and the child stops him (an incorrect example;
  the protégé effect).

**Wing 8, The Twin Altars and the Star Floor** (grade 8). Units: `g8.maths.linear_equations`, `g8.maths.systems`,
`g8.maths.expand_factorise` (a review for `g8.maths.roots`).
- *8.1 Twin Crystals* (8.EE.7b): crystals on both pans; with boxes (2(x − 3) = 5x + 9).
- *8.2 One, None or Many* (8.EE.7a): a breathing altar with crystals on both pans: level at one size (one solution),
  never level (none: take the crystals off both and 1 gem faces 5), level at every size (infinitely many).
- *8.3 The Twin Altars* (8.EE.8b-c): two crystal kinds (blue and rose) on two altars; the **swap seal** (a crystal may
  be swapped for what a level twin altar shows it weighs: substitution) and **stacking** (pour one altar's pans onto the
  other's: elimination).
- *8.4 The Star Floor* (8.EE.8a): where the child stands sets the crystals' weights (east: blue, north: rose); each
  altar's level line glows on the floor; stand where they cross and both altars level; parallel lines: no such spot.
- *8.5 The Mosaic Floor:* crystal tiles (x², x, 1): (x + 3)(x + 2) is a rectangle; factorising is tiling a given set into
  one rectangle; (a + b)² and the difference of two squares by cutting and turning (7 × 7 minus 3 × 3 makes 10 × 4: the
  unit's world task, played).
- *8.6 The Square Crystal:* a breathing x² tile; its weight leaves a U-shaped trail on the wall; x² = 9 levels at two
  sizes, 3 and a floaty −3.
- *8.7 Your Own Altar* (making, phase D): choose a secret weight, build both pans; the altar checks it is level and can
  be freed; share it with a friend.
- *8.T1 Twin Crystals in the Fog*, *8.T2 The Star Map* (two crystal kinds in the night sky), *8.T3 The Rocket's Two Fuels*.

**The fade** (picture 10). The rune line passes through four stages: **pictures** (the crystal icon and gem dots in
fives), **numbers** (numerals on the gems and the runes), **letters** (the crystal's rune becomes *x*; standard
notation), **runes only** (the pans in mist; the child acts on the runes with the same twin moves: dragging "+ 3" off
both sides flies the runes off with the same chime). The grade sets the starting stage (5: pictures, 6: numbers from
6.3, 7: letters, 8: runes as the default with the pans on request); the child's play moves it on (three altars in a row
freed with no help: the next stage; two helped in a row: back one). The Book always shows the symbols.

### 3.7 Minute 1, 5 and 30 of a first session

| | Flat (phone, tablet, PC, the web) | VR (the Quest 3) |
|---|---|---|
| **Minute 1** | DISCOVER's maths stop shows the temple's picture; PLAY. The camera glides up a stair of clouds to the temple at sunset; the door opens; Hoot's welcome. Inside, ten frozen crystals glow in a ring, a creature asleep in each. The first altar is in front: the ghost finger taps a gem on the left pan (it rises, amber) and one on the right (both float off, chiming). "Your turn!" The child taps a gem, then its twin: the chime. The crystal stands alone and cracks open: a fox Glimmer yawns, sings, flies up; the chandelier's first light | The child stands on a cloud at the temple's foot; the temple towers above. A cloud carries them up to the door (slowly, no turning). Inside, the first altar rises in front of them at waist height. The ghost hands lift a gem off each pan at once. The child reaches with both hands and does the same: the two gems dissolve with a chime and a buzz in both hands. The Glimmer flies past their face to the chandelier |
| **Minute 5** | Altar 10 of 11, the mixed run: three crystals \| twelve gems. Tap the bowl rack, pick three bowls, tap the seal: each pan sorts into three bowls, one share stays: "Free! It weighs four gems!" Ten chandelier crystals lit; the Great Altar rises in the centre | Pulls three bowls off the rack one by one, presses the seal on the fulcrum with a palm; watches the gems pour into the bowls; one bowl's share stays, the others float off |
| **Minute 30** | The Entrance Hall lit (6 min), the Sky Room solved (4 min: the habit failed at first; then gems on both pans, and the balloons popped), the Leaning Altar (7 min: the floor's line lit for "heavier than five gems", the stone dark), the Breathing Crystals (8 min: a ×3 box balanced by three crystals and twelve gems at every size, and Küchemann's altar that tips, levels and tips back). The end card shows a star on *Equations and inequalities* | The same rooms with the hands: two-hand lifts, balloons popping beside their hands, walking along the leaning altar's line to the boundary stone, the breathing crystal pulsing at arm's length |

### 3.8 Show, say, do (rule 0)

**Shown, not told.** Each new tool is shown once by the ghost (Life's ghost finger flat, ghost hands in VR), then "Your
turn!": the twin take (altar 1), the bowls (altar 5); in later wings the lever, the box, the Mirror, the swap seal. The
transfer rooms have no demonstration (they test the idea). After two refused moves on an altar the ghost does one step
(the altar counts as helped). The eye (SHOW ME) does one step any time (helped). Idle 10 s: everything that can be
touched glows for 3 s (never only the right thing: no help).

**Every voice line of phase B** (Professor Hoot, read by the system's voice through `PlayVoice.say`; each line cuts in;
at most 12 words; [n] is said as a number):

| # | When | Line |
|---|---|---|
| H1 | the arrival | Welcome to the Sky Temple! Its crystals are frozen. |
| H2 | the hall | A Glimmer sleeps in each crystal. Let's wake them! |
| H3 | altar 1, the ghost | Watch: the same off both pans. |
| H4 | after a demonstration | Your turn! |
| H5 | the child's first twin move | Fair and square! The altar stays level. |
| H6 | a crystal freed | Free! It weighs [n] gems! |
| H7 | the gems count themselves | One, two, three… [up to n] |
| H8 | the first Glimmer | It's flying up to the chandelier! |
| H9 | the first rule break | Whoa! The altar wants fair moves. |
| H10 | see why, after a rule break | The same on both pans! |
| H11 | an item carried across (first time) | Moving it across changes both pans. Same on both! |
| H12 | altar 5, the ghost's bowls | Watch: share both pans fairly. Keep one share. |
| H13 | see why after the first share | Two crystals weighed six. So one weighs three! |
| H14 | an uneven share | They won't share fairly. |
| H15 | the ghost's step after two refusals | Watch me do one. |
| H16 | a lift with no possible twin, after 8 s | The other pan has none. Put it back. |
| H17 | the Great Altar rises | The Great Altar! Free its crystal to light the hall. |
| H18 | the hall sings | The hall is lit! Listen to them sing! |
| H19 | see why of the hall | Whatever you do to one pan, do to the other. |
| H20 | the name, after the hall | Grown-ups call this an equation. You just solved eleven! |
| H21 | the door | The great door is open. The Sky Room awaits! |
| H22 | the end card | Wonderful keeping! Another hall? |
| R1 | an altar's start, the rune line read (stage 1) | A crystal and three gems weigh seven gems. |
| R2 | the answer read at the free | One crystal weighs four gems. |
| R3 | the rune line read (stages 2-3) | A crystal plus three equals seven. / x plus three equals seven. |
| R4 | a rune touched | its name: crystal, x, plus, minus, equals, seven… |
| S1 | the Sky Room opens | The Sky Room! Up here, balloons pull pans up. |
| S2 | the frame (teaching) | Balloons pull pans up. Gems pull them down. |
| S3 | waiting 15 s (once; the goal, not the move) | Make the crystal alone. Fair moves only. |
| S4 | the first zero pair (see why) | A gem and a balloon cancel out. Pop! |
| S5 | see why of the room | To undo a balloon, add a gem to both pans. |
| S6 | the end | You found the Sky Room's secret, like a real Keeper! |
| P1-P6 | praise (the strategy and the effort, one at a time, never twice in a row) | Fair and square! · Same on both pans. Perfect! · You shared it out. Clever! · Straight to the answer! · You're a real Keeper now! · Hoo hoo! Well kept! |
| G1-G5 | the place's own | (break) Need a rest? The triangle goes on, the door stops. · (Back) Leave the temple? Your Glimmers will wait. · (a Glimmer topples) Oops! A sleepy one! · (the chandelier lights) Hoo! Look how bright! · (first view inside) It's like a crystal palace! |

Each later room carries its hook line and its see-why line (§3.6 gives them); phase C writes the rest to the same rules.
Without a voice (Read to me turned off by a grown-up, or no English voice on the device) the lines show as words (G0's
ruling 28).

**How the voice carries the symbols.** Reading the symbols is part of the skill, so the symbols are never hidden and
never required before they have been heard:
1. The rune line is carved on the altar's plinth from the first altar and changes in step with every move (a gem off
   each pan: a dot fades from each side of the line, with the same chime).
2. Hoot reads the line at an altar's start and the answer at the free (R1-R3): as a description at stage 1 ("A crystal
   and three gems weigh seven gems"), then in maths words ("x plus three equals seven").
3. Every rune says its name when touched (G0's rule "a thing says its name"); the ear repeats the last line.
4. The runes-only stage (fog) comes only after the letters stage has been heard dozens of times; there Hoot still reads
   the line at the start, and the child acts on the runes themselves.
5. On the screen during play there are no words: only the rune line (numbers, x and + − × ÷ = <, which are the subject)
   and the HUD's pictures.

**Pictures and colours that carry meaning** (picture `08-things-and-meanings.png`). Shape, motion and sound carry each
meaning too, so nothing depends on colour alone.

| Thing | Its look | Its sound |
|---|---|---|
| A frozen crystal (x) | a tall ice-blue prism, chained, a sleeping creature curled inside | a low hum |
| A breathing crystal (a variable) | the same prism, unchained, slowly growing and shrinking, rings around it | a soft breath |
| A freed crystal | warm gold and empty; its Glimmer beside it | a bright crack, then the Glimmer's note |
| A gem (+1) | a round faceted gold gem; in rows of five on a pan | a clink |
| A number gem (+n; wing 7) | a bigger gold gem with its numeral | a deeper clink |
| A balloon (−1) | a round coral-red balloon on a string tied to the pan | a squeak; a pop when it cancels a gem |
| A crystal balloon (−x; wing 7) | a lilac prism-shaped balloon on a string | a soft squeak |
| A floaty crystal (a negative answer) | a freed crystal that drifts up on its own | a rising chime |
| A recipe box (k × [ ]) | a wooden box of k compartments with a "×k" tag | wood |
| The sharing bowls, the gem bag, the balloon pump | bronze bowls on a rack; a violet velvet bag; a brass pump | a bowl's ring; a rustle; a pump's puff |
| The Mirror (× −1; wing 7), the swap seal (wing 8), crystal tiles (wing 8) | a gold hand-mirror; a gold disc with two arrows; ice-blue tiles | a shimmer; a click; a snap |
| The rune line | dark carved runes on a cream plaque under the pans | a soft click when it changes |
| The glows | amber: waiting for a twin; green: a fair move; a soft red shimmer: refused | a two-note chime (fair); a soft rattle (refused) |

**Sounds and music** (all already in the repo, public domain or CC0, `assets/CREDITS.md`): Bach's *Goldberg Aria* in the
halls (CC0; Bach's symmetry suits a temple of balance), *Ode to Joy* for a hall's chorus (each Glimmer sings one note of
its first phrase, so freeing them plays it note by note, and the full hall sings it), Vivaldi's *Spring* in the Sky Room,
Satie's *Gymnopédie* for the breathing crystals, the repo's own *Eine kleine Nachtmusik* rendering in the Recipe Kitchen.
New sounds (the clinks, the two-note chime, the chains' soft rattle, the beam's creak, the crystal's crack, the Glimmers'
yawns and notes, the balloon's squeak and pop, the bowls, the seal's thunk) are made by a tool like
`tools/make_tiny_sfx.py`: original, so CC0 by construction.

**Words on the screen during play: none but the rune line.** The HUD shows pictures (G0's glyphs: the ear repeats Hoot's
line, the eye is SHOW ME, two bars are a break). The end card shows numbers (the gold) and stars.

### 3.9 The five tests, answered

**Choice.** What a 10-14-year-old chooses, and how this game gives it: *epiphanies* (the hall is a run of small "aha"s,
The Witness's "miniature epiphanies over and over again" [G19]: the trap altar, the bowls, the Great Altar's order, the
Sky Room's gem); *creatures* (a Glimmer asleep in every crystal, seen before it is freed, waking up because of you; their
notes become the hall's tune); *getting good, visibly* (the chandelier fills; the temple's map lights room by room; the
runes become readable); *the body* (in VR two giant pans under your two hands); *surprise* (the door, the Sky Room's
balloons, the Mirror's flip, the Star Floor where you stand on the answer); *making and owning* (your own altar for a
friend, room 8.7); *short* (an altar 20-60 s, a room 4-8 minutes, never timed). Risks: once the twin rule clicks,
one-step altars are easy (the answer: the hall is short, every room adds a tool or breaks a habit, the grade picks the
wing); a puzzle temple may feel like homework to some children (the answer: the Glimmers, the sound, the temple's
beauty; and the owner's child decides). **How we check:** the owner's child plays phase B; we note voluntary time, whether
they start the Sky Room unasked, whether they come back another day, and what they say about the Glimmers. A game nobody
returns to is redesigned before phase C.

**Mute.** Nothing in a room needs reading: the problem (a frozen crystal among gems) is seen; the move (a gem off each
pan) is shown once by the ghost; the world answers every move (the chime and the green glow, or the soft rattle and the
spring back); the result (the crystal cracks, the gems count themselves aloud) is seen and heard; the goal (the dark
chandelier, the closed door) is visible from the start. The only text is the rune line, which is the subject and is
always read aloud. **How we check:** a test that the screen shows no words but the rune line while an altar plays
(`AltarHud.screen_words()` = 0 outside the runes); every line spoken by itself (`PlayVoice`); the owner's child plays with
text hidden.

**Cheat.** The altar's rules are the rules of equality, the move budget catches wandering, and the beam cannot be used
to weigh the crystal. The phase A model (`balance-altar/model/hall_model.py`, 1,000 visits per player, the hall's eight
judged altars, numbers new every visit; the bar is MasteryRules': 7 of 8 freed first time):

| Player | Reaches 7 of 8 | Freed first time (of 8) | What happens |
|---|---|---|---|
| Knows the rule | **100 %** | 8.00 | twin moves only; takes the gems, shares by the crystal count; the Great Altar in two moves |
| Knows it, slips on 4 % of moves | 95.3 % | 7.64 | the fairness check: a slip costs that one altar |
| Keeps the balance, greedy (always the fair move that leaves the crystal most alone) | 100 % | 8.00 | not a cheat: fair moves aimed at the goal *are* the understanding this hall teaches (see below) |
| Keeps the balance, no plan (a random fair move each time) | 0.2 % | 3.04 | adding gems is fair but goes the wrong way; it frees about one altar in three by luck |
| Guesses which move undoes what | **0 %** | 1.59 | about a third of the take altars, one share altar in fifteen (it must also guess the bowls) |
| Habit: always take away | 0 % | 4.00 | every take altar, no share altar |
| Habit: divide by the number | 0 % | 3.00 | every share altar, no take altar, never the Great Altar |
| Random moves, fair or not | 0 % | 0.24 | about 18 refused moves a hall |
| Random taps, item by item | **0 %** | 0.14 | a twin completes only by accident |
| One pan only | 0 % | 0 | every move refused |
| Carries things across | 0 % | 0 | every move refused |
| Weighs the crystal (our chained beam) | 0 % | 0 | refused |
| Weighs the crystal (a free-swinging beam: **not built**) | 100 % | 8.00 | why the frozen crystal's chains hold the beam level (ruling 3) |

The model also checked the design: with the first move budget ("one move more than the shortest" on every altar) the
no-plan player passed about half the one-move altars (detours like "add two gems, then take five" fitted), so a one-move
altar must now be freed in one move (ruling 5). The greedy player is reported honestly: it only makes fair moves and
picks the one that brings the crystal nearest to alone, which is what we want a child to discover; where the shortest
path goes through a messier state (wing 7's echo bell, wing 8's twin altars) that strategy alone is not enough.

**Transfer.** Each idea comes back somewhere new, where the habit fails and the rule works. The phase A model of the Sky
Room (`balance-altar/model/sky_room_model.py`, 1,000 visits, six judged altars, the bar 5 of 6): the rule frees all six
(**100 %**; 97.0 % with slips); **the hall's habit frees the two familiar altars and none of the four balloon altars
(0 %)**; keeping the balance with no plan 0 %, guessing which move 0.2 %, random play, one pan and carrying across 0 %.
The ladder's model (`balance-altar/model/ladder_model.py`, 1,000 visits each) checks the later wings the same way:

| Room (wing) | The habit that fails | The rule | Others |
|---|---|---|---|
| (a) Crystals on both pans, a x + b = c x + d (8; phase C's transfer) | unwinding (take the gems, share by the crystal count; Knuth's grade-7 strategy [A1]): **0 %** (0 of 6) | **100 %** (88.1 % with slips: three moves each) | greedy 100 %; no plan, guessing, random taps, one pan: 0 % |
| (b) Breathing crystals: build the equivalent pan, level at sizes 2, 5, 8 (6-7) | the distributive slip 3x + 4: **0 %** (it passes only the like-terms altar); conjoining (7x): 0 %; matching the weight at one size: 0 % | **100 %** | right crystals with guessed gems 0 %; a random build 0 % |
| (c) The leaning altar, p x + q > r, half with p < 0 (7) | treating it as an equation (one stone lit): **0 %**; forgetting the Mirror's flip: **0 %** (3 of 6) | **100 %** | random side and stone 0.5 % |
| (d) Twin altars, x + y = 9 beside x = y + 3 (8) | every fair move on one altar alone, searched to depth 7 (1,576 states): **no crystal ever freed** | after one swap: two moves (take three gems, share by two) | — |

The first unhelped solve in a new setting is recorded as `SkillShown.NEW_SETTING`. The symbols themselves are a transfer
test too: the fog altars (6.T2, 7.T3, 8.T1) hide the pans, so only a child who reads the runes can act; the School's
written exercises and the Book stay as the outside check (the lead's audit, phase C).

**Wow.** The temple at sunset and the door opening for you; the first crystal cracking and its Glimmer yawning awake;
the chandelier filling, light by light; the Great Altar's chorus and the door onto the sky; the Sky Room's balloons; in a
headset, a gem lifted off each giant pan by your two hands and a Glimmer flying past your face. Each wow *is* the
concept (the crack happens only when the crystal is alone; the chorus is the hall's altars freed; the pop is a gem and a
balloon cancelling), never decoration. **How we check:** the owner's verdict on phase B, and whether the child shows it
to someone.

### 3.10 What the game records as learning (invisible assessment)

The game never asks a question to check. Its evidence model (evidence-centred design, as the leaf's [`leaf-voyage.md`
R30]; stealth assessment): each **competency** is an idea of §3.4; each **altar** is a situation where the child's moves
show it, judged by a rule; the altar becomes one `SkillShown` event for the room's unit.

**The altars of phase B** (unit `g6.maths.equations`):

| Altars | When | Judged when | Kind | Strength of the evidence |
|---|---|---|---|---|
| 1, 2, 5 | the hall's teaching altars (the ghost's twin move, the trap, the bowls) | not judged | — | teaching (a refused move here is how the rule is met) |
| 3, 4, 6-10 | the hall | freed with no rule break, no help, within the move budget | SOLVED (else HELPED; SHOWN if the ghost finished it) | strong: random taps free 0-4 % of these by luck; guessing take-or-share frees about a third of the take altars and one share altar in fifteen |
| 11, the Great Altar | the hall's end | as above (two moves; the budget is three) | SOLVED / HELPED / SHOWN | stronger: two moves, in an order that works |
| Sky Room 1-6 | the transfer room | as above | NEW_SETTING (else HELPED / SHOWN) | strongest: the hall's habit frees none of its balloon altars |

So the hall gives **8 events** (a round: MasteryRules counts one at 6; 7 of 8 right first time masters the unit, ★★, its
100 gold once) and the Sky Room **6 events**, `NEW_SETTING` when unhelped (a full round; its transfer kept apart in
`result.transfer`). Events are added as each altar is judged; `record` runs once when the room ends (never on "stop for
now", G0's rule); each SOLVED or NEW_SETTING altar pays the first-try gold through `SkillShown.pay_first_try` as it is
judged (the daily cap holds).

**What each event's note says** (the misconceptions, for the journal and the grown-ups): "one pan" (a lift not twinned),
"carried across", "unfair share" (bowls that don't divide), "no twin" (a lift whose kind the other pan lacks), "over
budget" (more moves than allowed), "ghost step", "eye". A freed altar with a refused move or over its budget is recorded
as `HELPED`: in MasteryRules' terms an answer right but not the first time (ruling 15).

**What "help" means:** the ghost's step (after two refused moves, or on SHOW ME), H16's hint (a lift that can't be
twinned), and the ghost finishing an altar make the altar HELPED (SHOWN if the ghost freed it). The teaching lines (H3,
H12, S2) and S3 (which restates the goal, never the move) are not help. **Gold:** each SOLVED or NEW_SETTING altar pays the
School's first-try gold; nothing pays for time.

**The room-to-unit map** (one main unit per room, so each room is a full round for its unit; other units get review
events only when already mastered, as the leaf's ruling 9):

| Rooms | Main unit | What is judged |
|---|---|---|
| 5.1-5.4, 5.T1 | `g5.maths.expressions` | a box weighed or built level the first time; a recipe packed right |
| 6.1, 6.T1, 6.2, 6.T2, 6.T3 | `g6.maths.equations` | the hall's 8, the Sky Room's 6, the leaning altar's lit solutions, the fog and open altars |
| 6.3 | `g6.maths.equivalent_expressions` | breathing builds level at every size, first time |
| 6.4 | `g6.maths.exponents_expressions` | powers and glass-crystal recipes weighed first time |
| 6.5 | `g6.maths.variables` | the rule's dials set right first time |
| 7.1, 7.2, 7.4, 7.T2, 7.T3 | `g7.maths.equations` | two-move altars, shards, the Mirror |
| 7.3 | `g7.maths.expressions` | boxes opened and packed (breathing check) |
| 7.5 | `g7.maths.inequalities` | leaning altars solved and lit right |
| 8.1, 8.2, 8.T1 | `g8.maths.linear_equations` | twin crystals freed; one, none or many told apart by breathing |
| 8.3, 8.4, 8.T2, 8.T3 | `g8.maths.systems` | twin altars freed with the swap or the stack; the Star Floor's crossing |
| 8.5, 8.6 | `g8.maths.expand_factorise` | rectangles tiled; the square crystal's two sizes |

**Adaptivity (honest).** After two helped altars in a row, an extra altar is slipped in and taught again (the ghost shows
its first move; not judged, so the room still gives its full count of judged altars; the journal notes "re-taught"); the
fade moves as §3.6 says. The game's own **keeper's journal** (device-only in
phase B, `user://balance_altar.json`) keeps, per idea (the twin rule, take, share, balloons, the reverse order), how often
the child showed it, with or without help, in which rooms, the misconceptions seen and whether they stopped ("one pan
only: twice in the first hall, never since"), and the fade stage; the next room reads it, and phase C can show the
grown-ups' page "what your child showed" in plain words.

**Why this shows learning:** an altar can be freed first time only by fair moves that undo what is beside the crystal, in
an order that works, within its budget; a transfer altar only by changing the habit to fit the rule. Guessing, the
classic errors and half-knowledge were tested and fail (§3.9). What the altars cannot show (whether the child can *say*
why both sides must change) is the Book's and the grown-ups' business, never a quiz.

### 3.11 The look

**The idea:** a temple built from the game's own shapes, in the Life rooms' kit look (lit matte shapes, glowing parts, a
few see-through panels), so it is EasyCraft and it runs on a phone and a Quest: white stone and gold, ice-blue crystals,
coral balloons, a warm sunset light. The pictures in `balance-altar/` are the sketches:

- `01-the-temple.png`: arriving (the temple on its clouds, the stair, the door, Hoot) and inside (the ring of altars, the
  chandelier, the great door, one altar close up with its sleeping Glimmer).
- `02-one-altar.png`: an altar named: the crown (two gold bars: the equals sign), the beam, the chained crystal, gems in
  fives, the rune line, the bowls, the gem bag.
- `03-the-twin-move.png`: the verb in four steps and the refused move, with why the beam is held.
- `04-the-hall.png`: the Entrance Hall as a map, its eleven altars in order with their times.
- `05-the-sky-room.png`: the transfer: the habit stuck, the rule's gems on both pans.
- `06-core-loop.png`, `07-the-ladder.png`, `08-things-and-meanings.png`, `09-vr.png`, `10-the-fade.png`,
  `11-later-wings.png`, `12-cheat-test.png` (the model's results, drawn from the models when the pictures are made).

**Scale.** The hall is about 16 m across under a 12 m dome; the chandelier hangs at 7 m. The active altar (flat and VR) is
child-sized: the beam at about 0.95 m, the pans' centres 0.7 m apart (two hands reach both), each pan 0.32 m wide, a gem
6 cm (hand-sized), a crystal 22 cm tall, the rune plaque 0.5 m wide at the plinth's front. In VR the child stands 0.45 m
from the altar's front. The Great Altar is twice the size, its pans at the same height.

**Light:** one warm key light (the sun through the oculus), a soft fill, no shadows (the budget); the crystals and the lit
chandelier sockets glow. **Colour:** white stone and gold at the top, warm sand floor; the meaning colours (§3.8) stand
out against them. **Motion:** the beam breathes slightly; gems float up in pairs; Glimmers fly in arcs; the ring turns
between altars; the Sky Room's balloons bob.

**Both graphics styles:** phase B has one look (the kit's), used in blocky and realistic; a realistic twin is phase C's.

### 3.12 Kind, fair and safe

Never timed: an altar waits as long as the child thinks. Never lost: a refused move changes nothing, stopping keeps every
freed Glimmer, and nothing happens to the temple while the child is away (no timers, no decay, no streaks). No failure
screen: the ghost helps after two refused moves. Glimmers are freed, never caught or bought, and each is shown before it
is freed (no random rewards, no gambling). A sleeping Glimmer is asleep, never sad or in danger (no guilt trick). Rewards
are fixed and once (the School's gold and stars). No real names. Calm sounds (the rattle is soft, never an alarm).
Reduce motion (SETTINGS) makes the breathing crystal step between sizes instead of pulsing, stills the chandelier's
sparkle and the clouds. VR comfort: the child stands still and the altar comes to them; the cloud lift is slow and
straight; blink is the comfort choice.

---

## 4. The tech plan for phase B

### 4.1 What phase B builds

The Entrance Hall and the Sky Room, complete and beautiful, flat and VR: the arrival, the hall and its eleven altars, the
Sky Room and its six, the altar's rules, the evidence and the record, the voice, the sounds and music, the ghost's
demonstrations, the Glimmers and the chandelier, the end card, and a two-room board (the hall again, the Sky Room).
Opened from DISCOVER (the unit page's PLAY for `g6.maths.equations`), from the Academy's Maths Workshop door (when the
child's unit is in the strand), and by a developer argument.

### 4.2 What G0's and W1's foundation gives, and what this game adds

| The foundation gives (`docs/devlog/parts/play-g0.md`, `play-w1.md`, DEVELOPMENT.md "The foundation's API") | This game adds |
|---|---|
| `PlayVoice.say` / `on()`: every line spoken, cutting in; words only without a voice | the lines as data (`data/play/altar/lines.json`), each tested for length; the rune line's spoken reading (`AltarRunes.say`) |
| `SkillShown`: `begin`, `add(unit, kind, note)`, `pay_first_try`, `record`; the round rule (6 events) | `AltarBeats`: each altar judged into one event with its note |
| `PlayHost`'s pattern: a place far above the world, hiding the screen it came from, its own camera, `LifeReach` for fingers, hands, laser and head, the VR anchor and blink, the idle glow, SHOW ME, the break card, Android Back (`any_open`) | `AltarTempleHost`: the same pattern for a sequence of altars (not exercise by exercise): the ring that turns, twin-move input (tap, long press, drag), the altar as the VR hands' grip claimer |
| `LifeGhostFinger` (flat) and `LifeGhostHands` (VR): show a step | the demonstrations: a twin take, the bowls; the ghost's step after two refused moves (the next move of `AltarSolver`'s shortest solution) |
| `PlayGlyph`, `PlayHud`'s ear, eye and break pictures; the screen-word budget | `AltarHud`: the end card's pictures; zero words in play but the rune line |
| `LifeRoomKit`: shapes and materials the warm-up already holds | `AltarKit` on top of it: stone, gold, crystals, gems, balloons; merged meshes and MultiMeshes |
| `VrGrabber.claimers` (`grip_claim(side)`, `grip_release(side)`: the Build Table's and `VrBricks`' way), `Vr.hand_busy`, `Vr.simulate` / `sim_hand` / `sim_input` | the altar claims a grip near a pan and picks the gem itself (no per-gem grabbable: the gems stay one MultiMesh) |
| DISCOVER, the registry's `signature` entries, P0/P1 and the audit; W1's `AcademyPlaza.opens()` (the lead's switch) and the crystals' `DiscoveryPlays.play_for` | one registry entry (`balance_altar`) that names a **host** (the mechanism the leaf's review decided; the leaf's phase B2 builds it, §4.7) |
| The School's generators (`G6AlgebraGen`, `G7NumberGen`, `G8AlgebraGen`) | `AltarGen` draws its altars from the same forms and ranges |

### 4.3 Files

- **Pure rules, `core/play/altar/`** (no nodes; deterministic; seeded; the phase A model's rules, `model/altar_rules.py`):
  - `AltarState`: the two pans (crystals, gems, balloons as net amounts; the hidden weight), `holds()`, `freed()`,
    `crystal_pan()`.
  - `AltarMoves`: the twin moves and their legality (take, add, share; phase C: echo, mirror, swap, stack, open, pack),
    the waiting batch (`lift(pan, kind)`, `place(pan, kind)`, `put_back()`, `handful(pan, kind)`), the rule breaks and
    their kinds (one pan, across, unfair share, no twin).
  - `AltarSolver`: the shortest solution (breadth-first, as the model's `shortest`): the ghost's next step and the move
    budget.
  - `AltarGen`: altars by form and level (add, mul, two-step, sub, sub two-step; phase C: twin, boxes, shards, negatives),
    seeded, from the generators' ranges.
  - `AltarBeats`: judges an altar (SOLVED, NEW_SETTING, HELPED, SHOWN; the note) and adds its `SkillShown` event.
  - `AltarRunes`: the rune line of a state at a fade stage (pictures, numbers, letters, runes), and its spoken reading
    (at most 12 words).
  - `AltarHalls`: the catalogue (`data/play/altar/halls.json`): each room's altars (form, taught or judged, its
    Glimmer), lines, music, unit, unlocks; the ladder.
  - `AltarProgress`: the temple's state (rooms lit, Glimmers, the keeper's journal, the fade stage); a device file in
    phase B (`user://balance_altar.json`, like `PlayQuests`).
  - `AltarTwinRules` (VR): which pan a hand is over, a handful's size, both hands' lifts as one twin.
- **The place, `entities/play/altar/`:** `AltarTempleHost` (open/close, input, camera, VR, the demonstrations, the
  record, the `finished` / `stopped` signals as `PlayHost`'s, `any_open`), `TempleHall` (the dome, the ring, the
  chandelier, the great door, the Great Altar's rise), `BalanceAltar` (one altar: the fulcrum and crown, the beam with a
  damped swing for the free, the pans, the chains, the crystal and its Glimmer, the gems and balloons as MultiMeshes, the
  rune plaque, the bowls, the gem bag, the pump; its `LifeReach` targets; the VR grip claimer), `SkyRoom` (the transfer
  room's dressing: clouds, balloons, the platform), `GlimmerModel` (blocky crystal creatures: fox, bunny, bird, turtle,
  fish, cat), `TempleArrival` (the cloud stair, the door), `AltarKit` (shapes and materials over `LifeRoomKit`).
- **UI, `ui/play/altar/`:** `AltarHud` (the ear, the eye, the break, the end card, the room board; pictures only).
- **Data:** `data/play/altar/halls.json`, `data/play/altar/lines.json`; the unit's `play` block names the game (§4.7).
- **Sounds:** `tools/make_altar_sfx.py` (clinks, the two-note chime, the soft rattle, the creak, the crack, the Glimmers'
  yawns and notes tuned to the hall's tune, the balloon's squeak and pop, the bowls, the seal); the music is in `assets/`.
- **Tools:** `tools/altar_smoke.gd` (plays both rooms with the rule bot, flat and simulated VR, headless; checks the
  record), `tools/altar_shots.gd` (pictures in a real window: the arrival, the hall, an altar close up, the free, the
  chorus, the Sky Room), `tools/altar_bench.gd` (draws and frame times, VR preview, like `vr_bench.gd`).

### 4.4 Flat and VR

**Flat (phones, tablets, PC, the web).** The camera looks at the active altar from the front, a little above (the
station view of G0's arena); between altars the ring turns (a 1 s glide). **A tap on a gem lifts it** (it rises and glows
amber; its possible twins on the other pan glow); **a tap on a twin** completes the move; a **drag** from a gem to a gem on
the other pan does both; a **long press** on a pan lifts a handful (every gem of that kind on it), and a long press on the
other pan takes the twin handful. A tap on a lifted gem puts it back (free). The bowl rack: a tap shows bowl counts 2-6 as
pictures; a tap on a count sets the bowls on both pans; a tap on the seal (the gem in the fulcrum's crown) shares. The gem
bag: a tap takes a gem (it floats above the bag), a tap on a pan places it (waiting for its twin). Every target is at least
a fingertip (`LifeReach.screen_pick`) and inside the view's free band (`PlayHud.FREE`). A developer argument opens a room
directly (`--altar-hall=entrance` or `sky`).

**VR (the Quest 3).** The child stands at the hall's spot (`Vr.anchor`), the active altar 0.45 m in front, its pans
within both hands' reach. **The twin move is two hands:** a grip near a pan lifts the gem under that hand (the altar claims
the grip: `grip_claim(side)`); while one hand holds a gem from one pan, the other hand's grip on the other pan takes its
twin, and both dissolve with the chime and a buzz in both hands (Cook, Mitchell & Goldin-Meadow's two-hand "equalizer"
gesture [C7]); letting a held gem go over its own pan puts it back. A grip with the hand open over a pile scoops a handful;
the other hand's scoop takes the same number. **One-handed** (a comfort setting, or a child holding one controller): a
trigger on a gem lifts it, a trigger on its twin completes the move. **The bowls:** pull bowls off the rack (one pull, one
bowl), press the seal with a palm. **The gem bag:** reach in, a gem in the hand, drop it on a pan. The HUD stays hidden;
the raised forearm shows the small panel (owner #127). Hoot perches on the altar's crown, his voice placed there. Tests
drive it with `Vr.simulate`, `sim_hand`, `sim_input`.

### 4.5 The budget

Targets: **≥ 30 FPS average and no frame over 100 ms on the emulator**; **≤ 100 draws a frame on the Quest** (the floor
preset, 72 Hz), aim ≤ 70; one light, no shadows; only shaders the warm-up holds (the kit's materials; a new one goes into
the census with its test). Estimated draws in the hall at its heaviest (the chorus): the hall's shell (dome, walls,
floor, oculus) merged 3; the ten other altars merged 1 and their crystals as one MultiMesh 1; the chandelier's frame 1 and
its lit and unlit sockets 2; the active altar (fulcrum, crown and plinth merged 1, beam 1, pans 2, chains 1, crystal 1, the
chains' glow 1, the sleeping silhouette 1, gems 1, balloons 1 and their strings 1, the rune plaque 1, bowls 1, gem bag 1,
pump 1) about 15; the flying Glimmer 3; Hoot 5; the VR hands 4 (flat: the avatar is out of view); the HUD canvas 10-20
(pictures batched like `CanvasBatch`) → **about 45-55**. The Sky Room: about 40 (fewer altars; clouds as one MultiMesh).
A MultiMesh's per-instance colour changes its shader, so each colour is its own MultiMesh (no census change), as the leaf
found.

### 4.6 Tests (TDD, each failing first)

- `tests/unit/test_altar_state.gd`, `test_altar_moves.gd`: the twin rules (a lift waits; a batch grows on its own pan;
  the twin commits; anything else is a rule break and changes nothing; put back is free; carrying across is refused;
  shares only when every amount divides; zero pairs cancel by themselves), freed only alone with nothing waiting.
- `tests/unit/test_altar_solver.gd`: shortest solutions for every form; the move budget (one move for one-move altars).
- `tests/unit/test_altar_gen.gd`: every generated altar holds for its weight and can be freed within its budget; the
  ranges are the School's generators'.
- `tests/unit/test_altar_beats.gd`: each altar's judgement (SOLVED, NEW_SETTING in the Sky Room, HELPED after help, a rule
  break or over budget, SHOWN when the ghost frees it); taught altars not judged; the notes; 8 and 6 events.
- `tests/unit/test_altar_cheat_bots.gd`: **the cheat test as a test**, the model's players over 1,000 seeded visits:
  random taps, random moves, one pan, across, the weigher, the two habits, the guesser and no-plan reach the hall's bar in
  under 1 %; the rule bot in over 99 %; the slip bot in over 90 %; in the Sky Room the hall's habit never, the rule always.
- `tests/unit/test_altar_runes.gd`: the rune line for every stage; the spoken reading at most 12 words.
- `tests/unit/test_altar_halls.gd`: the data: every room names a written unit; every line at most 12 words and never a
  question that needs reading; every room has its hook and see-why lines.
- `tests/unit/test_altar_twin_rules.gd` (VR): two hands, two pans, one twin; a handful's size; one-handed mode.
- `tests/integration/test_altar_place.gd`: every target in the flat view's free band and at least a fingertip; every pan
  within both hands' reach from the VR spot; only warmed shaders; no shadows.
- `tests/integration/test_altar_host.gd`: flat and simulated VR through both rooms: the arrival, the demonstrations, the
  trap, the bowls, the Great Altar, the chorus, the door, the Sky Room, the record (`SkillShown` events, the stars), the
  break, stop for now (nothing recorded), Android Back.
- `tests/integration/test_altar_voice.gd`: every line spoken by itself; no word on the screen but the rune line.
- `tests/integration/test_altar_budget.gd`: draws at the heaviest moment ≤ 100 (the place's own counter).
- The full suite once at the end; the smoke; pictures in a real window; the bench; then the lead on the emulator and the
  Quest, and the owner's child.

### 4.7 The hooks phase B needs from others (the lead decides: §8)

1. **The registry for a deep game with its own host**, as the leaf's review decided: `data/play/mechanics.json`'s
   `"signature": {"balance_altar": {"name": "Balance Altar", "host": "res://entities/play/altar/altar_temple_host.gd"}}`
   and `SchoolScreen`'s PLAY opening a host when the unit's `play.game` names one. The leaf's phase B2 builds this
   mechanism; if it has merged, Balance Altar adds one entry; if not, Balance Altar's B2 builds it the same way.
2. `g6.maths.equations`'s `play` block: `{"game": "balance_altar", "params": {"room": "entrance"}}` (a content file).
3. Back and the pause key belong to the temple while it shows (`AltarTempleHost.any_open` beside `PlayHost.any_open` in
   `menu.gd`; W1's `room_open` / `close`).
4. W1's Academy: the Maths Workshop door (`AcademyPlaza.opens`) and a crystal's choice open the temple when the child's
   unit is one the game covers (in phase B: `g6.maths.equations`).

### 4.8 The order of work (one agent, three briefs of two sessions; the lead checks between)

1. **The altar works** (sessions 1-2): `AltarState`, `AltarMoves`, `AltarSolver`, `AltarGen`, `AltarBeats`, `AltarRunes`,
   the data, `AltarProgress`, the bots as tests (the model's thresholds); then the places (`AltarKit`, `TempleHall`,
   `BalanceAltar`, `GlimmerModel`, the Sky Room's first dressing) and their pictures in a real window; the draws counted.
2. **The temple plays** (sessions 3-4): `AltarTempleHost` flat (input, the ring's turn, the demonstrations, the voice and
   the rune reading, the record, the end card, DISCOVER's and the Academy's hooks), then VR (the grip claimer, two-hand
   twins, the bowls, the gem bag, ghost hands, the cloud lift, comfort), the budget bench.
3. **The temple sings** (sessions 5-6): the Sky Room complete, sounds and music, juice (the crack, the Glimmers' flight
   and notes, the chorus, the chandelier, the door), the smoke, the full suite; fixes after the lead's emulator and Quest
   check and the owner's child's first play.

---

## 5. Phases and estimates

| Phase | What | Gate | Estimate |
|---|---|---|---|
| **A** (this) | research and design | the lead's review; the owner sees `balance-altar-owner.md` | done |
| **B** | the Entrance Hall and the Sky Room, complete and beautiful, flat and VR | played on the emulator (≥ 30 FPS, no frame > 100 ms) and the Quest (≤ 100 draws, 72 Hz); the owner's child plays; the five tests checked honestly (the bots, no words but the runes, the Sky Room solved unhelped, the child's choice, the owner's wow) | **6 agent sessions** (one agent; 5 if the leaf's B2 hook has merged; 5-8 with surprises) |
| **C** | the ladder at its minimum (about 18 rooms: 5.1, 5.2, 5.3, 6.2, 6.3, 6.4, 6.5, 6.T2, 7.1, 7.3, 7.4, 7.5, 7.T1, 8.1, 8.2, 8.3, 8.5, 8.T1), each with its altars and events; the eleven units to P1; the temple in the world (the floating island over the Academy); the temple's map; the fade across the wings; the progress in the profile; the School's written exercises as a before-and-after check (learning-is-play G6) | the full suite; the lead's device check; playtest data | about 16-22 agent sessions (three more kinds of altar: weighing, breathing, twin; the Mirror; tiles) |
| **D** | grow: the remaining rooms, your own altar for a friend, the world's puzzle temples, the Glimmers in the world, the realistic twin, temples visited together | voluntary time, returns, transfer in playtests | ongoing |

---

## 6. Risks

| Risk | Why it matters | What we do |
|---|---|---|
| Too easy once the twin rule clicks | a bored child stops choosing it | the hall is short (6 minutes); every room adds a tool or breaks a habit; the grade picks the wing; the mixed run and the Great Altar need a choice |
| A puzzle temple feels like school | choice | the Glimmers, the music, the temple's beauty, VR's hands; the owner's child decides; a redesign if nobody comes back |
| The knowledge stays in the game (DragonBox's gap [G3][G6]) | transfer | no prompts (the child chooses every move); the rune line read aloud from the first altar; the fade; fog altars; transfer rooms as evidence; the School's exercises as the outside check in phase C |
| The balance breaks with negatives [A7][B2] | the hardest part of early algebra | balloons and the Mirror, each introduced as a transfer test (6.T1, 7.4); the honesty table |
| The chained beam is a fiction (a real balance tips) | honesty; a curious child asks | the see-why (picture 03), the honesty table; the leaning and breathing altars tip truly |
| A child sees the rune line as decoration | the symbols never become theirs | it changes with every move, is read aloud, speaks when touched; the fog altars need it; the fade adapts |
| Phones: small gems, fat fingers | a mis-tap would cost a star | gems at least a fingertip; a lift alone is not a refusal (only a different act after it); put back is free; long press for handfuls; drag twin |
| VR: two-hand moves; one-handed players | comfort and access | the grip claimer; one-handed mode; standing still; slow lift; tested on the Quest |
| The voice (text-to-speech quality; a device with none) | rule 0 needs a voice | `PlayVoice`'s words when there is none (G0 ruling 28); a recorded voice is the owner's later choice |
| The evidence is noisy (a slip, a lucky guess) | stars must mean something | eight judged altars a hall, move budgets, transfer rooms; the slip player still masters 95 % |
| Glimmers become a collecting pressure | no FOMO, no gambling | no timers, no limited editions, no trading, each Glimmer seen before it is freed; they are the temple's light, not a currency |
| The registry and the menus' hooks (G0's and W1's files) | without them DISCOVER can't open the temple | the lead's decision (§8); the leaf's B2 mechanism; a developer argument meanwhile |
| Scope (four wings, about 30 rooms) | a long tail | the phases; phase C's minimum ladder; one place per wing reused by its rooms |

---

## 7. Rulings (each with its cost if wrong)

1. **The core verb is the twin move** (take, put, share: the same on both pans); the crystal is freed only alone with
   nothing waiting. *Cost:* one-step altars are easy once the rule clicks; the hall is short and the wings grow harder.
2. **A move is a batch that waits for its twin**: a lift waits (amber), more of the same on the same pan grows it, the
   other pan's same lifts commit it; anything else in between is a rule break; putting back is free. *Cost:* a child
   cannot do two different things on one pan before the other; an explorer's one experiment on a judged altar costs that
   altar's credit (the teaching altars are free to explore).
3. **The frozen crystal's chains hold the beam level**: a refused move rattles them and springs back, and the beam never
   shows which pan is heavier, so the crystal cannot be weighed (the model: weighing with a free beam wins 100 %, with
   the chained beam 0 %). *Cost:* less physical drama than a tipping beam, and a fiction (the honesty table); the leaning
   and breathing altars tip truly.
4. **A refused move changes nothing and costs only that altar's first-time credit**; every second one brings the ghost's
   step. *Cost:* none for the child's progress; the evidence is strict.
5. **The move budget: a one-move altar in one move, a longer one with one move more than its shortest solution** (taking
   pair by pair or by the handful is one move). *Cost:* a child who adds a pointless gem pair loses that altar's credit
   (the model showed the looser budget let a no-plan player free half the one-move altars).
6. **The sharing bowls have no preview** (set the count, then seal). *Cost:* a miscounted share costs that altar's credit;
   with a preview, trying every count would solve it.
7. **Gems in rows of five, at most 12-15 a pan, whole numbers in the hall** (weights 1-8); half-gems at level 3 and number
   gems from wing 7. *Cost:* 6.EE.7's rational numbers wait for level 3 and wing 7.
8. **Negatives are balloons** (a balloon pulls its pan up; a gem and a balloon on one pan cancel and float off by
   themselves), **crystal balloons** are −x, a **floaty crystal** is a negative answer. *Cost:* a fiction that keeps the
   algebra true (the honesty table); a real balloon's lift doesn't vanish.
9. **The equals sign is the fulcrum's crown** (two gold bars). *Cost:* none known.
10. **The crystal is never "c"**: its rune is a crystal icon until the letters stage, then *x*. *Cost:* the letters
    arrive later than in a textbook (that is the point: letters as numbers [A8][A10]).
11. **The fade moves with the child's play** (three altars freed in a row unhelped: the next stage; two helped in a row:
    back one); the grade sets the start. *Cost:* children of one grade see different stages; the Book always shows the
    symbols.
12. **The voice reads the rune line at an altar's start and the answer at its free; every rune says its name.** *Cost:*
    more voice per altar; the ear repeats; a grown-up can turn Read to me off (words then show).
13. **One main unit per room** (the hall and the Sky Room: `g6.maths.equations`). *Cost:* the Great Altar's two-step counts
    for a one-step unit (it needs the same knowledge, combined).
14. **Teaching altars are not judged** (three in the hall). *Cost:* 8 events a hall, not 11.
15. **A freed altar with a refused move or over budget is recorded as HELPED** (MasteryRules' "right, but not the first
    time"), with a note saying why. *Cost:* the kind's name says "helped" for "not first time"; a fifth kind is a G0 change
    (§8).
16. **The Sky Room's frame line is teaching and S3 (the goal restated after 15 s) is not help; H16's hint is.** *Cost:*
    the frame ("gems pull them down") is a strong cue; the habit model is unaffected (the habit never adds).
17. **Phase B ships the Entrance Hall and the Sky Room**, so the gate can check all five tests. *Cost:* the other wings are
    designed, not built, until phase C.
18. **The temple is a place of its own in phase B**; phase C puts a floating island over the Academy. *Cost:* phase B's
    temple isn't seen from the child's world.
19. **Glimmers are freed, never caught or bought; each is seen before it is freed; no random rewards.** *Cost:* less
    surprise than a loot drop; that surprise is gambling-shaped, which EasyCraft refuses.
20. **Never timed, never lost** (no clocks; stopping keeps every Glimmer). *Cost:* no speed practice; fluency comes from
    many altars.
21. **Professor Hoot is the guide; from wing 7 he sometimes makes a wrong move on purpose** (an incorrect example the
    altar refuses). *Cost:* a child might copy it; he does it only after the child has shown the rule.
22. **The altar comes to the child** (the ring turns; in VR the child stands still). *Cost:* no free walking in the hall
    in phase B (phase D).
23. **In VR the twin move is two hands at once; one-handed play stays possible.** *Cost:* a two-hand rule in the altar's
    grip claimer (no change to `VrGrabber`).
24. **Music from the repo's public-domain and CC0 recordings** (Goldberg Aria, Ode to Joy, Spring, Gymnopédie, the repo's
    own Nachtmusik). *Cost:* none.
25. **The Mirror (EasyCraft's magic of reflection) is negation**: × (−1) on both pans, a reflection across zero. *Cost:*
    the world's Mirror is a building mode; here it is the same idea on the number line, said once in the Book.
26. **The swap seal is allowed only when a level twin altar shows a crystal alone on one pan**; stacking altars is the
    second route. *Cost:* two methods to teach; both are the standards' (8.EE.8b).
27. **Two crystal kinds at most** (blue x, rose y). *Cost:* none (8.EE.8 is two variables).
28. **The weighing altar's beam is locked until the lever** (G0's Make it rule). *Cost:* a child can't "feel" the weight
    while building; it is the price of honest first-time evidence.
29. **The altars' numbers come from the School's generators' forms and ranges.** *Cost:* the temple can't drift from the
    curriculum; a generator change changes the altars (a test keeps them aligned).
30. **The temple's state is a device file in phase B**, the profile in phase C (merged so nothing is lost). *Cost:* a new
    device starts an unlit temple in phase B.
31. **Each wing has one place its rooms share**; transfer rooms re-dress it. *Cost:* four places in all.
32. **Never scary**: no traps, no falls, nothing breaks for good; a sleeping Glimmer is never in danger. *Cost:* none.
33. **No real names in the game** (DragonBox, Hands-On Equations and the studies stay in this document). *Cost:* none.
34. **Making comes in phase D** (your own altar for a friend). *Cost:* constructionism waits for sharing.
35. **The model's rules are phase B's starting rules** (`model/altar_rules.py`), and the bots become tests. *Cost:* a
    little test time (the rules run headless in milliseconds).

---

## 8. Open questions for the lead

1. **The registry for a deep game with its own host**: the leaf's review decided a `host` field on a signature entry and
   a hook in PLAY. Does Balance Altar's phase B wait for the leaf's B2 to land it (my proposal: yes if B2 is within a
   session or two; else Balance Altar's B2 builds the same mechanism), or should the hook be a small lead task now?
2. **SkillShown's kind for "freed, but not the first time"**: HELPED with a note (my proposal, no G0 change), or a fifth
   kind (TRIED) that G0's `record` treats like HELPED?
3. **P1 in phase C**: the eleven units of §2.4 as their wings ship (my proposal); the integers units keep their own play
   (a future Frog Jump).
4. **The temple in the world**: a floating island over the Discovery Academy with a cloud stair (my proposal), or a door
   inside the Academy's Maths Workshop?
5. **The fade**: the grade sets the starting stage and play moves it (my proposal), or the grade alone?
6. **The Great Altar's two-step in the hall**: judged for `g6.maths.equations` (my proposal: it needs the same knowledge
   combined), or a preview that records nothing?
7. **When phase B starts** relative to the leaf's B2-B3 and Fraction Bakery's phase A (the cap of three agents).
8. **The Glimmers outside the temple** (phase D): little lights that follow the child in their world, or the temple's
   alone?
9. **The grown-ups' page** (phase C): the keeper's journal in plain words ("Tried one pan only twice in the first hall,
   never since; freed the Sky Room's balloons without help")?

---

## 9. The honesty table: what is real, what is simplified, what is fiction

| In the game | Real? | Note |
|---|---|---|
| A level altar is an equation; doing the same to both pans keeps it level | real | the properties of equality (6.EE.5-7) |
| The crystal's weight is one fixed number we don't know yet | real | a specific unknown [A8] |
| A breathing crystal takes many weights | real idea, magic look | a variable; equivalent expressions are equal for every value (6.EE.4) |
| Taking, putting and sharing on both pans | real | subtracting, adding and dividing both sides |
| The echo bell, the Mirror | real maths, magic look | multiplying both sides; × (−1) negates every term and turns an inequality's sign |
| The frozen crystal's chains hold the beam level | **fiction** | a real balance tips; held so the crystal can't be weighed (ruling 3) |
| Gems weigh +1, balloons lift 1 | **simplified** | a balloon's lift is a real upward force; a gem and a balloon "cancelling" and floating off is a model of a + (−a) = 0 |
| A floaty crystal (a negative weight) | **fiction** | stands for a negative number |
| Recipe boxes | real | a(b + c) = ab + ac as k equal compartments |
| The swap seal, stacking altars | real | substitution of equals; adding equations |
| The Star Floor | real | a system's solution is where the two graphs cross (8.EE.8a) |
| Crystal tiles | real | the area model (algebra tiles) |
| Gems in rows of five | real | grouping that lets a count be seen at a glance |
| Whole-number weights in the hall | **simplified** | 6.EE.7 includes non-negative rationals: half-gems at level 3, number gems in wing 7 |
| The rune line | real notation | from the letters stage, standard algebra |
| Glimmers, the Sky Temple, the balance spell, Hoot | **fiction** | EasyCraft's magic |

---

## 10. Sources

Learning-is-play's sources [G1]-[G9] (`docs/design/learning-is-play.md` §10) and the leaf's [R29]-[R30] are used as
they are. New here:

**Children's algebra: misconceptions and what fixes them**
- [A1] Knuth, E. J., Stephens, A. C., McNeil, N. M., & Alibali, M. W. (2006). Does understanding the equal sign matter?
  Evidence from solving equations. *Journal for Research in Mathematics Education*, 37(4), 297-312.
  https://www.nctm.org/Publications/journal-for-research-in-mathematics-education/2006/Vol37/Issue4/Does-Understanding-the-Equal-Sign-Matter_-Evidence-from-Solving-Equations/ ;
  full text https://labweb.education.wisc.edu/knuth/taar/papers_rep_pub/JRME2006.pdf
- [A2] Kieran, C. (1981). Concepts associated with the equality symbol. *Educational Studies in Mathematics*, 12,
  317-326 (as quoted in [A1]).
- [A3] Falkner, K. P., Levi, L., & Carpenter, T. P. (1999). Children's understanding of equality: a foundation for
  algebra. *Teaching Children Mathematics*, 6(4), 232-236. https://doi.org/10.5951/TCM.6.4.0232
- [A4] Alibali, M. W., Knuth, E. J., Hattikudur, S., McNeil, N. M., & Stephens, A. C. (2007). A longitudinal examination
  of middle school students' understanding of the equal sign and equivalent equations. *Mathematical Thinking and
  Learning*, 9(3), 221-247. https://mathed.net/wiki/Alibali,_Knuth,_Hattikudur,_McNeil,_%26_Stephens_(2007)
- [A5] Herscovics, N., & Linchevski, L. (1994). A cognitive gap between arithmetic and algebra. *Educational Studies in
  Mathematics*, 27(1), 59-78. https://link.springer.com/doi/10.1007/BF01284528
- [A6] Filloy, E., & Rojano, T. (1989). Solving equations: the transition from arithmetic to algebra. *For the Learning
  of Mathematics*, 9(2), 19-25. https://flm-journal.org/Articles/3DA2C5DE336DFD448BCF339B51168E.pdf
- [A7] Vlassis, J. (2001). Solving equations with negatives or crossing the formalizing gap. *Proceedings of PME 25*,
  vol. 3, 375-382. https://orbilu.uni.lu/handle/10993/12890
- [A8] Küchemann, D. (1978). Children's understanding of numerical variables. *Mathematics in School*, 7(4), 23-26 (the
  CSMS algebra test, 3,000 13-15-year-olds; see also Küchemann 1981 in Hart (Ed.), *Children's Understanding of
  Mathematics: 11-16*). https://faculty.weber.edu/eamsel/Research%20Groups/Math%20Research/Kuchemann%20(1978).pdf
- [A9] Clement, J. (1982). Algebra word problem solutions: thought processes underlying a common misconception. *Journal
  for Research in Mathematics Education*, 13(1), 16-30; Clement, Lochhead & Monk (1981), Translation difficulties in
  learning mathematics, *American Mathematical Monthly*, 88. As reported:
  https://www.math.purdue.edu/~rhkenney/Kenney_Homepage/Links_to_Publications_files/PMENA_2013_Poetic_Final.pdf
- [A10] MacGregor, M., & Stacey, K. (1997). Students' understanding of algebraic notation: 11-15. *Educational Studies in
  Mathematics*, 33(1), 1-19. https://doi.org/10.1023/A:1002970913563
- [A11] How students learn mathematics: misconceptions in algebra (grade 7 students in Singapore; Matz's error list:
  distributive, cancellation and associative errors the most common). https://repository.nie.edu.sg/handle/10497/1225
- [A12] Tsamir, P., & Almog, N. (2001). Students' strategies and difficulties: the case of algebraic inequalities.
  *International Journal of Mathematical Education in Science and Technology*, 32(4), 513-524.
  https://cris.tau.ac.il/en/publications/students-strategies-and-difficulties-the-case-of-algebraic-inequa/
- [A13] Blanco, L. J., & Garrote, M. (2007). Difficulties in learning inequalities in students of the first year of
  pre-university education in Spain. *Eurasia Journal of Mathematics, Science and Technology Education*, 3(3), 221-229.
  https://www.ejmste.com/article/difficulties-in-learning-inequalitiesin-students-of-the-first-year-ofpre-university-education-in-4070

**The balance model**
- [B1] Otten, M., van den Heuvel-Panhuizen, M., & Veldhuis, M. (2019). The balance model for teaching linear equations: a
  systematic literature review. *International Journal of STEM Education*, 6, 30. https://doi.org/10.1186/s40594-019-0183-2
- [B2] Vlassis, J. (2002). The balance model: hindrance or support for the solving of linear equations with one unknown.
  *Educational Studies in Mathematics*, 49, 341-359. https://doi.org/10.1023/A:1020229023965
- [B3] Otten, M., van den Heuvel-Panhuizen, M., Veldhuis, M., Heinze, A., & Goldenberg, P. (2019). Developing algebraic
  reasoning in primary school using a hanging mobile as a learning supportive tool. *Infancia y Aprendizaje*, 42(3).
  https://www.leibniz-ipn.de/en/research/publications/developing-algebraic-reasoning-in-primary-school-using-a-hanging-mobile-as-a-learning-supportive-tool
- [B4] Suh, J., & Moyer, P. S. (2007). Developing students' representational fluency using virtual and physical algebra
  balances. *Journal of Computers in Mathematics and Science Teaching*, 26(2), 155-173.
  https://mason.gmu.edu/~jsuh4/tenure/part4thru8/papers/J.Computingmathscience%20teaching.representational.pdf

**Learning: fading, manipulatives, examples, gesture, perception**
- [C1] Fyfe, E. R., McNeil, N. M., Son, J. Y., & Goldstone, R. L. (2014). Concreteness fading in mathematics and science
  instruction: a systematic review. *Educational Psychology Review*, 26, 9-25. https://doi.org/10.1007/s10648-014-9249-3
- [C2] Kaminski, J. A., Sloutsky, V. M., & Heckler, A. F. (2008). The advantage of abstract examples in learning math.
  *Science*, 320, 454-455. https://news.osu.edu/concrete-examples-dont-help-students-learn-math-study-finds/
- [C3] Carbonneau, K. J., Marley, S. C., & Selig, J. P. (2013). A meta-analysis of the efficacy of teaching mathematics
  with concrete manipulatives. *Journal of Educational Psychology*, 105(2), 380-400. https://www.proquest.com/docview/1413417538
- [C4] Ottmar, E., Landy, D., Goldstone, R. L., & Weitnauer, E. (2015). Getting from here to there!: testing the
  effectiveness of an interactive mathematics intervention embedding perceptual learning. *Proceedings of the Cognitive
  Science Society*. https://pc.cogs.indiana.edu/?p=1101
- [C5] Sweller, J., & Cooper, G. A. (1985). The use of worked examples as a substitute for problem solving in learning
  algebra. *Cognition and Instruction*, 2(1), 59-89. https://en.wikipedia.org/wiki/Worked-example_effect
- [C6] Booth, J. L., Lange, K. E., Koedinger, K. R., & Newton, K. J. (2013). Using example problems to improve student
  learning in algebra: differentiating between correct and incorrect examples. *Learning and Instruction*, 25, 24-34;
  AlgebraByExample's randomized studies: https://serpinstitute.org/algebra-by-example/research
- [C7] Cook, S. W., Mitchell, Z., & Goldin-Meadow, S. (2008). Gesturing makes learning last. *Cognition*, 106(2),
  1047-1058. https://pmc.ncbi.nlm.nih.gov/articles/PMC2265003
- [C8] Kellman, P. J., Massey, C. M., & Son, J. Y. (2010). Perceptual learning modules in mathematics: enhancing
  students' pattern recognition, structure extraction, and fluency. *Topics in Cognitive Science*, 2(2), 285-305.
  https://pmc.ncbi.nlm.nih.gov/articles/PMC6124488
- [C9] Bufford, C. A., Mettler, E., Geller, E. H., & Kellman, P. J. (2014). The psychophysics of algebra expertise:
  mathematics perceptual learning interventions produce durable encoding changes.
  https://kellmanlab.psych.ucla.edu/files/bufford_mettler_geller_kellman_2014.pdf
- [C10] Kirshner, D., & Awtry, T. (2004). Visual salience of algebraic transformations. *Journal for Research in
  Mathematics Education*, 35(4), 224-257.
  https://www.nctm.org/Publications/journal-for-research-in-mathematics-education/2004/Vol35/Issue4/Visual-Salience-of-Algebraic-Transformations/

**Games and apps**
- [G1] DragonBox, how it plays (the box, the creature cards, night and day cards, additions mirrored on both trays, the
  fade to symbols, three stars a level): GeekDad (2012) https://geekdad.com/2012/06/dragonbox/ ; the company's story:
  https://dragonbox.com/about/our-story
- [G2] The Washington State Algebra Challenge (2013), self-reported, no control group:
  https://dragonbox.com/about/algebra-challenge ; https://news.cs.washington.edu/?p=10336
- [G3] Long, Y., & Aleven, V. (2017). Educational game and intelligent tutoring system: a classroom study and comparative
  design analysis. *ACM Transactions on Computer-Human Interaction*, 24(3), 20. https://doi.org/10.1145/3057889
- [G4] Carnegie Mellon University (2014), "Fun and Games", on the DragonBox and tutor study:
  https://www.cmu.edu/homepage/computing/2014/spring/fun-and-games.shtml
- [G5] Decker-Woodrow, L. E., Mason, C. A., Lee, J.-E., Chan, J. Y.-C., Sales, A., Liu, A., & Tu, S. (2023). The impacts
  of three educational technologies on algebraic understanding in the context of COVID-19. *AERA Open*, 9.
  https://doi.org/10.1177/23328584231165919
- [G6] Bernier, J., Heyer, N., Su, M., Yan, L., Ha, J., Islam, R., Jordan, M., & Nelson, B. (2026). A design-based
  approach to playful algebra learning with DragonBox Algebra. *Digital Experiences in Mathematics Education*, 12(2),
  416-450. https://researchwith.montclair.edu/en/publications/a-design-based-approach-to-playful-algebra-learning-with-dragonbo/
- [G7] Algebra Touch (Regular Berry Software): Common Sense Media's review
  https://www.commonsensemedia.org/app-reviews/algebra-touch ; Friedrich Verlag, "Ein Wisch zur Algebra"
  https://www.friedrich-verlag.de/mathematik/algebra/ein-wisch-zur-algebra-76
- [G8] From Here to There! (Graspable Math), the IES efficacy project:
  https://ies.ed.gov/use-work/awards/efficacy-here-there-dynamic-technology-improving-algebraic-understanding
- [G9] Algebra Balance (Ventura Educational Systems): blocks positive, balloons negative. https://apps.apple.com/app/id908720476
- [G10] The hot-air-balloon model for integers (Texas Instruments): https://education.ti.com/en/activity/detail/hot-air-balloon_1
- [G11] Hands-On Equations (H. Borenson): Borenson's 2007 presentation to the National Mathematics Advisory Panel
  https://corpora.tika.apache.org/base/docs/govdocs1/590/590177.pdf ; a summary of the evidence
  https://educatingalllearners.org/resources/hands-on-equations-balance-model-enhances-algebraic-equation-solving-in-upper-elementary-and-middle-school-students
- [G12] Algebra tiles and quadratic equations, a quasi-experiment with Form Four students (Malaysia, 2025):
  https://ejournal.upsi.edu.my/index.php/EJSMT/article/view/11355
- [G13] SolveMe Mobiles (Education Development Center; NSF 1135173): https://resourcecenters2015.videohall.com/presentations/580
- [G14] Pane, J. F., Griffin, B. A., McCaffrey, D. F., & Karam, R. (2014). Effectiveness of Cognitive Tutor Algebra I at
  scale. *Educational Evaluation and Policy Analysis*, 36(2), 127-144. https://ies.ed.gov/ncee/WWC/study/82098 ; the
  year-two result: https://www.edweek.org/education/study-hybrid-algebra-program-nearly-doubled-math-learning/2013/06
- [G15] Bai, H., Pan, W., Hirumi, A., & Kebritchi, M. (2012). Assessing the effectiveness of a 3-D instructional game on
  improving mathematics achievement and motivation of middle school students. *British Journal of Educational
  Technology*, 43(6) (DimensionM, 437 8th graders).
- [G16] Kebritchi, M., Hirumi, A., & Bai, H. (2010). The effects of modern mathematics computer games on mathematics
  achievement and class motivation. *Computers & Education*, 55(2), 427-443. https://stars.library.ucf.edu/scopus2010/616
- [G17] Lure of the Labyrinth (MIT Education Arcade): https://education.mit.edu/project/lure-of-the-labyrinth/ ; the
  study: https://www.irma-international.org/viewtitle/74217/
- [G18] Pope, H., & Mangram, C. (2015). Wuzzit Trouble: the influence of a digital math game on student number sense.
  *International Journal of Serious Games*, 2(4). https://journal.seriousgamessociety.org/index.php/IJSG/article/view/88
- [G19] The Witness (Thekla, 2016): https://en.wikipedia.org/wiki/The_Witness_(2016_video_game) ; on teaching by its
  puzzles' order: https://felixonline.co.uk/articles/2016-2-12-the-witness/
- [G20] WestEd's study of Prisms VR in Algebra 1 (2022-23; 514 students, 21 teachers), as reported:
  https://govtech.com/education/k-12/study-finds-ohio-math-scores-improved-with-vr-gamification

**The standards**
- [S1] Common Core 5.OA: https://www.thecorestandards.org/Math/Content/5/OA/ · [S2] 6.EE:
  https://www.thecorestandards.org/Math/Content/6/EE/ · [S3] 7.EE: https://www.thecorestandards.org/Math/Content/7/EE/ ·
  [S4] 8.EE: https://www.thecorestandards.org/Math/Content/8/EE/

## The lead's review (2026-10-18 05:30): phase A passes; the open questions decided
**Verdict: approved for phase B.** The verb (keep the balance: the same off, on or shared on both pans; the altar
refuses anything else) is how equations are solved; the models did their job and changed the design (the chained beam:
a free beam let weighing win every visit; one-move altars freed in one move; the Sky Room's two-move finale: guessing
from 1 % to 0.2 %); the transfer rooms make each half-habit fail every time; nothing is read but the carved equation,
which Hoot reads and each symbol names when touched; the fade from pictures to symbols is DragonBox's route with the
evidence stated honestly. The owner sees `balance-altar-owner.md` and can stop or change it at any point.
1. **The registry hook for a game with its own host:** built once, by Inside a Leaf's B2 (the design's §4.7 there);
   Balance Altar's phase B adopts it when it merges (its estimate: 5 sessions).
2. **"Freed, but not the first time":** HELPED with a note; SkillShown keeps its four kinds.
3. **P1:** a unit becomes P1 when its wing teaches all of it; until then it stays P0.
4. **Where the temple lives:** both: a floating island above the Discovery Academy (seen in the sky from the spawn: a
   wow), opened by the Academy's Maths door (W1's `AcademyPlaza.opens()`).
5. **The symbol stage:** the child's play moves it (mastery shown), starting from the grade's stage.
6. **The hall's two-move finale:** counts for the one-step unit as NEW_SETTING evidence (transfer), not as its first star.
7. **When:** phase B after the leaf's B2 has merged its host hook (about two sessions from now); its brief then.
8. **The Glimmers in the world:** phase D (a reward that follows the child; never a pet to feed or a timer).
9. **The grown-ups' page:** phase C, the plain-words journal, as Inside a Leaf's.
