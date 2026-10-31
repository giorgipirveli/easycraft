# M2 Task 15: Bot friends (owner feedback #18)

Owner request (2026-09-24 09:33): "we should be able to play with bots as a friends". Spec §12.14, plan
Task 15. Built in an isolated worktree on a branch cut from `m2-survive-the-night` at `2430164`, in
parallel with Tasks 4, 6, 14 and 16. No editor or emulator was used (house rule for agents); engine glue
was checked with a new headless smoke run on real terrain (`tools/bots_smoke.gd`).

## What was built

- **Up to 3 bot friends per world** (`BotRules.MAX_BOTS`), in any world (Sandbox or Survivor, solo or
  LAN host). The pause menu gets a **FRIENDS n/3** row above SAVE & QUIT that opens the friends page
  (`ui/menus/friends_panel.gd`): one row per friend (colour swatch, "Pip (builder bot)", **BYE**) and three
  big buttons **+ BUILDER / + EXPLORER / + FIGHTER** (disabled at 3). A LAN guest's menu has no FRIENDS row.
- **Who a friend is:** a made-up name (`BotRules.NAMES`, 16 names, all pass the username filter, none a
  pet's name), its own look (`BotRules.LOOKS`, 6 outfits: torso, legs and skin colours; in REALISTIC one of
  the two Kenney bodies with a shirt dyed in its colour, `tools/make_bot_skins.py`) and a personality:
  - **builder** — carries a hammer, puts small builds next to the player's builds;
  - **explorer** — roams further, points at shiny ores it can see and at wild dogs and cats to tame, and
    answers Task 16's `notice(point, text)`;
  - **fighter** — carries the sword, stays close and guards a wider circle (14 blocks) against monsters.
