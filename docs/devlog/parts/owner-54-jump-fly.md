# Owner feedback #54: a double tap on JUMP flies, tapping on opens the parachute

The owner (2026-09-28, playing the browser version on an iPhone, touch HUD): "when i click on up multyply times like
4-5-6 it should start flying with parashute as it uses but when i click same time on up it should go up and start
flying. run agent to fix this". Built in a worktree from `lead-merge` (`6535ebf`, which logs #54 and has the web
work); no editor, emulator, browser or godot-mcp use. Spec §3b (the ruling), §5.4 (a pointer).

## What the owner meant (the ruling)

"Up" is the touch HUD's JUMP button (it shows UP while flying or swimming). "Click multiple times" is tapping on;
"click same time" is two taps close together, a double tap. So:

1. **Two quick taps, then a pause = take off flying** (the Sandbox), like the FLY button, with a clear little lift.
2. **Tapping on (4, 5, 6 taps) = the jumps, then the parachute**, as the game already does. Keep it.

Numbers: the second tap within **0.35 s** of the first, and no third within 0.35 s after it (Minecraft's double-tap
window is 7 ticks = 0.35 s; a phone's double-tap timeout is about 0.3 s; a child's thumb is slower, so the upper
end). The take-off adds **0.25 s** of rising (about 2 blocks) before hovering.

Rulings (each with what it costs if wrong; also in spec §3b):
- **R1. The pause decides.** Both rules start with the same two taps, so the game cannot know at the second tap
  which one the child means. The two taps jump at once (the ground jump and an air jump: the child goes up straight
  away, which is the "go up"), and the take-off waits 0.35 s after the second tap for a third. A third within
  0.35 s makes it "tapping on". *Cost if wrong:* the flight begins about a third of a second after the second tap
  (the body is at the top of the double jump then, so it reads as one move: up, up, hover).
- **R2. Only where flying is free (the Sandbox).** Survivor pays gold for flying (10 gold a minute, M2 Task 7) and
  its double jump is a skill the child earns; Monster Wave has no flying at all. A double tap there stays a double
  jump and never spends gold or shows "You need gold to fly!". *Cost if wrong:* one rule, `JumpTaps.counts`.
- **R3. Tapping on never flies.** A row of taps goes on through a glide and its landing (a tap under the canopy
  spoils the row), so six steady taps with Jumps DOUBLE (glide, land, two more taps) do not take off. Taps never
  count while flying already (JUMP is UP: hold to climb), a ghost or in zero-G, swimming (JUMP swims up), on a
  zipline or the hook, or under the glider.
- **R4. A moment the body did not move forgets the taps** (asleep, riding, hidden in a barrel, knocked out, not
  spawned): two taps and then RIDE or SLEEP never take off later.
- **R5. The way back to walking stays** the FLY button (FLY → GHOST → WALK), F, `/walk`. A double tap while flying
  that lands again (Minecraft) was not asked for and would drop children who tap UP twice to climb. *Cost if
  wrong:* a small addition in `Player._jump_taps_step`.
- **R6. The glider is unchanged.** It still opens at the first tap after the last air jump once there are 3 blocks
  of air below (GLIDE_MIN_AIR). Checked at 0.15 s and 0.25 s rhythms: 4, 5 and 6 taps all open it (Jumps TRIPLE: at
  the 4th tap; DOUBLE: the 3rd).

## What the code did before (measured on a real Player, headless, Jolt)

A scratch test tapped JUMP n times (each press one physics frame) on a real Player on a stone floor, Sandbox, and
recorded the jumps, the glider and the physics switch. Before the change (taps 0.30 s and 0.50 s apart):

| Taps | Jumps TRIPLE (default) | Jumps DOUBLE |
|---|---|---|
| 1 | one jump (1.8 blocks) | one jump |
| 2 | double jump (3.0 blocks), lands walking | double jump, lands walking |
| 3 | triple jump (4.1–4.5 blocks) | double jump, then the glider |
| 4 | triple jump, then the glider at tap 4 | glider at tap 3; tap 4 does nothing |
| 5, 6 | the glider at tap 4; taps under the canopy do nothing | the same; at a slow rhythm the glide lands first and taps 5–6 jump again |

The WALK/FLY switch never moved: flying needed the FLY button (or F, `/fly`). So the owner's "4-5-6 taps →
parachute" already held; "two taps → fly" did not (it was a double jump).

## What it does now

Only two quick taps changed (taps 0.15 s and 0.30 s apart; the rest of the table is the same as before):

| Taps | Now |
|---|---|
| 2 quick (≤ 0.35 s), Sandbox | double jump, then take-off: FLY, hovering 4.9–5.4 blocks up; WALK button says FLY, JUMP says UP, DOWN shows |
| 2 quick, Survivor or Monster Wave | double jump, as before; no gold spent |
| 2 slow (0.45 s) | double jump, as before |
| 1, 3, 4, 5, 6 | as before (one jump; the triple jump; the jumps, then the parachute) |

## Code

