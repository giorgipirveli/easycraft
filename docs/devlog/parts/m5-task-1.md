# M5 Task 1: the accessibility pass (notes)

Brief `docs/superpowers/briefs/prompt-m5t1.md` (+ the lead's update); spec **§15.1** and its new **§15.1a "As built"**,
§5.15; plan M5 Task 1. Built by a background agent in its own worktree after `git merge lead-merge` (release 0.4.0),
paused at 17:44 by the owner's 3-agent cap, resumed at 19:20, merged again then (`c406484`, owner #52: **English only**
— no Georgian lines, nothing measured in two languages) and after M3 Task 15's merge (`1f545b3`: Pip's step card, PIP'S
LESSONS on HELP), without the editor or the emulator. **No block or item ids, no new always-visible HUD button.**

## What was built

| Piece | Where | What it does |
|---|---|---|
| The HUD table's sizes, mirror and moves | `ui/hud/hud_layout.gd` (a section at the end; `place` and `rect` go through it) | `configure(step, left, moves, screen)` / `configure_from(profile, screen)`: NORMAL is the table as it was; **BIG ×1.1 and BIGGER ×1.2** grow the thumb controls (JUMP 248/270, ATTACK 220/240, CROUCH and GLIDE 149/162, the stick 209/228) and use their own spots (`BIG_SPOTS`, `BIGGER_SPOTS`, `_MIDDLE`); the **left hand** sees every spot in a mirror (`mirrored`); **moves** (JUMP, ATTACK, CROUCH, the stick) are kept only when they cover nothing that may show with them (`APART` lists what never shows together) and stay inside the screen and the display's safe area (`fits`; `rejected` lists the rest). `clashes(screen)` lists overlaps (a test wants none). A placed control keeps its spot in meta (`PLACED`). |
| The HUD | `ui/hud/hud.gd` (a section at the end + 2 lines in `_ready`, the online dot's mirror) | Configures before anything is placed; `relayout()` places every control again (meta) when the settings that shape it change (`Game.settings_applied`, compared to the last layout: a volume slider does nothing) or the screen does; then the stick's size, the name's side, the online dot, the race clock and toasts under a visit's bar, the MORE panel's side, the text size, the chat's bar and lines. Adds the captions under the toasts. |
| MORE and the chat, mirrored | `ui/hud/more_panel.gd`, `ui/hud/chat_panel.gd` (sections at the end) | The MORE panel grows away from MORE on either side. The chat bar runs from the left edge to pause for the left hand; the lines' place (`_history_area`) is the right hand's in a mirror. |
| MOVE BUTTONS | `ui/hud/hud_editor.gd` (`HudEditor`) | A picture of the HUD at the child's size and hand: faint outlines of everything else, the four movable controls drawn like the HUD's; one finger (or two) drags; a place with no room is **crossed out** while held and the control goes back on letting go ("No room there: it went back."); DONE saves this size's moves (right hand's frame), RESET puts all four back, Back closes without saving. Title with a speaker. Works while paused. |
| SETTINGS: BUTTONS & TEXT | `ui/menus/settings_panel.gd` (a section at the end + 3 lines: the header's third page button, `show_page`, `_ready`) | Button size (NORMAL / BIG / BIGGER), Hands (RIGHT HAND / LEFT HAND) + MOVE BUTTONS (the editor on a `CanvasLayer` 120, over the menus, the pause menu and Feel's flash), Text size (NORMAL / BIG) + Sound captions, a line about them. 1036 × 617 on the 1280 × 720 screen. The page buttons keep #52's lit/dark look (`PAGE_SHUT`). |
| Settings and the profile | `core/save/profile_data.gd` | `button_size`, `left_handed`, `text_size`, `captions` (on) in the settings; `hud_moves` ({size: {spot: [x, y]}}) at the profile's top level (a Dictionary in the settings would be stringified by `_coerce`); unknown sizes and bad moves dropped on load. |
| TEXT SIZE | `ui/theme/text_size.gd` (`TextSize`) + one line each in the toast and name (Hud), `SurpriseBanner`, `PictureHint`, `RiddlePanel` (the note and the riddle's choices), `KnockoutOverlay` (the tip; its message is 64 px already), `ChatPanel` (lines, the measuring label, the hint, the bar) | `mark(control, normal_px)` keeps the NORMAL size in meta and a group; `refresh(tree)` applies a new choice (the Hud calls it before the chat measures its lines again). BIG ×1.25. |
| Sound captions | `core/rules/caption_rules.gd` (`CaptionRules`), `ui/hud/sound_captions.gd` (`SoundCaptions`) | Listens to `Audio.sound_played` (only audible sounds reach it): monsters' voices (goblin, slime, mummy, scorpion, yeti, bats, wisps, gummies) "Monster near", the Sneaker's jingle, the serpent's hiss, the bosses' roars, the serpent's rumble below, the wave horn, babble "Someone talks"; night falling from the scene's `SkyCycle`. A chip (picture drawn in code + a few words) on an oval round the middle towards the sound (behind: the bottom), following the camera; one per kind per 4 s, 3 at most, 2.5 s each; a small pop that Reduce motion turns off. |
| Never colour alone | `ui/avatar/avatar_tile.gd` (pips), `ui/hud/hearts_bar.gd` (hollow empty hearts), `ui/hud/chat_panel.gd` (marks) | Avatar and shop tiles count their rarity in pips (1–5, like the tier icons), shown while worn too (the rim turns gold then); an empty heart has a light outline (hollow), a full one a dark outline and a shine; the chat's game lines "» ", errors "! ", bot friends' lines "(bot) " (glyphs the game's own font has; `_fitting` measures the line as shown). |
| Reduce motion, newer effects | `core/rules/feel_rules.gd` (`burst_amount`, `burst_speed_scale`), `entities/fx/fx.gd` (`calm`), `world/blaster_director.gd` (pooled bursts), `ui/menus/coin_shower.gd` | Every `Fx.burst` (gadgets, piñatas, breaks) and the farm's coin shower: half the pieces, 0.6 speed, no spin; the blasters' pooled bursts and the rocket's/piñata's confetti take the setting at each restart (and go back); the menus' coin rain: a third of the coins, no spin, no sway. |
| The Theater over bigger or mirrored thumbs | `ui/hud/hud.gd` (`set_theater_open(on, panel)`; guards in `_update_attack_button`, `_show_up_down`, `_update_glide_button`), `scenes/sandbox.gd` (one line: it passes the panel) | Found by running the Theater test at every size and hand: at BIG/BIGGER and for the left hand the Theater's channel columns (not mirrored, fixed size) reach JUMP, ATTACK and CROUCH on a 16:9 phone, so a tap on a channel also jumped. While the Theater shows, a thumb button under one of its buttons steps aside (looked at 4× a second: its pages change); NORMAL right-handed is as before (JUMP stays). |
| Read aloud on every screen | `ui/avatar/look_choice.gd`, `ui/menus/code_panel.gd`, `ui/avatar/avatar_editor.gd`, `ui/hud/shop_panel.gd`, `ui/hud/totem_panel.gd` (one line each) | The screens without a speaker got one: the boy-or-girl step, the secret code panel, the avatar editor (bottom row: "Make your look." + its message), Tilly's shop and the Monster Totem (beside their titles). |

## Tests (RED → GREEN)

| Test | What it proves |
|---|---|
| `tests/unit/test_hud_layout_config.gd` (12) | NORMAL is the old table; BIG/BIGGER grow the thumb controls by their factor and keep the top buttons; `clashes` is empty at every size × hand × 1280/1600; the left hand's table is the mirror; moves kept / refused (onto JUMP, off the screen, onto the game clock), checked per screen (CROUCH −100 fits 1600, not 1280), mirrored for the left hand, only the four movable; `sanitize_moves`; the profile round trip. RED: 2 (my own bad example, and GLIDE vs TEAM PHOTO at NORMAL: see rulings). |
| `tests/integration/test_hud_layout.gd` (extended) | `test_every_button_is_big_with_a_picture_and_nothing_overlaps` and the GLIDE test at **every size and both hands** on 2400 × 1080 and 1334 × 750, Sandbox and Survivor, awake / riding / asleep / gliding (thumb buttons ≥ minimum × factor, the stick grows and fits its area); MORE's panel on the left hand's side; `test_changing_the_settings_places_the_hud_again`; `test_a_moved_jump_is_where_the_child_put_it_and_a_bad_move_is_not`; `test_the_left_hands_chat_bar_runs_from_the_left_edge_to_pause`. RED before the Hud relayout (4 failing). |
| `test_the_theater_keeps_its_buttons_to_itself` (at every size and hand) | RED: 1 test (JUMP / ATTACK / CROUCH under "Music", "TikTok Picks", "Funny", "Grown-ups" on a 16:9 phone at BIG, BIGGER, left); GREEN: they step aside and come back when it closes. |
| `tests/integration/test_hud_editor.gd` (9) | Real touches in a 1280 × 720 view: the four at the HUD's places at every size and hand; a drag + DONE saves; a place with no room is crossed out while held and refused on letting go; RESET (only this size's moves go); the left hand saves in the right hand's frame; two fingers, the stick; empty ground moves nothing; a speaker. |
| `tests/integration/test_settings_access_page.gd` (4) | Every page fits 1280 × 720; the third page shows only its rows and lights its button; the choices store the settings; MOVE BUTTONS opens the editor on a layer over everything that works while paused, and DONE closes it. |
| `tests/integration/test_text_size.gd` (5) | NORMAL/BIG only; a change reaches a HUD that is up (toast, name, banner, hint, note, knock-out tip, chat line and bar ×1.25) and back; a HUD made at BIG starts big; BIG words still fit (toast, banner, riddle; the knock-out words above GET UP); the chat's shown lines fit their area at BIG. RED: 16 before the marks. |
| `tests/unit/test_caption_rules.gd` (5), `tests/integration/test_sound_captions.gd` (6) | The sounds → kinds, everyday sounds none, every captioned sound exists in `Audio.SOUNDS`, words and pictures; rest and max; placement inside the screen (right on the right, behind at the bottom above the hotbar); on the HUD: from `Audio.sound_played`, towards the sound, apart; rests; the setting; night once; Reduce motion never pops; under the toasts, never taking a tap. |
| `tests/integration/test_never_colour_alone.gd` (6) | Pips per rarity for every tier item and blaster (pixels), avatar tiles' pips (worn too), hearts solid/half/hollow, chat marks distinct and drawable in the game's font and shown on the lines, the arrow and the eye. RED: parse (the API didn't exist). |
| `tests/integration/test_reduce_motion_effects.gd` (4) | The rules; `Fx.burst` and the farm's coin shower calmer; the blaster pools follow the setting each time and go back; the menus' coin rain. |
| `tests/integration/test_read_aloud_screens.gd` (4) | A speaker and words on: when were you born, which year, your name, boy or girl, choose your game, Sandbox/Survivor worlds, Monster Wave, SETTINGS, secret codes, the avatar editor, the portal hub, the pause menu, SETTINGS' three pages, the Secret Book, a note, Tilly's shop, the Monster Totem. RED: 6 screens without a speaker. |

Full suites: 623 scripts, **5825 passing**, 0 failing, 2 risky (#45b's two that never assert), exit 0 on the tree of
commit `87d1cc9` (after lead-merge `1f545b3`); the **final one** after lead-merge `eb888ee` (M3 T15, M4 T10) and the
Theater fix: 624 scripts, **5836 passing**, 0 failing, the same 2 risky, exit 0 (2026-09-25 22:07, load 7).

## Rulings (cost if wrong)

1. **Button size grows the thumb controls only** (the stick, JUMP/UP, ATTACK, CROUCH/DOWN, GLIDE), not pause, CHAT,
   BOOK, RIDE, WALK, MORE or the middle word buttons: they are ≥ 135 already and pressed calmly; the chat bar
   (`BAR_LEFT`), its lines and choices (`CHOICES_LEFT`, right of BOOK), the MORE panel and the hearts are laid out
   round them. Cost if wrong: the chat's bar/lines/choices and the top labels follow the top buttons' sizes (about
   half a day, owner #49's chat tests to redo).
2. **×1.1 and ×1.2** (the spec said normal/big/huge): a 16:9 phone's right edge is full at NORMAL (the labels, MORE,
   ATTACK and JUMP from top to bottom), and at ×1.25 JUMP in the corner meets the hotbar (x 983 vs 977). Cost: a
   bigger step needs the hotbar moved or narrowed.
3. **BIG/BIGGER have their own shape** (CROUCH above JUMP, ATTACK left of JUMP, GLIDE above ATTACK left of the compass,
   the stick's area 400 × 260, SLEEP/WAKE UP over STOP FOR TODAY/HELP UP left of ATTACK, the help ring above, TEAM
   PHOTO under CHAT), found with a small overlap checker (scratch) and proved by the tests. Cost: a child switching
   sizes sees ATTACK move; the moves are kept per size for that reason.
4. **Left hand = the whole HUD mirrored**, not only the bottom: the left column's CHAT ends at y 296 where MORE ends at
   253, so a mirrored ATTACK would sit on CHAT; a mirror of everything can't overlap anything that doesn't overlap now.
   Cost: pause and CHAT move to the top right for the left hand (a child who wants only the thumbs swapped can MOVE
   BUTTONS instead).
5. **GLIDE and TEAM PHOTO share a place at NORMAL on a 16:9 phone** (since M3 Task 14a, found by `clashes`): listed in
   `HudLayout.APART` rather than moving either at NORMAL (the lead and owner have seen that layout): both at once needs
   a glider in the air in the 20 s after a boss. Cost: TEAM PHOTO needs another NORMAL spot.
6. **Moves per button size**, stored in the right hand's frame; a move that stops fitting (another screen, a new size's
   neighbours) is ignored, never pushed somewhere else. Cost: a child on two phones may see a move only on the wider one.
7. **Safe area** = the screen ∩ the display's safe area (phones only; converted to canvas units); the table itself
   was never checked against notches and is not moved. Cost: a notch phone may need insets for the fixed spots too.
8. **Text size: 2 steps** (spec: 3; the brief: NORMAL / BIG) on the words read while playing, not menus: ×1.25 is
   measured to fit (notes, banners, toasts, the knock-out words above GET UP on a 16:9 phone); a bigger step was not
   tried; menus' buttons are 30 px already and every page must fit 720. The knock-out message (64 px) keeps its size,
   its tip grows. Cost: another step in `TextSize.FACTORS` and `test_text_size.gd`'s fits at it.
9. **Captions on by default**; placed on an oval inside the corner buttons rather than at the very edge (the edges are
   buttons); Sneaker's jingle and the serpent's rumble counted as important (a warning each). Cost: a default and
   two table lines.
10. **No team colours exist** (co-op only; hide-and-seek names the seeker in words): nothing to change.
11. **Chat marks** are glyphs the built-in font has ("»", "!") and a word for bots ("(bot) ") — no emoji (not in the
    font). Cost: a drawn icon beside the line instead.
12. **Reduce motion calms every `Fx.burst`**, not only the four named features (one place, block breaks included).

## Known, not fixed

- At BIG/BIGGER, GLIDE (only in the air with a glider) sits where Pip's step card (M3 Task 15, x 445–835, y 176–334 on
  a 16:9 phone) is: the tutorial never gives a glider and a new Survivor world has none, but a replay (PIP'S LESSONS)
  with a bought glider could put them together. Moving GLIDE lower collides with ATTACK or HELP UP.
- The HUD pictures tool (`tools/hud_shots.gd`) still draws NORMAL / right only.

## godot-prompter skills

`hud-system` (one layer, mouse-ignore labels: kept; the HUD is a full-rect Control, not a CanvasLayer of its own, as
before) and `responsive-ui` (anchors to the nearest edge, `DisplayServer.get_display_safe_area()` → used for moved
controls; `content_scale_factor` for bigger UI → rejected: it grows everything, the labels and the hotbar too, and the
16:9 layout would not fit).

## For the lead: emulator checklist (emulator-5554, both styles)

1. SETTINGS → BUTTONS & TEXT: the page fits; its button is lit; NORMAL/BIG/BIGGER, RIGHT/LEFT HAND, NORMAL/BIG text,
   Sound captions; the line about them.
2. BIGGER, in a Survivor world: JUMP in the corner, CROUCH above it, ATTACK left of it, the stick bigger; jump in the air
   with a glider (Sandbox) — GLIDE above ATTACK; near a bed SLEEP left of ATTACK; asleep WAKE UP over STOP FOR TODAY;
   nothing covers anything; the thumb reaches them. Same at BIG.
3. LEFT HAND (NORMAL and BIGGER): the whole HUD mirrored; the stick works on the right, JUMP/ATTACK on the left; open
   CHAT (the bar from the left edge to pause; typing; the lines), MORE (its panel on MORE's right), the hearts and name.
4. MOVE BUTTONS from the pause menu and from the main menu: drag JUMP a little, drag ATTACK onto JUMP (crossed out; it
   goes back, "No room there"), two fingers at once, the stick; DONE → the HUD has the moves at once; RESET; Back
   closes without saving; switch sizes: the moves are per size.
5. TEXT SIZE BIG: toasts, a banner (a secret), a note / the Wanderer's riddle, a first-time picture hint, the knock-out
   tip, the chat's lines and bar — bigger, nothing cut off.
6. Captions: a goblin grunting behind you (a chip at the bottom), a boss's roar, the wave horn (Monster Wave), a bot
   friend talking, dusk → "Night falls"; turn the setting off; Reduce motion: no pop.
7. Colour: avatar editor and the shop's tiles show pips (worn too); hearts after a hit (hollow empties); an error line
   "! …" and a bot friend's "(bot) …" in the chat.
8. Reduce motion on: a piñata, the rocket's confetti, a jump pad's boing — fewer, slower pieces; a code's coin rain.
9. Read to me / speakers: the boy-or-girl step, secret codes, the avatar editor, Tilly's shop, the Totem, MOVE BUTTONS.
