# The learning places' look: the Discovery Academy, the crystals and Hoot (2026-10-18, the rooms' look agent)

The brief: `docs/superpowers/plans/2026-10-18-academy-look-brief.md` (the owner's goal "amazing and best visuals"; #132,
#133). Branch `worktree-agent-a8757d25d030e69cd` (the rooms' look, approved), `lead-merge` (1.0.8) merged in at
`f6c92654`. No editor, emulator or adb: pictures from a real window on this PC (`nice`, one at a time).

**The full suite** (2026-10-18, the branch with `lead-merge` `0830dabd` in, nothing newer there):
1326 scripts, 12267 tests, **12264 passing, 0 failing**, the same 3 risky or pending as before (two tests assert
nothing, the server's move rule is off), no script errors; 92 minutes.

## 1. The pattern (reported before building)

**Picked: the rooms' look kit in the world.** The Academy is built with `LifeRoomDecor` (the rooms' kit) instead of
W1's two box lists: the same pieces (tiled boxes, lit boxes, cylinders and cones, balls, glowing boxes, lamps, trees),
merged per material into **three meshes for the whole Academy**: `Decor_Tiles` (the walls, the steps, the paving, the
plinths faced with the world's own block pictures: `BlockLibrary.page_material(0, &"opaque")`, so it follows the world's
style, pixel or realistic, by itself), `Decor_Lit` (the bands, roofs, turrets' cones, the dome, the gates' arches, the
perched Hoot: the Theater's warmed vertex-colour material) and `Decor_Glow` (windows, pictures, lanterns, the open doors'
light: the blinker's warmed unshaded material, bright at night with no light). W1's four meshes become three; its test
(`test_the_academy_draws_little`: at most four, no words, no light) holds unchanged. The perched Hoot is part of the lit
mesh (he never moves there); the flying Hoot is one shared model (`HootModel`) in three meshes (his body, each wing:
they beat in flight and fold when he lands). The crystal stays the warmed unshaded material with a see-through halo that
breathes (the mirror wall's warmed see-through settings) and a ring of lit stones.

**Rejected:** (1) the Academy in real world blocks (stamped): a child could dig it away, every edit re-meshes chunks, no
glow at night, and W1 ruled models for it (Life Town's way); (2) one mesh per part or MultiMeshes: many more draws where
the child first stands (the Quest's 100); (3) a separate realistic model set: the tiled faces already follow the style.

**What stays exactly as it was:** where it stands and how it is found and cleared (`AcademyPlaza`, the placer's
search, check and clearing), the doors' spots and what they open, the tower's size and Hoot's perch height
(`TOWER_TOP`, `PEDESTAL`: Hoot's flight lands there), the walls' collision, the crystal's timing, its challenge and every
touch rule, Hoot's lines and timings, DISCOVER. `DiscoveryDirector` is not touched (its `_open_place` is the leaf's B2).

## 2. What a child sees now

**The Academy** (`entities/discovery/academy_buildings.gd`): a storybook tower over the trees: a base of the world's own
stone blocks, cream plaster above, teal bands, four round corner turrets with pointed teal roofs and pennants (red, blue,
yellow, green) rising past the roof, an observatory dome with its telescope to the sky and a glowing ring at its foot,
warm windows on every side (two a storey, one great arched window at the top), a great wooden door under a stepped arch
with warm light over it, and DISCOVER's magnifying glass glowing in a golden ring on the front. **Professor Hoot** stands
on his perch on the dome, turned to the spawn, in his square cap. **Twelve picture-doors** on the ring, each in its
subject's colour: pillars on stone feet, a lintel, the subject's picture glowing on a sign in a golden frame under a
little gabled roof, a lantern lit on top (open), both leaves standing open into the courtyard and warm light on the
threshold, a paved square in its colour where to walk up. **The courtyard**: a paved ring round the tower, the front path
towards the spawn and a way through each door, every slab laid on its own ground; twelve lanterns between the doors.
**The places kept for the games that come**, each with a picture on a board (never words): the bakery's plot beside the
Maths Workshop (a frame of posts and beams going up, a stack of bricks, bread), the Voyage Garden's bed on the front
path's other side (dark earth, sprouts, a little white fence, a leaf), the Word Tower's scaffolding round the English
door (poles, braces, two plank floors, stones, a book), and the temple's little island floating above and behind the
tower (grass, earth and rock, a floor with two columns standing and one begun, a lintel, clouds stepping down from it
as a stair, a balance). At night the windows, the glass, the lanterns, the pictures, the thresholds and the dome's ring
glow (no light). A world with no room: the same tower on its floating island (grass, earth, rock in the world's blocks).

**The crystal** (`discovery_crystal.gd`): a cluster (the tall crystal, four small ones leaning out at its foot in violet
and cyan, seven motes of light turning with it), a soft see-through halo that breathes in and out, a ring of grey stones
on the ground that it rises out of; its first touch sparkles (a burst and a soft chime) besides the rise's chime.

**Hoot** (`hoot_model.gd`, `hoot_flyer.gd`): one blocky owl for the perch and the flight: a round brown body with a cream
belly and its chevrons, a big head with a pale face disc, round yellow eyes with dark pupils and a gleam, an orange beak
and feet, ear tufts, a tail, the square cap with its golden tassel, and two wings of their own. Flying in, his wings
beat (out and up, never quite folded) and he leans into his flight; as his feet touch he settles (a small squash) and
folds them; standing, he bobs while his line is said and now and then ruffles his wings. Flying off, they beat again.

## 3. Draws and triangles, before and after

Measured in a real Green Meadows world (seed 12345, the Academy at (4, 38, 34)) with `tools/academy_shots.gd`, the Mobile
renderer at 1280 x 720: each view's draws, and the Academy's own (the same view with the Academy hidden, taken away;
the world's chunks load between two measures, so a single view's difference can be off by a few draws or show
negative; the steady views are listed).

| | Before (W1) | After |
|---|---|---|
| The Academy's meshes | 4 (stone, glow, Hoot's body, his head) | **3 drawn** (block pictures, lit, glow) + 1 shadow-only proxy |
| Its draws, flat (the phone's view with the sun's shadows) | 5-7 | **4** |
| Its draws, VR (the Quest's preset: no shadows) | 4 | **3** |
| Its triangles, VR (drawn) | 2.6-2.7K | **14.1K** (14.6K from the spawn) |
| Its primitives, flat (with the shadow passes) | 5.7-8.2K | **15.3-16.5K** (its shadow is a 576-triangle proxy) |
| The whole frame at the spawn, VR | 100 draws | 97-101 draws (the world's own trees and chunks; the Academy 3) |
| The whole frame on the plaza, VR | 74 draws | 75 draws |
| A crystal standing | 1 mesh + labels | 3 meshes (the cluster, the halo, the stones) + labels |
| Hoot flying | 3 meshes | 3 meshes (his body, two wings) |

The Quest's budget is draws (100 a frame); the world itself already takes 70-114 at these views and the Academy takes one
draw less than before. Triangles grew (a merged mesh draws whole), held by its test to 16K (`TRIANGLES` in
`test_academy_look.gd`); no frame time was measured here (no emulator: the lead's check below).

## 4. Pictures

Before and after (each row a view: before, after, after in the headset's preview, after in the realistic style):
committed, smaller: `docs/devlog/parts/academy-look/academy_look_01.jpg` to `_03.jpg`; the full ones in this session's
scratchpad, `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/academy_sheets/academy_look_01.jpg`
to `_04.jpg`, every single picture beside them in `academy-shots/academy_shots/{before,after}/{flat,vr}/{blocky,realistic}/`.
The views: from the spawn (the forest hides it there in this world), from the air in front (the overview, day and night),
the plaza through the Maths door (day and night), the courtyard, Hoot on his perch, the temple's island, each of the
twelve doors, a crystal rising, waiting and touched (first person and behind the avatar), Hoot flying in, landed.
Re-make them with `tools/academy_shots.gd` (its header).

## 5. Rulings (what each costs if wrong)

1. **The Academy is the rooms' kit, three drawn meshes and a shadow proxy.** *Cost:* a merged mesh draws whole even half
   off-screen (14K triangles where W1 drew 2.7K); one constant (`TRIANGLES`) holds it.
2. **Its shadow is a proxy of plain boxes** (the tower, the turrets, the dome, Hoot, each door's pillars and sign;
   `SHADOWS_ONLY`); the drawn meshes cast none. *Cost:* a pointed roof casts a square shadow, the lanterns and the
   leaves none.
3. **Stone blocks for the base only, plaster above, smooth colours for the doors.** The realistic page's stone is dark
   grey: up the tower and on the doors it read dreary (pictures, 2026-10-18). *Cost:* less of the world's own blocks than
   the brief hoped (the base, the steps, the paving, the island, the bakery's earth and bricks, the Word Tower's stones).
4. **Where the coming games are marked** (their designs say only "beside", "in the courtyard", "above"): the bakery at
   (2.4, 4.75) and the Voyage Garden at (-2.4, 4.75) in the courtyard flanking the front path, the Word Tower's
   scaffolding round the English door (its design: the gate becomes its door), the temple's island at (0, 26, -6.5)
   (`BAKERY_AT`, `GARDEN_AT`, `TEMPLE_AT`). *Cost:* when a game's phase C picks another spot, its marker moves (one
   constant) and its place is built there instead.
5. **Every door's lantern is lit** (open): every door answers (a play, Life, or Hoot's calm "coming soon"). *Cost:* a door
   that only says "coming soon" looks as open as one that plays.
6. **The paving lies on the generator's own ground** (`height_at`, as the doors' floors): a child digging under a slab
   leaves it floating; a flower that grows there pokes through. *Cost:* rare (the plaza's plants are cleared once).
7. **One Hoot model, facing -Z** (BlockyAnimal's way, HootFlyer's `_face`); the Leaf's own owl (`LeafKit.hoot`, the
   leaf's file) is not switched here. *Cost:* two owls until the leaf's agent uses `HootModel` (one line there).
8. **The crystal's halo and stones are two more draws while a crystal stands** (the mirror wall's warmed see-through
   settings, the rooms' warmed lit material). *Cost:* 3 draws instead of 1 for the seconds a crystal waits.
9. **The kit draws a cone's sides as triangles** (no flat sliver, faces outwards:
   `test_a_cones_faces_point_outwards_and_none_is_flat`). *Cost:* none; the rooms' cones look the same.
10. **The pictures are taken in first person for the place views and from the air for the overview**; the crystal and
    Hoot in the courtyard. At seed 12345 the Academy stands in a forest: from the spawn and 17 m in front its trees hide
    it (W1's own picture was taken 21 m in front in another light). *Cost:* the spawn's own view shows trees; the
    landmark reads from the air, the plaza and every clearing.

## 6. What the lead must check (no emulator, no headset here)

On the **emulator** (`Pixel_8_API_35`): a new Green Meadows world in both graphics styles: the frame rate with the
Academy in view from the spawn and on the plaza (30 FPS or more, no frame over 100 ms: its triangles are 5x W1's, its
draws one fewer); the night (the windows, the lanterns, the pictures glow); each door's picture, its spoken name and what
it opens (unchanged); Hoot flying in and landing near the child (wings beating, folded, the settle); a crystal rising,
its halo breathing, the sparkle at the first touch; the realistic style's stone base.

On the **Quest 3**: the Academy life size from the plaza and the courtyard (the world's draws + 3), the doors' lanterns at
night, the crystal by hand (its gems where they were), Hoot landing beside the child and flying to his perch.

## The lead's review (2026-10-18 11:40)
**Merged** into `lead-w1b` (one conflict in `test_mesh_winding.gd`: the altar's and the Academy's tests both kept):
299/299 on the discovery, Academy, look, winding, warm-up and places files. The before-and-after sheets looked at: the
tower with its turrets, pennants and dome, the picture-doors, the courtyard's lanterns, the coming games' marks, the
temple island and its cloud stair, the crystal cluster, Hoot's one model; better in every row. **Two gaps, the next
task:** from the spawn the trees hide it entirely (the test world, seed 12345), and at night it is dark from a distance;
a child must see it and want to walk there (a landmark above the treetops by day, a glow that carries at night).
