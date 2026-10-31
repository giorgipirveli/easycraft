# M2 Task 18: Creature minds (owner feedback #24) — part 1: core, animals, bot friends; part 2: monsters

Owner, 2026-09-24 11:47: "please for monsters, for bots and for animals implement something like a mind,
like a small llm, which will be used for their decisions, for their learning, so they act more like real
animals, real monsters and real friends" — "but it should be light weight". Spec §12.17 (the authority),
plan Task 18. Built in an isolated worktree from `9b92c2a` (branch `m2-survive-the-night` after the secrets
merge), no editor or emulator use. Part 2 (monsters) waits for Task 5 (stealth) to be merged.

Commits: `0113060` (core), `c7cc7c2` (animals, thought bubbles, treats), `adeca3d` (bot friends, cost
bench), `65e3b68` (smoke run; answers to the child show at once), and this notes commit.

## What a mind is

The lead's ruling (spec §12.17): a small **learned neural mind** per creature, not a text LLM. The idea is
the same as a language model's — a network picks what comes next from what it sees and learns from what
happens — at the size of a phone: a few hundred weights, about a microsecond per forward pass.

```
senses (16 numbers, 0..1)            the creature fills the world facts; the mind fills its drives
   │                                 (hunger, sleepiness, fear, curiosity, company) and "how the
   ▼                                 last action went"
TinyNet: 16 → 12 ReLU units → 1 score per action    (the species' hand-made defaults + learning)
   │
   ▼  + personality offset per action (from the creature's id: no two sheep are the same)
   │
   ▼  only the actions possible now (a bit mask) → gentle softmax pick (temperature 0.35)
action, kept for the species' commit time (2–10 s) unless something happens (interrupt)
   │
   ▼  outcome → reward (the species' table) → learns the chosen action's last-layer row
```

### Pure code in `core/mind/`
| File | What |
|---|---|
| `tiny_net.gd` (`TinyNet`) | The MLP on `PackedFloat32Array` (`w1/b1`, `w2/b2`); the forward pass on native 4 × 4 blocks (`Projection * Vector4`); `learn()` moves only the output row of the chosen action, every weight clamped to ±4 and to ±2 of its hand-made default; deterministic `create(outputs, seed, defaults…)`; a save is the output layer's drift as one signed byte per weight (base64, 140 characters for 8 actions); `is_base64` guards loads (bad base64 logs engine errors) |
| `mind.gd` (`Mind`) | Senses, drives, personality, `think(allowed)`, `odds()`, `reward()` / `credit()` (for late outcomes like a kept build), `feel(event)` via the species' reward table, thoughts (≥ 8 s apart, the same picture again ≥ 24 s), save/load, an opt-in step counter for the bench |
| `mind_memory.gd` (`MindMemory`) | ≤ 8 players by name (like, fear, last seen; owners pinned, never forgotten, liked ≥ 0.8) and ≤ 8 places (food, den, danger, favourite); fear fades with a 45 s half-life, liking 10 min, places 10 min; faded strangers go after 5 min; `entry()` reads everything about a player in one look |
| `mind_species.gd` (`MindSpecies`) | A species' table: actions, hidden features and action rows (hand-made defaults), drive senses and starts, rewards, commit times, pictures, learning rate, temperature, personality size |
| `mind_book.gd` (`MindBook`) | One shared net per species per world (`MindBook.current`): what one sheep learns, every sheep of that world knows; saved in `WorldMeta.minds` (only tables that learned, ≤ 2 KB for the world, parsed defensively) |
| `thought.gd` (`Thought`) | Picture ids: heart, question, zzz, food (drumstick), sweat drop, light bulb |
| `species/animal_species.gd` | The animals' table and per-species traits (dogs come closer and look around more, rabbits run sooner, sheep stick together, cows graze and herd, cats watch) |
| `species/bot_species.gd`, `bot_style.gd` | The friends' table (5 designs + 3 kinds of finds) and what a friend learns of its child (favourite blocks, tall/wide, space, the side monsters come from); the greeting line |

The animals' hidden units are readable features, each a hand-made row over the senses: danger (fear of the
nearest player, a rush, a recent hit, the fear drive), friend (liked and near), hungry, sleepy (drive and
night), curious (drive and something new), lonely (misses its leader), homesick at night, calm, watchful (a
stranger near), content (the last outcome), day, and a constant. The action rows say how much each feature
speaks for each action (e.g. flee = 3 × danger − calm; sleep = 3 × sleepy + 0.5 × homesick − 2 × danger). So a
newborn animal already acts sensibly (unit tests: a hungry animal grazes, a scared one runs, a sleepy one at
night sleeps, a lonely one goes back to the herd, one that likes a player runs over, a curious one looks).

## Animals (`entities/animal/animal.gd`, section "M2 Task 18")

