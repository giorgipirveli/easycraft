# Owner #90: game controllers everywhere (PlayStation, Xbox, any pad)

The owner (2026-09-29): "make sure game can be played on playstation browser as well". The lead checked: the PS5's
browser is hidden and has no WebGL and no controller input, and the PS4's is too old for WebGL 2, so no 3D browser game
runs there (a console version needs Sony's programme: the owner's business step). What was built instead: a
**PlayStation (DualSense, DualShock) or Xbox controller plays the whole game** wherever the game runs (a PC, phone or
TV browser, Android, the desktop), and a browser that cannot run the game says so kindly. Brief:
`docs/superpowers/plans/2026-09-29-controllers-brief.md`. Built by a worker agent in its own worktree
(branch `worktree-agent-a42149d931c2cc0d2`, started from `lead-merge` 0121e692 and rebased onto a2979233, after the
missions, earn + invite + the Gold Shop and the TV shows were merged), without the editor, an emulator or a real pad.

## The buttons

| What the child does | PlayStation | Xbox (and any other pad) | Action (input map) |
|---|---|---|---|
| Walk | left stick | left stick | `move_forward/back/left/right` |
| Look around (smooth; SLOW / NORMAL / FAST in SETTINGS → HELP) | right stick | right stick | `look_up/down/left/right` (new, pad only) |
| Jump; two quick presses: fly up (as JUMP) | Cross | A | `jump` |
| Break a block (attack with a weapon in the hand) | R2 | RT | `break` |
| Place a block; open a door, a chest, Tilly's shop, talk to a quest giver, pet (as a right click or a tap) | L2 | LT | `place` |
| Pick a block: the hotbar's slot before / after | L1 / R1 | LB / RB | `hotbar_prev` / `hotbar_next` (new) |
| Attack (hold: draw the bow) | Square | X | `attack` |
| Walk, fly or ghost | Triangle | Y | `physics_mode` |
| Fly up / down (and swim up / down) | D-pad up / down | D-pad up / down | `fly_up` / `fly_down` |
| All the blocks (the palette) | D-pad left | D-pad left | `blocks` (new) |
| MORE: map, photo, camera, size, mirror, undo, the Lab, emotes | D-pad right | D-pad right | `more` (new) |
| Crouch (held in water: dive) | Circle | B | `crouch` |
| Camera (first / third person) | R3 | RS | `camera_toggle` |
| Size magic | L3 | LS | `size_mode` |
| MY MAP (opens and closes) | touchpad (Create too) | View | `map` (new) |
| Menu (pause) | Options | Menu | `pause` |
| **In menus:** move the focus / press / back | D-pad or left stick / Cross / Circle | D-pad or left stick / A / B | PadFocus (ui_accept has Cross / A) |
| **In menus:** a panel's pages | L1 / R1 | LB / RB | PadFocus (a TabBar) |

The table is `GamepadRules.BINDINGS` (`core/platform/gamepad_rules.gd`); `tools/setup_input_map.gd` writes its events into
`project.godot` beside the keys (`device -1`: every pad), and `test_pad_input_map.gd` checks the input map has every one.

## What a child can do with a controller

