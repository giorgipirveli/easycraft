# Learning is play: every lesson a game (owner #122) — the design

The owner (2026-10-17 18:49, #122): "consider we dont implements just a lessons, we implement game which learns, not
slides and lessons. all lessons should be game, part of game, mini games and etc but games, not lectures and slides and
classical lessons, this is why we are not school, we are something more. school still teaches old way, last 200 years
nothing changed in school treaching methodology, now we are changing it, this must be future of education, ultrathink
about this and act acordingly".

This document is the authority for how EasyCraft teaches (spec §22.0). It changes the School's form, not its content:
the grades, subjects, goals, standards, checked facts, sources, levels and generators stay; the slides and quizzes go.

## 1. Where we are, honestly

The School as built (grades 3-8, twelve subjects): **790 units, 5,835 lesson cards to read, 13,062 hand-written
exercises**, of which **61% are multiple choice (5,755) or true or false (2,280)**; then number answers (2,010), sorts
(1,093), orders (857), matches (853), and a few builds, robots, rhythms, labels and mixes. Generators make endless new
exercises with worked answers; mastery rules give stars, reviews and gold once. It is a careful digital school, and it
is still a school: read the cards, then answer the questions, on a panel in a menu.

What EasyCraft already does better than a school, and where the new form comes from:
- **Life and Success** (`life-skills.md`, `success-skills.md`): Experiences in rooms you play with your hands (flat
  and VR), a coach, ghost hands that show once, safe mistakes, three tracks, real tools and devices. Nobody reads a
  slide in Fire Escape; you crouch under the smoke.
- **The world**: blocks, the farm, buddies, Size Magic, the Mirror, stamps, robots you code, the Lab, the rocket you
  build and fly, the cosmos, Life Town, gold that buys real things. A world that already teaches when it is used.

## 2. What the evidence says, and where it warns

| Finding | What it means for us | Source |
|---|---|---|
| Digital games beat non-game teaching for learning (g = 0.33 over 57 comparisons); games with better-designed support beat plain games (0.34) | Games are a real method, not a treat; and design quality matters as much as being a game | [G1] |
| Serious games: learning d = 0.29, retention d = 0.36; more with several sessions, with other support, in groups | Many short sessions over days; a coach and explanations inside the game; play together | [G2] |
| **Intrinsic integration**: when the maths *is* the game's mechanic (Zombie Division: divide to defeat), children learned more in the same time, and chose to play it **7 times longer** than the same maths as a quiz between game parts | The one rule that decides everything: the concept is the move you make to win, never a gate before the fun | [G3] |
| Productive failure: trying a problem before being taught beats teaching first for conceptual understanding (53 studies, 166 comparisons) | Play first, words after: the challenge comes before any explanation | [G4] |
| An algebra game whose moves are algebra (DragonBox): in the Washington State Algebra Challenge, 92.9% of the 4,192 children who played 1.5 hours reached its mastery (the developers' own figures, no control group) | Abstract maths can be a game when the rules of the game are the rules of the maths | [G5] |
| Games alone don't transfer to broad skills; explanatory feedback and a short preparation before play help; small games with clear goals inside teaching work | Every game says *why* in one line; every game has a clear, small goal; games are a method, not a miracle | [G6] |
| Novices need guidance; discovery with no guidance teaches less | The coach shows once (the ghost hands) when a child is stuck, and the game's first level is a guided one | [G7] |
| Interesting decorations that are not the concept hurt learning (the seductive detail effect) | Beauty serves the concept: the shiny thing on screen is the thing to learn | [G8] |
| Assessment can be the play itself (stealth assessment) | No tests apart from play; what the child does is the evidence | [G9] |

## 3. The seven rules (every game passes all seven)

1. **The concept is the mechanic.** The move you make to win is the thing you learn: you share the pie to feed four
   buddies, you balance the altar to free the crystal, you set the angle to hit the target. *The test:* take the
   knowledge away; if the game can still be won, it is a quiz in costume, and it is rejected.
2. **Play first, words after.** A unit opens with a problem in the world (the hook) and the child tries it before
   anything is explained; the coach's one line comes after the try. No unit starts with reading.
3. **The world answers.** Feedback is the world's reaction (the bridge holds or sags, the buddy is fed or still hungry,
   the circuit lights) plus one sentence of why; never only "wrong".
4. **Shown, not told, when stuck.** After two misses the coach's ghost hands do one step in the game itself (Life's
   ghost hands); a novice is never left alone with a puzzle.
