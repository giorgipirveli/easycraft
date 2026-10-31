# Future lessons: games that teach, built one at a time (owner #122, #132, #133, #134)

The owner, 2026-10-17, after watching their child play EasyCraft for more than 30 minutes and meet no learning:
"consider no one will start reading in the game … deliver education without just reading" (#133), and "this is not an
easy task, ultrathink, noone will start reading and learning the lessons when playing game, so each game needs a lot
time power and thinking to create and implement, so handl this apropriatly, we need future lessons, not just texts
with visuals like slides, this is not a future education at all" (#134).

This document is the authority over `learning-is-play.md` §5 (the two layers of games) and §8 (the plan). That
document's evidence (§2), its seven rules (§3) and the loop (§4) stand; what changes is **how much we build at once
and how deep**.

## 1. What we got wrong
- **Breadth before depth.** The School grew to 818 units, 5,835 lesson cards and 13,062 exercises in three weeks. It is
  a careful digital textbook: words to read, then questions to answer. Children in a game do not read, and a textbook
  inside a game is still a textbook. G0's plan (seven generic mechanics over every unit at once) would dress those
  written questions as games: a choice question becomes "give the right object to the buddy", but the child still has
  to read the question. That is a slide with a costume.
- **Learning beside the game, not in it.** The School and Life open from the main menu; inside a world a child can play
  an hour and meet nothing (#132).
- **Text as the carrier.** Every unit's meaning sits in sentences. "Read to me" was off by default (fixed: `ff49983f`).

## 2. What a future lesson is
**A game a child chooses to play, where the knowledge is the only way to win, nothing has to be read, and the game
knows what the child learned from how they play.** Every game we build passes five tests before it ships:

| Test | The question | How we check it |
|---|---|---|
| **Choice** | Would a child pick it over their favourite game? | Voluntary play time in playtests (the owner's child first); a game nobody returns to is redesigned, not shipped |
| **Mute** | Can it be played with no reading at all? | Play it with the text hidden; every goal, step and result understood from what is seen, heard and done |
| **Cheat** | Can it be won without the knowledge? | Try to win by guessing or button-mashing; if that works, the concept is not the move (rule 1) |
| **Transfer** | After playing, can the child do the real thing? | Transfer levels in new settings inside the game (the same idea, a new look), never a quiz screen |
| **Wow** | Would the child show it to a friend? | Something beautiful, surprising or funny in the first minute; the owner's verdict |

## 3. The ingredients (each from research we can name)
1. **A fantasy and a purpose.** The child is someone doing something that matters in the game (a baker feeding a
   village, a tiny explorer saving a plant, a temple keeper freeing crystals). Knowledge is needed for that purpose.
2. **A system to play with, not questions to answer.** The best learning games are simulations whose rules *are* the
   concept: balance the scale and the crystal is free (DragonBox: algebra learned through a balance of objects that
   become symbols), mix the paint and the colour appears, open the leaf's pores and the water escapes. Children
   discover the rule by trying things (productive failure, Kapur) — with a short demonstration first for a novice
   (worked examples, Sweller; rule 4's ghost hands).
3. **The concept is the verb** (intrinsic integration, Habgood & Ainsworth: children chose the integrated version for
   seven times longer). The child's main action is the maths, the science, the grammar.
4. **Show, say, do — never read.** The world demonstrates; a voice says one short line, automatically; the answer is
   an action; the world answers (a bridge holds, a plant greens, a crowd cheers). On screen during play: pictures,
   numbers and a few words at most. Reading is taught only where reading the word is itself the move.
5. **Invisible assessment** (stealth assessment, Shute): the game records what the child *did* (solved without the
   hint, fixed a mistake alone, chose well in a new setting) and turns it into mastery (`MasteryRules`), so stars, gold,
   reviews and the grown-ups' page keep working without a single quiz.
6. **A ladder across the grades.** One game grows with the child: the same world, harder ideas (Balance Altar starts
   with gems on a scale at grade 5 and ends with two linked altars, simultaneous equations, at grade 8). A game covers a
   strand of the curriculum, not one lesson.
7. **Making and sharing** (constructionism, Papert): after learning a system the child builds with it (their own
   recipe, their own altar puzzle for a friend, their own machine), and online friends play it.
8. **In the world and in the body.** Each game is a place in the child's world (W1's Academy door, a crystal's
   moment), and in VR the hands do the move (cut with a knife, lift weights off a pan, carry a molecule).

## 4. How a game is made (one game per agent, at the highest effort, over days)
| Phase | What | Gate |
|---|---|---|
| **A. Research and design** | What children get wrong in this topic; the best games and apps that teach it and why; the curriculum strand it covers (our units' standards and facts); the design document: the fantasy, the core loop, the verb, the five tests answered, the ladder across the grades, what a child does in minute 1, 5 and 30, the voice lines, VR, what the game records as learning, the risks | The lead reviews the design (and shows the owner a one-page picture of it) before any code |
| **B. The vertical slice** | The first ten minutes, complete and beautiful: art, sound, voice, juice, flat and VR, the phones' budget | Played on the emulator and the Quest; the owner's child plays it; the five tests checked honestly |
| **C. The ladder** | Its levels across the grades, mapped to the units it replaces (their play level becomes P1), invisible assessment into MasteryRules, the Academy door and the crystals launch it | The full suite; the lead's check on devices |
| **D. Grow** | More levels, making and sharing, online play, new settings for transfer | Playtest data: voluntary time, returns, transfer |

A phase that fails its gate is redone, not shipped. A deep game takes days of agent work and real playtests; a whole
strand (fractions g3-6, algebra g5-8) takes weeks. That is the cost of a future lesson, and it is the job.

## 5. The first three games (wave 1, in this order as slots free)
1. **Size Magic Voyages: Inside a Leaf** (science, grades 4-8: what plants need, photosynthesis, cells, transport,
   gases, day and night). The child's garden plant is wilting; Size Magic shrinks the child to fix it from inside. They
   fly through the leaf's pores, carry carbon dioxide in, turn the chloroplasts to the light, open and close the pores to
   balance water against air on a hot day (the real trade-off plants make), send water up and sugar down. Nothing to
   read: every idea is a place and a thing to carry. Back at normal size the plant in the real garden is green and
   flowering. Only EasyCraft can do this (Size Magic); in VR it is a wonder.
2. **Balance Altar** (algebra, grades 5-8). A temple where crystals are trapped on balance altars; the altar takes a move
   only when it is done to both pans; gems and creatures turn into numbers and letters as the child grows (the DragonBox
   route, the best-evidenced way children learn to solve equations). Free the crystal and a door of the temple opens.
3. **Fraction Bakery** (fractions, grades 3-6, the topic children fail most). A bakery where buddies order shares; a
   knife that cuts only equal pieces (the denominator is the cut), slices that fit a tin only when they are the same
   size (common denominators as the move), a crowd fed fairly (fractions as division).

Then, one at a time: Word Magic (spoken spells: grammar as magic, reading as a skill), Time Portals (history as places),
Circuit Workshop, Living Island (ecology), Forces Park, Data Lab, the Rocket missions (built already: real physics;
counted as a future lesson once it records learning).

## 6. What happens to the School's 818 units
They stay, and they become what they are good at: **the curriculum map** (every grade's every subject, its standards
and facts, checked and sourced) and **the content behind the games** (each game's ladder is made from the units it
covers, and replaces them for children: their play level P1). The cards are the **Book**: for grown-ups, readers and
the curious, never the way a child must learn. A unit with no game yet stays in the School as it is, honestly marked
(its play level P0 and its "reading debt"), and is not dressed as a game.

## 7. What the running work becomes
- **Play G0** is re-scoped to **the foundation every game stands on**: the loop, the automatic voice, the ghost-hand
  demonstration, the place framework (flat and VR), the bridge from what a game records to MasteryRules, DISCOVER and
  its map, and the audit's play levels. Its generic mechanics stay only where a challenge is truly an action without
  reading (making a quantity, ordering, connecting, sorting pictures); written questions are not dressed as games.
- **Play W1** (learning inside the world) stands: the Academy's doors and the crystals open the games, and only
  challenges a child can play without reading.
- **G1's brief (two games per agent)** is replaced: one game per agent, phase A first, at the highest effort
  (`docs/superpowers/plans/2026-10-17-game-<name>-brief.md`).

## 8. Rulings (each with its cost if wrong)
1. **Depth before breadth: three excellent games before any more units.** *Cost:* for months most of the curriculum
   is reached only through the School and the Book; the owner sees fewer subjects covered by games.
2. **The owner's child is the first playtester and the five tests are the bar.** *Cost:* one child's taste is not
   every child's; we add more playtesters as the games grow.
3. **No quiz screens in games; mastery from play.** *Cost:* invisible assessment is harder to build and to trust;
   each game's notes say exactly what it records and why that shows learning.
4. **Phase A's design is reviewed before code.** *Cost:* a day per game before anything is playable.
