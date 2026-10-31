# M1b Task 12: Game chat and commands

Owner request (2026-09-23 22:58): "we also should have commands in the game chat". Spec §3b "Game chat
with commands", §5.13 and §5.14; plan Task 12.

## What was built

- A **CHAT** button on the HUD at (106, 18), size 76, next to pause. It is shown on touch and on desktop.
  - T or Enter opens the chat; "/" opens it with "/" already typed.
  - The chat bar sits at the top of the screen: a text field, SEND and X.
  - Under the bar is a row of tappable buttons:
    - Empty bar: the quick-chat phrases (Hi!, Follow me!, Look!, Nice build!, Thanks!, Help!, Bye!,
      Come here!, Wow!, Let's build!, Good job!, Yes!, No!) plus a "/ COMMANDS" button.
    - After "/": every command as a button. Tapping one that needs a choice shows its choices
      (for example /time shows day, night, noon, midnight, sunrise, sunset). Tapping a complete
      command runs it. A yellow hint line shows the usage.
  - The history holds the last lines: 6 while the bar is closed, fading 8 s after each line arrives;
    10 while it is open. Player lines are white, system lines gold and errors light red. It is text
    only, with no emoji.
- **Commands** (all work in Sandbox):
  - Implemented: `/help` (and `/help tp`), `/tp x y z` (with `~` and `~5`), `/tp name`, `/spawn`,
    `/fly`, `/ghost`, `/walk`, `/size giant|tiny|normal`, `/jumps 2|3`, `/style blocky|realistic`,
    `/seed`, `/clear` and `/give <block or item>`.
  - `/time`, `/home` and `/summon` are wired to sandbox hooks that other tasks build (see
    Integration). Until a hook exists they answer "That command arrives soon!".
- **Messages to other players** (LAN), following §5.13:
  - `under_13` players send and receive only the quick-chat phrases.
  - `13_plus` players send free text through a bad-word and personal-info filter.
  - Each message is at most 120 characters, trimmed, with spaces squeezed and control or invisible
    characters removed.
  - The host allows each player at most 5 messages or host commands per 10 s.
  - The host announces "X joined the game." and "X left the game.".

## Files

New:
- `core/rules/chat_rules.gd` (`ChatRules`): clean, check, filter_code, can_receive, message and the
  `RateLimiter` inner class.
- `core/rules/chat_commands.gd` (`ChatCommands`): tokenize, parse, the registry (`COMMANDS`), usage and
  about text, host_check, runs_on_host, is_allowed, suggestions, choices, find_player, giveable_ids
  and the `TIME_*` constants.
- `scenes/chat_command_runner.gd` (`ChatCommandRunner`): runs every command. Local commands run on
  this device; host commands run on the host through the hooks.
- `ui/hud/chat_panel.gd` (`ChatPanel`): the button, bar, choice buttons and history, plus blocking
  game keys while typing.
- Tests: `tests/unit/test_chat_rules.gd` (19), `tests/unit/test_chat_commands.gd` (24),
  `tests/integration/test_chat_session.gd` (13), `tests/integration/test_chat_panel.gd` (10).

Changed (shared files; insertions only, apart from one moved line):
- `autoloads/session.gd`: a new "Chat and commands" section at the end of the file, with its own
  signals and vars. No existing line changed.
- `ui/hud/hud.gd`:
  - `var chat := ChatPanel.new()`.
  - `add_child(chat)` just before the palette.
  - Two lines at the end of `setup()`: `chat.setup(...)` and adding the chat's blockers to the
    look/build area.
  - **Moved `fps_label` from x=110 to x=194**, because the CHAT button now covers x 106–182.
- `scenes/sandbox.gd`:
  - `_setup_chat()` is called at the end of `_setup_local_player()`.
  - Android Back closes an open chat (a new `elif` after the palette branch in `_notification`).
  - A new "Chat commands" section at the end of the file.
- `project.godot` and `tools/setup_input_map.gd`:
  - New actions `chat` (T, Enter) and `chat_command` (/), appended after `mirror`.
  - The project.godot entries are byte-identical to what the tool generates (checked by running
    the tool on a scratch copy).
- `docs/DEVELOPMENT.md`:
  - The chat keys in the input-map list.
  - Three gotchas: Input polling ignores GUI focus; a `--script` main loop can't name autoloads;
    `XDG_DATA_HOME` isolates `user://` for headless runs.

## Tests (TDD)

The rules (`ChatRules`, `ChatCommands`) and the Session wiring were written test-first. I ran each
file and watched it fail on the missing classes before implementing. `test_chat_panel.gd` was written
after `ChatPanel`, to lock the panel's behaviour headlessly.

Plan test list, and where each item lives:
- **Parsing:**
  - Case-insensitive names and extra spaces: `test_names_are_case_insensitive_and_extra_spaces_are_fine`.
  - Quoted words: `test_quoted_words_stay_together`.
  - `~` coordinates: `test_tp_tilde_means_here`.
  - Bad numbers: `test_tp_bad_numbers_give_a_friendly_error`.
  - Unknown command: `test_unknown_command_says_try_help`.
  - Also: `test_tp_absolute_coordinates_land_in_the_block_centre`, `test_tp_wrong_argument_count_shows_usage`,
    `test_tp_player_name`, `test_tp_is_clamped_to_the_world`, `test_find_player_by_name`,
    `test_time_values`, `test_give_finds_blocks_and_items_by_name`,
    `test_every_giveable_thing_fits_a_hotbar_slot`, `test_summon_animals` (also checks each animal
    exists in `AnimalRules.SPECIES`), `test_size_jumps_style`, `test_commands_without_arguments`,
    `test_help_topic`.
- **Usage text and a handler for every command:** `test_every_command_has_usage_text` and
  `test_every_command_has_a_handler` (the runner has `_cmd_<name>` for every registry entry).
- **Suggestions:**
  - "/ti" includes "/time": `test_suggestions_for_a_command_prefix`.
  - Choices of a command: `test_suggestions_for_arguments`.
  - `test_every_suggestion_is_a_valid_command`.
- **Message cleanup and the 120-character cap:** `test_clean_trims_and_squeezes_spaces`,
  `test_clean_strips_control_characters`, `test_clean_caps_at_120_characters`, `test_only_spaces_is_empty`.
- **`under_13` free text refused, quick chat passes:**
  - `test_under_13_free_text_is_refused`, `test_under_13_quick_phrases_pass`,
    `test_unknown_band_is_treated_as_under_13` and `test_under_13_players_only_receive_quick_phrases`.
  - Through the host: `test_under_13_free_text_is_refused_by_the_host` and
    `test_a_player_who_never_joined_counts_as_under_13`.
- **Phone numbers and bad words filtered for `13_plus`:**
  - `test_phone_numbers_are_filtered_for_teens`, `test_a_few_numbers_are_fine`,
    `test_emails_links_and_contact_apps_are_filtered` and `test_bad_words_are_filtered_for_teens`.
  - `test_innocent_words_that_contain_bad_ones_pass`, `test_username_filter_is_unchanged` and
    `test_filtered_message_is_refused`.
- **Rate limit (5 per 10 s per player):** `test_rate_limit_five_per_ten_seconds_per_player`,
  `test_rate_limit_forget_resets_a_player` and `test_host_rate_limits_messages`.
- **World-changing commands only on the host and only in Sandbox:**
  - Pure rules: `test_world_changing_commands_run_on_the_host`,
    `test_host_runs_only_world_changing_commands_sent_over_the_network` and
    `test_commands_only_in_sandbox`.
  - Through the host: `test_world_changing_command_reaches_the_sandbox_on_the_host`,
    `test_host_refuses_a_local_command_sent_to_it` and `test_commands_off_outside_sandbox`.
- **Hooks:** `test_hooks_not_built_yet_answer_soon` and `test_time_and_home_call_the_sandbox_hooks`.
- **Input map:** `test_chat_keys_are_in_the_input_map`.
- **Panel:**
  - `test_typing_switches_game_keys_off_and_back_on` and `test_leaving_the_game_while_typing_gives_the_keys_back`.
  - `test_empty_bar_shows_quick_phrases_and_commands`, `test_slash_shows_every_command_as_a_button`
    and `test_tapping_a_command_that_needs_a_choice_shows_the_choices`.
  - `test_submitting_a_command_closes_and_emits_it`, `test_under_13_free_text_stays_local_with_a_hint`,
    `test_keyboard_shortcuts` and `test_history_keeps_recent_lines_and_clears`.

Full suite: 330 passing (264 before plus 66 new), exit code 0.

### Extra evidence (headless, isolated `XDG_DATA_HOME`, nothing committed)

**Real sandbox, solo.** A driver typed every command through the real ChatPanel and runner:
- `/give diamond` put id 22 in the selected slot.
- `/tp ~ ~20 ~` moved the player to y+20, and `/tp 10 80 10` moved it to (10.5, 80, 10.5).
- `/spawn` went back to the spawn column.
- `/fly`, `/ghost`, `/walk`, `/size`, `/jumps` and `/style` applied, and `/seed` printed the seed.
- `/time`, `/home` and `/summon` answered "arrives soon".
- `/dance` and `/tp 1 x 1` gave friendly errors, and `/clear` emptied the history.
- No script errors.

**Two processes over ENet.** The host was HostHero (`13_plus`); the client was KidKay (`under_13`):
- KidKay's "Hi!" reached both players.
- A raw `Session._rpc_chat.rpc_id(1, "hello from a hacked client")` was refused.
- A raw re-join claiming `13_plus` was ignored, and the free text after it was refused.
- A raw `_rpc_command("/give diamond")` was refused ("works on your own device").
- `/time night` from the client reached the host and came back as "arrives soon" over RPC.
- The host's "Hi!" reached KidKay; the host's free text "want to build a castle?" did not.
- 6 × "Wow!" gave 5 delivered and one "Slow down".
- `/tp hosthero` (case-insensitive) landed 1 block beside the host.
- The host announced "KidKay left the game.".
- After the client left, the host logged one engine error, "Attempt to call RPC with unknown peer ID".
  It has no GDScript backtrace, so the call came from engine-side code (most likely the Voxel Tools
  terrain sync addressing the departed peer's viewer), not from chat. Chat only sends to
  `multiplayer.get_peers()`.

## Decisions (rulings), each with its cost if wrong

1. **How the host knows the age band.** Each player registers `{name, band}` once through a new
   `chat_join` RPC; it is not part of the hello handshake, so the existing handshake is untouched.
   - The first registration per peer wins. A peer that never registers counts as `under_13` and is
     named "Player".
   - The host checks every message against the sender's registered band, never against anything
     the message carries.
   - Trust trade-off: on LAN the band is self-declared by the joining device, because it is only
     stored there (§4.1). A modified client could lie once at join. M4 moves the band to the server
     account.
   - Cost if wrong: small. The same check moves to Nakama in M4.
2. **Under-13 players also receive only quick-chat phrases.** Free text from a `13_plus` player is
   not delivered to `under_13` players. That is the reading of "quick-chat wheel only" for under-13s.
   - Cost if wrong: under-13 siblings miss older players' typed messages. Relaxing it is a one-line
     change to `ChatRules.can_receive`.
3. **The chat filter matches whole words, not substrings.** It reuses `UsernameRules.BLOCKED_WORDS`
   and `LEET`; `username_rules.gd` is unchanged.
   - A word is blocked when it starts with a blocked word ("stupidest", "killed"). A few strong
     words are blocked anywhere inside a word.
   - Runs of single letters are joined, so "s t u p i d" is still caught.
   - Personal info covers 7 or more digits (spaces, dashes, dots, brackets and + allowed between
     them), emails, links, and contact phrases (address, snapchat, discord, "where do you live", …).
   - Refused messages are not masked; the sender gets a friendly reason.
   - Cost if wrong: "kill" and "hate" are blocked in chat too (they are on the username list), and
     numbers such as "120 64 -300" count as a phone number. The fix is a list edit. M4 gets a
     server-side filter.
4. **Where commands run.**
   - Local, on this device: `/help`, `/tp`, `/spawn`, `/fly`, `/ghost`, `/walk`, `/size`, `/jumps`,
     `/style`, `/seed`, `/clear` and `/give`. The body, hotbar and settings are each player's own;
     `/give` only fills the selected hotbar slot, and placing still passes the host's edit checks.
   - On the host: `/time`, `/home` and `/summon`.
   - The host re-parses the raw text (`ChatCommands.host_check`). It refuses local commands sent
     to it and anything while `Session.commands_enabled` is false.
   - Any player may ask for a host command in a Sandbox world, the same as in the spec. Cost if
     wrong: if the owner wants host-only powers (like Minecraft ops), add
     `if peer_id != multiplayer.get_unique_id(): refuse` in `Session._host_command`.
5. **The rate limit also counts host commands**, from the same bucket: 5 per 10 s per player.
   Local commands are not limited (they never reach the host).
6. **Modal chat.** While the bar is open, a see-through layer covers the screen: tapping outside the
   chat closes it, and no building or looking happens behind it.
   - The keyboard's game keys (every non-`ui_*` action) are taken out of the Input Map while typing
     and restored on close or on leaving the game. Escape and Android Back close the chat. Opening
     the pause menu closes it.
   - Sending a message or running a command closes the bar, as in Minecraft.
   - Cost if wrong: children can't walk and chat at the same time. The see-through layer can be
     dropped if the owner wants it.
7. **`/tp` details.**
   - Whole numbers on x and z land in the centre of that block (+0.5), as in Minecraft; decimals are
     used as typed.
   - It is clamped to ±30000 on x and z and to −63…256 on y. Exponent notation is refused.
   - It uses `Player.spawn_at`, so far jumps wait for terrain and walking mode unsticks the player
     from blocks.
   - `/tp name` lands 1 block beside the other player. The name is case-insensitive, and a unique
     start of a name also works.
8. **Times of day** (as the lead specified): midnight 0.0, sunrise and day 0.25, noon 0.5, sunset
   0.75, night 0.875. `/time` also accepts `sunrise` and `sunset`.
9. **Duplicate names** get a number on the host ("Hopper", "Hopper2").

## Integration notes for the lead

- **Sandbox hooks.** They are called on the host only, found with `has_method` on the sandbox node:
  - `set_time_of_day(t: float)`: t in 0..1 with 0 = midnight, from `ChatCommands.TIME_*`
    (0.0, 0.25, 0.5, 0.75, 0.875).
  - `go_home(peer_id: int)`: move that player home (bed, or the spawn). For a client, the hook must
    tell that client to move, because bodies are client-authoritative.
  - `summon_animal(species: StringName, near: Vector3)`: species is one of dog, cat, pig, cow,
    sheep, chicken, rabbit, fish. `near` is the asking player's feet, from the host's copy of their
    body.
  - A hook may return a non-empty `String`, which is shown to the asking player instead of the
    default reply (for example "Too many animals here!"). Otherwise the runner broadcasts "X made it
    night." (time) or "X called a dog!" (summon), or replies "Going home!".
- **Session API.**
  - Calls: `chat_join`, `request_chat`, `request_command`, `send_chat_line(peer_id, text, kind)`,
    `broadcast_chat_line(text)`.
  - Signals: `chat_received(from, text, kind)` and `command_requested(peer_id, cmd)` (host only).
  - State: `chat_names`, `commands_enabled`.
  - Other features can post to the chat with `Session.send_chat_line` or `broadcast_chat_line`.
- **Survivor (M2).** Set `Session.commands_enabled = false` on the host. For local commands the
  clients check their own copy, so M2 must also send the flag to clients (for example in
  `world_info`).
- **Merge conflicts to expect.** They are all "keep both" insertions:
  - The end of `session.gd` and `sandbox.gd`.
  - The `var` list and `_ready` in `hud.gd`.
  - The end of `[input]` in `project.godot` and of `KEYS` in `setup_input_map.gd`.
- **The spec's architecture list.** `core/rules/` gained "chat commands, chat rules"; that list was
  not edited to avoid a conflict.

## Visual checks for the lead (emulator and desktop)

1. **The CHAT button.** At (106, 18) next to II, it reads "CHAT" and does not overlap MIRROR (14, 112).
   The FPS label (when on) now starts at x=194.
2. **Tapping CHAT.**
   - The bar appears across the top and the on-screen keyboard comes up.
   - The quick phrases and "/ COMMANDS" show under the bar.
   - The buttons stay clear of the right-hand button column (they end 130 px from the right edge).
3. **Tapping "/ COMMANDS".** 15 command buttons appear (2–3 rows, scrollable). Tapping "/time" shows
   day…sunset, and tapping "night" runs it ("arrives soon" until Task 10 lands).
4. **Closed state.**
   - The history (top-left under the buttons, x 120–680, y 104–290) fades after about 8 s.
   - It does not cover the joystick area (bottom-left) or JUMP.
   - Check that it is readable over a bright sky (white text with a black outline).
5. **Typing on the desktop.** Press T, type "wasd" and the player must not move. Escape closes the
   chat. "/" opens it with "/" typed. Enter on an empty bar closes it.
6. **Tapping the world while the chat is open** closes it without placing a block. Android Back
   closes the chat instead of pausing.
7. **The plan's emulator checks.** `/time night`, `/tp ~ ~20 ~`, `/give diamond` and `/summon dog`
   (the last only after Task 9's hook).
8. **Two LAN instances.** Try quick chat between them, and free text from a `13_plus` profile.
9. **Long history lines** wrap within 560 px; long hint lines are clipped.