5. **Short, again, mixed.** A game is 3-8 minutes; it comes back days later as a new challenge (the generators: never
   the same twice), mixed with other units (interleaving). Stars by doing, the same mastery rules as now.
6. **In the world, for the world.** Games live in places of the world (or in rooms reached from them), use the world's
   things (blocks, the farm, buddies, Size Magic, tools, the rocket), and what you learn is useful there: a unit ends
   with a real task in the open world ("fence a field of 24 squares and plant it", checked by `BuildCheck`).
7. **Words are tools, not walls.** Reading happens inside play (a riddle, a map, a spell, a letter that tells you
   where the treasure is), read aloud for young children. The old cards become **the Book**: open it if you want,
   never the path.

And as everywhere in EasyCraft: calm, kind, never scary; never gambling; no pressure tricks; English only; nothing
personal kept or sent; flat and VR; phones' performance budget.

## 4. Every unit's play: the loop

| Step | What happens | From today's data |
|---|---|---|
| **Hook** (15 s) | A problem appears in the world: three pies and four hungry buddies; the bridge is missing its middle; the robot is stuck | the unit's goal and its first card's idea |
| **Try** | The child tries the challenge at level 1 before any explanation (productive failure; a guided first move on the Little track) | level-1 exercises and generators |
| **See why** | The coach's one line, and the ghost hands when stuck (rule 4) | each card's one idea becomes one coach moment (12 words at most) |
| **Play** | Rounds at levels 1-3 with rising challenge; stars by the same mastery rules | the exercises, the generators, `ExerciseCheck` as the referee |
| **Use it** | A real task in the world, checked there | today's "Try it in the world" card becomes a quest |
| **Come back** | The review days later: a new challenge in the same game, or mixed with others | `MasteryRules`' reviews |

`ExerciseCheck`, `MasteryRules`, the generators, the levels and the grown-ups' page keep working exactly as now: a
challenge solved in a game is an exercise answered. Nothing about progress, gold or standards is lost.

## 5. Two layers of games

### 5.1 The generic mechanics (step G0: every unit playable at once)
Seven mechanics, each one parametric, take any written unit's exercises and generators and make them play, so no unit
is slides on the day G0 merges. Each answer type becomes an action in a small place of the world:

| Exercise type (count) | Mechanic | What the child does (flat and VR) |
|---|---|---|
| number (2,010) | **Make it** | makes the quantity with the world's things: stacks blocks, joins base-ten rods, cuts fraction bars, pays exact coins, jumps a number line, fills a jug, balances a scale |
| sort (1,093) | **Sort it** | items come along a path or a conveyor; push or throw each into its bin (the machine sorts only when right) |
| order (857) | **Order it** | lays pieces into a bridge, a timeline path or a story strip that only works in order; the buddy walks it |
| match (853) | **Connect it** | runs wires, pipes or ropes between pairs; water flows, lamps light |
| label (53) | **Fix it** | puts parts where they belong on a machine or a picture; it starts when right |
| build (49), robot (24), rhythm (62), mix (22), point (4) | **Build it**, **Code it**, **Beat it**, **Mix it**, **Find it** | the block board in the world (`BuildCheck`), the robot, the rhythm on drums, the paint or potion, the spot on a map |
| choice (5,755), truefalse (2,280) | **Choose by doing** and **Test it** | choices are things to act with, not buttons: give the right thing to the buddy who needs it, set the switch, take the path; a claim is *tested* where it can be (drop both balls and see) and the world shows the result |

