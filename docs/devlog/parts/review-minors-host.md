# Review minors on the host: M1, M6, M9, M10 (2026-09-24)

Four deferred minors from the M1b whole-branch review (Task 15), listed in `docs/DEVELOPMENT.md` §9.
Built in a worktree cut from `m1b-underground` (`e83c3c9`) while the lead measured on the emulator.
No godot run happened while the lead's quiet lock (`QUIET_EMULATOR_MEASURING`) was in place, and no
editor or emulator was used. The lead merges.
Each fix is test-first (RED for the right reason, then GREEN) and has its own commit. The full suite
ran green before each commit.

Suite before: 513 tests, all passing (the run with only the new M1 tests added showed 518, 517 passing).

## M1: the bedrock check failed open

**Problem.** `PlacementRules.validate_edit` and `refusal` took the cell's current block as their
last argument, with a default of AIR. Both `Session` callers passed `world.get_block(pos)`, but a
future caller that forgot it would have let players break or replace bedrock. There were also no
host-level tests for bedrock through batches, stamps or the mirror.

**Fix.** `current_id` is now a required argument, right after `id`:
`validate_edit(block_pos, id, current_id, requester_eye, player_aabbs, reach = REACH + REACH_TOLERANCE)`,
and the same for `refusal`. A caller that forgets it now gets a compile error ("too few arguments"),
and the old argument order is a type error (a `Vector3` where an `int` goes), so the check fails
closed. `Session._host_apply` and `_host_apply_batch` were updated. The tap path no longer spells out
the default reach.

**Tests.**
- `tests/unit/test_placement_rules.gd` `test_the_current_block_is_a_required_argument`: reads both
  methods' argument lists (`get_script_method_list`) and checks that `current_id` has no default.
  RED: `current_id` was argument 5 of 6 with 4 required ("[5] expected to be between [0] and [3]",
  for both methods). GREEN after the change. The 12 existing calls in that file were updated (break
  tests pass the block being broken, place tests pass AIR).
- New `tests/integration/test_host_edits.gd`: host-level tests through `Session` in solo play
  (OfflineMultiplayerPeer, so this game is the host), on a real unsaved world and a real Player
  whose `BlockInteractor` sends the edits, as in the game:
  - `test_a_tap_never_breaks_or_replaces_bedrock`: `request_set_block` refuses break and replace,
    emits `edit_rejected` twice and tells the player "Bedrock can't be broken!".
  - `test_a_batch_skips_bedrock_and_applies_the_rest`: `request_set_blocks` applies the brick and
    skips the bedrock; a batch of only bedrock edits returns false.
  - `test_a_stamp_on_bedrock_keeps_the_bedrock_and_builds_the_rest`: a House stamp whose planks
    floor lands on 49 bedrock cells keeps all 49 and builds every other stamp block.
  - `test_a_mirror_copy_never_lands_on_bedrock`: Mirror mode on; the tapped cell gets its brick,
    the mirror copy on bedrock is refused.

  These four pass on the old code, because `Session` already passed the current block. To prove
  they catch the bug they guard, I removed the `world.get_block(pos)` argument from both `Session`
  calls (so the old default of AIR applied) and ran them: all 4 failed for the right reason
  (bedrock, id 18, became 0, 3 or 9; all 49 stamp floor cells were replaced; no `edit_rejected`,
  no message). Then I restored `Session`.

**Rulings.**
1. **`current_id` goes before the optional reach, and reach keeps its default.** A missing reach
   falls back to the tap reach, which is the smaller one, so it fails closed. A missing current block
   failed open, so only that one had to become required. Cost if wrong: none at run time; a caller
   that wants a batch reach still has to pass it, as before.
2. **The host tests put bedrock in the air above the spawn column** instead of streaming the real
   floor at y −64. The host check reads whatever block is in the cell, so the height doesn't matter,
   and the test stays fast (one world load for the whole script, in `before_all`). Cost if wrong: a
   bug that only happens at the real floor (y −64…−61) would be missed. Nothing in `Session` or
   `PlacementRules` depends on y.

## M6: a late joiner silently cancelled the sleep skip