- `core/rules/jump_taps.gd` (`JumpTaps`, new): the rows of taps, `DOUBLE_TAP_TIME` 0.35, `TAKE_OFF_LIFT` 0.25,
  `counts()` (free flying, walking, not swimming, no gadget).
- `entities/player/player.gd`: `_jump_taps_step(delta)` runs every moving frame before the gadgets (real time, not
  the Physics Lab's slow motion) and calls `take_off()` (`set_physics_mode(FLY)`, the lift, a whoosh); `_move_flying`
  holds UP while the lift lasts. The jumps (`JumpCounter`) and the glider (`_gadget_idle`) hear the same taps as
  before.
- The touch JUMP button (`TouchButton`, action `jump`) and Space press the same action, so both go through one path;
  nothing changed in the HUD (its WALK/FLY word, UP and DOWN follow `physics_mode_changed` as with the FLY button).

## Tests (RED first, then GREEN)

- `tests/unit/test_jump_taps.gd` (16): e.g. `test_two_quick_taps_then_a_pause_take_off_once`,
  `test_the_take_off_waits_for_the_pause_after_the_second_tap`, `test_a_slow_second_tap_is_no_double_tap`,
  `test_three_four_five_and_six_quick_taps_never_take_off`, `test_the_taps_go_on_through_frames_where_they_do_not_count`,
  `test_taps_count_only_where_flying_is_free_and_the_body_walks`. RED: `JumpTaps` did not exist.
- `tests/integration/test_jump_taps_player.gd` (12), a real Player: `test_two_quick_taps_lift_the_player_up_and_start_flying`,
  `test_two_quick_taps_fly_with_the_double_jump_setting_too`, `test_a_slower_double_tap_three_tenths_of_a_second_apart_still_flies`,
  `test_holding_jump_while_flying_goes_up_and_the_switch_walks_again`, and the ones that keep the old behaviour:
  `test_one_tap_is_one_jump`, `test_three_quick_taps_are_the_triple_jump`,
  `test_four_five_and_six_quick_taps_open_the_glider_as_before` (both jump settings, 0.15 s and 0.25 s),
  `test_three_quick_taps_with_the_double_jump_setting_open_the_glider`, `test_a_slow_second_tap_is_a_double_jump`,
  `test_survivor_and_monster_wave_keep_the_double_jump`, `test_the_glider_keeps_its_taps_in_the_air`,
  `test_two_quick_taps_then_a_nap_never_take_off_later`. RED on the old code: the four flying tests (never FLY);
  the nap test went RED on the first version without R4, then GREEN.
- `tests/integration/test_jump_taps_hud.gd` (2): `test_two_quick_taps_on_the_touch_jump_button_take_off` (touches
  pushed into the HUD's JUMP in a 1280 × 720 SubViewport) and `test_two_quick_presses_of_space_take_off_the_same_way`
  (key events through `Input.parse_input_event`): FLY, the WALK button says FLY, JUMP says UP, DOWN shows. A
  mutation check (the take-off switched off) made both fail on every assertion.
- No existing test encoded the old two-tap behaviour; none was changed. The autopilot's and the tutorial smoke's
  "triple jump" (three taps 0.25–0.27 s apart) is a row of three: it never takes off.
- Full suite (`tests/run_tests.sh` on `c758603`): **6128 passing, 1 failing, 2 risky** (the two that never assert).
  The failure is not from this change and was already on `lead-merge` (`6535ebf`): `tests/unit/test_boot_splash.gd`
  `test_every_android_preset_carries_the_splash` wants `export_filter="all_resources"` in every preset, and M7's
  "Web Music" pack preset (`[preset.8]`, `export_filter="resources"`) exports only the music on purpose. Left for the
  lead (the web work's owner): the test should look at Android presets only, as its name says.

Gotcha found (now in `docs/DEVELOPMENT.md` §8): GUT's `wait_physics_frames(1)` resumed two physics frames later, so a
tap rhythm written with it was twice as slow as meant; the tap tests await `get_tree().physics_frame` per frame.

## For the lead to check by hand (emulator touch, and the browser on a phone)

1. Sandbox, on the ground: tap JUMP twice quickly. The child jumps twice, rises a little more with a whoosh and
   hovers; the WALK button says FLY; JUMP says UP (hold it: climbs), DOWN descends. FLY → GHOST → WALK walks again.
2. Tap JUMP 4, 5, 6 times at a steady rhythm: the jumps, then the parachute opens (no flying), and it closes on
   landing. With Jumps DOUBLE in SETTINGS: the parachute at the 3rd tap.
3. Two taps with a slow second tap (about half a second): a plain double jump.
4. Survivor: two quick taps are a double jump; no "You need gold to fly!" and no gold spent.
5. The tutorial's jump lesson ("tap JUMP three times!") is unchanged: the tutorial plays in Survivor
   (`TutorialRules.plays_here`), where a double tap stays a double jump.
6. In the browser on a phone: two quick taps on JUMP never zoom the page (`web/shell.html` has
   `touch-action: none` on the canvas and `user-scalable=no`), and fly as on Android.