- **Always shown as a bot** (lead's ruling): a robot-face badge over the name tag, "builder bot" under
  the name, a little antenna on the blocky body, and "(bot)" after its name in the chat (a light-blue
  chat line, kind `&"bot"`).
- **Behaviour** (host only, an enum state machine decided 10 times a second: IDLE, FOLLOW, WANDER, FIGHT,
  BUILD, POINT; `BotRules.choose_behaviour`): a monster comes first, then an explorer's find or a builder's
  planned build, then walking back to the player, then wandering near them.
  - **Follow at a comfortable distance** (fighter 5, builder 7, explorer 15 blocks; walks back to 2.5,
    runs from 8) and **catch up**: more than 24 blocks away sideways (or 12 above/below a player standing
    on the ground), fallen out of the world, or not getting closer for 3 s, it pops up next to the player
    (a free spot beside them, caves too, or the ground below a flying player), once that ground is loaded.
  - **Fight monsters near the player** (group `monsters`): builder 6, explorer 8, fighter 14 blocks from
    the player, and anyone fights a monster within 3 blocks of itself. The swing is resolved by the host's
    `CombatDirector.bot_melee`: the weapon table's sword (reach, arc, max hits, damage 4, knockback),
    nothing through walls, **monsters only** (never players, animals, buddies or targets), once every
    0.8 s. It cheers ("Got it!") when a monster it hit is gone.
  - **Builders** build 15 s after joining and then every 40 s: next to the player's most recent block
    within 12 blocks of the player (the director remembers the last 32 player blocks from
    `WorldService.block_changed`), 2–4 blocks away, on natural ground, only in empty cells, touching only
    air or natural blocks (a hillside, a tree), never where someone stands. Sandbox designs: a lamp post,
    a planter, a rainbow pillar, a window pillar, a little flower; Survivor: hedges of leaves only.
  - **Explorers** look around every 2 s (a 13 × 9 × 13 box: one bulk copy, `WorldService.copy_box`, and a
    native search of its bytes, `BotRules.find_in_buffer`) for gold, diamond or crystal open to air or
    water, and for wild dogs and cats within 10 blocks; they walk over, stretch both arms towards it, sparkle it and say "Look! Something shiny over here!" (or the hook's text). They give up
    after 15 s if they can't get there, and forget it when the player goes more than 24 blocks away.
  - **Chat:** hello when added, bye when sent home, and short lines about fights, wins, builds, finds,
    knock-outs and now and then (45–90 s) an idle line — **at most one line per bot per 20 s**.
- **Hearts, knock-out and back:** each friend has its own `Health` (20 HP, regen like players). Monsters
  hurt it through `hurt(amount, from)` (a push away from the hit, a red puff). At 0 it bursts into
  confetti (4 colours, the shared `Fx` material), hides, leaves the `bots` group (monsters stop chasing
  it) and comes back after **10 s** next to the player with full hearts and 3 s of protection ("I'm back!").
- **Never takes the player's things:** no inventory, no gold, not in the `players` group (coins, bags,
  wave and boss rewards go to players), never breaks a block, never replaces one, and in Survivor never
  uses the player's counted blocks (leaves only, which give nothing when broken).
- **Saved with the world:** `WorldMeta.bots` = `[{name, personality, look}]`, parsed defensively (an unknown
  personality is dropped, a bad or repeated name or look gets a free one, at most 3). They come back next
  to the player when the world loads (and say hello).
- **Replicated like animals:** the sandbox's `Bots` container and `BotSpawner` exist on every peer;
  position and rotation are synced always, `held_item`, `knocked_out` and `pointing` on change. Guests
  animate the synced copy (speed from the position change) and play swings, confetti and sparkles from
  host RPCs on the bot.
- **Cost rules** (the animals' lessons, DEVELOPMENT.md §8): decisions 10 Hz and staggered between bots;
  nothing moves before the first decision; a friend with no player within 32 blocks (or waiting for the
  player's ground) rests; one shared players list and one shared monsters list per physics frame; a
  friend standing on the ground skips `move_and_slide` between decisions; the blocky body shares one box
  mesh per size and one material per colour with every other bot (the player's avatar is untouched); the
  realistic body shares one material per look; builders try at most 16 spots per plan (spread all
  around the player's block); the explorer's look is one bulk copy and a native byte search (0.02 ms,
  not 2–4.5 ms cell by cell); no per-event materials (all bursts use `Fx`).

## Files

New: `core/rules/bot_rules.gd`, `entities/bots/bot_friend.gd`, `entities/bots/bot_blocky_avatar.gd`,
`entities/bots/bot_realistic_avatar.gd`, `world/bot_director.gd`, `ui/menus/friends_panel.gd`,
`tools/make_bot_skins.py`, `assets/characters/bot_skins/bot_0..5.png`, `tools/bots_smoke.gd`,
`tools/bots_smoke_steps.gd`, `tests/unit/test_bot_rules.gd`, `tests/unit/test_world_meta_bots.gd`,
`tests/integration/test_bot_friends.gd`, `tests/integration/test_world_copy_box.gd`.

Shared files, each edit small and self-contained:
- `autoloads/session.gd` — a new section at the end, `# --- M2 Task 15: bot friends`: `bot_set_blocks`,
  `bot_say`.
- `world/combat_director.gd` — a new section at the end: `bot_melee`, `monster_hittables`,
  `MONSTER_CENTER`, `MONSTER_RADIUS`.
- `world/world_meta.gd` — field `bots`, `_parse_bots` (called at the end of `from_json`), `"bots"` in
  `to_json`.
- `ui/menus/pause_menu.gd` — one line in `_show_buttons` (`_add_friends_row(v, quit)`) and a section at
  the end (`friends`, `_add_friends_row`, `_show_friends`).
- `scenes/sandbox.gd` — `_add_bot_spawner()` in `_ready`, `_start_bots()` at the end of
  `_start_host_or_solo`, `meta.bots` in `save_world`, and a section at the end ("Bot friends (M2 Task 15)").
- `ui/hud/chat_panel.gd` — one colour in `COLORS` (`&"bot"`).
- `world/world_service.gd` — a section at the end: `copy_box(origin, size) -> VoxelBuffer`.
- `assets/CREDITS.md`, `docs/DEVELOPMENT.md` (§4 smoke run and skins tool, §5 bot friends and layer 64,
  §8 a Voxel Tools gotcha: search a copied box's bytes, not cell by cell).

Not touched (the lead updates them at merge): `docs/devlog/2026-09-24-m2.md` status row 15 and
`docs/playtests/owner-feedback.md` #18 (to **fixed** with the test names below), the spec and the plan.

## Tests (RED → GREEN)

Every test was written first and seen failing for the right reason:
- `tests/unit/test_bot_rules.gd` (32): RED "Identifier BotRules not declared", then GREEN. Later RED
  rounds: the guilt-line test failed on "Did you miss me?" (replaced by "Ready to play again!"); the
  "never where someone stands" and "checked again before it goes up" tests failed on the missing
  `plan_fits` / `bodies` parameter; "a build may lean on a hillside" failed (0 plans on tall natural
  bumps) before natural neighbours were allowed; "the tries go all around the block" failed for 6 of 72
  starts with consecutive tries (checked by setting the stride back to 1) and passes with stride 29;
  "ores are found in a copied box like a cell-by-cell search" (16- and 8-bit boxes), "a box of one block"
  and "the nearest open find wins" failed on the missing `find_in_buffer` / `nearest_open`.
- `tests/integration/test_world_copy_box.gd` (1): `copy_box` on a real VoxelTerrain holds the world's
  blocks and `find_in_buffer` finds a placed gold block (written after `copy_box`, as its engine check).
- `tests/unit/test_world_meta_bots.gd` (3): RED "Invalid access to property or key 'bots'", then GREEN.
- `tests/integration/test_bot_friends.gd` (31, FlatWorld and stand-in monsters, like `test_animal.gd`):
  RED "Identifier BotFriend / BotDirector / FriendsPanel not declared", then GREEN after fixes that the
  tests found: the director needs this game's own player by default (`leader`), a bot must not move
  before its first decision (`_active` starts false), and an explorer must forget what it saw when the
  player jumps far away (found by the smoke run; regression test
  `test_an_explorer_forgets_what_it_saw_when_the_player_moves_far_away`). The FRIENDS page test
  failed ("its row stays while the tap is handled") while BYE redrew the rows at once, freeing the
  tapped button's row during its own tap; the redraw is deferred now.
  Covered: up to three with own names and looks; removing makes room (and says bye); hello in the chat
  marked as a bot; one line per 20 s; badge, antenna and shared materials; the device's style (realistic
  body with its dyed skin, switches with the setting); every look has a skin; sync on change; follows to a
  comfortable distance on real physics; pops up next to the player; waits for the ground; decides 10
  times a second; rests with nobody near; fighters go for monsters builders leave alone; fighters hit
  monsters with the weapon table's damage at a friendly pace and never animals or the player; never
  through walls; a friend's swing skips players, animals and buddies; players' weapons pass through
  friends; cheers when its monster is gone; explorers point at shiny ores; the secrets hook answers only
  for explorers near the player; builders build next to the player's block (never on it); Survivor
  friends never touch the player's inventory or gold and use only leaves; the host edit path fills only
  empty cells in reach and never inside a player; monsters hurt friends through the `bots` group;
  knocked out, hidden, out of `bots`, back after 10 s next to the player with full hearts; friends count
  for boss health, knocked out too; saved and restored; the FRIENDS page adds and removes (and disables
  at 3); the pause menu shows the FRIENDS row to the host only.
- Full suite on the final tree: **704 tests passing, exit 0** (637 before this task; 67 new).

## Headless smoke run on real terrain (`tools/bots_smoke.gd`)

21 runs on new random worlds while the PC was shared (load average 29–70 from other agents' suites):
- Runs 1, 3, 5, 8–21 passed every check; **runs 16–21, on the final code, all passed**. Run 2 missed the
  stand-in monster within 10 s (cause not found; not seen in the 19 runs since). Runs 4, 6 and 7 found
  real problems: the explorer bouncing between the player and its old find after the player's long
  jump (fixed, regression test above), and two worlds where the builder found no spot next to the
  player's block (fixed: builds may lean on natural blocks, and the 16 tries spread all around the block;
  both with unit tests).
- The smoke run times the friends' own physics steps (it calls them itself; desktop, wall clock). Before
  the explorer fix, at load 45–70: 0.29–1.0 ms per frame for all three; explorer decisions 1.7 ms on
  average against 0.6 ms for the others. Timed on its own, the explorer's look cost **4.5 ms** (a
  Callable call per cell of its box) — 15–25 ms on a phone every 2 s. With the bulk copy and byte search
  it costs **0.019 ms** (the same box cell by cell: 2.0 ms), and a builder's plan 0.07 ms.
- After the fix (run 21, load 29): **0.26 ms per frame** for all three friends on average, worst frame
  11 ms; decisions 0.29–0.46 ms by personality, move steps 0.05 ms. Steps over 4 ms: 1.5 % of decisions,
  0.3 % of move steps — about in proportion to their length on this loaded PC, and a fixed control
  workload timed the same way spiked too, so these read as the scheduler's. Must be measured again on
  the emulator (see below).

## Rulings (decisions made on the owner's behalf)

1. **Bots are host-simulated companions, not network players** (M2 ruling 13): they work solo and on LAN
   without extra peers. *Cost if wrong:* nobody can drive a bot like a player.
2. **Bots follow the host's player; only the host (and solo) has the FRIENDS row.** A guest's game
   doesn't simulate them. *Cost if wrong:* a LAN guest can't add friends of their own (a request RPC to
   the host would add it; about an hour).
3. **Survivor builders plant leaves only** (the task's "never from the player's inventory" ruling):
   leaves give nothing when broken (§12.2), so a friend's build is never free blocks or gold. Sandbox
   builds are colourful. *Cost if wrong:* Survivor builds look plainer.
4. **A build never replaces, breaks or sits on the player's blocks and touches only air or natural
   blocks**, and no one gets an undo step for it (players break it like any block). *Cost if wrong:* a
   player may want to undo a friend's gift with the undo button.
5. **Bots only hit monsters, and players' weapons pass through bots** (bots are not in
   `CombatDirector.hittables`), so a sword swing never pulls onto a friend. *Cost if wrong:* no pushing
   friends around for fun.
6. **Bots fight with the wooden sword's stats at one swing per 0.8 s**: helpful, never the whole show.
   *Cost if wrong:* waves may feel too easy or too hard with three fighters; tune `ATTACK_EVERY`.
7. **One chat line per bot per 20 s, including the fight, win and knock-out lines** (the hello and the
   bye are always said). A throttled line is simply skipped. *Cost if wrong:* a child may miss a "Got
   it!" right after "Watch out!".
8. **Friends come back next to the player on load** (their positions are not saved). *Cost if wrong:*
   none known; they would teleport to the player within 0.1 s anyway.
9. **A knocked-out friend leaves the `bots` group** (monsters stop chasing an invisible target) but stays
   in `bot_friends` (team size). *Cost if wrong:* a monster that wants to "finish" a knocked-out bot
   can't find it (none should).
10. **Physics layer 64** for bot friends (mask 1: the world only; nothing collides with them, tap rays
    ignore them). *Cost if wrong:* if Task 4 picks 64 for monsters, the lead renumbers one (both are
    only used for their own bodies).
11. **REALISTIC skins are pre-dyed PNGs** (6 × 65 KB) rather than a runtime recolour (a 35k-pixel loop
    would cost 50–100 ms on a phone the first time a friend appears) or a new shader (a compile hitch).
    *Cost if wrong:* 390 KB of APK.
12. **Explorers also show wild dogs and cats to tame** (something to find in M2 before Task 16's secrets
    exist). *Cost if wrong:* none known.

Child-psychology rulings from the lead (docs/design/, 2026-09-24):
13. **Bots are always clearly labelled as bots** and never pretend to be real children: robot badge on
    the name tag, "builder bot" under the name, "(bot)" in chat names, an antenna on the blocky body.
14. **No guilt or pressure lines**, only cheerful, helpful lines that admire the child's builds; unit test
    `test_bots_never_say_guilt_or_pressure_lines` fails on "miss you", "miss me", "don't go", "last
    chance", "hurry", "only today", "you'll lose", "come back", "don't leave", "lonely", "sad"; builders'
    idle lines admire the player's builds (`test_builders_admire_the_players_builds`).
15. **Bots never ask for personal information and never react to it**: every line is a fixed phrase
    (`test_bots_never_ask_for_personal_information` bans name/age/school/address/phone/password/email/
    photo questions), and bots never read the chat (nothing in `entities/bots/` listens to
    `Session.chat_received`).

## Contract for the lead (Tasks 4, 9, 10, 16 and 2 at merge)

- **Monsters (Task 4) find and hurt friends:** group **`bots`** holds every friend that is up (not knocked
  out). Each is a `BotFriend` (`CharacterBody3D`): `global_position` (feet), `chest()` (aim point, 1 m up),
  `BotFriend.RADIUS` 0.3, `is_on_floor()`, and **`hurt(amount: int, from: Vector3)`** (host only; ignored
  while knocked out or in 3 s of protection; a knock-out at 0 is handled by the bot). Pick targets from
  `players` + `bots`; use `Session.hurt_player` for players and `hurt` for bots.
- **Friends hit monsters** through `CombatDirector.bot_melee(origin, dir, weapon_id)`, which calls the
  monster contract **`take_hit(damage: int, from: Vector3, knockback: Vector3)`** on nodes in group
  `monsters`. A monster may give **`hit_center() -> Vector3`** and **`hit_radius() -> float`** (big ones:
  the Golem); otherwise centre = feet + 0.6 and radius 0.5 (`CombatDirector.MONSTER_CENTER/RADIUS`). When
  Task 4 adds monsters to `CombatDirector.hittables`, `monster_hittables` can become a filter of it
  (kind `MONSTER`), as long as bots stay out of `hittables`. Friends leave a monster alone once it leaves
  the `monsters` group or is queued for deletion.
- **Rewards (Tasks 4, 9, 10):** friends are not in `players`, so coins, pickup bags and wave/boss gold go
  to players only; a friend's kill drops coins for a player to pick up. Don't pay friends.
- **Boss health (Task 10):** **`BotFriend.team_size(get_tree())`** = players + all friends (knocked out
  too) for HP 300 × (1 + 0.5 × (team − 1)). The slam can check `is_on_floor()` on friends like on players.
- **Totem waves (Task 9):** nothing to do: friends fight monsters near the player, wave monsters included.
- **Secrets (Task 16):** **`BotDirector.notice(point: Vector3, text := "") -> bool`** (the sandbox's
  `_bot_director`, host) asks the nearest explorer; or call `BotFriend.notice` on one. It walks over,
  points with both arms, sparkles the spot and says `text` (or "Look! Something shiny over here!"),
  only for points within 24 blocks of the player; false when no explorer will. A pointing gesture plus a
  sparkle works for children who can't read yet.
- **Knock-out (Task 2):** nothing shared; friends have their own knock-out.

## Merge notes (what will conflict)

- End-of-file sections in `session.gd`, `combat_director.gd`, `pause_menu.gd` and `sandbox.gd`: keep both.
- `pause_menu.gd` `_show_buttons`: Task 4 adds "Monsters: ON / OFF" for Sandbox worlds; keep both. Menu
  height with RESUME, SETTINGS, MONSTERS, FRIENDS, SAVE & QUIT is about 650 of 720 px (tight: check on the
  emulator; if it overflows, shrink the buttons to 76 px or put MONSTERS and FRIENDS side by side).
- `world_meta.gd`: the new field, `from_json` end and `to_json` dict are where other tasks add fields too.
- `combat_director.gd`: Task 4 adds monsters to `hittables`/`apply_hit`; my section is separate (see above).
- `chat_panel.gd` `COLORS`: one entry.
- Physics layer 64 (ruling 10).

## Messages from the lead

- A message about **picture riddles and a secret chime / `SecretRules.nearest_buried`** reached this task
  by mistake (it is Task 16's); I told the lead, who forwarded it. Not built here; the explorer's
  `notice()` hook above is what Task 16 can call.
- The **child-psychology rulings** (13–15 above) are built and tested.

## What to check on the emulator (lead)

1. Sandbox and Survivor: pause → FRIENDS 0/3 → add one of each → RESUME: three friends with badges and
   names next to the player, blocky and REALISTIC (switch the style: bodies change, shirts differ).
2. Walk and run: they follow; fly far or `/tp`: they pop up next to you; go into a cave: they come too.
3. Place a few blocks: within ~15 s the builder puts a small build next to them (Survivor: leaves).
4. Near gold/diamond/crystal in a cave, or a wild dog: the explorer points and says so in the chat.
5. After Task 4's merge, at night: friends fight monsters near you; a friend can be knocked out
   (confetti) and is back after 10 s; at a Totem wave and the Golem they help, and the Golem's HP counts them.
6. Chat: at most one line per friend per 20 s, light blue, "Name (bot): …".
7. Save & Quit, continue: the same friends come back and say hello.
8. **Performance:** the autopilot (both styles) with three friends added: ≥ 30 FPS and no frame over
   100 ms; `BOTS_SMOKE` numbers above are desktop-only and were taken under heavy load.
9. LAN (host + guest): the guest sees the friends move, swing and sparkle, and has no FRIENDS row.