**Problem.** When every player sleeps, the host counts down `SKIP_DELAY` (2.5 s) and then skips
the clock. A player who joined during the countdown is awake, so at its end `_process_skip` found
not everyone asleep and simply returned. The sleepers kept lying there and were never told why.

**Why the obvious fix was not enough.** The sandbox connects `Session.client_ready` for spawning
the joiner's body *after* `SleepDirector` has connected its own handler (`_setup_local_player()`
runs before the `client_ready` hookup in `sandbox.gd` `_start_host_or_solo`). So when the director
hears `client_ready`, the joiner's body is not in the tree yet, and a plain `_check_all_asleep()`
there still finds everyone asleep. I tried exactly that: the new test still failed (nobody told).

**Fix** (`world/sleep_director.gd`).
- `_check_all_asleep(leaving, joining)` takes the joining peer and counts it even before its body
  exists (no double count once it does). `_on_client_ready` calls it with the joiner, so a running
  countdown stops and every sleeper gets "Zzz... 2 of 3 asleep. Everybody sleeps in a bed to skip
  ahead!" at once.
- `_process_skip` no longer gives up silently. If the countdown ends and not everyone is asleep,
  it calls `_check_all_asleep()`, which tells the sleepers the count. That covers any other way the
  set of players might change without a check.

**Tests** (`tests/integration/test_sleep_director.gd`, fake peers 2, 3 and 4 as before). A small
`TellingDirector` subclass records what `_tell` would send, since fake peers have no connection.
- `test_a_late_joiner_stops_the_skip_and_the_sleepers_are_told`: peers 2 and 3 sleep, the
  countdown runs, then `client_ready(4)` fires *before* peer 4's body is added (the real order).
  RED: "[0] expected to equal [2]: both sleepers hear it" (the old code stopped the skip silently).
  It was still RED with the plain `_check_all_asleep()` call. GREEN with the joiner counted.
- `test_a_skip_that_cannot_happen_tells_the_sleepers`: a body appears without `client_ready` and the
  countdown runs out. RED: nobody told. GREEN: both sleepers hear "2 of 3 asleep".

**Rulings.**
3. **The joiner is counted by id instead of deferring the check to the next frame.** A deferred
   call would also see the body, but only if the sandbox adds it in the same frame, and tests would
   have to wait frames. Counting the id is order-independent, and a repeated "ready" (the body
   already exists) is counted once. Cost if wrong: if a `client_ready` ever came without a body
   following it, the skip would stay stopped until someone lies down or gets up again (both check
   again). Today the sandbox always adds the body right after.
4. **The countdown's end also tells the sleepers** (a safety net for paths we don't know of).
   Cost if wrong: in a rare case the sleepers see one extra "N of M asleep" line.

## M9: the chat filter missed non-ASCII digits and letters (13+ free text)

**Problem.** The phone-number pattern only knew the ASCII digits 0–9, and words were split on
anything outside a–z. So "٥٥٥١٢٣٤" (Arabic-Indic), "５５５１２３４" (fullwidth), "fück", "shít",
"ｆｕｃｋ" or "ѕhit" (Cyrillic ѕ) all got through to other 13+ players.

**Fix** (`core/rules/chat_rules.gd`). `ChatRules.normalize(text)` makes a checking copy, and
`filter_code` runs every check (phone digits, email, links, contact phrases, words) on that copy.
The message that is delivered keeps its accents. `normalize` is table-driven and needs no library:
- Lower case.
- `DIGIT_ZEROS`: the zero of every run of ten Unicode decimal digits (category Nd). There are 75
  such runs besides ASCII in Unicode 16; the list was generated and checked with Python's
  `unicodedata` (every run is ten contiguous digits). Each of them reads as ASCII 0–9.
  `DIGIT_LOOKALIKES`: superscript, subscript and circled digits (⁰¹², ₀₁₂, ⓪①②).
- Fullwidth ASCII (U+FF01–FF5E) reads as ASCII, so "kid＠example．com" and "ｗｗｗ．example．com"
  are caught as email and link.
