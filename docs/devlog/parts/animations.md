# More animations (owner #94: "also make more animations")

The brief: `docs/superpowers/plans/2026-09-30-animations-brief.md`. Branch `worktree-agent-a7ec21eb56ea686a1`, cut from
`lead-merge` at `fa9c09d3`. Order of work (so the other agents benefit early): the School pictures' animation API and
the first moving kinds, the UI motion helper, characters and helpers, the world's ambient life with its bench.

## 1. Moving School pictures (for the School and the Shorts)

### The API's shape (for the Shorts agent and the lead)

```gdscript
var pic := SchoolPicture.new(data, Vector2(560, 380))
pic.playing = true            # advances pic.time by itself, redrawing at SchoolPicture.FPS (30) while it shows
pic.time = 3.2                # or drive the clock yourself (seconds): a set redraws once; playing = false stops it
SchoolPicture.animates(data)  # true when this picture has motion to show (a good picture of a moving kind, and its
                              # data does not say "animate": false)
SchoolPicture.should_play(data, question)   # the School's rule: lesson cards play, exercises (question = true) stay
                              # still unless their data says "animate": true; Reduce motion: never
SchoolPicture.time_of(canvas_item)          # what a kind's drawing reads (0 for a still picture)
```

- `time` is 0 at the start, and **time 0 is every moving kind's still picture**: a picture nobody plays looks exactly
  as before. A still kind ignores `time` and `playing` (it never ticks and draws once; the test draws one picture of
  every still kind the lessons use, with the clock running, and counts one draw each).
- A playing picture stops ticking its redraws while it is hidden (`is_visible_in_tree`), and `playing = false` freezes
  it at its time. Setting `time` on a moving picture redraws it once, so a Short can scrub or sync it to its own clock
  (set `playing = false` then, and set `time` every frame or as often as you like).
- The data key `"animate"` (bool) is optional on every picture: `false` keeps a moving kind still anywhere; `true`
  lets an exercise's picture move (the School keeps questions still by default: the gears' turning is the answer to
  "which way does C turn?"). `SchoolPicture.problem` rejects a non-bool.

### What moves, and how (the rules are in `SchoolPictureMotion`, `ui/school/school_picture_motion.gd`)

