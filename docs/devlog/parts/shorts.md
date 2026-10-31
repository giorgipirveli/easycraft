# EasyCraft Shorts: short learning animations, swiped in the Theater (owner #94 and #96, 2026-09-30)

The owner (#94): "implement short scrollings like tiktok where [we] create videos and animations which must be
educational, like how to build a rocket, lessons explanations, learning animations … this should be presented at tv
shows room". Then (#96, 23:30): "we must keep reels high quality, implement visuals, video, animation tools and use
them". Brief: `docs/superpowers/plans/2026-09-30-shorts-brief.md`; spec §5.12b (with #96's "High quality, with real
tools" paragraph and "As built"). Built in the worktree branch `worktree-agent-a793e6a05f004b5ec`, reset to `lead-merge`
first, while other agents improved the lessons (grades 3-7) and the animations. No editor, emulator or adb was used.
Pictures came from windowed tool runs (`tools/shorts_shots.gd`, `tools/reel_preview.gd`); the lead checks Android on
the emulator (the list at the end).

## What a child sees

Walking into the cinema opens the Theater **on the SHORTS tab**, a pink tab with a phone picture, first among the
channels (EasyCraft TV, Space, Science and the rest keep their real 16:9 videos):

- **In the middle, a tall 9:16 player** that the game draws itself: a sky, space, paper, grass, sea, night, sunset,
  chalkboard or lab backdrop, and actors on it. Actors are words on bright stickers, the School's pictures, blocks and
  rocket parts, planets in the Star Map's colours, Professor Hoot, Pip and the other characters, arrows that draw
  themselves on, shapes (a pizza, a bulb, a cloud, the Moon's phases) and maps. They pop in with a little overshoot,
  drop and bounce, slide in and settle, spin, pulse and orbit. A big caption always sits in a dark band at the bottom.
  A bar for each scene runs along the top. The words are read aloud once (VOICE ON / VOICE OFF), with a soft pop, ding
  or tune on cue, and the Short loops. The camera pushes in slowly on every scene. The game's music rests while a Short
  plays and comes back when the child leaves.
- **Swiping like TikTok:** a finger drags the Short up or down and it **snaps** to the next or the last one with a small
  springy overshoot and a soft thump. The mouse wheel, ↑ / ↓ (also PageUp / PageDown, B / N), BACK / NEXT and a
  controller's D-pad do the same. A tap pauses and plays (a big ▶ sign). A **double tap** sends up a heart.
- **On the right:** the topic in its colour ("Rockets", "Maths · Grade 3"), the title, the position ("2 of 18"),
  **LIKE** (it turns into LIKED with a full heart), **LEARN IT**, BACK and NEXT, VOICE, EXIT.
- **On the left:** three filters: **SHOWS** (the hand-made Shorts), **LESSONS** (grade chips 3 to 7, then the units
  subject by subject: "1 of 137" in grade 3) and **LIKED** (the child's own hearts: "Tap the heart on a Short you like:
  it waits for you here."). Below them is the feed's list: each row has its topic's colour, a tick when seen and a
  yellow frame on the one playing; a tap on a row plays it. **Grown-ups** sits at the bottom.
- **LEARN IT** goes to what the Short teaches. A School unit opens over the Theater (the unit's page with its lesson,
  exercises and TRY IT IN THE LAB; Back or Esc returns to the same Short). A rocket Short leaves the Theater and opens
  the Mission Board (away from the home world, a toast says where it stands). A space Short opens the Star Map.
- **After 10 Shorts** a break card: "That's the show for now!" with **BACK TO MY WORLD** and **MORE SHORTS** as two
  equal choices. Nothing counts, scores or rewards watching.
- **Lessons in a minute:** every written School unit of grades 3-7 (614 today) is also a Short. It opens with a yellow
  "LESSON IN A MINUTE" sticker, the unit's title and Hoot. Then come its cards in turn: a card's picture pops in and
  slowly draws closer while its words are the caption and the voice. A card without a picture borrows one of the unit's
  own exercise pictures that gives nothing away; failing that, its **headline** comes in big ("Producers are plants",
  "Consumers are animals"), popping, sliding or dropping in turn, with the card's number and Hoot bouncing. The last
  scene says "Tap LEARN IT to read it all and practise."

Pictures (windowed, 1600 × 720 and 1280 × 720, the phone's shape): `tools/shorts_shots.gd -- --panel`. At both sizes
the player, the list and the buttons fit without overlapping, the caption is big and readable, and the tabs row is
unchanged.

## The Shorts made: 18 hand-made ones, every fact checked

Each has 4-6 scenes, lasts 36-52 s, teaches one idea and ends on a question to wonder about. The tests
(`tests/unit/test_short_library.gd`) work every number on the screen out again from the game's own tables or from
NASA's values, so a Short and the game can never disagree.

| Short (topic, LEARN IT) | Its facts | Checked against / sources |
|---|---|---|
| **Build a rocket** (rockets, Mission Board) | Built from the bottom up; the engine pushes hot gas down so the rocket goes up; a fuel tank holds 94 t of fuel and oxygen (space has no air); the crew capsule has one seat and a pointed top; three fins keep it straight. | The game's `RocketParts.fuel(FUEL_TANK)` = 94, `RocketParts.seats(CREW_CAPSULE)` = 1, `RocketCheck.FINS_NEEDED` = 3, `RocketCheck._pointed`. Action and reaction: Newton's third law (NASA Glenn, "Newton's Laws of Motion"). |
| **Push against weight** (rockets, Mission Board) | Lift-off needs push > weight; one engine pushes 250 t; two full tanks and an engine weigh 204 t (lifts); a third tank makes 304 t (too heavy); two engines, 500 t against 308 t (lifts). Puzzle: five tanks need 3 engines. | `RocketParts` thrust and masses, `RocketCheck.LIFT_MARGIN` (the game's own lift-off rule); the test also works out the puzzle's answer (3). Thrust-to-weight > 1: NASA Glenn, "Four Forces on a Model Rocket". |
| **Why rockets have stages** (rockets, Mission Board) | The Moon needs 15.3 km/s of speed, all added up; a full tank is 100 t, empty 6 t; stages drop away so the rest speeds up; real rockets have two or three stages. | `MissionRules.need(moon)` = 15.3, `RocketParts.mass_full/mass_empty`. Real Earth-surface-to-lunar-surface delta-v is about 15-16 km/s; Saturn V had three stages, Falcon 9 has two (NASA, "Saturn V"; SpaceX Falcon 9 page). |
| **Friends fly together** (rockets, Mission Board) | A capsule has one seat; Mars takes about 210 days; two friends need 420 days of supplies, and a service module gives 200; Mars has air, so a heat shield, a parachute and three legs. Puzzle: three friends need 4 modules. | `StarMap` Mars `days` = 210, the service module's 200 days, `mars.air`, `RocketCheck.LEGS_NEEDED` = 3; the test works out ceil(630 / 200) = 4. A Hohmann trip to Mars takes about 7-9 months (NASA Mars Exploration). |
| **Round and round the Sun** (space, Star Map) | Each planet has its own orbit; Mercury's year 88 days, Earth's 365 (365¼); Jupiter almost 12 years, Saturn about 29. The orbits on the screen go round at their real years' ratio, anticlockwise. | `StarMap.year_days` (the orrery's real years); NASA Planetary Fact Sheet (nssdc.gsfc.nasa.gov/planetary/factsheet): 88.0 d, 365.2 d, 4,331 d (11.86 y), 10,747 d (29.4 y). |
| **The Moon's changing shape** (space, Star Map) | The Moon makes no light; half of it is always lit; we see different amounts of that half; new to full and back takes about 29½ days. | The synodic month is 29.53 days (NASA Moon fact sheet; NASA Science "Moon Phases"). The drawn phase at "full" is checked at half the cycle. |
| **Jump on other worlds** (space, Star Map) | A good jump on Earth: about 30 cm; the Moon pulls about 6 times more gently, so 1.8 m; Mars about 80 cm; Pluto about 4.7 m (a giraffe's height); Jupiter about 12 cm. | Height = 30 cm × g(Earth) / g(world), with g from the NASA fact sheets: Moon 1.62, Mars 3.71, Jupiter 24.79, Pluto 0.62 m/s² (Earth 9.81). The Star Map's Moon facts say "6 times higher". A grown giraffe stands about 4.5-5.5 m (Smithsonian's National Zoo, "Giraffe"). |
| **Why Venus is the hottest** (space, Star Map) | Mercury is nearest the Sun but not the hottest; with almost no air it reaches 430 °C by day and falls to −180 °C at night; Venus's thick carbon dioxide air traps the heat: about 465 °C day and night, hot enough to melt lead. | The Star Map's own planet facts (the test reads them: "430 °C", "−180 °C", "465 °C", "melt lead"); NASA Science, "Mercury Facts" (430 °C by day, −180 °C at night); NASA's Venus Fact Sheet (mean surface temperature 737 K, about 464 °C); lead melts at 327 °C. |
| **Saturn's rings are ice** (space, Star Map) | Not a solid hoop: billions of pieces of ice and rock, from dust to house-sized; they stretch 282,000 km from Saturn, but the main rings are about 10 m thick; Saturn would float in water. | The Star Map's Saturn facts (the test reads "ice and rock", "as big as houses", "float"); NASA Science, "Saturn Facts" (rings up to 282,000 km out, generally about 10 m thick; density 0.687 g/cm³). |
| **Ice into rocket fuel** (space, Star Map) | Some polar craters on the Moon never see the Sun and keep ice; melted, it is water; electricity splits 9 kg of water into 1 kg of hydrogen and 8 kg of oxygen; hydrogen burns with oxygen as fuel, and the oxygen is good to breathe. | Molar masses (H₂O 18.0, H₂ 2.0, O 16.0: 1/9 and 8/9); `DepositKinds.MOON_ICE` ("never see the Sun") and the space engine's words ("hydrogen") in the game. NASA LRO/LCROSS on water ice in permanently shadowed craters. |
| **A lever lifts** (science, g3 Levers and linkages) | A lever is a bar turning on a pivot; load near the pivot and push far away; it balances when 60 kg × 1 m = 20 kg × 3 m; seesaws, scissors, bottle openers, wheelbarrows. | The law of the lever (Archimedes): the test checks 60 × 1 = 20 × 3 and that the drawn push is 3 times as far from the pivot. BBC Bitesize (KS2 science, levers). |
| **How a circuit lights a bulb** (science, g4 Electric circuits) | A bulb lights when electricity goes all the way round a loop; from the cell, through the bulb and back; a switch makes a gap; metals conduct, plastic, wood and rubber do not. | The School's own unit g4.science.circuits (its lesson); BBC Bitesize (KS2 science, circuits, conductors and insulators). |
| **The water cycle** (science, g6 The water cycle) | The Sun warms the sea and water evaporates into vapour; it cools and condenses into droplets (clouds); droplets join and fall as rain, snow or hail; rivers carry it back. | The School's unit g6.science.water_cycle; Met Office, "The water cycle"; USGS Water Science School. |
| **How plants make food** (nature, g5 Plants, air and water) | Plants make their own food with sunlight; roots take in water and leaves carbon dioxide through tiny holes; green chlorophyll catches the light and makes sugar; leaves give out oxygen. | The School's unit g5.science.plants_air_water; BBC Bitesize (KS3 biology, photosynthesis). |
| **Who eats whom?** (nature, g5 Food webs) | Every food chain starts with sunlight and a plant; grass → rabbit → fox, arrows show where the energy goes; producers, consumers, predator and prey; chains join into a web (a British woodland: oak, grass, caterpillar, mouse, rabbit, blue tit, fox, sparrowhawk). | The School's unit g5.science.food_webs; BBC Bitesize (KS2 science, food chains); the Woodland Trust (blue tits eat caterpillars, sparrowhawks eat small birds, foxes eat mice and rabbits). |
| **Fractions of a pizza** (maths, g3 Equivalent fractions) | One slice of 8 is one eighth; 4/8 = 1/2; 1/2 = 2/4 = 4/8; 8 slices shared by 4 friends is 2/8 = 1/4 each. Puzzle: 3/8 or 1/2? | Arithmetic, checked in the test (and no pizza ever has more slices shaded than it has). |
| **What a digit is worth** (maths, g3 Numbers to 10,000) | Ten ones make a ten, ten tens a hundred; 345 = 300 + 40 + 5; 543 is bigger. Puzzle: the biggest number from 3, 4 and 5 is 543. | Arithmetic, checked in the test (and the drawn blocks add up to 345). |
| **The Seven Wonders map** (history, Star Map: the Wonders tour is world 41) | Greek travellers listed seven wonders; six stood near the eastern Mediterranean, one in Babylon; only the Great Pyramid still stands; it was already about 2,000 years old when the others were built. | `WonderFacts.ANCIENT` (the map's points match the game's coordinates of the real sites to 0.05°) and `WonderFacts.TOUR_FACTS`. The pyramid was finished about 2560 BC; the others date from about 600-280 BC (Encyclopaedia Britannica, "Seven Wonders of the World"). |

**Lessons in a minute** (made at run time, `LessonShort`): every written unit of grades 3-7, 614 Shorts of 35-60 s
today. Their facts are the School's own lessons, word for word (the lesson agent keeps those correct). The Short only
chooses which sentences fit the minute.

## The style guide (owner #96): `core/shorts/short_style.gd`

- **Palette:** the game's UI colours (`ShortRules.COLOURS`: yellow, green, blue, red, orange, teal, purple, pink, white,
  ink, sky, brown, grey, gold, lime, cream, black, ice, leaf, sea); each topic in its colour (rockets orange, space
  purple, science green, nature leaf green, maths blue, history brown). Lessons tint their backdrop with their subject's colour.
- **One typeface family:** the game's UI font, at a few letter sizes only (`LETTER_SIZES` 16-110; nothing smaller
  than 16 on the 360 × 640 stage). Captions use 30, 27, 24, 21, then 18, the biggest that fits the band.
- **Safe margins for a phone held upright:** `SAFE` = Rect2(8, 24, 344, 608). The caption's band starts at y 440
  (`ShortRules.CAPTION_TOP`), and actors stay above it unless they are decoration that may bleed off the edge.
- **Legible words:** WCAG contrast of at least 4.5 between letters and their sticker, or else a dark outline (and
  then the sticker's contrast must be at least 2.0).
- **Motion:** 30 frames a second. Arrivals ease out (`ARRIVALS`: a pop takes 0.3-0.8 s, a slide 0.35-1.0 s, a drop
  0.5-1.4 s, a draw-on 0.3-2.5 s). A pop overshoots a little (the "back" curve). No linear moves or slides. Every move
  lasts at least 0.4 s (12 frames), most 0.4-0.6 s (12-18 frames).
- **Pacing:** captions and the voice at most 2.5 words a second (`WORDS_PER_SECOND`); a scene lasts 2.5-16 s; a
  hand-made Short lasts 20-60 s (a lesson 30-60 s).

## The quality checker

- `ShortCheck.problems(short)` checks the data: ids, title, topic, link, each scene's seconds, backdrop, camera, the
  caption's length and pace, the voice fitting its scene, sounds; for every actor, its kind (through `ShortKinds`),
  place, size, colours, letter size and legibility; for every move, that it is known, inside its scene, of a sensible
  duration, eased (never linear), at least 12 frames long, with the fields it needs. It runs on every hand-made Short
  (`test_short_library`) and every one of the 614 lessons (`test_lesson_short`).
- `tests/integration/test_short_quality.gd` plays them (every hand-made Short and a fourth of the lessons) and
  measures: every actor inside the frame at the end of its scene, no actor under the caption, no words on words, words
  at their full size at the scene's end.
- `test_short_style.gd`: the style constants themselves (contrast maths, letter sizes, frames).

## The reel studio and the review (owner #96)

`tools/reel_preview.gd` (windowed) shows a Short at its full stage size with a timeline to scrub (its ticks are the
scenes), PLAY, the scene list, reduce motion (R), the checker's findings and keys (Space, ← →, PageUp/PageDown). It
also writes **frame sheets**: one PNG grid of the Short every half second (`--sheet --short=…` or `--sheet --all`).
Every hand-made Short and two lessons (food webs: no pictures; circuits: pictures and a Quick memory) were reviewed on
their sheets, the Theater's panel on its pictures. **What the review changed:**

- **A real bug:** a `count` actor began at 0, not at its `from`, so the countdown read 0, 1… (ShortTimeline; test
  `test_a_count_starts_at_its_from`).
- **The camera:** a slow push-in (1.04×) on every scene, so a still moment still lives (off with reduce motion; a
  scene can set its own `camera`).
- **Backdrops:** the night and sunset backdrops lost their own Moon and Sun (two moons showed with a Short's Moon), and
  the grass hills went down so the ground meets the caption (animals had stood in the sky).
- **Shorts:** the pizza's taken slice lifts out with a white rim; "Who eats whom?" draws a woodland food web of its own
  arrow by arrow; the water cycle has real falling rain; arrows run round the circuit; stage 2 stays in sight with
  speed lines after the separation; the planets to choose from appear after lift-off; labels were moved inside the
  frame and off each other (food chain, ice into fuel, place value); PUSH and WEIGHT sit on stickers from the first
  scene (the panel picture showed thin letters on the sky).
- **Lessons in a minute:** a lesson without pictures had been a row of numbered circles. Now a card borrows one of its
  unit's exercise pictures that asks nothing (no "?", no hidden part; 424 cards can), else it shows its headline big
  (each sentence brings its own; a headline never ends on a dangling word like "Insulators do not"). The lesson's
  "Quick memory" (a question on an earlier unit with its answer in brackets; 415 of 614 lessons open with one) is left
  out, and the rest of that card stays.

## Pluggable actor kinds: the hooks for `scene3d` and `video`

- **Check side:** `core/shorts/short_kinds.gd` (ShortKinds: kind → check Callable). The built-in kinds are registered in
  `_builtins()`; the comment there marks the line for `_checks["scene3d"] = Scene3DKind.problem` and
  `_checks["video"] = VideoKind.problem`. `ShortKinds.register(kind, check)` also works at run time (a test does it).
  ShortCheck asks `ShortKinds.has` and `ShortKinds.problem` for every actor.
- **Draw side:** `ui/shorts/short_drawers.gd` (ShortDrawers: kind → ShortDrawer). The comment in `_builtins()` marks the
  line for `Scene3DDrawer.new()` and `VideoDrawer.new()`. The interface is `ui/shorts/short_drawer.gd`: `setup(actor)`
  (make its children: a SubViewport for the lit 3D studio, a VideoStreamPlayer; set `actor.size` and `actor.animated`),
  `draw(actor)` and `update(actor, state, t)`. `update` gets the scene's time `t` after every timeline step, so a video
  seeks to `t` and a 3D camera takes its pose at `t`, and a seek (the feed's snap, the frame sheets, the tests) shows
  exactly the frame playing reaches.
- The test `test_short_player.gd: test_a_new_actor_kind_plugs_in_with_its_check_and_its_drawer` registers a kind with both and
  plays it: the model for the next agent.
- Neither `scene3d` nor `video` is built here (the brief for them is the next agent's).

## What was built

| File | What |
|---|---|
| `core/shorts/short_rules.gd` | The format's constants: stage, caption band, limits, kinds, moves, eases, backdrops, shapes, colours, topics and their order, links. |
| `core/shorts/short_style.gd` | The style guide (above). |
| `core/shorts/short_timeline.gd` | Pure, seekable timing: each actor's state at any moment (visible, place, scale, turn, alpha, draw, value), easings (smooth, out, in, back, bounce, elastic), the scenes' starts, transitions, reduce motion. |
| `core/shorts/short_check.gd`, `short_kinds.gd` | The checker, the kind registry. |
| `core/shorts/shorts_data.gd` | Hearts (id → ± unix time, newest wins) and the seen list, in `ProfileData.shorts`; `ProfileBackup` merges them. |
| `core/shorts/lesson_short.gd` | Lessons in a minute. |
| `core/shorts/short_library.gd`, `short_feed.gd` | The hand-made Shorts' index and files; lessons made on demand (8 kept); the feed's filters and order. |
| `data/shorts/*.json` | The 18 Shorts and `shorts.json` (their order). |
| `ui/shorts/short_actor.gd`, `short_drawer.gd`, `short_drawers.gd` | One actor on the stage and its drawer. |
| `ui/shorts/short_backdrop.gd`, `short_player.gd` | The backdrops; the player (build, seek, play, loop, the voice, sounds and tunes, the caption, camera, bars, heart burst). |
| `ui/shorts/shorts_view.gd`, `shorts_icon.gd`, `shorts_tab.gd`, `shorts_school.gd` | The SHORTS view (feed of three players, swipe and snap, filters, list, buttons, break card), its icons, the tab, the School page over the Theater. |
| `ui/theater/theater_panel.gd` | SHORTS tab first, opens on it; the keys; LEARN IT; the School over it. |
| `scenes/sandbox.gd` | `learn_from_short(link)` (the Mission Board, the Star Map), the HUD while the Theater is open. |
| `core/save/profile_data.gd`, `profile_backup.gd` | `shorts`. |
| `ui/progress/read_aloud.gd` | The system voice keeps its voice list per language (asking cost ~70 ms each time on Linux). |
| `tools/shorts_shots.gd`, `tools/shorts_smoke.gd`, `tools/reel_preview.gd` (+ `_steps.gd`) | Pictures and the bench; the smoke run; the reel studio. |
| Tests | `tests/unit/test_short_timeline.gd`, `test_short_check.gd`, `test_short_style.gd`, `test_shorts_data.gd`, `test_lesson_short.gd`, `test_short_feed.gd`, `test_short_library.gd`; `tests/integration/test_short_player.gd`, `test_shorts_view.gd`, `test_theater_shorts.gd`, `test_short_quality.gd`; `test_theater.gd` (its panels start on a channel). |

## Rulings (each with what it costs if wrong)

1. **The Theater opens on SHORTS** (`TheaterPanel.opens_on_shorts`), even when the real videos' list is there. The owner
   asked for Shorts "at tv shows room" and they need no internet. *If wrong:* a child taps a channel tab once; one flag.
2. **Shorts are drawn live** (2D Controls on a 360 × 640 stage, scaled), not video files, as the spec says. *If wrong:*
   the `video` kind is ready to plug in (above).
3. **The voice reads a Short once; loops are silent** (captions stay). Hearing it every loop grated in the bench.
   *If wrong:* one line in `ShortPlayer` (the first-pass flag).
4. **A tap pauses and plays, a double tap is a heart** (TikTok's grammar); LIKE does the same. *If wrong:* a child
   pauses by accident on a double tap's first tap. The second tap resumes, so nothing is lost.
5. **The break card after 10 Shorts**, like the TV's 10 videos: two equal choices, no countdown. *If wrong:* one tap
   more for a child who wants more. `BREAK_AFTER`.
6. **Seen at half the Short** (`SEEN_AT` 0.5): a flick past doesn't count. The order puts topics with unseen Shorts
   first, a topic's Shorts together (rockets, space, science, nature, maths, history). *If wrong:* a Short counts as
   seen too early or late; one constant.
7. **Lessons filter by grade (chips 3-7), then subject** in the School's order; bonus units stay out (they are extras
   in the School too). *If wrong:* a grade's feed is long (137 in grade 3). The list shows titles, so a child can jump.
8. **LEARN IT for a rocket Short leaves the Theater for the Mission Board**, and away from the home world a toast says
   where it is; a space or history Short opens the Star Map (the Wonders tour is world 41 on it); a School unit opens
   over the Theater and returns to the same Short. *If wrong:* the Mission Board is one more walk; the toast says it.
9. **No rewards of any kind:** no gold, points, streaks, counts or public likes; a words test forbids them in every
   Short. The grown-ups' Theater switch covers SHORTS. *If wrong:* none (this is the fair-fun rule).
10. **The game's music rests while a Short plays** (the Music bus held; restored on leaving, covering, EXIT, walking
    out). *If wrong:* a child who likes the music hears it again in the world.
11. **A Short's tune is at most 4 s** and is made on a worker thread. A long tune cost ~100 ms in the frame it was
    built. *If wrong:* shorter jingles; the School's notes still play.
12. **Lessons in a minute share the minute** (first sentences first, cards without pictures give way first, the first
    card always stays) and are stretched to at least 30 s. *If wrong:* a sentence a child might want is left for LEARN
    IT. The end card says so.
13. **Quick memory is left out of a Lesson in a minute** (today): it reviews an earlier unit, and the minute teaches
    this one. *If wrong:* the Short loses a retrieval question that the full lesson keeps; it could return as a quiz beat.
14. **Headline cards use the words before a card's first colon, semicolon or comma** (4-44 letters, never ending on a
    dangling word), else the whole short sentence, else the numbered badge. *If wrong:* an odd headline on a few
    cards. The test's samples and the sheets looked right.
15. **Borrowed pictures come only from the unit's own exercises and give nothing away** (no "?", no hidden, missing,
    unknown or blank part). *If wrong:* a picture shows an exercise's scene early; it never shows an answer the child is
    asked for.
16. **The first speech of a session is warmed when the Shorts open** (the system voice's list; the Star Map's class).
    *If wrong:* a short pause as the Theater opens instead of in the first Short.
17. **The spec's "At least 16" became 18**, one per listed topic plus a crew flight and stages, all reviewed on their
    sheets; quality over quantity (owner #96).

## Performance: the bench

`tools/shorts_shots.gd -- --bench` (windowed, this PC, the Theater's panel as the game shows it, the voice on): each
Short plays a while, then a swipe snaps the next in. First the 18 hand-made Shorts, then grade 5's lessons.

| Run (2026-10-01, final code) | Frames | Average | p99 | Worst |
|---|---|---|---|---|
| Hand-made | 6,017 | 2.39 ms (418 FPS) | 5.50 ms | 25.1 ms |
| Grade 5 lessons | 6,486 | 2.22 ms (450 FPS) | 5.45 ms | 19.7 ms |

Building a Short takes up to ~7 ms, one neighbour per frame. Before the fixes in `6a4e4aef`, stalls were 114 ms (a
tune), 284-442 ms (the Star Map's class loading) and 70-100 ms a scene (Linux's speech service asked for its voices every
time). Headless, the per-frame cost test (`test_shorts_view.gd`, SHORTS_BENCH) plays and swipes at 0.11 ms a frame. At a
phone's 3-5× slower CPU the worst frame would be ~75-125 ms only if the phone's TTS behaved like Linux's, which it does
not (Android's TextToSpeech queues asynchronously). The lead should confirm on the emulator (below).

## Tests and checks

- New and changed tests (above) pass one by one (`-gtest=`).
- **The full suite** (2026-10-01, at `2c4dd37d`): 1,012 scripts, 9,278 tests, **9,276 passing, 0 failing**, 2 risky
  (the generator's `test_the_column_cache_changes_nothing` and `test_chunks_meet_without_seams`, which make no
  assertions, as on lead-merge), no SCRIPT ERROR or Parse Error, exit 0, 57 min.
- **Smoke:** `XDG_DATA_HOME=/tmp/…-smoke godot --headless --path . --script res://tools/shorts_smoke.gd` in a new
  Sandbox world: the Theater opens on SHORTS (first tab), the 18 Shorts show, the first waits still, 10 swipes play
  Shorts 2-11, a double tap hearts one and profile.json keeps it, LIKED shows, LEARN IT opens a School unit over the
  Theater and Android Back closes it, LEARN IT on a rocket Short opens the Mission Board, walking out stops the Short and
  brings the music back: **27 ok, 0 failed**.

## What the lead must check on the emulator

1. **Swiping by touch:** drag a Short up and down: it follows the finger, snaps with the small overshoot, and a short
   flick is enough. A tap pauses, a double tap sends a heart, and scrolling the list on the left doesn't swipe the player.
2. **The voice:** Android's TextToSpeech reads each scene once, in step with the caption; VOICE OFF silences it; the
   first Short after opening starts without a pause. Watch for a frame over 100 ms when a scene's speech starts.
3. **The size on a phone:** the 9:16 player, the caption (18-30 px on a 360 stage, so about 36-60 px at the emulator's
   scale), LIKE and LEARN IT readable and easy to hit; nothing under the notch or the gesture bar.
4. The game's music rests while a Short plays and returns on EXIT and walking out.
5. LEARN IT: a School unit over the Theater (Back returns to the same Short), the Mission Board from a rocket Short at
   home, the Star Map from a space Short.
6. A controller's D-pad moves between Shorts; A plays and pauses.
7. The FPS overlay while swiping for a minute: ≥ 30 FPS, no frame over 100 ms.

## Merge notes

- Touches shared files: `ui/theater/theater_panel.gd`, `scenes/sandbox.gd`, `core/save/profile_data.gd`,
  `core/save/profile_backup.gd`, `ui/progress/read_aloud.gd`, `tests/integration/test_theater.gd`, the spec §5.12b
  (lead-merge's "High quality" paragraph is carried here word for word, "As built" follows it) and
  `docs/DEVELOPMENT.md`.
- New `class_name`s (run `--import` after the merge): ShortRules, ShortStyle, ShortTimeline, ShortCheck, ShortKinds,
  ShortsData, LessonShort, ShortLibrary, ShortFeed, ShortActor, ShortDrawer, ShortDrawers, ShortBackdrop, ShortPlayer,
  ShortsView, ShortsIcon, ShortsTab, ShortsSchool.
- Lessons in a minute read the lesson files as they are at run time, so the lesson agent's edits flow in by
  themselves. `test_lesson_short` checks every written unit, so a lesson card that can't make a good Short shows up there.