- `CHAR_FOLDS`: accented Latin letters (à→a, ü→u, ñ→n, ß→ss, æ→ae, œ→oe, þ→th), Greek and
  Cyrillic letters that look like Latin ones (Cyrillic а е о р с у х і ј ѕ һ ӏ, Greek α ε ι κ ο ρ τ
  υ χ, and the capitals that look Latin once lower-cased, like В→b, Н→h, Т→t), other spaces
  (no-break, thin, ideographic, …) as " " and dashes (en, em, minus, …) as "-", so "555 123–4"
  still counts as 7 digits. A capital listed in the table wins over its small letter: a capital
  eta Η looks like H, a small η like n.
- Combining accents (U+0300–036F) are dropped, so "u" + "¨" is "u".
- The map is built once, on first use.

**Tests** (`tests/unit/test_chat_rules.gd`; the phone cases avoid words like "call me" that the
contact-phrase check would already catch):
- `test_phone_numbers_in_any_digits_are_filtered`: fullwidth, Arabic-Indic, Persian, Devanagari,
  Thai, mixed ASCII + Arabic-Indic, maths bold, circled, and ASCII split by a no-break space and an
  en dash. RED: all 9 passed the filter (`[<null>] expected to equal ["personal_info"]`). GREEN.
- `test_fullwidth_emails_and_links_are_filtered`: RED for both (`[""]`). GREEN.
- `test_accented_and_look_alike_swears_are_filtered`: "fück this", "shít", "FÜCK", "you are
  stüpid", "ｆｕｃｋ", "fu" + combining ¨ + "ck", "ѕhit", "fuсk" (Cyrillic с), "ΙDIOT" (Greek
  capital iota) and "a l٠ser" (Arabic-Indic zero read as 0, then l33t as o). RED: all 10 passed
  (`[<null>] expected to equal ["blocked_word"]`). GREEN.
