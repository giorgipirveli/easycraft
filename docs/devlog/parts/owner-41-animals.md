# Owner feedback #41: more different animals (with real sounds)

The owner (2026-09-24 20:42): "include more different animals" and "animals should have sounds, like real ones".
Built by an agent in its own worktree with `lead-merge` merged in first (the audio pass, #50's animal chorus, M3 Task 11
pets, M3 Task 20a rideable buddies, Frostpeak and the Candy Kingdom), without the editor, the emulator or godot-mcp.
Spec §14.19 (new), plan Task 26 (new), brief `docs/superpowers/briefs/prompt-own41.md`. No new block or item ids.

Skills: `godot-prompter:particles-vfx` — chose `CPUParticles3D` (the Compatibility renderer on the emulator, CandySprinkles'
pattern, `fixed_fps = 30`, world-space, the shared Fx material) for the bees and butterflies; rejected `GPUParticles3D`
(a process material and shader per system, Compatibility support) and turbulence (not in CPU particles, not needed for
a few insects). The animal work reuses the project's own patterns (M1b's host-simulated `Animal`, M2 Task 18's minds,
M3 Task 20a's RideRules/RideDirector) rather than new ones: the ride is input sync to the host (as 20a), no client
prediction.

## What was built

| Piece | Where | What it does |
|---|---|---|
| 19 new kinds | `core/rules/animal_rules.gd` (`SPECIES` rows, `HEALTH`, `DROPS`, section "owner #41") | Green Meadows: horse, donkey, goat, deer, duck, frog, turtle, squirrel, owl, hedgehog; the Sandstorm Desert: camel, lizard, fennec; Frostpeak: penguin, polar bear, arctic fox, seal; the Candy Kingdom: gummy bunny, candy bird. Weight 0 (placed by `AnimalHomes`). Optional row keys: `swims`, `walk_hop`/`hop_every`, `climb`, `shy`, `curls`, `slides`, `trees`, `nocturnal`, `lays`. Rules: `climb_height`, `walk_hop`, `hop_every`, `swims`, `curls_up`, `climbs_trees`/`is_trunk`, `nocturnal`/`feels_night`, `slides_on`/`slide_factor`, `flee_from` (a shy deer runs from anyone walking up within 9 blocks, anyone within 4), `lays_egg`, `hatch_by`, `attacks` (always false: the polar bear is gentle). `can_step` lets swimmers into water and onto its top. |
| Where they live | `core/rules/animal_homes.gd` (`AnimalHomes`) | Biomes per kind (`HOMES`): Meadows `meadow`, `shore` (water within 8 blocks, or low land ≤ sea + 5), `woods` (a tree within 5), `hills` (≥ sea + 16); desert `sand`, `oasis`; Frostpeak `snow`, `ice` (a frozen lake's ice), `lakeside`; candy `frosting`, `candy_woods`. A kind whose place of its own fits a herd's centre comes before the open-land kinds (`OPEN`). `pack_at`: Green Meadows keeps M1b's weighted herds and M3 Task 11's foxes and parrots; half of the other herds (`PACK_CHANCE`, a seeded roll of its own) become a new kind that fits. `pick_at`: the other universes pick only their own kinds. |
| Universes name their animals | `world/universes/*.gd` (`animals`), `UniverseRegistry.animals(u)` | Meadows: `AnimalRules.MEADOWS_KINDS` (the 10 old + 10 new); desert: camel, lizard, fennec; Frostpeak: penguin, polar bear, arctic fox, seal; candy: gummy bunny, candy bird. A universe that names none (e.g. a future realm) keeps Green Meadows'. `AnimalRules.spawns_for_cell(shape, cell, kinds)`, `AnimalDirector.kinds` (the sandbox sets it). |
| Food | `core/rules/animal_food.gd` (`AnimalFood`) | Every kind's food: the old ones grass and leaves (as M2 Task 18), grazers grass/leaves, camels the desert's dead bush, cactus and palm leaves, candy animals gumdrops/cotton candy/sprinkles, the sea animals the Fish Snack, birds the Seed Cracker. A block feeds from the hand (never used up); a treat item goes through PetDirector (Survivor pays one; a treat a wild animal doesn't eat is kept). |
| Minds | `core/mind/species/animal_species.gd` (`TRAITS`) | A trait row for each kind (herd horses, shy deer, a watchful owl, a calm polar bear, flocking penguins ...). The owl's night is the day (`feels_night`): it sleeps by day and is awake at night. |
| Box models | `entities/animal/animal_boxes.gd` (`AnimalBoxes`), `blocky_animal.gd` | 19 box models in BlockyAnimal's format (one shared mesh per kind, one shared material, at most two draw calls: a head that bobs or a tail that wags; an owl's head turns). The arctic fox shares the fox's boxes in white with grey socks. `dressed_mesh_for`: a saddled horse's or camel's saddle and a tamed donkey's packs are baked into a second cached mesh (no extra draw call). `COLLAR` for the five new pets. |
| The animal | `entities/animal/animal.gd` (small hooks marked "owner #41", section at the end) | Swimmers float just under the water's top (`_paddle`) and climb out onto a bank; a squirrel pressed against a trunk runs up it; walking hops by kind; a hedgehog curls (sits, still) for 4 s instead of running (a hit still pushes it); penguins and seals belly-slide on ice (× 2.2, no hops; every game tilts them flat while they move on ice); babies (from eggs: 0.55 size, a higher voice); a turtle's egg (synced `egg_at`, one shared egg mesh on every game); the rider (synced `rider_peer`, `saddled`, `chest`); `_ride_step` (the host moves a ridden horse or camel: RideRules.step at GALLOP/TREK, the storm factor, never into water or off a drop of more than 4, a hop onto a 1-block step). |
| The eggs | `world/animal_director.gd` (section at the end) | Host, once a second: a wild grown-up turtle on sand, ≥ 150 s after its last egg, lays one with a 10 % chance a look; a child within 2 blocks hatches it into a baby turtle next to it (`egg_hatched`); the sandbox tells that child "You found a turtle egg! A baby turtle hatched!" and counts `secret_found/turtle_egg`. |
| Riding | `core/magic/ride_rules.gd` (kinds GALLOP 9.5 m/s, TREK 6.5 m/s: free-turning like WALK), `core/rules/animal_ride_rules.gd` (`AnimalRideRules`), `world/ride_director.gd` (section "owner #41"), `entities/player/player.gd` (`riding_animal`, `mount()`) | A tamed horse or camel that got a SADDLE is ridden with M3 Task 20a's RIDE button (the same requests; the director looks for a buddy, then an animal of that name). A camel keeps its pace in a storm, a horse goes 70 % (`Animal.storm_source`: the sandbox's storm). HOP OFF / JUMP: `RideRules.dismount_spot` beside it. "Tame it, then tap it holding a SADDLE to ride it!" for an unsaddled one. |
| Pets | `core/rules/pet_rules.gd` (`KINDS` rows, perks `RIDE`, `CHEST`), `world/pet_director.gd` (section at the end), `entities/player/block_interactor.gd`, Session section "owner #41" | Horse (favourite: the berries, "an apple"), camel (the seed cracker, "grain"), donkey, fennec, arctic fox: two treats tame them (they count toward a child's 3 pets). A tap on your own tamed horse or camel holding a SADDLE saddles it (Survivor pays one; saved with the pet). The donkey's chest (`on_chest_put`: all of the held kind that fits; `on_chest_take`: a slot back, what doesn't fit stays). Non-pet kinds eat treats they like (`_feed_wild`). |
| The chest | `core/rules/donkey_chest.gd` (`DonkeyChest`), `ui/pets/pet_panel.gd` (CHEST page) | 9 slots × 99, flat `[id, count, ...]`, only ownable things (never bedrock), cleaned from saves. The pet card's CHEST (a donkey's only): 9 slot buttons (a picture and a number; a tap takes it back), PUT IN, BACK; clear of the HUD at 16:9 and 20:9. |
| Saves | `world/world_meta.gd` (`_parse_pet`), `scenes/sandbox.gd` (`_restore_pets`) | `saddled` (horse/camel only, a real `true`) and `chest` (donkeys, cleaned) are kept with the world's pets. |
| Voices | `tools/make_audio_pass_sfx.py pack`, `autoloads/audio.gd`, `core/rules/voice_rules.gd`, `assets/CREDITS.md` | 83 files (933 KB): a call (2-3 takes) and a hurt voice for every new kind, the horse's happy nicker; the fox and the parrot get real voices (the stand-ins `dog_2`/`chicken_3` are gone) and hurt voices. 67 freesound.org pages, every one read again on 2026-09-25 and saying CC0. |
| The chorus | `world/animal_chorus.gd` (one line), `VoiceRules.CALL_GAIN_DB` | Every kind has a measured level; a wild animal asleep never calls (an owl by day, the herds at night). |
| Bees and butterflies | `core/rules/insect_rules.gd` (`InsectRules`), `world/meadow_insects.gd` (`MeadowInsects`), descriptor field `insects` (Meadows), sandbox `_candy_local` | 10 butterflies and 8 bees round this game's player, by day, outdoors, over grass/bushes/leaves; two `CPUParticles3D`, the shared Fx material, 30 fps, nothing sent; not in the Monster Wave arena. |
| Chat | `core/rules/chat_commands.gd` | `/summon` knows every new kind (`polar_bear`, `arctic_fox`, `gummy_bunny`, `candy_bird` with the underscore). |
| Tools | `tools/animal_census.gd`, `tools/animals_bench.gd` (+ `_steps.gd`) | The herds each universe grows over 32 × 32 areas; the 40-animal cost measurement (below). |

## Tests (RED → GREEN)

Full suite through the slot gate (`tests/suite_slots.sh tests/run_tests.sh`): **4600 / 4600 passing, 478 scripts, exit 0**
(the first run: 4598 / 4600, the two MindBook tests below).

| Test file | Tests | RED |
|---|---|---|
| `tests/unit/test_animal_pack.gd` | 16: every animal has a home, herd, speed, food, voices, health, drops and a mind; the new kinds' rows and box models; sizes; foods; every universe names its animals (each new kind exactly one); a universe naming none keeps Meadows'; each universe grows only its own animals, all of them; desert animals on sand never in a pond or a cactus; seals on the lake ice, penguins by the lakes; candy birds in the cane forests; Meadows grows every new kind, each where it fits; the old herds stay where no new kind came (and ≥ 20 herds became new kinds); determinism; no animal attacks | "Static function animals() not found in base UniverseRegistry"; then the voices (until the sounds), the sheep's wool drops, the penguins' place (the test was wrong once penguins also live on the open snow) and Meadows' shore kinds (ducks 2, turtles 0 in 1024 areas: the shore rule was widened) |
| `tests/unit/test_animal_pack_rules.gd` | 10: goat 2 blocks, a shy deer, the hedgehog, swimmers' steps, belly-slides, trunks, the owl's night, hops, eggs, hatching | "climb_height() not found" |
| `tests/unit/test_animal_ride_rules.gd` | 5: only a saddled horse or camel, gallop/trek speeds under the paid Fly, the storm, never into water or off a cliff, the seat and getting off | written first; first run after `AnimalRideRules` and RideRules' new kinds (GREEN) |
| `tests/unit/test_animal_pack_pets.gd` | 10: the new pets and their perks, the arctic fox and fennec as species of their own, the chest (slots, caps, full, take, junk), saves (saddle, chest, hand-edited), `/summon` | "Cannot find member RIDE in base PetRules" |
| `tests/unit/test_meadow_insects.gd` | 4 | written first, first run after `InsectRules`/`MeadowInsects` (GREEN) |
| `tests/integration/test_animal_pack_behaviour.gd` | 9: a goat climbs a 2-block step a sheep can't; a duck floats where a sheep sinks; a deer runs from a child walking up, a sheep stays; a hedgehog curls and uncurls; a penguin slides on ice faster than on snow and lies flat; a squirrel runs up a trunk, a rabbit can't; an owl sleeps by day and wakes at night; a turtle lays an egg on sand that hatches into a baby when a child comes; no egg on stone | the penguin (7.2 m sliding against 6.0 m waddling: its walking hops took it off the ice, where the grip is 1; sliders no longer hop on ice) |
| `tests/integration/test_animal_pack_pet_director.gd` | 7: two treats tame a horse, a saddle makes it gallop (saved); only its own child saddles, never a wild one or a cow; Survivor pays one saddle; a penguin eats a fish snack (a bolt is kept); the donkey's chest put/take; only its child; a saved donkey keeps its chest | written before `on_saddle`/`on_chest_*`, first run after them (GREEN) |
| `tests/integration/test_donkey_chest_panel.gd` | 3: CHEST on a donkey's card only; PUT IN and a slot's tap; clear of the HUD | written before the page, first run after (GREEN) |
| `tests/integration/test_animal_ride.gd` | 5: RIDE next to a saddled horse (never an unsaddled one), on its back, HOP OFF beside it; the gallop's speed; a camel steady in a sandstorm, a horse at 70 %; a ridden horse stops at the water; only its rider steers | the water stop: stepped outside physics frames, `move_and_slide` used the test frame's delta (distances × 8) and the 10 Hz look-ahead was passed over; now the look-ahead runs every step and grows with the speed, and the test steps in physics frames |
| `tests/integration/test_animal_pack_chorus.gd` | 4: every kind has a measured level; 23 new flock animals + a horse + a goat make a calm, mixed chorus (6.5 calls a minute, no kind above 30 %); a sleeping wild owl is quiet; every new kind (and the fox and parrot) calls in 2-3 real takes and cries in its own hurt voice | the sleeping owl called |

| `tests/unit/test_mind_book.gd` (changed), `test_monster_mind.gd` | the whole-world save and the monsters' place in it | the first full suite: with 30 kinds, M2 Task 18's 2 KB `MindBook` budget (about 13 tables) filled with animal tables before the goblins' and slimes' (`test_monster_tables_fit_the_world_budget_with_the_animals`), and "every species saved" can't hold any more; now the monsters come first, then the tables that learned most (`TinyNet.learned`, `learned_in`) |

**Mutation checks** (each rule broken on purpose, the tests run, then restored; `scratchpad` script, 14 mutations in one
run): a goat's hop back to 1.1, swimmers not paddling, the deer not shy, the hedgehog not curling, the squirrel not
climbing, the owl's night not flipped, the chest's 99 cap, the saddle not saved, anyone saddling a horse, anyone using a
donkey's chest, the ridden horse not stopping at water (two lines), anyone's stick steering, a wild animal eating a treat
it doesn't eat. Every one made its test fail (17 failing tests); all green again after restoring.

## Rulings (each with its cost if wrong)

1. **The arctic fox and the fennec are species of their own** (white and sandy; `AnimalBoxes` shares the fox's boxes with
   other socks), wild in their universes, tamed with two treats like Green Meadows' fox, with the fox's treasure nose
   (SNIFF). Green Meadows' fox stays in Green Meadows. *Cost:* two more rows in `PetRules.KINDS`; if they should stay
   wild, delete the rows.
2. **Each universe grows only the animals its descriptor names** — cows no longer wander the desert, Frostpeak or the
   Candy Kingdom (they did before, since the spawn rules ignored the universe). A universe naming none keeps Green
   Meadows'. *Cost:* add kinds to a descriptor's list.
3. **Green Meadows: half the herds become a new kind** (`PACK_CHANCE` 0.5) through a seeded roll of its own, so every
   other herd keeps its species and spots (tested); kinds of a place of their own (ducks by the water, deer by the woods,
   goats on the hills) come before the open-meadow kinds. Census (seed 12345, 1024 areas): the old kinds 12-24 herds each,
   fish 153, horse 23, donkey 19, goat 12, deer 23, duck 6, frog 11, turtle 4, squirrel 7, owl 8, hedgehog 10. *Cost:*
   tune `PACK_CHANCE` and `HOMES` weights with `tools/animal_census.gd`.
4. **The shore** is water within 8 blocks or low land up to 5 above the sea: the Meadows coast is steep, and with M3
   Task 11's 5-block look only ~1 % of herd centres counted (ducks 2, turtles 0 in 1024 areas). *Cost:* a few ducks on
   low meadows a little way from the water.
5. **Penguins also live on the open snow** (weight 6 against the arctic fox's 8 and the polar bear's 4), seals only on
   the lake ice: lakes cover ~2 % of Frostpeak, and a child should meet penguins. *Cost:* penguins far from water.
6. **Horse, camel and donkey are pets** (two treats; they follow their child and count toward the 3 pets); **anyone may
   ride a saddled one nobody rides** (as M3 Task 20a's ruling 8 for buddies). *Cost:* one condition in
   `RideDirector.host_ride_animal`.
7. **"Food that exists":** taming uses the treats (the Berries stand for an apple, the Seed Cracker for wheat) — no new
   item ids were allocated; grass, leaves, the desert's plants and candy blocks feed from the hand. *Cost:* real apples
   and wheat need item ids from the lead.
8. **The saddle is given with a tap** (its own child, a tamed horse or camel), used up in Survivor (Tilly sells it, M3
   Task 20a), saved with the pet; it can't be taken back off. *Cost:* one more request if children want it back.
9. **Speeds:** a horse gallops at 9.5 m/s (under the paid Fly's 11), a camel treks at 6.5; a camel keeps its pace in a
   sand- or snowstorm, a horse goes 70 %. *Cost:* numbers in `RideRules.SPEED` / `AnimalRideRules.STORM_SLOW`.
10. **A ridden animal never walks into water nor off a drop of more than 4 blocks** (it stops): horses don't swim with a
    child on. *Cost:* a river means hopping off; a swim mode would be one more branch in `_ride_step`.
11. **The donkey's chest:** 9 slots of up to 99; PUT IN moves all of the held kind that fits, a tap takes a slot back
    whole (what doesn't fit in the bag stays); only its own child; a wild donkey carries nothing. In Sandbox (endless
    blocks) it keeps things for fun. *Cost:* a "put one" button if children want finer control.
12. **The turtle's egg** is on the turtle (synced), not a block (no ids): one at a time, ≥ 150 s apart, only on sand;
    a child within 2 blocks hatches it (a baby turtle, a line, `secret_found/turtle_egg`). Eggs and babies are not
    saved (a turtle far from everyone leaves with its egg; a baby is a wild turtle). *Cost:* an egg lost if the child
    walks away; a saved egg needs a WorldMeta list.
13. **A squirrel runs up a trunk to the leaves and drops back down** (animals take no fall damage). *Cost:* none seen;
    a perch in the leaves would be a new state.
14. **A wild animal asleep never calls** (the owl by day; also the herds at night, which #50 did not know): nights are
    a little quieter. *Cost:* if the owner wants night herd sounds, drop the one line in `AnimalChorus.step`.
15. **A hedgehog curls up for 4 s instead of running** (a hit still pushes it; its mind may walk it away afterwards).
16. **Bees and butterflies:** there is no flower block, so they fly over the meadow's grass, bushes and leaves by day,
    in Green Meadows only (descriptor field `insects`), not in the Monster Wave arena.
17. **Models:** box animals in both styles, like every animal today (the realistic style has no animal models); saddles
    and packs are a second cached mesh per kind. *Cost:* realistic animals are a separate task.
18. **Voices where no CC0 recording exists:** the fennec and the arctic fox are red foxes, the polar bear a grizzly (NPS),
    a candy bird real songbirds, a gummy bunny a real squeaky toy; the donkey's, deer's, turtle's, hedgehog's and
    lizard's hurt voices are their own calls played 15-30 % faster. *Cost:* swap takes in the tool's `animal_pack`.
19. **Chorus levels** were measured like #50 (phone speaker: two 500 Hz high-passes, EBU R128, takes looped) and
    brought towards −17 LUFS, boosts capped at +3 dB; the fish kept 0 (as #50 left it). *Cost:* numbers in
    `VoiceRules.CALL_GAIN_DB`; the lead listens on a phone.
20. **The Animal Book (M3 Task 21b) doesn't exist yet**, so nothing lists them; 21b can read `AnimalRules.SPECIES` with
    `AnimalHomes.HOMES` and `UniverseRegistry.animals(u)`.
21. **The world's saved minds stay at 2 KB** (spec §12.17), which holds about 13 learned tables: Green Meadows alone can
    have 20 kinds of animal and its monsters. The monsters' tables are saved first (their tactics are play), then the
    animals' that learned the most; the others start again from their hand-made defaults after a reload. *Cost:* a
    species a child taught a little forgets it on reload; `MindBook.MAX_TOTAL` 4096 would keep them all (~5 KB with every
    kind).

## Measurements

**40 animals near a player, headless** (`godot --headless --path . --script res://tools/animals_bench.gd -- --seconds=40`,
this desktop, CPU time of the host's `Animal._physics_process` for all 40 each physics frame, 40 new kinds against 40 of
M1b's farm animals in alternating 2 s blocks, a pond, an ice patch and trees, a player walking among them, day then night):

| Run (load) | New kinds: avg / p99 / worst ms per frame | Farm animals: avg / p99 / worst | Per animal | Chorus (80 animals) |
|---|---|---|---|---|
| 1 (24.6) | 1.622 / 4.024 / 6.970 | 1.608 / 4.060 / 10.897 | 40.5 µs vs 40.2 µs | 0.010 ms avg, 1.39 ms worst |
| 2 (15.3, the committed code) | 1.572 / 2.828 / 11.912 | 1.581 / 2.971 / 8.701 | 39.3 µs vs 39.5 µs | 0.010 ms avg, 2.20 ms worst |

The new kinds cost the same as the old (their extra rules run at the 10 Hz decisions or only for the few kinds that use
them). 40 animals are the worst case (a crowd of `/summon`s; wild herds stop at 20 near a player): on a phone 3-5× slower
that is 5-8 ms a frame for the animals alone, as for 40 of M1b's. Emulator FPS: the lead's check below.

**Census** (`godot --headless --path . --script res://tools/animal_census.gd -- --seed=12345 --cells=32`, herds/animals
over 1024 areas of 32 × 32): desert camel 170/308, lizard 172/261, fennec 114/167; Frostpeak penguin 163/487, polar bear
89/89, arctic fox 190/285, seal 4/6; candy gummy bunny 275/828, candy bird 143/351; Meadows in ruling 3.

**Voices:** 83 files, 933 KB (mono Vorbis q3, 32 kHz), 0.15-2.95 s. Phone loudness per kind (LUFS, two 500 Hz high-passes):
horse −17.0, donkey −19.5, goat −17.7, deer −19.4, duck −19.9, frog −17.7, turtle −19.0, squirrel −16.7, owl −18.0,
hedgehog −21.2, camel −20.1, lizard −22.8, fennec −18.6, penguin −19.8, polar bear −27.9, arctic fox −17.3, seal −26.7,
gummy bunny −18.4, candy bird −12.5, fox −16.5, parrot −15.3 (chicken −12.4 and sheep −16.5 measured the same way, as in #50).

## For the lead: what to check on the emulator

1. Green Meadows (both styles): walk the meadow — horses and donkeys in the open, deer, squirrels and owls by the trees,
   goats on the hills, ducks, frogs and turtles by the water; bees and butterflies round the child by day over grass
   (none at night, in caves, over sand). ≥ 30 FPS, no frame over 100 ms, with AUTOPILOT and near a crowd
   (`/summon duck` ×10 then `/summon horse` ×10).
2. Listen: every new kind's call sounds like the animal, the chorus stays calm (no one kind everywhere), the owl hoots at
   night only, the fox and the parrot sound like a fox and a parrot now.
3. A horse: two treats (PETS tab) tame it; tap it holding a SADDLE (MAGIC row; Tilly in Survivor): the saddle shows; RIDE:
   the child sits on its back, the stick gallops (faster than walking), it stops at water, HOP OFF beside it. A camel in
   the desert: steady in a sandstorm.
4. A donkey: two treats, its packs show; tap it: CHEST: PUT IN the held blocks, tap a slot to take them back.
5. Special moves: a goat hops up a 2-block step, a duck swims, a deer runs off as you walk up, a hedgehog curls up when you
   run at it, a squirrel runs up a trunk, penguins belly-slide on Frostpeak's lake ice, a seal lies on the ice.
6. A turtle on a sand beach: wait near it (a few minutes) — an egg; walk onto it: "You found a turtle egg! A baby turtle
   hatched!" and a small turtle.
7. The desert, Frostpeak and the Candy Kingdom show only their own animals (no cows).
8. LAN: a guest sees the saddle, the rider on the horse's back, the egg, the donkey's chest on its own card.

## Merge notes

Shared files touched (small, marked "owner #41"): `core/rules/animal_rules.gd` (SPECIES rows at the end of the table,
HEALTH, DROPS, `spawns_for_cell(..., kinds)`, `_species_at`, `_spot`, `can_step`, section at the end),
`core/magic/ride_rules.gd` (two kinds appended, `FREE_TURN`, `wants_hop`, `mount_line`), `core/rules/pet_rules.gd` (two
perks, five KINDS rows), `core/rules/voice_rules.gd`, `core/rules/chat_commands.gd`, `core/mind/species/animal_species.gd`,
`entities/animal/animal.gd` (hooks + section), `entities/animal/blocky_animal.gd`, `entities/player/player.gd` (the
ride section), `entities/player/block_interactor.gd` (two lines), `world/ride_director.gd`, `world/pet_director.gd`,
`world/animal_director.gd`, `world/animal_chorus.gd` (one line), `world/world_meta.gd` (`_parse_pet`),
`world/universes/*.gd`, `ui/pets/pet_panel.gd`, `autoloads/audio.gd`, `autoloads/session.gd` (section at the end),
`scenes/sandbox.gd` (`_start_animals`, `_start_minds`, `_start_pets`, `_restore_pets`, `_add_rides`, `_candy_local`, the
egg line, pet panel), `assets/CREDITS.md`. Likely conflicts: `AnimalRules.SPECIES`/`PetRules.KINDS` with owner #39's
baby dragon; `Audio.SOUNDS`; `RideRules.Kind` if someone else appends kinds.
