# The Reel Studio: 3D scenes and real video in the Shorts (owner #96)

The owner (#96, 2026-09-30): "consider we must keep reels high quality, implement visuals, video, animation tools and
use them". The bar: every cinematic reel should look like a real, polished short video a child would want to watch
twice. Brief: `docs/superpowers/plans/2026-09-30-reel-studio-brief.md`; spec §5.12b ("As built (Reel Studio)").
Built in the worktree branch `worktree-agent-a18c324cf667aaf40`, reset to `lead-merge` (`9ac40462`, EasyCraft Shorts
merged) first, while other agents improved the lessons and the world's visuals. No editor, emulator or adb was used;
pictures and videos came from real windows (`tools/reel_preview.gd`, `tools/reel_render.gd` under the Movie Maker).

## What a child sees

Eight new reels in the Theater's SHORTS feed, each with its topic's Shorts (the feed's order teaches: how to build a
rocket, then the 3D build, then lift-off…). They look like short films: a real 3D picture moving under the same big
captions, stickers, voice and sounds as every Short.

- **Live 3D** (drawn by the phone while it plays, a few KB of data each): *Build it part by part* (a Moon rocket of
  real parts drops onto the Launch Site's pad piece by piece), *Lift-off!* (countdown, ignition, white clouds rolling
  over the pad, the climb as the sky turns black, stage 1 letting go and tumbling away, stage 2, the lander flying on
  to the Moon), *The planets go round* (the eight planets round the Sun at their real years' ratios, starting where they
  really were on 1 October 2026; Jupiter's bands, Saturn's rings up close), *Landing on the Moon* (the lander's engine
  braking, the dust blowing off at touchdown, an astronaut waving, the Moon jumps six times higher, Earth in the sky).
- **Rendered video** (too heavy to draw live on a phone; on the web they come in a background pack): *Saturn's rings up
  close* (from a flat hoop far away to a flight through thousands of ice chunks going round at their own speeds), *A
  home on the Moon* (the Moon world's own colony, as the game builds it: the domes, the garden under pink lamps, the
  water plant and the rocket, Earth in the black sky), *The city in the clouds* (Venus's own cloud city: decks on their
  floats over the yellow clouds, the homes, the garden), *Fly over the Seven Wonders* (world 41's own wonders: the
  pyramid, the Hanging Gardens, the Lighthouse, the Colossus, the Mausoleum, the Temple of Artemis, and Zeus on his
  throne inside his temple).
- Until a video is on the device (a browser fetching the reels pack), its reel shows its still with "This video is on
  its way…" and waits; the feed swipes past it like any other.

## The tools (how to make a reel)

| What | Where |
|---|---|
| The format (a 3D stage's data) | `core/shorts/studio/studio_rules.gd` (StudioRules) |
| Pure, seekable motion | `studio_motion.gd` (models: moves, a rocket's stages letting go, emotes), `studio_camera.gd` (dolly, crane, push-in, orbit, cut, follow, shake, roll), `studio_particles.gd` (flame, smoke, dust, billow, sparkles, steam, snow) |
| The checks | `scene3d_kind.gd` (Scene3DKind: a stage and the `scene3d` actor), `video_kind.gd` (VideoKind), `reel_check.gd` (ReelCheck: the video's own quality) |
| Rockets of real parts | `studio_rockets.gd` (StudioRockets: a Moon rocket and its lander that RocketCheck flies) |
| Where the videos are | `reel_pack.gd` (ReelPack: `assets/reels/<file>.ogv` and `.jpg`, the web's reels pack) |
| Drawing | `ui/shorts/actors/scene3d_view.gd` (Scene3DView: a SubViewport of its own, rendered once a pose), `scene3d_models.gd` (the models), `scene3d_builds.gd` (the game's own places from their worlds' generators), `scene3d_effects.gd` (particles, one multimesh each), `scene3d_sky.gd` (the sky and the stars), `video_view.gd` (VideoView), `scene3d_drawer.gd`, `video_drawer.gd` |
| A whole reel's picture | `ShortPlayer`'s plate: a Short's `stage` (live) or `video` (rendered), under its actors and caption |
| Filming | `tools/reel_render.gd` (frames for the Movie Maker, pictures of moments, the bench), `tools/reel_render.sh` (the Movie Maker → Theora, the still, the video's frame sheet, the manifest) |
| Reviewing | `tools/reel_preview.gd` (the studio and its frame sheets: a cinematic reel live; `--video`: its video) |
| Reels | `data/shorts/cinematic/*.json`, listed in `data/shorts/shorts.json` |

### A stage, in short

```json
"stage": {"sky": [{"at": 0, "sky": "launch"}, {"at": 19, "dur": 8, "sky": "space"}], "light": "day", "sun": [0.55, 0.65, 0.5],
  "models": [{"id": "rocket", "model": "rocket", "rocket": "moon", "at": [0, 0, 0], "moves": [
      {"do": "move", "at": 14, "dur": 34, "to": [0, 6000, 0], "ease": "accel"}, {"do": "stage", "at": 29, "stage": 0}]}],
  "effects": [{"kind": "flame", "on": "rocket", "from": 12, "to": 48}],
  "camera": [{"at": 0, "pos": [9, 1.2, 13], "look": [0, 6.5, 0], "fov": 50},
    {"at": 8.9, "pos": [5, 13, 11], "look": [0, 7, 0], "path": "orbit"},
    {"at": 17, "cut": true, "follow": "rocket", "pos": [16, -8, 20], "look": [0, -2, 0]}]}
```

- Metres, y up (a block is 1 m). A Short's own `stage` runs on the Short's clock (a cinematic reel's picture); a
  `scene3d` actor's on its scene's (`{"kind": "scene3d", "at", "w", "h", "stage"}`). Any moment is a pure function of
  the time: a seek shows exactly the frame playing reaches (the feed's snap, the frame sheets, the Movie Maker).
- **Models:** rocket (`moon` or `lander`; `build` groups `{blocks, at, stage?}` drop in part by part), planet (any
  Star Map planet or moon: the flight's maps for the Earth, Moon, Mars and Mercury, bands for the gas giants), sun,
  rings (Saturn's C, B, A and F rings and the Cassini gap), ring_bits (ice chunks at Kepler speeds in an arc), orbit_line,
  ground (the flight's landing ground: moon, mars, grass, sand, concrete), pad (the flight's landing pad), blocks
  (`launch_tower`, `colony`, `venus_city`, `wonder` + `wonder`, or `cells`), avatar (`astronaut`, `explorer`,
  `default`), clouds.
- **Moves:** appear, pop, drop (entrances; a model may leave with `out` and come back), move, turn, spin (`rate` or
  `turns`), orbit, grow, stage (a rocket's stage lets go: it keeps the rocket's speed, falls back, drifts and tumbles),
  emote (wave, cheer, clap, think, hooray…). Eases: ShortTimeline's and `accel` (a steady push: a rocket leaving its pad).
- **Camera keys:** eased between (`smooth` by default); `path: "orbit"` swings round the look point (`turns` for more);
  `cut` starts a new shot; `follow` rides with a model; `shake` rumbles; `roll` turns the picture (a quarter turn stands
  the tilted orbits up in the tall 9:16 frame).
- **The style guide in 3D (Scene3DKind):** a camera move lasts 0.4 s at least (a cut any time) and never glides at a
  constant speed (but round an orbit); a model's move 0.4 s at least. **Framing (learned on the sheets):** the bottom
  third of the frame is the caption's: keep the subject above it (look a little below the subject), and the top band
  for the stickers.
- **Lights:** a key light from the stage's Sun, a fill and a rim light that stay placed round the camera, an ambient;
  no shadows (phones). Presets: studio, day, space, moon, dusk, venus, orrery (a light at the Sun's middle; the planets
  lit toward it).

### Filming and reviewing

```bash
# the studio (scrub, the checker's findings) and frame sheets (a cinematic reel live; --video: its video)
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_preview.gd -- --short=rocket_launch
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_preview.gd -- --sheet --short=rocket_launch,moon_colony
# pictures of moments at the video's size (the Short whole: --full)
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --resolution 540x960 --script res://tools/reel_render.gd -- --short=moon_landing --frames=3,14.5,30 --full
# a video reel to Theora (the Movie Maker; 3 min a reel here), its still, its frame sheet, the manifest
tools/reel_render.sh moon_colony [--q=2 --blur=0.5] [--keep] [--encode]
# the live reels' cost in a phone's player
XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --script res://tools/reel_render.gd -- --bench
```

## The reels: facts, sources and what the review changed

| Reel (topic, LEARN IT; live or video) | Its facts | Checked against / sources |
|---|---|---|
| **Build it part by part** (rockets, Mission Board; live, 47 s) | Built from the bottom up: engines first; fuel tanks hold fuel and oxygen (space has no air); fins keep it straight; a separator, then stage 2's space engines and tanks; the lander: legs, a tank, air and food, the capsule; the pointed nose last (air slides round it). | The rocket is StudioRockets' Moon rocket: `test_reel_studio_rockets` runs RocketCheck on it for the Moon (ok, 3 stages); `test_the_build_s_parts_are_the_rocket_s` (every part drops in). The words are RocketParts.WORDS' (the shop's cards). |
| **Lift-off!** (rockets, Mission Board; live, 48 s) | Nine engines, three stages; "3, 2, 1"; the engines push harder than the rocket weighs: PUSH 2,250 t, WEIGHT 1,582 t; the sky turns black (almost no air up in space); stage 1 and then stage 2 let go when empty, so the rest is lighter. | `test_the_launch_s_numbers_are_the_rocket_s`: 9 × RocketParts.push(ROCKET_ENGINE) = 2,250; RocketCheck's mass 1,581.5 t rounded; push > mass × LIFT_MARGIN. Staging: NASA, "Saturn V" (three stages) and NASA Glenn, "Multistage rockets". |
| **The planets go round** (space, Star Map; live, 50 s) | Eight planets round the Sun, each on its own path; Mercury 88 days, Earth 365; far planets slower: Jupiter almost 12 years, Saturn about 29, Neptune 165; one Earth year is 10 s here; not to scale. | `test_the_orrery_goes_round_at_the_real_years`: every period is 10 s × StarMap.year_days ÷ Earth's; each planet starts at StarMap.longitude for 1 October 2026; anticlockwise from the Sun's north. NASA Planetary Fact Sheet (87.97 d, 365.26 d, 4,332.6 d = 11.86 y, 10,759 d = 29.46 y, 60,190 d = 164.8 y). |
| **Landing on the Moon** (space, Star Map; live, 48 s) | No air on the Moon, so no parachute: the engine slows the lander; dust blows away at touchdown; people first stepped on the Moon in 1969; the Moon pulls about six times more gently, so you jump six times higher; Earth in the black sky. | The Star Map's Moon facts (the test reads "6 times higher" and "1969"); g Moon 1.62 m/s² vs 9.81 (NASA Moon Fact Sheet); Apollo 11, 20 July 1969 (NASA). |
| **Saturn's rings up close** (space, Star Map; video, 50 s) | From far away a flat hoop; billions of pieces of ice and rock, from dust to as big as a house; the rings reach 282,000 km from Saturn but are about 10 m thick; ice shines in sunlight. | The Star Map's Saturn facts (the test reads "ice and rock", "as big as houses"); NASA Science, "Saturn Facts" (rings out to 282,000 km, about 10 m thick, mostly water ice). The chunks orbit at Kepler speeds (ω ∝ r^−1.5). |
| **A home on the Moon** (space, Star Map; video, 50 s) | A colony: homes, a garden, a lab and a rocket, joined by glass tunnels; no air on the Moon, so the domes hold air in; plants under pink lamps give out oxygen; ice becomes water, air to breathe and rocket fuel; Earth in the black sky. | The colony is the Moon world's own (ColonyLayout through its generator, seed 20261001). Photosynthesis: BBC Bitesize (KS3 biology); pink grow lamps are red and blue LEDs (NASA, "Veggie"); water ice in the Moon's polar craters and splitting water for oxygen and hydrogen fuel (NASA LRO/LCROSS; the *Ice into rocket fuel* Short's sources). |
| **The city in the clouds** (space, Star Map; video, 50 s) | Venus is the hottest planet, about 465 °C on the ground; about 50 km up the air presses like Earth's and is much cooler; the air we breathe is lighter than Venus's thick air, so a float of it bobs up; scientists have imagined airships and floating cities there; the clouds below are acid. | The Star Map's Venus facts ("465 °C"); NASA's Venus Fact Sheet (mean surface 737 K); at 50 km about 1 bar and about 75 °C (NASA Langley's HAVOC study, 2015); molar masses: air about 29 g/mol, carbon dioxide 44; sulfuric acid clouds (NASA Science, "Venus Facts"). The city is Venus's own (VenusTerrain through its generator). |
| **Fly over the Seven Wonders** (history, Star Map; video, 54 s) | Greek travellers listed seven amazing places; the Great Pyramid, about 4,500 years old, still stands; the Hanging Gardens may never have been real; the Lighthouse's fire guided ships; the Colossus was a bronze giant; the Mausoleum a giant tomb with horses on top; the Temple of Artemis over 100 marble columns; Zeus sat on his throne; six are gone. | WonderFacts (the game's own: `test_the_wonders_are_the_tour_s_seven` reads "4,500 years", "Only the Great Pyramid still stands", "more than 100 marble columns"); Encyclopaedia Britannica, "Seven Wonders of the World". The wonders are world 41's own builds (WonderBuilds through its generator), where the tour stands them. |

**What the review changed (frame sheets of every reel, pictures at 540 × 960, the rendered videos' sheets):**

- *Lift-off!*: the first steam was a pile of big white cubes beside the rocket (removed); the ignition's smoke became
  white billows rolling low over the pad (a new `billow` effect) after the first try filled the frame with grey cubes;
  a bug made every ring of dust rise at 45° (a small lift had been made a whole unit up: fixed, test
  `test_a_ring_of_dust_spreads_low_along_the_ground`); the pad sat under the caption at ignition (the camera looks
  lower now); the opening shot was too far (closer, low); in the climb the flame hid under the caption (the rocket rides
  higher in the frame, and the camera falls behind as it speeds up); the separation was over in a second (a film's
  gravity, 6 m/s², and the camera tilts down to watch stage 1 tumble away); in the last scene the lander left the frame
  and the Moon slid away (the camera rides behind and below it, the Moon above); stickers overlapped the Moon and each
  other (moved; the quality test found PUSH over WEIGHT).
- *Landing on the Moon*: the astronaut showed its back (turned to the camera); the dust was huge grey cubes rising
  into the sky (the ring fix, smaller and lower, the billow look in moon grey); the first scene was a speck in a black
  sky (the camera now rides above the lander with the Moon's ground below and Earth on the horizon); the Moon's ground
  was snow-white (the moon light is softer); the Earth sat half off the frame (the shot looks a little higher).
- *The planets go round*: the inner planets were specks round a huge Sun in the tall frame (bigger inner planets and a
  camera that rolls a quarter turn so the tilted orbits stand up in 9:16); the orbit lines cut across Jupiter's and
  Saturn's close-ups (they leave for the close-ups and come back: `out`, then `pop`, a new rule in StudioMotion).
- *Build it part by part*: green boulders floated on the grass (the flight's rocks belong on the Moon and Mars only);
  the rocket grew too small in the frame (the camera follows it up).
- *Saturn's rings up close*: the chunks went round Saturn and out of the shot in 30 s (a gentler period: they drift
  past the camera); they hung over the Cassini gap (now in the A ring only); a grainy patch in the far shots (they
  appear only for the close flight).
- *A home on the Moon*: steam turned the ice scene into a wall of white cubes (removed); the ice mine read as an empty
  floor (the scene now flies past the water plant's dome to the rocket); Earth was out of the last shot (moved into it).
- *The city in the clouds*: the first shot was mostly empty haze (higher, over the decks); the deck orbit flew through
  the ring of decks (now from the landing deck's rim across the gaps to the garden and the homes); the float's close-up
  was a wall of steps (now from below, the floats hang against the sky).
- *Fly over the Seven Wonders*: the pyramid, the Lighthouse, the Colossus and the Mausoleum were too close (only walls
  of blocks: pulled back so each is whole); Zeus's statue is inside his temple (the camera goes in); the last shot from
  high above showed the wonders' world regions as a patchwork (it ends on the pyramid, the one still standing).

## Sizes and the cost on a phone

| Reel | How it plays | Length | On the device |
|---|---|---|---|
| Build it part by part | live 3D | 47 s | 6.4 KB of JSON |
| Lift-off! | live 3D | 48 s | 7.1 KB |
| The planets go round | live 3D | 50 s | 8.5 KB |
| Landing on the Moon | live 3D | 48 s | 5.8 KB |
| Saturn's rings up close | video 540 × 960, q3, blur 0.4 | 50 s | 1,755 KiB + a 18 KB still |
| A home on the Moon | video 540 × 960, q2, blur 0.5 | 50 s | 7,182 KiB + a 57 KB still |
| The city in the clouds | video 540 × 960, q3, blur 0.4 | 50 s | 4,698 KiB + a 31 KB still |
| Fly over the Seven Wonders | video 540 × 960, q3, blur 0.4 | 54 s | 6,454 KiB + a 33 KB still |
| **The four videos** | | | **20,089 KiB (19.6 MiB): in the APK (under 20 MiB); the web's reels pack** |

**Video encoding (measured on the Seven Wonders' 1,620 frames):** quality 5 was 26.1 MB; 5 with a keyframe every 5 s
25.2; a 750 kbps cap 4.8 MB but smeared in moving shots; quality 4 with a 0.4-pixel blur 10.7; **quality 3 with a
0.4-pixel blur 6.2 MB and clean in moving shots** (the blocks' pixel art shimmers frame to frame at a distance and that
shimmer cost most of the bytes). The colony (glass lattices everywhere) needed quality 2 with a 0.5-pixel blur.

**The live reels' cost** (`tools/reel_render.gd -- --bench`, this PC's Intel iGPU, a window, the Shorts' player at
a phone's 288 × 512 and 432 × 768 pixels; a phone's CPU is 3-5× slower, its GPU of the same class as this one or
slower; pose is the CPU's work to pose every model, particle and the camera, after the Theater's warm-up):

| Reel | Pixels | Stage GPU avg / p95 / max | Pose avg / max (CPU) | Draws | Triangles |
|---|---|---|---|---|---|
| Build it part by part | 288 × 512 | 1.80 / 2.00 / 3.68 ms | 0.52 / 1.45 ms | 17 | 4,252 |
| | 432 × 768 | 3.58 / 4.05 / 5.35 ms | 0.53 / 1.44 ms | | |
| Landing on the Moon | 288 × 512 | 1.12 / 1.57 / 2.34 ms | 0.75 / 2.36 ms | 25 | 8,858 |
| | 432 × 768 | 2.23 / 3.20 / 3.94 ms | 0.85 / 2.56 ms | | |
| Lift-off! | 288 × 512 | 0.95 / 2.44 / 3.26 ms | 1.17 / 4.20 ms | 10 | 7,940 |
| | 432 × 768 | 1.80 / 4.82 / 5.42 ms | 1.24 / 4.58 ms | | |
| The planets go round | 288 × 512 | 0.45 / 0.53 / 0.93 ms | 1.02 / 4.49 ms | 20 | 43,050 |
| | 432 × 768 | 0.72 / 0.91 / 1.39 ms | 0.93 / 2.04 ms | | |

So on a phone about 3-6 ms of CPU a frame on average (15-20 at the worst moment: ignition's billows, the sky turning)
and a few ms of GPU on top of the world's: inside the 33 ms of a 30 FPS frame, to be confirmed on the emulator. A
paused or hidden stage costs nothing (it renders once a pose). Building a reel in the feed (a neighbour, a frame of its
own): at most 20.5 ms here (`test_shorts_view`'s bench, every hand-made Short; the first try was 97 ms: the Earth's map
waited for, the gas giants' bands drawn on the main thread, a video reel seeking its poster; now the maps load on worker
threads when the Theater opens, the bands are drawn there too, a video reel's neighbour shows its still).

**A video's cost:** opening one 5 ms, seeking to 0 3 ms (each loop and each arrival), a frame's decode on this PC well
under a millisecond (Theora at 540 × 960 on the phone's CPU: the lead measures it on the emulator, point 2 below).

## Rulings (each with what it costs if wrong)

1. **Four reels live, four as video**, by what a phone can draw: the live ones are a few thousand triangles and 4
   particle effects (measured above); the colony, Venus's city and the wonders are whole regions of a world (hundreds of
   thousands of faces) and Saturn's rings 3,000 tumbling chunks. *If wrong:* a live reel too slow on a weak phone can
   be rendered like the others (`"video"` in its JSON and `tools/reel_render.sh`); a video reel could go live.
2. **The video is the picture only**; the captions, stickers, voice and sounds stay live over it (crisp at any size,
   VOICE OFF works, the voice is the device's own: Godot's Movie Maker cannot record the system's speech). *If wrong:*
   none known; `--full` renders a copy with them for a look.
3. **540 × 960 at Theora quality 3 (the colony 2) with a 0.4-0.5 pixel blur, a keyframe every 2 s**: all four videos
   together are 19.6 MiB, under the 20 MiB the brief allows in the APK. *If wrong:* sharper videos cost more bytes (the
   same reels at quality 5 were 95 MB); the knobs are `--q`/`--blur`.
4. **The videos ship in the APK** (under 20 MiB together); **the browser fetches them in a reels pack** after the music
   (`reels.<hash>.pck` in packs.json), an **iPhone only once the Shorts are opened** (ReelPack.wanted: every start copies
   user:// into the tab's memory, as the lead ruled for the realistic pictures). *If wrong:* a fifth heavy reel would
   push the APK over 20 MiB: then Android needs the same background download (WebContent with the server's URL).
5. **The videos are committed** (assets/reels/*.ogv, 19.6 MiB) like the music: filming needs a real window and 3 minutes
   a reel, and the exports, the tests and the owner's Mac need the files. *If wrong:* every re-render adds its size to
   the history; re-render only when a reel changes.
6. **A video reel never falls back to live 3D** in the feed (the brief: a still and "coming…" until its file is here).
   *If wrong:* a browser child waits for the reels pack (about 20 MB) to see them.
7. **A neighbour in the feed shows a video reel's still and opens nothing** (seeking a Theora video to its poster
   decoded up to 2 s of frames: 60 ms); the video opens when it plays. *If wrong:* the first frame of a video reel could
   show 5-8 ms late (it opens as the snap ends).
8. **The world regions come from the worlds' own generators** (the colony, Venus's city, the wonders: a child sees the
   same places in the game), seed 20261001, meshed with the world's own block library. *If wrong:* a region's square
   edge can show from high up (the wonders' last shot was moved for it).
9. **The orrery is not to scale** (distances and sizes squeezed, says a sticker), its years are (one Earth year = 10 s),
   and the planets start where they were on 1 October 2026. *If wrong:* none; the hand-made orbit Short says the same.
10. **The Moon rocket is a real one** (RocketCheck flies it to the Moon, its numbers are on the screen); the reels' rockets
    are block rockets like a child's, not a real rocket's shape. *If wrong:* none: a child can copy it.
11. **No new shader**: every stage draws with the game's own looks (block pages, the flight's planets, sky, Sun, pad and
    ground, the golem's glow and Fx's particles instanced, the avatar's parts, the Launch Site's material);
    `test_the_stage_draws_only_the_game_s_own_looks` checks every material against the census and those makers. A
    stage has its own lights (key, fill, rim), so on the web its first sight can still compile variants (like Build
    Rewind's stage; COVERED in `test_shader_warmup_sources.gd`). *If wrong:* a short pause the first time a live reel
    plays in a browser; the census can be run through the Theater.
12. **A live stage renders once a pose** (UPDATE_ONCE): paused or hidden it costs nothing; its pixels are its size on the
    screen (at most 540 × 960). *If wrong:* none known.

## Tests

- `tests/unit/test_reel_studio_motion.gd` (models, stages letting go, emotes, the camera's moves, particles: all the
  same at the same moment), `test_scene3d_kind.gd` (the stage's and the kinds' checks, the style in 3D),
  `test_reel_studio_rockets.gd` (RocketCheck flies the reels' rocket), `test_reel_studio_library.gd` (every reel checks
  and is in the feed, ReelCheck on every video, the facts against the game's tables), `test_reel_studio_pack.gd` (the
  web's reels pack, phones keep the videos, an iPhone waits for the Shorts).
- `tests/integration/test_scene3d_view.gd` (the stage: its own world, no shadows, seeks equal playing, once a pose, its
  pixels, only the game's looks, a stage falling away, the sky), `test_video_actor.gd` (a video reel plays in step,
  a neighbour opens nothing, an exact seek, the still and "coming…" until the pack, a clip in a scene).
- Small hooks in others' tests: `test_short_library.gd` (the index lists the cinematic folder too),
  `test_boot_splash.gd` (the Web Reels preset is a content pack), `test_shader_warmup_sources.gd` (two COVERED lines).

- **The full suite** (2026-10-01 04:24-05:22, at `1a54f97d`, `tests/run_tests.sh`): 1,032 scripts, 9,479 tests,
  **9,477 passing, 0 failing**, 2 risky (the generator's `test_the_column_cache_changes_nothing` and
  `test_chunks_meet_without_seams`, which make no assertions, as on lead-merge), no SCRIPT ERROR or Parse Error, exit 0,
  56 min.
- **Frame sheets** (the last ones, every reel): `build/reel_render/sheets/<id>_sheet.png` (the Short whole, a picture
  every half second, the stage live) and `build/reel_render/<id>/<id>_video_sheet.png` (the rendered videos, the
  picture alone); both git-ignored, made again by the commands above.

## What the lead must check on the emulator

1. **The live reels' frame rate** in the Theater (FPS overlay): *Lift-off!*, *Build it part by part*, *The planets go
   round*, *Landing on the Moon* play at ≥ 30 FPS with no frame over 100 ms, the world rendering behind the panel; the
   first one played after opening the Theater (the Earth's map and the gas giants' bands load on worker threads).
2. **The video reels play** (Theora on the phone's CPU at 540 × 960): smooth, in step with the captions and the voice,
   looping; a swipe away and back starts them from 0; the frame time while one plays (decoding).
3. **The APK's size** grows by about 20 MB (the videos); the store's limits are far above it.
4. The live stage's sharpness at the phone's scale (its pixels follow the player's size) and its colours in both
   graphics styles (the blocks follow BLOCKY/REALISTIC; check the colony and wonders videos were filmed BLOCKY).
5. A browser on the emulator: the video reels show their still and "This video is on its way…" until the reels pack
   (packs.json) is in, then play.

## Merge notes

- Shared files touched (small hooks): `core/shorts/short_check.gd` (a Short's `stage` and `video`),
  `core/shorts/short_kinds.gd` and `ui/shorts/short_drawers.gd` (the two kinds), `core/shorts/short_library.gd` (the
  cinematic folder), `ui/shorts/short_player.gd` (the plate, `prefer_live`, `plate_only`, `can_play`, the videos with
  pause and play), `ui/shorts/short_drawer.gd` (a comment), `ui/shorts/shorts_view.gd` (`open()` warms the stages and
  wants the reels), `data/shorts/shorts.json` (the eight reels in the feed), `tools/reel_preview_steps.gd` (live stages,
  exact video frames, ReelCheck's findings), `scenes/main.gd` (the reels pack heard; an iPhone waits),
  `export_presets.cfg` (Web Reels; the web games leave `assets/reels/*.ogv` out), `tools/export_web.sh` (the reels pack,
  `INCLUDE_REELS=1`), `.gitignore` (`override.cfg`), the tests listed above.
- New `class_name`s (run `--import` after the merge): StudioRules, StudioMotion, StudioCamera, StudioParticles,
  StudioRockets, Scene3DKind, VideoKind, ReelPack, ReelCheck, Scene3DView, Scene3DModels, Scene3DBuilds,
  Scene3DEffects, Scene3DSky, Scene3DDrawer, VideoView, VideoDrawer.
- The videos (`assets/reels/*.ogv`, 19.6 MiB) and their stills are committed; `assets/reels/reels.json` is their
  manifest (tools/reel_render.sh writes it; the tests read it).
