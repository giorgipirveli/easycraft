# M3 Task 20b — Buddy magic: secret shapes, the Buddy Album, My Stamps, befriending, mini-buddies, tricks

Agent notes, 2026-09-25. Spec §14.21 (added by this task), §16 (signature moments "secret buddy shapes", "the Golem that
becomes a tiny Pebble Golem friend", "the buddy that learns your dance"), research D1, C2, P2, P4, P5, plan Task 20
(20b). Branch cut from `m2-survive-the-night`, `lead-merge` merged in first (owner #39, #45b, M3 Task 8 ...), and
twice more (owner #41's animals and Nell; M3 Task 21a's words and voices and M4's ghost races).

## What was built

| Part | Files | What |
|---|---|---|
| Secret shapes | `core/magic/buddy_recipes.gd` (`BuddyRecipes`) | 8 recipes (snowman, lantern robot, flower pot, singing castle, lighthouse, rainbow caterpillar, crystal fairy, puppy): cells of block classes (any white block, any lamp, ...); `match_blocks` turns the build 4 ways and mirrors it, forgives ONE spare block, never tips it over; the first recipe that matches wins (no two recipes match each other: tested); each with a name, a title, a name-tag colour, traits (a fairy floats, a lighthouse glows bright), a thing it does (`act`, `every` seconds), a sound, a riddle; `silhouette` (the front view for the book), `block_of` (a class's picture block). |
| The special buddy | `entities/buddy/buddy.gd` (5 hooks + section "M3 Task 20b") | `recipe` from its blocks on every game (a save and a guest need nothing more), the recipe's traits before `_build`, the tag's colour; its act now and then on every game by itself (the shared `Fx` material, `Audio`; bursts only near this game's camera): snowflakes, a beep and a wave, growing (`grown`, the look only, up to 2×; the collision box never grows; a landing's squash comes back to the grown size), a tune of four chimes, a light flare, a bark and a fetch (the host runs it ahead of its child for 2.5 s: `fetch_target` in `_goal`), a rainbow wiggle, twinkles. Tricks: `trick_state`, `learn`, `load_tricks`, `do_trick` (dance, spin, wave, hop, sit, bow), saved as `tricks` in `WorldMeta.buddies`. |
| Pictures | `core/magic/buddy_picture.gd` (`BuddyPicture`), `ui/hud/build_picture.gd` (`BuildPicture`) | A build's front (z = 0, the face side) as ≤ 8 × 8 cells in a short run-length code ("w.h:id,id*n,..."); drawn with the blocks' own icons (no photo, no new texture or material); `shadow` for a silhouette. |
| Profile | `core/magic/buddy_magic_data.gd` (`BuddyMagicData`), `core/save/profile_data.gd` (`buddy_magic`), `core/save/profile_backup.gd` (`is_new`, `merge`) | Shapes found (once each), the Buddy Album (name, recipe, picture, universe, unix time; the newest 40, older ones a count, `woken`), the bosses' minis (like Pip's record), the tricks of the profile's own pets (Pip, the baby dragon, the minis). `from_dict` never fails; the backup merge keeps every shape, album entry (by time and name), mini and trick. |
| Befriending | `core/magic/befriend_rules.gd` (`BefriendRules`), `entities/player/block_interactor.gd` (one line + section) | The wand on a monster: `Session.request_befriend`; the host (`BuddyMagicDirector.on_befriend`) checks reach, level ≤ 2, not chasing (CHASE or WINDUP), not a wave's, not golden, not Monster Wave, the pet cap; the monster goes, a pet of species `monster_friend` (its kind the animal's `variant`) comes with hearts, "Jelly is your friend now! It follows you and never fights.", `animal_tamed/monster_friend`. A tap on a boss with the wand: "Bosses are too big to be friends... but beat one and see what happens!" (this game only). |
| Mini-buddies | `core/magic/mini_rules.gd` (`MiniRules`), `world/boss_director.gd` (signal `boss_won`) | The Pebble Golem, Sandy the Mini Sand Serpent, Flurry the Little Frost Giant, Cupcake the Cupcake Monster (the Sky Dragon's is #39's baby dragon). The host tells every player's game (`Session.buddy_magic_tell`); each keeps it once in its profile and asks for it (`Session.request_mini`, like Pip); asked within 60 s of the win it hops out of the boss's spot with hearts. Species `mini_boss`, the boss kind as `variant`, id `mini_<kind>_<peer>` (`PetDirector.is_profile_pet`: never saved in a world), never a pet place. |
| Pets' looks | `entities/animal/magic_pet_models.gd` (`MagicPetModels`), `entities/animal/animal.gd` (3 hooks + section), `entities/animal/blocky_animal.gd`, `core/rules/animal_rules.gd`, `pet_rules.gd`, `voice_rules.gd`, `core/mind/species/animal_species.gd` | A friend: its monster's level-1 boxes without the club, bow or snowball, fitted to 0.8 × 0.75, pink cheeks; a mini: a small box model of its boss in the boss's colours. One shared mesh per kind, BlockyAnimal's material. The collar fits each model. Both glow softly in the dark (the one shared `PetGlow`, perk GLOW). |
| Tricks | `core/magic/trick_rules.gd` (`TrickRules`) | Three of the same emote near one's own buddy or pet (8 blocks) teach it; later it does its move with the child. No timers; never forgotten. |
| The host | `world/buddy_magic_director.gd` (`BuddyMagicDirector`, node `BuddyMagic`) | Album entries and the secret-shape reveal (`host_buddy_woken`, from `_on_spark`), befriending, minis, lessons (`on_emote` from `Session.emote_played`: "Scout is watching you... 2 more!", "Scout learned to dance!"; the move on every game by one reliable RPC), profile pets' tricks sent back (`request_pet_tricks`), minis going home with a guest. Every game: `on_told` (its own profile), `bring_minis`, `local_tick` (minis' names, collars, hearts into the profile). |
| Session | `autoloads/session.gd` section "M3 Task 20b: buddy magic" | `request_befriend`, `request_mini`, `request_pet_tricks`, `buddy_magic_tell` and their RPCs (names cut to 64, tricks cleaned, at most 16). |
| The Secret Book | `ui/hud/secret_book.gd` (section) | Page 4 BUDDY RECIPES (a slot per shape: silhouette + riddle, then the picture and name; "Secret shapes found: 3 of 8"), page 5 BUDDY ALBUM (a scrolling grid of cards, newest first: picture, name (purple for a shape), universe, day; "Buddies woken: 52 (not shown: 12 older)"). |
| My Stamps | `core/building/my_stamp_book.gd` (`MyStampBook`), `data/items/item_ids.gd` (`MY_STAMP_FIRST` 495, 5 slots), `data/blueprints/blueprints.gd`, `ui/hud/block_icons.gd` (a rubber-stamp icon), `ui/hud/block_palette.gd` (tab STAMPS, section), `ui/building/my_stamp_bar.gd` (`MyStampBar`) | NEW STAMP → the bar: the next tap on the world picks a build (`BuildPicker`, ≤ 16 a side, ≤ 1,600 blocks), it glows (`BuildOutline`), SAVE STAMP keeps it in `user://my_stamps.json`, turned so the side the child saw is its front (`PowerTools.to_stamp`). Placed by `Blueprints` like the preset stamps: one edit, one undo. The x deletes after SURE?. |
| The sandbox | `scenes/sandbox.gd` (`_add_buddy_magic`, `_start_buddy_magic`, `_setup_buddy_magic_local`, 4 lines in `_on_spark`, `_restore_buddies`, `_restore_pets`; section at the end) | The node on every game; the host's hooks (the pets' spawn, the monsters, `boss_won`); a woken buddy's name from its recipe and its album entry; saved tricks and a friend's kind back on load; this game's profile part, its minis brought along, My Stamps' bar (NEW STAMP). |
| Smoke run | `tools/buddy_magic_smoke.gd` + `_steps.gd` | The whole path on a real new Sandbox world, headless (DEVELOPMENT.md §4). |