- **Start:** on the loading page any pad button presses PLAY (a TV's browser with only a pad). In the menu the first
  press shows a yellow ring on the first big button (never BACK), the D-pad or the left stick moves it, Cross / A
  presses, Circle / B goes back one screen; on the first screen Circle / B never quits the game.
- **Every menu screen:** SANDBOX, SURVIVOR, MONSTER WAVE, PLAY ONLINE, the School, AVATAR, SETTINGS (all three pages:
  the page buttons, toggles, sliders that slide with left and right, the new Controller look), the codes, the world
  cards. Typing a name or a code needs a keyboard (a phone's own keyboard opens when the box has the focus).
- **The School:** the grade, the map, units, lessons, rounds; every answer that is buttons, plus the two drawn ones: the
  coordinate grid and the build board get a cursor the D-pad moves (Cross / A picks a point or places / takes a block);
  Circle / B is the page's BACK.
- **Playing:** everything in the table. The crosshair shows and aims (as with a captured mouse); on a PC the arrow
  hides while the pad plays (a click takes it back); on a phone the touch buttons hide while the pad plays (a finger on
  the screen brings them back).
- **The world's panels:** the pause menu (RESUME first; Circle / B resumes; SETTINGS inside with its BACK; CONTROLLER
  beside BOARD shows the card), the palette (a block first; L1 / R1 or the page row turn pages), MORE (its picture
  buttons, now also on a PC for the pad), Tilly's shop, the Secret Book, riddles, the Totem, a course, the arena's
  result, the Gold Farm, the pet's card, SHARE and bottles, Build-and-Wear, the Science Lab, photo mode's buttons, the
  quest book and card, a player's card, the trade ask and window, the portal hub, MY MAP, the CONTROLLER card, the
  Mission Board (its three pages, CHOOSE, BUY, LAUNCH; Circle / B is its X), MOVE BUTTONS' own buttons.
- **The menu's newer screens** (they are the menu's, so they work by themselves): the Gold Shop (its shelves, PREVIOUS /
  NEXT, HOW TO EARN; Circle / B is its BACK), INVITE A FRIEND and its news card (a code is typed with a keyboard or the
  phone's own).
- **The Theater (EasyCraft TV):** inside the building its screen has the pad: the D-pad picks a channel tab, a video
  card, NEXT and BACK (the video before), Cross / A plays; Circle / B stops a playing video (CLOSE), then leaves (EXIT),
  and the child walks on (walking out and in again brings the screen back).
- **Space:** the Star Map starts the focus on the planet the child flew up from; the D-pad goes from body to body (they
  keep moving); Cross / A opens a body's card with LAND / HOME and MAP; Circle / B closes the card (back on that body),
  then the map. The planet guide's LET'S GO has the focus (Circle / B goes too).
- **Hints:** the KEYS card is the CONTROLLER card while a pad plays: the pad's own words (Cross, R2, Touchpad; A, RT,
  View) by its name, the face buttons drawn in their colours and shapes; it comes once by itself the first time a pad
  plays in a world, and from the pause menu after. It follows the hands (a key makes it the KEYS card again).
- **A browser that cannot run the game** (no WebGL 2 or WebAssembly: a PlayStation's, an old TV's) shows: "This browser
  can't run EasyCraft yet. Try Chrome, Edge, Firefox or Safari on a computer, tablet or phone. A PlayStation or Xbox
  controller works there too!" (and, small, what is missing), instead of a loading screen that never ends.

## How it works (general means, for every screen)

- **`GamepadRules`** (pure): the table, the words (`family(name)`: PlayStation by "DualSense", "DualShock", "PS4/PS5",
  "Sony", "054c", or a bare "Wireless Controller"; Xbox by "Xbox", "XInput", "045e"; anything else gets the Xbox
  letters), the look (`look_step`), which hands played last (`device_of`), and the focus rules: `first_focus` (a panel's
  `pad_first`, else the first big button in reading order that is not BACK nor a row of pages), `next_focus` (the
  nearest control ahead, one in line before one off to the side, no wrapping), `stick_direction` (a step past 0.6, let
  go under 0.35), `Repeat` (a held direction steps again after 0.42 s, then every 0.14 s), `is_back_word` (BACK, CLOSE,
  X, CANCEL, NOT NOW; never DONE).
- **`PadFocus`** (`ui/help/pad_focus.gd`, one per game from `main.gd`): `PadFocus.watch(panel)` (the panel has the pad
  whenever it shows; the newest shown wins; closed, the one under it gets the pad back where the child left it) and
  `PadFocus.take(panel, first)` (a card that just opened). New content inside a panel (the menu's screens, the School's
  pages) gets the focus by itself. Circle / B: the nearest `pad_back()` from the focus up, else the panel's
  BACK / CLOSE / X / CANCEL / NOT NOW button (or meta `pad_back`), else the game's Back (Android's: every screen already
  answers it). Buttons made unfocusable for the mouse (FOCUS_NONE) take the pad's focus and go back to FOCUS_NONE when
  the mouse, a finger or the keyboard comes back (no hidden focus left for Space to press). A drawn control takes part
  with `pad_move(dir) -> bool` and `pad_press() -> bool`. Controls: Buttons (not those the mouse passes through: a
  picture), TouchButtons (`pad_press`), sliders, a row of pages (TabBar), text boxes.
