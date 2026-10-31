# Size Magic Voyages: Inside a Leaf, phase A (research and design) (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-17-game-leaf-voyage-brief.md`; the authority: `docs/design/future-lessons.md`
(the five tests, the four gated phases). Phase A only: research and the design, no game code. Done on 2026-10-18 by the
game agent on the worktree branch `worktree-agent-ab81cb3a617434327`, cut from lead-merge at `d258cd72` (it holds
`e00b3752`, the brief, and `db3cd502`, future-lessons.md). No editor, no emulator, no adb, no downloads, no agents.

## What was delivered

- **The design:** `docs/design/games/leaf-voyage.md`: the research (children's ideas about plants and what changes them,
  the learning progression underneath, the games and VR studies that worked and failed, the science facts with sources,
  the curriculum strand with every unit), the fantasy, the core loop, the verb for every idea, the first voyage and the
  desert-night transfer voyage beat by beat with their simulation numbers, the ladder (rungs 4-8, about 34 voyages with
  their transfer settings), minute 1, 5 and 30 flat and in VR, every voice line of phase B (37, each at most 12 words),
  the colours, shapes and sounds that carry meaning, the evidence model into `SkillShown`, the look, the tech plan for
  phase B, the phases and estimates, risks, 33 rulings with their costs, the open questions, an honesty table and 45
  sources.
- **The owner's page:** `docs/design/games/leaf-voyage-owner.md` (one page, plain words, three pictures).
- **Pictures:** `docs/design/games/leaf-voyage/01-…11-*.png` (and their `.svg` sources), drawn by
  `docs/design/games/leaf-voyage/make_pictures.py` (`/usr/bin/python3 -I docs/design/games/leaf-voyage/make_pictures.py`,
  rendered with `rsvg-convert`). Picture 04's curves are the model's.
- **The models:** `docs/design/games/leaf-voyage/model/voyage_5_1_model.py` and `desert_night_model.py`: small
  simulations of the two phase B voyages with players standing in for children, used to test the cheat and transfer tests
  before any code, and to give phase B's `LeafSim` its starting numbers.

## The headline

- **The verb:** work the leaf's doors (stomata): open them to let air in, close them to keep water in, timed to the
  weather; every sugar the leaf builds is made of the air let in, and the plant grows from that sugar, not the soil.
  Deeper rungs add the verbs their ideas need (fill the cells, turn the chloroplasts, build sugar atom by atom, burn it at
  night, route it to where it is needed).
- **The cheat test, measured in the model** (1,000 runs per player, the six silent turns of voyage 5.1, 5 of 6 to
  master): the rule 100 % flat and VR; a slow child with the rule 72 % flat (0.8 s a door, 4 s to react), 100 % VR;
  random taps, always-open, always-closed and open-when-bright 0 %.
- **The transfer test, measured** (500 runs, the desert night's six beats): the cool-night rule 6 of 6 every time; the
  sunflower's habit 0 of 6; random about 1, always-closed 4, always-open 2; none reaches 5 of 6.
- **The ladder:** rung 4 Plant Explorer (grade 4, also grade 3's plants unit), rung 5 Built from Air, rung 6 One Cell,
  rung 7 Atom Builders, rung 8 The Whole Plant; transfer voyages: the cactus (5.T1, 8.T1, 4.T1), the water lily (4.T2,
  8.T3), the winter tree (8.T2), the dark cupboard, the pond, the animal cell, the onion, the Mars dome, the bread.
- **Seven units** become P1 in whole or in their plant half (`g3.plants_needs`, `g4.plant_animal_parts`,
  `g5.plants_air_water`, `g5.sun_energy_food`, `g6.cells`, `g7.photosynthesis`, `g8.transport_systems`).

## How the research was done

Web reading only (no downloads; one PDF the fetch tool cached by itself was deleted unread). The strongest sources: Wynn
et al. 2017 (food from soil in 28 articles, every age), the Carbon TIME learning progression (Mohan, Chen & Anderson
2009; Parker et al. 2013, 2015: about one US high-school student in ten traces matter and energy; tracing raised level 4
from 16 % to 42 %), Messig & Groß 2018 (the van Helmont demonstration alone reinforced the soil idea; human-eating image
schemas are the root), Culp et al. 2015 (a photosynthesis game with no effect), Parong & Mayer 2018 and Makransky et al.
2019 (VR: liked more, learned less, unless segmented and generative), Johnson-Glenberg 2018 (gestures mapped to the
content), the NGSS performance expectations' clarifications and boundaries (5-LS1-1, MS-LS1-2, MS-LS1-6, MS-LS1-7), and
the plant science (chloroplast avoidance, CAM, water-lily stomata, sunflower heliotropism, turgor, transpiration). The
owner's child's own game (Gorilla Tag, #130) set the VR movement: swimming with the arms through air that, at a cell's
size, really is thick (Purcell 1977).

## What the lead should check

1. The design's open questions (§8): the registry entry for a deep game with its own host and the `SchoolScreen` hook;
   which units go to P1 and how a half-covered unit shows its other half; where the Voyage Garden stands in the world; the
   garden's progress in the profile; VR movement for phase B; the voice; when phase B starts; the Mars dome as a colony
   mission; the leaf journal on the grown-ups' page.
2. Show the owner `leaf-voyage-owner.md`.
3. Phase B's brief from §4 (6 agent sessions; one agent, three briefs of two sessions with the lead's checks between).

## Rulings of this run (the design's §7 has all 33 with their costs)

The most consequential: the doors are the core verb (1); a sunflower (2); child words first, science names once after use
(3); no face or mouth on the plant (4); the child works the doors and carries sugar as honest fictions, said so at the end
(5, 6); voiced turns teach and silent turns are judged (8); one main unit per voyage (9); the plant never dies and changes
only through voyages (12); VR swimming (14); phase B ships 5.1 and the desert night so all five tests can be checked (18);
tap-to-glide on touch screens (33).