**Honest limit:** "Choose by doing" is the weakest bridge: a choice question in costume is close to a quiz. That is why
G0 is a bridge and the signature games are the goal, why every unit carries a **play level** (P0 generic, P1 its own
signature game) on the lead's audit, and why new units are written play-first (§7).

### 5.2 The signature games (steps G1-G5: the real goal)
Games whose mechanic *is* the concept (rule 1), each reused across the grades with harder parameters, each covering a
family of units (the units' `standards` and goals say which). A unit with a signature game plays it instead of the
generic mechanic.

**Maths**
- **Builder's Count** (g3-5): base-ten blocks are real blocks; ten cubes fuse into a rod, ten rods into a flat; build
  numbers, add and take away with regrouping by fusing and breaking.
- **Array Farm** (g3-6): plant fields in rows and columns (multiplication, division as sharing plots), fence them
  (perimeter), fill them (area); the crops really grow in the area you planted.
- **Fraction Bakery** (g3-6): share pies, cakes and gems fairly among buddies; cut again for equivalent fractions; fit
  slices into one tin to add; a fraction of a set feeds a crowd.
- **Frog Jump** (g3-7): a number line over a river: jumps add and subtract; below the water are the negatives; Size
  Magic zooms in for decimals; skip-counting jumps for multiples.
- **Market Change** (g3-7, with My Money Stall): exact change, decimals, discounts and percentages, unit prices.
- **Balance Altar** (g6-8): an equation is a balance; do the same to both sides to free the crystal x; see-saws for
  inequalities; recipe boxes for expressions (the DragonBox principle [G5]).
- **Ratio Kitchen** (g6-8): mix paint, potions and rocket fuel in ratio; scale recipes; buddies' speeds as unit rates;
  the graph draws itself as you mix (proportional relationships, slope).
- **Angle Launcher** (g4-8): set the angle to land the ball, the boat's heading, the ramp; angles in triangles by
  folding; parallel rails with their crossing angles.
- **Shape Forge** (g3-8): make shapes to fit locks: properties, symmetry with the game's own Mirror, rotations,
  reflections and translations, congruence and similarity.
- **Size Magic Volumes** (g5-8): fill boxes with cubes; pour cones and cylinders; the Size Magic shows doubling a side
  makes eight times the volume.
- **Treasure Grid** (g5-8): dig at coordinates; four quadrants; distances; the shortest path across the field is
  Pythagoras.
- **Data Lab** (g3-8): collect real data in the world (count animals, time runs, measure plants), plot it, find mean
  and median, predict, and catch the misleading graph.
- **Fair Festival** (g7-8): design a fair game for the buddies' festival; experiments against theory (probability;
  never a bet, never gold at stake).
- **Function Factory** (g4-8): input-output machines, patterns, linear functions; slope is a cart's ramp.

**Science**
- **Size Magic Voyages** (g4-8): shrink into a leaf, a cell, the blood, a drop of water: cells, organs, digestion,
  circulation, particles and the states of matter.
- **Living Island** (g3-8): run a pond and an island: food chains and webs, populations, adaptations, invasive
  species, biodiversity.
- **Weather Machine** (g3-8): heat, evaporate, make clouds and rain; climate zones; tilt the planet for the seasons.
- **Forces Park** (g3-8): ramps, friction, gravity, pushes and pulls, magnets, simple machines lifting blocks, speed
  by timing.
- **Circuit Workshop** (g4-8): wires, bulbs, switches; series and parallel; conductors; then logic gates for computing.
- **Light and Sound Lab** (g4-8): bounce a beam with mirrors to its target, lenses, colours; pitch by a string's
  length (with music).
- **Rock and Sky** (g3-8): the rock cycle in the voxel world's own layers, fossils dug up; the Moon's phases by
  orbiting it; the planets by flying the rocket (the cosmos).
