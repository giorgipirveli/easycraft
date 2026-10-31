# Robots and aliens on the planets — the agent brief (owner #86; spec §21f)

You are building **robots and friendly aliens** for EasyCraft's planets (Godot 4.7.2, typed GDScript, Voxel Tools), a
game for children. The owner: "on the planets we should have some aliens, robots as well". Work autonomously; do not
ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§21f (your design)**, §21, §21b, §21c (colonies), §3c (our own look:
   friendly, never scary), and how the game's creatures work: animals (`entities/animal/*`, their minds, spawning per
   universe, `UniverseRegistry.animals`, `lifeless`), buddies (`entities/buddy/*`: friendship, gifts), Tilly the trader
   (her stall and stock), the Moon's bunnies, quests and the adventure board, `SpaceSights`.

## What to build (spec §21f)
- **Robots on every space world**: a helper robot at each landing pad (says the planet's first facts, points to the
  sights, gives a small quest), rover buddies that follow the child and dig a sample when asked, drones that scout
  ahead; each our own design in both graphics styles, cheap to draw (the performance budget).
- **Friendly aliens**: on the real planets, a travelling alien explorers' camp (a small ship, a trader with alien
  things for gold, an explorer who shares a fact about its own far world, clearly make-believe) whose words stay honest
  about real life in space ("No one has found life beyond Earth yet: scientists keep looking, and so do we!"); on the
  playful planets (Boing, Rainbow), an alien village with homes and a game to play. Aliens can become friends (a
  friendship, a gift) and one can join the child's colony dome.
- Never hurt the child, never scary, peaceful worlds stay peaceful.

## Allocation and rules
- New files: `entities/robot/*`, `entities/alien/*`, `core/creatures/*` (pure rules), tests `tests/**/test_robot*.gd`,
  `test_alien*.gd`, notes `docs/devlog/parts/space-creatures.md`. Small additions: the space worlds' descriptors
  (spawning), the colonies if merged. Block ids only if the lead gives you a page. Never touch the School, the missions,
  the flight, the invites.
- TDD for the rules; windowed shots of each creature in both styles if you can open a window (else say so); `--import`
  and grep Parse Error; single tests while working; the FULL suite once at the end. Never open the editor or an
  emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
Notes (rulings, what a child meets, frame costs, what the lead must check on the emulator); spec §21f "As built";
`docs/DEVELOPMENT.md`. Commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
Report: branch, commits, what a child sees, the tests' results, what the lead must look at.
