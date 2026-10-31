# Owner feedback #49: a chat you can read on a phone

**The owner's words (2026-09-24, playing online through the real server on phones, build 0.3.2):** "we need
to improve chat, when you type you dont see the text, also text chats are not showing correctly".

Built on release 0.3.2's code (`4d3198d`: audio pass, Survivor games, blasters, treasure pack, chat commands
#40, bot chat #38). No emulator, adb or godot-mcp was used: the lead checks on the emulator (list below).

## How it was reproduced

`tools/chat_shots.gd` (new, windowed; DEVELOPMENT.md §4 "Pictures of the chat") draws a 13+ player's
crowded Survivor HUD (a game's round line and clock, the ★ BRAVE badge, the gold) over a bright sky, with
friends' lines (a long one, Georgian, an emote, a bot's answer) and a dark stand-in for a phone keyboard over
the bottom 55 % of the screen. Before and after, at 1600 × 720 (the emulator's 20:9 canvas) and 1280 × 720:
`owner-49/owner-49-shots.jpg` (left: before, right: after; the folder has a `.gdignore`, so the picture
is never imported or exported into the APK).

## Root causes (each suspect checked)

1. **The HUD was drawn over the open chat bar — the typed words vanished under it.** This is what "when
   you type you dont see the text" was. `Hud` adds the chat panel early and later pieces go after it
   (`move_child(x, palette.get_index())`): a game's round line, the wave line and the boss bar (top middle,
   over the middle of the text field), the ★ BRAVE badge (over the start of the typed words), the gold
   (over QUICK), the game clock and the race clock (over the phrase buttons and the lines), ATTACK and
   CROUCH (over the wheel's COMMANDS pill). Only the hearts and the eye had been moved under the chat. On
   the 2400 × 1080 screen alone the test flagged 17 controls drawn over the open chat.
2. **The phone keyboard hid the newest lines** (suspect 1, partly). The field itself was never under the
   keyboard: the bar has always been at the top. But Godot 4.7.2 on Android neither resizes nor pans the
   game for the keyboard (the activity is edge-to-edge; `GodotEditText` asks for `IME_FLAG_NO_EXTRACT_UI`,
   so a landscape keyboard is not full-screen either): it covers about the bottom half of the screen. The
   open history started under the phrase buttons (y 294) and ran oldest-first down to y ≈ 600, so the
   newest lines, the ones a child waits for, were under the keyboard; with the phrase buttons showing,
   only the oldest line was above it. Measured in the RED run: at 2400 × 1080 the newest line ended at
   y = 942–1239 px with the keyboard's top at 486 px.
3. **The quick-chat wheel covered the lines.** Under-13 players chat with the wheel only; the lines were
   drawn under its slots, so a friend's words could not be read while it was open.
4. **Contrast** (suspect 3). White words had only a 6 px outline over the world: hard to read over a bright
   sky or snow. Wrapping itself worked (a 120-letter word wraps); lines were not cut, but ten long lines ran
   down over the joystick and the hotbar.
5. **Georgian letters** (suspect 2). The game has no font of its own: every Label, LineEdit and Button uses
   the engine's built-in Open Sans SemiBold, which has **no Georgian** (`has_char(ა)` is false). Georgian
   only showed through the engine's automatic system-font lookup. On this desktop that worked (DejaVu
   Sans). On Android, Godot 4.7.2 does implement the lookup, but reads only `/system/etc/fonts.xml`
   (checked in the export template's `libgodot_android.so`: `/etc/fonts.xml`, `fallbackFor`, `und-`), a
   file Android 15 deprecates in favour of `font_fallback.xml`. Probably not the owner's main problem, but
   nothing guaranteed it; emoji go through the same lookup (they drew on this desktop, Noto Color Emoji).
6. Online reading and sending were checked too and were fine for Georgian: `ChatRules.clean` and the
   server's `chat.ts` keep it, Nakama's JSON carries UTF-8, and the team room echoes the sender's own
   line. (An under-13 reader never sees free text, and a room with an under-13 player refuses it: by design.)

## What changed

- `ui/hud/chat_panel.gd`, section "Owner 49" (and the history code it replaces):
  - While open (the bar, the wheel or MUTE / REPORT) the panel is the HUD's **last child**: drawn over
    everything and hearing touches first (its see-through layer closes it). Closed, it goes back between
    its neighbours (`_raise`), so the palette, the MORE panel and the emote wheel stay on top as before.
  - **The keyboard:** `keyboard_height` (a Callable; `DisplayServer.virtual_keyboard_get_height()` where the
    display server has a virtual keyboard, else 0) → `keyboard_top()` on the canvas (px × canvas height /
    window height). The phrase and command buttons shrink to about one row (they scroll) to leave two
    lines' room; the history shows **the newest lines that fit** between the buttons (or the bar) and the
    keyboard, measured before they show (`_fitting`: an autowrap label's `get_minimum_size()` at its
    width). Polled every frame while the bar is open, so it follows the keyboard up and down.
  - **With the wheel:** the lines move to a column left of it, under CHAT (clear of PAUSE, CHAT, BOOK and
    the slots), drawn over the wheel's dim (the history node now sits after the wheel, before the menu).
  - **Every line** is a label as wide as its words on a dark backing (`LINE_BACK`, alpha 0.9, rounded):
    contrast ≥ 4.5 for every kind (chat, system, error, bot) over snow, sky, sand or a cave. The open
    history is as wide as the buttons (up to 760); the closed one keeps to a 500 × 260 box (older lines
    give way to a long new one).
- `ui/hud/hud.gd`: the game clock goes under the chat (`mini(chat.get_index(), palette.get_index())`), like
  the hearts, so a friend's line reads over it.
- `ui/theme/ui_kit.gd`, section "Owner 49": `add_script_fallbacks()` (run once by `UiKit.theme()`) finds the
  device's font for Georgian (`SCRIPT_FONTS`: every letter; `OS.get_system_font_path_for_text`, then
  Android's files `/system/fonts/NotoSansGeorgian-VF.ttf`, `-Regular.otf`, `-Regular.ttf`, `.ttf`), keeps it
  only if it has every letter, draws it like the base font (a variable font at the base's weight, 600) and
  adds it to `ThemeDB.fallback_font.fallbacks`, the engine font every control and name tag uses. The path
  used is in `UiKit.script_font_paths`. Nothing is bundled.
- `tools/chat_shots.gd` + `_steps.gd` (pictures), spec §3b "A chat you can read on a phone", M4 plan 6b,
  DEVELOPMENT.md (pictures, architecture, four gotchas).

## Tests (RED → GREEN)

`tests/integration/test_chat_readable.gd`, at 2400 × 1080 and 1280 × 720 with a keyboard over 55 % of the
screen; all nine were RED before the fix (run on a copy that reached the new API dynamically, so each
failed for its own reason):

| Test | RED before |
|---|---|
| `test_what_a_child_types_and_the_newest_lines_stay_above_the_keyboard` | newest line at 942 px, keyboard top 486 px |
| `test_the_phrase_and_command_buttons_and_the_newest_line_fit_above_the_keyboard` | newest line at 1239 px |
| `test_the_chat_follows_the_keyboard_up_and_down` | 10 lines either way |
| `test_nothing_on_the_hud_is_drawn_over_the_open_chat` | BraveBadge, the round line, gold, game clock, race clock, ATTACK… over the field, buttons, lines, wheel |
| `test_closed_lines_stay_readable_over_the_games_clock` | the game clock over a line |
| `test_while_the_wheel_is_open_the_lines_stay_clear_of_it` | lines under 5 slots |
| `test_a_friends_long_line_wraps_inside_the_history_and_reads_on_any_world` | no backing (contrast 1.0 over snow) |
| `test_georgian_letters_have_glyphs_in_the_games_own_fonts` | the field and the lines lack ა–ჰ |
| `test_on_android_the_georgian_font_is_found_by_its_file_too` | no `SCRIPT_FONTS` |

The Georgian glyph test is `pending` on a computer with no Georgian font at all (this PC has Noto Sans
Georgian and DejaVu Sans).

## Three failures release 0.3.2 carried in (fixed in their own commit, tests only)

The first full suite on 0.3.2 + this change had 4 failing tests of 4089; none touch the chat:

- `test_candy_generator.gd::test_secret_structures_are_generated_without_seams` ("13 expected to equal 5"):
  the treasure pack (#42) adds its places to every universe's secrets and changed this check in the
  meadows, desert and frost tests to count the M2 kinds only; the Candy Kingdom test came from a parallel
  branch and kept the old count. Same one-line filter as the others.
- `test_main_menu_modes.gd` (`test_after_how_brave_a_new_survivor_world_asks_which_game`,
  `test_monster_wave_lists_the_arenas_and_a_card_starts_one`): the audio pass connects a click to every
  button's `pressed` as it enters the tree (`Audio._on_node_added`), after the menu's own handler, so
  `pressed.get_connections().back()` was the click. Failed the same way with the release's own chat, HUD
  and UiKit files put back. The test now picks the connection that is not Audio's (`_menu_bound`).
- `test_visit_world.gd::test_the_showcase_stands_on_the_island_with_the_friends_name_on_a_sign` failed once
  under the full suite's load and passes alone, with and without this change (it reads a streamed block
  right after the visit opens): timing, left as it is.

**Full suite (`tests/suite_slots.sh tests/run_tests.sh`): 4089/4089 passing, exit 0** (433 scripts).

## Rulings (cost if wrong)

1. **The open chat moves to the end of the HUD instead of every HUD piece moving under it.** One place,
   and pieces added later are covered too. Cost if wrong: while the bar is open, a tap on MORE or ATTACK
   closes the chat instead of pressing them (the see-through layer is on top now) — the design already
   said a tap outside closes the chat.
2. **The history shows the newest lines that fit; older ones give way** (open above the keyboard, closed in
   a 500 × 260 box). Cost if wrong: with the phrase buttons up and a tall keyboard only one or two lines
   show; typing hides the buttons and shows four or more. Before, ten lines ran under the keyboard and over
   the joystick.
3. **The keyboard's height is read every frame while the bar is open** (an int compare; a re-layout only
   when it changes). Cost if wrong: none measurable; closed, nothing is read.
4. **The device's font, not a bundled one, and not `SystemFont` by name.** On Android the Georgian family
   in `fonts.xml` has no name (Godot calls such families "sans-serif"), so `SystemFont(["Noto Sans
   Georgian"])` would get Roboto; the OS lookup for Georgian text (script `Geor`) and Android's file names
   find the right file on every Android version, and it is kept only if it has every letter. Cost if
   wrong: on a phone without any Georgian font the letters still show as boxes (the engine's own lookup
   is still there after ours); the fix then needs an OFL font and the owner's word (CC0-only rule).
5. **Emoji are left to the engine's automatic lookup.** They drew here; loading Android's 10 MB emoji font
   up front was not worth the memory. Cost if wrong: emoji show as boxes on some phones; the same
   `SCRIPT_FONTS` table takes an emoji entry.
6. **The game clock goes under the chat** (a friend's line, fading after 8 s, reads over the clock). Cost if
   wrong: a line covers part of the clock for a few seconds.
7. **Lines as wide as their words** (like chat bubbles), on a 0.9 dark backing. Cost if wrong: looks only.

## For the lead: check on the emulator (AVD `Pixel_8_API_35`)

Two games online through the server (or LAN), both 13+ with text chat, in a Survivor game (round line and
clock showing) with a Brave world if possible:

1. Tap CHAT: the keyboard comes up; type Georgian (switch the keyboard's language) and a long English
   sentence. **Every letter shows in the field at the top**, nothing covers it (no round line, BRAVE or
   gold over it), and SEND, QUICK and X are clear.
2. With the keyboard up: the phrase buttons (empty bar) and the "/" command buttons show a full row above
   the keyboard, and **the newest line sits above the keyboard**. Type words: the buttons go and four or
   more lines show. Hide the keyboard with Back: the lines fill the space again.
3. From the other game send a long line, a Georgian line and an emote: they show on dark backings, wrap
   inside the history and read over sky and snow; Georgian letters are real letters, not boxes. Also try
   an emoji (ruling 5).
4. `adb shell ls /system/etc/fonts.xml /system/etc/font_fallback.xml /system/fonts/NotoSansGeorgian*` (with
   the project's adb variables): which files this Android has (ruling 4).
5. An under-13 player: CHAT opens the wheel; friends' lines show in the column left of the wheel, under
   CHAT, not under the slots; tapping a friend's line there opens MUTE / REPORT.
6. Close the chat: the MORE panel and the block palette open over the HUD as before (the chat is back in
   its place); closed lines fade after 8 s and read over the game clock.
7. Performance: the chat open with the keyboard up for a minute costs no FPS (one int read per frame).
