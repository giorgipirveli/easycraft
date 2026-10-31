# Store listing — Google Play (final texts; M5 Task 4)

Written by the M5 Task 4 agent on 2026-09-25 from what the game really has (`docs/playtests/whats-new-0.4.0.md`, the
agents' notes in `docs/devlog/parts/`, and what merged after 0.4.0: Pip's tutorial, the MOBS tab, the weapons'
strength, M5 Task 1's accessibility pass and the player card in every world). **English only** (owner #52, 2026-09-25): no translated listing, ever. The App Store copy follows on the Mac.
**The owner approves the words; the lead pastes them into Play Console** with the upload whose build has every line
(Grow users → Store presence → Main store listing): the first build after 0.4.0 (release candidate 1.0.0) has every
line. Where each line comes from: "What each line rests on" below.

Limits (Google Play): app name ≤ 30 characters, short description ≤ 80, full description ≤ 4,000. The counts
below were measured on the text blocks as they stand (`python3`, `len()` of the text between the fences).
Play shows the full description as plain text: the blocks use no Markdown, only line breaks and "•".

Rules for every word here (Play's metadata policy and owner #43):
- Only what the build does. No "best", "#1", "free" or prices, no rankings, no calls like "download now", no
  testimonials, no emoji.
- **Never another game's name** in the listing, its keywords, the release notes or the screenshots' captions, not
  even as "like …" (`tests/unit/test_identity_words.gd` scans `docs/store/`).
- No licensed characters: the storybook costumes are described as "storybook costumes", never by a hero's name (the
  lawyer's check of #36's costume names is still open).

## App name
**EasyCraft** (spec: chosen by the owner 2026-09-23). Package id: `com.giorgi.easycraft` (final, spec §15.4; the debug builds still use `com.giorgi.game`).

**For the owner (owner feedback #43): a trademark search for "EasyCraft" before the first public release.**
The app is already in internal and closed testing under this name; the name (unlike the package id) can
still change until the production release, and it is much cheaper to change now than after launch. The
lead cannot do this search for you, and it is not legal advice (the lawyer who checks the privacy policy can
do it in the same visit):
1. Search the exact name and "Easy Craft" in the official registers, in the classes for games and apps
   (Nice class **9**: downloadable software and games; class **41**: entertainment, online games):
   the US register (USPTO trademark search), the EU register (EUIPO eSearch, or TMview, which covers the EU
   countries' offices too), the WIPO Global Brand Database (international registrations) and Georgia's
   Sakpatenti.
2. Search Google Play and the App Store for "EasyCraft", "Easy Craft" and "EasyCraft" with a space or a
   dash: an existing game with the same or a very similar name is a reason for a store complaint even
   without a registration.
3. Many games end in "-craft"; the ending alone belongs to nobody, but a name that sounds like one famous
   game draws a reviewer's eye. If the search finds a conflict, pick the new name before the production
   release (ideas the lead can prepare: names built on our own magic, e.g. "Buddy Blocks", "Wake the
   Blocks").
4. Write the result (date, where searched, what was found) into this file and tick it in
   `pre-launch-checklist.md`.

## Category, tags, contact (as set in the console on 2026-09-24; no change)
- Category: **Game → Adventure**. Tags (Play offers a fixed list; pick up to 5): Sandbox, Building, Adventure,
  Creative, Offline, if offered.
- Contact e-mail: parkingi-support@googlegroups.com. No phone, no website (the privacy policy's URL is its own field).
- Target audience and the Families answers: `families-and-rating.md`.

## English — the default listing (en-GB)

### Short description (78 characters)
```text
Build anything, wake it up and explore five magical universes full of secrets!
```

### Full description (3,334 characters)
```text
Build anything. Wake it up. Explore five magical universes full of secrets.

Two ways to play
• Sandbox: every block, unlimited. Build castles, rockets, rollercoasters and whole towns with paint, lines, fill, copy and paste, then watch your build grow again with Build Rewind. Bring out any animal, monster or boss from the MOBS page.
• Survivor: gather blocks, trade with Tilly, craft at the Workbench, build a safe home and get through the night. Pip the pet shows new players around in a little playground lesson.

Magic you won't find anywhere else
• Living buddies: build a creature, tap it with the wand and it wakes up, blinks and follows you. Find secret buddy shapes, fill the Buddy Album, teach your buddies tricks, and fly the dragon you built.
• Size Magic: shrink to walk into hidden mouse villages, or grow into a giant.
• Stamps and Mirror: build faster with ready-made shapes and mirrored building. Wear what you build as a hat, a backpack or wings.

Five universes
• Build a golden portal, put in a universe crystal and walk through: Green Meadows, the Sandstorm Desert, Frostpeak, the Candy Kingdom and the Dragon Realm, floating islands at sunrise where the Sky Dragon lives and a baby dragon waits to hatch.
• Forests, flower fields, swamps, beaches, islands, rivers that run to the sea, snowy mountains and glowing mushroom caves; villages with windmills, lighthouses, ships and castle ruins. MY MAP remembers the places you found.
• Secrets everywhere: buried treasure, hidden temples, crystal geodes, shipwrecks. The Secret Book shows how many are still hidden.

Adventures
• Quests: Tilly, Zara, Bram, Mimi and Nell the dragon keeper tell picture stories with keepsakes and titles to earn.
• Monsters come out at night. Hide in a bush, a barrel or a closet, or stand your ground with a sword, a bow and a shield; the harder a weapon is to get, the stronger it is. Every universe has its own boss.
• Animals with real voices: ride horses and camels, tame dogs and cats, and your dog sniffs out buried treasure.
• Books to fill: the Animal Book, the Memory Book, idea cards, trophy shelves and a tree that grows with you.

Never alone
• Bot friends play with you and understand what you say: "follow me", "build a house", "find treasure".
• Play together at home over Wi-Fi, or online with friends you invite: hide-and-seek, races on courses you build, trading, presents and a showcase your friends can visit. Race a friend's ghost on their course, even offline.

You, your way
• Make your look: boy, girl or just me, many hair styles and clothes, and storybook costumes you earn by playing.
• Bigger buttons, a left-handed layout, buttons you can move, bigger text and captions for important sounds.
• Read-aloud buttons use your phone's own voice. Simple controls help younger children.

Made for kids, trusted by parents
• No ads. No loot boxes. No purchases.
• Children under 13 play on their own, at home over Wi-Fi and with bot friends. Online play stays off for them until a parent gives verified permission; friends come only by invitation, and a grown-up approves each one.
• A grown-up area behind a parent gate: online play, chat, friend requests, play time, our privacy promise, and deleting the online account.
• Big buttons, pictures first, gentle stopping points ("Stop for today") and no streaks.
```

## When the shop opens (owner #35; not in 0.4.0)
Only in the release whose build has the Play product ids (`core/shop/shop_catalog.gd` `PLAY_IDS`), at the same time as
the console's "Contains in-app purchases" (see `families-and-rating.md`): replace "• No ads. No loot boxes. No
purchases." with "• No ads. No loot boxes. Nothing random for money. Optional extras (EasyCraft Plus, outfit packs) can
only be bought by a grown-up, behind a parent gate, with the price shown first."

## What each line rests on (re-check when a feature changes)
| Line | Built in |
|---|---|
| Sandbox tools: paint, lines, fill, copy/paste, Build Rewind; wearing builds | M3 Task 8 |
| The MOBS page (any animal, monster or boss, Sandbox) | owner #51 |
| Survivor, Tilly's shop, the Workbench | M2 Tasks 5–7, crafting (M3 Task 22), #43 (Workbench name) |
| Pip's playground lesson (Survivor, solo, the first time; PIP'S LESSONS in SETTINGS replays it) | M3 Task 15 (after 0.4.0) |
| Living buddies, secret shapes, Buddy Album, tricks | M1, M3 Task 20b; flying a built dragon: M3 Task 20a |
| Size Magic, mouse villages | M1, M3 Task 21c |
| Stamps, Mirror | M1 |
| Golden portals, five universes, Dragon Realm, Sky Dragon, baby dragon | M3 Tasks 2–5, owner #39, #43 |
| Forests, rivers, villages, MY MAP | owner #45b |
| Secrets, shipwrecks, the Secret Book | M2 Task 16, owner #42 |
| Quests with Tilly, Zara, Bram, Mimi, Nell | owner #45a |
| Hiding spots, weapons, bosses; a weapon's strength follows how hard it is to get | M2, M3 Tasks 2–4, #39; owner #53 (after 0.4.0) |
| Riding horses and camels; the dog finds treasure | owner #41, M3 Task 11 |
| Animal Book, Memory Book, idea cards, trophy shelves, the tree (the Hub Tree) | M3 Task 21b |
| Bot friends understand the chat | owner #38 |
| LAN, online with invited friends, hide-and-seek, courses and races, trading, presents, showcase, ghosts | M1, M4 Waves 1–3, M3 Task 7, M4 H, owner #37, M4 I, M4 ghost races |
| Boy / girl / just me, costumes | owner #48, owner #36 |
| Bigger buttons, left-handed layout, movable buttons, text size, sound captions | M5 Task 1 (after 0.4.0): BUTTON SIZE, the left hand, MOVE BUTTONS, TEXT SIZE, sound captions (`docs/devlog/parts/m5-task-1.md`) |
| Read-aloud, Simple controls | M3 Task 21a (read-aloud needs the phone's text-to-speech voice; the buttons hide without one) |
| No ads, no loot boxes, no purchases | spec §6; the shop's Play ids are empty in 0.4.0 (`ShopCatalog.PLAY_IDS`), so release builds say "The shop isn't open" |
| Under 13: online off until verified consent, friends by invitation, a grown-up approves each | M4 Waves 1–2; server 0.2.8 (the band only ever gets stricter). The consent provider is not registered yet, so for now online stays off for under-13 players: the line is still true |
| The grown-up area, the privacy promise (its PRIVACY page), deleting the online account | M4 C/F, M5 Task 4 (after 0.4.0), M4 Task 8b |
| Stop for today, no streaks | M2 Task 17, spec §6 |

## Art direction (owner feedback #43: our own look, spec §3c)
Block building is a genre, and other block games are on Google Play; what gets a game into trouble is
looking copied or suggesting a connection to another game. So every picture of the store page shows what
only EasyCraft has, first, and in its own colours:
- **Lead with the living buddies, Size Magic and the universes.** The first two screenshots and the feature
  graphic show a build waking up (googly eyes, the wand's sparkle) and a tiny or giant child next to it; the
  universes (the Candy Kingdom, Frostpeak, the Sandstorm Desert, the Dragon Realm at sunrise, the golden
  rainbow portals) come next. **Never a plain grass-block landscape** as a first picture, and never a lone
  block as the icon.
- **The icon is the buddy mark**: the orange block buddy with googly eyes and the wand's star on our teal
  (`icon.png`, made by `tools/make_brand_art.py`; the 512 px store copy is
  `docs/store/graphics/next/icon-512.png`, for the lead to upload instead of the grass-block icon that is
  live now).
- **Our palette**: teal and sunrise orange for the brand, the universes' own colours in the pictures, the
  new default avatar (orange tee, teal trousers, the buddy badge), never the old yellow-and-blue default.
- **Words**: never another game's name anywhere in the listing, its keywords, the release notes or the
  screenshots' captions, not even as "like …" or "better than …" (Play treats that as impersonation and
  keyword spam). `tests/unit/test_identity_words.gd` scans `docs/store/`, the release notes and the game's
  text for the names.

## Graphics
The exact shot list (scenes, chat commands, universes, sizes, captions), the feature graphic and the icon:
**`screenshots.md`**. Since 2026-09-27 the live pictures are that list's
(`docs/store/graphics/next/`); the 0.3.2 ones (secrets on grass-block land) are gone from the tree.
