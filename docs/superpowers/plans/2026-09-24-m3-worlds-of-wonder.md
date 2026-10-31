# M3 "Worlds of Wonder" Implementation Plan — universes 2–4, portals, Physics Lab, smart blocks, building tools, avatar editor, pets, farm, tutorial, codes, missions, Theater, action kit, photo mode

> **For agentic workers:** tasks run as parallel background agents in git worktrees with the fixed
> allocations below (no editor/emulator use, a notes file in `docs/devlog/parts/m3-task-<n>.md`);
> tasks marked **(after M2)** start once the M2 system they build on is merged. The lead merges,
> integrates and verifies on the emulator. TDD for every rule in `core/`.

**Goal:** the universe ladder (universes 2–4 with their monsters, bosses and secrets), a much richer
Sandbox (Physics Lab, smart blocks, Game Blocks courses, power tools, Build Rewind, Build-and-Wear),
self-expression (avatar editor, skins, emotes, pets with perks, photo mode), gentle long-term goals
(levels, missions, daily gift, Gold Farm, tutorial, codes), the Shorts Theater and the action kit.

**Spec:** `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` **§14** (detailed M3 spec),
refining §5 and §13, and **§16** (the engagement research's M3 core set: Tasks 20–21). Research:
`docs/design/` (owner feedback #21).

## Global constraints
- Everything from M1/M1b/M2 applies (performance bar on the emulator in both styles, in every
  universe; no per-event materials; host-validated actions; CC0 assets credited; fair fun §6: no loot
  boxes, no paid randomness, no punishing streaks).
- Child-first UI: icons first, short words, big buttons; nothing requires reading long text.

## Allocations (fixed)
- **Block atlas pages** (Task 1): the block library gets pages — page 0 is today's atlas (ids < 64);
  each universe and system gets its own 8 × 8 page (`data/blocks/pages/<name>.png` + realistic twin),
  one material per page. **Blocks and items share one id space** (a hotbar slot or a bag holds either;
  found by Task 5, lead's re-allocation 18:20): items own **100–175** (built) and **400+** (planned), so
  block ranges are: desert 64–79 (page 1, Task 2), frost 80–95 (page 2, Task 3), candy **176–191**
  (page 8, Task 4), smart + game blocks **192–207** (page 9, Task 7), portals/pads/lab **208–223**
  (page 10; Task 5's frame 208 and core 209; the Lab's pads stay 36–37 on page 0), ~~building-tool blocks
  224–239 (page 11, Task 8)~~ **the Dragon Realm 224–239 (page 11, owner #39, 2026-09-25: every 16-id page ≤ 255
  was allocated and Task 8's tools are items; Task 8 keeps page 12)**, painted blocks **240–255** (page 12,
  Task 8).
  **Page 13, ids 256–271: the wild meadows (Task 24b, owner #45b, 2026-09-25)** — every 16-id page ≤ 255 was
  allocated (the Dragon Realm took page 11), and items own only 100–175 and 400+, so blocks may use 256–399
  (the voxel type channel is 16-bit; `BuildCodec.BLOCK_MAX` and the server's `BuildRules.BLOCK_MAX` rise to 399).
  **Page 14, ids 272–287: M3 Task 21c** (272 pumpkin, 273 jack-o-lantern, 274 snowman's head, 275 the mice's cheese;
  276–287 free). Next free: page 15 (288–303) … page 21 (384–399).
  `test_no_block_takes_an_item_id` and `test_no_item_takes_an_id_of_the_block_pages` guard it.
  Page 10 (208–223) in detail (19:40): 208–209 portal frame and core (Task 5), 210–215 gadget blocks
  such as the zipline post (Task 14a), 216 SADDLE (Task 20a), 217–218 the trophy shelf and book blocks
  (Task 21b), ~~219 a mouse-hole marker (Task 21c)~~ (unused: Task 21c's blocks are on page 14, 272–275), **212–215 and 222 the universe portal cores (owner #39: meadows
212, desert 213, frost 214, candy 215, dragon 222; tiles 2 × (id − 208)), 223 free**. Tasks 20 and 21 are split for agents: 20a rideable
  buddies, 20b buddy magic; 21a words and voices, 21b books and memories, 21c the Tiny world and wake-ups.
  Agent order as slots free (lead, 19:40): M4 H, M4 I, then Tasks 4, 11, 14a, 14b, 8, 10, 20a, 20b, 21a,
  21b, 21c, and Task 15 (the tutorial) last.
- **Item ids**: gadgets and blasters **400–429** (Task 14; Task 8 took the free **408–411** for its tools), pet treats **430–434** (Task 11), paint
  **435–450**, crafted items **451–459, 490 and 495–499** (Survivor games + crafting, owner #34), gift stamps
  **460–479** (M4 I), universe crystals **480–489** (owner #39; lead 21:39), the Gold Farm **491–494**
  (Task 10: 491 `FARM`, bought from Tilly and placed; the lead's ids for it) (Task 8; `ChatCommands._LAST_ITEM_ID` grows with them), avatar items live in profile
  data, not item ids (Task 9). Task 24a (quests) takes **no** item or block ids: keepsakes, quest titles and
  quest places are profile data (`ProgressData.quests`).
- **Profile fields** (each task adds its own, parsed defensively): avatar/cosmetics (Task 9),
  level/XP/missions/achievements/gift (Task 12), codes redeemed (Task 13), farm (Task 10), tutorial
  done (Task 15), unlocked universes (M2).
- **HUD/menu spots**: LAB button (right column, Sandbox, Task 5); avatar editor in the main and pause
  menus (Task 9); emote wheel button (left column, Task 9); photo button (top-right, Task 16); missions
  panel in the pause menu (Task 12); admin panel text at the main menu's bottom (Task 13); the race clock
  top-centre below the wave/boss lines (Task 7, a label, never a button). Wave 2+ agents add no new
  always-visible HUD buttons (the M2 HUD pass moves rare ones into a MORE menu). **Since the M2 HUD
  pass** (`docs/devlog/parts/m2-task-17-hud.md`): LAB, the emote button and the photo button live in
  the MORE panel; every spot is in `HudLayout.SPOTS`; a new button used now and then goes in with
  `hud.more.add(button)` (135 px, a `symbol` from `HudIcons` and a short word).

## Review focus
1. Universe worlds never leak items/gold between modes or break the M2 save; the portal hub is safe.
2. Every universe holds the performance bar (new blocks via pages add ≤ a few draw calls per chunk).
3. Smart blocks and power tools can't be used to grief on LAN (host checks, caps, one undo).
4. Cosmetics and codes can't be minted by a client; nothing is random for money.
5. Children understand every new UI without reading much.

---

### Task 1: Block atlas pages (lead) — **done 15:45** (`tests/unit/test_block_pages.gd`)
Pages in `world/block_library.gd` (tiles per page, material per page, both styles), `tools/make_atlas.gd`
pages, the realistic twin tool; existing worlds render identically. Tests: every id maps to one page and
tile; both styles share each page's layout; page materials are shared, long-lived.

### Task 2: Sandstorm Desert (after M2 Tasks 4, 10, 16)
Generator shape (dunes, mesas, oases, pyramids with traps and treasure rooms), desert blocks page,
mummy and scorpion (spitter), the Sand Serpent boss, sandstorm weather, desert music, secrets, trader
stock. Tests per §14.1.

### Task 3: Frostpeak (after M2 Tasks 4, 10, 16)
Peaks, ice lakes (slippery), pines, igloos; snowstorms hiding everyone; yeti (tank) and ice bat
(flyer); the Frost Giant; frost blocks page; music; secrets. Tests per §14.1.

### Task 4: Candy Kingdom (after M2 Tasks 4, 10, 16)
Candy forests, chocolate rivers (swimmable, Task 14 of M2), gumdrop hills, cake mountains; gummy bear
(bouncing jumper) and candy sneaker; the Cake Monster (layered); candy page; music; secrets.

### Task 5: Universe ladder and portals (after M2 Task 10) — **merged 18:20**
Per-universe Survivor worlds (`survivor_u<u>`), the boss portal leading to the next, the portal hub (menu
+ stone circle), portal frames/cores linking two places in a world (Sandbox too), scaled prices.
Notes, the universe descriptor interface (`world/universes/<name>.gd`) and 8 rulings:
`docs/devlog/parts/m3-task-5.md`. Not done: the "+" tool levels of later universes (spec §14.1).

### Task 6: Physics Lab (Sandbox)
LAB button: Normal, Moon gravity, Zero-G, Fly, Ghost, Slow motion; jump pads and speed pads. Tests:
each mode's movement rules; Survivor keeps Normal + paid Fly.
**Merged** (`ea2e602`, `a6be563`, `933f87e`): `core/rules/lab_rules.gd` (LabRules), `core/rules/pad_rules.gd`
(PadRules), `entities/fx/pad_fx.gd` (PadFx), `ModeRules.PHYSICS_LAB`, pad blocks **36 JUMP_PAD and
37 SPEED_PAD** (`BlockIds.COUNT` 38; 32–35 are M2 Task 16's; move them to 128–135 with Task 1's pages),
sections in `entities/player/player.gd` (`lab_mode`, synced), `entities/animal/animal.gd`,
`ui/hud/hud.gd` (LAB at (-226, 204)), `scenes/sandbox.gd`, `WorldMeta.lab_mode`, the `lab_mode` action
(L), sounds `boing`/`whoosh` (`tools/make_pad_sfx.py`). Tests: 2 unit + 3 integration scripts (63 tests)
and additions to 4 unit scripts. Notes, rulings and the emulator checklist: `docs/devlog/parts/m3-task-6.md`.

### Task 7: Smart blocks and Game Blocks
Button, lever, pressure plate, powered door, jump pad, teleport pad pairs, light switch (one-step
power); START / FINISH / CHECKPOINT / COIN / BOUNCE with timer, respawn at checkpoints, medals by the
builder's goals; friends and bots can race. Host-validated; saved.

### Task 8: Building tools
Paint bucket (16 tints, a tint channel or tinted variants — decide by cost), line, fill (capped, one
undo), copy/paste with rotation, Build Rewind (record + orbit replay), Build-and-Wear (≤ 5 × 5 × 5
build → hat/backpack/wings, saved in the profile). Build-and-Wear picks its build with M4 agent I's
`BuildPicker` when that is merged first.
**Done in a worktree, to merge:** ids (blocks 240–255 PAINTED_* on page 12, `BlockIds.COUNT` 256; items 435–450
PAINT_*, and **408–411** LINE_TOOL, FILL_TOOL, COPY_TOOL, REWIND: the gadgets' free ids, ruling 2), `core/building/`
(PaintRules, PowerTools, RewindLog), `core/avatar/wear_rules.gd` (WearRules; `AvatarLook.builds`, code ≤ 2,048),
`data/blocks/paint_page.gd` + `tools/make_paint_page.gd` / `.py` (both styles, CC0 Plaster001), `entities/player/`
(BuildToolUser, WearMesh; sections in `block_interactor.gd`, `avatar_model.gd`), `ui/building/` (BuildToolBar,
RewindView, RewindPreview, WearCard), `ui/hud/build_tool_icons.gd`, the palette's BUILD tab, sections in
`autoloads/session.gd` (tool requests, the host's tool log, big edits 8 ms of writing a frame), `world/world_service.gd`
(`blocks_at`, `set_blocks`: one copy/paste for a box), `scenes/sandbox.gd`, `scenes/chat_command_runner.gd` and
`core/rules/chat_commands.gd` (/fill, /copy), `WorldMeta.rewind`; `tools/build_tools_smoke.gd`. Notes, rulings,
measurements and the emulator checklist: `docs/devlog/parts/m3-task-8.md`.

### Task 9: Avatar editor, skins, emotes, celebrations
Editor in menus; parts for both styles; own-design skins; emote wheel and dances; victory celebration
after waves/bosses; unlocks by gold/achievements/secrets/codes at fixed prices; saved in the profile.
**Merged** (`8370b88`, `b19e864`): `core/avatar/` (AvatarCatalog, AvatarLook,
AvatarUnlocks, EmotePoses), `entities/player/` (AvatarParts, AvatarSkin + shader, AvatarTrail,
Celebration, EmotePoser; sections in `avatar_model.gd`, `blocky_avatar.gd`, `realistic_avatar.gd`,
`player.gd`), `ui/avatar/` (AvatarEditor, AvatarPreview, AvatarTile, AvatarIcon, EmoteWheel,
EmoteButton), sections in `autoloads/session.gd`, `autoloads/profile.gd`, `core/save/profile_data.gd`,
`core/codes/code_rules.gd`, `ui/hud/hud.gd`, `ui/menus/menu.gd`, `ui/menus/pause_menu.gd`; masks in
`assets/characters/avatar_masks/`; tools `make_avatar_masks.py`, `avatar_gallery.gd`. Hooks for other
tasks: `Session.celebrate_all()` (M2 Tasks 9–10), `AvatarUnlocks.earn(profile, AvatarCatalog.EARN_*)`
(Tasks 4, 15, M2 Task 10, secrets), `Session.emote_played` and `Player.show_emote` (bots, buddies).
Notes and the emulator checklist: `docs/devlog/parts/m3-task-9.md`.

### Task 10: Gold Farm (after M2 Task 7)
Farm building from the trader, offline earnings (capped 12 h, scaled), upgrades, workers, the welcome-
back coin shower, opt-in local notification.
**Merged** (`cb1dd2d`): `core/economy/` (FarmRules, FarmSite, FarmNotifyRules), `net/` (FarmNotifier,
AndroidFarmNotifier: the plugin is M5's), `entities/farm/` (FarmBuilding, FarmWorker), `world/farm_director.gd`
(node `Farm`), `ui/hud/farm_panel.gd`, `Fx.coin_shower`, `ItemIds.FARM` 491 and its icon, Tilly's HOME price,
sections in `autoloads/session.gd`, `scenes/sandbox.gd`, `ui/hud/hud.gd`, `entities/player/block_interactor.gd`,
`ui/menus/settings_panel.gd` ("Farm note"), `WorldMeta.farm`, the profile's `farm_note` / `farm_note_at`;
`tools/farm_smoke.gd`. Beyond the brief: MOVE (the farm back in the bag with its levels). Notes, 13 rulings and the
emulator checklist: `docs/devlog/parts/m3-task-10.md`.

### Task 11: Pets with perks (after M2 Tasks 4, 16)
Perks for dogs/cats; Pip the robot pet; fox (finds buried treasure); parrot (points at secrets);
happiness heart and treats (never required).
**Merged** (`fb21ff3`): `core/rules/pet_rules.gd`, `pet_perks.gd`, `pet_echo.gd`, `world/pet_director.gd`
(node `Pets`), `ui/pets/` (PetPanel, PetHeart, PetPictures), sections in `entities/animal/animal.gd`,
`autoloads/session.gd`, `scenes/sandbox.gd`, `entities/player/block_interactor.gd`, `ui/hud/block_palette.gd` (the
PETS tab), small additions (items 430–434, the fox/parrot/Pip species, models, minds, Tilly's treats, saves, the
profile's Pip, `/summon fox|parrot|pip`, the chat's `own_line_sent`); `tools/pets_smoke.gd`. For Task 15:
`PetRules.give_pip(Profile.data)` then `sandbox.bring_pip()`. Notes, 16 rulings and the emulator checklist:
`docs/devlog/parts/m3-task-11.md`.

### Task 12: Levels, the adventure board, achievements, presents during play
XP from events (a small event bus), level titles for every play style on name tags, the **adventure
board** (3 picture goals the child picks, never expiring; replaces daily missions), pets bringing
**presents while the child plays** (no daily login gift), no streaks; achievements and a trophy room.
**Merged** (`c82907e`): `autoloads/progress.gd` (autoload `Progress`: `event(kind, amount)`),
`core/progress/` (LevelRules, ProgressData, BoardRules, AchievementRules, PresentRules),
`world/progress_director.gd`, `entities/player/name_tag.gd`, `ui/progress/` (AdventureBoard, TrophyRoom,
ProgressPictures, ProgressPicture), sections in `autoloads/session.gd`, `scenes/sandbox.gd`,
`entities/player/player.gd`, `ui/menus/pause_menu.gd`, the profile and its backup; one-line hooks listed in
the notes; `tools/progress_smoke.gd`. Task 7 counts a finished race with `Progress.event(&"race_finished")`.
Notes, 16 rulings and the emulator checklist: `docs/devlog/parts/m3-task-12.md`.

### Task 13: Admin panel and secret codes
Hashed codes with app salt, once per profile, `sasa192974` → 1,000 Survivor gold; the main menu text.

### Task 14: Action kit — gadgets and blasters (after M2 Task 6)
Glider, launch/bounce pads, grappling hook, zipline, instant builds, impulse and dance orbs; foam,
bubble, paint, snowball and confetti blasters (cartoon); Party Piñata drops and supply balloons; goblin
archers for build-fight practice.
- 14b (blasters, piñatas, supply balloons, goblin archers; items 415–424): built in its worktree, notes
  `docs/devlog/parts/m3-task-14b.md` (waiting for the lead's merge).
**Task 14a (gadgets) done in a worktree, to merge:** `core/rules/gadget_rules.gd` (GadgetRules),
`core/rules/zipline_links.gd` (ZiplineLinks), items 400–407 and blocks 210–211 (page 10 tiles, both styles),
`entities/gadgets/` (GadgetModels, GadgetLooks), `entities/player/gadget_user.gd`, `world/gadget_director.gd`,
`world/zipline_director.gd`, `ui/hud/gadget_icons.gd`, sections in `player.gd`, `block_interactor.gd`,
`monster.gd`, `stone_golem.gd` (+2 lines in the serpent and the giant), `session.gd`, `hud.gd`, `sandbox.gd`,
`block_palette.gd`, `shop_rules.gd`; `WorldMeta.ziplines`. Notes, 16 rulings and the emulator checklist:
`docs/devlog/parts/m3-task-14a.md`.

### Task 15: Tutorial with Pip (after M2; last)
Learn-by-doing steps, skippable without reward, 500 gold + hat + Pip as a pet.
**Built in a worktree (2026-09-25, spec §14.9 "As built"):** `core/tutorial/` (TutorialData, TutorialRules,
TutorialCourse, TutorialProps, TutorialChecks), `world/tutorial_director.gd` (node `Tutorial`, this game only),
`ui/tutorial/` (TutorialCard, TutorialOffer, TutorialPicture), small sections in `scenes/sandbox.gd`,
`entities/monsters/monster.gd` (the practice slime), `world/trade_director.gd` (the held tip), `ui/menus/settings_panel.gd`
(PIP'S LESSONS), `core/save/profile_data.gd` + `profile_backup.gd` (`tutorial`), `world/world_meta.gd`
(`tutorial_props`); `tools/tutorial_smoke.gd`. No block or item ids, no HUD button. Notes: `docs/devlog/parts/m3-task-15.md`.

### Task 16: Photo mode
Camera button, free camera, filters, frames, hide HUD, save and share (Android intent).
**Merged** (`ccb0342`): `core/photo/` (PhotoOrbit, PhotoGestures, PhotoFilters,
PhotoFrames, PhotoFiles, PhotoRules), `ui/photo/` (PhotoMode, PhotoChip, PhotoFrameOverlay, PhotoShare,
the filter shader), small sections in `ui/hud/hud.gd`, `scenes/sandbox.gd`, `entities/player/player.gd`,
`autoloads/audio.gd`, the `photo` action (P). Tests: 6 unit + 3 integration scripts (65 tests). Notes and
the emulator checklist: `docs/devlog/parts/m3-task-16.md`.

### Task 17: Shorts Theater
Theater building near spawn, vertical panel with side buttons, Android WebView plugin (evaluate
existing ones first), curated lists (bundled sample JSON until M4's server), age rules (§5.12),
kill-switch; "coming soon" until the owner provides the API keys (§11).

### Task 20: Signature bets (research, spec §16)
Rideable buddies (a saddle block + wand: build a dragon and fly it, a car and drive it, a boat and
sail it — compact footprint, owner feedback #9 lesson), secret buddy shapes (Buddy recipes page),
the Buddy Album and My Stamps, befriend a monster with the wand (counts toward the pet cap), bosses
turn into mini-buddies (the Pebble Golem), buddies and pets learn tricks (dance three times).
**20a merged** (`1a19183`) (spec §14.16): `core/magic/ride_rules.gd` (RideRules), `world/ride_director.gd`
(RideDirector, node `Rides`), block SADDLE 216 on page 10 (tiles (0,2)/(1,2), both styles; `PortalPage.TILES`,
`tools/make_portal_page.gd` / `.py`), sections in `entities/buddy/buddy.gd`, `entities/player/player.gd`,
`autoloads/session.gd`, `scenes/sandbox.gd`, `ui/hud/hud.gd` (RIDE, spot `ride` in `hud_layout.gd`, picture `ride` in
`hud_icons.gd`), `ui/hud/block_palette.gd` (MAGIC_BLOCKS), `core/economy/shop_rules.gd` (60 gold), one filter in
`world/playdate_director.gd`; `tools/ride_smoke.gd`. Tests: 4 new scripts (64 tests) and additions to 3. Notes,
rulings, measurements and the emulator checklist: `docs/devlog/parts/m3-task-20a.md`.
**20b built** (spec §14.21, agent branch `worktree-agent-af915ba815ebace13`, not merged yet): pure rules in
`core/magic/` (`BuddyRecipes` 8 secret shapes, `BuddyPicture`, `BuddyMagicData` in `ProfileData.buddy_magic`,
`BefriendRules`, `MiniRules`, `TrickRules`) and `core/building/my_stamp_book.gd`; `world/buddy_magic_director.gd` (node
`BuddyMagic`); sections in `buddy.gd`, `animal.gd`, `block_interactor.gd`, `session.gd`, `sandbox.gd`, `secret_book.gd`
(BUDDY RECIPES, BUDDY ALBUM), `block_palette.gd` (tab STAMPS); `ui/building/my_stamp_bar.gd`, `ui/hud/build_picture.gd`,
`entities/animal/magic_pet_models.gd`; item ids **495-499** (My Stamps), no block ids; species `monster_friend` and
`mini_boss`; `tools/buddy_magic_smoke.gd`. Notes, rulings and the emulator checklist: `docs/devlog/parts/m3-task-20b.md`.

### Task 21: Wonder pack (research core set)
Read-aloud of game text (TTS, never chat), babble voices, translation files (Georgian + English),
simple controls (auto-jump, camera follows, context buttons) offered at first launch, pets find more
secrets, trophy shelf, idea cards, wish list, honest help for every boss, the Totem's easier-wave
choice, Secret Book page rewards, building sounds and melody, wake more objects (cacti, snowmen,
pumpkins, a chest mimic), messages in bottles, the Tiny world (mouse holes and villages), the Animal
Book, the Hub Tree, the Memory Book, the parent corner, hide-and-seek with bots (moved to M4 agent H,
which builds hide-and-seek with friends and bots together, 19:25).
**21b (books and memories)** is specced in §14.24: the book's tabs (Animal Book, Memory Book, idea cards, saving up),
Secret Book page rewards, the trophy shelf (217) and bookshelf (218) on page 10, the Hub Tree; notes, rulings and the
emulator checklist in `docs/devlog/parts/m3-task-21b.md`.

- **21a (agent, spec §14.20) — done in a worktree, to merge:** read-aloud (`ReadAloud` + `SpeechQueue`, "Read to
  me", never chat), babble voices (`BabbleRules`, `BabbleVoices`, `tools/make_babble_sfx.py`), English and Georgian
  (`Lang`, `i18n/ka.po`, `i18n/not_words.txt`, `tools/i18n/`), simple controls (`SimpleControls`), SETTINGS' second
  page and the first-launch cards (`WelcomeCards`). No block, item or HUD spot taken. Notes
  `docs/devlog/parts/m3-task-21a.md`.

**21c done (branch `worktree-agent-a2c7cb49dafb1088b`, spec §14.22):** the Tiny world (`MouseVillages` in
`world/generators/`, placed apart from the secrets by `SecretRules.tiny_in_area`; `TinyDirector`, node
`Secrets/Tiny`; `MouseFamily`, `ChestMimic`; the Secret Book's slot, `/secret mice`), waking cacti, pumpkins and
snowmen and the chest mimic (`WakeKinds`), building notes and melody (`BuildNotes`, `BuildMelody`, SETTINGS "Block
music"), block page 14 (`TinyPage`). Notes, rulings and the emulator checklist: `docs/devlog/parts/m3-task-21c.md`.

### Owner 38: bot friends understand what the child says and asks (spec §12.14a)
On-device intents in English and Georgian (`core/bots/`: a scored matcher, a phrase table of ≥ 150
child-like sentences at ≥ 90 %), answers from the game (Tilly, the nearest secret, hearts, the day clock,
what the bot does), behaviour switches (follow, wait, home, build, lead to a secret, guard, run and hide,
dance, race), targeting by name, host routing of the chat bar and the quick-chat wheel (a BOTS picture
page for under-13 players), requests remembered. Agent brief `docs/superpowers/briefs/prompt-own38.md`;
notes `docs/devlog/parts/owner-38-bot-chat.md`.

### Task 24: Quests and a bigger world (owner feedback #45, 2026-09-24 21:49; renumbered from 22 at the 22:20 merge)
Brief `docs/superpowers/briefs/prompt-own45.md`. After Candy (Task 4) and the #41 animals and #42 treasures
packs. **24a** covers quests: new adventure-board goals, quest givers with 3–5 step picture-story chains, a
quest book with no timers, chains shared in co-op. **24b** extends the world: new Meadows biomes, rivers to a
sea with islands, villages and landmarks that get rarer with distance, and a world map of found places. The
generator costs no more per chunk than today. Each half gets its own block page and ids from the Allocations
when it starts. Spec §14 additions first.
- **24a (agent, spec §14.17) — done in a worktree, to merge** (notes, 15 rulings, the emulator checklist:
  `docs/devlog/parts/owner-45a-quests.md`; smoke run `tools/quest_smoke.gd`): `core/progress/` QuestRules (givers, 9 chains, the giver spot), QuestData (in
  ProgressData: the chain followed, stopped chains, done chains, keepsakes, titles, places), BoardRules +30 goals
  (modes, universe, species gates), ProgressData per-universe counts, LevelRules families `item_crafted`,
  `pet_fed`, `buddy_ridden`, `quest_step`, `quest_done`; one-line raisers in `session.gd` (host_craft),
  `pet_director.gd`, `ride_director.gd`, `course_director.gd`, `progress_director.gd`; `world/quest_director.gd`
  (node `Quests` on every peer: givers, bubbles, taps, steps, the arrow, rewards, co-op RPCs),
  `entities/npcs/quest_giver.gd`, `ui/progress/` QuestBook (MORE → QUESTS), QuestCard, pictures; the Secret
  Book's Keepsakes page; bots lead to the quest place. **No item or block ids** (keepsakes and titles are
  profile data). Notes `docs/devlog/parts/owner-45a-quests.md`.
- **24b (spec §14.18, agent 2026-09-25):** terrain version 2 for new worlds only (`WorldMeta.terrain`; old worlds
  keep version 1 forever: only edited chunks are saved); `MeadowsBiomeShape` / `MeadowsBiomeGenerator` (biomes,
  rivers that are warped lines reaching the sea, islands, snowy peaks, mushroom caves and underground lakes, the
  column cache); page 13 (ids 256–271, `MeadowsBlocks`, both styles); `MeadowsPlaces` (windmill, village, tower,
  lighthouse, ship, castle ruins, town; one per 256² region at most, rarer farther away, 60 blocks clear of the
  spawn, clear of every secret); `PlacesDirector` (node `Places`: finds, villagers who wave and trade); the MAP
  page in MORE (`WorldMapPanel`, the /find arrow); Session section "Owner 45b". Notes:
  `docs/devlog/parts/owner-45b-world.md`.

### Task 22: Survivor games and crafting (owner feedback #33, #34; spec §12.18, §12.19)
One agent in a worktree (allocations: Session section `# --- Survivor games and crafting`; item ids
**451–459**, more in **490–499** (lead's fix 21:40: 460–479 are M4 I's gift stamps, 480–489 universe crystals; 451 STICK); blocks **220 CRAFTING_TABLE, 221 FURNACE** on
page 10 (tiles in row 6 of the page, both styles, drawn by `tools/make_portal_page.gd` / `.py` with their
own seeds); the palette's CRAFT tab (Survivor); the game choice after COZY / NORMAL / BRAVE; one HUD label
for the night clock (`HudLayout.SPOTS.game_clock`)).
- **Survivor games:** `SurvivorGames` (CLASSIC / BUILD TO SURVIVE / ~~MONSTER HUNTER~~ — folded into Monster Wave by #44, see below — saved in `WorldMeta.game`,
  old worlds CLASSIC), the Build to Survive clock (`BuildRules`: 3:00 to the first night, days 4×, nights
  2×), `ShelterRules` (roof within 4, 16 rays from head and feet meet walls within 6), fiercer nights
  outside, beds only when sheltered, nights survived and best (`GameScores`), Monster Hunter packs and
  gold per defeat with combos × 2 / × 3 (`HunterRules`), Tilly's game prices; `SurvivorGameDirector`
  (node `SurvivorGame` on every peer) on the host; the HUD's `GameClock` label.
- **Crafting:** `Recipes` (28, one validated table: ids, counts, acyclic, no gold from Tilly loops),
  `CraftRules` (stations within 4 blocks, fuel, one tool of each, all or nothing), `Session.request_craft`
  (host-checked), the palette's CRAFT tab (`CraftBook`: shining cards, have/need).
- Tests first: shelters (roofs, walls, doors open/closed, gaps), night timing, monsters never reach a
  sheltered player, gold per defeat with levels, universes and combo caps, the recipe table, exact
  take/give, table/furnace reach, a guest's craft checked by the host, save/load of the game and scores,
  old worlds CLASSIC. Notes: `docs/devlog/parts/survivor-games-crafting.md`.
**Extended by owner feedback #44 (21:08, lead): MONSTER WAVE**, a third main mode (spec §12.20; `ModeRules.WAVE`,
arena worlds `wave_<u>`): a flat arena per universe (`ArenaShape`/`ArenaGenerator`), waves by themselves (the
WaveDirector), the raid boss at wave 10 (the BossDirector), a knock-out ends the run and pays gold for the time and
the waves (`ArenaRules`), a small kill bonus (Monster Hunter's combo), the best time and wave per universe, the choice
NEXT UNIVERSE / STAY; the menu's MONSTER WAVE button; **Survivor loses its Totem waves and its boss**; Monster Hunter
is folded in (removed from the Survivor games).
**First part done in a worktree (`9cf4045` spec, `ce9398c` code, then the docs/smoke commit), to merge:** 26 rulings, 14 new
test scripts (+ changes to 10), the smoke run `tools/survivor_games_smoke.gd` (30/30 ok); merge notes in the notes
file (page 10's PNGs: rerun both page tools after merging their scripts).

### Task 23: Treasure pack (owner feedback #42; renumbered from 22 at the 22:25 merge; brief `docs/superpowers/briefs/prompt-own42.md`)
Spec §12.16b: shipwrecks and sunken chests, mineshafts with loot carts, dungeon vaults behind a lever
puzzle (Task 7's levers), waterfall caves, hollow trees, the rainbow's pot of gold, wishing wells, pirate
coves, ruins, a friendly haunted house, campsites (placed by `TreasurePlaces` after the M2 kinds, in each
universe's own blocks); chest rarities with fixed tables (`TreasureLoot`); the Secret Book's "Treasure
Hunt" page with picture riddles; pets and bots hint at them. No new block or item ids; pictures in their
own atlas (`data/secrets/treasure_pictures.png`). Notes: `docs/devlog/parts/owner-42-secrets.md`.

### Owner feedback #40: more chat commands (agent, brief `prompt-own40.md`)
Spec §3b "More commands": /weather /heal /peace /freeze /give with counts /kit /speed /gravity
/universe /build /dance /emote /pet /bot /boss /xp /level /music /photo /save /clearbag /find, Georgian
names, chips by mode, Sandbox cheats vs what Survivor allows (tested), host-checked and rate-limited.
Files: `core/rules/chat_commands.gd`, `scenes/chat_command_runner.gd`, the chat panel's chips, a Session
section, `ui/hud/find_arrow.gd`. /fill and /copy come with Task 8. Notes: `docs/devlog/parts/owner-40-commands.md`.

### Task 25: Girl avatars (owner feedback #48, 2026-09-24 22:53)
Brief `docs/superpowers/briefs/prompt-own48.md`. A BOY / GIRL / "Just me" first choice picks a starting look, and every
part stays mixable. Free girl hair, faces and clothes in both styles; two "beautiful girl" presets; bots with mixed
looks. Child-appropriate and never sexualised; no gender look is ever for sale.
Refined in spec §14.6a: `AvatarLook.base` + `clothes` (a new CLOTHES tab, 12 tabs), `AvatarCatalog.PRESETS` /
`STARTS`, girl hair/hats/faces as blocky box parts plus realistic `_real` shapes (balls, cones) on new realistic
BODY and WAIST anchors, lashes and blush in `avatar_skin.gdshader`, the editor's BOY / GIRL / JUST ME row and
LOOKS view, the first-launch look step, bot looks (`BotRules.LOOKS[i].avatar`), `tools/girl_avatar_shots.gd`.

### Task 26: Universe portals you build and the Dragon Realm (owner feedback #39; spec §14.2a)
Brief `docs/superpowers/briefs/prompt-own39.md`. Universe crystals (items 480–484; 485–489 kept) earned by reaching
a universe (and from Tilly); a portal frame with a crystal in its core slot (cores 212–215, 222) swirls in that
universe's colours and travels: Survivor to its Survivor world, Sandbox to its own Sandbox world (`sandbox_<u>`),
the portal back at the arrival point. The **Dragon Realm** (universe 5, page 11 ids 224–239): floating islands over
a starry void (the wind carries a faller back), crystal spires, glowing mushrooms, dragon-scale blocks, dragon nests
whose eggs hatch into a pet dragon (`PetRules`), shadow bats and wisp spirits, the Sky Dragon (Monster Wave's raid
boss: signalled dives, crystal towers that heal it) whose win gives a baby dragon pet and a Dragon Crystal; the
ladder after Candy leads there. Notes: `docs/devlog/parts/owner-39-portals-dragon.md`.
- The Sky Dragon (a worker's part, merged by the lead): `SkyDragonRules`, `SkyDragon` (a `StoneGolem` to the
  BossDirector), `SkyDragonTower`, `SkyDragonModels`, `BossRules.SKY_DRAGON` (`/summon skydragon`), the bar's face,
  `tools/make_sky_dragon_sounds.py`, `tools/sky_dragon_bench.gd`. Notes: `docs/devlog/parts/owner-39-sky-dragon.md`.
- Part (worker): the realm's monsters — `MonsterRules.DRAGON_KINDS` (shadow bat, wisp spirit), their looks, sounds
  (`tools/make_dragon_monster_sounds.py`), minds, `/summon shadowbat|wisp`, the void rules for every flyer, the cost
  bench (`tools/dragon_monster_bench.gd`). Notes: `docs/devlog/parts/owner-39-dragon-monsters.md`.

### Task 26: More animals (owner feedback #41; brief `docs/superpowers/briefs/prompt-own41.md`)
Spec §14.17: 19 new kinds (Meadows 10 + bees and butterflies, desert 3, Frostpeak 4, candy 2), each universe's
descriptor names its animals (`animals`), a home table (`AnimalHomes`: biome and weight), food (`AnimalFood`), minds,
box models, real CC0 voices with chorus levels; horse and camel ride (RideRules GALLOP / TREK, a SADDLE on the pet),
the donkey's 9-slot chest, the turtle's egg, special moves (goat, duck, deer, penguin, squirrel, owl, hedgehog).
No new block or item ids. Notes: `docs/devlog/parts/owner-41-animals.md`.

### Task 27: The Storybook costume pack (owner feedback #36; Task 26 twice already at its merge)
Brief `docs/superpowers/briefs/prompt-own36.md`; spec §14.6b. 21 costumes (12 public-domain storybook heroes drawn
from the books, 9 of our own genre costumes) as whole looks of catalogue parts in both styles; the OUTFIT tab becomes
COSTUME (costumes first). `CostumeRules` (`core/avatar/costume_rules.gd`): the looks, their sources, one fixed way
each (bosses of the free universes, Tilly's and Zara's stories, levels, titles, a badge, Secret Book finds, a flying
ride, a code), `sync` from the profile (in a world: Session's owner-36 section; when the editor opens). Items
`costume.<id>` and `IN_COSTUME` parts in `AvatarCatalog`; no item or block ids; no new HUD button. A banned-names test
over every shipped string. Notes: `docs/devlog/parts/owner-36-costumes.md`.

### Task 28: The shop and trading (owner feedback #37; spec §14.23; Task 27 went to #36 at its merge)
Brief `docs/superpowers/briefs/prompt-own37.md` (agent in a worktree after the 2026-09-25 merges). MORE → SHOP (the
card with Tilly's distance and arrow, the players to trade with), the first-time picture tip, a stand beside each
universe helper (their `trader_stock`), market day every 7th day (Nico's cart, the village blocks at fixed prices,
`WorldMeta.market`), trading between players (ask, the trade window, READY, the host's atomic swap, the under-13
friends rule, the chat line). Allocations: Session section `# --- Trading`, UI in `ui/trade/`, the MORE entry, no
block or item ids, no always-visible HUD button. Notes: `docs/devlog/parts/owner-37-trade.md`.


### Task 29: The palette's MOBS page (owner feedback #51; spec §3b) — built by the lead 2026-09-25
`BlockPalette.MOBS_TAB` (8): ANIMALS, MONSTERS, BOSSES tiles (`AnimalPortrait` draws animals and, new, monsters from
their box models; bosses use `ProgressPictures`); `mob_requested(word)` → the sandbox's `ChatCommandRunner.run("/summon
<word>")`. Sandbox only. Tests: `tests/integration/test_palette_mobs.gd`.

### Task 18: Acceptance and release 0.4.0 (lead)
Tour checks for §14.15; performance in each universe and style; `~/Downloads/EasyCraft-0.4.0.apk`.

### Task 19: Whole-branch review and fix pass (lead)
Done by an agent in a worktree (2026-09-25): six fixes test-first (a village roof counted as a lantern, a guest's
orphaned buddy, a guest's error flood after the host left, a used-up chest mimic, /summon's "a owl", "1 stars";
three Georgian fixes reverted after the owner's "English only") and a not-fixed list for the lead:
`docs/devlog/parts/m3-task-19-review.md`.
