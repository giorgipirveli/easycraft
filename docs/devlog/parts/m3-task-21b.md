# M3 Task 21b: the wonder pack — books and memories (notes)

Built by a background agent in its own worktree (cut from `m2-survive-the-night`, `lead-merge` merged in first:
`a46b97f`, with #41 more animals, #39 the Dragon Realm, #45a quests, #45b a bigger world, M3 Task 8), without the
editor, the emulator or godot-mcp. Brief `docs/superpowers/briefs/prompt-m3t21b.md`; spec §16 (the M3 core set) and
the new **§14.24** (21a, 20b, 21c and #37 took §14.20–14.23 first); research `docs/design/engagement-and-child-psychology.md` C1 (Animal Book), R2 (Memory Book), C3
(trophy shelf), X5 (idea cards), R3 (wish list), C4 (page rewards), R1 (Hub Tree); plan Task 21.

## What was built

| Piece | Where | What it does |
|---|---|---|
| The books' profile data | `core/books/wonder_data.gd` (`WonderData`, `ProfileData.wonder`, JSON key `wonder`) | The Animal Book's marks (species → MET 1 / FED 2 / FRIEND 4), the saving list (≤ 6 `{kind, id}`), the Secret Book pages rewarded, the universes explored. Parsed field by field (unknown kinds, broken rows, bad numbers dropped; old profiles load empty); `merge_from` for the server backup (every mark, page and universe kept); `ProfileBackup.is_new` counts it. No dates or clocks (tested). |
| Animal Book rules | `core/books/animal_book_rules.gd` (`AnimalBookRules`) | A page per kind of **`AnimalRules.SPECIES`** (read, never listed: #41's 19 kinds came by themselves), names (`NAMES` for Pip, Baby Dragon, Fennec Fox; else the species word), one true fact per kind (`FACTS`, 31 now; a new kind without one gets `DEFAULT_FACT`), `record` (each mark once; fed or friend means met), `from_event` (`pet_fed/<kind>`, `animal_tamed/<kind>`), `catch_up` (a profile from before the book: its progress counts, Pip, the baby dragon), `newly_met` (within `MEET_DISTANCE` 8 blocks), `home_words` (the clue for a kind not met: the universe that names it, `UniverseRegistry.animals`; Pip and the dragon, never wild: "A very special friend!"). |
| Memory Book | `core/books/memory_rules.gd` (`MemoryRules`), `core/books/memory_book.gd` (`MemoryBook`, `user://memories/memory_book.json`) | 12 moments from counted events (first buddy, pet, secret, geode, monster, wave, friend, race, ride, story, craft, photo), `boss_<kind>` for every boss, `universe_<u>` (u ≥ 2), `first_night`, `page_<page>`, `level_5/10/20`; words and pictures; dates "25 Sep 2026". The book keeps each moment once with its date, unix time and a photo file name (a plain name beside the book, never a path); newest first; a versioned JSON of its own on the device, **never in the profile or the backup**. `photo_target`: a photo within `PHOTO_WINDOW` (10 min) goes with the newest moment still without one. |
| Idea cards | `core/books/idea_cards.gd` (`IdeaCards`) | 28 cards, a few words and 1–3 pictures each (ProgressPictures names, animal kinds drawn from their boxes, block and item icons); `flip` round and round. No reward keys, no timers (tested). |
| Saving up | `core/books/saving_rules.gd` (`SavingRules`) | Gold things only: Tilly's (any `ShopRules.for_sale` id) or a GOLD avatar item; never a pack item (owner #35's wish list keeps those); ≤ 6; `have_need` with Tilly's price in the child's universe (× 2^(u−1)); `tidy` drops owned looks; calm words (tested against pressure words). |
| Page rewards | `core/books/book_pages.gd` (`BookPages`); `AvatarCatalog` (`EARN_TREASURE_PAGE`, `EARN_KEEPSAKE_PAGE`, `hat.treasure_bandana`, `cape.storybook`), `AvatarParts` (their box recipes) | The Secret Book's three pages — M2 secrets (`SecretRules.KINDS`), Treasure Hunt (`TreasurePlaces.KINDS`), Keepsakes (every `QuestRules.CHAINS` story done) — each done gives once: its avatar item through `AvatarUnlocks.earn` (Fairy Wings: `EARN_SECRET_PAGE` already existed and nothing gave it; Pirate Bandana; Storybook Cape), its sticker (`page_*`, `ProgressData.is_sticker`, in the trophy room's sticker book) and a star on the Hub Tree. |
| Hub Tree rules | `core/books/hub_tree_rules.gd` (`HubTreeRules`) | State `{u, b, p}` from `WonderData.universes`, the progress' `boss_beaten/<kind>` counts and the pages; `clean` (it crosses the network); `grows` (only ever more); the trunk grows 0.3 a thing up to 6.5; boxes (crowns in each universe's colours, fruits by boss, three-box stars); `spot` beside the circle (behind it first, dry, within 2 of its height, no world tree within 2 columns). |
| Trophy rules | `core/books/trophy_rules.gd` (`TrophyRules`) | Shelves filled top row first, then along x, then z (the same on every game); `PER_SHELF` 4 (two on each of two shelves); a look per badge (cup, star, gem, block; colour by family); one shelf's boxes inside its cell. |
| Block index | `core/books/block_index.gd` (`BlockIndex`) | DefenseDirector's lantern-index pattern for any ids: 16-block chunks copied once, a budget a look, nearest first; the host's edits at once (`note_block`), a guest's chunks looked at again after `cache_seconds`. |
| Blocks 217–218 | `BlockIds.TROPHY_SHELF`, `BOOKSHELF`; `PortalPage.BOOK_TILES` (tiles (2..5, 2) = 2 × (id − 208)); `tools/make_portal_page.gd` + `.py` (drawn last, their own seed); `ShopRules.HOME_PRICES` (15, 10 × 2^(u−1)); `BlockPalette.HOME_BLOCKS` (the SMART page's HOME row) | The shelf is a **cut-out** cube (its side tile is a frame round two see-through openings: the trophies inside show from every side, both styles), the bookshelf an opaque case of books. Neither is paintable (page 10 is a job page). `/give trophyshelf`, `/give bookshelf`. |
| The director | `world/books_director.gd` (`BooksDirector`, node `Books`, every game) | Once a second: animals near this game's player met (a toast), the Survivor night watch (a night begun and ended without this player's knock-out → `first_night`). Listens to `Progress.counted` (Animal Book marks, memories; a secret or a story done checks the pages; a boss updates the tree), `leveled_up` (level memories), `badge_unlocked` (the shelves). At start: the book catches up with earlier play, this universe is explored (not in Monster Wave), pages already done give their reward. Photos: `note_photo(png)` makes a 256-wide copy on a `WorkerThreadPool` task and gives it to `photo_target`'s memory. The owner's showcase `{badges, tree}` goes to the shelves and the tree; the host sends it to guests. |
| Shelves and tree in the world | `world/trophy_shelves.gd` (`TrophyShelves`), `entities/books/hub_tree.gd` (`HubTree`) | Shelves within 16 blocks of this game's player (≤ 16 shelves), a look every 0.5 s, 3 chunk copies a look (a guest: 1, and again every 10 s); one `MeshInstance3D` a shelf with a mesh cached per content on BlockyAnimal's shared material (one draw call a shelf, nothing made while nothing changes). The tree: one mesh per state, cached; trunk and crowns on BlockyAnimal's material, fruits and stars on one shared unshaded material; no collision (like the circle's stones). |
| Session | `autoloads/session.gd`, section `# --- M3 Task 21b` | `books_share_showcase(data)` (host → every guest), `books_send_showcase(peer, data)` (at `client_ready`), `_rpc_books_showcase` → `books_showcase_received` (cleaned by `BooksDirector.clean_showcase`: known badges once, a clean tree). |
| The book's tabs | `ui/hud/secret_book.gd` (section at the end), `ui/books/` | The BOOK button's Secret Book gets a **column** of five picture tabs left of its pages (SECRETS, ANIMALS, MEMORIES, IDEAS, SAVING; 104 × 76, narrow enough for 20b's buddy recipes page beside them): `AnimalBookPage` (8 × 3 visible tiles of 122 × 120, scrolling; silhouettes; a card with the big picture, fact and marks, or a clue), `MemoryBookPage` (six cards a page, newest first, photo or picture, words, date; ◀ ▶), `IdeaCardsPage` (one big card, ◀ ▶ round), `SavingPage` (rows: picture, name, where, a have/need bar, X). `AnimalPortrait` draws a kind's own box model (three faces of each box, painter's order), a dark silhouette until met. `BookKit` is the pages' look. `open_tab(t)` for the bookshelf. |
| SAVE UP | `ui/hud/shop_panel.gd` (section at the end; one line each in `_footer`, `_refresh_selection`, `_on_trade_done`), `ui/avatar/avatar_editor.gd` (section; a line in `_build_right` and `_update_offer`) | Tilly: SAVE UP beside BUY when the gold isn't there yet (or it is on the list: SAVING ✓ takes it off); buying it takes it off. The editor: SAVE UP **in BUY's place** while the gold isn't there (the editor keeps its width). Neither spends gold. |
| The saving bar | `ui/books/saving_bar.gd` (`SavingBar`), `ui/hud/hud.gd` (section at the end: `setup_books`, `refresh_saving`) | A 150 × 9 bar inside the gold counter's own spot (a label's child, never a button): the first thing on the list, Survivor only, refreshed on gold changes, SAVE UP and the book closing. |
| Glue | `scenes/sandbox.gd` (section at the end, one line in `_setup_local_player`), `entities/player/block_interactor.gd` (signals `bookshelf_tapped`, `animal_fed`; `_tap_bookshelf`), `ui/photo/photo_mode.gd` (`last_png()`), `ui/progress/trophy_room.gd` (page stickers), `core/progress/progress_data.gd` (`is_sticker`) | |
| Smoke run | `tools/books_smoke.gd`, `tools/books_smoke_steps.gd` | Below. |

## Patterns (GodotPrompter skills)

- `save-load`: **chosen** JSON fields added to the profile with defaults (no version bump; each field falls back on
  its own, as the profile already does) and, for the Memory Book, a device-only JSON with a `version` written by
  `JsonStore.write_atomic`; **rejected** Resources (`.tres`, unsafe for user data) and ConfigFile.
- `godot-ui`: **chosen** containers built in code (like every menu), a column of big toggle buttons as tabs (the
  project's own pattern since M2 Task 6), `StyleBoxFlat` paper; **rejected** `TabContainer` (the 4.7 internal tab bar
  node, DEVELOPMENT §8) and a row of tabs over the pages (the tallest page would pass 700 px).
- `godot-optimization`: **chosen** one merged mesh per shelf content and per tree state, cached, on shared materials
  (one draw call each), a chunk index instead of box copies, decisions at 1–2 Hz; **rejected** a MeshInstance3D per
  trophy (4× the draw calls) and MultiMesh per trophy shape (per-instance colours need a custom material).

## Rulings (decisions made on the owner's behalf, each with its cost if wrong)

1. **"Wish list" is two lists.** Owner #35's `WishList` is the grown-up's list of pack items (a grown-up gives them);
   this task's is **"Saving up"** (`SavingRules`, SAVE UP): gold things the child saves for. Different names so a child
   never mixes "ask for it" with "save for it", as #35's ruling 6 foresaw. *Cost if wrong:* rename the words.
2. **SAVE UP shows only when the gold isn't there yet** (or the thing is on the list), in BUY's place in the editor.
   *Cost if wrong:* a child can't pin something affordable (then they can just buy it).
3. **The Memory Book stays on the device** (its own file, not the profile or the server backup), per research R2's
   guard; a new phone starts it empty (the photos couldn't move anyway). *Cost if wrong:* memories lost on a new phone.
4. **Memories are firsts** (each moment once) plus every boss and every universe; photos are the child's own (photo
   mode) — the game takes no picture by itself (no screen read-back at a big moment: a 20–50 ms frame on a phone).
   *Cost if wrong:* many memories without a photo; an automatic snapshot would be `PhotoMode.capture` + `note_photo`.
5. **A photo goes with the newest moment without one within 10 minutes**; later photos are just photos. *Cost:*
   `PHOTO_WINDOW`.
6. **The first night** is a Survivor night (any game) begun and ended without this player's knock-out, watched on the
   player's own game from the sky's clock. *Cost if wrong:* a child who slept through the night in a bed counts it too
   (the night still passed).
7. **"Met" = within 8 blocks** of this game's player, looked at once a second; fed = a pet treat (`pet_fed/<kind>`) or
   the animal's food from the hand (`AnimalFood.is_block_food`, the new `animal_fed` signal); friend = tamed. *Cost:*
   `MEET_DISTANCE`.
8. **Trophy shelves and the Hub Tree show the world owner's** (the host's) progress; a guest sees the host's (one RPC
   at join and on change). A shelf is a showcase for friends (research C3 "showing off at home"). *Cost if wrong:* a
   guest's own trophies never show in a friend's world.