- Guards against over-filtering, green before and after: `test_a_few_digits_in_any_script_are_fine`
  ("I built ２５ towers", "level ٣ in ٢ minutes") and `test_accented_words_pass_and_keep_their_accents`
  ("naïve café", "über cool build", "piñata party", "ça va?", Greek and Russian greetings; "Café
  crème!" is delivered with its accents).

**Rulings.**
5. **Fold look-alike Greek and Cyrillic letters too, not only accents.** Swapping in a Cyrillic
   "с" or "ѕ" is the most common way round a word filter, and it costs a few table entries. Cost if
   wrong: a 13+ player typing real Greek or Russian could, rarely, have a message refused when the
   folded letters happen to spell a blocked English word ("That message isn't allowed. Try saying
   it another way!"). No such case turned up in the tests; the fix would be to drop the Greek and
   Cyrillic entries from `CHAR_FOLDS`.
6. **The table, not the engine, decides what a digit is.** GDScript has no Unicode digit test, and
   the owner wants no external libraries. The table is complete for Unicode 16. Cost if wrong: a
   digit script added in a later Unicode version would get through until its zero is added to
   `DIGIT_ZEROS`.
7. **Other spaces and dashes are folded too** (beyond the task's digits and letters), because a
   phone number split by a no-break space or an en dash was the next easy way round. Cost if
   wrong: none known; they only affect the checking copy.

## M10: melee hit through walls

**Problem.** `CombatDirector.resolve_melee` (host) checked reach and the swing's cone, but not
what lay between. A sword or hammer pushed players and animals (and hit dummies) behind a 1-block
wall.

**Fix** (`world/combat_director.gd`).
- `in_sight(from, to)`: a `GridRay` from the attacker's chest to the target's centre over the
  director's `block_at` (the host's world; tests inject their own). Solid blocks stop it; water and
  air never do (`BlockIds.is_solid`). The cell the swing starts in is skipped (GridRay already does
  that), and so is the target's own cell, so an animal standing on a half-height bed can still be hit.
- `resolve_melee` now keeps only the things in reach **and** in sight, and only then lets
  `WeaponRules.melee_hits` pick the targets. Filtering after the pick was not enough: something
  hidden could still take the axe's only hit, or pull the aim assist away from a target in the
  open. I tried that version first and the third test below stayed red. The reach pre-filter
  (`hit_in_reach`: reach + radius + 1.0) is the same distance within which `melee_hits` looks for
  targets at all, so nothing changes for targets in the open, and the grid rays stay short (a few
  cells each, only for things within about 5 m).

**Tests** (`tests/integration/test_weapons_in_world.gd`):
- `test_melee_never_hits_through_a_wall`: a stone wall between a hammer swing and a dummy, an
  animal and a player (this game's own, so its push shows up as `Session.knocked_back`). RED: all 3
  were hit ("[3] expected to equal [0]", the cow was pushed, the player was knocked back). GREEN:
  nothing is hit, and the same swing without the wall hits all three.
- `test_water_never_blocks_a_swing`: the same wall made of water; the dummy and the animal are hit
  (green before and after, a guard against blocking too much).
- `test_a_hidden_animal_never_steals_the_swing`: an axe swing (one hit, 30° cone) with an animal
  15° to the left behind a pillar and a dummy 20° to the right in the open. RED: the hidden animal
  was pushed and the dummy missed. With the filter after the pick, the animal was spared but the
  dummy was still missed. GREEN with the filter before the pick.

**Weapons smoke run** (`tools/weapons_smoke.gd`, headless, private `XDG_DATA_HOME`): on a real world
with this fix, "sword hit the dummy for 4" is ok, so the sight check doesn't block a clear swing.
One step fails: "boomerang hit the dummy once (hits 2)", meaning the boomerang missed the dummy.
That step fails the same way on the code *before* this fix (a fresh folder, same result), and the
boomerang's hit check (`_boomerang_hits`) was not touched. **Left for the lead:** the smoke run's
boomerang step is red on `m1b-underground` as it stands. (A second run in a folder the first run
had already used fails earlier, at "found a flat spot for a dummy", because it reuses the saved
world. Each smoke run needs a fresh folder.)

**Rulings.**
8. **A grid ray over the voxel data, not a physics ray.** The host streams the terrain around remote
   players without collision (`viewer.requires_collisions = false` in `Player._ready`), so a physics
   ray would miss walls near a guest. It would also only be safe during physics frames. The voxel
   data is always there on the host, and tests can inject it. Cost if wrong: none known.
9. **The line runs from the chest to the target's centre**, as the swing does. A 1-block-high
   fence in front of a cow therefore blocks a swing at it (the chest is 1.0 above the feet, at the
   fence's top). Cost if wrong: children can't whack a cow over a low fence. The fix would be to
   also try from the eye.
10. **Leaves and glass block a swing**, like any solid block. Cost if wrong: a sword can't reach
    through a hedge; `in_sight` could skip leaves.
11. **Arrows and boomerangs are unchanged.** They already fly cell by cell and stop at solid
    blocks. Cost if wrong: none; out of scope.

## Result

| Minor | Fix | Test (RED → GREEN) | Commit |
|---|---|---|---|
| M1 | `current_id` required in `validate_edit` / `refusal`; host bedrock tests | `test_the_current_block_is_a_required_argument`; `test_host_edits.gd` (4 tests, proven against a forgetful caller) | `aa36822` |
| M6 | joiner counted at `client_ready`; the countdown's end tells the sleepers | `test_a_late_joiner_stops_the_skip_and_the_sleepers_are_told`, `test_a_skip_that_cannot_happen_tells_the_sleepers` | `2609a51` |
| M9 | `ChatRules.normalize` (digits, fullwidth, accents, look-alikes, spaces, dashes) | `test_phone_numbers_in_any_digits_are_filtered`, `test_fullwidth_emails_and_links_are_filtered`, `test_accented_and_look_alike_swears_are_filtered` (+2 guards) | `4ece175` |
| M10 | `in_sight` grid ray; things out of sight are left out before the swing picks | `test_melee_never_hits_through_a_wall`, `test_a_hidden_animal_never_steals_the_swing` (+1 guard) | the M10 commit |

Suite: 513 → 528 tests, all passing (`tests/run_tests.sh` exit 0 after each fix: 518, 520, 525, 528).
Still open in `docs/DEVELOPMENT.md` §9 from the M1b review: per-frame work that could be cached,
and a guest's pets freezing when the guest leaves.
