# The practice rooms look like real places (2026-10-17 to 10-18, the rooms' look agent)

## Where it stands (2026-10-18)

**Every practice room is dressed** (the 21 Life and Success Experiences on all three tracks, flat and VR; Real Builder's
building site keeps its own look) and so is G0's play place (`PlayArena`, the lead's request). The look test holds every
room now (`tests/integration/test_room_look.gd`: the dressed list is gone). Nothing a room teaches or plays moved:
targets, views, steps, reach, VR stands; every room's own tests pass unchanged (one thing shows later than before:
Find Your Way's waiting train, which stood in the market square, ruling in §3). Branch
`worktree-agent-a8757d25d030e69cd`, cut from `lead-merge` `59cff11a`, `lead-merge` merged in again before the full suite.

**The full suite** (2026-10-18, on the branch with `lead-merge` `bb6dd646` merged in, `tests/run_tests.sh`): 1313
scripts, 12156 tests, **12153 passing, 0 failing**, 3 risky or pending that were so before (the column cache's and the
chunks' seams' tests assert nothing, the server's move rule is off), no script errors; 85 minutes.

The brief: `docs/superpowers/plans/2026-10-17-rooms-look-brief.md` (the owner's standing goal "create amazing and best
visuals"; #122 "learning happens as play in places a child wants to be"). No editor, emulator or adb: pictures from a
real window on this PC (`nice`, one at a time), the Vulkan Mobile renderer (the phones' and the Quest's), 1280 x 720.

**Not done, next (the game never ends):** the realistic style's own floors are the blocks' realistic page (they follow
the world's style) but no room was tuned for it alone; Real Builder's site (the Tools agent's); the rooms' pictures in
the store sheet; a third look pass by the owner's eye on the phone and the Quest (below).

## 1. The pattern (reported before building)

**Picked: decoration helpers in the kit, merged into one mesh per material.** A new builder, `LifeRoomDecor`
(`entities/life/life_room_decor.gd`), takes a room's floors, walls, windows, skirting, rugs, plants, shelves, lamps,
pictures, fences, benches, trees, bushes and its sky as *pieces* and draws them, when the room is built, as:

| Mesh | Material (already warmed: ShaderWarmup's census) | What is in it |
|---|---|---|
| `Decor_Lit` | the Theater building's vertex-colour material (`vertex_color_use_as_albedo`, `vertex_color_is_srgb`), matte | every lit piece in its own colour |
| `Decor_Tiles` | the blocks' own page-0 material (`BlockLibrary.page_material(0, &"opaque")`: pixel or realistic as the world's style) | floors and walls in the game's block pictures (planks, brick, paving, cobbles, sand, grass, tiles), tinted by vertex colour |
| `Decor_Glow` | the launch site blinker's settings (unshaded, vertex colours) | windows' painted views, lamp shades, ceiling lights |
| `Sky` | the same unshaded settings, its own instance (a night tints it) | a dome round the room: horizon light, deeper blue above, hazy hills, soft clouds, the ground under the horizon |
| `Glass` | the mirror wall's see-through settings (`LifeRoomKit.material` with alpha) | window glass, one mesh a tint |

So a room's whole dressing costs **about four draws however many pieces it has**. Every piece is remembered as a box in
the room's space (`LifeRoom.look_pieces`): the keep-clear tests read them (never on a target, across a view's line or a
VR reach). The same merge takes a room's **existing static scenery**: a room builds its walls, counters and furniture
with LifeRoomKit's existing functions under `LifeRoom.scenery()` instead of `self` (the same calls, the same places), and
after `build()` `LifeRoomDecor.bake` merges every plain lit mesh there into one mesh, keeping as nodes whatever the room
holds in a property (in an Array or Dictionary too), every target's node (and what is above and under it), anything with
its own script (a buddy, a dog, a tool), anything hidden (it shows later), see-through or glowing things. A sign on a
static box is lifted off it (the same place) so the box can merge. `LifeRoomKit`'s existing functions are untouched
(Play G0 builds on them); the rooms' look is new functions in new files and LifeRoom's `_ready`.

**The light:** each room has its own warm key light (`LifeRoomSun`, no shadows); while the room shows, the world's sun is
put away (the rooms hang 1.5 km over the world they were opened from, and that world's sun lit them as its clock said:
a white noon, a red sunset, the moon) and given back after, as the rocket flight's own sun does. The room's environment
takes the worlds' tone (ACES under 1: the visuals brief), so whites stop washing out.

**Rejected: a MultiMesh per shape.** The rooms' dressing is boxes of every size, cylinders, cones, balls and quads in
dozens of colours, and the floors need the block pictures: a MultiMesh draws one shape a draw (a box MultiMesh, a
cylinder MultiMesh, a ball MultiMesh, ... each its own draw), cannot hold the textured floors with the rest, and cannot
take the rooms' existing scenery (its boxes are all different sizes). Nothing static moves, so no per-instance transform
is worth paying for. A merged mesh is one draw per material whatever the shapes, and costs only triangles (a room's whole
dressing is a few thousand; the Quest's budget is 750K).

**Rejected too:** merging every child of a room automatically (a test finds Find Your Way's `GreenLine` by name, rooms
show `Lead`, `FloodPath`, `Storm`, `HeldPhone` by name later: an explicit `scenery()` is safe); a sky shader or Godot's
procedural sky in the room's environment (its light would bake on every room open, a full-screen pass per eye on the
Quest; the dome is one unlit draw whose colours a night can tint).

## 2. What changed in each room

Every room: a real floor in the blocks' pictures, walls, a sky dome (or a ceiling indoors), its own warm sun and the
worlds' tone; its static furniture merged (`scenery()`); its people in few meshes (`LifeRoomPeople`), faces through
`feel`. The signs that broke the look rules moved (each says why in a comment at its line); nothing a step uses moved.

| Room (Experience) | The place now | Signs and words fixed |
|---|---|---|
| Little Lifesaver (`first_aid_room.gd`) | a bright training room: pale planks, mint walls under a rail, a tiled ceiling with lights, two windows over the garden, a bookshelf, plants, pictures, a clock, a bench, coat hooks | PRACTICE ROOM painted high like a banner |
| Fire Escape (`practice_house.gd`) | a home in its garden: grass, hedges, the meeting tree, stepping stones, flower beds, a fence; planks, the bedroom's carpet, a quilt, a wardrobe, a night light; a roof on Middle and Big (Little's hunt stays an open doll's house) | PRACTICE HOUSE over the front door, smaller, off the wall |
| My Money Stall (`market_room.gd`) | a town square (`town_square`: slabs, houses, lamps, flags, trees), a wooden counter, the other stalls' wares, the bank's steps, the shop's roof | MY STALL on the awning; SHOP at the shop's right end; the shop's price tags show at the shop |
| Safe Streets (`street_room.gd`) | asphalt, paving slabs, grass verges, the kit's houses (pitched roofs, windows), front gardens with hedges and flowers; dusk deepens the sky | PRACTICE STREET across the street; PARKED VAN painted on the van; the speedometer beside the wheel; one tree off the first view |
| The Kitchen (`kitchen_room.gd`) | a family kitchen: clay floor tiles, a splashback, a window over the sink, cupboard doors and handles, a hood, jars, a clock, a ceiling with lights | TODAY: lower; the pantry's price tags show at the pantry |
| Calm Corner (`calm_room.gd`) | a quiet room: soft planks, lilac walls with a wainscot, a round soft light, little warm lights, a framed window with drifting clouds, an armchair with a blanket, a beanbag, stars | CALM CORNER painted high |
| Water Safety (`water_room.gd`) | the pool garden (a paved deck, a tiled pool, loungers, a parasol, the hut), the beach (sand, palms, towels, a sandcastle, dunes), the winter pond (snowy pines, a snowman) | PLEASE WALK on its board; the lifeguard's chair lower (Gus's head in view); the reaching pole leans the other way |
| The Poisons Cupboard (`poisons_room.gd`) | the kitchen in tiles with a splashback and a painted window, a ceiling, a rug, a picture and a plant by the sofa; the hall's rug and coats; the house front's windows, door and flowers | PRACTICE HOUSE over the hall's front door |
| Earth and Weather (`earth_room.gd`) | the practice room in planks with a window, a rug, a plant; the garden's fence and flowers; the park's path, bench, bushes; more trees and mushrooms in the woods; the bag's corner; the playground's hopscotch | PRACTICE ROOM high and smaller; BE READY higher and smaller |
| Electricity Safety (`electric_room.gd`) | the house in planks and the bath corner's tiles, a short wall between them, a painted window behind the power lines, a splashback, an armchair; the park's path, bench and trees; hedges by the storm's path | (none needed) |
| Animal Friends (`animals_room.gd`) | every place in the game's grass with pale sand paths; trees, flower beds and a fence in the park; the dog park's fence and bowl; the farm's barn and hay; the hills' trees and rocks | PRACTICE HILLS lower and smaller |
| Medical Moments (`medical_room.gd`) | a calm first aid room (planks, a wainscot, the cabinet under its green cross, a poster, a window, a ceiling light); the playground's sandpit, swings, fence and flowers; the picnic's trees and basket | PRACTICE ROOM lower and smaller |
| Online City (`online_room.gd`) | a family living room: planks, walls all round with wallpaper, the sofa with arms and cushions, a floor lamp, pictures, a sideboard | (none needed) |
| Find Your Way (`find_way_room.gd`) | the market as a town square; the school in planks with windows, a shelf, a clock, its playground's fence and trees; the metro's tiled hall with a ceiling, light strips, a bench, rails and a tunnel mouth; the park's path and benches | PRACTICE METRO beside the map; the waiting train no longer stands in the market square (out of sight until it comes) |
| Home Helper (`home_helper_room.gd`) | one home along its wall: planks (the laundry's tiles), a wallpaper band, low wooden dividers between the corners, a ceiling with lights, windows, a laundry shelf, a splashback, the front door and coats | PRACTICE HOUSE lower and smaller |
| The Goal Board (`goal_room.gd`) | a bright playroom: planks and a rug, a pale blue wainscot, a window, a toy shelf, a beanbag, a front wall with its door | THE GOAL ROOM high; MY WEEK at the calendar's far end; the step cards' words on the cards in two lines |
| Talk & Deal (`talk_square.gd`) | a sunny market square: slabs, houses, flags, lamps, planters, benches, trees; a wooden counter | ANA'S APPLES on a chalkboard beside her cart; MY STALL on the awning; the cards' words in two lines; the investors' names a row over the table |
| Connections (`village_square.gd`) | a village square round a stone-stepped fountain: cottages, trees, lamps, flower tubs, flags, striped awnings; a night with a deep sky and moonlight | THE VILLAGE on an arch behind the child; the shops' names over their roofs, high and low in turn |
| Success Stories (`story_stage.gd`) | the theatre's hall: a polished floor, the stage in wood under a golden frame, footlights, blue walls with warm lamps, an aisle, seats with backs | (none needed) |
| My Shop (`shop_room.gd`) | the bakery (planks, brick and plaster, loaves on a shelf, a wooden counter) on a market square with Pip-pop's bakery across it | Bobo beside the counter's end (his head was cut, his tag over the ledger); the stand's sign on its awning |
| The Market Square (`market_square_room.gd`) | the square with its stalls, the wheat field, the chart | the near stalls' names on their counters, the far ones on boards over their roofs |
| G0's play place (`entities/play/play_arena.gd`) | a meadow garden round the table: a slab patio, stepping stones to an oak with a picnic rug, a fence with flower beds, a potting bench and shed, a bench, far trees | (its own words untouched) |

## 3. Rulings (what each costs if wrong)

- **The room lights itself** (`LifeRoomSun`, no shadows) and puts the world's sun away while it shows, as the rocket
  flight does. Cost if wrong: a world sun left hidden if a room were freed outside the tree (it gives back only what it
  hid, on exit).
- **The sky is a dome mesh following the viewer**, one unlit draw a night can tint, not a sky shader. Cost: no sky light
  in reflections (the rooms use a colour ambient anyway).
- **Real Builder keeps its own geometry** (the Tools agent's); it gets only the shared sky, sun and tone. Cost: its site
  still looks bare.
- **The VR budget: 66 of the room's own draws** from any VR stand, any of four ways (the HUD's canvas 25-29 and the
  hands, beam and panel about 4 take the rest of 100). Measured with `tools/room_shots.gd --vr`. Cost: if the HUD grows,
  66 must shrink with it (one constant, `VR_ROOM_DRAWS`).
- **The text rule:** no label cut by the screen's edges; none half under the HUD's top bar unless it is a target's own
  words (within 1 m of a target: a price board's rows). Heads whole under the bar, or just on screen for a person who
  carries a step's target. Cost: a target's words under the bar are hidden by the coach's text on a small phone.
- **Merged people keep their boxes as hidden nodes**, so LifeBuddy's own code works; a room that changes a merged
  buddy's face calls `LifeRoomPeople.feel` (every room's `x.face(...)` now does). Cost: a future room that calls
  `LifeBuddy.face` on a merged buddy shows the old mouth too (the look test's heads rule does not see it; review it).
- **A painted window is part of its wall** (remembered as SHELL): a thing seen in it (Electricity's kite in the lines) is
  not "covered" by it. Cost: a target put flat on a window would not be flagged.
- **`merge_parts` keeps only what the room holds under the thing**, not above it (a dictionary of bottles holds the
  bottle, which must not stop its sign's boxes merging). Cost: none seen; the kit's test proves both ways.
- **`merge_whole` for things that never come apart** (a bottle, its cap, its warning sign): a target inside (the sign,
  on Middle) keeps its node, the tap and the glow use the node, not its boxes. Cost: if a room ever hid a sign alone, its
  picture would stay on the bottle.
- **`merge_dog(dog, still)`**: a dog whose mood never changes again (Animals' three park dogs, the sleeper, the second
  shepherd dog) is one mesh as its mood left it. Cost: a room that later calls `set_mood` on such a dog sees no change.
- **Words draw within 25 m** (`LifeRoom.WORDS_SEEN`, a visibility range on every label of a room) and **a phone held up
  within 4 m**: a room's places stand 30 m and more apart and their words were the Quest's draws from the other places
  (Find Your Way: 75 -> 49). Cost: a sign meant to be read from further than 25 m would vanish (none is: the furthest
  view reads about 10 m).
- **A street car is one mesh** (its body and four wheels, made once per kind and colour by SurfaceTool): the wheels never
  turned. Cost: if the street's cars ever roll their wheels, the wheels must be their own meshes again.
- **Find Your Way's waiting train is hidden until it comes** (`train_coming`) or stops (the platform step done): it stood
  at `METRO + TRAIN_FROM` = x -4, inside the market square on Middle. Its path, speed and stop are unchanged. Cost: if a
  step wants the train seen waiting far down the line, it must be shown at that step.
- **No dressing over a sign's words** (`LifeRoomLook.words_covered`, the look test's newest rule): a flat sign is tested
  as it hangs from every side, a sign that turns to the eye as the first view sees it (it turns, so another view may
  differ). Wall and board signs are painted flat now (turned to the eye, they sank into their walls). Cost: a turning
  sign seen from a later step's view is not checked (the tags rule walks every step; this one only the first view).
- **Triangles for draws:** the merged meshes are drawn whole, so a room's triangles grew (the street 5-10K -> 34-38K, the
  rest 3-17K) while its draws fell to a third or less. The phones' and the Quest's budget is draws first (the Quest's
  triangles budget 750K); cost: none measured; the emulator's frame check is the lead's (below).

## 4. Draws and triangles, before and after

Measured on this PC, the Vulkan Mobile renderer at 1280 x 720 (`tools/room_shots.gd`: the room opened by its real host,
its first view; `--vr`: the headset's desktop preview at the start stand, the heaviest of four snap turns), and the look
test's own count (`test_every_room_draws_within_the_quests_budget_from_every_vr_stand`: the room's own draws from
**every** step's VR stand, any of four ways; the budget 66). Draws fell to a third on average; the triangles grew
because a merged mesh is drawn whole (the street's houses and verges 100 m long are one mesh): the budget that binds
on the phones and the Quest is draws (the Quest's triangles budget is 750K; the heaviest room here is 38K).

**The heaviest room in VR: the Kitchen, 64 of the room's own draws (Middle), 63 in the headset's preview** (it was 85,
86 and 92 on its tracks). The heaviest before were Find Your Way Middle (223 -> 48) and Connections (200 -> 46). G0's play place: its
heaviest station 79 -> 76 of its own budget of 100 (the play budget's test); its stations' first views 26-42 draws,
5.2-5.3K triangles (were 29-45 and 0.5-0.6K).

| Room | Track | Phone draws (3D) before → after | Phone triangles before → after | VR preview draws (3D, the start stand's heaviest way) before → after | Room's own VR draws, heaviest stand (test) before → after |
|---|---|---|---|---|---|
| animals | little | 4 → 5 | 2338 → 8192 | 45 → 10 | 94 → 36 |
| animals | middle | 15 → 9 | 2834 → 13352 | 47 → 11 | 163 → 44 |
| animals | big | 91 → 30 | 3922 → 8980 | 93 → 31 | 100 → 36 |
| calm_corner | little | 47 → 28 | 4286 → 6528 | 47 → 29 | 82 → 33 |
| calm_corner | middle | 47 → 28 | 4214 → 6456 | 47 → 29 | 80 → 44 |
| calm_corner | big | 47 → 28 | 4278 → 6520 | 47 → 29 | 54 → 35 |
| connections | little | 212 → 56 | 5790 → 18694 | 177 → 47 | 186 → 48 |
| connections | middle | 212 → 56 | 5786 → 18690 | 177 → 47 | 194 → 48 |
| connections | big | 212 → 56 | 5822 → 18726 | 177 → 47 | 200 → 46 |
| earth_weather | little | 26 → 18 | 3542 → 9066 | 28 → 17 | 63 → 42 |
| earth_weather | middle | 26 → 18 | 3326 → 8850 | 28 → 17 | 57 → 24 |
| earth_weather | big | 29 → 19 | 2970 → 8156 | 62 → 30 | 81 → 54 |
| electricity | little | 58 → 34 | 3422 → 5782 | 60 → 35 | 59 → 34 |
| electricity | middle | 56 → 32 | 3274 → 8426 | 58 → 33 | 82 → 38 |
| electricity | big | 67 → 36 | 3622 → 6150 | 63 → 34 | 114 → 45 |
| find_way | little | 101 → 24 | 3662 → 10000 | 105 → 27 | 146 → 28 |
| find_way | middle | 108 → 24 | 3850 → 17640 | 107 → 27 | 223 → 48 |
| find_way | big | 23 → 23 | 4122 → 12196 | 66 → 23 | 77 → 36 |
| fire_escape | little | 65 → 38 | 4466 → 10298 | 44 → 27 | 76 → 37 |
| fire_escape | middle | 37 → 18 | 3782 → 9806 | 35 → 17 | 71 → 29 |
| fire_escape | big | 42 → 22 | 4158 → 10182 | 40 → 21 | 41 → 21 |
| goal_board | little | 52 → 33 | 3286 → 5466 | 43 → 25 | 55 → 37 |
| goal_board | middle | 39 → 33 | 3208 → 5388 | 30 → 24 | 43 → 40 |
| goal_board | big | 45 → 38 | 3744 → 5924 | 34 → 27 | 40 → 34 |
| home_helper | little | 24 → 19 | 2798 → 8114 | 60 → 40 | 87 → 59 |
| home_helper | middle | 24 → 19 | 2762 → 8078 | 56 → 36 | 82 → 54 |
| home_helper | big | 15 → 15 | 2810 → 8162 | 62 → 38 | 74 → 48 |
| kitchen | little | 95 → 70 | 6474 → 9646 | 84 → 63 | 85 → 63 |
| kitchen | middle | 91 → 66 | 5910 → 9082 | 85 → 64 | 86 → 64 |
| kitchen | big | 104 → 69 | 6118 → 8978 | 81 → 60 | 92 → 60 |
| little_lifesaver | little | 29 → 16 | 2806 → 6024 | 31 → 17 | 61 → 38 |
| little_lifesaver | middle | 31 → 19 | 3282 → 6524 | 25 → 13 | 40 → 24 |
| little_lifesaver | big | 22 → 16 | 2718 → 5984 | 22 → 14 | 38 → 24 |
| market_square | little | 41 → 11 | 4794 → 12254 | 42 → 12 | 59 → 14 |
| market_square | middle | 118 → 41 | 4462 → 11966 | 110 → 42 | 128 → 52 |
| market_square | big | 123 → 43 | 4818 → 12446 | 115 → 44 | 156 → 61 |
| medical | little | 25 → 10 | 3066 → 7512 | 28 → 15 | 74 → 34 |
| medical | middle | 39 → 23 | 3098 → 6458 | 41 → 24 | 59 → 23 |
| medical | big | 24 → 15 | 2954 → 5996 | 33 → 23 | 34 → 23 |
| money_stall | little | 32 → 17 | 2914 → 9180 | 33 → 18 | 42 → 20 |
| money_stall | middle | 50 → 26 | 3294 → 9584 | 44 → 24 | 73 → 36 |
| money_stall | big | 55 → 29 | 3442 → 9688 | 48 → 27 | 72 → 35 |
| my_shop | little | 21 → 14 | 2710 → 10784 | 23 → 15 | 41 → 19 |
| my_shop | middle | 48 → 21 | 3126 → 11836 | 35 → 21 | 87 → 43 |
| my_shop | big | 50 → 23 | 3158 → 11868 | 37 → 23 | 127 → 51 |
| online_city | little | 31 → 10 | 3290 → 5428 | 28 → 11 | 32 → 16 |
| online_city | middle | 31 → 10 | 3182 → 5320 | 28 → 11 | 38 → 22 |
| online_city | big | 31 → 10 | 3230 → 5368 | 28 → 11 | 39 → 23 |
| poisons_cupboard | little | 76 → 25 | 3618 → 6966 | 40 → 18 | 84 → 25 |
| poisons_cupboard | middle | 77 → 25 | 3730 → 7078 | 55 → 22 | 123 → 32 |
| poisons_cupboard | big | 24 → 15 | 2794 → 5538 | 94 → 24 | 120 → 31 |
| real_builder | little | 23 → 24 | 3058 → 3680 | 19 → 19 | - → - |
| real_builder | middle | 51 → 52 | 3930 → 4552 | 36 → 36 | - → - |
| real_builder | big | 54 → 55 | 4490 → 5112 | 43 → 43 | - → - |
| safe_streets | little | 60 → 16 | 4926 → 33856 | 106 → 16 | 148 → 23 |
| safe_streets | middle | 107 → 25 | 6474 → 35104 | 177 → 41 | 175 → 38 |
| safe_streets | big | 157 → 34 | 10294 → 38036 | 154 → 33 | 162 → 34 |
| success_stories | little | 6 → 8 | 2374 → 4222 | 13 → 7 | 34 → 22 |
| success_stories | middle | 6 → 8 | 2374 → 4222 | 13 → 7 | 38 → 21 |
| success_stories | big | 6 → 8 | 2374 → 4222 | 12 → 7 | 86 → 24 |
| talk_deal | little | 50 → 17 | 3050 → 11272 | 40 → 18 | 67 → 19 |
| talk_deal | middle | 32 → 10 | 4294 → 12762 | 46 → 23 | 60 → 22 |
| talk_deal | big | 79 → 36 | 3634 → 11992 | 76 → 32 | 78 → 33 |
| water_safety | little | 38 → 24 | 2854 → 8666 | 39 → 25 | 51 → 26 |
| water_safety | middle | 40 → 26 | 2910 → 11406 | 44 → 41 | 102 → 51 |
| water_safety | big | 15 → 16 | 2430 → 6808 | 16 → 16 | 25 → 18 |

Real Builder's site is the Tools agent's (only the shared sky, sun and tone: one draw more).

## 5. Pictures

The before and after contact sheets (each row a room's track: the phone before and after, the headset's preview before
and after, the realistic style after): committed, smaller (the phone before and after, the headset's preview after):
`docs/devlog/parts/rooms-look/rooms_look_01.jpg` to `_04.jpg`; the full ones (with the headset before and the realistic
style) in the session's scratchpad,
`/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/rooms_look_sheets/rooms_look_before_after_01.jpg`
to `_08.jpg`, every single picture beside them in `room-shots/room_shots/{before,final}/{flat,vr}/{blocky,realistic}/`.
Re-make them with `tools/room_shots.gd` (its header) and a contact sheet of your own.

## 6. What the lead must check (no emulator, no headset here)

On the **emulator** (AVD `Pixel_8_API_35`, the autopilot's room runs or by hand):
1. Each room's first view on every track at 30 FPS or more, no frame over 100 ms, especially the heaviest in triangles:
   Safe Streets (34-38K), Find Your Way (Middle 18K), Animals (Middle 13K), the Kitchen (64 VR draws, the most).
2. The sky: no seam or gap at the dome's horizon on a tall phone (20:9) and on a tablet; Connections' and the street's
   night (the dome deepens, the lamps glow).
3. The block floors in both graphics styles (pixel and realistic): the tiles' scale looks right (one block a metre),
   nothing shimmers far off.
4. Faces: Calm Corner (Bobo, Mo, Pip-pop change feelings), Connections at night, the Story Theatre's scenes, the Kitchen,
   Medical Moments (Mo's allergy: the soft pink stays her own).
5. The world's sun comes back after leaving a room (the sandbox's light the same as before opening it).

On the **Quest 3** (the vr preset):
1. The heaviest stands: the Kitchen (60-64 room draws), Market Square Big (61), Home Helper Little (59), Earth and
   Weather Big (54), My Shop Big (51); the frame stays at 72 Hz with the HUD up.
2. The sky dome round the head (no edge in view when looking up or turning), the ceilings at their height (Calm
   Corner, the Kitchen, Medical's room) never inside the head when standing tall.
3. The play place (`PlayArena`): the garden round the table, its own sun, every station's reach.
4. The far words (signs on other places 25 m away vanish; nothing read at a step should).

## 7. Commits (this branch, the rooms' look)

`3dab893e` the pattern (the kit), `c21459e6` the look rules and the people's merge, `ae77276e` Talk & Deal, `37672eb2`
Connections, `28fee1e3` Water Safety (the sky follows the viewer), `ece43c09` My Shop, `c64838b1` (WIP, paused),
`a4044800` G0's play place, `e690bd09` the Market Square, `c5a1da22` the warm-up guard, `c41ff81d` My Money Stall
(`town_square`), `612e10bf` Little Lifesaver, `8106b199` Fire Escape, `c4d21155` the Kitchen, `0801a00b` Calm Corner,
`19d83fb4` the Goal Board, `c8451d1e` Success Stories, `7aa9df54` Online City, `7c9e0798` Home Helper, `e9f6cb87` Earth
and Weather, `3b0389ad` the Poisons Cupboard, `0a3e65e2` Electricity, `6692c5a6` Medical Moments, `bd16463f` Animal
Friends, `4797e963` Find Your Way, `11c0b536` Safe Streets, `1c9ee739` every room held to the rules, `d5e99573` no
dressing over a sign's words, and this notes commit; `lead-merge` merged in at `fb69cf4d` and again before the suite.