Skills: `godot-prompter:godot-testing` (GUT, TDD: pure rules first, then the entities, the director and the UI with
injected callables); `godot-prompter:multiplayer-basics` — chose the house pattern (a request RPC to the host, the host
decides, synced properties and one reliable RPC per rare moment: a trick's move, hearts, a reveal); rejected syncing a
buddy's act (every game runs it from its own clock: nothing to send, a moment's difference between screens is harmless)
and syncing a trick counter (only the host counts lessons).

## Tests (RED → GREEN)

Ten new scripts, 91 tests; changes to six.

| Script | Tests | RED |
|---|---|---|
| `tests/unit/test_buddy_recipes.gd` | 12: eight recipes with names, hints and acts; each matches its own shape and no other; any block of a class; turned 4 ways and mirrored; one spare block yes, two no; the snowman's near-misses (a blue nose, no nose, the nose at the feet, two white blocks, a wooden bottom); other near-misses (a castle missing a tower, the rainbow out of order, a robot without arms, a caterpillar standing on its end); big builds; every class block wakes with the wand; the silhouette; `block_of` | parse error: no `BuddyRecipes` |
| `tests/unit/test_buddy_album.gd` | 13: the picture (the front, blocks hidden behind, the eyes' side, a big build shrunk, runs packed, broken codes), the album (an entry, the cap and the older count, cleaning), shapes found once, the profile round trip, hand-edited saves, `is_new`, the backup merge keeps everything | written with the next script before `BuddyMagicData`, `BuddyPicture` and `MiniRules` existed, then green (honest note: run green on the first try after the code) |
| `tests/unit/test_buddy_magic_rules.gd` | 13: befriending's yes and every no (too strong, chasing, a boss first, a wave's, golden, Monster Wave, the pet cap), their words, the friend a pet counting toward the cap that never fights; every monster kind befriendable, no boss; a mini per boss once, the Pebble Golem, clean records, never a pet place, ids; tricks after three, each emote its own lesson, the moves, saved and cleaned, the words | as above |
| `tests/unit/test_my_stamp_book.gd` | 7: ids 495-499 and nobody else's, the lowest free slot from the lowest corner, the size cap (16 yes, 17 no, 1,792 blocks no), a full book, placed like a preset stamp, kept on the device, a broken file | written first, run after `MyStampBook` (honest note) |
| `tests/integration/test_special_buddy.gd` | 6: a shape is special (its tag's colour), the recipe's traits (the fairy floats, the lighthouse's and the robot's light), its act now and then with its sound (a plain buddy none), the flower pot grows but its box doesn't (and a squash comes back to the grown size), a dance learned after three and saved, every move plays | parse error: no `Buddy.GROW_MAX` |
| `tests/integration/test_magic_pets.gd` | 7: every monster kind's friend look (shared, the animals' material, pet sized, a small box), no club or bow, every boss's tiny look, the collar fits, a friend saved with its kind and tricks, a nonsense kind dropped, every move on a pet | RED: 11 kinds not shared (the plain animal box), the archer's box count |
| `tests/integration/test_buddy_magic_director.gd` | 16: the album (a plain buddy; a shape named, revealed and found once; a guest's goes to the guest), befriending (yes; the kind no's; the cap; Monster Wave; Survivor), minis (everyone there, once, out of the boss's spot, no pet place; none for the Sky Dragon; coming along and never saved; the record kept), tricks (three dances, too far, not mine, dancing along; pets' and Pip's in the profile; a profile pet's tricks back to the host; a known trick at once) | RED on a parse error in the director (`hops_out`'s type), then green; mutation-checked (the owner and range checks dropped: 3 asserts fail) |
| `tests/integration/test_buddy_book_pages.gd` | 6: two new pages, silhouettes and riddles, a found recipe's picture and name, the album newest first with where and its picture, the empty and the full album's lines, every page fits 1280 × 700 | run after the pages; mutation-checked (a found recipe showing its riddle and the album oldest first: 8 fails) |
| `tests/integration/test_my_stamps.gd` | 7: a stamp of mine placed whole and ONE undo takes it all, the STAMPS page with pictures, NEW STAMP, the x asks then deletes, the tab in both modes, the bar picks and saves (the build stays), a too-big build refused with words | parse errors: no `MyStampBar`, no `STAMPS_TAB` |
| `tests/integration/test_wand_befriend.gd` | 4: the wand on a monster asks the host, a sword never befriends, a buddy in front of a monster is the wand's (it sleeps), the wand on a boss says it is too big | three run after the hook, mutation-checked (the hook removed: 2 fail); the buddy-in-front test RED first (the ray saw only monsters: it befriended the slime behind the buddy) |
| changed | `test_pet_rules` (BY_WAND is a way to become a pet), `test_secret_book_pages` (5 pages), `test_block_palette` (NEW STAMP's button), `test_palette_armory` (8 tabs), `test_palette_gifts` (Survivor shows STAMPS), `test_animal_pack` (owner #41's "lives somewhere" leaves out the wand's friends like the given pets) | |

Headless smoke run (`tools/buddy_magic_smoke.gd`, DEVELOPMENT.md §4): 30 of 30 checks on a new Sandbox world
(seed 2586055882 at load 27, and after the M3 Task 21a merge seed 2781421817 at load 31): the snowman, the slime friend, the Pebble Golem, the dance, My Stamps and one undo, the
save. Its first runs found two things the unit tests could not: toasts replace each other (the book's and the mini's
words were hidden at once by the host's line; they now wait `SAY_LATER`, 2.8 s), and a slime friend standing by learns
the dance with the snowman ("Frosty and Clover learned to dance!": right; the check was wrong).

## Rulings (each with its cost if wrong)

1. **Eight recipes of block classes** (any white block, any lamp, any wall block ...): snowman, lantern robot, flower
   pot, singing castle, lighthouse, rainbow caterpillar, crystal fairy, puppy. *Cost:* a shape of a block not in its
   class (a snowman of white glass) stays plain; one line in `CLASSES`.
2. **Tolerance**: turned four ways and mirrored, ONE spare block; never tipped over (a snowman lying down is plain).
   *Cost:* children who build lying shapes miss; tipping is one more loop in `matches`.
3. **The first recipe in the table wins**; the puppy (any blocks) is last, so a shape of coloured blocks is never a
   puppy first. No two recipes match each other's shape (tested).
4. **A buddy's recipe comes from its blocks on every game** (not saved, not synced). *Cost:* changing a recipe later
   changes old buddies that matched it.
5. **The riddles are in the book from the start** (the research's guard wanted them found in the world: bottles,
   notes, the Wanderer). *Cost:* less to discover; gating a riddle behind a secret found is one condition in
   `_fill_recipe`.
6. **A secret shape found counts as `secret_found/buddy_shape`** (25 XP, the secrets goals). *Cost:* those goals fill
   a little faster.
7. **The Buddy Album is the Secret Book's last page** (not the pause menu: its fit test untouched, and the book is where
   the child already collects). *Cost:* a child looking in the pause menu; a button there could open the book's page.
8. **Album pictures are drawn from the build's blocks** (its front, ≤ 8 × 8, the blocks' own icons), not photos:
   nothing to take or render, the code is a few dozen characters. The album keeps no blocks (no WAKE AGAIN from it):
   40 × 200 blocks would not fit the profile's 60 KB backup; My Stamps keeps builds instead. *Cost:* research C2's
   "wake it again from the album" is not there.
9. **40 newest in the album, older ones a count** ("Buddies woken: 52 (not shown: 12 older)"). *Cost:* the oldest pictures are gone.
10. **"When" is the device's clock** (unix seconds, shown "25 Sep"). *Cost:* a phone with a wrong clock shows a wrong
    day; nothing depends on it.
11. **My Stamps live on the device** (`user://my_stamps.json`, like friends' gift stamps), not in the profile: five
    16-a-side stamps could be 80 KB, over the backup's 60 KB. *Cost:* a reinstall or a new phone loses them; a server
    store (M4) can keep them later.
12. **Five My Stamps** (the five ids allocated, 495-499). *Cost:* children want more; more ids needed.
13. **A stamp ≤ 16 a side and ≤ 1,600 blocks** (`EditBatch.MAX_BATCH`): always one edit and one undo; Survivor pays
    its blocks like every stamp. **The STAMPS tab shows in both modes.**
14. **NEW STAMP picks with BuildPicker** (the connected non-natural blocks under a tap; trees count, as for the wand),
    turned so the side the child saw is its front (`PowerTools.to_stamp`); the build stays in the world.
15. **A befriended monster is a pet** (species `monster_friend`, its kind as the animal's `variant`: the monster's look
    without its weapon, pet sized, pink cheeks), not a monster any more: it follows, is only ever pushed, fights
    nothing, and counts toward the pet cap of 3 (research ruling 5). *Cost:* a child with 3 pets can't befriend.
16. **"Calm" = not chasing** (not CHASE and not WINDUP); a monster that heard something ("?") or searches is calm
    enough. **Level 1-2 only; never a boss, a wave's monster or the golden slime; not in Monster Wave.** Reach: the
    edit reach + 1 block. *Cost:* a searching monster can be befriended.
17. **A friend glows softly in the dark** (perk GLOW, the one shared `PetGlow`), eats berries and seeds, gets a fun pet
    name (renamed on its pet card as usual) and the gummy bunnies' voice (a measured level). A mini-buddy glows too,
    eats a bolt like Pip and chirps with the pet dragon's voice. *Cost:* more glowing pets share the one light.
18. **Mini-buddies are pets that live in the profile** (like Pip: `BuddyMagicData.minis`, one per boss kind, never a
    pet place, never sold), not Buddy builds: one small shared box mesh each. **Every player in the game gets one**
    when the boss falls (the research: "everyone who fought"; the host doesn't track who hit it). *Cost:* a friend far
    away also gets one.
19. **The Sky Dragon gives no other mini**: owner #39's baby dragon is its tiny friend.
20. **In Monster Wave's arena** (no pets there) a raid boss's mini is kept in the profile and comes into the next world.
21. **A mini asked for within 60 s of its boss's fall hops out of the boss's spot** (with hearts); later it comes next
    to its child.
22. **Tricks: three of the same emote within 8 blocks of one's own buddy or pet**; lessons are counted on the host
    and not saved (two dances, then a reload: start again); learned tricks are saved and never forgotten (no timers).
23. **Every emote is a trick of its own; the moves**: the dances and Victory → a dance, Star Spin and Cheer → a spin (the
    brief's second trick; Cheer is free, Star Spin costs gold), wave → a wave, clap / laugh / thumbs up → a hop, sit, bow.
24. **Where tricks are kept**: world pets and buddies in the world save (`tricks`, next to the pet's mind rather than
    inside `MindMemory`, which is capped players and places), Pip's, the baby dragon's and the minis' in the profile
    (they travel between worlds). **A buddy put to sleep forgets its tricks** (it is blocks again; woken, a new
    buddy). *Cost:* against "never forgotten" for sleeping buddies; keeping them would need a key per build.
25. **A trick's move goes to every game by one reliable RPC** (at most one per creature per accepted emote: Session's
    400 ms emote cooldown). **A special buddy's act runs on every game by its own clock** (nothing sent; a moment's
    difference between screens is harmless); its sparkles only within 48 blocks of this game's camera.
26. **The flower pot grows its look only** (up to 2×, 10 % a time), never its collision box (owner feedback #9), and
    not saved (it starts small again after a reload).
27. **A puppy buddy fetches**: the host runs it 6 blocks past its child for 2.5 s.
28. **This game's own words wait 2.8 s** (`SAY_LATER`): toasts replace each other, and the host's line comes at the
    same moment.
29. **Spec §14.21** (owner #41's animals took §14.19 and M3 Task 21a §14.20 while this was built).

## Georgian (M3 Task 21a's rule, after its merge)

`tools/i18n/words.gd -- --missing` listed 73 new words and 13 formatted lines not translated first; now MISSING 0. The
formatted lines are translated before they are filled in (`Lang.t` in the static rules, `tr` in nodes); a trick's words
are whole sentences per move (`TrickRules.LEARNED_WORDS`: "%s learned to dance!" ...), not "learned to %s"; the album's
line has no English plural ("Buddies woken: %d", "Buddies woken: %d (not shown: %d older)"); the album's universe and
month go through `Lang.t`. 70 Georgian lines appended to `i18n/ka.po` under their own heading, **native check
needed** (buddy = მეგობრუკა, stamp = შტამპი, wand = ჯოხი, as the glossary). The shapes' and the minis' names (Frosty,
Bolt, Petal, Melody, Beacon, Twinkle, Scout; Pebble, Sandy, Flurry, Cupcake) are names: `i18n/not_words.txt`. The
special buddies keep their own sounds; 21a's babble already speaks for every buddy's cheer and wake-up.

## For the lead: what to check on the emulator

1. Sandbox: build a snowman (three painted white blocks, an orange paint block on the side of the top one), wand →
   WAKE UP: "A secret shape! Frosty the Jolly Snowman is alive!", a burst, a moment later "New in your Secret Book";
   its name tag light blue; snowflakes drift down every few seconds. BOOK → ▶ ▶ ▶: BUDDY RECIPES (the snowman filled
   in, the others dark silhouettes with riddles), BUDDY ALBUM (Frosty's picture, "Green Meadows", today). Both pages
   fit a 16:9 and a 20:9 screen.
2. The other shapes (hints on the recipes page): the castle sings, the lighthouse flares (in a dark cave), the fairy
   floats, the puppy runs ahead and back, the flower pot grows (and still walks through a 2-wide door), the robot glows.
   A plain build still wakes as before, and Build-and-Wear's HAT, BACKPACK and WINGS still work.
3. `/summon slime` at level 1, stand still until it wanders, wand-tap it: hearts, "… is your friend now!", a small
   slime with pink cheeks follows; its pet card opens on a tap; it glows faintly at night; monsters ignore it; a sword
   only pushes it. A chasing one and a level-3 one refuse kindly; the Golem refuses ("too big"). Save & load: still a
   slime friend. With three pets: "You already have 3 pets!".
4. `/summon golem`, beat it: the Pebble Golem hops out where it fell and follows; a moment later "A tiny Pebble Golem
   hopped out!". Quit, open another world (or Survivor): it comes along. The desert's serpent, the frost giant and the
   cake: their tiny versions. LAN: the guest gets one too, in its own profile.
5. The Bunny Hop three times next to a buddy or a pet: "… is watching you... 2 more!", "... 1 more!", "… learned to
   dance!" with hearts; the fourth time it dances along on both screens (LAN). Cheer ×3: a spin. Save & load: it still
   dances. Pip learns too and keeps it in other worlds.
6. Palette → STAMPS → + NEW STAMP → tap a small build (it glows) → SAVE STAMP: "Saved as My Stamp 1!"; its picture on
   the page; put it in the hotbar and tap the ground: the whole build; UNDO once: all gone. Survivor: it takes the
   blocks from the bag. x → SURE? deletes it.
7. Performance: ten special buddies (mixed shapes) around the player in both styles: ≥ 30 FPS, no frame over 100 ms
   (their acts are Fx bursts in the shared material and pooled sounds).

## Merge notes

Shared files touched (small, marked "M3 Task 20b"): `entities/buddy/buddy.gd` (5 hooks + section),
`entities/animal/animal.gd` (3 hooks + section), `entities/animal/blocky_animal.gd` (COLLAR rows),
`entities/player/block_interactor.gd` (one line + section), `autoloads/session.gd` (section at the end),
`scenes/sandbox.gd` (3 calls, `_on_spark`, `_restore_buddies`, `_restore_pets`, section at the end),
`world/boss_director.gd` (signal `boss_won`), `world/pet_director.gd` (`is_profile_pet`), `world/world_meta.gd`
(`_t20b_keep`), `core/rules/animal_rules.gd` / `animal_food.gd` / `pet_rules.gd` / `voice_rules.gd`,
`core/mind/species/animal_species.gd` (rows for `monster_friend` and `mini_boss`), `core/save/profile_data.gd` /
`profile_backup.gd` (`buddy_magic`), `data/items/item_ids.gd` (495-499), `data/blueprints/blueprints.gd`,
`ui/hud/block_icons.gd`, `ui/hud/block_palette.gd` (tab STAMPS: index 7), `ui/hud/secret_book.gd` (pages 4 and 5).
Likely conflicts: species rows with any new animal (every `AnimalRules.SPECIES` row needs food, health, drops, a call
level and traits: `test_animal_pack`), palette tabs (STAMPS is 7) and the palette's button count, the Secret Book's
page count (`test_secret_book_pages`), Session's and the sandbox's end sections.

## Suite counts and commits

| Run | Scripts | Tests | Result |
|---|---|---|---|
| Part 1 (the rules, the entities, the director), on the base before owner #41 | 522 | 5,085 | 5,078 passed; failing: `test_quest_rules` (universe 5's giver) and `test_wear_rules` (block 230), both failing on the base and fixed on `lead-merge`; `test_mind_book` (two more species; #41 rewrote it); `test_visit_world` (flaky at load 34, passes alone) |
| Part 2 (the book, My Stamps, the wand, the wiring), after the #41 merge | 536 | 5,183 | 5,179 passed; `test_palette_armory`'s tab count (fixed: STAMPS is tab 8) and `test_visit_world` (the same flake) |
| **Final, after the M3 Task 21a merge and the Georgian** | **556** | **5,324** | **5,322 passed, 2 risky (the base's), 0 failing; exit 0** |

Before this task on the final base: 5,324 − 91 = 5,233 tests. Commits: `b4cd7ec` (part 1), `5359c48` (merge: #41,
Nell), `0ce11cd` (part 2), `1840c49` (merge: 21a, ghost races), and the last one (Georgian, notes).
