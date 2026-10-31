# Balance Altar — phase A (research and design) — the agent brief (owner #133, #134)

The owner (2026-10-17): "noone will start reading and learning the lessons when playing game, so each game needs a lot
time power and thinking to create and implement … we need future lessons, not just texts with visuals like slides".
**Read `docs/design/future-lessons.md` first: it is the authority** (the five tests: choice, mute, cheat, transfer,
wow; the four gated phases). This is the second wave-1 game, one game, in depth; this run is **phase A only: research
and design, no game code**. The first game's phase A is the model of what a good phase A looks like:
`docs/design/games/leaf-voyage.md` (and the lead's review at its end), `leaf-voyage-owner.md`, its pictures and its
small simulation models (`docs/design/games/leaf-voyage/model/`: the cheat and transfer tests run as numbers before a
line of game code). Work autonomously; do not ask questions (decide, and write each ruling down with its cost).

## The game (the seed, `future-lessons.md` §5)
Algebra, grades 5-8. A temple where crystals are trapped on balance altars. The altar takes a move only when it is done
to both pans: take the same weight off both, split both into equal groups, add the same to both. Free the crystal (the
unknown alone on one pan) and a door of the temple opens. Gems and creatures turn into numbers and letters as the child
grows (the DragonBox route: the best-evidenced way children learn to solve equations without being taught the rules
first). Expressions as recipe boxes; inequalities as a see-saw that stays tipped; two altars sharing the same crystals
for simultaneous equations.

## What to produce (`docs/design/games/balance-altar.md`, plus pictures)
1. **Research** (cite each source; reading the web is fine, nothing downloaded): what children of 10-14 get wrong in
   early algebra (the equals sign as "the answer comes next", letters as labels or as objects, the operations on one side
   only, negatives, the distributive law) and what fixes them; DragonBox (what it does, what the evidence says and does
   not say: the Algebra Challenge's self-reported numbers, independent studies), Hands-On Equations, algebra tiles, and
   other games or apps that teach algebra and why they work or fail; the curriculum strand from our units
   (`data/school/g5-8/maths/*`: expressions, equivalent expressions, equations, variables, inequalities, linear
   equations, systems, expand and factorise, exponents in expressions) with each unit's standards.
2. **The design document**, concretely (as the leaf's): the fantasy and purpose; the core loop; **the verb that is the
   concept** for each idea; **the five tests** answered, with **a small simulation model** that shows guessing cannot win
   (random moves, one-side moves, greedy moves) and the rule does, and a transfer test in a new setting; **the ladder**
   grades 5-8 (the pictures-to-symbols fade, levels, transfer levels); **minute 1, 5 and 30**, flat and VR; **show, say,
   do** with every voice line (≤ 12 words, never a question that needs reading; reading the symbols is part of the
   skill, so say how the voice supports it); **what the game records** through G0's `SkillShown`; **the look** (the
   temple, the altars, the crystals, the creatures; sketched as pictures you make); **the tech plan for phase B** (on
   G0's foundation: `PlayHost`/a host of its own, `PlayVoice`, the demonstrations, `SkillShown`; DISCOVER and W1's
   Academy maths gate, `AcademyPlaza.opens()`; VR: lifting weights off pans by hand); risks and rulings; an honesty
   table (what is real maths, what is simplified).
3. **A one-page plain-words summary for the owner** (`docs/design/games/balance-altar-owner.md`) with three pictures.

## Rules
- Read also: `docs/design/learning-is-play.md`, spec §22.0, G0's notes (`docs/devlog/parts/play-g0.md`) and
  DEVELOPMENT.md's "The foundation's API, for the game agents", W1's notes (`docs/devlog/parts/play-w1.md`).
- Write only under `docs/design/games/` and your notes `docs/devlog/parts/game-altar-a.md`. Never open the editor or
  an emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Report: branch, commits, the design's headline (the verb, the five tests with the model's numbers, the ladder), the
  open questions the lead must decide, and phase B's estimate in agent sessions.
