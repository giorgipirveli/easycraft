# Robots and aliens on the planets (owner #86, spec §21f)

The owner (#86, 2026-09-29): "on the planets we should have some aliens, robots as well". Brief:
`docs/superpowers/plans/2026-09-29-space-creatures-brief.md`. Built by a worker agent in its own worktree (branch
`worktree-agent-ace7d148b8053f985`, reset to `lead-merge` 698c85ae first: the flight merged), without the editor, the
emulator or adb; windowed runs of the new `tools/creature_shots.gd` for pictures.

## Allocations (used; nothing else touched)

| What | Used |
|---|---|
| New files | `core/creatures/*` (pure: `CreatureWords`, `RobotRules`, `AlienRules`, `EchoGame`, `CreatureData`), `entities/robot/*` (`CreatureLook`, `RobotModels`, `SpaceCreature`, `HelperRobot`, `RoverBuddy`, `ScoutDrone`, `SpaceCreatures`), `entities/alien/*` (`AlienModels`, `Alien`, `AlienCamp`, `AlienVillage`), `ui/space/creature_card.gd` (`CreatureCard`), `tools/creatures_smoke*.gd`, `tools/creature_shots*.gd`, tests `tests/unit/test_robot_rules.gd`, `test_robot_words.gd`, `test_alien_rules.gd`, `test_alien_echo_game.gd`, `tests/integration/test_robot_creatures.gd`, `test_alien_village.gd` |
| Block ids, item ids, atlas tiles, sounds, HUD spots | none (every model is boxes in vertex colours; the drums ring the building notes' bell, `BuildMelody.STREAMS`) |
| Server module | unchanged (the profile's new `creatures` part travels in the backup like the rest) |
| Small additions to shared files | `scenes/sandbox.gd` (section "Owner #86", one call in `_space_local`), `entities/player/block_interactor.gd` (one tap: `_tap_space_creature`), `core/save/profile_data.gd` + `profile_backup.gd` (`creatures`), `core/magic/mini_rules.gd` (eight alien mini-buddies in `MINIS`), `entities/animal/magic_pet_models.gd` (their look), `world/buddy_magic_director.gd` (`bring_minis` brings one alien at a time), `ui/shop/gold_shop.gd` (the souvenirs on DECORATIONS) and its test |

## What a child meets on each planet

On **every space world** (the Moon, Planet Boing, Rainbow Planet, Mars, Europa, Io, Titan, Mercury):

1. **The helper robot** stands by the landing pad, five steps from its middle, to the front and right of the child who
   lands (never in the portal home, where the lander parks, Tilly's stall or Mercury's thermometer): a white round robot
   on two treads with teal and orange trims, a screen face with round glowing eyes and a smile, the planet's colour as a
   badge on its chest, an antenna with an orange light, its name over its head. Its **arm points where the HUD's compass
   points** (the planet guide's next place); on a planet without sights (the Moon, Boing, Rainbow) it points to the aliens.
   A "!" floats over it while its quest waits.
2. **It greets the child** who comes near: its hello in a speech bubble (and babble at a robot's pitch), then five seconds
   later "Look where my arm points: Great Canyon! The red arrow points there too." It never opens a card by itself: the
   guide card (its places) and the compass (the way) stay the guide's; the robot points and speaks.
3. **A tap on the robot** opens its card: its hello, the planet's first fact, where to go next, and its **Science Quest**:
   LET'S GO! / NOT NOW. The quest: (1) "tap your rover buddy: it digs a sample for science" (2) "explore <the guide's next
   place when the quest starts, else the aliens>", its arm pointing there (3) "come back to me" (a "?" over it): a question
   with three answers about the planet. Right the first time: "+10 gold!" (EarnRules.FACT_QUIZ_GOLD, once per question,
   into the child's gold in both modes); wrong: "Not yet! Here is a hint: …", a second miss shows the answer (the School's
   way: never a failure). Afterwards ANOTHER QUESTION until every question of that robot is answered.
4. **The rover buddy**, a little six-wheeled rover with a solar panel, a camera mast with two round eyes and a digging scoop,
   drives after the child (a little behind and to their right) and comes to them at once when left far behind. A tap: it
   tips its scoop, a puff of the ground's dust, a beep, and the sample's real fact ("Your sample: red Mars dust! It is red
   because the iron in it has rusted."). One sample per world counts for the quest.
5. **The scout drone** (four orange rotors, a teal dome, one wide eye) flies a few blocks over the ground ahead of the child
   towards the next place, and circles over them when every place is explored. A tap: "Your drone flew ahead: Great Canyon
   is 125 blocks south!"

On **the real bodies** (the Moon, Mars, Europa, Io, Titan, Mercury): **a travelling explorers' camp** about 30-50 blocks
from the pad, seen from it and on MY MAP from the landing ("Explorers' Camp"): a small round ship on three legs (a pearl
hull with a ring of lights, a glass dome, a door and a ramp, a star light on its antenna), a telescope looking at the sky
(they keep looking), a lamp post, the trader's table with its souvenirs, and two friendly aliens (round bodies, big round
shiny eyes, rosy cheeks, two antennae with glowing tips; our own design, never grey, never dark eyes):
- **The explorer** (by the telescope, a belt with a star badge and a backpack) says it comes from a make-believe world
  ("In my story, my home planet Glimmer has three suns…"), always **"No one has found life beyond Earth yet: scientists keep
  looking, and so do we!"** and a real fact about how scientists look for life, and asks for a sample of the planet. With
  the rover's sample: GIVE A SAMPLE → "Thank you! You are my friend now. Here is a present for you: the Glimmer Gem!" (a
  souvenir) → "May I come along with you, into every world?" COME ALONG / NOT NOW. Coming along, it is a **mini-buddy**
  (the buddy system: like a boss's mini, it follows the child into every world, never takes a pet place, never fights);
  its spot at the camp is empty while it is away. One alien comes along at a time: a new one sends the other back to its
  camp ("Zib goes back to its camp, and stays your friend").
- **The trader** (behind the table, an apron with a pocket) sells two **souvenirs** (make-believe treasures, 60-120 gold:
  the Three-Sun Marble, the Singing Pebble…) with the child's Survivor gold ("You have 510 gold."; "You need 40 more gold.
  Lessons in the SCHOOL earn it!"). Each is theirs once, with its story line; the Gold Shop's DECORATIONS shelf sells them
  too.
- Walking into the camp: "You found the aliens' camp! They are explorers from a make-believe world."

| # | World | Robot | Its first fact | The sample | Explorer, trader (souvenirs) |
|---|---|---|---|---|---|
| 16 | The Moon | Lumo | no air, no wind: footprints can last millions of years | moon dust: sharp bits of rock broken by space rocks | Blip (Planet Wobble; the moon bunnies are make-believe too), Ploo (Wobble Jelly Jar, Star Compass) |
| 17 | Planet Boing | Sprocket | gravity pulls you down on every planet; Boing's is weaker | boing moss (make-believe; real moss is a tiny plant) | the village Boingaloo: chief Bopsy, Hop, Zoop, Tiggle |
| 18 | Rainbow Planet | Prism | sunlight through raindrops splits into a rainbow | prism grass (make-believe; a real prism splits light) | the village Prismtown: chief Iri, Hue, Tint, Shimmer |
| 19 | Mars | Dusty | the Red Planet: rust in its dust; a day of about 24½ hours | red dust: its iron rusted | Zib (Glimmer, three suns), Quix (Three-Sun Marble, Singing Pebble) |
| 20 | Europa | Glint | Jupiter's moon; a salty ocean under its ice | ice never warmer than about −160 °C | Nuri (Bubbla, soap-bubble snow), Fizz (Bubble Snow Globe, Ice Flute) |
| 21 | Io | Ember | the most volcanic place in the solar system | yellow sulphur from its volcanoes | Tinka (Emberpop, pink rain), Wobbo (Pink Rain Umbrella, Warm Glow Stone) |
| 22 | Titan | Haze | Saturn's biggest moon, the only moon with thick air; methane lakes | ice as hard as rock at about −179 °C | Oolo (Mistyloo, fog wings), Mip (Fog Wings Kite, Haze Lantern) |
| 23 | Mercury | Sunny | closest to the Sun, the smallest planet; a year of 88 Earth days | dust; a huge iron core inside | Pim (Twirl, a one-hour day), Zeeka (Twirl Spinning Top, Sunbeam Hat) |

On **the playful planets** (Planet Boing, Rainbow Planet): **an alien village** in a clearing among the giant spring
mushrooms or the prism spires (on MY MAP by its name): four round homes round a square (Boing's mushroom huts with spotted
caps, Rainbow's huts with striped cone roofs), four drum pads (red, yellow, green, blue) in the square, the **chief** (a
little gold crown) and three villagers in scarves strolling round their homes (a tap: "Boop! Hello!", a hop). The chief
says the village is make-believe, the honest line and a real fact (radio telescopes listening; starlight split into colours
to learn what far planets' air is made of), and offers **Echo**: PLAY ECHO → the chief plays a little song on the drums (each
lights up, bounces and rings its own note of the pentatonic scale), then "Your turn! Hop on the drums in the same order."
Each round is one note longer (2 to 5 notes); a wrong drum: "Not yet! Listen again." and the round plays again; the whole
song: everyone hops for joy, the chief is the child's friend, gives its present (the Boingaloo Drum, the Rainbow Bell) and
asks to come along. No timer, nothing lost; walking away ends the game quietly.

## How it is built

- **Pure rules** (`core/creatures/`): `CreatureWords` (every word, the facts, the question banks, the aliens' colours, the
  souvenirs), `RobotRules` (the helper's spot, the quest's steps kept in the world's secrets as `creature:*` ids, the
  questions' gold, the rover's and the drone's goals), `AlienRules` (the camp's and the village's sites, friendship, the one
  buddy, souvenirs on SpendRules), `EchoGame`, `CreatureData` (the profile's part).
- **Nodes** (`entities/robot/`, `entities/alien/`): `SpaceCreatures` (node "Creatures" in the sandbox) builds everything from
  the world's seed and the landing (every game its own: space trips are solo; a LAN guest never builds them) and answers
  every tap; `SpaceCreature` is the shared base (taps: `SpaceCreature.find`, a ray near its middle within its reach, never
  through a block; babble; the bubble; the style's material; sleeping far from the child); `HelperRobot`, `RoverBuddy`,
  `ScoutDrone`, `Alien`, `AlienCamp`, `AlienVillage`. The card is `CreatureCard` (a `QuestOverlay`: Esc, Back and a finger
  outside close it; a PC shows its pointer).
- **Looks** (`CreatureLook`, `RobotModels`, `AlienModels`): each model is one merged mesh of boxes (WeaponModels.build)
  drawn with the animals' own vertex-colour material (the same flags as BlockyAnimal's: no new shader); the realistic style
  gives the robots Pip's shiny metal (`Animal.pip_material`, the same shader) and the aliens a softer sheen. Visibility
  ranges (110 m robots, 220 m camps and villages). A camp's ground-touching parts reach a block into the ground, so a camp
  on ground a block lower never floats.

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **The robot's greeting is a speech bubble and babble, never a card**: the landing already shows the planet guide's card
   and the landing words. *Cost:* one call (`_greet` opening the card).
2. **The robot points where the compass points, and the quest's place while the child explores it**; on a planet without
   sights, at the aliens. It never lists the places (the guide card's job). *Cost:* `SpaceCreatures.robot_target`.
3. **The helper robot stands five steps from the pad's middle, the front-right first**, clear of the portal home (3 in front
   of the landing child, or the world's own portal from an earlier visit), the lander (7 to the left: `_stand_lander`),
   Tilly's stall and Mercury's thermometer; it is placed at every load from the landing's facing (a robot moves about:
   never saved). *Cost:* `RobotRules.ANGLES`, `helper_spot`.
4. **The science quest is kept in the world's secrets** (`creature:quest`, `creature:sample`, `creature:place:<place>`,
   `creature:quest_done`, `creature:camp`): saved with the world, never counted by the Secret Book (its ids have four parts).
   One quest per world; its questions (3-4 per robot) each pay once per child (the profile's `CreatureData.quiz`). *Cost:* a
   quest per visit would need a day stamp.
5. **The quiz gold is EarnRules' "fact_quiz" row** (10 gold, once per question, right the first time), into the profile's
   Survivor gold in both modes (like the Lab's stars), shown on the gold counter. *Cost:* one constant.
6. **One sample per world** counts (a second tap repeats the fact). *Cost:* `RobotRules.dig`.
7. **Aliens on the real bodies are a camp; on the playful planets a village** (the brief). The Moon counts as a real body
   (its explorer says the moon bunnies are make-believe too). *Cost:* the tables `CAMPS`, `VILLAGES`.
8. **Friendship (the buddy system)**: an explorer befriends the child for a sample of its planet (the rover's), a chief for a
   won game of Echo; never for gold. A friend gives a present (a souvenir of its own, never sold). *Cost:* `AlienRules.state`.
9. **The friend who comes along is a mini-buddy** (MiniRules.MINIS gets eight alien kinds; the record lives in
   `BuddyMagicData.minis` and is never lost; `BuddyMagicDirector.bring_minis` brings only the one in `CreatureData.buddy`):
   the buddy system's own pipeline (it follows, never fights, never takes a pet place, comes into every world). Traders and
   villagers never come along. *Cost:* a new kind of pet would be a PetRules row and its own spawner.
10. **One alien comes along at a time**; befriending another asks, and the one before goes back to its camp (it stays a
    friend; its mini leaves the world). An alien buddy stays with the child until another comes along (no STAY HERE button).
    *Cost:* `AlienRules.come_along`, `stay_home` (already there, unused by the card).
11. **"One can join the child's colony dome"**: the colonies are not on this base. The friends are kept
    (`CreatureData.friends`, `buddy`); the colony agent can seat them in the dome from there. *Cost:* the colony's reading of
    `CreatureData`.
12. **Alien things for gold are souvenirs** (make-believe treasures with a story line, 60-120 gold, twelve for sale, eight
    presents) through `SpendRules.register` on the Gold Shop's DECORATIONS shelf (`alien:<id>`), bought at a camp's trader
    too (`AlienRules.buy`). No block or item ids (none were allocated): a souvenir is kept in the profile
    (`CreatureData.souvenirs`), shown on the trader's card ("Your souvenirs: …") and on the shelf; showing them in the
    colony dome or on the trophy shelf is next. *Cost:* the DECORATIONS shelf is no longer empty (its test changed).
13. **Honesty**: every explorer's and chief's card says `CreatureWords.HONEST` word for word, its home world is always "in my
    story" or "make-believe", and each tells a real fact about how scientists look for life. A trader's card says it too.
    No mission, company or person's name anywhere (`test_robot_words.gd` checks a list of 37). *Cost:* none.
14. **Never hurt, never scary**: aliens and the rover and drone have no collision (the child walks through them); the robot,
    the ship, the table and the homes have small boxes (Jolt's footprints small); no word they say is scary
    (`test_nothing_they_say_is_scary`). *Cost:* none.
15. **A bounce on the same drum counts once** (Planet Boing's moss bounces a child who lands; a song never has one drum twice
    in a row). *Cost:* `EchoGame.hop`.
16. **The village keeps its homes, square and chief clear of mushrooms and spires** (their caps overhang higher than a
    home's roof), not the whole clearing: Boing's mushrooms (1.2 % of columns) leave almost no 20-block clearing.
    *Cost:* `AlienRules.village_clear`.
17. **The alien site keeps 22 blocks from the landmark and 14 from each big sight**; other secrets (a temple, a room) may be
    near. *Cost:* `LANDMARK_CLEAR`, `SIGHT_CLEAR`.
18. **A robot guide at each landmark** (spec §21f) is not built yet: the helper robot and the drone point there. *Cost:* a
    `HelperRobot` at `SpaceSecretRules.landmark()`.
19. **The creatures are this game's own** (space trips are solo, `SpaceRules.refusal`): a LAN or online guest who joins a
    host already standing on a planet sees none (nothing is sent). *Cost:* the director on guests from the seed (every
    placement is already deterministic except the helper's facing).

## Facts and their sources

Every real fact the robots and aliens say (the question banks say the same facts):

| Fact (game words) | Source |
|---|---|
| The Moon has no air, so no wind: footprints can last millions of years | NASA, Moon facts (science.nasa.gov/moon/facts): no atmosphere, no wind or water to erase them |
| Moon dust (regolith): sharp broken rock from impacts over billions of years | NASA, Moon's surface / regolith (science.nasa.gov/moon) |
| On the real Moon you could jump about 6 times higher (gravity about one sixth) | NASA, Moon facts (gravity 1.62 m/s², 16.6 % of Earth's) |
| Mars is red: rust (iron oxide) in its dust; a day about 24½ hours | NASA, Mars facts (science.nasa.gov/mars/facts: a day of 24.6 hours) |
| The tallest volcano in the solar system is on Mars (Olympus Mons) | NASA, Mars facts |
| Mars's caps: frozen water and frozen carbon dioxide; water flowed long ago | NASA, Mars facts (and the game's own Mars sights, `cosmos-mars.md`) |
| Rovers study Mars rocks for signs of ancient tiny life | NASA Mars Exploration: the rovers' goal of seeking signs of ancient microbial life |
| Europa: Jupiter's moon; scientists think a salty ocean lies under its ice | NASA, Europa facts (science.nasa.gov/jupiter/jupiter-moons/europa) |
| Europa's surface never warmer than about −160 °C | NASA, Europa facts (−260 °F, −160 °C at the equator) |
| Io: the most volcanic place in the solar system, hundreds of volcanoes; sulphur | NASA, Io facts (science.nasa.gov/jupiter/jupiter-moons/io) |
| Titan: Saturn's biggest moon, the only moon with thick air; lakes and seas of liquid methane | NASA, Titan facts (science.nasa.gov/saturn/moons/titan) |
| Titan about −179 °C: its ice is as hard as rock | NASA, Titan facts (−290 °F, −179 °C) |
| A probe from Earth landed on Titan and sent pictures | ESA/NASA: a probe landed on Titan in 2005 (no mission name in the game) |
| Mercury: closest to the Sun, the smallest planet; a year of 88 Earth days | NASA, Mercury facts (science.nasa.gov/mercury/facts) |
| Mercury has a huge iron core (about 85 % of its radius) | NASA, Mercury facts |
| Mercury shrank as it cooled: long cliffs | NASA, Mercury (the game's own Mercury sight, `cosmos-mercury.md`) |
| Spacecraft have mapped the whole of Mercury | NASA: a spacecraft in orbit 2011-2015 imaged 100 % of the surface |
| Every living thing we know needs water; scientists look for water | NASA Astrobiology ("follow the water") |
| Europa's ocean: where there is water, there might be life | NASA, Europa mission pages |
| Tiny living things live in hot springs on Earth | NASA Astrobiology (extremophiles) |
| Some scientists wonder if very different life could live in Titan's methane lakes | NASA Astrobiology (life "not as we know it" in Titan's lakes: a question scientists study) |
| Telescopes have found more than 5,000 planets round other stars; scientists study their air | NASA Exoplanet Archive (over 5,500 confirmed by 2024) and space telescopes' atmosphere studies |
| Giant radio telescopes listen to space in case someone is calling | the SETI Institute's radio searches |
| Scientists split starlight into colours to learn what far planets' air is made of | NASA, space telescopes' transmission spectroscopy |
| Rainbows: sunlight through raindrops, red at the top; white light holds every colour | NOAA/NASA SciJinks "How is a rainbow formed?" |
| Gravity pulls you down after every jump on every planet | general physics |
| Real moss is a tiny plant that loves damp, shady places | general biology |

## Frame costs and draw calls

- **Per frame** (the desktop, the real Mars world settled, best of 5 runs of 240 frames): the helper robot 0.005 ms, the
  rover 0.007, the drone 0.025 (its four rotors spin), the explorer and the trader 0.006 each, the director 0.004:
  **0.052 ms for all of them** (Tilly alone 0.002). A phone 3-5× slower: about 0.25 ms. Measured by
  `tools/creatures_smoke.gd` (`CREATURES_FRAME_MS`) and the integration test (0.03-0.04 ms, `CREATURES_FRAME_MS`).
- **What keeps it small**: thinking 4 times a second; a transform is set only when it moves (every set tells its meshes);
  the rover and walking villagers read the ground once per column they reach (a block read is a locked read, ~15-35 µs);
  the robot and the aliens sleep beyond 64 blocks from the child; the village's drums are looked at 10 times a second only
  while Echo is on. A first measurement right after a teleport read 1.0-1.5 ms: that was the chunks streaming in round the
  camp competing for the CPU (the same code measured 0.05 ms three seconds later), not the creatures.
- **Draw calls**: Mars (a camp) 13 meshes (robot 2, rover 1, drone 5, the camp 1, each alien 2) and 10 labels (names, the
  bubbles, the sign, the mark); a village 4 homes + 4 drums + 4 aliens × 2 + robots 8. Nothing new to compile.
- **Loading**: finding the camp's site 0.5-5 ms, the village's 1-3.5 ms (`test_every_world_with_aliens_finds_a_calm_level_site_near_the_pad`).

## Tests

- `tests/unit/test_robot_rules.gd` (12), `test_robot_words.gd` (8), `test_alien_rules.gd` (10), `test_alien_echo_game.gd` (5),
  `tests/integration/test_robot_creatures.gd` (13: the robot, rover, drone and camp on Mars, pointing, taps, the whole quest
  with gold, a wrong answer, following and scouting, the friendship and the one buddy, the trader, the visit, the greeting,
  both styles, the frame cost), `test_alien_village.gd` (6: Boingaloo, Prismtown, Echo to a friendship, a wrong drum, walking
  away, strolling). 54 tests, all passing; the existing tests of the shared files touched pass (buddy magic, magic pets,
  gold shop, spend rules, profile data and backup, identity words, trader tap, pet dragon).
- **The full suite** (2026-09-30, on this branch): 872 scripts, 7,978 tests, **7,976 passing, 0 failing**, 2 risky as
  before, no script errors.
- `tools/creatures_smoke.gd` (`tools/smoke_all.sh creatures`): the real sandbox, a new Mars world and a new Planet Boing
  world, every tap through the child's own BlockInteractor: **0 fails** (about 50 s; three runs in a row).
- The pictures' tool also shows the robot's and an alien's cards over the world (`robot_card`, `alien_card`): both fit
  the screen (the trader's two souvenir buttons side by side, the robot's four paragraphs and LET'S GO / NOT NOW).
- Pictures: `tools/creature_shots.gd -- --universe=19` and `--universe=17` (windowed, both styles): the robot, rover and
  drone, the camp, Zib and Quix, Boingaloo and Bopsy looked as designed; Boing's first village stood under a giant
  mushroom (fixed: ruling 16); Bopsy's lime body was lost on the lime moss (now sunny yellow); the ship was small next to
  the aliens (now 1.4 times as big).

## For the lead

- **Merge**: the shared files above are one-line or one-section additions. `ProfileData`/`ProfileBackup` gain `creatures`
  (the daily-and-friends agent may add its own part next to it). `MiniRules.MINIS` gains eight alien kinds (existing tests
  iterate it: they pass). The Gold Shop registers the souvenirs (`test_gold_shop` no longer expects DECORATIONS empty).
- **Controllers**: `PadFocus` is not on this base; `CreatureCard` needs `PadFocus.watch(card)` once the controllers are
  merged (its buttons are plain Buttons in a QuestOverlay).
- **On the emulator** (both styles): land on Mars, Boing and the Moon: the robot by the pad (not in the portal, not under
  the lander after a mission), its bubble readable, its arm pointing along the compass; the rover following over bumpy
  ground (Mercury's craters, Io's cones) and the drone ahead; frame times by the camp and the village (the budget: ≥ 30 FPS,
  no frame over 100 ms), a tap on each creature with a finger (the rover and the drone are small: reach 6.5 and 10); the
  card on a phone's screen (860 wide); Echo's notes in time; the alien buddy following into Green Meadows.
- **Next**: a robot guide at each landmark; showing souvenirs in the colony dome and on the trophy shelf; the rover carrying
  blocks; more questions per robot; aliens in the far universes' villages (spec §21f); crews' alien friends (with the
  daily-and-friends work).