Wild land animals think with their species' shared net; fish and golden animals keep their old ways (ruling 6).
Every 0.1 s (unchanged) the animal decides; about 3 times a second its mind reads the senses and drives, and
it picks a new action when the old one has run its course or something happened (a hit, a treat, a liked
or feared player coming into range, something new, night falling, losing sight of the leader). The existing
steering, safe steps, rush-flee (M1b) and look-at-player carry the action out:

| Action | What the animal does |
|---|---|
| graze | stands, head bobbing; hunger falls (a drumstick bubble when it was hungry) |
| wander | the M1b wander, sometimes back towards a favourite spot (where it was fed) |
| herd | walks back to the herd's leader (the area's first animal, `a<x>_<z>_0`), each member at its own spot around it; faster when far |
| approach | runs over to the player it likes most (1.5× pace), stops 2.2 blocks away (a heart) |
| flee | keeps 9 blocks away from a player it fears (1.8× pace; a sweat drop) |
| sleep | at night walks to its den — the foot of the tree nearest its herd's home (one bulk copy of a 17 × 9 × 17 box, searched natively), else its home spot — each member a little apart, lies down (`sitting`, synced) with zzz; wakes at dawn, or when hit |
| explore | goes to look at a block a player placed lately (within 12, 40 s) or a new face (within 10; a question mark), then knows it |
| watch | stands and looks at a player near |

- **Affection and fear:** a treat (a tap holding grass or leaves — `Session.mind_request_treat`, the host checks
  the reach like petting; it never uses the block up) adds 0.6 liking and a heart; a pet adds 0.3; a weapon's
  push names the attacker (the nearest player on the side it was pushed away from) and adds 0.8 fear, −0.4
  liking, a danger place and a sweat drop. Being chased (a rush) adds a little fear.
- **Pets** keep following their owner (M1b, all pet tests unchanged); taming pins the owner's name in the
  pet's memory, saved with the pet (`WorldMeta.pets[i].mind`) and loaded on restore, so the pet remembers its
  owner by name; it shows a heart when the owner comes back after 20 s away (never sad: the child-psychology
  guard for pets).
- **Learning:** rewards (fed +1, petted +0.6, hit −1, chased −0.4, grazed +0.2, slept +0.1, explored +0.1)
  teach the species' net of this world — the sheep of a world where children feed them grow friendlier.

## Bot friends (`entities/bots/bot_friend.gd` and `world/bot_director.gd`, sections "M2 Task 18")

Each friend owns its net (it learns one child) and a `BotStyle`, both saved in `WorldMeta.bots[i].mind` (≤ 2 KB).
- **Builders:** the director tells builders each block the child places; the child's favourite build blocks
  (placed at least twice lately, fading) replace a design's own blocks (lights and leaves stay: a lamp, a
  planter) — in Sandbox; Survivor builds stay leaves (Task 15's ruling 3). Towers (blocks on top of the one
  before) tilt the pick towards pillars and lamp posts, walls towards the planter. A build still standing
  60 s later is "kept" (+1 for its design); a block of it broken is "broken" (−1, one lesson per build).
- **Explorers:** when an ore and a tameable animal are both in sight, the mind picks what to show first; after
  showing, it watches 45 s: the ore mined / the animal tamed / the secret visited (within 3 blocks) = used
  (+1); the child came within 4 = followed (+0.4); else ignored (−0.4). A kind scored very low is often not
  shown at all (60 % of the time). Task 16's `notice()` (secrets) is always answered.
- **Space:** when the friend has just come back to a child standing still and the child walks off (faster than
  2 m/s) within 3 s, it keeps 1 block more space next time (follow stop and wander ring, up to +6); a child
  walking up to a friend standing still takes 0.5 back. At most one lesson per 8 s.
- **Fighters:** every new monster they go for is noted by its side of the child (8 sectors, fading); when one
  side stands out, their wandering stays on that side.
- **Greeting:** a friend that knows its child from a saved world says "Hi <username>! It's me, Pip! Let's
  build something cool!" instead of the plain hello (a fixed line, never a question).
- A lesson lights a bulb over its head (the synced thought).

## Thought bubbles (`entities/mind/`)

`ThoughtPictures`: `data/minds/thoughts.png` (8 × 1 tiles of 32 px, `tools/make_thought_pictures.gd`), one
shared `QuadMesh` and one cached `StandardMaterial3D` per picture, with exactly the secrets' picture-plate
setup (unshaded, alpha scissor, nearest) so the two share one shader. `ThoughtBubble`: one per creature,
made on its first thought and reused; turned to this device's camera in code while shown (no billboard shader
variant); a small pop and bob unless Reduce motion; 2.5 s; only within 16 blocks of this device's camera;
at most 3 at once per screen; prewarmed once in front of the camera as the world appears. The host sets a
synced `thought` (on change) when a player is within 16 blocks; every peer shows it.

## Patterns chosen and rejected (the skills `ai-navigation`, `godot-optimization`, `state-machine`)

