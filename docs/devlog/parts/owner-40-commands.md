# Owner feedback #40: more chat commands

The owner (2026-09-24 20:40): "also save in plan, add more commands in the game". Brief
`docs/superpowers/briefs/prompt-own40.md`; spec §3b "More commands"; plan line in the M3 plan
("Owner feedback #40").

## What was built

21 new commands, each with a usage line, a one-line "about", tappable choice buttons and a Georgian name
(plus Georgian words for its choices). `/give` takes a count.

| Command | Runs on | Survivor? | What it does |
|---|---|---|---|
| `/weather clear\|rain\|snow\|sandstorm` | host | no (cheat) | Forces the universe's storm on or off (`SandstormDirector.force`). Only what the universe has: the desert's sandstorms, Frostpeak's snow. No rain anywhere yet (a kind "later update" answer). |
| `/heal` | host | no | Fills the hearts (`Health.heal`, then the same broadcast as the hearts' own regrowth). A knock-out is not skipped. |
| `/peace [on\|off]` | host | no | The pause menu's MONSTERS switch (Sandbox): monsters puff away, waves stop, the menu shows the same. Alone it toggles. |
| `/freeze [on\|off]` | host | no | Stops the day clock for everyone (`SkyCycle.running`); guests hear it from the host (Session, joiners too). Alone it toggles. |
| `/give name 64` | local | no | A count 1–999 (`Inventory.MAX_COUNT`), before or after the name. |
| `/kit` | local | no | A builder's hotbar: planks, brick, glass, stone, log, door, lantern, bed, wand. |
| `/speed 1\|2\|3` (slow, normal, fast) | local | no | 1: the Lab's slow motion; 2: normal; 3: the Speed potion's 1.5× for 60 s (asked from the host). |
| `/gravity moon\|normal\|zero` | local | no | The Physics Lab's Moon, Normal and Zero-G modes (`Player.set_lab_mode`). |
| `/universe 1-4` or a name | local | Survivor only | The stone circle's travel (`sandbox.travel_to`): alone, unlocked universes only; its own answers ("Travel works when you play alone."). |
| `/build house\|tower\|bridge\|tree\|rainbow` | local | no | The stamp 2 blocks ahead of the feet, facing the way you look, as one batch (one UNDO). |
| `/dance [hop\|robot\|star\|victory]`, `/emote name` | local | yes | Plays an emote you own (bought and earned ones need owning: "You don't have the Star Spin yet! …"). `/dance` alone picks one of your dances. |
| `/pet` | host | yes | Your pets stand up and come; one farther than 8 blocks pops next to you. |
| `/bot add [builder\|explorer\|fighter]`, `/bot remove [name]` | local (host/solo) | yes | The pause menu's FRIENDS row by chat; a unique start of a name works; with one friend `/bot remove` needs no name. A LAN guest: "Only the host can bring bot friends." |
| `/boss` | host | no | This universe's boss (Golem, Sand Serpent, Frost Giant) through the old `summon_boss` hook. |
| `/xp`, `/level` | local | yes | "You have 120 XP. 30 more for level 3!", "Level 2 Adventurer. 30 XP to level 3." |
| `/music next\|classical\|game\|on\|off` | local | yes | off/on = the settings' music volume (saved like the slider). classical/next wait for the audio pass (see below). |
| `/photo` | local | yes | Opens photo mode. |
| `/save` | local | yes | Saves now (host and solo); a guest: "The host saves this world." |
| `/clearbag` | host | Survivor only | Asks first; a second `/clearbag` within 15 s empties the bag. |
| `/find tilly\|home\|portal\|treasure` | local | yes | An arrow with the distance (`FindArrow`, at the treasure compass's spot) and words: "Tilly is 42 blocks away, on your left." Home is the bed, or the world's start. Portal: the Golem's portal, a swirling frame or the hub circle. Survivor's treasure needs a Treasure Map in the hotbar or bag. The arrow goes when you get there ("You found Tilly!" toast) or after 90 s. |

**Survivor allows** (kept by `test_survivor_allows_exactly_its_list`): /help /walk /jumps /style /seed /clear
/dance /emote /pet /bot /xp /level /music /photo /save /clearbag /find /universe. Everything else is a
Sandbox cheat ("That works in Sandbox only."). Sandbox allows all but /clearbag ("Your Sandbox bag never runs
out") and /universe ("Sandbox has one world").

**/help and the "/" buttons** show only what this child may use in this mode (commands off: /help). A command
typed that can't be used here shows why in the hint line instead of buttons. `/help weather` names the
Georgian command too.

**Host-checked and rate-limited.** World-changing ones go through `Session.request_command` → `host_check`
(parsed again, mode and switch checked, 5 per 10 s per player as before). Heavy local ones (`/build`,
`/save`, `/bot`) have the same 5-per-10-s limit on the device (`ChatCommands.LIMITED`). A LAN guest plays by the
host's mode (already) and now also the host's command switch (`Session._rpc_command_state`, sent at join).

**/fill and /copy are not built**: M3 Task 8's building tools are not in the game yet (brief: "skip if not").
`test_fill_and_copy_wait_for_the_building_tools` fails once someone adds them, as a reminder to test them.

## Georgian (native check needed)

Command names (`ChatCommands.COMMANDS[...].ge`): დახმარება help, ტელეპორტი tp, დასაწყისი spawn, სახლში home,
დრო time, მომეცი give, გამოძახება summon, საიდუმლო secret, ფრენა fly, მოჩვენება ghost, სიარული walk, ზომა size,
ნახტომი jumps, სტილი style, თესლი seed, გასუფთავება clear, ამინდი weather, განკურნება heal, მშვიდობა peace,
გაყინვა freeze, ნაკრები kit, სიჩქარე speed, გრავიტაცია gravity, სამყარო universe, აშენება build, ცეკვა dance,
ემოცია emote, შინაური pet, ბოტი bot, ბოსი boss, გამოცდილება xp, დონე level, მუსიკა music, ფოტო photo,
შენახვა save, დაცლა clearbag, იპოვე find.
Choice words (`ChatCommands.GEORGIAN_WORDS`, per command, so სახლი is a house to /build and home to /find):
time დღე ღამე შუადღე შუაღამე განთიადი დაისი; size გიგანტი პატარა ჩვეულებრივი; style კუბური რეალისტური;
weather მზე წვიმა თოვლი ქარიშხალი; peace/freeze/music ჩართე გამორთე; speed ნელა ჩვეულებრივი სწრაფად;
gravity მთვარე ჩვეულებრივი ნული; universe მდელო უდაბნო ყინვა ტკბილეული; build სახლი კოშკი ხიდი ხე ცისარტყელა;
dance კურდღელი რობოტი ვარსკვლავი გამარჯვება; bot დამატება წაშლა მშენებელი მკვლევარი მებრძოლი; music შემდეგი
კლასიკა თამაში; find ტილი სახლი პორტალი განძი.
Typing "/ამ" offers "/ამინდი"; after a Georgian name the choice buttons are Georgian. The "/" list stays one
English button per command. Replies stay English (the game's text; M3 Task 21a brings translation files).

## Files

- `core/rules/chat_commands.gd`: the table (with `ge`), the new parsing, `command_name`, Georgian words,
  `usable`/`context` for the buttons and /help, and the pure rules the runner asks (`weather_refusal`,
  `switch_value`, `build_anchor`, `owned_dances`, `find_words`, `find_refusal`, `xp_words`, `level_words`,
  `pets_words`, `confirmed` …).
- `scenes/chat_command_runner.gd`: a section "Owner 40: more commands" with the handlers. Injectable for tests:
  `store_setting`, `clock`, `owned`, `place_edits`.
- `ui/hud/chat_panel.gd`: the chips use `ChatCommands.command_name` and a context (`_command_context`), and a
  refused command shows why.
- `autoloads/session.gd`: a section "Owner 40: commands" at the end: `clock_frozen`, `set_clock_frozen`,
  `send_command_state`, `command_state_reset`, `_rpc_command_state` (also carries `commands_enabled`).
- New: `ui/hud/find_arrow.gd` (`FindArrow`).
- Tests: `tests/unit/test_chat_commands_more.gd` (35), `tests/integration/test_chat_commands_run.gd` (20),
  `tests/integration/test_chat_panel_commands.gd` (5), `tests/integration/test_find_arrow.gd` (4). Changed:
  `test_chat_commands.gd` (its "unknown command" example was `/dance`; now `/moonwalk`), `test_chat_panel.gd`
  and `test_chat_panel_online.gd` (the "/" list is the commands usable in the mode: Sandbox = all but 2).

## Tests RED → GREEN

- `test_chat_commands_more.gd` first failed to parse on the missing rules ("Static function
  weather_refusal() not found…"), then only on the missing runner handlers (21 "handler for /x"), then green.
- `test_chat_commands_run.gd` was written before the runner's handlers and injectables (it could not parse
  against the old runner); one failure after the first implementation was the test's own setup (the player
  had no world for `set_physics_mode`'s unstuck: now a flat fake world like `test_player_lab.gd`).
- `test_chat_panel_commands.gd`: 6 failures against the old panel (37 buttons in Survivor instead of 18, the
  refused /tp showed its usage, all four weathers in Green Meadows, English buttons after a Georgian name),
  then green. `FindArrow` and its test were written together (not strictly test-first).
- Mutation check: letting a late second `/clearbag` count (no 15 s window) fails
  `test_clearbag_asks_twice_then_empties_the_bag` ("too late: it asks again").

## Rulings (cost if wrong)

1. **No new sandbox hooks** (the lead kept this task out of `sandbox.gd`): the runner reads the sandbox's
   parts by name (listed in its header). Cost: a renamed node or var in `sandbox.gd` breaks a command quietly
   (SOON, or nothing found). The lead may move them into `has_method` hooks later.
2. **/speed 3 is the Speed potion** (1.5× for 60 s, Sandbox pays nothing), because the player has no other
   speed factor and `player.gd` was out of scope. Cost: "fast" ends after a minute; a speed factor in the
   Lab later would make it stay.
3. **/peace and /freeze alone toggle**; `on`/`off` are explicit. Tapping the `/peace` button runs it at once.
4. **/freeze is not saved** with the world (WorldMeta was out of scope): a reload runs the clock again. Cost: a
   child who froze a sunny day finds the clock running next time.
5. **/weather rain** answers "No rain here yet"; no universe has rain. The buttons show only the universe's own.
6. **/give counts only show in the words** in Sandbox (where /give works, every block is endless). Cost: none
   today; if a grown-up switch ever allows /give in Survivor, the count must go into the bag on the host.
7. **/build is not mirrored** in Mirror mode (one thing per command) and goes through the host's batch checks
   like a stamp (32-block batch reach, bedrock, bodies); UNDO takes the whole build back.
8. **/find treasure in Survivor needs a Treasure Map** you own (fair fun §6, §12.16: treasure is found by
   playing). It points to buried treasure (`SecretDirector.map_target`), like the map's compass.
9. **/universe is Survivor only** (Sandbox has one world, `UniverseRules.wants_hub`). When own #39 opens Sandbox
   universes, move `/universe` out of the refusal in `ChatCommands.refusal` and its test list.
10. **/bot is the host's** (solo or LAN host), like the FRIENDS row; bot friends follow the host.
11. **Emotes you don't own don't play** from chat either (the shop's and the Victory dance's rules hold).

## What the lead should hook up when the running agents merge

- **Audio pass (music)**: `/music classical|game` call `Music.use_style(style: StringName)` and `/music next`
  calls `Music.next_piece()` when those methods exist (`has_method`); until then "Classical music arrives soon!"
  / "More songs arrive soon!". If the audio pass names them differently (or keeps the choice in a MUSIC
  setting), change `_cmd_music` to store that setting (e.g. `store_setting.call("music", "classical")`).
- **Survivor games / Monster Wave (#44)**: if a MONSTER_WAVE mode joins `ModeRules`, check `refusal` (it goes by
  `ModeRules.CHEATS`, `UNLIMITED_BLOCKS` and `UniverseRules.wants_hub`) and the help list per mode. `/peace`
  stops waves through the MONSTERS switch as today; `/boss` uses `UniverseRegistry.boss_kind`. If Survivor
  loses its Totem, nothing here changes.
- **M3 Task 8 (building tools)**: add `/fill` and `/copy` then (the brief), and update
  `test_fill_and_copy_wait_for_the_building_tools`.

## Check on the emulator

- The Georgian command names and buttons render (the default font falls back to the system's Noto Sans
  Georgian on Android) and fit the chips.
- `/find tilly` in Survivor: the arrow sits left of WALK, points the right way while turning, and hides while a
  Treasure Map is held; the "You found Tilly!" toast.
- `/build house` two blocks ahead and UNDO (MORE) takes it back in one step; `/freeze` on a LAN guest.
- `/weather sandstorm` in the desert, `/weather snow` in Frostpeak; `/peace` flips the pause menu's MONSTERS.

## Skills

`godot-prompter:godot-testing` (GUT, fakes by injection rather than doubles: the runner's Callables),
`godot-prompter:localization` (rejected `tr()`/translation CSVs for the aliases: they are input words, not
shown text, and M3 Task 21a owns the translation files; chosen: alias tables in the rules),
`godot-prompter:multiplayer-basics` (the host decides; one `authority` RPC host → guest for the clock and the
command switch; guests' requests stay `any_peer` → host-checked).
