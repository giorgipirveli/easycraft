# The learning places' look: the Discovery Academy, the crystals and Hoot — the agent brief (owner goal "amazing and best visuals"; owner #132, #133)

Since 1.0.7 every child meets learning in the world (Play W1): the **Discovery Academy** stands near every home
world's spawn (a tower with a gate per subject family; the maths door will lead up to Balance Altar's floating temple
and to Fraction Bakery's courtyard, the English door to Word Magic's Word Tower), **discovery crystals** rise near the
child while they play, and **Professor Hoot** flies to the child and speaks. These are the front door to all the
learning, so they must be a wow from the first look: a child should *want* to walk to the Academy. Today they are W1's
first versions (`entities/discovery/academy_buildings.gd`, `academy_placer.gd`, `discovery_crystal.gd`,
`hoot_flyer.gd`; the cards in `ui/discovery/`). Work autonomously; do not ask questions (decide, and write each ruling
down with its cost).

## Read first
W1's notes (`docs/devlog/parts/play-w1.md`: the Academy as a Life Town layout, the crystal as a local node, Hoot's
flight and lines, the gates and their cards), the four approved games' designs where they say where they live
(`docs/design/games/balance-altar.md` (the temple floats above the Academy), `fraction-bakery.md` (the courtyard and its
lane), `word-magic.md` (the Word Tower beside the Academy), `leaf-voyage.md` (the Voyage Garden by the Academy)), your
own rooms' look notes (`docs/devlog/parts/rooms-look.md`: the pattern you made: `LifeRoomDecor` merged per material,
warmed materials only, the look rules), the world's look (blocky and realistic styles, the universes' skies),
`test_mesh_winding.gd` (the lead's fix: every box mesh faces outwards, Godot's front faces clockwise).

## Build
1. **The Academy as a landmark worth walking to**, in both graphics styles and in the world's own blocks where it can:
   a silhouette that reads from the spawn over the trees (the design's "tower over the trees"), the gates as
   picture-doors a non-reader understands (each subject family's picture, its colour, a light that says "open"), a plaza
   with places kept free for the games that come (the temple's island above, the bakery's courtyard building, the Word
   Tower, the Voyage Garden: mark them as ground, scaffolding or a "coming soon" picture, never words), lights at night.
2. **The crystal**: a beautiful, calm "?" crystal (a glow that breathes, a soft chime, a sparkle on touch, warmed
   materials only), the same in VR at life size.
3. **Hoot**: a well-made blocky owl (the leaf's B1 made its own owl model; one shared model now that BlockyAnimal faces
   outwards), his flight and landing, his perch on the Academy's top.
4. **Pictures** in a real window under `nice`, one at a time: the Academy from the spawn by day and night, the plaza,
   each gate, a crystal rising near the child, Hoot landing; flat, VR and the realistic style; looked at and fixed until
   they are beautiful. **The draws counted** at the spawn's view and on the plaza (the world's budget, the Quest's 100),
   and the frame rate kept: nothing heavier where the child first stands.

Nothing the Academy, the crystals or Hoot *do* may change (W1's tests: placement, the gates' opening, the crystal's
timing and challenge, Hoot's lines and timings, DISCOVER), and nothing of Inside a Leaf's B2 (it touches
`DiscoveryDirector._open_place` now: leave that function alone).

## Allocation and rules
- Yours: `entities/discovery/academy_buildings.gd`, `academy_placer.gd` (the look only), `discovery_crystal.gd` (the look
  only), `hoot_flyer.gd` (the look only), a new shared owl model file if needed, `ui/discovery/academy_icons.gd`, your
  look kit, tests `test_academy_look*.gd`, tools `tools/academy_shots*`, notes `docs/devlog/parts/academy-look.md`; one
  line per new material-making file in `test_shader_warmup_sources.gd`'s COVERED (proved in its census check); new box
  meshes in `test_mesh_winding.gd`.
- First merge lead-merge (now at the 1.0.8 commits: the unit page, the animals' winding, Inside a Leaf B1). TDD for every
  rule a look needs (draw counts, warmed shaders, reach and the free band where a target moves); `--import` after new
  class_name scripts; the FULL suite once at the end, right after merging lead-merge again. Never open the editor or an
  emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents. CC0 or own assets
  only. English only. Commits end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.

## Finish
Notes (the pattern picked and the one rejected, before/after pictures, the draws, the rulings, what the lead must check
on the emulator and the Quest). Report: branch, commits, the pictures, the draws, the full suite.