9. **Shelves fill in one order for the whole world** (top row first, then x, then z, within 16 blocks), four trophies a
   shelf. *Cost:* from the other side a row fills right to left.
10. **The shelf is a cut-out cube** (see-through openings on every side, no front), so no rotation is needed; the
    trophies are one baked mesh inside the cell. *Cost if wrong:* a back panel would need a facing (a block state).
11. **The Hub Tree stands only where the circle does** (Survivor worlds), beside it on dry ground; none if no spot is
    good (rare). No collision. *Cost:* children walk through the trunk, like the stones.
12. **Explored** = a Survivor or Sandbox world of that universe was played (not the Monster Wave arena); the first
    universe is home (a crown, no memory). *Cost:* none known.
13. **Page rewards: the Fairy Wings** (the catalog's existing `EARN_SECRET_PAGE` item, never given before) **for the
    first page, a new Pirate Bandana and Storybook Cape** for the others (box recipes, both styles); rarity EPIC like
    other earned items. *Cost:* two catalog rows.
14. **Page rewards are granted on the child's own game** (like codes offline and earned items), checked when a secret
    or a story is counted and at the world's start (profiles that finished a page earlier get it once). *Cost if wrong:*
    a modified client can give itself cosmetics (no gold, no advantage).
15. **The bookshelf's tap opens the book on MEMORIES** (whatever is in the hand; a hold still breaks it, like doors).
    *Cost if wrong:* one line (`SecretBook.MEMORIES_TAB`).
16. **Tilly sells the shelves** (trophy shelf 15, bookshelf 10, × 2^(u−1)); the Sandbox palette has them in a HOME row on
    the SMART page (the MAGIC row is full since 21c's pumpkin, jack-o-lantern and snowman head)
    (the block grid would grow a 13th column). *Cost:* two price entries.
17. **A guest finds shelves by copying chunks** (its world announces no edits): one 16³ copy a look, each chunk again after
    10 s (the host copies each once and hears every edit). *Cost if wrong:* a shelf a guest's friend places shows its
    trophies on the guest's screen up to 10 s late.
18. **Animal facts are short, true and friendly** (checked against common sources; "Horses can sleep standing up!");
    the candy kingdom's two made-up kinds get made-up facts about themselves. *Cost:* one table.

## Tests (RED → GREEN)

New: `tests/unit/test_wonder_data.gd` (8), `test_animal_book_rules.gd` (8), `test_saving_rules.gd` (7),
`test_book_pages.gd` (5), `test_memory_book.gd` (8), `test_idea_cards.gd` (3), `test_hub_tree_rules.gd` (5),
`test_trophy_rules.gd` (5), `test_block_index.gd` (5), `test_book_blocks.gd` (4); `tests/integration/test_books_tabs.gd`
(11), `test_books_director.gd` (14), `test_trophy_shelves_and_tree.gd` (6), `test_saving_up.gd` (5),
`test_bookshelf_tap.gd` (3). 97 tests in 15 scripts.

- **Rules (proper RED):** the ten unit scripts were written first and run against stub classes with the same API
  (empty returns): 44 of 50 failed on their assertions ("[] != [\"secrets\"]", "0 expected to equal 12", "a gold avatar
  item", …). GREEN after the rules: 53/54; the one left was the backup merge's universe order (fixed: kept sorted).
- **UI, director, shelves, tree, SAVE UP:** written after the code, so **mutation-checked** (`scratchpad` script, one
  rule broken at a time, its tests run, restored), 18 mutations, **all caught**: a page rewarded twice; no avatar item
  for a page; a knocked-out night remembered; animals never met by the director; a moment kept twice; a late photo
  attached; a pack item savable; SAVE UP when affordable; BUY not making way in the editor; every tab page shown at once;
  a silhouette named; a broken shelf's trophies left standing; a guest's showcase not cleaned; the backup losing the
  older copy's animals (first **missed**: the test's older copy had nothing the newer lacked — fixed, then caught); the
  saving bar in Sandbox; unknown badges on a shelf; the Hub Tree on a world tree; the bookshelf's tap line removed.
- **The fit:** every tab and every Secret Book page ≤ 1280 × 700 (`test_every_tab_fits_the_screen`, the Secret Book's
  own `test_both_pages_fit_the_screen` unchanged); the tabs are a column so no page got taller.
- **Full suite** (through the slot gate): before, on `lead-merge` `a46b97f`: 526 scripts, 5092 tests, 5087 passing and
  3 failing (the lead's known merge seams: the pet dragon in #41's checks, the quest book's keepsakes at 704 px; fixed in
  `efd53e4`). After this task's commit with `lead-merge` `efd53e4` merged in: **541 scripts, 5187 tests, 5185 passing, 2
  risky** (the old "did not assert" pair), 0 failing, exit 0, 879 s at load ~26 — 95 new tests, none of the others
  changed but the sticker book's count. After the shelves' radius tweak (24 → 16 blocks; a guest copies one chunk a look, again after 10 s; ruling 17):
  the same **541 scripts, 5187 tests, 5185 passing, 2 risky, 0 failing, exit 0**, 899 s at load ~29, no `SCRIPT ERROR`.
  **Final**, with `lead-merge` `151541d` merged in (M3 Task 21a, M4 ghost races) and the Georgian below: **561 scripts,
  5330 tests, 5328 passing, 2 risky, 0 failing, exit 0** (899 s at load ~30; `test_georgian_words` passes).
  **Final after owner #36** (`lead-merge` `fa048e3`, the Storybook costume pack, merged: conflicts only where both added
  at the same ends — Session, `AvatarCatalog`, `AvatarParts`, the avatar editor, `ka.po`; #36's Fairy costume shares the
  first page's `EARN_SECRET_PAGE`, so `test_book_pages` wants at least one wearable earned item per page): the first run
  had 1 failure, `test_saving_up`'s HUD bar — the machine's shared `profile.json` (which GUT runs load) owns a crown now,
  so the crown could not go on the list; `test_saving_up` and `test_books_tabs` now empty and restore the shared
  profile's cosmetics. Then **565 scripts, 5368 tests, 5366 passing, 2 risky, 0 failing, exit 0** (900 s, load ~20).
  After merging M3 Tasks 20b and 21c and owner #37 (`3d21f55`): the MAGIC row was full with 21c's three wakeable blocks, so
  the shelves moved to a **HOME row on the palette's SMART page** (`BlockPalette.HOME_BLOCKS`; the palette tests count it),
  and the book's tab column narrowed to 104 px so 20b's buddy recipes page fits 1280 px beside it; the books' spec section
  became §14.24 (20b, 21c and #37 took 14.21–14.23). 593 scripts, 5619 tests, 5617 passing, exit 0. After owner #43 (our own
  look): only page 10's PNGs conflicted; both tile tools were run again and the pages differ from `lead-merge`'s only in
  this task's tiles (2..5, 2), checked pixel by pixel (#43's golden portals, Workbench and Clay Oven untouched). **Final**,
  with `lead-merge` `4570650` merged in (the lead's fix of #36's costume test for #43's rosy face): **598 scripts, 5657
  tests, 5655 passing, 2 risky, 0 failing, exit 0** (891 s, load ~12); `words.gd --missing`: MISSING 0; the smoke run 25/25.

## The smoke run (the real game, headless)

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/books_smoke.gd`:
**25 of 25 checks pass** (exit 0; load 25): the director is there and Green Meadows explored; the Hub Tree 4.5 blocks from
the circle's middle on the ground (y 30 = the column's surface) with one crown and its mesh; a summoned cow met within 2 s;
`first_photo` and `first_buddy` kept, the photo saved 0 s later given to the newest (`first_buddy.png`, 256 × 144, in
`user://memories/`); a trophy shelf placed through `Session.request_set_block` (Survivor, from the bag) showing
`say_cheese` and `first_buddy` 1.2 s later; the geode as the page's last secret → the Fairy Wings, `pages: ["secrets"]`,
the tree's star, the banner "You found every secret on page 1! You got the Fairy Wings!" (queued after the board's and
badges' banners); a real tap on a bookshelf (the camera aimed from the eyes, as the door tests do) opening the book on
MEMORIES with 5 memories; the saving bar "25 / 400"; `profile.json` keeping `{animals: {cow: 1}, saving: [crown], pages:
[secrets], universes: [1]}`. The first run's tap from the third-person camera missed the shelf (the run then used the
signal); aiming from the eyes fixed the run, not the game.

## Words in Georgian (after merging M3 Task 21a)

`lead-merge` gained M3 Task 21a (English and Georgian) while this task was built; after merging it (`a543db7`):
`tools/i18n/words.gd -- --missing` listed **138 words without Georgian and 11 formatted before translation**; now
**MISSING 0, 0 formatted**. Formats go through `Lang.t("…") % x` in the rules (`AnimalBookRules`, `MemoryRules`,
`BookPages`) and `tr("…") % x` in the director and the Animal Book's card; the names and facts come back translated
(`name_of`, `fact_of`, `words_of`). Whole sentences, no English glue: the universe memory is **"I found a new world:
%s!"** and the clue **"Its home: %s"** (no "the" before a world's name); several animals met at once are joined with a
comma, not "and"; the card's marks are translated before they are joined; month names are words (`Jan` … `Dec`). The
138 Georgian lines are appended to `i18n/ka.po` under a heading marked **native check needed**, with the file's
glossary (buddy მეგობრუკა, pet შინაური, world სამყარო). Every book page has 21a's speaker (`ReadAloud.button`) beside
its title. `test_every_tab_fits_the_screen_in_georgian` measures every tab in Georgian; `test_georgian_words` passes.

## Hooks in shared files (for the lead)

| File | What |
|---|---|
| `core/save/profile_data.gd` | `wonder` field, one line in `from_json`, one in `to_json` |
| `core/save/profile_backup.gd` | `is_new` also needs `wonder.is_empty()`; `merge`: `out.wonder.merge_from(other.wonder)` |
| `core/progress/progress_data.gd` | `is_sticker` knows the page stickers |
| `core/avatar/avatar_catalog.gd`, `entities/player/avatar_parts.gd` | two earn events and reasons, two items, two recipes (at the ends) |
| `core/economy/shop_rules.gd` | two HOME prices |
| `data/blocks/block_ids.gd`, `data/blocks/portal_page.gd` | 217, 218 and their names; `BOOK_TILES` merged in `all_tiles` |
| `tools/make_portal_page.gd`, `.py` | the tiles drawn last with their own seed (the PNGs: only tiles (2..5, 2) changed, checked pixel by pixel); **after merging another page-10 owner, run both tools again** |
| `ui/hud/block_palette.gd` | `HOME_BLOCKS` and the SMART page's HOME row (tests: `test_block_palette`, `test_counted_hotbar`, `test_palette_smart` count it) |
| `ui/hud/secret_book.gd` | `_ready` puts its column in `_books_column(column)`; `open()` shows the SECRETS tab; section at the end |
| `ui/hud/shop_panel.gd`, `ui/avatar/avatar_editor.gd`, `ui/hud/hud.gd`, `ui/photo/photo_mode.gd`, `ui/progress/trophy_room.gd` | small hooks + sections at the end |
| `entities/player/block_interactor.gd` | one line in `place_at_screen` (bookshelf), one in the animal tap (`animal_fed`), section at the end |
| `scenes/sandbox.gd` | `_setup_books()` at the end of `_setup_local_player`; section at the end |
| `autoloads/session.gd` | section `# --- M3 Task 21b` at the end |
| `tests/integration/test_adventure_board.gd` | the sticker book's count + `BookPages.PAGES.size()` (the one test changed) |
| `i18n/ka.po` | 138 lines appended (M3 Task 21b's heading, native check needed) |

## What the lead should check on the emulator

1. BOOK (under the hearts): the book opens on the Secret Book with a column of five picture tabs on its left; each tab
   shows its page; nothing runs off the 2400 × 1080 screen or a 16:9 phone; BACK/outside closes it as before.
2. ANIMALS: silhouettes with "???" and a clue ("Its home: Sandstorm Desert"); walk near cows and sheep — a toast "New
   in your Animal Book: Cow!" and the cow's picture (its own box model, in colour) and a fact; feed a sheep grass from
   the hand (FED mark), tame a dog (heart). The pictures read well at phone size (are the box drawings recognisable?).
3. MEMORIES: wake a buddy → toast "New memory: I woke up my first buddy!"; take a photo (MORE → PHOTO) within 10
   minutes → the card shows the photo (a small copy); dates read "25 Sep 2026". Travel to universe 2 → "I found a new
   world: Sandstorm Desert!". A Survivor night without being knocked out → "I made it through my first night!".
4. IDEAS: ◀ ▶ flip the 28 cards round; the pictures (houses, dogs, cows drawn from their boxes, block icons) are big.
5. SAVING: at Tilly's with little gold pick the crystal sword → SAVE UP (blue) beside BUY → "It's on your saving list!",
   a thin bar under the HUD's gold (Survivor only); in the avatar editor a crown you can't afford shows SAVE UP in BUY's
   place; the SAVING tab lists both with bars; X takes one off; buying takes it off.
6. Page rewards: finish the first Secret Book page (all 8 M2 kinds) → banner "…You got the Fairy Wings!", the sticker in
   the trophy room's sticker book, a golden star on the Hub Tree.
7. The Hub Tree beside the stone circle (Survivor): a small tree with one green crown; beat a boss → a glowing fruit;
   travel to more universes → more crowns in their colours; it never overlaps the stones, Tilly or the Totem. Look at it
   at night (fruits and stars shine).
8. Trophy shelf (the palette's SMART page, HOME row, in Sandbox; Tilly's HOME in Survivor): place a row of them in a house → the badges stand on
   them as little cups, stars, gems; both styles (the realistic cabinet's openings are see-through). A LAN guest sees the
   host's trophies. Frame time with 8 shelves in view (one draw call each).
9. Bookshelf: a tap opens the book on MEMORIES; a hold still breaks it.
