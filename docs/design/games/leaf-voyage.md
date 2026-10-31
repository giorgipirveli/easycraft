# Size Magic Voyages: Inside a Leaf — the design (phase A)

The first future lesson (owner #133, #134; `docs/design/future-lessons.md` §5, wave 1). This is **phase A**: the research
and the design, reviewed by the lead (and shown to the owner as `leaf-voyage-owner.md`) before any code. The brief:
`docs/superpowers/plans/2026-10-17-game-leaf-voyage-brief.md`. Pictures: `docs/design/games/leaf-voyage/`. Notes on how
this was made: `docs/devlog/parts/game-leaf-a.md`. Written 2026-10-18 on the worktree branch
`worktree-agent-ab81cb3a617434327` (cut from lead-merge at `d258cd72`).

The owner, 2026-10-17, after watching their child play for half an hour and meet no learning: "noone will start reading
and learning the lessons when playing game … we need future lessons, not just texts with visuals like slides". So: a
child must *choose* this over their favourite game (the owner's child plays Gorilla Tag on the Quest, #130), nothing may
be read, guessing must lose, the idea must carry into new places, and the first minute must be beautiful.

---

## 0. In one page

**The fantasy.** Your sunflower is drooping in the heat. Size Magic shrinks you smaller than a hair, and you fly up
through one of the leaf's tiny doors into a green cathedral of cells, with sunlight pouring through the roof. Inside you
find out why it droops, fix it with your hands, and help the leaf build sugar out of thin air and light. Grow back to
normal size and the sunflower stands tall and opens its flower; a bee lands on it. Every year Size Magic takes you one
level deeper: the plant's parts (grade 4), inside the leaf (5), inside one cell (6), among the atoms (7), then back out
to run the whole plant (8).

**The verb that is the concept.** *Work the leaf's doors* (stomata): open them to let air in, close them to keep water
in, and time it to the weather, as real plants do. Every sugar the leaf builds is made from the air you let in, and the
plant grows from that sugar, not from the soil. Each deeper level adds the verb its idea needs (fill the cells, turn the
chloroplasts, build sugar atom by atom, burn it at night, send it where it's needed). Guessing loses: in a model of the
first voyage, a child who opens and closes doors at random reaches the mastery bar (5 of the 6 judged turns) in 0 of
1,000 runs, "always open" and "always closed" never do, and the real rule always does (§3.9).

**The five tests.**

| Test | This game's answer | Checked in phase B by |
|---|---|---|
| Choice | Flying (VR: swimming with your arms, Gorilla Tag's way) through a giant living world; your own plant that visibly thrives because of you; a rhythm of jobs (doors in the cloud, sugar in the sun); short voyages; a garden that grows across worlds | The owner's child: do they start a second voyage unasked, and come back another day? |
| Mute | Nothing to read: mist pours out of open doors, cells sag and plump, air puffs wait outside the doors, the green workshops light up, sugar pops out gold, the bud fills above the roof; one short spoken line at a time | Every line spoken by itself; no word on the screen during play (a test); the owner's child plays with text hidden |
| Cheat | The leaf is a simulation: doors that are wrong for the weather dry it out or starve it; the beats are judged by outcome and by contrast (open in the cloud *more than* in the blaze) | Bots in the tests: random, always-open, always-closed, greedy and habit bots fail; the rule bot passes |
| Transfer | Every level has new places where the rule must change shape: a cactus in the desert (open the doors at *night* and keep the air in jars), a water lily (doors on *top*), a tree in winter (live on the store, then send it *up* to the buds), a dark cupboard, a pond, a dome on Mars | Phase B ships the desert night: the sunflower's habit fails there (0 %), the understood rule wins (100 %) |
| Wow | The shrink (a Powers-of-Ten dive), the green cathedral, the bloom with a bee, a cactus flower opening under the stars | The owner's verdict; whether the child shows it to someone |

**The ladder (grades 4-8)**: rung 4 *Plant Explorer* (ant-sized: roots, stem, leaves, flowers), rung 5 *Built from Air*
(cell-sized: doors, air and water, sugar from light), rung 6 *One Cell* (inside a cell: wall, membrane, the water
balloon, chloroplasts, mitochondria, nucleus), rung 7 *Atom Builders* (molecule-sized: sugar built carbon by carbon,
burnt at night, atoms never lost), rung 8 *The Whole Plant* (water pulled up, sugar sent to where it's needed,
adaptations, design a plant). It replaces, fully or for their plant half, seven units (§2.6).

**Minute 1:** pour water on a drooping sunflower; it still droops; touch a leaf and shrink. **Minute 5:** inside, closing
the doors in the blaze and opening them when a cloud cools the leaf, carrying gold sugar to the bud's pipe. **Minute 30:**
four voyages in: the sunflower bloomed, its stem grew thick from air, a whole day and night went by, and a cactus opened
a white flower under the stars in the desert.

**Phase B** (the vertical slice): voyage 5.1 *The Drooping Sunflower* and the transfer voyage 5.T1 *The Desert Night*,
flat and VR, complete and beautiful. Estimate: **6 agent sessions** (§5). The open questions for the lead are in §8.

---

## 1. The bar this game must clear

From `future-lessons.md` §2 (the authority): a future lesson is a game a child chooses to play, where the knowledge is
the only way to win, nothing has to be read, and the game knows what the child learned from how they play. Five tests
(choice, mute, cheat, transfer, wow), four gated phases. From `learning-is-play.md` §3: the concept is the mechanic,
play first and words after, the world answers, shown when stuck, short and again, in the world and for the world, words
as tools. Rule 0 (owner #133): a child never has to read. EasyCraft's own rules apply too: calm, kind, never scary, no
gambling, no pressure tricks (no FOMO, no streaks, no character that is "sad" to make a child play:
`engagement-and-child-psychology.md`), English only, nothing personal kept or sent, flat and VR, the phones' budget.

---

## 2. Research

### 2.1 What children get wrong about plants, and what fixes it

The single most-reported plant misconception is that **plants take their food from the soil**: a 2017 review found it in
**28 separate articles**, from primary pupils to postgraduates and trainee teachers, and notes that such ideas form
young and persist through every level of schooling [R1]. In a well-known science-education film, new graduates of a top
university said a tree's mass comes from the soil [R11]. In the US, only about **one high-school student in ten** gives
explanations of photosynthesis, respiration and growth that keep track of matter and energy [R5][R6]. Younger children's
understanding grows with the school years, but unevenly [R12].

| What children think | Who, how often | Why it sticks | What fixes it (the research) | How this game fixes it |
|---|---|---|---|---|
| Plants get their food from the soil; roots are the mouth; fertiliser is "plant food" | 28 articles, age 7 to adult [R1]; graduates [R11] | Children see plants grow *in* soil and drink through roots; "plant food" on the bag; their own eating is the model (image schemas of human nutrition) [R8] | Make the difference from eating explicit *before* building the new idea ("dissimilation before assimilation") [R8]; trace matter, not just talk about it [R5]; a demonstration alone (van Helmont's willow) **reinforced** the old idea in one study [R8] | The plant never "eats" and has no mouth (ruling 4). The child *tests* soil, fertiliser, water and air as building materials with their own hands (voyage 5.2): soil grains can't get in, fertiliser adds a pinch of minerals, water passes through, only the sugar the leaf builds from air makes new stem. The block-scales show the plant gaining and the soil not. |
| Air has no weight; a gas is "nothing" | Ages 9-15 believe gases weigh nothing or less than solids [R9][R10] | Air is invisible and rises | Show gas as particles that take up space and have mass | Air is a crowd of real things you see, catch and build with (rung 5's puffs, rung 7's molecules); the plant's added weight is that air. |
| Sunlight, water or carbon dioxide *is* the food; light is a material | Common at 11-16 [R2][R3] | "Plants need light" is learned as "plants eat light" (an enabler, level 1 of the progression [R5]) | Separate energy from matter: light gives energy, air and water give the stuff [R5][R7] | Two colours and two jobs: light is **gold sparks** that charge the work, air and water are **things** that become the sugar. In the dark, air and water are there and nothing is built (5.3, 5.T2). |
| Photosynthesis is the plant's breathing ("plants breathe in CO2, breathe out O2"); plants respire only at night, or never | Secondary students [R2][R3] | Gas exchange looks like breathing; school pairs "plants make oxygen, animals use it" | Show both processes running in the same plant; respiration all day and night [R2] | Rung 6-7: the power stations (mitochondria) burn sugar day and night; at night the leaf breathes out CO2 and lives on its store (6.4, 7.4). |
| Matter turns into energy ("the food was converted to energy"); atoms disappear when things burn or are used up | Level 2-3 of the progression; most students [R5] | Everyday words: "burned up", "used up" | Conservation as a rule students *use*: count atoms, weigh before and after, keep energy and matter in separate accounts; in a college course this raised the share reaching level 4 from 16 % to 42 % [R5] | Rung 7: atoms are hand-sized things that cannot be made or deleted; a balance shows the atoms in and out are the same; energy is gold sparks that end as warmth, never as atoms. |
| Water goes up a plant because the roots pump it; leaves "drink" | Common; the units say "like a straw" | Pumps are familiar | Show the pull from the top: evaporation at the leaves | Rung 8: a rope of water pulled up from the leaf's doors; it breaks in a drought. |
| Plants are not alive, or not as alive as animals | Young children judge plants not living because they don't move [R1] | Plants don't move | Put plants in the foreground; show them responding | The sunflower droops and stands, turns to the sun (rung 4), its chloroplasts move in the light (rung 6). |
| Teleology: "roots grow down *to find* water" | Adults too [R1] | Purpose language | Mechanism language | The voice says what happens, not what the plant "wants". |

**The progression underneath** (Carbon TIME, Michigan State [R4][R5][R7]): level 1, stories of actors and enablers
("water helps the tree to grow"); level 2, more detailed stories with hidden parts like cells, but materials "turn into"
energy; level 3, attempts at tracing matter and energy, inconsistent; level 4, atoms traced and energy linked to the
bonds that store it. The ladder follows it: rungs 4-5 move a child from level 1 to level 2 (the plant has parts that do
things; air and water are *materials*, light is *energy*), rung 6 is level 2's cells, rung 7 is level 3 to 4 (atoms
traced, conserved), rung 8 uses level 4 at the scale of the whole plant.

**What we take from this:** (1) the game must make the child *move the matter* or cause it to move, not watch a
demonstration [R5][R8]; (2) energy and matter must look different and never turn into each other [R5]; (3) the plant
must never be shown eating [R8]; (4) the soil idea is tested, not lectured [R8][R13]; (5) prediction is an act, not a
question (the child acts on what they believe and the world answers: predict-observe-explain [R13]).

### 2.2 Games and simulations that teach biology: what works, what fails, and why

| Game or study | What it is | Worked? | Why | What we take |
|---|---|---|---|---|
| **Zombie Division** [G3 in `learning-is-play.md`] | Divide to defeat skeletons | Yes: children chose it **7× longer** than the same maths as a quiz | The maths *is* the attack | The doors *are* the concept |
| **DragonBox** [G5] | Algebra as a balance of objects that turn into symbols | Strong uptake (self-reported) | The rules of the game are the rules of the maths; symbols arrive late | Rung 7: atoms are objects first, formulas only in the Book |
| **A photosynthesis game played as homework before teaching** (cluster randomised trial) [R14] | A digital game, then lessons | **No significant effect** | The game's experience was not connected to the target ideas; teachers had to make the bridge | The see-why line after each try (rule 2) and the science names said after use; never a game beside the concept |
| **Immersive VR biology lessons** [R15] | "The Body VR" vs a slideshow | VR liked more, **learned less**; splitting it into parts with a pause to sum up after each restored learning | Spectacle overloads; generative pauses help | Short beats; one new thing at a time; a "see why" moment after each beat; the child *does* rather than watches |
| **VR added to a science lab simulation** [R16] | Desktop vs headset | More presence (d = 1.30), **less learning** (d = 0.80), more load (EEG) | Extra senses and text fight for attention | No text in VR; a sparse world; every beautiful thing is the concept (the seductive-detail rule [G8]) |
| **Embodied VR design** [R17] | Gestures that match the content | Higher-embodiment groups did better two weeks later; gestures "promote learning, agency, and attenuate simulator sickness" | Movement mapped to the idea | Squeeze two guard cells together to close a door; carry sugar to a pipe; turn a chloroplast to the light; the hands do the idea |
| **Immune Attack** (FAS, 2008) [R18] | Pilot a nanobot inside the body | Reported gains in cell and molecular knowledge (developer's evaluations) | Being inside the system; a job to do there | The shrink fantasy works; give the child a job inside |
| **Spore** [R19] | Evolve a creature | **Taught misconceptions** (evolution as a creature's choice, no natural selection) | The fun mechanic contradicted the science | Every fiction is listed and checked against the science (the honesty table, §9); the mechanic must be true to how plants work |
| **PhET simulations** [R20] | Interactive science sims | Students explore productively with little instruction | "Implicit scaffolding": the sim's affordances, limits and feedback guide without words | The world's limits teach: a closed door blocks air, an open door in the blaze pours mist, soil grains bounce off a root |
| **Newton's Playground / Physics Playground** [R21] | Physics puzzles, stealth assessment | In-game indicators related to learning; pre-post gains (8th-9th graders) | Evidence designed from the actions | The beats (§3.10) are designed as evidence first |
| **Teachable agents** (Betty's Brain) [R22] | Children teach a computer character | More effort, more learning, most for lower achievers (protégé effect) | Responsibility for someone else's learning | Hoot sometimes gets it wrong on purpose (rung 6+: he opens doors in the blaze) and the child stops him |
| **Botanicula** [R23] | A wordless adventure inside a tree | Award-winning, played without a word | Sound, animation and humour carry everything | Proof that a rich plant world needs no text; its humour and sound as models |
| **A Fisherman's Tale** [R24] | VR puzzles of scale (a model lighthouse within the lighthouse) | Praised for its scale play | Scale change in VR is a wonder when the world changes around a still player | The dive: the garden grows around the child's feet |
| **Gorilla Tag** [R25] | VR tag, moving only with your arms | 1M+ daily players, sessions near an hour (2024); the owner's child's game | Body movement is the joy; easy to learn, hard to master | In VR the child swims through the leaf's thick air with their arms |
| **Grow a Garden** (Roblox, 2025) [R26] | Plant, wait, harvest, sell | Over 20 million players at once | Growing and collecting, coming back to see growth | The garden of voyage plants (sunflower, cactus, lily, pumpkin, tree); **not** its random eggs or timers (no gambling, no FOMO) |
| **Super Mario Bros. World 1-1** [R27] | A first level that teaches without words | The model of teaching by level design | The first danger and the first power-up are placed so the player learns by doing | Voyage 5.1's first minute: the mist shows the problem, one door is closed by the ghost, the child does the rest |
| **The Magic School Bus**, **Fantastic Voyage**, **Powers of Ten** [R28] | Shrinking into the body and nature; a zoom by tens | Loved for generations | Scale as adventure; seeing the invisible | The fantasy and the dive |

**Why biology games usually fail:** they put the science *beside* the game (quiz gates, fact cards), they are spectacle
without a job, or their fun mechanic is false to the science. **Why the good ones work:** the system's rules are the
science's rules, the player has a purpose inside it, and the world answers every action.

### 2.3 The body and VR

Three findings shape the VR design. (1) VR raises presence and liking but can lower learning when it adds load [R15][R16]:
no reading in the headset, few things at once, every effect is the idea. (2) Gestures that match the content help
learning and comfort [R17]: the hands close the doors, carry the sugar, turn the chloroplasts. (3) The owner's child
loves Gorilla Tag's arm locomotion [R25]: moving by pulling yourself through the world is joyful and, because the body
makes the motion, comfortable. At the child's tiny size **air really is thick**: for something tens of micrometres
across, air's viscosity dominates and motion stops the moment you stop pushing (Reynolds number around 10⁻³ [P11]). So
"swim through the air with your arms, and stop when you stop" is both true and the most comfortable VR movement there is.

### 2.4 The science we must get right

| Fact | Used where | Source |
|---|---|---|
| Plant matter comes mostly from air and water, not the soil (5-LS1-1's clarification) | rung 5 | [P13] |
| Leaves take in carbon dioxide through pores (stomata); two guard cells swell to open a pore and go slack to close it; guard cells, unlike other skin cells, are green | doors | [P3][P4] |
| Stomata are about 1-3 % of the leaf's surface but lose most of its water (about 90 %); 97-99.5 % of the water roots take up leaves the plant by transpiration | doors, mist | [P3] |
| Transpiration is fastest on hot, dry, windy days (our grade 8 unit) | weather | g8 unit, [P3] |
| Plants close their stomata in the dark and in heat and drought, trading sugar for water | the trade-off | [P3][P5] |
| A well-watered cell's water pressure (turgor) is about 0.5 MPa or more, over 1 MPa when full: roughly five times a car tyre. Losing it is wilting | the droop | [P4] |
| Photosynthesis, net: 6 CO₂ + 6 H₂O + light → C₆H₁₂O₆ + 6 O₂, in chloroplasts. Middle school traces matter and energy, not the biochemistry | rung 5, 7 | [P13] |
| Respiration: sugar + oxygen → CO₂ + water + energy, in every living cell, day and night | rung 6, 7 | g7 unit |
| The oxygen plants give off comes from water, not from CO₂ (heavy-oxygen tracer, 1941) | rung 7's Expert secret | [P14] |
| Glucose's ring is 5 carbons and 1 oxygen, with the sixth carbon on a side arm; starch and cellulose are chains of glucose | rung 7, the stem built from sugar | chemistry texts |
| Chloroplasts gather on the cell's lit walls in weak light and move edge-on to the side walls in strong light; plants that can't do this bleach and die sooner in high light | rung 6 | [P1] |
| Young sunflowers follow the Sun from east to west and turn back at night; grown ones face east | rung 4 | [P2] |
| Cacti (CAM plants) open their stomata at night, store the CO₂ in their cells' vacuoles as an acid, and use it by day behind closed stomata | 5.T1, 8.T1 | [P5] |
| A water lily's floating leaves have stomata only on their upper side; air channels carry air down the stalk to the roots in the mud | 4.T2, 8.T3 | [P6] |
| Deciduous trees drop their leaves for winter (frozen ground gives no water; frost would burst the cells); chlorophyll fades and the yellow shows; stored starch becomes sugar for the buds in spring | 8.T2 | [P7][P8] |
| Giant-pumpkin growers keep one fruit per vine so all the sugar goes to it; peak gains of about 20 kg a day | 8.3 | [P9] |
| Plants are grown in space under red, blue and green LEDs | 7.T1 | [P10] |
| Van Helmont's willow: 5 lb grew to 169 lb in five years; the 200 lb of soil lost about 2 oz | 5.2, the scales | [P12] |
| Sizes (approximate, typical): leaf 0.1-0.3 mm thick; palisade cells about 15 µm wide and 50-80 µm tall with tens of chloroplasts; chloroplasts 5-8 µm; stomatal pores 10-30 µm long; a hair about 70 µm wide | the place's scale | textbook values; guard cells [P15] |

### 2.5 What the five tests need from the design (the research's verdict)

Choice comes from the three needs (autonomy, competence, relatedness [R29]; `engagement-and-child-psychology.md` §1.1),
from flow, curiosity and surprise, and from making and owning: the child chooses where to fly and when to act, gets better
visibly, and owns a plant and a garden. Mute comes from level design that teaches by placement [R27], implicit
scaffolding [R20] and a world that answers. Cheat comes from a simulation whose rules are the science [G3]. Transfer
comes from varied settings where the habit fails but the rule works. Wow must be the concept itself, never decoration
[G8].

### 2.6 The curriculum strand: the units this game replaces

The game covers the plant strand of our science units (NGSS and the UK and Singapore references in each unit). Each unit
below with its standards, its goals (from `data/school/gradeN.json`) and the ideas of its cards, and which rung and
voyage teaches each idea. **P1** marks a unit the game replaces for children once phase C ships it (its play level P1);
the cards stay as the Book.

| Unit | Standards | Its ideas (from the cards) | Taught by | After phase C |
|---|---|---|---|---|
| `g3.science.plants_needs` Plants: parts and needs | UK Y3 plants, SG P4 (preview) | parts and jobs (roots take in water and minerals, the stem holds up and carries water in thin tubes, leaves make food with sunlight, air and water, flowers make seeds, petals bring insects); needs (light, water, air, warmth, room, minerals; a cactus needs little water, a water lily lives in a pond); a fair test with three beans; water climbs a celery stick | rung 4 (4.1 parts and the water's climb, 4.3 petals and bees, 4.T1 cactus, 4.T2 lily); 5.T2 the three beans | **P1** (a grade 3 child plays rung 4) |
| `g4.science.plant_animal_parts` Plant and animal parts | 4-LS1-1 | the plant half: roots, stem, leaves, flowers, thorns, a cactus's thick waxy stem; the animal half: fur, shells, gills, heart, lungs, stomach, brain | rung 4 (the plant half) | **P1 for the plant half**; the animal half keeps G0's play until Body Quest or Living Island |
| `g5.science.plants_air_water` Plants grow from air and water | 5-LS1-1 | mass from air and water (van Helmont); leaves take in CO₂, roots take in water; light's energy turns CO₂ and water into sugar and oxygen; light is energy, air and water are material; soil gives a little mineral | rung 5 (5.1 doors, 5.2 the heavy head, 5.T1 desert night, 5.T3 pond bubbles) | **P1** |
| `g5.science.sun_energy_food` Energy from the Sun in food | 5-PS3-1 | animals need energy from food; plants make food with sunlight and store its energy; energy passes along a food chain; every meal's energy began as sunlight | rung 5 (5.3 a whole day: no light, no sugar; 5.4 seeds for a friend: the energy chain; 5.T2 the three beans) | **P1 mostly** (longer food chains: Living Island) |
| `g6.science.cells` Cells | MS-LS1-1, MS-LS1-2 | all living things are cells; Hooke's "small rooms"; membrane, nucleus, cytoplasm, mitochondria; plant cells also have a wall and chloroplasts; plant vs animal cells; cells → tissues → organs → organism; single-celled living things | rung 6 (all seven voyages; the visitor is an animal cell; the dive shows the levels of organisation) | **P1 mostly** (Hooke's history in the Book) |
| `g7.science.photosynthesis` Photosynthesis and respiration | MS-LS1-6, MS-LS1-7 | CO₂ + water + light → sugar + oxygen in chloroplasts; sugar stores light energy; respiration releases it in every living thing, plants too, day and night; mirror images; in the dark the store is used up; pondweed bubbles in light; a carbon atom's path from the air into your muscles | rung 7 (all; 5.T3 and 7.T1 too) | **P1** |
| `g8.science.transport_systems` Transport in plants and animals | SG S2, UK KS3, spiral from grade 5 | diffusion is enough for small things, big ones need tubes; xylem carries water and minerals up (root hairs take it in); phloem carries sugar up and down; transpiration through stomata pulls water up, fastest when hot, dry and windy; the animal half: heart, vessels, blood, lungs | rung 8 (the plant half) | **P1 for the plant half**; the animal half: Body Quest |
| `g7.science.atoms_molecules`, `g7.science.reactions` | MS-PS1-1, MS-PS1-5 | molecules from atoms (H₂O, CO₂, O₂); atoms rearranged, never lost; mass kept | rung 7 uses them (review events only) | stay P0 (their own game later) |
| `g7.science.energy_flow`, `g7.science.air_carbon_cycle` | MS-LS2-3, UK KS3 | matter cycles, energy flows; the carbon cycle; air is 0.04 % CO₂ | 7.5 the carbon ride, 7.T1 the Mars dome (review events) | stay P0 (Living Island, a climate game) |
| `g6.science.water_cycle`, `g4.science.states_of_matter`, `g5.science.particles`, `g5.science.reproduction_life`, `g3.science.fair_tests`, `g3.science.survival_habitats` | various | plants give off water vapour; evaporation; air is matter; pollination and seeds; fair tests; traits that help survival | touched by voyages (review events at most) | stay as they are |

Seven units become P1 in whole or in their plant half: `g3.plants_needs` (through rung 4), `g4.plant_animal_parts`
(plant half), `g5.plants_air_water`, `g5.sun_energy_food`, `g6.cells`, `g7.photosynthesis` and `g8.transport_systems`
(plant half). Their hand-written exercises (138 in all; fewer once the two split units' animal halves are left out)
stop being what a child meets; the game's beats are the evidence instead (§3.10).

---

## 3. The game

### 3.1 The fantasy and the purpose

**You are the only one small enough to help.** A plant can't tell you what's wrong; Size Magic (EasyCraft's own magic)
lets you go and look. The sunflower is *yours*: it lives in your garden, it changes because of what you did inside it, and
the garden grows with every voyage (a cactus from the desert, a water lily, a giant pumpkin for the fair, a tree that
sleeps through winter, wheat for the dome on Mars). The long purpose ties into EasyCraft's core loop (learn → gold → build
a rocket → fly): the colonies on Mars need plants for air and food, and the child who can run a leaf can make the dome's
garden thrive (7.T1).

**The guide** is Professor Hoot, DISCOVER's owl, who shrinks with you (a tiny blocky owl at your shoulder). He speaks;
nothing else in the plant does (ruling 4).

**The tone:** curious and calm, like a nature film you are inside. Funny in small ways (a ladybird lands on the leaf
above with a thump and a giant shadow; Hoot: "Just a ladybird. Hello up there!"). Never scary: no giant eyes, no
attackers, no dying plant.

### 3.2 Where it lives

- **Phase B:** a little garden terrace in its own place far above the world (like Life's rooms and G0's play arena), with
  its own sky. It opens from DISCOVER: the one unit it serves in phase B, `g5.science.plants_air_water`, shows the game's
  picture (a leaf with a sparkle) on the Science map, and its PLAY starts voyage 5.1 (§4.7 needs one hook from the lead).
- **Phase C:** the child's **Voyage Garden** stands in every home world beside the Discovery Academy (W1 stage 3), local
  to each child like the discovery crystals. Walking up to a plant and touching a leaf starts its voyages; **the garden is
  the map** (each plant is a door to its voyages) and a **depth dial** (ant, cell, inside a cell, atoms, whole plant: five
  pictures) picks the rung.
- **Phase D:** with Size Magic's TINY on, touching any sunflower in the world starts a voyage there; friends can visit each
  other's gardens and voyage together.

### 3.3 The core loop

| Every | The child | The world answers | Example (voyage 5.1) |
|---|---|---|---|
| **10 seconds** | one act with the hands: open or close a door, catch or carry, turn, place | at once, in sound and sight | squeeze a door shut: a soft squeak, the mist at that door stops, the cell beside it plumps |
| **minute** | one beat: a weather turn handled, a sugar finished and delivered, a cell refilled | the leaf changes: it lifts, brightens, the bud above fills | a cloud slides over the sun: open the doors; air puffs drift in; the green workshops light up; gold sugar pops out |
| **10 minutes** | one voyage | the real plant changes for good, outside, at normal size | the sunflower stands tall, its flower opens, a bee lands; the plant's scale goes up, the soil's doesn't |
| **days and weeks** | the ladder and the garden | Size Magic goes deeper each grade; the garden grows; friends visit (phase D) | next: the heavy head (what builds a plant?), a whole day and night, the desert at night |

The rhythm inside a leaf alternates the child's two jobs: **in the cloud, open the doors and let the air in; in the
blaze, close them and carry the sugar.** The weather is the music; the child plays along.

### 3.4 The verb is the concept

Every idea has the verb that *is* it, and a world that makes guessing lose.

| Idea | Verb | What the world does | Why guessing loses |
|---|---|---|---|
| Leaves take in air (CO₂) through their doors | **open** a door when the leaf needs air | puffs of air waiting outside drift in and float to the working cells | opening in the blaze pours out water: the leaf sags |
| The same doors let water out | **close** the doors in the heat | the blue mist stops; the vein refills the cells; the leaf lifts | random doors leave some open: the mist keeps pouring |
| The trade-off: air in costs water out | **time** the doors to the weather | a cloud's shadow, a cool breeze and quiet cicadas say "cool now"; the blaze says "close" | the beats are judged by contrast: doors more open in the cloud than in the blaze, the leaf never drooping |
| Light is the energy, not a material | **work in the light**; at night, keep the doors shut (no point letting water out) | in the dark the air is there and nothing is built | opening at night wastes water; that shows the idea is missing |
| Sugar is built from air and water with light | **build**: rung 5 watches the workshops build when all three are there; rung 7 places the carbon atoms itself | no input, no sugar; the world can't be talked into it | soil, oxygen or water alone build nothing |
| The plant's body comes from that sugar, not the soil | **build the stem** with what works (5.2) | soil grains bounce off the root's skin; fertiliser adds a violet pinch; water passes through and leaves by the doors; only sugar becomes new stem | three materials, three needs, six calls: a guesser fails |
| Sugar travels in its own tubes to where it's needed | **carry** sugar to the gold pipe (rung 5), **route** it to buds, roots, fruit or the store (rung 8) | sugar dropped in the blue water pipe bobs back up; a starving bud stays shut | the wrong pipe or the wrong place doesn't work |
| Cells hold the plant up by water pressure | **fill** the cells' water balloons (rung 6) | full balloons press the walls: the leaf stands; empty: it sags | water flows from the wetter cell to the drier one: a gate opened towards a drier neighbour empties the balloon instead |
| Chloroplasts catch light; too much burns | **turn** them face-on in dim light, edge-on in blazing light (rung 6) | dim: more sugar; blazing and face-on: they bleach pale | random turning gets too little sugar or bleaching |
| Respiration releases the sugar's energy, day and night, in plants too | **feed** the power stations sugar and oxygen (rungs 6-7) | gold sparks come out and power the cell's work; CO₂ goes out | burn the store too early and the morning has nothing |
| Atoms are rearranged, never lost | **build** sugar from exactly the atoms of 6 CO₂ and 6 H₂O; the spare oxygen leaves as O₂ (rung 7) | a ring with a missing atom won't close; atoms can't be thrown away; the balance shows in = out | the world enforces it |
| CO₂ is rare in air (0.04 %) | **catch** the rare CO₂ among the crowd of nitrogen (rung 7) | nitrogen pairs are useless to the builder | grabbing at random grabs nitrogen |
| Water is pulled up from the top | **keep the water rope whole**: open doors pull, heat and wind pull harder, drought snaps it (rung 8) | the rope rises or breaks with air bubbles | open-all-the-time snaps it in a drought |
| Sugar goes from sources to sinks | **route** by need (rung 8) | the bud, the root tip and the pumpkin grow where sugar goes | sending everything to one place starves the rest |
| Adaptations change *how* the rule is used | **apply the rule in a new world** (transfer) | desert: cool only at night; lily: doors on top; winter: no leaves, live on the store | the habit from the sunflower fails |
| Levels of organisation | **dive to the right depth** to find a problem (rung 6's plant doctor) | the fix is at one level only | random dives find nothing |

### 3.5 The first voyage, beat by beat (5.1 *The Drooping Sunflower*, the phase B slice)

Pictures: `leaf-voyage/01-garden-before-after.png`, `02-the-dive.png`, `03-inside-the-leaf.png`, `04-doors-and-weather.png`.

**The garden** (normal size, a sunny terrace in the sky): a sunflower in a terracotta pot, about the child's height,
drooping, its flower still a closed bud; the soil cracked and pale; a watering can on the grass; two little block-scales
by the pot (gold blocks for the plant's weight, brown for the soil's); cicadas; heat shimmer; Professor Hoot lands on the
fence.

1. **The hook (0:00).** Hoot: "Oh no! Our sunflower is drooping in the heat." The watering can glows. If the child does
   nothing for 6 s, the ghost (a finger flat, hands in VR) shows the can. The child waters the soil (flat: a tap and the
   can pours by itself; VR: lift it and tilt it). The soil darkens. It still droops. Hoot: "Good! But it still droops.
   Let's look inside!" The biggest leaf glows.
2. **The dive (0:20).** The child touches the leaf: Size Magic's sparkle and sound, then a rising chime at each step:
   ×10 (a ladybird like a bus), ×100 (a leaf hair like a glass tree), ×1,000 (the leaf's skin cells like paving stones,
   its doors like lips), and a last one at ×85,000 (a door as big as a gate). Flat: the camera rushes down onto the leaf;
   VR: the garden grows around the child's feet (the child never moves; the world does). Hoot, tiny now: "Smaller...
   smaller... we're tinier than a hair!" Under the leaf: a huge green ceiling with dark slits, blue mist pouring down out
   of them. Hoot: "Up through a door! Let's go in."
3. **Inside (0:32).** A green cathedral: round cells like soft balloons, tall columns above them, light pouring through a
   glass roof, Bach's *Air* coming in softly. But the cells sag and wrinkle, the green workshops inside them are dim, and
   mist drifts to the doors in the floor and pours out. Hoot: "Look! The water is escaping through the doors."
4. **Act 1: close the doors (0:40-1:40).** The ghost squeezes one door shut (its two green guard cells press together; a
   squeak and a sigh; the mist there stops). Hoot: "Squeeze the doors shut. Your turn!" The child closes the other five.
   Each closed door: blue drops run from the vein's blue pipe into the cells nearby, which plump up with a soft "bloop".
   After the child's first door: "Yes! The water stays in now." All closed: a deep rising swell, the cave tilts up (the
   leaf lifts), and through the roof the sunflower's head rises. Hoot: "The cells are full. The sunflower is standing up!"
   then, the see-why line: "Open doors let water out. Closed doors keep it in."
5. **Act 2: the trap (1:45).** The workshops stay dim. Hoot: "The green workshops have stopped. They need air." Outside the
   closed doors, little grey puffs bump against them, trying to get in. If the child opens a door now, in the blaze, mist
   pours out and the nearby cells sag: "Too hot! The water rushes out." (No failure screen: the child closes it.) If the
   child waits 6 s: "Wait for the sun to hide."
6. **The first cloud (2:05).** A cloud's shadow sweeps over the roof; the light softens to blue-green, the cicadas stop, a
   cool breeze sighs. Hoot: "A cloud! It's cooler now. Open the doors!" Air puffs drift in, float up into the cells, and
   the workshops light up; the first gold sugar pops out with a ding. Hoot: "Air plus light makes sugar. The plant makes
   its own food!" Once the child has opened and closed several doors: "Scientists call these doors stomata."
7. **The blaze returns (2:25).** The light snaps bright, the cicadas start, the heat shimmers. "Sun's back! Close the
   doors!" (voiced this once only). While the doors are shut the sugar waits at the workshops; the ghost carries one gold
   hexagon to the gold pipe of the vein (a whoosh: it zooms away towards the bud). Hoot: "Carry the sugar to the gold
   pipe." The bud's dark silhouette above the roof glows a little.
8. **The rhythm (2:40-5:00).** Three more cloud-and-blaze turns, now **silent**: only the shadow, the breeze and the
   cicadas tell the child. Clouds: open the doors, the air comes in, sugar pops out. Blazes: close the doors, carry the
   sugar. Hoot praises the strategy, not the child ("You waited for the cloud. Clever!", "Closed before the heat. Like a
   real plant!", "Your sugar is on its way!"). Sugar dropped in the blue pipe bobs back up: "That pipe brings water in.
   Sugar goes in the gold one."
9. **The bud fills (about 5:00).** Twelve sugars delivered: the silhouette above glows gold. Hoot: "The bud is full! Let's
   grow back and see!" The reverse dive (3 s).
10. **The world answers (5:10).** The garden in the evening light, crickets starting. The sunflower stands tall; the bud
    opens slowly, petal by petal, to Tchaikovsky's *Waltz of the Flowers*; a bee flies in and lands. Hoot: "Look! It's
    standing tall... and it's opening!" The scales: two new gold blocks on the plant's; the soil's the same. "The plant
    got heavier. The soil didn't." Then the idea of the whole game: **"Every petal was built from air you let in!"** And
    the honest end: "Real sunflowers work their doors all by themselves. Now you know how!"
11. **The end card (5:40).** Pictures only: the sunflower, the unit's stars, the gold (+ coins), and three buttons as
    pictures (↻ again, ▶ next voyage, a door: back). Hoot: "Wonderful work! Another voyage?"

A child who plays well takes about 6 minutes; a slower child about 8 (the bud asks for more clouds when it isn't full:
up to six turns in all). Nothing ever fails for good: a leaf that dries too far is caught by Hoot ("The leaf is too dry!
Close the doors.") and the ghost helps (that beat counts as helped).

**The leaf's rules for 5.1** (the starting numbers for phase B's `LeafSim`, from the phase A model
`leaf-voyage/model/voyage_5_1_model.py`):

| Quantity | Rule (per second) | Start values |
|---|---|---|
| Doors | 6 in the floor; each open or shut; a tap or a squeeze takes 0.5-0.8 s with the reach | all open (Act 1) |
| Weather | blaze: heat 1.0, light 1.0; cloud: heat 0.25, light 0.7; evening: heat 0.2, light 0.4; night: 0, 0. Act 2: the trap blaze (14 s), then four turns of a cloud (20 s) and a blaze (15 s), then the evening (10 s); turns 2-4 are silent and judged | noon blaze |
| Leaf water W (0-1) | + 0.035 × (1.05 − W) from the vein (watered soil) − open doors × 0.006 × (0.10 + heat) − 0.0006 through the skin | 0.95 at the start of Act 2 (Act 1 starts at 0.5, drooping) |
| Droop | W < 0.55: the leaf sags (seen inside and outside); W < 0.35: too dry, sugar at 30 %, Hoot steps in | |
| Air inside C (0-1) | rises with the open doors' share, falls as the workshops use it | 0 |
| Sugar | 0.35 × light × min(C / 0.5, 1) × (1, or 0.3 when too dry) hexagons per second | 0 |
| The bud | needs 12 hexagons through the gold pipe; fills only while the leaf stands (W ≥ 0.55) | 0 |

### 3.5b The desert night, beat by beat (5.T1, the phase B transfer voyage)

It opens after 5.1 (the voyage board's second stop). Picture: `leaf-voyage/10-transfer-worlds.png` (left).

1. **The hook (0:00).** Hoot carries a little cactus pot onto the terrace: "A cactus from the desert! It's hot and
   thirsty." The terrace turns into a dune at noon (the Sandstorm Desert's sand and light, a white-hot sun, heat shimmer,
   the desert's day music). No watering can: the sand is dry. The cactus's green stem glows (cacti build sugar in their
   stems; their spines are their leaves).
2. **The dive (0:15).** "Let's look inside its green stem. Size Magic!" Inside, the leaf's place re-dressed: a thick waxy
   roof, fewer doors sunk in little pits, big pale water-store cells, the green workshops in the outer cells, and empty
   glass jars inside the cells (the vacuoles, where a cactus keeps air).
3. **The first day (0:30-1:30).** "Phew, it's baking! Keep the doors shut." The doors start shut. A child carrying the
   sunflower's habit waits for a cloud; none comes. After 12 s, once: "No clouds in the desert. When does it cool down?"
   (a frame for the problem, not a hint after a miss). A door opened in the blaze pours out a great plume of mist and the
   cells shrink fast (L13). **Beat Day 1:** at most 2 doors open in the day's second half and the cactus never below
   0.55.
4. **Dusk and the first night (1:30-2:45).** The sky goes orange, then deep blue with stars; the shimmer stops; a cool wind
   and crickets; the desert's night music. "The sun is setting. Feel that cool air?" The light is gone, so the workshops
   are dark. The child opens the doors: air puffs drift in and, with no light to build with, float into the jars, which
   fill with a soft violet-green glow. "The cactus keeps the air in jars for tomorrow!" (see why). **Beat Night 1:** at
   least 3 doors open for half the night or more.
5. **Dawn (2:45).** The sky pales and the heat climbs over 8 s. **Beat Dawn 1:** all but 2 doors shut by the end of the
   dawn, the cactus never below 0.55.
6. **The second day (3:00-4:00).** Doors shut, sun up: the jars pour their air into the workshops and sugar builds behind
   shut doors. "Doors shut, and it still builds. Clever cactus!" The child carries the sugar to the gold pipe (to the bud
   at the cactus's top). **Beat Day 2** as Day 1.
7. **The second night and dawn (4:00-5:15):** **Beats Night 2, Dawn 2** as before.
8. **The world answers (about 5:30).** The reverse dive into the desert night: the cactus's bud opens into a big white
   flower under the moon (Beethoven's *Moonlight*), and a moth visits. "A flower that opens at night. The desert's
   secret!" Then the rule in words, after the child has used it: "Desert plants open their doors at night, when it's
   cool." End card; "You helped a desert plant, like a real botanist!"

**Its six beats** (Day 1, Night 1, Dawn 1, Day 2, Night 2, Dawn 2) are `SkillShown.NEW_SETTING` events for
`g5.science.plants_air_water` when passed without help (HELPED or SHOWN otherwise): a full round of six, kept apart as
transfer. **Its rules** (from `leaf-voyage/model/desert_night_model.py`): day heat 1.3 and light 1.0, the dawn ramping
over 8 s; night heat 0.05 and light 0; water from the dry sand + 0.012 × (1.05 − W); the waxy skin − 0.0004; open doors −
0.006 × (0.10 + heat) each; at night each open door adds 0.06 a second of stored air to the jars (up to 8 sugars' worth);
by day the workshops build 0.35 × light a second from the jars; the voyage is won with at least 6 sugars and the cactus
never below 0.55; days and nights 30 s each (day, night, day, night, day). The sunflower's habit (open by day) dries the
cactus every time; the cool-night rule wins every time (§3.9).

### 3.6 The ladder across grades 4-8

Each rung is a place, a depth of Size Magic, its verbs and its voyages (3-8 minutes each). The grade (DISCOVER's) picks the
child's rung after the prologue (5.1, everyone's first voyage); every rung stays open to everyone (curiosity is welcome,
ruling 28). Inside a rung the voyages unlock one after another; transfer voyages (T) come after their idea. Picture:
`leaf-voyage/06-the-ladder.png`.

**Rung 4, Plant Explorer** (grade 4, and grade 3's plants unit; ant-sized, ×50-300: the sunflower is a skyscraper).
Units: `g4.plant_animal_parts` (plant half), `g3.plants_needs`.
- *4.1 Up the Stem:* down in the root cave, root hairs like curtains drink from wet soil; the child drips blue dye into the
  water and flies up beside the stem as blue lines climb inside its skin (the celery test, played); for the last stretch
  Size Magic takes them deeper for a moment, into one tube, to ride the blue water into the leaf, which lifts. Verb: guide
  water from soil to leaf; a cut tube stops it (the leaf above wilts). See why: "Roots drink. The stem's tubes carry the
  water up."
- *4.2 Chasing the Sun:* a young sunflower turns to follow the sun, east to west, and back at night [P2]; the child turns
  leaves so none shades another (the board game Photosynthesis's idea). See why: "Leaves catch light to make the plant's
  food."
- *4.3 The Bee's Visit:* ride a bumblebee (Flight of the Bumblebee) from flower to flower; bright petals and nectar bring
  it; pollen carried makes seeds. See why: "Petals bring bees. Bees carry pollen. Pollen makes seeds."
- *4.T1 The Cactus Stem* (the Sandstorm Desert): the cactus stores rain in its thick stem and its wax keeps it in; fill
  the store in a short rain, survive the dry days. *4.T2 The Water Lily* (a pond): the leaves float, the stalks are long,
  the doors are on top.
- Harder: from one need at a time to two (water and light), then a new plant.

**Rung 5, Built from Air** (grade 5; cell-sized, about ×85,000: the child is about 18 µm tall, the size of a door).
Units: `g5.plants_air_water`, `g5.sun_energy_food`.
- *5.1 The Drooping Sunflower* (§3.5): the doors, air in and water out, sugar to the bud.
- *5.2 The Heavy Head:* the flower's head is heavy with seeds and the stem bends; it must grow thicker. Outside, a bag of
  fertiliser (a leaf-and-spoon picture), the soil and the can; inside the stem, the builders wait. The child tries what
  builds: soil grains bounce off the root's skin, fertiliser gives a violet pinch (it turns a pale workshop greener: a
  mineral's real job), water fills cells and passes on and out of the doors, **only sugar from the leaves snaps into new
  stem blocks**. Then the builders call (six calls: "new wall!", "a pale workshop!", "a thirsty cell!") and the child
  brings sugar, a mineral or water. The scales: the plant's gold blocks rise, the soil's stay. See why: "The stem is built
  from sugar. The sugar is built from air!" Science name: "The green workshops are chloroplasts."
- *5.3 Sunrise to Starlight:* a whole day: dawn (doors open with the light, Grieg's *Morning Mood*), the noon blaze, the
  afternoon clouds, dusk (the doors close by themselves in the dark), night: open a door and air comes in, but nothing is
  built. The store's glow carries the night. See why: "No light, no sugar. Light gives the energy." Science name: "This
  is photosynthesis: building with light."
- *5.4 Seeds for a Friend:* the seeds fill with sugar; a buddy eats them and runs, gold sparks in every step; the child
  follows the sparks back: buddy → seed → leaf → Sun (an order made with the hands). See why: "The energy in every meal
  started as sunlight."
- *5.T1 The Desert Night* (phase B; §3.7): a cactus where the day has no clouds. *5.T2 The Three Beans* (a dark cupboard):
  three pots, one without light, one without water, one with both; the child sets up the fair test, then dives into the
  dark one: air and water but no building. *5.T3 The Pond Bubbles:* pondweed under water; move the lamp closer and the
  oxygen bubbles come faster.
- Harder: from voiced cues to silent ones; shorter cloud windows; more doors; then a day with night; then new plants.

**Rung 6, One Cell** (grade 6; inside a palisade cell, about ×500,000: the cell is a palace, a chloroplast the size of a
car). Unit: `g6.cells`. Picture: `08-one-cell.png`.
- *6.1 The Water Balloon:* the vacuole (a huge water balloon) presses the cell's soft skin against its stiff wall; on a hot
  day it shrinks and the cell sags; the child opens the skin's water gates on the side of the wetter neighbour (by the
  vein), never towards a drier one (water flows from wet to dry), and the cell stands. See why: "Full of water, the cell
  pushes its wall. That's why plants stand."
- *6.2 Lanterns in the Light:* in dim light, gather the chloroplasts to the lit wall, face-on; when the light blazes, turn
  them edge-on and move them to the side walls or they bleach [P1]. A second trade-off, real.
- *6.3 The Builders' Plan:* the nucleus lights up its plan (a picture of the new wall); the child builds the wall from sugar
  blocks (cellulose is sugar chains) and the cell divides: the plant grows. See why: "The nucleus holds the plan. The
  wall is made of sugar."
- *6.4 The Power Stations:* at night the mitochondria need sugar and oxygen to power the cell's work; gold sparks come
  out, CO₂ goes out. See why: "Plants breathe out CO₂ too, day and night."
- *6.5 Deeper and Deeper (the plant doctor):* a patient plant with a symptom (pale leaves, a wilt, no flowers); dive to the
  right level (organ, tissue, cell, chloroplast) and fix it there. Hoot sometimes gets it wrong on purpose (opens the doors
  in the blaze; dives too shallow) and the child stops him (the protégé effect [R22]).
- *6.T1 The Visitor:* an animal cell floats in: no wall (it can't stand up), no chloroplasts (it can't make sugar); the
  child helps it with sugar from the plant. *6.T2 The Onion:* underground cells with no chloroplasts: why not here?
- Harder: two balances at once (water and light), then diagnosis.

**Rung 7, Atom Builders** (grade 7; molecule-sized, about ×2,000,000,000: atoms like footballs; the chloroplast is a
city). Unit: `g7.photosynthesis` (reviews for `g7.atoms_molecules`, `g7.reactions`, `g7.energy_flow`,
`g7.air_carbon_cycle`). Picture: `11-atom-builder.png`.
- *7.1 Catching Carbon:* outside the door the air is a crowd of nitrogen pairs and oxygen pairs; a CO₂ (one black carbon,
  two red oxygens) drifts past rarely (4 in every 10,000). Catch them and bring them in.
- *7.2 Light Sails:* the green sails (thylakoids) catch light; the light splits water: oxygen leaves in pairs (O₂), the
  hydrogens come away charged gold.
- *7.3 Six Carbons:* each CO₂'s carbon snaps onto the chain with charged hydrogen; one O₂ leaves for each; at six carbons
  the chain curls into the ring (5 carbons and an oxygen, the sixth carbon on its arm): glucose, glowing. A balance shows
  the atoms in and out: the same.
- *7.4 Night Shift:* by day build more rings than the cell burns and stack the spare as starch chains; at night unhook
  rings for the power stations (ring + O₂ → CO₂ + water + gold sparks). Survive to dawn with the cell's work done. See why:
  "Photosynthesis stores the energy. Respiration lets it out."
- *7.5 The Carbon Ride:* ride one carbon atom: air → leaf sugar → a grain → a buddy's muscle → breathed out → air.
- *7.T1 The Mars Dome:* the colony's crew breathes out CO₂; the dome's wheat under red and blue lamps builds sugar and gives
  oxygen [P10]; balance the dome (how many plants a crew needs; green lamps barely work: green bounces off leaves). *7.T2
  The Bread Rises:* yeast in dough burns sugar and the dough fills with CO₂ bubbles (respiration in a fungus).
- Expert secret (a bonus round): "The oxygen comes from the water!" (the 1941 heavy-oxygen experiment [P14]).
- Harder: one station, then two, then all four with the day clock.

**Rung 8, The Whole Plant** (grade 8; the plant as a map of roads, with rides down into its pipes). Unit:
`g8.transport_systems` (plant half; reviews for `g6.water_cycle`).
- *8.1 The Water Rope:* water is a rope pulled up from the top by the doors; hot, dry and windy pulls harder; a drought
  snaps it with air bubbles; keep it whole.
- *8.2 Sugar Roads:* route sugar from the leaves (sources) to the buds, root tips, flowers and the store (sinks), up and
  down.
- *8.3 The Giant Pumpkin:* for the fair: send the sugar to one pumpkin (growers keep one per vine [P9]) without starving
  the roots that drink for it.
- *8.4 Root Hairs:* more hairs drink more, but each costs sugar to grow.
- *8.5 Design a Plant* (making): choose leaf size, door count, root depth and store size; test it in the meadow, the
  desert, the pond, the winter or the Mars dome; share it with a friend (phase D).
- *8.T1 The Cactus's Secret* (CAM complete), *8.T2 The Winter Tree* (autumn: send the sugar to the store before the leaves
  fall; winter: frozen ground, no leaves, live on the store; spring: the store becomes the source and sugar goes *up* to
  the buds [P7][P8]), *8.T3 The Lily's Breath* (doors on top; send air down the stalk to the roots in the mud [P6]).
- Harder: whole seasons, several sinks, then design.

### 3.7 Minute 1, 5 and 30 of a first session

| | Flat (phone, tablet, PC, the web) | VR (the Quest 3) |
|---|---|---|
| **Minute 1** | The terrace: the drooping sunflower, cicadas, Hoot on the fence speaking. The can glows; the child taps it and it pours. Still drooping. A tap on the leaf: the camera rushes down the leaf, a chime at each step; tiny now, under a green ceiling with mist pouring out of dark slits; a tap on a door and the child glides up into the leaf. | The sunflower is as tall as the child. The child picks up the can by the handle and tilts it; water splashes the soil. They touch the leaf with a hand: the garden grows around their feet until the leaf is a ceiling far above. They pull themselves up with their arms (thick air: they stop when they stop) into a door. |
| **Minute 5** | Second silent turn of Act 2: a cloud's shadow; the child taps three doors open (the camera glides between them), air puffs float up, sugar pops; the sun blazes; four taps close the doors; tap a sugar to pick it up, tap the gold pipe to send it. The bud above the roof glows half full. Hoot: "Closed before the heat. Like a real plant!" | The child swims between doors and pulls each pair of guard cells apart with both hands as the cloud comes; they squeeze them shut as the light snaps bright; they grab gold hexagons and push them into the gold pipe's mouth (a whoosh, a buzz in the hand). Hoot flies at their shoulder. |
| **Minute 30** | Four voyages done: the sunflower bloomed (5.1); its stem grew thick from sugar, and the soil test showed what builds a plant (5.2); a whole day and night went by and the workshops stopped in the dark (5.3); a cactus arrived from the desert: no clouds, so the child waited for the night, opened the doors under the stars, saw the air kept in jars, closed them before dawn, and the cactus built sugar behind shut doors; on the second night its white flower opened to the *Moonlight* sonata (5.T1). The end card shows two stars on "Plants grow from air and water". | The same voyages, with the hands: tilting the can, pressing the soil test's grains against a root, cupping the jars as they fill in the desert night, standing under the cactus flower as it opens above their head. |

### 3.8 Show, say, do (rule 0)

**Shown, not told.** Each new act is shown once by the ghost (Life's ghost finger flat, ghost hands in VR), then "Your
turn!": the can, the first door, the first sugar to the pipe, the first jar in the desert. After two misses the ghost does
one more step (the beat counts as helped). The eye (SHOW ME) does one step any time (helped). Idle 10 s: everything that
can be touched glows for 3 s (never only the right one: no help).

**Every voice line of phase B** (Professor Hoot, read by the system's voice through `PlayVoice.say`; each line cuts in;
at most 12 words):

| # | When | Line |
|---|---|---|
| L1 | 5.1 opens | Oh no! Our sunflower is drooping in the heat. |
| L2 | soil watered | Good! But it still droops. Let's look inside! |
| L3 | the leaf glows | Touch the leaf. Size Magic! |
| L4 | the dive | Smaller... smaller... we're tinier than a hair! |
| L5 | under the leaf | Up through a door! Let's go in. |
| L6 | inside | Look! The water is escaping through the doors. |
| L7 | after the ghost's door | Squeeze the doors shut. Your turn! |
| L8 | the child's first door | Yes! The water stays in now. |
| L9 | hint after two misses | Squeeze the two green sides together. |
| L10 | all doors shut | The cells are full. The sunflower is standing up! |
| L11 | see why | Open doors let water out. Closed doors keep it in. |
| L12 | Act 2 | The green workshops have stopped. They need air. |
| L13 | a door opened in a blaze | Too hot! The water rushes out. |
| L14 | waiting 6 s in the blaze | Wait for the sun to hide. |
| L15 | first cloud (voiced once) | A cloud! It's cooler now. Open the doors! |
| L16 | first sugar (see why) | Air plus light makes sugar. The plant makes its own food! |
| L17 | after several doors | Scientists call these doors stomata. |
| L18 | first blaze of Act 2 (voiced once) | Sun's back! Close the doors! |
| L19 | the ghost carries sugar | Carry the sugar to the gold pipe. |
| L20 | sugar in the blue pipe | That pipe brings water in. Sugar goes in the gold one. |
| L21 | the bud full | The bud is full! Let's grow back and see! |
| L22 | the bloom | Look! It's standing tall... and it's opening! |
| L23 | the scales | The plant got heavier. The soil didn't. |
| L24 | the idea | Every petal was built from air you let in! |
| L25 | honesty | Real sunflowers work their doors all by themselves. Now you know how! |
| L26 | the end card | Wonderful work! Another voyage? |
| L27 | too dry | The leaf is too dry! Close the doors. |
| D1 | 5.T1 opens | A cactus from the desert! It's hot and thirsty. |
| D2 | the dive | Let's look inside its green stem. Size Magic! |
| D3 | inside, the blaze | Phew, it's baking! Keep the doors shut. |
| D4 | waiting 12 s for a cloud (once) | No clouds in the desert. When does it cool down? |
| D5 | dusk | The sun is setting. Feel that cool air? |
| D6 | the first jar fills (see why) | The cactus keeps the air in jars for tomorrow! |
| D7 | building behind shut doors | Doors shut, and it still builds. Clever cactus! |
| D8 | the night flower | A flower that opens at night. The desert's secret! |
| D9 | see why (the transfer rule) | Desert plants open their doors at night, when it's cool. |
| D10 | the end | You helped a desert plant, like a real botanist! |
| P1-P7 | praise (strategy and effort, one at a time, never twice in a row) | You waited for the cloud. Clever! · Closed before the heat. Like a real plant! · Your sugar is on its way! · Great timing! · The leaf is happy and full. · You're getting really good at this! · Hoo hoo! Well done! |
| G1-G5 | the place's own | (break) Need a rest? The triangle goes on, the door stops. · (Back) Leave the voyage? The sunflower will wait for you. · (a ladybird lands) Just a ladybird. Hello up there! · (Hoot shrinks) I'm a tiny owl! Don't sneeze! · (first view inside) It's like a green cathedral! |

Each later voyage carries its hook line and its see-why line (§3.6 gives them); phase C writes the rest to the same rules.
Without a voice (Read to me turned off by a grown-up, or no English voice on the device) the lines show as words (G0's
ruling 28).

**Pictures and colours that carry meaning** (picture: `07-things-and-colours.png`). Shape and motion carry each meaning
too, so nothing depends on colour alone.

| Thing | Rungs 4-6 | Rung 7 (the truth underneath) | Its sound |
|---|---|---|---|
| Water | bright blue drops; escaping as pale blue mist | one red oxygen with two white hydrogens, bent | drips, a glug as it climbs |
| Air the plant needs (CO₂) | a grey puff with a dark core and two red dots | a black carbon between two red oxygens, straight | a soft pop on arrival |
| Oxygen | pink-white bubbles leaving | two red oxygens joined | a bubble as it leaves |
| Sugar | a honey-gold hexagon that glows (it holds light's energy) | a ring of 5 carbons and an oxygen, the sixth carbon on an arm; a chain of rings is starch | a bright ding; a chord when a ring closes |
| Light | gold sparks streaming from the roof | gold sparks | a shimmer |
| Minerals | violet sparks, tiny | — | a tick |
| The doors (stomata) | two bean-shaped green guard cells around a dark slit | — | a squeak and a sigh (closing), a breath (opening) |
| The workshops (chloroplasts) | green glowing discs inside the cells | green sails stacked like coins | a hum when working |
| The power stations (mitochondria) | orange capsules with folded lines | — | a warm thrum |
| The cell's water balloon (vacuole) | clear blue, filling the cell | — | a soft bloop as it fills |
| The vein | a blue glass pipe (water in) beside a gold pipe (sugar out) | — | a whoosh into the gold pipe |
| Heat, cool, wind, night | heat shimmer and cicadas; a cloud's shadow, quiet and a breeze; ripples and a whoosh; dark blue and crickets | | |

**Sounds and music** (all already in the repo, public domain or CC0, `assets/CREDITS.md`): Bach's *Air* inside the leaf,
the *Waltz of the Flowers* for the bloom, Beethoven's *Moonlight* for the desert night, Grieg's *Morning Mood* at dawn
(5.3), *Flight of the Bumblebee* (4.3), Vivaldi's *Winter* (8.T2), the desert's day and night music (5.T1); the owl's calls
for Hoot, the sparkle for Size Magic, crickets, wind, drips, the brook, bubble pops, the ding and the chime. New sounds
(the doors' squeak and sigh, the cells' bloop, the gold pipe's whoosh, cicadas) are made by a tool like
`tools/make_tiny_sfx.py`: original, so CC0 by construction.

**Words on the screen during play: none.** The HUD shows only pictures (G0's glyphs: the ear repeats Hoot's line, the eye
is SHOW ME, two bars are a break). The end card shows numbers (the gold) and stars. Each thing says its name when
touched ("a door", "sugar"), spoken. The science names are spoken once, after the child has used the thing (rule 2: play
first, words after), and live in the Book.

### 3.9 The five tests, answered

**Choice.** What a 9-14-year-old chooses, and how this game gives it: *movement* (flying in a giant world; in VR, Gorilla
Tag's arm movement, which the owner's child already loves [R25]); *a living thing that thrives because of you* (the
sunflower visibly stands and blooms; later the garden); *getting good* (the silent turns become a rhythm the child
masters; Hoot's praise names the strategy); *surprise* (the dive, the ladybird, the cactus flower, the giant pumpkin);
*making and owning* (the garden; designing a plant at rung 8); *friends* (postcards of the bloom; visiting gardens and
voyaging together in phase D); *short* (6-8 minutes, then "another voyage?"). Risks: tasks can feel like chores (the
answer: the weather keeps changing, each voyage brings a new verb or place, and the plant's change is big); a slow child
on a phone may struggle (the answer: the windows lengthen after misses, §3.10). **How we check:** the owner's child plays
phase B; we note voluntary time, whether a second voyage is started unasked, whether the child returns another day, and
what they say to a friend. A game nobody returns to is redesigned before phase C.

**Mute.** Nothing in the voyage needs reading: the problem (mist pouring, cells sagging, the plant drooping) is seen; the
fix (a door's two green halves) is shown by the ghost once; the result (mist stops, cells plump, the leaf lifts) is
seen and heard; the weather is shadow, light, sound; the goal (the bud) is a shape above the roof that fills with gold.
**How we check:** a test that the screen shows no word while a voyage plays (`PlayHud.screen_words()` = 0); every line
spoken by itself (`PlayVoice`); the owner's child plays with text hidden.

**Cheat.** The leaf is a simulation whose rules are the science: doors that are wrong for the weather dry it out or starve
it. The beats are judged by outcome *and* contrast: a blaze is passed when the leaf never droops and by the blaze's second
half at most two of six doors are open; a cloud is passed when at least two sugars are built in it and the doors are open
at least 40 percentage points more than in the blaze before (§3.10). The phase A model
(`leaf-voyage/model/voyage_5_1_model.py`, 1,000 runs per player, the six silent turns judged as the design judges them;
the mastery bar is 5 of 6):

| Player | Reaches 5 of 6 (flat) | (VR) | What happens |
|---|---|---|---|
| Knows the rule (reacts in about 1.5 s) | **100 %** | **100 %** | 6 of 6; 12.8 sugars; the leaf never below 0.66 |
| Knows the rule but slow (4 s, 0.8 s a door) | 72 % | 100 % | the fairness check: knowledge decides; on a phone speed matters a little (ruling 25 lengthens the windows) |
| Taps doors at random | **0 %** | **0 %** | about 0.6 of 6 (one beat in ten, by luck) |
| Always open (the greedy "more air, more sugar") | 0 % | 0 % | more sugar (20) but the leaf dries four times |
| Always closed | 0 % | 0 % | 3 of 6 (the blazes); builds nothing |
| Opens whenever it's bright | 0 % | 0 % | dries three or four times |

**Transfer.** Each idea comes back somewhere new, where the habit fails and the rule works. The phase A model of the desert
night (`leaf-voyage/model/desert_night_model.py`, 500 runs, its six beats judged as §3.5b judges them): the understood
rule ("open when it's cool": at night, and keep the air) passes 6 of 6 every time (**100 %**); the sunflower's habit
(open by day) passes none and dries the cactus (**0 %**); random taps about 1 of 6, always-closed 4 (it never opens at
night) and always-open 2: none reaches 5 of 6 (**0 %**). The other
transfers: the dark cupboard (light is the energy), the pond (light makes oxygen), the animal cell and the onion (what a
cell has and why), the Mars dome (the balance of breathing and building), the bread (respiration elsewhere), the water
lily (doors on top), the winter tree (the store becomes the source), the giant pumpkin (one sink). The first solve without
help in a new setting is recorded as `SkillShown.NEW_SETTING`.

**Wow.** The dive (the garden growing around you; in a headset, breath-taking); the green cathedral with light pouring
through the roof; the leaf lifting when its cells fill; the bloom with a bee; the cactus flower opening under the stars.
Each wow *is* the concept (the light is the energy, the lift is water pressure, the bloom is built from the air), never
decoration (the seductive-detail rule [G8]). **How we check:** the owner's verdict on phase B, and whether the child shows
it to someone.

### 3.10 What the game records as learning (invisible assessment)

The game never asks a question to check. Its evidence model (evidence-centred design [R30]; stealth assessment [G9][R21]):
each **competency** is an idea of §3.4; each **beat** is a situation where the child's action shows it, judged by a rule;
the beat becomes one `SkillShown` event for the voyage's unit.

**The beats of phase B** (unit `g5.science.plants_air_water`):

| Beat | When | Passed when | Kind | Strength of the evidence |
|---|---|---|---|---|
| B1 | Act 1 (after the ghost's door) | all doors shut and the leaf back above 0.55, no second ghost, no SHOW ME | SOLVED (else HELPED) | weak: copying the demonstration (the worked-example effect: it still counts, as G0's ruling 34) |
| C2, C3, C4 | the silent clouds (turns 2-4) | ≥ 2 sugars built in the cloud and the doors' open share (its last 70 %) ≥ 0.4 above the blaze before | SOLVED / HELPED (after Hoot's hint or the ghost) | strong (contrast: random, always-open and always-closed can't pass) |
| Z2, Z3, Z4 | the silent blazes after them | the leaf never below 0.55 and at most 2 of 6 doors open in the blaze's second half | SOLVED / HELPED (after L27's rescue or the ghost) | strong: random passes about one beat in ten, by luck |
| extra turns | when the bud isn't full | as above | as above | more evidence, never less |
| (not judged) | the trap blaze that opens Act 2, the voiced first cloud and blaze (L13-L15, L18) | — | — | teaching, not evidence |

So 5.1 gives **at least 7 events**: MasteryRules records a round once there are 6 (`SkillShown`'s rule), and 5 of 6
right first time masters the unit (★★, its 100 gold once). The desert night (5.T1) gives **6 events** (Day 1, Night 1,
Dawn 1, Day 2, Night 2, Dawn 2: §3.5b), `NEW_SETTING` when passed without help, for the same unit: a full round, its
transfer kept apart in `result.transfer`. The events are added as each beat is judged; `record` runs once when the
voyage ends (never on "stop for now", G0's rule); each SOLVED or NEW_SETTING beat pays the first-try gold at once.

**The voyage-to-unit map** (one main unit per voyage, so each voyage is a full round for its unit; other units get review
events only when already mastered, ruling 9):

| Voyage | Main unit | Beats |
|---|---|---|
| 4.1, 4.2, 4.3 | `g4.plant_animal_parts` (4.3 also reviews `g3.plants_needs`) | the water reaches the leaf; a cut tube found; leaves arranged for light; petals opened for the bee; pollen delivered |
| 4.T1, 4.T2 | `g3.plants_needs` (NEW_SETTING) | the store filled in the rain; the lily's doors found on top |
| 5.1, 5.2, 5.T1, 5.T3 | `g5.plants_air_water` | §3.10's beats; 5.2's six builder calls answered with the right material (1 in 3 by chance each) |
| 5.3, 5.4, 5.T2 | `g5.sun_energy_food` | doors kept shut at night; the store lasts the night; the energy chain ordered back to the Sun; the dark bean diagnosed |
| 6.1-6.5, 6.T1, 6.T2 | `g6.cells` | balloons kept full; chloroplasts turned right for the light; the wall built to the plan; power stations fed at night; the right level found; the visitor helped |
| 7.1-7.5, 7.T1, 7.T2 | `g7.photosynthesis` | CO₂ caught among nitrogen; water split; rings closed with every atom; the night survived on the store; the carbon ride's forks; the dome balanced |
| 8.1-8.5, 8.T1-T3 | `g8.transport_systems` | the rope kept whole; sugar routed to need; the pumpkin grown without starving the roots; the design that survives its world; spring's sugar sent up |

**What "help" means:** Hoot's hint after two misses, the ghost's step, the eye (SHOW ME), and the "too dry" rescue make the
beat HELPED; the ghost finishing a beat makes it SHOWN. The voice's teaching lines before a beat are not help. **Gold:**
each SOLVED or NEW_SETTING beat pays the School's first-try gold through `SkillShown.pay_first_try` as it is judged (the
daily cap holds); nothing pays for time.

**Adaptivity (honest, ruling 25):** after two failed silent turns, the next cloud lasts 30 % longer and its cues are
stronger (a deeper shadow, a louder breeze); the beat is still judged and its `note` says so ("long window"). The game's
own **leaf journal** (device-only in phase B) keeps, per idea, how often the child showed it, with or without help, in
which settings: the next voyage reads it (fade Hoot's prompts once shown twice; offer the transfer voyage), and phase C
can show the grown-ups' page "what your child showed" in pictures.

**Why this shows learning:** a silent beat can only be passed by acting on the weather's cues in the direction the science
says (contrast), repeatedly; a transfer beat only by changing the habit to fit the rule. Guessing was tested and fails
(§3.9). What the beats can't show (whether the child can *say* why) is the Book's and the grown-ups' business, never a
quiz.

### 3.11 The look

**The idea:** a giant living world built from the game's own shapes: big, soft, readable forms in the Life rooms' kit look
(lit matte shapes, glowing parts, a few see-through panels), so it is EasyCraft and it runs on a phone and a Quest. The
pictures in `leaf-voyage/` are the sketches:

- `01-garden-before-after.png`: the terrace before (drooping, cracked soil, heat) and after (standing, the bloom, a bee, the
  two block-scales).
- `02-the-dive.png`: the dive by tens: garden ×1, leaf ×10 (a ladybird like a bus), ×100 (a leaf hair like a glass tree),
  ×1,000 (the skin's cells like paving), ×85,000 (inside).
- `03-inside-the-leaf.png`: the map of rung 5's place: the glass roof with the Sun and the bud's silhouette, the tall
  palisade columns, the round spongy cells around the air cave, the vein's blue and gold pipes, the floor with six doors
  (open: air in, mist out; shut), the tiny child and Hoot.
- `04-doors-and-weather.png`: the trade-off as a day strip: blaze / cloud / blaze / cloud / evening, the right doors for
  each, and the plant outside.
- `05-core-loop.png`, `06-the-ladder.png`, `07-things-and-colours.png`, `08-one-cell.png`, `09-vr.png`,
  `10-transfer-worlds.png`, `11-atom-builder.png`.

**Scale (rung 5):** the place is about 16 × 16 m across and 10 m tall. Real sizes ×85,000: the child stands about 1.5 m,
a door (a 20 µm pore) is about 1.7 m long, the spongy cells (about 30 µm) are 2.5 m balloons, the palisade columns 4-6 m,
a chloroplast 0.5 m (a beach ball), the vein's pipes about 1.2 m across; the leaf's real thickness (250 µm, 21 m at this
scale) is pressed to 10 m (a ruling in §7).

**Light:** one warm key light from the Sun above the roof, a soft green fill, no shadows (the budget); god rays as a few
glowing panels; the workshops glow; the cloud's shadow dims the roof and the rays. **Colour:** chartreuse light at the top,
emerald in the middle, deep teal-green below; the meaning colours of §3.8 stand out against them (blue water, gold sugar,
grey-and-red air, violet minerals). **Motion:** the cells breathe slowly; the doors open like lips parting; air puffs
wander and are drawn to the working cells; the leaf tilts as it lifts.

**Both graphics styles:** phase B has one look (the kit's), used in blocky and realistic; a realistic twin (smoother
shapes, soft translucency) is phase C's (ruling 15).

### 3.12 Kind, fair and safe

The plant never dies, and nothing happens to it while the child is away (no timers, no wilting from absence, no streaks):
it changes only through voyages (ruling 12). The droop is the first voyage's story, never a guilt trick
(`engagement-and-child-psychology.md`: no "sad" character to make a child play). No failure screen: a leaf too dry is
caught, helped and goes on. Rewards are fixed and once (the School's gold and stars). No real names (the in-game Mars dome
is the game's colony; space programmes, record growers and performers stay in this document). Calm sounds; Reduce motion
(SETTINGS) makes the dive a gentle fade and stills the god rays.

---

## 4. The tech plan for phase B

### 4.1 What phase B builds

Voyage **5.1** and transfer voyage **5.T1**, complete and beautiful, flat and VR: the garden terrace, the sunflower and its
states, the dive both ways, the leaf's inside (with the cactus's dressing for 5.T1), the simulation, the beats and the
record, the voice, the sounds and music, the ghost's demonstrations, the end card, and a two-stop voyage board. Opened from
DISCOVER (the unit page's PLAY for `g5.science.plants_air_water`) and by a developer argument.

### 4.2 What G0's foundation gives, and what this game adds

| G0 gives (`docs/devlog/parts/play-g0.md`, DEVELOPMENT.md "The foundation's API") | This game adds |
|---|---|
| `PlayVoice.say` / `on()`: every line spoken, cutting in; words only without a voice | the voyage's lines as data (`data/play/leaf/lines.json`), each tested for length |
| `SkillShown`: `begin`, `add(unit, kind, note)`, `pay_first_try`, `record`; the round rule (6 events) | the beats (`LeafBeats`) that turn the simulation's log into events |
| `PlayHost`'s pattern: the place far above the world (`ROOM_ORIGIN`), hiding the screen it came from, its own camera, `LifeReach` input for fingers, hands, laser and head, the VR anchor and blink, the idle glow, SHOW ME, the break card, Android Back (`any_open`) | `LeafVoyageHost`: the same pattern for a continuous simulation (not exercise by exercise), a flying flat camera, VR swimming and the laser grapple, two-hand door squeezes |
| `LifeGhostFinger` (flat) and `LifeGhostHands` (VR): show a step | the demonstrations: the can, a door, a sugar to the pipe, a jar |
| `PlayGlyph`, `PlayHud`'s ear, eye and break pictures; the 7-word screen budget | the end card's pictures; zero words in play |
| `LifeRoomKit`: shapes and materials the warm-up already holds; `PlayArena` (a `LifeRoom`) | `LeafKit` on top of it: cells, columns, doors, pipes, the roof, merged meshes and MultiMeshes |
| DISCOVER, the registry's `signature` entries, P0/P1 and the audit | one registry entry (`leaf_voyage`) that names a **host** instead of a station (needs the lead: §8) |
| Size Magic (`SizeMagic`, the player's `set_size_mode`, the HUD's SIZE): TINY 1/4, GIANT 3× | the dive reuses Size Magic's sparkle and sound and adds the depth steps; the voyage's scale is the place's own (the world's SizeMagic modes don't change: ruling 13) |

### 4.3 Files

- **Pure rules, `core/play/leaf/`** (no nodes; deterministic; seeded):
  - `LeafSim`: the leaf's state (doors, water, air inside, light at each workshop, sugar made and carried, the bud, the
    jars for CAM) stepped by `step(dt, weather)`; `toggle(door)`, `deliver(n)`; the numbers of §3.5 as constants and the
    voyage's data.
  - `LeafWeather`: the voyage's script (blaze, cloud, evening, night, dawn) from data; the lengthened windows.
  - `LeafBeats`: judges beats from the sim's log (the rules of §3.10) and emits `SkillShown` events with notes.
  - `LeafVoyages`: the catalogue (`data/play/leaf/voyages.json`): each voyage's id, rung, unit, setting, weather, beats,
    lines, music; the ladder; the unlocks.
  - `LeafProgress`: the garden's state (the plant's growth, voyages done, the leaf journal); a device file in phase B
    (`user://leaf_voyage.json`, like `PlayQuests`).
  - `LeafSwimRules` (VR): body velocity from the grips and the hands' motion, thick-air damping, the speed cap.
  - `LeafSpace`: the place's solid shapes (cells as spheres, columns as capsules, roof and floor planes, shut doors) and a
    push-out for the flyer, so no physics bodies are needed.
- **The place, `entities/play/leaf/`:** `LeafVoyageHost` (open/close, input, camera, VR, demonstrations, the record,
  `finished`/`stopped` signals as `PlayHost`'s), `LeafGarden` (the terrace, the pot, the can, the scales, the fence, bees),
  `SunflowerModel` (stem segments, leaves, the head and petals; droop, stand, bud, bloom by transforms), `LeafPlace` (the
  interior: merged cells, door pairs, the vein, the roof with the Sun, clouds and the bud, god rays, the mist, MultiMeshes
  of puffs and sugars), `LeafDive` (the transition), `CactusDressing` (5.T1: wax roof, fewer sunken doors, water-store cells,
  jars, the night sky), `LeafKit` (shapes and materials over `LifeRoomKit`).
- **UI, `ui/play/leaf/`:** `LeafHud` (the ear, the eye, the break, the end card, the voyage board; pictures only).
- **Data:** `data/play/leaf/voyages.json`, `data/play/leaf/lines.json`; the units' `play` blocks name the game (the lead's
  allocation: §8).
- **Sounds:** `tools/make_leaf_sfx.py` (the doors, the bloops, the whoosh, cicadas: synthesised, original); music and
  ambience already in `assets/`.
- **Tools:** `tools/leaf_smoke.gd` (plays 5.1 and 5.T1 with the rule bot, flat and simulated VR, headless; checks the
  record), `tools/leaf_shots.gd` (pictures in a real window: the garden, the dive, inside, the bloom, the desert night),
  `tools/leaf_bench.gd` (draws and frame times, VR preview on the Quest APK's platform, like `vr_bench.gd`).

### 4.4 Flat and VR

**Flat (phones, tablets, PC, the web).** The camera follows the tiny avatar from about 2.5 m behind and a little above
(a third-person view; the game's camera button switches to first person). **A tap on a thing glides the child to it and
acts** (a door toggles, a sugar is picked up, the gold pipe takes what is carried, the can pours, the leaf starts the
dive): one tap, a glide of at most 1.2 s, then the act; things already within reach act at once. A drag looks around.
Free flight is for keys (WASD, Space, C), a mouse and a game controller (the left stick flies, the right stick looks, A
acts on the thing in the middle of the view); on a touch screen there is no joystick (ruling 33). Every tap target is at
least a fingertip (`LifeReach.screen_pick`) and inside the flat view's free band. The child carries up to 3 sugars at
once (a little stack on the avatar's back). The voyage board (after 5.1's end card) shows two pictures: the sunflower
(5.1 again) and the cactus pot (5.T1, open once 5.1 is done). A developer argument opens a voyage directly
(`--leaf-voyage=5.1` or `5.T1`).

**VR (the Quest 3).** The child stands at the garden's spot (`Vr.anchor`); the can is lifted by the hand (squeeze, tilt: Life's pour); touching
the leaf starts the dive: the garden's root scales up around the child's feet over 3 s (the head never moves), then a
white sparkle fade into the place. Inside: **swimming** (squeeze a grip and pull: the body moves the other way at up to
2.5 m/s; thick air stops it within a quarter second when no hand pulls), **the laser grapple** (point at a door, a pipe or a
cell and pull the trigger: a 0.6 s glide there, `PlayHost.GLIDE`'s way), snap turns, and the child's own comfort choice
(blink only, if set). **Doors:** a squeeze with both hands on the two guard cells shuts it; pulling them apart opens it;
one hand's trigger on a door toggles it (for one-handed play). **Sugar:** a hand takes a hexagon (it follows the hand) and
lets go at the gold pipe's mouth (within 0.3 m). The HUD stays hidden; the raised forearm shows the small panel (owner
#127). Hoot flies at the shoulder, his voice placed there. Tests drive it with `Vr.simulate`, `sim_hand`, `sim_input`.

### 4.5 The budget

Targets: **≥ 30 FPS average and no frame over 100 ms on the emulator**; **≤ 100 draws a frame on the Quest** (the floor
preset, 72 Hz), aim ≤ 70; one light, no shadows; only shaders the warm-up holds (the kit's materials; a new one goes into
the census with its test). Estimated draws inside the leaf: cells (two merged meshes: walls, insides) 2; doors (a MultiMesh
per guard-cell colour) 2; the vein 3; roof and floor 2; the Sun, the clouds, the bud 3; god rays 2; workshops (one
MultiMesh) 1; air puffs, sugars, drops (a MultiMesh each) 3; mist (CPU particles, like `Fx`) 2; Hoot 5; the flat avatar 8
or the VR hands 4; the HUD canvas 10-20 (pictures batched like `CanvasBatch`) → **about 45-55**. The garden: about 35. See-
through surfaces (the roof, the cells' skins) are few and large-faced (phones' fill rate); the mist is a few small
particles. A MultiMesh's per-instance colour changes its shader, so each colour is its own MultiMesh (no census change).

### 4.6 Tests (TDD, each failing first)

- `tests/unit/test_leaf_sim.gd`: open doors lose water faster in heat; air comes in only through open doors; sugar needs air,
  light and water; the leaf droops below 0.55 and stands above it; the bud fills only while it stands; the jars fill only at
  night with open doors and feed the workshops by day (5.T1).
- `tests/unit/test_leaf_beats.gd`: each beat's rule; voiced turns not judged; help makes HELPED; the events for the voyage's
  unit; at least 6 per voyage; transfer beats are NEW_SETTING.
- `tests/unit/test_leaf_cheat_bots.gd`: **the cheat test as a test**: random, always-open, always-closed, greedy and
  "open when bright" bots reach 5 of the 6 silent beats in under 1 % of 1,000 seeded runs; the rule bot in over 99 %; the
  slow rule bot in over 60 % flat and 95 % VR; in 5.T1 the sunflower-habit bot never wins and the cool-rule bot always
  does.
- `tests/unit/test_leaf_voyages.gd`: the data: every voyage names a written unit; every line has at most 12 words and is
  never a question that needs reading; every voyage has a hook and a see-why line.
- `tests/unit/test_leaf_swim_rules.gd`: pull moves the other way; no pull stops within 0.25 s; the cap.
- `tests/integration/test_leaf_place.gd`: every target in the flat view's free band (`PlayHud.FREE`) and at least a
  fingertip big (`LifeReach`); every hand target within 1.1 m of the VR eye or the laser's reach; only warmed shaders; no
  shadows.
- `tests/integration/test_leaf_host.gd`: flat and simulated VR through 5.1 and 5.T1: the hook, the dive, Act 1, Act 2, the
  return, the record (`SkillShown` events, the stars), the break, stop for now (nothing recorded), Android Back.
- `tests/integration/test_leaf_voice.gd`: every line spoken by itself; no word on the screen while a voyage plays.
- `tests/integration/test_leaf_budget.gd`: draws at the heaviest moment ≤ 100 (the place's own counter, as
  `test_play_budget.gd`).
- The full suite once at the end; the smoke; pictures in a real window; the bench; then the lead on the emulator and the
  Quest, and the owner's child.

### 4.7 The hooks phase B needs from others (the lead decides: §8)

1. G0's registry: `data/play/mechanics.json`'s `"signature": {"leaf_voyage": {"name": "Size Magic Voyages: Inside a
   Leaf", "host": "res://entities/play/leaf/leaf_voyage_host.gd"}}`, and `SchoolScreen`'s PLAY opening a host (instead
   of `PlayHost`) when the unit's `play.game` names one, with `play.params.voyage` choosing the voyage.
2. `g5.science.plants_air_water`'s `play` block: `{"game": "leaf_voyage", "params": {"voyage": "5.1"}}` (a content file).
3. Back and the pause key belong to the voyage while it shows (`LeafVoyageHost.any_open` beside `PlayHost.any_open` in
   `menu.gd`; W1's `room_open`/`close`).

### 4.8 The order of work (one agent, three briefs of two sessions; the lead checks between)

1. **The leaf works** (sessions 1-2): `LeafSim`, `LeafWeather`, `LeafBeats`, the data, the bots, the unit tests; then the
   places (`LeafKit`, `LeafPlace`, `LeafGarden`, `SunflowerModel`, the dive) and their pictures in a real window.
2. **The voyage plays** (sessions 3-4): `LeafVoyageHost` flat (input, camera, demonstrations, voice, the record, the end
   card, DISCOVER's hook), then VR (anchor, swim, grapple, squeezes, ghost hands, the dive in VR), the budget bench.
3. **The voyage sings** (sessions 5-6): the desert night, sounds and music, juice (the bloom, the bee, the lift), the smoke,
   the full suite; fixes after the lead's emulator and Quest check and the owner's child's first play.

---

## 5. Phases and estimates

| Phase | What | Gate | Estimate |
|---|---|---|---|
| **A** (this) | research and design | the lead's review; the owner sees `leaf-voyage-owner.md` | done |
| **B** | 5.1 and 5.T1, complete and beautiful, flat and VR | played on the emulator (≥ 30 FPS, no frame > 100 ms) and the Quest (≤ 100 draws, 72 Hz); the owner's child plays; the five tests checked honestly (the bots, no words, a transfer solved, the child's choice, the owner's wow) | **6 agent sessions** (one agent; 5-8 with surprises) |
| **C** | the ladder: rungs 4-8 at their minimum (about 15 voyages: 4.1, 4.T1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.T1, 7.3, 7.4, 7.T1, 8.1, 8.2, 8.T2, plus 4.T2 or 8.T3), each with its beats; the seven units to P1; the Voyage Garden in the world by the Academy; the depth dial; the plant's progress in the profile | the full suite; the lead's device check; playtest data | about 15-20 agent sessions (four places to add: the plant at ant size, the cell, the chloroplast, the plant map) |
| **D** | grow: the remaining voyages, design a plant, friends' gardens and voyaging together, any sunflower in the world as a door, the realistic twin | voluntary time, returns, transfer in playtests | ongoing |

---

## 6. Risks

| Risk | Why it matters | What we do |
|---|---|---|
| Too hard for a 9-year-old (two acts, a trade-off) | a child who fails stops choosing it | one new thing at a time; voiced first turns; the ghost after two misses; longer windows after misses; phase B's playtest decides |
| Chores, not play (open, close, carry, repeat) | choice | the weather turns change the job every 15-20 s; each voyage brings a new verb or place; short voyages; strategy praise; VR's body movement |
| A fiction teaches something false (the child works the doors and carries sugar; plants don't need helpers) | Spore's lesson [R19] | the honesty table (§9), the end line L25, an expert's review sheet in phase C (like Life's) |
| VR overload or sickness (flying in a cave, scale changes) | VR can lower learning [R15][R16] and comfort | the world scales around still feet; swimming stops when you stop; snap turns; the child's comfort setting; no text; tested on the Quest |
| Budget (see-through cells, many molecules) | phones and the Quest | merged meshes and MultiMeshes, few see-through surfaces, CPU particles, a bench in phase B |
| The voice (text-to-speech quality; a device with none) | rule 0 needs a voice | `PlayVoice`'s words when there is none (G0 ruling 28); a recorded voice is the owner's later choice |
| The evidence is noisy (a beat passed by luck, a slow child failing) | stars must mean something | contrast criteria, many beats, transfer beats; the slow-child check in the bots; the notes record adapted windows |
| Mastery from 5.1 before the soil idea is tested | the star says more than was shown | 5.2 is the next voyage; phase C may split the unit's evidence (ruling 10) |
| The registry needs a "host" entry and a SchoolScreen hook (G0's files) | without it DISCOVER can't open the voyage | the lead's decision (§8); a developer argument meanwhile |
| Scope (34 voyages) | a long tail | the phases; phase C's minimum ladder; one place per rung reused by its voyages |
| The garden in the world (W1 stage 3 not built yet) | the plant outside is part of the fantasy | phase B's terrace in the place; phase C places it by the Academy |

---

## 7. Rulings (each with its cost if wrong)

1. **The core verb is the doors** (open for air, close for water, timed to the weather), not carrying matter by hand at
   rung 5. *Cost:* the matter is seen moving, not carried, until rung 7's atoms; 5.2's build test and the end's "every
   petal from air" carry the idea meanwhile.
2. **The plant is a sunflower** (our units already use sunflowers; a big flower to open; young ones follow the Sun; seeds
   for the energy chain). *Cost:* sunflower leaves have doors on both sides; we show them underneath, as on most broad
   leaves (the honesty table).
3. **Child words first, science names once after use** ("doors", then "stomata"; "green workshops", then "chloroplasts"),
   all in the Book. *Cost:* a child meets the science words by ear only; the written exercises are not played.
4. **No face and no mouth on the plant or its parts; only Hoot speaks** (eating is the root of the soil misconception
   [R8]). *Cost:* less cuteness; the plant's state shows by posture, colour and sound only.
5. **The child works the doors by hand** (real guard cells do it themselves); Hoot says so at the end (L25), and from rung 8
   the child sets the plant's own rule. *Cost:* a fiction to keep honest; listed in §9.
6. **The child carries sugar to the gold pipe** (the plant loads it itself). *Cost:* as 5.
7. **The weather drives the trade-off**, judged by outcome and contrast; the model's numbers are phase B's start. *Cost:* a
   slow child on a phone passes 72 % in the model; the windows lengthen after misses (ruling 25).
8. **The voiced first cloud and blaze teach and are not judged**; the silent turns are. *Cost:* 7 events per voyage, not 9;
   a child who waits for Hoot's voice every time earns no stars until they read the weather themselves (the point).
9. **One main unit per voyage** (≥ 6 events); other units get review events only when already mastered. *Cost:* a voyage
   touching several units' ideas stars one; the ladder spreads the units over the voyages.
10. **5.1 can master `g5.plants_air_water` before 5.2 tests the soil idea.** *Cost:* the first star says less than the
    unit's goal until 5.2, the next voyage on the board; phase C may require both.
11. **Phase B's garden is a terrace in the voyage's own place**; phase C puts the Voyage Garden in the world. *Cost:* phase
    B's sunflower isn't seen in the child's world.
12. **The plant never dies and changes only through voyages** (no real-time growth, no timers). *Cost:* less pull to come
    back than Grow a Garden's; that pull is FOMO, which EasyCraft refuses.
13. **The dive reuses Size Magic's sparkle and sound; the voyage has its own scale** (the world's SizeMagic modes are
    untouched). *Cost:* "shrink anywhere and voyage into any plant" needs a world hook later (phase D).
14. **VR moves by swimming, the laser grapple and snap turns**, honouring the child's comfort setting. *Cost:* a new
    locomotion to test on the Quest.
15. **One look for both graphics styles in phase B** (the kit's); a realistic twin in phase C. *Cost:* a realistic-style
    child sees the kit look in the leaf for a while.
16. **The voice is the system's text-to-speech; every line ≤ 12 words.** *Cost:* robotic on some devices; a recorded voice
    is the owner's later choice.
17. **Music from the repo's public-domain and CC0 classical recordings.** *Cost:* none (already in the game).
18. **Phase B ships 5.1 and the transfer voyage 5.T1**, so the gate can check all five tests. *Cost:* one more session.
19. **The garden's state is a device file in phase B**, the profile in phase C (merged so growth is never lost). *Cost:* a
    new device starts a new garden in phase B.
20. **Each rung has one place its voyages share**; transfer voyages re-dress a rung's place. *Cost:* five places in all.
21. **Molecules are huge and true in count at rung 7; sugar is built per carbon** (CO₂ + water → one link + O₂, a correct
    net balance), within MS-LS1-6/7's scope (matter and energy traced, no biochemistry [P13]); where O₂'s atoms come from is
    an Expert secret. *Cost:* the per-carbon build is not the Calvin cycle (out of the standards' scope).
22. **The hexagon is "sugar" at rungs 4-6, the true ring at rung 7.** *Cost:* a sign before the truth (§9).
23. **Each voyage ships with its cheat bots as tests.** *Cost:* a little test time (the sim runs headless in milliseconds).
24. **A unit is P1 when its `play.game` is `leaf_voyage`; PLAY opens the voyage the unit names; a half-covered unit keeps
    G0's play for its other half** behind a second picture. *Cost:* a hook in G0's registry and SchoolScreen (§8).
25. **Adaptive windows**: after two failed silent turns the next cloud is 30 % longer, still judged, the note says so.
    *Cost:* an easier window counts the same in MasteryRules (the note keeps it visible).
26. **Professor Hoot is the guide**, tiny inside. *Cost:* none known.
27. **"Plant food" (fertiliser) is a testable idea in 5.2**: a pinch of minerals, never mass. *Cost:* none.
28. **5.1 is everyone's prologue; the grade picks the default rung; every rung is open.** *Cost:* a grade 4 child may
    wander into atoms (welcome).
29. **Never scary**: no giant eyes, no attackers, no dying plant; friendly ladybirds and ants. *Cost:* none.
30. **No real names in the game.** *Cost:* none.
31. **The leaf's thickness is pressed** (21 m at true scale → 10 m) so the place fits a VR room-sized view. *Cost:* the
    proportions are a little off (§9).
32. **Stopping mid-voyage records nothing** (G0's rule) but the plant keeps what the child did (the bud's fill). *Cost:*
    a child who stops often gets fewer stars, never less plant.
33. **Flat play is tap-to-glide (a tap on a thing glides there and acts) with drag-to-look; free flight only by keys, a
    mouse or a game controller.** Everything a voyage asks for is a thing to tap, so a touch screen needs no joystick.
    *Cost:* a child on a phone can't roam the leaf freely; if playtests show they want to, a joystick is one HUD control.

---

## 8. Open questions for the lead

1. **The registry for a deep game with its own host**: add `host` to `data/play/mechanics.json`'s `signature` entries and
   let `SchoolScreen`'s PLAY open it (my proposal, §4.7), or a separate entry point for deep games?
2. **Which units go to P1 in phase C**, and how a half-covered unit shows its other half (my proposal: P1 for the eight in
   §2.6; `g4.plant_animal_parts` and `g8.transport_systems` keep G0's play for their animal half behind a second picture).
3. **The Voyage Garden in the world**: beside the Discovery Academy (W1 stage 3) and local to each child like the crystals
   (my proposal), or anywhere the child places a pot?
4. **The garden's progress in the profile** (phase C): a new `ProfileData` field merged in the backup (never losing growth):
   whose allocation?
5. **VR movement in phase B**: swimming and the grapple as designed (my proposal: the owner's child knows Gorilla Tag), or
   only the existing blink (less to build, less wow)?
6. **The voice**: the system's text-to-speech now; a recorded voice later is the owner's call.
7. **When phase B starts** relative to Balance Altar's and Fraction Bakery's phase A (wave 1, the cap of three agents).
8. **The Mars dome (7.T1)** as a mission of the colonies (the rocket loop): the lead's and the owner's call.
9. **The leaf journal** on the grown-ups' page in phase C ("what your child showed", in pictures)?

---

## 9. The honesty table: what is real, what is simplified, what is fiction

| In the game | Real? | Note |
|---|---|---|
| Doors (stomata) let air in and water out; plants close them in heat and drought and in the dark | real | [P3][P5] |
| Guard cells are green bean-shaped cells that swell to open | real | |
| The child opens and closes the doors | **fiction** | the plant does it itself (L25 says so) |
| The child carries sugar to the pipe | **fiction** | the plant loads its phloem itself |
| Air puffs drift in and gather at working cells | real (diffusion towards where CO₂ is used) | shown huge |
| Doors only underneath the sunflower's leaf | **simplified** | sunflowers have them on both sides, more underneath |
| Water from the vein refills the cells; full cells hold the leaf up | real | turgor [P4] |
| Sugar as a gold hexagon (rungs 4-6) | **simplified** | glucose's ring is 5 C and 1 O with an arm (rung 7 shows it) |
| Sugar built carbon by carbon (rung 7) | **simplified** | a correct net balance; not the Calvin cycle (outside MS-LS1-6) |
| The plant grows in minutes | **simplified** | days in reality |
| The scales: the plant gains, the soil doesn't | real | van Helmont [P12] |
| A cactus opens its doors at night and keeps the air in its cells | real | CAM [P5] |
| Chloroplasts move to face or avoid strong light | real | [P1] |
| Water flows from a wetter cell to a drier one (rung 6's water gates) | **simplified** | osmosis: water moves towards the cell whose sap is more concentrated |
| The place's proportions (the leaf pressed to half its thickness) | **simplified** | ruling 31 |
| Size Magic, Hoot shrinking, voyages | **fiction** | EasyCraft's magic |

---

## 10. Sources

Learning-is-play's sources [G1]-[G9] (`docs/design/learning-is-play.md` §10) are used as they are. New here:

**Children's ideas and how they change**
- [R1] Wynn, A. N., Pan, I. L., Rueschhoff, E. E., Herman, M. A. B., & Archer, E. K. (2017). Student misconceptions about
  plants – a first step in building a teaching resource. *Journal of Microbiology & Biology Education*, 18(1).
  https://doi.org/10.1128/jmbe.v18i1.1253 ; full text https://pmc.ncbi.nlm.nih.gov/articles/PMC5524439/
- [R2] Haslam, F., & Treagust, D. F. (1987). Diagnosing secondary students' misconceptions of photosynthesis and
  respiration in plants using a two-tier multiple choice instrument. *Journal of Biological Education*, 21(3), 203-211.
  Summary: https://wordpressua.uark.edu/scimap/2022/11/30/diagnosing-secondary-students-misconceptions-of-photosynthesis-and-respiration-in-plants-using-a-two-tier-multiple-choice-instrument
- [R3] Amir, R., & Tamir, P. (1994). In-depth analysis of misconceptions as a basis for developing research-based remedial
  instruction: the case of photosynthesis. *The American Biology Teacher*, 56(2), 94-100.
  https://wordpressua.uark.edu/scimap/?p=369
- [R4] Mohan, L., Chen, J., & Anderson, C. W. (2009). Developing a multi-year learning progression for carbon cycling in
  socio-ecological systems. *Journal of Research in Science Teaching*, 46(6), 675-698. https://lter.kbs.msu.edu/citations/2175
- [R5] Parker, J. M., de los Santos, E. X., & Anderson, C. W. (2013). What learning progressions on carbon-transforming
  processes tell us about how students learn to use the laws of conservation of matter and energy. *Educación Química*, 24,
  399-406. https://doi.org/10.1016/S0187-893X(13)72493-5
- [R6] Parker, J. M., de los Santos, E. X., & Anderson, C. W. (2015). Learning progressions & climate change. *The American
  Biology Teacher*, 77(4), 232-238. https://doi.org/10.1525/abt.2015.77.4.2
- [R7] Carbon TIME, Michigan State University: https://carbontime.create4stem.msu.edu ; the Plants unit's molecular-model
  activity: https://carbontime.create4stem.msu.edu/plants/activity-4.1
- [R8] Messig, D., & Groß, J. (2018). Understanding plant nutrition—the genesis of students' conceptions and the
  implications for teaching photosynthesis. *Education Sciences*, 8(3), 132. https://doi.org/10.3390/educsci8030132
- [R9] Stavy, R. (1990). Children's conception of changes in the state of matter: from liquid (or solid) to gas. *Journal
  of Research in Science Teaching*, 27(3), 247-266. https://cris.tau.ac.il/en/publications/childrens-conception-of-changes-in-the-state-of-matter-from-liqui/
- [R10] Institute of Physics, Spark: "Some students think that gases do not have mass".
  https://spark.iop.org/some-students-think-gases-do-not-have-mass
- [R11] Harvard-Smithsonian Center for Astrophysics (1997). *Minds of Our Own*, program 2: *Lessons from Thin Air*.
  https://stemedhub.org/resources/1338
- [R12] Kamarudin & Noor (2024). To what extent do primary school children understand photosynthesis? A study of
  children's drawings with follow-up interviews (48 children aged 7-13). *Education 3-13*.
  https://doi.org/10.1080/03004279.2024.2385434 ; https://eprints.whiterose.ac.uk/218112/
- [R13] White, R., & Gunstone, R. (1992). *Probing Understanding*. Falmer Press (predict-observe-explain).

**Games, simulations, VR and assessment**
- [R14] Culp, K. M., Martin, W., Clements, M., & Lewis Presser, A. (2015). Testing the impact of a pre-instructional digital
  game on middle-grade students' understanding of photosynthesis. *Technology, Knowledge and Learning*, 20(1), 5-26.
  https://eric.ed.gov/?id=EJ1054768
- [R15] Parong, J., & Mayer, R. E. (2018). Learning science in immersive virtual reality. *Journal of Educational
  Psychology*, 110(6), 785-797. https://doi.org/10.1037/edu0000241
- [R16] Makransky, G., Terkildsen, T. S., & Mayer, R. E. (2019). Adding immersive virtual reality to a science lab
  simulation causes more presence but less learning. *Learning and Instruction*, 60, 225-236.
  https://imotions.com/blog/adding-immersive-virtual-reality-to-a-science-lab-simulation-causes-more-presence-but-less-learning
- [R17] Johnson-Glenberg, M. C. (2018). Immersive VR and education: embodied design principles that include gesture and
  hand controls. *Frontiers in Robotics and AI*, 5, 81. https://pmc.ncbi.nlm.nih.gov/articles/PMC7805662/
- [R18] Immune Attack (Federation of American Scientists, 2008): https://en.wikipedia.org/wiki/Immune_Attack ;
  https://www.molecularjig.com/?p=3315
- [R19] Bean, T. E., Sinatra, G. M., & Schrader, P. G. (2010). Spore: spawning evolutionary misconceptions? *Journal of
  Science Education and Technology*, 19(5), 409-414. https://doi.org/10.1007/s10956-010-9211-1
- [R20] Podolefsky, N. S., Moore, E. B., & Perkins, K. K. (2013). Implicit scaffolding in interactive simulations (PhET).
  https://www.per-central.org/perc/2013/Detail.cfm?id=5248
- [R21] Shute, V. J., Ventura, M., & Kim, Y. J. (2013). Assessment and learning of qualitative physics in Newton's
  Playground. *The Journal of Educational Research*, 106, 423-430. https://myweb.fsu.edu/vshute/pdf/JER.pdf
- [R22] Chase, C. C., Chin, D. B., Oppezzo, M. A., & Schwartz, D. L. (2009). Teachable agents and the protégé effect:
  increasing the effort towards learning. *Journal of Science Education and Technology*, 18(4), 334-352.
  https://purl.stanford.edu/zm369yx3532
- [R23] Botanicula (Amanita Design, 2012): https://en.wikipedia.org/wiki/Botanicula
- [R24] A Fisherman's Tale (InnerspaceVR, 2019): https://en.wikipedia.org/wiki/A_Fisherman%27s_Tale
- [R25] Gorilla Tag (Another Axiom, 2021): https://en.wikipedia.org/wiki/Gorilla_Tag ; players and sessions:
  https://mixed-news.com/en/gorilla-tag-dau-mau-stats/
- [R26] Grow a Garden (Roblox, 2025), the concurrent-player records:
  https://esports.gg/news/roblox/grow-a-garden-breaks-blox-fruits-record-for-most-concurrent-users-on-roblox/ ;
  https://www.pocketgamer.biz/roblox-game-grow-a-garden-beats-steam-with-record-concurrent-user-high-of-89m
- [R27] Miyamoto on World 1-1 (Eurogamer interview, 2015), as reported:
  https://gamedeveloper.com/design/how-miyamoto-built-i-super-mario-bros-i-legendary-world-1-1
- [R28] Cultural precedents: *The Magic School Bus* (Scholastic, TV 1994-97; "Gets Planted"); *Fantastic Voyage* (1966
  film); Charles and Ray Eames, *Powers of Ten* (1977 film).
- [R29] Ryan, R. M., Rigby, C. S., & Przybylski, A. (2006). The motivational pull of video games: a self-determination
  theory approach. *Motivation and Emotion*, 30(4), 347-363.
- [R30] Mislevy, R. J., Almond, R. G., & Lukas, J. F. (2003). *A brief introduction to evidence-centered design*. ETS
  Research Report RR-03-16.

**Plant science**
- [P1] Kasahara, M., Kagawa, T., Oikawa, K., Suetsugu, N., Miyao, M., & Wada, M. (2002). Chloroplast avoidance movement
  reduces photodamage in plants. *Nature*, 420, 829-832. https://doi.org/10.1038/nature01213
- [P2] Atamian, H. S., Creux, N. M., Brown, E. A., Garner, A. G., Blackman, B. K., & Harmer, S. L. (2016). Circadian
  regulation of sunflower heliotropism, floral orientation, and pollinator visits. *Science*, 353(6299), 587-590.
  https://www.sciencedaily.com/releases/2016/08/160804152431.htm
- [P3] Transpiration (97-99.5 % of root water lost; stomata's share of water loss):
  https://en.wikipedia.org/wiki/Transpiration ; stomatal frequency and area (lab notes):
  https://faculty.csbsju.edu/SSAUPE/biol327/Lab/stomata/stoma_lab_freq.htm
- [P4] Turgor pressure (typically ≥ 0.5 MPa; over 1 MPa, about five times a car tyre): https://en.wikipedia.org/wiki/Turgor_pressure
- [P5] Crassulacean acid metabolism (stomata open at night; CO₂ stored as malic acid in the vacuole; used by day behind
  closed stomata): https://pmc.ncbi.nlm.nih.gov/articles/PMC4065858/figure/F1
- [P6] Water lily leaves (stomata on the upper side only): https://vcbio.science.ru.nl/en/image-gallery/show/PL0148/ ; air
  sent down to the roots: https://vtecostudies.org/blog/a-water-lilys-world
- [P7] Why trees drop leaves (water from frozen ground, frost) and autumn colours:
  https://www.canr.msu.edu/news/trees_avoid_damage_from_freezing_temperatures_part_1 ;
  https://set.adelaide.edu.au/news/list/2019/11/12/why-do-trees-lose-their-leaves
- [P8] Stored starch to sugar in spring (maple): https://massmaple.org/?p=24
- [P9] Giant pumpkins (one fruit per vine; peak growth): https://en.wikipedia.org/wiki/Giant_pumpkin ;
  https://www.scientificamerican.com/article/how-to-grow-a-2-560-pound-pumpkin/
- [P10] A plant chamber in space with red, blue and green LEDs (2014):
  https://www.nasa.gov/mission_pages/station/research/news/veggie
- [P11] Purcell, E. M. (1977). Life at low Reynolds number. *American Journal of Physics*, 45, 3-11.
  https://www.physics.brocku.ca/Courses/1P92_Kaur/SolidsFluids/Life-at-low-R/
- [P12] Van Helmont's willow (1648): https://faculty.csbsju.edu/ssaupe/biol115/van_helmont.htm
- [P13] NGSS performance expectations 5-LS1-1, MS-LS1-2, MS-LS1-6, MS-LS1-7 (clarifications and assessment boundaries):
  https://www.nextgenscience.org/pe/5-ls1-1-molecules-organisms-structures-and-processes ;
  https://www.nextgenscience.org/pe/ms-ls1-2-molecules-organisms-structures-and-processes ;
  https://www.nextgenscience.org/pe/ms-ls1-6-molecules-organisms-structures-and-processes ;
  https://www.nextgenscience.org/pe/ms-ls1-7-molecules-organisms-structures-and-processes
- [P14] Ruben, S., Randall, M., Kamen, M., & Hyde, J. L. (1941). Heavy oxygen (O18) as a tracer in the study of
  photosynthesis. *Journal of the American Chemical Society*, 63(3), 877-879.
- [P15] Guard-cell lengths and mesophyll (cereal leaves): https://www.jircas.go.jp/sites/default/files/publication/jarq/12-3-128-131_0.pdf

## The lead's review (2026-10-18 03:20): phase A passes; the open questions decided
**Verdict: approved for phase B.** The verb (the leaf's doors, opened and closed to the weather) is the real biology and
cannot be won by guessing (the model's 1,000 runs per player); the design attacks the most-reported misconception
(plants feed on soil) by showing it (the two block scales by the pot); nothing is read; the ladder grows by Size Magic's
depth, which only EasyCraft can do; minute 1 has a wow (the shrink dive into the green cathedral). The owner sees the
one-page summary (`leaf-voyage-owner.md`) and can stop or change it at any point.
1. **How DISCOVER opens it:** as proposed: a `host` field on a signature entry in `data/play/mechanics.json` and a hook in
   the School page's PLAY; also W1's `AcademyPlaza.opens()` at the Science door and a crystal's choice when the child's
   unit is one this game covers.
2. **P1 and half-covered units:** phase C marks a unit P1 only when the game teaches all of it; a half-covered unit
   (the animal half of grades 4 and 8) stays P0 and its page offers the voyage for its plant half beside its School
   round for the rest.
3. **The garden of voyage plants:** beside the Discovery Academy, local to each child like the crystals (never synced).
4. **The saved progress:** phase C's agent adds it to the profile (save, load, the backup's rules) with its tests.
5. **VR movement in phase B:** arm-swimming as designed (the owner's child already moves this way in Gorilla Tag), with
   the existing blink teleport as the comfort choice in VR COMFORT, and the vignette while moving.
6. **The voice:** the system's voice now (PlayVoice); a recorded voice is the owner's later decision.
7. **When:** phase B starts now in the free slot (three briefs of about two sessions, the lead's device check between).
   Balance Altar's and Fraction Bakery's phase A follow as slots free.
8. **The Mars dome voyage:** a transfer voyage in phase C; tying it to the colony missions is phase D.
9. **The grown-ups' page:** phase C adds the game's record there in plain words ("Opened the doors at the right times
   on a hot day, by themself").
