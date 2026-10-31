# Fraction Bakery — the design (phase A)

The third future lesson (owner #133, #134; `docs/design/future-lessons.md` §5, wave 1). This is **phase A**: the research
and the design, reviewed by the lead (and shown to the owner as `fraction-bakery-owner.md`) before any code. The brief:
`docs/superpowers/plans/2026-10-18-game-fraction-bakery-brief.md`. Pictures: `docs/design/games/fraction-bakery/` (drawn
by `make_pictures.py`). The models: `docs/design/games/fraction-bakery/model/`. Notes on how this was made:
`docs/devlog/parts/game-bakery-a.md`. Written 2026-10-18 on the worktree branch `worktree-agent-aa69169ab842fa870` (cut
from lead-merge at `1771f0ba`, the brief).

The owner, 2026-10-17, after watching their child play for half an hour and meet no learning: "noone will start reading
and learning the lessons when playing game … we need future lessons, not just texts with visuals like slides". Fractions
are where that bar bites hardest: they are the topic children fail most, and the classroom answer is a picture of a
shaded pie and a question to read. So the question this design answers is not "how do we show fractions in a game" but
"what would a child of 8 to 12 do with their hands, by choice, that *is* a fraction, and that only someone who knows what a
fraction is can win".

---

## 0. In one page

**The fantasy.** At the edge of the child's world stands the **Starlight Bakery**, a little round bakery that opens when
the sun goes down. Its chimney puffs star-shaped smoke; its window looks onto a lane of cottages where the village's
living buddies (EasyCraft's block buddies with googly eyes) live. The child is the **night baker**: everything the
village eats at breakfast is baked tonight, and every buddy wants its fair share. A buddy fed fairly does a happy hop and
the lantern in its cottage window lights; a night's last order is the **Feast**, a long table in the lane where the whole
village shares the pies; at dawn the bakery's sign earns a star. Each school year a new part of the bakery opens.

**The verb that is the concept.** *Cut it fair.* The **Fair Knife** cuts only equal pieces: the child sets how many (a
row of 12 dot-lights on its blade; in VR a twist of the handle, one click a piece), slices, and gives the pieces out. **The
number of pieces is the bottom number; the pieces given are the top number.** A table of buddies to feed (two pies, five
buddies) is fractions as sharing; a takeaway box (a buddy's thought bubble: a pie in six parts, five glowing) is a/b of a
whole. Every order is then handed over on the **Fair Line**, the counter's brass rail, one whole pie from post to post: the
box (or each plate) slides along it piece by piece and stops at its amount, and the buddy's flag pops up where it should
have stopped. **Every order lands on the number line**, which the research names as the representation that matters most
(Siegler's integrated theory, §2.2). Each rung adds the tool its idea needs: the leftover shelf (equivalence), tins whose
moulded sections take only one size of piece (common denominators: the move that makes adding possible), the cupcake tray
(a fraction of a set), loaves along the rail (the number line itself), the Size Oven (EasyCraft's Size Magic: multiplying
by a fraction scales a cake), measuring scoops (division: how many fit), the Hundred Tray (decimals and percents as other
names for the same share), the recipe book (ratios).

**The five tests** (the models' numbers: 1,000 seeded visits per player, §3.9).

| Test | This game's answer | Checked in phase B by |
|---|---|---|
| Choice | A cosy night bakery to run, a village that lights up because of you, buddies who hop when fed; short orders (20-50 s), nights of 6 minutes; in VR a knife in your hand and a box you shove along the counter; later, your own orders and recipes for a friend | The owner's child: do they start Midnight unasked, and come back another day? |
| Mute | Nothing to read: a table of buddies *is* a sharing order; a box order is a picture in a thought bubble; the knife's dots, the pieces, the rail and its flag carry everything; Hoot says each order aloud in words; numerals come only where reading them is the skill (from grade 4's stage), and are read aloud too | A test that no words show while an order plays (numerals only at stage 2+); the owner's child plays with text hidden |
| Cheat | Random cuts, trial and error, halving only, cutting everything small and dealing, turning n/p round and "one piece each" all fail: Opening Night's bar (7 of 8 orders right first time) is reached by **100 %** of visits that know what a fraction is (88.0 % with slips on 4 % of decisions) and by **0-2.6 %** of every player without it | Bots in the tests (the models' players, thresholds as tests) |
| Transfer | Every rung has rooms where the old habit fails and the idea wins. Phase B ships **Midnight Leftovers**: the oven sleeps, only already-cut pieces remain; Opening Night's habit ("the top number is how many pieces I give") and whole-number bias ("an eighth is bigger than a quarter, 8 > 4") reach the bar in **0 %** of visits, the idea ("a/b is a parts of size 1/b") in **100 %** (97.6 % with slips). Later: the Night Market (the same fraction of a bigger cake is more), the Queue, mixed tins, the Size Oven, the scoops, the Hundred Tray, the recipe book: each named misconception 0 % (§3.9) | Phase B: the habit bot never wins Midnight, the idea bot always; a child solves it unhelped |
| Wow | The bakery at dusk with star smoke; a pie falling apart into perfectly equal pieces with a sparkle and a "ting"; a box ticking along the brass rail and stopping exactly at the flag; the lane's lanterns lighting one by one; the Feast's long table under the stars; in VR, the knife twisting in your hand and the slice through the pie | The owner's verdict; whether the child shows it to someone |

**The ladder (grades 3-6)**: rung 3 *The Pie Shop* (cutting, sharing, a/b of a whole, the line, equivalence, adding the
same size, a fraction of a set), rung 4 *The Cake Kitchen* (re-cutting for equivalence, comparing any two, mixed numbers,
repeat orders: whole × fraction, tenths and hundredths), rung 5 *The Big Oven* (mixed tins: unlike denominators, the
Great Feast: fractions as division, half of a half: multiplying, the Size Oven: scaling, scoops: dividing with unit
fractions, the Hundred Tray: percent), rung 6 *The Recipe Book* (servings: dividing fractions, recipes: ratios and
ratio tables, the sale jar: percent of and the whole from a part). The same order card fades from a picture to a picture
with its numeral to the numeral alone to symbols (concreteness fading). It covers the strand's sixteen units (§2.4) and
makes each P1 when its rung ships.

**Minute 1:** dusk, the bakery's warm window, Hoot in a baker's hat; four buddies at the table and one pie; the ghost sets
the knife to four and slices; you deal; the plates glide along the rail and stop side by side; a lantern lights.
**Minute 5:** a jelly buddy wants five sixths: six dots, slice, five pieces in the box, a push: five ticks, the flag right
there; nine lanterns lit. **Minute 30:** Opening Night and the Feast, Midnight Leftovers (the old habit stopped short, then
six eighths filled three quarters), dawn, the Baguette Counter (five quarters past post one) and the Leftover Shelf.

**Phase B** (the vertical slice): Opening Night and Midnight Leftovers, flat and VR, complete and beautiful. Estimate:
**6 agent sessions** (5 if Inside a Leaf's phase B2 has landed the registry hook for deep games, §4.7). The open
questions for the lead are in §8.

---

## 1. The bar this game must clear

From `future-lessons.md` §2 (the authority): a future lesson is a game a child chooses to play, where the knowledge is
the only way to win, nothing has to be read, and the game knows what the child learned from how they play. Five tests
(choice, mute, cheat, transfer, wow), four gated phases. From `learning-is-play.md` §3: the concept is the mechanic, play
first and words after, the world answers, shown when stuck, short and again, in the world and for the world, words as
tools. Rule 0 (owner #133): a child never has to read. EasyCraft's own rules apply too: calm, kind, never scary, no
gambling, no pressure tricks (no FOMO, no streaks, no character made sad to make a child play), English only, nothing
personal kept or sent, flat and VR, the phones' budget.

Three things are special about fractions:
1. **The symbol lies.** "3/4" looks like two whole numbers, and everything a child knows about whole numbers (bigger
   numbers mean more; add the parts) is wrong for it. Most fraction errors are whole-number habits applied to fractions
   (§2.1). A future lesson must make the *amount* visible every time, so the habit meets the world and loses.
2. **One idea, many faces.** A fraction is a part of a whole, a share (3 ÷ 4), a point on a line, a measure, a scale
   factor and a ratio (the faces our own units teach, §2.4). A game that teaches only one face (pies)
   leaves the child unable to place 3/4 on a line or see it as 3 ÷ 4. The bakery has a face for each, all made with the
   same knife and judged on the same line.
3. **It decides what comes after.** Fifth graders' knowledge of fractions and division predicts their algebra and
   overall maths in high school, five or six years later, even after controlling for IQ, family income and education,
   reading, working memory and whole-number arithmetic (US and UK longitudinal data, §2.2 [F2]); the National Mathematics
   Advisory Panel called children's difficulty with fractions "pervasive" and "a major obstacle" to algebra [F26].
   Balance Altar's algebra stands on this strand.

---

## 2. Research

### 2.1 What children of 8-12 get wrong about fractions, and what fixes it

| What children think or do | Who, how often | Why it sticks | What fixes it (the research) | How this game fixes it |
|---|---|---|---|---|
| **Whole-number bias: a bigger bottom number means a bigger fraction** ("1/8 is bigger than 1/6 because 8 is bigger than 6") | Named and reviewed by Ni & Zhou [F5]; reported in Moss's classrooms [F9]; even in 6th and 8th grade, comparing 3/5 with other fractions was right only **69 %** and **75 %** of the time (low achievers **63 %**) [F3] | Years of whole numbers where more is bigger; the symbol shows two whole numbers | Treat every fraction as a magnitude on the number line (the integrated theory [F1]); number-line training transferred to magnitude comparison where area-model training did not [F12][F13] | **Every order slides along the Fair Line**: an eighth's step is visibly half a quarter's. Midnight's make-it-fair orders and the Queue (4.2) make the bias put the extra piece on the wrong plate or the buddies in the wrong order: the model's biased player **0 %** (§3.9) |
| **A fraction as two separate numbers** (the "independent whole numbers" strategy: 3/5 + 1/4 = 4/9) | **14 %** of all trials of 60 6th and 60 8th graders; **25 %** in 6th grade; **32 %** of low achievers' problems [F3]. Most 4th and 6th graders taught traditionally answered 1/2 + 1/3 = 2/5 [F9]. On a NAEP item (estimate 12/13 + 7/8 from 1, 2, 19, 21) **24 %** of 13-year-olds chose 2, **28 %** 19 and **27 %** 21 [F7] | The notation invites it; procedures learnt without magnitudes | Magnitude knowledge predicts fraction arithmetic [F1][F3]; "help students understand why procedures make sense" (the IES guide, moderate evidence [F6]) | **Tins take only one size of piece**: a half and a third go into one tin only when both are re-cut into sixths. The "add the tops and bottoms" tin (fifths) fits neither piece: the model's player **0 %**. On the Fair Line a sum is lengths end to end, so 1/2 + 1/3 visibly passes 1/2 |
| **"Equal parts" ignored**: any shape with three parts is called thirds | A recognised misconception ("number of parts only") in teachers' guides [F16][F17]; counting shaded and total parts works in textbook pictures, so counting replaces measuring [F18] | Fraction teaching often reduces to counting pieces [F18] | Begin with equal sharing, which children already understand (the IES guide's first recommendation [F6]; Empson [F10]); the measurement view [F8] | **The Fair Knife cuts only equal pieces, and fairness is the goal**: a table is fed only when every plate stops at the same mark. Midnight's pieces of a different size break "count the pieces": the habit **0 %** |
| **Fractions have no felt size**; the number line is weak | 6th graders' number-line estimates were off by **22 %**, 8th graders' by **17 %**; 0-5 lines were harder than 0-1 lines (**23 %** vs **16 %** off) [F3]. Across 263 effects and 10,576 children, number-line estimation correlates with maths achievement at **r = .44**, higher for fractions (**r = .52**) [F4]. Fifth-grade fraction and division knowledge predicts high-school algebra [F2] | Pies and shaded pictures teach part-of-a-shape, not how big | Number lines (the IES guide's second recommendation, moderate evidence [F6]); Fraction Face-Off's measurement interpretation, whose effect on released NAEP items was carried by it [F8] | **The Fair Line judges every order**; the Baguette Counter (3.2) lays two loaves on a 0-2 rail, so "the line's end is one" (Siegler & Pyke's 0-5 error) and "a fraction is less than one" both fail: **0 %** |
| **Multiplying makes bigger, dividing makes smaller** | Primitive models: multiplication as repeated addition, division as sharing a bigger number [F14] (confirmed with 902 7th graders in 2022 [F14]); preservice teachers, middle schoolers and university students lack the direction of effects for fractions [F15]; accuracy on fraction division **20 %**, multiplication **48 %** [F3] | Every whole-number product was bigger | Models that show why (IES rec. 3 [F6]); scaling (5.NF.5) and "how many fit" division | **The Size Oven** bakes three cakes at once and the child shelves each where it will fit after baking (×3/4 shrinks); **the Scoops** set out the moulds before pouring (6 ÷ 3/4 = 8). "Multiplying always makes bigger" and "division makes smaller" **0 %** |
| **The wrong operation's rule** (3/5 × 4/5 = 12/5: keeping the denominator when multiplying) | **26 %** of all trials, most of them on multiplication and division [F3]; **75 %** of traditionally taught 4th and 6th graders answered 1/2 × 1/8 = 1/4 [F9] | Rules learnt as symbol shuffles | Area models and "a fraction of a fraction" with meaning (IES rec. 3) | **Half of a Half** (5.3): the knife cuts a piece again and the child takes part of it; the tray cut both ways shows 2/3 × 3/4 as the part shaded twice |
| **Halving is easy, thirds are not** | Young children's partitioning starts from halving and halving again [F11] | Halves, quarters and eighths come by repeated halving; thirds and fifths need a plan | Equal sharing with 3, 5, 6 sharers (Empson [F10]) | **Opening Night seats tables of 3, 5, 6 and 8 and boxes in thirds, fifths and sixths**: the model's always-halve player reaches the bar in **0 %** of visits (12.3 % in the first draft) |
| **Decimals: longer is larger** (0.405 > 0.45), **shorter is larger** (0.4 > 0.45) | 3,204 Australian students in Years 4-10: longer-is-larger about **74 %** in Year 4, **33 %** in Year 6, **17 %** in Year 7; shorter-is-larger **10-15 %** at every age; only about **70 %** expert by Year 10 [F19]. A majority of middle schoolers said 0.059 > 0.2; **68 %** of 6th graders said 4 + .3 = .7; more than half of 6th and 8th graders said 1/8 = 0.8 [F9] | Digits after the point read as a whole number | Decimals as tenths and hundredths of a measure; Moss & Case's percent-first curriculum in linear measures [F20][F9]; a misconception-targeted decimal game beat a conventional tutor [G8] | **The Hundred Tray** (4.5, 5.6): 0.3 is three rows, 0.45 four rows and five squares; every decimal queue hides 0.4, 0.405, 0.45. Both misconceptions **0 %** |
| **Ratio as adding the same amount** (Mr Short is 6 clips, so Mr Tall, 2 buttons taller, is 8: not 9) | Karplus's classic task [F21]; in 704 students aged 11-16, the most frequent wrong strategies were comparing first terms and additive comparisons [F22] | Additive thinking works for differences | Conceptual strategies (ratio tables) before cross-multiplication (IES rec. 4, minimal evidence [F6]) | **The Recipe Book** (6.2): the dough comes out right only in the recipe's ratio; "add the same amount" (6 to 5 for 2 to 1, tripled) makes a flat cake: **0 %** |
| **Dividend and divisor swapped** (8 ÷ 3 = 3/8) | A written claim in our own unit (`g5.maths.fractions_as_division`); no prevalence figure found | Division read left to right as "the small over the big" | Equal sharing, where the share is visible [F10] | Tables of n pies for p buddies: the model's swapping player **0 %** |
| **The whole forgotten**: 1/2 is always more than 1/3 | The standard's own caveat ("comparisons are valid only when the two fractions refer to the same whole", 4.NF.2 [S2]); no prevalence figure found | Fractions taught with one size of pie | Wholes of different sizes, on purpose | **The Night Market** (4.T1): half of a small cake against a third of a cake twice its size; "the same fraction" habit **0 %** |

**What we take from this:** (1) the amount must be visible every time, on a line, so that whole-number habits meet the
world; (2) equal sharing is the way in: children already know what fair means; (3) every operation needs a reason a child
can see (pieces that fit a tin only at one size, a cake that shrinks in the Size Oven, moulds that fill or don't); (4)
the habits that work only for easy cases (halving, counting pieces, the bigger bottom number) must meet orders where they
fail; (5) decimals, percents and ratios are the same idea with other names, so they belong in the same bakery.

### 2.2 What makes it stick: the evidence for the method

| Finding | Source | What we take |
|---|---|---|
| **The integrated theory**: fractions extend the number system; what whole numbers and fractions share is magnitude. In 11- and 13-year-olds, fraction magnitude knowledge tracked fraction arithmetic and maths achievement, and explained achievement beyond fraction arithmetic | Siegler, Thompson & Schneider 2011 [F1] | The Fair Line: every order is a magnitude on a line |
| Fifth-grade fraction and division knowledge uniquely predicted high-school algebra and overall maths 5-6 years later (US and UK national longitudinal data), controlling for IQ, reading, working memory, family income and education, and whole-number arithmetic; it is prediction, not proof of cause | Siegler et al. 2012 [F2] | The strand is worth weeks of agent work |
| Lower achievers' fraction arithmetic stayed the same from 6th to 8th grade while higher achievers improved; magnitude knowledge and whole-number division predicted it | Siegler & Pyke 2013 [F3] | The gap opens early: grade 3's rung must be excellent |
| The IES practice guide's five recommendations: (1) build on informal sharing and proportionality (**minimal** evidence), (2) fractions are numbers, the number line (**moderate**), (3) why procedures make sense (**moderate**), (4) ratio, rate and proportion strategies before cross-multiplication (**minimal**), (5) teachers' knowledge (**minimal**) | Siegler et al. 2010 [F6] | Sharing tables first; the line always; tins, scoops and the oven as the reasons; ratio tables in the recipe book |
| **Fraction Face-Off!**: 36 thirty-minute lessons over 12 weeks for at-risk 4th graders: the 0-1 number line, fair shares and part-whole; developer-run randomized trials: an effect of 0.39 in one (213 students; both intervention groups beat the control on understanding and calculations), and 0.64 listed for a review of five trials (its summary does not say which trial the figure covers); in the 2016 trial the effect on released NAEP items was carried by the gain in the measurement interpretation | Fuchs et al. [F8]; Blueprints rates it "Promising" and notes the developer ran the studies [F8] | The measurement view as the spine: pieces are lengths on the Fair Line |
| Number-line training (2nd-3rd graders) transferred to an untrained fraction magnitude comparison; area-model training improved only its own task | Hamdan & Gunderson 2017 [F12] | The line, not only pies |
| 148 2nd-3rd graders, four 15-minute trainings: a (hybrid) one-dimensional number line beat a square area model and a square number line on magnitude comparison | Gunderson et al. 2019 [F13] | The Fair Line is one-dimensional: a thin rail, posts, no area |
| **The Rational Number Project**: over 1,600 4th-5th graders in 66 classrooms randomly assigned for 28-30 days; RNP (several physical models, fraction circles among them, and moving between pictures, objects, words and symbols) beat commercial curricula on the posttest, retention and four of six subscales (concepts, order, transfer, estimation); RNP children reasoned from mental images of size | Cramer, Post & delMas 2002 [F23] | Area models are not bad: pies help when they build an image of *size*. So pies for sharing and parts, the line for every judgement, and the same pieces in both |
| **Percent first**: 4th graders began with percent in linear measures (pipes, beakers, number-line "sidewalks"), halving as the strategy, then decimals, then fractions (the 1999 study: 16 experimental 4th graders, 13 matched controls); Moss's later account reports that the experimental children improved significantly and often scored above older children taught conventionally | Moss & Case 1999 [F20]; Moss 2005 [F9] | The Hundred Tray and the jar as measures; percents and decimals as names for the same share |
| Equal sharing in a first-grade classroom grew fraction concepts; 1st-5th graders' informal sharing strategies show multiplicative reasoning | Empson 1999 [F10]; Empson et al. 2006 [F10] | Tables of buddies are the entry, from minute 1 |
| Trying a problem before instruction beats instruction first for understanding | LP [G4] | Midnight's first box is tried before Hoot says a word |
| Novices need guidance; a demonstration first | LP [G7]; BA [C5] | The ghost shows the knife once, then "Your turn!" |
| Concreteness fading: concrete, then explicitly faded to the abstract; generic symbols transferred better than concrete ones alone | BA [C1], [C2] | The fade on the order cards (picture 10) |
| Studying incorrect examples beside correct ones did **not** help 342 4th-5th graders more than correct ones alone on decimal magnitude, and about 36 % stayed confident in their errors | Durkin & Rittle-Johnson 2012 [F24] | Hoot's deliberate wrong cuts (rung 5+) are a seasoning, never the method; the habit must fail in the world, not be shown failing |
| A two-hand ratio trainer: the screen turns green only when the hands' heights keep a ratio; children talk their way from the movement to proportion | Abrahamson (the Mathematical Imagery Trainer) [F25] | VR's two-hand pour in the recipe book (a warm-up, not judged) |
| A two-hand gesture made learning last (85 % kept vs 33 %) | BA [C7] | VR: one hand holds the board, the other slices; two hands pour |
| Intrinsic integration: children chose the integrated game seven times longer | LP [G3] | The cut is the denominator; nothing is beside the play |

### 2.3 Games and apps that teach fractions: what works, what fails, and why

| Game or study | What it is | Worked? | Why | What we take |
|---|---|---|---|---|
| **Slice Fractions** 1 and 2 (Ululab, 2014) [G1] | Slice ice and lava blocks to drop the right amount to a mammoth; wordless | **Partly evidenced.** Cyr et al.: Canadian 3rd graders (8-9) learned as much as with teacher-led teaching on TIMSS fraction items, with some transfer (a conference paper; sample not reported on the page); the developer says +10.5 % after three hours (self-reported); no independent replication found | Cutting is the verb; wordless levels | Cutting as the move; we add the denominator as a chosen number and the line as the judge |
| **Motion Math** [G2] | Tilt the device to drop a falling star onto a number line at a fraction | **Vendor-commissioned controlled study**: 122 5th graders, 20 minutes a day for five days: fractions test +15 % against a control, liking and self-efficacy +10 %; run by an independent researcher but commissioned and co-funded by the maker | Number-line placement as the play; short daily sessions | The line as the judge of every order; short orders |
| **Refraction** (University of Washington, Center for Game Science) [G3] | Split laser beams into fractions to power ships and free animals | **Big data, thin learning evidence.** Huge online A/B studies; "brain points" for effort and strategy kept more low performers playing (about 15,000 children), and random points did not (about 25,000); children made more fraction-creation mistakes than adult players; a learning-analytics project studied 3,000 third graders' play | Splitting as the move; praise effort and strategy, not speed | Hoot praises strategy and effort, never speed; nothing is timed |
| **Treefrog Treasure** (the same centre) [G4] | Jump onto the number line at a fraction to collect gems | No learning study found | — | — |
| **Battleship Numberline** [G5] | Estimate positions on a number line to hit ships | Randomized design experiments over 8 million estimates from hundreds of thousands of players; the designer: "the harder something is for kids, the more they fail, and the less time they want to spend doing it" | Challenge tuned for engagement | Opening Night is winnable: the first judged orders are easy; difficulty rises by rung, not by failing |
| **Semideus / Number Navigation Game** [G6] | A rational-number game on the number line | 95 4th graders (54 game, 41 control), five 30-minute sessions: bigger gains in magnitude estimation and ordering; **in-game metrics (performance, the highest level) predicted conceptual knowledge at posttest** | Line placement as play; the game's own record is valid evidence | What the bakery records (§3.10) is evidence, not a quiz |
| **Fraction Ball** (UC Irvine) [G7] | A basketball court whose arcs are worth 1/4, 2/4, 3/4 (one end) and 1/3, 2/3 (the other), decimals on the other side, a number line for the score | 160 4th-6th graders randomized within classes against PE, six 50-minute sessions: **+0.44 SD** on a fraction-and-decimal composite (arithmetic, conversion, number line); a pilot of 69 | The body, the line and team play | The Fair Line and the body in VR |
| **Decimal Point** (Carnegie Mellon) [G8] | An amusement park of 24 mini-games aimed at named decimal misconceptions | 153 middle-school students: the game (70) gave more learning and more enjoyment than conventional computer-based teaching (83); girls gained more | Misconception-targeted play | The Hundred Tray's traps for longer-is-larger and shorter-is-larger |
| **ST Math** (MIND Research Institute) [G9] | Wordless spatial-temporal puzzles with the penguin JiJi | 52 low-performing schools randomized: **a negligible, non-significant effect** (Rutherford et al. 2014); Evidence for ESSA lists +0.04; the developer's later report on the same grant claims a significant effect | Visual puzzles beside the curriculum | Wordless is necessary, not sufficient: the move must be the maths |
| **DragonBox Numbers, Big Numbers** [G10] | Whole numbers, counting, adding, carrying | No fractions title found | — | DragonBox's idea (the rules are the maths) is Balance Altar's; for fractions the cut is the rule |
| **Zombie Division** | Division as the attack | Chosen seven times longer than the same maths as a quiz | The maths is the move | The knife is the move |
| **Fraction Face-Off!** (not a game) | The intervention above | Developer-run randomized trials (0.39 in one; 0.64 listed for a five-trial review) | The line and fair shares | The bakery's two faces of every order: the share and the line |

**Why fraction games usually fail:** the fraction is a picture to name or a number to type beside a game; pies are
decoration; the line is a quiz screen. **Why the good ones work:** the move is a partition (Slice Fractions, Refraction),
the feedback is a magnitude on a line (Motion Math, Semideus, Fraction Ball), and the habits are made to fail (Decimal
Point). The bakery does all three in one verb.

### 2.4 The curriculum strand: the units this game replaces

The fraction strand of our maths units for grades 3-6 (the Common Core standards [S1]-[S4] and the Singapore and UK
references in each unit), with each unit's goals (from `data/school/gradeN.json`) and the ideas of its cards, and which
rung teaches each idea. **P1** marks a unit the game replaces for children once phase C ships its room; the cards stay as
the Book. Denominators follow the units' generators: 2, 3, 4, 5, 6, 8, 10, 12 (and 100).

| Unit | Standards | Its ideas (from the cards; exercises and generators) | Taught by | After phase C |
|---|---|---|---|---|
| `g3.maths.unit_fractions` | 3.NF.1, SG P3, UK Y3-4 | sharing into equal parts is the key; 1/4 is one of four equal parts, the bottom number counts them; 3/4 is 3 parts of size 1/4; unequal parts are not thirds; a fraction of a set (1/4 of 12 = 3; 3/4 of 12 = 9) (18 exercises; generators `g3f.name_fraction`, `pick_picture`, `fraction_of_set`, `equal_parts`, `build_fraction`) | rung 3: **Opening Night and Midnight Leftovers (phase B)**, the Cupcake Tray | **P1** |
| `g3.maths.fractions_number_line` | 3.NF.2, 3.NF.3c | a line from 0 to 1 cut into equal jumps; 2/3 is two jumps of a third; past 1 (5/4); whole numbers as fractions (4/4 = 1, 3 = 3/1); the same bottom: more jumps is bigger (18; `g3f.fraction_on_line`, `jumps`, `whole_as_fraction`, `order_on_line`, `compare_to_one`) | rung 3: the Baguette Counter | **P1** |
| `g3.maths.equivalent_fractions` | 3.NF.3, UK Y4, SG P3 | 1/2 = 2/4 = 4/8 on a fraction wall; cut every part in two; the same bottom: more parts is bigger; the same top: a bigger bottom means smaller parts; adding and taking away with the same bottom (19; `g3f.equivalent_missing`, `is_equivalent`, `compare_fractions`, `add_same`, `order_unit_fractions`) | rung 3: the Leftover Shelf, the Tin Oven | **P1** |
| `g4.maths.equal_fractions` | 4.NF.1, 4.NF.2 | multiply top and bottom by the same number (2/3 = 8/12); compare by making the bottoms the same or against 1/2 (9; `g4f.benchmark_half`, `compare_fractions`, `equivalent_missing`, `is_equivalent`, `pick_picture`) | rung 4: the Re-Cut, the Queue | **P1** |
| `g4.maths.add_fractions` | 4.NF.3 | same-size parts: add the tops; take away the same way; a fraction as a sum of smaller ones (5/6 = 2/6 + 3/6); mixed numbers (2 1/4 = 9/4) and adding them (11; `g4f.add_same`, `sub_same`, `decompose`, `mixed_to_fraction`, `add_mixed`, `fraction_story`, `build_fraction`) | rung 4: Pies and Pieces (and rung 3's Tin Oven) | **P1** |
| `g4.maths.fraction_times` | 4.NF.4 | 3/4 = 3 × 1/4; 5 × 1/3 = 5/3; 3 × 2/5 = 6/5; potions and chests in stories (10; `g4f.as_unit_multiple`, `unit_times`, `frac_times`, `times_between`, `times_story`) | rung 4: Repeat Orders | **P1** |
| `g4.maths.decimals` | 4.NF.5, 4.NF.6, 4.NF.7 | a tenth is 0.1, a hundredth 0.01; 3/10 = 30/100; compare tenths first; 0.5 = 0.50 (9; `g4f.build_tenths`, `tenths_to_hundredths`, `fraction_to_decimal`, `decimal_to_fraction`, `decimal_on_line`, `compare_decimals`, `add_tenths_hundredths`) | rung 4: the Chocolate Slab | **P1** |
| `g5.maths.unlike_fractions` | 5.NF.1, 5.NF.2 | parts the same size first: 1/2 + 1/3 = 3/6 + 2/6; a common denominator (12 for quarters and sixths); mixed numbers; check with benchmarks (10; `g5f.add_unlike`, `subtract_unlike`, `common_denominator`, `add_mixed_unlike`, `benchmark_sum`, `sum_mistake`, `unlike_story`) | rung 5: Mixed Tins | **P1** |
| `g5.maths.fractions_as_division` | 5.NF.3 | 3/4 = 3 ÷ 4: three cakes for four buddies; a ÷ b = a/b; more than one when the top is bigger (7/2 = 3 1/2); sharing stories (10; `g5f.division_to_fraction`, `fraction_to_division`, `share_story`, `between_wholes`, `share_mixed`, `sharing_picture`) | rung 5: the Great Feast (seeded from Opening Night's tables) | **P1** |
| `g5.maths.multiply_fractions` | 5.NF.4, 5.NF.6 | 2/3 × 6 = 2/3 of 6; 2/3 × 3/4 on a square shaded both ways; tops times tops; areas with fraction sides; mixed numbers (10; `g5f.fraction_of_number`, `fraction_times_fraction`, `area_model_product`, `fraction_rectangle`, `fraction_story`, `build_product`) | rung 5: Half of a Half | **P1** |
| `g5.maths.scaling` | 5.NF.5 | times more than 1 grows, less than 1 shrinks, 1 (4/4) keeps; compare without working out (10; `g5f.scale_compare`, `scale_factor`, `scale_order`, `scale_story`, `scale_truefalse`) | rung 5: the Size Oven | **P1** |
| `g5.maths.divide_unit_fractions` | 5.NF.7 | 1/3 ÷ 2 = 1/6; 4 ÷ 1/3 = 12 (how many thirds fit); check by multiplying; bags and juice (9; `g5f.unit_divided`, `whole_divided`, `unit_divide_story`, `divide_check`, `divide_truefalse`) | rung 5: the Scoops | **P1** |
| `g5.maths.percent_intro` | SG P5, UK Y6 | per cent = out of 100; 35 % of a hundred square; fractions, decimals and percents are names for the same amount; 10 % then build up; a discount in gold (19; `g5c.percent_square`, `percent_convert`, `percent_of`, `percent_order`, `discount`) | rung 5: the Hundred Tray | **P1** |
| `g6.maths.divide_fractions` | 6.NS.1 | how many of this fit into that; multiply by the reciprocal; check with a picture; ribbons and servings (11; `g6n.frac_divide`) | rung 6: Servings | **P1** |
| `g6.maths.ratios` | 6.RP.1, 6.RP.3a | a ratio compares two amounts (3 : 5); order matters; part to whole; equal ratios like equivalent fractions; ratio tables (11; `g6n.ratio_table`, `ratio_words`) | rung 6: the Recipe Book, the Big Batch | **P1** |
| `g6.maths.percent` | 6.RP.3c | a percent of a number by 1 % or 10 %; easy percents as fractions; the whole from a part and a percent (11; `g6n.percent_of`, `percent_story`) | rung 6: the Sale Jar | **P1** |
| `g5.maths.decimal_place_value`, `decimal_add_subtract`, `decimal_multiply_divide` | 5.NBT.3, 5.NBT.4, 5.NBT.7 | thousandths, rounding, lining up the points, placing the point | touched (the Hundred Tray's hundredths; the line's tenths); the algorithms belong to Market Change and Frog Jump (`learning-is-play.md` §5.2) | stay as they are |
| `g6.maths.convert_ratios`, `g6.maths.unit_rates` | 6.RP.3d, 6.RP.2, 6.RP.3b | conversions as ratios; unit rates, better buys, speed | touched (grams and cups in the recipe book); Ratio Kitchen's (g6-8) | stay as they are |
| `g4.maths.factors`, `g6.maths.gcf_lcm` | 4.OA.4, 6.NS.4 | factors, multiples, the least common multiple | used (the tins' common sizes; the knife's counts); reviews only when mastered | stay as they are |

Sixteen units become P1: their **195** hand-written exercises (93 number answers, 48 written choices, 29 true-or-false
claims, 8 orders, 8 matches, 6 builds, 3 sorts: **77** of them reading debt) stop being what a child meets, and their 104
cards (2,709 words) become the Book; the orders are the evidence instead (§3.10). The orders' numbers come from the same
ranges as the units' 78 generators (`G3FractionsGen`, `G4FractionsGen`, `G5FractionsGen`, the grade 6 generators), so what
a child bakes and what the Book shows agree.

### 2.5 What the five tests need from the design (the research's verdict)

Choice comes from autonomy, competence and relatedness (`engagement-and-child-psychology.md` §1.1), from creatures to care
about (the buddies), from a place that visibly grows because of you (the lane's lanterns, a village that fills), from
epiphanies (the first time two eighths fill a quarter), and from challenge kept winnable (Battleship Numberline [G5]).
Mute comes from orders that are situations (a table of buddies) and pictures, and from a world that answers (the Fair
Line). Cheat comes from cuts that are final, counts that must be chosen, and orders built so that every partial habit
meets one it cannot do (the models, §3.9). Transfer comes from the fade [BA C1][BA C2], from more than one face of a
fraction (pies, the line, sets, scoops, scaling, ratios: RNP [F23]), and from rooms where habits fail. Wow must be the
concept itself (the equal pieces falling apart, the box stopping at the flag), never decoration (LP [G8]).

---

## 3. The game

### 3.1 The fantasy and the purpose

**You are the night baker.** The Starlight Bakery is a little round bakery of cream walls under a red roof, with a
teal-and-white striped awning, a big round window glowing gold and a chimney that puffs star-shaped smoke whenever the
bakery is open (picture 01). Inside: a dome oven of red brick with a crackling fire, a long wooden counter with a brass rail
along its front edge (the Fair Line), a cutting board, the Fair Knife on its hook, a shelf of leftover pies, and a window
onto the lane. In the lane stand the cottages of the village's buddies: EasyCraft's living buddies, block builds with
googly eyes (a cube pup, a tall tower, a bunny, a tiny mouse, a wobbling jelly, a lantern buddy). Every night they come to
the window hungry. Tables of them sit outside with empty plates (two pies, five buddies: share them fairly); one at a
time they come with a takeaway box and an order in a thought bubble (a pie in six parts, five of them glowing).

A buddy fed fairly munches, does a happy hop, and the lantern in its cottage window lights. The lane fills with light
order by order; the night's last order is the **Feast**, a long table rolled out into the lane under the stars where the
whole village sits down together and every plate must be the same. When the Feast is fair the buddies cheer and sprinkles
go up like fireworks; then midnight comes with its leftovers, and after them the sky turns to dawn and the bakery's sign
earns a star. A new night (a new room) always waits.

**Why it matters to the child:** the village visibly grows lighter (and, rung by rung, larger: new buddies move into new
cottages) because of them; the buddies are theirs to feed and they know each by sight; fairness is something every
8-year-old cares about fiercely, and here fairness *is* the maths. The long purpose ties into EasyCraft's core loop
(learn → gold → build a rocket → fly): every judged order records through `SkillShown`, so stars and the School's gold come
from the bakery, and rung 6's transfer room is the launch site's fuel mix (a ratio).

**The guide** is Professor Hoot, DISCOVER's owl, in a baker's hat, perched on the bakery's sign outside and on the end
of the counter inside. He speaks; the buddies only babble and chirp; a little robin eats the crumbs of a pie cut wrong.

**The tone:** cosy, warm and a little funny, like a picture book at bedtime: the oven's crackle, a music box playing
Mozart's *Eine kleine Nachtmusik* ("a little night music", the repo's own rendering), the knife's "ting", the clack of
plates on the rail. Never scary, never rushed: nothing is timed, a hungry buddy just waits and wiggles, a wrong cut
becomes the robin's supper.

### 3.2 Where it lives

- **Phase B:** the bakery is a place of its own far above the world (like Life's rooms, G0's play arena and the altar's
  temple), always at dusk inside, with its own sky. It opens from DISCOVER (the unit `g3.maths.unit_fractions` shows the
  bakery's picture, a pie and a star, on the maths map, and its PLAY opens Opening Night; Hoot's pick opens it whenever that
  unit is the child's next or due one), from the Discovery Academy's Maths Workshop door when the child's unit is in the
  strand (`AcademyPlaza.opens()`, W1's switch), and by a developer argument (`--bakery-night=opening`).
- **Phase C:** the bakery stands in every home world's Discovery Academy courtyard, beside the Maths Workshop's gate,
  with the buddies' lane behind it (local to each child, like the crystals, never synced): its window glows and its
  chimney puffs stars *always* (no opening hours in the world: a time gate would be a pressure trick); walking in starts
  the child's rung; the lane's lit lanterns are the child's progress, visible from the courtyard. A discovery crystal (W1)
  for a child whose unit is in the strand can open a short night (four orders).
- **Phase D:** the child's own woken buddies (from their world) can come to the bakery as customers (owner's call, §8);
  a child's own order or recipe (rung 6.5) can be shared for a friend to bake; friends can bake together at one counter.

**The Maths door: how a child of each grade finds the right game.** Balance Altar (algebra, grades 5-8) and Fraction
Bakery (fractions, grades 3-6) both sit behind the Academy's Maths Workshop door. The door (and Hoot's pick in DISCOVER)
opens **the deep game that teaches the child's current maths unit** (a review due, else the next not mastered:
`DiscoveryPlays.subject_unit`, the rule W1 already uses), and G0's round when no deep game covers that unit yet:

| Grade | The door usually opens | Because |
|---|---|---|
| 3, 4 | the bakery (rung 3 or 4) | every fraction unit of the grade is the bakery's; non-fraction units still open G0's round |
| 5 | the bakery for `unlike_fractions` … `percent_intro`; the temple for `g5.maths.expressions` | the grade's units decide, in the School's order |
| 6 | the bakery for `divide_fractions`, `ratios`, `percent`; the temple for `equations`, `equivalent_expressions`, `exponents_expressions`, `variables` | the same rule |
| 7, 8 | the temple | the bakery's rungs stay open to everyone for review and fun |

The door's picture shows which game it will open (a pie or a crystal) and Hoot names it as the child walks up ("The bakery
is open tonight!" or "The temple is waiting!"). In phase C both are places a child can also walk into directly (the
bakery in the courtyard, the temple floating above): choice stays the child's; the door only makes the right one the
easy one. A grade-5 child mid-way through fractions who wanders into the temple simply plays the temple's entrance hall.

### 3.3 The core loop

| Every | The child | The world answers | Example (Opening Night) |
|---|---|---|---|
| **10 seconds** | one act with the hands: set the knife and slice, put a piece on a plate or in a box, push the box along the rail | at once, in sound and sight | the pie falls into five equal pieces with a sparkle and a "ting"; the box ticks along the rail |
| **minute** | one order: a table fed fairly or a box filled right | the plates (or the box) slide along the Fair Line and stop at the amount; the flag pops up; the buddies munch and hop; a lantern lights | "Fair and square!"; three plates side by side at two thirds |
| **10 minutes** | one night | the lane fills with light; the Feast's long table; dawn; a star on the sign | Opening Night's Feast: four pies for six buddies, every plate at two thirds |
| **days and weeks** | the rungs | a rung a school year with its new tool; the village grows (new buddies, new cottages); the recipe book's pages fill; in phase D, your own order for a friend | next: the Baguette Counter, the Leftover Shelf, the Tin Oven |

Picture 06. The rhythm inside a night alternates: a new tool or a new kind of order shown once by the ghost, three or four
orders where the child uses it, a mixed run where the child must decide what each order needs, then the night's Feast.

### 3.4 The verbs are the concepts

Every idea has the verb that *is* it, and a world that makes guessing lose.

| Idea | Verb | What the world does | Why guessing loses |
|---|---|---|---|
| A fraction is equal parts of a whole; the bottom number says how many | **cut** with the Fair Knife: set the count (12 dot-lights; in VR a twist, one click a piece), slice | the whole falls into that many *equal* pieces; the cut is final | no preview of the lines on a judged order and no undo: the count is chosen, not searched (the model: trial and error 0 %, with an undo 100 %) |
| The top number counts parts of that size | **give**: pieces onto a box or plates | the box slides along the Fair Line piece by piece and stops at its amount | a box is right only at the order's amount: random counts and cuts land there in 0-6 % of orders |
| A fraction is a share: n ÷ p = n/p | **share** a table: cut the pies, deal the pieces | the plates race along parallel rails; fair means they stop side by side, nothing left on the board | dealing twelfths works only when 12 shares among the buddies: tables of 5 and 8 stop it (2.6 %); halving stops at thirds (0 %) |
| A fraction is a point on the number line; past one; whole numbers as fractions | **slide** (every order) and, at the Baguette Counter, **cut the loaves** that lie along the rail | the box stops at its spot; 5/4 passes post 1; 8/4 stops on post 2 | "the line's end is one" and "a fraction is less than one" stop in the wrong place: 0 % |
| Equivalent fractions; a fraction's size is not its piece count | **use the leftovers** (and re-cut a piece into equal smaller pieces) | two eighths fill the space of one quarter on the order's picture; the box stops at the same spot | "give the top number of pieces" with pieces of another size stops short or long: 0 % |
| Comparing fractions (any two; the benchmark 1/2) | **make it fair** (top up the smaller plate); **line up the queue** by what each buddy ordered | the plates stop side by side; the buddies stand along the counter in order | whole-number bias tops up the wrong plate and queues by the bottom number: 0 % |
| Adding and taking away: only same-size parts can be counted together | **fill the tin**: tins with moulded sections take only pieces of their size; the oven bakes only full tins | a piece of the wrong size will not sit in a section; a full tin bakes into one whole cake | the add-tops-and-bottoms tin (fifths for 1/2 + 1/3) fits neither piece: 0 % |
| Unlike denominators: a common denominator | **pick the tin** both pieces can be re-cut to fit, re-cut, fill | the sixths tin takes the half as three sixths and the third as two | "the bigger bottom number's tin" works only when one divides the other (0.8 %) |
| Mixed numbers | **pack whole pies first** | a box of 9/4 holds two whole pies and a quarter; the rail shows two posts and a quarter | — |
| A fraction of a set | **fence the cupcake tray** into equal groups, take some | 3/4 of 12 is three groups of three | random fences rarely make equal groups |
| Whole × fraction | **repeat orders**: five buddies each want 2/3 | ten thirds: three whole pies and a third | — |
| Fraction × fraction; a fraction of a fraction | **cut a piece again** (half of a half); **cut the tray both ways** (the area model) | the twice-cut part is smaller than both | "multiplying makes bigger" expects more cake and gets less |
| Scaling: × less than one shrinks, × more than one grows | **the Size Oven** (Size Magic): three cakes go in with dial tags (×3/4, ×5/4, ×4/4); shelve each where it will fit after baking | the cakes come out smaller, bigger or the same and slide onto their shelves, or don't fit | one cake at a time let "multiplying makes bigger" pass 29 %; three at once: 0 % |
| Dividing: how many fit | **set the moulds, then pour** with a scoop (6 cups with a 3/4-cup scoop: 8 moulds) | every mould fills and nothing is left, or a mould stays empty, or batter is left | "division makes smaller" sets too few moulds: 0 % |
| Decimals and percents name the same share | **the Hundred Tray**: break off rows (tenths) and squares (hundredths) of a 10 × 10 slab; the jar's level | 0.45 is four rows and five squares; 45 % fills the jar to 45 of 100 marks | longer-is-larger and shorter-is-larger queue 0.4, 0.405, 0.45 wrongly: 0 % |
| Ratio: the same times as much | **pour the recipe**: scoops of flour and butter in the recipe card's ratio | the dough puffs golden only in ratio; otherwise a flat cake | adding the same amount to both: 0 % |
| Reading the symbols | **the order card's fade**: picture → picture and numeral → numeral → symbols | Hoot reads every card; each symbol says its name when touched | at stage 3+ only a child who reads the numeral can act (the picture is gone) |

### 3.5 Opening Night, beat by beat (the phase B slice)

Pictures: `fraction-bakery/01-the-bakery.png`, `02-the-fair-knife.png`, `03-the-fair-line.png`, `04-opening-night.png`.

**The place** (inside the bakery, at dusk): the counter in front of the child, its brass Fair Line along the front edge
(posts at 0, 1 and 2, a little pie on post 1 and two on post 2); the cutting board on the counter with a stack of fresh pies
beside it; the Fair Knife on its hook; the window onto the lane straight ahead, where a small table stands outside with
plates; the oven glowing at the left; the leftover shelf at the right, empty at the start; Hoot on the counter's end.
Tables are served through the window (the plates come in on a little hatch onto the counter's rails); boxes are handed
over on the counter. The child never walks: the orders come to them (in VR the child stands still behind the counter).

1. **The arrival (0:00).** The camera glides down the lane at dusk to the bakery; the door opens by itself; the warm
   light, the oven's crackle. Hoot (on the sign, then on the counter): "Welcome to the Starlight Bakery! The buddies are
   hungry." Then: "You're the baker tonight. Feed everyone fairly!"
2. **O1, taught (0:20): one pie, four buddies.** A bell; four buddies sit at the table outside; a pie on the board. The
   ghost finger taps the fourth dot on the knife (four dots light, four clicks), swipes across the pie: it falls into four
   equal pieces with a sparkle and a "ting". Hoot: "Watch: four buddies, four equal pieces." … "Your turn! One piece on each
   plate." The child deals (tap a piece, tap a plate; or drag; or a sweep across the plates). When every plate holds a
   piece the bell on the counter glows; the child rings it: the plates slide along the rail and stop side by side at one
   quarter: "Fair! Every plate the same." The buddies munch and hop; the first lantern lights in the lane: "Look! A light
   in the lane."
3. **O2, taught: the trap (0:50): one pie, three buddies.** No ghost. A child who halves (two, then four) finds one piece
   left over on the board (or, with two, a buddy with an empty plate who tilts its head): ringing the bell sends the plates
   along the rail and they stop apart. Hoot: "Hmm! Not fair yet." then "One piece for each buddy. All the same size!" (play
   first, words after). The cut pie becomes crumbs: the robin hops in and eats them ("Crumbs for the robin! Here's a new
   pie."). Set to three: "Fair and square!"
4. **O3, O4, judged (1:20, 1:45):** one pie for a table of 5, 6 or 8; two pies for 3 or 5. Silent but for the order spoken
   when the table sits down ("Two pies for five buddies."); Hoot praises after.
5. **O5, taught: the box (2:15): three quarters.** A pup buddy comes to the counter with a takeaway box; its thought bubble
   shows a pie in four parts, three glowing; Hoot reads it: "Three quarters of a pie, please!" The ghost sets four dots,
   slices, puts three pieces in the box, closes it and pushes it along the rail: tick, tick, tick; the box stops and the
   pup's flag pops up right there: a chime. Hoot: "Watch: four equal pieces. Three in the box." Then the see-why: "Three
   quarters: three pieces, each one quarter." The fourth piece slides onto the leftover shelf: "The extra piece goes on the
   shelf." (The shelf is Midnight's.)
6. **O6-O10, judged (2:50-4:40):** boxes (in thirds, quarters, sixths, eighths; one never in halves: thirds, fifths or
   sixths) and tables (three pies for 5 or 8 buddies; two or three pies for 5, 6 or 8) in a mixed run, each order spoken as
   it arrives. Silent; strategy praise ("Perfectly shared!", "Right on the flag!"). A box handed over too small stops short
   of the flag, and the gap is plain to see ("A little more, please!"); too big passes it ("Too much! It went past the
   flag."). Either can be fixed and handed over again (not first time).
7. **O11, judged: the Feast (5:10).** All the lanterns but the bakery's own are lit. The bakery's doors open onto the lane;
   a long table rolls out under the stars and six buddies sit down (the night's numbers: four pies for six, or three for
   eight, or five for six…). Hoot: "The Feast! Share every pie fairly with the whole lane." Six plates race along six
   rails. A child who cuts the four pies in thirds and deals two each, or in sixths and deals four each, is right either way
   (any fair split counts, mixed cuts too: a half and a sixth each is also two thirds); Hoot notices the bigger pieces:
   "Clever cutting!"
8. **The cheer (5:40).** Every plate at the same mark: the buddies cheer, sprinkles burst like fireworks, the lane glows;
   *Waltz of the Flowers* swells. Hoot: "Everyone has the same! Listen to them cheer!" The see-why of the night: "Equal
   pieces. The cut says the size, the count says how many." Then: "Grown-ups call these fractions. You baked them all
   night!"
9. **Midnight (6:10).** The music softens to the *Moonlight Sonata*; the oven's fire sinks to embers; the moon rises over
   the lane. Hoot: "Midnight! The oven's asleep, but some buddies are still hungry." The end card (pictures only): the lit
   lane, the stars, the unit's stars, the gold, three picture buttons (↻ again, ▶ Midnight, a door: back).

A child who knows the idea takes about 5-6 minutes; a slower one 7-8. Nothing is ever timed. After two wrong hand-overs on
an order the ghost does one step (the cut, or one deal; that order counts as helped); SHOW ME (the eye) does one step any
time (helped); idle for 10 s, everything that can be touched glows for 3 s (never only the right thing: no help).

**The bakery's rules for phase B** (the starting rules for `BakeryBench`, `BakeryKnife` and `BakeryJudge`, from the phase
A model, `fraction-bakery/model/bakery_rules.py`):

| Rule | Value |
|---|---|
| A whole | one pie, all pies the same size (the Night Market breaks this on purpose, later); fresh pies stacked by the board in Opening Night, none at Midnight |
| The Fair Knife | 2 to 12 equal pieces; cuts one whole or one piece (re-cutting a piece of size s gives n pieces of s/n); a long swipe across a row of pies cuts each the same (one decision); **no preview of the lines on a judged order** (a faint ghost line only on taught orders); **every cut is final** |
| An order | a table (n pies for p buddies: every plate the same, nothing left on the board, every pie used) or a box (a/b of a pie, the picture in a thought bubble); at Midnight, shelf boxes and make-it-fair plates |
| Dealing | tap a piece, then a plate or the box (or drag; a sweep across the plates deals one to each in turn); moving pieces between plates, or back to the board, is free until the hand-over |
| The hand-over | the bell (a table) or a push of the box: the Fair Line slides it, piece by piece, to its amount; it is judged then, and the buddy's flag shows the order's true spot. Nothing slides before the hand-over |
| Right | a table: every plate stops at the same mark and nothing is left; a box: it stops at the flag (any equivalent counts: six eighths for three quarters) |
| SOLVED (first time right) | right at the first hand-over, with no help, and within the cut budget: the fewest cuts that can make it, plus one (a table of n pies for p buddies needs one cut per pie that cannot be given whole) |
| Help | the ghost does the next step of a fewest-cut solution after every second wrong hand-over; SHOW ME any time; the ghost finishes an order after a third wrong hand-over (SHOWN) |
| A wrong cut | the pie becomes crumbs for the robin and a fresh pie comes (in Opening Night); the order's first-time credit is gone |
| Numbers | denominators from the units' generators (2-12); Opening Night's eight judged orders, as the model draws them: O3 one pie for 5, 6 or 8 buddies; O4 two pies for 3 or 5; O6 a box in thirds, quarters, sixths or eighths; O7 three pies for 5 or 8; O8 a box in thirds, fifths or sixths (never halves); O9 and the Feast from tables of 5, 6 or 8 (an odd number of pies at 8); O10 a box in thirds, fifths, sixths or eighths (§3.9 says why) |
| The night's record | 8 judged orders → 8 `SkillShown` events for `g3.maths.unit_fractions`; MasteryRules' bar: 7 of 8 |

### 3.5b Midnight Leftovers, beat by beat (the phase B transfer room)

It opens from Opening Night's end card, or as the night continues. Picture `fraction-bakery/05-midnight-leftovers.png`.

1. **The hook (0:00).** Moonlight through the window; the oven asleep, its embers glowing and a soft snore from the
   chimney (little "z" puffs of smoke); the leftover shelf glows: pies already cut, some pieces gone (a pie in eighths with
   six left, one in thirds with two left, one in sixths with five, a half, a quarter…). No fresh pies by the board. Hoot:
   "Midnight! The oven's asleep. Only the leftovers are left." The frame (teaching, not a move): "These pieces are cut
   already. Use what's on the shelf."
2. **M1, judged (0:15): three quarters, from eighths.** The pup's thought bubble shows a pie in four parts, three glowing;
   Hoot reads it. The shelf holds a pie in eighths (six left) and two thirds. The child who carries Opening Night's habit
   puts three eighths in the box and pushes it: it stops at three eighths, short of the flag, and the gap shows how far
   (Hoot: "It stopped short! Those pieces are smaller."). If nothing happens for 15 s, once: "Make the buddy's order from the
   shelf." (the goal, never the move: not help). The child who looks at the size sees that two eighths fill one quarter of
   the picture, puts six eighths in the box: it stops at the flag. The see-why, the first time: "Two eighths fill one
   quarter. Size matters!"
3. **M2, judged:** one half, from sixths (or eighths, tenths, quarters), with a stray third on the shelf.
4. **M3, judged: make it fair.** Two buddies at the window already hold a leftover each: a quarter and an eighth. Hoot:
   "Two buddies, two leftovers. Make their plates fair!" (the situation, never the idea). The shelf has eighths. One more eighth on the eighth's plate: both plates
   slide and stop side by side: "Fair! A quarter is two eighths." (Whole-number bias tops up the quarter's plate, "eight is
   more than four"; the plates stop apart.)
5. **M4, judged: a small piece from big ones.** The order is one sixth (or one quarter, one eighth, one twelfth); the shelf
   holds only halves (or quarters, thirds): re-cut a half into three with the knife, give one. (The habit gives a whole
   half: too much.)
6. **M5, judged: mixed sizes.** Two thirds when the shelf has one third and some sixths: a third and two sixths.
7. **M6, judged: three plates to make fair.** A half, a third and a sixth: top up the third's plate with a sixth and the
   sixth's with two sixths, so all three are halves.
8. **Dawn (about 4:00).** The sky pales; the sun rises over the lane; *Morning Mood* (Grieg) begins; the buddies come out
   of their cottages to breakfast; the sign's star lights. The rule in words, after the child has used it: "You found the
   bakery's secret: look at the size!" Then: "The sun is up! The whole lane has breakfast." End card.

**Its six orders** are `SkillShown.NEW_SETTING` events for `g3.maths.unit_fractions` when handed over right the first time
with no help and within the budget (HELPED or SHOWN otherwise): a full round, its transfer kept apart. 3.NF.1's own words
are the reason: "a/b is the quantity formed by a parts of size 1/b"; Midnight is where "of size 1/b" is tested. The model
of this room (`fraction-bakery/model/midnight_model.py`): Opening Night's habit and whole-number bias hand over none of the
six right (**0 %** of visits reach 5 of 6); the idea all six (**100 %**).

### 3.6 The ladder across grades 3-6

Each rung is a part of the bakery, its tool and its rooms (each room a short night of 6-10 orders, 4-8 minutes). The grade
(DISCOVER's) picks the child's rung after the prologue (Opening Night and Midnight, everyone's first rooms); every rung
stays open to everyone. Inside a rung the rooms open one after another; transfer rooms (T) come after their idea. Picture
`fraction-bakery/07-the-ladder.png`; the later tools: `11-later-rungs.png`.

**Rung 3, The Pie Shop** (grade 3). Units: `g3.maths.unit_fractions`, `g3.maths.fractions_number_line`,
`g3.maths.equivalent_fractions`. Tool: the Fair Knife, the Fair Line, the leftover shelf, the tins, the cupcake tray.
- *3.1 Opening Night* (phase B, §3.5): tables and boxes; a/b as a parts of size 1/b; sharing (3.NF.1).
- *3.T1 Midnight Leftovers* (phase B, §3.5b): the size is the idea.
- *3.2 The Baguette Counter* (3.NF.2, 3.NF.3c): two long loaves lie end to end along the rail (0 to 2); a box of a/b of a
  loaf: cut each loaf into b, give a; most orders go past post 1 (5/4, 5/3) or stop on a post (8/4 = 2; 3/3 = 1). Later in
  the room: "where will this buddy stand?" (the child sets a buddy's flag before the box slides; the line before the
  knife).
- *3.3 The Leftover Shelf* (3.NF.3a-d): equivalence as "the same amount": 1/2 = 2/4 = 4/8 by covering and by the rail;
  make-it-fair plates; compare with the same top or the same bottom number (more pieces of the same size; bigger pieces for
  the same count).
- *3.4 The Tin Oven* (3.NF.3, 4.NF.3a): tins with 2-12 moulded sections; a piece fits only a section of its size; the oven
  bakes only full tins: fill a tin that holds 3/8 (cut by the tin's sections, five more); add two buddies' pieces in one
  tin (2/5 + 1/5).
- *3.5 The Cupcake Tray* (3.NF.1, a fraction of a set): a tray of 12 (or 8, 10, 6); fence it into equal groups; 3/4 of the
  tray is three groups; a buddy family's order.
- *3.T2 The Picnic*: outside on a blanket at sunset: square trays and long ribbon cakes cut into equal pieces of different
  shapes (a square in four triangles or in four strips: both quarters, 3.G.2); the habit "a quarter looks like a pie wedge"
  fails.
- Harder: voiced to silent; pictures to numerals (stage 1 → 2); one pie → several; tables to 8.

**Rung 4, The Cake Kitchen** (grade 4). Units: `g4.maths.equal_fractions`, `g4.maths.add_fractions`,
`g4.maths.fraction_times`, `g4.maths.decimals`. New tool: the knife on every piece at once (a re-cut of a whole share), the
Queue, the Chocolate Slab.
- *4.1 The Re-Cut* (4.NF.1): an order in twelfths when the pies are already in thirds: re-cut every third into four
  (2/3 = 8/12: multiply the top and the bottom by four, seen as cutting every piece).
- *4.2 The Queue* (4.NF.2): four buddies with order cards (numerals) line up along the counter, the least first; every
  queue hides a same-top pair (2/5 against 2/3) and a small top worth more (1/2 against 3/8); the benchmark half: the
  rail's middle post glows.
- *4.3 Pies and Pieces* (4.NF.3b-d): mixed numbers: a box of 9/4 is packed as two whole pies and a quarter; adding and
  taking away mixed numbers at the counter; a fraction split into a sum (5/6 as a box of two sixths and a box of three).
- *4.4 Repeat Orders* (4.NF.4): five buddies each want two thirds: how many pies to cut? (ten thirds: three pies and a
  third; in this room the counter is longer and the rail runs to post 4, so the box stops at 10/3).
- *4.5 The Chocolate Slab* (4.NF.5-7): a slab of 10 rows of 10 squares; a tenth is a row, a hundredth a square; 3/10 =
  30/100; 0.45; compare decimals by building them.
- *4.T1 The Night Market*: a stall in the lane with cakes of different sizes: half of a small cake against a third of a
  cake twice as big; give a buddy the same amount from the big cake (the same fraction is more). The habit "1/2 is always
  more than 1/3" fails.
- Harder: numerals with pictures → numerals alone; the slab's queue traps.

**Rung 5, The Big Oven** (grade 5). Units: `g5.maths.unlike_fractions`, `g5.maths.fractions_as_division`,
`g5.maths.multiply_fractions`, `g5.maths.scaling`, `g5.maths.divide_unit_fractions`, `g5.maths.percent_intro`. New tools:
mixed tins, the Size Oven, the scoops, the Hundred Tray.
- *5.1 Mixed Tins* (5.NF.1-2): a half and a third into one tin: pick the tin both fit (sixths, or twelfths), re-cut both,
  bake; subtraction as "what's missing from a full tin"; benchmark checks ("more than one tin?"). Pairs with a common size
  above 12 use the big rectangular trays (24 sections) in phase C.
- *5.2 The Great Feast* (5.NF.3): bigger tables and more pies than buddies (seven pies for three: two each and a third);
  the long table's plates show mixed numbers on the rail.
- *5.3 Half of a Half* (5.NF.4, 5.NF.6): a fraction of a piece (cut a quarter in half: an eighth); 2/3 of 3/4 on a tray
  cut both ways (the part shaded twice); a fraction of a number (2/3 of a tray of 12); a garden-cake with fraction sides.
- *5.4 The Size Oven* (5.NF.5): EasyCraft's Size Magic in the oven: three cakes go in with dial tags (×3/4, ×5/4, ×4/4);
  the child shelves each where it will fit after baking, then bakes; the giant buddy's big tin and the mouse's tiny one.
- *5.5 The Scoops* (5.NF.7): measuring scoops of 1/2, 1/3, 1/4, 1/6, 1/8 cup; how many 1/3-cup scoops fill 4 cups (set
  out the moulds, then pour); 1/3 cup shared among four bowls (pick the scoop: 1/12).
- *5.6 The Hundred Tray* (percent_intro; decimals as names): a tray of 100 cupcake moulds; 35 % is 35 of 100; 3/5 = 60/100 =
  60 %; 25 % of a tray of 40; the jar's level; every decimal queue hides 0.4, 0.405, 0.45.
- *5.T1 The Giant's Picnic*: Size Magic shrinks the child among giant pies: the whole changes size while the fractions stay
  (a transfer of scaling and of "the same whole").
- Expert: Hoot cuts unfairly on purpose once a child has shown the idea, and the child fixes it (sparingly: §2.2).

**Rung 6, The Recipe Book** (grade 6). Units: `g6.maths.divide_fractions`, `g6.maths.ratios`, `g6.maths.percent`. New
tool: the recipe book (each page a recipe card in scoops; the dough's colour and rise as the judge).
- *6.1 Servings* (6.NS.1): how many 3/4-cup servings in 6 cups (set the moulds: 8); 3/4 ÷ 1/8 (six eighth-cup scoops);
  ribbons of icing cut into 2/5-metre pieces.
- *6.2 The Recipe Book* (6.RP.1, 6.RP.3a): a card of 2 scoops of flour to 1 of butter; a double and a triple batch; the
  page fills a ratio table as the child bakes (2 : 1, 4 : 2, 6 : 3); the order matters (butter to flour).
- *6.3 The Big Batch* (6.RP.3a): part to whole: juice mixed 2 parts orange to 3 water to fill a 1,500 mL jug.
- *6.4 The Sale Jar* (6.RP.3c): percent of a number (30 % of 80 cookies in the jar) and the whole from a part (12 cookies
  are 20 %: how many in the full jar?).
- *6.T1 The Rocket's Fuel* (at the launch site): fuel and oxidiser in the rocket's ratio, scaled to the tank (EasyCraft's
  rocket loop).
- *6.5 Your Own Recipe* (making, phase D): write a recipe card or an order for a friend; the game checks it can be baked.
- Hand-over: unit rates and proportional relationships continue in Ratio Kitchen (`learning-is-play.md` §5.2, grades 6-8).

**The fade** (picture 10). The order card passes through four stages: **pictures** (a pie in b parts, a glowing; a table
of buddies; the knife's dots), **pictures and numerals** (the numeral under the picture; numerals on the knife's dots and
the rail's posts), **numerals** (the picture gone: "5/6" alone, read aloud), **symbols** (rungs 4-6: "1/2 + 1/3" on a tin's
card, "3 × 2/3" on a repeat order, "6 ÷ 3/4" on a servings card, "2 : 1" on a recipe, "0.75 = 75 %" on the jar). The grade
sets the starting stage (3: pictures, 4: pictures and numerals, 5-6: numerals); the child's play moves it (three orders in
a row right with no help: the next stage; two helped in a row: back one). The Book always shows the symbols.

### 3.7 Minute 1, 5 and 30 of a first session

| | Flat (phone, tablet, PC, the web) | VR (the Quest 3) |
|---|---|---|
| **Minute 1** | DISCOVER's maths stop shows the bakery's picture (Hoot's pick opens it at once for a grade-3 child). The camera glides down the lane at dusk to the glowing bakery; the door opens; Hoot in his baker's hat. A bell: four buddies sit at the table outside; one pie on the board. The ghost finger taps the fourth dot and swipes: the pie falls into four equal pieces with a sparkle. "Your turn! One piece on each plate." The child drags the pieces, rings the bell: four plates glide along the brass rail and stop side by side; the buddies hop; the first lantern lights in the lane | The child stands behind the counter; the lane is outside the window at eye height. The ghost hands take the knife off its hook, twist the handle four clicks (four dots light) and slice. The child picks up each piece with a hand and drops it on a plate (the plate glows under the hand), then presses the bell with a palm: the plates glide; a buzz in the hand as they stop together; a lantern lights outside |
| **Minute 5** | O10: a jelly buddy at the counter, a pie in six parts with five glowing in its bubble; Hoot: "Five sixths of a pie, please!" Six dots, a swipe, five pieces into the box, a push: five ticks, and the jelly's flag pops up right there. Nine lanterns lit; the leftover sixth slides onto the shelf | Twists six clicks, slices, places five pieces in the box with the hand, and shoves the box along the counter with an open hand; it glides and ticks |
| **Minute 30** | Opening Night (6 min) and the Feast; Midnight Leftovers (4 min: three eighths stopped short at first, then six eighths filled three quarters; the quarter's and the eighth's plates made fair); dawn and the sign's first star. Hoot's pick then opens the Baguette Counter (7 min: loaves along the rail; five quarters past post one; eight quarters exactly on post two) and the Leftover Shelf (8 min: 1/2 = 2/4 = 4/8, make-it-fair plates). The end card shows a star on *Fractions of a whole and of a set* | The same rooms with the hands: slicing through a long loaf along the counter, a long shove past post one, topping up a buddy's plate at the window |

### 3.8 Show, say, do (rule 0)

**Shown, not told.** Each new tool or kind of order is shown once by the ghost (Life's ghost finger flat, ghost hands in
VR), then "Your turn!": the knife and dealing (O1), the box and the Fair Line (O5); in later rungs the tins, the re-cut,
the tray's fence, the Size Oven, the scoops, the slab, the recipe card. Transfer rooms have no demonstration (they test the
idea). After two wrong hand-overs on an order the ghost does one step (the order counts as helped). The eye (SHOW ME) does
one step any time (helped). Idle 10 s: everything that can be touched glows for 3 s (never only the right thing: no help).

**Every voice line of phase B** (Professor Hoot, read by the system's voice through `PlayVoice.say`; each line cuts in; at
most 12 words; [a], [b], [n], [p] are said as words: "three quarters", "five buddies"):

| # | When | Line |
|---|---|---|
| H1 | the arrival | Welcome to the Starlight Bakery! The buddies are hungry. |
| H2 | inside | You're the baker tonight. Feed everyone fairly! |
| H3 | O1, the ghost cuts | Watch: four buddies, four equal pieces. |
| H4 | after a demonstration | Your turn! |
| H5 | O1, after H4 (the deal is taught) | One piece on each plate. |
| H6 | the first fair table | Fair! Every plate the same. |
| H7 | the first slide along the Fair Line | Watch them slide. Side by side means fair! |
| H8 | the first lantern | Look! A light in the lane. |
| H9 | the first unfair hand-over | Hmm! Not fair yet. |
| H10 | see why, after an unfair table | One piece for each buddy. All the same size! |
| H11 | a wrong cut becomes crumbs | Crumbs for the robin! Here's a new pie. |
| H12 | O5, the ghost's box | Watch: four equal pieces. Three in the box. |
| H13 | see why after the first box | Three quarters: three pieces, each one quarter. |
| H14 | a box short of the flag | A little more, please! |
| H15 | a box past the flag | Too much! It went past the flag. |
| H16 | the first leftover goes to the shelf | The extra piece goes on the shelf. |
| H17 | the ghost's step after two wrong hand-overs | Watch me do one. |
| H18 | the Feast begins | The Feast! Share every pie fairly with the whole lane. |
| H19 | the Feast is fair | Everyone has the same! Listen to them cheer! |
| H20 | see why of the night | Equal pieces. The cut says the size, the count says how many. |
| H21 | the name, after the night | Grown-ups call these fractions. You baked them all night! |
| H22 | midnight | Midnight! The oven's asleep, but some buddies are still hungry. |
| H23 | the end card | Wonderful baking! Another night? |
| R1 | a box order, when the buddy arrives (every stage) | [a] [b] of a pie, please! ("Three quarters of a pie, please!") |
| R2 | a table order, when the buddies sit down | [n] pies for [p] buddies. ("Two pies for five buddies.") |
| R3 | a piece touched | its size: "One eighth." |
| R4 | the knife's count, as it is set | the number: "Four." |
| R5 | a post of the Fair Line touched | One whole pie. / Two whole pies. |
| R6 | a box or a table stops on the rail | the amount: "Three quarters!" / "Two thirds each!" |
| R7 | a numeral or symbol touched (stage 2+) | its name: "three quarters", "plus", "times", "to" |
| M1 | Midnight opens | Midnight! The oven's asleep. Only the leftovers are left. |
| M2 | the frame (teaching: the situation, not the move) | These pieces are cut already. Use what's on the shelf. |
| M3 | waiting 15 s (once; the goal, not the move) | Make the buddy's order from the shelf. |
| M4 | a box short at midnight, the first time | It stopped short! Those pieces are smaller. |
| M5 | see why after the first right box | Two eighths fill one quarter. Size matters! |
| M6 | the first make-it-fair order | Two buddies, two leftovers. Make their plates fair! |
| M7 | see why after the first fair plates | Fair! A quarter is two eighths. |
| M8 | see why of the room | You found the bakery's secret: look at the size! |
| M9 | dawn | The sun is up! The whole lane has breakfast. |
| P1-P6 | praise (the strategy and the effort, one at a time, never twice in a row; never speed) | Fair and square! · Perfectly shared! · Right on the flag! · Clever cutting! · You're a real baker now! · Hoo hoo! Delicious! |
| G1-G5 | the place's own | (break) Need a rest? The bakery will wait. · (Back) Leave the bakery? Your lanterns stay lit. · (the robin eats) The robin says thank you! · (the oven) Mmm, smell that bread! · (a buddy hops) Look at it dance! |

All 50 lines are at most 12 words (checked by a script, `docs/devlog/parts/game-bakery-a.md`); the only questions (H23,
G1, G2) are spoken and answered with picture buttons, so none needs reading. Each later room carries its hook line and its see-why line (§3.6 gives their ideas); phase C writes the rest to the same
rules. Without a voice (Read to me turned off by a grown-up, or no English voice on the device) the lines show as words
(G0's ruling 28). The voice says fractions as words ("three quarters", British usage as in the School's cards), never
"three slash four".

**How the voice carries the numerals.** Reading fractions is part of the skill at the top of the ladder, so the numerals
are never hidden and never required before they have been heard (picture 10):
1. Every order is spoken when it arrives, in words (R1, R2), at every stage.
2. From stage 2 the card shows the numeral under the picture; a touch on it says it again (R7); the knife's dots and the
   rail's posts get numerals too.
3. At stage 3 the picture is gone: the child acts on the numeral, still read aloud; the amount is said when a box stops
   (R6).
4. At stage 4 (rungs 4-6) the cards carry the sums, products, divisions, ratios and percents the rooms play; every
   symbol says its name when touched.
5. On the screen during play there are no words: only pictures, and the numerals and symbols, which are the subject.

**Pictures and colours that carry meaning** (picture `08-things-and-meanings.png`). Shape, motion and sound carry each
meaning too, so nothing depends on colour alone.

| Thing | Its look | Its sound |
|---|---|---|
| A pie (one whole) | a round pie with a lattice crust; berry, apple or leek filling | a soft thump on the board |
| A piece (1/n) | a wedge; its size is its name | its name when touched |
| The Fair Knife (the bottom number) | a wooden handle, a wide silver blade with 12 dot-lights; lit dots = pieces | a click per dot; a "ting" as it slices |
| The Fair Line (the number line) | the counter's brass rail; posts at 0, 1, 2 with pies on them | a tick per piece as a box slides; a chime at the flag |
| A takeaway box (an order) | kraft card with a star sticker | a paper rustle as it closes |
| Plates at a table (a share) | white plates, one per buddy, each on its own rail | the plates' clack as they stop |
| The flag (where the order should stop) | a teal flag on a pin | a pop as it rises |
| The leftover shelf (equivalence) | pies already cut, some pieces gone, glowing at midnight | a creak |
| A tin (a common denominator; rung 3+) | a round tin with moulded sections | a snap when a piece fits; a soft bump when it doesn't |
| A cupcake tray (a set) | a tray of moulds; a little fence that splits it | a pop per cupcake |
| A loaf (the line's object) | a long baguette lying along the rail | a crunch when cut |
| The Size Oven, scoops, the Hundred Tray, the recipe card (rungs 5-6) | a dial with a number tag; steel scoops; a slab of 10 × 10; a card in scoops | a rising or falling whistle; a pour; a snap per row; the dough's sigh |
| The glows | gold: the ordered part of a picture; teal: the flag; green: fair; a soft red shimmer: not fair yet | a two-note chime (fair); a soft "hmm" (not yet) |
| A lantern lit (a buddy fed) | a warm light in a cottage window | a soft chime |
| The robin (a wrong cut, kindly) | a little bird that eats the crumbs | a happy chirp |

**Sounds and music** (all already in the repo, public domain or CC0, `assets/CREDITS.md`): Mozart's *Eine kleine
Nachtmusik* in the repo's own music-box rendering for the nights (a "little night music" for a night bakery), Beethoven's
*Moonlight Sonata* (1st movement) for Midnight Leftovers, Grieg's *Morning Mood* for dawn, Tchaikovsky's *Waltz of the
Flowers* (The Nutcracker) for the Feast, Vivaldi's *Spring* for the Picnic, Satie's *Gymnopédie* for the Size Oven, Bach's
*Air on the G String* for the recipe book. New sounds (the knife's clicks and "ting", the slice, the plates' clack, the
rail's ticks, the flag's pop, the chime, the bell, the robin's chirp, the buddies' babble and munching, the oven's crackle
and snore) are made by a tool like `tools/make_tiny_sfx.py`: original, so CC0 by construction.

**Words on the screen during play: none** (pictures; numerals and symbols from stage 2, which are the subject). The HUD
shows pictures (G0's glyphs: the ear repeats Hoot's line, the eye is SHOW ME, two bars are a break). The end card shows
numbers (the gold) and stars.

### 3.9 The five tests, answered

**Choice.** What an 8-12-year-old chooses, and how this game gives it: *fairness* (children care about fair shares
fiercely; here fairness is the maths and the world shows it); *creatures* (the buddies, each known by sight, who hop when
fed); *a place that grows because of you* (the lane's lanterns, the village that fills rung by rung, the Feast); *getting
good, visibly* (the knife's counts get bigger, the orders harder, the cards grow numerals); *the body* (in VR a knife in
the hand, a slice, a shove along the counter); *surprise* (the Feast's table rolling out, the Size Oven's giant and tiny
cakes, the Giant's Picnic, the rocket's fuel); *making* (your own order or recipe for a friend, 6.5); *short* (an order
20-50 s, a night 4-8 minutes, never timed). The challenge is kept winnable early (Battleship Numberline's lesson [G5]):
Opening Night's first judged orders are easy, difficulty rises by rung, not by failing. Risks: an older child (grade 6)
may find the prologue babyish (the answer: it is six minutes, the grade then picks the rung, and rung 6's recipe book,
Size Oven and rocket fuel are for them); some children may see a bakery as "not for them" (the answer: the buddies, the
knife, the Feast, the giant's picnic; the owner's child decides). **How we check:** the owner's child plays phase B; we note
voluntary time, whether they start Midnight unasked, whether they come back another day, and what they say about the
buddies. A game nobody returns to is redesigned before phase C.

**Mute.** Nothing in a room needs reading: a table of buddies is a sharing order; a box order is a picture in a thought
bubble, and Hoot says it in words; the move (set the knife, slice, deal, push) is shown once by the ghost; the world
answers every act (the "ting" and the equal pieces; the plates side by side or apart; the box at the flag or short of it,
the gap plain to see); the goal (the dark lane, the empty plates) is visible from the start. The only text is the
numerals and symbols from stage 2, which are the subject and are always read aloud. **How we check:** a test that the
screen shows no words while an order plays (`BakeryHud.screen_words()` = 0 outside the numerals); every line spoken by
itself (`PlayVoice`); the owner's child plays with text hidden.

**Cheat.** The knife's count is chosen (no preview, no undo), every cut stays, the Fair Line moves only at the hand-over,
and the orders are built so that every partial habit meets one it cannot do. The phase A model
(`fraction-bakery/model/opening_night_model.py`, 1,000 visits per player, the night's eight judged orders, numbers new
every visit; the bar is MasteryRules': 7 of 8 right first time):

| Player | Reaches 7 of 8 | Right first time (of 8) | What happens |
|---|---|---|---|
| Knows what a fraction is | **100 %** | 8.00 | cuts each pie into as many pieces as buddies (or a multiple), gives a pieces of a whole cut into b |
| Knows it, slips on 4 % of decisions | 88.0 % | 7.37 | a knife click off or an unnoticed piece too many costs that order (two decisions an order) |
| Whole-number bias | 100 % | 8.00 | nothing in this room compares two amounts: Opening Night teaches what the numbers *are*; Midnight is where the bias fails (0 %) |
| Cuts everything in twelfths and deals round-robin | 2.6 % | 4.51 | a partial knower: it reads the boxes right; twelfths share among 3, 4 and 6 but not 5 or 8 |
| Always halves (2, 4, 8) | **0 %** | 2.29 | fails every table of 3, 5 or 6 and every box in thirds, fifths or sixths |
| One piece each, from one pie | 0 % | 4.00 | right on the boxes; leaves pies uncut at every table of more than one pie |
| Turns n/p round (8 ÷ 3 as 3/8) | 0 % | 0.00 | cuts each pie into as many pieces as there are pies |
| Random cuts and gives | **0 %** | 0.15 | — |
| Trial and error with our knife (the first cut stays) | **0 %** | 1.88 | a random count, then the best it can: right only when the random count happens to work |
| Trial and error with an undo (**not built**) | 100 % | 8.00 | why a cut is final and the knife shows no lines first (ruling 4) |

**What the model changed.** The first draft drew every table and box from grade 3's own denominators (2, 3, 4, 6, 8) with
tables of 2-6 buddies. There, the twelfths-and-deal player fed every table fairly and reached the bar on **100 %** of
visits, and the halving player on **12.3 %**: the denominator never had to be *chosen*. The night now seats tables of 5 and
8 (an odd number of pies at 8) and puts thirds, fifths and sixths in three of the boxes: 2.6 % and 0 %. The slip model was
corrected too: my first version counted a misdeal per pair of pieces dealt (88 % fell to 56 %); in the design, pieces on
the plates are in plain sight and moving them before the bell is free (ruling 6), so only the knife's click and an
unnoticed count are slips. Reported honestly: whole-number bias passes this room (it is Midnight's job), and a slip rate of
4 % per decision still loses about one visit in eight.

**Transfer.** Each idea comes back somewhere new, where the habit fails and the idea works. The phase A model of
Midnight Leftovers (`fraction-bakery/model/midnight_model.py`, 1,000 visits, six judged orders, the bar 5 of 6):

| Player | Reaches 5 of 6 | Right first time (of 6) |
|---|---|---|
| Knows what a fraction is | **100 %** | 6.00 |
| Knows it, slips 4 % | 97.6 % | 5.72 |
| **Opening Night's habit** ("the top number is how many pieces I give"; "fair is the same number of pieces") | **0 %** | 0.00 |
| **Whole-number bias** (an eighth is bigger than a quarter) | **0 %** | 0.00 |
| Greedy: the biggest piece that still fits, again and again (it knows sizes: the idea) | 100 % | 6.00 |
| Always halves (it knows sizes; only a re-cut into three fails it) | 100 % | 5.75 |
| Random | 0 % | 0.22 |
| The habit with one fresh pie on the bench (**not built**) | 0 % | 4.00: every box order right |

The last row is why the oven sleeps: with a fresh pie the habit would fill every box (it cuts by the bottom number and is
right); only the make-it-fair plates would stop it. The halving player passes Midnight because it knows sizes; Opening
Night's thirds and fifths stop it (0 %). The ladder's model (`fraction-bakery/model/ladder_model.py`, 1,000 visits each,
six orders a room, the bar 5 of 6) checks the later rooms the same way:

| Room (rung) | The habit that fails | The idea | Others |
|---|---|---|---|
| (a) Mixed tins (5) | add the tops and bottoms (the fifths tin for 1/2 + 1/3): **0 %**; "the bigger bottom number's tin": 0.8 % (halves do fit a quarters tin) | **100 %** (any common size counts: b × d when it fits, 100 %) | the first piece's tin 0 %; a random tin 0 % |
| (b) The Baguette Counter (3) | "the line's end is one" (Siegler & Pyke's 0-5 lines): **0 %**; "a fraction is less than one": **0 %**; the top number as loaves: 0 % | **100 %** | random 0 % |
| (c) The Queue (4) | whole-number bias (by the bottom number): **0 %**; by the top number: 0 %; by top + bottom: 0 % | **100 %** | knows only "more or less than a half" 0 %; random 0 % |
| (d) The Size Oven (5) | multiplying always makes bigger: **0 %**; a fraction always shrinks: 0 %; bigger numbers grow more: 0 % | **100 %** | random shelves 0 % |
| (e) The Scoops (5-6) | division makes smaller (multiplies instead): **0 %**; s ÷ D: 0 %; one mould a cup: 0 % | **100 %** | random 0 % |
| (f) The Recipe Book (6) | adds the same amount (Karplus's additive answer): **0 %**; keeps the butter: 0 %; adds the batch number: 0 % | **100 %** | random 0 % |
| (g) The Night Market (4; a transfer room) | the same fraction of the bigger cake: **0 %** | **100 %** | random 0 % |
| (h) The Hundred Tray (4-5) | longer is larger: **0 %**; shorter is larger: **0 %** | **100 %** | random 0 % |

**What the ladder's model changed** (its `--draft` flag prints the first drafts): (b) boxes drawn anywhere in (0, 2] let
"a fraction is less than one" reach **11.7 %**: four of the room's six orders now go past post one; (c) four random cards
let "order by the top number" reach **2.9 %**, and a same-top pair alone *raised* it to **12.5 %** (that player happens to
order same-top pairs right): every queue now holds a same-top pair *and* a small-top-big-value pair (1/2 and 3/8); (d) one
cake an order let "multiplying always makes bigger" reach **29.4 %** and "a fraction always shrinks" **37.5 %**: three cakes
now go in at once, one shrinking and one growing; (h) decimal queues without a trap let "shorter is larger" reach **2.7 %**:
every queue now holds 0.4, 0.405 and 0.45.

The first unhelped right order in a new setting is recorded as `SkillShown.NEW_SETTING`. The numerals are a transfer test
too: at stage 3 the picture is gone, so only a child who reads "5/6" can act; the School's written exercises and the Book
stay as the outside check (the lead's audit, phase C).

**Wow.** The bakery at dusk with star smoke and a glowing round window; the first pie falling into perfectly equal pieces
with a sparkle; a box ticking along the brass rail and stopping exactly where the flag pops up; the lane's lanterns
lighting one by one; the Feast's long table under the stars, six plates racing and stopping side by side, sprinkles like
fireworks; the dawn after Midnight; in a headset, twisting the knife until six dots glow and slicing through the pie with
your own hand. Each wow *is* the concept (the pieces are equal because the knife is fair; the plates stop together because
the shares are equal; the box stops at the flag because the amount is right), never decoration. **How we check:** the
owner's verdict on phase B, and whether the child shows it to someone.

### 3.10 What the game records as learning (invisible assessment)

The game never asks a question to check. Its evidence model (evidence-centred design, as the leaf's and the altar's;
stealth assessment, LP [G9]; in-game metrics as valid indicators, Semideus [G6]): each **competency** is an idea of §3.4;
each **order** is a situation where the child's acts show it, judged by a rule; the order becomes one `SkillShown` event
for the room's unit.

**The orders of phase B** (unit `g3.maths.unit_fractions`):

| Orders | When | Judged when | Kind | Strength of the evidence |
|---|---|---|---|---|
| O1, O2, O5 | Opening Night's taught orders (the ghost's cut, the trap, the ghost's box) | not judged | — | teaching (a wrong cut here is how the idea is met) |
| O3, O4, O6-O10 | Opening Night | right at the first hand-over, no help, within the cut budget | SOLVED (else HELPED; SHOWN if the ghost finished it) | strong: random cuts and gives 0-6 % per order; trial and error 14-34 % per order, and no player without the idea reaches 7 of 8 above 2.6 % |
| O11, the Feast | the night's end | as above (more buddies, more pies) | SOLVED / HELPED / SHOWN | stronger: the largest table |
| Midnight M1-M6 | the transfer room | as above | NEW_SETTING (else HELPED / SHOWN) | strongest: Opening Night's habit and the whole-number bias hand over none of them right |

So Opening Night gives **8 events** (a round: MasteryRules counts one at 6; 7 of 8 right first time masters the unit, ★★,
its gold once) and Midnight **6 events**, `NEW_SETTING` when unhelped (a full round; its transfer kept apart in
`result.transfer`). Events are added as each order is judged; `record` runs once when the room ends (never on "stop for
now", G0's rule); each SOLVED or NEW_SETTING order pays the first-try gold through `SkillShown.pay_first_try` as it is
judged (the daily cap holds).

**What each event's note says** (the misconceptions, for the journal and the grown-ups): "uneven cut" (a table whose
pieces could not be shared), "left over" (pieces or pies left at a table), "too little", "too much" (a box short of or past
the flag), "halves only" (a cut by 2, 4 or 8 where 3, 5 or 6 was needed), "count not size" (Midnight: the top number of
pieces of another size), "bigger bottom" (make-it-fair: the wrong plate topped up), "over budget" (more cuts than needed),
"ghost step", "eye". An order right but not at the first hand-over, or over its budget, is recorded as `HELPED`, with a note
saying why (the altar's ruling, approved by the lead: SkillShown keeps its four kinds).

**What "help" means:** the ghost's step (after two wrong hand-overs, or on SHOW ME) and the ghost finishing an order make
it HELPED (SHOWN if the ghost finished it). The teaching lines (H3, H5, H12, M2) and M3 (which restates the goal, never the
move) are not help. **Gold:** each SOLVED or NEW_SETTING order pays the School's first-try gold; nothing pays for time.

**The room-to-unit map** (one main unit per room, so each room is a full round for its unit; other units get review events
only when already mastered, as the leaf's ruling 9):

| Rooms | Main unit | What is judged |
|---|---|---|
| 3.1, 3.T1, 3.5 | `g3.maths.unit_fractions` | tables and boxes right first time; Midnight's orders; the tray's fences |
| 3.2 | `g3.maths.fractions_number_line` | loaves cut and given to the right spot; flags set before the slide |
| 3.3, 3.4, 3.T2 | `g3.maths.equivalent_fractions` | leftovers used to the right amount; plates made fair; tins filled |
| 4.1, 4.2 | `g4.maths.equal_fractions` | re-cuts to the order's size; queues in order |
| 4.3 | `g4.maths.add_fractions` | mixed-number boxes; sums and differences at the counter |
| 4.4 | `g4.maths.fraction_times` | repeat orders: the right number of pies cut and given |
| 4.5, 4.T1 | `g4.maths.decimals` (4.T1: `g4.maths.equal_fractions`, NEW_SETTING) | slab orders and decimal queues; the Night Market's same amounts |
| 5.1 | `g5.maths.unlike_fractions` | mixed tins baked right first time |
| 5.2 | `g5.maths.fractions_as_division` | the Great Feast's tables |
| 5.3 | `g5.maths.multiply_fractions` | a fraction of a piece, of a tray, of a number |
| 5.4, 5.T1 | `g5.maths.scaling` | the Size Oven's three-cake orders; the Giant's Picnic |
| 5.5 | `g5.maths.divide_unit_fractions` | moulds set out right before pouring; the right scoop |
| 5.6 | `g5.maths.percent_intro` | the Hundred Tray's orders and the jar |
| 6.1 | `g6.maths.divide_fractions` | servings set out right |
| 6.2, 6.3, 6.T1 | `g6.maths.ratios` | recipes poured in ratio; the big batch; the rocket's fuel |
| 6.4 | `g6.maths.percent` | the sale jar's orders |

**Adaptivity (honest).** After two helped orders in a row, an extra order of the same kind is slipped in and taught again
(the ghost shows its first step; not judged, so the room still gives its full count of judged orders; the journal notes
"re-taught"); the fade moves as §3.6 says. The game's own **baker's journal** (device-only in phase B,
`user://fraction_bakery.json`) keeps, per idea (the cut, the count, sharing, the line, size), how often the child showed it,
with or without help, in which rooms, the misconceptions seen and whether they stopped ("halved a table of three once in
the first night, never since"), and the fade stage; the next room reads it, and phase C can show the grown-ups' page "what
your child showed" in plain words.

**Why this shows learning:** a table is fed fairly first time only by a cut the buddies can share, every piece dealt
equally; a box stops at its flag only with pieces of the right size and the right count; at Midnight only by judging the
size of pieces that are not 1/b. Guessing, the classic errors and half-knowledge were tested and fail (§3.9). What the
orders cannot show (whether the child can *say* why) is the Book's and the grown-ups' business, never a quiz.

### 3.11 The look

**The idea:** a bakery built from the game's own shapes, in the Life rooms' kit look (lit matte shapes, glowing parts, a
few see-through panels), so it is EasyCraft and it runs on a phone and a Quest: cream walls, warm wood, brass, a teal
awning; berry, apple and leek pies; blue dusk outside, gold light inside. The pictures in `fraction-bakery/` are the
sketches:

- `01-the-bakery.png`: the bakery at dusk from the lane (star smoke, the lane's cottages and lanterns, buddies with orders
  in thought bubbles, Hoot on the sign) and inside (the oven, the leftover shelf, the counter and its Fair Line, the board,
  the knife).
- `02-the-fair-knife.png`: the verb in four steps (who's hungry, set the knife, slice, fair), the unfair cut, why the cut
  stays.
- `03-the-fair-line.png`: three quarters sliding piece by piece; too little and too much; a table's plates side by side;
  past one whole.
- `04-opening-night.png`: the night as a timeline, its eleven orders with their times.
- `05-midnight-leftovers.png`: the transfer: the habit's three eighths short of the flag, the idea's six eighths at it, and
  the make-it-fair plates.
- `06-core-loop.png`, `07-the-ladder.png`, `08-things-and-meanings.png`, `09-vr.png`, `10-the-fade.png`,
  `11-later-rungs.png`, `12-cheat-test.png` (the models' results, computed from the models when the pictures are made).

**Scale.** The bakery's room is about 8 m across; the counter 0.9 m high (child height in VR), 2.4 m long; the board 0.6 m
deep in front of the child; a pie 0.32 m across (so a twelfth is about 8 cm at the crust: one hand can pick it), the Fair
Line 1.2 m from post 0 to post 2 (0.6 m a whole) along the counter's front edge, within both hands' reach from the VR spot;
the window 1.2 m ahead, the lane beyond it; the buddies at the table 0.4-0.9 m tall. Flat, the camera looks at the board
and the rail from the front, a little above, with the window behind them (the station view of G0's arena).

**Light:** one warm key light (the lamps and the oven), a cool moonlight fill at Midnight, no shadows (the budget); the
lit cottage windows, the oven's mouth and the ordered parts glow. **Colour:** cream and wood around, brass for the line, the
meaning colours (§3.8) standing out against them. **Motion:** pieces fall apart and settle; plates and boxes glide; buddies
hop; star smoke rises; the Feast's table rolls out.

**Both graphics styles:** phase B has one look (the kit's), used in blocky and realistic; a realistic twin is phase C's.

### 3.12 Kind, fair and safe

Never timed: an order waits as long as the child thinks; a hungry buddy just wiggles. Never lost: a wrong cut becomes the
robin's supper and a fresh pie comes; stopping keeps every lit lantern; nothing happens to the bakery or the lane while
the child is away (no timers, no decay, no streaks, no opening hours in the world). No failure screen: the ghost helps
after two wrong hand-overs. A buddy is never sad or in danger (it tilts its head and waits; no guilt trick). No money
changes hands: the bakery is not a shop (EasyCraft's My Shop is the business game); buddies thank with a hop, and rewards
are the School's fixed gold and stars. No random rewards, no gambling. Food: a village bakery of bread, fruit and
vegetable pies, with a cake only on feast nights; no sweets economy, no "treat" pressure (Life's healthy plate stays
true). No real names. Calm sounds (the "not yet" is a soft "hmm", never a buzzer). Reduce motion (SETTINGS) makes pieces
appear apart instead of falling, plates step to their marks, stills the star smoke and the sprinkles. VR comfort: the child
stands still behind the counter and the orders come to them; blink is the comfort choice for any move.

---

## 4. The tech plan for phase B

### 4.1 What phase B builds

Opening Night and Midnight Leftovers, complete and beautiful, flat and VR: the arrival at dusk, the bakery, its eleven
orders and the Feast, Midnight's six orders and dawn, the knife, the deal and the Fair Line, the judge and the record, the
voice, the sounds and music, the ghost's demonstrations, the buddies and the lane's lanterns, the end card, and a two-room
board (Opening Night again, Midnight). Opened from DISCOVER (the unit page's PLAY for `g3.maths.unit_fractions`, and Hoot's
pick), from the Academy's Maths Workshop door (when the child's unit is in the strand), and by a developer argument.

### 4.2 What G0's and W1's foundation gives, and what this game adds

| The foundation gives (`docs/devlog/parts/play-g0.md`, `play-w1.md`, DEVELOPMENT.md "The foundation's API") | This game adds |
|---|---|
| `PlayVoice.say` / `on()`: every line spoken, cutting in; words only without a voice | the lines as data (`data/play/bakery/lines.json`), each tested for length; the orders' spoken form (`BakeryFade.say`: "three quarters of a pie, please!") |
| `SkillShown`: `begin`, `add(unit, kind, note)`, `pay_first_try`, `record`; the round rule (6 events) | `BakeryBeats`: each order judged into one event with its note |
| `PlayHost`'s pattern: a place far above the world, hiding the screen it came from, its own camera, `LifeReach` for fingers, hands, laser and head, the VR anchor and blink, the idle glow, SHOW ME, the break card, Android Back (`any_open`) | `BakeryHost`: the same pattern for a night of orders (not exercise by exercise): orders arriving at the window and the counter, the knife, the deal, the bell, the slide |
| `LifeGhostFinger` (flat) and `LifeGhostHands` (VR): show a step | the demonstrations: the knife and a deal (O1), the box and the slide (O5); the ghost's step after two wrong hand-overs (the next step of `BakerySolver`'s fewest-cut plan) |
| `PlayGlyph`, `PlayHud`'s ear, eye and break pictures; the screen-word budget | `BakeryHud`: the end card's pictures; zero words in play but the numerals from stage 2 |
| `LifeRoomKit`: shapes and materials the warm-up already holds | `BakeryKit` on top of it: cream walls, wood, brass, crusts and fillings; merged meshes and MultiMeshes |
| `Buddy` (the living buddies' mesher: a block build with googly eyes) and `LifeBuddy` (Life's calm people) | `BakeryCustomer`: a buddy made from a small block build with `Buddy`'s look, no physics, no following; poses: sit, wait, munch, hop |
| `VrGrabber.claimers` (`grip_claim(side)`, `grip_release(side)`: the Build Table's way), `Vr.hand_busy`, `Vr.simulate` / `sim_hand` / `sim_input` | the counter claims a grip near the knife, a piece, the box or the bell (pieces stay MultiMesh instances, not grabbables) |
| DISCOVER, the registry's `signature` entries, P0/P1 and the audit; W1's `AcademyPlaza.opens()` (the lead's switch), `DiscoveryPlays.subject_unit` and the crystals' `DiscoveryPlays.play_for` | one registry entry (`fraction_bakery`) that names a **host** (the mechanism the leaf's review decided; the leaf's phase B2 builds it, §4.7); the door's choice between the bakery and the temple by the child's unit (§3.2) |
| The School's generators (`G3FractionsGen`, `G4FractionsGen`, `G5FractionsGen`, the grade 6 generators) | `BakeryOrders` draws its orders from the same denominators and forms |

### 4.3 Files

- **Pure rules, `core/play/bakery/`** (no nodes; deterministic; seeded; the phase A model's rules, `model/bakery_rules.py`):
  - `BakeryFrac`: exact fractions as two ints (reduced with `NumberAnswer.gcd`), compare, add, multiply; Godot has no
    fraction type and floats would misjudge 1/3 + 1/3 + 1/3.
  - `BakeryBench`: fresh wholes and loose pieces; `cut_whole(n)`, `cut_piece(size, n)`, `take`, counts of cuts.
  - `BakeryKnife`: the dial (2-12), legality, the long swipe across a row.
  - `BakeryOrders`: order forms (table, box; phase B's shelf box and make-it-fair; phase C's tin, tray, loaf, queue, oven,
    scoop, slab, recipe) seeded by night and slot, with Opening Night's composition rules (§3.5) and Midnight's shelves.
  - `BakeryJudge`: the Fair Line's verdict (the amount; fair plates), the cut budget, SOLVED / NEW_SETTING / HELPED /
    SHOWN, the note (uneven cut, left over, too little, too much, halves only, count not size, bigger bottom, over budget,
    ghost step, eye).
  - `BakerySolver`: the fewest-cut plan for an order (the model's `plan_target` and `plan_equalize`): the ghost's next step
    and the budget.
  - `BakeryBeats`: one order into one `SkillShown` event.
  - `BakeryFade`: an order card at a stage (picture, picture and numeral, numeral, symbols) and its spoken form (at most 12
    words).
  - `BakeryNights`: the catalogue (`data/play/bakery/nights.json`): each room's orders (form, taught or judged, its buddy),
    lines, music, unit, unlocks; the ladder.
  - `BakeryProgress`: the lane (lanterns lit, the sign's stars), the baker's journal, the fade stage; a device file in
    phase B (`user://fraction_bakery.json`, like `PlayQuests`).
  - `BakeryHandRules` (VR): the knife's twist to a count, a slice's swing, which plate or box a hand is over.
- **The place, `entities/play/bakery/`:** `BakeryHost` (open/close, input, camera, VR, the demonstrations, the record, the
  `finished` / `stopped` signals as `PlayHost`'s, `any_open`), `BakeryShop` (the room: walls, oven and fire, counter,
  window, shelf, the lane outside with its cottages and lanterns), `FairKnifeModel` (handle, blade, 12 dot-lights),
  `PieModel` (pies and pieces: wedge meshes generated once per count 1-12 and cached, drawn as MultiMeshes per size and
  filling; loaves and trays in phase C), `FairLine` (the rail, posts, the sliding box or plates, the flag, the ticks),
  `BakeryCustomer` (a buddy at the table or the counter, its thought bubble), `FeastTable` (the long table, its plates and
  rails), `LeftoverShelf`, `RobinModel`, `BakeryKit` (shapes and materials over `LifeRoomKit`).
- **UI, `ui/play/bakery/`:** `BakeryHud` (the ear, the eye, the break, the end card, the room board; pictures only).
- **Data:** `data/play/bakery/nights.json`, `data/play/bakery/lines.json`; the unit's `play` block names the game (§4.7).
- **Sounds:** `tools/make_bakery_sfx.py` (the knife's clicks and "ting", the slice, plates' clack, the rail's ticks, the
  flag's pop, the chime, the bell, the robin, the buddies' babble and munch, the oven's crackle and snore); the music is in
  `assets/`.
- **Tools:** `tools/bakery_smoke.gd` (plays both rooms with the idea bot, flat and simulated VR, headless; checks the
  record), `tools/bakery_shots.gd` (pictures in a real window: the arrival, a cut, a slide, the Feast, Midnight, dawn),
  `tools/bakery_bench.gd` (draws and frame times, VR preview, like `vr_bench.gd`).

### 4.4 Flat and VR

**Flat (phones, tablets, PC, the web).** The camera looks at the board and the rail from the front, a little above, the
window and the lane behind them. **The knife:** a tap on the knife lifts it over the board and shows its 12 dots big; a tap
on the nth dot sets n (the dots light, a click each); a swipe across a pie (or along a row of pies) cuts. **Pieces:** a tap
on a piece lifts it (it rises and glows), a tap on a plate or the box puts it there; a drag does both; a sweep across the
plates deals one piece to each in turn; a tap on a placed piece lifts it again (free until the hand-over). **The hand-over:**
the bell (a table) glows when every plate holds a piece and is tapped; a box is pushed by a drag towards the rail (or a tap
on it, then on the rail). Every target is at least a fingertip (`LifeReach.screen_pick`) and inside the view's free band
(`PlayHud.FREE`); a pie on a phone is drawn large enough that a twelfth is a fingertip wide. A developer argument opens a
room directly (`--bakery-night=opening` or `midnight`).

**VR (the Quest 3).** The child stands behind the counter (`Vr.anchor`), the board 0.45 m in front, the rail along the
counter's edge and the bell within both hands' reach. **The knife:** a grip near its hook takes it (the counter claims the
grip: `grip_claim(side)`); twisting the wrist turns the handle, one click (a buzz) and one more lit dot every 30°; a swing
through a pie cuts it (a velocity threshold; a slow drag does nothing, so a hand resting on the board never cuts). **Pieces:**
a grip on a piece lifts it; letting go over a plate or the box puts it there (the plate glows under the hand); letting go
elsewhere returns it to the board. **The box:** an open hand shoves it along the counter; it glides by itself to its amount.
**The bell:** a palm press. **One-handed** (a comfort setting, or a child holding one controller): a trigger on the knife
adds a dot, a trigger on a pie cuts, a trigger on a piece then a plate deals. The HUD stays hidden; the raised forearm
shows the small panel (owner #127). Hoot perches on the counter's end, his voice placed there. Tests drive it with
`Vr.simulate`, `sim_hand`, `sim_input`.

### 4.5 The budget

Targets: **≥ 30 FPS average and no frame over 100 ms on the emulator**; **≤ 100 draws a frame on the Quest** (the floor
preset, 72 Hz), aim ≤ 70; one light, no shadows; only shaders the warm-up holds (the kit's materials; a new one goes into
the census with its test). Estimated draws at the heaviest moment (the Feast): the room's shell (walls, floor, roof beams)
merged 3; the oven 2 and its fire 1; the counter and window frame merged 1; the rail and its posts 2; the board 1; pies and
pieces as MultiMeshes per size and filling (at most four sizes at once × crust and filling) 8; plates 1; the box 1; the
knife 2 and its dots 1; the shelf 1; the lane outside (cottages merged 1, lanterns 1, the moon and sky 1); the Feast's table
1 and its rails 1; buddies (each merged into one mesh plus eyes as one MultiMesh for all) 6-8 + 1; thought bubbles 2; the
flag 1; the robin 1; Hoot 5; the VR hands 4 (flat: none); the HUD canvas 10-20 (pictures batched like `CanvasBatch`) →
**about 60-75**. Opening Night's ordinary orders: about 45-55; Midnight: about 45. A MultiMesh's per-instance colour
changes its shader, so each filling is its own MultiMesh (no census change), as the leaf found.

### 4.6 Tests (TDD, each failing first)

- `tests/unit/test_bakery_frac.gd`: exact sums, products and comparisons; 1/3 + 1/3 + 1/3 = 1.
- `tests/unit/test_bakery_bench.gd`, `test_bakery_knife.gd`: a cut makes n equal pieces and is final; re-cutting a piece;
  counts 2-12 only; the long swipe cuts each pie the same; no undo.
- `tests/unit/test_bakery_judge.gd`: a fair table (every plate the same, nothing left, every pie used); a box at its amount
  (any equivalent); too little and too much; the cut budget; SOLVED, NEW_SETTING at Midnight, HELPED after help, a wrong
  hand-over or over budget, SHOWN when the ghost finishes; every note.
- `tests/unit/test_bakery_solver.gd`: the fewest-cut plan for every order form (tables, boxes, shelf boxes with re-cuts,
  make-it-fair plates).
- `tests/unit/test_bakery_orders.gd`: every generated order can be made within its budget; Opening Night's composition
  (the rules table's composition, slot by slot); Midnight's shelves always hold a plan; the denominators
  are the generators'.
- `tests/unit/test_bakery_cheat_bots.gd`: **the cheat test as a test**, the models' players over 1,000 seeded visits:
  random, trial and error, halving, twelfths-and-deal, one piece each, turning n/p round reach Opening Night's bar in under
  3 %; the idea bot in over 99 %; the slip bot in over 80 %; at Midnight the habit and the bias never, the idea always.
- `tests/unit/test_bakery_fade.gd`: the card at every stage; the spoken form at most 12 words and in words ("three
  quarters").
- `tests/unit/test_bakery_nights.gd`: the data: every room names a written unit; every line at most 12 words and never a
  question that needs reading; every room has its hook and see-why lines.
- `tests/unit/test_bakery_hand_rules.gd` (VR): the twist's clicks, the slice's swing threshold, release over a plate.
- `tests/integration/test_bakery_place.gd`: every target in the flat view's free band and at least a fingertip (a twelfth
  too); everything within both hands' reach from the VR spot; only warmed shaders; no shadows.
- `tests/integration/test_bakery_host.gd`: flat and simulated VR through both rooms: the arrival, the demonstrations, the
  trap, the box, the Feast, midnight, dawn, the record (`SkillShown` events, the stars), the break, stop for now (nothing
  recorded), Android Back.
- `tests/integration/test_bakery_voice.gd`: every line spoken by itself; no word on the screen but the numerals from
  stage 2.
- `tests/integration/test_bakery_budget.gd`: draws at the Feast ≤ 100 (the place's own counter).
- The full suite once at the end; the smoke; pictures in a real window; the bench; then the lead on the emulator and the
  Quest, and the owner's child.

### 4.7 The hooks phase B needs from others (the lead decides: §8)

1. **The registry for a deep game with its own host**, as the leaf's review decided: `data/play/mechanics.json`'s
   `"signature": {"fraction_bakery": {"name": "Fraction Bakery", "host": "res://entities/play/bakery/bakery_host.gd"}}`
   and `SchoolScreen`'s PLAY opening a host when the unit's `play.game` names one. (DEVELOPMENT.md's example of a signature
   entry already names `fraction_bakery` as a `PlayStation` script; the bakery is a scene with its own host, the second
   way that section allows.) The leaf's phase B2 builds this mechanism; if it has merged, the bakery adds one entry; if
   not, the bakery's B2 builds it the same way.
2. `g3.maths.unit_fractions`'s `play` block: `{"game": "fraction_bakery", "params": {"night": "opening"}}` (a content
   file).
3. Back and the pause key belong to the bakery while it shows (`BakeryHost.any_open` beside `PlayHost.any_open` in
   `menu.gd`; W1's `room_open` / `close`).
4. W1's Academy: the Maths Workshop door (`AcademyPlaza.opens`) and a crystal's choice open the bakery when the child's
   unit is one it covers (in phase B: `g3.maths.unit_fractions`), the temple when it is the temple's (§3.2's table).

### 4.8 The order of work (one agent, three briefs of two sessions; the lead checks between)

1. **The bakery works** (sessions 1-2): `BakeryFrac`, `BakeryBench`, `BakeryKnife`, `BakeryOrders`, `BakeryJudge`,
   `BakerySolver`, `BakeryBeats`, `BakeryFade`, the data, `BakeryProgress`, the bots as tests (the models' thresholds);
   then the places (`BakeryKit`, `BakeryShop`, `PieModel` with its wedge meshes, `FairLine`, `FairKnifeModel`,
   `BakeryCustomer`) and their pictures in a real window; the draws counted.
2. **The bakery opens** (sessions 3-4): `BakeryHost` flat (input, the knife, the deal, the bell, the slide, the
   demonstrations, the voice and the orders' spoken form, the record, the end card, DISCOVER's and the Academy's hooks),
   then VR (the grip claimer, the twist and the slice, carrying pieces, the shove, the bell, ghost hands, comfort), the
   budget bench.
3. **The bakery glows** (sessions 5-6): Midnight complete, the Feast, sounds and music, juice (the pieces falling apart, the
   sparkle, the ticks and the flag, the hop, the lanterns, the sprinkles, dawn), the smoke, the full suite; fixes after the
   lead's emulator and Quest check and the owner's child's first play.

---

## 5. Phases and estimates

| Phase | What | Gate | Estimate |
|---|---|---|---|
| **A** (this) | research and design | the lead's review; the owner sees `fraction-bakery-owner.md` | done |
| **B** | Opening Night and Midnight Leftovers, complete and beautiful, flat and VR | played on the emulator (≥ 30 FPS, no frame > 100 ms) and the Quest (≤ 100 draws, 72 Hz); the owner's child plays; the five tests checked honestly (the bots, no words but numerals, Midnight solved unhelped, the child's choice, the owner's wow) | **6 agent sessions** (one agent; 5 if the leaf's B2 host hook has merged and Balance Altar's phase B has proved the deep-game host pattern; 5-8 with surprises) |
| **C** | the ladder at its minimum (20 rooms: 3.2, 3.3, 3.4, 3.5, 3.T2, 4.1, 4.2, 4.3, 4.4, 4.5, 4.T1, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.1, 6.2, 6.4), each with its orders and events; the sixteen units to P1; the bakery in the Academy's courtyard with its lane; the fade across the rungs; the progress in the profile; the School's written exercises as a before-and-after check (learning-is-play G6) | the full suite; the lead's device check; playtest data | about 20-26 agent sessions (new tools: tins and the big trays, the cupcake tray, loaves, the slab and the Hundred Tray, the Size Oven, scoops, the recipe book) |
| **D** | grow: the remaining rooms (3.T2's variants, 5.T1, 6.3, 6.T1), your own order or recipe for a friend, the child's own buddies as customers, baking together online, the realistic twin | voluntary time, returns, transfer in playtests | ongoing |

---

## 6. Risks

| Risk | Why it matters | What we do |
|---|---|---|
| Too easy once the knife clicks | a bored child stops choosing it | Opening Night is short (6 minutes); every rung adds a tool or breaks a habit; the grade picks the rung; the Feast and Midnight need judgement |
| A bakery feels babyish to an 11-12-year-old, or "not for me" to some children | choice | the buddies, the knife, the Feast, the Size Oven's giants, the rocket fuel; the owner's child decides; a redesign if nobody comes back |
| The knowledge stays in the bakery (pies only) | transfer | the Fair Line on every order (the number line), the fade to numerals and symbols, transfer rooms (Midnight, the Picnic, the Night Market, the Giant's Picnic), the School's exercises as the outside check in phase C |
| The knife does the partitioning, so children never practise making equal parts | 3.NF.1 and 3.G.2 are about equal parts | the trap (O2) and every table make "equal" the goal; the Picnic judges equal parts of different shapes; the slab and trays partition by rows and groups |
| Dealing many pieces is tedious on a phone (three pies for eight buddies is 24 pieces) | choice | the sweep deals one piece to each plate in turn; a long swipe cuts a row of pies; pieces large enough to hit |
| Fat fingers on a twelfth | a mis-tap could cost a star | pieces at least a fingertip; a lift alone changes nothing; moving pieces is free until the hand-over; the bell glows only when every plate holds a piece |
| The Fair Line's slide is a fiction (a box doesn't move by its content) | honesty; a curious child asks | the honesty table; the Book says it is the bakery's magic measure |
| VR: the twist and the slice need tuning | access and comfort | the grip claimer's thresholds; one-handed mode; tested on the Quest |
| The voice (text-to-speech saying fractions; a device with none) | rule 0 needs a voice | lines pass words, never "3/4"; `PlayVoice`'s words when there is none (G0 ruling 28); a recorded voice is the owner's later choice |
| The evidence is noisy (a slip, a lucky cut) | stars must mean something | eight judged orders a night, the cut budget, transfer rooms; the slip player still masters 88 % (Opening Night) and 97.6 % (Midnight) |
| Overlap with other games (My Shop's bakery in the Market Square, Ratio Kitchen, Market Change, Frog Jump) | confusion, duplicated work | no money in this bakery; ratios stop at recipes; decimal algorithms and the integer line are left to their games (rulings 18, 30, 31) |
| Food messaging (a bakery in a game that teaches healthy plates) | consistency with Life | bread, fruit and vegetable pies; a cake only on feast nights; no treat economy |
| Lanterns and the village become a collecting pressure | no FOMO | no timers, no decay, no streaks, no opening hours; lanterns stay lit for ever |
| The registry and the menus' hooks (G0's and W1's files) | without them DISCOVER can't open the bakery | the lead's decision (§8); the leaf's B2 mechanism; a developer argument meanwhile |
| Scope (four rungs, about 24 rooms) | a long tail | the phases; phase C's minimum ladder; one place (the bakery) re-dressed for every room |

---

## 7. Rulings (each with its cost if wrong)

1. **The core verb is the cut**: the Fair Knife cuts only equal pieces into a chosen count (2-12); the count is the bottom
   number, the pieces given the top. *Cost:* the knife does the partitioning; children don't practise drawing equal parts
   by hand (the Picnic and the trays judge equal parts instead).
2. **Every order is judged on the Fair Line**, the counter's brass rail (one whole from post to post), sliding piece by
   piece to its amount; the buddy's flag then shows the true spot. *Cost:* a fiction (the honesty table) and about a second
   of motion per order.
3. **No preview of the cut lines on a judged order** (a faint ghost line on taught orders only). *Cost:* a beginner cannot
   see five pieces before cutting; the ghost helps after two misses.
4. **Every cut is final**; a wrong cut's pie becomes crumbs for the robin and a fresh pie comes. *Cost:* an explorer's
   curiosity costs that order's star (the taught orders are free to explore). The model: an undo lets trial and error reach
   the bar on 100 % of visits; with the cut final, 0 %.
5. **The Fair Line moves only at the hand-over.** *Cost:* no feel of the amount while building; it is the price of honest
   first-time evidence (G0's Make it rule).
6. **Moving pieces between plates, or back to the board, is free until the hand-over.** *Cost:* none for the evidence: the
   amount is still unknown until the slide; a child who sees an uneven deal may fix it (self-correction, not search).
7. **The cut budget is the fewest cuts that can make the order, plus one.** *Cost:* a child who cuts spare pies loses that
   order's star.
8. **Any fair split counts**: finer pieces (six eighths for three quarters), mixed cuts (a half and a sixth for two
   thirds). *Cost:* none known; the twelfths-and-deal player is right wherever twelfths share, and the model shows it still
   can't reach the bar.
9. **Opening Night's numbers** (§3.5's rules table): tables mostly of 5, 6 and 8 buddies (an odd number of pies at 8),
   two orders that halving can never make (two pies for 3 or 5; a box in thirds, fifths or sixths), boxes in thirds to
   eighths. *Cost:* fifths go beyond the Common Core's grade 3 list (2, 3,
   4, 6, 8), though our own grade 3 generators already use them (open question 5). The model: grade 3's denominators alone
   let twelfths-and-deal pass 100 %.
10. **Opening Night and Midnight are everyone's first rooms; then the grade picks the rung.** *Cost:* a grade-6 child spends
    ten minutes on grade-3 ideas once.
11. **At midnight the oven sleeps: no fresh pies.** *Cost:* a fiction; it is the transfer test's design (the model: with a
    fresh pie the habit fills every box order).
12. **Midnight's orders are NEW_SETTING events for `g3.maths.unit_fractions`** ("a/b is a parts of size 1/b": the size is
    what Midnight tests). *Cost:* equivalence (3.NF.3) gets no events until room 3.3 (open question 1).
13. **Teaching orders are not judged** (three in Opening Night). *Cost:* 8 events a night, not 11.
14. **An order right but not at the first hand-over, or over its budget, is recorded as HELPED with a note.** *Cost:* as
    the altar's (the lead approved it there).
15. **Hoot speaks every order in words at every stage.** *Cost:* at stage 3 a child can act on the voice alone, so reading
    the numeral is supported, not forced; the School's written exercises and the Book stay the check of reading.
16. **The fade moves with play; the grade sets the start** (3: pictures; 4: pictures and numerals; 5-6: numerals). *Cost:*
    children of one grade see different stages; the Book always shows the symbols.
17. **The customers are the village's buddies** (living-buddy look); the child's own woken buddies may come in phase D.
    *Cost:* phase B's buddies are not the child's own.
18. **No money in the bakery** (buddies thank with a hop). *Cost:* the bakery doesn't teach money (My Shop and Market Change
    do).
19. **Food: bread, fruit and vegetable pies; a cake only on feast nights.** *Cost:* less candy appeal.
20. **Never timed, never lost, no opening hours in the world.** *Cost:* no speed practice; no "come back tonight" hook (that
    hook would be a pressure trick).
21. **Phase B ships Opening Night and Midnight Leftovers**, so the gate can check all five tests. *Cost:* the line,
    equivalence and adding wait for phase C.
22. **The bakery is a place of its own in phase B**; phase C puts it in the Academy's courtyard with its lane. *Cost:* phase
    B's bakery isn't seen from the world.
23. **The Maths door (and Hoot's pick) opens the deep game that teaches the child's current maths unit** (the bakery or the
    temple), G0's round otherwise. *Cost:* the door doesn't offer a choice itself (in phase C both places can be walked into).
24. **Tins take only pieces of their sections' size.** *Cost:* a fiction (a real tin takes anything), standing for "only
    same-size parts can be counted together".
25. **The Size Oven is Size Magic**: × a fraction scales a cake. *Cost:* in the world Size Magic is the child's power; here
    it is the oven's (said once in the Book).
26. **The Size Oven bakes three cakes at once, at least one shrinking and one growing.** *Cost:* busier orders; the model:
    one cake an order let "a fraction always shrinks" reach 37.5 %.
27. **Every queue holds a same-top pair and a small-top-big-value pair; every decimal queue holds 0.4, 0.405, 0.45.** *Cost:*
    the queues' shapes repeat (their numbers still vary); the model: without the traps, guessing rules reached 2.7-12.5 %.
28. **Four of the Baguette Counter's six orders go past one loaf.** *Cost:* fewer proper fractions in that room (Opening
    Night has them); the model: boxes anywhere let "a fraction is less than one" reach 11.7 %.
29. **Pairs whose common size is above 12 use big rectangular trays (24 sections) in phase C.** *Cost:* one more tool.
30. **Ratios in the bakery stop at recipes, ratio tables and percent (6.RP.1, 3a, 3c); rates and proportional relationships
    are Ratio Kitchen's.** *Cost:* two games share the ratio topic (open question 3).
31. **Decimals in the bakery are names for the same share (tenths, hundredths, percent); the decimal algorithms (5.NBT.7)
    stay with Market Change and Frog Jump.** *Cost:* the three decimal units stay P0 until those games (open question 4).
32. **Hoot cuts unfairly on purpose only from rung 5, and sparingly.** *Cost:* less protégé effect; incorrect examples did
    not add to correct ones for decimals [F24].
33. **In VR the knife is held and twisted, pieces are carried by hand, the box is shoved, the bell pressed; the two-hand pour
    is a warm-up, not judged; one-handed play stays possible.** *Cost:* a twist gesture to tune on the Quest.
34. **Music from the repo's public-domain and CC0 recordings** (Eine kleine Nachtmusik, the Moonlight Sonata, Morning Mood,
    Waltz of the Flowers, Spring, Gymnopédie, Air on the G String). *Cost:* none.
35. **The models' rules are phase B's starting rules** (`model/bakery_rules.py`), and the bots become tests. *Cost:* a
    little test time (the rules run headless in milliseconds).
36. **No real names in the game** (the studies and apps stay in this document). *Cost:* none.
37. **The bakery's state is a device file in phase B**, the profile in phase C (merged so nothing is lost). *Cost:* a new
    device starts with a dark lane in phase B.
38. **One main unit per room.** *Cost:* Opening Night's sharing tables (5.NF.3's idea, seeded early) count for 3.NF.1.

---

## 8. Open questions for the lead

1. **Midnight's events**: NEW_SETTING for `g3.maths.unit_fractions` (my proposal: 3.NF.1's "parts of size 1/b" is what it
   tests, and it keeps one main unit per room), or SOLVED events for `g3.maths.equivalent_fractions` (a first round of
   equivalence)?
2. **The registry for a deep game with its own host**: adopted from the leaf's B2 when it merges (my proposal, as the
   altar's review decided), or built by the bakery's B2 if the leaf's hasn't landed?
3. **Ratios**: the bakery's rung 6 takes recipes, ratio tables and percent, and hands rates and proportion to Ratio Kitchen
   (my proposal), or does the recipe book grow into Ratio Kitchen (one game for ratios, grades 6-8)?
4. **Decimals**: the bakery teaches decimals as names for the same share and leaves the three decimal-algorithm units P0
   for Market Change and Frog Jump (my proposal), or should the bakery take `g5.maths.decimal_place_value` too (the slab to
   thousandths through a Size Magic zoom)?
5. **Fifths in the prologue**: tables of 5 and boxes in fifths (my proposal: our own grade 3 generators use them, and the
   model needs a table the twelfths can't share), or the Common Core's grade 3 list only (2, 3, 4, 6, 8: then tables of 8
   with an odd number of pies must carry the weight, and the model is re-run)?
6. **Where the bakery lives in phase C**: a building in the Academy's courtyard with its lane behind (my proposal), or a
   room inside the Maths Workshop?
7. **The Maths door for grades 5-6**: by the child's current unit (my proposal, §3.2), or a picture choice at the door
   (a pie or a crystal)?
8. **The child's own buddies as customers** (phase D): their woken buddies from their world come to order (my proposal), or
   the village's buddies only?
9. **When phase B starts** relative to the leaf's B2-B3 and Balance Altar's B (the cap of three agents).
10. **The food** (the owner's taste): a village bakery of bread, fruit and vegetable pies with a feast-night cake (my
    proposal), or freer cakes and sweets?
11. **The grown-ups' page** (phase C): the baker's journal in plain words ("Halved a table of three once in the first night,
    never since; made six eighths into three quarters by themself at midnight")?

---

## 9. The honesty table: what is real, what is simplified, what is fiction

| In the game | Real? | Note |
|---|---|---|
| A fraction is equal parts of a whole; the bottom number counts them, the top counts those taken | real | 3.NF.1 |
| A table of n pies for p buddies gives each n/p | real | fractions as division (5.NF.3) |
| The Fair Knife always cuts equal pieces | **magic** | a real knife can't; the equal parts are the precondition the knife makes certain (the Picnic judges equal parts by eye) |
| The Fair Line: a box slides by its content and stops at its amount | **fiction** | a real number line, a magic measure; it shows magnitude, the thing to learn |
| All pies are the same size | **simplified** | the "same whole" is assumed and the Night Market breaks it on purpose (4.NF.2's caveat) |
| Amount of pie = the fraction | simplified | uniform pies; crumbs ignored |
| Re-cutting a piece into equal smaller pieces | real | equivalent fractions by splitting (multiplying top and bottom) |
| Tins whose sections take only one size | **fiction** | stands for "only same-size parts can be counted together" (common denominators) |
| The cupcake tray's groups | real | a fraction of a set |
| The Size Oven scaling a cake | real maths, magic look | multiplication as scaling (5.NF.5); the cake's area would scale by the square: the oven scales "how much cake", said once in the Book |
| Scoops: how many fit | real | measurement division (5.NF.7, 6.NS.1) |
| The Hundred Tray and the jar | real | hundredths, decimals and percents as names for the same share |
| Recipes in ratio | real, simplified | real baking chemistry is not exactly linear; the ratio idea is exact |
| The robin, the buddies, the night village, Hoot | **fiction** | EasyCraft's world |

---

## 10. Sources

Learning-is-play's sources (`docs/design/learning-is-play.md` §10, cited here as LP [G3], [G4], [G7], [G8], [G9]) and
Balance Altar's (`docs/design/games/balance-altar.md` §10, cited as BA [C1], [C2], [C5], [C7], [G19]) are used as they
are. New here (reading the web only; nothing was downloaded except one PDF the fetch tool saved by itself, which was
deleted unread: `docs/devlog/parts/game-bakery-a.md` says so):

**Children's fractions: misconceptions and what fixes them**
- [F1] Siegler, R. S., Thompson, C. A., & Schneider, M. (2011). An integrated theory of whole number and fractions
  development. *Cognitive Psychology*, 62, 273-296. https://doi.org/10.1016/j.cogpsych.2011.03.001 ;
  https://www.uni-trier.de/fileadmin/fb1/prof/PSY/PAE/Forschung/SieglerEtAl2011.pdf
- [F2] Siegler, R. S., Duncan, G. J., Davis-Kean, P. E., Duckworth, K., Claessens, A., Engel, M., Susperreguy, M. I., &
  Chen, M. (2012). Early predictors of high school mathematics achievement. *Psychological Science*, 23(7), 691-697.
  https://doi.org/10.1177/0956797612440101 ; https://www.cmu.edu/news/stories/archives/2012/june/june15_mathsuccess.html
- [F3] Siegler, R. S., & Pyke, A. A. (2013). Developmental and individual differences in understanding of fractions.
  *Developmental Psychology*, 49(10), 1994-2004. https://pmc.ncbi.nlm.nih.gov/articles/PMC4103412
- [F4] Schneider, M., Merz, S., Stricker, J., De Smedt, B., Torbeyns, J., Verschaffel, L., & Luwel, K. (2018). Associations
  of number line estimation with mathematical competence: a meta-analysis. *Child Development*, 89(5), 1467-1484.
  https://doi.org/10.1111/cdev.13068 (the fractions-versus-whole-numbers figures as reported by a later paper:
  https://jnc.psychopen.eu/index.php/jnc/article/download/7617/7617.html?inline=1)
- [F5] Ni, Y., & Zhou, Y.-D. (2005). Teaching and learning fraction and rational numbers: the origins and implications of
  whole number bias. *Educational Psychologist*, 40(1), 27-52. https://doi.org/10.1207/s15326985ep4001_3
- [F6] Siegler, R., Carpenter, T., Fennell, F., Geary, D., Lewis, J., Okamoto, Y., Thompson, L., & Wray, J. (2010).
  *Developing effective fractions instruction for kindergarten through 8th grade* (IES practice guide, NCEE 2010-4039).
  https://ies.ed.gov/ncee/wwc/PracticeGuide/15
- [F7] Post, T. R. (1981). Fractions: results and implications from National Assessment. *The Arithmetic Teacher*
  (the 12/13 + 7/8 item's percentages for 13-year-olds, as reproduced by the Lesson Study Alliance:
  https://lessonresearch.net/course/task-1 ; the sources disagree on the assessment's year); Carpenter, T. P., Corbitt,
  M. K., Kepner, H. S., Lindquist, M. M., & Reys, R. E. (1981), *Results from the second mathematics assessment of the
  National Assessment of Educational Progress*, NCTM.
- [F8] Fraction Face-Off!: Fuchs, L. S., Schumacher, R. F., Long, J., Namkung, J., Hamlett, C. L., Cirino, P. T., Jordan,
  N. C., Siegler, R., Gersten, R., & Changas, P. (2013). Improving at-risk learners' understanding of fractions. *Journal of
  Educational Psychology*, 105(3), 683-700; Fuchs et al. (2016), *Elementary School Journal* (213 students, effect 0.39; the
  NAEP effect mediated by the measurement interpretation): https://edknowledge.stanford.edu/node/275 ; Fuchs, Malone,
  Schumacher, Namkung & Wang (2017), *Journal of Learning Disabilities*, 50(6), 631-639 (five trials):
  https://edknowledge.stanford.edu/node/274 ; Blueprints' rating ("Promising"; developer-conducted):
  https://blueprintsprograms.org/programs/848999999/fraction-face-off
- [F9] Moss, J. (2005). Pipes, tubes, and beakers: new approaches to teaching the rational-number system. In National
  Research Council, *How Students Learn: History, Mathematics, and Science in the Classroom*.
  https://www.nationalacademies.org/read/10126/chapter/8
- [F10] Empson, S. B. (1999). Equal sharing and shared meaning: the development of fraction concepts in a first-grade
  classroom. *Cognition and Instruction*, 17(3), 283-342. https://doi.org/10.1207/s1532690xci1703_3 ; Empson, S. B., Junk,
  D., Dominguez, H., & Turner, E. (2006). Fractions as the coordination of multiplicatively related quantities.
  *Educational Studies in Mathematics*, 63, 1-28. https://link.springer.com/article/10.1007/s10649-005-9000-6
- [F11] Pothier, Y., & Sawada, D. (1983). Partitioning: the emergence of rational number ideas in young children. *Journal
  for Research in Mathematics Education*, 14, 307-317 (its halving strategies as cited in Charles & Nason, MERGA 1999:
  https://merga.net.au/wp-content/uploads/DOCS/common/Uploaded%20files/Annual%20Conference%20Proceedings/1999%20Annual%20Conference%20Proceedings/RP_Charles_Nason_1999.pdf)
- [F12] Hamdan, N., & Gunderson, E. A. (2017). The number line is a critical spatial-numerical representation: evidence
  from a fraction intervention. *Developmental Psychology*, 53(3).
  https://ecrhub.org/publications/number-line-critical-spatial-numerical-representation-evidence-fraction-intervention
- [F13] Gunderson, E. A., Hamdan, N., Hildebrand, L., & Bartek, V. (2019). Number line unidimensionality is a critical
  feature for promoting fraction magnitude concepts. *Journal of Experimental Child Psychology*, 187, 104657.
  https://doi.org/10.1016/j.jecp.2019.06.010
- [F14] Fischbein, E., Deri, M., Nello, M. S., & Marino, M. S. (1985). The role of implicit models in solving verbal
  problems in multiplication and division. *Journal for Research in Mathematics Education*, 16(1), 3-17; the 2022
  replication with 902 grade 7 students (Giberti & Maffia), as reported: https://iris.unimo.it/handle/11380/1381693
- [F15] Siegler, R. S., & Lortie-Forgues, H. (2015). Conceptual knowledge of fraction arithmetic. *Journal of Educational
  Psychology*, 107, 909-918. https://doi.org/10.1037/edu0000025
- [F16] "Number of parts only: unequal areas" (Australian Association of Mathematics Teachers, Make It Count: Top Drawer):
  https://makeitcount.aamt.edu.au/Topdrawer/Fractions/Misunderstandings/Number-of-parts-only/Unequal-areas
- [F17] Virginia Department of Education (2025), fractions guidance for teachers:
  https://www.doe.virginia.gov/home/showpublisheddocument/75719/639045082610070000
- [F18] Mitchell, A. (2005), MERGA conference paper on fraction instruction as counting:
  https://merga.net.au/wp-content/uploads/DOCS/common/Uploaded%20files/Annual%20Conference%20Proceedings/2005%20Annual%20Conference%20Proceedings/Mitchell%20RP612005.pdf
- [F19] Steinle, V., & Stacey, K. The Learning Decimals project's prevalence of misconceptions, Years 4 to 10 (3,204
  students, 12 Victorian schools): https://extranet.education.unimelb.edu.au/SME/TNMY/Decimals/Decimals/tests/incidenc.htm
- [F20] Moss, J., & Case, R. (1999). Developing children's understanding of the rational numbers: a new model and an
  experimental curriculum. *Journal for Research in Mathematics Education*, 30(2), 122-147.
  https://www.nctm.org/Publications/Journal-for-Research-in-Mathematics-Education/1999/Vol30/Issue2/Developing-Children_s-Understanding-of-the-Rational-Numbers_-A-New-Model-and-an-Experimental-Curriculum/
- [F21] Karplus's Mr Short and Mr Tall task, as described in "Proportional reasoning":
  https://en.wikipedia.org/wiki/Proportional_reasoning
- [F22] Noelting, G. (1980). The development of proportional reasoning and the ratio concept (the Orange Juice
  Experiment), part I. *Educational Studies in Mathematics*, 11, 217-253; a study of 704 students aged 11-16 with
  Noelting's levels: https://www.scielo.sa.cr/pdf/uniciencia/v37n1/2215-3470-uniciencia-37-01-382.pdf
- [F23] Cramer, K. A., Post, T. R., & delMas, R. C. (2002). Initial fraction learning by fourth- and fifth-grade students:
  a comparison of the effects of using commercial curricula with the effects of using the Rational Number Project
  curriculum. *Journal for Research in Mathematics Education*, 33(2), 111-144.
  https://www.nctm.org/Publications/journal-for-research-in-mathematics-education/2002/Vol33/Issue2/Initial-Fraction-Learning-by-Fourth--and-Fifth-Grade-Students_-A-Comparison-of-the-Effects-of-Using-Commercial-Curricula/
- [F24] Durkin, K., & Rittle-Johnson, B. (2012). The effectiveness of using incorrect examples to support learning about
  decimal magnitude. *Learning and Instruction*, 22, 206-214. https://ir.vanderbilt.edu/handle/1803/11934
- [F25] Abrahamson, D., the Mathematical Imagery Trainer for Proportion (Kinemathics, UC Berkeley's Embodied Design
  Research Laboratory): https://edrl.berkeley.edu/projects/kinemathics
- [F26] The National Mathematics Advisory Panel (2008), *Foundations for Success*: students' difficulty with fractions is
  "pervasive" and "a major obstacle" to algebra, as reported:
  https://www.edweek.org/teaching-learning/panel-calls-for-systematic-basic-approach-to-math/2008/03

**Games and apps**
- [G1] Slice Fractions (Ululab): Cyr, S., Riopel, M., & Charland, P. (2016). Game design of a video game on fractions
  concept learning in elementary school students. *EDULEARN16 Proceedings*, 4575-4582.
  https://library.iated.org/view/CYR2016GAM ; the developer's "+10.5 %" claim (self-reported):
  https://apps.appfollow.io/ios/slice-fractions/794730213?country=ca
- [G2] Riconscente, M. M. (2013). Results from a controlled study of the iPad fractions game Motion Math. *Games and
  Culture*, 8(4), 186-214. https://doi.org/10.1177/1555412013496894 ; the study's announcement:
  https://joanganzcooneycenter.org/2011/12/21/but-are-they-really-learning/
- [G3] Refraction (University of Washington, Center for Game Science): https://news.cs.washington.edu/?p=14236 ; O'Rourke,
  E., Haimovitz, K., Ballweber, C., Dweck, C., & Popović, Z. (2014). Brain points: a growth mindset incentive structure
  boosts persistence in an educational game. CHI 2014.
  https://grail.cs.washington.edu/wp-content/uploads/2015/08/orourke2014bpa.pdf ; children's and adults' play compared:
  https://educators.brainpop.com/?p=31295 ; the learning-analytics project (3,000 third graders):
  https://cadrek12.org/projects/eager-illuminating-learning-splitting-learning-analytics-approach-fraction-game-data-analys
- [G4] Treefrog Treasure (the same centre), BrainPOP's lesson plan: https://educators.brainpop.com/?p=24023
- [G5] Battleship Numberline (D. Lomas; Carnegie Mellon): https://www.cmu.edu/pier/fellows-and-alumni/lomas.html ; the
  designer's interview: https://joanganzcooneycenter.org/?p=14666
- [G6] Kiili, K., Moeller, K., & Ninaus, M. (2018). Evaluating the effectiveness of a game-based rational number training:
  in-game metrics as learning indicators. *Computers & Education*, 120, 13-28.
  https://researchportal.tuni.fi/en/publications/evaluating-the-effectiveness-of-a-game-based-rational-number-trai/
- [G7] Bustamante, A. S., Begolli, K. N., Alvarez-Vargas, D., Bailey, D. H., & Richland, L. E. (2022). Fraction Ball:
  playful and physically active fraction and decimal learning. https://hdl.handle.net/20.500.14099/34 ; the AERA abstract
  (+0.44 SD): https://www.aera.net/Publications/Online-Paper-Repository/AERA-Online-Paper-Repository-Viewer/ID/1687087 ;
  https://www.brookings.edu/articles/having-a-ball-with-fractions-fostering-math-skills-through-playful-learning/
- [G8] McLaren, B. M., Adams, D. M., Mayer, R. E., & Forlizzi, J. (2017). A computer-based game that promotes mathematics
  learning more than a conventional approach. *International Journal of Game-Based Learning*, 7(1), 36-56.
  https://doi.org/10.4018/IJGBL.2017010103 ; https://hcii.cmu.edu/hcii-impacts/decimal-point-game
- [G9] Rutherford, T., Farkas, G., Duncan, G., et al. (2014). A randomized trial of an elementary school mathematics
  software intervention: Spatial-Temporal Math. *Journal of Research on Educational Effectiveness*, 7(4), 358-383.
  https://fpg.unc.edu/publications/randomized-trial-elementary-school-mathematics-software-intervention-spatial-temporal ;
  Evidence for ESSA's entry: https://evidenceforessa.org/program/st-math-spatial-temporal-math/
- [G10] DragonBox Numbers (Kahoot DragonBox): https://apps.apple.com/us/app/-/id1005050125

**The standards**
- [S1] Common Core 3.NF: https://www.thecorestandards.org/Math/Content/3/NF/ · [S2] 4.NF:
  https://www.thecorestandards.org/Math/Content/4/NF/ · [S3] 5.NF: https://www.thecorestandards.org/Math/Content/5/NF/ ·
  [S4] 6.NS and 6.RP: https://www.thecorestandards.org/Math/Content/6/NS/ , https://www.thecorestandards.org/Math/Content/6/RP/

## The lead's review (2026-10-18 07:05): phase A passes; the open questions decided
**Verdict: approved for phase B.** The verb (cut it fair: the Fair Knife cuts only equal pieces into the count the
child sets; the count is the bottom number, the pieces given the top) is what a fraction is; sharing tables and
takeaway boxes give both meanings (division and part of a whole), and the Fair Line puts every order on a number line,
the representation the evidence favours. The models did their job and changed the design (Opening Night's tables of 5
and 8 and boxes in thirds, fifths and sixths took twelfths-and-deal from 100 % to 2.6 %; final cuts, because an undo let
trial and error win every visit; the sleeping oven; four later rooms re-tuned); Midnight Leftovers makes the habit fail
every time; the research's self-reported and second-hand figures are marked as such. The owner sees
`fraction-bakery-owner.md` and can stop or change it at any point.
1. **Midnight's events:** NEW_SETTING evidence for `g3.maths.unit_fractions` (as the altar's finale: transfer, not a first
   star); `equivalent_fractions` gets its own room's SOLVED events.
2. **The host registry:** adopted from Inside a Leaf's B2 (built once there).
3. **Ratios:** the bakery stops at recipes, ratio tables and percent; rates and proportion go to a later game (Ratio
   Kitchen, grades 6-8, in `future-lessons.md`'s queue).
4. **Decimals:** names for the same share (tenths and hundredths on the slab); the three decimal-algorithm units stay P0
   for later games.
5. **Fifths in the grade-3 prologue:** yes (our generators use them; a small step past the Common Core's grade-3 list,
   noted on the grown-ups' page).
6. **Where it lives:** a building in the Academy's courtyard with its lane behind (seen from the plaza; the Maths door
   leads there or up to the temple).
7. **The Maths door:** by the child's current maths unit (the game that teaches it); a child who has both open hears Hoot
   name the one picked, and the other stays reachable on foot.
8. **The child's own buddies as customers:** yes, phase D.
9. **When:** phase B after the leaf's B2 host hook, and after Balance Altar's phase B has started (the altar first: it was
   designed first); one game agent at a time beside the rooms' look while the cap is three.
10. **The food:** the village bakery (bread, fruit and vegetable pies, a feast-night cake).
11. **The grown-ups' page:** phase C, the plain-words baker's journal, as the leaf's and the altar's.
