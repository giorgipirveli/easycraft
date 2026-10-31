# Size Magic Voyages: Inside a Leaf — phase A (research and design) — the agent brief (owner #133, #134)

The owner (2026-10-17, after watching their child play 30 minutes with no learning): "noone will start reading and
learning the lessons when playing game, so each game needs a lot time power and thinking to create and implement …
we need future lessons, not just texts with visuals like slides". **Read `docs/design/future-lessons.md` first: it is
the authority.** You are building the first of its wave-1 games, one game, in depth. This run is **phase A only:
research and design**. No game code: the lead reviews your design (and shows the owner a one-page picture of it)
before phase B builds it. Work autonomously; do not ask questions (decide, and write each ruling down with its cost).

## The game (the seed, `future-lessons.md` §5)
The child's garden plant is wilting. Size Magic (EasyCraft's own magic: the child can grow giant or shrink tiny) shrinks
the child to fix it from inside: fly in through the leaf's pores, carry carbon dioxide in, turn the chloroplasts to the
light, open and close the pores to balance water against air on a hot day (the trade-off real plants make), send water
up and sugar down. Nothing to read: every idea is a place and a thing to carry. Back at normal size the plant in the
real garden is green and flowering. In VR it is a wonder.

## What to produce (`docs/design/games/leaf-voyage.md`, plus pictures)
1. **Research** (cite each source; the web is fine to read, nothing downloaded):
   - what children of 9-14 get wrong about plants (the classic misconceptions: plants get food from the soil, air has no
     weight, plants breathe only at night, …) and what fixes them;
   - the best games and simulations that teach biology or cells or photosynthesis and why they work or fail;
   - the curriculum strand this game covers: our units (`data/school/g4-8/science/*`, their standards, facts and
     goals: list each unit the game would replace and which of its ideas each level teaches).
2. **The design document**, answering, concretely:
   - the fantasy and the purpose; the core loop (what the child does every 10 seconds, every minute, every 10
     minutes); **the verb that is the concept** for each idea (rule 1: show that guessing cannot win);
   - **the five tests** (choice, mute, cheat, transfer, wow) answered for this game;
   - **the ladder** across grades 4-8 (levels, what each teaches, how it gets harder, the transfer levels in new
     settings: a cactus in the desert, a water lily, a tree in winter);
   - **minute 1, 5 and 30** of a child's first session, step by step, flat and in VR;
   - **how it shows, says and does** (rule 0): the demonstrations, every voice line (short, warm, read by the system's
     voice), the pictures and colours that carry meaning (a CO2 molecule's look, water's, sugar's), the sounds, and the
     words on screen (aim for none during play);
   - **what the game records as learning** (invisible assessment: which actions show which skill, with what confidence,
     and how they reach MasteryRules through G0's bridge);
   - **the look**: the inside of a leaf at the child's tiny size, built from the game's own blocks and models (the
     cells, the veins, the pores, the light), sketched as pictures (use the game's own drawing tools or simple diagrams
     you make; put them in `docs/design/games/leaf-voyage/`);
   - **the tech plan for phase B**: scenes and scripts, how Size Magic's shrinking is reused, the budget (≥ 30 FPS on
     the emulator, ≤ 100 draws on the Quest), VR, what G0's foundation gives and what this game adds, the tests;
   - **risks and rulings** with their costs.
3. A **one-page summary for the owner** (`docs/design/games/leaf-voyage-owner.md`): the fantasy, three pictures, what
   a child does and learns, in plain words, no jargon.

## Rules
- Read: `docs/design/future-lessons.md`, `docs/design/learning-is-play.md`, spec §22.0, Size Magic's code and docs
  (DEVELOPMENT.md, `docs/devlog/parts/*size*`), the Life rooms (how a place is built), G0's notes when merged
  (`docs/devlog/parts/play-g0.md`).
- Nothing outside `docs/design/games/` (and your notes `docs/devlog/parts/game-leaf-a.md`). Never open the editor or an
  emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Report: branch, commits, the design's headline (the verb, the five tests, the ladder), the open questions the lead
  must decide, and phase B's estimate (in agent sessions).