- **Mixing Lab** (g3-8): mixtures and separating (sieve, filter, evaporate), reversible and irreversible changes,
  safe indicators (never a recipe for anything dangerous: Life §14).

**English**
- **Word Magic** (g3-8): spells are sentences and grammar is the magic: nouns summon, adjectives shape, verbs act,
  adverbs say how, tenses say when, conjunctions chain spells, punctuation ends and joins; prefixes and suffixes are
  runes that change a word (un- turns the light off).
- **Story Theater** (g3-8): buddies act out the story the child assembles: plot order, characters' choices, cause and
  effect, point of view by changing the camera, dialogue punctuation makes them speak.
- **Detective Reader** (g3-8): mysteries solved from texts: signs, letters, logs, maps and captions; inference, main
  idea, evidence.
- **Persuade the Council** (g5-8): win the village's vote with reasons and evidence for that audience; spot bias and
  fallacies (Talk & Deal's way).
- **Poetry Music** (g3-8): lines that fit the beat open the music box; rhyme, rhythm, figurative language as effects.

**History, geography, citizenship**
- **Time Portals** (g3-8): be there: move the pyramid's stones with ramps and levers, run a Silk Road caravan, steer a
  Viking ship by the sun, keep a mill town's factory running and see its costs, land on the Moon (built); hard history
  told with respect and never shown.
- **Timeline Bridge** and **the Museum** (g3-8): order events to cross; curate an exhibition from primary and
  secondary sources and judge which to trust.
- **Map Quest** (g3-8): navigate by compass, grid references and scale; contours as real hills; a raft from source to
  sea; push plates to raise mountains and shake the ground.
- **Village Council** (g3-8): rules, rights, votes, budgets and taxes, laws and fairness, a sustainable town, with
  consequences you can see.

**Computing, arts, music, health and PE, D&T**
- **Robot Coder** (built; g3-8): sequences, loops, conditions, debugging, data; **Online City** (Life) for safety.
- **Colour Potions and the Gallery** (g3-8): mix colours, tints and shades; perspective by placing things in a scene;
  restore a painting by its style; sculpt with blocks.
- **Beat Blocks** (g3-8): rhythm on drums, loops composed with note blocks, pitch by height, the orchestra's families.
- **Body Quest** (g3-8, with Size Magic Voyages and Life): the body from inside, the heart rate in a race, a healthy
  plate (Life's Kitchen).
- **Inventor's Workshop** (g3-8, the tool engine and Real Builder): a brief, a design, a build, a test against the
  brief.
- **Projects** stay big builds in the world.

## 6. Where it lives

- **DISCOVER** replaces SCHOOL on the menu for children (a ruling: "we are not school, we are something more"; the
  grown-ups' page keeps the programme's words: grades, subjects, standards). The map shows each subject's places as a
  world to explore, not a list of lessons.
- Each game is a place (an arena reached from the map, like Life's rooms, and, for the signature games, a place in
  the world too, as Life Town is). Flat and VR (hands in VR do the moves: cutting, pouring, balancing, fusing).
- One framework for Life and learning games where it fits: rooms, steps, motions, tools, the coach, ghost hands,
  tracks (G0 measures whether Life's `ToolRoomHost` and rooms carry the generic mechanics, and says which it chose).

## 7. How units are written from now

New units (grade 9 up, and every rewrite) are written **play-first**: a `play` block in the unit's file (the hook, the
game and its parameters, the challenges from exercises and generators, the coach's lines, the world task); cards only
as coach lines and the Book. G0 fixes the format. Until G0 merges, the School's content agents finish what they have
(grade 7 and 8's last core units) and none start card-only work.

## 8. The plan

- **G0 (one agent, first):** the play layer and loop (§4); the seven generic mechanics (§5.1) for every written unit;
  DISCOVER and its map; the Book; the `play` format; flat and VR; the budget; the play level on the audit.
- **G1 Maths** (two agents after G0): number and fractions (Builder's Count, Array Farm, Fraction Bakery, Frog Jump,
  Market Change), then algebra, geometry and data (Balance Altar, Ratio Kitchen, Angle Launcher, Shape Forge, Size Magic
  Volumes, Treasure Grid, Data Lab, Fair Festival, Function Factory).
- **G2 Science**, **G3 English**, **G4 History, geography, citizenship**, **G5 Computing, arts, music, health, D&T**.
- **G6 Measured:** before-and-after checks in play (the same challenge cold and after), time chosen in free play (the
  7× test [G3]), the share of units at P1; the experts' review of each game's teaching.
- The grades continue (grade 9 up) in the play-first format.

## 9. Rulings (each with its cost if wrong)

1. **The content stays, the form changes.** *Cost:* none of the 790 units is thrown away; if a unit's facts don't
   suit play, it keeps them in the Book.
2. **G0's generic layer before the signature games**, so nothing stays slides while the best games are built. *Cost:*
   for a while most choice questions are "choose by doing", close to a quiz; the play level on the audit keeps it
   visible.
3. **DISCOVER for children, the programme's words for grown-ups.** *Cost:* one rename.
4. **No reading before playing; the Book on request.** *Cost:* a child who likes reading first opens the Book.
5. **The coach and ghost hands stay** (guidance [G7]) — this is not "discovery without help". *Cost:* none.
6. **Signature games cover families of units across grades.** *Cost:* a unit that fits no family stays generic until
   its own game.

## 10. Sources

- [G1] Clark, D. B., Tanner-Smith, E. E., & Killingsworth, S. S. (2016). Digital games, design, and learning: A
  systematic review and meta-analysis. *Review of Educational Research*, 86(1), 79-122.
  https://doi.org/10.3102/0034654315582065 ; brief: https://www.sri.com/publication/education-learning-pubs/digital-learning-pubs/digital-games-design-and-learning-a-systematic-review-and-meta-analysis-brief/
- [G2] Wouters, P., van Nimwegen, C., van Oostendorp, H., & van der Spek, E. D. (2013). A meta-analysis of the
  cognitive and motivational effects of serious games. *Journal of Educational Psychology*, 105(2), 249-265.
  https://research-portal.uu.nl/en/publications/a-meta-analysis-of-the-cognitive-and-motivational-effects-of-seri/
- [G3] Habgood, M. P. J., & Ainsworth, S. E. (2011). Motivating children to learn effectively: Exploring the value of
  intrinsic integration in educational games. *Journal of the Learning Sciences*, 20(2), 169-206.
  https://shura.shu.ac.uk/3556/
- [G4] Sinha, T., & Kapur, M. (2021). When problem solving followed by instruction works: Evidence for productive
  failure. *Review of Educational Research*. https://doi.org/10.3102/00346543211019105 ; summary:
  https://www.weforum.org/stories/2021/09/students-who-productively-fail-learn-more/
- [G5] DragonBox and the University of Washington's Center for Game Science, the Washington State Algebra Challenge
  (2013): https://dragonbox.com/about/algebra-challenge ; https://news.cs.washington.edu/?p=10336 (self-reported,
  no control group).
- [G6] Mayer, R. E. (2019). What should be the role of computer games in education? *Policy Insights from the
  Behavioral and Brain Sciences*. https://visus-uk.sagepub.com/en-us/mst/press/what-should-be-the-role-of-computer-games-in-education
- [G7] Kirschner, P. A., Sweller, J., & Clark, R. E. (2006). Why minimal guidance during instruction does not work.
  *Educational Psychologist*, 41(2), 75-86.
- [G8] Rey, G. D. (2012). A review of research and a meta-analysis of the seductive detail effect. *Educational
  Research Review*, 7(3), 216-237.
- [G9] Shute, V. J. (2011). Stealth assessment in computer-based games to support learning. In S. Tobias & J. D.
  Fletcher (Eds.), *Computer games and instruction* (pp. 503-524). Information Age.