- **The world's inputs** (`GamepadRules.world_actions`) leave the input map while a panel has the pad and come back when
  it closes (and when PadFocus leaves the tree): Cross / A never jumps behind a menu, the stick never walks. Options,
  the map button and Cross / A (ui_accept) stay.
- **Triggers** send many small moves; PadFocus lets one press and one release per squeeze through (the actions' dead
  zone is 0.5), so R2 breaks one block per squeeze.
- **The ring** (`PadFocus.PadRing`, `UiKit.focus_ring()` / `focus_shadow()`): a thick yellow rounded frame with a dark
  edge, over everything (layer 126), round the focused control, pulsing gently (still with Reduce motion), only while a
  pad is used. The theme's own focus stays empty: the mouse and fingers never see a ring.

## Rulings (each with what it costs if wrong)

1. **The class is `GamepadRules` in `core/platform/gamepad_rules.gd`**, not `PadRules` (the brief's name): `PadRules`
   is the jump pads' class. Cost: none.
2. **Circle / B crouches while playing and goes back in menus** (a panel with no BACK button: the phone's Back). The
   menus' back is the familiar one; while playing, B next to A is where console games crouch. Cost if wrong: a child
   who presses B to "go back" while playing crouches (harmless; Options pauses). Change: `crouch` to R3 in BINDINGS.
3. **Triangle / Y is WALK / FLY / GHOST; the D-pad's up and down fly up and down** (the brief's "Triangle/Y flies up
   or down with the D-pad"). Two quick Cross presses take off, as JUMP does.
4. **The D-pad's left opens every block (the palette) and its right the MORE panel**; undo, mirror, photo, the map's
   button and emotes live in MORE (two presses). MORE's picture buttons (SIZE, CAM, UNDO, MIRROR, LAB), hidden on a PC
   (the keys have them), show there while a pad plays. Cost: undo is two presses away.
5. **L3 is Size magic, R3 the camera.** Cost: few children press the sticks; both are in MORE too.
6. **The map is the PlayStation's touchpad and Create / Share, the Xbox's View (Select on other pads).** A browser's
   standard mapping has no touchpad button, so there it is Create. Cost: none.
7. **L2 places and uses** (doors, chests, Tilly, quest givers, pets: what a right click or a tap does, the same
   `place_at_screen`). R2 breaks (with a weapon: attacks). Cost: none (the PC's mouse does the same).
8. **L1 / R1 select a hotbar slot without drinking a potion** (a number key or a tap on the slot drinks). Cost: a pad
   player cannot drink a potion yet (Survivor): the lead's list below.
9. **One break or place per trigger squeeze**, no hold-to-repeat (as mouse clicks). Cost: many blocks, many squeezes.
10. **The look:** 2.6 rad/s (about 150° a second) at full tilt, up and down 75 % of that, a dead middle of 0.12, a
    squared curve (small tilts aim slowly); SLOW × 0.6, FAST × 1.5; no invert-Y. Cost: some children want inverted
    looking up and down (a setting to add), or faster turns (FAST).
11. **The last input decides "pad"**: a pad's press or push (past 0.5) turns it on; a key, a click or a finger turns it
    off; **the mouse moving never does** (a PlayStation pad's touchpad is a mouse on Android). Cost: on a PC a child who
    only moves the mouse (no click) keeps the pad's crosshair and hidden arrow until a click or a key.
12. **The press that wakes the pad in a menu only shows the ring** (it never presses something unseen). Cost: one extra
    press at the first menu.
13. **No wrapping** at a panel's edge: the focus stays, the child sees where it is. Cost: none.
14. **A panel sets the world's pad inputs aside by editing the input map at run time** (restored on close and when
    PadFocus leaves). Cost: none while nothing saves the input map at run time (nothing does).
15. **The ring is PadFocus's own overlay** (layer 126), not the theme's focus stylebox: every screen gets the same ring
    whatever its own styles (the palette, the books and the trade window set their focus to nothing), the unmerged
    screens too. Cost: a control on a layer above 126 (none today) would be drawn over the ring.
16. **The CONTROLLER card shows once by itself** (`settings.pad_seen`, the first time a pad plays in a world), then
    from the pause menu's CONTROLLER (KEYS on a PC without a pad). The pause menu's third row holds BOARD, INVITE and
    it (smaller words when three). Cost: none.
17. **Circle / B on the menu's first screen never quits** (`PadFocus.back_from_pad`); Android's Back still does.
18. **PlayStation or Xbox by the pad's name; everything else gets the Xbox letters.** Cost: a Switch Pro controller's
    card says A where its own label is B (the ring still shows which button a menu wants).
19. **Rows of pages (TabBar) are focus stops whose left and right turn the pages**; the first focus never goes there
    (it goes to a block, not the palette's page row). L1 / R1 turn them from anywhere in the panel.
20. **The kind page checks WebGL 2 and WebAssembly before the engine's script**, in old-browser JavaScript; when the
    engine's script never comes (or cannot be read) it says "Missing: a newer browser". English only (#52).
21. **A pad's button presses the loading page's PLAY.** Some browsers keep the sound off until a tap, a click or a key
    (a pad press is not a "user gesture" everywhere). Cost: a pad-only TV may start silent.
22. **The Theater's screen is watched** (inside the building it is the Theater: owner #89's panel opens when the child
    walks in): the pad picks and plays videos there instead of walking; Circle / B stops a video (CLOSE), then EXIT (marked
    `pad_back` from the sandbox, `pad_theater`, because its "BACK" is the video before) gives the walking back. Cost if
    wrong: a child with a pad who walks in by accident needs one Circle / B to walk on.
23. **Not pad-driven (yet):** typing (the chat, names, codes: a keyboard or the phone's own), the emote wheel and the
    quick-chat wheel (fingers), MOVE BUTTONS (fingers: it arranges touch buttons), photo mode's camera (turn and zoom:
    fingers or the mouse; its buttons are pad-driven), rides (Y key) and co-op HELP UP / GET UP (H / G keys), SLEEP by
    a bed, the HUD's BOOK button, drinking a potion. The lead's list below.

## Files

New: `core/platform/gamepad_rules.gd`, `ui/help/pad_focus.gd`, `ui/help/pad_glyph.gd`, `tools/web_kind_page_check.mjs`,
tests `tests/unit/test_pad_gamepad_rules.gd`, `tests/integration/test_pad_{input_map,focus,screens,menu,player,card,web_page}.gd`.
Small additions: `project.godot` (the input map: joypad events and the new pad-only actions; `break` / `place` dead
zone 0.5; `ui_accept` + Cross / A), `tools/setup_input_map.gd`, `scenes/main.gd` (install), `ui/menus/menu.gd` (watch; B
never quits), `ui/menus/pause_menu.gd` (watch, `pad_back`, KEYS / CONTROLLER), `ui/menus/settings_panel.gd` (Controller
look: SLOW / NORMAL / FAST on the HELP page's Lessons row; MOVE BUTTONS takes the pad's focus), `core/save/profile_data.gd` (`pad_seen`, `pad_look`), `ui/help/keys_card.gd` (the CONTROLLER card),
`ui/theme/ui_kit.gd` (the ring's look), `ui/controls/touch_button.gd` (`pad_press`), `ui/hud/hud.gd` (`set_pad`),
`entities/player/player.gd` (the right stick), `scenes/sandbox.gd` (the panels watched, L1 / R1, the palette, MORE, the
map, the crosshair, the arrow, the card), `ui/space/space_panel.gd` (watch, `here_body`, `pad_back`),
`ui/space/planet_guide_card.gd` (take, `pad_back`), `ui/school/grid_answer.gd` and `ui/school/build_board.gd` (the
cursor), `web/shell.html` (the kind page, a pad presses PLAY, a tip).

## Tests

`tests/unit/test_pad_gamepad_rules.gd` (23: the table, the families and words, the card's lines, which hands, the
look's maths and the camera's direction, the focus rules, the stick's steps and repeats, BACK words),
`test_pad_input_map.gd` (5), `test_pad_focus.gd` (19: waking, first focus, the D-pad and stick, containment, Cross,
Circle three ways, the world's inputs set aside and given back, mouse-only buttons, the newest panel and memory, new
content, pages, sliders, a drawn control, triggers, hidden focus), `test_pad_screens.gd` (15: every SETTINGS page and
the pause menu reachable, sliders, the pause menu's Circle and CONTROLLER card, the School's pages and Circle, a build
answer with the D-pad, the Star Map and a body's card, the planet guide, the palette, MORE, the HUD on a phone and a
PC, the Mission Board, the Gold Shop, the Theater), `test_pad_menu.gd` (3: the real main menu), `test_pad_player.gd` (4: a real Player's right stick, the look set
aside, the hotbar's steps, a phone's HUD), `test_pad_card.gd` (7), `test_pad_web_page.gd` (3). All pass. In a real
headless Chromium: `PW_HOME=~/src/pwenv node tools/web_kind_page_check.mjs` → 4 PASS (everything there: no kind page;
no WebGL (`--disable-3d-apis`), no WebAssembly, no engine script: the kind page with what is missing).

**The full suite** (`tests/run_tests.sh`, 2026-09-30, on `lead-merge` a2979233 with this branch): 869 scripts, 7,996
tests, **7,994 passing, 0 failing**, 2 risky that never assert (`test_the_column_cache_changes_nothing`,
`test_chunks_meet_without_seams`: the voxel benches, as before), no script errors. The run before it found SETTINGS'
HELP page 797 px tall: the friend's code row (#79, merged meanwhile) and the Controller look's own row did not both
fit; the Controller look moved onto the Lessons row (705 px), and `test_pad_card.gd` now measures the page as the menu
shows it (UiKit's theme in a panel).

## The screens that were not merged when this started

The missions, earn + invite + the Gold Shop and the TV shows were merged into `lead-merge` while this was built; the
branch was rebased onto them and they are wired now (tests in `test_pad_screens.gd`):
- **The Mission Board:** watched (`_setup_pad`); a mission's CHOOSE, the pages, BUY, LAUNCH by the D-pad; Circle / B is
  its X; it waits (its own rule) until the child walks away and back. `test_the_mission_board_s_pages_can_be_reached_and_circle_closes_it`.
- **The Gold Shop, INVITE A FRIEND, the invite news card:** screens of the menu (`_show`), so the menu's watch covers
  them with no change. `test_the_gold_shop_can_be_reached_and_circle_goes_back`.
- **The Theater's panel:** watched, EXIT as its back button (`pad_theater`). `test_the_theater_s_screen_and_circle_leaves`.

**Still to come: the rocket flight** (`entities/flight`, `ui/flight`, not merged): what it needs is below, with the
recipe. What the merged screens could still do better: the Mission Board's page buttons could take L1 / R1 (they are
toggle buttons, not a TabBar: the D-pad reaches them); the Theater's tabs likewise.

The recipe for any screen: **one line** where it is made, `PadFocus.watch(panel)` (a panel that shows and hides with
`visible`) or `PadFocus.take(card, first)` (a card made when it opens); its close button says BACK, CLOSE, X, CANCEL or
NOT NOW (or has meta `pad_back`), or it has `pad_back() -> bool`; a button the child should start on has meta
`pad_first`; a drawn control (a map, a picture to pick from) has `pad_move(dir) -> bool` and `pad_press() -> bool`;
anything the child does while playing that is only a touch button needs an input action with a pad event in
`GamepadRules.BINDINGS` (then `godot --headless --path . --script res://tools/setup_input_map.gd`). Never watch a panel
that shows while the child plays (it sets the pad's walking aside).

- **The rocket flight (`entities/flight`, `ui/flight`):** its steering and boost must be input actions (not only touch
  buttons) with pad events in BINDINGS: the left stick steers (the `move_*` actions, or its own actions on the left
  stick's axes), Cross / A boosts or fires, R2 / L2 throttle if it has one, Options pauses; a flight is playing (never
  watched). Its screens (the countdown, choose a destination, the landing card, the mission's result) get
  `PadFocus.take(card, first)` when they open; the landing's LET'S GO gets `pad_first`.
- **Anything new in earn + invite that opens over the world** (not through the menu): `PadFocus.watch(panel)`; a buy's
  "Are you sure?" card `PadFocus.take(card, no_button)` (the safe answer first).

## What the lead must check with a real controller

On the PC (Chrome and Firefox, a DualSense or DualShock and an Xbox pad, USB and Bluetooth; `tools/web_serve.py` build or
the desktop game):
1. The loading page: a pad button presses PLAY; the menu's first press shows the ring on SANDBOX (PLAY for a new
   player); the stick and the D-pad move one step per push, repeating when held; Cross / A presses; Circle / B back;
   Circle / B on the first screen does nothing.
2. The pad's name gives the right words: the CONTROLLER card says Cross / R2 / Touchpad for a PlayStation pad, A / RT /
   View for an Xbox pad (print `Input.get_joy_name(0)` if not: `GamepadRules.family` may need the name added).
3. In a world: every row of the button table. Especially: the right stick's direction (not upside down), its speed at
   NORMAL, no drift when let go (the dead zone 0.12); R2 breaks once per squeeze; L2 opens a door, Tilly's shop, a chest;
   the triggers' axes arrive as axes (a pad that reports them as buttons would need BINDINGS extra button events);
   Circle crouches; a double Cross takes off; the crosshair shows and the arrow hides.
4. The menus in a world: the pause menu (RESUME first, Circle resumes, CONTROLLER card), the palette (a block first,
   L1 / R1 pages, Circle closes), MORE (D-pad right, the picture buttons, Circle closes), the shop's X, the Star Map
   (the moving bodies, a card's LAND and MAP, Circle twice), Mercury's guide, MY MAP (the touchpad / View opens and
   closes it), the Mission Board at the Launch Site (walk up, D-pad, Circle; it stays shut until the child walks away),
   the Theater (walk in: the screen has the pad; a video plays by Cross / A; Circle stops it, Circle again leaves, then
   walk out; on a phone and in a browser the video player is a native view or a page element over the game: check the
   ring round its buttons is not hidden under it).
5. Switching hands: a click or a key takes the ring and the arrow away and Space never presses a button the pad left
   focused; the pad again brings them back; the KEYS card turns into the CONTROLLER card and back.
6. The kind page: open the live link in a PS5's or PS4's browser (or `chrome --disable-3d-apis`): the kind words.

On the emulator (`Pixel_8_API_35`; its Chrome gets no pad, so the app): the menus by the emulator's own gamepad key
events, e.g. `ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554 ~/android-sdk/platform-tools/adb shell input
gamepad keyevent KEYCODE_BUTTON_A` (and `KEYCODE_DPAD_DOWN`, `KEYCODE_BUTTON_B`, `KEYCODE_BUTTON_R1`,
`KEYCODE_BUTTON_START`): the ring, the steps, Cross, Circle; the touch buttons hide after a pad key and come back with a
tap; Circle / B must not also send Android's own Back (Godot handles the pad's keys; if the game both goes back and
crouches or leaves twice, that is the sign). The sticks and triggers need a real phone with a pad (the owner's check):
walking, looking, breaking, and a DualSense's touchpad (a mouse on Android) must never take the game away from the pad.