- **Chosen: utility selection (the net scores actions) over steering behaviours** (seek/flee/arrive/wander on
  `_dir`), on top of the existing enum-free animal steering and Task 15's enum state machine
  (`BotRules.choose_behaviour`, kept as is: the mind tunes its parameters — which design, which find, how
  far — rather than replacing its states). The animals' actions are a flat enum-like set (8 < the skill's
  "node-based past ~8 states" line), matched by index.
- **Rejected: NavigationAgent3D / baked NavigationMesh.** The voxel world changes with every edit; baking per
  chunk costs frames on phones; the safe-step rules already keep animals off cliffs and out of water.
- **Rejected: behaviour trees (Beehave, LimboAI).** An addon (or a node tree) per creature for eight actions,
  no learning, and more nodes per animal.
- **Rejected: node-based state machines** (a node per state per creature: 24 animals × 8 nodes).
- **Optimisation (godot-optimization):** no allocations in the hot path beyond two small arrays per pick;
  shared per-frame player and name lists; typed packed arrays; the matrix product on native `Projection ×
  Vector4` (profiled: GDScript loops 18 µs, blocks 0.75 µs); senses read about 3 times a second while steering
  stays at 10 Hz; the herd leader and the novelty search cached for a second; the den search once a night per
  herd as one bulk copy; shared materials and meshes for bubbles (no per-event materials).

## Tests (RED → GREEN)

