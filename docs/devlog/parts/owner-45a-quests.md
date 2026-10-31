# Owner feedback #45a: more quests (notes)

Owner, 2026-09-24 21:49: "save into plan that we should continue implementing new quests and also we should extend
the world". Brief `docs/superpowers/briefs/prompt-own45.md`, section "45a — Quests"; spec **§14.17** (new); plan M3
**Task 24a**. Built by a background agent in its own worktree after `git merge lead-merge` (a fast-forward to
`27306da`: the adventure board and levels, the treasure pack, pets, Monster Wave, crafting, the Gold Farm, the action
kit, bot chat, the chat commands, the audio pass), without the editor or the emulator. Before the final suite
`lead-merge` was merged again (`6c838c6`: owner #49's chat, #50's animal chorus and the lead's fixes for the pets'
voices and three test gaps, which failed the first suite run on the old base — `test_voice_rules` fails the same way
on `27306da` alone). **Part b (the bigger world)
is not touched: no generator changed.** The #41 animals pack is not merged yet: its goals wait for the species.

## What was built

| Piece | Where | What it does |
|---|---|---|
| More counters | `core/progress/level_rules.gd` (families), one-line raisers in `autoloads/session.gd` (`host_craft`), `world/pet_director.gd` (`on_treat`), `world/ride_director.gd` (`host_ride`), `world/course_director.gd` (the medal), `world/progress_director.gd` (`watch_host`: the world's real boss, `wave_won/arena`) | `item_crafted/<recipe>` (XP 10, new style "Master Crafter"), `pet_fed/<species>` (5, Animal Friend), `buddy_ridden/<fly/drive/sail/walk>` (10, Buddy Maker), `quest_step` (20) and `quest_done/<chain>` (100, new style "Quest Hero"), `race_finished/<gold/silver/bronze>`, `boss_beaten/<serpent/giant/cake/golem>` (was always "golem"), `wave_won/arena` (Monster Wave) |
| Counts per universe | `autoloads/progress.gd` (`Progress.universe`, signal `counted`), `core/progress/progress_data.gd` (`u_counts`, `count_in`, `record(kind, n, u)`) | every event also counts in the universe it happened in (at most 8 universes × 64 kinds: the server backup's 60 KB); the backup merge keeps the best of both |
| 44 new board goals | `core/progress/board_rules.gd` (67 in all) | the desert, Frostpeak and Candy (their monsters; bosses in Monster Wave; secrets and 5 places explored in that universe), crafting (a table, 10 things, a stone pickaxe, glass, an iron sword), Monster Wave (3 and 10 arena waves), pets (fox, parrot, 3 treats, 3 animals), the #41 animals (horse, camel, penguin: listed once the species exist), the #42 treasures (shipwreck, vault, haunted house, well, rainbow, mineshaft), races (3 races, a gold medal), building (500 blocks, ride a buddy, fly a buddy dragon), quests (finish a story), explore 20 places. Each says its `modes` (and `universe`); the goal list says where a goal counts when it can't be done here ("in Monster Wave", "in the Sandstorm Desert"). |
| Stories | `core/progress/quest_rules.gd` (`QuestRules`, pure), `core/progress/quest_data.gd` (`QuestData`, in `ProgressData.quests`) | 4 givers (Tilly, Zara the explorer, Bram the ranger, Mimi the baker), 9 chains of 3–4 steps: DO (count an event of the chain's universe from the step's start), REACH (walk to the nearest place of a secret kind: "follow it to the pyramid"), GO (come back to the giver). Start, stop (the story waits with what it counted), resume, a friend's help, finish (keepsake, title `q_<chain>`, place), gold base × 2^(u−1); a helper's spot from the seed |
| The world's glue | `world/quest_director.gd` (`QuestDirector`, node `Quests` on every peer), section at the end of `scenes/sandbox.gd` (+3 one-liners: `_add_quests`, `_setup_quests`, Android Back, `BotDirector.quest_near`) | places the giver, the bubbles ("!" a story waits, "?" come back), a tap on a giver → its card (and it counts as coming back), moves the story on once a second and on every counted event, banners, confetti and jingles, Survivor gold through the host once, the arrow (a `FindArrow` in the compass's spot; places looked up on a worker thread, a guest asks the host), co-op sharing |
| Givers | `entities/npcs/quest_giver.gd` (`QuestGiver`) | a blocky figure per giver (straw hat, explorer's hat and backpack, fur hood and scarf, baker's hat) with two shared meshes, a name label, a bubble, one small static body; turns and waves at a player near; `QuestGiver.find` for taps (like `Trader.find`) |
| Taps | `entities/player/block_interactor.gd` (section "Owner #45a") | a tap on a giver emits `quest_giver_tapped`; a tap on Tilly's stall opens her card instead of the shop only while she has something to say (`stall_quest_tap`) |
| UI | `ui/progress/quest_overlay.gd`, `quest_card.gd`, `quest_book.gd`, `quest_pictures.gd`, `read_aloud.gd`; `ui/hud/hud_icons.gd` (picture `quests`); `ui/progress/progress_pictures.gd` (+48 pictures) | MORE → QUESTS (a 135 px picture button in the MORE panel: no new always-visible button) opens the book; a giver's card; both take touches before the HUD; the speaker button reads the page aloud (system TTS, hidden without a voice) |
| Titles | `level_rules.gd` (`is_title`, `title_text`), `name_tag.gd`, `progress_data.gd`, `autoloads/progress.gd`, the board's title page (scrolls now) | a story's title ("Pyramid Pal") is picked like the play-style titles and shows on the name tag |
| Secret Book | `ui/hud/secret_book.gd` | a third page, "Keepsakes": a spot per story, its keepsake once done, "Ask Zara" until then |
| Sticker book | `ui/progress/trophy_room.gd` | scrolls (67 goals + 3 gift stickers) |
| Bots | `world/bot_director.gd`, `core/bots/bot_intents.gd`, `bot_answers.gd` | "find treasure", "follow the arrow", "quest", "ისარს" lead to the child's story's place first ("the place of your quest") |
| Smoke run | `tools/quest_smoke.gd`, `tools/quest_smoke_steps.gd` | a new desert Survivor world, end to end (26 checks) |
| Project | `project.godot` `[audio] general/text_to_speech=true` | Godot's TTS |

### The stories

| Giver (universe) | Story | Steps | Keepsake · title · gold |
|---|---|---|---|
| Tilly (Green Meadows) | Tilly's lost map | dig up buried treasure → find the old ruins → back to Tilly | old key · Map Reader · 100 |
| | A home for animals | tame a dog or cat → chase away 3 slimes → find a hollow tree → back | golden bell · Animal Hero · 120 |
| | Catch a falling star | wake a buddy → catch a shooting star → find a crystal geode → back | star in a jar · Star Catcher · 150 |
| Zara (Sandstorm Desert) | The golden scarab | find my lost map piece (treasure) → follow it to the pyramid → open the hidden door → bring the scarab | golden scarab · Pyramid Pal · 100 × 2 |
| | Safe desert paths | chase away 3 scorpions → make glass in a furnace → find the old mineshaft → back | Zara's compass · Desert Guard · 120 × 2 |
| Bram (Frostpeak) | Light up the camp | find the snowy camp → make a lantern → chase away 2 yetis → back | snow globe · Frost Friend · 100 × 4 |
| | The ice temple | chase away 3 ice bats → follow the arrow to the ice temple → the plates in order → back | ice crown · Ice Explorer · 120 × 4 |
| Mimi (Candy Kingdom) | The big cake party | 3 gummy bears → a rock-candy geode → the gingerbread house's treasure → back | cherry cupcake · Sweet Helper · 100 × 8 |
| | The hidden recipe | 2 candy sneakers → the hidden room in the cake → the haunted house → back | recipe book · Candy Chef · 120 × 8 |

## Skills and patterns (godot-prompter)

- **dialogue-system:** its Resource-based `DialogueLine`/`DialogueData` and a dialogue manager autoload were
  **rejected** for const tables in a pure class (like `BoardRules`): the stories are short, fixed and tested as data
  (every step's kind really raised, pictures known, no clock words); a card shows one "beat" (the giver's hello, the
  story, LET'S GO / NOT NOW) instead of a line-by-line typewriter (children who can't read get pictures and the
  read-aloud button). Kept from it: data separate from the UI, the UI driven from the data, one place for the text.
- **multiplayer-basics:** the host decides the shared story (any_peer requests checked on the host: known kind,
  a player in the game, 20 events per 10 s; authority RPCs back); every RPC goes only to a connected peer (`_send`),
  so solo play and tests send nothing. Givers are placed by every game from the seed (no spawner, nothing sent),
  as the hub circle is. Rejected: a MultiplayerSynchronizer for the shared story (a small reliable RPC on each
  change is enough).
- **event-bus:** the story follows `Progress.counted` (the existing bus) instead of hooks in every system.
- **godot-ui:** the book and card are containers in a centred PanelContainer; lists scroll; every page is measured
  against 1280 × 720; the MorePanel pattern (take touches in `_input` before the HUD's `TouchButton`s).

## Tests (RED → GREEN)

| File | Tests | RED |
|---|---|---|
| `tests/unit/test_quest_rules.gd` | 17 | missing `QuestRules`; then a hollow tree's kind is `hollowtree`, a 5-word keepsake, the name tag ignoring quest titles |
| `tests/unit/test_quest_data.gd` | 9 | missing `QuestData` / `ProgressData.quests` / `count_in` |
| `tests/unit/test_board_goals_more.gd` | 8 | missing `LevelRules.CRAFTED`, `BoardRules.modes_of`; a goal of a universe counted everywhere |
| `tests/integration/test_quest_director.gd` | 20 | written after the director: **mutation-checked** (below); `test_the_arrow_rests_at_the_place` proper RED (the arrow blinked back every second at the place) |
| `tests/integration/test_quest_book.gd` | 14 | the book, the card, MORE → QUESTS, touches, fits, no clock words |
| Added to Task 12's and others' | 11 | `test_courses` (the medal counts), `test_ride_director` (a ride counts), `test_pet_director` (treats count), `test_craft_session` (a craft counts), `test_progress_director` (the real boss, arena waves, per universe): **proper RED** ("0 expected to equal 1"); `test_adventure_board` (a story's title; where a goal counts), `test_secret_book_pages` (the Keepsakes page, 3 pages), `test_bot_talk` (follow the arrow), `test_bot_intents` (the arrow words; the Georgian one failed first: "მიჰყევი" sounded like FOLLOW, so the arrow words weigh 6) |
| Changed | | `test_board_rules` (≥ 23 goals; the new creative families; the list offers only available goals), `test_adventure_board`'s sticker book now scrolls (it measured 1249 px tall with 67 goals: RED, then a ScrollContainer) |

**Mutation check of the director and bot tests** (the director was written before its tests): five breaks at once —
rewards sent to every guest instead of the helpers, gold paid more than once, a tap on the giver not counting as
coming back, a guest who isn't in the game counting for the shared story, bots ignoring the quest place — made
exactly the five matching tests fail (`test_everyone_who_helped_gets_the_reward_and_nobody_else`,
`test_a_story_done_in_survivor_pays_its_fixed_gold_once`, `test_a_tap_on_the_giver_is_coming_back`,
`test_a_friends_matching_events_count_for_the_shared_story`, `test_follow_the_arrow_leads_to_the_quest_place_first`);
all restored and green.

**Full suite** (`tests/suite_slots.sh tests/run_tests.sh`, on `lead-merge` `6c838c6` + this work): **473 scripts,
4605 tests, all passing**, exit 0, no `SCRIPT ERROR` / `Parse Error` (it waited 19 minutes for a slot; the run took
about 11 minutes at load 22–37). The smoke run passes 26 of 26 on the same tree.

### The smoke run (the real game, headless)

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script
res://tools/quest_smoke.gd`: a new Survivor world in the Sandstorm Desert. **26 of 26 checks pass** (exit 0), no
engine errors: the director and QUESTS in MORE; Zara at her seed spot 16.8 blocks from the spawn, on the ground,
with "!"; a real tap through the interactor opens her card; LET'S GO; the arrow at the nearest buried treasure; an
explorer bot asked "follow the arrow" guides to it; the treasure found through the Secret Director's own path; the
arrow to "the puzzle temple"; walking there (6 blocks from it) counts; the pyramid solved → "?" over Zara; walking
back ends it: the scarab, 200 gold (25 → 225) from the host, a place, 4 steps counted, the banner, the title on the
name tag ("2:q_zara_scarab"), the book ("Zara 1/2", "1 of 9 keepsakes"), the Secret Book's page, the profile on disk.

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **Tilly is Green Meadows' giver:** in Survivor she is the trader (a "!" over her stall; a tap opens her card, which
   has SHOP, only while she has something to say — otherwise the shop opens as before); in the Sandbox (no stall) a
   Tilly figure stands where her stall would be. The helpers live in universes 2–4, which are Survivor worlds; the
   Monster Wave arenas have none. *Cost if wrong:* a Sandbox child meets only Tilly's three stories.
2. **Every game places its giver from the seed** (no spawner, nothing saved), like the hub circle: 13–19 blocks from
   the spawn on dry, level ground clear of trees, 6+ blocks from Tilly's stall, the Totem, the hub circle and the
   Theater and 3+ blocks off the straight ways from the spawn to them — inside the treasure pack's 60-block clear
   zone, so no secret place is ever built there. Tested over 4 seeds × 3 universes. *Cost if wrong:* on odd terrain
   the fallback spot may be uneven (still off the ways).
3. **9 stories of 3–4 steps** (the brief allows 3–5), told in order: a giver's next story comes after the one before.
   All steps are things the world already has (secrets and #42 places, animals, monsters, crafting, buddies).
   *Cost if wrong:* content only (a `QuestRules.CHAINS` row).
4. **A step counts only in its story's universe, from the moment it starts** (per-universe counts); a "follow the
   arrow" step's find on the way counts for the next step (a child who solves the pyramid before the walk registers
   isn't asked to do it again). *Cost if wrong:* none known.
5. **One story is followed at a time; the others wait with what they counted.** STOP FOR NOW or starting another
   story keeps its step and count; nothing counts for a waiting story; GO ON goes on from there. No timers, dates or
   streaks anywhere (tested on the data, the stories' words and every page). *Cost if wrong:* none known.
6. **A tap on the giver counts as coming back** (a tap reaches 6 blocks), as well as walking within 4.5.
7. **Stories with crafting are Survivor-only** (crafting is Survivor's); the Sandbox tells Tilly's three (none crafts).
8. **Rewards are profile data, not items:** no item or block ids were taken (the M3 plan's Allocations say so). The
   keepsake sits on the Secret Book's new Keepsakes page and in the quest book; the title (`q_<chain>`) on the name
   tag; the place (universe, world seed, x, y, z) in the profile — the quest book's PLACES shows the way back in that
   world with the arrow, and 45b's world map can draw them. Gold: base 100/120/150 × 2^(u−1), paid by the host
   once per player and story. *Cost if wrong:* a modified LAN guest can claim a story's gold once per session
   (trusted LAN, like board goals; M4's server wallet can take it over).
9. **Co-op: the host decides.** PLAY TOGETHER (in the host's book, with friends in the game) shares the host's story
   of this universe. A guest's game sends its events that match the shared step (the host counts at most 20 per
   10 s per guest); any player's arrival counts. **Helpers** are the host, every guest whose event counted, the
   player who did a step and everyone within 24 blocks of them; when the story ends each helper gets its keepsake,
   title and place and (Survivor) its gold from the host, once — a helper who did that story before gets nothing
   again. A guest's own story keeps its place. *Cost if wrong:* a friend who left before the end gets no reward
   (they can do the story themselves).
10. **Bot friends lead to the story's place first** when asked to find treasure, "follow the arrow" or about the
    quest (the host knows a guest's place: its game tells it). Georgian arrow words (ისარი, ისარს, ისრის) and the
    answer "შენი თავგადასავლის ადგილი": **native check needed**.
11. **44 new goals**; bosses of universes 2–4 are Monster Wave goals (Survivor has no bosses since #44); the old
    "Beat the Stone Golem" now counts the golem only (every boss counted as "golem" before); "Win a wave" is Sandbox
    and Monster Wave (Survivor lost its Totem, #44). Goals of the #41 animals (horse, camel, penguin) are hidden until
    the species exist. Board gold stays paid where gold is real (Survivor and Monster Wave). *Cost if wrong:* change
    a row's `modes`.
12. **Counts per universe are capped** (8 universes × 64 kinds) so the profile stays well under the server backup's
    60 KB (tested). *Cost if wrong:* a 9th universe's goals would count only account-wide.
13. **Read-aloud through the system's text-to-speech** (research O6): a drawn speaker button on the card and the book;
    it hides where the device has no voice. *Cost if wrong:* no button on a phone without TTS voices.
14. **Two new play styles** for the new counters: "Master Crafter" (crafting) and "Quest Hero" (quest steps and
    stories); treats count for Animal Friend, rides for Buddy Maker.
15. **The quest pages take touches before the HUD** (the MorePanel pattern): a finger on the book never presses
    JUMP behind it; one outside closes it (tested with real touches in a SubViewport).

## What the lead should check on the emulator

1. **Sandbox (Meadows):** a Tilly figure near where the stall would be (≈ 12 blocks from the spawn), a yellow "!" over
   her; walk up, tap her: her card (her picture, "Hello, friend!", the story's picture and words, 3 step pictures,
   "You get: tilly's old key"), the speaker button reads it aloud on the phone; LET'S GO: an arrow with distance in
   the compass's spot (top right) pointing to buried treasure. MORE → QUESTS: the book fits 2400 × 1080; ARROW: OFF
   hides the arrow; STOP FOR NOW / GO ON.
2. **Survivor Meadows:** a "!" over Tilly's awning; a tap opens her card with SHOP (SHOP opens the shop); with no "!"
   a tap opens the shop at once, as before.
3. **Survivor desert / Frostpeak / Candy:** Zara, Bram, Mimi by the spawn, not in the way to Tilly's stall, the
   Totem, the hub circle or the Theater. Play "The golden scarab" to the end: banners, the jingle, confetti, +200
   gold, "?" over Zara before the last step, the keepsake on the Secret Book's third page, the title on the board's
   title page ("Pyramid Pal").
4. **LAN (two instances):** the host's book → PLAY TOGETHER; the guest's book says "Playing together: …"; the guest
   finds the step's secret → the host's story moves on; at the end both get the keepsake (and gold in Survivor);
   the title shows on the other player's name tag.
5. **Bot friend:** chat "follow the arrow" (or the BOTS page's treasure picture): an explorer leads to the step's place.
6. **Board:** the goal list (8 columns, scrolls) shows the new goals with "in Monster Wave" / "in the Sandstorm Desert"
   under the ones that count elsewhere; the sticker book and the title page scroll.
7. **Performance:** the director decides once a second; a giver is two shared meshes; the place lookup runs on a worker
   thread (check no long frame when a story starts or a step moves on).
