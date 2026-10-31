# The forever roadmap (owner, 2026-09-29: #70, #71, #72)

> **Standing order (#71):** "this game never ends, we have alwys to work here and develop new content, so save this
> into plan and goal, we never stop developing new worlds, new universes, new lessons, new contents".
> There is no last milestone. When one item is finished, the next one starts. "Nothing worth doing" is never the answer
> while this list has items, and it always has.

The goal (#72): finish the full plan; the game online; educational content covering the full school programme; a
cosmos with stars and planets where each planet is its own universe; universes so worth exploring that families will
be glad to pay to unlock more later; the best visuals we can make.

## The loop (every item)
1. Owner feedback first (log it in `docs/playtests/owner-feedback.md` the moment it arrives).
2. Write the item into the spec (§3b / the section it belongs to) and this plan; rulings go to the dev log.
3. Test first; `--import` and grep Parse Error; the full suite (`tests/run_tests.sh`, one of the 3 PC-wide slots).
4. Fast-forward main, deploy the web (`tools/export_web.sh`, `tools/deploy_web.sh`, `tools/deploy_web_github.sh`),
   rebuild the Android release when the owner is about to upload.
5. Document: the dev log, owner-feedback, RESUME-HERE, DEVELOPMENT.md when a command changes.
6. Pick the next item below. Never report a whole area as "done": say exactly what exists and what comes next.

Agents: at most 3 at once (owner 2026-09-25), when the account's usage allows (weekly limit resets Oct 3, 06:00
Tbilisi). Never overload the PC: niced exports, one emulator, shut it down after.

## §0 THE CORE LOOP (owner #79, 2026-09-29: "the most important parts … remember this into plan this is very important")
**The world game plan (owner #81, "the most important plan"): `2026-09-29-world-game-plan.md`**: why children invite
friends (crews, mentoring, postcards, gifts, two-key secrets, class and family codes), the referral program tied to
learning, staying involved the educational way, every age and everyone, a world game; its order of work.
**Learn and solve puzzles, and invite new players, to earn gold → buy the rocket's parts with gold → build the rocket
(checked like a real one) → sit at the controls and fly to the Moon yourself (real animations and visuals) → land,
explore, and go further (Mars, the other planets).** Everything else hangs on this loop: the School and the Lab are
where gold is earned, the planets, colonies and wonders are where the rocket takes you. Design: spec §25 (with §21d
missions, §21c colonies, §21e invent it, §24 wonders). Order of work:
1. **Earning and inviting** (brief `2026-09-29-earn-invite-brief.md`): gold for lessons, puzzles, the Lab and secrets
   (`EarnRules`, daily caps, never for time); invite codes and links, the server's referral rules and rewards (only for
   new players who really play; no contacts, no personal data; a note for the owner's lawyer).
2. **Missions** (brief `2026-09-29-missions-brief.md`): the Launch Site, the Mission Board, rocket parts bought with
   gold, the real check.
3. **The flight** (brief `2026-09-29-rocket-flight-brief.md`): sit at the controls, lift-off, clouds, stages, space,
   the Earth and the Moon as real spheres, orbit, landing; Mars's fiery entry.
4. **Prospecting and mining** (owner #80, spec §26, brief `2026-09-29-prospecting-brief.md`): real resources where
   real geology puts them (gold, copper, iron, coal, oil and gas, salt, diamonds; the Moon's and Mars's ice), found by
   quests (maps, clues, problems, quizzes, surveys, adventures), mined and refined in real steps; they sell for gold and
   fuel the rocket (kerosene, and on the Moon and Mars oxygen and hydrogen from ice).
5. **Robots and friendly aliens** on the planets (owner #86, spec §21f, brief `2026-09-29-space-creatures-brief.md`);
   the flight's movie-style moments (light speed, a warp tunnel, a wormhole, asteroids, a nebula) are in the flight's
   brief.
6. **The TV shows finished** (owner #89, brief `2026-09-29-tv-shows-brief.md`) and **game controllers** everywhere
   (owner #90, brief `2026-09-29-controllers-brief.md`; the PlayStation's own browsers cannot run a 3D web game).
7. Then: flying together as a crew, the colonies under domes (#77), the world's wonders (#78), invent it (#78).

## §1 The School (#70): every school subject, every grade, then deeper, forever
**Owner #122 (2026-10-17): every lesson is a game.** The School's subjects and grades below are its content; its form is
play (`docs/design/learning-is-play.md`): G0 makes every written unit playable (seven generic mechanics), G1-G5 build the
signature games family by family (maths, science, English, humanities, the rest), G6 measures; grade 9 up is written
play-first.
**Owner #133, #134 (2026-10-17): future lessons, in depth** (`docs/design/future-lessons.md`, the authority): one deep
game at a time, each researched, designed (phase A, with models that show guessing cannot win), built (B), laddered across
the grades (C) and grown (D). Designed and approved 2026-10-18: Inside a Leaf (science, building), Balance Altar
(algebra), Fraction Bakery (fractions), Word Magic (English grammar and the move from listening to reading). Queued:
Story Theater, Detective Reader, Persuade the Council (English), Time Portals (history), Circuit Workshop, Living Island,
Forces Park, Data Lab, Ratio Kitchen (grades 6-8), and **a phonics game for the youngest** (letter sounds and decoding
for children below our grade 3, who cannot decode yet: Word Magic carries a non-reader by ear but is not a phonics
course; the lead's review of Word Magic, 2026-10-18).
What exists (2026-09-29 10:00): grades 4–8, three subjects (maths, science, English), 201 units, each a short lesson
and ~15 practice questions (maths also has generators with endless questions). That is **not** a full school year.

The subjects of a school day (grades 3–8), each its own tab in the School:

| Subject | Framework (the unit outline follows it; British spelling) |
|---|---|
| Maths | US Common Core State Standards for Mathematics |
| English | Common Core English Language Arts (reading, writing, grammar, vocabulary, speaking) |
| Science | NGSS; grades 7–8 cover physics, chemistry, biology and earth and space |
| History | UK National Curriculum history (KS2–KS3), world history from the Stone Age to the modern world |
| Geography | UK National Curriculum geography (KS2–KS3): maps, places, continents, rivers, weather, climate, people |
| Citizenship | UK citizenship (KS2–KS3) and the US C3 civics strand: community, rules and laws, rights, money, democracy |
| Computing | UK Computing (KS2–KS3) and CSTA: algorithms, coding ideas, data, networks, staying safe online |
| Art and Design | UK Art and Design and the US National Core Arts Standards: colour, line, shape, artists, techniques |
| Music | UK Music and the US National Core Arts Standards: rhythm, pitch, notation, instruments, composers |
| Health and PE | US National Health Education Standards and SHAPE America: the body, food, sleep, safety, sports and games |

Ruling: no second-language subject (the owner, 2026-09-25 17:57: English only, never a translation or a language
picker). Cost if wrong: a language subject added later.

Order of work:
1. **Grade 3, every subject** (the owner: "start from grade 3").
2. **The new subjects for grades 4, 5, 6, 7, 8**, in that order (history, geography, citizenship, computing, art,
   music, health and PE).
3. **Depth:** grow each subject of each grade towards everything a school year teaches (every standard or topic its
   own unit), grade 3 upwards; more practice and generators where a subject has calculations.
4. Then grades 1–2 and 9–12, and on (the School never ends).

Agent queue (briefs in this folder; at most 3 agents at once):
1. grade 3 computing, art, music (`2026-09-29-grade3-arts-brief.md`) — running
2. grade 3 health and PE, D&T, projects (`2026-09-29-grade3-life-brief.md`) — running
3. then, one agent each, with `2026-09-29-school-subjects-brief.md` (GRADE, SUBJECTS): grade 4 history, geography,
   citizenship; grade 4 computing, art, music; grade 4 health and PE, D&T, projects; grade 4 maths, science, English
   (the research's new units); then grade 5, 6, 7, 8 the same way. Interleaved with the cosmos (Mars live 13:51, the Science Lab
   running, then Europa, Io, Titan … with `2026-09-29-cosmos-planet-brief.md`: BODY, WORLD, PAGE, IDS; spec §21b.2).

Progress (2026-09-29):
- 10:35 the School has room for every subject (ten tabs and colours, a grade lists its own subjects, the map fits two
  rows of tabs), grade 3 ids and up to 4000 units of progress (`2a5554b`).
- 10:40 grade 3's outline: maths 18, science 14, English 16 units (`73566c3`); two agents write their lessons.
- 10:50 the backup's limits raised for a School that grows (server module 0.2.14: 1 MiB, 5000 keys an object; Nakama
  4 MiB requests; the game's ProfileBackup 1000 KB) (`4f3bd14`).

## §2 The cosmos (#72, #74)
What exists: flying above the space line opens space; three planets (the Moon, Planet Boing, Rainbow Planet), each a
real endless world (spec §21).
Next:
- **A star map in space:** every universe is a planet in the sky (Green Meadows, the Desert, Frostpeak, Candy
  Kingdom, the Dragon Realm, the Moon, Planet Boing, the Rainbow Planet, and every new one). The child flies to one and
  lands. Locked ones are shown too, with what unlocks them (a boss, or later EasyCraft Plus).
- **The real solar system** (#74: "closer to real worlds so player start learning real things"): planets and moons
  that are real places, each its own universe with its real facts to feel and learn: Mercury (the Sun huge, days hot,
  nights freezing), Venus (thick yellow clouds), Mars (red dust, Olympus Mons, the rovers), Jupiter's moons (Europa's
  ice, Io's volcanoes), Saturn's rings and Titan, the ice giants, Pluto. Real gravity (a jump on the Moon or on Mars),
  real day lengths, real temperatures shown on a space thermometer, the planets in their real order around the Sun.
- **More planets**, each its own universe (worlds 19, 20, …): new ground, sky, gravity, creatures and secrets; the
  playful planets (Boing, Rainbow) stay as the child's own discoveries beside the real ones.
- **Stars and nebulae** in space: a real starry sky with the real constellations and far suns, a telescope to name them.

Design: spec §21b (2026-09-29): the Star Map (every real planet and every universe with a card of real facts, a free
peek, LAND or what opens it), then real planets as worlds 19-27 in this order: Mars, Europa, Io, Titan, Mercury, Venus's
cloud city, Saturn's rings, Pluto, Triton.

**Owner #77 and #78 (2026-09-29 evening), now first in the cosmos queue:**
- **Missions** (spec §21d, brief `2026-09-29-missions-brief.md`): the way to a planet is a rocket the child builds on
  the Launch Site's pad, alone or with friends, checked like a real rocket (push against weight, the rocket equation,
  air, seats, a heat shield), then a countdown and a launch. A planet reached once stays on the route. No portals.
- **Colonies under domes** on Mars and the Moon (spec §21c, brief `2026-09-29-colony-domes-brief.md`): the real Moon
  base and Mars city ideas; a greenhouse dome where plants and animals live, homes, a lab, water and oxygen plants,
  solar fields, a big rocket.
- **Invent it** (spec §21e): in Survivor, flight is invented in history's order (kite, balloon, glider, plane, jet,
  rocket), each with its real story and science; more invention lines after.
- **The world's wonders** (spec §24, brief `2026-09-29-world-wonders-brief.md`): world 41 and Earth's range 41-60; the
  ancient seven, the new seven, nature's wonders, later wonders; the Wonders Passport.

## §3 Universes (#72)
Ladder today: 1 Green Meadows, 2 Sandstorm Desert, 3 Frostpeak, 4 Candy Kingdom, 5 Dragon Realm. Next (spec §5.1):
6 Glow Caves, 7 Neon City, 8 Lava Core, then remix universes and the hidden Glitch universe. Each: its own look,
blocks, music, monsters, boss and secrets.
- **2026-10-01:** universe 6, the Glow Caves, is next for an agent (brief `2026-10-01-glow-caves-brief.md`: caves of
  light, the Spore Mother, real cave science; page 44, ids 752-767), when Ganymede's slot frees.

## §4 Worth paying for later (#72)
EasyCraft Plus (a one-time purchase, every universe after the first two) is built; the shop stays off until the owner
opens it. What makes it worth it: universes with their own wonders, bosses and secrets; previews of locked universes
and planets (a short look inside, the Secret Book's count); planets on the star map. Always within the fair-fun rules
of `docs/design/` (no pressure, no tricks, a grown-up buys).

## §5 Visuals (#72)
A pass on light, sky, clouds, water and space, in both graphics styles, within the performance budget (≥ 30 FPS on
the emulator, no frame over 100 ms in play).
- **What exists (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md):** colours decoded once on every renderer,
  ACES at exposure 0.75, the far land melting into the sky, hazy far hills, a golden low sun, the photo sky at dusk and
  night, moonlit nights, a world's own sunlight (Mars), blocky water's depth, glint and shimmer, swaying leaves and
  plants (HIGH), the title diorama beside the wordmark; `tools/look_shots.gd` photographs and benches fixed views in
  both styles and renderers.
- **What comes next:** the sway on MEDIUM (find why a custom cut-out shader costs twice StandardMaterial3D's on
  Vulkan Mobile); the wordmark's shine and the loading card's look; a touch of colour variation on big fields (a
  block shader); water's colour by depth and a soft shoreline (needs the depth texture: a full-screen copy on phones,
  measure first); clouds in the painted sky; the realistic sky at other hours (a sky shader instead of the fog's wash);
  each world's own haze and light (Venus's white noon, the Wonders' bright grass); caves' own mood.

## §6 Learning worlds (#74): real things, real crafts, labs, secrets, excitement
The owner: "make the universies closer to real worlds so player start learning real things, real crafts, real
allsubjects, we need more labs, more eduction, more secrets, more excitments". The School's subjects come alive in the
worlds (and the School's projects send the child into them):
- **Real crafts** in the game's building: smelting ore to metal, pottery from clay (a kiln), weaving from wool and
  cotton, woodwork, glass from sand, dyes from plants, bread from wheat, paper from wood; each shows the real steps.
- **Labs:** a science lab block and room where the child mixes, heats, weighs and measures (states of matter, mixtures
  and reactions, magnets, circuits, light and colour, plants growing); results written in the Lab Book. Designed:
  spec §23 (the Science Lab: predict, try it, what happened and why; six experiments first).
- **Real nature:** animals and plants with real names, where they live and what they eat (a field guide that fills as
  the child meets them); rocks and minerals with their real properties; real weather.
- **Real places and history:** landmarks to find (a pyramid, a castle, a lighthouse, an observatory), each with its
  real story; maps and a compass; history's inventions in the order people made them.
- **Every subject in the world:** maths in building and trading (measuring, areas, money), music with instruments
  that play real notes, art with real colour mixing, computing with block-programmable robots, health with food and
  sleep that matter to the buddy.
- **More secrets and excitement:** real facts as secrets to discover (the Secret Book), expeditions, discoveries that
  unlock new places, surprises in every world.

## §7 Life skills and the educational platform (#112, #113, 2026-10-16)
"This is not just a game, this is an educational platform." Beside the School (§1), **Life**: everything a child needs
in life, learned by doing (in VR with the hands), made obvious for a child who cannot read yet, with the learning shown to
parents, and a classroom mode for a teacher with ~20 headsets. The design: `docs/design/life-skills.md`; spec §27.
Order: L1 (the Life tab, the Passport, the grown-ups' Life page, the Experience framework, Little Lifesaver, Fire Escape,
My Money Stall) as soon as an agent slot frees after VR P5 and the cars; then L2 (Safe Streets,
The Kitchen, Calm Corner, Life Town), L3, L4 (the Classroom, C1, is the future: #114); side by side with the School's next grades (#111). Never "done" (#71).
**Success (#115):** Life's second strand, what school does not teach: money, business, trading, communication,
connections, negotiation, leadership, self-mastery, thinking, character, the future of work (`docs/design/success-skills.md`).
S1 rides with L1 (My Money Stall as My Business's first step), then S2 beside L2, S3, S4.