| Test file | Tests | RED |
|---|---|---|
| `tests/unit/test_tiny_net.gd` | 9 | "TinyNet not declared"; then the toy-reward test (a random hidden layer can't tell the two situations apart: fixed by a hand-made hidden layer, as every species has) and a bad-base64 engine error (fixed by `is_base64`) |
| `tests/unit/test_mind_memory.gd` | 9 | "MindMemory not declared"; test values fixed for the owner floor and 0.1-block rounding |
| `tests/unit/test_mind.gd` | 19 | "AnimalSpecies not declared" (a `const A := …` alias isn't a constant expression); learning-off compared scores (the outcome sense moves them) — now compares weights; the repeat-thought rule ("REPEAT_GAP not found"); the reaction rule ("REACTION_GAP not found", from the smoke run); the budget test failed on the wall clock at load 50 (334 ms) — now this thread's CPU time |
| `tests/unit/test_bot_mind.gd` | 10 | "BotStyle / BotSpecies not declared" |
| `tests/unit/test_mind_book.gd` | 7 | "Invalid assignment of property 'minds'", "Invalid access to 'mind'" |
| `tests/integration/test_thought_bubble.gd` | 8 | written first but first run after the code; mutation check: a material made per bubble fails "one material per picture" |
| `tests/integration/test_animal_minds.gd` | 12 | "Cannot find member time_source"; then "by the tree" (the den search box was centred on the wandering leader, so a tree 6.4 blocks away fell outside: now around the herd's home, 17 × 9 × 17) |
| `tests/integration/test_animal_treats.gd` | 3 | "Static function mind_treat() not found" |
| `tests/integration/test_bot_minds.gd` | 8 | first run after the code; mutation checks: unstyled designs fail "the child's blocks" (after the test moved to blocks no design has), always-the-first-find fails "shows the dog"; fixes the tests found: `notice()` refuses while pointing, a teleported player's cached spot made the friend rest, monsters added in the same frame weren't seen, a wandering friend came close again (wander spots now keep the space too) |

Required tests: forward pass and pick (tiny net, mind), learning converges on a toy reward and stays clamped
(tiny net), memory caps and forgetting, save/load (net, mind, memory, style, book, world meta), same seed =
same individual, fed by A → comes to A and keeps away from B who hit it, herd follows a leader, animals sleep
at night (together, by a tree) and wake, a builder prefers the child's blocks, an explorer learns what the child
follows, the bubble uses shared materials, budget (10,000 decisions).

Suite: **1418 → 1503** passing (exit 0), 148 → 157 scripts. All Task 15 bot tests and all animal and golden-animal
tests unchanged and green.

## Headless runs on real terrain

- **`tools/minds_smoke.gd`** (new Sandbox world): animals near the player have minds and act (graze, wander,
  explore, herd seen); a treat through `Session.mind_request_treat` → liking 0.60 and a heart bubble on it;
  at night half or more of the animals near the player lie down to sleep within 9–15 s; in the morning none
  lies down; the world saves `animal:<species>`. First run: 5 ok, 1 FAIL (no heart: the 8 s thought gap
  after the chicken's own "food" thought) → the reaction rule (ruling 10, `test_an_answer_to_the_child_shows_at_once`);
  second run: all ok (exit 0), no engine errors or warnings in the log.
- **`tools/bots_smoke.gd`** (Task 15's, unchanged): every check ok on the new code (three friends, catch-up,
  the builder's build next to the player's block, the fighter's hits, knock-out and back, saving, bye); friends'
  own physics steps 0.435 ms per frame on average (load 26–33; Task 15 measured 0.26–1.0 ms at loads 29–70).
- A 150 s headless Survivor game (`-- --survivor --new-world`): no script errors.

## Numbers (desktop i9-12950HX, shared with other agents' work)

| What | Result | Load average |
|---|---|---|
| Forward pass, GDScript loops vs `Projection × Vector4` blocks (16 → 12 → 8) | 18.3 µs vs **0.75 µs** | 28 |
| 10,000 decisions (tick + pick; `test_mind`) | **91 ms CPU (9.1 µs each)**; wall clock 73 ms (quickest of 5 × 2,000) | 50 |
| An animal's mind step keeping its action / sensing and picking in the same step (bench, CPU) | **5.4–9.9 µs / 24.6–37.4 µs** | 31–44 |
| A friend's mind step / a design pick / a find pick (bench, CPU) | 2.6–5.0 µs / 10–16 µs / 10–16.8 µs | 31–44 |
| Mind steps per frame (24 animals + 3 friends at 60 Hz) | 5.0 steps, 0.17 picks | — |
| **Minds' CPU per frame, 24 animals + 3 friends** | **0.030–0.054 ms** (budget: ≤ 0.3 ms with 20 monsters) | 31–44 |
| Animals' whole physics step per frame, minds on / off (bench, CPU) | 0.65–0.89 / 0.46–0.66 ms | 31–44 |
| Walking animals per frame, minds on / off | 19.9–20.0 / 15.8–15.9 of 24 | — |

- **Per decision:** the pick itself (tick + think, the unit budget) is 9 µs; an average 10 Hz mind step is
  5–10 µs (it senses about every third step and picks about once in 30). A step that senses *and* picks is
  25–37 µs on this loaded PC — over the spec's 20 µs, but rare (0.17 per frame for all 27 creatures). Ruling 17.
- The budget test times its own thread's CPU (`/proc/thread-self/schedstat`): with a load average of 50 on
  24 cores the wall clock ran 2–3 × slower (a first run failed at 334 ms).
- The frame totals include the clock read (17–40 µs: reading the proc file). The on/off difference (≈ 0.2 ms)
  is mostly **movement, not thinking**: with minds, herds follow their leaders and animals go to look at the
  walking player and new blocks, so about 4 more animals walk each frame (each walking animal moves every
  physics step). Phones are 3–5 × slower: about 0.6–1 ms per frame for the livelier animals — measure on the
  emulator (below).
- Per-step wall-clock figures from the bench (27–57 µs) are dominated by being preempted on this busy PC and
  are not used.
- Saved minds: a species table 140 characters; a whole world of 8 learned animal species ≈ 1.3 KB
  (`test_a_whole_world_of_learned_species_saves_in_two_kilobytes`); a pet's or friend's mind < 2 KB (tested).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A small learned neural mind, not a text LLM** (lead, spec §12.17). *Cost if wrong:* the owner wanted
   words; a curated, filtered line set on the M4 server could speak for bots behind the same mind interface.
2. **Only the output layer learns; the hidden layer is hand-made, readable features.** Learning stays
   gentle and explainable, and a fresh creature acts sensibly. *Cost if wrong:* slower, shallower learning
   (no new features); a full backprop step would be about 12 × the cost per event.
3. **Wild animals share one learned table per species per world; individuals differ by personality and
   memory.** *Cost if wrong:* one sheep's scare makes all sheep of that world a little shyer.
4. **Feeding = a tap on an animal holding grass or leaves**; it never uses the block up (also in Survivor), and
   it still counts as a pet (so dogs and cats still tame). There is no food item. *Cost if wrong:* a child who
   holds grass by chance "feeds" (harmless); a real food item later changes one list (`AnimalSpecies.TREATS`).
5. **The attacker is the nearest player on the side the push came from** (no change to `CombatDirector`).
   *Cost if wrong:* in a crowd, the wrong child may be feared for a minute.
6. **Fish and golden animals have no mind** (fish swim as before; golden animals keep Task 16's flee-and-catch
   rules). *Cost if wrong:* schools of fish don't follow a leader.
7. **Pets keep M1b's follow-the-owner movement;** their mind only remembers (the owner pinned by name) and
   shows thoughts; fear never makes a pet leave its owner (child-psychology guard: pets never run away or
   sulk). *Cost if wrong:* pets feel less "alive" than wild animals.
8. **Night = `DayCycle.is_night`; there is no light sense** (spec lists light); dens are the foot of the tree
   nearest the herd's home within 8 blocks, else the home spot. *Cost if wrong:* animals in a cave by day
   don't sleep; herds far from trees sleep in the open.
9. **Senses about 3 times a second** (steering stays at 10 Hz; a hit or treat is felt at the next decision).
   *Cost if wrong:* a 0.3 s slower reaction to a liked or feared player (the M1b rush-flee is still 10 Hz).
10. **Thoughts:** ≥ 8 s apart per creature, the same picture again ≥ 24 s, at most 3 on one screen, only within
    16 blocks; an **answer to something the child just did** (a treat, a pet, a hit, the owner back, a friend's
    lesson) comes after only 2 s (found by the minds smoke run: a chicken that had just thought "food" showed
    no heart when fed). *Cost if wrong:* children see fewer bubbles than they'd like; four constants.
11. **Bots: Survivor builds stay leaves** (Task 15 ruling 3) — the child's favourite blocks only in Sandbox.
    *Cost if wrong:* Survivor friends don't show the child's style in blocks (they still learn shapes).
12. **Bot secrets are always shown** (`notice()` is Task 16's hook); the learned preference only orders an ore
    and an animal. *Cost if wrong:* a child who ignores secrets still gets pointed at them.
13. **More space: +1 block per lesson, up to +6, one lesson per 8 s; only when the child walks off within 3 s
    of the friend arriving next to a still child.** Walking on after a long stop doesn't count. *Cost if wrong:*
    a child who often turns away may find friends far; the cap keeps them within 13 blocks.
14. **The username greeting only for a saved friend that knows its child** (the child's own validated
    username, a fixed template, no questions). *Cost if wrong:* none known.
15. **The minds' glue lives in end-of-file sections of `animal.gd` (≈ 610 lines) and `bot_friend.gd` (≈ 270
    lines)**; the hooks in their existing code are one line each (setup, save, knockback, sync list, `_process`,
    the pace, `_decide`; follow distance, explorer look, build plan, secrets hook). *Cost if wrong:* long files;
    the sections can move to helper scripts later.
16. **`Mind.profiling`** (off by default) stays in the code: two `Time` reads per mind step while the bench runs.
    *Cost if wrong:* a bool check per step.
17. **"≤ 20 µs per decision" is read as the pick and the average step** (9 µs and 5–10 µs); the rare step that
    also re-reads the senses costs 25–37 µs here. *Cost if wrong:* a further pass (a compact senses array,
    skipping idle animals' senses) — the per-frame total (0.03–0.05 ms) is far inside the 0.3 ms budget.

## Merge notes (what will conflict)

- `autoloads/session.gd`: a new section at the end ("M2 Task 18: minds").
- `world/world_meta.gd`: field `minds`, `m.minds = MindBook.clean(…)` at the end of `from_json`, `"minds"` in
  `to_json`, `_keep_mind` in `_parse_pet` / `_parse_bots`, a section at the end.
- `scenes/sandbox.gd`: `_start_minds()` before `_start_animals()`, `meta.minds` in `save_world`, the pet mind in
  `_restore_pets`, the bubble prewarm in `_setup_local_player`, a section and `_exit_tree` at the end.
- `entities/animal/animal.gd`, `entities/bots/bot_friend.gd`, `world/bot_director.gd`: hooks as above and a
  section at the end each; `BotDirector.add(personality, name, look, mind)` has a new optional argument.
- `entities/player/block_interactor.gd`: two lines after `Session.request_pet` (the treat).
- `docs/DEVELOPMENT.md` §4 (bench and pictures), §5 (architecture), §8 (two gotchas); `assets/CREDITS.md`.
- Not touched (for the lead at merge): `docs/devlog/2026-09-24-m2.md` (status row 18),
  `docs/playtests/owner-feedback.md` #24 (part 1 fixed: the test names above), the spec, the plan.

## What the lead should check on the emulator

1. **Animals by day** (Sandbox, a herd near spawn): they graze and wander, members follow the first one; walk
   into a herd: a question mark over one that comes to sniff you; place a block next to them: a curious one
   comes to look.
2. **Feeding:** select grass, tap a sheep: a heart; walk 10 blocks away and stand: it runs over to you.
   Hit it with the sword: a sweat drop, it runs and keeps about 9 blocks away from you for a minute.
3. **Night** (`/time night`): herds walk to a tree near their home and lie down together with zzz (at most 3
   bubbles at once); `/time day`: they get up.
4. **Pets:** tame a dog, Save & Quit, continue: the dog is back and (host) its saved mind has your name.
5. **Bubbles:** readable at a distance, facing the camera, no stutter the first time one appears (prewarmed);
   Reduce motion ON: no bob or pop. On a LAN guest the same bubbles appear.
6. **Bot friends (Sandbox):** add a builder, build a small tower of blue blocks: its next build is blue; break
   one of its builds: the next is a different design and a bulb shows; add an explorer near gold and a wild
   dog, tame the dogs it shows and ignore the gold a few times: it shows dogs first; add a fighter, `/summon
   goblin` on one side a few times: it stands guard on that side. Save & Quit, continue: "Hi <name>! It's me…".
7. **Performance (the budget):** the autopilot in both styles with herds around and three friends: ≥ 30 FPS,
   no frame over 100 ms. Desktop numbers above: minds 0.03–0.04 ms per frame; the livelier animals walk more
   (≈ +0.2 ms desktop, maybe +0.6–1 ms on the emulator) — if the emulator is tight, raise
   `Animal.SENSE_EVERY` or the graze share in `AnimalSpecies` (graze row), not the net.

## Part 2: monsters (after Task 5, stealth)

Built after the lead's message (Task 5 merged): the worktree was brought up to date with `git merge
m2-survive-the-night` (a fast-forward to `260cf8b`: part 1, stealth, defenses, waves, the Golem, golden slimes,
M4 online work). Baseline suite there: 2354 tests, 2353 passing + 1 risky (`test_an_unowned_id_is_not_placeable`
does not assert; not this task's), exit 0.

### What a monster's mind does

While a monster **chases what it sees** (stealth's "!"), its `mind` (a `Mind` on its kind's table in this world,
`MindBook` key `monster:goblin` / `monster:slime`) picks a tactic, keeps it 2.5–3 s (a call 0.5 s) unless
something happens (a hit), and the tactic **only steers** `_dir`:

| Tactic | What the child sees and hears | When it can be picked |
|---|---|---|
| straight | comes straight at you (Task 4's chase) | always |
| zigzag | weaves from side to side, 0.8 rad off the line, switching every 0.6 s (a slime hops side to side) | 5+ blocks away |
| go round | curves round to your side (aims 4 blocks beside you, on the side it is already on from where you look), then in | 5+ blocks away |
| wait by cover | stops (or steps to a spot 2 blocks off with a block between it and you, if there is one) and watches you; thinks again when you come within 4 | 6+ blocks away, and you hold a bow, boomerang or spear or look its way |
| back off | steps back at the wary pace (0.6 × chase speed), **facing you**, to 7 blocks; not again for 8 s (you can chase it) | its hearts below 60 % |
| call a friend | a growl (goblin) or squish (slime) you hear; up to 2 quiet monsters within 12 blocks come to where you are with "?" first (never straight to "!") | a quiet monster near, not in its last 20 s |

Within 3 blocks every tactic comes straight in and attacks exactly as before (the goblin's 0.8 s wind-up, the
slime's touch). The senses at a pick: how near you are, whether you look its way (the avatar's yaw), what you
hold (`MonsterSpecies.weapon_class`: bow, boomerang and spear reach far; sword, axe, hammer, mace up close),
its own hearts, a quiet friend near, hit lately, **shot from far lately** (a hit with nobody within 5 blocks),
and the drives boldness and caution (goblins bolder, slimes more careful). Hand-made defaults: a fresh goblin
mostly comes straight (tested: > 25 of 60 picks against an archer), a badly hurt one often steps back.

**Lessons** (only when something happens): landing a hit +1, getting within 3 blocks +0.3, a friend answering
a call +0.2, being hit up close −0.3, **shot from far −1**, defeated −1 — credited to the tactic it picked.
Every monster of a kind in a world shares one table, so the goblins of a world slowly change their tactics over
many nights (saved in `WorldMeta.minds`; with the animals' tables the world still saves under 2 KB, tested).
The drift of every learned weight is **capped by the universe**: ±0.75 in universe 1, +0.25 per universe after
it (`TinyNet.max_delta`, at most `MAX_DELTA` 2).

### Fair-fun guards (spec §12.17)

- **Never more damage, speed, sight or hearts** than §12.4/§12.5: tactics only choose a direction or standing
  still; the speed comes from Task 4's `_move_speed()` (backing off uses the wary pace), perception is stealth's
  `perceive()` (untouched), hits are `MonsterRules.hit`, hearts `MonsterRules.hp`. Tested for every tactic
  (fastest step ≤ `MonsterRules.speed`, one hit = §12.4's, `PERCEIVE_RANGE` unchanged).
- **Never changes blocks:** the tactics read the world through `block_at` only (the cover spot); Task 4's
  `test_monsters_never_change_blocks` (scenario + source scan of every monster file) stays green.
- **Eases off after the child's knock-outs** (honest help, research G3): `Session.knockout_received` → that
  child's ease +0.5 (at most 1), fading with a 2-minute half-life. Against that child, with the chance of the
  ease, only straight (at ease 1) or straight / back off; and learning × (1 − ease), so knocking a child out
  teaches the goblins nothing. Tested with two knock-outs: four goblins in a row come straight and the table
  does not move.
- **Sandbox's gentle monsters learn slowly** (0.3 × the lesson; tested against a normal lesson). **Cozy worlds**
  (`Session.difficulty == DifficultyRules.COZY`): no learning at all, and only straight or backing off.
- **Golden slimes never think** (no mind; they keep Task 16's run-away rules).
- **Stealth, lanterns, doors, waves stay:** the ? / ! marks are stealth's; Task 8's lantern fear runs after the
  tactic's steering in `_decide` (tested: level 1 slimes and goblins weaving and curving in still stay 6 blocks
  from a lantern), the door checks sit in the steps (untouched); a wave monster that sees nobody still walks to
  the Totem (tactics are for a chase). All their tests are green.
- **The one-time hint:** after a lesson, for each tactic not told yet: if the tactic itself worked (its own score
  in its situation rose by 0.2), it is now the kind's first choice there and wasn't at the start, every child
  gets a toast once per world (`MonsterSpecies.HINTS`: "The goblins remember your bow. They zigzag now!", "Hurt
  goblins step back now. Go after them!", "Goblins call their friends now. Listen for the growl!" …; saved in
  `WorldMeta.mind_hints`, never again after a reload).

### Code

| File | What |
|---|---|
| `core/mind/species/monster_species.gd` (`MonsterSpecies`) | Tactics, senses, hand-made features and rows per kind, rewards, `allowed()`, `cap()`, `weapon_class()`, the hints and their situations |
| `core/mind/monster_minds.gd` (`MonsterMinds`) | `MonsterMinds.current`: difficulty, gentle, easing per child, `learning()`, `restrict()`, `check_hints()` and signal `hint`, `clean_hints()` |
| `core/mind/tiny_net.gd` | `max_delta` (the universe cap); `MAX_WEIGHT` 4 → 5 (ruling 27) |
| `core/mind/mind.gd` | `hold(action)` (a scripted pick: tests, the bench) |
| `entities/monsters/monster.gd` | The stealth `mind` is renamed **`awareness`** (the lead's note; the creature Mind is `mind`, like animals and friends); one-line hooks: `_mind_tick()` at the top of `_decide`, `_tactic_steer()` in the chase branch, `_mind_took_hit()` in `take_hit`, `_mind_landed()` in `_hurt`, and one in `_turn` (backs off facing you); a section at the end (tactics, the cover spot, the call, lessons, `use_tactic()`) |
| `world/world_meta.gd` | `mind_hints` (parsed: known hint keys only) |
| `scenes/sandbox.gd` | `_start_monster_minds()`: the guards from the world (difficulty, gentle), the hints (toasts to every player through `Session.send_feedback`), knock-outs, a 1 s clock for easing; hints saved with the world |
| Tests renamed | `test_monster_stealth.gd` (7 lines), `test_stealth_director.gd` (4), `test_monster_defenses.gd` (1): `.mind` → `.awareness` |
| `tools/minds_bench*.gd` | 20 chasing monsters added (the friends' swings hurt nobody, so all 20 stay) |

### Tests (RED → GREEN)

| Test file | Tests | RED |
|---|---|---|
| `tests/unit/test_monster_mind.gd` | 15 | "MonsterMinds / MonsterSpecies not declared" (written first); then a parse error: a method named `ease()` clashes with the global `ease(x, curve)` (renamed `ease_of`); "Cannot convert 1 to boolean" (bit masks in `assert_true`); the hurt goblin stepped back 4 of 60 times — a hand-made weight of 5 (then 8) was **silently clipped to TinyNet.MAX_WEIGHT 4** (the feature is scaled now, and the new `test_hand_made_weights_are_never_clipped` found part 1's dog, 4.55, and rabbit, 4.2, clipped too: `MAX_WEIGHT` is 5 now); the first hint rule fired all five hints once straight was punished (now a hint needs the tactic itself to have worked) |
| `tests/integration/test_monster_minds.gd` | 15 | first run after the code; the tests found: backing off turned the goblin's back, so it lost sight and rushed back in (it steps back facing you now); a waiting goblin whose child came within 3 blocks kept the label "wait" while coming in (close up the tactic is straight); tactics stayed set after a chase ended (cleared outside "!"); hints were checked at most every 2 s of wall time, so a lesson right after another was never looked at (checked at every lesson now: lessons are rare). Mutation checks: without `restrict()` and with learning always 1, the knock-out, Cozy and Sandbox tests fail |

Commits: `ec7ccb4` (monster minds) and this notes commit. Suite: **2354 → 2384** tests (2383 passing, the
same 1 risky test as before), exit 0.

The plan's test: `test_a_goblin_shot_from_far_learns_to_zigzag_within_a_few_encounters` (each night a new
goblin; straight at the archer: arrows from far; zigzagging in: it reaches the child) — the world's goblins
prefer zigzag after 1–5 encounters, one hint says so, and the table is saved.

All of Task 4's, 5's, 8's, 9's, 10's and the golden slimes' monster tests are unchanged apart from the rename
and green: `test_monster` 23, `test_monster_stealth` 17, `test_stealth_director` 14, `test_monster_defenses` 8,
`test_monster_director` 25, `test_monster_combat` 8, `test_wave_monster` 3, `test_waves` 25, `test_golden_slime`
2, `test_defense_director` 17, `test_doors` 16, `test_stone_golem` 15, `test_boss_director` 18.

### Numbers (desktop, this thread's CPU time; load average 4–22)

| What | Result |
|---|---|
| A monster's mind step per decision (tick + tactic steering) | 4.2–5.6 µs |
| A tactic pick (senses, mask, guards, think) | 24–27 µs (about 0.55 picks per frame for everything in the bench) |
| **All minds per frame: 20 monsters + 24 animals + 3 friends** | **0.046–0.056 ms** (budget 0.3 ms) |
| 20 chasing monsters' whole physics step per frame | 0.91 ms (Tasks 4/5 measured 0.94 ms for 20 chasing, before minds) |
| Monster smoke run on real terrain (`tools/monster_smoke.gd`, Survivor) | every check ok, `fails=0`, no engine errors or warnings (its frame times were taken while the suite ran: not used) |

A pick at 24–27 µs is over the spec's 20 µs per decision; picks are rare (a chase start, every 2.5–3 s, a hit),
and the per-decision step is 4–6 µs (ruling 17 applies).

### Rulings (part 2; cost if wrong)

18. **The stealth state is renamed `awareness`; the creature Mind is `mind`** (like animals and friends).
    *Cost if wrong:* other branches that still say `monster.mind.state` need the rename (a merge shows it).
19. **Tactics only while the monster sees its target;** searching, "?" and walking to a noise stay stealth's.
    *Cost if wrong:* a lost chase is always straight to the last known spot.
20. **Within 3 blocks everything comes straight in** (the attack is unchanged). *Cost if wrong:* none known.
21. **"Shot from far" = hit with no player or friend within 5 blocks.** *Cost if wrong:* a boomerang thrown
    from 4 blocks counts as close.
22. **Cozy = no learning and only straight or backing off** (the spec says "switch monster learning off"; the
    plain tactics follow Cozy's gentle spirit). *Cost if wrong:* Cozy monsters never zigzag or go round.
23. **Easing is per child, +0.5 a knock-out, half-life 2 minutes.** *Cost if wrong:* a child knocked out once
    meets clever monsters again a few minutes later.
24. **A call brings at most 2 quiet monsters within 12 blocks, with "?" first, once per 20 s per caller.**
    *Cost if wrong:* bigger crowds at night; three constants.
25. **Backing off: at most to 7 blocks, not again for 8 s, at the wary pace, facing the child.** *Cost if
    wrong:* tune the constants.
26. **Hints are toasts** (`Session.send_feedback` to every player), once per kind and tactic per world. *Cost if
    wrong:* a child who can't read misses them (the behaviour itself is the signal).
27. **`TinyNet.MAX_WEIGHT` 4 → 5**, so hand-made weights are what they say (dogs come a little more readily,
    rabbits flee a little sooner than in part 1). *Cost if wrong:* those two species' defaults move a little.
28. **No thought bubbles over monsters** (the stealth marks already float there; tactics show in the movement).
    *Cost if wrong:* a child reads a monster's plan less easily.
29. **The Stone Golem keeps its fixed, signalled attacks** (it is not a `Monster`; its fight has its own honest
    help, Task 10). *Cost if wrong:* the boss doesn't learn.

### Merge notes (part 2)

- `entities/monsters/monster.gd`: the rename (`mind` → `awareness`, 25 places) touches every stealth line;
  anyone editing monster perception in parallel will conflict there. Hooks: `_decide` (2 lines), `take_hit`,
  `_hurt`, `_turn`; the section at the end.
- `world/world_meta.gd` (`mind_hints`), `scenes/sandbox.gd` (`_start_monster_minds`, one line in `save_world`).
- `core/mind/tiny_net.gd` (`max_delta`, `MAX_WEIGHT`), `core/mind/mind.gd` (`hold`).
- `docs/DEVELOPMENT.md` §4 (the bench) and §5 (creature minds); not touched: the M2 dev log row, owner feedback
  #24 (part 2 done: the test names above), the spec, the plan.

### What the lead should check on the emulator (part 2)

1. **Survivor at night with a bow:** shoot goblins from far over a few nights (or `/summon goblin` in Sandbox,
   which learns 0.3 × as fast): at first they come straight; after a few arrows they weave in, and one toast says
   "The goblins remember your bow. They zigzag now!" (once per world, also after Save & Quit and continue).
2. **Tactics look fair:** a zigzag is readable (not jittery), going round is a clear curve, a waiting goblin
   stands and watches (the "!" stays), a hurt goblin steps back facing you and comes again, a call is heard
   (growl / squish) and a friend comes with "?". No monster is ever faster than before.
3. **Knock-outs:** after being knocked out twice, monsters come straight at you for a few minutes.
4. **A Cozy world:** monsters never zigzag or go round, and no hint ever appears.
5. **Lanterns, doors, the Totem:** weak monsters still keep 6 blocks from a lantern while weaving; doors still
   stop them; a wave still walks to the Totem.
6. **Performance:** the autopilot at night with 20 monsters (both styles); desktop minds cost 0.05 ms per frame.