| Kind | Where it is drawn | What moves |
|---|---|---|
| `gears` | `school_picture_g5life.gd` | every gear turns its way; the small ones faster, by the teeth (`gear_spin`: 3 teeth a second pass the meshing point); the marks go round, so turns can be counted |
| `pulleys` {sizes} | g5life | the spokes turn with the belt, the small wheel faster (`pulley_spin`); a crossed belt the other way. A lift stays still |
| `cam` | g5life | the cam turns clockwise, 60 degrees a second from its `turn`; the follower rides up and down, the graph's dot runs along its line |
| `food_web` | g5life | a gold dot of energy runs along every arrow, from the food to its eater (1.6 s a trip, staggered) |
| `lever` | `school_picture_life.gd` | the effort pushes its end down, the load's end rises and comes back (9 degrees, 2.4 s), when the pivot is between them |
| `circuit` {lit, switch closed} | `school_picture_g4life.gd` | gold dots of current flow round the wire from the cell's + end (`circuit_way`); a motor's fan spins |
| `wave` (no labels) | `school_picture.gd` | the waves travel right; more waves in a band (a higher pitch) go up and down faster at the same speed |
| `water_cycle` (new) | `school_picture_motion.gd` | vapour rises from the sea, the cloud drifts, rain falls on the hill, the river runs to the sea |
| `moon_phases` (new) | motion | the Moon goes round the Earth once in 16 s, its Sun side lit, and beside it the Moon as it looks from Earth; the "row" rings the phase now |
| `orbit` (new) | motion | planets go round the Sun, nearer ones faster (the real years' ratios); the Moon round the Earth; gravity and speed arrows ride the first body |
| `pendulum` (new) | motion | 1-3 pendulums swing; a longer one more slowly (its period grows with the square root of its length); energy bars trade kinetic for potential |
| `rocket_stages` (new) | motion | the rocket climbs, each stage burns, drops away turning and falling, the next fires; the sky goes black |

Flowing dots fade in over their first 0.4 s (`fade_in`), so time 0 has none (the still picture). The new kinds' fields
are in the header of `school_picture_motion.gd`. No lesson uses the new kinds yet (lesson JSON is the lesson quality
agent's): the lead can add them where they teach, e.g. `g6.science.water_cycle` (water_cycle), `g8.science.moon_seasons`
(moon_phases), `g8.science.gravity_orbits` and `solar_system` (orbit with arrows), `g8.science.kinetic_potential`
(pendulum with energy), `g4.science.rockets_explorer` (rocket_stages), `g8.science.waves` (wave).

### Cost (desktop, headless, `test_drawing_a_moving_picture_is_cheap`)

One draw of a moving picture at 560 x 380: 0.08-0.5 ms for most kinds; the dearest is four gears with 90 teeth, 0.93 ms
(the gears' polygons and outlines). At 30 draws a second that is under 1 ms a frame here, 3-5 ms on a phone at the
dearest, in the School's screens (a menu, not play). The test fails over 2.5 ms a draw.

### Rulings

- **Exercises hold still by default** (motion can give the answer away: the turning gears answer "which way does C
  turn?", the cam's turn is the question "how high is the follower at 90 degrees?"); `"animate": true` opts in. Cost if
  wrong: a question that would have been clearer moving is still until its data says so.
- **A lever moves only when its pivot is between the load and the effort**: the picture's effort arrow always pushes
  down, which for a load between would push the load down too. Cost if wrong: grade 3's class 2 and 3 levers stay still.
- **A labelled wave stays still** (its labels point at a still crest and trough). Cost: grade 4's labelled wave is still.
- **A circuit moves only when the picture says it works** (`lit`, switch closed): a picture that does not say so may be
  the question "will it light?". Cost: an unlit working circuit shows no current.
- **Reduce motion keeps the School's pictures still** (`should_play`); a Short that drives `time` itself is the Shorts
  agent's call (a video the child chose to watch).
- **The orbits are not to scale** (evenly spaced rings) and the Moon's month in the orbit picture is 4 s beside Earth's
  10 s year (to scale it would be a blur); the periods of the planets keep the real ratios.
- **New kinds live in a new file** (`school_picture_motion.gd`, the brief's allocation lets the animation agent add
  drawing to the picture files); the kind-unique test finds it by itself.

## 2. The UI motion helper (`UiMotion`, `ui/fx/ui_motion.gd`; `UiFlyers`, `ui/fx/ui_flyers.gd`)

One helper so every panel feels the same (tweens only; nothing runs per frame when nothing moves):

| Call | What a child sees | Where it is used now |
|---|---|---|
| `UiMotion.pop_in(control, delay)` | a card or panel grows from its middle (0.86 to 1, a little overshoot) and fades in, 0.24 s | the HUD's toasts (a new one), MORE, the pause menu, the Secret Book, the shop, the Mission Board, the world map, the pet panel, the emote wheel; the School's lesson cards, the round's stars, the "+gold" line |
| `UiMotion.squash_on_press(button)` | a pressed button squashes (wider, flatter) and springs back | every `UiKit.big_button` (so every SchoolUi / OnlineUi button: 359 call sites) |
| `UiMotion.fly(host, from, target, count, UiFlyers.COIN / STAR)` | coins or stars fly in an arc to their counter, which bumps as each lands | Survivor gold earned (`GoldCounter`: from the middle of the screen to the coin, 1-8 coins by `coins_for`); the School's answer gold (to the "+gold" line) |
| `UiMotion.burst(host, at, count)` | a few gold stars burst, fall a little and fade | a right answer in the School (8 at the first try, 5 after help); a unit's level-up at a round's end (10) |
| `UiMotion.glow(control)` | brightens and settles three times, then exactly itself again | the round's stars when a star is won, the unit is mastered, or a third star remembered |

- `UiFlyers` is one pooled node per screen (a `top_level` child of the host, never laid out by a container), drawing
  every piece in one canvas item; at most 24 pieces (the oldest land at once); asleep (not processing) when nothing
  flies. Cost: a step with 16 pieces in the air 10 us here (`test_flying_pieces_are_cheap`).
- **Reduce motion:** a fade without growing, no squash, at most two coins flying straight, half the stars, slower, not
  spinning (FeelRules), one glow instead of three.
- UiMotion's tweens run while the game is paused (`TWEEN_PAUSE_PROCESS`; the pause menu pauses the tree).
- Ruling: **the main menu's own pop stays** (`Menu._show` already grew its pages from 0.92 with the same easing, and
  scales a tall page down to fit); cost if wrong: its pop is 0.18 s, a hair quicker than the HUD's.
- Ruling: **the Theater's panel is not touched** (the Shorts agent's); the lead can add `UiMotion.pop_in(self)` to its
  `open()` after the merge.

## 3. Characters and helpers

- **New poses** (`EmotePoses`, both bodies): `think` (a hand to the chin, the head tilted), `yawn` (arms up wide, the
  head tipped back), `stretch` (up on tiptoe, then arms out) are free on the emote wheel (`AvatarCatalog`
  `emote.think/yawn/stretch`: the child can put them on the wheel in the avatar editor); `look` (a glance round) and
  `hooray` (a happy little jump and one whole spin, arms up) are the body's own. Poses got a `head` key,
  Vector3(nod, turn, tilt): the blocky head anchor turns (hats and hair with it), the realistic `Head` bone turns in
  `EmotePoser._pose_bone` (else the clip's own head).
- **Idle life** (`AnimIdle`, `entities/player/anim_idle.gd`; `Player._idle_tick`): after 7 s standing still, a
  glance round, a stretch or a think every 8-14 s (a yawn at night by the sky's clock, `Animal.time_source`); a wave
  when a friend (a player or a bot) walks up within 5 m, once per arrival. Never while walking, flying fast, swimming,
  asleep, knocked out, riding, hiding, or over an emote or dance. **Every game plays these for every body it shows;
  nothing is sent** (ruling; cost if wrong: two screens may see a different fidget, which nobody can tell).
- **Happy reactions** (`Player.react_happy`, sent like any emote): a secret found, a quest step or story done, a board
  goal, an animal tamed (`AnimIdle.cheers_for` on `Progress.counted`), a Wonders Passport stamp won
  (`WondersDirector.stamp_won`, new), a rocket's landing (`AnimIdle.cheer_on_arrival`, set in the sandbox's `landed`;
  the child jumps 0.8 s after the new world's loading card is gone). Never over a dance or emote the child chose (an
  idle fidget gives way). Not for blocks, monsters or exploring (too often) nor waves and bosses (they dance
  `victory`). A lesson star: the School is a menu screen (no avatar there): its stars pop and glow instead (§2).
- **Helpers greet** (`AnimGreet`, `entities/npcs/anim_greet.gd`): Tilly and the quest givers, Gemma, the helper robots
  and the aliens hop hello (a crouch, a stretch, a hop, settled exactly at rest) as the child walks up, on top of the
  turn and wave they had; a quest giver the child stands by jumps for joy three times at the child's quest step, story
  or board goal (`AnimGreet.cheers_for`). The robots' and aliens' own `cheer()` (a hop and sparkles) already came with
  their quests. **Professor Hoot** (the School's owl, `SchoolUi.Teacher`) bounces hello whenever a page shows him
  (`UiMotion.bounce`: scale only, so no container is fought).
- **Animals' idle life** (`AnimLife`, `entities/animal/anim_life.gd`; `Animal._life_step`), on top of the wagging
  tails and grazing heads they had: now and then (6-14 s, each animal its own rhythm from its id) a standing animal
  hops (rabbits, frogs, squirrels, chickens, the bunnies, the candy bird), shakes itself (dogs, foxes, sheep, goats,
  horses, donkeys, parrots, ducks, penguins, polar bears) or sniffs the ground (the rest); never while it walks, sits,
  carries a rider or is golden; fish keep their sway. A cheer cuts a fidget short cleanly (`AnimLife.rest`). Cost: 40
  animals 17 us a frame here (`test_forty_animals_fidgeting_are_cheap`).
- **A new wheel has Think** (`AvatarCatalog.DEFAULT_WHEEL`: where Thumbs Up was), so MORE's EMOTE plays wave, dance,
  cheer and think from the first world (the brief's list). Ruling; cost if wrong: a new child finds Thumbs Up in the
  avatar editor, one tap away (a saved wheel keeps its own).
- Rulings: **no blink** for the 3D helpers (their eyes are part of one vertex-coloured mesh each: a blink needs eye
  meshes of their own; cost if wrong: they hop and wave but never blink). **The animals' fidgets are not sent** (every
  game shows its own, like their tails). **Idle fidgets are not on the wheel** (`look`, `hooray`).
- Small hooks in files not ours: `core/avatar/emote_poses.gd` (the poses), `core/avatar/avatar_catalog.gd` (three
  free emotes), `entities/player/blocky_avatar.gd` and `emote_poser.gd` (the head), `entities/player/player.gd` (idle,
  cheers), `entities/animal/animal.gd` (fidgets; the cheer rests the body first), `entities/npcs/quest_giver.gd`,
  `world/prospecting/prospect_camp.gd`, `entities/robot/helper_robot.gd`, `entities/alien/alien.gd` (the hop hello),
  `world/wonders/wonders_director.gd` (`stamp_won`), `scenes/sandbox.gd` (the landing and stamp cheers),
  `ui/school/school_ui.gd` (Hoot's bounce).

## 4. The world's ambient life (`world/life/`)

| What | Where | How (budget) |
|---|---|---|
| Fireflies over the meadow at night | `Fireflies` (a `CPUParticles3D`), `LifeRules.fireflies_on` | 14 (LOW: 7), blinking on and off three times a life (a size curve), drifting round the player in the world's space; the golem's glow instanced (the rocket flame's shader); 30 fps, no shadows |
| A flock of birds circling high by day | `Birds` (one `MultiMeshInstance3D`), `LifeRules.bird_*` | 6 birds (LOW: 3) of 3 boxes each (a body, two wings flapping then gliding), each round its own circle 9-20 m out, 16 m over the player, the flock's middle drifting after them; Fx's material in a multimesh laid out exactly like a CPUParticles3D's (colours and custom data), a fixed bounding box, no shadows; hidden and not updated at night or in a cave |
| Both | `AmbientLife` (sandbox `_add_ambient_life`, where a universe has `insects`: Green Meadows) | when: four times a second; every frame: follow the player, fly the birds; nothing sent; the developer arg `--no-ambient-life` leaves it out |
| Leaves and petals from a broken tree, bush or flower block | `LifeRules.flutter` from `Fx.break_block` | 7 leaves in the block's greens or 10 petals, floating down slowly and tumbling (`Fx.confetti`: Fx's material, its 32-effect budget, LOW halves, Reduce motion calms) |
| The Launch Site tower's warning light blinks | `Blinker` (in `LaunchBuildings.setup`) | a red glowing box over the tower's light, on 40 % of every 1.2 s (the golem's glow, its own vertex colours); a visibility change twice a period |
| A flag waves on Mission Control's roof | `WavingFlag` (in `LaunchBuildings.setup`) | a pole and five teal strips (the middle one gold) hinged one to the next, a wave running along them; the Launch Site's own vertex-colour material; asleep farther than 90 m from the camera |

**Found and fixed on the way:** Green Meadows' bees and butterflies (owner #41's `MeadowInsects`) were never added:
the sandbox asked `WorldService.descriptor()`, which is null for universe 1 (it names only the other universes), so
`_candy_local` returned before them. `Sandbox._meadow_local` now asks `UniverseRegistry.descriptor(world.universe)` and
adds the insects and the ambient life (the life bench shows both in a new Green Meadows world).

### The bench (`tools/life_bench.gd`)

A new Sandbox world in Green Meadows, the player standing on the grass; four windows, the life on and off by turns,
by day (the birds fly) and at night (the fireflies blink). Main thread's CPU per frame (Linux /proc), desktop,
headless, `--max-fps 60 --voxel-threads=2`, load 2.6-3.0:

| Run | day on | day off | night on | night off | the life's own tick |
|---|---|---|---|---|---|
| 1 (15 s windows) | 1.820 ms | 1.798 ms | 2.342 ms | 2.220 ms | 61 us by day (birds), 13 us at night |
| 2 (20 s windows) | 1.973 ms | 1.823 ms | 2.198 ms | 2.215 ms | 67 us by day, 13 us at night |

So the life costs 0.0-0.15 ms of the main thread a frame here (the runs' noise is about 0.1 ms): 0.1-0.5 ms on a phone.
Headless draws nothing: the GPU's share (one multimesh draw of 18 boxes, one particle draw of 14) is the emulator's
to show. Run it: `XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --max-fps 60 --path . --script
res://tools/life_bench.gd -- --voxel-threads=2` (a private folder with a copy of `profile.json`).

### Rulings

- **Fish in water: the game's own fish** (the `fish` animals swim in the meadows' water); no second kind of fish.
  Cost if wrong: a pond without an animal fish looks empty.
- **Flags that are blocks stay still** (the lookout towers' flags and the colonies' are voxels; Gemma's is part of
  her camp's one mesh): only the Launch Site's new flag waves. Cost: landmarks' block flags do not wave.
- **The wonders' water features stay block water** (their flow is the water's own look).
- **Birds and fireflies only in Green Meadows** (where the bees and butterflies are): the desert, snow and candy
  skies have their own weather. Cost: no birds over the other worlds.
- **Warm-up:** the birds share Fx's instanced draw and the fireflies the golem's glow instanced (the rocket flame's, in
  the census's `flight` phase), both listed in `test_shader_warmup_sources.gd`. **The lead re-runs the census after the
  merge** so the fireflies' first sight at night in a meadow (the `play` phase's night) and the Launch Site's blinking
  light are in their own phases' tiers.

## Windowed shots of the moving pictures (`tools/anim_shots.gd`)

`XDG_DATA_HOME=/tmp/easycraft-anim-shots godot --path . --disable-vsync --script res://tools/anim_shots.gd`: every moving
sample at 0, 1.3 and 3.1 s, three to a row (PNGs in `user://anim_shots/`). What I saw (2026-09-30, this PC's window):
the water cycle's vapour rising up its wavy arrows, the rain and the river's dots; the Moon going round anticlockwise
with its Sun side lit and the view from Earth growing from new to a waxing crescent to the first quarter (the row's
ring moving with it); the planets on elliptical orbits (the card's width used), the gravity and speed arrows riding the
Earth; the long pendulum behind the short one, the energy bars trading kinetic for potential; the rocket on its pad,
then climbing into a deepening blue with a stage dropping away (fins, turning, fading) and the next one firing; the
gears' marks going round (the small gear fastest); the lever tipping, effort down and load up; the circuit's gold dots
flowing clockwise from the battery's + and the motor's fan turned; energy dots running up the food web. Fixed from the
first shots: the four-planet orbit was cramped (now ellipses), the gravity and speed words sat on the planets' names
(now names outside the orbit, the words beside the arrows), a falling stage left the card (moving pictures clip to
their card now; the fall is shorter), the rocket's sky went grey (now blue, then black).

## For the lead

- **Merge:** the School's picture files (`school_picture.gd`, `_g4life`, `_g5life`, `_life`), `school_screen.gd`,
  `exercise_panel.gd`, `choice_answer.gd`, `school_ui.gd` (lesson quality edits only lesson JSON, so no overlap
  expected); `ui/theme/ui_kit.gd` (one line: every big button squashes); `scenes/sandbox.gd` (`_meadow_local`,
  `_add_ambient_life`, the landing's and the Wonders stamp's cheers); `entities/player/player.gd`, `animal.gd`,
  `emote_poses.gd`, `avatar_catalog.gd`; `tests/unit/test_shader_warmup_sources.gd` (two COVERED lines). The Shorts
  agent may call `SchoolPicture.time` / `playing` and the new kinds (the API's shape above).
- **After the merge:** re-run the shader census (§7 of DEVELOPMENT.md) so the fireflies (the golem's glow instanced,
  at night in the meadow), the birds (Fx's instanced draw) and the Launch Site's blinking light land in their tiers.
  Add `UiMotion.pop_in(self)` to the Theater panel's `open()` if the Shorts agent has not.
- **On the emulator:**
  1. A Green Meadows world at dusk and at night (`/time` in the chat): FPS with the birds circling and the fireflies
     blinking (≥ 30 FPS, no frame over 100 ms), in both styles; that the fireflies glow (unshaded) and the birds read
     as birds (small, dark, flapping) against the sky; bees and butterflies by day (they were never added before, see
     §4).
  2. A phone's feel of the UI: a panel's pop (MORE, the shop, the pause menu), a button's squash, coins flying to the
     gold counter in Survivor (Reduce motion on: a fade, no squash, two coins).
  3. The School: a lesson with gears or a lever (grade 5 D&T, grade 3 levers) moves; its exercise's picture holds
     still; a right answer bursts stars; Professor Hoot bounces; a round's end with a new star glows.
  4. Standing still for 10 s: a glance round or a stretch (a yawn at night); walking up to Tilly: she hops hello; a
     secret found: the child jumps and spins (seen by a friend too).
  5. The Launch Site: the tower's light blinks, the flag waves on Mission Control's roof.

## The full suite (2026-09-30 23:16 to 2026-10-01 00:11, 3291 s, while another worktree's suite ran)

9224 passing, 4 failing files: `test_hud_layout.gd` and `test_trade_director.gd` measured the MORE panel's buttons
right after it opened, mid-pop (drawn at 0.9 of their size): they now call `UiMotion.settle(hud.more)` first (a new
helper: a motion ended at once); `test_ui_motion.gd` sampled a squash 0.12 s in, too early on the busy PC: every
animation test of mine now watches every frame of a motion instead of one moment; `test_avatar_models.gd`'s
`test_air_jumps_flip_and_come_back_upright` (a wall-clock check of the flip 0.12 s in, not touched here: `play_jump` is
unchanged) failed under the load and passes alone (15/15). The four files, and every file of mine, pass on their own
after the fixes (96 tests). Two `Risky` (no assert) tests are the terrain's, as before.
