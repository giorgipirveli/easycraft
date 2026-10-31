# M3 Task 21c: the wonder pack — the Tiny world, waking more things, building sounds (notes)

Brief `docs/superpowers/briefs/prompt-m3t21c.md`; spec §3a (Size Magic "tiny-only secrets"), §16 ("a Tiny-only mouse
village", "building sounds", "wake more objects"), new **§14.22**; plan M3 Task 21 (21c). Built by a background agent in
its own worktree (branch `worktree-agent-a2c7cb49dafb1088b`, cut from `m2-survive-the-night`, `lead-merge` merged in
first and again as it moved: #45b, #39, #41, Nell, the lead's fixes, M4 ghost races and M3 Task 21a's Georgian), without the editor or the emulator.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Block page 14 | `data/blocks/tiny_page.gd` (`TinyPage`), `BlockIds` 272–275, `tools/make_tiny_page.gd` / `.py` | the pumpkin, the glowing jack-o-lantern, the snowman's head (coal eyes, a carrot nose, a top hat on top) and the mice's tiny cheese; both styles (the realistic twin painted from the pixel designs with CC0 ambientCG Plaster001 and Snow003 grain). The Sandbox palette's MAGIC row and Tilly's HOME (3 / 6 / 4 gold) have the first three; the cheese is treasure only (`LootRules.TREASURE_ONLY`, never `/give`n or sold) |
| Building notes (pure) | `core/building/build_notes.gd` (`BuildNotes`) | the major pentatonic scale (C D E G A), each block family's note (stone low … glass and lights high), two voices (a wooden marimba; a bell for glass, crystal, ice, lamps), exact pitches (semitone ratios, no random wobble), `Melody`: the next block within 1.5 s and 2 blocks of the last climbs a degree (a phrase of 6, then again from the row's first note); the budget: a note at most every 70 ms and 8 in any second |
| Building melody | `entities/player/build_melody.gd` (`BuildMelody`, the BlockInteractor's child `melody`) | plays the notes from its own pool of 4 `AudioStreamPlayer3D`s on the Effects bus (made once, never grows; Audio's pools untouched), reports each as `build_note` through `Audio.sound_played` (owner #50's counting tools); one note per tap, stamp, paint tap or tool step (LINE, FILL, PASTE: once, never once per cell); "Block music" off plays the plain pop as before |
| Setting | `ui/menus/settings_panel.gd` (`_add_block_music`), `ProfileData.DEFAULT_SETTINGS.build_notes` (on) | SETTINGS → LANGUAGE & HELP → Comfort: **Block music**, beside Reduce motion |
| Wake kinds (pure) | `core/magic/wake_kinds.gd` (`WakeKinds`) | a woken build's kind from its solid blocks (flowers it stood among don't count): CACTUS (mostly cactus), PUMPKIN (mostly pumpkins, or a build of ≤ 12 with a pumpkin on top: a scarecrow), SNOWMAN (a snowman's head on top of mostly snow blocks); names and wake words of their own; the chest mimic's rules: `mimic_hop` (≤ 1.4 blocks a hop, stops 1.6 from the child, never up or down more than a step), `feet_near`, `mimic_present` (one small thing fixed by the chest; never gold, never treasure), the words (never scary) |
| Woken looks | `entities/buddy/buddy.gd` section "M3 Task 21c" | a cactus's pink flower pops out when it cheers (one shared mesh), a jack-o-lantern glows orange, a pumpkin rocks and rolls as it lands and giggles when cheered, a snowman puffs snow as it lands (at most once a second) |
| Mouse villages (pure) | `world/generators/mouse_villages.gd` (`MouseVillages`), `SecretRules.tiny` (`tiny_in_area`, `tiny_near`, `block_at`, `find`, `is_kind`) | at most one per 128-block area, 4 seeded attempts; a door 1 block high at the foot of a hill (HILL: the natural ground buries half the room) or between a big old tree's log roots on a grassy knoll (KNOLL: a built mound, its sides and back a block down a block to f − 1, its front the door's wall), a 2-block tunnel, a 5 × 5 × 3 room (plank / sandstone / snow-brick / gingerbread walls, the mice's houses — a red-roofed house, a pumpkin, cactus, snowman or jack-o-lantern house, a barrel to hide in — a lamp in the back wall and one on a post), the tiny chest at the back; a level doorstep open to the sky; a marker by the door (pumpkin; the desert: two cacti; Frostpeak: packed snow and a snowman's head; the Candy Kingdom: a jack-o-lantern) |
| Placement rules | the same | the seed, the area and the terrain alone; every box inside its area (seam-safe); **never listed in `secrets_in_area`**, so no M2 secret, no treasure-pack place (#42) and no wild-meadows place (#45b) moves: the village keeps `GAP` (4) from the area's secrets and from the places of the regions it touches (the generator's own `MeadowsPlaces`, lent by `share_places`, or its own through a weak `SecretsView`); 60 blocks clear of the spawn; dry land, no river, no trunk on the doorstep or by the marker; the ground round a knoll no lower than its slope's foot. Not in the Dragon Realm (`fits_terrain`) or the arena |
| Generators | `MeadowsGenerator._place_secrets` (one line), `MeadowsBiomeGenerator._make_secrets` (lends its places) | every generator writes the villages after the secrets (and after the wild meadows' places); `reference_block` has them through `SecretRules.block_at` |
| Host and every game | `world/tiny_director.gd` (`TinyDirector`, node `Secrets/Tiny`) | host: a TINY child whose feet are in a room finds the village (the director's banner, chime, book); the mouse family near players; the chest mimic (below). Every game: its own player, not tiny and not a ghost, in a room is shown out to the door ("Too big for the mouse village! …") |
| SecretDirector hooks | `world/secret_director.gd` (marked "M3 Task 21c") | its child `Tiny`; villages near players in its host tick (chime, things, the book's count of an explored area), `/secret` hints, the find words and picture, a bot's notice line, the plate tick drives the mimics, `make_thing` asks `TinyDirector` |
| The mice | `entities/interactables/mouse_family.gd` (`MouseFamily`) | two grown-up mice (an apron, a shirt) and a little one, as tall as a tiny child: they turn to the nearest child within 5 blocks and wave, squeak hello (at most every 8 s); a tap: a squeak and a hop. Two shared meshes, looked at 4 times a second |
| The tiny chest | `TreasureChest` (one line: scaled 0.45), `MouseVillages.loot` (through `LootRules.roll`) | the cheese (the Secret Book's shelf), one little thing fixed by the chest, and in Survivor 10 gold × 2^(u−1), always the same |
| The chest mimic | `entities/interactables/chest_mimic.gd` (`ChestMimic`), `TinyDirector`, `Session` section "M3 Task 21c" (`request_wake_chest`), `SecretTaps` (the wand on an **opened** chest) | googly eyes, a giggle; it hops after the child who woke it (the host decides each hop 10 times a second, `hop_to` to every game: an arc, a clop, a squash), opens wide with its tongue out for a small present (never gold), puffs back to sleep; the still chest hides meanwhile. Once per chest (`SecretState.solved["mimic:<id>"]`), at most 3 awake, within reach; counts as waking a buddy (M3 Task 12) |
| Secret Book | `ui/hud/secret_book.gd`, `ui/hud/pictures.gd` (one line), `ui/hud/tiny_pictures.gd` (`TinyPictures`) | page 1 gets a Mouse Village slot: a picture riddle (a tiny door in a hill, "A tiny door by a hill. Get small!") until found, then the mouse's face, the name and the count. Pictures drawn in code as 16 px text rows, ids 64+ |
| Chat | `core/rules/chat_commands.gd` | `/secret mice` (Sandbox) |
| Sounds | `tools/make_tiny_sfx.py`, `autoloads/audio.gd` | `build_note_wood.wav`, `build_note_bell.wav` (C4, 32 kHz), `mouse_squeak_1/2.wav`, `mimic_hop.wav` (original, credited) |
| Tools | `tools/tiny_smoke.gd` (+ steps), `tools/tiny_bench.gd` | the end-to-end smoke run in a real world, the placement bench |

## Skills and patterns (godot-prompter)

- **procedural-generation:** a seeded RNG per area whose numbers are all drawn up front (the attempts never depend on
  the terrain checks), placement checks against the terrain rules (not the voxels), reachability by construction
  (a level doorstep, a 1-high door, the room closed but for it) and proved by a flood fill in the tests (a body 1 block
  tall walks in, one 2 blocks tall never does); a mutation (a 2-high door) made that test fail. Rejected: noise-based
  scattering per column (its own seam handling) and cellular-automata burrows (organic, but hard to prove a door is
  the only way in and that nothing else opens a hillside).
- **audio-system:** an SFX pool of positional players made once (`BuildMelody`, 4), one short sample per voice pitched
  by the scale's exact ratios, the Effects bus (the SOUND EFFECTS slider still works), a budget instead of per-player
  `max_polyphony`. Rejected: an `AudioStreamGenerator` synthesising notes at run time (a mix thread's work every frame
  on a phone) and `AudioStreamPolyphonic` (one player, but no per-note position, and no clean count for the budget).

## Tests (RED → GREEN)

| File | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_tiny_blocks.gd` | 10 | `TinyPage` and the block ids missing |
| `tests/unit/test_build_notes.gd` | 8 | `BuildNotes` missing |
| `tests/integration/test_build_melody.gd` | 6 | `BuildMelody` missing (the LINE test: one note for an 11-block line; a paint tap one) |
| `tests/unit/test_wake_kinds.gd` | 10 | `WakeKinds` missing; later `feet_near`; then a pumpkin among flowers (the smoke run found it) |
| `tests/integration/test_wake_buddies.gd` | 4 | `Buddy.flower()` missing |
| `tests/unit/test_mouse_villages.gd` | 12 | `SecretRules.tiny_in_area` missing; then "at the foot of a hill" (no HILL in the green meadows: hills now count where the ground buries the roof, and the test looks in the desert and Frostpeak too); then the walk-over test found 2–3 block steps at a knoll's edge (the slope now goes down to f − 1 and the ground round it may not be lower) |
| `tests/integration/test_tiny_world.gd` | 10 | `TinyDirector`, `MouseFamily`, `ChestMimic`, `Session.request_wake_chest` missing; then "they wave" (the test's players were hidden: a spawned body is visible) |
| additions | +2 | `test_settings_panel` (Block music), `test_secret_book_pages` (the mouse village's slot) |
| adjusted | | `test_meadows_blocks` (COUNT ≥ 272), `test_chat_commands` (one more `/secret` choice), `test_secrets_in_world` (an explored area's count has its villages), `test_secret_book_pages` (page 1 has one more slot) |

Full suite: see "Suite" below.

## End to end in the real game (no editor, no emulator)

`tools/tiny_smoke.gd` (headless, new Sandbox world, seed 12345, terrain 2): **27 checks pass** — the nearest village
(`mice_0_-1_65`, a knoll, 89 blocks from the spawn) is in the generated terrain (893 cells of its boxes compared, 0
differ), a normal-size child walking at the door for 3 s stays outside (0.8 blocks short), a tiny child walks in with
the real input and physics in 1.8 s and finds it, the mice (waving) and the tiny chest come, the cheese, the wand wakes
the opened chest (it hops, gives its present, sleeps; once), growing in the room shows the child out, a pumpkin wakes as
"Pumpkin" ("Pumpkin is awake! It loves to roll."), `/secret mice`, the save keeps the find and the mimic.

## Measurements

`tools/tiny_bench.gd`, this PC at load 25–31 (other agents building):

| Universe | Villages in 225 areas | A new area's villages: avg / worst ms |
|---|---|---|
| Green Meadows (old) | 48 | 1.9 / 10.1 |
| Wild meadows | 38 | 3.2 / 19.8 (its places worked out too) |
| Desert | 116 | 3.0 / 14.9 |
| Frostpeak | 92 | 2.2 / 15.1 |
| Candy Kingdom | 108 | 7.3 / 30.0 |

A village's chunks: 3.68 ms with villages against 3.66 without (old meadows), 7.97 against 8.69 (wild meadows): the
same within the noise. Placement runs on the generator's threads; the host's SecretDirector (its own SecretRules) finds
the same answers in the cache every `MouseVillages` of a world shares, so it places an area on the main thread only
when it asks before the generator got there (`/secret` looks 700 blocks round). Measure the first steps into new land on
the emulator (a phone is 3–5× slower).

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **Block page 14 (ids 272–275), not block 219 on page 10**: the lead's newer allocation for this agent (the brief's 219
   stays free). *Cost:* none.
2. **Villages are apart from the secrets** (`SecretRules.tiny`, never in `secrets_in_area`): nothing placed before
   moves; a village gives way to secrets and places instead. *Cost:* fewer villages where secrets and places crowd.
3. **Worlds saved before get villages in chunks never edited**, like the treasure pack (#42 ruling 3). *Cost:* a village
   crossing an edited chunk is cut there (a half knoll next to an old build, rarely).
4. **No mouse hole "under Tilly's stall"**: Tilly stands only in Survivor worlds, 12 blocks from the spawn, and the
   terrain generator doesn't know the mode (a Sandbox world would have a hole and no stall); the spawn's 60 blocks stay
   clear of places. *Cost:* one of the brief's three kinds of hole; a painted mouse door on the stall could come later.
5. **The way in is level** (a tiny child can't climb a block: its jump is 0.5 blocks): children shrink at the door (MORE →
   SIZE). Hints: the pumpkin by the door, the secret chime, the Secret Book's riddle "Get small!", an explorer bot's
   "Only tiny friends fit in there." *Cost:* a child has to think of shrinking.
6. **Found only by a tiny child; a normal-size child in the room is shown out** to the door (its own game, twice a
   second; not in Ghost mode). *Cost:* a child who digs in never looks round the room at normal size (they can shrink).
7. **Knolls in green land, hills where the land is steep:** HILL when the natural ground buries half the room's shell,
   else a built knoll with a big old tree; the green meadows are gentle, so their doors are mostly in tree roots, while
   the desert's mesas and Frostpeak's peaks have hill doors. A knoll's front is the door's wall (6 blocks); its sides
   and back go down a block at a time (walked over). *Cost:* few "foot of a hill" doors in green worlds.
8. **Density:** at most one per area, 4 attempts (0.55 / 0.45 / 0.4 / 0.35); seed 12345, 169 areas: 38 old meadows, 27
   wild meadows, 86 desert, 72 Frostpeak, 84 candy. *Cost:* tune `ATTEMPTS`.
9. **One cache per world** (static, keyed by the seed, the terrain's and the rules' scripts and the treasure pack), shared
   by the generator's and the director's `MouseVillages`. *Cost:* two different rule sets with the same key would share
   answers (none known).
10. **The tiny chest:** the cheese (a legendary treasure-only block, so the chest glows gold), one little thing fixed by
    the chest, 10 gold × 2^(u−1) in Survivor, always the same (§6). *Cost:* none known.
11. **The chest mimic:** the wand on an **opened** chest (a closed one opens as always), once per chest (saved in
    `SecretState.solved` as `mimic:<id>`), at most 3 awake, 6 hops of 0.6 s, a present of one small fixed thing (never
    gold or treasure), then back to sleep; it counts as waking a buddy. Never harmful: a tap-only thing (layer 512, mask
    0), never a monster, no attack. *Cost:* a chest wakes only once.
12. **Wake kinds by their own blocks** (the majority of its solid blocks; a snowman needs the snowman's head on top):
    Task 20b's secret shapes (e.g. a snowman of snow blocks with an orange nose) stay 20b's. *Cost:* see "for the lead".
13. **Notes replace the pop** for taps, stamps, paint and LINE / FILL / PASTE steps; other placements (quick builds,
    chat `/fill`) keep their own sound. A row = the next block within 1.5 s and 2 blocks. *Cost:* those still pop.
14. **Block music is on** in a new profile, on SETTINGS' LANGUAGE & HELP page beside Reduce motion ("Comfort"): the
    last row and the game page's toggles are too wide once Georgian (1379 px with it on the last row; 1218 there).
    *Cost:* a grown-up who wants it off looks on the second page.
15. **Tilly sells** the pumpkin (3), the jack-o-lantern (6) and the snowman's head (4) × 2^(u−1); the cheese is never sold.
16. **Georgian (M3 Task 21a merged in):** 21 new lines in `i18n/ka.po` (under "Added by M3 Task 21c", native check
    needed); a woken cactus's, pumpkin's or snowman's names stay as they are (21a's ruling 5: `i18n/not_words.txt`), as do
    the pictures' palette rows; the wake words, the tiny chest's and the mimic's banner titles and the `/secret` name are
    translated before they are filled in or joined (`Lang.t`). *Cost:* the Georgian needs a native speaker's check.

## For the lead (merge)

- **Task 20b (buddy magic, running now) overlaps in `scenes/sandbox.gd` `_on_spark`**: I changed the buddy's name
  (`WakeKinds.name_for`) and the wake line (`WakeKinds.wake_line`); 20b's secret shapes will change the same lines.
  Suggested order: 20b's recipe first, then `WakeKinds`, then the ordinary buddy. Its snowman recipe (snow blocks + an
  orange nose) is not a `WakeKinds.SNOWMAN` (that needs block 274 on top). `Buddy` has a new section at its end.
- **Likely conflicts:** `world/secret_director.gd` (hooks marked "M3 Task 21c"), `world/generators/secret_rules.gd`
  (`tiny`, `_init`'s 4th argument), `ui/hud/secret_book.gd` (page 1's slot; Task 21b may add pages), `autoloads/session.gd`
  and `autoloads/audio.gd` (end sections), `core/rules/chat_commands.gd` (`SECRET_KINDS`, NEVER_GIVEN, TREASURE_ONLY),
  `core/rules/loot_rules.gd`, `data/blocks/block_ids.gd` (COUNT 276), `ui/hud/block_palette.gd` (MAGIC_BLOCKS),
  `core/economy/shop_rules.gd`, `ui/menus/settings_panel.gd` (last row), `scenes/sandbox.gd` (`_on_spark`, one line in
  `_start_places`), `entities/player/block_interactor.gd`, `entities/interactables/secret_taps.gd`, `assets/CREDITS.md`,
  `docs/DEVELOPMENT.md`, the spec (§14.22) and the plan.
- **Seen, not changed (#45b's):** the wand takes flowers and wheat along with a build (they are not in
  `CaptureRules.GROUND`); a house built in a flower field wakes with the flowers round its feet. `WakeKinds` ignores them.

## What to check on the emulator

1. A new Sandbox world: `/secret mice` and its `/tp`: the knoll with its old tree, the pumpkin by the door, the log roots
   round the 1-block door (both styles); in a desert world a mesa door with two cacti, in Frostpeak a small snowman.
2. MORE → SIZE → TINY at the doorstep, walk in: plank walls, the little houses, glowing mushrooms; the mice wave and
   squeak; "You found a mouse village!"; the Secret Book's first page: the riddle before, the mouse after.
3. Tap the tiny chest: the cheese on the shelf (its page-14 icon), "The mice's treasure!".
4. The wand, tap the opened chest: googly eyes, a giggle, it hops after you, opens wide with its tongue, the present's
   banner, a sparkle puff, the still chest back. Tap again: "The chest is fast asleep. Zzz..."
5. SIZE to normal inside the room: shown out to the door with the toast.
6. Build a row of planks: rising notes; glass rings like a bell; a LINE of 20: one note; Mirror on and building fast:
   never a flood of notes; SETTINGS → LANGUAGE & HELP → Block music off: the plain pop.
9. In Georgian: the wake words, "თაგვების სოფელი იპოვე!", the Secret Book's slot, Block music on the second page.
7. Wake a pumpkin, a jack-o-lantern (an orange glow), a cactus column (`/give cactus`), packed snow with a snowman's
   head: their names and words, the flower, the roll, the snow puffs.
8. Frame times while walking into new land in a new world (mouse villages are placed with the secrets).

## Suite

- Before (lead-merge as this task started, 04:55): 516 scripts, 5018 tests, 5013 passing (3 failures of the night's
  merges, fixed by the lead since).
- After (this branch with lead-merge up to M3 Task 21a and M4 ghost races merged in, 09:40, load 25–28): **553 scripts,
  5295 tests, 5292 passing**, 2 risky (the wild meadows' generator tests that "did not assert", as before) and 1 failure,
  `test_secret_hud`'s count of the Secret Book's first page (8 slots; it has the mouse village now): the test fixed,
  its file rerun 9/9. 63 tests are new (the table above), 6 adjusted.
- `tools/i18n/words.gd -- --missing`: MISSING 0 without Georgian, 0 formatted without tr().
