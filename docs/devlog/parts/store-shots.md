# Store pictures by script (2026-09-27)

The new Google Play graphics (`docs/store/screenshots.md`'s shot list: eight 1920 × 1080 phone screenshots and the
1024 × 500 feature graphic) taken on the desktop by a script instead of by hand on the emulator: the real game, real
rendering (Vulkan Mobile on this PC's Intel iGPU), the phone's touch HUD (`-- --touch`), in real Sandbox worlds set up
through the game's own paths. No editor, emulator or adb; **no game code changed**. The files are in
`docs/store/graphics/next/` (a `.gdignore` folder), ready for the lead to upload.

## How to run it

```bash
XDG_DATA_HOME=/tmp/easycraft-store-shots godot --path . --disable-vsync --resolution 1920x1080 \
  --script res://tools/store_shots.gd -- --touch [--only=wake,size,portal,dragon,dog,hide,race,book,feature]
```

- Windowed (headless draws nothing); it refuses unless `XDG_DATA_HOME` contains "shots" (it starts new Sandbox worlds
  and writes a made-up player's profile there). The 1920 × 1080 window fits this PC's 1920 × 1200 screen; a smaller
  viewport would be resized with Lanczos to 1920 × 1080 (a `STORE_SHOT resized` line says so; it never happened).
- Candidates go to `$XDG_DATA_HOME/store_shots/<shot>_<n>.jpg` (1920 × 1080, RGB, quality 0.92); `STORE_SHOT` lines
  say what happened (`STORE_SHOT chat …` echoes every chat answer, e.g. a refused `/build`). A whole run takes about
  15 minutes (nine new worlds); `--only=` runs some; `--only=probe_candy,probe_dragon` pictures those universes'
  spawns in four directions. The launcher quits with 1 if the steps script does not load (it hung before).
- The picked candidates were copied by hand to `docs/store/graphics/next/shot-<n>-<name>.jpg`. The feature graphic
  is screenshots.md's PIL recipe on `feature_1.jpg`, with one change: the wordmark at (110, 110) instead of
  (60, middle), so it lies inside the middle 80 % (x 102–922) and on open sky.

## How it sets things up

- **Profile** (private folder): username "SwiftDragon54", under 13, the new default look (`AvatarLook.new()`: orange
  tee, teal trousers, the buddy badge), BLOCKY, graphics HIGH, view distance 160, no FPS counter, song names and
  captions off, every universe reached (5), `purchases` ["plus"], the shop tip seen. Its progress is reset and some
  earlier play is counted in once (`PLAYED`: buddies woken, pets tamed, secrets, races …; level 5), so the adventure
  board's first goals are done and no "Goal done: Wake a buddy!" banner covers a moment.
- **Every picture has a NEW world of its own** (Green Meadows seed 12345, the Candy Kingdom 424242, the Dragon Realm
  515151; `Game.start_world` the way the game opens a universe's Sandbox world after a portal trip), so nothing from
  one picture (a buddy, a pet, a bot) follows the child into the next. `/time day` and `/freeze on` through the chat
  runner; the chat's answers cleared before each picture.
- **Stages**: a flat meadow at least 60 blocks from the spawn and 70 from the Shorts Theater (`_flat_meadow`, the
  world's own `MeadowsBiomeShape`), levelled round its middle with grass; trees and plants in the way cleared
  (`_clear_plants`); wild animals near it sent away every frame (they walk up to look at the magic, with "?"
  bubbles), so nothing wanders into a picture.
- **The camera** is the game's third-person camera: only its yaw and pitch are set, as a finger drag sets them (the
  child's head is always in the middle, as in the game), and the body is turned to face the camera. The feature
  graphic's photo is photo mode's own orbit camera (yaw, pitch, distance, a pan within its 6-block limit, as its
  gestures allow) with photo mode's buttons hidden the way the shutter hides them.

## The pictures

| # | File | What it shows | How |
|---|---|---|---|
| 1 | `shot-1-wake.jpg` | A 4-block buddy (teal legs and arms, orange body, yellow head, pink nose) in a sunny meadow by brick ruins and trees, its googly eyes just open and gold stars round it; the child beside it with the wand in hand; the toast "Boppy is alive! Tap it to cheer." | `/give wand`, `Session.request_spark` on the build (what the wand's tap sends), the frame 1.0 s after the spark (after the blink, before the name tag pops up half hidden behind its head) |
| 2 | `shot-2-size.jpg` | Size Magic: the tiny child standing at the feet of a giant 6-block buddy, the camera low and looking up at its face and eyes | `/size tiny`; the buddy and the child on a 2-block grass terrace, the child 0.2 from its edge, so the tiny child's short camera can look up from below the edge (on flat ground it squeezes onto the child) |
| 3 | `shot-3-portal.jpg` | The Candy Kingdom (frosting ground, candy canes, lollipops, cake hills): a golden 2 × 3 portal with its gold-and-rainbow swirl on the left, the child beside it | its own Sandbox world (away from its Theater); two frames built with the block API, both Portal Cores placed through `Session.request_set_block` (the child's placing path), the second 30 blocks behind the camera so they link and swirl |
| 4 | `shot-4-dragon.jpg` | The Dragon Realm at sunrise: the Sky Dragon flying over a floating island, the beams of its sun lanterns, one lantern close by, the boss bar on the HUD, the child on the home island's rim | its own Sandbox world; the rim away from its Theater; `/time sunrise`, `/summon skydragon`; the realm's trees between the child and the rim cleared; a frame about 5 s after the summon |
| 5 | `shot-5-dog.jpg` | The pet dog "Biscuit" (a heart over it: it is the child's pet) on the sand X of a buried treasure, the child beside it, the toast "You found the treasure!" | the nearest buried treasure in a meadow; `/summon dog`'s hook, three `Session.request_pet` (tamed), a name and collar; the dog's own sniff trip (its timer set to now) leads it to the X where it paws the ground; `/find treasure` |
| 6 | `shot-6-hide.jpg` | Night: hiding in a barrel in front of a small house with two lanterns; a goblin stands at the door looking about; the HUD's closed eye and "They can't see me!" | `/build house`, lanterns and a barrel through `Session.request_set_block`, `/time night`, `Session.stealth_request_hide`, `/peace on` (the night's wild monsters go home), a level-3 goblin summoned by the monster director |
| 7 | `shot-7-race.jpg` | Racing a bot friend ("Bloop, explorer bot" on its tag) on a built course: both jumping the red-and-yellow hurdle, coins, bounce pads, the teal-and-orange lane walls, the race clock 0:01.2 with 2 coins | START, a hurdle, bounce pads, CHECKPOINT and FINISH lines, coins; the child runs it once (the best run), a bot friend joins and is asked to race it (`BotDirector.race`, the FRIENDS page's RACE ME!), the child runs again beside it |
| 8 | `shot-8-book.jpg` | The Secret Book open on ANIMALS ("Animal Book", 18 of 33 animals, pets marked with hearts), its tab column SECRETS / ANIMALS / MEMORIES / IDEAS / SAVING | four secrets found through the secret director's own "found" path, fifteen animals summoned next to the child (met), `hud.secret_book.open()` then the ANIMALS tab (richer than SECRETS, which the doc allows) |
| – | `feature-graphic.jpg` | The wordmark on a sunset sky on the left; on the right a buddy waking (eyes open, gold stars, "Boppy") in front of a stone castle, the child beside it | two `/build tower` and a battlemented wall between them, `/time sunset`, the wake, then photo mode (HUD hidden) |

## Compromises and oddities

- **No shot swapped for a spare**; all eight are the doc's moments.
- **Shot 5**: the dog's dirt puff is real but tiny (6 small brown specks, `Animal._rpc_dig`), so it barely reads in the
  picture; and the /find arrow is not on the HUD: it only shows farther than 3 blocks from the target, where the dog
  would be too small, so the picture has the "You found the treasure!" toast instead. The treasure's sand X and the
  ground round it were levelled to one height (the X put back) so no step cuts through the picture.
- **Shot 6**: the view is from inside the barrel (the game's own hiding view: it darkens the edges), so the barrel
  itself is not in the picture. `/summon goblin` picks one of four spots 4 blocks round the child (one was inside the
  house), so the goblin is set down once between the barrel and the house, facing the barrel; from there it walks by
  itself. A level-1 goblin keeps away from lanterns (it never came near the house), so it is level 3.
- **Shot 2**: from pitch 0.5 up the tiny child's spring arm touches the terrace and the camera squeezes onto the
  child; at 0.46 a sliver of the giant's name tag peeks over its head at the top edge. The end-to-end verification
  run once had the giant walk after the tiny child (a buddy follows its owner from 3.5 blocks) and land on it, so the
  tool now holds it on its own spot through `Buddy.playdate_target` (what a playdate's spot does) and prints the
  camera arm's length per frame (1.80 = clear); two reruns after that were identical to the pick.
- **Shot 7**: no meadow 17 blocks wide and flat within 1200 blocks of the spawn, so the course is on the spawn's own
  meadow, levelled; the Monster Totem ("Wave 1") stands behind the PAUSE button there. The bot friend's name is picked
  at random (Doodle, Comet, Bloop in different runs).
- **The Shorts Theater**: every stage keeps 70 blocks from it (the Candy Kingdom's and the Dragon Realm's stand near
  their spawns); none is in a picture.
- The feature graphic's buddy is right of the middle (a play button may lie over the middle) and the wordmark is
  inside the middle 80 %; the child's feet are near the bottom right edge.
- `tools/store_shots_steps.gd` reaches a few private members for set-up (`sb._bot_director`, `sb._monsters`,
  `SecretDirector._mark_found`, `Animal._sniff_t`, `PhotoMode._place_camera`), as the smoke tools do.
